/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR125_rendiconto_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  importo_codice_bilancio_prec numeric,
  rif_cc varchar,
  rif_dm varchar,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  importo_dati_passivo numeric,
  importo_dati_passivo_prec numeric,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer
) AS
$body$
DECLARE

classifGestione record;
pdce            record;
impprimanota    record;
dati_passivo    record;

anno_prec 			 VARCHAR;
v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_dare_prec      NUMERIC :=0;
v_imp_avere_prec     NUMERIC :=0;
v_importo 			 NUMERIC :=0;
v_importo_prec 		 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_pdce_fam_code_prec VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_prec VARCHAR;
v_anno_int integer; -- SIAC-5487
v_anno_prec_int integer; -- SIAC-5487

DEF_NULL	constant VARCHAR:=''; 
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;

v_importo_anno_prec NUMERIC;

BEGIN

anno_prec := (p_anno::INTEGER-1)::VARCHAR;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer; -- SIAC-5487
v_anno_prec_int := p_anno::integer-1; -- SIAC-5487

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
importo_codice_bilancio_prec := 0;
rif_CC := '';
rif_DM := '';
codice_raggruppamento := '';
descr_raggruppamento := '';
codice_codifica_albero := '';
valore_importo := 0;
codice_subraggruppamento := '';
classif_id_liv1 := 0;
classif_id_liv2 := 0;
classif_id_liv3 := 0;
classif_id_liv4 := 0;
classif_id_liv5 := 0;
classif_id_liv6 := 0;

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';

IF p_classificatori = '1' THEN
   v_classificatori := '00020'; -- 'CE_CODBIL';
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00021'; -- 'SPA_CODBIL';   
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00022'; -- 'SPP_CODBIL';
   v_classificatori1 := '00023'; -- 'CO_CODBIL';
END IF;  

raise notice '1 - %' , v_classificatori;  

v_anno_prec := p_anno::INTEGER-1;

IF p_classificatori = '2' THEN

WITH Importipn AS (
 SELECT 
        Importipn.pdce_conto_id,
        Importipn.anno,
        CASE
            WHEN Importipn.movep_det_segno = 'Dare' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_dare,  
        CASE
            WHEN Importipn.movep_det_segno = 'Avere' THEN
                 Importipn.movep_det_importo
            ELSE
                 0     
        END  importo_avere               
  FROM (   
   SELECT  anno_eserc.anno,
            CASE 
              WHEN pdce_conto.livello = 8 THEN
                   (select a.pdce_conto_id_padre
                   from   siac_t_pdce_conto a
                   where  a.pdce_conto_id = pdce_conto.pdce_conto_id
                   and    a.data_cancellazione is null)
              ELSE
               pdce_conto.pdce_conto_id
            END pdce_conto_id,                    
            mov_ep_det.movep_det_segno, 
            mov_ep_det.movep_det_importo
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
    AND prima_nota.ente_proprietario_id=p_ente_prop_id  
    AND anno_eserc.anno IN (p_anno,v_anno_prec)
    AND pdce_conto.pdce_conto_id IN (select a.pdce_conto_id
                                     from  siac_r_pdce_conto_attr a, siac_t_attr c
                                     where a.attr_id = c.attr_id
                                     and   c.attr_code = 'pdce_conto_segno_negativo'
                                     and   a."boolean" = 'S'
                                     and   a.ente_proprietario_id = p_ente_prop_id)
    AND pnota_stato.pnota_stato_code='D'
    AND pdce_fam.pdce_fam_code IN ('PP','OP')
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
    AND causale_ep.data_cancellazione is NULL
    ) Importipn
    ),
    codifica_bilancio as (
    SELECT a.pdce_conto_id, tb.ordine
    FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
        classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, level, arrhierarchy) AS (
        SELECT rt1.classif_classif_fam_tree_id,
                                rt1.classif_fam_tree_id, rt1.classif_id,
                                rt1.classif_id_padre, rt1.ente_proprietario_id,
                                rt1.ordine, rt1.livello, 1,
                                ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
        FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1,  siac_d_class_fam cf
        WHERE cf.classif_fam_id = tt1.classif_fam_id 
        AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
        AND   rt1.classif_id_padre IS NULL 
        AND   cf.classif_fam_code::text = '00021'::text 
        AND   tt1.ente_proprietario_id = rt1.ente_proprietario_id 
        AND   rt1.data_cancellazione is null
        AND   tt1.data_cancellazione is null
        AND   cf.data_cancellazione is null
        --AND   date_trunc('day'::text, now()) > rt1.validita_inizio 
        --AND  (date_trunc('day'::text, now()) < rt1.validita_fine OR tt1.validita_fine IS NULL)
        AND   cf.ente_proprietario_id = p_ente_prop_id
        UNION ALL
        SELECT tn.classif_classif_fam_tree_id,
                                tn.classif_fam_tree_id, tn.classif_id,
                                tn.classif_id_padre, tn.ente_proprietario_id,
                                tn.ordine, tn.livello, tp.level + 1,
                                tp.arrhierarchy || tn.classif_id
        FROM rqname tp, siac_r_class_fam_tree tn
        WHERE tp.classif_id = tn.classif_id_padre 
        AND tn.ente_proprietario_id = tp.ente_proprietario_id
        AND tn.ente_proprietario_id = p_ente_prop_id
        AND  tn.data_cancellazione is null
        )
        SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
                rqname.classif_id, rqname.classif_id_padre,
                rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
                rqname.level
        FROM rqname
        ORDER BY rqname.arrhierarchy
        ) tb, siac_t_class t1,
        siac_d_class_tipo ti1,
        siac_r_pdce_conto_class a
    WHERE t1.classif_id = tb.classif_id 
    AND   ti1.classif_tipo_id = t1.classif_tipo_id 
    AND   t1.ente_proprietario_id = tb.ente_proprietario_id 
    AND   ti1.ente_proprietario_id = t1.ente_proprietario_id
    AND   a.classif_id = t1.classif_id
    AND   a.ente_proprietario_id = t1.ente_proprietario_id
    AND   t1.data_cancellazione is null
    AND   ti1.data_cancellazione is null
    AND   a.data_cancellazione is null
    AND   v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
    AND   v_anno_int BETWEEN date_part('year',a.validita_inizio) AND date_part('year',COALESCE(a.validita_fine,now())) -- SIAC-6156
    )
    INSERT INTO rep_bilr125_dati_stato_passivo
    SELECT  
    Importipn.anno,
    codifica_bilancio.ordine,
    SUM(Importipn.importo_dare) importo_dare,
    SUM(Importipn.importo_avere) importo_avere,         
    SUM(Importipn.importo_avere - Importipn.importo_dare) importo_passivo,
    user_table
    FROM Importipn 
    INNER JOIN codifica_bilancio ON Importipn.pdce_conto_id = codifica_bilancio.pdce_conto_id
    GROUP BY Importipn.anno, codifica_bilancio.ordine ;

