/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_configura_report_ente (
  p_ente integer,
  p_anno_bil varchar
)
RETURNS void AS
$body$
DECLARE

login_operazione_data varchar;
login_operazione_loc varchar;
v_bil_id integer;
rec record;
rec2 record;
rec3 record;
competenza_anni integer;
v_repimp_importo      numeric;
currtiins integer;

BEGIN
login_operazione_data:=to_char(now(),'dd/mm/yyyy_hh24:mi:ss');
login_operazione_loc:= 'fnc_siac_bko_configura_report_ente NEW';
login_operazione_loc:= login_operazione_loc||' '||login_operazione_data;

v_bil_id := 0;

SELECT a.bil_id 
INTO  v_bil_id
FROM  siac_t_bil a, siac_t_periodo b
WHERE a.ente_proprietario_id = p_ente
AND   a.ente_proprietario_id= b.ente_proprietario_id
AND   a.periodo_id = b.periodo_id
AND   b.anno = p_anno_bil;

DELETE 
FROM  siac_r_report_importi_appo
WHERE ente_proprietario_id = p_ente;
/*AND   repimp_id IN ( SELECT b.repimp_id
                     FROM   siac_t_report_importi_appo b
                     WHERE  b.ente_proprietario_id = p_ente
                     AND    b.bil_id = v_bil_id
                    ); */

INSERT INTO siac_r_report_importi_appo
SELECT * 
FROM   siac_r_report_importi a
WHERE  a.ente_proprietario_id = p_ente;
/*AND    a.repimp_id IN ( SELECT b.repimp_id
                        FROM siac_t_report_importi_appo b
                        WHERE b.ente_proprietario_id = p_ente
                        AND   b.bil_id = v_bil_id
                      ); */ 

DELETE 
FROM  siac_t_report_importi_appo
WHERE ente_proprietario_id = p_ente;
--AND   bil_id = v_bil_id;

INSERT INTO siac_t_report_importi_appo
SELECT * 
FROM   siac_t_report_importi
WHERE  ente_proprietario_id = p_ente;
--AND    bil_id = v_bil_id;

DELETE 
FROM  siac_r_report_importi a
WHERE a.ente_proprietario_id = p_ente
AND   a.repimp_id in ( SELECT b.repimp_id
                       FROM siac_t_report_importi b
                       WHERE b.ente_proprietario_id = p_ente
                       AND   b.bil_id = v_bil_id
                      );  

DELETE 
FROM siac_t_report_importi
WHERE ente_proprietario_id = p_ente
AND   bil_id = v_bil_id;

FOR rec IN 
SELECT * 
FROM siac_t_report 
WHERE ente_proprietario_id = p_ente
AND data_cancellazione IS NULL 
ORDER BY rep_codice

