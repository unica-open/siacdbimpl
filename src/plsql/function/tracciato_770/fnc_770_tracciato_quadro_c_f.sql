/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_770_tracciato_quadro_c_f (
  p_anno_elab varchar,
  p_ente_proprietario_id integer,
  p_ex_ente varchar,
  p_quadro_c_f varchar
)
RETURNS varchar AS
$body$
DECLARE

rec_tracciato_770 record;
rec_indirizzo record;
rec_inps record;
rec_tracciato_fin_c record;
rec_tracciato_fin_f record;

v_soggetto_id INTEGER; -- SIAC-5485
v_comune_id_nascita INTEGER; 
v_comune_id INTEGER;
v_comune_id_gen INTEGER;
v_via_tipo_id INTEGER;
v_ord_id_a INTEGER;
v_indirizzo_tipo_code VARCHAR;
v_principale VARCHAR;
v_onere_tipo_code VARCHAR;

v_zip_code VARCHAR;
v_comune_desc VARCHAR;
v_provincia_desc VARCHAR;
v_nazione_desc VARCHAR;
v_indirizzo VARCHAR;
v_via_tipo_desc VARCHAR;
v_toponimo VARCHAR;
v_numero_civico VARCHAR;
v_frazione VARCHAR;
v_interno VARCHAR;
-- INPS
v_importoParzInpsImpon NUMERIC;
v_importoParzInpsNetto NUMERIC;
v_importoParzInpsRiten NUMERIC;
v_importoParzInpsEnte NUMERIC;
v_importo_ritenuta_inps NUMERIC;
v_importo_imponibile_inps NUMERIC;
v_importo_ente_inps NUMERIC;
v_importo_netto_inps NUMERIC;
v_idFatturaOld INTEGER;
v_contaQuotaInps INTEGER;
v_percQuota NUMERIC;
v_numeroQuoteFattura INTEGER;
-- INPS 
v_tipo_record VARCHAR;
v_codice_fiscale_ente VARCHAR;
v_codice_fiscale_percipiente VARCHAR;
v_tipo_percipiente VARCHAR;
v_cognome VARCHAR;
v_nome VARCHAR;
v_sesso VARCHAR;
v_data_nascita TIMESTAMP;    
v_comune_nascita VARCHAR;
v_nazione_nascita VARCHAR; 
v_provincia_nascita VARCHAR;
v_comune_indirizzo_principale VARCHAR;
v_provincia_indirizzo_principale VARCHAR;
v_indirizzo_principale VARCHAR;
v_cap_indirizzo_principale VARCHAR;  
 
v_indirizzo_fiscale VARCHAR;
v_cap_indirizzo_fiscale VARCHAR;
v_comune_indirizzo_fiscale VARCHAR;
v_provincia_indirizzo_fiscale VARCHAR;    
        
v_codice_fiscale_estero VARCHAR;
v_causale VARCHAR;
v_importo_lordo NUMERIC;
v_somma_non_soggetta NUMERIC;  
v_importo_imponibile NUMERIC;
v_ord_ts_det_importo NUMERIC;
v_importo_carico_ente NUMERIC;
v_importo_carico_soggetto NUMERIC; 
v_codice VARCHAR;  
v_codice_tributo VARCHAR;
v_matricola_c INTEGER;
v_matricola_f INTEGER;
v_codice_controllo2 VARCHAR;
v_aliquota NUMERIC;
    
v_elab_id INTEGER;
v_elab_id_det INTEGER;
v_elab_id_temp INTEGER;
v_elab_id_det_temp INTEGER;
v_codresult INTEGER := null;
elab_mif_esito_in CONSTANT  VARCHAR := 'IN';
elab_mif_esito_ok CONSTANT  VARCHAR := 'OK';
elab_mif_esito_ko CONSTANT  VARCHAR := 'KO';
v_tipo_flusso  CONSTANT  VARCHAR := 'MOD770';
v_login CONSTANT  VARCHAR := 'SIAC';
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

IF p_ex_ente IS NULL THEN
   messaggioRisultato := 'Parametro Ex Ente nullo.';
   -- RETURN NEXT;
   RETURN messaggioRisultato;
END IF;

IF p_quadro_c_f IS NULL THEN
   messaggioRisultato := 'Parametro Quadro C-F nullo.';
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

v_elab_id_det := 1;
v_elab_id_det_temp := 1;
v_matricola_c := 8000000;
v_matricola_f := 9000000;

IF p_quadro_c_f in ('C','T') THEN
  DELETE FROM siac.tracciato_770_quadro_c_temp
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab

  DELETE FROM siac.tracciato_770_quadro_c
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab
END IF;

IF p_quadro_c_f in ('F','T') THEN
  DELETE FROM siac.tracciato_770_quadro_f_temp
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab

  DELETE FROM siac.tracciato_770_quadro_f
  WHERE ente_proprietario_id = p_ente_proprietario_id;
  --AND   anno_competenza = p_anno_elab
END IF;

IF p_quadro_c_f = 'C' THEN
   v_onere_tipo_code := 'IRPEF';
ELSIF p_quadro_c_f = 'F' THEN
   v_onere_tipo_code := 'IRPEG';
ELSE
   v_onere_tipo_code := null;
END IF;   

v_codice_fiscale_ente := null;
v_tipo_record := null;

SELECT codice_fiscale
INTO   v_codice_fiscale_ente
FROM   siac_t_ente_proprietario
WHERE  ente_proprietario_id = p_ente_proprietario_id;

--v_importo_lordo := 0;
--v_codice_tributo := null;
--v_causale := null; 

v_idFatturaOld := 0;
v_contaQuotaInps := 0;

FOR rec_tracciato_770 IN
SELECT --sto.ord_id, 
       --SUM(totd.ord_ts_det_importo) IMPORTO_LORDO,
       --totd.ord_ts_det_importo IMPORTO_LORDO,       
       rdo.caus_id,
       sdo.onere_code,
       td.doc_id,
       rdo.doc_onere_id,
       rdo.somma_non_soggetta_tipo_id,
       rdo.onere_id,
       sros.soggetto_id,
       roa.testo
