/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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
v_anno_int integer; -- SIAC-5487

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
	
v_anno_int := p_anno::integer; -- SIAC-5487

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
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto2.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto2.validita_fine,now())) -- SIAC-5487
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto3
      ON (t_pdce_conto2.pdce_conto_id=t_pdce_conto3.pdce_conto_id_padre
    	  AND t_pdce_conto3.livello=3 and t_pdce_conto3.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto3.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto3.validita_fine,now())) -- SIAC-5487
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto4
      ON (t_pdce_conto3.pdce_conto_id=t_pdce_conto4.pdce_conto_id_padre
    	  AND t_pdce_conto4.livello=4 and t_pdce_conto4.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto4.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto4.validita_fine,now())) -- SIAC-5487
         )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto5
      ON (t_pdce_conto4.pdce_conto_id=t_pdce_conto5.pdce_conto_id_padre
          AND t_pdce_conto5.livello=5 and t_pdce_conto5.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto5.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto5.validita_fine,now())) -- SIAC-5487
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto6
      ON (t_pdce_conto5.pdce_conto_id=t_pdce_conto6.pdce_conto_id_padre
          AND t_pdce_conto6.livello=6 and t_pdce_conto6.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto6.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto6.validita_fine,now())) -- SIAC-5487
          )
 LEFT JOIN siac_t_pdce_conto t_pdce_conto7
      ON (t_pdce_conto6.pdce_conto_id=t_pdce_conto7.pdce_conto_id_padre
          AND t_pdce_conto7.livello=7 and t_pdce_conto7.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto7.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto7.validita_fine,now())) -- SIAC-5487
          )         
 LEFT JOIN siac_t_pdce_conto t_pdce_conto8
      ON (t_pdce_conto7.pdce_conto_id=t_pdce_conto8.pdce_conto_id_padre
          AND t_pdce_conto8.livello=8 and t_pdce_conto8.data_cancellazione is NULL
          AND v_anno_int BETWEEN date_part('year',t_pdce_conto8.validita_inizio) AND date_part('year',COALESCE(t_pdce_conto8.validita_fine,now())) -- SIAC-5487
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
    AND    rpcc.data_cancellazione IS NULL
    AND    v_anno_int BETWEEN date_part('year',rpcc.validita_inizio) AND date_part('year',COALESCE(rpcc.validita_fine,now())); -- SIAC-5487

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