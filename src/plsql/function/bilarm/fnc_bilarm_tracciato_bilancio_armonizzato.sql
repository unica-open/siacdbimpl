/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilarm_tracciato_bilancio_armonizzato (
  p_anno_elab varchar,
  p_ente_proprietario_id integer
)
RETURNS varchar AS
$body$
DECLARE

rec_tracciato_std record;
rec_tracciato_fpv record;
rec_tracciato_entrata record;
rec_movgest_ts record;
rec_imp_impegnato record;
rec_imp_cap record;
rec_imp_cap_entrata record;
rec_tracciato_fin record;
v_elab_id INTEGER;
v_elab_id_det INTEGER;
v_elab_id_temp INTEGER;
v_elab_id_det_temp INTEGER;
v_codice_istituto CONSTANT VARCHAR := '00001';
v_codice_ente VARCHAR;
v_ind_entrate_uscite VARCHAR; 
v_anno_residuo VARCHAR; 
v_descr_codifica_bilancio_pt1 VARCHAR;
v_descr_codifica_bilancio_pt2 VARCHAR;
v_importo_capitolo NUMERIC; 
v_importo_cassa NUMERIC; 
v_importo_cassa_entrata NUMERIC;
v_importo_impegnato NUMERIC; 
v_importo_fondo_vincolato NUMERIC; 
v_importo_capitolo_tot NUMERIC;
v_importo_cassa_tot NUMERIC;
v_importo_impegnato_tot NUMERIC;
v_importo_fondo_vincolato_tot NUMERIC; 
v_classif_code VARCHAR;
v_movgest_ts_tipo_code VARCHAR; 
v_blank VARCHAR;
v_codresult INTEGER := null;
v_fase_operativa_code_std VARCHAR; 
v_fase_operativa_code_fpv VARCHAR;

elab_mif_esito_in CONSTANT  VARCHAR := 'IN';
elab_mif_esito_ok CONSTANT  VARCHAR := 'OK';
elab_mif_esito_ko CONSTANT  VARCHAR := 'KO';
v_tipo_flusso  CONSTANT  VARCHAR := 'BILARM';
v_login CONSTANT  VARCHAR := 'SIAC';
v_classif_prg CONSTANT  VARCHAR := 'PROGRAMMA';
v_classif_titolo CONSTANT  VARCHAR := 'MACROAGGREGATO';
v_classif_tipologia CONSTANT  VARCHAR := 'CATEGORIA';
v_entrate CONSTANT  VARCHAR := 'CAP-EG';
v_spese CONSTANT  VARCHAR := 'CAP-UG';
v_elem_valido CONSTANT  VARCHAR := 'VA'; 
v_elem_cat_std CONSTANT  VARCHAR := 'STD'; 
v_elem_cat_fpv CONSTANT  VARCHAR := 'FPV'; 
v_elem_det_sta CONSTANT  VARCHAR := 'STA';
v_elem_det_str CONSTANT  VARCHAR := 'STR';
v_elem_det_sca CONSTANT  VARCHAR := 'SCA';
messaggioRisultato VARCHAR;

BEGIN

-- Inserimento record in tabella mif_t_flusso_elaborato
INSERT INTO mif_t_flusso_elaborato
(flusso_elab_mif_data,
 flusso_elab_mif_esito,
 flusso_elab_mif_esito_msg,
 flusso_elab_mif_file_nome,
 flusso_elab_mif_tipo_id,
 flusso_elab_mif_id_flusso_oil,
 validita_inizio,
 ente_proprietario_id,
 login_operazione)
 (SELECT now(),
         elab_mif_esito_in,
         'Elaborazione in corso per tipo flusso '||v_tipo_flusso,
         tipo.flusso_elab_mif_nome_file,
         tipo.flusso_elab_mif_tipo_id,
         null, -- flussoElabMifOilId, -- non usato per questo tipo di flusso
         now(),
         p_ente_proprietario_id,
         v_login
  FROM mif_d_flusso_elaborato_tipo tipo
  WHERE tipo.ente_proprietario_id = p_ente_proprietario_id
  AND   tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
  AND   tipo.data_cancellazione IS NULL
  AND   tipo.validita_fine IS NULL
 )
 RETURNING flusso_elab_mif_id into v_elab_id;

