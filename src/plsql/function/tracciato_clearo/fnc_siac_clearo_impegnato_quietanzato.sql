/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_clearo_impegnato_quietanzato (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_anno_provv varchar,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

  anno_bilancio_int integer;

BEGIN

IF p_data IS NULL THEN
   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   ELSE
      p_data := now();
   END IF;   
END IF;

DELETE FROM  siac_clearo_impegnato_quietanzato 
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;

/*DELETE FROM  siac_clearo_impegnato
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;

DELETE FROM  siac_clearo_quietanzato 
WHERE ente_proprietario_id = p_ente_proprietario_id 
AND   anno_bilancio = p_anno_bilancio;*/

anno_bilancio_int := p_anno_bilancio::integer;

-- Dati estratti per l'impegnato
WITH provvedimenti AS (
SELECT 
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
(case when cl.classif_code is not null and cl.classif_code!='' then e.attoamm_tipo_code||' '||cl.classif_code ELSE
         e.attoamm_tipo_code end ) attoamm_tipo_code, 
e.attoamm_tipo_desc, d.attoamm_stato_desc
FROM 
siac.siac_r_movgest_ts_atto_amm a, 
siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e,
siac.siac_t_atto_amm b
left join siac_r_atto_amm_class rc 
                  join siac_t_class cl join siac_d_class_tipo tipoc on ( tipoc.classif_tipo_id=cl.classif_tipo_id
                                                                   and  tipoc.classif_tipo_code in ('CDC','CDR'))
                    on (rc.classif_id=cl.classif_id
                   and cl.data_cancellazione is null )
     on (b.attoamm_id=rc.attoamm_id                                   
     and rc.data_cancellazione is null
     and rc.validita_fine is null )
WHERE a.ente_proprietario_id=p_ente_proprietario_id
--AND b.attoamm_anno >= p_anno_bilancio
AND b.attoamm_anno >= p_anno_provv
AND a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
-- AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
-- AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
, impegnato AS (
SELECT
t_movgest_ts.movgest_ts_id,
t_movgest.movgest_anno, 
t_movgest.movgest_numero,
t_movgest_ts.movgest_ts_code,
d_movgest_ts_tipo.movgest_ts_tipo_code,
t_movgest_ts_det.movgest_ts_det_importo
FROM siac_t_movgest t_movgest,
siac_t_bil t_bil,
siac_t_periodo t_periodo,
siac_t_movgest_ts t_movgest_ts,    
siac_d_movgest_tipo d_movgest_tipo,            
siac_t_movgest_ts_det t_movgest_ts_det,
siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
siac_d_movgest_ts_tipo d_movgest_ts_tipo,
siac_r_movgest_ts_stato r_movgest_ts_stato,
siac_d_movgest_stato d_movgest_stato 
WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
AND t_bil.bil_id= t_movgest.bil_id   
AND t_periodo.periodo_id=t_bil.periodo_id    
AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	       
AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
AND t_movgest.ente_proprietario_id=p_ente_proprietario_id
AND t_periodo.anno = p_anno_bilancio
-- AND t_movgest.movgest_anno = anno_bilancio_int
AND t_movgest.movgest_anno <= anno_bilancio_int
AND t_movgest.parere_finanziario = 'TRUE'
AND d_movgest_tipo.movgest_tipo_code='I'
AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
AND d_movgest_stato.movgest_stato_code = 'D' 
--AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' --solo impegni non sub-impegni
AND t_movgest_ts.data_cancellazione IS NULL
AND t_movgest.data_cancellazione IS NULL   
AND t_bil.data_cancellazione IS NULL 
AND t_periodo.data_cancellazione IS NULL
AND d_movgest_tipo.data_cancellazione IS NULL            
AND t_movgest_ts_det.data_cancellazione IS NULL
AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
AND d_movgest_ts_tipo.data_cancellazione IS NULL
AND r_movgest_ts_stato.data_cancellazione IS NULL
AND d_movgest_stato.data_cancellazione IS NULL
-- AND p_data BETWEEN r_movgest_ts_stato.validita_inizio and COALESCE(r_movgest_ts_stato.validita_fine,p_data)
and  t_movgest.validita_fine is null
and  t_bil.validita_fine is null
and  t_periodo.validita_fine is null
and  t_movgest_ts.validita_fine is null
and  d_movgest_tipo.validita_fine is null
and  t_movgest_ts_det.validita_fine is null
and  d_movgest_ts_det_tipo.validita_fine is null
and  d_movgest_ts_tipo.validita_fine is null
and  r_movgest_ts_stato.validita_fine is null
and  d_movgest_stato.validita_fine is null
)
/*, t_flagDaRiaccertamento as (
SELECT 
a.movgest_ts_id,
a."boolean" flagDaRiaccertamento
FROM  siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE b.attr_code='flagDaRiaccertamento' 
AND a.ente_proprietario_id = p_ente_proprietario_id 
AND a.attr_id = b.attr_id
AND a."boolean"  = 'N'
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
)*/
, sogg as (SELECT 
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND a.ente_proprietario_id = p_ente_proprietario_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
-- AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND a.validita_fine is null
AND b.validita_fine is null
)
, sogcla as (SELECT 
a.movgest_ts_id,
b.soggetto_classe_code, b.soggetto_classe_desc
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE a.ente_proprietario_id = p_ente_proprietario_id 
AND a.soggetto_classe_id = b.soggetto_classe_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
-- AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND a.validita_fine is null
AND b.validita_fine is null
)
--INSERT INTO siac_clearo_impegnato
INSERT INTO siac_clearo_impegnato_quietanzato
(ente_proprietario_id,
 anno_bilancio,
 anno_atto_amministrativo,
 num_atto_amministrativo,
 oggetto_atto_amministrativo,
 note_atto_amministrativo,
 cod_tipo_atto_amministrativo,
 desc_tipo_atto_amministrativo,
 desc_stato_atto_amministrativo,
 anno_impegno,
 num_impegno,
 impegnato,
 cod_soggetto,
 desc_soggetto,
 cf_soggetto,
 cf_estero_soggetto,
 p_iva_soggetto,
 cod_classe_soggetto,
 desc_classe_soggetto,
 tipo_impegno,
 tipo_importo)   
SELECT 
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, provvedimenti.attoamm_numero, provvedimenti.attoamm_oggetto, provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, provvedimenti.attoamm_tipo_desc, provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, impegnato.movgest_numero, 
--impegnato.movgest_ts_det_importo, 
COALESCE(SUM(impegnato.movgest_ts_det_importo),0) importo_impegnato,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva,
sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
impegnato.movgest_ts_tipo_code,
'I'
FROM provvedimenti
INNER JOIN impegnato ON impegnato.movgest_ts_id = provvedimenti.movgest_ts_id
-- INNER JOIN t_flagDaRiaccertamento ON t_flagDaRiaccertamento.movgest_ts_id = impegnato.movgest_ts_id
LEFT JOIN sogg ON sogg.movgest_ts_id = impegnato.movgest_ts_id
LEFT JOIN sogcla ON sogcla.movgest_ts_id = impegnato.movgest_ts_id
GROUP BY
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno,
provvedimenti.attoamm_numero, 
provvedimenti.attoamm_oggetto, 
provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, 
provvedimenti.attoamm_tipo_desc, 
provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, 
impegnato.movgest_numero,
sogg.soggetto_code, 
sogg.soggetto_desc, 
sogg.codice_fiscale, 
sogg.codice_fiscale_estero, 
sogg.partita_iva,
sogcla.soggetto_classe_code, 
sogcla.soggetto_classe_desc,
impegnato.movgest_ts_tipo_code,
'I'::varchar;

-- Dati estratti per il quietanzato
WITH provvedimenti AS (
SELECT 
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
(case when cl.classif_code is not null and cl.classif_code!='' then e.attoamm_tipo_code||' '||cl.classif_code ELSE
         e.attoamm_tipo_code end ) attoamm_tipo_code, 
e.attoamm_tipo_desc, d.attoamm_stato_desc,
t_movgest.movgest_anno,
t_movgest.movgest_numero
FROM 
siac.siac_r_movgest_ts_atto_amm a,
siac.siac_t_movgest_ts t_movgest_ts,
siac.siac_t_movgest t_movgest,
siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e,
siac.siac_t_atto_amm b 
left join siac_r_atto_amm_class rc 
                  join siac_t_class cl join siac_d_class_tipo tipoc on ( tipoc.classif_tipo_id=cl.classif_tipo_id
                                                                   and  tipoc.classif_tipo_code in ('CDC','CDR'))
                    on (rc.classif_id=cl.classif_id
                   and cl.data_cancellazione is null )
     on (b.attoamm_id=rc.attoamm_id                                   
     and rc.data_cancellazione is null
     and rc.validita_fine is null )
WHERE a.ente_proprietario_id=p_ente_proprietario_id
--AND b.attoamm_anno >= p_anno_bilancio
AND b.attoamm_anno >= p_anno_provv
AND a.attoamm_id=b.attoamm_id
AND t_movgest_ts.movgest_ts_id = a.movgest_ts_id
AND t_movgest.movgest_id = t_movgest_ts.movgest_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   t_movgest_ts.data_cancellazione IS NULL
AND   t_movgest.data_cancellazione IS NULL
-- AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
-- AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)
AND a.validita_fine is null
AND b.validita_fine is null
AND c.validita_fine is null
AND d.validita_fine is null
AND e.validita_fine is null
AND t_movgest_ts.validita_fine IS NULL
AND t_movgest.validita_fine IS NULL
),
impegnato AS (
SELECT
t_movgest_ts.movgest_ts_id,
t_movgest.movgest_anno, 
t_movgest.movgest_numero,
t_movgest_ts.movgest_ts_code,
d_movgest_ts_tipo.movgest_ts_tipo_code
FROM siac_t_movgest t_movgest,
siac_t_bil t_bil,
siac_t_periodo t_periodo,
siac_t_movgest_ts t_movgest_ts,    
siac_d_movgest_tipo d_movgest_tipo,            
siac_d_movgest_ts_tipo d_movgest_ts_tipo,
siac_r_movgest_ts_stato r_movgest_ts_stato,
siac_d_movgest_stato d_movgest_stato 
WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
AND t_bil.bil_id= t_movgest.bil_id   
AND t_periodo.periodo_id=t_bil.periodo_id    
AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	       
AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
AND t_movgest.ente_proprietario_id=p_ente_proprietario_id
AND t_periodo.anno = p_anno_bilancio
--AND t_movgest.movgest_anno = 2017
AND t_movgest.parere_finanziario = 'TRUE' -- Da considrare?  24.08.2017 Sofia secondo me deve rimanere
AND d_movgest_tipo.movgest_tipo_code='I'
AND d_movgest_stato.movgest_stato_code = 'D' -- Da considrare? 24.08.2017 Sofia secondo me deve rimanere
--AND d_movgest_ts_tipo.movgest_ts_tipo_code = 'T' -- solo impegni non sub-impegni
AND t_movgest_ts.data_cancellazione IS NULL
AND t_movgest.data_cancellazione IS NULL   
AND t_bil.data_cancellazione IS NULL 
AND t_periodo.data_cancellazione IS NULL
AND d_movgest_tipo.data_cancellazione IS NULL            
AND d_movgest_ts_tipo.data_cancellazione IS NULL
AND r_movgest_ts_stato.data_cancellazione IS NULL
AND d_movgest_stato.data_cancellazione IS NULL
-- AND p_data BETWEEN r_movgest_ts_stato.validita_inizio and COALESCE(r_movgest_ts_stato.validita_fine,p_data)
and  t_movgest.validita_fine is null
and  t_bil.validita_fine is null
and  t_periodo.validita_fine is null
and  t_movgest_ts.validita_fine is null
and  d_movgest_tipo.validita_fine is null
and  d_movgest_ts_tipo.validita_fine is null
and  r_movgest_ts_stato.validita_fine is null
and  d_movgest_stato.validita_fine is null
)
, sogg as (SELECT
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND a.ente_proprietario_id = p_ente_proprietario_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
-- AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND  a.validita_fine is null
AND  b.validita_fine is null

)
, sogcla as (SELECT 
a.movgest_ts_id,
b.soggetto_classe_code, b.soggetto_classe_desc
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE a.ente_proprietario_id = p_ente_proprietario_id 
AND a.soggetto_classe_id = b.soggetto_classe_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
-- AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
AND  a.validita_fine is null
AND  b.validita_fine is null
)
, impliquidatoquietanzato AS (
WITH quietanzato AS (
  SELECT e.ord_ts_det_importo, a.ord_id, b.ord_ts_id
  FROM 
  siac_t_ordinativo a,
  siac_t_ordinativo_ts b,
  siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
  siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
  WHERE a.ente_proprietario_id = p_ente_proprietario_id 
  AND  a.ord_id = b.ord_id
  AND  c.ord_id = b.ord_id
  AND  c.ord_stato_id = d.ord_stato_id
  AND  e.ord_ts_id = b.ord_ts_id
  AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
  AND  d.ord_stato_code= 'Q'
  AND  f.ord_ts_det_tipo_code = 'A'  
  AND  a.data_cancellazione IS NULL
  AND  b.data_cancellazione IS NULL
  AND  c.data_cancellazione IS NULL 
  AND  d.data_cancellazione IS NULL  
  AND  e.data_cancellazione IS NULL
  AND  f.data_cancellazione IS NULL
  -- AND   p_data BETWEEN c.validita_inizio and COALESCE(c.validita_fine,p_data)
  AND  a.validita_fine is null
  AND  b.validita_fine is null
  AND  c.validita_fine is null
  AND  d.validita_fine is null
  AND  e.validita_fine is null
  AND  f.validita_fine is null            
/*  )
, sogg AS (SELECT 
a.ord_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale, 
b.codice_fiscale_estero, b.partita_iva
FROM siac_r_ordinativo_soggetto a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
AND a.ente_proprietario_id = p_ente_proprietario_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)*/
)
SELECT
quietanzato.ord_ts_det_importo,/*
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, 
sogg.codice_fiscale_estero, sogg.partita_iva,*/
b.movgest_ts_id,
d.movgest_anno,
d.movgest_numero
FROM  quietanzato
--INNER JOIN sogg ON quietanzato.ord_id = sogg.ord_id
INNER JOIN siac_r_liquidazione_ord a ON  a.sord_id = quietanzato.ord_ts_id
INNER JOIN siac_r_liquidazione_movgest b ON b.liq_id = a.liq_id
INNER JOIN siac_t_movgest_ts c ON b.movgest_ts_id = c.movgest_ts_id
INNER JOIN siac_t_movgest d ON d.movgest_id = c.movgest_id
WHERE a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
-- AND   p_data BETWEEN a.validita_inizio and COALESCE(a.validita_fine,p_data)
-- AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine,p_data)
AND  a.validita_fine is null
AND  b.validita_fine is null
AND  c.validita_fine is null
AND  d.validita_fine is null
)
--INSERT INTO siac_clearo_quietanzato
INSERT INTO siac_clearo_impegnato_quietanzato
(ente_proprietario_id,
 anno_bilancio,
 anno_atto_amministrativo,
 num_atto_amministrativo,
 oggetto_atto_amministrativo,
 note_atto_amministrativo,
 cod_tipo_atto_amministrativo,
 desc_tipo_atto_amministrativo,
 desc_stato_atto_amministrativo,
 anno_impegno,
 num_impegno,
 quietanzato,
 cod_soggetto,
 desc_soggetto,
 cf_soggetto,
 cf_estero_soggetto,
 p_iva_soggetto,
 cod_classe_soggetto,
 desc_classe_soggetto, 
 tipo_impegno,
 tipo_importo)
