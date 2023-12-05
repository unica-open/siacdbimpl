/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- siac.v_simop_impegni_scheda_partecipaz source
drop MATERIALIZED VIEW siac.v_simop_impegni_scheda_partecipaz;

CREATE MATERIALIZED VIEW siac.v_simop_impegni_scheda_partecipaz
TABLESPACE pg_default
AS WITH pdc AS (
         SELECT r.movgest_ts_id,
            cl.classif_code AS codice_pdc
           FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
          WHERE r.ente_proprietario_id = 2 AND r.classif_id = cl.classif_id AND cl.classif_tipo_id = tipo.classif_tipo_id AND tipo.classif_tipo_code::text = 'PDC_V'::text AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
        ), cig AS (
         SELECT rattr.movgest_ts_id,
            rattr.testo AS codice_cig
           FROM siac_r_movgest_ts_attr rattr,
            siac_t_attr attr
          WHERE rattr.testo IS NOT NULL AND rattr.testo::text <> ''::text AND attr.attr_id = rattr.attr_id AND attr.attr_code::text = 'cig'::text AND rattr.data_cancellazione IS NULL AND rattr.validita_fine IS NULL
        ), provvedimento AS (        
SELECT ratto.movgest_ts_id,
            (((((tipo.attoamm_tipo_code::text || ' '::text) || atto.attoamm_anno::text) || '/'::text) || atto.attoamm_numero) || '   '::text) || cl.classif_code::text AS provvedimento
           FROM siac_r_movgest_ts_atto_amm ratto,
            siac_t_movgest mov,
            siac_t_movgest_ts ts, 
            siac_d_atto_amm_tipo tipo,
            siac_t_atto_amm atto
             LEFT JOIN siac_r_atto_amm_class rattocl ON atto.attoamm_id = rattocl.attoamm_id AND rattocl.data_cancellazione IS NULL AND rattocl.validita_fine IS NULL
             LEFT JOIN siac_t_class cl ON rattocl.classif_id = cl.classif_id
             LEFT JOIN siac_d_class_tipo tipocl ON cl.classif_tipo_id = tipocl.classif_tipo_id AND (tipocl.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text]))
          WHERE ratto.attoamm_id = atto.attoamm_id 
            AND ratto.movgest_ts_id = ts.movgest_ts_id
            and ts.movgest_id = mov.movgest_id 
            AND atto.attoamm_tipo_id = tipo.attoamm_tipo_id 
            AND ratto.data_cancellazione IS NULL 
            AND ratto.validita_fine IS NULL
          ), capitolo AS (
         SELECT rcap.movgest_id,
            cap.elem_code AS capitolo,
            cap.elem_code2 AS articolo
           FROM siac_t_movgest mov,
            siac_t_movgest_ts ts, 
            siac_r_movgest_bil_elem rcap,
            siac_t_bil_elem cap
          WHERE rcap.ente_proprietario_id = 2 
            AND rcap.movgest_id = ts.movgest_id 
            and ts.movgest_id = mov.movgest_id 
            AND cap.elem_id = rcap.elem_id 
            AND rcap.data_cancellazione IS NULL 
            AND rcap.validita_fine IS null
        ), liquidato AS (
         SELECT rliqmov.movgest_ts_id,
            sum(liq.liq_importo) AS tot_liq
           FROM siac_r_liquidazione_movgest rliqmov,
            siac_t_liquidazione liq,
            siac_r_liquidazione_stato rs,
            siac_d_liquidazione_stato stato,
            siac_t_movgest mov,
            siac_t_movgest_ts ts
          WHERE rliqmov.liq_id = liq.liq_id 
            AND rliqmov.movgest_ts_id = ts.movgest_ts_id 
            and ts.movgest_id = mov.movgest_id 
            AND rs.liq_id = liq.liq_id 
            AND rs.liq_stato_id = stato.liq_stato_id 
            AND stato.liq_stato_code::text <> 'A'::text 
            AND rliqmov.data_cancellazione IS NULL 
            AND rliqmov.validita_fine IS NULL 
            AND rs.data_cancellazione IS NULL 
            AND rs.validita_fine IS NULL 
            AND liq.data_cancellazione IS NULL
          GROUP BY rliqmov.movgest_ts_id
        ), pagato AS (
         SELECT rliqmov.movgest_ts_id,
            sum(importopag.ord_ts_det_importo) AS tot_pag
           FROM siac_r_liquidazione_movgest rliqmov,
            siac_t_liquidazione liq,
            siac_r_liquidazione_stato rstliq,
            siac_d_liquidazione_stato statoliq,
            siac_r_liquidazione_ord rliqord,
            siac_t_ordinativo mand,
            siac_r_ordinativo_stato rstmand,
            siac_d_ordinativo_stato statomand,
            siac_d_ordinativo_tipo tipo,
            siac_t_ordinativo_ts ts,
            siac_t_ordinativo_ts_det importopag,
            siac_d_ordinativo_ts_det_tipo tipopag
          WHERE rliqmov.liq_id = liq.liq_id 
            AND rliqord.liq_id = liq.liq_id 
            AND liq.liq_id = rstliq.liq_id 
            AND rstliq.liq_stato_id = statoliq.liq_stato_id 
            AND statoliq.liq_stato_code::text = 'V'::text 
            AND rliqord.sord_id = ts.ord_ts_id 
            AND ts.ord_id = mand.ord_id 
            AND mand.ord_tipo_id = tipo.ord_tipo_id 
            AND tipo.ord_tipo_code::text = 'P'::text 
            AND mand.ord_id = rstmand.ord_id 
            AND rstmand.ord_stato_id = statomand.ord_stato_id 
            AND statomand.ord_stato_code::text <> 'A'::text 
            AND mand.ord_id = ts.ord_id 
            AND importopag.ord_ts_id = ts.ord_ts_id
            AND tipopag.ord_ts_det_tipo_id = importopag.ord_ts_det_tipo_id 
            AND tipopag.ord_ts_det_tipo_code::text = 'A'::text 
            AND rliqmov.data_cancellazione IS NULL 
            AND rliqmov.validita_fine IS NULL 
            AND rstmand.data_cancellazione IS NULL 
            AND rstmand.validita_fine IS NULL 
            AND rstliq.data_cancellazione IS NULL 
            AND rstliq.validita_fine IS NULL
          GROUP BY rliqmov.movgest_ts_id   
        )
 SELECT DISTINCT 
    to_char(periodomov.anno::integer) as esercizio,
    sog.codice_fiscale::character varying AS codice_fiscale_partecipata,
    sog.partita_iva AS p_iva_partecipata,
    sog.soggetto_code AS codice_anagrafico_fornitore,
    sog.soggetto_desc AS nome_partecipata,
    mov.movgest_anno AS anno_impegno,
    mov.movgest_numero AS numero_impegno,
       CASE
            WHEN tsMov.movgest_ts_code::integer::numeric = mov.movgest_numero THEN 0
            ELSE tsMov.movgest_ts_code::integer
        END AS numero_sub_impegno,
    tsMov.movgest_ts_desc AS descrizione_impegno,
    statoMov.movgest_stato_code Stato_Impegno,
    pdc.codice_pdc AS pcf_completo,
        CASE
            WHEN periodomov.anno::integer = mov.movgest_anno THEN importiimpatt.movgest_ts_det_importo
            ELSE 0::numeric
        END AS importo_impegnato,
    COALESCE(liquidato.tot_liq, NULL::numeric, 0::numeric) AS liquidato,
    COALESCE(pagato.tot_pag, NULL::numeric, 0::numeric) AS importo_pagato,
    provvedimento.provvedimento,
    cig.codice_cig,
    motivo_assenza.siope_assenza_motivazione_desc,
    (capitolo.capitolo::text || '/'::text) || capitolo.articolo::text AS capitolo,
    'D'::text AS fonte
   FROM siac_r_movgest_ts_sog rsog,
    siac_t_movgest_ts_det importiimpatt,
    siac_d_movgest_ts_det_tipo tipoimportiatt,
    siac_t_soggetto sog,
    siac_t_soc_partecipate part,
    siac_t_bil bilmov,
    siac_t_periodo periodomov,
    siac_t_movgest mov    
          JOIN siac_d_movgest_tipo tipomov_1 ON mov.movgest_tipo_id = tipomov_1.movgest_tipo_id AND tipomov_1.movgest_tipo_code::text = 'I'::text
     LEFT JOIN siac_t_movgest_ts tsMov ON mov.movgest_id = tsMov.movgest_id
     LEFT JOIN siac_r_movgest_ts_stato rsMov ON tsMov.movgest_ts_id = rsMov.movgest_ts_id AND rsMov.data_cancellazione IS NULL AND rsMov.validita_fine IS NULL
          JOIN siac_d_movgest_stato statoMov ON rsMov.movgest_stato_id = statoMov.movgest_stato_id AND statoMov.movgest_stato_code::text = 'D'::text   
     LEFT JOIN pdc ON tsMov.movgest_ts_id = pdc.movgest_ts_id
     LEFT JOIN cig ON tsMov.movgest_ts_id = cig.movgest_ts_id
     LEFT JOIN capitolo ON mov.movgest_id = capitolo.movgest_id
     LEFT JOIN provvedimento ON tsMov.movgest_ts_id = provvedimento.movgest_ts_id
     LEFT JOIN liquidato ON tsMov.movgest_ts_id = liquidato.movgest_ts_id
     LEFT JOIN pagato ON tsMov.movgest_ts_id = pagato.movgest_ts_id
     LEFT JOIN siac_d_siope_assenza_motivazione motivo_assenza ON tsMov.siope_assenza_motivazione_id = motivo_assenza.siope_assenza_motivazione_id
  WHERE rsog.movgest_ts_id = tsMov.movgest_ts_id 
    AND rsog.soggetto_id = sog.soggetto_id 
    AND sog.soggetto_code::text = part.codice::text 
    AND part.anno = periodomov.anno 
    AND importiimpatt.movgest_ts_id = tsMov.movgest_ts_id 
    AND importiimpatt.movgest_ts_det_importo > 0::numeric 
    AND importiimpatt.movgest_ts_det_tipo_id = tipoimportiatt.movgest_ts_det_tipo_id 
    AND tipoimportiatt.movgest_ts_det_tipo_code::text = 'A'::text 
    AND mov.bil_id = bilmov.bil_id 
    AND bilmov.periodo_id = periodomov.periodo_id 
    AND rsog.data_cancellazione IS NULL 
    AND rsog.validita_fine IS NULL 
    AND mov.data_cancellazione IS NULL 
    AND mov.validita_fine IS NULL 
    AND periodomov.anno::integer >= mov.movgest_anno
