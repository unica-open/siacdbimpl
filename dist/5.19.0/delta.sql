/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- INIZIO task-149.sql



\echo task-149.sql


update siac.siac_d_mutuo_ripartizione_tipo set mutuo_ripartizione_tipo_desc = 'Capitale' where mutuo_ripartizione_tipo_code = '01';
update siac.siac_d_mutuo_ripartizione_tipo set mutuo_ripartizione_tipo_desc = 'Interessi' where mutuo_ripartizione_tipo_code = '02';

ALTER TABLE IF EXISTS siac.siac_r_mutuo_ripartizione DROP CONSTRAINT IF EXISTS siac_d_mutuo_ripartizione_tipo_siac_r_mutuo_ripartizione;
ALTER TABLE siac.siac_r_mutuo_ripartizione 
	ADD CONSTRAINT siac_d_mutuo_ripartizione_tipo_siac_r_mutuo_ripartizione 
	FOREIGN KEY (mutuo_ripartizione_tipo_id) REFERENCES siac.siac_d_mutuo_ripartizione_tipo(mutuo_ripartizione_tipo_id);





-- INIZIO SIAC-8580.sql



\echo SIAC-8580.sql


--SIAC-8580 - Maurizio - INIZIO

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

/* Parametri: 

- p_classificatori: 
	1 = Piano dei conti patrimoniale - Report BILR136;
    2 = Piano dei conti patrimoniale - Report BILR131.
- p_liv_aggiuntivi: S/N.
- p_tipo_stampa: Stampare tutti gli importi:
	1 = No;
    2 = Si.
	

*/ 

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
IF p_classificatori = '1' THEN --BILR136
   sql_query_add := ' AND pdce_fam.pdce_fam_code IN (''CE'',''RE'') ';
   sql_query_add1 := ' AND strutt_pdce.pdce_liv0_code IN (''CE'',''RE'') ';
ELSIF p_classificatori = '2' THEN   --BILR131
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
    
    --SIAC-8580 01/08/2023. Gestione del livello 8.
    IF p_liv_aggiuntivi = 'N' AND p_classificatori <> '1' THEN     
       id_pdce8=0;
       codice_pdce8='';
       descr_pdce8='';          
    ELSE          
    	raise notice 'Livello 8 = %', elenco_prime_note.pdce_liv8_id;
        
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
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR131_saldo_economico_patrimoniale" (p_ente_prop_id integer, p_anno varchar, p_classificatori varchar, p_liv_aggiuntivi varchar, p_tipo_stampa integer)
  OWNER TO siac;
  
--SIAC-8580 - Maurizio - FINE
  




-- INIZIO SIAC-8854.sql



\echo SIAC-8854.sql


--SIAC-8854 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR265_stampa_mandati_reversali_vincoli" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_codice_vincolo varchar
)
RETURNS TABLE (
  vincolo_gen_code varchar,
  vincolo_gen_desc varchar,
  vincolo_code varchar,
  vincolo_desc varchar,
  elem_id integer,
  elem_code varchar,
  elem_code2 varchar,
  elem_desc varchar,
  tipo_capitolo varchar,
  ord_anno integer,
  ord_numero numeric,
  tipo_ordinativo varchar,
  stato_ord_code varchar,
  stato_ord_desc varchar,
  conto_tesoreria varchar,
  conto_tesoreria_pertinenza varchar,
  importo_ordinativo numeric
) AS
$body$
DECLARE
bilancio_id integer;
str_query varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


BEGIN

/*
	29/08/2023.
  Funzione creata per la SIAC-8854 per il report BILR265.
  La funzione estrae mandati e reversali collegati a sottoconti vincolati.

*/

elemTipoCodeE:='CAP-EG';
elemTipoCodeS:='CAP-UG';

select bil.bil_id
	INTO bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id = per.periodo_id
and bil.ente_proprietario_id=p_ente_prop_id
and per.anno=p_anno
and bil.data_cancellazione IS NULL;

raise notice 'elem_id di % = %', p_anno, bilancio_id;


str_query:='select vinc_genere.vincolo_gen_code::varchar vincolo_gen_code, vinc_genere.vincolo_gen_desc::varchar vincolo_gen_desc, 
vinc.vincolo_code::varchar vincolo_code, vinc.vincolo_desc::varchar vincolo_desc,
cap.elem_id::integer elem_id,  cap.elem_code::varchar elem_code, cap.elem_code2::varchar elem_code2, 
cap.elem_desc::varchar elem_desc, 
case when tipo_cap.elem_tipo_code = '''||elemTipoCodeE ||'''
	then''Entrata''::varchar 
    else ''Spesa''::varchar end tipo_capitolo, 