IF p_anno_elab IS NULL THEN
   messaggioRisultato := 'Parametro Anno di Elaborazione nullo.';
   -- RETURN NEXT;
   -- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
   UPDATE  mif_t_flusso_elaborato
   SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
       (elab_mif_esito_ko,'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato, now())
   WHERE flusso_elab_mif_id = v_elab_id;
   RETURN messaggioRisultato;
END IF;

IF p_ente_proprietario_id IS NULL THEN
   messaggioRisultato := 'Parametro Ente Propietario nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF v_elab_id IS NULL THEN
  messaggioRisultato := 'Errore generico in inserimento';
  -- RETURN NEXT;  
  RETURN messaggioRisultato;
END IF;

v_codresult:=null;
-- Verifica esistenza elaborazioni in corso per tipo flusso
SELECT DISTINCT 1 
INTO v_codresult
FROM mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
WHERE  elab.flusso_elab_mif_id != v_elab_id
AND    elab.flusso_elab_mif_esito = elab_mif_esito_in
AND    elab.data_cancellazione IS NULL
AND    elab.validita_fine IS NULL
AND    tipo.flusso_elab_mif_tipo_id = elab.flusso_elab_mif_tipo_id
AND    tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
AND    tipo.ente_proprietario_id = p_ente_proprietario_id
AND    tipo.data_cancellazione IS NULL
AND    tipo.validita_fine IS NULL;

IF v_codresult IS NOT NULL THEN
   messaggioRisultato := 'Verificare situazioni esistenti.';
   -- RETURN NEXT;
   -- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
   UPDATE  mif_t_flusso_elaborato
   SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
       (elab_mif_esito_ko,'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato, now())
   WHERE flusso_elab_mif_id = v_elab_id;
   RETURN messaggioRisultato;  
END IF;

v_codice_ente := LPAD(p_ente_proprietario_id::varchar, 7, '0');
v_blank := LPAD(' ',45,' ');
v_elab_id_det := 1;
v_elab_id_det_temp := 1;

v_importo_capitolo := 0;
v_importo_cassa := 0; 
v_importo_cassa_entrata := 0;
v_importo_impegnato := 0; 
v_importo_fondo_vincolato := 0;
v_importo_capitolo_tot := 0;
v_importo_cassa_tot := 0;
v_importo_impegnato_tot := 0;
v_importo_fondo_vincolato_tot := 0; 

DELETE FROM siac.bilarm_tracciato_temp
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   anno = p_anno_elab;

-- Parte relativa a elem_cat_code = 'STD'
FOR rec_tracciato_std IN
WITH a AS (
SELECT tb.ente_proprietario_id, tp.anno, tbe.elem_id, tbe.elem_code, tc.classif_code, tc.classif_desc, dct.classif_tipo_code, dbet.elem_tipo_code, dbec.elem_cat_code, tb.periodo_id, tbe.bil_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
INNER JOIN siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
INNER JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
INNER JOIN siac.siac_r_bil_elem_class srbec ON srbec.elem_id = tbe.elem_id
INNER JOIN siac.siac_t_class tc ON tc.classif_id = srbec.classif_id
INNER JOIN siac.siac_d_class_tipo dct ON dct.classif_tipo_id = tc.classif_tipo_id
WHERE tb.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dct.classif_tipo_code in (v_classif_prg, v_classif_titolo)
AND   dbet.elem_tipo_code = v_spese
AND   dbes.elem_stato_code = v_elem_valido
AND   dbec.elem_cat_code = v_elem_cat_std
AND now() BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, now())
AND tbe.data_cancellazione IS NULL
AND now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND tb.data_cancellazione IS NULL
AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND tp.data_cancellazione IS NULL
AND now() BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, now())
AND dbet.data_cancellazione IS NULL
AND now() BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, now())
AND rbes.data_cancellazione IS NULL
AND now() BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, now())
AND dbes.data_cancellazione IS NULL
AND now() BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, now())
AND rbec.data_cancellazione IS NULL
AND now() BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, now())
AND dbec.data_cancellazione IS NULL
AND now() BETWEEN srbec.validita_inizio AND COALESCE(srbec.validita_fine, now())
AND srbec.data_cancellazione IS NULL
AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
AND tc.data_cancellazione IS NULL
AND now() BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, now())
AND dct.data_cancellazione IS NULL)
, b AS (
SELECT tb.ente_proprietario_id, tp.anno, tbe.elem_id, tbe.elem_code, tc.classif_code, tc.classif_desc, dct.classif_tipo_code, dbet.elem_tipo_code, dbec.elem_cat_code, tb.periodo_id, tbe.bil_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
INNER JOIN siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
INNER JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
INNER JOIN siac.siac_r_bil_elem_class srbec ON srbec.elem_id = tbe.elem_id
INNER JOIN siac.siac_t_class tc ON tc.classif_id = srbec.classif_id
INNER JOIN siac.siac_d_class_tipo dct ON dct.classif_tipo_id = tc.classif_tipo_id
WHERE tb.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dct.classif_tipo_code = v_classif_prg
AND   dbet.elem_tipo_code = v_spese
AND   dbes.elem_stato_code = v_elem_valido
AND   dbec.elem_cat_code = v_elem_cat_std
AND now() BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, now())
AND tbe.data_cancellazione IS NULL
AND now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND tb.data_cancellazione IS NULL
AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND tp.data_cancellazione IS NULL
AND now() BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, now())
AND dbet.data_cancellazione IS NULL
AND now() BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, now())
AND rbes.data_cancellazione IS NULL
AND now() BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, now())
AND dbes.data_cancellazione IS NULL
AND now() BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, now())
AND rbec.data_cancellazione IS NULL
AND now() BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, now())
AND dbec.data_cancellazione IS NULL
AND now() BETWEEN srbec.validita_inizio AND COALESCE(srbec.validita_fine, now())
AND srbec.data_cancellazione IS NULL
AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
AND tc.data_cancellazione IS NULL
AND now() BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, now())
AND dct.data_cancellazione IS NULL)
, c AS (
SELECT tb.ente_proprietario_id, tp.anno, tbe.elem_id, tbe.elem_code, stc.classif_code, stc.classif_desc, dct.classif_tipo_code, dbet.elem_tipo_code, dbec.elem_cat_code, tb.periodo_id, tbe.bil_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
INNER JOIN siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
INNER JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
INNER JOIN siac.siac_r_bil_elem_class srbec ON srbec.elem_id = tbe.elem_id
INNER JOIN siac.siac_t_class tc ON tc.classif_id = srbec.classif_id
INNER JOIN siac.siac_d_class_tipo dct ON dct.classif_tipo_id = tc.classif_tipo_id
INNER JOIN siac.siac_r_class_fam_tree rcft ON rcft.classif_id = tc.classif_id
INNER JOIN siac.siac_t_class stc ON stc.classif_id = rcft.classif_id_padre
WHERE tb.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dct.classif_tipo_code = v_classif_titolo
AND   dbet.elem_tipo_code = v_spese
AND   dbes.elem_stato_code = v_elem_valido
AND   dbec.elem_cat_code = v_elem_cat_std
AND now() BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, now())
AND tbe.data_cancellazione IS NULL
AND now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND tb.data_cancellazione IS NULL
AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND tp.data_cancellazione IS NULL
AND now() BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, now())
AND dbet.data_cancellazione IS NULL
AND now() BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, now())
AND rbes.data_cancellazione IS NULL
AND now() BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, now())
AND dbes.data_cancellazione IS NULL
AND now() BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, now())
AND rbec.data_cancellazione IS NULL
AND now() BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, now())
AND dbec.data_cancellazione IS NULL
AND now() BETWEEN srbec.validita_inizio AND COALESCE(srbec.validita_fine, now())
AND srbec.data_cancellazione IS NULL
AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
AND tc.data_cancellazione IS NULL
AND now() BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, now())
AND dct.data_cancellazione IS NULL
AND now() BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, now())
AND rcft.data_cancellazione IS NULL
AND now() BETWEEN stc.validita_inizio AND COALESCE(stc.validita_fine, now())
AND stc.data_cancellazione IS NULL)
SELECT
a.ente_proprietario_id, 
a.anno, 
a.elem_id, 
a.elem_code, 
a.elem_tipo_code,
a.elem_cat_code,
COALESCE(b.classif_code,'')||COALESCE(c.classif_code,'') cod_aggregazione,
COALESCE(b.classif_desc, ' ')||' '||COALESCE(c.classif_desc, ' ') desc_aggregazione, 
a.periodo_id,
a.bil_id
FROM a
LEFT JOIN b ON a.elem_id = b.elem_id
LEFT JOIN c ON a.elem_id = c.elem_id
GROUP BY  -- Nel caso uno stesso elem_id sia abbinato a più classificatori
a.ente_proprietario_id, 
a.anno, 
a.elem_id, 
a.elem_code, 
a.elem_tipo_code,
a.elem_cat_code,
COALESCE(b.classif_code,'')||COALESCE(c.classif_code,''),
COALESCE(b.classif_desc, ' ')||' '||COALESCE(c.classif_desc, ' '), 
a.periodo_id,
a.bil_id

