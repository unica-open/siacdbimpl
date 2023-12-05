/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_siac_fpv_spesa_previsione( INTEGER, VARCHAR );
DROP FUNCTION IF EXISTS siac.fnc_siac_fpv_spesa_previsione( INTEGER );
 
CREATE OR replace FUNCTION siac.fnc_siac_fpv_spesa_previsione ( cronop_id_in INTEGER ) 
  returns TABLE ( missione       VARCHAR,
                  programma      VARCHAR,
                  titolo         VARCHAR,
                  anno_out       VARCHAR,
                  spesa_prevista NUMERIC,
                  fpv_spesa      NUMERIC )
AS
  $body$
  DECLARE
    max_anno_ciclo  INTEGER;
    min_anno_ciclo  INTEGER;
    anno_ciclo      INTEGER;
    cronop_id       INTEGER;
    rec_crono_spese RECORD;
    rec_out         RECORD;
    rtn_messaggio 	VARCHAR(1000):='';
    
    -- variabili spesa
    cronop_elem_id_out              INTEGER;
    cronop_anno_out                 VARCHAR;
    importo_spesa_out               NUMERIC;
	classif_id_programma_out        INTEGER;
    classif_id_missione_out         INTEGER;
    classif_id_titolo_out           INTEGER;
    classif_code_programma_out      VARCHAR;
    classif_code_missione_out       VARCHAR;
    classif_code_titolo_out         VARCHAR;
	classif_tipo_code_missione_out  VARCHAR;
    classif_tipo_code_programma_out VARCHAR;
    classif_tipo_code_titolo_out    VARCHAR;
    
	-- accumulatori
    v_tot_spesa_previstaanno NUMERIC;  
    v_entrata_per_anno       NUMERIC;
    v_fpv_spesa_annoprec     NUMERIC;

  BEGIN
    v_fpv_spesa_annoprec:=0;
    
    -- tabella di appoggio
    CREATE TEMPORARY TABLE temp_fpv_spesa(
       tmp_missione        VARCHAR
      ,tmp_programma       VARCHAR
      ,tmp_titolo          VARCHAR
      ,tmp_anno_out        VARCHAR
      ,tmp_spesa_prevista  NUMERIC
      ,tmp_fpv_spesa       NUMERIC
    )
    ON COMMIT DROP;
    
    
    
    
    --trovo gli anni su cui ciclare
    --trovo max e min
    SELECT max(a.anno::INTEGER),min(a.anno::INTEGER)
    INTO   max_anno_ciclo,min_anno_ciclo
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
    
    RAISE notice 'min anno ciclo: %', min_anno_ciclo;
    RAISE notice 'max anno ciclo: %', max_anno_ciclo;
    
    FOR anno_ciclo IN min_anno_ciclo .. max_anno_ciclo
    LOOP
      RAISE notice 'anno_ciclo_G : %', anno_ciclo;
      
      v_tot_spesa_previstaanno:=0;
      
      FOR rec_crono_spese IN
            SELECT c.cronop_id,
                   ce.cronop_elem_id,
                   pe.anno,
                   ced.cronop_elem_det_importo
            FROM   siac_t_cronop c,
                   siac_t_cronop_elem ce,
                   siac_t_cronop_elem_det ced,
                   siac_d_bil_elem_tipo te,
                   siac_t_periodo pe                   
            WHERE  c.cronop_id =cronop_id_in
            AND    c.cronop_id = ce.cronop_id
            AND    ce.cronop_elem_id = ced.cronop_elem_id
            AND    ced.periodo_id = pe.periodo_id
            AND    ce.elem_tipo_id = te.elem_tipo_id
            AND    te.elem_tipo_code = 'CAP-UP'
            AND    pe.anno::INTEGER = anno_ciclo
            AND    c.data_cancellazione IS NULL
            AND    ce.data_cancellazione IS NULL
            AND    ced.data_cancellazione IS NULL
            AND    te.data_cancellazione IS NULL
            AND    pe.data_cancellazione IS NULL 
      LOOP 
      
      cronop_id:=rec_crono_spese.cronop_id;
      cronop_elem_id_out:=rec_crono_spese.cronop_elem_id;
      cronop_anno_out:=rec_crono_spese.anno;
      importo_spesa_out:=rec_crono_spese.cronop_elem_det_importo;
      
      --cerco classificatori collegati
      --PROGRAMMA
      SELECT DISTINCT cl2.classif_id,
                      cl2.classif_code,
                      clt2.classif_tipo_code,
                      ft2.classif_id_padre
      INTO            classif_id_programma_out ,
                      classif_code_programma_out ,
                      classif_tipo_code_programma_out,
                      classif_id_missione_out
      FROM            siac_t_class cl2,
                      siac_r_cronop_elem_class rcl2,
                      siac_r_class_fam_tree ft2,
                      siac_t_class_fam_tree cf2,
                      siac_d_class_fam df2,
                      siac_d_class_tipo clt2
      WHERE           rcl2.cronop_elem_id=cronop_elem_id_out
      AND             rcl2.classif_id=cl2.classif_id
      AND             ft2.classif_id=cl2.classif_id
      AND             ft2.classif_fam_tree_id=cf2.classif_fam_tree_id
      AND             df2.classif_fam_id=cf2.classif_fam_id
      AND             df2.classif_fam_desc='Spesa - MissioniProgrammi'
      AND             cl2.classif_tipo_id=clt2.classif_tipo_id
      AND             clt2.classif_tipo_code='PROGRAMMA';
      
      --trova missione papa' del programma
      SELECT clpa.classif_code,
             clt2.classif_tipo_code
      INTO   classif_code_missione_out ,
             classif_tipo_code_missione_out
      FROM   siac_t_class clpa,
             siac_d_class_tipo clt2
      WHERE  clpa.classif_tipo_id=clt2.classif_tipo_id
      AND    clpa.classif_id=classif_id_missione_out;
      
      -- TITOLO
      SELECT DISTINCT cl2.classif_id,
                      cl2.classif_code,
                      clt2.classif_tipo_code
      INTO            classif_id_titolo_out,
                      classif_code_titolo_out ,
                      classif_tipo_code_titolo_out
      FROM            siac_t_class cl2,
                      siac_r_cronop_elem_class rcl2,
                      siac_d_class_tipo clt2
      WHERE           rcl2.cronop_elem_id=cronop_elem_id_out
      AND             rcl2.classif_id=cl2.classif_id
      AND             cl2.classif_tipo_id=clt2.classif_tipo_id
      AND             clt2.classif_tipo_code='TITOLO_SPESA';
      
      v_tot_spesa_previstaanno := v_tot_spesa_previstaanno + importo_spesa_out;

      insert into temp_fpv_spesa (
        tmp_missione        
       ,tmp_programma       
       ,tmp_titolo          
       ,tmp_anno_out        
       ,tmp_spesa_prevista  
       ,tmp_fpv_spesa       
      )VALUES(
       classif_code_missione_out
       ,classif_code_programma_out
       ,classif_code_titolo_out
       ,anno_ciclo
       ,importo_spesa_out
       ,null     
      );
      
      RAISE notice 'insert temp_fpv_spesa % %',rec_crono_spese.cronop_elem_id, anno_ciclo;
    END LOOP;
    
    --calcolo le entrate 
    SELECT coalesce(sum (ced.cronop_elem_det_importo), 0)
    into  v_entrata_per_anno
    FROM         
         siac_t_cronop c,
         siac_t_cronop_elem ce,
         siac_t_cronop_elem_det ced,
         siac_d_bil_elem_tipo te,
         siac_t_periodo pe
    WHERE  c.cronop_id =cronop_id_in
    AND    c.cronop_id = ce.cronop_id
    AND    ce.cronop_elem_id = ced.cronop_elem_id
    AND    ced.periodo_id = pe.periodo_id
    AND    ce.elem_tipo_id = te.elem_tipo_id
    AND    te.elem_tipo_code = 'CAP-EP'
    AND    pe.anno::INTEGER = anno_ciclo
    AND    c.data_cancellazione IS NULL
    AND    ce.data_cancellazione IS NULL
    AND    ced.data_cancellazione IS NULL
    AND    te.data_cancellazione IS NULL
    AND    pe.data_cancellazione IS NULL; 

    fpv_spesa := v_entrata_per_anno - v_tot_spesa_previstaanno + v_fpv_spesa_annoprec;

     insert into temp_fpv_spesa (
       tmp_missione        
      ,tmp_programma       
      ,tmp_titolo          
      ,tmp_anno_out        
      ,tmp_spesa_prevista  
      ,tmp_fpv_spesa       
     )VALUES(
       null
      ,null
      ,null
      ,anno_ciclo
      ,v_tot_spesa_previstaanno
      ,fpv_spesa     
     );

	raise notice '% - % + % = %', v_entrata_per_anno, v_tot_spesa_previstaanno, v_fpv_spesa_annoprec, fpv_spesa;
    v_fpv_spesa_annoprec := fpv_spesa;
    
    anno_ciclo := anno_ciclo + 1;

  END LOOP;
  
    FOR rec_out IN
      select tmp_missione        
      ,tmp_programma       
      ,tmp_titolo          
      ,tmp_anno_out              
      ,tmp_fpv_spesa       
      ,sum(tmp_spesa_prevista)  tmp_spesa_prevista
      from 
      	temp_fpv_spesa
	  group by
         tmp_anno_out  
       	,tmp_missione        
      	,tmp_programma       
      	,tmp_titolo      
      	,tmp_fpv_spesa
      order by 	
      	 tmp_anno_out  
       	,tmp_missione        
      	,tmp_programma       
      	,tmp_titolo          
        	
     LOOP

		missione		 	:= rec_out.tmp_missione;
    	programma		 	:= rec_out.tmp_programma;
    	titolo		     	:= rec_out.tmp_titolo;
    	anno_out		 	:= rec_out.tmp_anno_out;
    	spesa_prevista   	:= rec_out.tmp_spesa_prevista;
    	fpv_spesa		 	:= rec_out.tmp_fpv_spesa;
		RETURN NEXT;
        
  	END loop;
	
	DROP TABLE temp_fpv_spesa;
  
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