ord.ord_anno::integer ord_anno, ord.ord_numero::numeric ord_numero, ord_tipo.ord_tipo_code::varchar tipo_ordinativo,
ord_stato.ord_stato_code::varchar stato_ord_code, ord_stato.ord_stato_desc::varchar stato_ord_desc, 
COALESCE(contotes.contotes_code,'''')::varchar conto_tesoreria, 
COALESCE(contites_pert.contotes_code,'''')::varchar conto_tesoreria_pertinenza,
ord_ts_det.ord_ts_det_importo::numeric importo_ordinativo 
from siac_t_bil_elem cap,
	siac_r_vincolo_bil_elem r_cap_vincolo,
    siac_t_vincolo vinc,
    siac_d_bil_elem_tipo tipo_cap,
    siac_r_vincolo_genere r_vinc_genere,
    siac_d_vincolo_genere vinc_genere,
    siac_r_ordinativo_bil_elem r_ord_cap,
    siac_t_ordinativo ord
    	left join siac_d_contotesoreria contotes
        	on contotes.contotes_id=ord.contotes_id and contotes.data_cancellazione IS NULL
        left join (select r_ord_conto_des_pert.ord_id, contotes_pert.contotes_id, 
        				contotes_pert.contotes_code, contotes_pert.contotes_desc
        			from siac_r_ordinativo_contotes_nodisp r_ord_conto_des_pert,
                    	siac_d_contotesoreria contotes_pert
                    where r_ord_conto_des_pert.contotes_id=contotes_pert.contotes_id
                    	and r_ord_conto_des_pert.data_cancellazione IS NULL) contites_pert
            on contites_pert.ord_id=ord.ord_id,
    siac_d_ordinativo_tipo ord_tipo,
    siac_r_ordinativo_stato r_ord_stato,
    siac_d_ordinativo_stato ord_stato,
    siac_t_ordinativo_ts ord_ts,
    siac_t_ordinativo_ts_det ord_ts_det,
    siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo
where cap.elem_id=   r_cap_vincolo.elem_id
    and r_cap_vincolo.vincolo_id=vinc.vincolo_id
    and tipo_cap.elem_tipo_id=cap.elem_tipo_id
    and r_vinc_genere.vincolo_id=vinc.vincolo_id
    and r_vinc_genere.vincolo_gen_id=vinc_genere.vincolo_gen_id
    and r_ord_cap.elem_id=cap.elem_id
    and r_ord_cap.ord_id=ord.ord_id
    and ord_tipo.ord_tipo_id=ord.ord_tipo_id
    and r_ord_stato.ord_id=ord.ord_id
    and r_ord_stato.ord_stato_id=ord_stato.ord_stato_id
    and ord_ts.ord_id=ord.ord_id
    and ord_ts_det.ord_ts_id=ord_ts.ord_ts_id
    and d_ord_ts_det_tipo.ord_ts_det_tipo_id=ord_ts_det.ord_ts_det_tipo_id
    and r_cap_vincolo.ente_proprietario_id='||p_ente_prop_id||'
    and cap.bil_id='||bilancio_id ||'
    and tipo_cap.elem_tipo_code in ('''||elemTipoCodeE||''', '''||elemTipoCodeS||''')
    and ord_stato.ord_stato_code <> ''A'' --escludo gli annullati
    and d_ord_ts_det_tipo.ord_ts_det_tipo_code=''A'' --Importo Attuale';
    if trim(COALESCE(p_codice_vincolo,'')) <> '' then
    	str_query:=str_query||' 
        and upper(vinc.vincolo_code) like ''%'||upper(trim(p_codice_vincolo))||'%'' ';
    end if;
    
    str_query:=str_query||'
    and r_cap_vincolo.data_cancellazione IS NULL
    and r_vinc_genere.data_cancellazione IS NULL
    and r_ord_cap.data_cancellazione IS NULL
    and r_ord_stato.data_cancellazione IS NULL
    and r_ord_stato.validita_fine IS NULL
    and ord.data_cancellazione IS NULL
    and ord_ts.data_cancellazione IS NULL
    and ord_ts_det.data_cancellazione IS NULL
ORDER BY vincolo_code, tipo_capitolo, elem_code, elem_code2, ord_anno, ord_numero, stato_ord_code,
	    conto_tesoreria, conto_tesoreria_pertinenza';
        
raise notice 'Query: %', str_query;
        
return query execute str_query;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='altro errore generico';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR265_stampa_mandati_reversali_vincoli" (p_ente_prop_id integer, p_anno varchar, p_codice_vincolo varchar)
  OWNER TO siac;
  
--SIAC-8854 - Maurizio - fine
  




-- INIZIO task-153.sql



\echo task-153.sql


--siac-task issues #153 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR116_Stampa_riepilogo_iva" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_mese varchar
)
RETURNS TABLE (
  bil_anno varchar,
  desc_ente varchar,
  data_registrazione date,
  cod_fisc_ente varchar,
  desc_periodo varchar,
  cod_tipo_registro varchar,
  desc_tipo_registro varchar,
  cod_registro varchar,
  desc_registro varchar,
  cod_aliquota_iva varchar,
  desc_aliquota_iva varchar,
  importo_iva_imponibile numeric,
  importo_iva_imposta numeric,
  importo_iva_totale numeric,
  tipo_reg_completa varchar,
  cod_reg_completa varchar,
  aliquota_completa varchar,
  tipo_registro varchar,
  data_emissione date,
  data_prot_def date,
  importo_iva_detraibile numeric,
  importo_iva_indetraibile numeric,
  importo_esente numeric,
  importo_split numeric,
  importo_fuori_campo numeric,
  percent_indetr numeric,
  pro_rata numeric,
  aliquota_perc numeric,
  importo_iva_split numeric,
  importo_detraibile numeric,
  importo_indetraibile numeric
) AS
$body$
DECLARE
classifBilRec record;
elencoRegistriIva record;

mese1 varchar;
anno1 varchar;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
ricorrente varchar;
v_id_doc integer;
v_tipo_doc varchar;

BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;   

