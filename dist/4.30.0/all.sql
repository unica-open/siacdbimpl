/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--SIAC-7894 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR158_strutura_dca_stato_patrimonio"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR159_struttura_dca_conto_economico"(p_anno_bilancio varchar, p_ente_proprietario_id integer, cod_missione varchar, cod_programma varchar);

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
  pnota_id integer,
  ambito_id integer
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
    
/* 30/12/2020 SIAC-7894.
	Inserita la gestione dell'ambito in quanto si deve filtrare per ambito FIN.
*/  

sql_query:='select zz.*  from (
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
  g.pnota_id, b.ambito_id
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
  /* 20/09/2017: SIAC-5216.
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
  prime_note.pnota_id,prime_note.ambito_id,
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
  	  capall.pnota_id, capall.ambito_id
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
  	  capall.pnota_id, capall.ambito_id       
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
  	  capall.pnota_id, capall.ambito_id       
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
  sql_query:=sql_query||' ) as zz ,
    siac_d_ambito ambito
where zz.ambito_id =ambito.ambito_id
    and ambito.ambito_code=''AMBITO_FIN''  ';
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
  g.pnota_id, b.ambito_id
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
    prime_note_lib.pnota_id,  prime_note_lib.ambito_id  
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
  	prime_note_lib.pnota_id, prime_note_lib.ambito_id       
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
  	prime_note_lib.pnota_id, prime_note_lib.ambito_id           
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
    ) as xx,
 siac_d_ambito ambito
where xx.ambito_id =ambito.ambito_id
    and ambito.ambito_code=''AMBITO_FIN'' ';
    
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


CREATE OR REPLACE FUNCTION siac."BILR158_strutura_dca_stato_patrimonio" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  nome_ente varchar,
  fam_code varchar,
  fam_desc varchar,
  segno_importo varchar,
  pdce_conto_code varchar,
  pdce_conto_desc varchar,
  importo numeric,
  livello integer
) AS
$body$
DECLARE

elenco_prime_note record;
v_pdce_conto_code varchar;
v_pdce_conto_desc varchar;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		 varchar(1000):=DEF_NULL;

BEGIN

nome_ente := '';
fam_code := '';
fam_desc := '';
segno_importo := '';
pdce_conto_code := '';
pdce_conto_desc := ''; 
importo := 0; 
livello := 0;

SELECT a.ente_denominazione
INTO  nome_ente
FROM  siac_t_ente_proprietario a
WHERE a.ente_proprietario_id = p_ente_prop_id;

FOR elenco_prime_note IN 
SELECT d.pdce_fam_code, d.pdce_fam_desc,
e.movep_det_segno, 
SUM(COALESCE(e.movep_det_importo,0)) AS importo,
b.pdce_conto_code, b.pdce_conto_desc, b.livello,
b.pdce_conto_id_padre
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
--29/12/2020 SIAC-7894: occorre filtrare per ambito = FIN.
INNER JOIN siac_d_ambito ambito ON ambito.ambito_id= b.ambito_id   
WHERE b.ente_proprietario_id = p_ente_prop_id
AND   m.pnota_stato_code = 'D'
AND   i.anno = p_anno
AND   d.pdce_fam_code in ('PP','AP','OP','OA')
--29/12/2020 SIAC-7894: occorre filtrare per ambito = FIN.
AND   ambito.ambito_code ='AMBITO_FIN'
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
GROUP BY d.pdce_fam_code, d.pdce_fam_desc, e.movep_det_segno, 
b.pdce_conto_code, b.pdce_conto_desc, b.livello,
b.pdce_conto_id_padre
ORDER BY d.pdce_fam_code, b.pdce_conto_code
  
LOOP

  IF elenco_prime_note.livello = 8 THEN
    
    v_pdce_conto_code := null;
    v_pdce_conto_desc := null;
  
    SELECT b.pdce_conto_code, b.pdce_conto_desc
    INTO  v_pdce_conto_code, v_pdce_conto_desc
    FROM  siac_t_pdce_conto b
    WHERE b.pdce_conto_id = elenco_prime_note.pdce_conto_id_padre
    AND   b.data_cancellazione IS NULL;
  
    pdce_conto_code := v_pdce_conto_code;
    pdce_conto_desc := v_pdce_conto_desc;
  
  ELSE
  
    pdce_conto_code := elenco_prime_note.pdce_conto_code;
    pdce_conto_desc := elenco_prime_note.pdce_conto_desc;
    
  END IF;

  fam_code := elenco_prime_note.pdce_fam_code;
  fam_desc := elenco_prime_note.pdce_fam_desc;
  segno_importo := elenco_prime_note.movep_det_segno;
  importo := elenco_prime_note.importo;
  livello := elenco_prime_note.livello;

  return next;

  fam_code := '';
  fam_desc := '';
  segno_importo := '';
  pdce_conto_code := '';
  pdce_conto_desc := ''; 
  importo := 0; 
  livello := 0;

END LOOP;

EXCEPTION
	when no_data_found THEN
		 raise notice 'Dati non trovati' ;
	when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'DCA Patrimonio',substring(SQLERRM from 1 for 500);
         return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-7894 - Maurizio - FINE




-- 7848 inizio



--drop FUNCTION siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, anno_atto_amm_int integer, numero_atto_amm integer, codice_soggetto text, id_modpag integer, login_oper text);
CREATE OR REPLACE 
FUNCTION siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, anno_atto_amm integer, numero_atto_amm integer, codice_soggetto text, id_modpag integer, login_oper text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE

atto_amministrativo siac_t_atto_amm%ROWTYPE;
liquidazione siac_t_liquidazione%ROWTYPE;
ordinativo siac_t_ordinativo%ROWTYPE;
soggetto siac_t_soggetto%ROWTYPE;
id_soggetto_relazione siac_r_soggetto_relaz.soggetto_relaz_id%type;


begin
	
	-- return 'MANUTENZIONE IN CORSO';

	
	select * into atto_amministrativo from siac_t_atto_amm staa, siac_d_atto_amm_tipo sdaat 
		where staa.attoamm_anno = CAST(anno_atto_amm AS varchar)
		and staa.attoamm_numero = numero_atto_amm
		and staa.ente_proprietario_id = id_ente
		and sdaat.attoamm_tipo_code = 'ALG' 
		AND sdaat.ente_proprietario_id= id_ente
		AND sdaat.attoamm_tipo_id = staa.attoamm_tipo_id;
	

	select sts.* into soggetto from siac_t_soggetto sts, siac_d_ambito sda
		where sts.soggetto_code = codice_soggetto
		and sts.ente_proprietario_id = id_ente
		and sda.ambito_id = sts.ambito_id 
		and sda.ambito_code = 'AMBITO_FIN'
		and sda.ente_proprietario_id = id_ente;

	
	-- controlli
	
	select stl.* into liquidazione from 
		 siac_t_liquidazione stl, 
		 siac_r_liquidazione_atto_amm srlaa , 
		 siac_r_liquidazione_soggetto srls,
		 siac_r_liquidazione_stato srlst,  
		 siac_d_liquidazione_stato sdls
    where atto_amministrativo.attoamm_id = srlaa.attoamm_id
		and srlaa.liq_id = stl.liq_id
		and srlaa.data_cancellazione is null
		and srlaa.validita_fine is null
		and stl.liq_id = srls.liq_id
		and srls.soggetto_id = soggetto.soggetto_id
		and stl.liq_id = srlst.liq_id
		and srlst.data_cancellazione is NULL
		AND srlst.validita_inizio < CURRENT_TIMESTAMP    
		AND (srlst.validita_fine IS NULL OR srlst.validita_fine > CURRENT_TIMESTAMP)  
		and srlst.liq_stato_id = sdls.liq_stato_id
		and sdls.liq_stato_code != 'A'
		and sdls.ente_proprietario_id= id_ente
		and stl.bil_id = id_bilancio;
	

	if liquidazione is NULL then
		return 'la liquidazione associata non e'' presente sull''anno di bilancio corrente';
	end if;

		
	select sto.* into ordinativo from 
			siac_r_liquidazione_ord srlo, siac_t_ordinativo_ts stot, siac_t_ordinativo sto, siac_r_ordinativo_stato sros, siac_d_ordinativo_stato sdos 
		where srlo.liq_id = liquidazione.liq_id
		and stot.ord_ts_id=srlo.sord_id 
		and sto.ord_id=stot.ord_id 
		and sros.ord_id=sto.ord_id 
		and sdos.ord_stato_id=sros.ord_stato_id
		and sdos.ord_stato_code != 'A'
		AND sto.data_cancellazione is null   
		AND sto.validita_inizio < CURRENT_TIMESTAMP    
		AND (sto.validita_fine IS NULL OR sto.validita_fine > CURRENT_TIMESTAMP)  
		AND stot.data_cancellazione is null   
		AND stot.validita_inizio < CURRENT_TIMESTAMP    
		AND (stot.validita_fine IS NULL OR stot.validita_fine > CURRENT_TIMESTAMP)  
		AND sros.data_cancellazione is null   
		AND sros.validita_inizio < CURRENT_TIMESTAMP    
		AND (sros.validita_fine IS NULL OR sros.validita_fine > CURRENT_TIMESTAMP) 
		limit 1;

	if ordinativo.ord_id is not null then
		return 'la liquidazione ' || liquidazione.liq_anno || '/' || liquidazione.liq_numero || ' e'' associata all''ordinativo ' || ordinativo.ord_anno || '/' || ordinativo.ord_numero;
	end if;
	
	
	-- aggiornamenti
	
		update siac_r_subdoc_modpag srsm
		set    data_cancellazione=CURRENT_TIMESTAMP,
			   validita_fine=CURRENT_TIMESTAMP,
			   login_Operazione=login_oper
 		from siac_r_subdoc_atto_amm srsaa, siac_t_subdoc sts, 
 			siac_r_doc_sog srds 
 		where srsaa.attoamm_id = atto_amministrativo.attoamm_id 
		and srsaa.subdoc_id = sts.subdoc_id 
		and srds.doc_id = sts.doc_id 
		and soggetto.soggetto_id = srds.soggetto_id 
		and srsm.subdoc_id = sts.subdoc_id 
 		and srsaa.data_cancellazione is NULL
		AND srsaa.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsaa.validita_fine IS NULL OR srsaa.validita_fine > CURRENT_TIMESTAMP)  
 		and srsm.data_cancellazione is NULL
		AND srsm.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsm.validita_fine IS NULL OR srsm.validita_fine > CURRENT_TIMESTAMP)  
;



	insert into siac_r_subdoc_modpag
	(
		subdoc_id,
		modpag_id,
		validita_inizio,
		login_Operazione,
		ente_proprietario_id
	)
	select sts.subdoc_id,
		   id_modpag,
		   CURRENT_TIMESTAMP,
		   login_oper,
		   id_ente
	from siac_r_subdoc_atto_amm srsaa, 
		siac_t_subdoc sts,
		siac_t_doc std, 
		siac_r_doc_sog srds
	where atto_amministrativo.attoamm_id = srsaa.attoamm_id
		and srsaa.subdoc_id = sts.subdoc_id
		and sts.ente_proprietario_id = id_ente
		and sts.doc_id = std.doc_id
		and std.doc_id = srds.doc_id
		and std.ente_proprietario_id = id_ente
		and srds.soggetto_id = soggetto.soggetto_id
		and srsaa.data_cancellazione is NULL
		AND srsaa.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsaa.validita_fine IS NULL OR srsaa.validita_fine > CURRENT_TIMESTAMP)  
		and srds.data_cancellazione is NULL
		AND srds.validita_inizio < CURRENT_TIMESTAMP    
		AND (srds.validita_fine IS NULL OR srds.validita_fine > CURRENT_TIMESTAMP)  
	;
	

	select srsr.soggetto_relaz_id into id_soggetto_relazione from siac_r_soggrel_modpag srsm, siac_r_soggetto_relaz srsr 
		where srsm.modpag_id = id_modpag
		and srsr.soggetto_relaz_id = srsm.soggetto_relaz_id 
		and srsr.soggetto_id_da = soggetto.soggetto_id;
	

	update siac_t_liquidazione stl
	   set modpag_id = case when id_soggetto_relazione is NULL then id_modpag else NULL end,
	   	   soggetto_relaz_id = case when id_soggetto_relazione is NULL then NULL else id_soggetto_relazione end, 
		   data_modifica = CURRENT_TIMESTAMP,
		   login_operazione = login_oper 
	from siac_r_liquidazione_atto_amm srlaa , 
		 siac_r_liquidazione_soggetto srls,
		 siac_r_liquidazione_stato srlst,  
		 siac_d_liquidazione_stato sdls
    where atto_amministrativo.attoamm_id = srlaa.attoamm_id
		and srlaa.liq_id = stl.liq_id
		and srlaa.data_cancellazione is null
		and srlaa.validita_fine is null
		and stl.liq_id = srls.liq_id
		and srls.soggetto_id = soggetto.soggetto_id
		and stl.bil_id = id_bilancio
		and stl.liq_id = srlst.liq_id
		and srlst.liq_stato_id = sdls.liq_stato_id
		and srlst.data_cancellazione is NULL
		AND srlst.validita_inizio < CURRENT_TIMESTAMP    
		AND (srlst.validita_fine IS NULL OR srlst.validita_fine > CURRENT_TIMESTAMP)  
		and sdls.liq_stato_code != 'A'
		and sdls.ente_proprietario_id=id_ente
	;

	--

	
    return null;

exception
        when others  THEN
            return SQLERRM;
END;
$function$
;


-- 7848 fine

-- 19.01.2021 Sofia jira SIAC-7958 - inizio

drop function if exists  siac.fnc_siac_stanz_effettivo_up_anno (
  id_in integer,
  anno_comp_in varchar,
  ente_prop_in integer,
  bil_id_in integer,
  anno_in varchar,
  ele_code_in varchar,
  ele_code2_in varchar,
  ele_code3_in varchar
);
drop function if exists  siac.fnc_siac_stanz_effettivo_up_anno_comp 
(

  id_in integer,
  id_comp integer,
  anno_comp_in varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_stanz_effettivo_up_anno (
  id_in integer = NULL::integer,
  anno_comp_in varchar = (NOT NULL::boolean),
  ente_prop_in integer = NULL::integer,
  bil_id_in integer = NULL::integer,
  anno_in varchar = NULL::character varying,
  ele_code_in varchar = NULL::character varying,
  ele_code2_in varchar = NULL::character varying,
  ele_code3_in varchar = NULL::character varying
)
RETURNS TABLE (
  elemid integer,
  annocompetenza varchar,
  stanzeffettivo numeric,
  stanzeffettivocassa numeric,
  massimoimpegnabile numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';
STA_IMP_SCA     constant varchar:='SCA';
STA_IMP_MI     constant varchar:='MI'; -- tipo importo massimo impegnabile

-- fasi di bilancio
FASE_BIL_PREV  constant varchar:='P'; -- previsione
FASE_BIL_PROV  constant varchar:='E'; -- esercizio provvisorio
FASE_BIL_GEST  constant varchar:='G'; -- esercizio gestione
FASE_BIL_CONS  constant varchar:='O'; -- esercizio consuntivo
FASE_BIL_CHIU  constant varchar:='C'; -- esercizio chiuso

-- stati variazioni di importo
STATO_VAR_G    constant varchar:='G'; -- GIUNTA
STATO_VAR_C    constant varchar:='C'; -- CONSIGLIO
STATO_VAR_D    constant varchar:='D'; -- DEFINITIVA
STATO_VAR_B    constant varchar:='B'; -- BOZZA
--- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
STATO_VAR_P    constant varchar:='P'; -- PRE-DEFINITIVO

bilancioId integer:=0;
bilElemId  integer:=0;
bilElemGestId  integer:=0;

strMessaggio varchar(1500):=NVL_STR;

bilFaseOperativa varchar(10):=NVL_STR;
annoBilancio varchar(10):=NVL_STR;

stanziamentoPrev numeric:=0;
stanziamentoPrevCassa numeric:=0;

stanziamento numeric:=0;


stanziamentoEff numeric:=0;

deltaMenoPrev numeric:=0;
varImpGestione numeric:=0;

deltaMenoGest numeric:=0;


deltaMenoPrevCassa numeric:=0;
varImpGestioneCassa numeric:=0;
deltaMenoGestCassa numeric:=0;

stanziamentoEffCassa numeric:=0;
stanziamentoCassa numeric:=0;
stanzMassimoImpegnabile numeric:=null;


enteProprietarioId INTEGER:=0;
periodoId integer:=0;
periodoCompId integer:=0;
BEGIN

 annoCompetenza:=null;
 stanzEffettivo:=null;
 stanzEffettivoCassa:=null;
 elemId:=null;
 massimoImpegnabile:=null;

 -- controllo parametri
 -- anno_comp_in obbligatorio
 -- se id_in non serve altro
 -- diversamente deve essere passato
 -- ente_prop_id, anno_in o bil_id_in
 --  e  la chiave logica del capitolo
 -- ele_code_in,ele_code2_in,ele_code3_in

 strMessaggio:='Calcolo stanziamento effettivo.Controllo parametri.';

 if anno_comp_in is null or anno_comp_in=NVL_STR then
    	RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
 	if  ( (bil_id_in is null or bil_id_in=0) and
          (ente_prop_in is null or ente_prop_in=0))  then
    	RAISE EXCEPTION '% Id ente proprietario mancante.',strMessaggio;
    end if;

    if ele_code_in is null or ele_code_in=NVL_STR or
       ele_code2_in is null or ele_code2_in=NVL_STR or
       ele_code3_in is null or ele_code3_in=NVL_STR then
    	RAISE EXCEPTION '% Chiave logica elem.Bil. mancante.',strMessaggio;
    end if;

    if ( (bil_id_in is null or bil_id_in=0 ) and
         (anno_in is null or anno_in=NVL_STR)) then
    	RAISE EXCEPTION '% Anno bilancio mancante.',strMessaggio;
    end if;

 end if;



 if id_in is not null and id_in!=0 then
        strMessaggio:='Lettura identificativo bilancioId, annoBilancio e enteProprietarioId da elemento di bilancio elem_id='||id_in||'.';
    	select bil.bil_id, per.anno, bilElem.ente_proprietario_id
               into strict bilancioId, annoBilancio, enteProprietarioId
        from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
             siac_t_bil bil, siac_t_periodo per
        where bilElem.elem_id=id_in
        and   bilElem.data_cancellazione is null
        and   bilElem.validita_fine is null
        and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
        and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP
        and   bil.bil_id=bilElem.bil_id
        and   per.periodo_id=bil.periodo_id;

        bilElemId:=id_in;
 else
   if bil_id_in is not null and bil_id_in!=0  then
 	bilancioId:=bil_id_in;
   end if;
 end if;

 if bilancioId is not null and bilancioId!=0 then
  strMessaggio:='Lettura identificativo annoBilancio enteProprietarioId periodoId elemento di bilancio elem_id='||id_in
              ||' per bilancioId='||bilancioId||'.';

  select per.anno,  bil.ente_proprietario_id, per.periodo_id
        into strict annoBilancio, enteProprietarioId, periodoId
  from siac_t_bil bil, siac_t_periodo per
  where bil.bil_id=bilancioId and
        per.periodo_id=bil.periodo_id;
 end if;

 if bilElemId is null or bilElemId=0 then
   strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in||'.';
   if bilancioId is not null and bilancioId!=0 then
 	 strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                    ||'  per bilancioId='||bilancioId||' .';
     select bilElem.elem_id into strict bilElemId
     from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem
     where bilElem.bil_id=bilancioId
     and   bilElem.elem_code=ele_code_in
     and   bilElem.elem_code2=ele_code2_in
     and   bilElem.elem_code3=ele_code3_in
     and   bilElem.data_cancellazione is null
     and   bilElem.validita_fine is null
     and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
     and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP;
   else
	 strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                    ||'  bilancioId periodoId per annoBilancioIn='||anno_in||' enteProprietarioIn'||ente_prop_in||' .';
     select bilElem.elem_id, bilelem.bil_id, per.periodo_id
            into strict bilElemId, bilancioId, periodoId
     from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
          siac_t_bil bil, siac_t_periodo per, siac_d_periodo_tipo tipoPer
     where per.anno=anno_in
     and   per.ente_proprietario_id=ente_prop_in
     and   tipoPer.periodo_tipo_id=per.periodo_tipo_id
     and   tipoPer.periodo_tipo_code='SY'
     and   bil.periodo_id=per.periodo_id
     and   bilElem.bil_id=bil.bil_id
     and   bilElem.elem_code=ele_code_in
     and   bilElem.elem_code2=ele_code2_in
     and   bilElem.elem_code3=ele_code3_in
     and   bilElem.data_cancellazione is null
     and   bilElem.validita_fine is null
     and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
     and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP;

     annoBilancio:=anno_in;
     enteProprietarioId:=ente_prop_in;

   end if;

 end  if;




 strMessaggio:='Lettura fase di bilancio corrente per  anno bilancio='||annoBilancio||' bilancioId='||bilancioId||'.';
 select faseop.fase_operativa_code into strict bilFaseOperativa
 from siac_d_fase_operativa faseOp, siac_r_bil_fase_operativa bilFaseOp
 where bilfaseop.bil_id=bilancioId and
       bilfaseop.data_cancellazione is null and
       bilfaseop.validita_fine is null  and
       faseOp.fase_operativa_id = bilfaseop.fase_operativa_id and
       faseOp.data_cancellazione is  null and
       faseOp.validita_fine is null;


 if bilFaseOperativa not in ( FASE_BIL_PREV, FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
   	RAISE EXCEPTION '% Fase non ammessa per il calcolo richiesto.',strMessaggio;
 end if;

 if anno_comp_in!=annoBilancio then
 	strMessaggio:='Lettura periodoCompId per anno_comp_in='||anno_comp_in||' elem_id='||bilElemId||'.';

 	select  per.periodo_id into strict periodoCompId
    from siac_t_periodo per, siac_d_periodo_tipo perTipo
    where per.anno=anno_comp_in
    and   per.ente_proprietario_id=enteProprietarioId
    and   perTipo.periodo_tipo_id=per.periodo_tipo_id
    and   perTipo.periodo_tipo_code='SY';
  else
     periodoCompId:=periodoId;
  end if;



 if bilFaseOperativa = FASE_BIL_PROV then
 	strMessaggio:='Lettura elemento di bilancio equivalente di gestione per elem_id='||bilElemId||'.';
	select bilElemGest.elem_id into  bilElemGestId
    from siac_t_bil_elem bilElemPrev, siac_d_bil_elem_tipo tipoGest,
       	 siac_t_bil_elem bilElemGest
    where bilElemPrev.elem_id=bilElemId and
          bilElemGest.elem_code=bilElemPrev.elem_code and
          bilElemGest.elem_code2=bilElemPrev.elem_code2 and
          bilElemGest.elem_code3=bilElemPrev.elem_code3 and
          bilElemGest.ente_proprietario_id=bilElemPrev.ente_proprietario_id and
          bilElemGest.bil_id=bilElemPrev.bil_id and
          bilElemGest.data_cancellazione is null and bilElemGest.validita_fine is null and
          tipoGest.elem_tipo_id=bilElemGest.elem_tipo_id and
          tipoGest.elem_tipo_code=TIPO_CAP_UG;

    if NOT FOUND then
	    bilElemGestId:=0;
    end if;

  end if;

  strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
  select importiPrev.elem_det_importo into strict stanziamentoPrev
  from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
  where importiPrev.elem_id=bilElemId AND
	    importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
        tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
        tipoImpPrev.elem_det_tipo_code=STA_IMP and
        importiPrev.periodo_id=periodoCompId;

 if anno_comp_in=annoBilancio then
      strMessaggio:='Lettura stanziamenti di previsione cassa per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
      select importiprev.elem_det_importo into strict stanziamentoPrevCassa
      from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
      where importiPrev.elem_id=bilElemId AND
 	        importiPrev.data_cancellazione is null and importiPrev.validita_fine is null and
   	   	    tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id and
	        tipoImpPrev.elem_det_tipo_code=STA_IMP_SCA and
	        importiPrev.periodo_id=periodoCompId;
 end if;

 --raise 'stanziamentoPrev %',stanziamentoPrev;
  if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then --1
     --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
	 --- diverso da BOZZA,DEFINTIVO,ANNULLATO
   	 strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemId||' anno_comp_in='||
                       anno_comp_in||'.';
     --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
     select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrev
     from siac_t_variazione var,
          siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
          siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
     where bilElemDetVar.elem_id=bilElemId and
    	   bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
           bilElemDetVar.periodo_id=periodoCompId and
           bilElemDetVar.elem_det_importo<0 AND
  	       bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
           bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
           bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
           statoVar.data_cancellazione is null and statoVar.validita_fine is null and
           tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
           var.variazione_id=statoVar.variazione_id and
           var.data_cancellazione is null and var.validita_fine is null and
           var.bil_id=bilancioId;

    if  bilFaseOperativa =FASE_BIL_PROV and bilElemGestId!=0 then --2
     --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
     strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemGestId||' anno_comp_in='||
                       anno_comp_in||'.';

     select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestione
     from siac_t_variazione var,
          siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
          siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
     where bilElemDetVar.elem_id=bilElemGestId and
       	   bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
           bilElemDetVar.periodo_id=periodoCompId and
  	       bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
           bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
           bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
           statoVar.data_cancellazione is null and statoVar.validita_fine is null and
           tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
           tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
           var.variazione_id=statoVar.variazione_id and
           var.data_cancellazione is null and var.validita_fine is null and
           var.bil_id=bilancioId;


       -- importo massimo impegnabile
       stanzMassimoImpegnabile:=null;
   	   strMessaggio:='Lettura massimo impegnabile per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
	   select importiGest.elem_det_importo into  stanzMassimoImpegnabile
	   from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
       where importiGest.elem_id=bilElemGestId AND
             importiGest.data_cancellazione is null and importiGest.validita_fine is null and
  			 tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
             tipoImp.elem_det_tipo_code=STA_IMP_MI and
	    	 importiGest.periodo_id=periodoCompId;

    end if; --2

    if anno_comp_in=annoBilancio then --2



      --- calcolo dei 'delta-previsione', variazioni agli importi di cassa del CAP-UP in stato
      --- diverso da BOZZA,DEFINTIVO,ANNULLATO
      strMessaggio:='Lettura variazioni delta-meno-prev cassa per elem_id='||bilElemId||' anno_comp_in='||
                       anno_comp_in||'.';
	  --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
      select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoPrevCassa
      from siac_t_variazione var,
           siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
           siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
      where bilElemDetVar.elem_id=bilElemId and
      	    bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
            bilElemDetVar.periodo_id=periodoCompId and
	        bilElemDetVar.elem_det_importo<0 AND
  	        bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
            bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
            bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
            statoVar.data_cancellazione is null and statoVar.validita_fine is null and
            tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--            tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
            tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
            var.variazione_id=statoVar.variazione_id and
            var.data_cancellazione is null and var.validita_fine is null and
            var.bil_id=bilancioId;


     if  bilFaseOperativa =FASE_BIL_PROV and bilElemGestId!=0 then --3
      --- calcolo variazioni applicate alla gestione, variazioni agli importi di casas CAP-UG
      strMessaggio:='Lettura variazioni di gestione cassa per elem_id='||bilElemGestId||' anno_comp_in='||
                       anno_comp_in||'.';

      select coalesce(sum(bilElemDetVar.elem_det_importo),0) into strict varImpGestioneCassa
      from siac_t_variazione var,
       	   siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
           siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
      where bilElemDetVar.elem_id=bilElemGestId and
        	bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
            bilElemDetVar.periodo_id=periodoCompId and
            bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
            bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
            bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
            statoVar.data_cancellazione is null and statoVar.validita_fine is null and
            tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
            tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D and
            var.variazione_id=statoVar.variazione_id and
            var.data_cancellazione is null and var.validita_fine is null and
            var.bil_id=bilancioId;
    end if; --3
   end if; --2
 end if; --1

 if bilFaseOperativa in ( FASE_BIL_PROV) and bilElemGestId!=0 then

     strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemGestId||' anno_comp_in='||anno_comp_in||'.';
   	 select importiGest.elem_det_importo into strict stanziamento
     from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
     where importiGest.elem_id=bilElemGestId AND
       	   importiGest.data_cancellazione is null and importiGest.validita_fine is null and
   	 	   tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
           tipoImp.elem_det_tipo_code=STA_IMP and
    	   importiGest.periodo_id=periodoCompId;

     --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
     strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemGestId||' anno_comp_in='||
                           anno_comp_in||'.';
	 --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
     select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGest
     from siac_t_variazione var,
      	  siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	      siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
     where bilElemDetVar.elem_id=bilElemGestId and
           bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
           bilElemDetVar.periodo_id=periodoCompId and
	       bilElemDetVar.elem_det_importo<0 AND
  	       bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
	       bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
           bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	       statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	   tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--	       tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
--	       tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
	       tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14102016 Sofia JIRA-SIAC-4099
           var.variazione_id=statoVar.variazione_id and
           var.data_cancellazione is null and var.validita_fine is null and
	       var.bil_id=bilancioId;

	 if anno_comp_in=annoBilancio then
         	strMessaggio:='Lettura stanziamenti di gestione cassa per elem_id='||bilElemGestId||' anno_comp_in='||anno_comp_in||'.';

            select importiGest.elem_det_importo into strict stanziamentoCassa
			from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
		    where importiGest.elem_id=bilElemGestId AND
         		  importiGest.data_cancellazione is null and importiGest.validita_fine is null and
		   		  tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id and
		          tipoImp.elem_det_tipo_code=STA_IMP_SCA and
	    	      importiGest.periodo_id=periodoCompId;


         --- calcolo dei 'delta-gestione', variazioni agli importi di cassa del CAP-UG in stato
 	     --- diverso da BOZZA,DEFINTIVO,ANNULLATO
       	 strMessaggio:='Lettura variazioni delta-meno-gest cassa per elem_id='||bilElemGestId||' anno_comp_in='||
                           anno_comp_in||'.';
		 --- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
    	 select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into strict deltaMenoGestCassa
         from siac_t_variazione var,
              siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
	          siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
         where bilElemDetVar.elem_id=bilElemGestId and
               bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
               bilElemDetVar.periodo_id=periodoCompId and
			   bilElemDetVar.elem_det_importo<0 AND
  	    	   bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
	           bilElemDetVarTipo.elem_det_tipo_code=STA_IMP_SCA and
    	       bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
	           statoVar.data_cancellazione is null and statoVar.validita_fine is null and
    	       tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
--   	           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
--   	           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
   	           tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) and -- 14102016 Sofia JIRA-SIAC-4099
        	   var.variazione_id=statoVar.variazione_id and
               var.data_cancellazione is null and var.validita_fine is null and
	           var.bil_id=bilancioId;
      end if;
 end if;

 -- stanziamenti di previsione competenza e cassa adeguati a
 -- relativi 'delta-meno' e variazioni def. applicate alle gestione
 /* 04.07.2016 Sofia ID-INC000001114035
 stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev+varImpGestione; */

 stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev;
 if anno_comp_in=annoBilancio then
   /* 04.07.2016 Sofia ID-INC000001114035
     stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa+varImpGestioneCassa; **/
     stanziamentoPrevCassa:= stanziamentoPrevCassa-deltaMenoPrevCassa;
 end if;



 strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'.';
 case