END IF;


FOR classifGestione IN
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       --case when zz.classif_code='26' then 'E.26' else zz.classif_code end codice_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       --case when zz.ordine='26' then 'E.26' else zz.ordine end codice_codifica_albero,
       case when zz.ordine='E.26' then 3 else zz.level end livello_codifica,
       --zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
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
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
/*           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)*/
           AND v_anno_int BETWEEN date_part('year',tt1.validita_inizio) AND 
           date_part('year',COALESCE(tt1.validita_fine,now())) --SIAC-5487
           AND v_anno_int BETWEEN date_part('year',rt1.validita_inizio) AND 
           date_part('year',COALESCE(rt1.validita_fine,now())) 
           AND v_anno_int BETWEEN date_part('year',c.validita_inizio) AND 
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
        AND v_anno_int BETWEEN date_part('year',tn.validita_inizio) AND 
           date_part('year',COALESCE(tn.validita_fine,now())) 
AND v_anno_int BETWEEN date_part('year',c2.validita_inizio) AND 
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
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, 
--case when zz.ordine='26' then 'E.26' else zz.ordine end asc
zz.ordine
/*
SELECT zz.ente_proprietario_id, 
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica, 
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero, 
       zz.level AS livello_codifica,
       zz.classif_id, 
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,  
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6         
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
           FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf
           WHERE cf.classif_fam_id = tt1.classif_fam_id 
           AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
           AND rt1.classif_id_padre IS NULL 
           AND   (cf.classif_fam_code = v_classificatori OR cf.classif_fam_code = v_classificatori1)
           AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
           AND date_trunc('day'::text, now()) > tt1.validita_inizio 
           AND (date_trunc('day'::text, now()) < tt1.validita_fine OR tt1.validita_fine IS NULL)
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
    AND v_anno_int BETWEEN date_part('year',t1.validita_inizio) AND date_part('year',COALESCE(t1.validita_fine,now())) --SIAC-5487
) zz
--WHERE zz.ente_proprietario_id = p_ente_prop_id
ORDER BY zz.classif_tipo_code desc, zz.ordine asc     */

