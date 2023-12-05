/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) select 'OP-SPE-aggiornaImpegnoGsa', 'Aggiornamento dati inoltro a gsa per impegno', ta.azione_tipo_id, ga.gruppo_azioni_id,
 '/../siacfinapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'),
 e.ente_proprietario_id, 'admin'
  from siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
  where  ta.ente_proprietario_id = e.ente_proprietario_id
  and ga.ente_proprietario_id = e.ente_proprietario_id
  and ta.azione_tipo_code = 'AZIONE_SECONDARIA'
  and ga.gruppo_azioni_code = 'FIN_BASE1'
  and not exists (select 1 from siac_t_azione z where z.azione_tipo_id=ta.azione_tipo_id
  and z.azione_code='OP-SPE-aggiornaImpegnoGsa')
  ;
  
  INSERT INTO
  siac.siac_t_azione
(
  azione_code,
  azione_desc,
  azione_tipo_id,
  gruppo_azioni_id,
  urlapplicazione,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
) select 'OP-ENT-aggiornaAccertamentoGsa', 'Aggiornamento dati inoltro a gsa per accertamento', ta.azione_tipo_id, ga.gruppo_azioni_id,
 '/../siacfinapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'),
 e.ente_proprietario_id, 'admin'
  from siac_d_azione_tipo ta, siac_d_gruppo_azioni ga, siac_t_ente_proprietario e
  where  ta.ente_proprietario_id = e.ente_proprietario_id
  and ga.ente_proprietario_id = e.ente_proprietario_id
  and ta.azione_tipo_code = 'AZIONE_SECONDARIA'
  and ga.gruppo_azioni_code = 'FIN_BASE1'
  and not exists (select 1 from siac_t_azione z where z.azione_tipo_id=ta.azione_tipo_id
  and z.azione_code='OP-ENT-aggiornaAccertamentoGsa')
  ;
  
  --SIAC-5320
  --SIAC-5396
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



DROP FUNCTION IF EXISTS siac.fnc_siac_fpv_entrata_previsione( INTEGER, VARCHAR ) ;
DROP FUNCTION IF EXISTS siac.fnc_siac_fpv_entrata_previsione( INTEGER ) ;

 CREATE OR replace FUNCTION siac.fnc_siac_fpv_entrata_previsione ( cronop_id_in  INTEGER) 
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
      AND    te.elem_tipo_code = 'CAP-EP'
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
                    AND    te.elem_tipo_code = 'CAP-UP'
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
                    AND    te.elem_tipo_code = 'CAP-UP'
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
  
-- fINE siac-5320
  
  -- SIAC-5119 - CR 592 - e SIAC-5382 INIZIO - Maurizio

UPDATE siac_t_azione
SET urlapplicazione = '/../siacrepapp/azioneRichiesta.do'
WHERE azione_code = 'OP-GEN-stampe-utilityGSA';