SELECT 
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, provvedimenti.attoamm_numero, provvedimenti.attoamm_oggetto, provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, provvedimenti.attoamm_tipo_desc, provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, impegnato.movgest_numero,
-- impliquidatoquietanzato.ord_ts_det_importo,
COALESCE(SUM(impliquidatoquietanzato.ord_ts_det_importo),0) importo_quietanzato, 
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale, sogg.codice_fiscale_estero, sogg.partita_iva,
sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc, 
-- impliquidatoquietanzato.soggetto_code, impliquidatoquietanzato.soggetto_desc, impliquidatoquietanzato.codice_fiscale, 
-- impliquidatoquietanzato.codice_fiscale_estero, impliquidatoquietanzato.partita_iva,
impegnato.movgest_ts_tipo_code,
'Q'
FROM provvedimenti
INNER JOIN impegnato ON impegnato.movgest_ts_id = provvedimenti.movgest_ts_id
LEFT  JOIN sogg ON sogg.movgest_ts_id = impegnato.movgest_ts_id
LEFT  JOIN sogcla ON sogcla.movgest_ts_id = impegnato.movgest_ts_id
--INNER JOIN impliquidatoquietanzato ON impliquidatoquietanzato.movgest_ts_id = provvedimenti.movgest_ts_id
INNER JOIN impliquidatoquietanzato ON impliquidatoquietanzato.movgest_anno = provvedimenti.movgest_anno
                                   AND impliquidatoquietanzato.movgest_numero = provvedimenti.movgest_numero
GROUP BY
p_ente_proprietario_id,
p_anno_bilancio,
provvedimenti.attoamm_anno, 
provvedimenti.attoamm_numero, 
provvedimenti.attoamm_oggetto, 
provvedimenti.attoamm_note,
provvedimenti.attoamm_tipo_code, 
provvedimenti.attoamm_tipo_desc, 
provvedimenti.attoamm_stato_desc,
impegnato.movgest_anno, 
impegnato.movgest_numero,
/*impliquidatoquietanzato.soggetto_code, 
impliquidatoquietanzato.soggetto_desc, 
impliquidatoquietanzato.codice_fiscale, 
impliquidatoquietanzato.codice_fiscale_estero, 
impliquidatoquietanzato.partita_iva,*/
sogg.soggetto_code, 
sogg.soggetto_desc, 
sogg.codice_fiscale, 
sogg.codice_fiscale_estero, 
sogg.partita_iva,
sogcla.soggetto_classe_code, 
sogcla.soggetto_classe_desc,
impegnato.movgest_ts_tipo_code,
'Q'::varchar;

esito:='ok';

EXCEPTION
WHEN others THEN
  esito:='Funzione carico impegnato quietanzato (FNC_SIAC_CLEARO_IMPEGNATO_QUIETANZATO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;