--   when bilFaseOperativa=FASE_BIL_PROV then -- 15.01.2021 Sofia JiraSIAC-7958
-- 15.01.2021 Sofia JiraSIAC-7958
   when bilFaseOperativa=FASE_BIL_PROV and ente_prop_in!=2 then
 --  		if stanziamentoPrev>stanziamento then 26072016 Sofia JIRA-SIAC-3887
   		if stanziamentoPrev>stanziamento-deltaMenoGest then
        /* 04.07.2016 Sofia ID-INC000001114035
        	 stanziamentoEff:=stanziamento; **/
             stanziamentoEff:=stanziamento-deltaMenoGest;
        else stanziamentoEff:=stanziamentoPrev;
        end if;

        if anno_comp_in=annoBilancio then
--         if stanziamentoPrevCassa>stanziamentoCassa then 26072016 Sofia JIRA-SIAC-3887
         if stanziamentoPrevCassa>stanziamentoCassa-deltaMenoGestCassa then
          /* 04.07.2016 Sofia ID-INC000001114035
        	 stanziamentoEffCassa:=stanziamentoCassa; **/
             stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
         else stanziamentoEffCassa:=stanziamentoPrevCassa;
         end if;
        end if;

   ELSE
   		stanziamentoEff:=stanziamentoPrev;
        if anno_comp_in=annoBilancio then
         stanziamentoEffCassa:=stanziamentoPrevCassa;
        end if;
 end case;

  /* 04.07.2016 Sofia ID-INC000001114035
 -- stanziamentoEff abbattutto dai 'delta-gestione'
 stanziamentoEff:=stanziamentoEff-deltaMenoGest;
 if anno_comp_in = annoBilancio then
  stanziamentoEffCassa:=stanziamentoEffCassa-deltaMenoGestCassa;
 end if; */



 elemId:=bilElemId;
 annoCompetenza:=anno_comp_in;
 stanzEffettivo:=stanziamentoEff;
 if anno_comp_in = annoBilancio then
  stanzEffettivoCassa:=stanziamentoEffCassa;
 end if;
 if stanzMassimoImpegnabile is not null then
   	massimoImpegnabile:=stanzMassimoImpegnabile;
 end if;


 return next;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (

  id_in integer,
  id_comp integer,
  anno_comp_in varchar
)
RETURNS TABLE (
  elemid integer,
  annocompetenza varchar,
  stanzeffettivo numeric,
  stanzeffettivocassa numeric,
  massimoimpegnabile numeric
) AS
$body$
DECLARE


-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';
STA_IMP_SCA     constant varchar:='SCA';
STA_IMP_MI     constant varchar:='MI'; -- tipo importo massimo impegnabile

-- fasi di bilancio
FASE_BIL_PREV  constant varchar:='P'; -- previsione
FASE_BIL_PROV  constant varchar:='E'; -- esercizio provvisorio
FASE_BIL_GEST  constant varchar:='G'; -- esercizio gestione
FASE_BIL_CONS  constant varchar:='O'; -- esercizio consuntivo
FASE_BIL_CHIU  constant varchar:='C'; -- esercizio chiuso

-- stati variazioni di importo
STATO_VAR_G    constant varchar:='G'; -- GIUNTA
STATO_VAR_C    constant varchar:='C'; -- CONSIGLIO
STATO_VAR_D    constant varchar:='D'; -- DEFINITIVA
STATO_VAR_B    constant varchar:='B'; -- BOZZA
--- 31.03.2016 Sofia SIAC-3304 aggiunto stato P
STATO_VAR_P    constant varchar:='P'; -- PRE-DEFINITIVO

bilancioId integer:=0;
bilElemId  integer:=0;
bilElemGestId  integer:=0;

strMessaggio varchar(1500):=NVL_STR;

bilFaseOperativa varchar(10):=NVL_STR;
annoBilancio varchar(10):=NVL_STR;

stanziamentoPrev numeric:=0;
stanziamentoPrevCassa numeric:=0;
stanziamento numeric:=0;
stanziamentoEff numeric:=0;
deltaMenoPrev numeric:=0;
varImpGestione numeric:=0;
deltaMenoGest numeric:=0;
deltaMenoPrevCassa numeric:=0;
varImpGestioneCassa numeric:=0;
deltaMenoGestCassa numeric:=0;
stanziamentoEffCassa numeric:=0;
stanziamentoCassa numeric:=0;
stanzMassimoImpegnabile numeric:=null;
enteProprietarioId INTEGER:=0;
periodoId integer:=0;
periodoCompId integer:=0;

BEGIN

     annoCompetenza:=null;
     stanzEffettivo:=null;
     stanzEffettivoCassa:=null;
     elemId:=null;
     massimoImpegnabile:=null;

      -- controllo parametri
      -- anno_comp_in obbligatorio
      -- se id_in non serve altro
      -- diversamente deve essere passato
      -- ente_prop_id, anno_in o bil_id_in
      --  e  la chiave logica del capitolo
      -- ele_code_in,ele_code2_in,ele_code3_in

     strMessaggio:='Calcolo stanziamento effettivo.Controllo parametri.';

     if anno_comp_in is null or anno_comp_in=NVL_STR then
         	RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
     end if;

     if id_comp is null or id_comp=0 then
         	RAISE EXCEPTION '% Id componente mancante.',strMessaggio;
     end if;

     if id_in is null or id_in=0 then

          if  ( (bil_id_in is null or bil_id_in=0) and (ente_prop_in is null or ente_prop_in=0)) then
         	     RAISE EXCEPTION '% Id ente proprietario mancante.',strMessaggio;
          end if;

          if ele_code_in is null or ele_code_in=NVL_STR or ele_code2_in is null or ele_code2_in=NVL_STR or ele_code3_in is null or ele_code3_in=NVL_STR then
         	     RAISE EXCEPTION '% Chiave logica elem.Bil. mancante.',strMessaggio;
          end if;

          if ( (bil_id_in is null or bil_id_in=0 ) and (anno_in is null or anno_in=NVL_STR)) then
         	     RAISE EXCEPTION '% Anno bilancio mancante.',strMessaggio;
          end if;
     end if;


     if id_in is not null and id_in!=0 then

          strMessaggio:='Lettura identificativo bilancioId, annoBilancio e enteProprietarioId da elemento di bilancio elem_id='||id_in||'.';
         	select bil.bil_id, per.anno, bilElem.ente_proprietario_id
                    into strict bilancioId, annoBilancio, enteProprietarioId
             from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
                  siac_t_bil bil, siac_t_periodo per
             where bilElem.elem_id=id_in
             and   bilElem.data_cancellazione is null
             and   bilElem.validita_fine is null
             and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
             and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP
             and   bil.bil_id=bilElem.bil_id
             and   per.periodo_id=bil.periodo_id;
             bilElemId:=id_in;
     else
          if bil_id_in is not null and bil_id_in!=0  then
      	     bilancioId:=bil_id_in;
          end if;
     end if;

     if bilancioId is not null and bilancioId!=0 then
          strMessaggio:='Lettura identificativo annoBilancio enteProprietarioId periodoId elemento di bilancio elem_id='||id_in
                   ||' per bilancioId='||bilancioId||'.';

          select per.anno,  bil.ente_proprietario_id, per.periodo_id into strict annoBilancio, enteProprietarioId, periodoId
          from siac_t_bil bil, siac_t_periodo per
          where bil.bil_id=bilancioId
                and per.periodo_id=bil.periodo_id;
     end if;

     if bilElemId is null or bilElemId=0 then
          strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in||'.';
          if bilancioId is not null and bilancioId!=0 then
      	     strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                         ||'  per bilancioId='||bilancioId||' .';
               select bilElem.elem_id into strict bilElemId
               from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem
               where bilElem.bil_id=bilancioId
               and   bilElem.elem_code=ele_code_in
               and   bilElem.elem_code2=ele_code2_in
               and   bilElem.elem_code3=ele_code3_in
               and   bilElem.data_cancellazione is null
               and   bilElem.validita_fine is null
               and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
               and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP;
          else
     	     strMessaggio:='Lettura identificativo elemento di bilancio '||ele_code_in||'/'||ele_code2_in||'/'||ele_code3_in
                         ||'  bilancioId periodoId per annoBilancioIn='||anno_in||' enteProprietarioIn'||ente_prop_in||' .';
               select bilElem.elem_id, bilelem.bil_id, per.periodo_id into strict bilElemId, bilancioId, periodoId
               from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo tipoBilElem,
               siac_t_bil bil, siac_t_periodo per, siac_d_periodo_tipo tipoPer
               where per.anno=anno_in
               and   per.ente_proprietario_id=ente_prop_in
               and   tipoPer.periodo_tipo_id=per.periodo_tipo_id
               and   tipoPer.periodo_tipo_code='SY'
               and   bil.periodo_id=per.periodo_id
               and   bilElem.bil_id=bil.bil_id
               and   bilElem.elem_code=ele_code_in
               and   bilElem.elem_code2=ele_code2_in
               and   bilElem.elem_code3=ele_code3_in
               and   bilElem.data_cancellazione is null
               and   bilElem.validita_fine is null
               and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
               and   tipoBilElem.elem_tipo_code = TIPO_CAP_UP;

               annoBilancio:=anno_in;
               enteProprietarioId:=ente_prop_in;

          end if;
     end if;

     strMessaggio:='Lettura fase di bilancio corrente per  anno bilancio='||annoBilancio||' bilancioId='||bilancioId||'.';
     select faseop.fase_operativa_code into strict bilFaseOperativa
     from siac_d_fase_operativa faseOp, siac_r_bil_fase_operativa bilFaseOp
     where bilfaseop.bil_id=bilancioId
          and bilfaseop.data_cancellazione is null
          and bilfaseop.validita_fine is null
          and faseOp.fase_operativa_id = bilfaseop.fase_operativa_id
          and faseOp.data_cancellazione is null
          and faseOp.validita_fine is null;


     if bilFaseOperativa not in ( FASE_BIL_PREV, FASE_BIL_PROV, FASE_BIL_GEST,FASE_BIL_CONS,FASE_BIL_CHIU) then
        	RAISE EXCEPTION '% Fase non ammessa per il calcolo richiesto.',strMessaggio;
     end if;

     if anno_comp_in!=annoBilancio then
      	strMessaggio:='Lettura periodoCompId per anno_comp_in='||anno_comp_in||' elem_id='||bilElemId||'.';
          select  per.periodo_id into strict periodoCompId
          from siac_t_periodo per, siac_d_periodo_tipo perTipo
          where per.anno=anno_comp_in
          and   per.ente_proprietario_id=enteProprietarioId
          and   perTipo.periodo_tipo_id=per.periodo_tipo_id
          and   perTipo.periodo_tipo_code='SY';
     else
          periodoCompId:=periodoId;
     end if;

     if bilFaseOperativa = FASE_BIL_PROV then
          strMessaggio:='Lettura elemento di bilancio equivalente di gestione per elem_id='||bilElemId||'.';
          select bilElemGest.elem_id into  bilElemGestId
          from siac_t_bil_elem bilElemPrev, siac_d_bil_elem_tipo tipoGest,
               siac_t_bil_elem bilElemGest
          where bilElemPrev.elem_id=bilElemId
          and bilElemGest.elem_code=bilElemPrev.elem_code
          and bilElemGest.elem_code2=bilElemPrev.elem_code2
          and bilElemGest.elem_code3=bilElemPrev.elem_code3
          and bilElemGest.ente_proprietario_id=bilElemPrev.ente_proprietario_id
          and bilElemGest.bil_id=bilElemPrev.bil_id
          and bilElemGest.data_cancellazione is null
          and bilElemGest.validita_fine is null
          and tipoGest.elem_tipo_id=bilElemGest.elem_tipo_id
          and tipoGest.elem_tipo_code=TIPO_CAP_UG;

          if NOT FOUND then
          	bilElemGestId:=0;
          end if;
     end if;

     strMessaggio:='Lettura stanziamenti di previsione per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';

     /*SIAC - 7349*/
     select comp.elem_det_importo  into strict stanziamentoPrev
     from siac_t_bil_elem_det importiPrev,
     	siac_d_bil_elem_det_tipo tipoImpPrev,
     	siac_t_bil_elem_det_comp comp,
     	siac_d_bil_elem_det_comp_tipo comptipo
     where importiPrev.elem_id=bilElemId
     	and comp.elem_det_id = importiPrev.elem_det_id
          and importiPrev.data_cancellazione is null
          and importiPrev.validita_fine is null
     	and tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id
          and tipoImpPrev.elem_det_tipo_code=STA_IMP
     	and comp.data_cancellazione is null and comp.validita_fine is null
          and importiPrev.periodo_id=periodoCompId
     	and comptipo.data_cancellazione is null
        -- SIAC-7796
		-- and comptipo.validita_fine is null
     	and comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id
     	and comptipo.elem_det_comp_tipo_id = id_comp
	-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
		and not (exists (
			select siactbilel4_.elem_det_var_comp_id
			from 	siac_t_bil_elem_det_var_comp siactbilel4_
					cross join siac_t_bil_elem_det_var siactbilel5_
					cross join siac_r_variazione_stato siacrvaria6_
					cross join siac_d_variazione_stato siacdvaria7_
			where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
				and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
				and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
				and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
				and siactbilel4_.elem_det_flag='N'
				and siacdvaria7_.variazione_stato_tipo_code<>'D'
				and siactbilel4_.data_cancellazione is null
				and siactbilel5_.data_cancellazione is null
				and siacrvaria6_.data_cancellazione is null
			));

     if anno_comp_in=annoBilancio then
           strMessaggio:='Lettura stanziamenti di previsione cassa per elem_id='||bilElemId||' anno_comp_in='||anno_comp_in||'.';
           select importiprev.elem_det_importo into strict stanziamentoPrevCassa
           from siac_t_bil_elem_det importiPrev, siac_d_bil_elem_det_tipo tipoImpPrev
           where importiPrev.elem_id=bilElemId
      	     and importiPrev.data_cancellazione is null
               and importiPrev.validita_fine is null
        	   	and tipoImpPrev.elem_det_tipo_id=importiPrev.elem_det_tipo_id
     	     and tipoImpPrev.elem_det_tipo_code=STA_IMP_SCA
     	     and importiPrev.periodo_id=periodoCompId;
     end if;



     if bilFaseOperativa in (FASE_BIL_PROV,FASE_BIL_PREV) then --1
          --- calcolo dei 'delta-previsione', variazioni agli importi del CAP-UP in stato
     	--- diverso da BOZZA,DEFINTIVO,ANNULLATO
        	strMessaggio:='Lettura variazioni delta-meno-prev per elem_id='||bilElemId||' anno_comp_in='||
                            anno_comp_in||'.';

     	/*SIAC - 7349*/
         /*ERRORE RISCONTRATO NEL TEST FASE DI PREV - mr*/
	     /*select   coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoPrev
          from siac_t_variazione var,
              	siac_r_variazione_stato statoVar,
	     	siac_d_variazione_stato tipoStatoVar,
               siac_t_bil_elem_det_var bilElemDetVar,
	     	siac_d_bil_elem_det_tipo bilElemDetVarTipo,
               siac_t_bil_elem_det_var_comp bilElemDetVarComp,
               siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo,
               siac_t_bil_elem_det_comp bilElemDetComp
              where bilElemDetVar.elem_id=bilElemId
             	     and bilElemDetVar.data_cancellazione is null
                    and bilElemDetVar.validita_fine is null
                    and bilElemDetVar.periodo_id=periodoCompId
	     	     and bilElemDetVar.elem_det_importo<0
  	               and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
                    and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
                    and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
                    and statoVar.data_cancellazione is null
                    and statoVar.validita_fine is null
                    and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
                    and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) -- 1109015 Sofia aggiunto STATO_VAR_B
	     		and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) -- Sofia 26072016 JIRA-SIAC-3887
                    and var.variazione_id=statoVar.variazione_id
                    and var.data_cancellazione is null and var.validita_fine is null
                    and var.bil_id= bilancioId
	     		and bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null
	     		and bilElemDetComp.data_cancellazione is null and bilElemDetComp.validita_fine is null
                    and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
                    and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
	     		and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp; --adeguamento*/

          select  coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoPrev
			from siac_t_variazione var,
			siac_r_variazione_stato statoVar,
			siac_d_variazione_stato tipoStatoVar,
			siac_t_bil_elem_det_var bilElemDetVar,
			siac_d_bil_elem_det_tipo bilElemDetVarTipo,
			siac_t_bil_elem_det_var_comp bilElemDetVarComp,
			siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo --adeguamento
			where bilElemDetVar.elem_id=bilElemId and
			bilElemDetVar.data_cancellazione is null and bilElemDetVar.validita_fine is null and
			bilElemDetVar.periodo_id=periodoCompId and
			bilElemDetVar.elem_det_importo<0 AND
			bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id and
			bilElemDetVarTipo.elem_det_tipo_code=STA_IMP and
			bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id and
			statoVar.data_cancellazione is null and statoVar.validita_fine is null and
			tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id and
			-- tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and -- 1109015 Sofia aggiunto STATO_VAR_B
			tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- Sofia 26072016 JIRA-SIAC-3887
			var.variazione_id=statoVar.variazione_id and
			var.data_cancellazione is null and var.validita_fine is null and
			var.bil_id= bilancioId and
			bilElemDetVarComp.data_cancellazione is null and bilElemDetVarComp.validita_fine is null and
			bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
			and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp;

          if  bilFaseOperativa =FASE_BIL_PROV and bilElemGestId!=0 then --2
          --- calcolo variazioni applicate alla gestione, variazioni agli importi CAP-UG
               strMessaggio:='Lettura variazioni di gestione per elem_id='||bilElemGestId||' anno_comp_in='||
                       anno_comp_in||'.';

	          select coalesce(sum(bilElemDetVarComp.elem_det_importo),0) into strict varImpGestione
                  from siac_t_variazione var,
                       siac_r_variazione_stato statoVar,
                       siac_d_variazione_stato tipoStatoVar,
                       siac_t_bil_elem_det_var bilElemDetVar,
                       siac_d_bil_elem_det_tipo bilElemDetVarTipo,
                       siac_t_bil_elem_det_var_comp bilElemDetVarComp,
                       siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, --adeguamento
                       siac_t_bil_elem_det_comp bilElemDetComp
                     -- where bilElemDetVar.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
                    where bilElemDetVar.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
                    and bilElemDetVar.data_cancellazione is null
                    and bilElemDetVar.validita_fine is null
                    and bilElemDetVar.periodo_id=periodoCompId
  	               and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
                    and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
                    and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
                    and statoVar.data_cancellazione is null and statoVar.validita_fine is null
                    and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
                    and tipoStatoVar.variazione_stato_tipo_code=STATO_VAR_D
                    and var.variazione_id=statoVar.variazione_id
                    and var.data_cancellazione is null
                    and var.validita_fine is null
                    and var.bil_id=bilancioId
                    and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
                    and bilElemDetVarComp.elem_det_comp_id = bilElemDetComp.elem_det_comp_id
	          	and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
	          	and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp --adeguamento
	          	and bilElemDetVarComp.data_cancellazione is null
                    and bilElemDetVarComp.validita_fine is null
                    and bilElemDetComp.data_cancellazione is null
                    and bilElemDetComp.validita_fine is null;


          end if; --2
     end if; --1

     if bilFaseOperativa in ( FASE_BIL_PROV) and bilElemGestId!=0 then


			  strMessaggio:='Lettura stanziamenti di gestione per elem_id='||bilElemGestId||' anno_comp_in='||anno_comp_in||'.';
			--SIAC-7349
				-- SIAC-7796: 	defaultato a zero gli importi nel caso di componente mancante in gestione equivalente
				-- select comp.elem_det_importo	into strict stanziamento
			  select coalesce(comp.elem_det_importo, 0) into stanziamento
			from siac_t_bil_elem_det importiGest,
			siac_d_bil_elem_det_tipo tipoImp,
			  siac_t_bil_elem_det_comp comp,
			siac_d_bil_elem_det_comp_tipo comptipo
			-- where importiGest.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
			where importiGest.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
			and importiGest.data_cancellazione is null
			  and importiGest.validita_fine is null
				 and tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id
			  and tipoImp.elem_det_tipo_code=STA_IMP
				 and importiGest.periodo_id=periodoCompId
			  and comp.elem_det_id = importiGest.elem_det_id
			 and comp.elem_det_comp_tipo_id = comptipo.elem_det_comp_tipo_id
			 and comp.data_cancellazione is null
			  and comp.validita_fine is null
			  and comptipo.data_cancellazione is null
			  -- SIAC-7796
			  -- and comptipo.validita_fine is null
			 and comptipo.elem_det_comp_tipo_id = id_comp
			-- SIAC-7349 Aggiunto non exists per escludere le componenti che sono collegate come "nuovi dettagli" tramite variazione in stato diverso da definitivo
			and not (exists (
				select siactbilel4_.elem_det_var_comp_id
				from 	siac_t_bil_elem_det_var_comp siactbilel4_
						cross join siac_t_bil_elem_det_var siactbilel5_
						cross join siac_r_variazione_stato siacrvaria6_
						cross join siac_d_variazione_stato siacdvaria7_
				where 	siactbilel4_.elem_det_var_id=siactbilel5_.elem_det_var_id
					and siactbilel5_.variazione_stato_id=siacrvaria6_.variazione_stato_id
					and siacrvaria6_.variazione_stato_tipo_id=siacdvaria7_.variazione_stato_tipo_id
					and siactbilel4_.elem_det_comp_id=comp.elem_det_comp_id
					and siactbilel4_.elem_det_flag='N'
					and siacdvaria7_.variazione_stato_tipo_code<>'D'
					and siactbilel4_.data_cancellazione is null
					and siactbilel5_.data_cancellazione is null
					and siacrvaria6_.data_cancellazione is null
				));



          --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
          --- diverso da BOZZA,DEFINTIVO,ANNULLATO
          strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||bilElemGestId||' anno_comp_in='||
                           anno_comp_in||'.';

     	--SIAC-7349
     	select coalesce(sum(abs(bilElemDetVarComp.elem_det_importo)),0) into strict deltaMenoGest
          from siac_t_variazione var,
          siac_r_variazione_stato statoVar,
          siac_d_variazione_stato tipoStatoVar,
	     siac_t_bil_elem_det_var bilElemDetVar,
          siac_d_bil_elem_det_tipo bilElemDetVarTipo,
          siac_t_bil_elem_det_var_comp bilElemDetVarComp,
          siac_d_bil_elem_det_comp_tipo bilElemDetCompTipo, --adeguamento
          siac_t_bil_elem_det_comp bilElemDetComp
     	  -- where bilElemDetVar.elem_id=bilElemId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
          where bilElemDetVar.elem_id=bilElemGestId --SIAC-7349 Fix TC su calcolo disponibilita' variare - GS - 10/07/2020
          and bilElemDetVar.data_cancellazione is null
          and bilElemDetVar.validita_fine is null
          and bilElemDetVar.periodo_id=periodoCompId
		and bilElemDetVar.elem_det_importo<0
  	    	and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
	     and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
    	     and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
	     and statoVar.data_cancellazione is null
          and statoVar.validita_fine is null
    	     and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
       	--and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_B,STATO_VAR_P) and --1109015 Sofia aggiunto STATO_VAR_B
      	--and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P) and -- 26072016 Sofia JIRA-SIAC-3887
       	and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P,STATO_VAR_B) -- 14.102016 Sofia JIRA-SIAC-4099 riaggiunto B
          and var.variazione_id=statoVar.variazione_id
          and var.data_cancellazione is null and var.validita_fine is null
     	and var.bil_id=bilancioId
          and bilElemDetVarComp.elem_det_var_id = bilElemDetVar.elem_det_var_id
          and bilElemDetVarComp.elem_det_comp_id = bilElemDetComp.elem_det_comp_id
     	and bilElemDetVarComp.data_cancellazione is null
          and bilElemDetVarComp.validita_fine is null
          and bilElemDetComp.data_cancellazione is null
          and bilElemDetComp.validita_fine is null
     	and bilElemDetComp.elem_det_comp_tipo_id =  bilElemDetCompTipo.elem_det_comp_tipo_id
     	and bilElemDetCompTipo.elem_det_comp_tipo_id = id_comp; --adeguamento

     end if;


     stanziamentoPrev:= stanziamentoPrev-deltaMenoPrev;




     strMessaggio:='Stanziamento effettivo elem_id='||bilElemId||'.';
     case