FROM  siac_t_ordinativo sto
INNER JOIN siac_t_ente_proprietario tep ON sto.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac_t_bil tb ON tb.bil_id = sto.bil_id
INNER JOIN siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
INNER JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
INNER JOIN siac_d_ordinativo_tipo dot ON dot.ord_tipo_id = sto.ord_tipo_id
INNER JOIN siac_t_ordinativo_ts tot ON tot.ord_id = sto.ord_id
--INNER JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
--INNER JOIN siac_d_ordinativo_ts_det_tipo dotdt ON dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
INNER JOIN siac_r_subdoc_ordinativo_ts rsot ON rsot.ord_ts_id = tot.ord_ts_id
INNER JOIN siac_t_subdoc ts ON ts.subdoc_id = rsot.subdoc_id
INNER JOIN siac_t_doc td ON td.doc_id = ts.doc_id
INNER JOIN siac_r_doc_onere rdo ON rdo.doc_id = td.doc_id
INNER JOIN siac_r_onere_attr roa ON roa.onere_id = rdo.onere_id
INNER JOIN siac_t_attr ta ON ta.attr_id = roa.attr_id
INNER JOIN siac_d_onere sdo ON sdo.onere_id = rdo.onere_id
INNER JOIN siac_d_onere_tipo sdot ON sdot.onere_tipo_id = sdo.onere_tipo_id
INNER JOIN siac_r_ordinativo_soggetto sros ON sros.ord_id = sto.ord_id
WHERE sto.ente_proprietario_id = p_ente_proprietario_id
AND   tp.anno = p_anno_elab
AND   dos.ord_stato_code <> 'A'
AND   dot.ord_tipo_code = 'P'
--AND   dotdt.ord_ts_det_tipo_code = 'A'
AND   ((roa.testo = p_quadro_c_f) OR ('T' = p_quadro_c_f AND roa.testo IN ('C','F')))
AND   ta.attr_code = 'QUADRO_770'
AND   ((sdot.onere_tipo_code = v_onere_tipo_code) OR ('T' = p_quadro_c_f AND sdot.onere_tipo_code IN ('IRPEF','IRPEG')))
AND   sto.data_cancellazione IS NULL
AND   tep.data_cancellazione IS NULL
AND   tb.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   ros.data_cancellazione IS NULL
AND   dos.data_cancellazione IS NULL
AND   dot.data_cancellazione IS NULL
AND   tot.data_cancellazione IS NULL
--AND   totd.data_cancellazione IS NULL
--AND   dotdt.data_cancellazione IS NULL
AND   rsot.data_cancellazione IS NULL
AND   ts.data_cancellazione IS NULL
AND   td.data_cancellazione IS NULL
AND   rdo.data_cancellazione IS NULL
AND   roa.data_cancellazione IS NULL
AND   ta.data_cancellazione IS NULL
AND   sdo.data_cancellazione IS NULL
AND   sdot.data_cancellazione IS NULL
AND   sros.data_cancellazione IS NULL
AND   now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
AND   now() BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, now())
AND   now() BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, now())
AND   now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
AND   now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
AND   now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
AND   now() BETWEEN dot.validita_inizio AND COALESCE(dot.validita_fine, now())
AND   now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
--AND   now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
--AND   now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
AND   now() BETWEEN rsot.validita_inizio AND COALESCE(rsot.validita_fine, now())
AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
AND   now() BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, now())
AND   now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now())
AND   now() BETWEEN roa.validita_inizio AND COALESCE(roa.validita_fine, now())
AND   now() BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, now())
AND   now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
AND   now() BETWEEN sdot.validita_inizio AND COALESCE(sdot.validita_fine, now())
AND   now() BETWEEN sros.validita_inizio AND COALESCE(sros.validita_fine, now())
GROUP BY   rdo.caus_id,
           sdo.onere_code,
           td.doc_id,
           rdo.doc_onere_id,
           rdo.somma_non_soggetta_tipo_id,
           rdo.onere_id,
           sros.soggetto_id,
           roa.testo

LOOP  

  --v_importo_lordo := 0;
  v_importoParzInpsImpon := 0;
  v_importoParzInpsNetto := 0;
  v_importoParzInpsRiten := 0;
  v_importoParzInpsEnte := 0;
  v_importo_ritenuta_inps := 0;
  v_importo_imponibile_inps := 0;
  v_importo_ente_inps := 0;
  v_importo_netto_inps := 0;
  v_codice_tributo := null;

  --v_importo_lordo := rec_tracciato_770.IMPORTO_LORDO;
  v_codice_tributo := rec_tracciato_770.onere_code;
  
  v_causale := null;
  
  BEGIN

    SELECT dc.caus_code
    INTO   STRICT v_causale
    FROM   siac_d_causale dc
    WHERE  dc.caus_id = rec_tracciato_770.caus_id
    AND    dc.data_cancellazione IS NULL
    AND    now() BETWEEN dc.validita_inizio AND COALESCE(dc.validita_fine, now());

  EXCEPTION
      
    WHEN NO_DATA_FOUND THEN
        v_causale := null;
      
  END;

  IF rec_tracciato_770.testo = 'C' THEN
   
    v_tipo_record := 'SC';   
    
    -- v_codice := null; -- SIAC-5955
    v_codice := '0'; -- SIAC-5955
    
    IF rec_tracciato_770.somma_non_soggetta_tipo_id IS NULL THEN
          -- SIAC-5955 INIZIO