LOOP

      SELECT dfo.fase_operativa_code
      INTO v_fase_operativa_code_std
      FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
      WHERE rbfo.bil_id = rec_tracciato_std.bil_id
      AND   dfo.fase_operativa_id = rbfo.fase_operativa_id
      AND   now() BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, now())
      AND   now() BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, now())
      AND   rbfo.data_cancellazione IS NULL
      AND   dfo.data_cancellazione IS NULL; 

      v_importo_impegnato := 0;    
      
      IF v_fase_operativa_code_std = 'E' THEN
        
        FOR rec_movgest_ts IN 
        SELECT tmt.movgest_ts_id, tmt.movgest_ts_tipo_id
        FROM siac.siac_r_movgest_bil_elem  mbe
        INNER JOIN siac.siac_t_movgest_ts tmt ON tmt.movgest_id = mbe.movgest_id 
        WHERE mbe.elem_id = rec_tracciato_std.elem_id
        AND now() BETWEEN mbe.validita_inizio AND COALESCE(mbe.validita_fine, now()) -- Si può eliminare questa condizione per velocizzare eventualmente la funzione
        AND mbe.data_cancellazione IS NULL      
        AND now() BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, now()) -- Si può eliminare questa condizione per velocizzare eventualmente la funzione
        AND tmt.data_cancellazione IS NULL 
              
        LOOP
                          
          SELECT dmtt.movgest_ts_tipo_code
          INTO v_movgest_ts_tipo_code
          FROM siac.siac_d_movgest_ts_tipo dmtt
          WHERE dmtt.movgest_ts_tipo_id = rec_movgest_ts.movgest_ts_tipo_id
          AND now() BETWEEN dmtt.validita_inizio AND COALESCE(dmtt.validita_fine, now()) -- Si può eliminare questa condizione per velocizzare eventualmente la funzione
          AND dmtt.data_cancellazione IS NULL;
          
          IF v_movgest_ts_tipo_code = 'T' THEN
          
            FOR rec_imp_impegnato IN 
            SELECT SUM(tmtd.movgest_ts_det_importo) importo_impegnato
            FROM siac.siac_t_movgest_ts_det tmtd
            INNER JOIN siac_d_movgest_ts_det_tipo tdt ON tmtd.movgest_ts_det_tipo_id = tdt.movgest_ts_det_tipo_id        
            INNER JOIN siac.siac_r_movgest_ts_stato rmts ON rmts.movgest_ts_id = tmtd.movgest_ts_id 
            INNER JOIN siac.siac_d_movgest_stato dms ON dms.movgest_stato_id = rmts.movgest_stato_id                                          
            WHERE tmtd.movgest_ts_id = rec_movgest_ts.movgest_ts_id
            AND  dms.movgest_stato_code not in ('A', 'P')
            AND   tdt.movgest_ts_det_tipo_code = 'A'                   
            AND now() BETWEEN tmtd.validita_inizio AND COALESCE(tmtd.validita_fine, now())
            AND tmtd.data_cancellazione IS NULL  
            AND now() BETWEEN rmts.validita_inizio AND COALESCE(rmts.validita_fine, now())
            AND rmts.data_cancellazione IS NULL  
            AND now() BETWEEN dms.validita_inizio AND COALESCE(dms.validita_fine, now())
            AND dms.data_cancellazione IS NULL
            AND now() BETWEEN tdt.validita_inizio AND COALESCE(tdt.validita_fine, now())
            AND tdt.data_cancellazione IS NULL
          
            LOOP
                v_importo_impegnato := v_importo_impegnato + rec_imp_impegnato.importo_impegnato;
            END LOOP;
            
          END IF;
        
        END LOOP;
      
      END IF;   
         
  FOR rec_imp_cap IN 
  SELECT bed.elem_det_importo, dbedt.elem_det_tipo_code
  FROM siac.siac_t_bil_elem_det bed
  INNER JOIN siac.siac_d_bil_elem_det_tipo dbedt ON dbedt.elem_det_tipo_id = bed.elem_det_tipo_id
  WHERE bed.elem_id = rec_tracciato_std.elem_id
  AND   bed.periodo_id = rec_tracciato_std.periodo_id
  AND   dbedt.elem_det_tipo_code in (v_elem_det_sta, v_elem_det_str)
  AND now() BETWEEN bed.validita_inizio AND COALESCE(bed.validita_fine, now())
  AND bed.data_cancellazione IS NULL
  AND now() BETWEEN dbedt.validita_inizio AND COALESCE(dbedt.validita_fine, now())
  AND dbedt.data_cancellazione IS NULL

  LOOP
    v_importo_cassa := 0; 
  	IF rec_imp_cap.elem_det_tipo_code = v_elem_det_sta THEN
            
      SELECT bed.elem_det_importo importo_cassa
      INTO v_importo_cassa
      FROM siac.siac_t_bil_elem_det bed
      INNER JOIN siac.siac_d_bil_elem_det_tipo dbedt ON dbedt.elem_det_tipo_id = bed.elem_det_tipo_id
      WHERE bed.elem_id = rec_tracciato_std.elem_id
      AND   bed.periodo_id = rec_tracciato_std.periodo_id
      AND dbedt.elem_det_tipo_code = v_elem_det_sca
      AND now() BETWEEN bed.validita_inizio AND COALESCE(bed.validita_fine, now())
      AND bed.data_cancellazione IS NULL
      AND now() BETWEEN dbedt.validita_inizio AND COALESCE(dbedt.validita_fine, now())
      AND dbedt.data_cancellazione IS NULL;
            
     ELSE
    
      v_importo_cassa := 0;
      v_importo_impegnato := 0;
    
    END IF;
  
  INSERT INTO siac.bilarm_tracciato_temp
      ( elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        anno,
        elem_id,
        elem_code,
        elem_cat_code,
        cod_aggregazione,
        desc_aggregazione,
        elem_det_tipo_code, 
        elem_tipo_code, 
        importo_capitolo,
        importo_cassa,
        importo_impegnato,
        importo_fondo_vincolato
      )
     VALUES
      ( v_elab_id,
        v_elab_id_det_temp,
        rec_tracciato_std.ente_proprietario_id,
        rec_tracciato_std.anno,
        rec_tracciato_std.elem_id,
        rec_tracciato_std.elem_code,
        rec_tracciato_std.elem_cat_code,
        LPAD(rec_tracciato_std.cod_aggregazione,7,'0'),
        rec_tracciato_std.desc_aggregazione,
        rec_imp_cap.elem_det_tipo_code, 
        rec_tracciato_std.elem_tipo_code, 
        rec_imp_cap.elem_det_importo,
        v_importo_cassa,
        v_importo_impegnato,
        0
      );         
  
  v_elab_id_det_temp := v_elab_id_det_temp + 1;
  
  END LOOP;