LOOP

  --Trovo competenza anni (anno bilancio, anno bilancio + 1, anno bilancio + 2)
  SELECT rep_competenza_anni  
  INTO   competenza_anni
  FROM   bko_t_report_competenze 
  WHERE  rep_codice = rec.rep_codice;

  IF competenza_anni IS NULL THEN
     competenza_anni:=0;
  END IF;

  FOR i IN 0 .. competenza_anni - 1 LOOP
    -- Record da inserire tranne quelli già presenti
    -- I record presenti nella tabella SIAC_T_REPORT_IMPORTI non sono univoci per report
    -- ma sono comuni a più report per stesso numero di riga
    -- Se per due report lo stesso codice (repimp_codice) ha lo stesso numero
    -- di riga in tabella si avrà un solo record. 
    -- Se per due report lo stesso codice (repimp_codice) ha un diverso numero
    -- di riga in tabella si avranno diversi record.  
    FOR rec2 IN 
    SELECT DISTINCT 
    per.anno,
    bi.rep_codice, 
    bi.repimp_codice,
    bi.repimp_desc,
    bi.repimp_importo,
    bi.repimp_modificabile,
    bi.repimp_progr_riga, 
    bil.bil_id,
    per2.periodo_id,
    re.validita_inizio,
    re.validita_fine,
    re.ente_proprietario_id,
    login_operazione_loc
    FROM 
    bko_t_report_importi bi, 
    siac_t_report re,
    siac_t_bil bil , 
    siac_t_periodo per, 
    siac_d_periodo_tipo pt,
    siac_t_periodo per2, 
    siac_d_periodo_tipo pt2
    WHERE bi.rep_codice=re.rep_codice 
    AND re.ente_proprietario_id=rec.ente_proprietario_id
    AND re.ente_proprietario_id=bil.ente_proprietario_id
    AND re.ente_proprietario_id=per.ente_proprietario_id
    AND bil.periodo_id=per.periodo_id
    AND bil.data_cancellazione IS NULL
    AND per.periodo_tipo_id=pt.periodo_tipo_id
    AND pt.periodo_tipo_code='SY'
    AND pt2.periodo_tipo_code='SY'
    AND per2.ente_proprietario_id=per.ente_proprietario_id
    AND pt2.periodo_tipo_id=per2.periodo_tipo_id
    AND per2.anno::integer=per.anno::integer + i::integer
    AND re.rep_codice=rec.rep_codice
    AND per.anno = p_anno_bil
    AND NOT EXISTS
    (
    SELECT 1 
    FROM siac_t_report_importi d 
    WHERE d.repimp_codice=bi.repimp_codice
    AND d.repimp_modificabile=bi.repimp_modificabile 
    AND COALESCE(d.repimp_progr_riga,0)=COALESCE(bi.repimp_progr_riga,0)
    AND d.ente_proprietario_id=rec.ente_proprietario_id
    AND d.periodo_id=per2.periodo_id
    AND d.bil_id=bil.bil_id
    )
    ORDER BY 
    bil.bil_id,
    per2.periodo_id,
    bi.repimp_progr_riga,
    bi.repimp_codice
    
    LOOP
      -- Salvo l'importo presente prima della cancellazione dei dati per poi
      -- inserirlo nella tabella SIAC_T_REPORT_IMPORTI  
      v_repimp_importo      := 0;
      
      SELECT a.repimp_importo
      INTO  v_repimp_importo
      FROM  siac_t_report_importi_appo a, siac_t_report b, siac_r_report_importi_appo c,
            siac_t_bil d, siac_t_periodo e
      WHERE a.ente_proprietario_id = d.ente_proprietario_id
      AND   a.ente_proprietario_id = e.ente_proprietario_id
      AND   c.rep_id = b.rep_id
      AND   a.repimp_id = c.repimp_id
      AND   d.periodo_id = e.periodo_id
      AND   a.repimp_codice = rec2.repimp_codice
      --and   a.repimp_desc = rec2.repimp_desc
      --and   a.repimp_modificabile = rec2.repimp_modificabile
      --and   a.repimp_progr_riga = rec2.repimp_progr_riga
      AND   a.bil_id = rec2.bil_id
      AND   a.periodo_id = rec2.periodo_id    
      AND   a.ente_proprietario_id = rec2.ente_proprietario_id
      AND   b.rep_codice = rec2.rep_codice    
      AND   e.anno = rec2.anno;
         
      INSERT INTO 
      siac.siac_t_report_importi
      (
      repimp_codice,
      repimp_desc,
      repimp_importo,
      repimp_modificabile,
      repimp_progr_riga,
      bil_id,
      periodo_id,
      validita_inizio,
      validita_fine,
      ente_proprietario_id,
      login_operazione
      ) 
      VALUES
      (rec2.repimp_codice,
      rec2.repimp_desc,
      COALESCE(v_repimp_importo,0),
      rec2.repimp_modificabile,
      rec2.repimp_progr_riga, 
      rec2.bil_id,
      rec2.periodo_id,
      rec2.validita_inizio,
      rec2.validita_fine,
      rec2.ente_proprietario_id,
      login_operazione_loc);    
                        
      SELECT currval('siac_t_report_importi_repimp_id_seq') INTO currtiins;
                         
      INSERT INTO 
      siac.siac_r_report_importi
      (
      rep_id,
      repimp_id,
      posizione_stampa,
      validita_inizio,
      validita_fine,
      ente_proprietario_id,
      login_operazione
      )
      VALUES(
      rec.rep_id,
      currtiins,
      1,
      rec2.validita_inizio,
      rec2.validita_fine,
      rec2.ente_proprietario_id,
      login_operazione_loc
      )
      ;
      
    END LOOP;         
    
    -- Inserisco i dati nella SIAC_R_REPORT_IMPORTI anche per quei record 
    -- che non ho trattato in precedenza 
    FOR rec3 IN 
    SELECT DISTINCT 
    re.rep_id, 
    bi.repimp_codice,
    bi.repimp_desc,
    bi.repimp_importo,
    bi.repimp_modificabile,
    bi.repimp_progr_riga, 
    bil.bil_id,
    per2.periodo_id,
    re.validita_inizio,
    re.validita_fine,
    re.ente_proprietario_id,
    login_operazione_loc
    FROM 
    bko_t_report_importi bi, 
    siac_t_report re,
    siac_t_bil bil , 
    siac_t_periodo per, 
    siac_d_periodo_tipo pt,
    siac_t_periodo per2, 
    siac_d_periodo_tipo pt2
    WHERE bi.rep_codice=re.rep_codice 
    AND re.ente_proprietario_id=rec.ente_proprietario_id
    AND re.ente_proprietario_id=bil.ente_proprietario_id
    AND re.ente_proprietario_id=per.ente_proprietario_id
    AND bil.periodo_id=per.periodo_id
    AND bil.data_cancellazione IS NULL
    AND per.periodo_tipo_id=pt.periodo_tipo_id
    AND pt.periodo_tipo_code='SY'
    AND pt2.periodo_tipo_code='SY'
    AND per2.ente_proprietario_id=per.ente_proprietario_id
    AND pt2.periodo_tipo_id=per2.periodo_tipo_id
    AND per2.anno::integer=per.anno::integer + i::integer
    AND re.rep_codice=rec.rep_codice
    AND per.anno = p_anno_bil
    AND EXISTS
    (
    SELECT 1 
    FROM siac_t_report_importi d 
    WHERE d.repimp_codice=bi.repimp_codice
    AND d.repimp_modificabile=bi.repimp_modificabile 
    AND COALESCE(d.repimp_progr_riga,0)=COALESCE(bi.repimp_progr_riga,0)
    AND d.ente_proprietario_id=rec.ente_proprietario_id
    AND d.periodo_id=per2.periodo_id
    AND d.bil_id=bil.bil_id
    )
    ORDER BY 
    bil.bil_id,
    per2.periodo_id,
    bi.repimp_progr_riga,
    bi.repimp_codice
    LOOP
    
      INSERT INTO 
      siac.siac_r_report_importi
      (
      rep_id,
      repimp_id,
      posizione_stampa,
      validita_inizio,
      validita_fine,
      ente_proprietario_id,
      login_operazione
      ) 
      SELECT c.rep_id,g.repimp_id,1,g.validita_inizio,g.validita_fine,g.ente_proprietario_id,login_operazione_loc
      FROM 
      siac_t_report c, 
      bko_t_report_importi a, siac_t_report_importi g
      WHERE c.rep_codice=a.rep_codice
      AND a.repimp_codice=g.repimp_codice
      AND a.repimp_modificabile=g.repimp_modificabile
      AND COALESCE(g.repimp_progr_riga,0)=COALESCE(a.repimp_progr_riga,0)
      AND g.ente_proprietario_id=c.ente_proprietario_id 
      AND c.ente_proprietario_id=p_ente
      AND g.bil_id=rec3.bil_id
      AND g.periodo_id=rec3.periodo_id
      AND c.rep_id=REC.rep_id
      AND NOT EXISTS 
      (SELECT 1 
       FROM siac_r_report_importi r 
       WHERE r.rep_id=c.rep_id 
       AND g.repimp_id=r.repimp_id
      );
    
    END LOOP;
  
  END LOOP;

END LOOP;

EXCEPTION
WHEN no_data_found THEN
	raise notice 'nessun dato trovato';
WHEN others  THEN
	raise notice 'errore : %  - stato: % ', SQLERRM, SQLSTATE;
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;