/*          SELECT dsnst.somma_non_soggetta_tipo_code::varchar
          --INTO  STRICT v_codice
          INTO  v_codice
          FROM  siac_r_onere_somma_non_soggetta_tipo rosnst,
                siac_d_somma_non_soggetta_tipo dsnst
          WHERE rosnst.somma_non_soggetta_tipo_id = dsnst.somma_non_soggetta_tipo_id   
          AND   rosnst.onere_id = rec_tracciato_770.onere_id
          AND   rosnst.data_cancellazione IS NULL
          AND   dsnst.data_cancellazione IS NULL
          AND   now() BETWEEN rosnst.validita_inizio AND COALESCE(rosnst.validita_fine, now())
          AND   now() BETWEEN dsnst.validita_inizio AND COALESCE(dsnst.validita_fine, now());*/
          
          v_codice := '0';
          
          -- SIAC-5955 FINE                    
    ELSE

        BEGIN

          SELECT dsnst.somma_non_soggetta_tipo_code::varchar
          INTO   STRICT v_codice 
          FROM   siac_d_somma_non_soggetta_tipo dsnst
          WHERE  dsnst.somma_non_soggetta_tipo_id = rec_tracciato_770.somma_non_soggetta_tipo_id
          AND    dsnst.data_cancellazione IS NULL
          AND    now() BETWEEN dsnst.validita_inizio AND COALESCE(dsnst.validita_fine, now());  
      
        EXCEPTION
              
          WHEN NO_DATA_FOUND THEN
               -- v_codice := null; -- SIAC-5955
               v_codice := '0'; -- SIAC-5955
              
        END;    
    
    END IF;
    
  ELSE
    
    v_tipo_record := 'SF'; 
    
  END IF;

    -- PARTE RELATIVA AL SOGGETTO INIZIO
    
    v_codice_fiscale_percipiente := null;
    v_codice_fiscale_estero := null;
    v_tipo_percipiente := null;
    v_cognome := null;
    v_nome := null;
    v_sesso := null;
    v_data_nascita := null;
    v_comune_id_nascita := null;
    v_soggetto_id := null; -- SIAC-5485 
    
    BEGIN -- SIAC-5485 INIZIO
    
    SELECT a.soggetto_id_da
    INTO   STRICT v_soggetto_id
    FROM   siac_r_soggetto_relaz a, siac_d_relaz_tipo b
    WHERE  a.ente_proprietario_id = p_ente_proprietario_id
    AND    a.relaz_tipo_id = b.relaz_tipo_id
    AND    b.relaz_tipo_code = 'SEDE_SECONDARIA'
    AND    a.soggetto_id_a = rec_tracciato_770.soggetto_id;
    
    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN      
           v_soggetto_id := rec_tracciato_770.soggetto_id; 
              
    END; -- SIAC-5485 FINE
        
    BEGIN
    
      SELECT ts.codice_fiscale,
             ts.codice_fiscale_estero,
             CASE 
                WHEN dst.soggetto_tipo_code IN ('PF','PFI') THEN
                     1
                ELSE
                     2
             END tipo_percipiente,
             coalesce(tpf.cognome, tpg.ragione_sociale) cognome,
             tpf.nome,
             tpf.sesso,
             tpf.nascita_data,
             tpf.comune_id_nascita
      INTO  STRICT v_codice_fiscale_percipiente,
            v_codice_fiscale_estero,
            v_tipo_percipiente,
            v_cognome,
            v_nome,
            v_sesso,
            v_data_nascita,
            v_comune_id_nascita                
      FROM siac_t_soggetto ts
      INNER JOIN siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
      INNER JOIN siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
      LEFT JOIN  siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                              AND now() BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, now())
                                              AND tpg.data_cancellazione IS NULL
      LEFT JOIN  siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                              AND now() BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, now())
                                              AND tpf.data_cancellazione IS NULL
      WHERE ts.soggetto_id = v_soggetto_id -- rec_tracciato_770.soggetto_id -- SIAC-5485
      AND   ts.data_cancellazione IS NULL
      AND   rst.data_cancellazione IS NULL
      AND   dst.data_cancellazione IS NULL
      AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
      AND   now() BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, now())
      AND   now() BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, now());

      v_cognome := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cognome),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
      v_nome := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_nome),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));

    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN
           null;
              
    END;
    
    v_indirizzo_principale := null;
    v_cap_indirizzo_principale := null;
    v_comune_indirizzo_principale := null;
    v_provincia_indirizzo_principale := null;

    v_indirizzo_fiscale := null; -- SIAC-5485
    v_cap_indirizzo_fiscale := null; -- SIAC-5485
    v_comune_indirizzo_fiscale := null; -- SIAC-5485
    v_provincia_indirizzo_fiscale := null; -- SIAC-5485

    v_comune_nascita := null;
    v_provincia_nascita := null;
    v_nazione_nascita := null;    
    
    FOR rec_indirizzo IN
    SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
           tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
    FROM   siac.siac_t_indirizzo_soggetto tis
    INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                        AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                                        --AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                        --AND rist.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                              AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                              --AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                              --AND dit.data_cancellazione IS NULL
    WHERE tis.soggetto_id = v_soggetto_id -- rec_tracciato_770.soggetto_id -- SIAC-5485
    AND   tis.principale = 'S'
    AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
    --AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
    --AND   tis.data_cancellazione IS NULL
    UNION -- SIAC-5485 INIZIO
    SELECT tis.comune_id, dit.indirizzo_tipo_code, tis.principale, tis.zip_code,
           tis.toponimo, tis.numero_civico, tis.frazione, tis.interno, tis.via_tipo_id
    FROM   siac.siac_t_indirizzo_soggetto tis
    INNER JOIN siac.siac_r_indirizzo_soggetto_tipo rist ON rist.indirizzo_id = tis.indirizzo_id
                                                        AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                                        --AND now() BETWEEN rist.validita_inizio AND COALESCE(rist.validita_fine, now())
                                                        --AND rist.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_indirizzo_tipo dit ON dit.indirizzo_tipo_id = rist.indirizzo_tipo_id
                                              AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
                                              --AND now() BETWEEN dit.validita_inizio AND COALESCE(dit.validita_fine, now())
                                              --AND dit.data_cancellazione IS NULL
    WHERE tis.soggetto_id = rec_tracciato_770.soggetto_id
    AND   dit.indirizzo_tipo_code = 'DOMICILIO'
    --AND   tis.principale = 'S'
    AND   to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy') BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, to_timestamp('31/12/'||p_anno_elab,'dd/mm/yyyy'))
    --AND   now() BETWEEN tis.validita_inizio AND COALESCE(tis.validita_fine, now())
    --AND   tis.data_cancellazione IS NULL -- SIAC-5485 FINE    
    UNION
    SELECT NULL, 'NASCITA', NULL, NULL, NULL, NULL, NULL, NULL, NULL

    LOOP

      v_comune_id := null;
      v_comune_id_gen := null;
      v_via_tipo_id := null;
      v_indirizzo_tipo_code := null;
      v_principale := null;
      
      v_zip_code := null;
      v_comune_desc := null;
      v_provincia_desc := null;
      v_nazione_desc := null;
      v_indirizzo := null;
      v_via_tipo_desc := null;
      v_toponimo := null;
      v_numero_civico := null;
      v_frazione := null;
      v_interno := null;
      
      v_comune_id := rec_indirizzo.comune_id;
      v_via_tipo_id := rec_indirizzo.via_tipo_id;      
      v_indirizzo_tipo_code := rec_indirizzo.indirizzo_tipo_code;      
      v_principale := rec_indirizzo.principale;
      
      v_zip_code := rec_indirizzo.zip_code;
      v_toponimo := rec_indirizzo.toponimo;
      v_numero_civico := rec_indirizzo.numero_civico;
      v_frazione := rec_indirizzo.frazione;
      v_interno := rec_indirizzo.interno;

      BEGIN
      
        SELECT dvt.via_tipo_desc
        INTO STRICT v_via_tipo_desc
        FROM siac.siac_d_via_tipo dvt
        WHERE dvt.via_tipo_id = v_via_tipo_id
        AND now() BETWEEN dvt.validita_inizio AND COALESCE(dvt.validita_fine, now())
        AND dvt.data_cancellazione IS NULL;
      
      EXCEPTION
      
        WHEN NO_DATA_FOUND THEN
        	v_via_tipo_desc := null;
      
      END;
      
      IF v_via_tipo_desc IS NOT NULL THEN
         v_indirizzo := v_via_tipo_desc;
      END IF;

      IF v_toponimo IS NOT NULL THEN
         v_indirizzo := v_indirizzo||' '||v_toponimo;
      END IF;

      IF v_numero_civico IS NOT NULL THEN
         v_indirizzo := v_indirizzo||' '||v_numero_civico;
      END IF;

      IF v_frazione IS NOT NULL THEN
         v_indirizzo := v_indirizzo||', frazione '||v_frazione;
      END IF;

      IF v_interno IS NOT NULL THEN
         v_indirizzo := v_indirizzo||', interno '||v_interno;
      END IF;

      v_indirizzo := REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_indirizzo),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''');
      v_indirizzo := UPPER(v_indirizzo);

      IF v_indirizzo_tipo_code = 'NASCITA' THEN
         v_comune_id_gen := v_comune_id_nascita;
      ELSE
         v_comune_id_gen := v_comune_id;
      END IF;

      BEGIN

        SELECT tc.comune_desc, tp.sigla_automobilistica, tn.nazione_desc
        INTO  STRICT v_comune_desc, v_provincia_desc, v_nazione_desc
        FROM siac.siac_t_comune tc
        LEFT JOIN siac.siac_r_comune_provincia rcp ON rcp.comune_id = tc.comune_id
                                                   AND now() BETWEEN rcp.validita_inizio AND COALESCE(rcp.validita_fine, now())
                                                   AND rcp.data_cancellazione IS NULL
        LEFT JOIN siac.siac_t_provincia tp ON tp.provincia_id = rcp.provincia_id
                                           AND now() BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, now())
                                           AND tp.data_cancellazione IS NULL
        LEFT JOIN siac.siac_t_nazione tn ON tn.nazione_id = tc.nazione_id
                                         AND now() BETWEEN tn.validita_inizio AND COALESCE(tn.validita_fine, now())
                                         AND tn.data_cancellazione IS NULL
        WHERE tc.comune_id = v_comune_id_gen
        AND now() BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, now())
        AND tc.data_cancellazione IS NULL;

      EXCEPTION
                
        WHEN NO_DATA_FOUND THEN
             null;
                
      END;

    
      IF v_principale = 'S' THEN
         v_indirizzo_principale := v_indirizzo;
         v_cap_indirizzo_principale := v_zip_code;
         v_comune_indirizzo_principale := v_comune_desc;
         v_provincia_indirizzo_principale := v_provincia_desc;
      END IF;
       -- SIAC-5485 INIZIO
      IF  v_indirizzo_tipo_code = 'DOMICILIO' THEN
         v_indirizzo_fiscale := v_indirizzo;
         v_cap_indirizzo_fiscale := v_zip_code;
         v_comune_indirizzo_fiscale := v_comune_desc;
         v_provincia_indirizzo_fiscale := v_provincia_desc;      
      END IF;
      -- SIAC-5485 FINE
      IF  v_indirizzo_tipo_code = 'NASCITA' THEN
          v_comune_nascita := v_comune_desc;
          v_provincia_nascita := v_provincia_desc;
          v_nazione_nascita := v_nazione_desc;
      END IF;    

    END LOOP;

    v_cap_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cap_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_comune_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_provincia_indirizzo_principale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_indirizzo_principale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_cap_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_cap_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_comune_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_provincia_indirizzo_fiscale := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_indirizzo_fiscale),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u''')); -- SIAC-5485
    v_comune_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_comune_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_provincia_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_provincia_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));
    v_nazione_nascita := upper(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(lower(v_nazione_nascita),'à','a'''),'è','e'''),'é','e'''),'ì','i'''),'ò','o'''),'ù','u'''));

    -- PARTE RELATIVA AL SOGGETTO FINE

    v_somma_non_soggetta := 0;  
    v_importo_imponibile := 0;
    v_importo_lordo := 0;
