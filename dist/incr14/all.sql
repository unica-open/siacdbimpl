/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5323 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR131_saldo_economico_patrimoniale" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar,
  p_liv_aggiuntivi varchar,
  p_tipo_stampa integer
)
RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  tipo_pnota varchar,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  cod_bil0 varchar,
  cod_bil1 varchar,
  cod_bil2 varchar,
  cod_bil3 varchar,
  cod_bil4 varchar,
  cod_bil5 varchar,
  cod_bil6 varchar,
  cod_bil7 varchar,
  cod_bil8 varchar
) AS
$body$
DECLARE
elenco_prime_note record;
sql_query varchar;
sql_query_add varchar;
sql_query_add1 varchar;
v_pdce_conto_id integer; 
v_classif_id integer;
v_classif_id_padre integer;
v_classif_id_part integer;
v_conta_ciclo_classif integer;
v_classif_code_app varchar;
v_livello integer;
v_ordine varchar;
v_conta_rec integer;
v_cod_bil_parziale varchar;
v_posiz_punto integer;
v_classificatori varchar;
v_classificatori1 varchar;
v_classificatori2 varchar;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		 varchar(1000):=DEF_NULL;
user_table			 varchar;

BEGIN

nome_ente='';
id_pdce0=0;
codice_pdce0='';
descr_pdce0='';
id_pdce1=0;
codice_pdce1='';
descr_pdce1='';
id_pdce2=0;
codice_pdce2='';
descr_pdce2='';
id_pdce3=0;
codice_pdce3='';
descr_pdce3='';        
id_pdce4=0;
codice_pdce4='';
descr_pdce4='';   
id_pdce5=0;
codice_pdce5='';
descr_pdce5='';   
id_pdce6=0;
codice_pdce6='';
descr_pdce6='';   
id_pdce7=0;
codice_pdce7='';
descr_pdce7='';    
id_pdce8=0;
codice_pdce8='';
descr_pdce8='';         
tipo_pnota='';
importo_dare=0;
importo_avere=0;
livello=0;
saldo_prec_dare=0;
saldo_prec_avere=0;
saldo_ini_dare=0;
saldo_ini_avere=0;
cod_bil0='';
cod_bil1='';
cod_bil2='';
cod_bil3='';
cod_bil4='';
cod_bil5='';
cod_bil6='';
cod_bil7='';
cod_bil8='';  

SELECT fnc_siac_random_user()
INTO   user_table;
	
/* carico l'intera struttura PDCE */
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';
raise notice 'ora: % ',clock_timestamp()::varchar;

SELECT a.ente_denominazione
INTO  nome_ente
FROM  siac_t_ente_proprietario a
WHERE a.ente_proprietario_id = p_ente_prop_id;

INSERT INTO siac_rep_struttura_pdce
SELECT v.*, user_table FROM
(SELECT t_pdce_conto0.pdce_conto_id pdce_liv0_id, t_pdce_conto0.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto0.pdce_conto_code pdce_liv0_code, t_pdce_conto0.pdce_conto_desc pdce_liv0_desc,
		t_pdce_conto1.pdce_conto_id pdce_liv1_id, t_pdce_conto1.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto1.pdce_conto_code pdce_liv1_code, t_pdce_conto1.pdce_conto_desc pdce_liv1_desc,
		t_pdce_conto2.pdce_conto_id pdce_liv2_id, t_pdce_conto2.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto2.pdce_conto_code pdce_liv2_code, t_pdce_conto2.pdce_conto_desc pdce_liv2_desc,
		t_pdce_conto3.pdce_conto_id pdce_liv3_id, t_pdce_conto3.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto3.pdce_conto_code pdce_liv3_code, t_pdce_conto3.pdce_conto_desc pdce_liv3_desc,
		t_pdce_conto4.pdce_conto_id pdce_liv4_id, t_pdce_conto4.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto4.pdce_conto_code pdce_liv4_code, t_pdce_conto4.pdce_conto_desc pdce_liv4_desc,
		t_pdce_conto5.pdce_conto_id pdce_liv5_id, t_pdce_conto5.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto5.pdce_conto_code pdce_liv5_code, t_pdce_conto5.pdce_conto_desc pdce_liv5_desc,
		t_pdce_conto6.pdce_conto_id pdce_liv6_id, t_pdce_conto6.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto6.pdce_conto_code pdce_liv6_code, t_pdce_conto6.pdce_conto_desc pdce_liv6_desc,
		t_pdce_conto7.pdce_conto_id pdce_liv7_id, t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto7.pdce_conto_code pdce_liv7_code, t_pdce_conto7.pdce_conto_desc pdce_liv7_desc,
		t_pdce_conto8.pdce_conto_id pdce_liv8_id, t_pdce_conto8.pdce_conto_id_padre pdce_liv0_id_padre, t_pdce_conto8.pdce_conto_code pdce_liv8_code, t_pdce_conto8.pdce_conto_desc pdce_liv8_desc
 FROM siac_t_pdce_conto t_pdce_conto0, siac_t_pdce_conto t_pdce_conto1
 LEFT JOIN siac_t_pdce_conto t_pdce_conto2
      ON (t_pdce_conto1.pdce_conto_id=t_pdce_conto2.pdce_conto_id_padre
          AND t_pdce_conto2.livello=2 and t_pdce_conto2.data_cancellazione is NULL
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto3
      ON (t_pdce_conto2.pdce_conto_id=t_pdce_conto3.pdce_conto_id_padre
    	  AND t_pdce_conto3.livello=3 and t_pdce_conto3.data_cancellazione is NULL
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto4
      ON (t_pdce_conto3.pdce_conto_id=t_pdce_conto4.pdce_conto_id_padre
    	  AND t_pdce_conto4.livello=4 and t_pdce_conto4.data_cancellazione is NULL
         )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto5
      ON (t_pdce_conto4.pdce_conto_id=t_pdce_conto5.pdce_conto_id_padre
          AND t_pdce_conto5.livello=5 and t_pdce_conto5.data_cancellazione is NULL
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto6
      ON (t_pdce_conto5.pdce_conto_id=t_pdce_conto6.pdce_conto_id_padre
          AND t_pdce_conto6.livello=6 and t_pdce_conto6.data_cancellazione is NULL
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto7
      ON (t_pdce_conto6.pdce_conto_id=t_pdce_conto7.pdce_conto_id_padre
          AND t_pdce_conto7.livello=7 and t_pdce_conto7.data_cancellazione is NULL
          )         
 LEFT JOIN siac_t_pdce_conto t_pdce_conto8
      ON (t_pdce_conto7.pdce_conto_id=t_pdce_conto8.pdce_conto_id_padre
          AND t_pdce_conto8.livello=8 and t_pdce_conto8.data_cancellazione is NULL
          )                           
 WHERE t_pdce_conto0.pdce_conto_id=t_pdce_conto1.pdce_conto_id_padre
 AND t_pdce_conto0.livello=0
 AND t_pdce_conto1.livello=1
 AND t_pdce_conto0.ente_proprietario_id=p_ente_prop_id
 AND t_pdce_conto0.data_cancellazione is NULL
 AND t_pdce_conto1.data_cancellazione is NULL
 ORDER BY t_pdce_conto0.pdce_conto_code,
          t_pdce_conto1.pdce_conto_code, t_pdce_conto2.pdce_conto_code,
          t_pdce_conto3.pdce_conto_code, t_pdce_conto4.pdce_conto_code,
		  t_pdce_conto5.pdce_conto_code, t_pdce_conto6.pdce_conto_code,
		  t_pdce_conto7.pdce_conto_code, t_pdce_conto8.pdce_conto_code) v;

raise notice 'ora: % ',clock_timestamp()::varchar;

RTN_MESSAGGIO:='Estrazione dei dati codice bilancio''.';
raise notice 'Estrazione dei dati codice bilancio';

v_classificatori  := '';
v_classificatori1 := '';
v_classificatori2 := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL'; 
   v_classificatori1 := '00022'; -- 'SPP_CODBIL';
   v_classificatori2 := '00023'; -- 'CO_CODBIL';
END IF;

INSERT INTO siac_rep_raccordo_pdce_bil
SELECT a.ente_proprietario_id,
       null,
       a.classif_id,
       0,
       0,
       a.ordine, 
       user_table
FROM   siac_r_class_fam_tree a, siac_t_class_fam_tree b, siac_d_class_fam c
WHERE a.classif_fam_tree_id = b.classif_fam_tree_id
AND   c.classif_fam_id = b.classif_fam_id
AND   a.ente_proprietario_id = p_ente_prop_id
AND   (c.classif_fam_code = v_classificatori OR c.classif_fam_code = v_classificatori1 OR c.classif_fam_code = v_classificatori2)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL 
AND   c.data_cancellazione IS NULL;
/*SELECT  
       tb.ente_proprietario_id, 
       t1.classif_code,
       tb.classif_id, 
       tb.classif_id_padre,
       tb.level,
       tb.ordine, 
       user_table
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
       FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
       WHERE cf.classif_fam_id = tt1.classif_fam_id 
       AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
       AND   rt1.classif_id_padre IS NULL 
       AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1 OR cf.classif_fam_code = v_classificatori2)
       AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
       AND date_trunc('day'::text, now()) > tt1.validita_inizio 
       AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
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
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre 
    AND tn.ente_proprietario_id = tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id,
           rqname.classif_fam_tree_id,
           rqname.classif_id,
           rqname.classif_id_padre,
           rqname.ente_proprietario_id,
           rqname.ordine, rqname.livello,
           rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb,
    siac_t_class t1, siac_d_class_tipo ti1
WHERE tb.ente_proprietario_id  = p_ente_prop_id
AND  t1.classif_id = tb.classif_id           
AND  ti1.classif_tipo_id = t1.classif_tipo_id 
AND  t1.ente_proprietario_id = tb.ente_proprietario_id 
AND  ti1.ente_proprietario_id = t1.ente_proprietario_id;*/

raise notice 'ora: % ',clock_timestamp()::varchar;

RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

/* estrazione dei dati delle prime note */
IF p_classificatori = '1' THEN 
   sql_query_add := ' AND pdce_fam.pdce_fam_code IN (''CE'',''RE'') ';
   sql_query_add1 := ' AND strutt_pdce.pdce_liv0_code IN (''CE'',''RE'') ';
ELSIF p_classificatori = '2' THEN   
   sql_query_add := ' AND pdce_fam.pdce_fam_code IN (''AP'',''PP'',''OP'',''OA'') '; 
   sql_query_add1 := ' AND strutt_pdce.pdce_liv0_code IN (''AP'',''PP'',''OP'',''OA'') ';
END IF;      

IF p_tipo_stampa = 1 THEN -- Stampo solo i piani dei conti legati ad importi
    
    sql_query := 
    'SELECT pdce_conto.pdce_conto_id,
            pdce_conto.livello,
            d_tipo_causale.causale_ep_tipo_code,                
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo,
            pdce_fam.pdce_fam_code,
            strutt_pdce.*          
    FROM   siac_t_periodo	 		anno_eserc,	
           siac_t_bil	 			bilancio,
           siac_t_prima_nota        prima_nota,
           siac_t_mov_ep_det	    mov_ep_det,
           siac_r_prima_nota_stato  r_pnota_stato,
           siac_d_prima_nota_stato  pnota_stato,
           siac_t_pdce_conto	    pdce_conto,
           siac_t_pdce_fam_tree     pdce_fam_tree,
           siac_d_pdce_fam          pdce_fam,
           siac_t_causale_ep	    causale_ep,
           siac_d_causale_ep_tipo   d_tipo_causale,
           siac_rep_struttura_pdce  strutt_pdce,
           siac_t_mov_ep		    mov_ep     
    WHERE  bilancio.periodo_id=anno_eserc.periodo_id	
    AND    prima_nota.bil_id=bilancio.bil_id
    AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
    AND    prima_nota.pnota_id=mov_ep.regep_id
    AND    mov_ep.movep_id=mov_ep_det.movep_id
    AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
    AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
    AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
    AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
    AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
    AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
    AND    d_tipo_causale.causale_ep_tipo_id=causale_ep.causale_ep_tipo_id 
    AND   ((pdce_conto.livello=0 
                AND strutt_pdce.pdce_liv0_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=1 
                AND strutt_pdce.pdce_liv1_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=2 
                AND strutt_pdce.pdce_liv2_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=3 
                AND strutt_pdce.pdce_liv3_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=4 
                AND strutt_pdce.pdce_liv4_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=5 
                AND strutt_pdce.pdce_liv5_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=6 
                AND strutt_pdce.pdce_liv6_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=7 
                AND strutt_pdce.pdce_liv7_id=pdce_conto.pdce_conto_id)
            OR (pdce_conto.livello=8 
                AND strutt_pdce.pdce_liv8_id=pdce_conto.pdce_conto_id))
    AND prima_nota.ente_proprietario_id='||p_ente_prop_id||'   
    AND anno_eserc.anno='''||p_anno||'''
    AND pnota_stato.pnota_stato_code=''D'''
    ||sql_query_add||' 
    AND strutt_pdce.utente='''||user_table||'''
    AND bilancio.data_cancellazione is NULL
    AND anno_eserc.data_cancellazione is NULL
    AND prima_nota.data_cancellazione is NULL
    AND mov_ep.data_cancellazione is NULL
    AND mov_ep_det.data_cancellazione is NULL
    AND r_pnota_stato.data_cancellazione is NULL
    AND pnota_stato.data_cancellazione is NULL
    AND pdce_conto.data_cancellazione is NULL
    AND pdce_fam_tree.data_cancellazione is NULL
    AND pdce_fam.data_cancellazione is NULL
    AND (causale_ep.data_cancellazione is NULL
         OR 
         causale_ep.data_cancellazione BETWEEN to_timestamp(''01/01/'||p_anno||''', ''dd/mm/yyyy'') AND now()
         ) 
    AND d_tipo_causale.data_cancellazione is NULL';
    
ELSIF p_tipo_stampa = 2 THEN  -- Stampo tutti i piani dei conti legati o meno ad importi

 sql_query := 
 'WITH a AS(SELECT 
  strutt_pdce.pdce_liv0_id,
  strutt_pdce.pdce_liv0_id_padre,
  strutt_pdce.pdce_liv0_code,
  strutt_pdce.pdce_liv0_desc,
  strutt_pdce.pdce_liv1_id,
  strutt_pdce.pdce_liv1_id_padre,
  strutt_pdce.pdce_liv1_code,
  strutt_pdce.pdce_liv1_desc,
  strutt_pdce.pdce_liv2_id,
  strutt_pdce.pdce_liv2_id_padre,
  strutt_pdce.pdce_liv2_code,
  strutt_pdce.pdce_liv2_desc,
  strutt_pdce.pdce_liv3_id,
  strutt_pdce.pdce_liv3_id_padre,
  strutt_pdce.pdce_liv3_code,
  strutt_pdce.pdce_liv3_desc,
  strutt_pdce.pdce_liv4_id,
  strutt_pdce.pdce_liv4_id_padre,
  strutt_pdce.pdce_liv4_code,
  strutt_pdce.pdce_liv4_desc,
  strutt_pdce.pdce_liv5_id,
  strutt_pdce.pdce_liv5_id_padre,
  strutt_pdce.pdce_liv5_code,
  strutt_pdce.pdce_liv5_desc,
  strutt_pdce.pdce_liv6_id,
  strutt_pdce.pdce_liv6_id_padre,
  strutt_pdce.pdce_liv6_code,
  strutt_pdce.pdce_liv6_desc,
  strutt_pdce.pdce_liv7_id ,
  strutt_pdce.pdce_liv7_id_padre,
  strutt_pdce.pdce_liv7_code,
  strutt_pdce.pdce_liv7_desc,
  strutt_pdce.pdce_liv8_id,
  strutt_pdce.pdce_liv8_id_padre,
  strutt_pdce.pdce_liv8_code,
  strutt_pdce.pdce_liv8_desc,
  strutt_pdce.utente
FROM siac_rep_struttura_pdce strutt_pdce
WHERE strutt_pdce.utente='''||user_table||'''
'||sql_query_add1||'
)
, b AS (SELECT pdce_conto.pdce_conto_id,
               pdce_conto.livello,
               d_tipo_causale.causale_ep_tipo_code,                
               mov_ep_det.movep_det_segno, 
               mov_ep_det.movep_det_importo,
               pdce_fam.pdce_fam_code               
FROM   siac_t_periodo	 		anno_eserc,	
       siac_t_bil	 			bilancio,
       siac_t_prima_nota        prima_nota,
       siac_t_mov_ep_det	    mov_ep_det,
       siac_r_prima_nota_stato  r_pnota_stato,
       siac_d_prima_nota_stato  pnota_stato,
       siac_t_pdce_conto	    pdce_conto,
       siac_t_pdce_fam_tree     pdce_fam_tree,
       siac_d_pdce_fam          pdce_fam,
       siac_t_causale_ep	    causale_ep,
       siac_d_causale_ep_tipo   d_tipo_causale,
       siac_t_mov_ep		    mov_ep     
WHERE  bilancio.periodo_id=anno_eserc.periodo_id
AND    prima_nota.bil_id=bilancio.bil_id
AND    prima_nota.ente_proprietario_id=anno_eserc.ente_proprietario_id
AND    prima_nota.pnota_id=mov_ep.regep_id
AND    mov_ep.movep_id=mov_ep_det.movep_id
AND    r_pnota_stato.pnota_id=prima_nota.pnota_id
AND    pnota_stato.pnota_stato_id=r_pnota_stato.pnota_stato_id
AND    pdce_conto.pdce_conto_id=mov_ep_det.pdce_conto_id
AND    pdce_conto.pdce_fam_tree_id=pdce_fam_tree.pdce_fam_tree_id
AND    pdce_fam_tree.pdce_fam_id=pdce_fam.pdce_fam_id
AND    causale_ep.causale_ep_id=mov_ep.causale_ep_id
AND    d_tipo_causale.causale_ep_tipo_id=causale_ep.causale_ep_tipo_id 
AND prima_nota.ente_proprietario_id='||p_ente_prop_id||'   
AND anno_eserc.anno='''||p_anno||'''
AND pnota_stato.pnota_stato_code=''D'''
||sql_query_add||'
AND bilancio.data_cancellazione is NULL
AND anno_eserc.data_cancellazione is NULL
AND prima_nota.data_cancellazione is NULL
AND mov_ep.data_cancellazione is NULL
AND mov_ep_det.data_cancellazione is NULL
AND r_pnota_stato.data_cancellazione is NULL
AND pnota_stato.data_cancellazione is NULL
AND pdce_conto.data_cancellazione is NULL
AND pdce_fam_tree.data_cancellazione is NULL
AND pdce_fam.data_cancellazione is NULL
AND (causale_ep.data_cancellazione is NULL
     OR 
     causale_ep.data_cancellazione BETWEEN to_timestamp(''01/01/'||p_anno||''', ''dd/mm/yyyy'') AND now()
     ) 