END LOOP;

-- Parte relativa a elem_cat_code = 'FPV'
FOR rec_tracciato_fpv IN
WITH a AS (
SELECT tb.ente_proprietario_id, tp.anno, tbe.elem_id, tbe.elem_code, tc.classif_code, dct.classif_tipo_code, dbet.elem_tipo_code, dbec.elem_cat_code, tb.periodo_id, tbe.bil_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
INNER JOIN siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
INNER JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
INNER JOIN siac.siac_r_bil_elem_class srbec ON srbec.elem_id = tbe.elem_id
INNER JOIN siac.siac_t_class tc ON tc.classif_id = srbec.classif_id
INNER JOIN siac.siac_d_class_tipo dct ON dct.classif_tipo_id = tc.classif_tipo_id
WHERE tb.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dct.classif_tipo_code in (v_classif_prg, v_classif_titolo)
AND   dbet.elem_tipo_code = v_spese
AND   dbes.elem_stato_code = v_elem_valido
AND   dbec.elem_cat_code = v_elem_cat_fpv
AND now() BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, now())
AND tbe.data_cancellazione IS NULL
AND now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND tb.data_cancellazione IS NULL
AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND tp.data_cancellazione IS NULL
AND now() BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, now())
AND dbet.data_cancellazione IS NULL
AND now() BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, now())
AND rbes.data_cancellazione IS NULL
AND now() BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, now())
AND dbes.data_cancellazione IS NULL
AND now() BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, now())
AND rbec.data_cancellazione IS NULL
AND now() BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, now())
AND dbec.data_cancellazione IS NULL
AND now() BETWEEN srbec.validita_inizio AND COALESCE(srbec.validita_fine, now())
AND srbec.data_cancellazione IS NULL
AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
AND tc.data_cancellazione IS NULL
AND now() BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, now())
AND dct.data_cancellazione IS NULL)
, b AS (
SELECT tb.ente_proprietario_id, tp.anno, tbe.elem_id, tbe.elem_code, tc.classif_code, dct.classif_tipo_code, dbet.elem_tipo_code, dbec.elem_cat_code, tb.periodo_id, tbe.bil_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
INNER JOIN siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
INNER JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
INNER JOIN siac.siac_r_bil_elem_class srbec ON srbec.elem_id = tbe.elem_id
INNER JOIN siac.siac_t_class tc ON tc.classif_id = srbec.classif_id
INNER JOIN siac.siac_d_class_tipo dct ON dct.classif_tipo_id = tc.classif_tipo_id
WHERE tb.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dct.classif_tipo_code = v_classif_prg
AND   dbet.elem_tipo_code = v_spese
AND   dbes.elem_stato_code = v_elem_valido
AND   dbec.elem_cat_code = v_elem_cat_fpv
AND now() BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, now())
AND tbe.data_cancellazione IS NULL
AND now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND tb.data_cancellazione IS NULL
AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND tp.data_cancellazione IS NULL
AND now() BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, now())
AND dbet.data_cancellazione IS NULL
AND now() BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, now())
AND rbes.data_cancellazione IS NULL
AND now() BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, now())
AND dbes.data_cancellazione IS NULL
AND now() BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, now())
AND rbec.data_cancellazione IS NULL
AND now() BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, now())
AND dbec.data_cancellazione IS NULL
AND now() BETWEEN srbec.validita_inizio AND COALESCE(srbec.validita_fine, now())
AND srbec.data_cancellazione IS NULL
AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
AND tc.data_cancellazione IS NULL
AND now() BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, now())
AND dct.data_cancellazione IS NULL)
, c AS (
SELECT tb.ente_proprietario_id, tp.anno, tbe.elem_id, tbe.elem_code, stc.classif_code, dct.classif_tipo_code, dbet.elem_tipo_code, dbec.elem_cat_code, tb.periodo_id, tbe.bil_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
INNER JOIN siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
INNER JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
INNER JOIN siac.siac_r_bil_elem_class srbec ON srbec.elem_id = tbe.elem_id
INNER JOIN siac.siac_t_class tc ON tc.classif_id = srbec.classif_id
INNER JOIN siac.siac_d_class_tipo dct ON dct.classif_tipo_id = tc.classif_tipo_id
INNER JOIN siac.siac_r_class_fam_tree rcft ON rcft.classif_id = tc.classif_id
INNER JOIN siac.siac_t_class stc ON stc.classif_id = rcft.classif_id_padre
WHERE tb.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dct.classif_tipo_code = v_classif_titolo
AND   dbet.elem_tipo_code = v_spese
AND   dbes.elem_stato_code = v_elem_valido
AND   dbec.elem_cat_code = v_elem_cat_fpv
AND now() BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, now())
AND tbe.data_cancellazione IS NULL
AND now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND tb.data_cancellazione IS NULL
AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND tp.data_cancellazione IS NULL
AND now() BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, now())
AND dbet.data_cancellazione IS NULL
AND now() BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, now())
AND rbes.data_cancellazione IS NULL
AND now() BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, now())
AND dbes.data_cancellazione IS NULL
AND now() BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, now())
AND rbec.data_cancellazione IS NULL
AND now() BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, now())
AND dbec.data_cancellazione IS NULL
AND now() BETWEEN srbec.validita_inizio AND COALESCE(srbec.validita_fine, now())
AND srbec.data_cancellazione IS NULL
AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
AND tc.data_cancellazione IS NULL
AND now() BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, now())
AND dct.data_cancellazione IS NULL
AND now() BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, now())
AND rcft.data_cancellazione IS NULL
AND now() BETWEEN stc.validita_inizio AND COALESCE(stc.validita_fine, now())
AND stc.data_cancellazione IS NULL)
SELECT
a.ente_proprietario_id, 
a.anno, 
a.elem_id, 
a.elem_code, 
a.elem_tipo_code,
a.elem_cat_code,
COALESCE(b.classif_code,'')||COALESCE(c.classif_code,'') cod_aggregazione,
a.periodo_id,
a.bil_id
FROM a
LEFT JOIN b ON a.elem_id = b.elem_id
LEFT JOIN c ON a.elem_id = c.elem_id
GROUP BY 
a.ente_proprietario_id, 
a.anno, 
a.elem_id, 
a.elem_code, 
a.elem_tipo_code,
a.elem_cat_code,
COALESCE(b.classif_code,'')||COALESCE(c.classif_code,''),
a.periodo_id,
a.bil_id