/*     v_ord_ts_det_importo := 0;

   SELECT rdo.somma_non_soggetta,  --> id 32 
           rdo.importo_imponibile,  --> id 33 
           totd.ord_ts_det_importo  --> id 34 e id 35 a 0
    INTO   v_somma_non_soggetta,   
           v_importo_imponibile,
           v_ord_ts_det_importo -- Ritenute a titolo d' acconto           
    FROM   siac_r_doc_onere_ordinativo_ts rdoot   
    INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
    INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
    INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
    INNER  JOIN siac_r_doc_onere rdo ON rdoot.doc_onere_id = rdo.doc_onere_id
    WHERE  rdoot.doc_onere_id = rec_tracciato_770.doc_onere_id
    AND    dotdt.ord_ts_det_tipo_code = 'A'  
    AND    rdoot.data_cancellazione IS NULL
    AND    tot.data_cancellazione IS NULL
    AND    totd.data_cancellazione IS NULL
    AND    dotdt.data_cancellazione IS NULL
    AND    rdo.data_cancellazione IS NULL
    AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
    AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
    AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
    AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
    AND    now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now());*/

    BEGIN

      SELECT COALESCE(rdo.somma_non_soggetta,0),  --> id 31 
             COALESCE(rdo.importo_imponibile,0)   --> id 32 
      INTO   STRICT v_somma_non_soggetta,   
             v_importo_imponibile    
      FROM   siac_r_doc_onere rdo
      WHERE  rdo.doc_onere_id = rec_tracciato_770.doc_onere_id
      AND    rdo.data_cancellazione IS NULL
      AND    now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now());
      
    EXCEPTION
              
      WHEN NO_DATA_FOUND THEN
           null;
              
    END;
    
    v_importo_lordo := v_importo_imponibile + v_somma_non_soggetta;
      
      v_ord_ts_det_importo := 0;

      BEGIN

        SELECT SUM(totd.ord_ts_det_importo) --> id 34 e id 35 a 0
        INTO   STRICT v_ord_ts_det_importo -- Ritenute a titolo d' acconto           
        FROM   siac_r_doc_onere_ordinativo_ts rdoot 
        INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
        INNER  JOIN siac_t_ordinativo sto ON sto.ord_id = tot.ord_id
        INNER  JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
        INNER  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id      
        INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
        INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
        WHERE  rdoot.doc_onere_id = rec_tracciato_770.doc_onere_id
        AND    dotdt.ord_ts_det_tipo_code = 'A'  
        AND    dos.ord_stato_code <> 'A'
        AND    rdoot.data_cancellazione IS NULL
        AND    tot.data_cancellazione IS NULL
        AND    sto.data_cancellazione IS NULL
        AND    ros.data_cancellazione IS NULL
        AND    dos.data_cancellazione IS NULL    
        AND    totd.data_cancellazione IS NULL
        AND    dotdt.data_cancellazione IS NULL
        AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
        AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
        AND    now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
        AND    now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
        AND    now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
        AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
        AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now());

      EXCEPTION
                
        WHEN NO_DATA_FOUND THEN
             null;
                
      END;

IF rec_tracciato_770.testo = 'F' THEN

  BEGIN

    v_aliquota := 0;

    SELECT roa.percentuale
    INTO   STRICT v_aliquota
    FROM   siac_d_onere sdo, siac_r_onere_attr roa, siac_t_attr ta
    WHERE  sdo.onere_id = rec_tracciato_770.onere_id
    AND    sdo.onere_id = roa.onere_id    
    AND    roa.attr_id = ta.attr_id
    AND    ta.attr_code = 'ALIQUOTA_SOGG'
    AND    sdo.data_cancellazione IS NULL
    AND    roa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
    AND    now() BETWEEN roa.validita_inizio AND COALESCE(roa.validita_fine, now())
    AND    now() BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, now());

  EXCEPTION
                
    WHEN NO_DATA_FOUND THEN
         null;
                
  END;

END IF;

