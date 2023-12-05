/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- siac.v_simop_accert_scheda_partecipaz source
drop MATERIALIZED VIEW siac.v_simop_accert_scheda_partecipaz;

CREATE MATERIALIZED VIEW siac.v_simop_accert_scheda_partecipaz
TABLESPACE pg_default
AS WITH pdc AS (
         SELECT r.movgest_ts_id,
            cl.classif_code AS codice_pdc
           FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
          WHERE r.ente_proprietario_id = 2 AND r.classif_id = cl.classif_id AND cl.classif_tipo_id = tipo.classif_tipo_id AND tipo.classif_tipo_code::text = 'PDC_V'::text AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
        ), provvedimento AS (
         SELECT ratto.movgest_ts_id,
            (((((tipo.attoamm_tipo_code::text || ' '::text) || atto.attoamm_anno::text) || '/'::text) || atto.attoamm_numero) || '   '::text) || cl.classif_code::text AS provvedimento
           FROM siac_r_movgest_ts_atto_amm ratto,
            siac_t_movgest mov,
            siac_t_movgest_ts ts,
            siac_d_movgest_tipo tipomov,
            siac_d_atto_amm_tipo tipo,
            siac_t_atto_amm atto
             LEFT JOIN siac_r_atto_amm_class rattocl ON atto.attoamm_id = rattocl.attoamm_id AND rattocl.data_cancellazione IS NULL AND rattocl.validita_fine IS NULL
             LEFT JOIN siac_t_class cl ON rattocl.classif_id = cl.classif_id
             LEFT JOIN siac_d_class_tipo tipocl ON cl.classif_tipo_id = tipocl.classif_tipo_id AND (tipocl.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text]))
          WHERE ratto.attoamm_id = atto.attoamm_id AND ratto.movgest_ts_id = ts.movgest_ts_id AND ts.movgest_id = mov.movgest_id AND atto.attoamm_tipo_id = tipo.attoamm_tipo_id AND mov.movgest_tipo_id = tipomov.movgest_tipo_id AND tipomov.movgest_tipo_code::text = 'A'::text AND ratto.data_cancellazione IS NULL AND ratto.validita_fine IS NULL
        ), capitolo AS (
         SELECT rcap.movgest_id,
            cap.elem_code AS capitolo,
            cap.elem_code2 AS articolo
           FROM siac_t_movgest mov,
            siac_r_movgest_bil_elem rcap,
            siac_t_bil_elem cap
          WHERE mov.ente_proprietario_id = 2 AND rcap.movgest_id = mov.movgest_id AND cap.elem_id = rcap.elem_id AND rcap.data_cancellazione IS NULL AND rcap.validita_fine IS NULL
        ), incassato AS (
         SELECT raccrev.movgest_ts_id,
            sum(importopag.ord_ts_det_importo) AS tot_inc
           FROM siac_r_ordinativo_ts_movgest_ts raccrev,
            siac_t_ordinativo rev,
            siac_r_ordinativo_stato rs,
            siac_d_ordinativo_stato stato,
            siac_d_ordinativo_tipo tipo,
            siac_t_ordinativo_ts ts,
            siac_t_ordinativo_ts_det importopag,
            siac_d_ordinativo_ts_det_tipo tipopag,
            siac_v_bko_accertamento_valido acc
          WHERE raccrev.movgest_ts_id = acc.movgest_ts_id AND raccrev.ord_ts_id = ts.ord_ts_id AND ts.ord_id = rev.ord_id AND rev.ord_tipo_id = tipo.ord_tipo_id AND rs.ord_id = rev.ord_id AND rs.ord_stato_id = stato.ord_stato_id AND stato.ord_stato_code::text <> 'A'::text AND tipo.ord_tipo_code::text = 'I'::text AND importopag.ord_ts_id = ts.ord_ts_id AND tipopag.ord_ts_det_tipo_id = importopag.ord_ts_det_tipo_id AND tipopag.ord_ts_det_tipo_code::text = 'A'::text AND raccrev.data_cancellazione IS NULL AND raccrev.validita_fine IS NULL AND rs.data_cancellazione IS NULL AND rs.validita_fine IS NULL
          GROUP BY raccrev.movgest_ts_id
        )
 SELECT DISTINCT to_char(acc.anno_bilancio) AS esercizio,
    sog.soggetto_code AS codice_anagrafico_fornitore,
    sog.codice_fiscale::character varying AS codice_fiscale_partecipata,
    sog.partita_iva AS p_iva_partecipata,
    sog.soggetto_desc AS nome_partecipata,
    acc.movgest_anno AS anno_accert,
    acc.movgest_numero AS numero_accert,
    acc.movgest_subnumero AS numero_sub_accert,
    acc.movgest_ts_desc AS descrizione_accert,
    pdc.codice_pdc AS pcf_completo,
        CASE
            WHEN acc.anno_bilancio = acc.movgest_anno THEN importiimpatt.movgest_ts_det_importo
            ELSE 0::numeric
        END AS importo_accertato,
    COALESCE(incassato.tot_inc, NULL::numeric, 0::numeric) AS importo_incassato,
    provvedimento.provvedimento,
    (capitolo.capitolo::text || '/'::text) || capitolo.articolo::text AS capitolo,
    'D'::text AS fonte
   FROM siac_r_movgest_ts_sog rsog,
    siac_t_movgest_ts_det importiimpatt,
    siac_d_movgest_ts_det_tipo tipoimportiatt,
    siac_t_soggetto sog,
    siac_t_soc_partecipate part,
    siac_v_bko_accertamento_valido acc
     LEFT JOIN pdc ON acc.movgest_ts_id = pdc.movgest_ts_id
     LEFT JOIN capitolo ON acc.movgest_id = capitolo.movgest_id
     LEFT JOIN provvedimento ON acc.movgest_ts_id = provvedimento.movgest_ts_id
     LEFT JOIN incassato ON acc.movgest_ts_id = incassato.movgest_ts_id
  WHERE rsog.movgest_ts_id = acc.movgest_ts_id AND rsog.soggetto_id = sog.soggetto_id AND sog.soggetto_code::text = part.codice::text AND part.anno::integer = acc.anno_bilancio AND importiimpatt.movgest_ts_id = acc.movgest_ts_id AND importiimpatt.movgest_ts_det_importo > 0::numeric AND importiimpatt.movgest_ts_det_tipo_id = tipoimportiatt.movgest_ts_det_tipo_id AND tipoimportiatt.movgest_ts_det_tipo_code::text = 'A'::text AND rsog.data_cancellazione IS NULL AND rsog.validita_fine IS NULL AND acc.anno_bilancio >= acc.movgest_anno