--          when bilFaseOperativa=FASE_BIL_PROV then 15.01.2021 Sofia Jira SIAC_7958
-- 15.01.2021 Sofia Jira SIAC_7958
          when bilFaseOperativa=FASE_BIL_PROV and enteProprietarioId!=2 then

 --
   		     if stanziamentoPrev>stanziamento-deltaMenoGest then
                    stanziamentoEff:=stanziamento-deltaMenoGest;
               else
                    stanziamentoEff:=stanziamentoPrev;
               end if;

               if anno_comp_in=annoBilancio then
--             if stanziamentoPrevCassa>stanziamentoCassa then 26072016 Sofia JIRA-SIAC-3887
                    if stanziamentoPrevCassa>stanziamentoCassa-deltaMenoGestCassa then
                    /* 04.07.2016 Sofia ID-INC000001114035
        	          stanziamentoEffCassa:=stanziamentoCassa; **/
                         stanziamentoEffCassa:=stanziamentoCassa-deltaMenoGestCassa;
                    else
                         stanziamentoEffCassa:=stanziamentoPrevCassa;
                    end if;
               end if;
     else

   	     stanziamentoEff:=stanziamentoPrev;
          if anno_comp_in=annoBilancio then
               stanziamentoEffCassa:=stanziamentoPrevCassa;
          end if;

     end case;

  /* 04.07.2016 Sofia ID-INC000001114035
 -- stanziamentoEff abbattutto dai 'delta-gestione'
 stanziamentoEff:=stanziamentoEff-deltaMenoGest;
 if anno_comp_in = annoBilancio then
  stanziamentoEffCassa:=stanziamentoEffCassa-deltaMenoGestCassa;
 end if; */



     elemId:=bilElemId;
     annoCompetenza:=anno_comp_in;
     stanzEffettivo:=stanziamentoEff;
     if anno_comp_in = annoBilancio then
     stanzEffettivoCassa:=stanziamentoEffCassa;
     end if;
     if stanzMassimoImpegnabile is not null then
        	massimoImpegnabile:=stanzMassimoImpegnabile;
     end if;

     return next;


     exception
         when RAISE_EXCEPTION THEN
             RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
             return;
     	when no_data_found then
     		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
             return;
     	when others  THEN
      		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
             return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
ALTER FUNCTION siac.fnc_siac_stanz_effettivo_up_anno 
               ( id_in integer,anno_comp_in varchar, ente_prop_in integer,bil_id_in integer,anno_in varchar,ele_code_in varchar, ele_code2_in varchar,ele_code3_in varchar) OWNER TO siac;
ALTER FUNCTION siac.fnc_siac_stanz_effettivo_up_anno_comp (id_in integer, id_comp integer, anno_comp_in varchar)
  OWNER TO siac;
-- 19.01.2021 Sofia jira SIAC-7958 - fine


--SIAC-7974 - Maurizio - INIZIO

INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  verificauo,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'OP-REP-ReportVariazioniBilancio-2021',
'Sezione report variazioni bilancio',
a.azione_tipo_id,b.gruppo_azioni_id,
'/../siacrepapp/azioneRichiestaContentOnly.do',
FALSE,
now(),
a.ente_proprietario_id,
'admin'
 from siac_d_azione_tipo a, siac_d_gruppo_azioni b
where
b.ente_proprietario_id=A.ente_proprietario_id
and
a.azione_tipo_code='AZIONE_SECONDARIA'
and b.gruppo_azioni_code='REPORTISTICA' and
not exists (select 1 from siac_t_azione z where z.azione_code='OP-REP-ReportVariazioniBilancio-2021'
and z.ente_proprietario_id=a.ente_proprietario_id);


insert into siac_r_ruolo_op_azione
(
  ruolo_op_id,
  azione_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  data_cancellazione,
  login_operazione
)
select 
rop.ruolo_op_id,
a0.azione_id,
now(),
null,
a0.ente_proprietario_id,
null,
'admin' 
from siac_t_azione a0,
(select ra.ruolo_op_id from siac_t_azione a, 
siac_r_ruolo_op_azione ra
where ra.azione_id=a.azione_id
and a.azione_code='OP-GESC004-ricVar'
and ra.data_cancellazione is NULL
and ra.validita_fine IS NULL
) rop
where a0.azione_code = 'OP-REP-ReportVariazioniBilancio-2021'
and not exists (
select 1 from siac_r_ruolo_op_azione ra0
where ra0.azione_id=a0.azione_id
and ra0.ruolo_op_id=rop.ruolo_op_id);

--SIAC-7974 - Maurizio - FINE

--SIAC-7838 INIZIO
select * from fnc_dba_add_column_params('siac_t_movgest_ts_det_mod','mtdm_aggiudicazione_senza_sog','boolean');

CREATE TABLE IF NOT EXISTS siac_d_modifica_tipo_applicazione (
  mod_tipo_appl_id SERIAL,
  mod_tipo_appl_code VARCHAR(200) NOT NULL,
  mod_tipo_appl_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_modifica_tipo_applicazione PRIMARY KEY(mod_tipo_appl_id),
  CONSTRAINT siac_t_ente_proprietario_siac_d_modifica_tipo_applicazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);