IF rec_tracciato_770.testo = 'C' THEN

      v_importo_carico_ente := 0;
      v_importo_carico_soggetto := 0; 

      /* verifico quante quote ci sono relative alla fattura */
  /*    v_numeroQuoteFattura := 0;
  		            
      SELECT count(*)
      INTO   v_numeroQuoteFattura
      FROM   siac_t_subdoc
      WHERE  doc_id= rec_tracciato_770.doc_id;
                
      IF NOT FOUND THEN
          v_numeroQuoteFattura := 0;
      END IF;*/

      FOR rec_inps IN  
      SELECT td.doc_importo IMPORTO_FATTURA,
             ts.subdoc_importo IMPORTO_QUOTA,
             rdo.importo_carico_ente,
             --totd.ord_ts_det_importo
             --rdo.importo_carico_soggetto
             rdo.doc_onere_id
      FROM  siac_t_ordinativo sto
      INNER JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
      INNER JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id
      INNER JOIN siac_t_ordinativo_ts tot ON tot.ord_id = sto.ord_id
      INNER JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
      INNER JOIN siac_d_ordinativo_ts_det_tipo dotdt ON dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
      INNER JOIN siac_r_subdoc_ordinativo_ts rsot ON rsot.ord_ts_id = tot.ord_ts_id
      INNER JOIN siac_t_subdoc ts ON ts.subdoc_id = rsot.subdoc_id
      INNER JOIN siac_t_doc td ON td.doc_id = ts.doc_id
      INNER JOIN siac_r_doc_onere rdo ON rdo.doc_id = td.doc_id
      INNER JOIN siac_d_onere sdo ON sdo.onere_id = rdo.onere_id
      INNER JOIN siac_d_onere_tipo sdot ON sdot.onere_tipo_id = sdo.onere_tipo_id
      WHERE td.doc_id = rec_tracciato_770.doc_id
      AND   dos.ord_stato_code <> 'A'
      AND   dotdt.ord_ts_det_tipo_code = 'A'
      AND   sdot.onere_tipo_code = 'INPS'
      AND   sto.data_cancellazione IS NULL
      AND   ros.data_cancellazione IS NULL
      AND   dos.data_cancellazione IS NULL
      AND   tot.data_cancellazione IS NULL
      AND   totd.data_cancellazione IS NULL
      AND   dotdt.data_cancellazione IS NULL
      AND   rsot.data_cancellazione IS NULL
      AND   ts.data_cancellazione IS NULL
      AND   td.data_cancellazione IS NULL
      AND   rdo.data_cancellazione IS NULL
      AND   sdo.data_cancellazione IS NULL
      AND   sdot.data_cancellazione IS NULL
      AND   now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
      AND   now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
      AND   now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
      AND   now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
      AND   now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
      AND   now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now())
      AND   now() BETWEEN rsot.validita_inizio AND COALESCE(rsot.validita_fine, now())
      AND   now() BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, now())
      AND   now() BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, now())
      AND   now() BETWEEN rdo.validita_inizio AND COALESCE(rdo.validita_fine, now())
      AND   now() BETWEEN sdo.validita_inizio AND COALESCE(sdo.validita_fine, now())
      AND   now() BETWEEN sdot.validita_inizio AND COALESCE(sdot.validita_fine, now())
       
      LOOP
      
        BEGIN

          SELECT SUM(totd.ord_ts_det_importo)
          INTO   STRICT v_importo_carico_soggetto           
          FROM   siac_r_doc_onere_ordinativo_ts rdoot 
          INNER  JOIN siac_t_ordinativo_ts tot ON tot.ord_ts_id = rdoot.ord_ts_id
          INNER  JOIN siac_t_ordinativo sto ON sto.ord_id = tot.ord_id
          INNER  JOIN siac_r_ordinativo_stato ros ON sto.ord_id = ros.ord_id
          INNER  JOIN siac_d_ordinativo_stato dos ON ros.ord_stato_id = dos.ord_stato_id      
          INNER  JOIN siac_t_ordinativo_ts_det totd ON totd.ord_ts_id = tot.ord_ts_id
          INNER  JOIN siac_d_ordinativo_ts_det_tipo dotdt ON totd.ord_ts_det_tipo_id = dotdt.ord_ts_det_tipo_id
          WHERE  rdoot.doc_onere_id = rec_inps.doc_onere_id
          AND    dotdt.ord_ts_det_tipo_code = 'A'  
          AND    dos.ord_stato_code <> 'A'
          AND    rdoot.data_cancellazione IS NULL
          AND    tot.data_cancellazione IS NULL
          AND    sto.data_cancellazione IS NULL
          AND    ros.data_cancellazione IS NULL
          AND    dos.data_cancellazione IS NULL    
          AND    totd.data_cancellazione IS NULL
          AND    dotdt.data_cancellazione IS NULL
          AND    now() BETWEEN rdoot.validita_inizio AND COALESCE(rdoot.validita_fine, now())
          AND    now() BETWEEN tot.validita_inizio AND COALESCE(tot.validita_fine, now())
          AND    now() BETWEEN sto.validita_inizio AND COALESCE(sto.validita_fine, now())
          AND    now() BETWEEN ros.validita_inizio AND COALESCE(ros.validita_fine, now())
          AND    now() BETWEEN dos.validita_inizio AND COALESCE(dos.validita_fine, now())
          AND    now() BETWEEN totd.validita_inizio AND COALESCE(totd.validita_fine, now())
          AND    now() BETWEEN dotdt.validita_inizio AND COALESCE(dotdt.validita_fine, now());

        EXCEPTION
                  
          WHEN NO_DATA_FOUND THEN
               null;
                  
        END;    
      
          --v_importo_carico_soggetto := rec_inps.importo_carico_soggetto;
          --v_importo_carico_ente := rec_inps.importo_carico_ente;
          v_percQuota := 0;    	          
                                                  
          -- calcolo la percentuale della quota corrente rispetto
          -- al totale fattura.
          v_percQuota := COALESCE(rec_inps.IMPORTO_QUOTA,0)*100/COALESCE(rec_inps.IMPORTO_FATTURA,0);                
                                                       
          --raise notice 'IRAP ORD_ID=%,  ORD_NUM =%', elencoMandati.ord_id,numero_mandato; 
          --raise notice 'ESTRATTO: IMPON =%, RITEN = %, ENTE =%', elencoMandati.IMPORTO_IMPONIBILE,elencoMandati.IMPOSTA,elencoMandati.IMPORTO_CARICO_ENTE;          
          --raise notice 'FATTURA_ID = %, NUMERO_QUOTE = %, IMPORTO FATT = %, IMPORTO QUOTA = %, PERC_QUOTA = %',elencoMandati.doc_id,numeroQuoteFattura, elencoMandati.IMPORTO_FATTURA, elencoMandati.IMPORTO_QUOTA,  percQuota;
                                
          -- la fattura e' la stessa della quota precedente.       		      
          ----IF v_idFatturaOld = rec_tracciato_770.doc_id THEN
              ----v_contaQuotaInps := v_contaQuotaInps + 1;
              --raise notice 'Fattura uguale alla prec: %, num_quota = %',idFatturaOld, contaQuotaIrap;
              -- e' l'ultima quota della fattura:
              -- gli importi sono quelli totali meno quelli delle quote
              -- precedenti, per evitare problemi di arrotondamento.            
  /*          IF v_contaQuotaInps = v_numeroQuoteFattura THEN
              --raise notice 'ULTIMA QUOTA'; 
              v_importo_imponibile_inps := v_importo_imponibile - v_importoParzInpsImpon;
              v_importo_ritenuta_inps := v_importo_carico_soggetto - v_importoParzInpsRiten;
              v_importo_ente_inps := rec_inps.importo_carico_ente - v_importoParzInpsEnte;                                  
              -- azzero gli importi parziali per fattura
              v_importoParzInpsImpon := 0;
              v_importoParzInpsRiten := 0;
              v_importoParzInpsEnte := 0;
              v_importoParzInpsNetto := 0;
              v_contaQuotaInps := 0;      
            ELSE*/
              --raise notice 'ALTRA QUOTA';
              --v_importo_imponibile_inps := v_importo_imponibile*v_percQuota/100;
              --v_importo_ritenuta_inps := v_importo_carico_soggetto*v_percQuota/100; 
              ----v_importo_ente_inps := rec_inps.importo_carico_ente*v_percQuota/100;
              --v_importo_netto_inps := v_importo_lordo-v_importo_ritenuta_inps;                      
              -- sommo l'importo della quota corrente
              -- al parziale per fattura.
              --v_importoParzInpsImpon := v_importoParzInpsImpon + v_importo_imponibile_inps;
              --v_importoParzInpsRiten := v_importoParzInpsRiten + v_importo_ritenuta_inps;
              ----v_importoParzInpsEnte :=  v_importoParzInpsEnte + v_importo_ente_inps;
              --v_importoParzInpsNetto := v_importoParzInpsNetto + v_importo_netto_inps;                      
            --END IF;      
          ----ELSE -- fattura diversa dalla precedente
            --raise notice 'Fattura diversa dalla prec: %, %',idFatturaOld,elencoMandati.doc_id;
            --v_importo_imponibile_inps := v_importo_imponibile*v_percQuota/100;
            --v_importo_ritenuta_inps := v_importo_carico_soggetto*v_percQuota/100; 
            v_importo_ente_inps := COALESCE(rec_inps.importo_carico_ente,0)*v_percQuota/100;
            --v_importo_netto_inps := v_importo_lordo - v_importo_ritenuta_inps;
            -- imposto l'importo della quota corrente
            -- al parziale per fattura.            
            --v_importoParzInpsImpon := v_importo_imponibile_inps;
            --v_importoParzInpsRiten := v_importo_ritenuta_inps;
            ----v_importoParzInpsEnte := v_importo_ente_inps;
            --v_importoParzInpsNetto := v_importo_netto_inps;
            ----v_contaQuotaInps := 1;            
          ----END IF;                                    
          --raise notice 'ParzImpon = %, ParzRiten = %, ParzEnte = %, ParzNetto = %', importoParzIrapImpon,importoParzIrapRiten,importoParzIrapEnte,importoParzIrapNetto;                
          --raise notice 'IMPON =%, RITEN = %, ENTE =%, NETTO= %', importo_imponibile_irap, importo_ritenuta_irap,importo_ente_irap,importo_ente_irap; 
          ----v_idFatturaOld := rec_tracciato_770.doc_id;    
          v_importo_carico_ente :=  v_importo_carico_ente + v_importo_ente_inps;  
      END LOOP;
  
    END IF;  
           
    IF rec_tracciato_770.testo = 'F' THEN
       null;
       -- Aliquota
       -- Ritenute Operate
    END IF;
        
    IF rec_tracciato_770.testo = 'C' THEN
    
      INSERT INTO siac.tracciato_770_quadro_c_temp
       (
        elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        tipo_record,
        codice_fiscale_ente,
        codice_fiscale_percipiente,
        tipo_percipiente,
        cognome_denominazione,
        nome,
        sesso,
        data_nascita,
        comune_nascita,
        provincia_nascita,
        comune_domicilio_spedizione,
        provincia_domicilio_spedizione,
        indirizzo_domicilio_spedizione,
        cap_domicilio_spedizione,
        percipienti_esteri_cod_fiscale,
        causale,
        ammontare_lordo_corrisposto,
        altre_somme_no_ritenute,
        imponibile_b,
        ritenute_titolo_acconto_b,
        ritenute_titolo_imposta_b,
        contr_prev_carico_sog_erogante,
        contr_prev_carico_sog_percipie,
        codice,
        anno_competenza,
        codice_tributo
        )
         VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          p_ente_proprietario_id,
          v_tipo_record,
          v_codice_fiscale_ente,
          v_codice_fiscale_percipiente,
          v_tipo_percipiente,
          v_cognome,
          v_nome,
          v_sesso,
          v_data_nascita,    
          COALESCE(v_comune_nascita, v_nazione_nascita), 
          v_provincia_nascita,
          v_comune_indirizzo_principale, 
          v_provincia_indirizzo_principale, 
          v_indirizzo_principale, 
          v_cap_indirizzo_principale,           
          v_codice_fiscale_estero,
          v_causale,
          v_importo_lordo,
          v_somma_non_soggetta,   
          v_importo_imponibile,
          v_ord_ts_det_importo,
          0,
          v_importo_carico_ente,
          v_importo_carico_soggetto,      
          v_codice,
          p_anno_elab,
          v_codice_tributo
        );         
    
    END IF;    
    
    IF rec_tracciato_770.testo = 'F' THEN    
    
      INSERT INTO siac.tracciato_770_quadro_f_temp
       (
        elab_id_temp,
        elab_id_det_temp,
        ente_proprietario_id,
        tipo_record,
        codice_fiscale_ente,
        codice_fiscale_percipiente,
        tipo_percipiente,
        cognome_denominazione,
        nome,
        sesso,
        data_nascita,
        comune_nascita,
        provincia_nascita,
        comune_domicilio_fiscale,
        provincia_domicilio_fiscale,
        indirizzo_domicilio_fiscale,
        cap_domicilio_spedizione,
        codice_identif_fiscale_estero,
        causale,
        ammontare_lordo_corrisposto,
        altre_somme_no_ritenute,
        aliquota,
        ritenute_operate,
        ritenute_sospese,
        rimborsi,
        anno_competenza,
        codice_tributo
        )
         VALUES
        ( v_elab_id,
          v_elab_id_det_temp,
          p_ente_proprietario_id,
          v_tipo_record,
          v_codice_fiscale_ente,
          v_codice_fiscale_percipiente,
          v_tipo_percipiente,
          v_cognome,
          v_nome,
          v_sesso,
          v_data_nascita,    
          COALESCE(v_comune_nascita, v_nazione_nascita), 
          v_provincia_nascita,
          COALESCE(v_comune_indirizzo_fiscale, v_comune_indirizzo_principale), 
          COALESCE(v_provincia_indirizzo_fiscale, v_provincia_indirizzo_principale), 
          COALESCE(v_indirizzo_fiscale, v_indirizzo_principale), 
          COALESCE(v_cap_indirizzo_fiscale, v_cap_indirizzo_principale),           
          v_codice_fiscale_estero,
          v_causale,
          v_importo_lordo,
          v_somma_non_soggetta,   
          v_aliquota,
          v_ord_ts_det_importo,
          0,
          0,    
          p_anno_elab,
          v_codice_tributo
        );         
     
    END IF;
    
  v_elab_id_det_temp := v_elab_id_det_temp + 1;
     