AND d_tipo_causale.data_cancellazione is NULL
)
SELECT a.*,
b.pdce_conto_id,
b.livello,
b.causale_ep_tipo_code,                
b.movep_det_segno, 
b.movep_det_importo,
b.pdce_fam_code
FROM a
LEFT JOIN b ON
((b.livello=0 AND a.pdce_liv0_id=b.pdce_conto_id)
  OR (b.livello=1 
      AND a.pdce_liv1_id=b.pdce_conto_id)
  OR (b.livello=2 
      AND a.pdce_liv2_id=b.pdce_conto_id)
  OR (b.livello=3 
      AND a.pdce_liv3_id=b.pdce_conto_id)
  OR (b.livello=4 
      AND a.pdce_liv4_id=b.pdce_conto_id)
  OR (b.livello=5 
      AND a.pdce_liv5_id=b.pdce_conto_id)
  OR (b.livello=6 
      AND a.pdce_liv6_id=b.pdce_conto_id)
  OR (b.livello=7 
      AND a.pdce_liv7_id=b.pdce_conto_id)
  OR (b.livello=8 
      AND a.pdce_liv8_id=b.pdce_conto_id))';

END IF;
raise notice 'SQL % ',sql_query;
FOR elenco_prime_note IN
EXECUTE sql_query
        
LOOP
    
    saldo_prec_dare=0;
	saldo_prec_avere=0;
	saldo_ini_dare=0;
    saldo_ini_avere=0;
    
    v_pdce_conto_id := null;
    
    IF elenco_prime_note.pdce_liv8_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv8_id;
    ELSIF  elenco_prime_note.pdce_liv7_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv7_id;
    ELSIF  elenco_prime_note.pdce_liv6_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv6_id; 
    ELSIF  elenco_prime_note.pdce_liv5_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv5_id; 
    ELSIF  elenco_prime_note.pdce_liv4_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv4_id; 
    ELSIF  elenco_prime_note.pdce_liv3_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv3_id; 
    ELSIF  elenco_prime_note.pdce_liv2_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv2_id; 
    ELSIF  elenco_prime_note.pdce_liv1_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv1_id; 
    ELSIF  elenco_prime_note.pdce_liv0_code IS NOT NULL THEN
       v_pdce_conto_id := elenco_prime_note.pdce_liv0_id; 
    END IF;                                                         
           
    v_classif_id := null;
            
    SELECT rpcc.classif_id
    INTO   v_classif_id
    FROM   siac_r_pdce_conto_class rpcc
    WHERE  rpcc.pdce_conto_id = v_pdce_conto_id
    AND    rpcc.data_cancellazione IS NULL; 

    v_conta_ciclo_classif :=0;   
    v_classif_id_padre := null;
    cod_bil0='';
    cod_bil1='';
    cod_bil2='';
    cod_bil3='';
    cod_bil4='';
    cod_bil5='';
    cod_bil6='';
    cod_bil7='';
    cod_bil8='';  

    v_ordine := '';

    SELECT a.ordine
    INTO   v_ordine
    FROM siac_rep_raccordo_pdce_bil a
    WHERE a.classif_id = v_classif_id
    AND   a.utente = user_table;
            
    cod_bil0 := replace(v_ordine,'.','  ');
    
    -- Da ripristinare nel caso si voglia scomporre il valore di v_ordine
    -- per ripartirlo su piu' colonne
/*    v_conta_rec := 1;
    v_cod_bil_parziale := null;
    v_posiz_punto := 0;
    
   LOOP
    
        v_posiz_punto := POSITION('.' in COALESCE(v_cod_bil_parziale,v_ordine));
        
        IF v_conta_rec = 1 THEN
           IF v_posiz_punto <> 0 THEN
              cod_bil1 := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);     
           ELSE
              cod_bil1 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;   
        ELSIF v_conta_rec = 2 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil2 := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);        
           ELSE
              cod_bil2 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;          ELSIF v_conta_rec = 3 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil3 := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);
           ELSE
              cod_bil3 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;                  
        ELSIF v_conta_rec = 4 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil4 := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);   
           ELSE
              cod_bil4 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;                
        ELSIF v_conta_rec = 5 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil5:= SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);   
           ELSE
              cod_bil5 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;                
        ELSIF v_conta_rec = 6 THEN
           IF v_posiz_punto <> 0 THEN        
              cod_bil6:= SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from 1 for  position('.' in COALESCE(v_cod_bil_parziale,v_ordine))-1);  
           ELSE
              cod_bil6 := COALESCE(v_cod_bil_parziale,v_ordine);
           END IF;                
        END IF;           
        
        v_cod_bil_parziale := SUBSTRING(COALESCE(v_cod_bil_parziale,v_ordine) from position('.' in COALESCE(v_cod_bil_parziale,v_ordine))+1);
                     
        v_conta_rec := v_conta_rec + 1;
        
    	EXIT WHEN v_posiz_punto = 0;
    
    END LOOP;*/                  
     
    tipo_pnota=elenco_prime_note.causale_ep_tipo_code;
    id_pdce0=COALESCE(elenco_prime_note.pdce_liv0_id,0);
    codice_pdce0=COALESCE(elenco_prime_note.pdce_liv0_code,'');
    descr_pdce0=COALESCE(elenco_prime_note.pdce_liv0_desc,'');
    
    id_pdce1=COALESCE(elenco_prime_note.pdce_liv1_id,0);
    codice_pdce1=COALESCE(elenco_prime_note.pdce_liv1_code,'');
    descr_pdce1=COALESCE(elenco_prime_note.pdce_liv1_desc,'');
    
    id_pdce2=COALESCE(elenco_prime_note.pdce_liv2_id,0);
    codice_pdce2=COALESCE(elenco_prime_note.pdce_liv2_code,'');
    descr_pdce2=COALESCE(elenco_prime_note.pdce_liv2_desc,'');
    
    id_pdce3=COALESCE(elenco_prime_note.pdce_liv3_id,0);
    codice_pdce3=COALESCE(elenco_prime_note.pdce_liv3_code,'');
    descr_pdce3=COALESCE(elenco_prime_note.pdce_liv3_desc,'');  
          
    id_pdce4=COALESCE(elenco_prime_note.pdce_liv4_id,0);
    codice_pdce4=COALESCE(elenco_prime_note.pdce_liv4_code,'');
    descr_pdce4=COALESCE(elenco_prime_note.pdce_liv4_desc,''); 
      
    id_pdce5=COALESCE(elenco_prime_note.pdce_liv5_id,0);
    codice_pdce5=COALESCE(elenco_prime_note.pdce_liv5_code,'');
    descr_pdce5=COALESCE(elenco_prime_note.pdce_liv5_desc,'');  
     
    id_pdce6=COALESCE(elenco_prime_note.pdce_liv6_id,0);
    codice_pdce6=COALESCE(elenco_prime_note.pdce_liv6_code,'');
    descr_pdce6=COALESCE(elenco_prime_note.pdce_liv6_desc,''); 
      
    IF p_liv_aggiuntivi = 'N' AND p_classificatori = '1' THEN    
       id_pdce7=0;
       codice_pdce7='';
       descr_pdce7='';         
    ELSE   
       id_pdce7=COALESCE(elenco_prime_note.pdce_liv7_id,0);
       codice_pdce7=COALESCE(elenco_prime_note.pdce_liv7_code,'');
       descr_pdce7=COALESCE(elenco_prime_note.pdce_liv7_desc,'');
    END IF;
    
    IF p_liv_aggiuntivi = 'N' AND p_classificatori <> '1' THEN     
       id_pdce8=0;
       codice_pdce8='';
       descr_pdce8='';          
    ELSE          
       id_pdce8=COALESCE(elenco_prime_note.pdce_liv8_id,0);
       codice_pdce8=COALESCE(elenco_prime_note.pdce_liv8_code,'');
       descr_pdce8=COALESCE(elenco_prime_note.pdce_liv8_desc,'');      
    END IF;
    
    livello=elenco_prime_note.livello;

    IF upper(elenco_prime_note.movep_det_segno)='AVERE' THEN               
            importo_dare=0;
            importo_avere=COALESCE(elenco_prime_note.movep_det_importo,0);               
    ELSE                
            importo_dare=COALESCE(elenco_prime_note.movep_det_importo,0);
            importo_avere=0;                          
    END IF; 
    
    --raise notice 'importo dare = %, importo avere = %',importo_dare,importo_avere;

    return next;
    nome_ente='';
    id_pdce0=0;
    codice_pdce0='';
    descr_pdce0='';
    id_pdce1=0;
    codice_pdce1='';
    descr_pdce1='';
    id_pdce2=0;
    codice_pdce2='';
    descr_pdce2='';
    id_pdce3=0;
    codice_pdce3='';
    descr_pdce3='';        
    id_pdce4=0;
    codice_pdce4='';
    descr_pdce4='';   
    id_pdce5=0;
    codice_pdce5='';
    descr_pdce5='';   
    id_pdce6=0;
    codice_pdce6='';
    descr_pdce6='';   
    id_pdce7=0;
    codice_pdce7='';
    descr_pdce7='';    
    id_pdce8=0;
    codice_pdce8='';
    descr_pdce8='';   
    tipo_pnota='';
    importo_dare=0;
    importo_avere=0;
    livello=0;
    cod_bil0='';
    cod_bil1='';
    cod_bil2='';
    cod_bil3='';
    cod_bil4='';
    cod_bil5='';
    cod_bil6='';
    cod_bil7='';
    cod_bil8='';     
 
END LOOP;  
          
raise notice 'ora: % ',clock_timestamp()::varchar;            

delete from siac_rep_struttura_pdce where utente=user_table;
delete from siac_rep_raccordo_pdce_bil where utente=user_table;
  
EXCEPTION
	when no_data_found THEN
		 raise notice 'Dati non trovati' ;
	when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'SALDO PDCE',substring(SQLERRM from 1 for 500);
         return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5323 FINE