LOOP

  SELECT dfo.fase_operativa_code
  INTO v_fase_operativa_code_fpv
  FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
  WHERE rbfo.bil_id = rec_tracciato_fpv.bil_id
  AND   dfo.fase_operativa_id = rbfo.fase_operativa_id
  AND   now() BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, now())
  AND   now() BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, now())
  AND   rbfo.data_cancellazione IS NULL
  AND   dfo.data_cancellazione IS NULL; 

  v_importo_fondo_vincolato := 0;
  
  IF v_fase_operativa_code_fpv = 'E' THEN
  
      SELECT bed.elem_det_importo
      INTO v_importo_fondo_vincolato 
      FROM siac.siac_t_bil_elem_det bed
      INNER JOIN siac.siac_d_bil_elem_det_tipo dbedt ON dbedt.elem_det_tipo_id = bed.elem_det_tipo_id
      WHERE bed.elem_id = rec_tracciato_fpv.elem_id
      AND   bed.periodo_id = rec_tracciato_fpv.periodo_id
      AND   dbedt.elem_det_tipo_code = v_elem_det_sta
      AND now() BETWEEN bed.validita_inizio AND COALESCE(bed.validita_fine, now())
      AND bed.data_cancellazione IS NULL
      AND now() BETWEEN dbedt.validita_inizio AND COALESCE(dbedt.validita_fine, now())
      AND dbedt.data_cancellazione IS NULL;
      
  END IF;    

  INSERT INTO siac.bilarm_tracciato_temp
      ( elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        anno,
        elem_id,
        elem_code,
        elem_cat_code,
        cod_aggregazione,
        desc_aggregazione,
        elem_det_tipo_code, 
        elem_tipo_code, 
        importo_capitolo,
        importo_cassa,
        importo_impegnato,
        importo_fondo_vincolato
      )
     VALUES
      ( v_elab_id,
        v_elab_id_det_temp,
        rec_tracciato_fpv.ente_proprietario_id,
        rec_tracciato_fpv.anno,
        rec_tracciato_fpv.elem_id,
        rec_tracciato_fpv.elem_code,
        v_elem_cat_fpv, -- elem_cat_code,
        LPAD(rec_tracciato_fpv.cod_aggregazione,7,'0'),
        NULL, -- desc_aggregazione, -- Non necessario nel caso di FPV
        v_elem_det_sta, 
        rec_tracciato_fpv.elem_tipo_code, 
        0,
        0,
        0,
        v_importo_fondo_vincolato
      );   

      v_elab_id_det_temp := v_elab_id_det_temp + 1;