END LOOP;

IF p_quadro_c_f IN ('C','T') THEN
  v_elab_id_det := 1;
  -- Parte relativa al caricamento della tabella finale
  FOR rec_tracciato_fin_c IN
  SELECT   
    tipo_record,
    rpad(substring(coalesce(codice_fiscale_ente,'') from 1 for 16), 16, ' ') codice_fiscale_ente,
    rpad(substring(coalesce(codice_fiscale_percipiente,'') from 1 for 16), 16, ' ') codice_fiscale_percipiente,
    tipo_percipiente,
    rpad(substring(coalesce(cognome_denominazione,'') from 1 for 24), 24, ' ') cognome_denominazione,
    rpad(substring(coalesce(nome,'') from 1 for 20), 20, ' ') nome,
    rpad(coalesce(sesso,''), 1, ' ') sesso,
    lpad(coalesce(to_char(data_nascita,'yyyymmdd'),''),8,'0') data_nascita,
    rpad(substring(coalesce(comune_nascita,'') from 1 for 21), 21, ' ') comune_nascita,
    rpad(substring(coalesce(provincia_nascita,'') from 1 for 2), 2, ' ') provincia_nascita,
    rpad(substring(coalesce(comune_domicilio_spedizione,'') from 1 for 21), 21, ' ') comune_domicilio_spedizione,
    rpad(substring(coalesce(provincia_domicilio_spedizione,'') from 1 for 2), 2, ' ') provincia_domicilio_spedizione,
    rpad(substring(coalesce(indirizzo_domicilio_spedizione,'') from 1 for 35), 35, ' ') indirizzo_domicilio_spedizione,
    rpad(substring(coalesce(cap_domicilio_spedizione,'') from 1 for 5), 5, ' ') cap_domicilio_spedizione,
    rpad(substring(coalesce(percipienti_esteri_cod_fiscale,'') from 1 for 20), 20, ' ') percipienti_esteri_cod_fiscale,
    rpad(substring(coalesce(causale,'') from 1 for 2), 2, ' ') causale,
    rpad(substring(coalesce(codice,'') from 1 for 1), 1, ' ') codice,
    anno_competenza,
    lpad((SUM(coalesce(ammontare_lordo_corrisposto,0))*100)::bigint::varchar, 11, '0')::varchar ammontare_lordo_corrisposto,
    lpad((SUM(coalesce(altre_somme_no_ritenute,0))*100)::bigint::varchar, 11, '0') altre_somme_no_ritenute,
    lpad((SUM(coalesce(imponibile_b,0))*100)::bigint::varchar, 11, '0') imponibile_b,
    lpad((SUM(coalesce(ritenute_titolo_acconto_b,0))*100)::bigint::varchar, 11, '0') ritenute_titolo_acconto_b,
    lpad((SUM(coalesce(ritenute_titolo_imposta_b,0))*100)::bigint::varchar, 11, '0') ritenute_titolo_imposta_b,
    lpad((SUM(coalesce(contr_prev_carico_sog_erogante,0))*100)::bigint::varchar, 11, '0') contr_prev_carico_sog_erogante,
    lpad((SUM(coalesce(contr_prev_carico_sog_percipie,0))*100)::bigint::varchar, 11, '0') contr_prev_carico_sog_percipie,
    lpad(codice_tributo,4,'0') codice_tributo
  FROM tracciato_770_quadro_c_temp
  WHERE elab_id_temp = v_elab_id
  AND   ente_proprietario_id = p_ente_proprietario_id
  AND   anno_competenza = p_anno_elab
  GROUP BY
    tipo_record,
    codice_fiscale_ente,
    codice_fiscale_percipiente,
    tipo_percipiente,
    cognome_denominazione,
    nome,
    sesso,
    data_nascita,
    comune_nascita,
    provincia_nascita,
    comune_domicilio_spedizione,
    provincia_domicilio_spedizione,
    indirizzo_domicilio_spedizione,
    cap_domicilio_spedizione,
    percipienti_esteri_cod_fiscale,
    causale,
    codice,
    anno_competenza,
    codice_tributo
    
  LOOP
            
      INSERT INTO siac.tracciato_770_quadro_c
        ( 
          elab_id,
          elab_id_det,
          elab_data,
          ente_proprietario_id,
          tipo_record,
          codice_fiscale_ente,
          codice_fiscale_percipiente,
          tipo_percipiente,
          cognome_denominazione,
          nome,
          sesso,
          data_nascita,
          comune_nascita,
          provincia_nascita,
          colonna_1,
          colonna_2 ,
          comune_domicilio_fiscale_prec,
          comune_domicilio_spedizione,
          provincia_domicilio_spedizione,
          colonna_3,
          esclusione_precompilata,
          categorie_particolari,
          indirizzo_domicilio_spedizione,
          cap_domicilio_spedizione,
          colonna_4,
          codice_sede,
          comune_domicilio_fiscale,
          rappresentante_codice_fiscale,
          percipienti_esteri_no_res,
          percipienti_esteri_localita,
          percipienti_esteri_stato,
          percipienti_esteri_cod_fiscale,
          ex_causale,
          ammontare_lordo_corrisposto,
          somme_no_ritenute_regime_conv,
          altre_somme_no_ritenute,
          imponibile_b,
          ritenute_titolo_acconto_b,
          ritenute_titolo_imposta_b,
          ritenute_sospese_b,
          anticipazione,
          anno,
          add_reg_titolo_acconto_b,
          add_reg_titolo_imposta_b,
          add_reg_sospesa_b,
          imponibile_anni_prec,
          ritenute_operate_anni_prec,
          contr_prev_carico_sog_erogante,
          contr_prev_carico_sog_percipie,
          spese_rimborsate,
          ritenute_rimborsate,
          colonna_5,
          percipienti_esteri_via_numciv,
          colonna_6,
          eventi_eccezionali,
          somme_prima_data_fallimento,
          somme_curatore_commissario,
          colonna_7,
          colonna_8,
          codice,
          colonna_9,
          codice_fiscale_e,
          imponibile_e,
          ritenute_titolo_acconto_e,
          ritenute_titolo_imposta_e,
          ritenute_sospese_e,
          add_reg_titolo_acconto_e,
          add_reg_titolo_imposta_e,
          add_reg_sospesa_e,
          add_com_titolo_acconto_e,
          add_com_titolo_imposta_e,
          add_com_sospesa_e,
          add_com_titolo_acconto_b,
          add_com_titolo_imposta_b,
          add_com_sospesa_b,
          colonna_10,
          codice_fiscale_redd_diversi_f,
          codice_fiscale_pignoramento_f,
          codice_fiscale_esproprio_f,
          colonna_11,
          colonna_12,
          colonna_13,
          colonna_14,
          colonna_15,
          colonna_16,
          colonna_17,
          colonna_18,
          colonna_19,
          colonna_20,
          colonna_21,
          colonna_22,
          colonna_23,
          codice_fiscale_ente_prev,
          denominazione_ente_prev,
          codice_ente_prev,
          codice_azienda,
          categoria,
          altri_contributi,
          importo_altri_contributi,
          contributi_dovuti,
          contributi_versati,
          causale,
          colonna_24,
          colonna_25,
          colonna_26,
          colonna_27,
          anno_competenza,
          ex_ente,
          progressivo,
          matricola,
          codice_tributo,
          versione_tracciato_procsi,
          colonna_28,
          caratteri_controllo_1,
          caratteri_controllo_2
        )
      VALUES
        ( v_elab_id,
          v_elab_id_det,
          now(),
          p_ente_proprietario_id,
          rec_tracciato_fin_c.tipo_record,
          rec_tracciato_fin_c.codice_fiscale_ente,
          rec_tracciato_fin_c.codice_fiscale_percipiente,
          rec_tracciato_fin_c.tipo_percipiente,
          rec_tracciato_fin_c.cognome_denominazione,
          rec_tracciato_fin_c.nome,
          rec_tracciato_fin_c.sesso,
          rec_tracciato_fin_c.data_nascita,
          rec_tracciato_fin_c.comune_nascita,
          rec_tracciato_fin_c.provincia_nascita,
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rec_tracciato_fin_c.comune_domicilio_spedizione,
          rec_tracciato_fin_c.provincia_domicilio_spedizione,
          rpad(' ',3,' '),
          rpad(' ',1,' '),
          rpad(' ',2,' '),
          rec_tracciato_fin_c.indirizzo_domicilio_spedizione,
          rec_tracciato_fin_c.cap_domicilio_spedizione,
          rpad(' ',57,' '),
          rpad(' ',3,' '),
          rpad(' ',4,' '),
          rpad(' ',16,' '),
          rpad(' ',1,' '),
          rpad(' ',35,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_c.percipienti_esteri_cod_fiscale,
          rpad(' ',1,' '),
          rec_tracciato_fin_c.ammontare_lordo_corrisposto,
          lpad('0',11,'0'),
          rec_tracciato_fin_c.altre_somme_no_ritenute,
          rec_tracciato_fin_c.imponibile_b,
          rec_tracciato_fin_c.ritenute_titolo_acconto_b,
          rec_tracciato_fin_c.ritenute_titolo_imposta_b,
          lpad('0',11,'0'),
          lpad('0',1,'0'),
          lpad('0',4,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rec_tracciato_fin_c.contr_prev_carico_sog_erogante,
          rec_tracciato_fin_c.contr_prev_carico_sog_percipie,
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          rpad(' ',1,' '),
          lpad('0',1,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',11,' '),
          rpad(' ',1,' '),        
          rec_tracciato_fin_c.codice,
          rpad(' ',9,' '),
          rpad(' ',16,' '),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rpad(' ',103,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',16,' '),
          rpad(' ',1,' '),
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',6,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',4,' '),
          rpad(' ',9,' '),
          rpad(' ',1,' '),
          rpad(' ',16,' '),
          rpad(' ',30,' '),
          rpad(' ',1,' '),
          rpad(' ',15,' '),
          rpad(' ',1,' '),
          lpad('0',1,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          lpad('0',11,'0'),
          rec_tracciato_fin_c.causale,
          rpad(' ',1044,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),          
          rpad(' ',1818,' '),
          rec_tracciato_fin_c.anno_competenza,
          rpad(p_ex_ente,4,' '),
          lpad((v_elab_id_det)::varchar,7,'0'),
          lpad((v_matricola_c)::varchar,7,'0'),
          rec_tracciato_fin_c.codice_tributo,
          'V15',
          rpad(' ',9,' '),
          'A',
          NULL
        );      
    
       v_matricola_c := 8000000 + v_elab_id_det;
       v_elab_id_det := v_elab_id_det + 1;
       
  END LOOP;
  
END IF;

IF p_quadro_c_f IN ('F','T') THEN
  v_elab_id_det := 1;
  -- Parte relativa al caricamento della tabella finale
  FOR rec_tracciato_fin_f IN
  SELECT   
    tipo_record,
    rpad(substring(coalesce(codice_fiscale_ente,'') from 1 for 16), 16, ' ') codice_fiscale_ente,
    rpad(substring(coalesce(codice_fiscale_percipiente,'') from 1 for 16), 16, ' ') codice_fiscale_percipiente,
    tipo_percipiente,
    rpad(substring(coalesce(cognome_denominazione,'') from 1 for 24), 24, ' ') cognome_denominazione,
    rpad(substring(coalesce(nome,'') from 1 for 20), 20, ' ') nome,
    rpad(coalesce(sesso,''), 1, ' ') sesso,
    lpad(coalesce(to_char(data_nascita,'yyyymmdd'),''),8,'0') data_nascita,
    rpad(substring(coalesce(comune_nascita,'') from 1 for 21), 21, ' ') comune_nascita,
    rpad(substring(coalesce(provincia_nascita,'') from 1 for 2), 2, ' ') provincia_nascita,
    rpad(substring(coalesce(comune_domicilio_fiscale,'') from 1 for 21), 21, ' ') comune_domicilio_fiscale,
    rpad(substring(coalesce(provincia_domicilio_fiscale,'') from 1 for 2), 2, ' ') provincia_domicilio_fiscale,
    rpad(substring(coalesce(indirizzo_domicilio_fiscale,'') from 1 for 35), 35, ' ') indirizzo_domicilio_fiscale,
    rpad(substring(coalesce(cap_domicilio_spedizione,'') from 1 for 5), 5, ' ') cap_domicilio_spedizione,
    rpad(substring(coalesce(codice_identif_fiscale_estero,'') from 1 for 20), 20, ' ') codice_identif_fiscale_estero,
    rpad(substring(coalesce(causale,'') from 1 for 1), 1, ' ') causale,
    anno_competenza,
    lpad((SUM(coalesce(ammontare_lordo_corrisposto,0))*100)::bigint::varchar, 13, '0')::varchar ammontare_lordo_corrisposto,
    lpad((SUM(coalesce(altre_somme_no_ritenute,0))*100)::bigint::varchar, 13, '0') altre_somme_no_ritenute,
    lpad((SUM(coalesce(ritenute_operate,0))*100)::bigint::varchar, 13, '0') ritenute_operate,
    lpad((SUM(coalesce(ritenute_sospese,0))*100)::bigint::varchar, 13, '0') ritenute_sospese,
    lpad((SUM(coalesce(rimborsi,0))*100)::bigint::varchar, 13, '0') rimborsi,
    lpad(codice_tributo,4,'0') codice_tributo,
    -- lpad((coalesce(aliquota,0)*100)::bigint::varchar,5,'0') aliquota -- SIAC-5951
    lpad(coalesce(aliquota,0)::bigint::varchar,5,'0') aliquota -- SIAC-5951
  FROM tracciato_770_quadro_f_temp
  WHERE elab_id_temp = v_elab_id
  AND   ente_proprietario_id = p_ente_proprietario_id
  AND   anno_competenza = p_anno_elab
  GROUP BY
    tipo_record,
    codice_fiscale_ente,
    codice_fiscale_percipiente,
    tipo_percipiente,
    cognome_denominazione,
    nome,
    sesso,
    data_nascita,
    comune_nascita,
    provincia_nascita,
    comune_domicilio_fiscale,
    provincia_domicilio_fiscale,
    indirizzo_domicilio_fiscale,
    cap_domicilio_spedizione,
    codice_identif_fiscale_estero,
    causale,
    anno_competenza,
    codice_tributo,
    aliquota
    
  LOOP
            
      INSERT INTO siac.tracciato_770_quadro_f
        ( 
          elab_id,
          elab_id_det,
          elab_data,
          ente_proprietario_id,
          tipo_record,
          codice_fiscale_ente,
          codice_fiscale_percipiente,
          tipo_percipiente,
          cognome_denominazione,
          nome,
          sesso,
          data_nascita,
          comune_nascita,
          provincia_nascita,
          comune_domicilio_fiscale,
          provincia_domicilio_fiscale,
          indirizzo_domicilio_fiscale,
          colonna_1,
          colonna_2,
          colonna_3,
          colonna_4,
          cap_domicilio_spedizione,
          colonna_5,
          codice_stato_estero,
          codice_identif_fiscale_estero,
          causale,
          ammontare_lordo_corrisposto,
          somme_no_soggette_ritenuta,
          aliquota,
          ritenute_operate,
          ritenute_sospese,
          codice_fiscale_rappr_soc,
          cognome_denom_rappr_soc,
          nome_rappr_soc,
          sesso_rappr_soc,
          data_nascita_rappr_soc,
          comune_nascita_rappr_soc,
          provincia_nascita_rappr_soc,
          comune_dom_fiscale_rappr_soc,
          provincia_rappr_soc,
          indirizzo_rappr_soc,
          codice_stato_estero_rappr_soc,
          rimborsi,
          colonna_6,
          colonna_7,
          colonna_8,
          colonna_9,
          colonna_10,
          colonna_11,
          colonna_12,
          colonna_13,
          colonna_14,
          colonna_15,
          colonna_16,
          colonna_17,
          colonna_18,
          colonna_19,
          colonna_20,
          colonna_21,
          colonna_22,
          colonna_23,
          anno_competenza,
          ex_ente,
          progressivo,
          matricola,
          codice_tributo,
          versione_tracciato_procsi,
          colonna_28,
          caratteri_controllo_1, 
          caratteri_controllo_2
        )
      VALUES
        ( v_elab_id,
          v_elab_id_det,
          now(),
          p_ente_proprietario_id,
          rec_tracciato_fin_f.tipo_record,
          rec_tracciato_fin_f.codice_fiscale_ente,
          rec_tracciato_fin_f.codice_fiscale_percipiente,
          rec_tracciato_fin_f.tipo_percipiente,
          rec_tracciato_fin_f.cognome_denominazione,
          rec_tracciato_fin_f.nome,
          rec_tracciato_fin_f.sesso,
          rec_tracciato_fin_f.data_nascita,
          rec_tracciato_fin_f.comune_nascita,
          rec_tracciato_fin_f.provincia_nascita,
          rec_tracciato_fin_f.comune_domicilio_fiscale,
          rec_tracciato_fin_f.provincia_domicilio_fiscale,
          rec_tracciato_fin_f.indirizzo_domicilio_fiscale,
          rpad(' ',60,' '),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          rec_tracciato_fin_f.cap_domicilio_spedizione,
          rpad(' ',31,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_f.codice_identif_fiscale_estero,
          rec_tracciato_fin_f.causale,
          rec_tracciato_fin_f.ammontare_lordo_corrisposto,
          rec_tracciato_fin_f.altre_somme_no_ritenute,
          rec_tracciato_fin_f.aliquota,
          rec_tracciato_fin_f.ritenute_operate,
          rec_tracciato_fin_f.ritenute_sospese,
          rpad(' ',16,' '),
          rpad(' ',60,' '),
          rpad(' ',20,' '),
          rpad(' ',1,' '),
          lpad('0',8,'0'),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',21,' '),
          rpad(' ',2,' '),
          rpad(' ',35,' '),
          lpad('0',3,'0'),
          rec_tracciato_fin_f.rimborsi,
          rpad(' ',315,' '),
          rpad(' ',16,' '),       
          rpad(' ',1,' '),      
          rpad(' ',2,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',6,' '),
          rpad(' ',4,' '),
          rpad(' ',7,' '),
          rpad(' ',4,' '),
          rpad(' ',9,' '),
          rpad(' ',1,' '),
          rpad(' ',1143,' '),
          rpad(' ',4,' '),    
          rpad(' ',4,' '),
          rpad(' ',1818,' '),                                                                                                                                              
          rec_tracciato_fin_f.anno_competenza,
          rpad(p_ex_ente,4,' '),
          lpad((v_elab_id_det)::varchar,7,'0'),
          lpad((v_matricola_f)::varchar,7,'0'),
          rec_tracciato_fin_f.codice_tributo,
          'V15',
          rpad(' ',9,' '),
          'A',
          NULL
        );      
    
       v_matricola_f := 9000000 + v_elab_id_det;
       v_elab_id_det := v_elab_id_det + 1;
       
  END LOOP;
             
END IF;  

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