UNION
( WITH pdc AS (
         SELECT r.movgest_ts_id,
            cl.classif_code AS codice_pdc
           FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
          WHERE r.ente_proprietario_id = 2 AND r.classif_id = cl.classif_id AND cl.classif_tipo_id = tipo.classif_tipo_id AND tipo.classif_tipo_code::text = 'PDC_V'::text AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
        ), cig AS (
         SELECT rattr.movgest_ts_id,
            rattr.testo AS codice_cig
           FROM siac_r_movgest_ts_attr rattr,
            siac_t_attr attr
          WHERE rattr.testo IS NOT NULL AND rattr.testo::text <> ''::text AND attr.attr_id = rattr.attr_id AND attr.attr_code::text = 'cig'::text AND rattr.data_cancellazione IS NULL AND rattr.validita_fine IS NULL
        ), provvedimento AS (
         SELECT ratto.movgest_ts_id,
            (((((tipo.attoamm_tipo_code::text || ' '::text) || atto.attoamm_anno::text) || '/'::text) || atto.attoamm_numero) || '   '::text) || cl.classif_code::text AS provvedimento
           FROM siac_r_movgest_ts_atto_amm ratto,
            siac_t_movgest mov,
            siac_t_movgest_ts ts, 
            siac_d_atto_amm_tipo tipo,
            siac_t_atto_amm atto
             LEFT JOIN siac_r_atto_amm_class rattocl ON atto.attoamm_id = rattocl.attoamm_id AND rattocl.data_cancellazione IS NULL AND rattocl.validita_fine IS NULL
             LEFT JOIN siac_t_class cl ON rattocl.classif_id = cl.classif_id
             LEFT JOIN siac_d_class_tipo tipocl ON cl.classif_tipo_id = tipocl.classif_tipo_id AND (tipocl.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text]))
          WHERE ratto.attoamm_id = atto.attoamm_id 
            AND ratto.movgest_ts_id = ts.movgest_ts_id
            and ts.movgest_id = mov.movgest_id 
            AND atto.attoamm_tipo_id = tipo.attoamm_tipo_id 
            AND ratto.data_cancellazione IS NULL 
            AND ratto.validita_fine IS NULL
        ), capitolo AS (
         SELECT rcap.movgest_id,
            cap.elem_code AS capitolo,
            cap.elem_code2 AS articolo
           FROM siac_t_movgest imp,
            siac_r_movgest_bil_elem rcap,
            siac_t_bil_elem cap
          WHERE imp.ente_proprietario_id = 2 AND rcap.movgest_id = imp.movgest_id AND cap.elem_id = rcap.elem_id AND rcap.data_cancellazione IS NULL AND rcap.validita_fine IS NULL
        ), liquidato AS (
         select liquidato_interno.movgest_ts_id, liquidato_interno.soggetto_id, sum(liquidato_interno.tot_liq) tot_liq from 
         (SELECT rliqmov.movgest_ts_id,
            rliqsog.soggetto_id,
            CASE
              WHEN periodo.anno::integer = liq.liq_anno THEN sum(liq.liq_importo)
               ELSE 0::integer
            END AS tot_liq      
           --sum(liq.liq_importo) AS tot_liq
           FROM siac_r_liquidazione_movgest rliqmov,
            siac_t_liquidazione liq,
            siac_r_liquidazione_stato rs,
            siac_d_liquidazione_stato stato,
            siac_r_liquidazione_soggetto rliqsog,
            siac_t_soggetto sogliq_1,
            siac_t_soc_partecipate part,
            siac_t_periodo periodo,
            siac_t_bil bil            
          WHERE rliqmov.liq_id = liq.liq_id 
            AND rs.liq_id = liq.liq_id 
            AND rs.liq_stato_id = stato.liq_stato_id 
            AND stato.liq_stato_code::text <> 'A'::text 
            AND rliqsog.liq_id = liq.liq_id 
            AND bil.bil_id = liq.bil_id 
            AND bil.periodo_id = periodo.periodo_id
            --AND periodo.anno::integer = liq.liq_anno 
            AND rliqsog.soggetto_id = sogliq_1.soggetto_id 
            AND sogliq_1.soggetto_code::text = part.codice::text 
            AND part.anno = periodo.anno
            AND rliqmov.data_cancellazione IS NULL 
            AND rliqmov.validita_fine IS NULL 
            AND rs.data_cancellazione IS NULL 
            AND rs.validita_fine IS NULL 
            AND rliqsog.data_cancellazione IS NULL 
            AND rliqsog.validita_fine IS NULL 
            AND liq.data_cancellazione IS NULL 
            AND 0 <> (( SELECT count(*) AS count
                   FROM siac_r_movgest_ts_sogclasse rms
                  WHERE rms.movgest_ts_id = rliqmov.movgest_ts_id 
                    AND rms.data_cancellazione IS NULL))
          group by periodo.anno, liq.liq_anno, rliqmov.movgest_ts_id, rliqsog.soggetto_id) liquidato_interno
          GROUP  BY  liquidato_interno.movgest_ts_id, liquidato_interno.soggetto_id    
        ),pagato AS (
         SELECT distinct 
            rliqmov.movgest_ts_id,
            rliqsog.soggetto_id,
            sum(importopag.ord_ts_det_importo) AS tot_pag
           FROM siac_r_liquidazione_movgest rliqmov,
            siac_t_liquidazione liq,
            siac_r_liquidazione_soggetto rliqsog,
            siac_t_soggetto sogliq_1,
            siac_r_liquidazione_stato rstliq,
            siac_d_liquidazione_stato statoliq,
            siac_r_liquidazione_ord rliqord,
            siac_t_ordinativo mand,
            siac_r_ordinativo_stato rstmand,
            siac_d_ordinativo_stato statomand,
            siac_d_ordinativo_tipo tipo,
            siac_t_ordinativo_ts ts,
            siac_t_ordinativo_ts_det importopag,
            siac_d_ordinativo_ts_det_tipo tipopag,
            siac_t_soc_partecipate part,
            siac_t_periodo periodo,
            siac_t_bil bil
          WHERE rliqmov.liq_id = liq.liq_id 
            AND rliqord.liq_id = liq.liq_id 
            AND liq.liq_id = rstliq.liq_id 
            AND rstliq.liq_stato_id = statoliq.liq_stato_id 
            AND statoliq.liq_stato_code::text = 'V'::text 
            AND rliqord.sord_id = ts.ord_ts_id 
            AND ts.ord_id = mand.ord_id 
            AND mand.ord_tipo_id = tipo.ord_tipo_id 
            AND tipo.ord_tipo_code::text = 'P'::text 
            AND mand.ord_id = rstmand.ord_id 
            AND rstmand.ord_stato_id = statomand.ord_stato_id 
            AND statomand.ord_stato_code::text <> 'A'::text 
            AND mand.ord_id = ts.ord_id 
            AND importopag.ord_ts_id = ts.ord_ts_id 
            AND tipopag.ord_ts_det_tipo_id = importopag.ord_ts_det_tipo_id 
            AND tipopag.ord_ts_det_tipo_code::text = 'A'::text 
            AND rliqmov.data_cancellazione IS NULL 
            AND rliqmov.validita_fine IS NULL 
            AND rstmand.data_cancellazione IS NULL 
            AND rstmand.validita_fine IS NULL 
            AND rstliq.data_cancellazione IS NULL 
            AND rstliq.validita_fine IS NULL 
            AND bil.bil_id = liq.bil_id 
            AND bil.periodo_id = periodo.periodo_id
--            AND periodo.anno::integer = liq.liq_anno 
            AND rliqsog.soggetto_id = sogliq_1.soggetto_id 
            AND sogliq_1.soggetto_code::text = part.codice::text 
            AND part.anno = periodo.anno
            AND rliqsog.liq_id = liq.liq_id 
            AND rliqsog.soggetto_id = sogliq_1.soggetto_id 
            AND rliqsog.data_cancellazione IS NULL 
            AND rliqsog.validita_fine IS NULL 
            AND liq.data_cancellazione IS NULL 
            AND 0 <> (( SELECT count(*) AS count
                   FROM siac_r_movgest_ts_sogclasse rms
                  WHERE rms.movgest_ts_id = rliqmov.movgest_ts_id AND rms.data_cancellazione IS NULL))                  
                  GROUP BY rliqmov.movgest_ts_id, rliqsog.soggetto_id 
        )
 SELECT DISTINCT 
    to_char(periodomov.anno::integer) as esercizio,
    sogLiq.codice_fiscale::character varying AS codice_fiscale_partecipata,
    sogLiq.partita_iva AS p_iva_partecipata,
    sogLiq.soggetto_code AS codice_anagrafico_fornitore,
    sogLiq.soggetto_desc AS nome_partecipata,
    mov.movgest_anno AS anno_impegno,
    mov.movgest_numero AS numero_impegno,      
       CASE
            WHEN tsMov.movgest_ts_code::integer::numeric = mov.movgest_numero THEN 0
            ELSE tsMov.movgest_ts_code::integer
        END AS numero_sub_impegno,
    tsMov.movgest_ts_desc AS descrizione_impegno,
    statoMov.movgest_stato_code Stato_Impegno,
    pdc.codice_pdc AS pcf_completo,
    COALESCE(liquidato.tot_liq, NULL::numeric, 0::numeric)   AS importo_impegnato,
    COALESCE(liquidato.tot_liq, NULL::numeric, 0::numeric)  AS liquidato,
    COALESCE(pagato.tot_pag, NULL::numeric, 0::numeric) AS importo_pagato,
    provvedimento.provvedimento,
    cig.codice_cig,
    motivo_assenza.siope_assenza_motivazione_desc,
    (capitolo.capitolo::text || '/'::text) || capitolo.articolo::text AS capitolo,
    'Q'::text AS fonte