END LOOP;

-- Parte reltiva ai capitoli di entrata
FOR rec_tracciato_entrata IN
SELECT tb.ente_proprietario_id, tp.anno, tbe.elem_id, tbe.elem_code, stc.classif_code, stc.classif_desc, dct.classif_tipo_code, dbet.elem_tipo_code, dbec.elem_cat_code, tb.periodo_id
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
INNER JOIN siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
INNER JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
INNER JOIN siac.siac_r_bil_elem_class srbec ON srbec.elem_id = tbe.elem_id
INNER JOIN siac.siac_t_class tc ON tc.classif_id = srbec.classif_id
INNER JOIN siac.siac_d_class_tipo dct ON dct.classif_tipo_id = tc.classif_tipo_id
INNER JOIN siac.siac_r_class_fam_tree rcft ON rcft.classif_id = tc.classif_id
INNER JOIN siac.siac_t_class stc ON stc.classif_id = rcft.classif_id_padre
WHERE tb.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dct.classif_tipo_code = v_classif_tipologia
AND   dbet.elem_tipo_code = v_entrate
AND   dbes.elem_stato_code = v_elem_valido
AND   dbec.elem_cat_code = v_elem_cat_std
AND now() BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, now())
AND tbe.data_cancellazione IS NULL
AND now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND tb.data_cancellazione IS NULL
AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND tp.data_cancellazione IS NULL
AND now() BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, now())
AND dbet.data_cancellazione IS NULL
AND now() BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, now())
AND rbes.data_cancellazione IS NULL
AND now() BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, now())
AND dbes.data_cancellazione IS NULL
AND now() BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, now())
AND rbec.data_cancellazione IS NULL
AND now() BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, now())
AND dbec.data_cancellazione IS NULL
AND now() BETWEEN srbec.validita_inizio AND COALESCE(srbec.validita_fine, now())
AND srbec.data_cancellazione IS NULL
AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
AND tc.data_cancellazione IS NULL
AND now() BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, now())
AND dct.data_cancellazione IS NULL
AND now() BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, now())
AND rcft.data_cancellazione IS NULL
AND now() BETWEEN stc.validita_inizio AND COALESCE(stc.validita_fine, now())
AND stc.data_cancellazione IS NULL