-- SIAC-5361 INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_capitolo_spesa (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

  rec_elem_id record;
  rec_classif_id record;
  rec_attr record;
  rec_elem_dett record;
  -- Variabili per campi estratti dal cursore rec_elem_id
  v_ente_proprietario_id INTEGER := null;
  v_ente_denominazione VARCHAR := null;
  v_anno VARCHAR := null;
  v_fase_operativa_code VARCHAR := null;
  v_fase_operativa_desc VARCHAR := null;
  v_elem_code VARCHAR := null;
  v_elem_code2 VARCHAR := null;
  v_elem_code3 VARCHAR := null;
  v_elem_desc VARCHAR := null;
  v_elem_desc2 VARCHAR := null;
  v_elem_tipo_code VARCHAR := null;
  v_elem_tipo_desc VARCHAR := null;
  v_elem_stato_code VARCHAR := null;
  v_elem_stato_desc VARCHAR := null;
  v_elem_cat_code VARCHAR := null;
  v_elem_cat_desc VARCHAR := null;
  -- Variabili per classificatori in gerarchia
  v_codice_titolo_spesa VARCHAR;
  v_descrizione_titolo_spesa VARCHAR;
  v_codice_macroaggregato_spesa VARCHAR;
  v_descrizione_macroaggregato_spesa VARCHAR;
  v_codice_missione_spesa VARCHAR;
  v_descrizione_missione_spesa VARCHAR;
  v_codice_programma_spesa VARCHAR;
  v_descrizione_programma_spesa VARCHAR;
  v_codice_pdc_finanziario_I VARCHAR := null;
  v_descrizione_pdc_finanziario_I VARCHAR := null;
  v_codice_pdc_finanziario_II VARCHAR := null;
  v_descrizione_pdc_finanziario_II VARCHAR := null;
  v_codice_pdc_finanziario_III VARCHAR := null;
  v_descrizione_pdc_finanziario_III VARCHAR := null;
  v_codice_pdc_finanziario_IV VARCHAR := null;
  v_descrizione_pdc_finanziario_IV VARCHAR := null;
  v_codice_pdc_finanziario_V VARCHAR := null;
  v_descrizione_pdc_finanziario_V VARCHAR := null;
  v_codice_cofog_divisione VARCHAR := null;
  v_descrizione_cofog_divisione VARCHAR := null;
  v_codice_cofog_gruppo VARCHAR := null;
  v_descrizione_cofog_gruppo VARCHAR := null;
  v_codice_cdr VARCHAR := null;
  v_descrizione_cdr VARCHAR := null;
  v_codice_cdc VARCHAR := null;
  v_descrizione_cdc VARCHAR := null;
  v_codice_siope_I_spesa VARCHAR := null;
  v_descrizione_siope_I_spesa VARCHAR := null;
  v_codice_siope_II_spesa VARCHAR := null;
  v_descrizione_siope_II_spesa VARCHAR := null;
  v_codice_siope_III_spesa VARCHAR := null;
  v_descrizione_siope_III_spesa VARCHAR := null;
  -- Variabili per classificatori non in gerarchia
  v_codice_spesa_ricorrente VARCHAR := null;
  v_descrizione_spesa_ricorrente VARCHAR := null;
  v_codice_transazione_spesa_ue VARCHAR := null;
  v_descrizione_transazione_spesa_ue VARCHAR := null;
  v_codice_tipo_fondo VARCHAR := null;
  v_descrizione_tipo_fondo VARCHAR := null;
  v_codice_tipo_finanziamento VARCHAR := null;
  v_descrizione_tipo_finanziamento VARCHAR := null;
  v_codice_politiche_regionali_unitarie VARCHAR := null;
  v_descrizione_politiche_regionali_unitarie VARCHAR := null;
  v_codice_perimetro_sanitario_spesa VARCHAR := null;
  v_descrizione_perimetro_sanitario_spesa VARCHAR := null;
  v_classificatore_generico_1 VARCHAR := null;
  v_classificatore_generico_1_descrizione_valore VARCHAR := null;
  v_classificatore_generico_1_valore VARCHAR := null;
  v_classificatore_generico_2 VARCHAR := null;
  v_classificatore_generico_2_descrizione_valore VARCHAR := null;
  v_classificatore_generico_2_valore VARCHAR := null;
  v_classificatore_generico_3 VARCHAR := null;
  v_classificatore_generico_3_descrizione_valore VARCHAR := null;
  v_classificatore_generico_3_valore VARCHAR := null;
  v_classificatore_generico_4 VARCHAR := null;
  v_classificatore_generico_4_descrizione_valore VARCHAR := null;
  v_classificatore_generico_4_valore VARCHAR := null;
  v_classificatore_generico_5 VARCHAR := null;
  v_classificatore_generico_5_descrizione_valore VARCHAR := null;
  v_classificatore_generico_5_valore VARCHAR := null;
  v_classificatore_generico_6 VARCHAR := null;
  v_classificatore_generico_6_descrizione_valore VARCHAR := null;
  v_classificatore_generico_6_valore VARCHAR := null;
  v_classificatore_generico_7 VARCHAR := null;
  v_classificatore_generico_7_descrizione_valore VARCHAR := null;
  v_classificatore_generico_7_valore VARCHAR := null;
  v_classificatore_generico_8 VARCHAR := null;
  v_classificatore_generico_8_descrizione_valore VARCHAR := null;
  v_classificatore_generico_8_valore VARCHAR := null;
  v_classificatore_generico_9 VARCHAR := null;
  v_classificatore_generico_9_descrizione_valore VARCHAR := null;
  v_classificatore_generico_9_valore VARCHAR := null;
  v_classificatore_generico_10 VARCHAR := null;
  v_classificatore_generico_10_descrizione_valore VARCHAR := null;
  v_classificatore_generico_10_valore VARCHAR := null;
  v_classificatore_generico_11 VARCHAR := null;
  v_classificatore_generico_11_descrizione_valore VARCHAR := null;
  v_classificatore_generico_11_valore VARCHAR := null;
  v_classificatore_generico_12 VARCHAR := null;
  v_classificatore_generico_12_descrizione_valore VARCHAR := null;
  v_classificatore_generico_12_valore VARCHAR := null;
  v_classificatore_generico_13 VARCHAR := null;
  v_classificatore_generico_13_descrizione_valore VARCHAR := null;
  v_classificatore_generico_13_valore VARCHAR:= null;
  v_classificatore_generico_14 VARCHAR := null;
  v_classificatore_generico_14_descrizione_valore VARCHAR := null;
  v_classificatore_generico_14_valore VARCHAR := null;
  v_classificatore_generico_15 VARCHAR := null;
  v_classificatore_generico_15_descrizione_valore VARCHAR := null;
  v_classificatore_generico_15_valore VARCHAR := null;
  -- Variabili per attributi
  v_FlagEntrateRicorrenti VARCHAR := null;
  v_FlagFunzioniDelegate VARCHAR := null;
  v_FlagImpegnabile VARCHAR := null;
  v_FlagPerMemoria VARCHAR := null;
  v_FlagRilevanteIva VARCHAR := null;
  v_FlagTrasferimentoOrganiComunitari VARCHAR := null;
  v_Note VARCHAR := null;
  -- Variabili per stipendio
  v_codice_stipendio VARCHAR := null;
  v_descrizione_stipendio VARCHAR := null;
  -- Variabili per attivita' iva
  v_codice_attivita_iva VARCHAR := null;
  v_descrizione_attivita_iva VARCHAR := null;
  -- Variabili per i campi di detaglio degli elementi
  v_massimo_impegnabile_anno1 NUMERIC := null;
  v_stanziamento_cassa_anno1 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno1  NUMERIC := null;
  v_stanziamento_anno1 NUMERIC := null;
  v_stanziamento_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_anno1  NUMERIC := null;
  v_flag_anno1 VARCHAR := null;
  v_massimo_impegnabile_anno2 NUMERIC := null;
  v_stanziamento_cassa_anno2 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno2 NUMERIC := null;
  v_stanziamento_anno2 NUMERIC := null;
  v_stanziamento_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_anno2 NUMERIC := null;
  v_flag_anno2 VARCHAR := null;
  v_massimo_impegnabile_anno3 NUMERIC := null;
  v_stanziamento_cassa_anno3 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno3 NUMERIC := null;
  v_stanziamento_anno3 NUMERIC := null;
  v_stanziamento_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_anno3 NUMERIC := null;
  v_flag_anno3 VARCHAR := null;
  -- Variabili per campi funzione
  v_disponibilita_impegnare_anno1 NUMERIC := null;
  v_disponibilita_impegnare_anno2 NUMERIC := null;
  v_disponibilita_impegnare_anno3 NUMERIC := null;
  -- Variabili utili per il caricamento
  v_classif_code VARCHAR := null;
  v_classif_desc VARCHAR := null;
  v_classif_tipo_code VARCHAR := null;
  v_classif_tipo_desc VARCHAR := null;
  v_elem_id INTEGER := null;
  v_classif_id INTEGER := null;
  v_classif_id_part INTEGER := null;
  v_classif_id_padre INTEGER := null;
  v_classif_tipo_id INTEGER := null;
  v_classif_fam_id INTEGER := null;
  v_conta_ciclo_classif INTEGER := null;
  v_anno_elem_dett INTEGER := null;
  v_anno_appo INTEGER := null;
  v_flag_attributo VARCHAR := null;
  v_bil_id INTEGER := null;

  v_fnc_result VARCHAR := null;

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

select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) - '||clock_timestamp();
RETURN NEXT;


esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_capitolo_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id
AND bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre gli elementi
FOR rec_elem_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, dbet.elem_tipo_code, dbet.elem_tipo_desc,
       dbes.elem_stato_code, dbes.elem_stato_desc, dbec.elem_cat_code, dbec.elem_cat_desc,
       tbe.elem_id, tb.bil_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tb.periodo_id = tp.periodo_id
INNER JOIN siac.siac_t_ente_proprietario tep ON tb.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
LEFT JOIN  siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
                                               AND p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
                                               AND rbec.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
                                              AND p_data BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, p_data)
                                              AND dbec.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND dbet.elem_tipo_code in ('CAP-UG', 'CAP-UP')
AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
AND tbe.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, p_data)
AND dbet.data_cancellazione IS NULL
AND p_data BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, p_data)
AND rbes.data_cancellazione IS NULL
AND p_data BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, p_data)
AND dbes.data_cancellazione IS NULL

LOOP
v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_elem_code := null;
v_elem_code2 := null;
v_elem_code3 := null;
v_elem_desc := null;
v_elem_desc2 := null;
v_elem_tipo_code := null;
v_elem_tipo_desc := null;
v_elem_stato_code := null;
v_elem_stato_desc := null;
v_elem_cat_code := null;
v_elem_cat_desc := null;

v_elem_id := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_bil_id := null; 

v_ente_proprietario_id := rec_elem_id.ente_proprietario_id;
v_ente_denominazione := rec_elem_id.ente_denominazione;
v_anno := rec_elem_id.anno;
v_elem_code := rec_elem_id.elem_code;
v_elem_code2 := rec_elem_id.elem_code2;
v_elem_code3 := rec_elem_id.elem_code3;
v_elem_desc := rec_elem_id.elem_desc;
v_elem_desc2 := rec_elem_id.elem_desc2;
v_elem_tipo_code := rec_elem_id.elem_tipo_code;
v_elem_tipo_desc := rec_elem_id.elem_tipo_desc;
v_elem_stato_code := rec_elem_id.elem_stato_code;
v_elem_stato_desc := rec_elem_id.elem_stato_desc;
v_elem_cat_code := rec_elem_id.elem_cat_code;
v_elem_cat_desc := rec_elem_id.elem_cat_desc;

v_elem_id := rec_elem_id.elem_id;
v_anno_appo := rec_elem_id.anno::integer;
v_bil_id := rec_elem_id.bil_id;

-- Sezione per estrarre i classificatori
v_codice_titolo_spesa := null;
v_descrizione_titolo_spesa := null;
v_codice_macroaggregato_spesa := null;
v_descrizione_macroaggregato_spesa := null;
v_codice_missione_spesa := null;
v_descrizione_missione_spesa := null;
v_codice_programma_spesa := null;
v_descrizione_programma_spesa := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_cofog_divisione := null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;
v_codice_cdr := null;
v_descrizione_cdr := null;
v_codice_cdc := null;
v_descrizione_cdc := null;
v_codice_siope_I_spesa := null;
v_descrizione_siope_I_spesa := null;
v_codice_siope_II_spesa:= null;
v_descrizione_siope_II_spesa := null;
v_codice_siope_III_spesa := null;
v_descrizione_siope_III_spesa := null;

v_codice_spesa_ricorrente := null;
v_descrizione_spesa_ricorrente := null;
v_codice_transazione_spesa_ue := null;
v_descrizione_transazione_spesa_ue := null;
v_codice_tipo_fondo := null;
v_descrizione_tipo_fondo := null;
v_codice_tipo_finanziamento := null;
v_descrizione_tipo_finanziamento := null;
v_codice_politiche_regionali_unitarie := null;
v_descrizione_politiche_regionali_unitarie := null;
v_codice_perimetro_sanitario_spesa := null;
v_descrizione_perimetro_sanitario_spesa := null;
v_classificatore_generico_1:= null;
v_classificatore_generico_1_descrizione_valore:= null;
v_classificatore_generico_1_valore:= null;
v_classificatore_generico_2:= null;
v_classificatore_generico_2_descrizione_valore:= null;
v_classificatore_generico_2_valore:= null;
v_classificatore_generico_3:= null;
v_classificatore_generico_3_descrizione_valore:= null;
v_classificatore_generico_3_valore:= null;
v_classificatore_generico_4:= null;
v_classificatore_generico_4_descrizione_valore:= null;
v_classificatore_generico_4_valore:= null;
v_classificatore_generico_5:= null;
v_classificatore_generico_5_descrizione_valore:= null;
v_classificatore_generico_5_valore:= null;
v_classificatore_generico_6:= null;
v_classificatore_generico_6_descrizione_valore:= null;
v_classificatore_generico_6_valore:= null;
v_classificatore_generico_7:= null;
v_classificatore_generico_7_descrizione_valore:= null;
v_classificatore_generico_7_valore:= null;
v_classificatore_generico_8:= null;
v_classificatore_generico_8_descrizione_valore:= null;
v_classificatore_generico_8_valore:= null;
v_classificatore_generico_9:= null;
v_classificatore_generico_9_descrizione_valore:= null;
v_classificatore_generico_9_valore:= null;
v_classificatore_generico_10:= null;
v_classificatore_generico_10_descrizione_valore:= null;
v_classificatore_generico_10_valore:= null;
v_classificatore_generico_11:= null;
v_classificatore_generico_11_descrizione_valore:= null;
v_classificatore_generico_11_valore:= null;
v_classificatore_generico_12:= null;
v_classificatore_generico_12_descrizione_valore:= null;
v_classificatore_generico_12_valore:= null;
v_classificatore_generico_13:= null;
v_classificatore_generico_13_descrizione_valore:= null;
v_classificatore_generico_13_valore:= null;
v_classificatore_generico_14:= null;
v_classificatore_generico_14_descrizione_valore:= null;
v_classificatore_generico_14_valore:= null;
v_classificatore_generico_15:= null;
v_classificatore_generico_15_descrizione_valore:= null;
v_classificatore_generico_15_valore:= null;
esito:= '  Inizio ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
-- Sezione per estrarre la fase operativa
SELECT dfo.fase_operativa_code, dfo.fase_operativa_desc 
INTO v_fase_operativa_code, v_fase_operativa_desc 
FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
WHERE dfo.fase_operativa_id = rbfo.fase_operativa_id
AND   rbfo.bil_id = v_bil_id
AND   p_data BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, p_data)
AND   p_data BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, p_data)
AND   rbfo.data_cancellazione IS NULL
AND   dfo.data_cancellazione IS NULL; 
-- Ciclo per estrarre i classificatori relativi ad un dato elemento
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
FROM siac.siac_r_bil_elem_class rbec, siac.siac_t_class tc
WHERE tc.classif_id = rbec.classif_id
AND   rbec.elem_id = v_elem_id
AND   rbec.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

LOOP

v_classif_id :=  rec_classif_id.classif_id;
v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
v_classif_fam_id := null;

-- Estrazione per determinare se un classificatore e' in gerarchia
SELECT rcfct.classif_fam_id
INTO v_classif_fam_id
FROM siac.siac_r_class_fam_class_tipo rcfct
WHERE rcfct.classif_tipo_id = v_classif_tipo_id
AND   rcfct.data_cancellazione IS NULL
AND   p_data BETWEEN rcfct.validita_inizio AND COALESCE(rcfct.validita_fine, p_data);

-- Se il classificatore non e' in gerarchia
IF NOT FOUND THEN
  esito:= '    Inizio step classificatori non in gerarchia - '||clock_timestamp();
  return next;
  v_classif_tipo_code := null;
  v_classif_code := rec_classif_id.classif_code;
  v_classif_desc := rec_classif_id.classif_desc;

  SELECT dct.classif_tipo_code , dct.classif_tipo_desc
  INTO   v_classif_tipo_code, v_classif_tipo_desc
  FROM   siac.siac_d_class_tipo dct
  WHERE  dct.classif_tipo_id = v_classif_tipo_id
  AND    dct.data_cancellazione IS NULL
  AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'RICORRENTE_SPESA' THEN
     v_codice_spesa_ricorrente      := v_classif_code;
     v_descrizione_spesa_ricorrente := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TRANSAZIONE_UE_SPESA' THEN
     v_codice_transazione_spesa_ue      := v_classif_code;
     v_descrizione_transazione_spesa_ue := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FONDO' THEN
     v_codice_tipo_fondo      := v_classif_code;
     v_descrizione_tipo_fondo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FINANZIAMENTO' THEN
     v_codice_tipo_finanziamento      := v_classif_code;
     v_descrizione_tipo_finanziamento := v_classif_desc;
  ELSIF v_classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE' THEN
     v_codice_politiche_regionali_unitarie      := v_classif_code;
     v_descrizione_politiche_regionali_unitarie := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA' THEN
     v_codice_perimetro_sanitario_spesa      := v_classif_code;
     v_descrizione_perimetro_sanitario_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_1' THEN
     v_classificatore_generico_1      :=  v_classif_tipo_desc;
     v_classificatore_generico_1_descrizione_valore := v_classif_desc;
     v_classificatore_generico_1_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_2' THEN
     v_classificatore_generico_2      := v_classif_tipo_desc;
     v_classificatore_generico_2_descrizione_valore := v_classif_desc;
     v_classificatore_generico_2_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_3' THEN
     v_classificatore_generico_3      := v_classif_tipo_desc;
     v_classificatore_generico_3_descrizione_valore := v_classif_desc;
     v_classificatore_generico_3_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_4' THEN
     v_classificatore_generico_4      := v_classif_tipo_desc;
     v_classificatore_generico_4_descrizione_valore := v_classif_desc;
     v_classificatore_generico_4_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_5' THEN
     v_classificatore_generico_5    := v_classif_tipo_desc;
     v_classificatore_generico_5_descrizione_valore := v_classif_desc;
     v_classificatore_generico_5_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_6' THEN
     v_classificatore_generico_6      := v_classif_tipo_desc;
     v_classificatore_generico_6_descrizione_valore := v_classif_desc;
     v_classificatore_generico_6_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_7' THEN
     v_classificatore_generico_7      := v_classif_tipo_desc;
     v_classificatore_generico_7_descrizione_valore := v_classif_desc;
     v_classificatore_generico_7_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_8' THEN
     v_classificatore_generico_8      := v_classif_tipo_desc;
     v_classificatore_generico_8_descrizione_valore := v_classif_desc;
     v_classificatore_generico_8_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_9' THEN
     v_classificatore_generico_9      := v_classif_tipo_desc;
     v_classificatore_generico_9_descrizione_valore := v_classif_desc;
     v_classificatore_generico_9_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_10' THEN
     v_classificatore_generico_10     := v_classif_tipo_desc;
     v_classificatore_generico_10_descrizione_valore := v_classif_desc;
     v_classificatore_generico_10_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_31' THEN
     v_classificatore_generico_11    := v_classif_tipo_desc;
     v_classificatore_generico_11_descrizione_valore := v_classif_desc;
     v_classificatore_generico_11_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_32' THEN
     v_classificatore_generico_12     := v_classif_tipo_desc;
     v_classificatore_generico_12_descrizione_valore := v_classif_desc;
     v_classificatore_generico_12_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_33' THEN
     v_classificatore_generico_13      := v_classif_tipo_desc;
     v_classificatore_generico_13_descrizione_valore := v_classif_desc;
     v_classificatore_generico_13_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_34' THEN
     v_classificatore_generico_14      := v_classif_tipo_desc;
     v_classificatore_generico_14_descrizione_valore := v_classif_desc;
     v_classificatore_generico_14_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_35' THEN
     v_classificatore_generico_15      := v_classif_tipo_desc;
     v_classificatore_generico_15_descrizione_valore := v_classif_desc;
     v_classificatore_generico_15_valore      := v_classif_code;
  END IF;
  esito:= '    Fine step classificatori non in gerarchia - '||clock_timestamp();
  return next;