TipoImpstanzresidui='SRI'; -- stanziamento residuo iniziale (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
desc_ente='';
data_registrazione=NULL;
cod_fisc_ente='';
desc_periodo='';
cod_tipo_registro='';
desc_tipo_registro='';
cod_registro='';
desc_registro='';
cod_aliquota_iva='';
desc_aliquota_iva='';
importo_iva_imponibile=0;
importo_iva_imposta=0;
importo_iva_totale=0;
tipo_reg_completa='';
cod_reg_completa='';
aliquota_completa='';
tipo_registro='';
data_emissione=NULL;
data_prot_def=NULL;
importo_iva_detraibile=0;
importo_iva_indetraibile=0;
importo_esente=0;
importo_split=0;
importo_fuori_campo=0;
importo_iva_split=0;
percent_indetr=0;
pro_rata=0;
aliquota_perc=0;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;

if p_mese = '12' THEN
	mese1='01';
    anno1=(p_anno ::integer +1) ::varchar;
else 
	mese1=(p_mese ::integer +1) ::varchar;
    anno1=p_anno;
end if;
raise notice 'mese = %, anno = %', mese1,anno1;
raise notice 'DATA A = %', to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy');
--raise notice 'DATA A meno uno = %', to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')-1;
 
RTN_MESSAGGIO:='Estrazione dei dati Registri IVA ''.';

/*
	24/08/2023: Procedura modificata per siac-task issues #153.
    L'estrazione principale e' stata spezzata in 2 parti, una per i documenti di Entrata e l'altra per quelli di Spesa.
    Per le entrate la ricerca oltre che per la data operazione (subdociva_data_prot_def) deve essere effettuata anche
    per la data fattura (doc_data_emissione); entrambe devono rientrare nel mese scelto dall'utente.
    Per le spese la ricerca deve avvenire per la data di quietanza.
*/

FOR elencoRegistriIva IN   
	--collegati a quote documento - ENTRATA   
  select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
  from siac_t_iva_registro t_reg_iva,
          siac_d_iva_registro_tipo d_iva_reg_tipo,
          siac_t_subdoc_iva t_subdoc_iva,
          siac_r_ivamov r_ivamov,
          siac_t_ivamov t_ivamov,
          siac_t_iva_aliquota t_iva_aliquota,
          siac_t_ente_proprietario ente_prop,
          siac_d_iva_operazione_tipo tipo_oper,
          siac_t_iva_gruppo iva_gruppo,
          siac_r_iva_registro_gruppo riva_gruppo,
          siac_r_iva_gruppo_prorata rprorata,
          siac_t_iva_prorata prorata,
          siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts,
          siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo
  where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
          AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
          AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
          AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
          AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
          AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
          AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
          AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
          AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
          AND rprorata.ivagru_id = iva_gruppo.ivagru_id
          AND prorata.ivapro_id=rprorata.ivapro_id
                  --- AGGIUNTO DA QUI
          AND    rssi.subdociva_id = t_subdoc_iva.subdociva_id
          AND    td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
          AND    rssi.subdoc_id = ts.subdoc_id
          AND    ts.doc_id = td.doc_id
          and td.doc_tipo_id=doc_tipo.doc_tipo_id
          and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id
          AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
          AND rprorata.ivagrupro_anno = p_anno::integer
          and doc_fam_tipo.doc_fam_tipo_code ='E' --documenti di entrata
         --AND t_subdoc_iva.subdociva_data_prot_def between  
        -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --aggiunto anche il test sulla data di emissione della fattura.
         AND ((t_subdoc_iva.subdociva_data_prot_def >=  
       		 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
            t_subdoc_iva.subdociva_data_prot_def < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  OR
        	(td.doc_data_emissione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_emissione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))) 
         --03/07/2018 SIAC-6275: occorre escludere i registri IVA
         -- con ivareg_flagliquidazioneiva = false
          AND t_reg_iva.ivareg_flagliquidazioneiva = true
          AND t_reg_iva.data_cancellazione IS NULL
          AND d_iva_reg_tipo.data_cancellazione IS NULL    
          AND t_subdoc_iva.data_cancellazione IS NULL 
          AND r_ivamov.data_cancellazione IS NULL
          AND t_ivamov.data_cancellazione IS NULL
          AND riva_gruppo.data_cancellazione is NULL
          AND t_iva_aliquota.data_cancellazione IS NULL
          AND rprorata.data_cancellazione is null
          AND    rssi.data_cancellazione IS NULL
          AND    ts.data_cancellazione IS NULL
          AND    td.data_cancellazione IS NULL
          --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
          --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
          --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
          --AND    t_subdoc_iva.dociva_r_id IS NULL
          /*AND not exists 
          (select 1 from siac_r_doc_iva b
              where b.doc_id = td.doc_id 
              and b.data_cancellazione is null )   */
  /*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
              t_iva_aliquota.ivaaliquota_code   */       
UNION
	--collegati al documento - ENTRATA
select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
from siac_t_iva_registro t_reg_iva,
		siac_d_iva_registro_tipo d_iva_reg_tipo,
        siac_t_subdoc_iva t_subdoc_iva,
        siac_r_ivamov r_ivamov,
        siac_t_ivamov t_ivamov,
        siac_t_iva_aliquota t_iva_aliquota,
        siac_t_ente_proprietario ente_prop,
        siac_d_iva_operazione_tipo tipo_oper,
        siac_t_iva_gruppo iva_gruppo,
        siac_r_iva_registro_gruppo riva_gruppo,
        siac_r_iva_gruppo_prorata rprorata,
        siac_t_iva_prorata prorata,
        siac_r_doc_iva rdi, siac_t_doc td,
        siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo
where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
		AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
        AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
        AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
        AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
        AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
        AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
        AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
        AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
        AND rprorata.ivagru_id = iva_gruppo.ivagru_id
        AND prorata.ivapro_id=rprorata.ivapro_id
                ---- DA QUI
        AND rdi.dociva_r_id = t_subdoc_iva.dociva_r_id
        AND td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
        AND rdi.doc_id = td.doc_id
        and td.doc_tipo_id=doc_tipo.doc_tipo_id
        and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id	
        AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
        AND rprorata.ivagrupro_anno = p_anno::integer
       --AND t_subdoc_iva.subdociva_data_prot_def between  
      -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
      --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
      	--24/08/2023: siac-task issues #153:
        --aggiunto anche il test sulla data di emissione della fattura.
       AND ((t_subdoc_iva.subdociva_data_prot_def >=  
       		 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
            t_subdoc_iva.subdociva_data_prot_def < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  OR
        	(td.doc_data_emissione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_emissione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')))
       --03/07/2018 SIAC-6275: occorre escludere i registri IVA
       -- con ivareg_flagliquidazioneiva = false
        AND t_reg_iva.ivareg_flagliquidazioneiva = true
        and doc_fam_tipo.doc_fam_tipo_code ='E' --documenti di entrata
        AND t_reg_iva.data_cancellazione IS NULL
        AND d_iva_reg_tipo.data_cancellazione IS NULL    
        AND t_subdoc_iva.data_cancellazione IS NULL 
        AND r_ivamov.data_cancellazione IS NULL
        AND t_ivamov.data_cancellazione IS NULL
        AND riva_gruppo.data_cancellazione is NULL
        AND t_iva_aliquota.data_cancellazione IS NULL
        AND rprorata.data_cancellazione is null
        AND    rdi.data_cancellazione IS NULL
        AND    td.data_cancellazione IS NULL
        --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
        --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
        --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
        AND    t_subdoc_iva.dociva_r_id  IS NOT NULL
        and not exists (select 1 from siac_r_subdoc_subdoc_iva x
   			 where x.data_cancellazione is null and x.validita_fine is null 
             --and x.subdociva_id = t_subdoc_iva.subdociva_id
             and exists   (
             select y.subdoc_id from siac_t_subdoc y
             where y.doc_id=td.doc_id
             and x.subdoc_id = y.subdoc_id
             and y.data_cancellazione is null
  		) )
UNION        
	--collegati a quote documento - SPESA   
  select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
  from siac_t_iva_registro t_reg_iva,
          siac_d_iva_registro_tipo d_iva_reg_tipo,
          siac_t_subdoc_iva t_subdoc_iva,
          siac_r_ivamov r_ivamov,
          siac_t_ivamov t_ivamov,
          siac_t_iva_aliquota t_iva_aliquota,
          siac_t_ente_proprietario ente_prop,
          siac_d_iva_operazione_tipo tipo_oper,
          siac_t_iva_gruppo iva_gruppo,
          siac_r_iva_registro_gruppo riva_gruppo,
          siac_r_iva_gruppo_prorata rprorata,
          siac_t_iva_prorata prorata,
          siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts,
          siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo,
          siac_r_subdoc_ordinativo_ts r_sub_ord_ts, 
          siac_t_ordinativo ord, siac_t_ordinativo_ts ord_ts, siac_t_ordinativo_ts_det ord_ts_det,
          siac_d_ordinativo_ts_det_tipo ord_ts_det_tipo, siac_r_ordinativo_stato r_ord_stato,
          siac_d_ordinativo_stato ord_stato 
  where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
          AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
          AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
          AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
          AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
          AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
          AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
          AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
          AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
          AND rprorata.ivagru_id = iva_gruppo.ivagru_id
          AND prorata.ivapro_id=rprorata.ivapro_id
                  --- AGGIUNTO DA QUI
          AND    rssi.subdociva_id = t_subdoc_iva.subdociva_id
          AND    td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
          AND    rssi.subdoc_id = ts.subdoc_id
          AND    ts.doc_id = td.doc_id
          and td.doc_tipo_id=doc_tipo.doc_tipo_id
          and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id
          and r_sub_ord_ts.subdoc_id=ts.subdoc_id
          and ts.doc_id=td.doc_id
          and ord_ts.ord_ts_id=r_sub_ord_ts.ord_ts_id
          and ord_ts.ord_id=ord.ord_id
          and ord_ts_det.ord_ts_id=ord_ts.ord_ts_id
          and ord_ts_det_tipo.ord_ts_det_tipo_id=ord_ts_det.ord_ts_det_tipo_id
          and r_ord_stato.ord_id=ord.ord_id
          and r_ord_stato.ord_stato_id=ord_stato.ord_stato_id
          AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
          AND rprorata.ivagrupro_anno = p_anno::integer
          and doc_fam_tipo.doc_fam_tipo_code ='S' --documenti di spesa
         --AND t_subdoc_iva.subdociva_data_prot_def between  
        -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --Cambiato il test: non subdociva_data_prot_def ma la data di quietanza che è quella in cui e' stato inserito lo stato
        --quietanziato.
        /* AND (t_subdoc_iva.subdociva_data_prot_def >=  
          to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
          t_subdoc_iva.subdociva_data_prot_def <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  */         
         AND (r_ord_stato.validita_inizio >=  
       	 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
         r_ord_stato.validita_inizio <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))
         --24/08/2023: siac-task issues #153:
         --solo quelli Quietanziati
         and ord_stato.ord_stato_code = 'Q'
         --03/07/2018 SIAC-6275: occorre escludere i registri IVA
         -- con ivareg_flagliquidazioneiva = false
          AND t_reg_iva.ivareg_flagliquidazioneiva = true
          AND t_reg_iva.data_cancellazione IS NULL
          AND d_iva_reg_tipo.data_cancellazione IS NULL    
          AND t_subdoc_iva.data_cancellazione IS NULL 
          AND r_ivamov.data_cancellazione IS NULL
          AND t_ivamov.data_cancellazione IS NULL
          AND riva_gruppo.data_cancellazione is NULL
          AND t_iva_aliquota.data_cancellazione IS NULL
          AND rprorata.data_cancellazione is null
          AND    rssi.data_cancellazione IS NULL
          AND    ts.data_cancellazione IS NULL
          AND    td.data_cancellazione IS NULL
          --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
          --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
          --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
          --AND    t_subdoc_iva.dociva_r_id IS NULL
          /*AND not exists 
          (select 1 from siac_r_doc_iva b
              where b.doc_id = td.doc_id 
              and b.data_cancellazione is null )   */
  /*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
              t_iva_aliquota.ivaaliquota_code   */       
UNION
	--collegati al documento - SPESA
select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
from siac_t_iva_registro t_reg_iva,
		siac_d_iva_registro_tipo d_iva_reg_tipo,
        siac_t_subdoc_iva t_subdoc_iva,
        siac_r_ivamov r_ivamov,
        siac_t_ivamov t_ivamov,
        siac_t_iva_aliquota t_iva_aliquota,
        siac_t_ente_proprietario ente_prop,
        siac_d_iva_operazione_tipo tipo_oper,
        siac_t_iva_gruppo iva_gruppo,
        siac_r_iva_registro_gruppo riva_gruppo,
        siac_r_iva_gruppo_prorata rprorata,
        siac_t_iva_prorata prorata,
        siac_r_doc_iva rdi, siac_t_doc td,
        siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_sub_ord_ts, siac_t_subdoc subdoc,
        siac_t_ordinativo ord, siac_t_ordinativo_ts ord_ts, siac_t_ordinativo_ts_det ord_ts_det,
        siac_d_ordinativo_ts_det_tipo ord_ts_det_tipo, siac_r_ordinativo_stato r_ord_stato,
        siac_d_ordinativo_stato ord_stato 
where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
		AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
        AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
        AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
        AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
        AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
        AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
        AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
        AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
        AND rprorata.ivagru_id = iva_gruppo.ivagru_id
        AND prorata.ivapro_id=rprorata.ivapro_id
                ---- DA QUI
        AND rdi.dociva_r_id = t_subdoc_iva.dociva_r_id
        AND td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
        AND rdi.doc_id = td.doc_id
        and td.doc_tipo_id=doc_tipo.doc_tipo_id
        and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id	
        and r_sub_ord_ts.subdoc_id=subdoc.subdoc_id
        and subdoc.doc_id=td.doc_id
        and ord_ts.ord_ts_id=r_sub_ord_ts.ord_ts_id
        and ord_ts.ord_id=ord.ord_id
        and ord_ts_det.ord_ts_id=ord_ts.ord_ts_id
        and ord_ts_det_tipo.ord_ts_det_tipo_id=ord_ts_det.ord_ts_det_tipo_id
        and r_ord_stato.ord_id=ord.ord_id
        and r_ord_stato.ord_stato_id=ord_stato.ord_stato_id
        AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
        AND rprorata.ivagrupro_anno = p_anno::integer
       --AND t_subdoc_iva.subdociva_data_prot_def between  
      -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
      --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --Cambiato il test: non subdociva_data_prot_def ma la data di quietanza che è quella in cui e' stato inserito lo stato
        --quietanziato.
    /*   AND (t_subdoc_iva.subdociva_data_prot_def >=  
       	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        t_subdoc_iva.subdociva_data_prot_def <  
       to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  */
        AND (r_ord_stato.validita_inizio >=  
       	 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
         r_ord_stato.validita_inizio <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  
         --24/08/2023: siac-task issues #153:
         --solo quelli Quietanziati
       and ord_stato.ord_stato_code = 'Q'
       --03/07/2018 SIAC-6275: occorre escludere i registri IVA
       -- con ivareg_flagliquidazioneiva = false
        AND t_reg_iva.ivareg_flagliquidazioneiva = true
        and doc_fam_tipo.doc_fam_tipo_code ='S' --documenti di spesa
        AND t_reg_iva.data_cancellazione IS NULL
        AND d_iva_reg_tipo.data_cancellazione IS NULL    
        AND t_subdoc_iva.data_cancellazione IS NULL 
        AND r_ivamov.data_cancellazione IS NULL
        AND t_ivamov.data_cancellazione IS NULL
        AND riva_gruppo.data_cancellazione is NULL
        AND t_iva_aliquota.data_cancellazione IS NULL
        AND rprorata.data_cancellazione is null
        AND    rdi.data_cancellazione IS NULL
        AND    td.data_cancellazione IS NULL
        --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
        --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
        --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
        AND    t_subdoc_iva.dociva_r_id  IS NOT NULL
        and subdoc.data_cancellazione IS NULL
        and r_sub_ord_ts.data_cancellazione IS NULL
        and ord.data_cancellazione IS NULL
        and ord_ts.data_cancellazione IS NULL
        and r_ord_stato.data_cancellazione IS NULL
        and r_ord_stato.validita_fine IS NULL
        and not exists (select 1 from siac_r_subdoc_subdoc_iva x
   			 where x.data_cancellazione is null and x.validita_fine is null 
             --and x.subdociva_id = t_subdoc_iva.subdociva_id
             and exists   (
             select y.subdoc_id from siac_t_subdoc y
             where y.doc_id=td.doc_id
             and x.subdoc_id = y.subdoc_id
             and y.data_cancellazione is null
  		) )        
/*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
			t_iva_aliquota.ivaaliquota_code     */     
loop

--COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))

select x.* 
into v_id_doc , v_tipo_doc  from (
  SELECT distinct td.doc_id, tipo.doc_tipo_code
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts, siac_d_doc_tipo tipo
  WHERE  rssi.subdociva_id = elencoRegistriIva.subdociva_id
  AND    td.ente_proprietario_id = p_ente_prop_id
  AND    rssi.subdoc_id = ts.subdoc_id
  AND    ts.doc_id = td.doc_id
  AND	 tipo.doc_tipo_id= td.doc_tipo_id
  AND    rssi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
  --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    elencoRegistriIva.dociva_r_id IS NULL
  UNION 
  SELECT distinct td.doc_id,  tipo.doc_tipo_code
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_doc_iva rdi, siac_t_doc td, siac_t_subdoc ts, siac_d_doc_tipo tipo
  WHERE  rdi.dociva_r_id = elencoRegistriIva.dociva_r_id 
  AND    td.ente_proprietario_id = p_ente_prop_id
  AND    rdi.doc_id = td.doc_id
  AND    ts.doc_id = td.doc_id
  AND	 tipo.doc_tipo_id= td.doc_tipo_id
  AND    rdi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
  --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    elencoRegistriIva.dociva_r_id  IS NOT NULL
  ) x;

raise notice 'v_id_doc - v_tipo_doc % - %', v_id_doc , v_tipo_doc ; 



bil_anno='';
desc_ente=elencoRegistriIva.ente_denominazione;
data_registrazione=elencoRegistriIva.subdociva_data_emissione;
cod_fisc_ente=elencoRegistriIva.codice_fiscale;
desc_periodo='';
cod_tipo_registro=elencoRegistriIva.ivareg_tipo_code;
desc_tipo_registro=elencoRegistriIva.ivareg_tipo_desc;
cod_registro=elencoRegistriIva.ivareg_code;
desc_registro=elencoRegistriIva.ivareg_desc;
cod_aliquota_iva=elencoRegistriIva.ivaaliquota_code;
desc_aliquota_iva=elencoRegistriIva.ivaaliquota_desc;
importo_iva_imponibile=elencoRegistriIva.ivamov_imponibile;
importo_iva_imposta=elencoRegistriIva.ivamov_imposta;
importo_iva_totale=elencoRegistriIva.ivamov_totale;

tipo_reg_completa=desc_tipo_registro;
cod_reg_completa=desc_registro;
aliquota_completa= desc_aliquota_iva;
data_emissione=elencoRegistriIva.data_emissione;
data_prot_def=elencoRegistriIva.data_prot_def; 


-- CI = CORRISPETTIVI
-- VI = VENDITE IVA IMMEDIATA
-- VD = VENDITE IVA DIFFERITA
-- AI = ACQUISTI IVA IMMEDIATA
-- AD = ACQUISTI IVA DIFFERITA
if cod_tipo_registro = 'CI' OR cod_tipo_registro = 'VI' OR cod_tipo_registro = 'VD' THEN
	tipo_registro='V'; --VENDITE
ELSE
	tipo_registro='A'; --ACQUISTI
END IF;



if v_tipo_doc in ('NCD', 'NCV') and elencoRegistriIva.ivamov_imponibile > 0 
then 
   	importo_iva_imponibile= importo_iva_imponibile*-1;
	importo_iva_imposta=importo_iva_imposta*-1;
	importo_iva_totale=importo_iva_totale*-1;
end if;
       

importo_iva_indetraibile=round((coalesce(importo_iva_imposta,0)/100)*coalesce(elencoRegistriIva.ivaaliquota_perc_indetr,0),2);
importo_iva_detraibile=coalesce(importo_iva_imposta,0) - importo_iva_indetraibile;

importo_indetraibile=round((coalesce(importo_iva_imponibile,0)/100)*coalesce(elencoRegistriIva.ivaaliquota_perc_indetr,0),2);
importo_detraibile=coalesce(importo_iva_imponibile,0) - importo_indetraibile;

importo_esente=0;

if elencoRegistriIva.ivaop_tipo_code = 'ES' then
	importo_esente=importo_iva_imponibile;
end if;

importo_fuori_campo=0;

if elencoRegistriIva.ivaop_tipo_code = 'FCI' then
	importo_fuori_campo=importo_iva_imponibile;
end if;

importo_split=0;
if elencoRegistriIva.ivaaliquota_split = true then
	importo_split=importo_detraibile;
    importo_iva_split=importo_iva_detraibile;
end if;



percent_indetr= elencoRegistriIva.ivaaliquota_perc_indetr;
pro_rata=elencoRegistriIva.ivapro_perc;
aliquota_perc=elencoRegistriIva.ivaaliquota_perc;


return next;

bil_anno='';
desc_ente='';
data_registrazione=NULL;
cod_fisc_ente='';
desc_periodo='';
cod_tipo_registro='';
desc_tipo_registro='';
cod_registro='';
desc_registro='';
cod_aliquota_iva='';
desc_aliquota_iva='';
importo_iva_imponibile=0;
importo_iva_imposta=0;
importo_iva_totale=0;
tipo_reg_completa='';
cod_reg_completa='';
aliquota_completa='';
tipo_registro='';
data_emissione=NULL;
data_prot_def=NULL;
importo_iva_detraibile=0;
importo_iva_indetraibile=0;
importo_esente=0;
importo_split=0;
importo_iva_split=0;
importo_fuori_campo=0;
percent_indetr=0;
pro_rata=0;
aliquota_perc=0;
end loop;




raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato per i registri IVA' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR116_Stampa_riepilogo_iva" (p_ente_prop_id integer, p_anno varchar, p_mese varchar)
  OWNER TO siac;


--siac-task issues #153 - Maurizio - FINE





-- INIZIO task-156.sql



\echo task-156.sql


/*
*Paolo Simone
*/
UPDATE siac_t_soggetto SET istituto_di_credito = FALSE WHERE istituto_di_credito IS NULL;
ALTER TABLE siac.siac_t_soggetto ALTER COLUMN istituto_di_credito SET NOT NULL;




-- INIZIO task-174.sql



\echo task-174.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_siac_gsa_ordinativo
(
  p_anno_bilancio varchar,
  p_tipo_ord           varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_gsa_ordinativo
(p_anno_bilancio varchar, 
 p_tipo_ord           varchar,
 p_ente_proprietario_id integer, 
 p_data timestamp without time zone)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
v_user_table varchar;
params varchar;
p_bilancio_id integer:=null;


annoBilancio integer;
annoBilancio_ini integer;
codResult integer:=null;
annoRec record;

ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

BEGIN


select fnc_siac_random_user()
into	v_user_table;


IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;


if p_tipo_ord is not null and   p_tipo_ord not in ('I','P','E') then 
	RAISE EXCEPTION 'Errore: Parametro Tipo Ordinativo non valido [I,P]';
    RETURN;
 else 
     if p_tipo_ord is null then p_tipo_ord:='E';  
     end if;
 end if;

IF p_data IS NULL THEN
   p_data := now();
END IF;

if p_anno_bilancio is null then 
    annoBilancio:=extract('YEAR' from now())::integer;
else 
    annoBilancio:=p_anno_bilancio::integer;
end if;
annoBilancio_ini:=annoBilancio;


 params := annoBilancio::varchar||' - '||p_tipo_ord||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;

 esito:= 'Inizio funzione carico ordinativi  GSA (fnc_siac_gsa_ordinativo) - '||clock_timestamp(); 
 RETURN NEXT;
 insert into
 siac_gsa_ordinativi_log_elab 
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
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 ); 

 esito:='Parametri='||params; 
 RETURN next;
 insert into
 siac_gsa_ordinativi_log_elab 
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
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 );

esito:= '  Inizio eliminazione dati pregressi into siac_gsa_ordinativo - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
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
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

DELETE FROM siac.siac_gsa_ordinativo
WHERE ente_proprietario_id = p_ente_proprietario_id;

esito:= '  Fine eliminazione dati pregressi into siac_gsa_ordinativo - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
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
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

 esito:='  Verifica fase bilancio annoBilancio-1='||(annoBilancio-1)::varchar||'.';
 -- Aggiungere parametro per non estrarre anno-1
 select 1 into codResult
 from siac_t_bil bil,siac_t_periodo per,
	       siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
 where per.ente_proprietario_id=p_ente_proprietario_id  
 and     per.anno::integer=annoBilancio-1
 and     bil.periodo_id=per.periodo_id
 and     r.bil_id=bil.bil_id 
 and     fase.fase_operativa_id=r.fase_operativa_id
 and     fase.fase_operativa_code in (ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
 if codResult is not null then
        codResult:=null;
        select 1 into codResult
        from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
        where tipo.ente_proprietario_id=p_ente_proprietario_id
        and      tipo.gestione_tipo_code='SCARICO_GSA_ORD_ANNO_PREC'  
        and      liv.gestione_tipo_id=tipo.gestione_tipo_id
        and      liv.gestione_livello_code=(annoBilancio-1)::varchar
        and      tipo.data_cancellazione is null 
        and      tipo.validita_fine is null 
        and      liv.data_cancellazione is null 
        and      liv.validita_fine is null;
		if codResult is not null then
			    	annoBilancio_ini:=annoBilancio-1;
	    end if;  
 end if;	   
 if   codResult is not null then
	           esito:=esito||'  Carico ordinativi GSA annoBilancio='||annoBilancio_ini::varchar||' e annoBilancio='||annoBilancio::varchar||'.';
 else       esito:=esito||'  Carico ordinativi GSA annoBilancio='||annoBilancio::varchar||'.';
 end if;
 RETURN next;

 insert into
 siac_gsa_ordinativi_log_elab 
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
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 );  


 esito:='  Carico ordinativi GSA annoBilancio='||annoBilancio_ini::varchar||' e annoBilancio='||annoBilancio::varchar||'. Prima di inizio ciclo.';
 RETURN next;
 for annoRec in
 (
    select *
    from
   	(select annoBilancio_ini anno_elab
     union
     select annoBilancio anno_elab
    ) query
    order by 1
)
loop
    esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo.';
    RETURN next;
   
    if p_tipo_ord in ('I','E') then 
   	 -- scarico ordinativi di incasso
     esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo per incassi.';
     RETURN next;
     return query  select fnc_siac_gsa_ordinativo_incasso (annoRec.anno_elab::varchar,p_ente_proprietario_id, p_data);
     
     esito:= '  Inizio caricamento incassi into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
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
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;	
     insert into siac_gsa_ordinativo 
     (
	     ente_proprietario_id,
   	     anno_bilancio,
   	     ord_tipo,
	     ord_anno,
		 ord_numero,
		 ord_desc,
		 ord_stato_code,
	 	 ord_data_emissione,
		 ord_data_firma,
		 ord_data_quietanza,
		 ord_data_annullo,
   	 	 numero_capitolo,
    	 numero_articolo,
      	 capitolo_desc,
    	 soggetto_code,
    	 soggetto_desc,
		 pdc_fin_liv_1,
		 pdc_fin_liv_2,
		 pdc_fin_liv_3,
		 pdc_fin_liv_4,
		 pdc_fin_liv_5,
	 	 ord_sub_numero, 
	 	 ord_sub_importo,
	  	 ord_sub_desc,
	     movgest_anno,
	     movgest_numero,
	     movgest_sub_numero,
	     movgest_gsa,
	     movgest_attoamm_tipo_code,
	     movgest_attoamm_anno,
	     movgest_attoamm_numero,
	     movgest_attoamm_sac,
	     liq_attoamm_tipo_code,
	     liq_attoamm_anno,
	     liq_attoamm_numero,
	     liq_attoamm_sac
     )
     select 
         inc.ente_proprietario_id,
   	     inc.anno_bilancio,
   	     'E',
	     inc.ord_anno,
		 inc.ord_numero,
		 inc.ord_desc,
		 inc.ord_stato_code,
	 	 to_char(inc.ord_data_emissione,'YYYYMMDD'),
		 to_char(inc.ord_data_firma,'YYYYMMDD'),
		 to_char(inc.ord_data_quietanza,'YYYYMMDD'),
		 to_char(inc.ord_data_annullo,'YYYYMMDD'),
   	 	 inc.numero_capitolo,
    	 inc.numero_articolo,
      	 inc.capitolo_desc,
    	 inc.soggetto_code,
    	 inc.soggetto_desc,
		 inc.pdc_fin_liv_1,
 		 inc.pdc_fin_liv_2,
		 inc.pdc_fin_liv_3,
 		 inc.pdc_fin_liv_4,
 		 inc.pdc_fin_liv_5,
	 	 inc.ord_sub_numero, 
	 	 inc.ord_sub_importo,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	  	 --inc.ord_sub_desc,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	 	 --replace(replace(substring( inc.ord_desc,1,255),chr(10),''),chr(13),''),
translate
( 
substring( inc.ord_desc,1,255),
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar||
chr(59)::varchar, -- 06.09.2023 Sofia SIAC-TASK-174 ;  con , 
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(44)::varchar), -- 06.09.2023 Sofia SIAC-TASK-174 ;  con ,
	     inc.movgest_anno,
	     inc.movgest_numero,
	     inc.movgest_sub_numero,
	     inc.movgest_gsa,
	     inc.movgest_attoamm_tipo_code,
	     inc.movgest_attoamm_anno,
	     inc.movgest_attoamm_numero,
	     inc.movgest_attoamm_sac,
	     inc.ord_attoamm_tipo_code,
	     inc.ord_attoamm_anno,
	     inc.ord_attoamm_numero,
	     inc.ord_attoamm_sac
     from siac_gsa_ordinativo_incasso inc 
     where inc.anno_bilancio =annoRec.anno_elab
     and     inc.ente_proprietario_id =p_ente_proprietario_id ;
     
     esito:= '  Fine caricamento incassi into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
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
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;	
    end if;
    if p_tipo_ord in ('P','E') then 
      	-- scarico ordinativi di pagamento
     esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo per pagamenti.';
     RETURN next;
     return query select fnc_siac_gsa_ordinativo_pagamento (annoRec.anno_elab::varchar,p_ente_proprietario_id, p_data);
     
    esito:= '  Inizio caricamento pagamenti into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
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
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;
     insert into siac_gsa_ordinativo 
     (
	     ente_proprietario_id,
   	     anno_bilancio,
   	     ord_tipo,
	     ord_anno,
		 ord_numero,
		 ord_desc,
		 ord_stato_code,
	 	 ord_data_emissione,
		 ord_data_firma,
		 ord_data_quietanza,
		 ord_data_annullo,
   	 	 numero_capitolo,
    	 numero_articolo,
      	 capitolo_desc,
    	 soggetto_code,
    	 soggetto_desc,
		 pdc_fin_liv_1,
		 pdc_fin_liv_2,
		 pdc_fin_liv_3,
		 pdc_fin_liv_4,
		 pdc_fin_liv_5,
	 	 ord_sub_numero, 
	 	 ord_sub_importo,
	  	 ord_sub_desc,
	     movgest_anno,
	     movgest_numero,
	     movgest_sub_numero,
	     movgest_gsa,
	     movgest_attoamm_tipo_code,
	     movgest_attoamm_anno,
	     movgest_attoamm_numero,
	     movgest_attoamm_sac,
	     liq_anno,
	     liq_numero,
	     liq_attoamm_tipo_code,
	     liq_attoamm_anno,
	     liq_attoamm_numero,
	     liq_attoamm_sac
     )
     select 
         pag.ente_proprietario_id,
   	     pag.anno_bilancio,
   	     'U',
	     pag.ord_anno,
		 pag.ord_numero,
		 pag.ord_desc,
		 pag.ord_stato_code,
	 	 to_char(pag.ord_data_emissione,'YYYYMMDD'),
		 to_char(pag.ord_data_firma,'YYYYMMDD'),
		 to_char(pag.ord_data_quietanza,'YYYYMMDD'),
		 to_char(pag.ord_data_annullo,'YYYYMMDD'),
   	 	 pag.numero_capitolo,
    	 pag.numero_articolo,
      	 pag.capitolo_desc,
    	 pag.soggetto_code,
    	 pag.soggetto_desc,
		 pag.pdc_fin_liv_1,
		 pag.pdc_fin_liv_2,
		 pag.pdc_fin_liv_3,
		 pag.pdc_fin_liv_4,
		 pag.pdc_fin_liv_5,
	 	 pag.ord_sub_numero, 
	 	 pag.ord_sub_importo,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	  	 -- pag.ord_sub_desc,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
--	 	 replace(replace(substring( pag.ord_desc,1,255),chr(10),''),chr(13),''),
translate
( 
substring( pag.ord_desc,1,255),
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar),	 	 
	     pag.movgest_anno,
	     pag.movgest_numero,
	     pag.movgest_sub_numero,
	     pag.movgest_gsa,
	     pag.movgest_attoamm_tipo_code,
	     pag.movgest_attoamm_anno,
	     pag.movgest_attoamm_numero,
	     pag.movgest_attoamm_sac,
	     pag.liq_anno,
	     pag.liq_numero,
	     pag.liq_attoamm_tipo_code,
	     pag.liq_attoamm_anno,
	     pag.liq_attoamm_numero,
	     pag.liq_attoamm_sac
     from siac_gsa_ordinativo_pagamento pag 
     where pag.anno_bilancio =annoRec.anno_elab
     and     pag.ente_proprietario_id =p_ente_proprietario_id;
     
     esito:= '  Fine caricamento pagamenti into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
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
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;
    
    end if;
end loop;
   

esito:= 'Fine funzione carico ordinativi  GSA (fnc_siac_gsa_ordinativo) - '||clock_timestamp();
RETURN NEXT;
insert into
siac_gsa_ordinativi_log_elab 
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
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

 
update siac_gsa_ordinativi_log_elab  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()- fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi GSA (fnc_siac_gsa_ordinativi terminata con errori '||sqlstate||'-'||SQLERRM;
  raise notice 'esito=%',esito;
--  RAISE NOTICE '% %-%.',esito, SQLSTATE,SQLERRM;
  return next;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

alter function  siac.fnc_siac_gsa_ordinativo (  varchar, varchar,integer, timestamp) owner to siac;




-- INIZIO task-175.sql



\echo task-175.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

/*DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);*/

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar, 
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
   strMessaggio       			VARCHAR(1500)	:='';
   strMessaggioErr       			VARCHAR(1500)	:='';
   strMessaggiofinale 			VARCHAR(1500)	:='';
   codResult              		INTEGER  		:=NULL;
   dataInizioVal 				timestamp		:=NULL;
   faseBilElabId 		        integer:=null;
   faseBilElabPGId          integer:=null;
   faseBilElabGPId          integer:=null;
   bilancioId                   integer:=null;
   periodoId                    integer:=null;
   
   
   tipoOperazioni varchar(50):=null;
  
   faseOp                       varchar(50):=null;
   -- 04.09.2023 Sofia SIAC-TASK-175
   faseOpSucc               varchar(50):=null;
   bilancioSuccId integer:=null;
   periodoSuccId integer:=null;
  
   strRec record;

   APE_GEST_PROGRAMMI    	    CONSTANT varchar:='APE_GEST_ALL_PROGRAMMI';
   P_FASE						CONSTANT varchar:='P';
   E_FASE					    CONSTANT varchar:='E';
   
  BEGIN

   messaggioRisultato:='';
   codicerisultato:=0;
   faseBilElabIdRet:=0;
   dataInizioVal:= clock_timestamp();

   strmessaggiofinale:='Allineamento '||coalesce(tipoAllineamento,' ')||' Programmi-Cronoprogrammi per annoBilancio='||annoBilancio::varchar||'.';
   raise notice '%',strmessaggiofinale;
   strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PROGRAMMI||' IN CORSO.';
   select 1 into codResult
   from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
   and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
   and   fase.fase_bil_elab_esito like 'IN%'
   and   fase.data_cancellazione is null
   and   fase.validita_fine is null
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null;
   if codResult is not null then
   	raise exception ' Esistenza fase in corso.';
   end if;

   -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
   -- da g anno     a  p anno GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti 
   -- da p anno     a g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
   --     'gp|GP|PG'
   strMessaggio:='Verifica tipo allineamenti da eseguire per  '||APE_GEST_PROGRAMMI||'.';
   select tipo.fase_bil_elab_tipo_param  into tipoOperazioni
   from fase_bil_d_elaborazione_tipo  tipo 
   where tipo.ente_proprietario_id =enteProprietarioId 
   and      tipo.fase_bil_elab_tipo_code =APE_GEST_PROGRAMMI
   and      tipo.data_cancellazione  is null 
   and      tipo.validita_fine is null;
   if tipoOperazioni is null then 
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Nessun tipo di allineamento predisposto in esecuzione.';
	   return;
   end if;


    
    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 P ANNO IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;

	 strMessaggio:='Inserimento LOG.';
 	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;
     
     --- 04.09.2023 Sofia SIAC-TASK-175
     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio+1='||(annoBilancio+1)::varchar||'.';
     select bil.bil_id , per.periodo_id into --strict 
                bilancioSuccId, periodoSuccId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio+1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

          --- 04.09.2023 Sofia SIAC-TASK-175 
     strMessaggio:='Verifica fase di bilancio di successivo.';
	 select fase.fase_operativa_code into faseOpSucc
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioSuccId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     --- 04.09.2023 Sofia SIAC-TASK-175
	 strMessaggio:='Verifica fase di bilancio di corrente e successivo.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     raise notice 'FaseOp=%',faseOp;
     raise notice 'FaseOpSucc=%',faseOpSucc;
     --- 04.09.2023 Sofia SIAC-TASK-175
     if ( faseOp is null or faseOp not in (P_FASE,E_FASE) ) and 
         ( faseOpSucc is null or faseOpSucc!=P_FASE )   then
      	raise notice ' Il bilancio deve essere in fase % o %.',P_FASE,E_FASE;
	--	strMessaggio:='Allineamento Programmi-Cronoprogrammi gp -  da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	    strMessaggio:=strMessaggio||' Il bilancio deve essere in fase '||P_FASE||' o '||E_FASE||'. Chiusura fase_bil_t_elaborazione KO.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Fase di bilancio non ammessa.';
	   return;
     end if;
    
    -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
--    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%gp%' then 
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%gp%'  then 
	 -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
     strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
     if tipoOperazioni like '%gp%'  and faseOp  in (P_FASE,E_FASE) then --- 04.09.2023 Sofia SIAC-TASK-175
      raise notice '%',strmessaggio;
      strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.';
 	
	  select * into strRec
      from fnc_fasi_bil_gest_apertura_programmi_popola
      (
       faseBilElabId,
       enteproprietarioid,
       annobilancio,
       'P',
       loginoperazione,
	   dataelaborazione
      );
      if strRec.codiceRisultato!=0 then
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
      end if;
     
      if codiceRisultato = 0 then
          strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
          strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	 select * into strRec
	     from fnc_fasi_bil_gest_apertura_programmi_elabora
    	 (
	      faseBilElabId,
    	  enteproprietarioid,
	      annobilancio,
          'P',
          loginoperazione,
          dataelaborazione,
          false -- no colleg. movimenti
         );
         if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
         end if;
      end if;
     else  -- --- 04.09.2023 Sofia SIAC-TASK-175
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Il bilancio deve essere in fase '||P_FASE||' o '||E_FASE||'. Chiusura fase_bil_t_elaborazione OK.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 a P ANNO TERMINATA CON SUCCESSO.'||
                                                       ' Il bilancio deve essere in fase '||P_FASE||' o '||E_FASE||'.'
       where fase_bil_elab_id=faseBilElabId;

       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;
	  faseBilElabId:=null;
     end if; -- --- 04.09.2023 Sofia SIAC-TASK-175
    
      if codiceRisultato=0 and faseBilElabId is not null then
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 a P ANNO TERMINATA CON SUCCESSO.'
       where fase_bil_elab_id=faseBilElabId;

       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

	 else
      if codiceRisultato!=0 and faseBilElabId is not null then
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||strMessaggioErr||' Chiusura fase_bil_t_elaborazione KO.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      end if;
     end if;
    end if;
   
   
    --- 04.09.2023 Sofia SIAC-TASK-175 inizio 
    -- da g anno   a  p anno gp   - ES.PREVISIONE annoBilancio+1  no ribaltamento collegamenti con movimenti
    -- da modificare fnc interne tutto nello stesso annoBilancio
   faseBilElabId:=null;
    if ( coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%gp%'  ) and
        tipoOperazioni like '%gp%' and codiceRisultato=0 and faseOpSucc=P_FASE  then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||annoBilancio::varchar||' a previsione annoBilancio+1='||(annoBilancio+1)::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';
       
       insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO A P ANNO SUCCESSIVO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabId;

    
        if faseBilElabId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||annoBilancio::varchar||' a previsione annoBilancio+1='||(annoBilancio+1)::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.'; 
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabId,
           enteproprietarioid,
           annobilancio+1,
           'P',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
       
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||annoBilancio::varchar||' a previsione annoBilancio+1='||(annoBilancio+1)::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabId,
    	    enteproprietarioid,
	        annobilancio+1,
            'P',
            loginoperazione,
            dataelaborazione,
            false -- no colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if; 
      end if;
     end if;
    
     if faseBilElabId is not null then
      strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||annoBilancio::varchar||' a previsione annoBilancio+1='||(annoBilancio+1)::varchar||'.';
      if codiceRisultato=0 then 
     	   strMessaggio:=strMessaggio||'  Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO a P ANNO SUCCESSIVO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||strMessaggioErr||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;
	
    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO A P ANNO SUCCESSUVI TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabId;
      end if;
     end if;
    --- 04.09.2023 Sofia SIAC-TASK-175 fine
    
     -- da g anno   a  p anno GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti
     -- da modificare fnc interne tutto nello stesso annoBilancio
    if (coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%GP%'  ) and
        tipoOperazioni like '%GP%' and codiceRisultato=0 and faseOp=E_FASE  then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';

       insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO A P ANNO IN CORSO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabGPId;

    
        if faseBilElabGPId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabGPId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.'; 
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabGPId,
           enteproprietarioid,
           annobilancio,
           'GP',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
       
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabGPId,
    	    enteproprietarioid,
	        annobilancio,
            'GP',
            loginoperazione,
            dataelaborazione,
            false -- no colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if; 
      end if;
     end if;
    
     if faseBilElabGPId is not null then
      strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
      if codiceRisultato=0 then 
     	   strMessaggio:=strMessaggio||'  Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabGPId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO a P ANNO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabGPId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabGPId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabGPId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;
	
    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabGPId;
      end if;
     end if;
    
    -- da p anno     a g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
    if ( coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%PG%' ) and
        tipoOperazioni like '%PG%'  and codiceRisultato=0 and faseOp=E_FASE then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';
       
        insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO A G ANNO IN CORSO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabPGId;
        
        if faseBilElabPGId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabPGId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.';
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabPGId,
           enteproprietarioid,
           annobilancio,
           'G',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabPGId,
    	    enteproprietarioid,
	        annobilancio,
            'G',
            loginoperazione,
            dataelaborazione,
            true -- si colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if;
       end if; 
     end if;
    
 	 
     if faseBilElabPGId is not null then
     strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
     if codiceRisultato=0 then 
           
     	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabPGId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO a G ANNO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabPGId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabPGId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabPGId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;

    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO A G ANNO TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabPGId;
      end if;
    end if;

 
	 if  codiceRisultato=0 then
	  	 messaggioRisultato := strMessaggioFinale||' Operazione terminata correttamente';
	  	 if faseBilElabId is not null then 
 	  	 	faseBilElabIdRet:=faseBilElabId;
 	  	 else 
 	  	    if faseBilElabPGId is not null then 
   	   	     faseBilElabIdRet:=faseBilElabPGId;
   	   	    else 
   	   	     if faseBilElabGPId is not null then 
   	   	      faseBilElabIdRet:=faseBilElabGPId;
   	   	     end if;
   	   	    end if; 
   	   	 end if; 
	 else
  	  	 messaggioRisultato := strMessaggioFinale||strMessaggio||strMessaggioErr;
     end if;

	 RETURN;
EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter FUNCTION siac.fnc_fasi_bil_gest_allinea_programmi
(
integer, 
integer, 
varchar,
varchar, 
timestamp without time zone, 
OUT integer,
OUT integer, 
OUT  varchar
) owner to siac;