LOOP

  FOR rec_imp_cap_entrata IN 
  SELECT bed.elem_det_importo, dbedt.elem_det_tipo_code
  FROM siac.siac_t_bil_elem_det bed
  INNER JOIN siac.siac_d_bil_elem_det_tipo dbedt ON dbedt.elem_det_tipo_id = bed.elem_det_tipo_id
  WHERE bed.elem_id = rec_tracciato_entrata.elem_id
  AND   bed.periodo_id = rec_tracciato_entrata.periodo_id
  AND   dbedt.elem_det_tipo_code in (v_elem_det_sta, v_elem_det_str)
  AND now() BETWEEN bed.validita_inizio AND COALESCE(bed.validita_fine, now())
  AND bed.data_cancellazione IS NULL
  AND now() BETWEEN dbedt.validita_inizio AND COALESCE(dbedt.validita_fine, now())
  AND dbedt.data_cancellazione IS NULL

  LOOP
  
    v_importo_cassa_entrata := 0;  
  	IF rec_imp_cap_entrata.elem_det_tipo_code = v_elem_det_sta THEN
        
      SELECT bed.elem_det_importo importo_cassa
      INTO v_importo_cassa_entrata
      FROM siac.siac_t_bil_elem_det bed
      INNER JOIN siac.siac_d_bil_elem_det_tipo dbedt ON dbedt.elem_det_tipo_id = bed.elem_det_tipo_id
      WHERE bed.elem_id = rec_tracciato_entrata.elem_id
      AND   bed.periodo_id = rec_tracciato_entrata.periodo_id
      AND dbedt.elem_det_tipo_code = v_elem_det_sca
      AND now() BETWEEN bed.validita_inizio AND COALESCE(bed.validita_fine, now())
      AND bed.data_cancellazione IS NULL
      AND now() BETWEEN dbedt.validita_inizio AND COALESCE(dbedt.validita_fine, now())
      AND dbedt.data_cancellazione IS NULL;
            
    ELSE
    
      v_importo_cassa_entrata := 0;
    
    END IF;  

    INSERT INTO siac.bilarm_tracciato_temp
        ( elab_id_temp,
          elab_id_det_temp,
          ente_proprietario_id,
          anno,
          elem_id,
          elem_code,
          elem_cat_code,
          cod_aggregazione,
          desc_aggregazione,
          elem_det_tipo_code, 
          elem_tipo_code, 
          importo_capitolo,
          importo_cassa,
          importo_impegnato,
          importo_fondo_vincolato
        )
       VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          rec_tracciato_entrata.ente_proprietario_id,
          rec_tracciato_entrata.anno,
          rec_tracciato_entrata.elem_id,
          rec_tracciato_entrata.elem_code,
          rec_tracciato_entrata.elem_cat_code,
          LPAD(SUBSTRING(rec_tracciato_entrata.classif_code,1,5),7,'0'),
          rec_tracciato_entrata.classif_desc,
          rec_imp_cap_entrata.elem_det_tipo_code, 
          rec_tracciato_entrata.elem_tipo_code, 
          rec_imp_cap_entrata.elem_det_importo,
          v_importo_cassa_entrata,
          0,
          0
        );        

        v_elab_id_det_temp := v_elab_id_det_temp + 1;

  END LOOP;

END LOOP;

-- Parte relativa al caricamento della tabella finale
FOR rec_tracciato_fin IN
SELECT 
a.elem_tipo_code,
a.elem_det_tipo_code,
a.cod_aggregazione,
a.desc_aggregazione,
SUM(a.importo_capitolo) importo_capitolo_tot,
SUM(a.importo_cassa) importo_cassa_tot,
SUM(a.importo_impegnato) importo_impegnato_tot
FROM siac.bilarm_tracciato_temp a
WHERE a.elab_id_temp = v_elab_id
AND   a.elem_cat_code = v_elem_cat_std
AND   a.ente_proprietario_id = p_ente_proprietario_id
AND   a.anno = p_anno_elab
GROUP BY a.elem_tipo_code, a.elem_cat_code, a.elem_det_tipo_code, a.cod_aggregazione, a.desc_aggregazione