LOOP
    
        
    valore_importo := 0;

    SELECT COUNT(*)
    INTO   valore_importo
    FROM   siac_r_class_fam_tree a
    WHERE  a.classif_id_padre = classifGestione.classif_id
    AND    a.data_cancellazione IS NULL;

    IF classifGestione.livello_codifica = 3 THEN    
       v_codice_subraggruppamento := classifGestione.codice_codifica;  
       codice_subraggruppamento := v_codice_subraggruppamento;       
    ELSIF classifGestione.livello_codifica < 3 THEN
       codice_subraggruppamento := '';        
    ELSIF classifGestione.livello_codifica > 3 THEN
       codice_subraggruppamento := v_codice_subraggruppamento;          
    END IF;
       
    IF classifGestione.livello_codifica = 2 THEN
       codice_raggruppamento := SUBSTRING(classifGestione.descrizione_codifica FROM 1 FOR 1);
       descr_raggruppamento := classifGestione.descrizione_codifica;
    ELSIF classifGestione.livello_codifica = 1 THEN  
       codice_raggruppamento := '';
       descr_raggruppamento := '';  
    END IF;   
    
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF;
    
    rif_CC := ''; 
    rif_DM := '';

    SELECT a.rif_art_2424_cc, a.rif_dm_26_4_95
    INTO rif_CC, rif_DM
    FROM siac_rep_rendiconto_gestione_rif a
    WHERE a.codice_bilancio = classifGestione.codice_codifica_albero
    AND   (a.codice_report = v_classificatori OR a.codice_report = v_classificatori1);    

    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0; 
    
    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

      SELECT importo_passivo
      INTO   importo_dati_passivo_prec
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = v_anno_prec
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;
          
    END IF;
    
    v_imp_dare := 0;
    v_imp_avere := 0;
    v_imp_dare_prec := 0;
    v_imp_avere_prec := 0;
    v_importo := 0;
    v_importo_prec := 0;
    v_pdce_fam_code := '';
    v_pdce_fam_code_prec := '';

    FOR pdce IN
	SELECT d.pdce_fam_code, e.movep_det_segno, i.anno, SUM(COALESCE(e.movep_det_importo,0)) AS importo
    FROM  siac_r_pdce_conto_class a
    INNER JOIN siac_t_pdce_conto b ON a.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree c ON b.pdce_fam_tree_id = c.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d ON c.pdce_fam_id = d.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det e ON e.pdce_conto_id = b.pdce_conto_id
    INNER JOIN siac_t_mov_ep f ON e.movep_id = f.movep_id
    INNER JOIN siac_t_prima_nota g ON f.regep_id = g.pnota_id
    INNER JOIN siac_t_bil h ON g.bil_id = h.bil_id
    INNER JOIN siac_t_periodo i ON h.periodo_id = i.periodo_id
    INNER JOIN siac_r_prima_nota_stato l ON g.pnota_id = l.pnota_id
    INNER JOIN siac_d_prima_nota_stato m ON l.pnota_stato_id = m.pnota_stato_id
    WHERE a.classif_id = classifGestione.classif_id
    AND   m.pnota_stato_code = 'D'
    AND   (i.anno = p_anno OR i.anno = anno_prec)
    AND   a.data_cancellazione IS NULL
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
/*    AND   (v_anno_int BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487    
           OR
           v_anno_prec_int BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487 
          )*/
       AND   (i.anno::integer BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487    
           OR
           i.anno::integer BETWEEN date_part('year',b.validita_inizio) AND date_part('year',COALESCE(b.validita_fine,now())) --SIAC-5487 
          )  
    AND  v_anno_int BETWEEN date_part('year',a.validita_inizio)::integer
    AND coalesce (date_part('year',a.validita_fine)::integer ,v_anno_int) 
    GROUP BY d.pdce_fam_code, e.movep_det_segno, i.anno
        
    LOOP
        
    IF p_classificatori IN ('1','3') THEN
           
      IF pdce.movep_det_segno = 'Dare' THEN
         IF pdce.anno = p_anno THEN
            v_imp_dare := pdce.importo;
         ELSE
            v_imp_dare_prec := pdce.importo;
         END IF;   
      ELSIF pdce.movep_det_segno = 'Avere' THEN
         IF pdce.anno = p_anno THEN
            v_imp_avere := pdce.importo;
         ELSE
            v_imp_avere_prec := pdce.importo;
         END IF;                   
      END IF;               
    
      IF pdce.anno = p_anno THEN
         v_pdce_fam_code := pdce.pdce_fam_code;
      ELSE
         v_pdce_fam_code_prec := pdce.pdce_fam_code;
      END IF;    
        
    ELSIF p_classificatori = '2' THEN  
      IF pdce.pdce_fam_code = 'AP' THEN 
      
        IF pdce.movep_det_segno = 'Dare' THEN
           IF pdce.anno = p_anno THEN
              v_imp_dare := pdce.importo;
           ELSE
              v_imp_dare_prec := pdce.importo;
           END IF;   
        ELSIF pdce.movep_det_segno = 'Avere' THEN
           IF pdce.anno = p_anno THEN
              v_imp_avere := pdce.importo;
           ELSE
              v_imp_avere_prec :=pdce.importo;
           END IF;                   
        END IF;       
      
        IF pdce.anno = p_anno THEN
           v_pdce_fam_code := pdce.pdce_fam_code;
        ELSE
           v_pdce_fam_code_prec := pdce.pdce_fam_code;
        END IF;      
      
      END IF;        
    END IF;  
                                                                        
    END LOOP;


        
    IF p_classificatori IN ('1','3') THEN
      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN   
         v_importo := v_imp_dare - v_imp_avere;   
      END IF; 
    
      IF v_pdce_fam_code_prec IN ('PP','OP','OA','RE') THEN
         v_importo_prec := v_imp_avere_prec - v_imp_dare_prec;
      ELSIF v_pdce_fam_code_prec IN ('AP','CE') THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;     
    
    ELSIF p_classificatori = '2' THEN
      
      IF v_pdce_fam_code = 'AP' THEN   
         v_importo := v_imp_dare - v_imp_avere;
      END IF; 
      
      IF v_pdce_fam_code_prec = 'AP' THEN   
         v_importo_prec := v_imp_dare_prec - v_imp_avere_prec;   
      END IF;       
            
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);
    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code_prec,classifGestione.classif_id,COALESCE(v_importo_prec,0),COALESCE(v_imp_dare_prec,0),COALESCE(v_imp_avere_prec,0);
        
    END IF;
    
