/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR206_rendiconto_gestione_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_classificatori varchar,
  p_data_pnota_da date,
  p_data_pnota_a date
)
RETURNS TABLE (
  tipo_codifica varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  livello_codifica integer,
  importo_codice_bilancio numeric,
  codice_raggruppamento varchar,
  descr_raggruppamento varchar,
  codice_codifica_albero varchar,
  valore_importo integer,
  codice_subraggruppamento varchar,
  classif_id_liv1 integer,
  classif_id_liv2 integer,
  classif_id_liv3 integer,
  classif_id_liv4 integer,
  classif_id_liv5 integer,
  classif_id_liv6 integer,
  pdce_conto_code varchar,
  pdce_conto_descr varchar,
  importo_dare numeric,
  importo_avere numeric,
  display_error varchar
) AS
$body$
DECLARE

classifGestione record;
pdce            record;

v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;

v_importo 			 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_int integer;

DEF_NULL	constant VARCHAR:='';
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;
conta_date integer;

BEGIN


RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer;

tipo_codifica := '';
codice_codifica := '';
descrizione_codifica := '';
livello_codifica := 0;
importo_codice_bilancio := 0;
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
pdce_conto_code := '';
pdce_conto_descr := '';
importo_dare :=0;
importo_avere :=0;
display_error:='';

RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL BILANCIO ''.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';



IF p_classificatori = '1' THEN
   v_classificatori := '00024'; -- conto economico (codice di bilancio) gsa
ELSIF p_classificatori = '2' THEN
   v_classificatori := '00026'; -- stato patrimoniale attivo (codice di bilancio) gsa
ELSIF p_classificatori = '3' THEN
   v_classificatori  := '00025';  -- stato patrimoniale passivo (codice di bilancio) gsa
END IF;


raise notice '1 - %' , v_classificatori;

--21/04/2020 SIAC-7426.
-- Aggiunta gestione delle date Da/A della prima nota definitiva.
-- Aggiunta anche gestione dell'errore tramite display_error.
conta_date:=0;
if p_data_pnota_da is not null then
	conta_date:=conta_date+1;
end if;
   
if p_data_pnota_a is not null then
	conta_date:=conta_date+1;
end if;

if conta_date = 1 then
	display_error:= 'Specificare entrambe le date dell''intervallo relativo alla data definititiva della prima nota.';
    return next;
    return;
end if;

if p_data_pnota_a < p_data_pnota_da then
	display_error:= 'La data A della prima nota definitiva deve essere uguale o successiva a quella DA';
    return next;
    return;
end if;
    
-- attivita - passivita con segno negativo -- 11.06.Sofia siac-6201 - non serve
/*IF p_classificatori = '2' THEN

WITH Importipn AS
(
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
    AND anno_eserc.anno IN (p_anno)
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
        AND   cf.classif_fam_code::text = '00026'::text
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

END IF;*/

-- loop per codifica di bilancio
-- CODBIL_GSA
-- CE_CODBIL_GSA  1 - costi,ricavi
-- SPA_CODBIL_GSA 2 - attivita bilancio
-- SPP_CODBIL_GSA 3 - passivita bilancio
FOR classifGestione IN
SELECT zz.ente_proprietario_id,
       zz.classif_tipo_code AS tipo_codifica,
       zz.classif_code AS codice_codifica,
       zz.classif_desc AS descrizione_codifica,
       zz.ordine AS codice_codifica_albero,
       case when zz.ordine='E.26' then 3 else zz.level end livello_codifica,
       zz.classif_id,
       zz.classif_id_padre,
       zz.arrhierarchy,
       COALESCE(zz.arrhierarchy[1],0) classif_id_liv1,
       COALESCE(zz.arrhierarchy[2],0) classif_id_liv2,
       COALESCE(zz.arrhierarchy[3],0) classif_id_liv3,
       COALESCE(zz.arrhierarchy[4],0) classif_id_liv4,
       COALESCE(zz.arrhierarchy[5],0) classif_id_liv5,
       COALESCE(zz.arrhierarchy[6],0) classif_id_liv6