UNION
( WITH pdc AS (
         SELECT r.movgest_ts_id,
            cl.classif_code AS codice_pdc
           FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
          WHERE r.ente_proprietario_id = 2 AND r.classif_id = cl.classif_id AND cl.classif_tipo_id = tipo.classif_tipo_id AND tipo.classif_tipo_code::text = 'PDC_V'::text AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
        ), provvedimento AS (
         SELECT ratto.movgest_ts_id,
            (((((tipo.attoamm_tipo_code::text || ' '::text) || atto.attoamm_anno::text) || '/'::text) || atto.attoamm_numero) || '   '::text) || cl.classif_code::text AS provvedimento
           FROM siac_r_movgest_ts_atto_amm ratto,
            siac_t_movgest mov,
            siac_t_movgest_ts ts,
            siac_d_movgest_tipo tipomov,
            siac_d_atto_amm_tipo tipo,
            siac_t_atto_amm atto
             LEFT JOIN siac_r_atto_amm_class rattocl ON atto.attoamm_id = rattocl.attoamm_id AND rattocl.data_cancellazione IS NULL AND rattocl.validita_fine IS NULL
             LEFT JOIN siac_t_class cl ON rattocl.classif_id = cl.classif_id
             LEFT JOIN siac_d_class_tipo tipocl ON cl.classif_tipo_id = tipocl.classif_tipo_id AND (tipocl.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text]))
          WHERE ratto.attoamm_id = atto.attoamm_id AND ratto.movgest_ts_id = ts.movgest_ts_id AND ts.movgest_id = mov.movgest_id AND atto.attoamm_tipo_id = tipo.attoamm_tipo_id AND mov.movgest_tipo_id = tipomov.movgest_tipo_id AND tipomov.movgest_tipo_code::text = 'A'::text AND ratto.data_cancellazione IS NULL AND ratto.validita_fine IS NULL
        ), capitolo AS (
         SELECT rcap.movgest_id,
            cap.elem_code AS capitolo,
            cap.elem_code2 AS articolo
           FROM siac_t_movgest mov,
            siac_r_movgest_bil_elem rcap,
            siac_t_bil_elem cap
          WHERE mov.ente_proprietario_id = 2 AND rcap.movgest_id = mov.movgest_id AND cap.elem_id = rcap.elem_id AND rcap.data_cancellazione IS NULL AND rcap.validita_fine IS NULL
        ), incassato AS (
         SELECT raccrev.movgest_ts_id,
            rrevsog.soggetto_id,
            sum(importopag.ord_ts_det_importo) AS tot_inc
           FROM siac_r_ordinativo_ts_movgest_ts raccrev,
            siac_t_ordinativo rev,
            siac_r_ordinativo_stato rs,
            siac_d_ordinativo_stato stato,
            siac_r_ordinativo_soggetto rrevsog,
            siac_t_soggetto soginc,
            siac_d_ordinativo_tipo tipo,
            siac_t_ordinativo_ts ts,
            siac_t_ordinativo_ts_det importopag,
            siac_d_ordinativo_ts_det_tipo tipopag,
            siac_t_soc_partecipate part,
            siac_t_periodo periodo,
            siac_t_bil bil
          WHERE raccrev.ord_ts_id = ts.ord_ts_id AND ts.ord_id = rev.ord_id AND rev.ord_tipo_id = tipo.ord_tipo_id AND bil.bil_id = rev.bil_id AND bil.periodo_id = periodo.periodo_id AND rs.ord_id = rev.ord_id AND rs.ord_stato_id = stato.ord_stato_id AND stato.ord_stato_code::text <> 'A'::text AND tipo.ord_tipo_code::text = 'I'::text AND importopag.ord_ts_id = ts.ord_ts_id AND tipopag.ord_ts_det_tipo_id = importopag.ord_ts_det_tipo_id AND tipopag.ord_ts_det_tipo_code::text = 'A'::text AND rs.data_cancellazione IS NULL AND rs.validita_fine IS NULL AND rrevsog.soggetto_id = soginc.soggetto_id AND soginc.soggetto_code::text = part.codice::text AND part.anno::text = periodo.anno::text AND rrevsog.ord_id = rev.ord_id AND rrevsog.soggetto_id = soginc.soggetto_id AND rrevsog.data_cancellazione IS NULL AND rrevsog.validita_fine IS NULL AND 0 <> (( SELECT count(*) AS count
                   FROM siac_r_movgest_ts_sogclasse rms
                  WHERE rms.movgest_ts_id = raccrev.movgest_ts_id AND rms.data_cancellazione IS NULL))
          GROUP BY raccrev.movgest_ts_id, rrevsog.soggetto_id
        )
 SELECT DISTINCT to_char(accertamento.anno_bilancio) AS esercizio,
    sogrev.soggetto_code AS codice_anagrafico_fornitore,
    sogrev.codice_fiscale::character varying AS codice_fiscale_partecipata,
    sogrev.partita_iva AS p_iva_partecipata,
    sogrev.soggetto_desc AS nome_partecipata,
    accertamento.movgest_anno AS anno_accert,
    accertamento.movgest_numero AS numero_accert,
    accertamento.movgest_subnumero AS numero_sub_accert,
    accertamento.movgest_ts_desc AS descrizione_accert,
    pdc.codice_pdc AS pcf_completo,
/*        CASE
            WHEN accertamento.anno_bilancio = accertamento.movgest_anno THEN incassato.tot_inc
            ELSE 0::numeric
        END AS importo_accertato,*/
        incassato.tot_inc AS importo_accertato,
    COALESCE(incassato.tot_inc, NULL::numeric, 0::numeric) AS importo_incassato,
    provvedimento.provvedimento,
    (capitolo.capitolo::text || '/'::text) || capitolo.articolo::text AS capitolo,
    'Q'::text AS fonte
   FROM siac_v_bko_accertamento_valido accertamento
     LEFT JOIN pdc ON accertamento.movgest_ts_id = pdc.movgest_ts_id
     LEFT JOIN capitolo ON accertamento.movgest_id = capitolo.movgest_id
     LEFT JOIN provvedimento ON accertamento.movgest_ts_id = provvedimento.movgest_ts_id
     LEFT JOIN incassato ON accertamento.movgest_ts_id = incassato.movgest_ts_id
     LEFT JOIN siac_t_soggetto sogrev ON incassato.soggetto_id = sogrev.soggetto_id
  WHERE incassato.tot_inc > 0::numeric)
  ORDER BY 4, 5, 6
WITH DATA;