/* SIAC-6296. 11/07/2018: per risolvere il problema relativo all'estrazione
	dei dati dell'anno precedente che in alcuni casi non sono estratti 
    correttamente a causa delle date di fine validita'.
    E' chiamata una copia della procedura passando in input l'anno 
    precedente.
    In questo modo si e' sicuri che i dati dell'anno precedente sono
    uguali a quelli ottenuti nel report con input anno precente. */    
    select a.importo_codice_bilancio
    into v_importo_anno_prec
    from "BILR125_rendiconto_gestione_anno_prec"(p_ente_prop_id, anno_prec, 
    	p_classificatori, classifGestione.codice_codifica,
        classifGestione.descrizione_codifica) a;
  --  where a.codice_codifica = classifGestione.codice_codifica
   -- and a.descrizione_codifica = classifGestione.descrizione_codifica
   -- and a.tipo_codifica = classifGestione.tipo_codifica
   -- and a.livello_codifica = classifGestione.livello_codifica;
    
           
	v_importo_prec:=v_importo_anno_prec;
        
    raise notice 'codice_codifica = %, descr_codifica = %, importo_prec = %', 
    	classifGestione.codice_codifica, classifGestione.descrizione_codifica,
        v_importo_anno_prec; 
        
    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;
  
    IF p_classificatori != '1' THEN
    
      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;         
         importo_codice_bilancio_prec := v_importo_prec;
      ELSE
         importo_codice_bilancio := 0;       
         importo_codice_bilancio_prec := 0;
      END IF;          
  
    ELSE
      importo_codice_bilancio := v_importo;
      importo_codice_bilancio_prec := v_importo_prec;     
    END IF;

raise notice 'classif_id = %, descrizione_codifica = %, codice_raggruppamento = %, codice_subraggruppamento = %, v_importo = %, v_importo_prec = %',
    	classifGestione.classif_id,
        classifGestione.descrizione_codifica, codice_raggruppamento,
        codice_subraggruppamento, 
        v_importo, v_importo_prec;
        
    codice_codifica_albero := classifGestione.codice_codifica_albero;
    
    classif_id_liv1 := classifGestione.classif_id_liv1;
    classif_id_liv2 := classifGestione.classif_id_liv2;
    classif_id_liv3 := classifGestione.classif_id_liv3;
    classif_id_liv4 := classifGestione.classif_id_liv4;
    classif_id_liv5 := classifGestione.classif_id_liv5;
    classif_id_liv6 := classifGestione.classif_id_liv6;
      
    return next;

    tipo_codifica := '';
    codice_codifica := '';
    descrizione_codifica := '';
    livello_codifica := 0;
    importo_codice_bilancio := 0;
    importo_codice_bilancio_prec := 0;
    rif_CC := '';
    rif_DM := '';
    codice_codifica_albero := '';
    valore_importo := 0;
    codice_subraggruppamento := '';
    importo_dati_passivo :=0;
    importo_dati_passivo_prec :=0;
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;

END LOOP;

delete from rep_bilr125_dati_stato_passivo where utente=user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;