FROM
(
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
           AND v_anno_int BETWEEN date_part('year',tt1.validita_inizio) AND
           date_part('year',COALESCE(tt1.validita_fine,now()))
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
ORDER BY zz.classif_tipo_code desc,
         zz.ordine
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

  /* 11.06.2018 Sofia siac-6201 - non esiste per GSA
    IF classifGestione.tipo_codifica = 'CO_CODBIL' AND classifGestione.livello_codifica <> 1 THEN
       codice_raggruppamento := 'Z';
       descr_raggruppamento := 'CONTI D''ORDINE';
    END IF; */


/*  -- 11.06.2018 Sofia siac-6201 - non serve
    importo_dati_passivo :=0;

    IF p_classificatori = '2' THEN
      SELECT importo_passivo
      INTO   importo_dati_passivo
      FROM   rep_bilr125_dati_stato_passivo
      WHERE  anno = p_anno
      AND    codice_codifica_albero_passivo = classifGestione.codice_codifica_albero
      AND    utente = user_table;

    END IF;*/

    v_imp_dare := 0;
    v_imp_avere := 0;
    v_importo := 0;
    v_pdce_fam_code := '';
    raise notice 'classif_id = %', classifGestione.classif_id;

-- inizio loop per conto
FOR pdce IN
   WITH
   conti AS
   (
    SELECT fam.pdce_fam_code,
           conto.pdce_conto_code, conto.pdce_conto_desc,
           conto.pdce_conto_id
    from siac_r_pdce_conto_class r,  siac_t_pdce_conto conto,
         siac_t_pdce_fam_tree famtree, siac_d_pdce_fam fam,siac_d_ambito ambito
    where r.classif_id=classifGestione.classif_id
    and   conto.pdce_conto_id=r.pdce_conto_id
    and   famtree.pdce_fam_tree_id=conto.pdce_fam_tree_id
    and   fam.pdce_fam_id=famtree.pdce_fam_id
    and   ambito.ambito_id=conto.ambito_id
    and   ambito.ambito_code='AMBITO_GSA'
    and   r.data_cancellazione is null
    and   conto.data_cancellazione is null
    and   v_anno_int BETWEEN date_part('year',r.validita_inizio)::integer and  coalesce (date_part('year',r.validita_fine)::integer ,v_anno_int)
	and   v_anno_int BETWEEN date_part('year',conto.validita_inizio) AND date_part('year',COALESCE(conto.validita_fine,now()))
   ),
   movimenti as
   (
    select det.pdce_conto_id,
           sum( case  when det.movep_det_segno='Dare' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_dare,
           sum( case  when det.movep_det_segno='Avere' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_avere
    from  siac_t_periodo per,   siac_t_bil bil,
          siac_t_prima_nota pn, siac_r_prima_nota_stato rs, siac_d_prima_nota_stato stato,
          siac_t_mov_ep ep, siac_t_mov_ep_det det,siac_d_ambito ambito
    where bil.ente_proprietario_id=p_ente_prop_id
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=v_anno_int
    and   pn.bil_id=bil.bil_id
    and   rs.pnota_id=pn.pnota_id
    and   stato.pnota_stato_id=rs.pnota_stato_id
    and   stato.pnota_stato_code='D'
    and   ep.regep_id=pn.pnota_id
    and   det.movep_id=ep.movep_id
    and   ambito.ambito_id=pn.ambito_id
    and   ambito.ambito_code='AMBITO_GSA'
--21/04/2020 SIAC-7426.
-- Aggiunta gestione delle date Da/A della prima nota definitiva.    
 	and   ((p_data_pnota_da is NOT NULL and 
    		trunc(pn.pnota_dataregistrazionegiornale) between 
    			p_data_pnota_da and p_data_pnota_a) OR
            p_data_pnota_da IS NULL)               
    and   pn.data_cancellazione is null
    and   pn.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   ep.data_cancellazione is null
    and   ep.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    group by det.pdce_conto_id
   )
   select  conti.pdce_fam_code,
           conti.pdce_conto_code, conti.pdce_conto_desc,
           coalesce(movimenti.importo_dare,0) importo_dare, coalesce(movimenti.importo_avere,0) importo_avere
   from conti left join   movimenti on ( conti.pdce_conto_id=movimenti.pdce_conto_id )
LOOP
    raise notice 'Importo Dare = %', pdce.importo_dare;
    raise notice 'Importo Avere = %', pdce.importo_avere;

    v_imp_dare:=pdce.importo_dare;
    v_imp_avere := pdce.importo_avere;
    v_pdce_fam_code := pdce.pdce_fam_code;

    importo_avere:= v_imp_avere;
    importo_dare:=v_imp_dare;
    pdce_conto_code:=pdce.pdce_conto_code;
    pdce_conto_descr:= pdce.pdce_conto_desc;


    IF p_classificatori IN ('1','3') THEN

      IF v_pdce_fam_code IN ('PP','OP','OA','RE') THEN
         v_importo := v_imp_avere - v_imp_dare;
      ELSIF v_pdce_fam_code IN ('AP','CE') THEN
         v_importo := v_imp_dare - v_imp_avere;
      END IF;



    ELSIF p_classificatori = '2' THEN

      IF v_pdce_fam_code = 'AP' THEN
         v_importo := v_imp_dare - v_imp_avere;
      END IF;


    -- raise notice 'Famiglia %, Classe %, Importo %, Dare %, Avere %',v_pdce_fam_code,classifGestione.classif_id,COALESCE(v_importo,0),COALESCE(v_imp_dare,0),COALESCE(v_imp_avere,0);

    END IF;

    tipo_codifica := classifGestione.tipo_codifica;
    codice_codifica := classifGestione.codice_codifica;
    descrizione_codifica := classifGestione.descrizione_codifica;
    livello_codifica := classifGestione.livello_codifica;

    IF p_classificatori != '1' THEN

      IF valore_importo = 0 or classifGestione.codice_codifica_albero = 'B.III.2.1' or classifGestione.codice_codifica_albero = 'B.III.2.2'  or classifGestione.codice_codifica_albero = 'B.III.2.3' THEN
         importo_codice_bilancio := v_importo;
      ELSE
         importo_codice_bilancio := 0;
      END IF;

    ELSE
      importo_codice_bilancio := v_importo;
    END IF;

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
    codice_codifica_albero := '';
    classif_id_liv1 := 0;
    classif_id_liv2 := 0;
    classif_id_liv3 := 0;
    classif_id_liv4 := 0;
    classif_id_liv5 := 0;
    classif_id_liv6 := 0;
    pdce_conto_code := '';
    pdce_conto_descr := '';
    importo_dare :=0;
    importo_avere :=0;
  end loop;  -- loop per conto

  valore_importo := 0;
  codice_subraggruppamento := '';
--  importo_dati_passivo :=0; -- 11.06.2018 Sofia siac-6201 - non serve


END LOOP; -- loop per codifica di bilancio

--delete from rep_bilr125_dati_stato_passivo where utente=user_table; -- 11.06.2018 Sofia siac-6201 - non serve

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'nessun dato trovato per rendiconto gestione GSA';
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