LOOP

  v_importo_capitolo_tot := rec_tracciato_fin.importo_capitolo_tot;
  v_importo_cassa_tot := rec_tracciato_fin.importo_cassa_tot;
  v_importo_impegnato_tot := rec_tracciato_fin.importo_impegnato_tot;

  IF rec_tracciato_fin.elem_tipo_code = v_spese THEN
     v_ind_entrate_uscite := 'U';
  ELSE
     v_ind_entrate_uscite := 'E';
  END IF;   

  IF rec_tracciato_fin.elem_det_tipo_code = v_elem_det_sta THEN
  
     v_anno_residuo := '0000';
  
     IF rec_tracciato_fin.elem_tipo_code = v_spese THEN         

       SELECT COALESCE(SUM(importo_fondo_vincolato),0)
       INTO v_importo_fondo_vincolato_tot
       FROM siac.bilarm_tracciato_temp
       WHERE elab_id_temp = v_elab_id
       AND   cod_aggregazione = rec_tracciato_fin.cod_aggregazione
       AND   ente_proprietario_id = p_ente_proprietario_id
       AND   anno = p_anno_elab
       AND   elem_cat_code = 'FPV';
    
     END IF;
  
  ELSE
   
     v_anno_residuo := p_anno_elab::integer - 1;
     v_importo_fondo_vincolato_tot := 0;
    
  END IF;
  
  IF length(rec_tracciato_fin.desc_aggregazione) < 45 THEN
     v_descr_codifica_bilancio_pt1 := rpad(rec_tracciato_fin.desc_aggregazione, 45, ' ');
     v_descr_codifica_bilancio_pt2 := rpad(' ', 45, ' ');
  ELSIF length(rec_tracciato_fin.desc_aggregazione) > 45 THEN
     v_descr_codifica_bilancio_pt1 := substring(rec_tracciato_fin.desc_aggregazione, 1, 45);
     v_descr_codifica_bilancio_pt2 := rpad(substring(rec_tracciato_fin.desc_aggregazione, 46), 45, ' ');
  END IF;  
          
    INSERT INTO siac.bilarm_tracciato
      ( elab_id,
        elab_id_det,
        elab_data,
        ente_proprietario_id,
        codice_istituto,
        codice_ente,
        anno_esercizio,
        indicativo_entrate_uscite,
        codifica_bilancio,
        numero_articolo,
        anno_residuo,
        descr_codifica_bilancio_pt1,
        descr_codifica_bilancio_pt2,
        colonna_1,
        colonna_2,
        codice_meccanografico,
        colonna_3,
        importo_capitolo,
        importo_cassa,
        colonna_4,
        colonna_5,
        colonna_6,
        importo_impegnato,
        importo_fondo_vincolato,
        colonna_7,
        colonna_8,
        colonna_9,
        colonna_10,
        colonna_11,
        colonna_12,
        colonna_13,
        colonna_14,
        colonna_15,
        colonna_16
      )
    VALUES
      ( v_elab_id,
        v_elab_id_det,
        now(),
        p_ente_proprietario_id,
        v_codice_istituto,
        v_codice_ente,
        p_anno_elab,
        v_ind_entrate_uscite,
        rec_tracciato_fin.cod_aggregazione,
        '000',
        COALESCE(v_anno_residuo,'0000'),
        v_descr_codifica_bilancio_pt1,
        v_descr_codifica_bilancio_pt2,
        v_blank,
        v_blank,
        rec_tracciato_fin.cod_aggregazione,
        ' ',
        LPAD((v_importo_capitolo_tot*100)::bigint::varchar, 17, '0'),
        LPAD((v_importo_cassa_tot*100)::bigint::varchar, 17, '0'),
        '0000000',
        ' ',
        '00000000000000000',
        LPAD((v_importo_impegnato_tot*100)::bigint::varchar, 17, '0'),
        LPAD((v_importo_fondo_vincolato_tot*100)::bigint::varchar, 17, '0'),
        '00',
        '00',
        '00',
        '00',
        '00',
        '00',
        '00',
        '00',
        '00',
        '                    '
      );      
  
     v_elab_id_det := v_elab_id_det + 1;

END LOOP;

messaggioRisultato := 'OK';

-- Aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id = v_elab_id
UPDATE  mif_t_flusso_elaborato
SET (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
    (elab_mif_esito_ok,'Elaborazione conclusa [stato OK] per tipo flusso '||v_tipo_flusso, now())
WHERE flusso_elab_mif_id = v_elab_id;

RETURN messaggioRisultato;

EXCEPTION

	WHEN OTHERS  THEN
         messaggioRisultato := SUBSTRING(UPPER(SQLERRM) from 1 for 100);
         -- RETURN NEXT;
		 messaggioRisultato := UPPER(messaggioRisultato);
        
        INSERT INTO mif_t_flusso_elaborato
        (flusso_elab_mif_data,
         flusso_elab_mif_esito,
         flusso_elab_mif_esito_msg,
         flusso_elab_mif_file_nome,
         flusso_elab_mif_tipo_id,
         flusso_elab_mif_id_flusso_oil,
         validita_inizio,
         validita_fine,
         ente_proprietario_id,
         login_operazione)
         (SELECT now(),
                 elab_mif_esito_ko,
                 'Elaborazione conclusa con errori per tipo flusso '||v_tipo_flusso||'.'||messaggioRisultato,
                 tipo.flusso_elab_mif_nome_file,
                 tipo.flusso_elab_mif_tipo_id,
                 null, -- flussoElabMifOilId, -- non usato per questo tipo di flusso
                 now(),
                 now(),
                 p_ente_proprietario_id,
                 v_login
          FROM mif_d_flusso_elaborato_tipo tipo
          WHERE tipo.ente_proprietario_id = p_ente_proprietario_id
          AND   tipo.flusso_elab_mif_tipo_code = v_tipo_flusso
          AND   tipo.data_cancellazione IS NULL
          AND   tipo.validita_fine IS NULL
         );
         
         RETURN messaggioRisultato;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;