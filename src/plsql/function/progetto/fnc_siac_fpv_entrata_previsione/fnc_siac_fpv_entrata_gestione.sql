/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_siac_fpv_entrata_gestione( INTEGER, VARCHAR ) ;
DROP FUNCTION IF EXISTS siac.fnc_siac_fpv_entrata_gestione( INTEGER ) ;

 CREATE OR replace FUNCTION siac.fnc_siac_fpv_entrata_gestione ( cronop_id_in  INTEGER) 
 returns TABLE ( anno_out             VARCHAR,
                 entrata_prevista     NUMERIC,
                 spesa_corrente       NUMERIC,
                 spesa_conto_capitale NUMERIC,
                 totale_spese         NUMERIC,
                 fpv_entrata          NUMERIC )
AS
  $body$
  DECLARE
    max_anno_ciclo             INTEGER;
    min_anno_ciclo             INTEGER;
    anno_ciclo                 INTEGER;
    v_user                     VARCHAR;
    def_null                   CONSTANT VARCHAR :='';
    rtn_messaggio              VARCHAR(1000)    :=def_null;
    fpv_entrata_anno_prec      NUMERIC := 0;
    totale_spese_anno_prec     NUMERIC := 0;
    entrata_prevista_anno_prec NUMERIC := 0;
  BEGIN
    v_user:=fnc_siac_random_user();

    --trovo gli anni su cui ciclare
    --trovo max

    SELECT MIN(a.anno::INTEGER),
    	   MAX(a.anno::INTEGER)
    INTO   min_anno_ciclo,
    	   max_anno_ciclo
    FROM   siac_t_cronop p,
           siac_t_cronop_elem mp,
           siac_t_cronop_elem_det mv,
           siac_t_periodo a
    WHERE  p.cronop_id=cronop_id_in
    AND    p.cronop_id=mp.cronop_id
    AND    mp.cronop_elem_id=mv.cronop_elem_id
    AND    mv.periodo_id = a.periodo_id
    AND    p.data_cancellazione IS NULL
    AND    mp.data_cancellazione IS NULL
    AND    mv.data_cancellazione IS NULL
    AND    a.data_cancellazione IS NULL ;
    
    
    FOR anno_ciclo IN min_anno_ciclo .. max_anno_ciclo
    LOOP
      RAISE notice 'anno ciclo: %', anno_ciclo;

      SELECT SUM(ced.cronop_elem_det_importo)
      INTO   entrata_prevista
      FROM   siac_t_cronop c,
             siac_t_cronop_elem ce,
             siac_t_cronop_elem_det ced,
             siac_d_bil_elem_tipo te,
             siac_t_periodo pe
      WHERE  c.cronop_id = cronop_id_in
      AND    c.cronop_id = ce.cronop_id
      AND    ce.cronop_elem_id = ced.cronop_elem_id
      AND    ced.periodo_id = pe.periodo_id
      AND    ce.elem_tipo_id = te.elem_tipo_id
      AND    te.elem_tipo_code = 'CAP-EG'
      AND    pe.anno::INTEGER = anno_ciclo
      --AND    pe.anno::INTEGER=anno_ciclo
      AND    ce.data_cancellazione IS NULL
      AND    ced.data_cancellazione IS NULL
      AND    c.data_cancellazione IS NULL
      AND    te.data_cancellazione IS NULL
      AND    pe.data_cancellazione IS NULL;
      
      IF entrata_prevista IS NULL THEN
        entrata_prevista:=0;
      END IF;
      
      SELECT SUM(tb.QUOTA)
      INTO   spesa_conto_capitale
      FROM   (
                    SELECT ced.cronop_elem_det_importo QUOTA,
                           cl.classif_code             titolo_code
                    FROM   siac_t_cronop c,
                           siac_t_cronop_elem ce,
                           siac_t_cronop_elem_det ced,
                           siac_d_bil_elem_tipo te,
                           siac_t_periodo pe,
                           siac_r_cronop_elem_class rcl,
                           siac_t_class cl,
                           siac_d_class_tipo clt
                    WHERE  c.cronop_id =cronop_id_in
                    AND    c.cronop_id = ce.cronop_id
                    AND    ce.cronop_elem_id = ced.cronop_elem_id
                    AND    ced.periodo_id = pe.periodo_id
                    AND    ce.elem_tipo_id = te.elem_tipo_id
                    AND    te.elem_tipo_code = 'CAP-UG'
                    AND    pe.anno::         INTEGER = anno_ciclo
                    --AND    pe.anno::         INTEGER>= anno_ciclo
                    --AND    ced.anno_entrata::INTEGER < anno_ciclo
                    AND    ce.cronop_elem_id = rcl.cronop_elem_id
                    AND    rcl.classif_id=cl.classif_id
                    AND    cl.classif_tipo_id=clt.classif_tipo_id
                    AND    clt.classif_tipo_code = 'TITOLO_SPESA'
                    AND    ce.data_cancellazione IS NULL
                    AND    ced.data_cancellazione IS NULL
                    AND    rcl.data_cancellazione IS NULL
                    AND    c.data_cancellazione IS NULL
                    AND    te.data_cancellazione IS NULL
                    AND    pe.data_cancellazione IS NULL
                    AND    cl.data_cancellazione IS NULL
                    AND    clt.data_cancellazione IS NULL ) tb
      WHERE  tb.titolo_code IN ('2', '3');
      
      IF spesa_conto_capitale IS NULL THEN
        spesa_conto_capitale:=0;
      END IF;
      
      SELECT SUM(tb.QUOTA)
      INTO   spesa_corrente
      FROM   (
                    SELECT ced.cronop_elem_det_importo QUOTA,
                           cl.classif_code             titolo_code
                    FROM   siac_t_cronop c,
                           siac_t_cronop_elem ce,
                           siac_t_cronop_elem_det ced,
                           siac_d_bil_elem_tipo te,
                           siac_t_periodo pe,
                           siac_r_cronop_elem_class rcl,
                           siac_t_class cl,
                           siac_d_class_tipo clt
                    WHERE  c.cronop_id =cronop_id_in
                    AND    c.cronop_id = ce.cronop_id
                    AND    ce.cronop_elem_id = ced.cronop_elem_id
                    AND    ced.periodo_id = pe.periodo_id
                    AND    ce.elem_tipo_id = te.elem_tipo_id
                    AND    te.elem_tipo_code = 'CAP-UG'
                    AND    pe.anno::         INTEGER = anno_ciclo
                    --AND    pe.anno::         INTEGER>= anno_ciclo
                    --AND    ced.anno_entrata::INTEGER < anno_ciclo
                    AND    ce.cronop_elem_id = rcl.cronop_elem_id
                    AND    rcl.classif_id=cl.classif_id
                    AND    cl.classif_tipo_id=clt.classif_tipo_id
                    AND    clt.classif_tipo_code = 'TITOLO_SPESA'
                    AND    ce.data_cancellazione IS NULL
                    AND    ced.data_cancellazione IS NULL
                    AND    rcl.data_cancellazione IS NULL
                    AND    c.data_cancellazione IS NULL
                    AND    te.data_cancellazione IS NULL
                    AND    pe.data_cancellazione IS NULL
                    AND    cl.data_cancellazione IS NULL
                    AND    clt.data_cancellazione IS NULL ) tb
      WHERE  tb.titolo_code NOT IN ('2', '3');
      
      IF spesa_corrente IS NULL THEN
        spesa_corrente:=0;
      END IF;
      
      anno_out :=anno_ciclo;
      totale_spese := spesa_corrente + spesa_conto_capitale;
      fpv_entrata := entrata_prevista_anno_prec - totale_spese_anno_prec + fpv_entrata_anno_prec;
      
      -- Salvo i dati attuali per usarli nell'anno successivo
      entrata_prevista_anno_prec := entrata_prevista;
      totale_spese_anno_prec := totale_spese;
      fpv_entrata_anno_prec := fpv_entrata;
      RETURN NEXT;
      anno_ciclo:=anno_ciclo+1;    
    END LOOP;
    
  EXCEPTION
  WHEN no_data_found THEN
    RAISE notice 'nessun valore trovato' ;
    RETURN;
  WHEN OTHERS THEN
    --RTN_MESSAGGIO:='capitolo altro errore';
    RAISE
  EXCEPTION
    '% Errore : %-%.',rtn_messaggio,SQLSTATE,SQLERRM;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security definer cost 100 ROWS 1000;