select fnc_dba_create_index(
'siac_d_modifica_tipo_applicazione'::text,
  'idx_siac_d_modifica_tipo_appl_1'::text,
  'mod_tipo_appl_code COLLATE pg_catalog."default", validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

select fnc_dba_create_index(
'siac_d_modifica_tipo_applicazione'::text,
  'siac_d_modifica_tipo_applicazione_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);

insert into siac_d_modifica_tipo_applicazione
(mod_tipo_appl_code,mod_tipo_appl_desc  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tmp.code, tmp.descr, to_timestamp('01/01/2020','dd/mm/yyyy'),a.ente_proprietario_id,'SIAC-7838'
from siac.siac_t_ente_proprietario a
CROSS JOIN (VALUES ('GEN'  ,'Generico'), ('ROR'  ,'ROR'), ('AGG-RID'  ,'Aggiudicazione-Riduzione'))as tmp (code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_modifica_tipo_applicazione ta
	WHERE ta.ente_proprietario_id = a.ente_proprietario_id
	AND ta.mod_tipo_appl_code = tmp.code
	AND ta.data_cancellazione IS NULL
);
  
  
  
CREATE TABLE IF NOT EXISTS siac_r_modifica_tipo_applicazione (
  mod_tipo_r_tipo_appl_id SERIAL,
  mod_tipo_id INTEGER NOT NULL,
  mod_tipo_appl_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_r_modifica_tipo_applicazione PRIMARY KEY(mod_tipo_r_tipo_appl_id),
  CONSTRAINT siac_d_modifica_tipo_tipo_applicazione_siac_r_modifica_tipo_applicazione FOREIGN KEY (mod_tipo_appl_id)
    REFERENCES siac.siac_d_modifica_tipo_applicazione(mod_tipo_appl_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_siac_r_modifica_tipo_applicazione FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_modifica_tipo_tipo_applicazione_siac_r_modifica_tipo_applicazione FOREIGN KEY (mod_tipo_id)
    REFERENCES siac.siac_d_modifica_tipo(mod_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

select fnc_dba_create_index(
'siac_r_modifica_tipo_applicazione'::text,
  'idx_siac_r_modifica_tipo_applicazione_1'::text,
  'mod_tipo_id, mod_tipo_appl_id, validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);

select fnc_dba_create_index(
'siac_r_modifica_tipo_applicazione'::text,
  'siac_r_modifica_tipo_applicazione_fk_modifica_tipo_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);

insert into  siac_r_modifica_tipo_applicazione
(mod_tipo_id,mod_tipo_appl_id  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tipo.mod_tipo_id, applicazione.mod_tipo_appl_id, to_timestamp('01/01/2020','dd/mm/yyyy'), ente.ente_proprietario_id, 'SIAC-7838' 
from siac_t_ente_proprietario ente 
join siac_d_modifica_tipo tipo on tipo.ente_proprietario_id  = ente.ente_proprietario_id 
join siac_d_modifica_tipo_applicazione applicazione on (applicazione.ente_proprietario_id  = ente.ente_proprietario_id  and applicazione.ente_proprietario_id = ente.ente_proprietario_id)
where tipo.data_cancellazione  is null and applicazione .data_cancellazione  is null
and tipo.mod_tipo_code not like 'AGG' and applicazione.mod_tipo_appl_code='GEN'
and not exists(
	select 1 from siac_r_modifica_tipo_applicazione r_app
	where r_app.ente_proprietario_id = ente.ente_proprietario_id 
	and r_app.mod_tipo_id  = tipo.mod_tipo_id 
	and r_app.mod_tipo_appl_id  = applicazione.mod_tipo_appl_id 
	and r_app.data_cancellazione is null
);


insert into  siac_r_modifica_tipo_applicazione
(mod_tipo_id,mod_tipo_appl_id  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tipo.mod_tipo_id, applicazione.mod_tipo_appl_id, to_timestamp('01/01/2020','dd/mm/yyyy'), ente.ente_proprietario_id, 'SIAC-7838' 
from siac_t_ente_proprietario ente 
join siac_d_modifica_tipo tipo on tipo.ente_proprietario_id  = ente.ente_proprietario_id 
join siac_d_modifica_tipo_applicazione applicazione on (applicazione.ente_proprietario_id  = ente.ente_proprietario_id  and applicazione.ente_proprietario_id = ente.ente_proprietario_id)
where tipo.data_cancellazione  is null and applicazione .data_cancellazione  is null
and tipo.mod_tipo_code not like 'AGG' and applicazione.mod_tipo_appl_code='ROR'
and (upper(mod_tipo_desc) like 'ROR%' or upper(mod_tipo_desc) like 'ECO%')
and not exists(
	select 1 from siac_r_modifica_tipo_applicazione r_app
	where r_app.ente_proprietario_id = ente.ente_proprietario_id 
	and r_app.mod_tipo_id  = tipo.mod_tipo_id 
	and r_app.mod_tipo_appl_id  = applicazione.mod_tipo_appl_id 
	and r_app.data_cancellazione is null
);



insert into  siac_r_modifica_tipo_applicazione
(mod_tipo_id,mod_tipo_appl_id  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tipo.mod_tipo_id, applicazione.mod_tipo_appl_id, to_timestamp('01/01/2020','dd/mm/yyyy'), ente.ente_proprietario_id, 'SIAC-7838' 
from siac_t_ente_proprietario ente 
join siac_d_modifica_tipo tipo on tipo.ente_proprietario_id  = ente.ente_proprietario_id 
join siac_d_modifica_tipo_applicazione applicazione on (applicazione.ente_proprietario_id  = ente.ente_proprietario_id  and applicazione.ente_proprietario_id = ente.ente_proprietario_id)
where tipo.data_cancellazione  is null and applicazione .data_cancellazione  is null
and tipo.mod_tipo_code='AGG' and applicazione.mod_tipo_appl_code='AGG-RID'
and not exists(
	select 1 from siac_r_modifica_tipo_applicazione r_app
	where r_app.ente_proprietario_id = ente.ente_proprietario_id 
	and r_app.mod_tipo_id  = tipo.mod_tipo_id 
	and r_app.mod_tipo_appl_id  = applicazione.mod_tipo_appl_id 
	and r_app.data_cancellazione is null
);
  

--SIAC-7838 FINE

--SIAC-7933 - Maurizio - INIZIO

DROP FUNCTION if exists siac."fnc_lancio_BILR011_anni_precedenti_gestione"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);

CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR011_anni_precedenti_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  imp_colonna_h numeric,
  imp_colonna_d numeric
) AS
$body$
DECLARE

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della fnc_lancio_BILR171_anni_precedenti che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
        Richiama la BILR011_allegato_fpv_previsione_con_dati_gestione con parametri 
        diversi a seconda dell'anno di prospetto.
		Poiche' il report BILR171 viene eliminato per l'anno 2018 la funzione 
        fnc_lancio_BILR171_anni_precedenti rimane per gli anni precedenti.
*/

/*
	21/12/2020: SIAC-7933.
    	Questa funzione serve per calcolare i dati della colonna H dell'anno precedente
        quando l'anno di prospetto e' maggiore di quello del bilancio.
        In questo caso tale colonna diventa la colonna A del report.
    	La funzione e' stata rivista in quanto prima la colonna H dell'anno precedente 
        del report era calcolata usando solo i dati della Gestione.
        Invece ora viene calcolata sommando i dati della Gestione delle colonne
        A e B e quelli di Previsione delle colonne D, E, F e G dell'anno precedente 
        cosi' come avviene anche quando l'anno di prospetto e' uguale all'anno del Bilancio. 
        Per questo motivo le query sono state riviste e viene richiamata anche la funzione
        "BILR011_Allegato_B_Fondo_Pluriennale_vincolato" che prende i dati di Previsione.
        
        Inoltre la funzione restituisce anche l'importo della colonna D anno precedente,
        in quanto e' stato richiesto che quando l'anno prospetto e' maggiore di quello
        del bilancio tale importo sia sommato alla colonna B.        

*/

	--anno prospetto = anno bilancio + 1
if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
 /*
  select missione_code, programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code;*/  
  
  	--  FPV = dati di Previsione, anno_prec = dati di gestione
  with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-(anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g) imp_colonna_h,
    FPV.spese_da_impeg_anno1_d imp_colonna_d
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro;
 
	--anno prospetto = anno bilancio + 2
elsif p_anno_prospetto::integer = (p_anno::integer)+2 then
-- quando l'anno prospette e' anno bilancio + 2, devo calcolare l'importo della 
-- colonna H del report con anno -2 perche' diventa la colonna A dell'anno -1.
  return query
   select anno_meno2.missione_code, anno_meno2.programma_code,
   (anno_meno2.importo_colonna_h -
    (anno_meno1.importo_avanzo+anno_meno1.spese_impegnate+ 
    anno_meno2.spese_da_impeg_anno1_d) + --devo aggiungere anche la colonna_B.
    anno_meno1.spese_da_impeg_anno1_d + anno_meno1.spese_da_impeg_anno2_e +
   	anno_meno1.spese_da_impeg_anni_succ_f + anno_meno1.spese_da_impeg_non_def_g) imp_colonna_h,
    anno_meno1.spese_da_impeg_anno1_d imp_colonna_d
  from (
  	--  FPV = dati di Previsione, anno_prec = dati di gestione, Anno prospetto -2.
  with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-2)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-2)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-
    (anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g ) importo_colonna_h,
    anno_prec.importo_avanzo, anno_prec.spese_impegnate, FPV.spese_da_impeg_anno1_d
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro) anno_meno2,
 ( --  FPV = dati di Previsione, anno_prec = dati di gestione. Anno prospetto -1.
 	with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-
    (anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g) importo_colonna_h,
    FPV.spese_da_impeg_anno1_d, FPV.spese_da_impeg_anno2_e,
    FPV.spese_da_impeg_anni_succ_f, FPV.spese_da_impeg_non_def_g,
    anno_prec.spese_impegnate, anno_prec.importo_avanzo
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro) anno_meno1
where anno_meno2.missione_code = anno_meno1.missione_code
  and   anno_meno2.programma_code = anno_meno1.programma_code;
  
  /*
    select a.missione_code, a.programma_code,
    (a.importo_colonna_h-b.importo_colonna_h) as imp_colonna_h
  from (
  select missione_code, 
         programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  )
  group by missione_code, programma_code
  ) a, 
  (select missione_code, programma_code, 
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code;*/

end if;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-7933 - Maurizio - FINE

--SIAC-7762 - Maurizio - INIZIO

update siac_t_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-7762',
    repimp_desc='H) Utilizzo avanzo di amministrazione per spese correnti e per rimborso prestiti'
where repimp_codice= 'ava_amm_s_c'
	and repimp_id in (select b.repimp_id
                from siac_t_report a,
                siac_t_report_importi b,
                siac_r_report_importi c,
                siac_t_bil d,
                siac_t_periodo e
                where a.rep_id=c.rep_id
                and b.repimp_id=c.repimp_id
                and b.bil_id=d.bil_id
                and d.periodo_id=e.periodo_id
                and a.rep_codice='BILR142'
                and e.anno in('2020','2021')
                and b.repimp_codice= 'ava_amm_s_c'
                and a.data_cancellazione IS NULL
                and b.data_cancellazione IS NULL
                and c.data_cancellazione IS NULL )
     and login_operazione not like '%SIAC-7762';   


update siac_t_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-7762',
    repimp_desc='H) Utilizzo avanzo di amministrazione per spese correnti e per rimborso prestiti - di cui per estinzione anticipata di prestiti'
where repimp_codice= 'di_cui_ava_amm_s_c'
	and repimp_id in (select b.repimp_id
                  from siac_t_report a,
                  siac_t_report_importi b,
                  siac_r_report_importi c,
                  siac_t_bil d,
                  siac_t_periodo e
                  where a.rep_id=c.rep_id
                  and b.repimp_id=c.repimp_id
                  and b.bil_id=d.bil_id
                  and d.periodo_id=e.periodo_id
                  and a.rep_codice='BILR142'
                  and e.anno in('2020','2021')
                  and b.repimp_codice= 'di_cui_ava_amm_s_c'
                  and a.data_cancellazione IS NULL
                  and b.data_cancellazione IS NULL
                  and c.data_cancellazione IS NULL )
		and login_operazione not like '%SIAC-7762';                      

delete from bko_t_report_importi
where rep_codice ='BILR142';

insert into bko_t_report_importi(
	rep_codice, rep_desc,  repimp_codice ,  repimp_desc,
  repimp_importo,  repimp_modificabile,  repimp_progr_riga, posizione_stampa)
select DISTINCT a.rep_codice, a.rep_desc, b.repimp_codice, b.repimp_desc,
	0, b.repimp_modificabile, b.repimp_progr_riga, c.posizione_stampa
from siac_t_report a,
	siac_t_report_importi b,
    siac_r_report_importi c,
    siac_t_bil d,
    siac_t_periodo e  
where a.rep_id=c.rep_id
	and b.repimp_id =c.repimp_id
    and b.bil_id=d.bil_id
    and d.periodo_id=e.periodo_id
    and a.rep_codice in('BILR142')
    and e.anno='2020'
    and a.data_cancellazione IS NULL 
    and b.data_cancellazione IS NULL 
    and c.data_cancellazione IS NULL
    and not exists (select 1
				    from bko_t_report_importi
                    where rep_codice = a.rep_codice
                    and repimp_codice=b.repimp_codice); 

--SIAC-7762 - Maurizio - FINE
                    
-- SIAC-8025
ALTER TABLE siac.siac_t_indirizzo_soggetto_mod ALTER COLUMN via_tipo_id DROP NOT NULL;
-- SIAC-8025


-- 17.02.2021 Sofia SIAC-8023 - inizio
drop VIEW if exists siac.siac_v_dwh_provvisori_cassa;
CREATE OR REPLACE VIEW siac.siac_v_dwh_provvisori_cassa(
    ente_proprietario_id,
    provc_tipo_code,
    provc_tipo_desc,
    provc_anno,
    provc_numero,
    provc_causale,
    provc_subcausale,
    provc_denom_soggetto,
    provc_importo,
    provc_data_annullamento,
    provc_data_convalida,
    provc_data_emissione,
    provc_data_regolarizzazione,
    tipo_sac,
    codice_sac,
    provc_data_trasmissione,
    provc_accettato,
    provc_note,
    provc_conto_evidenza, -- 28.05.2018 Sofia siac-6126
    provc_descrizione_conto_evidenza, -- 28.05.2018 Sofia siac-6126
    -- 17.02.2021 Sofia 	SIAC-8023
    provc_data_invio_servizio, 
    provc_data_rifiuto_err_attrib
    )
AS
WITH provv AS(
  SELECT a.ente_proprietario_id,
         b.provc_tipo_code,
         b.provc_tipo_desc,
         a.provc_anno,
         a.provc_numero,
         a.provc_causale,
         a.provc_subcausale,
         a.provc_denom_soggetto,
         a.provc_importo,
         a.provc_data_annullamento,
         a.provc_data_convalida,
         a.provc_data_emissione,
         a.provc_data_regolarizzazione,
         a.provc_id,
         a.provc_data_trasmissione,
         a.provc_accettato,
         a.provc_note,
         -- 17.02.2021 Sofia 	SIAC-8023
         a.provc_data_invio_servizio  provc_data_invio_servizio, 
         a.provc_data_rifiuto_errata_attribuzione provc_data_rifiuto_err_attrib
  FROM siac_t_prov_cassa a,
       siac_d_prov_cassa_tipo b
  WHERE a.provc_tipo_id = b.provc_tipo_id AND
        a.data_cancellazione IS NULL), sac AS(
    SELECT n.classif_code AS codice_sac,
           n.classif_desc AS descrizione_cdc,
           o.classif_tipo_code AS tipo_sac,
           m.provc_id
    FROM siac_r_prov_cassa_class m,
         siac_t_class n,
         siac_d_class_tipo o
    WHERE n.classif_id = m.classif_id AND
          o.classif_tipo_id = n.classif_tipo_id AND
          (o.classif_tipo_code::text = ANY (ARRAY [ 'CDC'::text, 'CDR'::text ]))
  AND
          now() >= m.validita_inizio AND
          now() <= COALESCE(m.validita_fine::timestamp with time zone, now())
  AND
          m.data_cancellazione IS NULL),
  provc_conto_evidenza as -- 28.05.2018 Sofia siac-6126
  (
      select query.provc_id,
           query.oil_ricevuta_id,
           query.conto_evidenza,
           query.descrizione_conto_evidenza
  from
  (
  with
  rprov as
  (
  select *
  from siac_r_prov_cassa_oil_ricevuta r
  where r.data_cancellazione is null
  and   r.validita_fine is null
  ),
  ricevuta as
  (
  select oil.*
  from siac_t_oil_ricevuta oil,siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='P'
  and   oil.oil_ricevuta_tipo_id=tipo.oil_ricevuta_tipo_id
  and   oil.oil_ricevuta_errore_id is null
  and   oil.data_cancellazione is null
  and   oil.validita_fine is null
  ),
  giocassa as
  (
  select
         gio.flusso_elab_mif_id,
         gio.mif_t_giornalecassa_id,
         gio.conto_evidenza,
         gio.descrizione_conto_evidenza
  from mif_t_giornalecassa gio
  where gio.tipo_documento in ( 'SOSPESO ENTRATA','SOSPESO USCITA')
  and   gio.data_cancellazione is null
  and   gio.validita_fine is null
  )
  select rprov.provc_id,
         rprov.oil_ricevuta_id, ricevuta.oil_ricevuta_tipo_id,
         ricevuta.oil_progr_ricevuta_id, ricevuta.flusso_elab_mif_id,
         giocassa.conto_evidenza, giocassa.descrizione_conto_evidenza
  from  rprov, ricevuta, giocassa
  where ricevuta.oil_ricevuta_id=rprov.oil_ricevuta_id
  and   giocassa.flusso_elab_mif_id=ricevuta.flusso_elab_mif_id
  and   giocassa.mif_t_giornalecassa_id=ricevuta.oil_progr_ricevuta_id
  ) query, siac_d_oil_ricevuta_tipo tipo
  where tipo.oil_ricevuta_tipo_code='P'
  and   tipo.oil_ricevuta_tipo_id=query.oil_ricevuta_tipo_id
  )
   SELECT provv.ente_proprietario_id,
             provv.provc_tipo_code,
             provv.provc_tipo_desc,
             provv.provc_anno,
             provv.provc_numero,
             provv.provc_causale,
             provv.provc_subcausale,
             provv.provc_denom_soggetto,
             provv.provc_importo,
             provv.provc_data_annullamento,
             provv.provc_data_convalida,
             provv.provc_data_emissione,
             provv.provc_data_regolarizzazione,
             sac.tipo_sac,
             sac.codice_sac,
             provv.provc_data_trasmissione,
             provv.provc_accettato,
             provv.provc_note,
             provc_conto_evidenza.conto_evidenza, -- 28.05.2018 Sofia siac-6126
             provc_conto_evidenza.descrizione_conto_evidenza, -- 28.05.2018 Sofia siac-6126
             -- 17.02.2021 Sofia 	SIAC-8023
             provv.provc_data_invio_servizio, 
             provv.provc_data_rifiuto_err_attrib
      FROM provv
           LEFT JOIN sac ON sac.provc_id = provv.provc_id
           left join provc_conto_evidenza on (provv.provc_id=provc_conto_evidenza.provc_id) -- 28.05.2018 Sofia siac-6126
      ORDER BY provv.ente_proprietario_id;
	  
alter VIEW siac.siac_v_dwh_provvisori_cassa owner to siac;
-- 17.02.2021 Sofia SIAC-8023 - fine

-- 17.02.2021 Sofia SIAC-7886 - inizio
drop VIEW if exists siac.siac_v_dwh_variazione_bilancio;
CREATE OR REPLACE VIEW siac.siac_v_dwh_variazione_bilancio(
    bil_anno,
    numero_variazione,
    desc_variazione,
    cod_stato_variazione,
    desc_stato_variazione,
    cod_tipo_variazione,
    desc_tipo_variazione,
    anno_atto_amministrativo,
    numero_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_capitolo,
    cod_articolo,
    cod_ueb,
    cod_tipo_capitolo,
    importo,
    tipo_importo,
    anno_variazione,
    attoamm_id,
    ente_proprietario_id,
    cod_sac,
    desc_sac,
    tipo_sac,
    data_definizione, -- 23.06.2020 Sofia SIAC-7684
    -- SIAC-7886 17.02.2021 Sofua
    data_apertura_proposta,
    data_chiusura_proposta,
    cod_sac_proposta,
    desc_sac_proposta,
    tipo_sac_proposta
    )
AS
select  tb.*
from
(
WITH
variaz AS
(
  SELECT p.anno AS bil_anno,
         e.variazione_num AS numero_variazione,
         e.variazione_desc AS desc_variazione,
         d.variazione_stato_tipo_code AS cod_stato_variazione,
         d.variazione_stato_tipo_desc AS desc_stato_variazione,
         f.variazione_tipo_code AS cod_tipo_variazione,
         f.variazione_tipo_desc AS desc_tipo_variazione,
         a.elem_code AS cod_capitolo,
         a.elem_code2 AS cod_articolo,
         a.elem_code3 AS cod_ueb,
         i.elem_tipo_code AS cod_tipo_capitolo,
         b.elem_det_importo AS importo,
         h.elem_det_tipo_desc AS tipo_importo,
         l.anno AS anno_variazione,
         c.attoamm_id,
         a.ente_proprietario_id,
         -- 23.06.2020 Sofia SIAC-7684
         (case when d.variazione_stato_tipo_code='D' then c.validita_inizio
              else null end ) data_definizione,
         -- SIAC-7886 17.02.2021 Sofia
         e.data_apertura_proposta,
         e.data_chiusura_proposta,
         e.classif_id
  FROM siac_t_bil_elem a,
       siac_t_bil_elem_det_var b,
       siac_r_variazione_stato c,
       siac_d_variazione_stato d,
       siac_t_variazione e,
       siac_d_variazione_tipo f,
       siac_t_bil g,
       siac_d_bil_elem_det_tipo h,
       siac_d_bil_elem_tipo i,
       siac_t_periodo l,
       siac_t_periodo p
  WHERE a.elem_id = b.elem_id AND
        c.variazione_stato_id = b.variazione_stato_id AND
        c.variazione_stato_tipo_id = d.variazione_stato_tipo_id AND
        c.variazione_id = e.variazione_id AND
        f.variazione_tipo_id = e.variazione_tipo_id AND
        b.data_cancellazione IS NULL AND
        a.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        g.bil_id = e.bil_id AND
        h.elem_det_tipo_id = b.elem_det_tipo_id AND
        i.elem_tipo_id = a.elem_tipo_id AND
        l.periodo_id = b.periodo_id
        AND p.periodo_id = g.periodo_id
),
attoamm as
(
    select
    m.attoamm_id,
    m.attoamm_anno AS anno_atto_amministrativo,
    m.attoamm_numero AS numero_atto_amministrativo,
    q.attoamm_tipo_code AS cod_tipo_atto_amministrativo
    from siac_t_atto_amm m,  siac_d_atto_amm_tipo q
    where
    q.attoamm_tipo_id = m.attoamm_tipo_id
    and
    m.data_cancellazione IS NULL AND
    q.data_cancellazione IS NULL
),
sac AS
(
    SELECT
     i.attoamm_id,
     l.classif_id,
     l.classif_code,
     l.classif_desc,
     m.classif_tipo_code
    FROM  siac_r_atto_amm_class i,
          siac_t_class l,
          siac_d_class_tipo m,
          siac_r_class_fam_tree n,
          siac_t_class_fam_tree o,
          siac_d_class_fam p
    WHERE i.classif_id = l.classif_id AND
          m.classif_tipo_id = l.classif_tipo_id AND
          n.classif_id = l.classif_id AND
          n.classif_fam_tree_id = o.classif_fam_tree_id AND
          o.classif_fam_id = p.classif_fam_id AND
          p.classif_fam_code::text = '00005'::text AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL
),
-- SIAC-7886 17.02.2021 Sofia
str_proposta as
(
select tipo.classif_tipo_code, c.classif_code ,c.classif_desc,c.classif_id
from siac_t_class c,siac_d_class_tipo tipo
where tipo.classif_tipo_code in ('CDC','CDR')
and   c.classif_tipo_Id=tipo.classif_tipo_id
and   c.data_cancellazione is null
)
SELECT
   variaz.bil_anno,
   variaz.numero_variazione,
   variaz.desc_variazione,
   variaz.cod_stato_variazione,
   variaz.desc_stato_variazione,
   variaz.cod_tipo_variazione,
   variaz.desc_tipo_variazione,
   attoamm.anno_atto_amministrativo,
   attoamm.numero_atto_amministrativo,
   attoamm.cod_tipo_atto_amministrativo,
   variaz.cod_capitolo,
   variaz.cod_articolo,
   variaz.cod_ueb,
   variaz.cod_tipo_capitolo,
   variaz.importo,
   variaz.tipo_importo,
   variaz.anno_variazione,
   variaz.attoamm_id,
   variaz.ente_proprietario_id,
   sac.classif_code AS cod_sac,
   sac.classif_desc AS desc_sac,
   sac.classif_tipo_code AS tipo_sac,
   variaz.data_definizione, -- 23.06.2020 Sofia SIAC-7684
    -- SIAC-7886 17.02.2021 Sofia
   variaz.data_apertura_proposta,
   variaz.data_chiusura_proposta,
   str_proposta.classif_code::varchar(200) cod_sac_proposta,
   str_proposta.classif_desc::varchar(500) desc_sac_proposta,
   str_proposta.classif_tipo_code::varchar(200) tipo_sac_proposta
FROM variaz
      left join attoamm on  variaz.attoamm_id = attoamm.attoamm_id
      LEFT JOIN sac ON variaz.attoamm_id = sac.attoamm_id
      -- SIAC-7886 17.02.2021 Sofia
      left join str_proposta on variaz.classif_id=str_proposta.classif_id
) tb
order by tb.ente_proprietario_id, tb.bil_anno, tb.numero_variazione;
alter VIEW siac.siac_v_dwh_variazione_bilancio owner to siac;
-- 17.02.2021 Sofia SIAC-7886 - fine

-- 17.02.2021 Sofia SIAC-7907 - inizio
drop VIEW if exists siac.siac_v_dwh_pdce;
CREATE OR REPLACE VIEW siac.siac_v_dwh_pdce (
    ente_proprietario_id,
    pdce_conto_code,
    pdce_conto_desc,
    pdce_ct_tipo_code,
    pdce_ct_tipo_desc,
    pdce_fam_code,
    pdce_fam_desc,
    classif_id,
    ambito_code,
    ambito_desc,
    livello,
    conto_foglia,
    -- 17.02.2021 Sofia SIAC-7907
    validita_inizio,
    validita_fine
    )
AS
SELECT tpc.ente_proprietario_id, tpc.pdce_conto_code, tpc.pdce_conto_desc,
    dpct.pdce_ct_tipo_code, dpct.pdce_ct_tipo_desc, dpf.pdce_fam_code,
    dpf.pdce_fam_desc, rpcc.classif_id, da.ambito_code, da.ambito_desc,
    tpc.livello, tabattr."boolean",
    -- 17.02.2021 Sofia SIAC-7907
    tpc.validita_inizio,
    tpc.validita_fine
FROM siac_t_pdce_conto tpc
   JOIN siac_d_pdce_conto_tipo dpct ON dpct.pdce_ct_tipo_id = tpc.pdce_ct_tipo_id
   JOIN siac_t_pdce_fam_tree tpft ON tpft.pdce_fam_tree_id = tpc.pdce_fam_tree_id
   JOIN siac_d_pdce_fam dpf ON dpf.pdce_fam_id = tpft.pdce_fam_id
   JOIN siac_d_ambito da ON da.ambito_id = dpf.ambito_id
   LEFT JOIN siac_r_pdce_conto_class rpcc ON rpcc.pdce_conto_id = tpc.pdce_conto_id
        AND rpcc.data_cancellazione IS NULL
        AND date_trunc('day'::text, now()) > rpcc.validita_inizio
        AND (date_trunc('day'::text, now()) < rpcc.validita_fine OR rpcc.validita_fine IS NULL)
   LEFT JOIN (SELECT pca.pdce_conto_id, pca."boolean"
              FROM  siac_r_pdce_conto_attr pca
              INNER JOIN siac_t_attr ta ON ta.attr_id = pca.attr_id
              WHERE ta.attr_code = 'pdce_conto_foglia'
              AND pca.data_cancellazione IS NULL
              AND ta.data_cancellazione IS NULL
              AND date_trunc('day'::text, now()) > pca.validita_inizio
              AND (date_trunc('day'::text, now()) < pca.validita_fine OR pca.validita_fine IS NULL)
             ) tabattr ON tabattr.pdce_conto_id = tpc.pdce_conto_id
WHERE tpc.data_cancellazione IS NULL
AND dpct.data_cancellazione IS NULL
AND tpft.data_cancellazione IS NULL
AND dpf.data_cancellazione IS NULL;
alter VIEW siac.siac_v_dwh_pdce owner to siac;
-- 17.02.2021 Sofia SIAC-7907 - fine

-- 19.02.2021 Sofia SIAC-8056 - inizio
drop VIEW if exists siac.siac_v_dwh_mod_impegno;
CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_impegno
(
    bil_anno,
    anno_impegno,
    num_impegno,
    cod_movgest_ts,
    desc_movgest_ts,
    tipo_movgest_ts,
    importo_modifica,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    ente_proprietario_id,
    desc_stato_modifica,
    flag_reimputazione,
    anno_reimputazione,
    elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
    validita_inizio,
    data_creazione -- 30.08.2018 Sofia jira-6292
    )
AS
WITH zz AS(
  SELECT l.anno,
         b.movgest_anno,
         b.movgest_numero,
         c.movgest_ts_code,
         c.movgest_ts_desc,
         dmtt.movgest_ts_tipo_code,
         a.movgest_ts_det_importo,
         d.mod_num,
         d.mod_desc,
         f.mod_stato_code,
         g.mod_tipo_code,
         g.mod_tipo_desc,
         h.attoamm_anno,
         h.attoamm_numero,
         daat.attoamm_tipo_code,
         a.ente_proprietario_id,
         h.attoamm_id,
         f.mod_stato_desc,
         a.mtdm_reimputazione_flag,
         -- 19.02.2021 Sofia SIAC-8056
         (case when a.mtdm_reimputazione_flag=true then a.mtdm_reimputazione_anno else null end) mtdm_reimputazione_anno,
         d.elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
         d.validita_inizio,
         d.data_creazione -- 30.08.2018 Sofia jira-6292
  FROM siac_t_movgest_ts_det_mod a
       JOIN siac_t_movgest_ts c ON c.movgest_ts_id = a.movgest_ts_id
       JOIN siac_t_movgest b ON b.movgest_id = c.movgest_id
       JOIN siac_d_movgest_tipo tt ON tt.movgest_tipo_id = b.movgest_tipo_id
       JOIN siac_r_modifica_stato e ON e.mod_stato_r_id = a.mod_stato_r_id
       JOIN siac_t_modifica d ON d.mod_id = e.mod_id
       JOIN siac_d_modifica_stato f ON f.mod_stato_id = e.mod_stato_id
       LEFT JOIN siac_d_modifica_tipo g ON g.mod_tipo_id = d.mod_tipo_id AND
         g.data_cancellazione IS NULL
       JOIN siac_t_atto_amm h ON h.attoamm_id = d.attoamm_id
       JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id =
         h.attoamm_tipo_id
       JOIN siac_t_bil i ON i.bil_id = b.bil_id
       JOIN siac_t_periodo l ON i.periodo_id = l.periodo_id
       JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id =
         c.movgest_ts_tipo_id
  WHERE tt.movgest_tipo_code::text = 'I' ::text AND
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        tt.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        e.data_cancellazione IS NULL AND
        f.data_cancellazione IS NULL AND
        h.data_cancellazione IS NULL AND
        daat.data_cancellazione IS NULL AND
        i.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        dmtt.data_cancellazione IS NULL), aa AS(
    SELECT i.attoamm_id,
           l.classif_id,
           l.classif_code,
           l.classif_desc,
           m.classif_tipo_code
    FROM siac_r_atto_amm_class i,
         siac_t_class l,
         siac_d_class_tipo m,
         siac_r_class_fam_tree n,
         siac_t_class_fam_tree o,
         siac_d_class_fam p
    WHERE i.classif_id = l.classif_id AND
          m.classif_tipo_id = l.classif_tipo_id AND
          n.classif_id = l.classif_id AND
          n.classif_fam_tree_id = o.classif_fam_tree_id AND
          o.classif_fam_id = p.classif_fam_id AND
          p.classif_fam_code::text = '00005' ::text AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL)
      SELECT zz.anno AS bil_anno,
             zz.movgest_anno AS anno_impegno,
             zz.movgest_numero AS num_impegno,
             zz.movgest_ts_code AS cod_movgest_ts,
             zz.movgest_ts_desc AS desc_movgest_ts,
             zz.movgest_ts_tipo_code AS tipo_movgest_ts,
             zz.movgest_ts_det_importo AS importo_modifica,
             zz.mod_num AS numero_modifica,
             zz.mod_desc AS desc_modifica,
             zz.mod_stato_code AS stato_modifica,
             zz.mod_tipo_code AS cod_tipo_modifica,
             zz.mod_tipo_desc AS desc_tipo_modifica,
             zz.attoamm_anno AS anno_atto_amministrativo,
             zz.attoamm_numero AS num_atto_amministrativo,
             zz.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
             aa.classif_code AS cod_sac,
             aa.classif_desc AS desc_sac,
             aa.classif_tipo_code AS tipo_sac,
             zz.ente_proprietario_id,
             zz.mod_stato_desc AS desc_stato_modifica,
             zz.mtdm_reimputazione_flag AS flag_reimputazione,
             zz.mtdm_reimputazione_anno AS anno_reimputazione,
             zz.elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
             zz.validita_inizio,
             zz.data_creazione -- 30.08.2018 Sofia jira-6292
      FROM zz
           LEFT JOIN aa ON zz.attoamm_id = aa.attoamm_id;
alter VIEW siac.siac_v_dwh_mod_impegno owner to siac;

drop VIEW if exists siac.siac_v_dwh_mod_accertamento;
CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_accertamento(
    bil_anno,
    anno_accertamento,
    num_accertamento,
    cod_movgest_ts,
    desc_movgest_ts,
    tipo_movgest_ts,
    importo_modifica,
    numero_modifica,
    desc_modifica,
    stato_modifica,
    cod_tipo_modifica,
    desc_tipo_modifica,
    anno_atto_amministrativo,
    num_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_sac,
    desc_sac,
    tipo_sac,
    ente_proprietario_id,
    desc_stato_modifica,
    flag_reimputazione,
    anno_reimputazione,
    elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
    validita_inizio,
    data_creazione -- 30.08.2018 Sofia jira-6292
    )
AS
WITH zz AS(
  SELECT l.anno,
         b.movgest_anno,
         b.movgest_numero,
         c.movgest_ts_code,
         c.movgest_ts_desc,
         dmtt.movgest_ts_tipo_code,
         a.movgest_ts_det_importo,
         d.mod_num,
         d.mod_desc,
         f.mod_stato_code,
         g.mod_tipo_code,
         g.mod_tipo_desc,
         h.attoamm_anno,
         h.attoamm_numero,
         daat.attoamm_tipo_code,
         a.ente_proprietario_id,
         h.attoamm_id,
         f.mod_stato_desc,
         a.mtdm_reimputazione_flag,
         d.validita_inizio,
         d.elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
         -- 19.02.2021 Sofia SIAC-8056
         (case when a.mtdm_reimputazione_flag=true then a.mtdm_reimputazione_anno else null end) mtdm_reimputazione_anno,
         d.data_creazione, -- 30.08.2018 Sofia jira-6292
         CASE
           WHEN dmtt.movgest_ts_tipo_code::text = 'S' ::text THEN (SELECT count(a1.*) AS count
                                                                   FROM siac_t_movgest_ts_det_mod a1
                                                                   JOIN siac_t_movgest_ts c1 ON c1.movgest_ts_id = a1.movgest_ts_id
                                                                   JOIN siac_t_movgest b1 ON b1.movgest_id = c1.movgest_id
                                                                   JOIN siac_d_movgest_tipo tt1 ON tt1.movgest_tipo_id = b1.movgest_tipo_id
                                                                   JOIN siac_r_modifica_stato e1 ON e1.mod_stato_r_id = a1.mod_stato_r_id
                                                                   JOIN siac_t_modifica d1 ON d1.mod_id = e1.mod_id
                                                                   JOIN siac_d_modifica_stato f1 ON f1.mod_stato_id = e1.mod_stato_id
                                                                   LEFT JOIN siac_d_modifica_tipo g1 ON g1.mod_tipo_id = d1.mod_tipo_id
                                                                                                     AND g1.data_cancellazione IS NULL
                                                                                                     AND g1.mod_tipo_code::text = g.mod_tipo_code::text
                                                                   JOIN siac_d_movgest_ts_tipo dmtt1 ON dmtt1.movgest_ts_tipo_id = c1.movgest_ts_tipo_id
                                                                   JOIN siac_t_bil i1 ON i1.bil_id = b1.bil_id
                                                                   JOIN siac_t_periodo l1 ON l1.periodo_id = i1.periodo_id
                                                                   WHERE tt1.movgest_tipo_code::text = 'A'::text
																   AND   dmtt1.movgest_ts_tipo_code::text = 'T'::text
																   AND   b1.movgest_anno = b.movgest_anno
																   AND   b1.movgest_numero = b.movgest_numero
																   AND d1.mod_num = d.mod_num
																   AND f1.mod_stato_code::text = f.mod_stato_code::text
																   AND a1.ente_proprietario_id = a.ente_proprietario_id
																   AND l1.anno::text = l.anno::text
																   AND a1.data_cancellazione IS NULL
																   AND b1.data_cancellazione IS NULL
																   AND c1.data_cancellazione IS NULL
																   AND tt1.data_cancellazione IS NULL
																   AND d1.data_cancellazione IS NULL
																   AND e1.data_cancellazione IS NULL
																   AND f1.data_cancellazione IS NULL
																   AND dmtt1.data_cancellazione IS NULL
																   AND i1.data_cancellazione IS NULL
																   AND l1.data_cancellazione IS NULL
         )
           ELSE 0::bigint
         END AS verifica_record_doppi
  FROM siac_t_movgest_ts_det_mod a
       JOIN siac_t_movgest_ts c ON c.movgest_ts_id = a.movgest_ts_id
       JOIN siac_t_movgest b ON b.movgest_id = c.movgest_id
       JOIN siac_d_movgest_tipo tt ON tt.movgest_tipo_id = b.movgest_tipo_id
       JOIN siac_r_modifica_stato e ON e.mod_stato_r_id = a.mod_stato_r_id
       JOIN siac_t_modifica d ON d.mod_id = e.mod_id
       JOIN siac_d_modifica_stato f ON f.mod_stato_id = e.mod_stato_id
       LEFT JOIN siac_d_modifica_tipo g ON g.mod_tipo_id = d.mod_tipo_id AND
         g.data_cancellazione IS NULL
       JOIN siac_t_atto_amm h ON h.attoamm_id = d.attoamm_id
       JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id =
         h.attoamm_tipo_id
       JOIN siac_t_bil i ON i.bil_id = b.bil_id
       JOIN siac_t_periodo l ON l.periodo_id = i.periodo_id
       JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id =
         c.movgest_ts_tipo_id
  WHERE tt.movgest_tipo_code::text = 'A' ::text AND
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        tt.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        e.data_cancellazione IS NULL AND
        f.data_cancellazione IS NULL AND
        h.data_cancellazione IS NULL AND
        daat.data_cancellazione IS NULL AND
        i.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        dmtt.data_cancellazione IS NULL), aa AS (
         SELECT i.attoamm_id,
                l.classif_id,
                l.classif_code,
                l.classif_desc,
                m.classif_tipo_code
         FROM siac_r_atto_amm_class i,
              siac_t_class l,
              siac_d_class_tipo m,
              siac_r_class_fam_tree n,
              siac_t_class_fam_tree o,
              siac_d_class_fam p
         WHERE i.classif_id = l.classif_id AND
               m.classif_tipo_id = l.classif_tipo_id AND
               n.classif_id = l.classif_id AND
               n.classif_fam_tree_id = o.classif_fam_tree_id AND
               o.classif_fam_id = p.classif_fam_id AND
               p.classif_fam_code::text = '00005' ::text AND
               i.data_cancellazione IS NULL AND
               l.data_cancellazione IS NULL AND
               m.data_cancellazione IS NULL AND
               n.data_cancellazione IS NULL AND
               o.data_cancellazione IS NULL AND
               p.data_cancellazione IS NULL)
 SELECT zz.anno AS bil_anno,
        zz.movgest_anno AS anno_accertamento,
        zz.movgest_numero AS num_accertamento,
        zz.movgest_ts_code AS cod_movgest_ts,
        zz.movgest_ts_desc AS desc_movgest_ts,
        zz.movgest_ts_tipo_code AS tipo_movgest_ts,
        zz.movgest_ts_det_importo AS importo_modifica,
        zz.mod_num AS numero_modifica,
        zz.mod_desc AS desc_modifica,
        zz.mod_stato_code AS stato_modifica,
        zz.mod_tipo_code AS cod_tipo_modifica,
        zz.mod_tipo_desc AS desc_tipo_modifica,
        zz.attoamm_anno AS anno_atto_amministrativo,
        zz.attoamm_numero AS num_atto_amministrativo,
        zz.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
        aa.classif_code AS cod_sac,
        aa.classif_desc AS desc_sac,
        aa.classif_tipo_code AS tipo_sac,
        zz.ente_proprietario_id,
        zz.mod_stato_desc AS desc_stato_modifica,
        zz.mtdm_reimputazione_flag AS flag_reimputazione,
        zz.mtdm_reimputazione_anno AS anno_reimputazione,
        zz.elab_ror_reanno, -- 19.02.2020 Sofia jira siac-7292
        zz.validita_inizio,
        zz.data_creazione -- 30.08.2018 Sofia jira-6292
 FROM zz
      LEFT JOIN aa ON zz.attoamm_id = aa.attoamm_id
 WHERE zz.verifica_record_doppi = 0;
 alter VIEW siac.siac_v_dwh_mod_accertamento owner to siac;
-- 19.02.2021 Sofia SIAC-8056 - fine

-- 24.05.2021 Sofia SIAC-8020 - inizio
drop VIEW if exists siac.siac_v_dwh_modifiche_associaz;
CREATE OR REPLACE VIEW siac.siac_v_dwh_modifiche_associaz
(
  bil_anno,
  acc_anno,
  acc_numero,
  acc_subnumero,
  acc_mod_numero,
  imp_anno,
  imp_numero,
  imp_subnumero,
  imp_mod_numero,
  importo_associaz,
  importo_residuo,
  ente_proprietario_id
) as
select
     per.anno::integer bil_anno,
     mov_acc.movgest_anno::integer acc_anno,
     mov_acc.movgest_numero::integer acc_nuumero,
     (case when tipo_ts_acc.movgest_ts_tipo_code='T' then 0 else ts_acc.movgest_ts_code::integer end )::integer acc_subnumero,
     modif_acc.mod_num::integer acc_mod_numero,
     mov_imp.movgest_anno::integer imp_anno,
     mov_imp.movgest_numero::integer imp_numero,
     (case when tipo_ts_imp.movgest_ts_tipo_code='T' then 0 else ts_imp.movgest_ts_code::integer end)::integer imp_subnumero,
     modif_imp.mod_num::integer imp_mod_numero,
     r.movgest_ts_det_mod_importo importo_associaz,
     r.movgest_ts_det_mod_impo_residuo importo_residuo,
     per.ente_proprietario_id
from siac_r_movgest_ts_det_mod r,
     siac_t_movgest_ts_det_mod dmod_acc,
     siac_t_movgest_ts ts_acc,siac_t_movgest mov_acc,
     siac_d_movgest_ts_tipo tipo_ts_acc,
     siac_r_modifica_stato rs_acc,siac_t_modifica modif_acc,
     siac_t_bil bil,siac_t_periodo per,
     siac_t_movgest_ts_det_mod dmod_imp,
     siac_t_movgest_ts ts_imp,siac_t_movgest mov_imp,
     siac_d_movgest_ts_tipo tipo_ts_imp,
     siac_r_modifica_stato rs_imp,siac_t_modifica modif_imp
where r.movgest_ts_det_mod_entrata_id=dmod_acc.movgest_ts_det_mod_id
and   ts_acc.movgest_ts_id=dmod_acc.movgest_ts_id
and   mov_acc.movgest_id=ts_acc.movgest_id
and   tipo_ts_acc.movgest_ts_tipo_id=ts_acc.movgest_ts_tipo_id
and   bil.bil_id=mov_acc.bil_id
and   per.periodo_id=bil.periodo_id
and   rs_acc.mod_stato_r_id=dmod_acc.mod_stato_r_id
and   modif_acc.mod_id=rs_acc.mod_id
and   dmod_imp.movgest_ts_det_mod_id=r.movgest_ts_det_mod_spesa_id
and   ts_imp.movgest_ts_id=dmod_imp.movgest_ts_id
and   mov_imp.movgest_id=ts_imp.movgest_id
and   tipo_ts_imp.movgest_ts_tipo_id=ts_imp.movgest_ts_tipo_id
and   rs_imp.mod_stato_r_id=dmod_imp.mod_stato_r_id
and   modif_imp.mod_id=rs_imp.mod_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   dmod_acc.data_cancellazione is null
and   dmod_acc.validita_fine is null
and   ts_acc.data_cancellazione is null
and   ts_acc.validita_fine is null
and   mov_acc.data_cancellazione is null
and   mov_acc.validita_fine is null
and   rs_acc.data_cancellazione is null
and   rs_acc.validita_fine is null
and   modif_acc.data_cancellazione is null
and   modif_acc.validita_fine is null
and   dmod_imp.data_cancellazione is null
and   dmod_imp.validita_fine is null
and   ts_imp.data_cancellazione is null
and   ts_imp.validita_fine is null
and   mov_imp.data_cancellazione is null
and   mov_imp.validita_fine is null
and   rs_imp.data_cancellazione is null
and   rs_imp.validita_fine is null
and   modif_imp.data_cancellazione is null
and   modif_imp.validita_fine is null;
alter VIEW siac.siac_v_dwh_modifiche_associaz owner to siac;

drop view if exists siac.siac_v_dwh_vincoli_movgest;
drop table if exists siac.siac_t_vincolo_pending;
CREATE TABLE if not exists siac.siac_t_vincolo_pending
(
  vincolo_pending_id serial,
  movgest_ts_r_id integer not null,
  bil_anno varchar(4) not null,
  importo_pending numeric not null default 0,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL  DEFAULT now(),
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  data_creazione  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  data_modifica  TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
  login_operazione varchar(200) not null,
  CONSTRAINT pk_siac_vincolo_pending PRIMARY KEY(vincolo_pending_id),
  CONSTRAINT siac_t_ente_proprietario_siac_t_vincolo_pend FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_r_movgest_ts_siac_t_vincolo_pend FOREIGN KEY (movgest_ts_r_id)
    REFERENCES siac.siac_r_movgest_ts(movgest_ts_r_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE	
);

CREATE INDEX idx_siac_t_vincolo_pending_fk_ente_proprietario_id ON siac.siac_t_vincolo_pending
  USING btree (ente_proprietario_id);
  
CREATE UNIQUE INDEX idx_siac_t_vincolo_pending_fk_siac_r_movgest_ts ON siac.siac_t_vincolo_pending
  USING btree (movgest_ts_r_id, validita_inizio, ente_proprietario_id)
  WHERE (data_cancellazione IS NULL);

alter table siac.siac_t_vincolo_pending owner to siac;

CREATE OR REPLACE VIEW siac.siac_v_dwh_vincoli_movgest
(
    ente_proprietario_id,
    bil_code,
    anno_bilancio,
    programma_code,
    programma_desc,
    tipo_da,
    anno_da,
    numero_da,
    tipo_a,
    anno_a,
    numero_a,
    importo_vincolo,
    tipo_avanzo_vincolo,
    -- 23.02.2021 Sofia Jira SIAC-8920
    movgest_ts_r_id,
    importo_pendig
    )
AS
-- 23.02.2021 Sofia Jira SIAC-8920
select query_vincoli.*,
       coalesce(pending.importo_pending,0) importo_pending

from
(
SELECT bil.ente_proprietario_id,
       bil.bil_code,
       periodo.anno AS anno_bilancio,
       progetto.programma_code, progetto.programma_desc,
       movtipoda.movgest_tipo_code AS tipo_da,  -- accertamento
       movda.movgest_anno AS anno_da,
       movda.movgest_numero AS numero_da,
       movtipoa.movgest_tipo_code AS tipo_a,    -- impegno
       mova.movgest_anno AS anno_a,
       mova.movgest_numero AS numero_a,
       a.movgest_ts_importo AS importo_vincolo,
       dat.avav_tipo_code AS tipo_avanzo_vincolo,
       -- 23.02.2021 Sofia Jira SIAC-8920
       a.movgest_ts_r_id
FROM siac_r_movgest_ts a
     JOIN siac_t_movgest_ts movtsa ON a.movgest_ts_b_id = movtsa.movgest_ts_id -- impegno
     JOIN siac_t_movgest mova ON mova.movgest_id = movtsa.movgest_id
     JOIN siac_d_movgest_tipo movtipoa ON movtipoa.movgest_tipo_id = mova.movgest_tipo_id
     JOIN siac_t_bil bil ON bil.bil_id = mova.bil_id
     JOIN siac_t_periodo periodo ON bil.periodo_id = periodo.periodo_id
     LEFT JOIN siac_t_movgest_ts movtsda ON  -- accertamento
               a.movgest_ts_a_id = movtsda.movgest_ts_id AND movtsda.data_cancellazione IS NULL
     LEFT JOIN siac_t_movgest movda ON
               movda.movgest_id = movtsda.movgest_id AND movda.data_cancellazione IS NULL
     LEFT JOIN siac_d_movgest_tipo movtipoda ON movtipoda.movgest_tipo_id = movda.movgest_tipo_id AND movtipoda.data_cancellazione IS NULL
     LEFT JOIN siac_r_movgest_ts_programma rprogramma ON
               rprogramma.movgest_ts_id = movtsa.movgest_ts_id AND rprogramma.data_cancellazione IS NULL
     LEFT JOIN siac_t_programma progetto ON
               progetto.programma_id = rprogramma.programma_id AND progetto.data_cancellazione IS NULL
     LEFT JOIN siac_t_avanzovincolo ta ON ta.avav_id = a.avav_id AND ta.data_cancellazione IS NULL
     LEFT JOIN siac_d_avanzovincolo_tipo dat ON dat.avav_tipo_id =   ta.avav_tipo_id AND dat.data_cancellazione IS NULL
WHERE a.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   movtsa.data_cancellazione IS NULL
AND   movtsa.validita_fine IS NULL
AND   mova.data_cancellazione IS NULL
AND   mova.validita_fine IS NULL
AND   movtipoa.data_cancellazione IS NULL
AND   movtipoa.validita_fine IS NULL
AND   bil.data_cancellazione IS NULL
AND   periodo.data_cancellazione IS NULL
--UNION -- 28.09.2018 Sofia Jira SIAC-6427 - inverto da, a per avere casi di accertamento (a) senza impegno (da)
UNION ALL -- 18.03.2019 Sofia Jira SIAC-6736
SELECT bil.ente_proprietario_id,
       bil.bil_code, periodo.anno AS anno_bilancio,
       progetto.programma_code, progetto.programma_desc,
       movtipoda.movgest_tipo_code AS tipo_da, -- impegno
       movda.movgest_anno AS anno_da,
       movda.movgest_numero AS numero_da,
       movtipoa.movgest_tipo_code AS tipo_a, -- accertamento
       mova.movgest_anno AS anno_a,
       mova.movgest_numero AS numero_a,
       a.movgest_ts_importo AS importo_vincolo,
       dat.avav_tipo_code AS tipo_avanzo_vincolo,
       -- 23.02.2021 Sofia Jira SIAC-8920
       a.movgest_ts_r_id
FROM siac_r_movgest_ts a
     JOIN siac_t_movgest_ts movtsa ON a.movgest_ts_a_id = movtsa.movgest_ts_id -- accertamento
     JOIN siac_t_movgest mova ON mova.movgest_id = movtsa.movgest_id
     JOIN siac_d_movgest_tipo movtipoa ON movtipoa.movgest_tipo_id = mova.movgest_tipo_id
     JOIN siac_t_bil bil ON bil.bil_id = mova.bil_id
     JOIN siac_t_periodo periodo ON bil.periodo_id = periodo.periodo_id
     LEFT JOIN siac_t_movgest_ts movtsda ON  -- impegno
               a.movgest_ts_b_id = movtsda.movgest_ts_id AND movtsda.data_cancellazione IS NULL
     LEFT JOIN siac_t_movgest movda ON
               movda.movgest_id = movtsda.movgest_id AND movda.data_cancellazione IS NULL
     LEFT JOIN siac_d_movgest_tipo movtipoda ON
               movtipoda.movgest_tipo_id = movda.movgest_tipo_id AND movtipoda.data_cancellazione IS NULL
     LEFT JOIN siac_r_movgest_ts_programma rprogramma ON
               rprogramma.movgest_ts_id = movtsa.movgest_ts_id AND rprogramma.data_cancellazione IS NULL
     LEFT JOIN siac_t_programma progetto ON
               progetto.programma_id = rprogramma.programma_id AND progetto.data_cancellazione IS NULL
     LEFT JOIN siac_t_avanzovincolo ta ON
               ta.avav_id = a.avav_id AND ta.data_cancellazione IS NULL
     LEFT JOIN siac_d_avanzovincolo_tipo dat ON
               dat.avav_tipo_id = ta.avav_tipo_id AND dat.data_cancellazione IS NULL
WHERE a.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   movtsa.data_cancellazione IS NULL
AND   movtsa.validita_fine IS NULL
AND   mova.data_cancellazione IS NULL
AND   mova.validita_fine IS NULL
AND   movtipoa.data_cancellazione IS NULL
AND   movtipoa.validita_fine IS NULL
AND   bil.data_cancellazione IS NULL
AND   periodo.data_cancellazione IS NULL
) query_vincoli
  left join siac_t_vincolo_pending pending on (pending.movgest_ts_r_id=query_vincoli.movgest_ts_r_id and pending.data_cancellazione is null);
alter view siac.siac_v_dwh_vincoli_movgest owner to siac;

drop FUNCTION if exists siac.fnc_siac_vincoli_pending_modifica
(
  p_mod_id integer,
  p_anno_bilancio integer,
  p_log_elab      varchar,
  p_login_operazione varchar,
  p_data_elaborazione timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_vincoli_pending_modifica
(
  p_mod_id integer,
  p_anno_bilancio integer,
  p_log_elab      varchar,
  p_login_operazione varchar,
  p_data_elaborazione timestamp
)
RETURNS varchar AS
$body$
DECLARE
 importo_mod_da_scalare numeric:=null;
 importo_delta_vincolo numeric:=null;
 ente_proprietario_id_in integer;
 rec record;

 esito varchar(10);

 strMessaggio varchar(1000) := null;
 h_result integer:=null;
 mod_id_in integer:=null;
cur CURSOR(par_in integer) FOR
select query.tipomod,
	   query.mod_id,
       query.movgest_ts_r_id,
       query.movgest_ts_importo,
       query.tipoordinamento
from
(
--avav
SELECT 'avav' tipomod,
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo - coalesce(pending.importo_pending,0) movgest_ts_importo,
case when n.avav_tipo_code='FPVSC' then 1
	 when n.avav_tipo_code='FPVCC' then 1 when n.avav_tipo_code='AAM' then 2 else 3 end
		as tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_t_avanzovincolo l, siac_d_movgest_ts_tipo m,siac_d_avanzovincolo_tipo n,
siac_r_movgest_ts i left join siac_t_vincolo_pending  pending on ( pending.movgest_ts_r_id=i.movgest_ts_r_id and pending.data_cancellazione is null )
WHERE
a.mod_id=par_in--mod_id_in
 and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and
c.mtdm_reimputazione_flag=true and
c.movgest_ts_det_importo<0 and
i.movgest_ts_b_id=f.movgest_ts_id and
i.movgest_ts_importo-coalesce(pending.importo_pending,0)>0 and -- con importo ancora da aggiornare
n.avav_tipo_id=l.avav_tipo_id and
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.avav_id=i.avav_id and
i.movgest_ts_importo-coalesce(pending.importo_pending,0)> -- vincoli impegno FPV/AAM che non sono gia' stati aggiornati da on-line su mod.spesa
(
select coalesce(sum(rvinc.importo_delta ),0) importo_delta
from siac_r_modifica_vincolo rvinc
where rvinc.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc.mod_id=a.mod_id
and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
) and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null and
n.data_cancellazione is null
union
-- imp acc
SELECT
'impacc' tipomod,
a.mod_id,
i.movgest_ts_r_id,
i.movgest_ts_importo-coalesce(pending.importo_pending,0) movgest_ts_importo,
4 tipoordinamento
FROM siac_t_modifica a,
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c,
siac_d_modifica_stato d,
siac_d_movgest_ts_det_tipo e, siac_t_movgest_ts f, siac_t_movgest g,siac_d_movgest_tipo h,
siac_t_movgest_ts l, siac_d_movgest_ts_tipo m,
siac_r_movgest_ts i left join siac_t_vincolo_pending  pending on ( pending.movgest_ts_r_id=i.movgest_ts_r_id and pending.data_cancellazione is null )
WHERE
a.mod_id=par_in--mod_id_in
and
a.mod_id = b.mod_id AND
c.mod_stato_r_id = b.mod_stato_r_id AND
d.mod_stato_id = b.mod_stato_id and
e.movgest_ts_det_tipo_id=c.movgest_ts_det_tipo_id and
f.movgest_ts_id=c.movgest_ts_id and
g.movgest_id=f.movgest_id and
d.mod_stato_code='V' and
h.movgest_tipo_id=g.movgest_tipo_id and
h.movgest_tipo_code='I' and
c.mtdm_reimputazione_flag=true and
c.movgest_ts_det_importo<0 and
i.movgest_ts_b_id=f.movgest_ts_id and
i.movgest_ts_importo-coalesce(pending.importo_pending,0)>0 and -- con importo ancora da aggiornare
now() BETWEEN i.validita_inizio and COALESCE(i.validita_fine,now()) and
now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now()) and
m.movgest_ts_tipo_id=f.movgest_ts_tipo_id and
l.movgest_ts_id=i.movgest_ts_a_id and
i.movgest_ts_importo-coalesce(pending.importo_pending,0)>
(
select coalesce(sum(vinc.importo_delta),0)
FROM
(
--  vincoli impegno accertamento che non sono gia' stati aggiornati da on-line su mod.spesa (A)
-- (A)
(
select coalesce(sum(rvinc.importo_delta),0) importo_delta
from siac_r_modifica_vincolo rvinc
where rvinc.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc.mod_id=a.mod_id
and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
)
union
(
select coalesce(sum(rvinc_mod.importo_delta),0) importo_delta
from   siac_r_modifica_vincolo rvinc_mod,
       siac_r_modifica_stato rs_mod_acc,
       siac_t_movgest_ts_det_mod det_mod_acc,
	   siac_r_movgest_ts_det_mod rmod_acc

where rvinc_mod.movgest_ts_r_id=i.movgest_ts_r_id
and   rvinc_mod.modvinc_tipo_operazione='INSERIMENTO'
and   rs_mod_acc.mod_id=rvinc_mod.mod_id
and   det_mod_acc.mod_stato_r_id=rs_mod_acc.mod_stato_r_id
and   det_mod_acc.movgest_ts_id=i.movgest_ts_a_id
and   det_mod_acc.mtdm_reimputazione_flag=true
and   det_mod_acc.movgest_ts_det_importo<0
and   rmod_acc.movgest_ts_det_mod_entrata_id=det_mod_acc.movgest_ts_det_mod_id
and   rmod_acc.movgest_ts_det_mod_spesa_id=c.movgest_ts_det_mod_id
and   rs_mod_acc.mod_stato_id=d.mod_stato_id
and   rvinc_mod.data_cancellazione is null
and   rvinc_mod.validita_fine is null
and   rs_mod_acc.data_cancellazione is null
and   rs_mod_acc.validita_fine is null
and   det_mod_acc.data_cancellazione is null
and   det_mod_acc.validita_fine is null
)
) vinc
) and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL and
e.data_cancellazione is null and
f.data_cancellazione is null and
g.data_cancellazione is null and
h.data_cancellazione is null and
i.data_cancellazione is null and
l.data_cancellazione is null and
m.data_cancellazione is null
) query
order
by 5 desc,2 asc,4 desc,
-- 21.07.2020 Sofia aggiunto ultimo ord. per coerenza rispetto codice java per calcolo
-- campo pending in elenco vincoli
3 desc;



begin

mod_id_in:=p_mod_id;

strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Inizio.';
--raise notice '%',strMessaggio;

esito:='oknodata'::varchar;

strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_mod_da_calare.';
--raise notice '%',strMessaggio;

-- calcolo importo della modifica  a parametro
SELECT abs(det_mod.movgest_ts_det_importo), det_mod.ente_proprietario_id
       into importo_mod_da_scalare, ente_proprietario_id_in
FROM siac_t_modifica mod,
     siac_r_modifica_stato rs_mod,
     siac_d_modifica_stato stato_mod,
     siac_t_movgest_ts ts,
     siac_t_movgest mov,
     siac_d_movgest_tipo tipo_mov,
     siac_t_movgest_ts_det_mod det_mod
WHERE mod.mod_id = mod_id_in
and   rs_mod.mod_id = mod.mod_id
and   det_mod.mod_stato_r_id = rs_mod.mod_stato_r_id
and   stato_mod.mod_stato_id = rs_mod.mod_stato_id
and   stato_mod.mod_stato_code = 'V'
and   ts.movgest_ts_id = det_mod.movgest_ts_id
and   mov.movgest_id = ts.movgest_id
and   tipo_mov.movgest_tipo_id = mov.movgest_tipo_id
and   tipo_mov.movgest_tipo_code = 'I'
and   det_mod.mtdm_reimputazione_flag=true
and   det_mod.movgest_ts_det_importo<0
and   now() BETWEEN rs_mod.validita_inizio
and   COALESCE(rs_mod.validita_fine, now())
and   mod.data_cancellazione IS NULL
and   rs_mod.data_cancellazione IS NULL
and   det_mod.data_cancellazione IS NULL
and   ts.data_cancellazione IS NULL
and   mov.data_cancellazione is null;

strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_mod_da_calare='||coalesce(importo_mod_da_scalare,0)::varchar||'.';
--raise notice '%',strMessaggio;

-- calcolo dei delta sui vincoli impegno adeguati con la modifica  a parametro
if importo_mod_da_scalare is not null and
   importo_mod_da_scalare>0 then
   strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su impegno.';
--   raise notice '%',strMessaggio;

   select sum(abs(rvinc.importo_delta)) into importo_delta_vincolo
   from siac_r_modifica_vincolo rvinc
   where rvinc.mod_id=mod_id_in
   and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
   and   rvinc.data_cancellazione is null
   and   rvinc.validita_fine is null;
   strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su imp ='||coalesce(importo_delta_vincolo,0)::varchar||'.';
--   raise notice '%',strMessaggio;
   if importo_delta_vincolo is not null then
   		importo_mod_da_scalare:=importo_mod_da_scalare-importo_delta_vincolo;
   end if;

end if;

-- calcolo dei delta sui vincoli di accertamento legati sia (vincolo o mod_entrata)
-- a impegno della modifica a parametro
if importo_mod_da_scalare is not null and
   importo_mod_da_scalare>0 then

  strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su accert.';
--  raise notice '%',strMessaggio;
  importo_delta_vincolo:=null;
  select sum(abs(rvinc_mod.importo_delta)) into importo_delta_vincolo
  from siac_r_modifica_stato rs_spesa,siac_d_modifica_stato stato_mod_spesa,
       siac_t_movgest_ts_det_mod det_mod_spesa,
       siac_r_movgest_ts_det_mod rmod_acc, siac_t_movgest_ts_det_mod det_mod_acc,
       siac_r_modifica_vincolo rvinc_mod,siac_r_movgest_ts rvinc,
       siac_r_modifica_stato rs_mod_acc
  where rs_spesa.mod_id=mod_id_in
  and   stato_mod_spesa.mod_stato_id=rs_spesa.mod_stato_id
  and   stato_mod_spesa.mod_Stato_code='V'
  and   det_mod_spesa.mod_stato_r_id=rs_spesa.mod_stato_r_id
  and   rmod_acc.movgest_ts_det_mod_spesa_id=det_mod_spesa.movgest_ts_det_mod_id
  and   det_mod_acc.movgest_ts_det_mod_id=rmod_acc.movgest_ts_det_mod_entrata_id
  and   det_mod_acc.mtdm_reimputazione_flag=true
  and   det_mod_acc.movgest_ts_det_importo<0
  and   rs_mod_acc.mod_stato_r_id=det_mod_acc.mod_stato_r_id
  and   rs_mod_acc.mod_Stato_id=stato_mod_spesa.mod_stato_id
  and   rvinc.movgest_ts_b_id=det_mod_spesa.movgest_ts_id
  and   rvinc.movgest_ts_a_id=det_mod_acc.movgest_ts_id
  and   rvinc_mod.movgest_ts_r_id=rvinc.movgest_ts_r_id
  and   rvinc_mod.mod_id=rs_mod_acc.mod_id
  and   rvinc_mod.modvinc_tipo_operazione='INSERIMENTO'
  and   rs_spesa.data_cancellazione is null
  and   rs_spesa.validita_fine is null
  and   det_mod_spesa.data_cancellazione is null
  and   det_mod_spesa.validita_fine is null
  and   rmod_acc.data_cancellazione is null
  and   rmod_acc.validita_fine is null
  and   det_mod_acc.data_cancellazione is null
  and   det_mod_acc.validita_fine is null
  and   rvinc_mod.data_cancellazione is null
  and   rvinc_mod.validita_fine is null
  and   rvinc.data_cancellazione is null
  and   rvinc.validita_fine is null
  and   rs_mod_acc.data_cancellazione is null
  and   rs_mod_acc.validita_fine is null;
  strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Lettura importo_delta_vincolo su accert='||coalesce(importo_delta_vincolo,0)::varchar||'.';
--  raise notice '%',strMessaggio;
  if importo_delta_vincolo is not null then
   		importo_mod_da_scalare:=importo_mod_da_scalare-importo_delta_vincolo;
   end if;
end if;


strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. importo_mod_da_scalare='||coalesce(importo_mod_da_scalare,0)::varchar||'.';
--raise notice '%',strMessaggio;

if importo_mod_da_scalare>0 then
strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Inizio loop di aggiornamento.';
--raise notice '%',strMessaggio;
for rec in cur(mod_id_in) loop
    if rec.movgest_ts_importo is not null and importo_mod_da_scalare>0 then
        if rec.movgest_ts_importo - importo_mod_da_scalare <=0 then

          esito:='ok';
          /*update siac_r_movgest_ts
          set movgest_ts_importo = 0,
              login_operazione = login_operazione_in,
              data_modifica = clock_timestamp()
          where movgest_ts_r_id = rec.movgest_ts_r_id;*/

          /*insert into siac_r_modifica_vincolo
          (mod_id, movgest_ts_r_id,
           modvinc_tipo_operazione, importo_delta, validita_inizio, ente_proprietario_id,
           login_operazione)
          values
          (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO', -rec.movgest_ts_importo,
           clock_timestamp(), ente_proprietario_id_in, login_operazione_in || ' - ' ||
            'fnc_siac_riccertamento_reimp');*/
          h_result:=null;
	      update siac_t_vincolo_pending pending
          set    importo_pending =pending.importo_pending+rec.movgest_ts_importo
          where pending.movgest_ts_r_id=rec.movgest_ts_r_id
          and   pending.data_cancellazione is null
          returning pending.movgest_ts_r_id into h_result;

--		  raise notice 'h_result=%', h_result;

          if h_result is null then
            insert into siac_t_vincolo_pending
            (
              ente_proprietario_id,
              bil_anno,
              movgest_ts_r_id,
              importo_pending,
              login_operazione
            )
            values
            (
              ente_proprietario_id_in,
              p_anno_bilancio::varchar,
              rec.movgest_ts_r_id,
              rec.movgest_ts_importo,
              p_login_operazione
            );
		  end if;

          importo_mod_da_scalare:= importo_mod_da_scalare - rec.movgest_ts_importo;

        elsif rec.movgest_ts_importo - importo_mod_da_scalare > 0 then
          esito:='ok';
/*          update siac_r_movgest_ts
          set    movgest_ts_importo = movgest_ts_importo - importo_mod_da_scalare,
                 login_operazione=login_operazione_in,
                 data_modifica=clock_timestamp()
          where movgest_ts_r_id=rec.movgest_ts_r_id;*/

/*          insert into siac_r_modifica_vincolo
          (mod_id,movgest_ts_r_id,modvinc_tipo_operazione,
           importo_delta,validita_inizio,ente_proprietario_id,login_operazione )
          values
          (mod_id_in, rec.movgest_ts_r_id, 'INSERIMENTO',-importo_mod_da_scalare,clock_timestamp(),
           ente_proprietario_id_in,login_operazione_in||' - '||'fnc_siac_riccertamento_reimp' );*/

          h_result:=null;
          update siac_t_vincolo_pending pending
          set    importo_pending =pending.importo_pending+importo_mod_da_scalare
          where pending.movgest_ts_r_id=rec.movgest_ts_r_id
          and   pending.data_cancellazione is null
          returning pending.movgest_ts_r_id into h_result;

--          raise notice 'h_result=%', h_result;

		  if h_result is null then
            insert into siac_t_vincolo_pending
            (
              ente_proprietario_id,
              bil_anno,
              movgest_ts_r_id,
              importo_pending,
              login_operazione
            )
            values
            (
              ente_proprietario_id_in,
              p_anno_bilancio::varchar,
              rec.movgest_ts_r_id,
              importo_mod_da_scalare,
              p_login_operazione
            );
          end if;

          importo_mod_da_scalare:= importo_mod_da_scalare - importo_mod_da_scalare;

        end if;
    end if;
end loop;

end if;

strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Fine esito='||esito||'.';
esito:='OK';
return esito;

EXCEPTION
WHEN others THEN
  esito:='ko';
  strMessaggio:='Aggiornamento pending vincoli da reimputazione - fnc_siac_vincoli_pending_modifica - mod_id='
             ||mod_id_in::varchar||'. Fine esito='||esito||'-  '||SQLSTATE||'-'||SQLERRM||'.';
--  RAISE NOTICE '%',strMessaggio;
RETURN esito;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
alter function siac.fnc_siac_vincoli_pending_modifica(integer,integer,varchar,varchar,timestamp) owner to siac;

drop function if exists siac.fnc_siac_vincoli_pending
(
  p_ente_proprietario_id integer,
  p_anno_bilancio integer,
  p_log_elab      varchar,
  p_movgest_anno  integer,
  p_movgest_numero integer,
  p_login_operazione varchar,
  p_data_elaborazione timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_vincoli_pending
(
  p_ente_proprietario_id integer,
  p_anno_bilancio integer,
  p_log_elab      varchar,
  p_movgest_anno  integer,
  p_movgest_numero integer,
  p_login_operazione varchar,
  p_data_elaborazione timestamp
)
RETURNS integer  AS
$body$
DECLARE
 params varchar(250):=null;

 p_esito integer:=-1;
 esito varchar(10):='OK';

 rec record;
 cur_modif CURSOR (c_movgest_anno integer,c_movgest_numero integer ) FOR
 select modif.mod_id, per.anno::integer anno_bilancio
 from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     siac_t_bil bil,siac_t_periodo per,
     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo ts_tipo,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
     siac_t_movgest_ts_det_mod dmod,
     siac_r_modifica_stato rs_mod,siac_d_modifica_stato stato_mod,
     siac_t_modifica modif
where tipo.ente_proprietario_id=p_ente_proprietario_id
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   bil.bil_id=mov.bil_id
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=p_anno_bilancio
and   ts.movgest_id=mov.movgest_id
and   ts_tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   ts_tipo.movgest_ts_tipo_code='T'
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   stato.movgest_stato_code!='A'
and   dmod.movgest_ts_id=ts.movgest_ts_id
and   rs_mod.mod_stato_r_id=dmod.mod_stato_r_id
and   stato_mod.mod_stato_id=rs_mod.mod_stato_id
and   stato_mod.mod_stato_code!='A'
and   modif.mod_id=rs_mod.mod_id
and   dmod.movgest_ts_det_importo<0
and   dmod.mtdm_reimputazione_flag=true
and   dmod.mtdm_reimputazione_anno is not null
and   modif.elab_ror_reanno=false
and   mov.movgest_anno::integer=coalesce(c_movgest_anno,mov.movgest_anno::integer)
and   mov.movgest_numero::integer=coalesce(c_movgest_numero,mov.movgest_numero::integer)
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   rs_mod.data_cancellazione is null
and   rs_mod.validita_fine is null
and   dmod.data_cancellazione is null
and   dmod.validita_fine is null
order by mov.movgest_anno::integer,mov.movgest_numero::integer,modif.mod_num::integer;


begin

p_esito:=-1;

params := p_anno_bilancio::varchar||' - '||p_ente_proprietario_id::varchar||' - '||p_data_elaborazione::varchar;
raise notice '%', 'fnc_siac_vincoli_pending - inizio - '||clock_timestamp()::varchar||'.';

if p_log_elab is not null then
 insert into  siac_dwh_log_elaborazioni
  (
    ente_proprietario_id,
    fnc_name ,
    fnc_parameters ,
    fnc_elaborazione_inizio ,
    fnc_user
  )
  values
  (
    p_ente_proprietario_id,
    'fnc_siac_vincoli_pending',
    params||' - fnc_siac_vincoli_pending - inizio - '||clock_timestamp()::varchar||'.',
    clock_timestamp(),
    p_log_elab
  );
end if;

raise notice '%', 'fnc_siac_vincoli_pending - inizio cancellazione  siac_dwh_vincoli_pending - '||clock_timestamp()::varchar||'.';
delete from siac_t_vincolo_pending pending
where pending.ente_proprietario_id=p_ente_proprietario_id
and   pending.bil_anno::integer=p_anno_bilancio;

if p_log_elab is not null then
 insert into  siac_dwh_log_elaborazioni
  (
    ente_proprietario_id,
    fnc_name ,
    fnc_parameters ,
    fnc_elaborazione_inizio ,
    fnc_user
  )
  values
  (
    p_ente_proprietario_id,
    'fnc_siac_vincoli_pending',
    params||' - fnc_siac_vincoli_pending - inizio chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.',
    clock_timestamp(),
    p_log_elab
  );
end if;

raise notice '%', 'fnc_siac_vincoli_pending - inizio chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.';
for rec in cur_modif (p_movgest_anno,p_movgest_numero) loop
select fnc_siac_vincoli_pending_modifica(rec.mod_id,rec.anno_bilancio,p_log_elab,p_login_operazione,p_data_elaborazione) into esito;
--raise notice '%', 'fnc_siac_vincoli_pending - chiamata fnc_siac_vincoli_pending_modifica - mod_id='||rec.mod_id::varchar||' esito='||esito::varchar||'.';
end loop;
raise notice '%', 'fnc_siac_vincoli_pending - fine chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.';

if p_log_elab is not null then
 insert into  siac_dwh_log_elaborazioni
  (
    ente_proprietario_id,
    fnc_name ,
    fnc_parameters ,
    fnc_elaborazione_inizio ,
    fnc_user
  )
  values
  (
    p_ente_proprietario_id,
    'fnc_siac_vincoli_pending',
    params||' - fnc_siac_vincoli_pending - fine chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.',
    clock_timestamp(),
    p_log_elab
  );
end if;

raise notice '%', 'fnc_siac_vincoli_pending - fine chiamata fnc_siac_vincoli_pending_modifica - '||clock_timestamp()::varchar||'.';

p_esito:=0;
return p_esito;

EXCEPTION
WHEN others THEN
  p_esito:=-1;
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
  RETURN p_esito;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
alter function siac.fnc_siac_vincoli_pending(integer,integer,varchar,integer,integer,varchar,timestamp) owner to siac;

drop FUNCTION if exists siac.fnc_siac_dwh_impegno
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_impegno
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
declare
v_user_table varchar;
params varchar;

-- 24.02.2021 Sofia Jira SIAC-8020
h_esito integer:=null;
begin

select fnc_siac_random_user()
into	v_user_table;

IF p_data IS NULL THEN
   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   ELSE
      p_data := now();
   END IF;
END IF;

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
'fnc_siac_dwh_impegno',
params,
clock_timestamp(),
v_user_table
);

-- 24.02.2021 Sofia Jira SIAC-8020 - inizio
select
fnc_siac_vincoli_pending
(
  p_ente_proprietario_id,
  p_anno_bilancio::integer,
  v_user_table,
  null::integer,--p_movgest_anno  integer,
  null::integer,--p_movgest_numero integer,
  'fnc_siac_dwh_impegno'::varchar,--p_login_operazione varchar,
  p_data::timestamp
) into h_esito;
raise notice 'esito fnc_siac_vincoli_pending=%',h_esito::varchar;
-- 24.02.2021 Sofia Jira SIAC-8020 - fine

delete from siac_dwh_impegno where
ente_proprietario_id=p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
delete from siac_dwh_subimpegno where
ente_proprietario_id=p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;

INSERT INTO
  siac.siac_dwh_impegno
(
  ente_proprietario_id,  ente_denominazione,  bil_anno,  cod_fase_operativa,  desc_fase_operativa,
  anno_impegno,  num_impegno,  desc_impegno,  cod_impegno,  cod_stato_impegno,  desc_stato_impegno,
  data_scadenza,  parere_finanziario,  cod_capitolo,  cod_articolo,  cod_ueb,  desc_capitolo,  desc_articolo,
  soggetto_id, cod_soggetto, desc_soggetto,  cf_soggetto,  cf_estero_soggetto, p_iva_soggetto,  cod_classe_soggetto,  desc_classe_soggetto,
  cod_tipo_impegno,  desc_tipo_impegno,   cod_spesa_ricorrente,  desc_spesa_ricorrente,  cod_perimetro_sanita_spesa,  desc_perimetro_sanita_spesa,
  cod_transazione_ue_spesa,  desc_transazione_ue_spesa,  cod_politiche_regionali_unit,  desc_politiche_regionali_unit,
  cod_pdc_finanziario_i,  desc_pdc_finanziario_i,  cod_pdc_finanziario_ii,  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,  desc_pdc_finanziario_iii,  cod_pdc_finanziario_iv,  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,  desc_pdc_finanziario_v,  cod_pdc_economico_i,  desc_pdc_economico_i,
  cod_pdc_economico_ii,  desc_pdc_economico_ii,  cod_pdc_economico_iii,  desc_pdc_economico_iii,
  cod_pdc_economico_iv,  desc_pdc_economico_iv,  cod_pdc_economico_v,  desc_pdc_economico_v,
  cod_cofog_divisione,  desc_cofog_divisione,  cod_cofog_gruppo,  desc_cofog_gruppo,
  classificatore_1,  classificatore_1_valore,  classificatore_1_desc_valore,
  classificatore_2,  classificatore_2_valore,  classificatore_2_desc_valore,
  classificatore_3,  classificatore_3_valore,  classificatore_3_desc_valore,
  classificatore_4,  classificatore_4_valore,  classificatore_4_desc_valore,
  classificatore_5,  classificatore_5_valore,  classificatore_5_desc_valore,
  annocapitoloorigine,  numcapitoloorigine,  annoorigineplur, numarticoloorigine,  annoriaccertato,  numriaccertato,  numorigineplur,
  flagdariaccertamento,
  flagdareanno,-- 19.02.2020 Sofia jira siac-7292
  anno_atto_amministrativo,  num_atto_amministrativo,  oggetto_atto_amministrativo,  note_atto_amministrativo,
  cod_tipo_atto_amministrativo, desc_tipo_atto_amministrativo, desc_stato_atto_amministrativo,
  importo_iniziale,  importo_attuale,  importo_utilizzabile,
  note,  anno_finanziamento,  cig,  cup,  num_ueb_origine,  validato,
  num_accertamento_finanziamento,  importo_liquidato,  importo_quietanziato,  importo_emesso,
  --data_elaborazione,
  flagcassaeconomale,  data_inizio_val_stato_imp,  data_inizio_val_imp,
  data_creazione_imp,  data_modifica_imp,
  cod_cdc_atto_amministrativo,  desc_cdc_atto_amministrativo,
  cod_cdr_atto_amministrativo,  desc_cdr_atto_amministrativo,
  cod_programma, desc_programma,
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile,
  cod_siope_tipo_debito, desc_siope_tipo_debito, desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, desc_siope_assenza_motivazione, desc_siope_assenza_motiv_bnkit,
  flag_attiva_gsa, -- 28.05.2018 Sofia siac-6202
  -- 23.10.2018 Sofia siac-6336
  stato_programma,
  versione_cronop,
  desc_cronop,
  anno_cronop,
  -- SIAC-7541 23.04.2020 Sofia
  cod_cdr_struttura_comp,
  desc_cdr_struttura_comp,
  cod_cdc_struttura_comp,
  desc_cdc_struttura_comp
  )
select
xx.ente_proprietario_id, xx.ente_denominazione, xx.anno,xx.fase_operativa_code, xx.fase_operativa_desc ,
xx.movgest_anno, xx.movgest_numero, xx.movgest_desc, xx.movgest_ts_code, --xx.movgest_ts_desc,
xx.movgest_stato_code, xx.movgest_stato_desc, xx.movgest_ts_scadenza_data,
case when xx.parere_finanziario=false then 'F' else 'S' end parere_finanziario
,-- xx.movgest_id, xx.movgest_ts_id, xx.movgest_ts_tipo_code,
xx.elem_code, xx.elem_code2, xx.elem_code3, xx.elem_desc, xx.elem_desc2, --xx.bil_id,
xx.soggetto_id, xx.soggetto_code, xx.soggetto_desc, xx.codice_fiscale,xx.codice_fiscale_estero, xx.partita_iva, xx.soggetto_classe_code, xx.soggetto_classe_desc,
xx.tipoimpegno_classif_code,xx.tipoimpegno_classif_desc,xx.ricorrentespesa_classif_code,xx.ricorrentespesa_classif_desc,
xx.persaspesa_classif_code,xx.persaspesa_classif_desc, xx.truespesa_classif_code, xx.truespesa_classif_desc, xx.polregunitarie_classif_code,xx.polregunitarie_classif_desc,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_I else xx.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_I else xx.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_II else xx.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_II else xx.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_III else xx.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_III else xx.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_IV else xx.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_IV else xx.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_I else xx.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_I else xx.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_II else xx.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_II else xx.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_III else xx.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_III else xx.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_IV else xx.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_IV else xx.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
xx.codice_cofog_divisione, xx.descrizione_cofog_divisione,xx.codice_cofog_gruppo,xx.descrizione_cofog_gruppo,
xx.cla11_classif_tipo_desc,xx.cla11_classif_code,xx.cla11_classif_desc,
xx.cla12_classif_tipo_desc,xx.cla12_classif_code,xx.cla12_classif_desc,
xx.cla13_classif_tipo_desc,xx.cla13_classif_code,xx.cla13_classif_desc,
xx.cla14_classif_tipo_desc,xx.cla14_classif_code,xx.cla14_classif_desc,
xx.cla15_classif_tipo_desc,xx.cla15_classif_code,xx.cla15_classif_desc,
xx.annoCapitoloOrigine,xx.numeroCapitoloOrigine,xx.annoOriginePlur,xx.numeroArticoloOrigine,xx.annoRiaccertato,xx.numeroRiaccertato,
xx.numeroOriginePlur, xx.flagDaRiaccertamento,
xx.flagDaReanno, -- 19.02.2020 Sofia jira siac-7292
xx.attoamm_anno, xx.attoamm_numero, xx.attoamm_oggetto, xx.attoamm_note,
xx.attoamm_tipo_code, xx.attoamm_tipo_desc, xx.attoamm_stato_desc,
xx.importo_iniziale, xx.importo_attuale, xx.importo_utilizzabile,
xx.NOTE_MOVGEST,  xx.annoFinanziamento, xx.cig,xx.cup, xx.numeroUEBOrigine,  xx.validato,
--xx.attoamm_id,
xx.numeroAccFinanziamento,  xx.importo_liquidato,  xx.importo_quietanziato, xx.importo_emesso,
xx.flagCassaEconomale,
xx.data_inizio_val_stato_subimp, xx.data_inizio_val_imp,
xx.data_creazione_imp, xx.data_modifica_imp,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_code::varchar else xx.cdr_cdc_code::varchar end cdc_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_desc::varchar else xx.cdr_cdc_desc::varchar end cdc_desc,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_code::varchar else xx.cdr_cdr_code::varchar end cdr_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_desc::varchar else xx.cdr_cdr_desc::varchar end cdr_desc,
xx.programma_code, xx.programma_desc,
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile,
xx.siope_tipo_debito_code, xx.siope_tipo_debito_desc, xx.siope_tipo_debito_desc_bnkit,
xx.siope_assenza_motivazione_code, xx.siope_assenza_motivazione_desc, xx.siope_assenza_motivazione_desc_bnkit,
xx.flag_attiva_gsa, -- 28.05.2018 Sofia siac-6102
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
-- 23.10.2018 Sofia SIAC-6336
xx.programma_stato,
xx.versione_cronop,
xx.desc_cronop,
xx.anno_cronop,
-- SIAC-7541 23.04.2020 Sofia
xx.cod_cdr_struttura_comp,
xx.desc_cdr_struttura_comp,
xx.cod_cdc_struttura_comp,
xx.desc_cdc_struttura_comp
 from (
with imp as (
SELECT
e.ente_proprietario_id, e.ente_denominazione, d.anno,
       b.movgest_anno, b.movgest_numero, b.movgest_desc, a.movgest_ts_code, a.movgest_ts_desc,
       i.movgest_stato_code, i.movgest_stato_desc,
       a.movgest_ts_scadenza_data, b.parere_finanziario, b.movgest_id, a.movgest_ts_id,
       g.movgest_ts_tipo_code,    c.bil_id,
       h.validita_inizio as data_inizio_val_stato_subimp,
       a.data_creazione as data_creazione_subimp,
       a.validita_inizio as  data_inizio_val_subimp,
       a.data_modifica as data_modifica_subimp,
       b.data_creazione as data_creazione_imp,
       b.validita_inizio as data_inizio_val_imp,
       b.data_modifica as data_modifica_imp,
       m.fase_operativa_code, m.fase_operativa_desc,
       n.siope_tipo_debito_code, n.siope_tipo_debito_desc, n.siope_tipo_debito_desc_bnkit,
       o.siope_assenza_motivazione_code, o.siope_assenza_motivazione_desc, o.siope_assenza_motivazione_desc_bnkit
FROM
siac_t_movgest_ts a
left join siac_d_siope_tipo_debito n on n.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
left join siac_d_siope_assenza_motivazione o on o.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
, siac_t_movgest b
, siac_t_bil c
, siac_t_periodo d
, siac_t_ente_proprietario e
, siac_d_movgest_tipo f
, siac_d_movgest_ts_tipo g
, siac_r_movgest_ts_stato h
, siac_d_movgest_stato i,
siac_r_bil_fase_operativa l, siac_d_fase_operativa m
where a.movgest_id=  b.movgest_id and
 b.bil_id = c.bil_id and
 d.periodo_id = c.periodo_id and
 e.ente_proprietario_id = b.ente_proprietario_id   and
 b.movgest_tipo_id = f.movgest_tipo_id and
 a.movgest_ts_tipo_id = g.movgest_ts_tipo_id      and
 h.movgest_ts_id = a.movgest_ts_id   and
 h.movgest_stato_id = i.movgest_stato_id
and e.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
AND f.movgest_tipo_code = 'I'
--and b.movgest_anno::integer in (2021,2022)
--and b.movgest_numero::integer between 2550 and 3000
-- 22.11.2018 Sofia jira SIAC-6548
-- AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and l.bil_id=c.bil_id
and m.fase_operativa_id=l.fase_operativa_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
--and  b.movgest_anno::integer=2020
--and  b.movgest_numero::integer in (2892,2901,3065,3157,3158,3178)
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND c.data_cancellazione IS NULL
AND d.data_cancellazione IS NULL
AND e.data_cancellazione IS NULL
AND f.data_cancellazione IS NULL
AND g.data_cancellazione IS NULL
AND h.data_cancellazione IS NULL
AND i.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
AND c.validita_fine IS NULL
AND d.validita_fine IS NULL
AND e.validita_fine IS NULL
AND f.validita_fine IS NULL
AND g.validita_fine IS NULL
AND h.validita_fine IS NULL
AND i.validita_fine IS NULL
)
, cap as (
select l.movgest_id
,m.elem_code, m.elem_code2, m.elem_code3, m.elem_desc, m.elem_desc2
From siac_r_movgest_bil_elem l, siac_t_bil_elem m
where l.elem_id=m.elem_id
and l.ente_proprietario_id=p_ente_proprietario_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND l.data_cancellazione IS NULL
AND m.data_cancellazione IS NULL
AND l.validita_fine IS NULL
AND m.validita_fine IS NULL
),
sogg as (SELECT
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale,
b.codice_fiscale_estero, b.partita_iva, b.soggetto_id
/*INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto,
v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id*/
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
and a.ente_proprietario_id=p_ente_proprietario_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
sogcla as (SELECT
a.movgest_ts_id,b.soggetto_classe_code, b.soggetto_classe_desc
--INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_classe_id = b.soggetto_classe_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
--classificatori non gerarchici
tipoimpegno as (
SELECT
a.movgest_ts_id,b.classif_code tipoimpegno_classif_code,b.classif_desc tipoimpegno_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_IMPEGNO'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
ricorrentespesa as (
SELECT
a.movgest_ts_id,b.classif_code ricorrentespesa_classif_code,b.classif_desc ricorrentespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
truespesa as (
SELECT
a.movgest_ts_id,b.classif_code truespesa_classif_code,b.classif_desc truespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
persaspesa as (
SELECT
a.movgest_ts_id,b.classif_code persaspesa_classif_code,b.classif_desc persaspesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
polregunitarie as (
SELECT
a.movgest_ts_id,b.classif_code polregunitarie_classif_code,b.classif_desc polregunitarie_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
cla11 as (
SELECT
a.movgest_ts_id,b.classif_code cla11_classif_code,b.classif_desc cla11_classif_desc,
c.classif_tipo_desc cla11_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_11'
-- AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla12 as (
SELECT
a.movgest_ts_id,b.classif_code cla12_classif_code,b.classif_desc cla12_classif_desc,
c.classif_tipo_desc cla12_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_12'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla13 as (
SELECT
a.movgest_ts_id,b.classif_code cla13_classif_code,b.classif_desc cla13_classif_desc,
c.classif_tipo_desc cla13_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_13'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla14 as (
SELECT
a.movgest_ts_id,b.classif_code cla14_classif_code,b.classif_desc cla14_classif_desc,
c.classif_tipo_desc cla14_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_14'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla15 as (
SELECT
a.movgest_ts_id,b.classif_code cla15_classif_code,b.classif_desc cla15_classif_desc,
c.classif_tipo_desc cla15_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_15'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
--sezione attributi
, t_annoCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo annoCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo annoOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroArticoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroArticoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroArticoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo annoRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo numeroRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo numeroOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagDaRiaccertamento as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaRiaccertamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaRiaccertamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
-- 19.02.2020 Sofia jira siac-7292
, t_flagDaReanno as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaReanno
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaReanno' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroUEBOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroUEBOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroUEBOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cig as (
SELECT
a.movgest_ts_id
, a.testo cig
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cup as (
SELECT
a.movgest_ts_id
, a.testo cup
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_NOTE_MOVGEST as (
SELECT
a.movgest_ts_id
, a.testo NOTE_MOVGEST
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_MOVGEST' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_validato as (
SELECT
a.movgest_ts_id
, a."boolean" validato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='validato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo annoFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroAccFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo numeroAccFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroAccFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagCassaEconomale as (
SELECT
a.movgest_ts_id
, a."boolean" flagCassaEconomale
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagCassaEconomale' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazione as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazione
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazione' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazioneLiquidabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazioneLiquidabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazioneLiquidabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
t_flagFrazionabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagFrazionabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagFrazionabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_movgest_ts_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
,
atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null
and a.validita_fine is null
--and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
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
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null
and c.validita_fine is null
and a2.validita_fine is null*/
)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null*/
)
select
atmc.movgest_ts_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id),
impattuale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_attuale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='A'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
impiniziale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_iniziale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='I'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
imputilizzabile as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_utilizzabile, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='U'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
),
impliquidatoemessoquietanziato as (select tz.* from (
with liquid as (
 SELECT sum(COALESCE(b.liq_importo,0)) importo_liquidato, a.movgest_ts_id,
b.liq_id
    FROM siac.siac_r_liquidazione_movgest a, siac.siac_t_liquidazione b,
    siac.siac_d_liquidazione_stato c, siac.siac_r_liquidazione_stato d
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id
    AND   a.liq_id = b.liq_id
    AND   b.liq_id = d.liq_id
    AND   d.liq_stato_id = c.liq_stato_id
    AND   c.liq_stato_code <> 'A'
    --AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    --AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data)
    AND a.data_cancellazione IS NULL
    AND b.data_cancellazione IS NULL
    AND c.data_cancellazione IS NULL
    AND d.data_cancellazione IS NULL
    AND a.validita_fine IS NULL
    AND b.validita_fine IS NULL
    AND c.validita_fine IS NULL
    AND d.validita_fine IS NULL
    group by a.movgest_ts_id, b.liq_id),
emes as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_emesso, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code <> 'A'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id),
quiet as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_quietanziato, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code= 'Q'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id)
select liquid.movgest_ts_id,coalesce(sum(liquid.importo_liquidato),0) importo_liquidato,
coalesce(sum(emes.importo_emesso),0) importo_emesso,
coalesce(sum(quiet.importo_quietanziato),0) importo_quietanziato
from liquid left join emes ON
liquid.liq_id=emes.liq_id
left join quiet ON
liquid.liq_id=quiet.liq_id
group by liquid.movgest_ts_id
) as tz),
cofog as (
select distinct r.movgest_ts_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_movgest_class r,
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
--and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
)
, pdc5 as (
select distinct
r.movgest_ts_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- SIAC-5883 FINE Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pdc4 as (
select distinct r.movgest_ts_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- SIAC-5883 FINE Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, pce5 as (
select distinct r.movgest_ts_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pce4 as (
select distinct r.movgest_ts_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
),
-- 30.04.2019 Sofia siac-6255 - modificato tutto il pezzo per tirare su il programma-cronop secondo
-- nuovo collegamento o secondo vecchio collegamento se non esiste tramite nuovo
progr_all_all as
(
with
progr_all as
(
with
-- 23.10.2018 Sofia siac-6336
progetto_old as -- vecchio collegamento
(
with
 progr as
 (
  select rmtp.movgest_ts_id, tp.programma_code, tp.programma_desc,
         stato.programma_stato_code  programma_stato,
         rmtp.programma_id
  from   siac_r_movgest_ts_programma rmtp, siac_t_programma tp, siac_r_programma_stato rs, siac_d_programma_stato stato
  where  rmtp.programma_id = tp.programma_id
  --and    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
  --and    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
  and    rs.programma_id=tp.programma_id
  and    stato.programma_stato_id=rs.programma_stato_id
  and    rmtp.data_cancellazione IS NULL
  and    tp.data_cancellazione IS NULL
  and    rmtp.validita_fine IS NULL
  and    tp.validita_fine IS NULL
  and    rs.data_cancellazione is null
  and    rs.validita_fine is null
 ),
 -- 23.10.2018 Sofia siac-6336
 cronop as
 (
  select cronop.programma_id,
		 cronop.cronop_id,
         cronop.cronop_code versione_cronop,
         cronop.cronop_desc desc_cronop,
         per.anno::varchar  anno_cronop
  from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_periodo per,siac_t_bil bil
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  ),
  cronop_ultimo as
  (
  select cronop.programma_id,
		 max(cronop.cronop_id) cronop_id
  from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_bil bil ,siac_t_periodo per
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  group by cronop.programma_id
  )
  select 1 programma_tipo_coll,
         progr.movgest_ts_id, progr.programma_code, progr.programma_desc,
         progr.programma_stato ,
         cronop.versione_cronop,
         cronop.desc_cronop,
         cronop.anno_cronop
  from progr
   left join cronop join cronop_ultimo on (cronop.cronop_id=cronop_ultimo.cronop_id)
    on (progr.programma_id=cronop.programma_id)
),
-- 30.04.2019 Sofia siac-6255 - nuovo collegamento
progetto as
(
 with
 progr as
 (
  select tp.programma_code, tp.programma_desc,
         stato.programma_stato_code  programma_stato,
         tp.programma_id
  from   siac_t_programma tp, siac_r_programma_stato rs, siac_d_programma_stato stato
  where  stato.ente_proprietario_id=p_ente_proprietario_id
  and    rs.programma_stato_id=stato.programma_stato_id
  and    tp.programma_id=rs.programma_id
  and    tp.data_cancellazione IS NULL
  and    tp.validita_fine IS NULL
  and    rs.data_cancellazione is null
  and    rs.validita_fine is null
 ),
 cronop as
 (
  select rmov.movgest_ts_id,
         cronop.programma_id,
		 cronop.cronop_id,
         cronop.cronop_code versione_cronop,
         cronop.cronop_desc desc_cronop,
         per.anno::varchar  anno_cronop,
         rmov.data_creazione
  from siac_r_movgest_ts_cronop_elem rmov, siac_t_cronop_elem celem,
       siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_periodo per,siac_t_bil bil
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   celem.cronop_id=cronop.cronop_id
  and   rmov.cronop_elem_id=celem.cronop_elem_id
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  and   celem.data_cancellazione is null
  and   celem.validita_fine is null
  and   rmov.data_cancellazione is null
  and   rmov.validita_fine is null
 ),
 cronop_ultimo as
 (
  select rmov.movgest_ts_id,
         max(cronop.cronop_id) ult_cronop_id
  from siac_r_movgest_ts_cronop_elem rmov, siac_t_cronop_elem celem,
       siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,
       siac_t_periodo per,siac_t_bil bil
  where stato.ente_proprietario_id=p_ente_proprietario_id
  and   stato.cronop_stato_code='VA'
  and   rs.cronop_stato_id=stato.cronop_stato_id
  and   cronop.cronop_id=rs.cronop_id
  and   bil.bil_id=cronop.bil_id
  and   per.periodo_id=bil.periodo_id
  and   per.anno::INTEGER=p_anno_bilancio::integer
  and   celem.cronop_id=cronop.cronop_id
  and   rmov.cronop_elem_id=celem.cronop_elem_id
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   cronop.data_cancellazione is null
  and   cronop.validita_fine is null
  and   celem.data_cancellazione is null
  and   celem.validita_fine is null
  and   rmov.data_cancellazione is null
  and   rmov.validita_fine is null
  group by rmov.movgest_ts_id
 )
 select 2 programma_tipo_coll,
        cronop.movgest_ts_id,
        progr.programma_code, progr.programma_desc,
        progr.programma_stato ,
        cronop.versione_cronop,
        cronop.desc_cronop,
        cronop.anno_cronop
 from progr, cronop ,cronop_ultimo
 where cronop.programma_id=progr.programma_id
 and   cronop_ultimo.ult_cronop_id=cronop.cronop_id
 and   cronop_ultimo.movgest_ts_id=cronop.movgest_ts_id
)
select *
from progetto_old
union
select *
from progetto
)
select *
from progr_all p1
where
(  ( p1.programma_tipo_coll=1 and p1.movgest_ts_id is not null ) or
   (p1.programma_tipo_coll=2
    and   not exists (select 1 from progr_all p2 where p2.programma_tipo_coll=1 and p2.movgest_Ts_id is not null)
   )
)
),
-- 30.04.2019 Sofia siac-6255 - fine
impFlagAttivaGsa as -- 28.05.2018 Sofia siac-6102
(
select rattr.movgest_ts_id, rattr.boolean flag_attiva_gsa
from siac_r_movgest_ts_attr rattr, siac_t_attr attr
where attr.ente_proprietario_id=p_ente_proprietario_id
and   attr.attr_code='FlagAttivaGsa'
and   rattr.attr_id=attr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
),
-- SIAC-7541 23.04.2020 Sofia
cdc_struttura as
(
SELECT rc.movgest_ts_id,c.classif_code cod_cdc_struttura_comp,c.classif_desc desc_cdc_struttura_comp
from   siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipo
where rc.ente_proprietario_id = p_ente_proprietario_id
and   c.classif_id=rc.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code='CDC'
AND   rc.data_cancellazione IS NULL
--AND   c.data_cancellazione IS NULL
AND   rc.validita_fine IS NULL
),
-- SIAC-7541 23.04.2020 Sofia
cdr_struttura as
(
SELECT rc.movgest_ts_id,c.classif_code cod_cdr_struttura_comp,c.classif_desc desc_cdr_struttura_comp
from   siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipo
where rc.ente_proprietario_id = p_ente_proprietario_id
and   c.classif_id=rc.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code='CDR'
AND   rc.data_cancellazione IS NULL
--AND   c.data_cancellazione IS NULL
AND   rc.validita_fine IS NULL
)
select
imp.ente_proprietario_id, imp.ente_denominazione, imp.anno,
imp.movgest_anno, imp.movgest_numero, imp.movgest_desc, imp.movgest_ts_code, imp.movgest_ts_desc,
imp.movgest_stato_code, imp.movgest_stato_desc,
imp.movgest_ts_scadenza_data, imp.parere_finanziario, imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_tipo_code,
cap.elem_code, cap.elem_code2, cap.elem_code3, cap.elem_desc, cap.elem_desc2,
imp.bil_id,
imp.data_inizio_val_stato_subimp,
imp.data_creazione_subimp,
imp.data_inizio_val_subimp,
imp.data_modifica_subimp,
imp.data_creazione_imp,
imp.data_inizio_val_imp,
imp.data_modifica_imp,
imp.fase_operativa_code, imp.fase_operativa_desc ,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale,
sogg.codice_fiscale_estero, sogg.partita_iva, sogg.soggetto_id
,sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
tipoimpegno.tipoimpegno_classif_code,
tipoimpegno.tipoimpegno_classif_desc,
ricorrentespesa.ricorrentespesa_classif_code,
ricorrentespesa.ricorrentespesa_classif_desc,
truespesa.truespesa_classif_code,
truespesa.truespesa_classif_desc,
persaspesa.persaspesa_classif_code,
persaspesa.persaspesa_classif_desc,
polregunitarie.polregunitarie_classif_code,
polregunitarie.polregunitarie_classif_desc,
cla11.cla11_classif_code,
cla11.cla11_classif_desc,
cla11.cla11_classif_tipo_desc,
cla12.cla12_classif_code,
cla12.cla12_classif_desc,
cla12.cla12_classif_tipo_desc,
cla13.cla13_classif_code,
cla13.cla13_classif_desc,
cla13.cla13_classif_tipo_desc,
cla14.cla14_classif_code,
cla14.cla14_classif_desc,
cla14.cla14_classif_tipo_desc,
cla15.cla15_classif_code,
cla15.cla15_classif_desc,
cla15.cla15_classif_tipo_desc,
t_annoCapitoloOrigine.annoCapitoloOrigine,
t_numeroCapitoloOrigine.numeroCapitoloOrigine,
t_annoOriginePlur.annoOriginePlur,
t_numeroArticoloOrigine.numeroArticoloOrigine,
t_annoRiaccertato.annoRiaccertato,
t_numeroRiaccertato.numeroRiaccertato,
t_numeroOriginePlur.numeroOriginePlur,
t_flagDaRiaccertamento.flagDaRiaccertamento,
t_flagDaReanno.flagDaReanno, -- 19.02.2020 Sofia jira siac-7292
t_numeroUEBOrigine.numeroUEBOrigine,
t_cig.cig,
t_cup.cup,
t_NOTE_MOVGEST.NOTE_MOVGEST,
t_validato.validato,
t_annoFinanziamento.annoFinanziamento,
t_numeroAccFinanziamento.numeroAccFinanziamento,
t_flagCassaEconomale.flagCassaEconomale,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
impattuale.importo_attuale,
impiniziale.importo_iniziale,
imputilizzabile.importo_utilizzabile,
impliquidatoemessoquietanziato.importo_liquidato,
impliquidatoemessoquietanziato.importo_emesso,
impliquidatoemessoquietanziato,importo_quietanziato,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
-- 30.04.2019 Sofia siac-6255 - cambiato qui solo nome alias progr_all_all
progr_all_all.programma_code, progr_all_all.programma_desc,
t_flagPrenotazione.flagPrenotazione, t_flagPrenotazioneLiquidabile.flagPrenotazioneLiquidabile,
t_flagFrazionabile.flagFrazionabile,
imp.siope_tipo_debito_code, imp.siope_tipo_debito_desc, imp.siope_tipo_debito_desc_bnkit,
imp.siope_assenza_motivazione_code, imp.siope_assenza_motivazione_desc, imp.siope_assenza_motivazione_desc_bnkit,
coalesce(impFlagAttivaGsa.flag_attiva_gsa,'N') flag_attiva_gsa, -- 28.05.2018 Sofia siac-6102
-- 23.10.2018 Sofia SIAC-6336
-- 30.04.2019 Sofia siac-6255 - cambiato qui solo nome alias progr_all_all
progr_all_all.programma_stato,
progr_all_all.versione_cronop,
progr_all_all.desc_cronop,
progr_all_all.anno_cronop,
-- SIAC-7541 23.04.2020 Sofia
cdr_struttura.cod_cdr_struttura_comp,
cdr_struttura.desc_cdr_struttura_comp,
cdc_struttura.cod_cdc_struttura_comp,
cdc_struttura.desc_cdc_struttura_comp
from
imp left join cap
on
imp.movgest_id=cap.movgest_id
left join sogg
on
imp.movgest_ts_id=sogg.movgest_ts_id
left join sogcla
on
imp.movgest_ts_id=sogcla.movgest_ts_id
left join tipoimpegno
on
imp.movgest_ts_id=tipoimpegno.movgest_ts_id
left join ricorrentespesa
on
imp.movgest_ts_id=ricorrentespesa.movgest_ts_id
left join truespesa
on
imp.movgest_ts_id=truespesa.movgest_ts_id
left join persaspesa
on
imp.movgest_ts_id=persaspesa.movgest_ts_id
left join polregunitarie
on
imp.movgest_ts_id=polregunitarie.movgest_ts_id
left join cla11
on
imp.movgest_ts_id=cla11.movgest_ts_id
left join cla12
on
imp.movgest_ts_id=cla12.movgest_ts_id
left join cla13
on
imp.movgest_ts_id=cla13.movgest_ts_id
left join cla14
on
imp.movgest_ts_id=cla14.movgest_ts_id
left join cla15
on
imp.movgest_ts_id=cla15.movgest_ts_id
left join t_annoCapitoloOrigine
on
imp.movgest_ts_id=t_annoCapitoloOrigine.movgest_ts_id
left join t_numeroCapitoloOrigine
on
imp.movgest_ts_id=t_numeroCapitoloOrigine.movgest_ts_id
left join t_annoOriginePlur
on
imp.movgest_ts_id=t_annoOriginePlur.movgest_ts_id
left join t_numeroArticoloOrigine
on
imp.movgest_ts_id=t_numeroArticoloOrigine.movgest_ts_id
left join t_annoRiaccertato
on
imp.movgest_ts_id=t_annoRiaccertato.movgest_ts_id
left join t_numeroRiaccertato
on
imp.movgest_ts_id=t_numeroRiaccertato.movgest_ts_id
left join t_numeroOriginePlur
on
imp.movgest_ts_id=t_numeroOriginePlur.movgest_ts_id
left join t_flagDaRiaccertamento
on
imp.movgest_ts_id=t_flagDaRiaccertamento.movgest_ts_id
-- 19.02.2020 Sofia jira siac-7292
left join t_flagDaReanno
on
imp.movgest_ts_id=t_flagDaReanno.movgest_ts_id
left join t_numeroUEBOrigine
on
imp.movgest_ts_id=t_numeroUEBOrigine.movgest_ts_id
left join t_cig
on
imp.movgest_ts_id=t_cig.movgest_ts_id
left join t_cup
on
imp.movgest_ts_id=t_cup.movgest_ts_id
left join t_NOTE_MOVGEST
on
imp.movgest_ts_id=t_NOTE_MOVGEST.movgest_ts_id
left join t_validato
on
imp.movgest_ts_id=t_validato.movgest_ts_id
left join t_annoFinanziamento
on
imp.movgest_ts_id=t_annoFinanziamento.movgest_ts_id
left join t_numeroAccFinanziamento
on
imp.movgest_ts_id=t_numeroAccFinanziamento.movgest_ts_id
left join t_flagCassaEconomale
on
imp.movgest_ts_id=t_flagCassaEconomale.movgest_ts_id
left join attoamm
on
imp.movgest_ts_id=attoamm.movgest_ts_id
left join impattuale
on
imp.movgest_ts_id=impattuale.movgest_ts_id
left join impiniziale
on
imp.movgest_ts_id=impiniziale.movgest_ts_id
left join imputilizzabile
on
imp.movgest_ts_id=imputilizzabile.movgest_ts_id
left join impliquidatoemessoquietanziato
on
imp.movgest_ts_id=impliquidatoemessoquietanziato.movgest_ts_id
left join cofog
on
imp.movgest_ts_id=cofog.movgest_ts_id
left join pdc5
on
imp.movgest_ts_id=pdc5.movgest_ts_id
left join pdc4
on
imp.movgest_ts_id=pdc4.movgest_ts_id
left join pce5
on
imp.movgest_ts_id=pce5.movgest_ts_id
left join pce4
on
imp.movgest_ts_id=pce4.movgest_ts_id
left join progr_all_all
on
imp.movgest_ts_id=progr_all_all.movgest_ts_id
left join t_flagPrenotazione
on
imp.movgest_ts_id=t_flagPrenotazione.movgest_ts_id
left join t_flagPrenotazioneLiquidabile
on
imp.movgest_ts_id=t_flagPrenotazioneLiquidabile.movgest_ts_id
left join t_flagFrazionabile
on
imp.movgest_ts_id=t_flagFrazionabile.movgest_ts_id
left join impFlagAttivaGsa
on
imp.movgest_ts_id=impFlagAttivaGsa.movgest_ts_id -- 28.05.2018 Sofia siac-6102
-- SIAC-7541 23.04.2020 Sofia
left join cdr_struttura on
imp.movgest_ts_id=cdr_struttura.movgest_ts_id
left join cdc_struttura on
imp.movgest_ts_id=cdc_struttura.movgest_ts_id
) xx
where xx.movgest_ts_tipo_code='T';



--------subimp

INSERT INTO
  siac.siac_dwh_subimpegno
(
  ente_proprietario_id,  ente_denominazione,  bil_anno,  cod_fase_operativa,  desc_fase_operativa,
  anno_impegno,  num_impegno,  desc_impegno,  cod_subimpegno,  cod_stato_subimpegno,  desc_stato_subimpegno,
  data_scadenza,  parere_finanziario,  cod_capitolo,  cod_articolo,  cod_ueb,  desc_capitolo,  desc_articolo,
  soggetto_id, cod_soggetto, desc_soggetto,  cf_soggetto,  cf_estero_soggetto, p_iva_soggetto,  cod_classe_soggetto,  desc_classe_soggetto,
  cod_tipo_impegno,  desc_tipo_impegno,   cod_spesa_ricorrente,  desc_spesa_ricorrente,  cod_perimetro_sanita_spesa,  desc_perimetro_sanita_spesa,
  cod_transazione_ue_spesa,  desc_transazione_ue_spesa,  cod_politiche_regionali_unit,  desc_politiche_regionali_unit,
  cod_pdc_finanziario_i,  desc_pdc_finanziario_i,  cod_pdc_finanziario_ii,  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,  desc_pdc_finanziario_iii,  cod_pdc_finanziario_iv,  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,  desc_pdc_finanziario_v,  cod_pdc_economico_i,  desc_pdc_economico_i,
  cod_pdc_economico_ii,  desc_pdc_economico_ii,  cod_pdc_economico_iii,  desc_pdc_economico_iii,
  cod_pdc_economico_iv,  desc_pdc_economico_iv,  cod_pdc_economico_v,  desc_pdc_economico_v,
  cod_cofog_divisione,  desc_cofog_divisione,  cod_cofog_gruppo,  desc_cofog_gruppo,
  classificatore_1,  classificatore_1_valore,  classificatore_1_desc_valore,
  classificatore_2,  classificatore_2_valore,  classificatore_2_desc_valore,
  classificatore_3,  classificatore_3_valore,  classificatore_3_desc_valore,
  classificatore_4,  classificatore_4_valore,  classificatore_4_desc_valore,
  classificatore_5,  classificatore_5_valore,  classificatore_5_desc_valore,
  annocapitoloorigine,  numcapitoloorigine,  annoorigineplur, numarticoloorigine,  annoriaccertato,  numriaccertato,  numorigineplur,
  flagdariaccertamento,
  flagdareanno, -- 19.02.2020 Sofia jira siac-7292
  anno_atto_amministrativo,  num_atto_amministrativo,  oggetto_atto_amministrativo,  note_atto_amministrativo,
  cod_tipo_atto_amministrativo, desc_tipo_atto_amministrativo, desc_stato_atto_amministrativo,
   importo_iniziale,  importo_attuale,  importo_utilizzabile,
  note,  anno_finanziamento,  cig,  cup,  num_ueb_origine,  validato,
  num_accertamento_finanziamento,  importo_liquidato,  importo_quietanziato,  importo_emesso,
  --data_elaborazione,
  flagcassaeconomale,  data_inizio_val_stato_subimp,  data_inizio_val_subimp,
  data_creazione_subimp,  data_modifica_subimp,
  cod_cdc_atto_amministrativo,  desc_cdc_atto_amministrativo,
  cod_cdr_atto_amministrativo,  desc_cdr_atto_amministrativo,
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile,
  cod_siope_tipo_debito, desc_siope_tipo_debito, desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, desc_siope_assenza_motivazione, desc_siope_assenza_motiv_bnkit,
  flag_attiva_gsa, -- 28.05.2018 Sofia siac-6202
  -- SIAC-7541 23.04.2020 Sofia
  cod_cdr_struttura_comp,
  desc_cdr_struttura_comp,
  cod_cdc_struttura_comp,
  desc_cdc_struttura_comp
  )
select
xx.ente_proprietario_id, xx.ente_denominazione, xx.anno,xx.fase_operativa_code, xx.fase_operativa_desc ,
xx.movgest_anno, xx.movgest_numero, xx.movgest_desc, xx.movgest_ts_code, --xx.movgest_ts_desc,
xx.movgest_stato_code, xx.movgest_stato_desc, xx.movgest_ts_scadenza_data,
case when xx.parere_finanziario=false then 'F' else 'S' end parere_finanziario,-- xx.movgest_id, xx.movgest_ts_id, xx.movgest_ts_tipo_code,
xx.elem_code, xx.elem_code2, xx.elem_code3, xx.elem_desc, xx.elem_desc2, --xx.bil_id,
xx.soggetto_id, xx.soggetto_code, xx.soggetto_desc, xx.codice_fiscale,xx.codice_fiscale_estero, xx.partita_iva, xx.soggetto_classe_code, xx.soggetto_classe_desc,
xx.tipoimpegno_classif_code,xx.tipoimpegno_classif_desc,xx.ricorrentespesa_classif_code,xx.ricorrentespesa_classif_desc,
xx.persaspesa_classif_code,xx.persaspesa_classif_desc, xx.truespesa_classif_code, xx.truespesa_classif_desc, xx.polregunitarie_classif_code,xx.polregunitarie_classif_desc,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_I else xx.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_I else xx.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_II else xx.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_II else xx.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_III else xx.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_III else xx.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_IV else xx.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_IV else xx.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_I else xx.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_I else xx.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_II else xx.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_II else xx.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_III else xx.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_III else xx.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_IV else xx.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_IV else xx.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
xx.codice_cofog_divisione, xx.descrizione_cofog_divisione,xx.codice_cofog_gruppo,xx.descrizione_cofog_gruppo,
xx.cla11_classif_tipo_code,xx.cla11_classif_code,xx.cla11_classif_desc,xx.cla12_classif_tipo_code,xx.cla12_classif_code,xx.cla12_classif_desc,
xx.cla13_classif_tipo_code,xx.cla13_classif_code,xx.cla13_classif_desc,xx.cla14_classif_tipo_code,xx.cla14_classif_code,xx.cla14_classif_desc,
xx.cla15_classif_tipo_code,xx.cla15_classif_code,xx.cla15_classif_desc,
xx.annoCapitoloOrigine,xx.numeroCapitoloOrigine,xx.annoOriginePlur,xx.numeroArticoloOrigine,xx.annoRiaccertato,xx.numeroRiaccertato,
xx.numeroOriginePlur, xx.flagDaRiaccertamento,
xx.flagDaReanno, -- 19.02.2020 Sofia jira siac-7292
xx.attoamm_anno, xx.attoamm_numero, xx.attoamm_oggetto, xx.attoamm_note,
xx.attoamm_tipo_code, xx.attoamm_tipo_desc, xx.attoamm_stato_desc,
xx.importo_iniziale, xx.importo_attuale, xx.importo_utilizzabile,
xx.NOTE_MOVGEST,  xx.annoFinanziamento, xx.cig,xx.cup, xx.numeroUEBOrigine,  xx.validato,
--xx.attoamm_id,
xx.numeroAccFinanziamento,  xx.importo_liquidato,  xx.importo_quietanziato, xx.importo_emesso,
xx.flagCassaEconomale,
xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_code::varchar else xx.cdr_cdc_code::varchar end cdc_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_desc::varchar else xx.cdr_cdc_desc::varchar end cdc_desc,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_code::varchar else xx.cdr_cdr_code::varchar end cdr_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_desc::varchar else xx.cdr_cdr_desc::varchar end cdr_desc,
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile,
xx.siope_tipo_debito_code, xx.siope_tipo_debito_desc, xx.siope_tipo_debito_desc_bnkit,
xx.siope_assenza_motivazione_code, xx.siope_assenza_motivazione_desc, xx.siope_assenza_motivazione_desc_bnkit,
xx.flag_attiva_gsa, -- 28.05.2018 Sofia siac-6202
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
-- SIAC-7541 23.04.2020 Sofia
xx.cod_cdr_struttura_comp,
xx.desc_cdr_struttura_comp,
xx.cod_cdc_struttura_comp,
xx.desc_cdc_struttura_comp
 from (
with imp as (
SELECT
e.ente_proprietario_id, e.ente_denominazione, d.anno,
       b.movgest_anno, b.movgest_numero, b.movgest_desc, a.movgest_ts_code, a.movgest_ts_desc,
       i.movgest_stato_code, i.movgest_stato_desc,
       a.movgest_ts_scadenza_data, b.parere_finanziario, b.movgest_id, a.movgest_ts_id,
       g.movgest_ts_tipo_code,    c.bil_id,
       h.validita_inizio as data_inizio_val_stato_subimp,
       a.data_creazione as data_creazione_subimp,
       a.validita_inizio as  data_inizio_val_subimp,
       a.data_modifica as data_modifica_subimp,
       b.data_creazione as data_creazione_imp,
       b.validita_inizio as data_inizio_val_imp,
       b.data_modifica as data_modifica_imp,
       m.fase_operativa_code, m.fase_operativa_desc,
       n.siope_tipo_debito_code, n.siope_tipo_debito_desc, n.siope_tipo_debito_desc_bnkit,
       o.siope_assenza_motivazione_code, o.siope_assenza_motivazione_desc, o.siope_assenza_motivazione_desc_bnkit
FROM
siac_t_movgest_ts a
left join siac_d_siope_tipo_debito n on n.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
left join siac_d_siope_assenza_motivazione o on o.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
, siac_t_movgest b
, siac_t_bil c
,  siac_t_periodo d
, siac_t_ente_proprietario e
,  siac_d_movgest_tipo f
,  siac_d_movgest_ts_tipo g
,  siac_r_movgest_ts_stato h
,  siac_d_movgest_stato i,
siac_r_bil_fase_operativa l, siac_d_fase_operativa m
where a.movgest_id=  b.movgest_id and
 b.bil_id = c.bil_id and
 d.periodo_id = c.periodo_id and
 e.ente_proprietario_id = b.ente_proprietario_id   and
 b.movgest_tipo_id = f.movgest_tipo_id and
 a.movgest_ts_tipo_id = g.movgest_ts_tipo_id      and
 h.movgest_ts_id = a.movgest_ts_id   and
 h.movgest_stato_id = i.movgest_stato_id
and e.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
AND f.movgest_tipo_code = 'I'
--AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
--and  b.movgest_anno::integer=2020
and l.bil_id=c.bil_id
and m.fase_operativa_id=l.fase_operativa_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND c.data_cancellazione IS NULL
AND d.data_cancellazione IS NULL
AND e.data_cancellazione IS NULL
AND f.data_cancellazione IS NULL
AND g.data_cancellazione IS NULL
AND h.data_cancellazione IS NULL
AND i.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
AND c.validita_fine IS NULL
AND d.validita_fine IS NULL
AND e.validita_fine IS NULL
AND f.validita_fine IS NULL
AND g.validita_fine IS NULL
AND h.validita_fine IS NULL
AND i.validita_fine IS NULL
)
, cap as (
select l.movgest_id
,m.elem_code, m.elem_code2, m.elem_code3, m.elem_desc, m.elem_desc2
From siac_r_movgest_bil_elem l, siac_t_bil_elem m
where l.elem_id=m.elem_id
and l.ente_proprietario_id=p_ente_proprietario_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND l.data_cancellazione IS NULL
AND m.data_cancellazione IS NULL
AND l.validita_fine IS NULL
AND m.validita_fine IS NULL
),
sogg as (SELECT
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale,
b.codice_fiscale_estero, b.partita_iva, b.soggetto_id
/*INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto,
v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id*/
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
and a.ente_proprietario_id=p_ente_proprietario_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
sogcla as (SELECT
a.movgest_ts_id,b.soggetto_classe_code, b.soggetto_classe_desc
--INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_classe_id = b.soggetto_classe_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
)
,
--classificatori non gerarchici
tipoimpegno as (
SELECT
a.movgest_ts_id,b.classif_code tipoimpegno_classif_code,b.classif_desc tipoimpegno_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_IMPEGNO'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
ricorrentespesa as (
SELECT
a.movgest_ts_id,b.classif_code ricorrentespesa_classif_code,b.classif_desc ricorrentespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
truespesa as (
SELECT
a.movgest_ts_id,b.classif_code truespesa_classif_code,b.classif_desc truespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
persaspesa as (
SELECT
a.movgest_ts_id,b.classif_code persaspesa_classif_code,b.classif_desc persaspesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
polregunitarie as (
SELECT
a.movgest_ts_id,b.classif_code polregunitarie_classif_code,b.classif_desc polregunitarie_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
cla11 as (
SELECT
a.movgest_ts_id,b.classif_code cla11_classif_code,b.classif_desc cla11_classif_desc, c.classif_tipo_code cla11_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_11'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla12 as (
SELECT
a.movgest_ts_id,b.classif_code cla12_classif_code,b.classif_desc cla12_classif_desc, c.classif_tipo_code cla12_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_12'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla13 as (
SELECT
a.movgest_ts_id,b.classif_code cla13_classif_code,b.classif_desc cla13_classif_desc, c.classif_tipo_code cla13_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_13'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla14 as (
SELECT
a.movgest_ts_id,b.classif_code cla14_classif_code,b.classif_desc cla14_classif_desc, c.classif_tipo_code cla14_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_14'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla15 as (
SELECT
a.movgest_ts_id,b.classif_code cla15_classif_code,b.classif_desc cla15_classif_desc, c.classif_tipo_code cla15_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_15'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
--sezione attributi
, t_annoCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo annoCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo annoOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroArticoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroArticoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroArticoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo annoRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo numeroRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo numeroOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagDaRiaccertamento as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaRiaccertamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaRiaccertamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
-- 19.02.2020 Sofia jira siac-7292
, t_flagDaReanno as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaReanno
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaReanno' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)

, t_numeroUEBOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroUEBOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroUEBOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cig as (
SELECT
a.movgest_ts_id
, a.testo cig
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cup as (
SELECT
a.movgest_ts_id
, a.testo cup
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_NOTE_MOVGEST as (
SELECT
a.movgest_ts_id
, a.testo NOTE_MOVGEST
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_MOVGEST' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_validato as (
SELECT
a.movgest_ts_id
, a."boolean" validato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='validato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo annoFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroAccFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo numeroAccFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroAccFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagCassaEconomale as (
SELECT
a.movgest_ts_id
, a."boolean" flagCassaEconomale
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagCassaEconomale' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazione as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazione
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazione' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazioneLiquidabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazioneLiquidabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazioneLiquidabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
t_flagFrazionabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagFrazionabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagFrazionabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_movgest_ts_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null
AND   a.validita_fine IS NULL
--and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
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
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null
and a2.classif_id=c.classif_id_padre
/*and a.validita_fine is null
and b.validita_fine is null
and c.validita_fine is null
and a2.validita_fine is null*/
)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null*/
)
select
atmc.movgest_ts_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id),
impattuale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_attuale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='A'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
impiniziale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_iniziale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='I'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
imputilizzabile as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_utilizzabile, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='U'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
),
impliquidatoemessoquietanziato as (select tz.* from (
with liquid as (
 SELECT sum(COALESCE(b.liq_importo,0)) importo_liquidato, a.movgest_ts_id,
b.liq_id
    FROM siac.siac_r_liquidazione_movgest a, siac.siac_t_liquidazione b,
    siac.siac_d_liquidazione_stato c, siac.siac_r_liquidazione_stato d
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id
    AND   a.liq_id = b.liq_id
    AND   b.liq_id = d.liq_id
    AND   d.liq_stato_id = c.liq_stato_id
    AND   c.liq_stato_code <> 'A'
    --AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    --AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data)
    AND a.data_cancellazione IS NULL
    AND b.data_cancellazione IS NULL
    AND c.data_cancellazione IS NULL
    AND d.data_cancellazione IS NULL
    AND a.validita_fine IS NULL
    AND b.validita_fine IS NULL
    AND c.validita_fine IS NULL
    AND d.validita_fine IS NULL
    group by a.movgest_ts_id, b.liq_id),
emes as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_emesso, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code <> 'A'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id),
quiet as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_quietanziato, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code= 'Q'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id)
select liquid.movgest_ts_id,coalesce(sum(liquid.importo_liquidato),0) importo_liquidato,
coalesce(sum(emes.importo_emesso),0) importo_emesso,
coalesce(sum(quiet.importo_quietanziato),0) importo_quietanziato
from liquid left join emes ON
liquid.liq_id=emes.liq_id
left join quiet ON
liquid.liq_id=quiet.liq_id
group by liquid.movgest_ts_id
) as tz),
cofog as (
select distinct r.movgest_ts_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_movgest_class r,
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
--and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
)
, pdc5 as (
select distinct
r.movgest_ts_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- FINE SIAC-5883 Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pdc4 as (
select distinct r.movgest_ts_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- FINE SIAC-5883 Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, pce5 as (
select distinct r.movgest_ts_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pce4 as (
select distinct r.movgest_ts_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
),
impFlagAttivaGsa as -- 28.05.2018 Sofia siac-6102
(
select rattr.movgest_ts_id, rattr.boolean flag_attiva_gsa
from siac_r_movgest_ts_attr rattr, siac_t_attr attr
where attr.ente_proprietario_id=p_ente_proprietario_id
and   attr.attr_code='FlagAttivaGsa'
and   rattr.attr_id=attr.attr_id
and   rattr.data_cancellazione is null
and   rattr.validita_fine is null
),
-- SIAC-7541 23.04.2020 Sofia
struttura_comp as
(
 with
 impegno_ts as
 (
  select ts.movgest_id, ts.movgest_ts_id
  from siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipo
  where tipo.ente_proprietario_id=p_ente_proprietario_id
  and   tipo.movgest_ts_tipo_code='T'
  and   ts.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
 ),
 cdc_struttura_comp as
 (
 select rc.movgest_ts_id, c.classif_code, c.classif_desc
 from siac_r_movgest_class rc,siac_t_class c,siac_d_class_tipo tipo
 where tipo.ente_proprietario_id=p_ente_proprietario_id
 and   tipo.classif_tipo_code='CDC'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   rc.classif_id=c.classif_id
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null
 ),
 cdr_struttura_comp as
 (
 select rc.movgest_ts_id, c.classif_code, c.classif_desc
 from siac_r_movgest_class rc,siac_t_class c,siac_d_class_tipo tipo
 where tipo.ente_proprietario_id=p_ente_proprietario_id
 and   tipo.classif_tipo_code='CDR'
 and   c.classif_tipo_id=tipo.classif_tipo_id
 and   rc.classif_id=c.classif_id
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null
 )
 select impegno_Ts.movgest_id,
        cdr_struttura_comp.classif_code cod_cdr_struttura_comp,
        cdr_struttura_comp.classif_desc desc_cdr_struttura_comp,
        cdc_struttura_comp.classif_code cod_cdc_struttura_comp,
        cdc_struttura_comp.classif_code desc_cdc_struttura_comp
 from impegno_ts
      left join cdc_struttura_comp on  impegno_ts.movgest_ts_id=cdc_struttura_comp.movgest_ts_id
      left join cdr_struttura_comp on  impegno_ts.movgest_ts_id=cdr_struttura_comp.movgest_ts_id
) -- SIAC-7541 23.04.2020 Sofia
select
imp.ente_proprietario_id, imp.ente_denominazione, imp.anno,
imp.movgest_anno, imp.movgest_numero, imp.movgest_desc, imp.movgest_ts_code, imp.movgest_ts_desc,
imp.movgest_stato_code, imp.movgest_stato_desc,
imp.movgest_ts_scadenza_data, imp.parere_finanziario, imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_tipo_code,
cap.elem_code, cap.elem_code2, cap.elem_code3, cap.elem_desc, cap.elem_desc2,
imp.bil_id,
imp.data_inizio_val_stato_subimp,
imp.data_creazione_subimp,
imp.data_inizio_val_subimp,
imp.data_modifica_subimp,
imp.data_creazione_imp,
imp.data_inizio_val_imp,
imp.data_modifica_imp,
imp.fase_operativa_code, imp.fase_operativa_desc ,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale,
sogg.codice_fiscale_estero, sogg.partita_iva, sogg.soggetto_id
,sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
tipoimpegno.tipoimpegno_classif_code,
tipoimpegno.tipoimpegno_classif_desc,
ricorrentespesa.ricorrentespesa_classif_code,
ricorrentespesa.ricorrentespesa_classif_desc,
truespesa.truespesa_classif_code,
truespesa.truespesa_classif_desc,
persaspesa.persaspesa_classif_code,
persaspesa.persaspesa_classif_desc,
polregunitarie.polregunitarie_classif_code,
polregunitarie.polregunitarie_classif_desc,
cla11.cla11_classif_code,
cla11.cla11_classif_desc,
cla11.cla11_classif_tipo_code,
cla12.cla12_classif_code,
cla12.cla12_classif_desc,
cla12.cla12_classif_tipo_code,
cla13.cla13_classif_code,
cla13.cla13_classif_desc,
cla13.cla13_classif_tipo_code,
cla14.cla14_classif_code,
cla14.cla14_classif_desc,
cla14.cla14_classif_tipo_code,
cla15.cla15_classif_code,
cla15.cla15_classif_desc,
cla15.cla15_classif_tipo_code,
t_annoCapitoloOrigine.annoCapitoloOrigine,
t_numeroCapitoloOrigine.numeroCapitoloOrigine,
t_annoOriginePlur.annoOriginePlur,
t_numeroArticoloOrigine.numeroArticoloOrigine,
t_annoRiaccertato.annoRiaccertato,
t_numeroRiaccertato.numeroRiaccertato,
t_numeroOriginePlur.numeroOriginePlur,
t_flagDaRiaccertamento.flagDaRiaccertamento,
-- 19.02.2020 Sofia jira siac-7292
t_flagDaReanno.flagDaReanno,
t_numeroUEBOrigine.numeroUEBOrigine,
t_cig.cig,
t_cup.cup,
t_NOTE_MOVGEST.NOTE_MOVGEST,
t_validato.validato,
t_annoFinanziamento.annoFinanziamento,
t_numeroAccFinanziamento.numeroAccFinanziamento,
t_flagCassaEconomale.flagCassaEconomale,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
impattuale.importo_attuale,
impiniziale.importo_iniziale,
imputilizzabile.importo_utilizzabile,
impliquidatoemessoquietanziato.importo_liquidato,
impliquidatoemessoquietanziato.importo_emesso,
impliquidatoemessoquietanziato,importo_quietanziato,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagPrenotazione.flagPrenotazione, t_flagPrenotazioneLiquidabile.flagPrenotazioneLiquidabile,
t_flagFrazionabile.flagFrazionabile,
imp.siope_tipo_debito_code, imp.siope_tipo_debito_desc, imp.siope_tipo_debito_desc_bnkit,
imp.siope_assenza_motivazione_code, imp.siope_assenza_motivazione_desc, imp.siope_assenza_motivazione_desc_bnkit,
coalesce(impFlagAttivaGsa.flag_attiva_gsa,'N') flag_attiva_gsa, -- 28.05.2018 Sofia siac-6102
-- SIAC-7541 23.04.2020 Sofia
struttura_comp.cod_cdr_struttura_comp,
struttura_comp.desc_cdr_struttura_comp,
struttura_comp.cod_cdc_struttura_comp,
struttura_comp.desc_cdc_struttura_comp
from
imp left join cap
on
imp.movgest_id=cap.movgest_id
left join sogg
on
imp.movgest_ts_id=sogg.movgest_ts_id
left join sogcla
on
imp.movgest_ts_id=sogcla.movgest_ts_id
left join tipoimpegno
on
imp.movgest_ts_id=tipoimpegno.movgest_ts_id
left join ricorrentespesa
on
imp.movgest_ts_id=ricorrentespesa.movgest_ts_id
left join truespesa
on
imp.movgest_ts_id=truespesa.movgest_ts_id
left join persaspesa
on
imp.movgest_ts_id=persaspesa.movgest_ts_id
left join polregunitarie
on
imp.movgest_ts_id=polregunitarie.movgest_ts_id
left join cla11
on
imp.movgest_ts_id=cla11.movgest_ts_id
left join cla12
on
imp.movgest_ts_id=cla12.movgest_ts_id
left join cla13
on
imp.movgest_ts_id=cla13.movgest_ts_id
left join cla14
on
imp.movgest_ts_id=cla14.movgest_ts_id
left join cla15
on
imp.movgest_ts_id=cla15.movgest_ts_id
left join t_annoCapitoloOrigine
on
imp.movgest_ts_id=t_annoCapitoloOrigine.movgest_ts_id
left join t_numeroCapitoloOrigine
on
imp.movgest_ts_id=t_numeroCapitoloOrigine.movgest_ts_id
left join t_annoOriginePlur
on
imp.movgest_ts_id=t_annoOriginePlur.movgest_ts_id
left join t_numeroArticoloOrigine
on
imp.movgest_ts_id=t_numeroArticoloOrigine.movgest_ts_id
left join t_annoRiaccertato
on
imp.movgest_ts_id=t_annoRiaccertato.movgest_ts_id
left join t_numeroRiaccertato
on
imp.movgest_ts_id=t_numeroRiaccertato.movgest_ts_id
left join t_numeroOriginePlur
on
imp.movgest_ts_id=t_numeroOriginePlur.movgest_ts_id
left join t_flagDaRiaccertamento
on
imp.movgest_ts_id=t_flagDaRiaccertamento.movgest_ts_id
-- 19.02.2020 Sofia jira siac-7292
left join t_flagDaReanno
on
imp.movgest_ts_id=t_flagDaReanno.movgest_ts_id

left join t_numeroUEBOrigine
on
imp.movgest_ts_id=t_numeroUEBOrigine.movgest_ts_id
left join t_cig
on
imp.movgest_ts_id=t_cig.movgest_ts_id
left join t_cup
on
imp.movgest_ts_id=t_cup.movgest_ts_id
left join t_NOTE_MOVGEST
on
imp.movgest_ts_id=t_NOTE_MOVGEST.movgest_ts_id
left join t_validato
on
imp.movgest_ts_id=t_validato.movgest_ts_id
left join t_annoFinanziamento
on
imp.movgest_ts_id=t_annoFinanziamento.movgest_ts_id
left join t_numeroAccFinanziamento
on
imp.movgest_ts_id=t_numeroAccFinanziamento.movgest_ts_id
left join t_flagCassaEconomale
on
imp.movgest_ts_id=t_flagCassaEconomale.movgest_ts_id
left join attoamm
on
imp.movgest_ts_id=attoamm.movgest_ts_id
left join impattuale
on
imp.movgest_ts_id=impattuale.movgest_ts_id
left join impiniziale
on
imp.movgest_ts_id=impiniziale.movgest_ts_id
left join imputilizzabile
on
imp.movgest_ts_id=imputilizzabile.movgest_ts_id
left join impliquidatoemessoquietanziato
on
imp.movgest_ts_id=impliquidatoemessoquietanziato.movgest_ts_id
left join cofog
on
imp.movgest_ts_id=cofog.movgest_ts_id
left join pdc5
on
imp.movgest_ts_id=pdc5.movgest_ts_id
left join pdc4
on
imp.movgest_ts_id=pdc4.movgest_ts_id
left join pce5
on
imp.movgest_ts_id=pce5.movgest_ts_id
left join pce4
on
imp.movgest_ts_id=pce4.movgest_ts_id
left join t_flagPrenotazione
on
imp.movgest_ts_id=t_flagPrenotazione.movgest_ts_id
left join t_flagPrenotazioneLiquidabile
on
imp.movgest_ts_id=t_flagPrenotazioneLiquidabile.movgest_ts_id
left join t_flagFrazionabile
on
imp.movgest_ts_id=t_flagFrazionabile.movgest_ts_id
left join impFlagAttivaGsa  -- 28.05.2018 Sofia siac-6102
on
imp.movgest_ts_id=impFlagAttivaGsa.movgest_ts_id
-- SIAC-7541 23.04.2020 Sofia
left join struttura_comp
on
imp.movgest_id=struttura_comp.movgest_id
) xx
where xx.movgest_ts_tipo_code='S';

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

esito:='ok';

EXCEPTION
WHEN others THEN
  esito:='Funzione carico impegni (FNC_SIAC_DWH_IMPEGNO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
alter function siac.fnc_siac_dwh_impegno(varchar,integer,timestamp) owner to siac;

-- 24.05.2021 Sofia SIAC-8020 - fine


-- 7848
select fnc_siac_bko_inserisci_azione('OP-BKOF018-modificaModalitaPagamentoAttoAllegato', 'Atto allegato - Backoffice modifica modalita'' di pagamento', 
	'/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE');
	
--- INC000004766859
insert into siac_d_modifica_tipo
(
  mod_tipo_code,
  mod_tipo_desc,
  login_operazione,
  validita_inizio,
  ente_proprietario_id
)
select 'RIDCOI',
       'riduzione con contestuale prenotazione/impegno',
       'INC000004766859',
       to_timestamp('2020-01-01', 'yyyy-mm-dd'),
	   ente.ente_proprietario_id
from siac_t_ente_proprietario ente
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_modifica_tipo dbt
	WHERE dbt.ente_proprietario_id = ente.ente_proprietario_id
	AND dbt.mod_tipo_id=(SELECT mod_tipo_id
	 FROM siac_d_modifica_tipo
	 WHERE mod_tipo_code=TRIM('RIDCOI')  AND ente_proprietario_id=ente.ente_proprietario_id )
);

insert into  siac_r_modifica_tipo_applicazione
(mod_tipo_id,mod_tipo_appl_id  ,validita_inizio, ente_proprietario_id  ,login_operazione)
select tipo.mod_tipo_id, applicazione.mod_tipo_appl_id, to_timestamp('01/01/2020','dd/mm/yyyy'), ente.ente_proprietario_id, 'INC000004766859' 
from siac_t_ente_proprietario ente 
join siac_d_modifica_tipo tipo on tipo.ente_proprietario_id  = ente.ente_proprietario_id 
join siac_d_modifica_tipo_applicazione applicazione on (applicazione.ente_proprietario_id  = ente.ente_proprietario_id  and applicazione.ente_proprietario_id = ente.ente_proprietario_id)
where tipo.data_cancellazione  is null and applicazione .data_cancellazione  is null
and tipo.mod_tipo_code='RIDCOI' and applicazione.mod_tipo_appl_code='AGG-RID'
and not exists(
	select 1 from siac_r_modifica_tipo_applicazione r_app
	where r_app.ente_proprietario_id = ente.ente_proprietario_id 
	and r_app.mod_tipo_id  = tipo.mod_tipo_id 
	and r_app.mod_tipo_appl_id  = applicazione.mod_tipo_appl_id 
	and r_app.data_cancellazione is null
);

	
--INC000004766859
	


-- SIAC-8090



CREATE OR REPLACE FUNCTION siac.fnc_siac_verifica_importi_dopo_annullamento_modifica(idente integer, idbilancio integer, codicetipomovimento character varying, annomovimento integer, numeromovimento numeric)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE

siac_t_movgest_ts_det_A_row siac_t_movgest_ts_det%ROWTYPE;
movgest_ts_det_importo_I siac_t_movgest_ts_det.movgest_ts_det_importo%type;
movgest_ts_det_importo_sum siac_t_movgest_ts_det.movgest_ts_det_importo%type;

begin
	
  --return 'MANUTENZIONE IN CORSO';


	-- importo attuale	
	select stmtdm.* into siac_t_movgest_ts_det_A_row
	from siac_t_movgest_ts_det stmtdm, siac_t_movgest_ts stmt, siac_d_movgest_tipo sdmt,
	siac_t_movgest stm, siac_d_movgest_ts_det_tipo sdmtdt, siac_d_movgest_ts_tipo sdmtt 
	where 
	--
	stm.movgest_anno = annoMovimento 
	and stm.movgest_numero = numeroMovimento
	and stm.bil_id = idBilancio 
	and stm.ente_proprietario_id = idEnte
	--
	and stm.movgest_tipo_id = sdmt.movgest_tipo_id 
	and sdmt.movgest_tipo_code = codiceTipoMovimento
	and sdmt.ente_proprietario_id = stm.ente_proprietario_id 
	and	stmt.movgest_id = stm.movgest_id 
	and stmtdm.movgest_ts_id = stmt.movgest_ts_id 
	and stmtdm.movgest_ts_det_tipo_id = sdmtdt.movgest_ts_det_tipo_id 
	and sdmtdt.movgest_ts_det_tipo_code = 'A'
	and sdmtt.movgest_ts_tipo_id = stmt.movgest_ts_tipo_id 
	and sdmtt.movgest_ts_tipo_code = 'T'
	and sdmtt.ente_proprietario_id = stm.ente_proprietario_id
	and stmtdm.data_cancellazione is NULL
	AND stmtdm.validita_inizio < CURRENT_TIMESTAMP    
	AND (stmtdm.validita_fine IS NULL OR stmtdm.validita_fine > CURRENT_TIMESTAMP)
	;

	-- importo iniziale
	select movgest_ts_det_importo into movgest_ts_det_importo_I
	from siac_t_movgest_ts_det stmtdm, siac_t_movgest_ts stmt, siac_d_movgest_tipo sdmt,
	siac_t_movgest stm, siac_d_movgest_ts_det_tipo sdmtdt, siac_d_movgest_ts_tipo sdmtt 
	where 
	--
	stm.movgest_anno = annoMovimento 
	and stm.movgest_numero = numeroMovimento
	and stm.bil_id = idBilancio 
	and stm.ente_proprietario_id = idEnte
	--
	and stm.movgest_tipo_id = sdmt.movgest_tipo_id 
	and sdmt.movgest_tipo_code = codiceTipoMovimento
	and sdmt.ente_proprietario_id = stm.ente_proprietario_id 
	and	stmt.movgest_id = stm.movgest_id 
	and stmtdm.movgest_ts_id = stmt.movgest_ts_id 
	and stmtdm.movgest_ts_det_tipo_id = sdmtdt.movgest_ts_det_tipo_id 
	and sdmtdt.movgest_ts_det_tipo_code = 'I'
	and sdmtt.movgest_ts_tipo_id = stmt.movgest_ts_tipo_id 
	and sdmtt.movgest_ts_tipo_code = 'T'
	and sdmtt.ente_proprietario_id = stm.ente_proprietario_id
	and stmtdm.data_cancellazione is NULL
	AND stmtdm.validita_inizio < CURRENT_TIMESTAMP    
	AND (stmtdm.validita_fine IS NULL OR stmtdm.validita_fine > CURRENT_TIMESTAMP)  
    ;
	
	-- somma delle modifiche
	select coalesce(sum(stmtdm.movgest_ts_det_importo), 0) into movgest_ts_det_importo_sum
	from siac_t_movgest_ts_det_mod stmtdm, siac_r_modifica_stato srms , siac_d_modifica_stato sdms ,
	siac_t_movgest_ts stmt, siac_d_movgest_ts_tipo sdmtt, siac_t_movgest stm, siac_d_movgest_tipo sdmt, siac_d_movgest_ts_det_tipo sdmtdt
	where  
	--
	stm.movgest_anno = annoMovimento 
	and stm.movgest_numero = numeroMovimento
	and stm.bil_id = idBilancio 
	and stm.ente_proprietario_id = idEnte
	--
	and stm.movgest_tipo_id = sdmt.movgest_tipo_id 
	and sdmt.movgest_tipo_code = codiceTipoMovimento
	and sdmt.ente_proprietario_id = stm.ente_proprietario_id 
	and srms.mod_stato_r_id = stmtdm.mod_stato_r_id
	and sdms.mod_stato_id = srms.mod_stato_id 
	and sdms.mod_stato_code != 'A' 
	and stmt.movgest_id =stm.movgest_id 
	and stmtdm.movgest_ts_id = stmt.movgest_ts_id 
	and sdmtt.movgest_ts_tipo_id = stmt.movgest_ts_tipo_id 
	and sdmtt.movgest_ts_tipo_code = 'T'
	and sdmtt.ente_proprietario_id = stm.ente_proprietario_id 
	and	stmt.movgest_id = stm.movgest_id 
	and sdmtdt.movgest_ts_det_tipo_id=stmtdm.movgest_ts_det_tipo_id
	and sdmtdt.movgest_ts_det_tipo_code = 'A' 
	and sdmtdt.ente_proprietario_id = stm.ente_proprietario_id
	and stmtdm.data_cancellazione is NULL
	AND stmtdm.validita_inizio < CURRENT_TIMESTAMP    
	AND (stmtdm.validita_fine IS NULL OR stmtdm.validita_fine > CURRENT_TIMESTAMP)  
	and srms.data_cancellazione is NULL
	AND srms.validita_inizio < CURRENT_TIMESTAMP    
	AND (srms.validita_fine IS NULL OR srms.validita_fine > CURRENT_TIMESTAMP)  
	;

	if siac_t_movgest_ts_det_A_row.movgest_ts_det_importo != movgest_ts_det_importo_I + movgest_ts_det_importo_sum    
	then
		update siac_t_movgest_ts_det set
		movgest_ts_det_importo=movgest_ts_det_importo_I + movgest_ts_det_importo_sum,
		login_operazione = concat('fnc_siac_verifica_importi - ', login_operazione) 
		where movgest_ts_det_id=siac_t_movgest_ts_det_A_row.movgest_ts_det_id;	
	
		return  'fnc_siac_verifica_importi_dopo_annullamento_modifica: presente incongruenza - '||
				annoMovimento||'/'||numeroMovimento||
				'/idBilancio:'||idBilancio||
				'/movgest_ts_det_id:'||siac_t_movgest_ts_det_A_row.movgest_ts_det_id||
				'/importo_attuale:'||coalesce(siac_t_movgest_ts_det_A_row.movgest_ts_det_importo::text,'')||
				'/importo_iniziale:'||coalesce(movgest_ts_det_importo_I::text,'')||
				'/somma_importi_modifiche:'||coalesce(movgest_ts_det_importo_sum::text,'')
		;
/*	else
		return  'fnc_siac_verifica_importi_dopo_annullamento_modifica: OK - '||
				annoMovimento||'/'||numeroMovimento||
				'/idBilancio:'||idBilancio||
				'/movgest_ts_det_id:'||siac_t_movgest_ts_det_A_row.movgest_ts_det_id||
				'/importo_attuale:'||coalesce(siac_t_movgest_ts_det_A_row.movgest_ts_det_importo::text,'')||
				'/importo_iniziale:'||coalesce(movgest_ts_det_importo_I::text,'')||
				'/somma_importi_modifiche:'||coalesce(movgest_ts_det_importo_sum::text,'')
		; */
	end if;
	
	
    return null;

exception
        when others  THEN
            return 'ERR: ' || SQLERRM;
END;
$function$
;

-- SIAC-8090 fine