-- Se il classificatoree' in gerarchia
ELSE
 esito:= '    Inizio step classificatori in gerarchia - '||clock_timestamp();
 return next;
 v_conta_ciclo_classif :=0;
 v_classif_id_padre := null;

 -- Loop per RISALIRE la gerarchia di un dato classificatore
 LOOP

  v_classif_code := null;
  v_classif_desc := null;
  v_classif_id_part := null;
  v_classif_tipo_code := null;
  v_classif_tipo_desc:=null;

  IF v_conta_ciclo_classif = 0 THEN
     v_classif_id_part := v_classif_id;
  ELSE
     v_classif_id_part := v_classif_id_padre;
  END IF;

  SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code, dct.classif_tipo_desc
  INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code, v_classif_tipo_desc
  FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
  WHERE rcft.classif_id = tc.classif_id
  AND   dct.classif_tipo_id = tc.classif_tipo_id
  AND   tc.classif_id = v_classif_id_part
  AND   rcft.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   dct.data_cancellazione IS NULL
  AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
  AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF    v_classif_tipo_code = 'TITOLO_SPESA' THEN
        v_codice_titolo_spesa := v_classif_code;
        v_descrizione_titolo_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'MACROAGGREGATO' THEN
        v_codice_macroaggregato_spesa := v_classif_code;
        v_descrizione_macroaggregato_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'MISSIONE' THEN
        v_codice_missione_spesa := v_classif_code;
        v_descrizione_missione_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PROGRAMMA' THEN
        v_codice_programma_spesa := v_classif_code;
        v_descrizione_programma_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_I' THEN
        v_codice_pdc_finanziario_I := v_classif_code;
        v_descrizione_pdc_finanziario_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_II' THEN
        v_codice_pdc_finanziario_II := v_classif_code;
        v_descrizione_pdc_finanziario_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_III' THEN
        v_codice_pdc_finanziario_III := v_classif_code;
        v_descrizione_pdc_finanziario_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_IV' THEN
        v_codice_pdc_finanziario_IV := v_classif_code;
        v_descrizione_pdc_finanziario_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_V' THEN
        v_codice_pdc_finanziario_V := v_classif_code;
        v_descrizione_pdc_finanziario_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDR' THEN
        v_codice_cdr := v_classif_code;
        v_descrizione_cdr := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDC' THEN
        v_codice_cdc := v_classif_code;
        v_descrizione_cdc := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_I' THEN
        v_codice_siope_I_spesa := v_classif_code;
        v_descrizione_siope_I_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_II' THEN
        v_codice_siope_II_spesa := v_classif_code;
        v_descrizione_siope_II_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_III' THEN
        v_codice_siope_III_spesa := v_classif_code;
        v_descrizione_siope_III_spesa := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
 esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
 return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
 esito:= '    Inizio step attributi - '||clock_timestamp();
 return next;
v_FlagEntrateRicorrenti := null;
v_FlagFunzioniDelegate := null;
v_FlagImpegnabile := null;
v_FlagPerMemoria := null;
v_FlagRilevanteIva := null;
v_FlagTrasferimentoOrganiComunitari := null;
v_Note := null;
v_flag_attributo := null;

FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rbea.tabella_id, rbea.percentuale, rbea."boolean" true_false, rbea.numerico, rbea.testo
FROM   siac.siac_r_bil_elem_attr rbea, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rbea.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rbea.elem_id = v_elem_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rbea.validita_inizio AND COALESCE(rbea.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'FlagEntrateRicorrenti' THEN
     v_FlagEntrateRicorrenti := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagFunzioniDelegate' THEN
     v_FlagFunzioniDelegate := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagImpegnabile' THEN
     v_FlagImpegnabile := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagPerMemoria' THEN
     v_FlagPerMemoria := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagRilevanteIva' THEN
     v_FlagRilevanteIva := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagTrasferimentoOrganiComunitari' THEN
     v_FlagTrasferimentoOrganiComunitari := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Note' THEN
     v_Note := v_flag_attributo;
  END IF;

END LOOP;
esito:= '    Fine step attributi - '||clock_timestamp();
return next;
esito:= '    Inizio step stipendi - '||clock_timestamp();
return next;
-- Sezione per i dati di stipendio
v_codice_stipendio := null;
v_descrizione_stipendio := null;

SELECT dsc.stipcode_code, dsc.stipcode_desc
INTO v_codice_stipendio, v_descrizione_stipendio
FROM  siac.siac_r_bil_elem_stipendio_codice rbesc, siac.siac_d_stipendio_codice dsc
WHERE rbesc.stipcode_id = dsc.stipcode_id
AND   rbesc.elem_id = v_elem_id
AND   rbesc.data_cancellazione IS NULL
AND   dsc.data_cancellazione IS NULL
AND   p_data between rbesc.validita_inizio and coalesce(rbesc.validita_fine, p_data)
AND   p_data between dsc.validita_inizio and coalesce(dsc.validita_fine, p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step iva - '||clock_timestamp();
return next;
-- Sezione per i dati di iva
v_codice_attivita_iva := null;
v_descrizione_attivita_iva := null;

SELECT tia.ivaatt_code, tia.ivaatt_desc
INTO v_codice_attivita_iva, v_descrizione_attivita_iva
FROM siac.siac_r_bil_elem_iva_attivita rbeia, siac.siac_t_iva_attivita tia
WHERE rbeia.ivaatt_id = tia.ivaatt_id
AND   rbeia.elem_id = v_elem_id
AND   rbeia.data_cancellazione IS NULL
AND   tia.data_cancellazione IS NULL
AND   p_data between rbeia.validita_inizio and coalesce(rbeia.validita_fine,p_data)
AND   p_data between tia.validita_inizio and coalesce(tia.validita_fine,p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step dettagli elementi - '||clock_timestamp();
return next;
-- Sezione per i dati di dettaglio degli elementi
v_massimo_impegnabile_anno1 := null;
v_stanziamento_cassa_anno1 := null;
v_stanziamento_cassa_iniziale_anno1 := null;
v_stanziamento_residuo_iniziale_anno1 := null;
v_stanziamento_anno1 := null;
v_stanziamento_iniziale_anno1 := null;
v_stanziamento_residuo_anno1 := null;
v_flag_anno1 := null;
v_massimo_impegnabile_anno2 := null;
v_stanziamento_cassa_anno2 := null;
v_stanziamento_cassa_iniziale_anno2 := null;
v_stanziamento_residuo_iniziale_anno2 := null;
v_stanziamento_anno2 := null;
v_stanziamento_iniziale_anno2 := null;
v_stanziamento_residuo_anno2 := null;
v_flag_anno2 := null;
v_massimo_impegnabile_anno3 := null;
v_stanziamento_cassa_anno3 := null;
v_stanziamento_cassa_iniziale_anno3 := null;
v_stanziamento_residuo_iniziale_anno3 := null;
v_stanziamento_anno3 := null;
v_stanziamento_iniziale_anno3 := null;
v_stanziamento_residuo_anno3 := null;
v_flag_anno3 := null;

v_anno_elem_dett := null;

FOR rec_elem_dett IN
SELECT dbedt.elem_det_tipo_code, tbed.elem_det_flag, tbed.elem_det_importo, tp.anno
FROM  siac.siac_t_bil_elem_det tbed, siac.siac_d_bil_elem_det_tipo dbedt, siac.siac_t_periodo tp
WHERE tbed.elem_det_tipo_id = dbedt.elem_det_tipo_id
AND   tbed.periodo_id = tp.periodo_id
AND   tbed.elem_id = v_elem_id
AND   tbed.data_cancellazione IS NULL
AND   dbedt.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   p_data between tbed.validita_inizio and coalesce(tbed.validita_fine,p_data)
AND   p_data between dbedt.validita_inizio and coalesce(dbedt.validita_fine,p_data)
AND   p_data between tp.validita_inizio and coalesce(tp.validita_fine,p_data)

LOOP
v_anno_elem_dett := rec_elem_dett.anno::integer;
  IF v_anno_elem_dett = v_anno_appo THEN
    v_flag_anno1 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno1 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 1) THEN
    v_flag_anno2 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno2 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 2) THEN
    v_flag_anno3 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno3 := rec_elem_dett.elem_det_importo;
    END IF;
  END IF;
END LOOP;
esito:= '    Fine step dettagli elementi - '||clock_timestamp();
return next;
esito:= '    Inizio step dati da funzione - '||clock_timestamp();
return next;
-- Sezione per valorizzazione delle variabili per i campi di funzione
v_disponibilita_impegnare_anno1 := null;
v_disponibilita_impegnare_anno2 := null;
v_disponibilita_impegnare_anno3 := null;

IF v_elem_tipo_code = 'CAP-UG' THEN
   v_disponibilita_impegnare_anno1 := siac.fnc_siac_disponibilitaimpegnareug_anno1(v_elem_id);
   v_disponibilita_impegnare_anno2 := siac.fnc_siac_disponibilitaimpegnareug_anno2(v_elem_id);
   v_disponibilita_impegnare_anno3 := siac.fnc_siac_disponibilitaimpegnareug_anno3(v_elem_id);
END IF;
esito:= '    Fine step dati da funzione - '||clock_timestamp();
return next;
INSERT INTO siac.siac_dwh_capitolo_spesa
(ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
cod_tipo_capitolo,
desc_tipo_capitolo,
cod_stato_capitolo,
desc_stato_capitolo,
cod_classificazione_capitolo,
desc_classificazione_capitolo,
cod_titolo_spesa,
desc_titolo_spesa,
cod_macroaggregato_spesa,
desc_macroaggregato_spesa,
cod_missione_spesa,
desc_missione_spesa,
cod_programma_spesa,
desc_programma_spesa,
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
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
cod_cdr,
desc_cdr,
cod_cdc,
desc_cdc,
cod_siope_i_spesa,
desc_siope_i_spesa,
cod_siope_ii_spesa,
desc_siope_ii_spesa,
cod_siope_iii_spesa,
desc_siope_iii_spesa,
cod_spesa_ricorrente,
desc_spesa_ricorrente,
cod_transazione_spesa_ue,
desc_transazione_spesa_ue,
cod_tipo_fondo,
desc_tipo_fondo,
cod_tipo_finanziamento,
desc_tipo_finanziamento,
cod_politiche_regionali_unit,
desc_politiche_regionali_unit,
cod_perimetro_sanita_spesa,
desc_perimetro_sanita_spesa,
classificatore_1,
classificatore_1_valore,
classificatore_1_desc_valore,
classificatore_2,
classificatore_2_valore,
classificatore_2_desc_valore,
classificatore_3,
classificatore_3_valore,
classificatore_3_desc_valore,
classificatore_4,
classificatore_4_valore,
classificatore_4_desc_valore,
classificatore_5,
classificatore_5_valore,
classificatore_5_desc_valore,
classificatore_6,
classificatore_6_valore,
classificatore_6_desc_valore,
classificatore_7,
classificatore_7_valore,
classificatore_7_desc_valore,
classificatore_8,
classificatore_8_valore,
classificatore_8_desc_valore,
classificatore_9,
classificatore_9_valore,
classificatore_9_desc_valore,
classificatore_10,
classificatore_10_valore,
classificatore_10_desc_valore,
classificatore_11,
classificatore_11_valore,
classificatore_11_desc_valore,
classificatore_12,
classificatore_12_valore,
classificatore_12_desc_valore,
classificatore_13,
classificatore_13_valore,
classificatore_13_desc_valore,
classificatore_14,
classificatore_14_valore,
classificatore_14_desc_valore,
classificatore_15,
classificatore_15_valore,
classificatore_15_desc_valore,
flagentratericorrenti,
flagfunzionidelegate,
flagimpegnabile,
flagpermemoria,
flagrilevanteiva,
flag_trasf_organi_comunitari,
note,
cod_stipendio,
desc_stipendio,
cod_attivita_iva,
desc_attivita_iva,
massimo_impegnabile_anno1,
stanz_cassa_anno1,
stanz_cassa_iniziale_anno1,
stanz_residuo_iniziale_anno1,
stanz_anno1,
stanz_iniziale_anno1,
stanz_residuo_anno1,
flag_anno1,
massimo_impegnabile_anno2,
stanz_cassa_anno2,
stanz_cassa_iniziale_anno2,
stanz_residuo_iniziale_anno2,
stanz_anno2,
stanz_iniziale_anno2,
stanz_residuo_anno2,
flag_anno2,
massimo_impegnabile_anno3,
stanz_cassa_anno3,
stanz_cassa_iniziale_anno3,
stanz_residuo_iniziale_anno3,
stanz_anno3,
stanz_iniziale_anno3,
stanz_residuo_anno3,
flag_anno3,
disponibilita_impegnare_anno1,
disponibilita_impegnare_anno2,
disponibilita_impegnare_anno3
)
VALUES (v_ente_proprietario_id,
        v_ente_denominazione,
        v_anno,
        v_fase_operativa_code,
        v_fase_operativa_desc,
        v_elem_code,
        v_elem_code2,
        v_elem_code3,
        v_elem_desc,
        v_elem_desc2,
        v_elem_tipo_code,
        v_elem_tipo_desc,
        v_elem_stato_code,
        v_elem_stato_desc,
        v_elem_cat_code,
        v_elem_cat_desc,
		v_codice_titolo_spesa,
		v_descrizione_titolo_spesa,
		v_codice_macroaggregato_spesa,
		v_descrizione_macroaggregato_spesa,
		v_codice_missione_spesa,
		v_descrizione_missione_spesa,
		v_codice_programma_spesa,
		v_descrizione_programma_spesa,
        v_codice_pdc_finanziario_I,
        v_descrizione_pdc_finanziario_I,
        v_codice_pdc_finanziario_II,
        v_descrizione_pdc_finanziario_II,
        v_codice_pdc_finanziario_III,
        v_descrizione_pdc_finanziario_III,
        v_codice_pdc_finanziario_IV,
        v_descrizione_pdc_finanziario_IV,
        v_codice_pdc_finanziario_V,
        v_descrizione_pdc_finanziario_V,
        v_codice_cofog_divisione,
        v_descrizione_cofog_divisione,
        v_codice_cofog_gruppo,
        v_descrizione_cofog_gruppo,
        v_codice_cdr,
        v_descrizione_cdr,
        v_codice_cdc,
        v_descrizione_cdc,
        v_codice_siope_I_spesa,
        v_descrizione_siope_I_spesa,
        v_codice_siope_II_spesa,
        v_descrizione_siope_II_spesa,
        v_codice_siope_III_spesa,
        v_descrizione_siope_III_spesa,
        v_codice_spesa_ricorrente,
        v_descrizione_spesa_ricorrente,
        v_codice_transazione_spesa_ue,
        v_descrizione_transazione_spesa_ue,
        v_codice_tipo_fondo,
        v_descrizione_tipo_fondo,
        v_codice_tipo_finanziamento,
        v_descrizione_tipo_finanziamento,
	    v_codice_politiche_regionali_unitarie,
	    v_descrizione_politiche_regionali_unitarie,
        v_codice_perimetro_sanitario_spesa,
        v_descrizione_perimetro_sanitario_spesa,
        v_classificatore_generico_1,
        v_classificatore_generico_1_valore,
        v_classificatore_generico_1_descrizione_valore,
        v_classificatore_generico_2,
        v_classificatore_generico_2_valore,
        v_classificatore_generico_2_descrizione_valore,
        v_classificatore_generico_3,
        v_classificatore_generico_3_valore,
        v_classificatore_generico_3_descrizione_valore,
        v_classificatore_generico_4,
        v_classificatore_generico_4_valore,
        v_classificatore_generico_4_descrizione_valore,
        v_classificatore_generico_5,
        v_classificatore_generico_5_valore,
        v_classificatore_generico_5_descrizione_valore,
        v_classificatore_generico_6,
        v_classificatore_generico_6_valore,
        v_classificatore_generico_6_descrizione_valore,
        v_classificatore_generico_7,
        v_classificatore_generico_7_valore,
        v_classificatore_generico_7_descrizione_valore,
        v_classificatore_generico_8,
        v_classificatore_generico_8_valore,
        v_classificatore_generico_8_descrizione_valore,
        v_classificatore_generico_9,
        v_classificatore_generico_9_valore,
        v_classificatore_generico_9_descrizione_valore,
        v_classificatore_generico_10,
        v_classificatore_generico_10_valore,
        v_classificatore_generico_10_descrizione_valore,
        v_classificatore_generico_11,
        v_classificatore_generico_11_valore,
        v_classificatore_generico_11_descrizione_valore,
        v_classificatore_generico_12,
        v_classificatore_generico_12_valore,
        v_classificatore_generico_12_descrizione_valore,
        v_classificatore_generico_13,
        v_classificatore_generico_13_valore,
        v_classificatore_generico_13_descrizione_valore,
        v_classificatore_generico_14,
        v_classificatore_generico_14_valore,
        v_classificatore_generico_14_descrizione_valore,
        v_classificatore_generico_15,
        v_classificatore_generico_15_valore,
        v_classificatore_generico_15_descrizione_valore,
        v_FlagEntrateRicorrenti,
		v_FlagFunzioniDelegate,
        v_FlagImpegnabile,
        v_FlagPerMemoria,
        v_FlagRilevanteIva,
        v_FlagTrasferimentoOrganiComunitari,
        v_Note,
        v_codice_stipendio,
        v_descrizione_stipendio,
        v_codice_attivita_iva,
        v_descrizione_attivita_iva,
        v_massimo_impegnabile_anno1,
        v_stanziamento_cassa_anno1,
        v_stanziamento_cassa_iniziale_anno1,
        v_stanziamento_residuo_iniziale_anno1,
        v_stanziamento_anno1,
        v_stanziamento_iniziale_anno1,
        v_stanziamento_residuo_anno1,
        v_flag_anno1,
        v_massimo_impegnabile_anno2,
        v_stanziamento_cassa_anno2,
        v_stanziamento_cassa_iniziale_anno2,
        v_stanziamento_residuo_iniziale_anno2,
        v_stanziamento_anno2,
        v_stanziamento_iniziale_anno2,
        v_stanziamento_residuo_anno2,
        v_flag_anno2,
        v_massimo_impegnabile_anno3,
        v_stanziamento_cassa_anno3,
        v_stanziamento_cassa_iniziale_anno3,
        v_stanziamento_residuo_iniziale_anno3,
        v_stanziamento_anno3,
        v_stanziamento_iniziale_anno3,
        v_stanziamento_residuo_anno3,
        v_flag_anno3,
        v_disponibilita_impegnare_anno1,
        v_disponibilita_impegnare_anno2,
        v_disponibilita_impegnare_anno3
       );
esito:= '  Fine ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
END LOOP;
esito:= 'Fine funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
-- SIAC-5361 FINE

-- SIAC-5325 INIZIO
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_contabilita_generale (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

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
class      record;

v_imp_doc_liq_ord INTEGER := 0;
v_imp_liq_ord INTEGER := 0;
v_imp_ord INTEGER := 0;
v_doc_tipo_code VARCHAR := null;
v_soggetto_code VARCHAR := null;
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno VARCHAR := null;
v_pnota_desc VARCHAR := null;  
v_pnota_progressivogiornale INTEGER := null;  
v_pnota_dataregistrazionegiornale TIMESTAMP := null; 
v_pnota_stato_code VARCHAR := null;  
v_pnota_stato_desc VARCHAR := null;                  
v_movep_code VARCHAR := null;  
v_movep_desc VARCHAR := null; 
v_pnota_numero INTEGER := null;  
v_movep_det_code VARCHAR := null;  
v_movep_det_desc VARCHAR := null;  
v_movep_det_importo NUMERIC := null;   
v_movep_det_segno VARCHAR := null;  
v_livello INTEGER := null;
v_ordine VARCHAR := null; 
v_pdce_conto_code  VARCHAR := null; 
v_pdce_conto_desc  VARCHAR := null; 
v_pdce_ct_tipo_code VARCHAR := null;  
v_pdce_ct_tipo_desc VARCHAR := null;  
v_pdce_fam_tree_code VARCHAR := null;    
v_pdce_fam_tree_desc VARCHAR := null;  
v_pdce_fam_code VARCHAR := null;
v_pdce_fam_desc VARCHAR := null;
v_pdce_fam_segno VARCHAR := null;  
v_ambito_code VARCHAR := null;
v_ambito_desc VARCHAR := null;
v_causale_ep_code VARCHAR := null;
v_causale_ep_desc VARCHAR := null;
v_causale_ep_tipo_code VARCHAR := null;
v_causale_ep_tipo_desc VARCHAR := null;
v_causale_ep_stato_code VARCHAR := null;
v_causale_ep_stato_desc VARCHAR := null;
v_evento_code VARCHAR := null;
v_evento_desc VARCHAR := null; 
v_collegamento_tipo_code VARCHAR := null;
v_collegamento_tipo_desc VARCHAR := null;
v_classif_code VARCHAR := null;  
v_classif_desc VARCHAR := null;  
v_classif_code_app VARCHAR := null;  
v_classif_desc_app VARCHAR := null;  
v_movgest_anno INTEGER := null;      
v_movgest_numero NUMERIC := null;
v_movgest_ts_code VARCHAR := null;
v_ord_ts_code VARCHAR := null;
v_ord_anno INTEGER := null; 
v_ord_numero NUMERIC := null;
v_anno_liq INTEGER := null;  
v_num_liq NUMERIC := null;  
v_anno_doc INTEGER := null; 
v_num_doc VARCHAR(200) := null; 
v_tipo_doc VARCHAR := null;
v_data_emissione_doc TIMESTAMP := null; 
v_cod_soggetto_doc VARCHAR := null;
v_num_subdoc INTEGER := null;
v_flag_mod  VARCHAR(1) := null;  
v_entrate_uscite  VARCHAR(1) := null; 
v_classif_code_bil VARCHAR := null; 
v_classif_desc_bil VARCHAR := null; 
v_ricecon_numero INTEGER := null;    
v_causale_ep_tipo_id_pn INTEGER := null;
v_pnota_id INTEGER := null; 
v_causale_ep_id_mov INTEGER := null;  
v_pdce_conto_id INTEGER := null; 
v_pdce_conto_id_padre INTEGER :=  null;
v_pdce_ct_tipo_id INTEGER := null; 
v_pdce_fam_tree_id INTEGER := null; 
v_pdce_fam_id INTEGER := null;   
v_ambito_id INTEGER := null;
v_causale_ep_id INTEGER := null;
v_causale_ep_tipo_id INTEGER := null;
v_evento_tipo_id INTEGER := null;
v_regep_id INTEGER := null;
v_regmovfin_id INTEGER := null;
v_campo_pk_id INTEGER := null;
v_evento_id INTEGER := null;
v_classif_id INTEGER := null;
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_impegno_id INTEGER := null;
v_mod_stato_r_id INTEGER := null;
v_movgest_ts_id_mod INTEGER := null;
v_movgest_id INTEGER := null;
v_ord_ts_id INTEGER := null;
v_doc_id INTEGER := null;
v_doc_tipo_id INTEGER := null;
v_ricecon_id INTEGER := null; 
v_conta_ciclo_classif INTEGER := null;

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

esito:= 'Inizio funzione carico dati contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_contabilita_generale
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

FOR prima_nota IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione,
       tp.anno,
       tpn.pnota_desc, tpn.pnota_numero, tpn.pnota_progressivogiornale, tpn.pnota_dataregistrazionegiornale, 
       dpns.pnota_stato_code, dpns.pnota_stato_desc,
       tpn.causale_ep_tipo_id, tpn.pnota_id  
FROM   siac_t_prima_nota tpn, siac_t_ente_proprietario tep, siac_t_bil tb, siac_t_periodo tp, 
       siac_r_prima_nota_stato rpns, siac_d_prima_nota_stato dpns
WHERE  tep.ente_proprietario_id = p_ente_proprietario_id
AND    tep.ente_proprietario_id = tpn.ente_proprietario_id
AND    tb.bil_id = tpn.bil_id
AND    tb.periodo_id = tp.periodo_id
AND    tp.anno = p_anno_bilancio
AND    rpns.pnota_id = tpn.pnota_id
AND    rpns.pnota_stato_id = dpns.pnota_stato_id
AND    dpns.pnota_stato_code = 'D'
--AND    p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND    tep.data_cancellazione IS NULL
--AND    p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND    tb.data_cancellazione IS NULL
--AND    p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND    tp.data_cancellazione IS NULL
--AND    p_data BETWEEN tpn.validita_inizio AND COALESCE(tpn.validita_fine, p_data)
AND    tpn.data_cancellazione IS NULL
--AND    p_data BETWEEN rpns.validita_inizio AND COALESCE(rpns.validita_fine, p_data)
AND    rpns.data_cancellazione IS NULL
--AND    p_data BETWEEN dpns.validita_inizio AND COALESCE(dpns.validita_fine, p_data)
AND    dpns.data_cancellazione IS NULL

LOOP

  v_ente_proprietario_id := null;
  v_ente_denominazione := null;
  v_anno := null;
  v_pnota_desc := null;  
  v_pnota_numero := null;
  v_pnota_progressivogiornale := null;  
  v_pnota_dataregistrazionegiornale := null; 
  v_pnota_stato_code := null;  
  v_pnota_stato_desc := null;  
  v_causale_ep_tipo_id_pn := null;
  v_regep_id := null;

  v_ente_proprietario_id := prima_nota.ente_proprietario_id;
  v_ente_denominazione := prima_nota.ente_denominazione;
  v_anno := prima_nota.anno;
  v_pnota_desc := prima_nota.pnota_desc;
  v_pnota_numero := prima_nota.pnota_numero;
  v_pnota_progressivogiornale := prima_nota.pnota_progressivogiornale; 
  v_pnota_dataregistrazionegiornale := prima_nota.pnota_dataregistrazionegiornale;
  v_pnota_stato_code := prima_nota.pnota_stato_code;
  v_pnota_stato_desc := prima_nota.pnota_stato_desc; 
  v_causale_ep_tipo_id_pn := prima_nota.causale_ep_tipo_id;
  v_regep_id := prima_nota.pnota_id; 

  v_causale_ep_tipo_code := null;
  v_causale_ep_tipo_desc := null;
        
  SELECT dcet.causale_ep_tipo_code, dcet.causale_ep_tipo_desc
  INTO   v_causale_ep_tipo_code, v_causale_ep_tipo_desc
  FROM   siac_d_causale_ep_tipo dcet
  WHERE  dcet.causale_ep_tipo_id = v_causale_ep_tipo_id_pn
  --AND    p_data BETWEEN dcet.validita_inizio AND COALESCE(dcet.validita_fine, p_data)
  AND    dcet.data_cancellazione IS NULL; 

  FOR movimenti IN
  SELECT tme.movep_code, tme.movep_desc,
         tmed.movep_det_code, tmed.movep_det_desc, tmed.movep_det_importo, tmed.movep_det_segno, 
         tme.causale_ep_id, tmed.pdce_conto_id, tme.regmovfin_id
  FROM   siac_t_mov_ep tme, siac_t_mov_ep_det tmed
  WHERE  tme.regep_id = v_regep_id
  AND    tme.movep_id = tmed.movep_id
  --AND    p_data BETWEEN tme.validita_inizio AND COALESCE(tme.validita_fine, p_data)
  AND    tme.data_cancellazione IS NULL
  --AND    p_data BETWEEN tmed.validita_inizio AND COALESCE(tmed.validita_fine, p_data)
  AND    tmed.data_cancellazione IS NULL

  LOOP

    v_movep_code := null;  
    v_movep_desc := null; 
    v_movep_det_code := null;  
    v_movep_det_desc := null;  
    v_movep_det_importo := null;   
    v_movep_det_segno := null; 
    v_causale_ep_id_mov := null;  
    v_pdce_conto_id := null; 
    v_regmovfin_id := null;

    v_movep_code := movimenti.movep_code;
    v_movep_desc := movimenti.movep_desc;
    v_movep_det_code := movimenti.movep_det_code;  
    v_movep_det_desc := movimenti.movep_det_desc; 
    v_movep_det_importo := movimenti.movep_det_importo;  
    v_movep_det_segno := movimenti.movep_det_segno; 
    v_causale_ep_id_mov := movimenti.causale_ep_id;  
    v_pdce_conto_id := movimenti.pdce_conto_id; 
    v_regmovfin_id := movimenti.regmovfin_id;

    v_campo_pk_id := null;
    v_evento_id := null; 
        
    SELECT a.campo_pk_id, a.evento_id
    INTO v_campo_pk_id, v_evento_id
    FROM siac_r_evento_reg_movfin a
    WHERE a.regmovfin_id = v_regmovfin_id
    --AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND    a.data_cancellazione IS NULL;  

    v_livello := null;
    v_ordine := null; 
    v_pdce_conto_code := null; 
    v_pdce_conto_desc := null;  
    v_pdce_conto_id_padre :=  null;
    v_pdce_ct_tipo_id := null; 
    v_pdce_fam_tree_id := null; 
    
/*    SELECT tpc.livello, tpc.ordine, tpc.pdce_conto_code, tpc.pdce_conto_desc, 
           tpc.pdce_conto_id_padre, tpc.pdce_ct_tipo_id, tpc.pdce_fam_tree_id
    INTO   v_livello, v_ordine, v_pdce_conto_code, v_pdce_conto_desc, 
           v_pdce_conto_id_padre, v_pdce_ct_tipo_id, v_pdce_fam_tree_id    
    FROM   siac_r_causale_ep_pdce_conto rcepc, siac_t_pdce_conto tpc
    WHERE  rcepc.causale_ep_id = v_causale_ep_id_mov
    AND    rcepc.pdce_conto_id = v_pdce_conto_id
    AND    rcepc.pdce_conto_id = tpc.pdce_conto_id
    --AND    p_data BETWEEN rcepc.validita_inizio AND COALESCE(rcepc.validita_fine, p_data)
    AND    rcepc.data_cancellazione IS NULL
    --AND    p_data BETWEEN tpc.validita_inizio AND COALESCE(tpc.validita_fine, p_data)
    AND    tpc.data_cancellazione IS NULL;  */      

    SELECT tpc.livello, tpc.ordine, tpc.pdce_conto_code, tpc.pdce_conto_desc, 
           tpc.pdce_conto_id_padre, tpc.pdce_ct_tipo_id, tpc.pdce_fam_tree_id
    INTO   v_livello, v_ordine, v_pdce_conto_code, v_pdce_conto_desc, 
           v_pdce_conto_id_padre, v_pdce_ct_tipo_id, v_pdce_fam_tree_id    
    FROM   siac_t_pdce_conto tpc
    WHERE  tpc.pdce_conto_id = v_pdce_conto_id
    AND    tpc.data_cancellazione IS NULL;  

    v_classif_id := null;
        
    SELECT rpcc.classif_id
    INTO   v_classif_id
    FROM   siac_r_pdce_conto_class rpcc
    WHERE  rpcc.pdce_conto_id = v_pdce_conto_id
    --AND    p_data BETWEEN rpcc.validita_inizio AND COALESCE(rpcc.validita_fine, p_data)
    AND    rpcc.data_cancellazione IS NULL; 

    v_conta_ciclo_classif :=0;   
    v_classif_code_bil := null;
    v_classif_id_padre := null;

    LOOP
                 
      v_classif_code_app := null;
      v_classif_desc_app := null;      
      v_classif_id_part := null;

      IF v_conta_ciclo_classif = 0 THEN
         v_classif_id_part := v_classif_id;
      ELSE
         v_classif_id_part := v_classif_id_padre;
      END IF;
            
/*      SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre
      INTO   v_classif_code_app, v_classif_desc_app, v_classif_id_padre
      FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc
      WHERE rcft.classif_id = tc.classif_id
      AND   tc.classif_id = v_classif_id_part
      AND   rcft.data_cancellazione IS NULL
      AND   tc.data_cancellazione IS NULL;
      --AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
      --AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data);
      */
      -- Trasformato in cursore con la condizione sulle date messa come if per velocizzare la funzione
      FOR class IN 
      SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre
      ,rcft.validita_inizio data_inizio_fam_tree, rcft.validita_fine data_fine_fam_tree, tc.validita_inizio data_inizio_class, tc.validita_fine data_fine_class
      FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc
      WHERE rcft.classif_id = tc.classif_id
      AND   tc.classif_id = v_classif_id_part
      AND   rcft.data_cancellazione IS NULL
      AND   tc.data_cancellazione IS NULL
      
      LOOP

      --IF p_data BETWEEN class.data_inizio_fam_tree AND COALESCE(class.data_fine_fam_tree, p_data) 
      --AND p_data BETWEEN class.data_inizio_class AND COALESCE(class.data_fine_class, p_data) 
      --THEN

         v_classif_id_padre := class.classif_id_padre;
         v_classif_code_app := class.classif_code;
         
          IF v_classif_code_bil is null THEN
             v_classif_code_bil := v_classif_code_app; 
          ELSE
             v_classif_code_bil := v_classif_code_app||'.'||v_classif_code_bil;
          END IF;                       
          
          v_conta_ciclo_classif := v_conta_ciclo_classif +1;
          
      --END IF;
       
      END LOOP;
       
      EXIT WHEN v_classif_id_padre IS NULL;
      
    END LOOP;
         
    v_pdce_ct_tipo_code := null;  
    v_pdce_ct_tipo_desc := null; 
      
    SELECT dpct.pdce_ct_tipo_code, dpct.pdce_ct_tipo_desc
    INTO   v_pdce_ct_tipo_code, v_pdce_ct_tipo_desc
    FROM   siac_d_pdce_conto_tipo dpct
    WHERE  dpct.pdce_ct_tipo_id = v_pdce_ct_tipo_id
    --AND    p_data BETWEEN dpct.validita_inizio AND COALESCE(dpct.validita_fine, p_data)
    AND    dpct.data_cancellazione IS NULL;    
    
    v_pdce_fam_tree_code := null;  
    v_pdce_fam_tree_desc := null; 
    v_pdce_fam_id := null;  
      
    SELECT --tpft.pdce_fam_code, tpft.pdce_fam_desc,
           tpft.pdce_fam_id
    INTO   --v_pdce_fam_tree_code, v_pdce_fam_tree_desc,
           v_pdce_fam_id       
    FROM   siac_t_pdce_fam_tree tpft
    WHERE  tpft.pdce_fam_tree_id = v_pdce_fam_tree_id
    ---AND    p_data BETWEEN tpft.validita_inizio AND COALESCE(tpft.validita_fine, p_data)
    AND    tpft.data_cancellazione IS NULL;    
    
    v_pdce_fam_code := null; 
    v_pdce_fam_desc := null; 
    v_pdce_fam_segno := null;
    v_ambito_id := null;  
      
    SELECT dpf.pdce_fam_code, dpf.pdce_fam_desc, --dpf.pdce_fam_segno,
           dpf.ambito_id
    INTO   v_pdce_fam_code, v_pdce_fam_desc, --v_pdce_fam_segno,
           v_ambito_id       
    FROM   siac_d_pdce_fam dpf
    WHERE  dpf.pdce_fam_id = v_pdce_fam_id
    --AND    p_data BETWEEN dpf.validita_inizio AND COALESCE(dpf.validita_fine, p_data)
    AND    dpf.data_cancellazione IS NULL;    
    
    v_ambito_code := null; 
    v_ambito_desc := null;
      
    SELECT da.ambito_code, da.ambito_desc
    INTO   v_ambito_code, v_ambito_desc
    FROM   siac_d_ambito da
    WHERE  da.ambito_id = v_ambito_id
    --AND    p_data BETWEEN da.validita_inizio AND COALESCE(da.validita_fine, p_data)
    AND    da.data_cancellazione IS NULL;  

    v_evento_code := null;
    v_evento_desc := null; 
    v_collegamento_tipo_code := null;
    v_collegamento_tipo_desc := null;
    v_evento_tipo_id := null;    
    v_classif_code := null;
    v_classif_desc := null;
    v_entrate_uscite := null;
    v_mod_stato_r_id := null;
    v_movgest_ts_id_mod := null;
    v_flag_mod := null;
    v_movgest_ts_id_mod := null;
    v_movgest_id := null; 
    v_ricecon_id := null;  
    v_movgest_anno := null;     
    v_movgest_numero := null;
    v_movgest_ts_code := null;    
    v_ord_ts_id := null; 
    v_ord_ts_code := null;
    v_ord_anno := null;
    v_ord_numero := null;  
    v_anno_liq := null; 
    v_num_liq := null;
    v_doc_id := null; 
    v_num_subdoc := null; 
    v_anno_doc := null;
    v_num_doc := null; 
    v_data_emissione_doc := null;
    v_doc_tipo_id := null;
    v_doc_tipo_code := null;
    v_soggetto_code := null; 
    v_ricecon_numero := null;      
  
  IF v_causale_ep_tipo_code <> 'LIB' THEN
    
    SELECT tc.classif_code, tc.classif_desc
    INTO   v_classif_code, v_classif_desc
    FROM   siac_r_causale_ep_class rcec, siac_t_class tc, siac_d_class_tipo dct
    WHERE  rcec.causale_ep_id = v_causale_ep_id_mov
    AND    rcec.classif_id = tc.classif_id
    AND    tc.classif_tipo_id = dct.classif_tipo_id
    AND    dct.classif_tipo_code = 'PDC_V'
    --AND    p_data BETWEEN rcec.validita_inizio AND COALESCE(rcec.validita_fine, p_data)
    AND    rcec.data_cancellazione IS NULL
    --AND    p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
    AND    tc.data_cancellazione IS NULL
    --AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)
    AND    dct.data_cancellazione IS NULL;  
    
    v_entrate_uscite  := SUBSTRING(v_classif_code from 1 for 1);
  
    SELECT de.evento_code, de.evento_desc, dct.collegamento_tipo_code, dct.collegamento_tipo_desc,
           de.evento_tipo_id
    INTO   v_evento_code, v_evento_desc, v_collegamento_tipo_code, v_collegamento_tipo_desc, 
           v_evento_tipo_id         
    FROM   siac_d_evento de, siac_d_collegamento_tipo dct
    WHERE  de.evento_id = v_evento_id
    AND    de.collegamento_tipo_id = dct.collegamento_tipo_id
    --AND    p_data BETWEEN de.validita_inizio AND COALESCE(de.validita_fine, p_data)
    AND    de.data_cancellazione IS NULL
    --AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)
    AND    dct.data_cancellazione IS NULL;    
          
    -- Si dovra' forse tenere conto anche dei tipi RE e RR rispettivamente Richiesta Economale e Rendiconto Richiesta Economale 
    -- Condizione aggiunta il 13/02/2017
    IF v_collegamento_tipo_code in ('I','A','SI','SA','MMGS','MMGE') THEN
    
      IF v_collegamento_tipo_code in ('MMGS','MMGE') THEN
       
        SELECT rms.mod_stato_r_id
        INTO  v_mod_stato_r_id
        FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms
        WHERE rms.ente_proprietario_id = p_ente_proprietario_id
        AND   tm.mod_id = v_campo_pk_id  
        AND   tm.mod_id = rms.mod_id  
        AND   rms.mod_stato_id = dms.mod_stato_id
        AND   dms.mod_stato_code = 'V'
        --AND   p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
        AND   tm.data_cancellazione IS NULL
        --AND   p_data BETWEEN rms.validita_inizio AND COALESCE(rms.validita_fine, p_data)
        AND   rms.data_cancellazione IS NULL
        --AND   p_data BETWEEN dms.validita_inizio AND COALESCE(dms.validita_fine, p_data)
        AND   dms.data_cancellazione IS NULL;    

        SELECT tmtdm.movgest_ts_id 
        INTO   v_movgest_ts_id_mod
        FROM   siac_t_movgest_ts_det_mod tmtdm
        WHERE  tmtdm.ente_proprietario_id = p_ente_proprietario_id
        AND    tmtdm.mod_stato_r_id = v_mod_stato_r_id
        --AND    p_data BETWEEN tmtdm.validita_inizio AND COALESCE(tmtdm.validita_fine, p_data)
        AND    tmtdm.data_cancellazione IS NULL;      
     
        IF v_movgest_ts_id_mod IS NOT NULL THEN
            
          v_flag_mod := 'S';
          
        ELSE
          
          v_flag_mod := 'N';
          
          SELECT rmtsm.movgest_ts_id 
          INTO   v_movgest_ts_id_mod
          FROM   siac_r_movgest_ts_sog_mod rmtsm
          WHERE  rmtsm.ente_proprietario_id = p_ente_proprietario_id
          AND    rmtsm.mod_stato_r_id = v_mod_stato_r_id
          --AND    p_data BETWEEN rmtsm.validita_inizio AND COALESCE(rmtsm.validita_fine, p_data)
          AND    rmtsm.data_cancellazione IS NULL;         
          
          IF v_movgest_ts_id_mod IS NOT NULL AND v_ambito_code = 'AMBITO_GSA' THEN
             v_flag_mod := 'S';
          END IF;     
                  
        END IF;
      
        SELECT tmt.movgest_id, tmt.movgest_ts_code
        INTO  v_movgest_id, v_movgest_ts_code 
        FROM  siac_t_movgest_ts tmt
        WHERE tmt.movgest_ts_id = v_movgest_ts_id_mod
        AND   tmt.ente_proprietario_id = p_ente_proprietario_id
        --AND   p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
        AND   tmt.data_cancellazione IS NULL;         

        SELECT tm.movgest_anno, tm.movgest_numero
        INTO  v_movgest_anno, v_movgest_numero
        FROM  siac_t_movgest tm
        WHERE tm.movgest_id = v_movgest_id
        AND   tm.ente_proprietario_id = p_ente_proprietario_id
        --AND   p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
        AND   tm.data_cancellazione IS NULL;        
      
      END IF;
      
      IF v_collegamento_tipo_code in ('I','A') THEN
      
        SELECT tm.movgest_anno, tm.movgest_numero
        INTO  v_movgest_anno, v_movgest_numero
        FROM  siac_t_movgest tm
        WHERE tm.movgest_id = v_campo_pk_id
        AND   tm.ente_proprietario_id = p_ente_proprietario_id
        --AND   p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
        AND   tm.data_cancellazione IS NULL;       
      
      END IF;
      
      IF v_collegamento_tipo_code in ('SI','SA') THEN
      
        SELECT tmt.movgest_id, tmt.movgest_ts_code
        INTO  v_movgest_id, v_movgest_ts_code 
        FROM  siac_t_movgest_ts tmt
        WHERE tmt.movgest_ts_id = v_campo_pk_id
        AND   tmt.ente_proprietario_id = p_ente_proprietario_id
        --AND   p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
        AND   tmt.data_cancellazione IS NULL;         

        SELECT tm.movgest_anno, tm.movgest_numero
        INTO  v_movgest_anno, v_movgest_numero
        FROM  siac_t_movgest tm
        WHERE tm.movgest_id = v_movgest_id
        AND   tm.ente_proprietario_id = p_ente_proprietario_id
        --AND   p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
        AND   tm.data_cancellazione IS NULL; 
      
      END IF;      
      
      IF v_collegamento_tipo_code in ('I','A') AND v_movgest_ts_code = v_movgest_numero::varchar THEN
         v_movgest_ts_code := null;
      END IF;
  
    ELSIF v_collegamento_tipo_code in ('OP','OI') THEN

      SELECT sto.ord_anno, sto.ord_numero
      INTO  v_ord_anno, v_ord_numero
      FROM  siac_t_ordinativo sto
      WHERE sto.ord_id = v_campo_pk_id
      AND   sto.ente_proprietario_id = p_ente_proprietario_id
      --AND   p_data BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, p_data)
      AND   sto.data_cancellazione IS NULL;       
                             
    ELSIF v_collegamento_tipo_code = 'L' THEN  

      SELECT tl.liq_anno, tl.liq_numero
      INTO  v_anno_liq, v_num_liq
      FROM  siac_t_liquidazione tl
      WHERE tl.liq_id = v_campo_pk_id
      --AND   p_data BETWEEN tl.validita_inizio AND COALESCE(tl.validita_fine, p_data)
      AND   tl.data_cancellazione IS NULL;        

    ELSIF v_collegamento_tipo_code in ('SS','SE') THEN  
      
      SELECT ts.doc_id, ts.subdoc_numero
      INTO  v_doc_id, v_num_subdoc 
      FROM  siac_t_subdoc ts
      WHERE ts.subdoc_id = v_campo_pk_id
      AND   ts.ente_proprietario_id = p_ente_proprietario_id
      --AND   p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
      AND   ts.data_cancellazione IS NULL;         

      SELECT td.doc_anno, td.doc_numero, td.doc_tipo_id, td.doc_data_emissione
      INTO  v_anno_doc, v_num_doc, v_doc_tipo_id, v_data_emissione_doc
      FROM  siac_t_doc td
      WHERE td.doc_id = v_doc_id
      AND   td.ente_proprietario_id = p_ente_proprietario_id
      --AND   p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
      AND   td.data_cancellazione IS NULL;  

      SELECT ddt.doc_tipo_code
      INTO   v_doc_tipo_code
      FROM   siac_d_doc_tipo ddt
      WHERE  ddt.doc_tipo_id = v_doc_tipo_id
      --AND    p_data BETWEEN ddt.validita_inizio AND COALESCE(ddt.validita_fine, p_data)
      AND    ddt.data_cancellazione IS NULL;
            
      SELECT ts.soggetto_code
      INTO   v_soggetto_code
      FROM   siac_r_doc_sog srds, siac_t_soggetto ts
      WHERE  srds.doc_id = v_doc_id
      AND    srds.soggetto_id = ts.soggetto_id
      --AND    p_data BETWEEN srds.validita_inizio AND COALESCE(srds.validita_fine, p_data)
      --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
      AND    srds.data_cancellazione IS NULL
      AND    ts.data_cancellazione IS NULL;
   
    ELSIF v_collegamento_tipo_code = 'RR' THEN

      SELECT tg.ricecon_id
      INTO   v_ricecon_id
      FROM   siac_t_giustificativo tg
      WHERE  tg.gst_id = v_campo_pk_id      
      --AND    p_data BETWEEN tg.validita_inizio AND COALESCE(tg.validita_fine, p_data)
      AND    tg.data_cancellazione  IS NULL;

      SELECT tre.ricecon_numero
      INTO   v_ricecon_numero
      FROM   siac_t_richiesta_econ tre
      WHERE  tre.ricecon_id = v_ricecon_id      
      --AND    p_data BETWEEN tre.validita_inizio AND COALESCE(tre.validita_fine, p_data)
      AND    tre.data_cancellazione  IS NULL;

    ELSIF v_collegamento_tipo_code = 'RE' THEN

      SELECT tre.ricecon_numero
      INTO   v_ricecon_numero
      FROM   siac_t_richiesta_econ tre
      WHERE  tre.ricecon_id = v_campo_pk_id      
      --AND    p_data BETWEEN tre.validita_inizio AND COALESCE(tre.validita_fine, p_data)   
      AND    tre.data_cancellazione  IS NULL;

    END IF;

  END IF;
    
    FOR causale in
    SELECT tce.causale_ep_code, tce.causale_ep_desc
    FROM siac_t_causale_ep tce
    WHERE tce.causale_ep_id = v_causale_ep_id_mov
    --AND   p_data BETWEEN tce.validita_inizio AND COALESCE(tce.validita_fine, p_data)
    --AND  tce.data_cancellazione is NULL
    AND  (tce.data_cancellazione is NULL
         OR 
         tce.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
         ) 

    LOOP
      
      v_causale_ep_code := null;
      v_causale_ep_desc := null;
      v_causale_ep_code := causale.causale_ep_code;
      v_causale_ep_desc := causale.causale_ep_desc;
    
      v_causale_ep_stato_code := null;
      v_causale_ep_stato_desc := null;
        
      SELECT dces.causale_ep_stato_code, dces.causale_ep_stato_desc
      INTO   v_causale_ep_stato_code, v_causale_ep_stato_desc
      FROM   siac_r_causale_ep_stato rces, siac_d_causale_ep_stato dces
      WHERE  rces.causale_ep_id = v_causale_ep_id_mov 
      AND    dces.causale_ep_stato_id = rces.causale_ep_stato_id
      --AND    p_data BETWEEN rces.validita_inizio AND COALESCE(rces.validita_fine, p_data)
      AND    rces.data_cancellazione IS NULL
      --AND    p_data BETWEEN dces.validita_inizio AND COALESCE(dces.validita_fine, p_data)
      AND    dces.data_cancellazione IS NULL;     
    
        INSERT INTO siac.siac_dwh_contabilita_generale
        ( ente_proprietario_id,
          ente_denominazione,
          bil_anno,
          desc_prima_nota,
          num_provvisorio_prima_nota,  
          num_definitivo_prima_nota, 
          data_registrazione_prima_nota, 
          cod_stato_prima_nota,  
          desc_stato_prima_nota,
          cod_mov_ep,
          desc_mov_ep,
          cod_mov_ep_dettaglio, 
          desc_mov_ep_dettaglio, 
          importo_mov_ep,
          segno_mov_ep,
          cod_piano_dei_conti,
          desc_piano_dei_conti,             
          livello_piano_dei_conti, 
          ordine_piano_dei_conti, 
          --cod_pdce_fam_tree,
          --desc_pdce_fam_tree,
          cod_pdce_fam,
          desc_pdce_fam,      
          --segno_pdce_fam,
          cod_ambito,
          desc_ambito,
          cod_causale,
          desc_causale,      
          cod_tipo_causale,
          desc_tipo_causale,
          cod_stato_causale,
          desc_stato_causale,      
          cod_evento,
          desc_evento,
          cod_tipo_mov_finanziario,
          desc_tipo_mov_finanziario,
          --cod_tipo_evento,
          --desc_tipo_evento,
          cod_piano_finanziario,
          desc_piano_finanziario,
          --collegamento_mov_finanziario,
          anno_movimento, 
          numero_movimento,
          cod_submovimento,        
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
          cod_bilancio,
          numero_ricecon       
        )
        VALUES (p_ente_proprietario_id,
                v_ente_denominazione,
                v_anno,
                v_pnota_desc, 
                v_pnota_numero, 
                v_pnota_progressivogiornale, 
                v_pnota_dataregistrazionegiornale, 
                v_pnota_stato_code,  
                v_pnota_stato_desc,
                v_movep_code,
                v_movep_desc,
                v_movep_det_code, 
                v_movep_det_desc, 
                v_movep_det_importo,
                v_movep_det_segno,
                v_pdce_conto_code,
                v_pdce_conto_desc,
                v_livello, 
                v_ordine, 
                --v_pdce_fam_tree_code,  
                --v_pdce_fam_tree_desc,
                v_pdce_fam_code,
                v_pdce_fam_desc,
                --v_pdce_fam_segno,
                v_ambito_code, 
                v_ambito_desc,
                v_causale_ep_code,
                v_causale_ep_desc,
                v_causale_ep_tipo_code,
                v_causale_ep_tipo_desc,
                v_causale_ep_stato_code,
                v_causale_ep_stato_desc,
                v_evento_code,
                v_evento_desc, 
                v_collegamento_tipo_code,
                v_collegamento_tipo_desc,                
                --v_evento_tipo_code,
                --v_evento_tipo_desc,
                v_classif_code,
                v_classif_desc,
                --v_campo_pk_id,
                v_movgest_anno,
                v_movgest_numero,
                v_movgest_ts_code,                 
                v_ord_anno,  
                v_ord_numero,
                v_ord_ts_code,
                v_anno_liq,
                v_num_liq,
                v_anno_doc,
                v_num_doc,
                v_doc_tipo_code,
                v_data_emissione_doc,
                v_soggetto_code,
                v_num_subdoc,
                v_flag_mod,
                v_entrate_uscite,
                v_classif_code_bil,
                v_ricecon_numero                                 
               );
 
    END LOOP;
    
  END LOOP;