FROM siac_t_soggetto sogLiq,
     siac_t_soc_partecipate part,
     siac_t_bil bilmov,
     siac_t_periodo periodomov,
     siac_t_movgest mov
          JOIN siac_d_movgest_tipo tipomov_1 ON mov.movgest_tipo_id = tipomov_1.movgest_tipo_id AND tipomov_1.movgest_tipo_code::text = 'I'::text
     LEFT JOIN siac_t_movgest_ts tsMov ON mov.movgest_id = tsMov.movgest_id
     LEFT JOIN siac_r_movgest_ts_stato rsMov ON tsMov.movgest_ts_id = rsMov.movgest_ts_id AND rsMov.data_cancellazione IS NULL AND rsMov.validita_fine IS NULL
          JOIN siac_d_movgest_stato statoMov ON rsMov.movgest_stato_id = statoMov.movgest_stato_id AND statoMov.movgest_stato_code::text = 'D'::text   
     LEFT JOIN pdc ON tsMov.movgest_ts_id = pdc.movgest_ts_id
     LEFT JOIN cig ON tsMov.movgest_ts_id = cig.movgest_ts_id
     LEFT JOIN capitolo ON mov.movgest_id = capitolo.movgest_id
     LEFT JOIN provvedimento ON tsMov.movgest_ts_id = provvedimento.movgest_ts_id
     LEFT JOIN liquidato ON tsMov.movgest_ts_id = liquidato.movgest_ts_id 
     LEFT JOIN pagato ON tsMov.movgest_ts_id = pagato.movgest_ts_id 
     LEFT JOIN siac_d_siope_assenza_motivazione motivo_assenza ON tsMov.siope_assenza_motivazione_id = motivo_assenza.siope_assenza_motivazione_id
  WHERE (liquidato.tot_liq > 0::numeric or pagato.tot_pag > 0::numeric)
    and mov.bil_id = bilmov.bil_id 
    AND bilmov.periodo_id = periodomov.periodo_id 
    AND sogLiq.soggetto_code::text = part.codice::text 
    AND part.anno = periodomov.anno 
    AND sogLiq.soggetto_id = liquidato.soggetto_id 
    and sogLiq.soggetto_id = pagato.soggetto_id
    AND mov.data_cancellazione IS NULL 
    AND mov.validita_fine IS null)            
  ORDER BY 4, 5, 6
WITH DATA;