CREATE OR REPLACE FUNCTION siac."BILR167_registrazioni_stato_notificato_entrate" (
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_ambito varchar,
  p_tipo_evento varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_anno_capitolo varchar,
  p_num_capitolo varchar,
  p_code_soggetto varchar,
  p_cod_conto_fin varchar
)
RETURNS TABLE (
  pdce_conto_fin_code varchar,
  pdce_conto_fin_desc varchar,
  pdce_conto_fin_code_agg varchar,
  pdce_conto_fin_desc_agg varchar,
  bil_elem_code varchar,
  bil_elem_code2 varchar,
  bil_elem_code3 varchar,
  anno_bil_elem varchar,
  evento_code varchar,
  evento_tipo_code varchar,
  tipo_coll_code varchar,
  ambito_code varchar,
  data_registrazione date,
  numero_movimento varchar,
  anno_movimento varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  display_error varchar,
  regmovfin_id integer
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;
sql_query VARCHAR;
contaDate INTEGER;
contaDatiCap INTEGER;
cod_soggetto_verif VARCHAR;
cod_pdce_verif VARCHAR;

BEGIN
  RTN_MESSAGGIO:='select 1';
    
  
  /* QUESTA PROCEDURA e' richiamata oltre che dal report BILR167
  		anche dal BILR168 */
          
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

display_error:='';
contaDate:=0;
contaDatiCap:=0;

if p_data_reg_da IS NOT NULL THEN
	contaDate = contaDate+1;
end if;
if p_data_reg_a IS NOT NULL THEN
	contaDate = contaDate+1;
end if;   

if contaDate = 1 THEN
	display_error:='OCCORRE SPECIFICARE ENTRAMBE LE DATE DELL''INTERVALLO ''DATA REGISTRAZIONE DA'' / ''DATA REGISTRAZIONE A''';
    return next;
    return;
end if;

if p_anno_capitolo is not null AND p_anno_capitolo <> '' THEN
	contaDatiCap:=contaDatiCap+1;
end if;
if p_num_capitolo is not null AND p_num_capitolo <> '' THEN
	contaDatiCap:=contaDatiCap+1;
end if;
if contaDatiCap = 1 THEN
	display_error:='OCCORRE SPECIFICARE SIA L''ANNO CHE IL NUMERO DEL CAPITOLO';
    return next;
    return;
end if;

if p_anno_capitolo is not null AND p_anno_capitolo <> '' AND	
	p_anno_capitolo <> p_anno_bilancio THEN
    display_error:='L''ANNO DEL CAPITOLO DEVE ESSERE IDENTICO A QUELLO DEL BILANCIO.';
    return next;
    return;
end if;
if p_code_soggetto is not null and p_code_soggetto <> '' THEN
	cod_soggetto_verif:='';
	select a.soggetto_code
    	into cod_soggetto_verif
    from siac_t_soggetto a
    where a.soggetto_code=trim(p_code_soggetto)
    	and a.ente_proprietario_id =p_ente_proprietario_id
    	and a.data_cancellazione is null;
    IF NOT FOUND THEN
		select a.soggetto_classe_code
    		into cod_soggetto_verif
    	from siac_d_soggetto_classe a
    	where a.soggetto_classe_code=trim(p_code_soggetto)
        	and a.ente_proprietario_id =p_ente_proprietario_id
    		and a.data_cancellazione is null;
    	IF NOT FOUND THEN
        	display_error:='IL CODICE SOGGETTO INDICATO NON ESISTE.';
    		return next;
    		return;
        end if;
    END IF;
end if;
if p_ambito ='AMBITO_FIN' AND 
	(p_cod_conto_fin is not null and p_cod_conto_fin <> '') then
    	cod_pdce_verif:='';
        select t_class.classif_code
        into cod_pdce_verif
        from siac_t_class t_class,
        	siac_d_class_tipo d_class_tipo
        where d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
        and t_class.ente_proprietario_id=p_ente_proprietario_id
        and t_class.classif_code=p_cod_conto_fin
        and d_class_tipo.classif_tipo_code like 'PDC_%';
    IF NOT FOUND THEN
    	display_error:='IL CODICE CONTO FINANZIARIO INDICATO NON ESISTE.';
    	return next;
    	return;
    end if;
    
end if;
    
/*
Possibili ambiti: AMBITO_GSA o AMBITO_FIN
*/
sql_query= '
 -- return query
  select zz.* from (
  with capall as(
 with cap as (
  select cl.classif_id,
  anno_eserc.anno anno_cap,
  e.*
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	''CATEGORIA''
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id			=	'||p_ente_proprietario_id||'
and anno_eserc.anno					= 	'''||p_anno_bilancio||'''
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	''CAP-EG''
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	''VA''
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	''STD''
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
  ), 
  dati_registro_mov as(
  WITH registro_mov AS (
  select 
  	d_ambito.ambito_code, d_evento.evento_code , d_evento_tipo.evento_tipo_code,
 	d_reg_movfin_stato.regmovfin_stato_code,
  	t_reg_movfin.data_creazione data_registrazione,
    d_coll_tipo.collegamento_tipo_code,d_coll_tipo.collegamento_tipo_desc,  
    t_reg_movfin.*,t_class.classif_code pdce_conto_fin_code, 
    t_class.classif_desc pdce_conto_fin_desc,
    t_class2.classif_code pdce_conto_fin_code_agg, 
    t_class2.classif_desc pdce_conto_fin_desc_agg,
    r_ev_reg_movfin.campo_pk_id, r_ev_reg_movfin.campo_pk_id_2
from siac_t_reg_movfin t_reg_movfin
		LEFT JOIN siac_t_class t_class
        	ON (t_class.classif_id= t_reg_movfin.classif_id_iniziale
            	AND t_class.data_cancellazione IS NULL)
		LEFT JOIN siac_t_class t_class2
        	ON (t_class2.classif_id= t_reg_movfin.classif_id_aggiornato
            	AND t_class2.data_cancellazione IS NULL),            
	siac_r_reg_movfin_stato r_reg_movfin_stato,
    siac_d_reg_movfin_stato d_reg_movfin_stato, 
    siac_d_ambito d_ambito,
    siac_r_evento_reg_movfin r_ev_reg_movfin,
    siac_d_evento d_evento,
    siac_d_evento_tipo d_evento_tipo,
    siac_d_collegamento_tipo d_coll_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where t_reg_movfin.regmovfin_id= r_reg_movfin_stato.regmovfin_id
and r_reg_movfin_stato.regmovfin_stato_id=d_reg_movfin_stato.regmovfin_stato_id
and d_ambito.ambito_id=t_reg_movfin.ambito_id
and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
and r_ev_reg_movfin.regmovfin_id=t_reg_movfin.regmovfin_id
and d_evento.evento_id=r_ev_reg_movfin.evento_id
and d_evento_tipo.evento_tipo_id=d_evento.evento_tipo_id
and t_reg_movfin.bil_id=t_bil.bil_id
and t_bil.periodo_id=t_periodo.periodo_id
and t_reg_movfin.ente_proprietario_id='||p_ente_proprietario_id||'
and t_periodo.anno='''||p_anno_bilancio||'''
and d_reg_movfin_stato.regmovfin_stato_code=''N'' --Notificato
and d_ambito.ambito_code = '''||p_ambito||''' 
and d_evento_tipo.evento_tipo_code ='''||p_tipo_evento||''' ';
if contaDate = 2 THEN  --inserito filtro sulle date.
	sql_query=sql_query|| ' and date_trunc(''day'',t_reg_movfin.data_creazione) between '''||p_data_reg_da||''' and '''||p_data_reg_a||''' ';
end if;
sql_query=sql_query||' and t_reg_movfin.data_cancellazione IS NULL   
and r_reg_movfin_stato.data_cancellazione IS NULL
and d_reg_movfin_stato.data_cancellazione IS NULL
and d_ambito.data_cancellazione IS NULL
and r_ev_reg_movfin.data_cancellazione IS NULL
and d_evento.data_cancellazione IS NULL
and d_coll_tipo.data_cancellazione IS NULL
and t_bil.data_cancellazione IS NULL
and t_periodo.data_cancellazione IS NULL
and d_evento_tipo.data_cancellazione IS NULL
  ),  
  collegamento_MMGS_MMGE_a AS ( 
  SELECT DISTINCT rmbe.elem_id, tm.mod_id,
  		movgest.movgest_anno anno_movimento, 
        movgest.movgest_numero numero_movimento,
        r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, 
        siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
        siac_r_movgest_bil_elem rmbe, siac_t_movgest movgest
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND 	movgest.movgest_id=tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND 	movgest.data_cancellazione IS NULL
  ), 
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id, 
  		movgest.movgest_anno anno_movimento, 
        movgest.movgest_numero numero_movimento,
        r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, 
        siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),                     
        siac_r_movgest_bil_elem rmbe, siac_t_movgest movgest
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND 	movgest.movgest_id=tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND 	movgest.data_cancellazione IS NULL
  ), 
  collegamento_I_A AS (
  SELECT DISTINCT a.elem_id, a.movgest_id, 
  b.movgest_anno anno_movimento, b.movgest_numero numero_movimento,
  		r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM   siac_r_movgest_bil_elem a, siac_t_movgest b,
  		siac_d_movgest_ts_tipo movgest_ts_tipo,
  		siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL)                
  WHERE  a.movgest_id=b.movgest_id
  AND	 b.movgest_id = tmt.movgest_id
  AND 	 tmt.movgest_ts_tipo_id = movgest_ts_tipo.movgest_ts_tipo_id
  AND    a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND 	 movgest_ts_tipo.movgest_ts_tipo_code=''T''
  AND    a.data_cancellazione IS NULL
  AND  	 b.data_cancellazione IS NULL
  AND	 movgest_ts_tipo.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id,
  	c.movgest_anno anno_movimento, 
     --12/10/2017: in caso di SUB aggiunto anche il codice al numero impegno
    c.movgest_numero||'' - ''||a.movgest_ts_code numero_movimento,
    r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_movgest_ts a
  		LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=a.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
        LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=a.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  	siac_r_movgest_bil_elem b, siac_t_movgest c
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_id = b.movgest_id
  AND   a.movgest_id = c.movgest_id
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  AND  	c.data_cancellazione IS NULL
  ), 
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, a.subdoc_id,  
  t_doc.doc_anno anno_movimento, 
  t_doc.doc_numero||''-''||t_subdoc.subdoc_numero numero_movimento,
  r_doc_sog.soggetto_id
  FROM   siac_r_subdoc_movgest_ts a, 
  	siac_t_movgest_ts b, siac_r_movgest_bil_elem c,
    siac_t_subdoc t_subdoc,    	
    siac_t_doc t_doc
    	LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	 AND r_doc_sog.data_cancellazione IS NULL)
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  and 	 a.subdoc_id = t_subdoc.subdoc_id
  and 	 t_subdoc.doc_id = t_doc.doc_id ';
 
  /* 	Si deve testare la data di fine validita' perche' (da mail di Irene):
     "a causa della doppia gestione che purtroppo non e' stata implementata sui documenti!!!! 
     E' stato trovato questo escamotage per cui la relazione 2016 viene chiusa con una
data dell''anno nuovo (in questo caso 2017) e viene creata quella nuova del 2017
(quella che tra l''altro vediamo da sistema anche sul 2016).
Per cui l''unica soluzione e' recuperare nella tabella r_subdoc_movgest_ts  la
relazione 2016 che troverai non piu' valida."
  */ 
sql_query = sql_query || '
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND	 t_subdoc.data_cancellazione IS NULL
  AND	 t_doc.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id,
  	t_ord.ord_anno anno_movimento, t_ord.ord_numero numero_movimento,
    siac_r_ordinativo_soggetto.soggetto_id
  FROM   siac_r_ordinativo_bil_elem a, 
  	siac_t_ordinativo t_ord
    	LEFT JOIN siac_r_ordinativo_soggetto
        	ON (siac_r_ordinativo_soggetto.ord_id=t_ord.ord_id
                	 AND   siac_r_ordinativo_soggetto.data_cancellazione IS NULL)
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND 	 t_ord.ord_id = a.ord_id
  AND    a.data_cancellazione IS NULL
  AND    t_ord.data_cancellazione IS NULL  
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id,
    	t_liq.liq_anno anno_movimento, t_liq.liq_numero numero_movimento,
        r_liq_sogg.soggetto_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, 
  siac_r_movgest_bil_elem c, 
  siac_t_liquidazione t_liq
  		LEFT JOIN siac_r_liquidazione_soggetto r_liq_sogg
        	ON (r_liq_sogg.liq_id = t_liq.liq_id
            	AND r_liq_sogg.data_cancellazione IS NULL)
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND 	 t_liq.liq_id = a.liq_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND	 t_liq.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id,
  	movgest.movgest_anno anno_movimento, movgest.movgest_numero numero_movimento,
    r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, 
  siac_t_movgest_ts c
  		LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=c.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
        LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=c.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  siac_r_movgest_bil_elem d, siac_t_movgest movgest
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.ricecon_id = b.ricecon_id
  AND   b.movgest_ts_id = c.movgest_ts_id
  AND   c.movgest_id = d.movgest_id
  AND	c.movgest_id = movgest.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   d.data_cancellazione  IS NULL
  AND   movgest.data_cancellazione  IS NULL
  ),
  collegamento_RE AS (
  SELECT DISTINCT c.elem_id, a.ricecon_id,
  movgest.movgest_anno anno_movimento, movgest.movgest_numero numero_movimento,
  r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_r_richiesta_econ_movgest a, 
  	siac_t_movgest_ts b
    	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=b.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
    	LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=b.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  	siac_r_movgest_bil_elem c, siac_t_movgest movgest
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND	b.movgest_id = movgest.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   movgest.data_cancellazione  IS NULL
  ),
  /* NOTE DI CREDITO
    In questo caso occorre prendere l''impegno del documento collegato e non quello della nota di 
    credito che non esiste */
  collegamento_SS_SE_NCD AS (  
  select c.elem_id, a.subdoc_id,
  t_doc.doc_anno anno_movimento, 
  t_doc.doc_numero||''-''||t_subdoc.subdoc_numero numero_movimento,
  r_doc_sog.soggetto_id
  from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, 
  siac_r_movgest_bil_elem c, siac_t_subdoc t_subdoc, 
  siac_t_doc t_doc
  	LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	 AND r_doc_sog.data_cancellazione IS NULL)
  where a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  and 	 a.subdoc_id = t_subdoc.subdoc_id
  and 	 t_subdoc.doc_id = t_doc.doc_id
  AND b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND	 t_subdoc.data_cancellazione IS NULL
  AND	 t_doc.data_cancellazione IS NULL
  )
  SELECT 
  registro_mov.pdce_conto_fin_code,
  registro_mov.pdce_conto_fin_desc,
  registro_mov.pdce_conto_fin_code_agg,
  registro_mov.pdce_conto_fin_desc_agg,  
  registro_mov.evento_code,registro_mov.evento_tipo_code,
  registro_mov.ambito_code,registro_mov.data_registrazione,
  registro_mov.collegamento_tipo_code,
  registro_mov.regmovfin_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id), collegamento_SS_SE_NCD.elem_id) elem_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.numero_movimento::varchar,collegamento_MMGS_MMGE_b.numero_movimento::varchar),collegamento_I_A.numero_movimento::varchar),collegamento_SI_SA.numero_movimento::varchar),collegamento_SS_SE.numero_movimento::varchar),collegamento_OP_OI.numero_movimento::varchar),collegamento_L.numero_movimento::varchar),collegamento_RR.numero_movimento::varchar),collegamento_RE.numero_movimento::varchar),collegamento_SS_SE_NCD.numero_movimento::varchar),'''') numero_movimento,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.anno_movimento::varchar,collegamento_MMGS_MMGE_b.anno_movimento::varchar),collegamento_I_A.anno_movimento::varchar),collegamento_SI_SA.anno_movimento::varchar),collegamento_SS_SE.anno_movimento::varchar),collegamento_OP_OI.anno_movimento::varchar),collegamento_L.anno_movimento::varchar),collegamento_RR.anno_movimento::varchar),collegamento_RE.anno_movimento::varchar),collegamento_SS_SE_NCD.numero_movimento::varchar),'''') anno_movimento,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.soggetto_id,collegamento_MMGS_MMGE_b.soggetto_id), collegamento_I_A.soggetto_id),collegamento_SI_SA.soggetto_id),collegamento_SS_SE.soggetto_id),collegamento_OP_OI.soggetto_id),collegamento_L.soggetto_id),collegamento_RR.soggetto_id),collegamento_RE.soggetto_id),collegamento_SS_SE_NCD.soggetto_id),0) soggetto_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.soggetto_classe_id,collegamento_MMGS_MMGE_b.soggetto_classe_id), collegamento_I_A.soggetto_classe_id),collegamento_SI_SA.soggetto_classe_id),collegamento_RR.soggetto_classe_id),collegamento_RE.soggetto_classe_id), 0) soggetto_classe_id
  FROM   registro_mov
  	-- ModificaMovimentoGestioneSpesa O ModificaMovimentoGestioneEntrata
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''MMGS'',''MMGE'') 
  	-- ModificaMovimentoGestioneSpesa O ModificaMovimentoGestioneEntrata
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''MMGS'',''MMGE'')
    -- Impegno o Accertamento                                   
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''I'',''A'')
	-- SubImpegno o SubAccertamento
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''SI'',''SA'')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''SS'',''SE'')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''OP'',''OI'')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''L''
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''RR''
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''RE''
  --20/09/2017: collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = registro_mov.campo_pk_id_2
  										AND registro_mov.collegamento_tipo_code IN (''SS'',''SE'')                                       
  ) ,
  elenco_soggetti as (
  	select t_sogg.soggetto_id, t_sogg.soggetto_code, t_sogg.soggetto_desc
		from siac_t_soggetto t_sogg
        where t_sogg.ente_proprietario_id ='||p_ente_proprietario_id||'
		and t_sogg.data_cancellazione IS NULL
  ) ,
    elenco_soggetti_classe as (
  	select d_sogg_classe.soggetto_classe_id, d_sogg_classe.soggetto_classe_code, 
    	d_sogg_classe.soggetto_classe_desc
		from siac_d_soggetto_classe d_sogg_classe
        where d_sogg_classe.ente_proprietario_id ='||p_ente_proprietario_id||'
		and d_sogg_classe.data_cancellazione IS NULL
  )                    
  select
  cap.elem_id bil_ele_id,
  cap.elem_code bil_ele_code,
  cap.elem_desc bil_ele_desc,
  cap.elem_code2 bil_ele_code2,
  cap.elem_desc2 bil_ele_desc2,
  cap.elem_id_padre bil_ele_id_padre,
  cap.elem_code3 bil_ele_code3,
  cap.anno_cap,
  dati_registro_mov.*,
  elenco_soggetti.*,
  elenco_soggetti_classe.*
  from dati_registro_mov 
  	left join cap on cap.elem_id = dati_registro_mov.elem_id  
    left join elenco_soggetti on elenco_soggetti.soggetto_id = dati_registro_mov.soggetto_id
    left join elenco_soggetti_classe on elenco_soggetti_classe.soggetto_classe_id = dati_registro_mov.soggetto_classe_id    
  )
  select DISTINCT
      COALESCE(capall.pdce_conto_fin_code,'''')::VARCHAR,
      COALESCE(capall.pdce_conto_fin_desc,'''')::VARCHAR,   
      CASE WHEN capall.pdce_conto_fin_code_agg = capall.pdce_conto_fin_code
      	THEN ''''::VARCHAR
        ELSE COALESCE(capall.pdce_conto_fin_code_agg,'''')::VARCHAR END pdce_conto_fin_code_agg,
      CASE WHEN capall.pdce_conto_fin_desc_agg = capall.pdce_conto_fin_desc
      THEN ''''::VARCHAR
        ELSE COALESCE(capall.pdce_conto_fin_desc_agg,'''')::VARCHAR END pdce_conto_fin_desc_agg,
      COALESCE(capall.bil_ele_code,'''')::VARCHAR,
      COALESCE(capall.bil_ele_code2,'''')::VARCHAR,
      COALESCE(capall.bil_ele_code3,'''')::VARCHAR,
      COALESCE(capall.anno_cap,'''')::VARCHAR,
      capall.evento_code::VARCHAR,
      capall.evento_tipo_code::VARCHAR,
      capall.collegamento_tipo_code::VARCHAR,
      capall.ambito_code::VARCHAR,
      capall.data_registrazione::DATE,
      capall.numero_movimento::VARCHAR,
      capall.anno_movimento::VARCHAR,
      CASE WHEN capall.soggetto_code IS NULL
      	THEN capall.soggetto_classe_code::VARCHAR
        ELSE capall.soggetto_code::VARCHAR END soggetto_code,
      CASE WHEN capall.soggetto_desc IS NULL
      	THEN capall.soggetto_classe_desc::VARCHAR
        ELSE capall.soggetto_desc::VARCHAR END soggetto_desc,
      ''''::VARCHAR,
      capall.regmovfin_id
     from capall ';
     /* se sono stati specificati i parametri per capitolo, soggetto e
     	pdce, inserisco le condizioni */
    if contaDatiCap = 2 THEN
    	sql_query = sql_query || ' where capall.anno_cap ='''||p_anno_capitolo|| '''
        	and capall.bil_ele_code ='''||p_num_capitolo|| '''';
 	end if;
    if p_code_soggetto is not null  and p_code_soggetto <> '' THEN
    	 if contaDatiCap = 2 THEN
         	sql_query = sql_query || ' AND (capall.soggetto_code = '''||p_code_soggetto||'''
            	OR capall.soggetto_classe_code = '''||p_code_soggetto||''')';
         else
         	sql_query = sql_query || ' WHERE (capall.soggetto_code = '''||p_code_soggetto||'''
            	OR capall.soggetto_classe_code = '''||p_code_soggetto||''')';
         end if;         
    end if;
    if p_cod_conto_fin is not null  and p_cod_conto_fin <> '' THEN
    	if contaDatiCap = 2 OR 
        	(p_code_soggetto is not null  and p_code_soggetto <> '') THEN
            	sql_query = sql_query || ' AND capall.pdce_conto_fin_code ='''||p_cod_conto_fin||''' ';
    	else
        		sql_query = sql_query || ' WHERE capall.pdce_conto_fin_code ='''||p_cod_conto_fin||''' ';
    	end if;
    end if;
    
    sql_query = sql_query || ' ) as zz; ';

raise notice 'sql_query = %', sql_query;
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

CREATE OR REPLACE FUNCTION siac."BILR167_registrazioni_stato_notificato_spese" (
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_ambito varchar,
  p_tipo_evento varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_anno_capitolo varchar,
  p_num_capitolo varchar,
  p_code_soggetto varchar,
  p_cod_conto_fin varchar
)
RETURNS TABLE (
  pdce_conto_fin_code varchar,
  pdce_conto_fin_desc varchar,
  pdce_conto_fin_code_agg varchar,
  pdce_conto_fin_desc_agg varchar,
  bil_elem_code varchar,
  bil_elem_code2 varchar,
  bil_elem_code3 varchar,
  anno_bil_elem varchar,
  evento_code varchar,
  evento_tipo_code varchar,
  tipo_coll_code varchar,
  ambito_code varchar,
  data_registrazione date,
  numero_movimento varchar,
  anno_movimento varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  display_error varchar,
  regmovfin_id integer
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;
sql_query VARCHAR;
contaDate INTEGER;
contaDatiCap INTEGER;
cod_soggetto_verif VARCHAR;
cod_pdce_verif VARCHAR;

BEGIN
  RTN_MESSAGGIO:='select 1';
  
  /* QUESTA PROCEDURA e' richiamata oltre che dal report BILR167
  		anche dal BILR168 */
    
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

display_error:='';
contaDate:=0;
contaDatiCap:=0;

if p_data_reg_da IS NOT NULL THEN
	contaDate = contaDate+1;
end if;
if p_data_reg_a IS NOT NULL THEN
	contaDate = contaDate+1;
end if;   

if contaDate = 1 THEN
	display_error:='OCCORRE SPECIFICARE ENTRAMBE LE DATE DELL''INTERVALLO ''DATA REGISTRAZIONE DA'' / ''DATA REGISTRAZIONE A''';
    return next;
    return;
end if;

if p_anno_capitolo is not null AND p_anno_capitolo <> '' THEN
	contaDatiCap:=contaDatiCap+1;
end if;
if p_num_capitolo is not null AND p_num_capitolo <> '' THEN
	contaDatiCap:=contaDatiCap+1;
end if;
if contaDatiCap = 1 THEN
	display_error:='OCCORRE SPECIFICARE SIA L''ANNO CHE IL NUMERO DEL CAPITOLO';
    return next;
    return;
end if;

if p_anno_capitolo is not null AND p_anno_capitolo <> '' AND	
	p_anno_capitolo <> p_anno_bilancio THEN
    display_error:='L''ANNO DEL CAPITOLO DEVE ESSERE IDENTICO A QUELLO DEL BILANCIO.';
    return next;
    return;
end if;
if p_code_soggetto is not null and p_code_soggetto <> '' THEN
	cod_soggetto_verif:='';
	select a.soggetto_code
    	into cod_soggetto_verif
    from siac_t_soggetto a
    where a.soggetto_code=trim(p_code_soggetto)
    	and a.ente_proprietario_id =p_ente_proprietario_id
    	and a.data_cancellazione is null;
    IF NOT FOUND THEN
		select a.soggetto_classe_code
    		into cod_soggetto_verif
    	from siac_d_soggetto_classe a
    	where a.soggetto_classe_code=trim(p_code_soggetto)
        	and a.ente_proprietario_id =p_ente_proprietario_id
    		and a.data_cancellazione is null;
    	IF NOT FOUND THEN
        	display_error:='IL CODICE SOGGETTO INDICATO NON ESISTE.';
    		return next;
    		return;
        end if;
    END IF;
end if;
if p_ambito ='AMBITO_FIN' AND 
	(p_cod_conto_fin is not null and p_cod_conto_fin <> '') then
    	cod_pdce_verif:='';
        select t_class.classif_code
        into cod_pdce_verif
        from siac_t_class t_class,
        	siac_d_class_tipo d_class_tipo
        where d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
        and t_class.ente_proprietario_id=p_ente_proprietario_id
        and t_class.classif_code=p_cod_conto_fin
        and d_class_tipo.classif_tipo_code like 'PDC_%';
    IF NOT FOUND THEN
    	display_error:='IL CODICE CONTO FINANZIARIO INDICATO NON ESISTE.';
    	return next;
    	return;
    end if;
    
end if;
/*
Possibili ambiti: AMBITO_GSA o AMBITO_FIN
*/
sql_query= '
 -- return query
  select zz.* from (
  with capall as(
 with cap as (
  select a.elem_id,
  a.elem_code ,
  a.elem_desc ,
  a.elem_code2 ,
  a.elem_desc2 ,
  a.elem_id_padre ,
  a.elem_code3,
  d.classif_id programma_id,d2.classif_id macroag_id, t_periodo.anno anno_cap
  from siac_t_bil_elem a,siac_d_bil_elem_tipo b, siac_r_bil_elem_class c,
  siac_r_bil_elem_class c2,
  siac_t_class d,siac_t_class d2,
  siac_d_class_tipo e,siac_d_class_tipo e2, siac_r_bil_elem_categoria f, 
  siac_d_bil_elem_categoria g,siac_r_bil_elem_stato h,siac_d_bil_elem_stato i,
  siac_t_bil t_bil, siac_t_periodo t_periodo
  where a.ente_proprietario_id='||p_ente_proprietario_id||'
  and a.bil_id='||bilancio_id||'
  and a.bil_id=t_bil.bil_id
  and t_bil.periodo_id=t_periodo.periodo_id
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
  dati_registro_mov as(
  WITH registro_mov AS (
  select 
  	d_ambito.ambito_code, d_evento.evento_code , d_evento_tipo.evento_tipo_code,
 	d_reg_movfin_stato.regmovfin_stato_code,
  	t_reg_movfin.data_creazione data_registrazione,
    d_coll_tipo.collegamento_tipo_code,d_coll_tipo.collegamento_tipo_desc,  
    t_reg_movfin.*,t_class.classif_code pdce_conto_fin_code, 
    t_class.classif_desc pdce_conto_fin_desc,
    t_class2.classif_code pdce_conto_fin_code_agg, 
    t_class2.classif_desc pdce_conto_fin_desc_agg,
    r_ev_reg_movfin.campo_pk_id, r_ev_reg_movfin.campo_pk_id_2
from siac_t_reg_movfin t_reg_movfin
		LEFT JOIN siac_t_class t_class
        	ON (t_class.classif_id= t_reg_movfin.classif_id_iniziale
            	AND t_class.data_cancellazione IS NULL)
		LEFT JOIN siac_t_class t_class2
        	ON (t_class2.classif_id= t_reg_movfin.classif_id_aggiornato
            	AND t_class2.data_cancellazione IS NULL),            
	siac_r_reg_movfin_stato r_reg_movfin_stato,
    siac_d_reg_movfin_stato d_reg_movfin_stato, 
    siac_d_ambito d_ambito,
    siac_r_evento_reg_movfin r_ev_reg_movfin,
    siac_d_evento d_evento,
    siac_d_evento_tipo d_evento_tipo,
    siac_d_collegamento_tipo d_coll_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where t_reg_movfin.regmovfin_id= r_reg_movfin_stato.regmovfin_id
and r_reg_movfin_stato.regmovfin_stato_id=d_reg_movfin_stato.regmovfin_stato_id
and d_ambito.ambito_id=t_reg_movfin.ambito_id
and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
and r_ev_reg_movfin.regmovfin_id=t_reg_movfin.regmovfin_id
and d_evento.evento_id=r_ev_reg_movfin.evento_id
and d_evento_tipo.evento_tipo_id=d_evento.evento_tipo_id
and t_reg_movfin.bil_id=t_bil.bil_id
and t_bil.periodo_id=t_periodo.periodo_id
and t_reg_movfin.ente_proprietario_id='||p_ente_proprietario_id||'
and t_periodo.anno='''||p_anno_bilancio||'''
and d_reg_movfin_stato.regmovfin_stato_code=''N'' --Notificato
and d_ambito.ambito_code = '''||p_ambito||'''
and d_evento_tipo.evento_tipo_code ='''||p_tipo_evento||''' ';
if contaDate = 2 THEN  --inserito filtro sulle date.
	sql_query=sql_query|| ' and date_trunc(''day'',t_reg_movfin.data_creazione) between '''||p_data_reg_da||''' and '''||p_data_reg_a||''' ';
end if;
sql_query=sql_query||' and t_reg_movfin.data_cancellazione IS NULL   
and r_reg_movfin_stato.data_cancellazione IS NULL
and d_reg_movfin_stato.data_cancellazione IS NULL
and d_ambito.data_cancellazione IS NULL
and r_ev_reg_movfin.data_cancellazione IS NULL
and d_evento.data_cancellazione IS NULL
and d_coll_tipo.data_cancellazione IS NULL
and t_bil.data_cancellazione IS NULL
and t_periodo.data_cancellazione IS NULL
and d_evento_tipo.data_cancellazione IS NULL
  ),  
  collegamento_MMGS_MMGE_a AS ( 
  SELECT DISTINCT rmbe.elem_id, tm.mod_id, 
  		movgest.movgest_anno anno_movimento, 
        movgest.movgest_numero numero_movimento,
        r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, 
        siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
        siac_r_movgest_bil_elem rmbe, siac_t_movgest movgest
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND 	movgest.movgest_id=tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND 	movgest.data_cancellazione IS NULL
  ), 
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id, 
  		movgest.movgest_anno anno_movimento, 
        movgest.movgest_numero numero_movimento,
        r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, 
        siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),                     
        siac_r_movgest_bil_elem rmbe, siac_t_movgest movgest
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND 	movgest.movgest_id=tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND 	movgest.data_cancellazione IS NULL
  ), 
  collegamento_I_A AS (
  SELECT DISTINCT a.elem_id, a.movgest_id, 
  b.movgest_anno anno_movimento, b.movgest_numero numero_movimento,
  		r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM   siac_r_movgest_bil_elem a, siac_t_movgest b,
  		siac_d_movgest_ts_tipo movgest_ts_tipo,
  		siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL)                
  WHERE  a.movgest_id=b.movgest_id
  AND	 b.movgest_id = tmt.movgest_id
  AND 	 tmt.movgest_ts_tipo_id = movgest_ts_tipo.movgest_ts_tipo_id
  AND    a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND 	 movgest_ts_tipo.movgest_ts_tipo_code=''T''
  AND    a.data_cancellazione IS NULL
  AND  	 b.data_cancellazione IS NULL
  AND	 movgest_ts_tipo.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id,
  	c.movgest_anno anno_movimento, 
    --12/10/2017: in caso di SUB aggiunto anche il codice al numero impegno
    c.movgest_numero||'' - ''||a.movgest_ts_code numero_movimento,
    r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_movgest_ts a
  		LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=a.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
        LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=a.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  	siac_r_movgest_bil_elem b, siac_t_movgest c
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_id = b.movgest_id
  AND   a.movgest_id = c.movgest_id
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  AND  	c.data_cancellazione IS NULL
  ), 
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, a.subdoc_id,  
  t_doc.doc_anno anno_movimento, 
  t_doc.doc_numero||''-''||t_subdoc.subdoc_numero numero_movimento,
  r_doc_sog.soggetto_id
  FROM   siac_r_subdoc_movgest_ts a, 
  	siac_t_movgest_ts b, siac_r_movgest_bil_elem c,
    siac_t_subdoc t_subdoc,    	
    siac_t_doc t_doc
    	LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	 AND r_doc_sog.data_cancellazione IS NULL)
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  and 	 a.subdoc_id = t_subdoc.subdoc_id
  and 	 t_subdoc.doc_id = t_doc.doc_id ';
 
  /* 	Si deve testare la data di fine validita' perche' (da mail di Irene):
     "a causa della doppia gestione che purtroppo non e' stata implementata sui documenti!!!! 
     E' stato trovato questo escamotage per cui la relazione 2016 viene chiusa con una
data dell''anno nuovo (in questo caso 2017) e viene creata quella nuova del 2017
(quella che tra l''altro vediamo da sistema anche sul 2016).
Per cui l''unica soluzione e' recuperare nella tabella r_subdoc_movgest_ts  la
relazione 2016 che troverai non piu' valida."
  */ 
sql_query = sql_query || '
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND	 t_subdoc.data_cancellazione IS NULL
  AND	 t_doc.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id,
  	t_ord.ord_anno anno_movimento, t_ord.ord_numero numero_movimento,
    siac_r_ordinativo_soggetto.soggetto_id
  FROM   siac_r_ordinativo_bil_elem a, 
  	siac_t_ordinativo t_ord
    	LEFT JOIN siac_r_ordinativo_soggetto
        	ON (siac_r_ordinativo_soggetto.ord_id=t_ord.ord_id
                	 AND   siac_r_ordinativo_soggetto.data_cancellazione IS NULL)
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND 	 t_ord.ord_id = a.ord_id
  AND    a.data_cancellazione IS NULL
  AND    t_ord.data_cancellazione IS NULL  
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id,
    	t_liq.liq_anno anno_movimento, t_liq.liq_numero numero_movimento,
        r_liq_sogg.soggetto_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, 
  siac_r_movgest_bil_elem c, 
  siac_t_liquidazione t_liq
  		LEFT JOIN siac_r_liquidazione_soggetto r_liq_sogg
        	ON (r_liq_sogg.liq_id = t_liq.liq_id
            	AND r_liq_sogg.data_cancellazione IS NULL)
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND 	 t_liq.liq_id = a.liq_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND	 t_liq.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id,
  	movgest.movgest_anno anno_movimento, movgest.movgest_numero numero_movimento,
    r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, 
  siac_t_movgest_ts c
  		LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=c.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
        LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=c.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  siac_r_movgest_bil_elem d, siac_t_movgest movgest
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.ricecon_id = b.ricecon_id
  AND   b.movgest_ts_id = c.movgest_ts_id
  AND   c.movgest_id = d.movgest_id
  AND	c.movgest_id = movgest.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   d.data_cancellazione  IS NULL
  AND   movgest.data_cancellazione  IS NULL
  ),
  collegamento_RE AS (
  SELECT DISTINCT c.elem_id, a.ricecon_id,
  movgest.movgest_anno anno_movimento, movgest.movgest_numero numero_movimento,
  r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_r_richiesta_econ_movgest a, 
  	siac_t_movgest_ts b
    	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=b.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
    	LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=b.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  	siac_r_movgest_bil_elem c, siac_t_movgest movgest
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND	b.movgest_id = movgest.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   movgest.data_cancellazione  IS NULL
  ),
  /* NOTE DI CREDITO
    In questo caso occorre prendere l''impegno del documento collegato e non quello della nota di 
    credito che non esiste */
  collegamento_SS_SE_NCD AS (  
  select c.elem_id, a.subdoc_id,
  t_doc.doc_anno anno_movimento, 
  t_doc.doc_numero||''-''||t_subdoc.subdoc_numero numero_movimento,
  r_doc_sog.soggetto_id
  from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, 
  siac_r_movgest_bil_elem c, siac_t_subdoc t_subdoc, 
  siac_t_doc t_doc
  	LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	 AND r_doc_sog.data_cancellazione IS NULL)
  where a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  and 	 a.subdoc_id = t_subdoc.subdoc_id
  and 	 t_subdoc.doc_id = t_doc.doc_id
  AND b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy'')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND	 t_subdoc.data_cancellazione IS NULL
  AND	 t_doc.data_cancellazione IS NULL
  )
  SELECT 
  registro_mov.pdce_conto_fin_code,
  registro_mov.pdce_conto_fin_desc,
  registro_mov.pdce_conto_fin_code_agg,
  registro_mov.pdce_conto_fin_desc_agg,  
  registro_mov.evento_code,registro_mov.evento_tipo_code,
  registro_mov.ambito_code,registro_mov.data_registrazione,
  registro_mov.collegamento_tipo_code,
  registro_mov.regmovfin_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id), collegamento_SS_SE_NCD.elem_id) elem_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.numero_movimento::varchar,collegamento_MMGS_MMGE_b.numero_movimento::varchar),collegamento_I_A.numero_movimento::varchar),collegamento_SI_SA.numero_movimento::varchar),collegamento_SS_SE.numero_movimento::varchar),collegamento_OP_OI.numero_movimento::varchar),collegamento_L.numero_movimento::varchar),collegamento_RR.numero_movimento::varchar),collegamento_RE.numero_movimento::varchar),collegamento_SS_SE_NCD.numero_movimento::varchar),'''') numero_movimento,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.anno_movimento::varchar,collegamento_MMGS_MMGE_b.anno_movimento::varchar),collegamento_I_A.anno_movimento::varchar),collegamento_SI_SA.anno_movimento::varchar),collegamento_SS_SE.anno_movimento::varchar),collegamento_OP_OI.anno_movimento::varchar),collegamento_L.anno_movimento::varchar),collegamento_RR.anno_movimento::varchar),collegamento_RE.anno_movimento::varchar),collegamento_SS_SE_NCD.numero_movimento::varchar),'''') anno_movimento,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.soggetto_id,collegamento_MMGS_MMGE_b.soggetto_id), collegamento_I_A.soggetto_id),collegamento_SI_SA.soggetto_id),collegamento_SS_SE.soggetto_id),collegamento_OP_OI.soggetto_id),collegamento_L.soggetto_id),collegamento_RR.soggetto_id),collegamento_RE.soggetto_id),collegamento_SS_SE_NCD.soggetto_id),0) soggetto_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.soggetto_classe_id,collegamento_MMGS_MMGE_b.soggetto_classe_id), collegamento_I_A.soggetto_classe_id),collegamento_SI_SA.soggetto_classe_id),collegamento_RR.soggetto_classe_id),collegamento_RE.soggetto_classe_id), 0) soggetto_classe_id
  FROM   registro_mov
  	-- ModificaMovimentoGestioneSpesa O ModificaMovimentoGestioneEntrata
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''MMGS'',''MMGE'') 
  	-- ModificaMovimentoGestioneSpesa O ModificaMovimentoGestioneEntrata
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''MMGS'',''MMGE'')
    -- Impegno o Accertamento                                   
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''I'',''A'')
	-- SubImpegno o SubAccertamento
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''SI'',''SA'')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''SS'',''SE'')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''OP'',''OI'')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''L''
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''RR''
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''RE''
  --20/09/2017: collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = registro_mov.campo_pk_id_2
  										AND registro_mov.collegamento_tipo_code IN (''SS'',''SE'')                                       
  ) ,
  elenco_soggetti as (
  	select t_sogg.soggetto_id, t_sogg.soggetto_code, t_sogg.soggetto_desc
		from siac_t_soggetto t_sogg
        where t_sogg.ente_proprietario_id ='||p_ente_proprietario_id||'
		and t_sogg.data_cancellazione IS NULL
  ) ,
    elenco_soggetti_classe as (
  	select d_sogg_classe.soggetto_classe_id, d_sogg_classe.soggetto_classe_code, 
    	d_sogg_classe.soggetto_classe_desc
		from siac_d_soggetto_classe d_sogg_classe
        where d_sogg_classe.ente_proprietario_id ='||p_ente_proprietario_id||'
		and d_sogg_classe.data_cancellazione IS NULL
  )                    
  select
  cap.elem_id bil_ele_id,
  cap.elem_code bil_ele_code,
  cap.elem_desc bil_ele_desc,
  cap.elem_code2 bil_ele_code2,
  cap.elem_desc2 bil_ele_desc2,
  cap.elem_id_padre bil_ele_id_padre,
  cap.elem_code3 bil_ele_code3,
  cap.programma_id,cap.macroag_id,cap.anno_cap,
  dati_registro_mov.*,
  elenco_soggetti.*,
  elenco_soggetti_classe.*
  from dati_registro_mov 
  	left join cap on cap.elem_id = dati_registro_mov.elem_id  
    left join elenco_soggetti on elenco_soggetti.soggetto_id = dati_registro_mov.soggetto_id
    left join elenco_soggetti_classe on elenco_soggetti_classe.soggetto_classe_id = dati_registro_mov.soggetto_classe_id    
  )
  select DISTINCT
      COALESCE(capall.pdce_conto_fin_code,'''')::VARCHAR,
      COALESCE(capall.pdce_conto_fin_desc,'''')::VARCHAR,   
	  CASE WHEN capall.pdce_conto_fin_code_agg = capall.pdce_conto_fin_code
      	THEN ''''::VARCHAR
        ELSE COALESCE(capall.pdce_conto_fin_code_agg,'''')::VARCHAR END pdce_conto_fin_code_agg,
      CASE WHEN capall.pdce_conto_fin_desc_agg = capall.pdce_conto_fin_desc
      THEN ''''::VARCHAR
        ELSE COALESCE(capall.pdce_conto_fin_desc_agg,'''')::VARCHAR END pdce_conto_fin_desc_agg,        
      COALESCE(capall.bil_ele_code,'''')::VARCHAR,
      COALESCE(capall.bil_ele_code2,'''')::VARCHAR,
      COALESCE(capall.bil_ele_code3,'''')::VARCHAR,
      COALESCE(capall.anno_cap,'''')::VARCHAR,
      capall.evento_code::VARCHAR,
      capall.evento_tipo_code::VARCHAR,
      capall.collegamento_tipo_code::VARCHAR,
      capall.ambito_code::VARCHAR,
      capall.data_registrazione::DATE,
      capall.numero_movimento::VARCHAR,
      capall.anno_movimento::VARCHAR,
      CASE WHEN capall.soggetto_code IS NULL
      	THEN capall.soggetto_classe_code::VARCHAR
        ELSE capall.soggetto_code::VARCHAR END soggetto_code,
      CASE WHEN capall.soggetto_desc IS NULL
      	THEN capall.soggetto_classe_desc::VARCHAR
        ELSE capall.soggetto_desc::VARCHAR END soggetto_desc,
      ''''::VARCHAR,
      capall.regmovfin_id::INTEGER
     from capall ';
    if contaDatiCap = 2 THEN
    	sql_query = sql_query || ' where capall.anno_cap ='''||p_anno_capitolo|| '''
        	and capall.bil_ele_code ='''||p_num_capitolo|| '''';
 	end if;
    if p_code_soggetto is not null  and p_code_soggetto <> '' THEN
    	 if contaDatiCap = 2 THEN
         	sql_query = sql_query || ' AND (capall.soggetto_code = '''||p_code_soggetto||'''
            	OR capall.soggetto_classe_code = '''||p_code_soggetto||''')';
         else
         	sql_query = sql_query || ' WHERE (capall.soggetto_code = '''||p_code_soggetto||'''
            	OR capall.soggetto_classe_code = '''||p_code_soggetto||''')';
         end if;         
    end if;
    if p_cod_conto_fin is not null  and p_cod_conto_fin <> '' THEN
    	if contaDatiCap = 2 OR 
        	(p_code_soggetto is not null  and p_code_soggetto <> '') THEN
            	sql_query = sql_query || ' AND capall.pdce_conto_fin_code ='''||p_cod_conto_fin||''' ';
    	else
        		sql_query = sql_query || ' WHERE capall.pdce_conto_fin_code ='''||p_cod_conto_fin||''' ';
    	end if;
    end if;
    
    sql_query = sql_query || ' ) as zz; ';

raise notice 'sql_query = %', sql_query;
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

-- SIAC-5119 - CR 592 - e SIAC-5382 FINE - Maurizio


-- SIAC-5255 - CR 982 - INIZIO - Maurizio

DROP FUNCTION siac."BILR089_elenco_accrediti_bancari"(p_ente_prop_id integer, p_anno varchar, p_cassaecon_id integer, p_data_da date, p_data_a date);

CREATE OR REPLACE FUNCTION siac."BILR089_elenco_accrediti_bancari" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_cassaecon_id integer,
  p_data_da date,
  p_data_a date
)
RETURNS TABLE (
  nome_ente varchar,
  anno_ese_finanz integer,
  benef_matricola varchar,
  benef_cognome varchar,
  benef_nome varchar,
  banca_iban varchar,
  num_sospeso integer,
  data_sospeso date,
  importo numeric,
  benef_fattura varchar,
  benef_cod_fisc_fattura varchar,
  benef_partita_iva_fattura varchar,
  benef_codice_fattura varchar,
  num_fattura varchar,
  tipo_richiesta_econ varchar,
  benef_ricecon_codice varchar,
  ricecon_tipo_desc varchar,
  num_movimento integer
) AS
$body$
DECLARE
elencoAccrediti record;
dati_giustif record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

anno_eser_int INTEGER;



BEGIN

nome_ente='';
anno_ese_finanz=0;
benef_matricola ='';
benef_cognome='';
benef_nome='';
banca_iban='';
num_sospeso=NULL;
data_sospeso=NULL;
importo=0;
benef_fattura='';
benef_cod_fisc_fattura='';
benef_partita_iva_fattura='';
benef_codice_fattura='';
num_fattura='';
tipo_richiesta_econ='';
benef_ricecon_codice:='';
ricecon_tipo_desc:='';
num_movimento:=0;

RTN_MESSAGGIO:='Estrazione dei dati degli accrediti bancari ''.';

raise notice 'Estrazione dei dati degli accrediti bancari';
raise notice 'ora: % ',clock_timestamp()::varchar;

anno_eser_int=p_anno :: INTEGER;


for elencoAccrediti in
select ente_prop.ente_denominazione,
	richiesta_econ.ricecon_codice_beneficiario,
	richiesta_econ.ricecon_codice_fiscale,
    richiesta_econ.ricecon_cognome,
    richiesta_econ.ricecon_nome,
    richiesta_econ.ricecon_matricola,
    richiesta_econ.ricecon_importo,
    richiesta_econ.ricecon_codice_beneficiario,
    richiesta_econ_sospesa.ricecons_numero num_sospeso,
    documento.doc_numero,
    documento.doc_anno,
    sub_documento.subdoc_numero,
    movimento.iban ,
    movimento.movt_pagamento_dettaglio,
    movimento.movt_data,
    movimento.gst_id,
    movimento.movt_numero,
    soggetto.codice_fiscale,
    soggetto.partita_iva,
    soggetto.soggetto_desc,
    soggetto.soggetto_code,  
    documento.doc_numero,
    anno_eserc.anno,
    richiesta_econ_tipo.ricecon_tipo_code,
    richiesta_econ_tipo.ricecon_tipo_desc,
    r_acc_tipo_cassa.cec_accredito_tipo_id
from siac_t_ente_proprietario				ente_prop,
	siac_t_movimento						movimento
    /* 30/03/2017: aggiunto il join con la tabella siac_r_accredito_tipo_cassa_econ
    	per filtrare le richieste che non sono pagate tramite assegno */
    	left join siac_r_accredito_tipo_cassa_econ r_acc_tipo_cassa
        	on (r_acc_tipo_cassa.cec_r_accredito_tipo_id=movimento.cec_r_accredito_tipo_id
            	and r_acc_tipo_cassa.data_cancellazione is null),
	siac_r_richiesta_econ_stato				r_richiesta_stato,
 	siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
	siac_d_richiesta_econ_stato				richiesta_stato,
    siac_t_periodo 							anno_eserc,
    siac_t_bil 								bilancio,
    siac_d_cassa_econ_modpag_tipo   		mod_pag_tipo,
	siac_t_richiesta_econ richiesta_econ
	 FULL join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
            on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
            	AND richiesta_econ_sospesa.data_cancellazione IS NULL)
     FULL join siac_r_richiesta_econ_subdoc	r_richiesta_econ_subdoc    			
            on (richiesta_econ.ricecon_id=r_richiesta_econ_subdoc.ricecon_id            	
            	AND r_richiesta_econ_subdoc.data_cancellazione IS NULL)            
      LEFT join 			siac_t_subdoc	sub_documento
            on (r_richiesta_econ_subdoc.subdoc_id=sub_documento.subdoc_id
            	AND sub_documento.data_cancellazione IS NULL)
	 LEFT join siac_t_doc				documento
            on (sub_documento.doc_id=documento.doc_id
            	AND documento.data_cancellazione IS NULL)  
     /* 29/02/2016: il soggetto deve essere quello della fattura e non
     	quello del subdoc */                          
     -- LEFT join 			siac_r_subdoc_sog	sub_doc_sog
      --      on (sub_documento.subdoc_id=sub_doc_sog.subdoc_id
     --       	AND sub_doc_sog.data_cancellazione IS NULL)
      --LEFT join 			siac_t_soggetto	soggetto
     --       on (sub_doc_sog.soggetto_id=soggetto.soggetto_id
     --       	AND soggetto.data_cancellazione IS NULL)   
     LEFT join 			siac_r_doc_sog	r_doc_sog
            on (documento.doc_id=r_doc_sog.doc_id
            	AND r_doc_sog.data_cancellazione IS NULL)
     LEFT join 			siac_t_soggetto	soggetto
            on (r_doc_sog.soggetto_id=soggetto.soggetto_id
            	AND soggetto.data_cancellazione IS NULL)  
WHERE  ente_prop.ente_proprietario_id=richiesta_econ.ente_proprietario_id
	AND movimento.ricecon_id=richiesta_econ.ricecon_id
    AND richiesta_econ_tipo.ricecon_tipo_id=richiesta_econ.ricecon_tipo_id
    AND mod_pag_tipo.cassamodpag_tipo_id=movimento.cassamodpag_tipo_id
	AND richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id
	AND r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id    
    AND richiesta_econ.bil_id=bilancio.bil_id
    AND bilancio.periodo_id=anno_eserc.periodo_id
    AND richiesta_econ.ente_proprietario_id=p_ente_prop_id
    AND richiesta_econ.cassaecon_id=p_cassaecon_id
    AND anno_eserc.anno=p_anno
    AND movimento.movt_data between p_data_da AND p_data_a
    AND richiesta_stato.ricecon_stato_code<>'AN' -- Annullati
    AND mod_pag_tipo.cassamodpag_tipo_code ='CC' -- Conto Corrente 
    	/* 30/03/2017: se questo campo e' NULL la richiesta NON e' pagata tramite
        	assegno */
    AND r_acc_tipo_cassa.cec_accredito_tipo_id IS NULL
    AND ente_prop.data_cancellazione IS NULL
    AND  movimento.data_cancellazione is null
    AND richiesta_econ.data_cancellazione IS NULL 
    AND r_richiesta_stato.data_cancellazione IS NULL 
    AND richiesta_econ_tipo.data_cancellazione IS NULL 
    AND richiesta_stato.data_cancellazione IS NULL  
    AND bilancio.data_cancellazione IS NULL
    AND anno_eserc.data_cancellazione IS NULL          
loop
raise notice 'mov = %, cec_accredito_tipo_id =%', elencoAccrediti.movt_pagamento_dettaglio,
elencoAccrediti.cec_accredito_tipo_id;

nome_ente=COALESCE(elencoAccrediti.ente_denominazione,'');
anno_ese_finanz=elencoAccrediti.anno ::INTEGER;
benef_matricola =COALESCE(elencoAccrediti.ricecon_matricola,'');

benef_cognome=COALESCE(elencoAccrediti.ricecon_cognome,'');
benef_nome=COALESCE(elencoAccrediti.ricecon_nome,'');

/* 12/09/2017: jira SIAC-5226.
	Ci sono casi in cui i campi ricecon_cognome e ricecon_nome contengono entrambi
    sia il nome che il cognome, di conseguenza il report raddoppia l'informazione.
    Per questo si e' deciso che, se i due campi sono uguali, la procedura restiuisce
    solo uno dei due. */
if benef_cognome = benef_nome THEN
	benef_nome:='';
end if;

	--27/04/2017: aggiunto il codice del beneficiario
benef_ricecon_codice=COALESCE(elencoAccrediti.ricecon_codice_beneficiario,'');

IF elencoAccrediti.iban IS NULL THEN
	banca_iban=COALESCE(elencoAccrediti.movt_pagamento_dettaglio,'');	
else
	banca_iban=elencoAccrediti.iban;	
END IF;
num_sospeso=elencoAccrediti.num_sospeso;
	/* come data sospeso usiamo la data del movimento */
data_sospeso=elencoAccrediti.movt_data;

if elencoAccrediti.gst_id is not NULL THEN                       
    SELECT rend_importo_restituito, rend_importo_integrato
      INTO dati_giustif
      FROM siac_t_giustificativo
      WHERE gst_id = elencoAccrediti.gst_id;
      IF NOT FOUND THEN
          RAISE EXCEPTION 'Non esiste il giustificativo %', elenco_movimenti.gst_id;
          return;
      ELSE
                      /* se esiste un importo restituito prendo questo con segno negativo */
      	if dati_giustif.rend_importo_restituito > 0 THEN                  
        	importo = -dati_giustif.rend_importo_restituito;
        elsif dati_giustif.rend_importo_integrato > 0 THEN
        	importo = dati_giustif.rend_importo_integrato;
        else 
        	importo=0;
        end if;
    END IF;   
else
	importo=COALESCE(elencoAccrediti.ricecon_importo,0);    
end if;

--importo=COALESCE(elencoAccrediti.ricecon_importo,0);
benef_fattura=COALESCE(elencoAccrediti.soggetto_desc,'');
benef_cod_fisc_fattura=COALESCE(elencoAccrediti.codice_fiscale,'');
benef_partita_iva_fattura=COALESCE(elencoAccrediti.partita_iva,'');
benef_codice_fattura=COALESCE(elencoAccrediti.soggetto_code,'');
num_fattura=COALESCE(elencoAccrediti.doc_numero,'');
tipo_richiesta_econ=elencoAccrediti.ricecon_tipo_code;     

/* 04/10/2017: SIAC-5255 CR-982
	Aggiunti la descrizione della richiesta ed il numero
	del movimento */
ricecon_tipo_desc:=COALESCE(elencoAccrediti.ricecon_tipo_desc, ''); 
num_movimento:=elencoAccrediti.movt_numero;

return next;


nome_ente='';
anno_ese_finanz=0;
benef_matricola ='';
benef_cognome='';
benef_nome='';
banca_iban='';
num_sospeso=NULL;
data_sospeso=NULL;
importo=0;
benef_fattura='';
benef_cod_fisc_fattura='';
benef_partita_iva_fattura='';
benef_codice_fattura='';
num_fattura='';
tipo_richiesta_econ='';
ricecon_tipo_desc:='';
num_movimento:=0;

end loop;

raise notice 'fine estrazione dei dati';  
raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'nessun dato trovato' ;
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
COST 100 ROWS 1000;

-- SIAC-5255 - CR 982 - FINE - Maurizio



-- Correzione di un refuso INIZIO - Maurizio

CREATE OR REPLACE FUNCTION siac."BILR159_struttura_dca_conto_economico" (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer
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
  livello integer
) AS
$body$
DECLARE

nome_ente varchar;
bilancio_id integer;
RTN_MESSAGGIO text;

BEGIN
  RTN_MESSAGGIO:='select 1';
  
  SELECT a.ente_denominazione
  INTO  nome_ente
  FROM  siac_t_ente_proprietario a
  WHERE a.ente_proprietario_id = p_ente_proprietario_id;
    
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

  return query
  select zz.* from (
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
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00001'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
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
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00001'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
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
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00002'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
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
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
  and d.classif_fam_code = '00002'
  and to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy'))
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
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.bil_id=bilancio_id
  and b.elem_tipo_id=a.elem_tipo_id
  and b.elem_tipo_code = 'CAP-UG'
  and c.elem_id=a.elem_id
  and c2.elem_id=a.elem_id
  and d.classif_id=c.classif_id
  and d2.classif_id=c2.classif_id
  and e.classif_tipo_id=d.classif_tipo_id
  and e2.classif_tipo_id=d2.classif_tipo_id
  and e.classif_tipo_code='PROGRAMMA'
  and e2.classif_tipo_code='MACROAGGREGATO'
  and g.elem_cat_id=f.elem_cat_id
  and f.elem_id=a.elem_id
  and g.elem_cat_code in	('STD','FPV','FSC','FPVC')
  and h.elem_id=a.elem_id
  and i.elem_stato_id=h.elem_stato_id
  and i.elem_stato_code = 'VA'
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
  b.livello
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
  WHERE b.ente_proprietario_id = p_ente_proprietario_id
  AND   m.pnota_stato_code = 'D'
  AND   i.anno = p_anno_bilancio
  AND   d.pdce_fam_code in ('CE','RE')
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
  WHERE rms.ente_proprietario_id = p_ente_proprietario_id
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = 'V'
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
  WHERE rms.ente_proprietario_id = p_ente_proprietario_id
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND   dms.mod_stato_code = 'V'
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
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id
  FROM  siac_t_movgest_ts a, siac_r_movgest_bil_elem b
  WHERE a.ente_proprietario_id = p_ente_proprietario_id
  AND   a.movgest_id = b.movgest_id
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  ),
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, a.subdoc_id
  FROM   siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = p_ente_proprietario_id
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  /* 19/09/2017: SIAC-5216.
  	Si deve testare la data di fine validita' perche' (da mail di Irene):
     "a causa della doppia gestione che purtroppo non e' stata implementata sui documenti!!!! 
     E' stato trovato questo escamotage per cui la relazione 2016 viene chiusa con una
data dell'anno nuovo (in questo caso 2017) e viene creata quella nuova del 2017
(quella che tra l'altro vediamo da sistema anche sul 2016).
Per cui l'unica soluzione e' recuperare nella tabella r_subdoc_movgest_ts  la
relazione 2016 che troverai non piu' valida."
  */
    --and a.data_cancellazione IS NULL
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id
  FROM   siac_r_ordinativo_bil_elem a
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
  AND    a.data_cancellazione IS NULL
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  WHERE  b.ente_proprietario_id = p_ente_proprietario_id
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
  WHERE a.ente_proprietario_id = p_ente_proprietario_id
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
  WHERE b.ente_proprietario_id = p_ente_proprietario_id
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  ),
  /* 20/09/2017: SIAC-5216..
  	Aggiunto collegamento per estrarre il capitolo nel caso il documento
  	sia una nota di Credito.
    In questo caso occorre prendere l'impegno del documento collegato e non quello della nota di 
    credito che non esiste */
  collegamento_SS_SE_NCD AS (
  select c.elem_id, a.subdoc_id
  from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
  where a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  --and a.subdoc_id=  54524
  AND b.ente_proprietario_id = p_ente_proprietario_id
  AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				AND a.validita_fine IS NOT NULL AND
                a.validita_fine > to_timestamp('31/12/'||p_anno_bilancio,'dd/mm/yyyy')))
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  )
  SELECT 
  prime_note.movep_det_segno,
  prime_note.importo,
  prime_note.pdce_conto_code,
  prime_note.pdce_conto_desc,
  prime_note.livello,
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
                                       AND prime_note.collegamento_tipo_code IN ('MMGS','MMGE') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('MMGS','MMGE')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('I','A')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('SI','SA')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('SS','SE')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code IN ('OP','OI')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'L'
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'RR'
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = prime_note.campo_pk_id
                                       AND prime_note.collegamento_tipo_code = 'RE'
  --20/09/2017: collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = prime_note.campo_pk_id_2
  										AND prime_note.collegamento_tipo_code IN ('SS','SE')                                       
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
  from cap
  left join dati_prime_note on cap.elem_id = dati_prime_note.elem_id  
  )
  select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      capall.movep_det_segno::varchar,
      capall.importo::numeric,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  union all
    select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      'Avere',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  union all
      select 
      nome_ente::varchar,
      --''::varchar missione_tipo_code,
      --clas.missione_tipo_desc::varchar,
      clas.missione_code::varchar,
      clas.missione_desc::varchar,
      --''::varchar programma_tipo_code,
      --clas.programma_tipo_desc::varchar,
      clas.programma_code::varchar,
      clas.programma_desc::varchar,
  /*    ''::varchar	titusc_tipo_code,
      clas.titusc_tipo_desc::varchar,
      clas.titusc_code::varchar,
      clas.titusc_desc::varchar,
      ''::varchar macroag_tipo_code,
      clas.macroag_tipo_desc::varchar,
      clas.macroag_code::varchar,
      clas.macroag_desc::varchar,
      capall.bil_ele_code::varchar,
      capall.bil_ele_desc::varchar,
      capall.bil_ele_code2::varchar,
      capall.bil_ele_desc2::varchar,
      capall.bil_ele_id::integer,
      capall.bil_ele_id_padre::integer,
      capall.bil_ele_code3::varchar,*/
      'Dare',
      0.00::numeric(15,2) ,
      capall.pdce_conto_code::varchar,
      capall.pdce_conto_desc::varchar,
      capall.livello::integer
  from clas left join capall on 
  clas.programma_id = capall.programma_id and    
  clas.macroag_id=capall.macroag_id
  where capall.importo is not null
  ) as zz; 

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

-- Correzione di un refuso FINE - Maurizio
  
-- SIAC-5332 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR092_stampa_mastrino" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
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
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;



BEGIN

p_data_reg_a:=date_trunc('day', to_timestamp(to_char(p_data_reg_a,'dd/mm/yyyy'),'dd/mm/yyyy')) + interval '1 day';


select ente_denominazione,b.bil_id into nome_ente_in,bil_id_in
from siac_t_ente_proprietario a,siac_t_bil b,siac_t_periodo c where 
a.ente_proprietario_id=p_ente_prop_id and
a.ente_proprietario_id=b.ente_proprietario_id and b.periodo_id=c.periodo_id
and c.anno=p_anno
;
/*
raise notice 'dati input  p_ente_prop_id % - 
  p_anno % - 
  p_data_reg_da % - 
  p_data_reg_a % - 
  p_pdce_v_livello % - 
  nome_ente_in % - 
  bil_id_in %', p_ente_prop_id::varchar , p_anno::varchar ,  p_data_reg_da::varchar ,
  p_data_reg_a::varchar ,  p_pdce_v_livello::varchar ,  nome_ente_in::varchar ,
  bil_id_in::varchar ;
*/
    select fnc_siac_random_user()
	into	user_table;

raise notice '1 - % ',clock_timestamp()::varchar;
	select --a.pdce_conto_code, 
    a.pdce_conto_id --, a.livello
    into --dati_pdce
    pdce_conto_id_in
    from siac_t_pdce_conto a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.pdce_conto_code=p_pdce_v_livello;
    IF NOT FOUND THEN
    	display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') e'' inesistente';
        return next;
    	return;
    END IF;
--raise notice 'PDCE livello = %, conto = %, ID = %',  dati_pdce.livello, dati_pdce.pdce_conto_code, dati_pdce.pdce_conto_id;      
    
--     carico l'intera struttura PDCE 
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';

raise notice '2 - % ',clock_timestamp()::varchar;
INSERT INTO 
  siac.siac_rep_struttura_pdce
(
  pdce_liv0_id,
  pdce_liv0_id_padre,
  pdce_liv0_code,
  pdce_liv0_desc,
  pdce_liv1_id,
  pdce_liv1_id_padre,
  pdce_liv1_code,
  pdce_liv1_desc,
  pdce_liv2_id,
  pdce_liv2_id_padre,
  pdce_liv2_code,
  pdce_liv2_desc,
  pdce_liv3_id,
  pdce_liv3_id_padre,
  pdce_liv3_code,
  pdce_liv3_desc,
  pdce_liv4_id,
  pdce_liv4_id_padre,
  pdce_liv4_code,
  pdce_liv4_desc,
  pdce_liv5_id,
  pdce_liv5_id_padre,
  pdce_liv5_code,
  pdce_liv5_desc,
  pdce_liv6_id,
  pdce_liv6_id_padre,
  pdce_liv6_code,
  pdce_liv6_desc,
  pdce_liv7_id,
  pdce_liv7_id_padre,
  pdce_liv7_code,
  pdce_liv7_desc,
  utente
)
select zzz.*, user_table from(
with t_pdce_conto0 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree where pdce_conto_id=pdce_conto_id_in
),
t_pdce_conto1 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
),
t_pdce_conto2 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto3 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto4 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto5 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto6 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto7 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
select 
t_pdce_conto7.pdce_conto_id pdce_liv0_id,
t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre, 
t_pdce_conto7.pdce_conto_code pdce_liv0_code,
t_pdce_conto7.pdce_conto_desc pdce_liv0_desc,
t_pdce_conto6.pdce_conto_id pdce_liv1_id, 
t_pdce_conto6.pdce_conto_id_padre pdce_liv1_id_padre, 
t_pdce_conto6.pdce_conto_code pdce_liv1_code,
t_pdce_conto6.pdce_conto_desc pdce_liv1_desc,
t_pdce_conto5.pdce_conto_id pdce_liv2_id, 
t_pdce_conto5.pdce_conto_id_padre pdce_liv2_id_padre, 
t_pdce_conto5.pdce_conto_code pdce_liv2_code,
t_pdce_conto5.pdce_conto_desc pdce_liv2_desc,
t_pdce_conto4.pdce_conto_id pdce_liv3_id, 
t_pdce_conto4.pdce_conto_id_padre pdce_liv3_id_padre, 
t_pdce_conto4.pdce_conto_code pdce_liv3_code,
t_pdce_conto4.pdce_conto_desc pdce_liv3_desc,
t_pdce_conto3.pdce_conto_id pdce_liv4_id, 
t_pdce_conto3.pdce_conto_id_padre pdce_liv4_id_padre, 
t_pdce_conto3.pdce_conto_code pdce_liv4_code,
t_pdce_conto3.pdce_conto_desc pdce_liv4_desc,
t_pdce_conto2.pdce_conto_id pdce_liv5_id, 
t_pdce_conto2.pdce_conto_id_padre pdce_liv5_id_padre, 
t_pdce_conto2.pdce_conto_code pdce_liv5_code,
t_pdce_conto2.pdce_conto_desc pdce_liv5_desc,
t_pdce_conto1.pdce_conto_id pdce_liv6_id, 
t_pdce_conto1.pdce_conto_id_padre pdce_liv6_id_padre, 
t_pdce_conto1.pdce_conto_code pdce_liv6_code,
t_pdce_conto1.pdce_conto_desc pdce_liv6_desc,
t_pdce_conto0.pdce_conto_id pdce_liv7_id, 
t_pdce_conto0.pdce_conto_id_padre pdce_liv7_id_padre, 
t_pdce_conto0.pdce_conto_code pdce_liv7_code,
t_pdce_conto0.pdce_conto_desc pdce_liv7_desc
 from t_pdce_conto0 left join t_pdce_conto1
on t_pdce_conto0.livello-1=t_pdce_conto1.livello
left join t_pdce_conto2
on t_pdce_conto1.livello-1=t_pdce_conto2.livello
left join t_pdce_conto3
on t_pdce_conto2.livello-1=t_pdce_conto3.livello
left join t_pdce_conto4
on t_pdce_conto3.livello-1=t_pdce_conto4.livello
left join t_pdce_conto5
on t_pdce_conto4.livello-1=t_pdce_conto5.livello
left join t_pdce_conto6
on t_pdce_conto5.livello-1=t_pdce_conto6.livello
left join t_pdce_conto7
on t_pdce_conto6.livello-1=t_pdce_conto7.livello
) as zzz;

raise notice '3 - % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

return query  
select outp.* from (
with ord as (--ORD
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'ORD'::varchar tipo_pnota,
c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
s.soggetto_desc::varchar       descr_soggetto,
'ORD'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a  and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
     --   limit 1
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all       
select impacc.* from (          
--A,I 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.movgest_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest q                
WHERE d.collegamento_tipo_code in ('I','A') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_id=b.campo_pk_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL 
),
sogcla as (
select distinct c.movgest_id,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest c,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select c.movgest_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest c,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_id=sogcla.movgest_id 
left join sog on 
movgest.movgest_id=sog.movgest_id 
) as impacc
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all         
select impsubacc.* from (          
--SA,SI 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest_ts q,siac_t_movgest r               
WHERE d.collegamento_tipo_code in ('SI','SA') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_ts_id =b.campo_pk_id and
r.movgest_id=q.movgest_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL 
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubacc
--'MMGE','MMGS'
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all        
select impsubaccmod.* from (          
with movgest as (
/*SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest r,
 siac_t_movgest_ts q, siac_t_modifica s,siac_r_modifica_stato t,
 siac_t_movgest_ts_det_mod u
WHERE d.collegamento_tipo_code in ('MMGE','MMGS') and
  a.ente_proprietario_id=p_ente_prop_id
  and  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and r.movgest_id=q.movgest_id 
and s.mod_id=b.campo_pk_id
and t.mod_id=s.mod_id
and q.movgest_id=r.movgest_id
and u.mod_stato_r_id=t.mod_stato_r_id
and u.movgest_ts_id=q.movgest_ts_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL and 
s.data_cancellazione IS NULL and 
t.data_cancellazione IS NULL and 
u.data_cancellazione IS NULL  
union
select 
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
  from siac_t_prima_nota a 
,siac_r_prima_nota_stato b, siac_d_prima_nota_stato c,siac_t_mov_ep d,
siac_t_mov_ep_det e, siac_t_reg_movfin f,siac_r_evento_reg_movfin g,
siac_d_evento h,siac_d_collegamento_tipo i, siac_d_evento_tipo l,
siac_t_modifica m, siac_r_modifica_stato n, siac_d_modifica_stato o,
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where a.ente_proprietario_id=p_ente_prop_id
and b.pnota_id=a.pnota_id
and a.bil_id=bil_id_in
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between     p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and m.mod_id=g.campo_pk_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and c.pnota_stato_code='D'
and p.mod_stato_r_id=n.mod_stato_r_id
and q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and  a.data_cancellazione is null 
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null 
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null*/


with modge as (
select 
n.mod_stato_r_id,
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  from siac_t_prima_nota a 
,siac_r_prima_nota_stato b, siac_d_prima_nota_stato c,siac_t_mov_ep d,
siac_t_mov_ep_det e, siac_t_reg_movfin f,siac_r_evento_reg_movfin g,
siac_d_evento h,siac_d_collegamento_tipo i, siac_d_evento_tipo l,
siac_t_modifica m, siac_r_modifica_stato n, siac_d_modifica_stato o
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bil_id_in
and b.pnota_id=a.pnota_id
and i.collegamento_tipo_code in ('MMGS','MMGE')
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between     p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and m.mod_id=g.campo_pk_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and c.pnota_stato_code='D'
and  a.data_cancellazione is null 
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null 
) ,
modsog as (
select p.mod_stato_r_id,q.movgest_ts_id,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
 from 
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
,
modimp as (
select p.mod_stato_r_id,q.movgest_ts_id 
,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
from 
siac_t_movgest_ts_det_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
select 
modge.pnota_dataregistrazionegiornale,
modge.num_prima_nota,
modge.tipo_pnota,
modge.prov_pnota,
modge.tipo_documento ,--uguale a tipo_pnota,
modge.data_registrazione_movimento,
modge.numero_documento,
case when modsog.movgest_ts_id is null then modimp.num_det_rif else modsog.num_det_rif end num_det_rif,
modge.ente_proprietario_id,
modge.pdce_conto_id,     
modge.tipo_movimento,
modge.data_det_rif,
modge.data_registrazione,
modge.importo_dare,                    
modge.importo_avere           
, case when modsog.movgest_ts_id is null then modimp.movgest_ts_id else modsog.movgest_ts_id end movgest_ts_id
from modge left join
modsog on modge.mod_stato_r_id=modsog.mod_stato_r_id
left join
modimp on modge.mod_stato_r_id=modimp.mod_stato_r_id
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubaccmod
--LIQ
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all 
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'LIQ'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'LIQ'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.liq_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.liq_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_liquidazione q,
       siac_r_liquidazione_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('L') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.liq_id=b.campo_pk_id and
        r.liq_id=q.liq_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--DOC
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'FAT'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
t.soggetto_code::varchar cod_soggetto,
 t.soggetto_desc::varchar       descr_soggetto,
'FAT'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.doc_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
r.doc_data_emissione::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_subdoc q,
       siac_t_doc  r,
       siac_r_doc_sog s,
       siac_t_soggetto t                                       
WHERE d.collegamento_tipo_code in ('SS','SE') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.subdoc_id=b.campo_pk_id and
        r.doc_id=q.doc_id and 
        s.doc_id=r.doc_id and 
        s.soggetto_id=t.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL/*
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
'' tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'' tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
'' numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id and
  a.regmovfin_id = b.regmovfin_id AND
        c.	evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in and
        l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL*/
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--lib
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
case when dd.evento_code='AAP' then 'AAP'::varchar when dd.evento_code='APP' then 'APP'::varchar
else 'LIB'::varchar end tipo_pnota,
 dd.evento_code::varchar prov_pnota,
m.pnota_desc::varchar cod_soggetto,
 ''::varchar       descr_soggetto,
'LIB'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
''::varchar num_det_rif,
m.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
siac_t_causale_ep	aa,
siac_d_causale_ep_tipo bb,
siac_r_evento_causale cc,
siac_d_evento dd,
siac_d_evento_tipo g
where 
l.ente_proprietario_id=p_ente_prop_id
and l.regep_id=m.pnota_id
and n.pnota_id=m.pnota_id
and o.pnota_stato_id=n.pnota_stato_id
and p.movep_id=l.movep_id
and aa.causale_ep_id=l.causale_ep_id
and bb.causale_ep_tipo_id=aa.causale_ep_tipo_id
and bb.causale_ep_tipo_code='LIB'
and cc.causale_ep_id=aa.causale_ep_id
and dd.evento_id=cc.evento_id 
and g.evento_tipo_id=dd.evento_tipo_id and
 m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
aa.data_cancellazione IS NULL AND
bb.data_cancellazione IS NULL AND
cc.data_cancellazione IS NULL AND
dd.data_cancellazione IS NULL AND  
g.data_cancellazione IS NULL 
AND  n.validita_fine IS NULL
AND  cc.validita_fine IS NULL
AND  m.bil_id = bil_id_in
        )
        ,cc as 
        ( WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_code, my_tree.livello
from my_tree 
),
bb as (select * from siac_rep_struttura_pdce bb where bb.utente=user_table)
        /* bb as (select pdce_conto.livello, pdce_conto.pdce_conto_id,pdce_conto.pdce_conto_code codice_conto,
        pdce_conto.pdce_conto_desc descr_pdce_livello,strutt_pdce.*
    	from siac_t_pdce_conto	pdce_conto,
            siac_rep_struttura_pdce strutt_pdce
        where ((pdce_conto.livello=0 
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
         and pdce_conto.ente_proprietario_id=p_ente_prop_id 
         and pdce_conto.pdce_conto_code=p_pdce_v_livello
        and strutt_pdce.utente=user_table
         and pdce_conto.data_cancellazione is NULL)*/
         select   
nome_ente_in,
bb.pdce_liv0_id::integer  id_pdce0 ,
bb.pdce_liv0_code::varchar codice_pdce0 ,
bb.pdce_liv0_desc  descr_pdce0 ,
bb.pdce_liv1_id id_pdce1,
bb.pdce_liv1_code::varchar  codice_pdce1 ,
bb.pdce_liv1_desc::varchar  descr_pdce1 ,
bb.pdce_liv2_id  id_pdce2 ,
bb.pdce_liv2_code::varchar codice_pdce2 ,
bb.pdce_liv2_desc::varchar  descr_pdce2 ,
bb.pdce_liv3_id  id_pdce3 ,
bb.pdce_liv3_code::varchar  codice_pdce3 ,
bb.pdce_liv3_desc::varchar  descr_pdce3 ,
bb.pdce_liv4_id   id_pdce4 ,
bb.pdce_liv4_code::varchar  codice_pdce4 ,
bb.pdce_liv4_desc::varchar  descr_pdce4 ,
bb.pdce_liv5_id   id_pdce5 ,
bb.pdce_liv5_code::varchar  codice_pdce5 ,
bb.pdce_liv5_desc::varchar  descr_pdce5 ,
bb.pdce_liv6_id   id_pdce6 ,
bb.pdce_liv6_code::varchar  codice_pdce6 ,
bb.pdce_liv6_desc::varchar  descr_pdce6 ,
bb.pdce_liv7_id   id_pdce7 ,
bb.pdce_liv7_code::varchar  codice_pdce7 ,
bb.pdce_liv7_desc::varchar  descr_pdce7 ,
coalesce(bb.pdce_liv8_id,0)::integer   id_pdce8 ,
coalesce(bb.pdce_liv8_code,'')::varchar  codice_pdce8 ,
coalesce(bb.pdce_liv8_desc,'')::varchar  descr_pdce8, 
ord.data_registrazione,
ord.num_prima_nota,
ord.tipo_pnota tipo_pnota,
ord.prov_pnota,
ord.cod_soggetto, 
ord.descr_soggetto,
ord.tipo_documento tipo_documento,--uguale a tipo_pnota,
ord.data_registrazione_movimento,
''::varchar numero_documento,
ord.num_det_rif,
ord.data_det_rif,
ord.importo_dare,                    
ord.importo_avere,             
--bb.livello::integer,
cc.livello::integer,
ord.tipo_movimento,
0::numeric  saldo_prec_dare,
0::numeric  saldo_prec_avere ,
0::numeric saldo_ini_dare ,
0::numeric saldo_ini_avere ,
--bb.codice_conto::varchar   code_pdce_livello ,
cc.pdce_conto_code::varchar   code_pdce_livello ,
''::varchar  display_error 
from ord join cc on ord.pdce_conto_id=cc.pdce_conto_id
cross join bb 
) as outp
;
  
 delete from siac_rep_struttura_pdce 	where utente=user_table;
  
exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5332 FINE  

-- SIAC-5281 INIZIO
DROP TABLE IF EXISTS siac.siac_r_mov_ep_det_class;

CREATE TABLE siac.siac_r_mov_ep_det_class (
	movep_det_classif_id SERIAL,
	movep_det_id         INTEGER NOT NULL,
	classif_id           INTEGER NOT NULL,
	validita_inizio      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
	validita_fine        TIMESTAMP WITHOUT TIME ZONE,
	ente_proprietario_id INTEGER NOT NULL,
	data_creazione       TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_modifica        TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
	data_cancellazione   TIMESTAMP WITHOUT TIME ZONE,
	login_operazione     CHARACTER VARYING(200) NOT NULL,
	
	CONSTRAINT pk_siac_r_mov_ep_det_class PRIMARY KEY (movep_det_classif_id),
	CONSTRAINT siac_t_mov_ep_det_siac_r_mov_ep_det_class FOREIGN KEY (movep_det_id)
		REFERENCES siac.siac_t_mov_ep_det(movep_det_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	CONSTRAINT siac_t_class_siac_r_mov_ep_det_class FOREIGN KEY (classif_id)
		REFERENCES siac.siac_t_class(classif_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION,
	CONSTRAINT siac_t_ente_proprietario_siac_r_mov_ep_det_class FOREIGN KEY (ente_proprietario_id)
		REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
		ON DELETE NO ACTION
		ON UPDATE NO ACTION
);

ALTER TABLE siac.siac_r_mov_ep_det_class OWNER TO siac;
-- SIAC-5281 FINE

-- Stampa Mastrino Ottimizzazione INIZIO
CREATE OR REPLACE FUNCTION siac."BILR092_stampa_mastrino" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
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
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;



BEGIN

p_data_reg_a:=date_trunc('day', to_timestamp(to_char(p_data_reg_a,'dd/mm/yyyy'),'dd/mm/yyyy')) + interval '1 day';


select ente_denominazione,b.bil_id into nome_ente_in,bil_id_in
from siac_t_ente_proprietario a,siac_t_bil b,siac_t_periodo c where 
a.ente_proprietario_id=p_ente_prop_id and
a.ente_proprietario_id=b.ente_proprietario_id and b.periodo_id=c.periodo_id
and c.anno=p_anno
;
/*
raise notice 'dati input  p_ente_prop_id % - 
  p_anno % - 
  p_data_reg_da % - 
  p_data_reg_a % - 
  p_pdce_v_livello % - 
  nome_ente_in % - 
  bil_id_in %', p_ente_prop_id::varchar , p_anno::varchar ,  p_data_reg_da::varchar ,
  p_data_reg_a::varchar ,  p_pdce_v_livello::varchar ,  nome_ente_in::varchar ,
  bil_id_in::varchar ;
*/
    select fnc_siac_random_user()
	into	user_table;

raise notice '1 - % ',clock_timestamp()::varchar;
	select --a.pdce_conto_code, 
    a.pdce_conto_id --, a.livello
    into --dati_pdce
    pdce_conto_id_in
    from siac_t_pdce_conto a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.pdce_conto_code=p_pdce_v_livello;
    IF NOT FOUND THEN
    	display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') e'' inesistente';
        return next;
    	return;
    END IF;
--raise notice 'PDCE livello = %, conto = %, ID = %',  dati_pdce.livello, dati_pdce.pdce_conto_code, dati_pdce.pdce_conto_id;      
    
--     carico l'intera struttura PDCE 
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';

raise notice '2 - % ',clock_timestamp()::varchar;
INSERT INTO 
  siac.siac_rep_struttura_pdce
(
  pdce_liv0_id,
  pdce_liv0_id_padre,
  pdce_liv0_code,
  pdce_liv0_desc,
  pdce_liv1_id,
  pdce_liv1_id_padre,
  pdce_liv1_code,
  pdce_liv1_desc,
  pdce_liv2_id,
  pdce_liv2_id_padre,
  pdce_liv2_code,
  pdce_liv2_desc,
  pdce_liv3_id,
  pdce_liv3_id_padre,
  pdce_liv3_code,
  pdce_liv3_desc,
  pdce_liv4_id,
  pdce_liv4_id_padre,
  pdce_liv4_code,
  pdce_liv4_desc,
  pdce_liv5_id,
  pdce_liv5_id_padre,
  pdce_liv5_code,
  pdce_liv5_desc,
  pdce_liv6_id,
  pdce_liv6_id_padre,
  pdce_liv6_code,
  pdce_liv6_desc,
  pdce_liv7_id,
  pdce_liv7_id_padre,
  pdce_liv7_code,
  pdce_liv7_desc,
  utente
)
select zzz.*, user_table from(
with t_pdce_conto0 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree where pdce_conto_id=pdce_conto_id_in
),
t_pdce_conto1 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
),
t_pdce_conto2 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto3 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto4 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto5 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto6 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto7 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
select 
t_pdce_conto7.pdce_conto_id pdce_liv0_id,
t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre, 
t_pdce_conto7.pdce_conto_code pdce_liv0_code,
t_pdce_conto7.pdce_conto_desc pdce_liv0_desc,
t_pdce_conto6.pdce_conto_id pdce_liv1_id, 
t_pdce_conto6.pdce_conto_id_padre pdce_liv1_id_padre, 
t_pdce_conto6.pdce_conto_code pdce_liv1_code,
t_pdce_conto6.pdce_conto_desc pdce_liv1_desc,
t_pdce_conto5.pdce_conto_id pdce_liv2_id, 
t_pdce_conto5.pdce_conto_id_padre pdce_liv2_id_padre, 
t_pdce_conto5.pdce_conto_code pdce_liv2_code,
t_pdce_conto5.pdce_conto_desc pdce_liv2_desc,
t_pdce_conto4.pdce_conto_id pdce_liv3_id, 
t_pdce_conto4.pdce_conto_id_padre pdce_liv3_id_padre, 
t_pdce_conto4.pdce_conto_code pdce_liv3_code,
t_pdce_conto4.pdce_conto_desc pdce_liv3_desc,
t_pdce_conto3.pdce_conto_id pdce_liv4_id, 
t_pdce_conto3.pdce_conto_id_padre pdce_liv4_id_padre, 
t_pdce_conto3.pdce_conto_code pdce_liv4_code,
t_pdce_conto3.pdce_conto_desc pdce_liv4_desc,
t_pdce_conto2.pdce_conto_id pdce_liv5_id, 
t_pdce_conto2.pdce_conto_id_padre pdce_liv5_id_padre, 
t_pdce_conto2.pdce_conto_code pdce_liv5_code,
t_pdce_conto2.pdce_conto_desc pdce_liv5_desc,
t_pdce_conto1.pdce_conto_id pdce_liv6_id, 
t_pdce_conto1.pdce_conto_id_padre pdce_liv6_id_padre, 
t_pdce_conto1.pdce_conto_code pdce_liv6_code,
t_pdce_conto1.pdce_conto_desc pdce_liv6_desc,
t_pdce_conto0.pdce_conto_id pdce_liv7_id, 
t_pdce_conto0.pdce_conto_id_padre pdce_liv7_id_padre, 
t_pdce_conto0.pdce_conto_code pdce_liv7_code,
t_pdce_conto0.pdce_conto_desc pdce_liv7_desc
 from t_pdce_conto0 left join t_pdce_conto1
on t_pdce_conto0.livello-1=t_pdce_conto1.livello
left join t_pdce_conto2
on t_pdce_conto1.livello-1=t_pdce_conto2.livello
left join t_pdce_conto3
on t_pdce_conto2.livello-1=t_pdce_conto3.livello
left join t_pdce_conto4
on t_pdce_conto3.livello-1=t_pdce_conto4.livello
left join t_pdce_conto5
on t_pdce_conto4.livello-1=t_pdce_conto5.livello
left join t_pdce_conto6
on t_pdce_conto5.livello-1=t_pdce_conto6.livello
left join t_pdce_conto7
on t_pdce_conto6.livello-1=t_pdce_conto7.livello
) as zzz;

raise notice '3 - % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

return query  
select outp.* from (
with ord as (--ORD
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'ORD'::varchar tipo_pnota,
c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
s.soggetto_desc::varchar       descr_soggetto,
'ORD'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a  and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
     --   limit 1
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all       
select impacc.* from (          
--A,I 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.movgest_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest q                
WHERE d.collegamento_tipo_code in ('I','A') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_id=b.campo_pk_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL 
),
sogcla as (
select distinct c.movgest_id,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest c,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select c.movgest_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest c,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_id=sogcla.movgest_id 
left join sog on 
movgest.movgest_id=sog.movgest_id 
) as impacc
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all         
select impsubacc.* from (          
--SA,SI 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest_ts q,siac_t_movgest r               
WHERE d.collegamento_tipo_code in ('SI','SA') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_ts_id =b.campo_pk_id and
r.movgest_id=q.movgest_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL 
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubacc
--'MMGE','MMGS'
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all        
select impsubaccmod.* from (          
with movgest as (
/*SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest r,
 siac_t_movgest_ts q, siac_t_modifica s,siac_r_modifica_stato t,
 siac_t_movgest_ts_det_mod u
WHERE d.collegamento_tipo_code in ('MMGE','MMGS') and
  a.ente_proprietario_id=p_ente_prop_id
  and  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and r.movgest_id=q.movgest_id 
and s.mod_id=b.campo_pk_id
and t.mod_id=s.mod_id
and q.movgest_id=r.movgest_id
and u.mod_stato_r_id=t.mod_stato_r_id
and u.movgest_ts_id=q.movgest_ts_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL and 
s.data_cancellazione IS NULL and 
t.data_cancellazione IS NULL and 
u.data_cancellazione IS NULL  
union
select 
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
  from siac_t_prima_nota a 
,siac_r_prima_nota_stato b, siac_d_prima_nota_stato c,siac_t_mov_ep d,
siac_t_mov_ep_det e, siac_t_reg_movfin f,siac_r_evento_reg_movfin g,
siac_d_evento h,siac_d_collegamento_tipo i, siac_d_evento_tipo l,
siac_t_modifica m, siac_r_modifica_stato n, siac_d_modifica_stato o,
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where a.ente_proprietario_id=p_ente_prop_id
and b.pnota_id=a.pnota_id
and a.bil_id=bil_id_in
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between     p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and m.mod_id=g.campo_pk_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and c.pnota_stato_code='D'
and p.mod_stato_r_id=n.mod_stato_r_id
and q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and  a.data_cancellazione is null 
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null 
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null*/
with modge as (select tbz.* from (
with modprnoteint as (
select 
g.campo_pk_id,
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
from 
siac_t_prima_nota a 
,siac_r_prima_nota_stato b, 
siac_d_prima_nota_stato c,
siac_t_mov_ep d,
siac_t_mov_ep_det e, 
siac_t_reg_movfin f,
siac_r_evento_reg_movfin g,
siac_d_evento h,
siac_d_collegamento_tipo i, 
siac_d_evento_tipo l
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bil_id_in
and b.pnota_id=a.pnota_id
and i.collegamento_tipo_code in ('MMGS','MMGE')
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between  p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and c.pnota_stato_code='D'
and  a.data_cancellazione is null 
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
)
,
moddd as (
select m.mod_id,n.mod_stato_r_id
 from siac_t_modifica m, 
siac_r_modifica_stato n, 
siac_d_modifica_stato o
where m.ente_proprietario_id=p_ente_prop_id 
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null
) 
select 
moddd.mod_stato_r_id,
modprnoteint.pnota_dataregistrazionegiornale,
modprnoteint.num_prima_nota,
modprnoteint.tipo_pnota,
modprnoteint.prov_pnota,
modprnoteint.tipo_documento,
modprnoteint.data_registrazione_movimento,
modprnoteint.numero_documento,
modprnoteint.ente_proprietario_id,
modprnoteint.pdce_conto_id,     
modprnoteint.tipo_movimento,
modprnoteint.data_det_rif,
modprnoteint.data_registrazione,
modprnoteint.importo_dare,                    
modprnoteint.importo_avere           
 from modprnoteint join moddd
on  moddd.mod_id=modprnoteint.campo_pk_id)
as tbz
) ,
modsog as (
select p.mod_stato_r_id,q.movgest_ts_id,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
 from 
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
p.ente_proprietario_id=p_ente_prop_id and
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
,
modimp as (
select p.mod_stato_r_id,q.movgest_ts_id 
,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
from 
siac_t_movgest_ts_det_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
p.ente_proprietario_id=p_ente_prop_id and
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
select 
modge.pnota_dataregistrazionegiornale,
modge.num_prima_nota,
modge.tipo_pnota,
modge.prov_pnota,
modge.tipo_documento ,--uguale a tipo_pnota,
modge.data_registrazione_movimento,
modge.numero_documento,
case when modsog.movgest_ts_id is null then modimp.num_det_rif else modsog.num_det_rif end num_det_rif,
modge.ente_proprietario_id,
modge.pdce_conto_id,     
modge.tipo_movimento,
modge.data_det_rif,
modge.data_registrazione,
modge.importo_dare,                    
modge.importo_avere           
, case when modsog.movgest_ts_id is null then modimp.movgest_ts_id else modsog.movgest_ts_id end movgest_ts_id
from modge left join
modsog on modge.mod_stato_r_id=modsog.mod_stato_r_id
left join
modimp on modge.mod_stato_r_id=modimp.mod_stato_r_id
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubaccmod
--LIQ
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all 
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'LIQ'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'LIQ'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.liq_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.liq_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_liquidazione q,
       siac_r_liquidazione_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('L') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.liq_id=b.campo_pk_id and
        r.liq_id=q.liq_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--DOC
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'FAT'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
t.soggetto_code::varchar cod_soggetto,
 t.soggetto_desc::varchar       descr_soggetto,
'FAT'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.doc_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
r.doc_data_emissione::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_subdoc q,
       siac_t_doc  r,
       siac_r_doc_sog s,
       siac_t_soggetto t                                       
WHERE d.collegamento_tipo_code in ('SS','SE') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.subdoc_id=b.campo_pk_id and
        r.doc_id=q.doc_id and 
        s.doc_id=r.doc_id and 
        s.soggetto_id=t.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL/*
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
'' tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'' tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
'' numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id and
  a.regmovfin_id = b.regmovfin_id AND
        c.	evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in and
        l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL*/
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--lib
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
case when dd.evento_code='AAP' then 'AAP'::varchar when dd.evento_code='APP' then 'APP'::varchar
else 'LIB'::varchar end tipo_pnota,
 dd.evento_code::varchar prov_pnota,
m.pnota_desc::varchar cod_soggetto,
 ''::varchar       descr_soggetto,
'LIB'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
''::varchar num_det_rif,
m.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
siac_t_causale_ep	aa,
siac_d_causale_ep_tipo bb,
siac_r_evento_causale cc,
siac_d_evento dd,
siac_d_evento_tipo g
where 
l.ente_proprietario_id=p_ente_prop_id
and l.regep_id=m.pnota_id
and n.pnota_id=m.pnota_id
and o.pnota_stato_id=n.pnota_stato_id
and p.movep_id=l.movep_id
and aa.causale_ep_id=l.causale_ep_id
and bb.causale_ep_tipo_id=aa.causale_ep_tipo_id
and bb.causale_ep_tipo_code='LIB'
and cc.causale_ep_id=aa.causale_ep_id
and dd.evento_id=cc.evento_id 
and g.evento_tipo_id=dd.evento_tipo_id and
 m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
aa.data_cancellazione IS NULL AND
bb.data_cancellazione IS NULL AND
cc.data_cancellazione IS NULL AND
dd.data_cancellazione IS NULL AND  
g.data_cancellazione IS NULL 
AND  n.validita_fine IS NULL
AND  cc.validita_fine IS NULL
AND  m.bil_id = bil_id_in
        )
        ,cc as 
        ( WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_code, my_tree.livello
from my_tree 
),
bb as (select * from siac_rep_struttura_pdce bb where bb.utente=user_table)
        /* bb as (select pdce_conto.livello, pdce_conto.pdce_conto_id,pdce_conto.pdce_conto_code codice_conto,
        pdce_conto.pdce_conto_desc descr_pdce_livello,strutt_pdce.*
    	from siac_t_pdce_conto	pdce_conto,
            siac_rep_struttura_pdce strutt_pdce
        where ((pdce_conto.livello=0 
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
         and pdce_conto.ente_proprietario_id=p_ente_prop_id 
         and pdce_conto.pdce_conto_code=p_pdce_v_livello
        and strutt_pdce.utente=user_table
         and pdce_conto.data_cancellazione is NULL)*/
         select   
nome_ente_in,
bb.pdce_liv0_id::integer  id_pdce0 ,
bb.pdce_liv0_code::varchar codice_pdce0 ,
bb.pdce_liv0_desc  descr_pdce0 ,
bb.pdce_liv1_id id_pdce1,
bb.pdce_liv1_code::varchar  codice_pdce1 ,
bb.pdce_liv1_desc::varchar  descr_pdce1 ,
bb.pdce_liv2_id  id_pdce2 ,
bb.pdce_liv2_code::varchar codice_pdce2 ,
bb.pdce_liv2_desc::varchar  descr_pdce2 ,
bb.pdce_liv3_id  id_pdce3 ,
bb.pdce_liv3_code::varchar  codice_pdce3 ,
bb.pdce_liv3_desc::varchar  descr_pdce3 ,
bb.pdce_liv4_id   id_pdce4 ,
bb.pdce_liv4_code::varchar  codice_pdce4 ,
bb.pdce_liv4_desc::varchar  descr_pdce4 ,
bb.pdce_liv5_id   id_pdce5 ,
bb.pdce_liv5_code::varchar  codice_pdce5 ,
bb.pdce_liv5_desc::varchar  descr_pdce5 ,
bb.pdce_liv6_id   id_pdce6 ,
bb.pdce_liv6_code::varchar  codice_pdce6 ,
bb.pdce_liv6_desc::varchar  descr_pdce6 ,
bb.pdce_liv7_id   id_pdce7 ,
bb.pdce_liv7_code::varchar  codice_pdce7 ,
bb.pdce_liv7_desc::varchar  descr_pdce7 ,
coalesce(bb.pdce_liv8_id,0)::integer   id_pdce8 ,
coalesce(bb.pdce_liv8_code,'')::varchar  codice_pdce8 ,
coalesce(bb.pdce_liv8_desc,'')::varchar  descr_pdce8, 
ord.data_registrazione,
ord.num_prima_nota,
ord.tipo_pnota tipo_pnota,
ord.prov_pnota,
ord.cod_soggetto, 
ord.descr_soggetto,
ord.tipo_documento tipo_documento,--uguale a tipo_pnota,
ord.data_registrazione_movimento,
''::varchar numero_documento,
ord.num_det_rif,
ord.data_det_rif,
ord.importo_dare,                    
ord.importo_avere,             
--bb.livello::integer,
cc.livello::integer,
ord.tipo_movimento,
0::numeric  saldo_prec_dare,
0::numeric  saldo_prec_avere ,
0::numeric saldo_ini_dare ,
0::numeric saldo_ini_avere ,
--bb.codice_conto::varchar   code_pdce_livello ,
cc.pdce_conto_code::varchar   code_pdce_livello ,
''::varchar  display_error 
from ord join cc on ord.pdce_conto_id=cc.pdce_conto_id
cross join bb 
) as outp
;
  
 delete from siac_rep_struttura_pdce 	where utente=user_table;
  
exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- Stampa Mastrino Ottimizzazione FINE

--SIAC-5396 INIZIO - Maurizio

CREATE OR REPLACE FUNCTION siac."BILR059_fpv_spese_sintetico" (
  p_ente_prop_id integer,
  p_set_id varchar,
  p_anno_bilancio varchar,
  p_gestione varchar
)
RETURNS TABLE (
  anno_out varchar,
  id_set varchar,
  codice_set varchar,
  descrizione_set varchar,
  id_programma integer,
  codice_programma varchar,
  descrizione_programma varchar,
  id_cronop integer,
  codice_cronop varchar,
  descrizione_cronop varchar,
  missione varchar,
  programma varchar,
  titolo varchar,
  spesa_prevista numeric,
  fpv_spesa numeric,
  tipo varchar
) AS
$body$
DECLARE
setRec record;
setrecpro record;

DEF_NULL	constant 			varchar:='';
def_spazio	constant 			varchar:=' ';  
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
flag_gestione	VARCHAR;
r_set_cronop_id INTEGER;
user_table	varchar;
contaChiamate integer;

BEGIN
anno_out='';
id_set=0;
codice_set='';
descrizione_set='';
id_programma=0;
id_cronop=0;
missione='';
programma='';
titolo='';
spesa_prevista=0;
fpv_spesa=0;
descrizione_programma='';
descrizione_cronop='';
codice_programma='';
codice_cronop='';
tipo='';



select fnc_siac_random_user()
into	user_table;
RTN_MESSAGGIO:='inserimento tabella di comodo dove usa gestione = false '||p_set_id||'.';
insert into siac_rep_set_cronop_fpv
 select 		gruppo.set_cronop_code			set_code,
                gruppo.set_cronop_desc			descr_set,
                gruppo.set_cronop_id			set_id,
                r_gruppo_crono.cronop_id		cronop_id,
                r_gruppo_crono.programma_id		programma_id,
                r_gruppo_crono.set_cronop_id	id_r_set_cronop,
                r_gruppo_crono.usa_gestione		gestione_flag,
                t_programma.programma_code		programma_codice,
                t_programma.programma_desc		programma_descrizione,
                t_cronop.cronop_code			cronop_codice,
                t_cronop.cronop_desc			cronop_descrizione,
                p_ente_prop_id					ente,
                user_table	 					utente
    from   		siac_t_fpv_set_cronop 	gruppo,  	
                siac_r_fpv_set_cronop	r_gruppo_crono,
                siac_t_bil				bil,
                siac_t_periodo 			periodo, 
                siac_t_programma 		t_programma,
                siac_t_cronop 			t_cronop
        where		gruppo.set_cronop_code		=	p_set_id
        and			gruppo.set_cronop_id		=	r_gruppo_crono.set_cronop_id
        and			r_gruppo_crono.cronop_id	=	t_cronop.cronop_id
        and			r_gruppo_crono.usa_gestione	= FALSE
        and			r_gruppo_crono.programma_id	=	t_programma.programma_id
        and			gruppo.bil_id				=	bil.bil_id
        and			bil.periodo_id				=	periodo.periodo_id
        and			periodo.anno				=	p_anno_bilancio
        and			gruppo.ente_proprietario_id	=	p_ente_prop_id
        and			bil.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			periodo.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_programma.ente_proprietario_id =	gruppo.ente_proprietario_id
        and			t_cronop.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			gruppo.data_cancellazione		is null
        and			r_gruppo_crono.data_cancellazione	is null 
        and			bil.data_cancellazione			is null
        and			periodo.data_cancellazione		is null
        and			t_programma.data_cancellazione			is null
        and			t_cronop.data_cancellazione			is null
        order by gestione_flag,programma_id,cronop_id;	       
 
 RTN_MESSAGGIO:='inserimento tabella di comodo dove usa gestione = true '||p_set_id||'.';    
 insert into siac_rep_set_cronop_fpv
 select 		gruppo.set_cronop_code			set_code,
                gruppo.set_cronop_desc			descr_set,
                gruppo.set_cronop_id			set_id,
                r_gruppo_crono.cronop_id		cronop_id,
                r_gruppo_crono.programma_id		programma_id,
                r_gruppo_crono.set_cronop_id	id_r_set_cronop,
                r_gruppo_crono.usa_gestione		gestione_flag,
                t_programma.programma_code		programma_codice,
                t_programma.programma_desc		programma_descrizione,
                ' ',
                ' ',
                p_ente_prop_id					ente,
                user_table	 					utente
    from   		siac_t_fpv_set_cronop 	gruppo,  	
                siac_r_fpv_set_cronop	r_gruppo_crono,
                siac_t_bil				bil,
                siac_t_periodo 			periodo, 
                siac_t_programma 		t_programma
        where		gruppo.set_cronop_code		=	p_set_id
        and			gruppo.set_cronop_id		=	r_gruppo_crono.set_cronop_id
        and			r_gruppo_crono.usa_gestione	= TRUE
        and			r_gruppo_crono.programma_id	=	t_programma.programma_id
        and			gruppo.bil_id				=	bil.bil_id
        and			bil.periodo_id				=	periodo.periodo_id
        and			periodo.anno				=	p_anno_bilancio
        and			gruppo.ente_proprietario_id	=	p_ente_prop_id
        and			bil.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			periodo.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_programma.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			gruppo.data_cancellazione		is null
        and			r_gruppo_crono.data_cancellazione is null 
        and			bil.data_cancellazione			is null
        and			periodo.data_cancellazione		is null
        and			t_programma.data_cancellazione	is null
        order by gestione_flag,programma_id,cronop_id;	

if p_gestione = 'NO' THEN
	BEGIN
    RTN_MESSAGGIO:='lettura tabella di comodo ''.';  
   -- contaChiamate:=0;
	for setRec in
		select 	set_code				codice_set,
  				descr_set				descrizione_set,
  				set_id					id_set,
 				cronop_id				id_cronop,
   				programma_id			id_programma,
   				id_r_set_cronop			r_set_cronop_id,
   				gestione_flag			flag_gestione,
   				programma_codice		codice_programma,
  				programma_descrizione	descrizione_programma,
   				cronop_codice			codice_cronop,
  				cronop_descrizione		descrizione_cronop,
 				ente,
  				utente
    	from siac_rep_set_cronop_fpv
    	loop
        	if setRec.flag_gestione = false then
        		BEGIN
        --contaChiamate:=contaChiamate+1;
        --raise notice 'Chiamata %',contaChiamate;
                RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_spesa_previsione - param =  '||setRec.id_cronop||'.'||p_anno_bilancio||'.';
            	for setRecPro in
                -- 17/10/2017: procedura cambiata, tolto parametro anno bilancio
                    --SELECT * from fnc_siac_fpv_spesa_previsione(setRec.id_cronop,p_anno_bilancio)
                    SELECT * from fnc_siac_fpv_spesa_previsione(setRec.id_cronop) a
                    WHERE a.anno_out::INTEGER >= p_anno_bilancio::INTEGER
                    loop 
                    raise notice '<<<  ------->>>>   1    codice programma % >>>', setRec.codice_programma ;
        			raise notice '<<<  ------->>>>>  1     codice cronoprogramma % >>>', setRec.codice_cronop ;
                        id_set:=setRec.id_set;
        				codice_set:=setRec.codice_set;
        				descrizione_set:=setRec.descrizione_set;
        				id_programma:=setRec.id_programma;
        				id_cronop:=setRec.id_cronop;
       					descrizione_programma:=setRec.descrizione_programma;
						descrizione_cronop:=setRec.descrizione_cronop;
                        anno_out:=setRecPro.anno_out;
      			 		missione:=setRecPro.missione;
  				      	programma:=setRecPro.programma;
 				       	titolo:=setRecPro.titolo;
 			    		spesa_prevista:=setRecPro.spesa_prevista;
			        	fpv_spesa:=setRecPro.fpv_spesa;
                        codice_programma:=setRec.codice_programma;
                        codice_cronop:=setRec.codice_cronop;
                        if setRec.flag_gestione = false then
         					tipo='PREVISIONE';
        				ELSE
    						tipo='GESTIONE';
  						end if;
                        return next;
                        missione='';
  						programma='';
       					titolo='';
        				spesa_prevista=0;
        				fpv_spesa=0; 
        			end loop;
            	end;
            ELSE
            	BEGIN
                	RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_spesa - param =  '||setRec.id_programma||'.'||p_anno_bilancio||'.';
      				for setRecPro in
                    SELECT * from fnc_siac_fpv_spesa(setRec.id_programma,p_anno_bilancio)
    					loop 
                        id_set:=setRec.id_set;
        				codice_set:=setRec.codice_set;
        				descrizione_set:=setRec.descrizione_set;
        				id_programma:=setRec.id_programma;
        				id_cronop:=setRec.id_cronop;
       					descrizione_programma:=setRec.descrizione_programma;
						descrizione_cronop:=setRec.descrizione_cronop;
                        anno_out:=setRecPro.anno_out;
      			 		missione:=setRecPro.missione;
  				      	programma:=setRecPro.programma;
 				       	titolo:=setRecPro.titolo;
 			    		spesa_prevista:=setRecPro.spesa_prevista;
			        	fpv_spesa:=setRecPro.fpv_spesa;
                        codice_programma:=setRec.codice_programma;
                        codice_cronop:=setRec.codice_cronop; 
				   		tipo='GESTIONE';
                        return next;
                        missione='';
  						programma='';
       					titolo='';
        				spesa_prevista=0;
        				fpv_spesa=0; 
        			end loop;
                end;    
            end if;
        end loop;
    end;

--------------------------------------------------------------------------------------------------------------------------------
ELSE
		 raise notice '<<<  gestione uguale a si >>>' ;
  BEGIN
  		RTN_MESSAGGIO:='Lettura tabella siac_rep_set_cronop_fpv flag = true';
  		for setRec in
        select  set_code				codice_set,
  				descr_set				descrizione_set,
  				set_id					id_set,
 				cronop_id				id_cronop,
   				programma_id			id_programma,
   				id_r_set_cronop			r_set_cronop_id,
   				gestione_flag			flag_gestione,
   				programma_codice		codice_programma,
  				programma_descrizione	descrizione_programma,
   				cronop_codice			codice_cronop,
  				cronop_descrizione		descrizione_cronop,
                ente,
  				utente
  		from     siac_rep_set_cronop_fpv a   	where a.gestione_flag = TRUE
    		loop 
            
            	BEGIN
                	RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_spesa - param =  '||setRec.id_programma||'.'||p_anno_bilancio||'.';
      				for setRecPro in 
                    SELECT * from fnc_siac_fpv_spesa(setRec.id_programma,p_anno_bilancio)
    					loop 
                        raise notice '<<<  ------->>>>   2    codice programma % >>>', setRec.codice_programma ;
        				raise notice '<<<  ------->>>>>  2     codice cronoprogramma % >>>', setRec.codice_cronop ;
                        id_set:=setRec.id_set;
        				codice_set:=setRec.codice_set;
        				descrizione_set:=setRec.descrizione_set;
        				id_programma:=setRec.id_programma;
        				id_cronop:=setRec.id_cronop;
       					descrizione_programma:=setRec.descrizione_programma;
						descrizione_cronop:=setRec.descrizione_cronop;
                        anno_out:=setRecPro.anno_out;
      			 		missione:=setRecPro.missione;
  				      	programma:=setRecPro.programma;
 				       	titolo:=setRecPro.titolo;
 			    		spesa_prevista:=setRecPro.spesa_prevista;
			        	fpv_spesa:=setRecPro.fpv_spesa;
                        codice_programma:=setRec.codice_programma;
                        codice_cronop:=setRec.codice_cronop; 
				   		tipo='GESTIONE';
                        return next;
                        missione='';
  						programma='';
       					titolo='';
        				spesa_prevista=0;
        				fpv_spesa=0; 
        				end loop;
                end;
 			end loop;
    end;
end if;    
delete from siac_rep_set_cronop_fpv where  utente = user_table;
	exception
	when no_data_found THEN
		raise notice '<<<  set fpv non trovato >>>' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
raise notice 'fine OK';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

CREATE OR REPLACE FUNCTION siac."BILR060_fpv_entrate_sintetico" (
  p_ente_prop_id integer,
  p_set_id varchar,
  p_anno_bilancio varchar,
  p_gestione varchar
)
RETURNS TABLE (
  anno_out varchar,
  id_set integer,
  codice_set varchar,
  descrizione_set varchar,
  id_programma integer,
  codice_programma varchar,
  descrizione_programma varchar,
  id_cronop integer,
  codice_cronop varchar,
  descrizione_cronop varchar,
  entrata_prevista numeric,
  fpv_entrata_spesa_corrente numeric,
  fpv_entrata_spesa_conto_capitale numeric,
  totale numeric,
  fpv_entrata_complessivo numeric,
  tipo varchar
) AS
$body$
DECLARE
setRec record;
setrecpro record;


DEF_NULL	constant 	varchar:='';
def_spazio	constant 	varchar:=' ';  
RTN_MESSAGGIO 			varchar(1000):=DEF_NULL;
flag_gestione			VARCHAR;
--codice_programma		VARCHAR;
--codice_cronop			VARCHAR;
r_set_cronop_id 		INTEGER;
ente_proprietario_id 	INTEGER;
user_table 				VARCHAR;

BEGIN
anno_out='';
id_set=0;
codice_set='';
descrizione_set='';
id_programma=0;
id_cronop=0;
entrata_prevista=0;
fpv_entrata_spesa_corrente=0;
fpv_entrata_spesa_conto_capitale=0;
totale=0;
fpv_entrata_complessivo=0;
descrizione_programma='';
descrizione_cronop='';
codice_programma='';   

select fnc_siac_random_user()
into	user_table;
RTN_MESSAGGIO:='inserimento tabella di comodo dove usa gestione = false '||p_set_id||'.';
insert into siac_rep_set_cronop_fpv
 select 		gruppo.set_cronop_code			set_code,
                gruppo.set_cronop_desc			descr_set,
                gruppo.set_cronop_id			set_id,
                r_gruppo_crono.cronop_id		cronop_id,
                r_gruppo_crono.programma_id		programma_id,
                r_gruppo_crono.set_cronop_id	id_r_set_cronop,
                r_gruppo_crono.usa_gestione		gestione_flag,
                t_programma.programma_code		programma_codice,
                t_programma.programma_desc		programma_descrizione,
                t_cronop.cronop_code			cronop_codice,
                t_cronop.cronop_desc			cronop_descrizione,
                p_ente_prop_id					ente,
                user_table 						utente
    from   		siac_t_fpv_set_cronop 	gruppo,  	
                siac_r_fpv_set_cronop	r_gruppo_crono,
                siac_t_bil				bil,
                siac_t_periodo 			periodo, 
                siac_t_programma 		t_programma,
                siac_t_cronop 			t_cronop
        where		gruppo.set_cronop_code		=	p_set_id
        and			gruppo.set_cronop_id		=	r_gruppo_crono.set_cronop_id
        and			r_gruppo_crono.cronop_id	=	t_cronop.cronop_id
        and			r_gruppo_crono.usa_gestione	= FALSE
        and			r_gruppo_crono.programma_id	=	t_programma.programma_id
        and			gruppo.bil_id				=	bil.bil_id
        and			bil.periodo_id				=	periodo.periodo_id
        and			periodo.anno				=	p_anno_bilancio
        and			gruppo.ente_proprietario_id	=	p_ente_prop_id
        and			bil.ente_proprietario_id		=	gruppo.ente_proprietario_id
        and			periodo.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_programma.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_cronop.ente_proprietario_id		=	gruppo.ente_proprietario_id
        and			gruppo.data_cancellazione		is null
        and 		r_gruppo_crono.data_cancellazione is null 
        and			bil.data_cancellazione			is null
        and			periodo.data_cancellazione		is null
        and			t_programma.data_cancellazione			is null
        and			t_cronop.data_cancellazione			is null
        order by gestione_flag,id_programma,id_cronop;	
        
 RTN_MESSAGGIO:='inserimento tabella di comodo dove usa gestione = true '||p_set_id||'.';        
 insert into siac_rep_set_cronop_fpv
 select 		gruppo.set_cronop_code			set_code,
                gruppo.set_cronop_desc			descr_set,
                gruppo.set_cronop_id			set_id,
                r_gruppo_crono.cronop_id		cronop_id,
                r_gruppo_crono.programma_id		programma_id,
                r_gruppo_crono.set_cronop_id	id_r_set_cronop,
                r_gruppo_crono.usa_gestione		gestione_flag,
                COALESCE(t_programma.programma_code,'')		programma_codice,
                COALESCE(t_programma.programma_desc,'')		programma_descrizione,
                ' ',
                ' ',
                p_ente_prop_id					ente,
                user_table 						utente
    from   		siac_t_fpv_set_cronop 	gruppo,  	
                siac_r_fpv_set_cronop	r_gruppo_crono,
                siac_t_bil				bil,
                siac_t_periodo 			periodo, 
                siac_t_programma 		t_programma
        where		gruppo.set_cronop_code		=	p_set_id
        and			gruppo.set_cronop_id		=	r_gruppo_crono.set_cronop_id
        and			r_gruppo_crono.usa_gestione	= TRUE
        and			r_gruppo_crono.programma_id	=	t_programma.programma_id
        and			gruppo.bil_id				=	bil.bil_id
        and			bil.periodo_id				=	periodo.periodo_id
        and			periodo.anno				=	p_anno_bilancio
        and			gruppo.ente_proprietario_id	=	p_ente_prop_id
        and			bil.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			periodo.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_programma.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			gruppo.data_cancellazione		is null
        and			r_gruppo_crono.data_cancellazione is null
        and			bil.data_cancellazione			is null
        and			periodo.data_cancellazione		is null
        and			t_programma.data_cancellazione	is null
        order by gestione_flag,programma_id,cronop_id;	

if p_gestione = 'NO' THEN
	 raise notice '<<<  gestione uguale a no >>>' ;
     RTN_MESSAGGIO:='lettura tabella di comodo ''.';  
	BEGIN
	for setRec in
	select 		set_code				codice_set,
  				descr_set				descrizione_set,
  				set_id					id_set,
 				cronop_id				id_cronop,
   				programma_id			id_programma,
   				id_r_set_cronop			r_set_cronop_id,
   				gestione_flag			flag_gestione,
   				COALESCE(programma_codice,'')		codice_programma,
  				COALESCE(programma_descrizione,'')	descrizione_programma,
   				COALESCE(cronop_codice,'')			codice_cronop,
  				COALESCE(cronop_descrizione,'')		descrizione_cronop,
 				ente,
  				utente
    from siac_rep_set_cronop_fpv
    loop 
    	if setRec.flag_gestione = false then
        	BEGIN
            	RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_entrata_previsione - param =  '||setRec.id_cronop||'.'||p_anno_bilancio||'.';
         	for setRecPro in 
            -- 17/10/2017: procedura cambiata, tolto parametro anno bilancio
             --SELECT * from  fnc_siac_fpv_entrata_previsione(setrec.id_cronop,p_anno_bilancio)
             SELECT * from  fnc_siac_fpv_entrata_previsione(setrec.id_cronop) a
             WHERE a.anno_out::INTEGER >= p_anno_bilancio::INTEGER
             loop
             
              raise notice '<<<  descrizione programma--- punto 1 >>> %',setRec.descrizione_programma;
              raise notice '<<<  ------->>>>>  1     codice cronoprogramma % >>>', setRec.codice_cronop ;
             	id_set:=setRec.id_set;
        		codice_set:=setRec.codice_set;
        		descrizione_set:=setRec.descrizione_set;
        		id_programma:=setRec.id_programma;
        		id_cronop:=setRec.id_cronop;
        		descrizione_programma:=setRec.descrizione_programma;
				descrizione_cronop:=setRec.descrizione_cronop;
        		anno_out:=setRecPro.anno_out;
        		entrata_prevista:=setRecPro.entrata_prevista;
        		--fpv_entrata_spesa_corrente:=setRecPro.fpv_entrata_spesa_corrente;
                fpv_entrata_spesa_corrente:=setRecPro.spesa_corrente;
        		--fpv_entrata_spesa_conto_capitale:=setRecPro.fpv_entrata_spesa_conto_capitale;
                fpv_entrata_spesa_conto_capitale:=setRecPro.spesa_conto_capitale;
        		--totale:=setRecPro.totale;
                totale:=setRecPro.totale_spese;
        		--fpv_entrata_complessivo:=setRecPro.fpv_entrata_complessivo;
                fpv_entrata_complessivo:=setRecPro.fpv_entrata;
                codice_programma:=setRec.codice_programma;
                codice_cronop:=setRec.codice_cronop;
        		if setRec.flag_gestione = false then
         			tipo='PREVISIONE';
         		ELSE
    				tipo='GESTIONE';
  				end if;
        		return next;
        		anno_out='';
        		id_set=0;
        		codice_set='';
        		descrizione_set='';
        		id_programma=0;
        		id_cronop=0;
        		entrata_prevista=0;
        		fpv_entrata_spesa_corrente=0;
        		fpv_entrata_spesa_conto_capitale=0;
        		totale=0;
        		fpv_entrata_complessivo=0;
        		descrizione_programma='';
        		descrizione_cronop=''; 
        		tipo='';
             end loop;
            end;
         ELSE
         	BEGIN
            RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_entrata - param =  '||setRec.id_programma||'.'||p_anno_bilancio||'.';
            for setRecPro in 
    		SELECT 	* from fnc_siac_fpv_entrata(setrec.id_programma,p_anno_bilancio)
            loop
            	              raise notice '<<<  descrizione programma punto 2 >>> %',setRec.descrizione_programma;
            	id_set:=setRec.id_set;
        		codice_set:=setRec.codice_set;
        		descrizione_set:=setRec.descrizione_set;
        		id_programma:=setRec.id_programma;
        		id_cronop:=setRec.id_cronop;
        		descrizione_programma:=setRec.descrizione_programma;
				descrizione_cronop:=setRec.descrizione_cronop;
        		anno_out:=setRecPro.anno_out;
        		entrata_prevista:=setRecPro.entrata_prevista;
        		fpv_entrata_spesa_corrente:=setRecPro.fpv_entrata_spesa_corrente;
        		fpv_entrata_spesa_conto_capitale:=setRecPro.fpv_entrata_spesa_conto_capitale;
        		totale:=setRecPro.totale;
        		fpv_entrata_complessivo:=setRecPro.fpv_entrata_complessivo;
                codice_programma:=setRec.codice_programma;
                codice_cronop:=setRec.codice_cronop;
                tipo='GESTIONE';
                
        		return next;
                
        		anno_out='';
        		id_set=0;
        		codice_set='';
        		descrizione_set='';
        		id_programma=0;
        		id_cronop=0;
        		entrata_prevista=0;
        		fpv_entrata_spesa_corrente=0;
        		fpv_entrata_spesa_conto_capitale=0;
        		totale=0;
        		fpv_entrata_complessivo=0;
        		descrizione_programma='';
        		descrizione_cronop=''; 
        		tipo='';
            end loop;
            end;
  		end if;
 	end loop;
    end;
  ELSE
  		 raise notice '<<<  gestione uguale a si >>>' ;
  BEGIN
  RTN_MESSAGGIO:='Lettura tabella siac_rep_set_cronop_fpv flag = true';
  for setRec in
  select  		set_code				codice_set,
  				descr_set				descrizione_set,
  				set_id					id_set,
 				cronop_id				id_cronop,
   				programma_id			id_programma,
   				id_r_set_cronop			r_set_cronop_id,
   				gestione_flag			flag_gestione,
   				programma_codice		codice_programma,
  				programma_descrizione	descrizione_programma,
   				cronop_codice			codice_cronop,
  				cronop_descrizione		descrizione_cronop,
                ente,
  				utente
  	from 
    siac_rep_set_cronop_fpv a   	where a.gestione_flag = TRUE
    loop
    BEGIN
    RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_entrata - param =  '||setRec.id_programma||'.'||p_anno_bilancio||'.';
		for setRecPro in 
      	SELECT *  from fnc_siac_fpv_entrata(setRec.id_programma,p_anno_bilancio)
		loop
                      raise notice '<<<  descrizione programma punto 3>>> %',setRec.descrizione_programma;
        id_set:=setRec.id_set;
        codice_set:=setRec.codice_set;
        descrizione_set:=setRec.descrizione_set;
        id_programma:=setRec.id_programma;
        id_cronop:=setRec.id_cronop;
        descrizione_programma:=setRec.descrizione_programma;
		descrizione_cronop:=setRec.descrizione_cronop;
        anno_out:=setRecPro.anno_out;
        entrata_prevista:=setRecPro.entrata_prevista;
        fpv_entrata_spesa_corrente:=setRecPro.fpv_entrata_spesa_corrente;
        fpv_entrata_spesa_conto_capitale:=setRecPro.fpv_entrata_spesa_conto_capitale;
        totale:=setRecPro.totale;
        fpv_entrata_complessivo:=setRecPro.fpv_entrata_complessivo;
        codice_programma:=setRec.codice_programma;
        codice_cronop:=setRec.codice_cronop; 
    	tipo='GESTIONE';
        		return next;
        anno_out='';
        id_set=0;
        codice_set='';
        descrizione_set='';
        id_programma=0;
        id_cronop=0;
        entrata_prevista=0;
        fpv_entrata_spesa_corrente=0;
        fpv_entrata_spesa_conto_capitale=0;
        totale=0;
        fpv_entrata_complessivo=0;
        descrizione_programma='';
        descrizione_cronop=''; 
        tipo='';
        end loop;
    end;
 	end loop;
    end;  
  end if;
  
  delete from siac_rep_set_cronop_fpv where  utente = user_table;
    
exception
	when no_data_found THEN
		raise notice '<<<  set fpv non trovato >>>' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='ricerca set fpv ===> ';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
raise notice 'fine OK';
return; 
    	
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-5396 FINE - Maurizio