END LOOP;
               
esito:= 'Fine funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
-- SIAC-5325 FINE

-- SIAC-5425 INIZIO


CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_capitolospesa (
  _uid_capitolospesa integer,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  ord_numero numeric,
  ord_desc varchar,
  ord_emissione_data timestamp,
  soggetto_code varchar,
  soggetto_desc varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  ord_stato_desc varchar,
  importo numeric,
  ord_ts_code varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  uid_capitolo integer,
  num_capitolo varchar,
  num_articolo varchar,
  num_ueb varchar,
  capitolo_desc varchar,
  provc_anno integer,
  provc_numero numeric,
  provc_data_convalida timestamp
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
 rec record;
 rec2 record;
 attoamm_uid integer;
BEGIN

	for rec in 
		select
			siac_r_ordinativo_bil_elem.ord_id,
			siac_t_ordinativo.ord_numero,
			siac_t_ordinativo.ord_emissione_data,
			siac_t_bil_elem.elem_id,
			siac_t_bil_elem.elem_code,
			siac_t_bil_elem.elem_code2,
			siac_t_bil_elem.elem_code3,
			siac_t_bil_elem.elem_desc,
            siac_t_ordinativo.ord_desc,
            siac_d_ordinativo_stato.ord_stato_desc,
            siac_t_ordinativo_ts_det.ord_ts_det_importo as importo,
            siac_t_ordinativo_ts.ord_ts_code
		from
			 siac_r_ordinativo_bil_elem --r
			,siac_t_bil_elem --s
			,siac_t_ordinativo --y
			,siac_d_ordinativo_tipo --i            
            ,siac_r_ordinativo_stato --d,
            ,siac_d_ordinativo_stato --e,
            ,siac_t_ordinativo_ts --f,
            ,siac_t_ordinativo_ts_det --g,
            ,siac_d_ordinativo_ts_det_tipo --h
              
		where siac_t_bil_elem.elem_id=siac_r_ordinativo_bil_elem.elem_id
		and siac_t_ordinativo.ord_id=siac_r_ordinativo_bil_elem.ord_id
		and siac_t_bil_elem.elem_id=_uid_capitolospesa
		and siac_d_ordinativo_tipo.ord_tipo_id=siac_t_ordinativo.ord_tipo_id
		and siac_d_ordinativo_tipo.ord_tipo_code='P'
		and siac_r_ordinativo_bil_elem.data_cancellazione is null
		and siac_t_bil_elem.data_cancellazione is null
		and siac_d_ordinativo_tipo.data_cancellazione is null
		and now() BETWEEN siac_r_ordinativo_bil_elem.validita_inizio and coalesce (siac_r_ordinativo_bil_elem.validita_fine,now())
		and siac_t_ordinativo.data_cancellazione is null       
        and siac_r_ordinativo_stato.ord_id=siac_t_ordinativo.ord_id
        and siac_r_ordinativo_stato.ord_stato_id=siac_d_ordinativo_stato.ord_stato_id
        and now() BETWEEN siac_r_ordinativo_stato.validita_inizio and COALESCE(siac_r_ordinativo_stato.validita_fine,now())
        and siac_t_ordinativo_ts.ord_id=siac_t_ordinativo.ord_id
        and siac_t_ordinativo_ts_det.ord_ts_id=siac_t_ordinativo_ts.ord_ts_id
        and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_id=siac_t_ordinativo_ts_det.ord_ts_det_tipo_id
        and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code = 'A'
        and siac_t_ordinativo.data_cancellazione is null
        and siac_r_ordinativo_stato.data_cancellazione is null
        and siac_d_ordinativo_stato.data_cancellazione is null
        and siac_t_ordinativo_ts.data_cancellazione is null
        and siac_t_ordinativo_ts_det.data_cancellazione is null
        
		order by 2,3
		LIMIT _limit
		OFFSET _offset
	
	loop
		uid:=rec.ord_id;
		uid_capitolo:=rec.elem_id;
		num_capitolo:=rec.elem_code;
		num_articolo:=rec.elem_code2;
		num_ueb:=rec.elem_code3;
		capitolo_desc:=rec.elem_desc;

              uid := rec.ord_id;
              ord_numero := rec.ord_numero;
              ord_desc := rec.ord_desc;              
              ord_emissione_data := rec.ord_emissione_data;
              ord_stato_desc := rec.ord_stato_desc;
              importo := rec.importo;
              ord_ts_code := rec.ord_ts_code;

              select
                  siac_t_soggetto.soggetto_code,
                  siac_t_soggetto.soggetto_desc
              into
                  soggetto_code,
                  soggetto_desc
              from
                  siac_r_ordinativo_soggetto --b,
                  ,siac_t_soggetto --c
              where siac_r_ordinativo_soggetto.ord_id=uid
              and siac_r_ordinativo_soggetto.soggetto_id=siac_t_soggetto.soggetto_id
              and now() BETWEEN siac_r_ordinativo_soggetto.validita_inizio and COALESCE(siac_r_ordinativo_soggetto.validita_fine,now())
              and siac_r_ordinativo_soggetto.data_cancellazione is null
              and siac_t_soggetto.data_cancellazione is null;
      		
              select
                  siac_t_atto_amm.attoamm_id,
                  siac_t_atto_amm.attoamm_numero,
                  siac_t_atto_amm.attoamm_anno,
                  siac_d_atto_amm_stato.attoamm_stato_desc,
                  siac_d_atto_amm_tipo.attoamm_tipo_code,
                  siac_d_atto_amm_tipo.attoamm_tipo_desc
              into
                  attoamm_uid,
                  attoamm_numero,
                  attoamm_anno,
                  attoamm_stato_desc,
                  attoamm_tipo_code,
                  attoamm_tipo_desc
              from
                  siac_r_ordinativo_atto_amm --m
                  ,siac_t_atto_amm --n
                  ,siac_d_atto_amm_tipo --o
                  ,siac_r_atto_amm_stato --p
                  ,siac_d_atto_amm_stato --q
              where siac_r_ordinativo_atto_amm.ord_id=uid
              and siac_t_atto_amm.attoamm_id=siac_r_ordinativo_atto_amm.attoamm_id
              and siac_d_atto_amm_tipo.attoamm_tipo_id=siac_t_atto_amm.attoamm_tipo_id
              and siac_r_atto_amm_stato.attoamm_id=siac_t_atto_amm.attoamm_id
              and siac_r_atto_amm_stato.attoamm_stato_id=siac_d_atto_amm_stato.attoamm_stato_id
              and now() BETWEEN siac_r_atto_amm_stato.validita_inizio and coalesce (siac_r_atto_amm_stato.validita_fine,now())
              and now() BETWEEN siac_r_ordinativo_atto_amm.validita_inizio and COALESCE(siac_r_ordinativo_atto_amm.validita_fine,now())
              and siac_d_atto_amm_stato.attoamm_stato_code<>'ANNULLATO'
              and siac_r_ordinativo_atto_amm.data_cancellazione is null
              and siac_t_atto_amm.data_cancellazione is null
              and siac_d_atto_amm_tipo.data_cancellazione is null
              and siac_r_atto_amm_stato.data_cancellazione is null
              and siac_d_atto_amm_stato.data_cancellazione is null;
      		
              accredito_tipo_code := null;
              accredito_tipo_desc := null;
      		
              select
                  siac_d_accredito_tipo.accredito_tipo_code,
                  siac_d_accredito_tipo.accredito_tipo_desc
              into
                  accredito_tipo_code,
                  accredito_tipo_desc
              FROM
                  siac_r_ordinativo_modpag --c2,
                  ,siac_t_modpag --d2,
                  ,siac_d_accredito_tipo --e2
              where siac_r_ordinativo_modpag.ord_id=uid
                and siac_r_ordinativo_modpag.modpag_id=siac_t_modpag.modpag_id
                and siac_d_accredito_tipo.accredito_tipo_id=siac_t_modpag.accredito_tipo_id
                and now() BETWEEN siac_r_ordinativo_modpag.validita_inizio and coalesce (siac_r_ordinativo_modpag.validita_fine,now())
                and siac_r_ordinativo_modpag.data_cancellazione is null
                and siac_t_modpag.data_cancellazione is null
                and siac_d_accredito_tipo.data_cancellazione is null;
      		
              IF accredito_tipo_code IS NULL THEN
                  SELECT
                      drt.relaz_tipo_code,
                      drt.relaz_tipo_desc
                  into
                      accredito_tipo_code,
                      accredito_tipo_desc
                  FROM
                      siac_r_ordinativo_modpag rom,
                      siac_r_soggetto_relaz rsr,
                      siac_d_relaz_tipo drt
                  where rom.ord_id=uid
                    and rsr.soggetto_relaz_id = rom.soggetto_relaz_id
                    and drt.relaz_tipo_id = rsr.relaz_tipo_id
                    and now() BETWEEN rom.validita_inizio and coalesce (rom.validita_fine,now())
                    and now() BETWEEN rsr.validita_inizio and coalesce (rsr.validita_fine,now())
                    and rom.data_cancellazione is null
                    and rsr.data_cancellazione is null
                    and drt.data_cancellazione is null;
              END IF;
      		
              attoamm_sac_code:=null;
              attoamm_sac_desc:=null;
      		
              select
                  siac_t_class.classif_code,
                  siac_t_class.classif_desc
              into
                  attoamm_sac_code,
                  attoamm_sac_desc
              from
                  siac_r_atto_amm_class --z,
                  ,siac_t_class --y,
                  ,siac_d_class_tipo --x
              where siac_r_atto_amm_class.attoamm_id=attoamm_uid
              and siac_r_atto_amm_class.classif_id=siac_t_class.classif_id
              and siac_d_class_tipo.classif_tipo_id=siac_t_class.classif_tipo_id
              and now() BETWEEN siac_r_atto_amm_class.validita_inizio and coalesce (siac_r_atto_amm_class.validita_fine,now())
              and siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
              and siac_r_atto_amm_class.data_cancellazione is NULL
              and siac_d_class_tipo.data_cancellazione is NULL
              and siac_t_class.data_cancellazione is NULL;
      		
              select
                  siac_t_prov_cassa.provc_anno,
                  siac_t_prov_cassa.provc_numero,
                  siac_t_prov_cassa.provc_data_convalida
              into
                  provc_anno,
                  provc_numero,
                  provc_data_convalida
              from
                  siac_r_ordinativo_prov_cassa --a2,
                  ,siac_t_prov_cassa --b2
              where siac_r_ordinativo_prov_cassa.ord_id=uid
              and siac_t_prov_cassa.provc_id=siac_r_ordinativo_prov_cassa.provc_id
              and now() BETWEEN siac_r_ordinativo_prov_cassa.validita_inizio and coalesce (siac_r_ordinativo_prov_cassa.validita_fine,now())
              and siac_r_ordinativo_prov_cassa.data_cancellazione is NULL
              and siac_t_prov_cassa.data_cancellazione is NULL;
      		
              return next;
              
		--end loop;
	end loop;

	return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_capitolospesa_total (
  _uid_capitolospesa integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) 
	into total
	from (
          SELECT 1
          from
              siac_r_ordinativo_bil_elem --r,
              ,siac_t_bil_elem --s,
              ,siac_t_ordinativo --y,
              ,siac_d_ordinativo_tipo --i
              
              ,siac_r_ordinativo_stato --d,
              ,siac_d_ordinativo_stato --e,
              ,siac_t_ordinativo_ts --f,
              ,siac_t_ordinativo_ts_det --g,
              ,siac_d_ordinativo_ts_det_tipo --h
              
          where 
              siac_t_bil_elem.elem_id=siac_r_ordinativo_bil_elem.elem_id
          and siac_t_ordinativo.ord_id=siac_r_ordinativo_bil_elem.ord_id
          and siac_t_bil_elem.elem_id= _uid_capitolospesa
          and siac_d_ordinativo_tipo.ord_tipo_id=siac_t_ordinativo.ord_tipo_id
          and siac_d_ordinativo_tipo.ord_tipo_code='P'
          and siac_r_ordinativo_bil_elem.data_cancellazione is null
          and siac_t_bil_elem.data_cancellazione is null
          and siac_d_ordinativo_tipo.data_cancellazione is null
          and now() BETWEEN siac_r_ordinativo_bil_elem.validita_inizio and coalesce (siac_r_ordinativo_bil_elem.validita_fine,now())
		  and siac_t_ordinativo.data_cancellazione is null         
          and siac_r_ordinativo_stato.ord_id=siac_t_ordinativo.ord_id
          and siac_r_ordinativo_stato.ord_stato_id=siac_d_ordinativo_stato.ord_stato_id
          and now() BETWEEN siac_r_ordinativo_stato.validita_inizio and COALESCE(siac_r_ordinativo_stato.validita_fine,now())
          and siac_t_ordinativo_ts.ord_id=siac_t_ordinativo.ord_id
          and siac_t_ordinativo_ts_det.ord_ts_id=siac_t_ordinativo_ts.ord_ts_id
          and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_id=siac_t_ordinativo_ts_det.ord_ts_det_tipo_id
          and siac_d_ordinativo_ts_det_tipo.ord_ts_det_tipo_code = 'A'
          and siac_t_ordinativo.data_cancellazione is null
          and siac_r_ordinativo_stato.data_cancellazione is null
          and siac_d_ordinativo_stato.data_cancellazione is null
          and siac_t_ordinativo_ts.data_cancellazione is null
          and siac_t_ordinativo_ts_det.data_cancellazione is null
	)	   
  	as ord_id ;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-5425

-- SIAC-5289 - INIZIO - Maurizio

DROP FUNCTION IF EXISTS siac."BILR168_riepilogo_anticipi_spesa_rimborsi"(p_ente_prop_id integer, p_anno varchar, p_data_da date, p_data_a date, p_cassaecon_id integer);

CREATE OR REPLACE FUNCTION siac."BILR168_riepilogo_anticipi_spesa_rimborsi" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_da date,
  p_data_a date,
  p_cassaecon_id integer
)
RETURNS TABLE (
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  anno_impegno integer,
  num_impegno varchar,
  descr_impegno varchar,
  num_sub_impegno varchar,
  num_movimento integer,
  tipo_richiesta varchar,
  num_sospeso integer,
  data_movimento date,
  data_richiesta date,
  matricola varchar,
  nominativo varchar,
  descr_richiesta varchar,
  imp_richiesta numeric,
  code_tipo_richiesta varchar,
  tipo varchar,
  rendicontato varchar
) AS
$body$
DECLARE
elenco_movimenti record;
dati_giustif record;
sql_query VARCHAR;
num_date INTEGER;
RTN_MESSAGGIO text;

BEGIN   
   num_capitolo='';
   num_articolo='';
   ueb='';
   anno_impegno=0;
   num_impegno='';
   descr_impegno='';
   num_movimento=0;
   tipo_richiesta='';
   num_sospeso=0;
   data_movimento=NULL;

   matricola='';
   nominativo='';
   descr_richiesta='';
   imp_richiesta=0;   
   code_tipo_richiesta='';
   num_sub_impegno='';
   

        
RTN_MESSAGGIO:='esecuzione della query. ';   
 
sql_query:='with ele_movimenti_cassa as(
select richiesta_econ.ricecon_id,
		movimento.movt_numero 					num_movimento,
        movimento.gst_id,
        richiesta_econ.ricecon_desc				descr_richiesta,
        richiesta_econ.ricecon_importo			imp_richiesta,
        richiesta_econ_tipo.ricecon_tipo_desc	tipo_richiesta,            
        richiesta_econ_tipo.ricecon_tipo_code  	code_tipo_richiesta,
        movimento.movt_data				data_movimento,
        richiesta_econ_sospesa.ricecons_numero	num_sospeso,
        richiesta_econ.ricecon_matricola		matricola,
        CASE WHEN  richiesta_econ.ricecon_nome = richiesta_econ.ricecon_cognome 
            THEN richiesta_econ.ricecon_nome
            ELSE richiesta_econ.ricecon_cognome||'' ''||
                richiesta_econ.ricecon_nome end nominativo,
        date_trunc(''day'', richiesta_econ.data_creazione) 	data_richiesta,
        t_giustif.rend_importo_restituito, 
        t_giustif.rend_importo_integrato
 from 	siac_t_movimento						movimento
 			LEFT JOIN siac_t_giustificativo 	t_giustif
            	on (t_giustif.gst_id = movimento.gst_id
                	AND t_giustif.data_cancellazione is null),
 		siac_t_richiesta_econ					richiesta_econ
        	LEFT join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
            	on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
            		and richiesta_econ_sospesa.data_cancellazione is null),
        siac_t_cassa_econ						cassa_econ,
 		siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
        siac_r_richiesta_econ_stato				r_richiesta_stato,
        siac_d_richiesta_econ_stato				richiesta_stato,
        siac_t_periodo 							anno_eserc,
        siac_t_bil 								bilancio
where   movimento.ricecon_id=richiesta_econ.ricecon_id	    
    AND cassa_econ.cassaecon_id= richiesta_econ.cassaecon_id
    AND richiesta_econ.ricecon_tipo_id=richiesta_econ_tipo.ricecon_tipo_id 
    AND richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id 
    AND r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id
    and richiesta_econ.bil_id=bilancio.bil_id
    and bilancio.periodo_id=anno_eserc.periodo_id
    and movimento.ente_proprietario_id ='||p_ente_prop_id||'
    and richiesta_econ.cassaecon_id='||p_cassaecon_id||'
    and anno_eserc.anno='''||p_anno||'''
    and richiesta_stato.ricecon_stato_code <> ''AN'' ';
    if p_data_da is NOT NULL AND p_data_a is NOT NULL THEN
    	sql_query:=sql_query||'
        	AND date_trunc(''day'', richiesta_econ.data_creazione) between '''||p_data_da||''' and '''|| p_data_a||'''';
    end if;
    sql_query:=sql_query||'
    AND richiesta_econ_tipo.ricecon_tipo_code in(
    	''ANTICIPO_SPESE'',
    	--''ANTICIPO_SPESE_MISSIONE'', 
       -- ''ANTICIPO_SPESE_MISSIONE_RENDICONTO'',
        ''ANTICIPO_SPESE_RENDICONTO'', 
      --  ''ANTICIPO_TRASFERTA_DIPENDENTI'',
        ''RIMBORSO_SPESE'')
    AND movimento.data_cancellazione IS NULL
    AND richiesta_econ.data_cancellazione IS NULL
    AND cassa_econ.data_cancellazione IS NULL
    AND richiesta_econ_tipo.data_cancellazione IS NULL
    AND r_richiesta_stato.data_cancellazione IS NULL
    AND richiesta_stato.data_cancellazione IS NULL
    AND anno_eserc.data_cancellazione IS NULL
    AND bilancio.data_cancellazione IS NULL ),
ele_movimenti_cap as(
	select r_richiesta_movgest.ricecon_id, movgest.movgest_anno anno_impegno,
    	movgest.movgest_numero num_impegno, movgest_ts.movgest_ts_code num_sub_impegno,
        bil_elem.elem_code num_capitolo,
        bil_elem.elem_code2 num_articolo, bil_elem.elem_code3 UEB,
        movgest.movgest_desc					descr_impegno
    from siac_r_richiesta_econ_movgest			r_richiesta_movgest,
    	siac_t_movgest							movgest,
    	siac_t_movgest_ts						movgest_ts,
        siac_r_movgest_bil_elem					r_mov_gest_bil_elem,
        siac_t_bil_elem							bil_elem
    where movgest_ts.movgest_id=movgest.movgest_id
    	and movgest_ts.movgest_ts_id=r_richiesta_movgest.movgest_ts_id
        and r_mov_gest_bil_elem.movgest_id=movgest.movgest_id
        and bil_elem.elem_id=r_mov_gest_bil_elem.elem_id
        and r_richiesta_movgest.ente_proprietario_id ='||p_ente_prop_id||'
        AND r_richiesta_movgest.data_cancellazione IS NULL  
        AND movgest.data_cancellazione IS NULL    
        AND movgest_ts.data_cancellazione IS NULL    
        AND r_mov_gest_bil_elem.data_cancellazione IS NULL    
        AND bil_elem.data_cancellazione IS NULL)  
select num_capitolo::varchar, 
		num_articolo::varchar, 
        ueb::varchar, 
        anno_impegno::integer, 
        num_impegno::varchar,
        descr_impegno::varchar,
		num_sub_impegno::varchar, 
        num_movimento::integer,
        tipo_richiesta::varchar, 
        num_sospeso::integer,
        --COALESCE(num_sospeso::varchar,'''')::varchar num_sospeso,
        data_movimento::date,
        data_richiesta::date, 
        COALESCE(matricola,'''')::varchar matricola,      
        nominativo::varchar nominativo,           
        COALESCE(descr_richiesta,'''')::varchar descr_richiesta,
        CASE WHEN gst_id IS NULL 
        	THEN imp_richiesta::numeric
            ELSE
            	CASE WHEN rend_importo_restituito > 0
                	THEN -rend_importo_restituito::numeric
                    ELSE rend_importo_integrato::numeric end
                end imp_richiesta, 
        code_tipo_richiesta::varchar ,
        CASE WHEN code_tipo_richiesta = ''RIMBORSO_SPESE'' 
        	THEN ''R''::varchar
            ELSE ''A''::varchar end tipo,
        CASE WHEN gst_id IS NULL 
        	THEN ''''::varchar
            ELSE ''R''::varchar end rendicontato
	from ele_movimenti_cassa
    	left join ele_movimenti_cap on ele_movimenti_cap.ricecon_id = ele_movimenti_cassa.ricecon_id        
    ORDER BY num_capitolo, num_articolo, ueb, anno_impegno, num_impegno';  

raise notice '%', sql_query;
return query execute sql_query;


exception
	when no_data_found THEN
		raise notice 'movimenti non trovati' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura dei movimenti non rendicontati ';
        RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-5289 - FINE - Maurizio

-- SIAC-5313 INIZIO
CREATE OR REPLACE VIEW siac.siac_v_dwh_predocumenti_incasso (
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
    conto_corrente_code,
    conto_corrente_desc,
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
    doc_fam_tipo_desc)
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
    d.predoc_id = a.predoc_id AND e.caus_id = d.caus_id AND f.caus_id = e.caus_id AND g.caus_tipo_id = f.caus_tipo_id AND h.predoc_id = a.predoc_id AND i.caus_fam_tipo_id = g.caus_fam_tipo_id AND a.doc_fam_tipo_id = l.doc_fam_tipo_id AND l.doc_fam_tipo_code::text = 'E'::text AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL AND g.data_cancellazione IS NULL AND h.data_cancellazione IS NULL AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL
        ), sog AS (
    SELECT a.predoc_id, b.soggetto_id, b.soggetto_code, b.soggetto_desc
    FROM siac_r_predoc_sog a, siac_t_soggetto b
    WHERE b.soggetto_id = a.soggetto_id AND a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL
    ), movgest AS (
    SELECT a.predoc_id, c.movgest_anno, c.movgest_numero,
                CASE
                    WHEN d.movgest_ts_tipo_code::text = 'T'::text THEN
                        '0'::character varying(200)
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
        AND (c.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL
    ), cc AS (
    SELECT a.predoc_id, b.classif_code, b.classif_desc,
            c.classif_tipo_code
    FROM siac_r_predoc_class a, siac_t_class b, siac_d_class_tipo c
    WHERE a.classif_id = b.classif_id AND c.classif_tipo_id = b.classif_tipo_id
        AND c.classif_tipo_code::text = 'CBPI'::text AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL
    ), doc AS (
    SELECT e.predoc_id, a.doc_id, a.doc_numero, a.doc_anno,
            a.doc_data_emissione, c.doc_tipo_code, c.doc_tipo_desc
    FROM siac_t_doc a, siac_t_subdoc b, siac_d_doc_tipo c,
            siac_r_predoc_subdoc e
    WHERE a.doc_id = b.doc_id AND c.doc_tipo_id = a.doc_tipo_id AND e.subdoc_id
        = b.subdoc_id AND a.data_cancellazione IS NULL AND e.validita_fine IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND e.data_cancellazione IS NULL
    )
    SELECT pred.ente_proprietario_id, pred.predoc_id, pred.predoc_numero,
    pred.predoc_periodo_competenza, pred.predoc_data_competenza,
    pred.predoc_data AS data_esecuzione, pred.predoc_data_trasmissione,
    pred.predoc_importo, pred.predoc_desc AS descrizione,
    pred.predoc_codice_iuv, pred.predoc_note, pred.predoc_stato_code,
    pred.predoc_stato_desc, sac.classif_code AS struttura_code,
    sac.classif_desc AS struttura_desc,
    sac.classif_tipo_code AS struttura_tipo_code,
    cc.classif_code AS conto_corrente_code,
    cc.classif_desc AS conto_corrente_desc,
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
    pred.doc_fam_tipo_code, pred.doc_fam_tipo_desc
    FROM pred
   LEFT JOIN sog ON pred.predoc_id = sog.predoc_id
   LEFT JOIN movgest ON pred.predoc_id = movgest.predoc_id
   LEFT JOIN sac ON pred.predoc_id = sac.predoc_id
   LEFT JOIN cc ON pred.predoc_id = cc.predoc_id
   LEFT JOIN doc ON pred.predoc_id = doc.predoc_id
    ORDER BY pred.ente_proprietario_id, pred.predoc_numero, pred.predoc_data_competenza;
-- SIAC-5313 FINE