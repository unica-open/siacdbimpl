<<<<<<< HEAD
-- siac.v_simop_residui_passivi source
drop MATERIALIZED VIEW siac.v_simop_residui_passivi;


CREATE MATERIALIZED VIEW siac.v_simop_residui_passivi
TABLESPACE pg_default
AS WITH sac AS (
         SELECT r.movgest_ts_id,
            cl.classif_code AS codice_sac
           FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
          WHERE r.ente_proprietario_id = 2 AND r.classif_id = cl.classif_id AND cl.classif_tipo_id = tipo.classif_tipo_id AND (tipo.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
        ), liquidato_entro AS (
         SELECT DISTINCT mov.bil_id,
            mov.movgest_anno,
            mov.movgest_numero,
            sum(liq.liq_importo) AS tot_liq
           FROM siac_t_bil bilmov,
            siac_t_periodo periodomov,
            siac_t_movgest mov
             LEFT JOIN siac_d_movgest_tipo tipomov_1 ON mov.movgest_tipo_id = tipomov_1.movgest_tipo_id AND tipomov_1.movgest_tipo_code::text = 'I'::text
             LEFT JOIN siac_t_movgest_ts tsmov_1 ON mov.movgest_id = tsmov_1.movgest_id
             LEFT JOIN siac_r_movgest_ts_stato rsmov_1 ON tsmov_1.movgest_ts_id = rsmov_1.movgest_ts_id AND rsmov_1.data_cancellazione IS NULL AND rsmov_1.validita_fine IS NULL
             LEFT JOIN siac_d_movgest_stato statomov_1 ON rsmov_1.movgest_stato_id = statomov_1.movgest_stato_id AND statomov_1.movgest_stato_code::text = 'D'::text
             LEFT JOIN siac_r_liquidazione_movgest rliqmov ON tsmov_1.movgest_ts_id = rliqmov.movgest_ts_id AND rliqmov.data_cancellazione IS NULL AND rliqmov.validita_fine IS NULL
             LEFT JOIN siac_t_liquidazione liq ON rliqmov.liq_id = liq.liq_id AND liq.data_cancellazione IS NULL AND liq.validita_fine IS NULL
             LEFT JOIN siac_r_liquidazione_stato rsliq ON liq.liq_id = rsliq.liq_id AND rsliq.data_cancellazione IS NULL AND rsliq.validita_fine IS NULL
             JOIN siac_d_liquidazione_stato statoliq ON rsliq.liq_stato_id = statoliq.liq_stato_id AND statoliq.liq_stato_code::text = 'V'::text
          WHERE mov.bil_id = bilmov.bil_id AND bilmov.periodo_id = periodomov.periodo_id AND mov.data_cancellazione IS NULL AND mov.validita_fine IS NULL
          GROUP BY mov.bil_id, mov.movgest_anno, mov.movgest_numero
        ), liquidato_oltre AS (
         SELECT bilgen.bil_id,
            totale_liquid_anno.movgest_anno,
            totale_liquid_anno.movgest_numero,
            sum(totale_liquid_anno.tot_liq) AS tot_liq
           FROM ( SELECT DISTINCT mov.bil_id,
                    mov.movgest_anno,
                    mov.movgest_numero,
                    sum(liq.liq_importo) AS tot_liq
                   FROM siac_t_bil bilmov,
                    siac_t_periodo periodomov,
                    siac_t_movgest mov
                     LEFT JOIN siac_d_movgest_tipo tipomov_1 ON mov.movgest_tipo_id = tipomov_1.movgest_tipo_id AND tipomov_1.movgest_tipo_code::text = 'I'::text
                     LEFT JOIN siac_t_movgest_ts tsmov_1 ON mov.movgest_id = tsmov_1.movgest_id
                     LEFT JOIN siac_r_movgest_ts_stato rsmov_1 ON tsmov_1.movgest_ts_id = rsmov_1.movgest_ts_id AND rsmov_1.data_cancellazione IS NULL AND rsmov_1.validita_fine IS NULL
                     LEFT JOIN siac_d_movgest_stato statomov_1 ON rsmov_1.movgest_stato_id = statomov_1.movgest_stato_id AND statomov_1.movgest_stato_code::text = 'D'::text
                     LEFT JOIN siac_r_liquidazione_movgest rliqmov ON tsmov_1.movgest_ts_id = rliqmov.movgest_ts_id AND rliqmov.data_cancellazione IS NULL AND rliqmov.validita_fine IS NULL
                     LEFT JOIN siac_t_liquidazione liq ON rliqmov.liq_id = liq.liq_id AND liq.data_cancellazione IS NULL AND liq.validita_fine IS NULL
                     LEFT JOIN siac_r_liquidazione_stato rsliq ON liq.liq_id = rsliq.liq_id AND rsliq.data_cancellazione IS NULL AND rsliq.validita_fine IS NULL
                     JOIN siac_d_liquidazione_stato statoliq ON rsliq.liq_stato_id = statoliq.liq_stato_id AND statoliq.liq_stato_code::text = 'V'::text
                  WHERE mov.bil_id = bilmov.bil_id AND bilmov.periodo_id = periodomov.periodo_id AND mov.data_cancellazione IS NULL AND mov.validita_fine IS NULL
                  GROUP BY mov.bil_id, mov.movgest_anno, mov.movgest_numero) totale_liquid_anno,
            siac_t_bil bilgen
          WHERE bilgen.ente_proprietario_id = 2 AND totale_liquid_anno.bil_id > bilgen.bil_id
          GROUP BY bilgen.bil_id, totale_liquid_anno.movgest_anno, totale_liquid_anno.movgest_numero
        ), pagato_entro AS (
         SELECT DISTINCT mov.bil_id,
            mov.movgest_anno,
            mov.movgest_numero,
            sum(COALESCE(importopag.ord_ts_det_importo, NULL::numeric, 0::numeric)) AS tot_pag
           FROM siac_t_bil bilmov,
            siac_t_periodo periodomov,
            siac_t_movgest mov
             LEFT JOIN siac_d_movgest_tipo tipomov_1 ON mov.movgest_tipo_id = tipomov_1.movgest_tipo_id AND tipomov_1.movgest_tipo_code::text = 'I'::text
             LEFT JOIN siac_t_movgest_ts tsmov_1 ON mov.movgest_id = tsmov_1.movgest_id
             LEFT JOIN siac_r_movgest_ts_stato rsmov_1 ON tsmov_1.movgest_ts_id = rsmov_1.movgest_ts_id AND rsmov_1.data_cancellazione IS NULL AND rsmov_1.validita_fine IS NULL
             LEFT JOIN siac_d_movgest_stato statomov_1 ON rsmov_1.movgest_stato_id = statomov_1.movgest_stato_id AND statomov_1.movgest_stato_code::text = 'D'::text
             LEFT JOIN siac_r_liquidazione_movgest rliqmov ON tsmov_1.movgest_ts_id = rliqmov.movgest_ts_id AND rliqmov.data_cancellazione IS NULL AND rliqmov.validita_fine IS NULL
             LEFT JOIN siac_t_liquidazione liq ON rliqmov.liq_id = liq.liq_id AND liq.data_cancellazione IS NULL AND liq.validita_fine IS NULL
             LEFT JOIN siac_r_liquidazione_stato rsliq ON liq.liq_id = rsliq.liq_id AND rsliq.data_cancellazione IS NULL AND rsliq.validita_fine IS NULL
             JOIN siac_d_liquidazione_stato statoliq ON rsliq.liq_stato_id = statoliq.liq_stato_id AND statoliq.liq_stato_code::text = 'V'::text
             LEFT JOIN siac_r_liquidazione_ord rliqord ON liq.liq_id = rliqord.liq_id AND rliqord.data_cancellazione IS NULL AND rliqord.validita_fine IS NULL
             LEFT JOIN siac_t_ordinativo_ts tsord ON rliqord.sord_id = tsord.ord_ts_id
             LEFT JOIN siac_t_ordinativo mand ON tsord.ord_id = mand.ord_id
             LEFT JOIN siac_r_ordinativo_stato rsord ON mand.ord_id = rsord.ord_id AND rsord.data_cancellazione IS NULL AND rsord.validita_fine IS NULL
             JOIN siac_d_ordinativo_stato statomand ON rsord.ord_stato_id = statomand.ord_stato_id AND statomand.ord_stato_code::text = 'Q'::text
             LEFT JOIN siac_t_ordinativo_ts_det importopag ON tsord.ord_ts_id = importopag.ord_ts_id
             JOIN siac_d_ordinativo_ts_det_tipo tipopag ON importopag.ord_ts_det_tipo_id = tipopag.ord_ts_det_tipo_id AND tipopag.ord_ts_det_tipo_code::text = 'A'::text
          WHERE mov.bil_id = bilmov.bil_id AND bilmov.periodo_id = periodomov.periodo_id AND mov.data_cancellazione IS NULL AND mov.validita_fine IS NULL
          GROUP BY mov.bil_id, mov.movgest_anno, mov.movgest_numero
        ), pagato_oltre AS (
         SELECT bilgen.bil_id,
            pag_oltre.movgest_anno,
            pag_oltre.movgest_numero,
            sum(pag_oltre.pagato) AS tot_pag
           FROM ( SELECT mov.bil_id AS mov_bil_id,
                    mov.movgest_anno,
                    mov.movgest_numero,
                    sum(COALESCE(importopag.ord_ts_det_importo, NULL::numeric, 0::numeric)) AS pagato
                   FROM siac_t_bil bilmov,
                    siac_t_periodo periodomov,
                    siac_t_movgest mov
                     LEFT JOIN siac_d_movgest_tipo tipomov_1 ON mov.movgest_tipo_id = tipomov_1.movgest_tipo_id AND tipomov_1.movgest_tipo_code::text = 'I'::text
                     LEFT JOIN siac_t_movgest_ts tsmov_1 ON mov.movgest_id = tsmov_1.movgest_id
                     LEFT JOIN siac_r_movgest_ts_stato rsmov_1 ON tsmov_1.movgest_ts_id = rsmov_1.movgest_ts_id AND rsmov_1.data_cancellazione IS NULL AND rsmov_1.validita_fine IS NULL
                     LEFT JOIN siac_d_movgest_stato statomov_1 ON rsmov_1.movgest_stato_id = statomov_1.movgest_stato_id AND statomov_1.movgest_stato_code::text = 'D'::text
                     LEFT JOIN siac_r_liquidazione_movgest rliqmov ON tsmov_1.movgest_ts_id = rliqmov.movgest_ts_id AND rliqmov.data_cancellazione IS NULL AND rliqmov.validita_fine IS NULL
                     LEFT JOIN siac_t_liquidazione liq ON rliqmov.liq_id = liq.liq_id AND liq.data_cancellazione IS NULL AND liq.validita_fine IS NULL
                     LEFT JOIN siac_r_liquidazione_stato rsliq ON liq.liq_id = rsliq.liq_id AND rsliq.data_cancellazione IS NULL AND rsliq.validita_fine IS NULL
                     JOIN siac_d_liquidazione_stato statoliq ON rsliq.liq_stato_id = statoliq.liq_stato_id AND statoliq.liq_stato_code::text = 'V'::text
                     LEFT JOIN siac_r_liquidazione_ord rliqord ON liq.liq_id = rliqord.liq_id AND rliqord.data_cancellazione IS NULL AND rliqord.validita_fine IS NULL
                     LEFT JOIN siac_t_ordinativo_ts tsord ON rliqord.sord_id = tsord.ord_ts_id
                     LEFT JOIN siac_t_ordinativo mand ON tsord.ord_id = mand.ord_id
                     LEFT JOIN siac_r_ordinativo_stato rsord ON mand.ord_id = rsord.ord_id AND rsord.data_cancellazione IS NULL AND rsord.validita_fine IS NULL
                     JOIN siac_d_ordinativo_stato statomand ON rsord.ord_stato_id = statomand.ord_stato_id AND statomand.ord_stato_code::text = 'Q'::text
                     LEFT JOIN siac_t_ordinativo_ts_det importopag ON tsord.ord_ts_id = importopag.ord_ts_id
                     JOIN siac_d_ordinativo_ts_det_tipo tipopag ON importopag.ord_ts_det_tipo_id = tipopag.ord_ts_det_tipo_id AND tipopag.ord_ts_det_tipo_code::text = 'A'::text
                  WHERE mov.bil_id = bilmov.bil_id AND bilmov.periodo_id = periodomov.periodo_id AND mov.data_cancellazione IS NULL AND mov.validita_fine IS NULL AND mov.movgest_anno = 2017 AND mov.movgest_numero = 1945::numeric
                  GROUP BY mov.bil_id, mov.movgest_anno, mov.movgest_numero
                  ORDER BY mov.bil_id DESC) pag_oltre,
            siac_t_bil bilgen
          WHERE bilgen.ente_proprietario_id = 2 AND pag_oltre.mov_bil_id > bilgen.bil_id
          GROUP BY bilgen.bil_id, pag_oltre.movgest_anno, pag_oltre.movgest_numero
        ), documenti_entro AS (
         SELECT DISTINCT mov.bil_id,
            mov.movgest_anno,
            mov.movgest_numero,
            sum(sub.subdoc_importo) AS tot_quote
           FROM siac_t_bil bilmov,
            siac_t_movgest mov
             LEFT JOIN siac_d_movgest_tipo tipomov_1 ON mov.movgest_tipo_id = tipomov_1.movgest_tipo_id AND tipomov_1.movgest_tipo_code::text = 'I'::text
             LEFT JOIN siac_t_movgest_ts tsmov_1 ON mov.movgest_id = tsmov_1.movgest_id
             LEFT JOIN siac_r_movgest_ts_stato rsmov_1 ON tsmov_1.movgest_ts_id = rsmov_1.movgest_ts_id AND rsmov_1.data_cancellazione IS NULL AND rsmov_1.validita_fine IS NULL
             LEFT JOIN siac_d_movgest_stato statomov_1 ON rsmov_1.movgest_stato_id = statomov_1.movgest_stato_id AND statomov_1.movgest_stato_code::text = 'D'::text
             LEFT JOIN siac_r_subdoc_movgest_ts rsubmov ON tsmov_1.movgest_ts_id = rsubmov.movgest_ts_id AND rsubmov.data_cancellazione IS NULL AND rsubmov.validita_fine IS NULL
             LEFT JOIN siac_t_subdoc sub ON rsubmov.subdoc_id = sub.subdoc_id
          WHERE mov.bil_id = bilmov.bil_id AND mov.data_cancellazione IS NULL AND mov.validita_fine IS NULL
          GROUP BY mov.bil_id, mov.movgest_anno, mov.movgest_numero
        ), documenti_oltre AS (
         SELECT bilgen.bil_id,
            totale_quote_anno.movgest_anno,
            totale_quote_anno.movgest_numero,
            sum(totale_quote_anno.tot_quote) AS tot_quote
           FROM ( SELECT DISTINCT periodomov.anno,
                    mov.bil_id,
                    mov.movgest_anno,
                    mov.movgest_numero,
                    sum(sub.subdoc_importo) AS tot_quote
                   FROM siac_t_bil bilmov,
                    siac_t_periodo periodomov,
                    siac_t_movgest mov
                     LEFT JOIN siac_d_movgest_tipo tipomov_1 ON mov.movgest_tipo_id = tipomov_1.movgest_tipo_id AND tipomov_1.movgest_tipo_code::text = 'I'::text
                     LEFT JOIN siac_t_movgest_ts tsmov_1 ON mov.movgest_id = tsmov_1.movgest_id
                     LEFT JOIN siac_r_movgest_ts_stato rsmov_1 ON tsmov_1.movgest_ts_id = rsmov_1.movgest_ts_id AND rsmov_1.data_cancellazione IS NULL AND rsmov_1.validita_fine IS NULL
                     LEFT JOIN siac_d_movgest_stato statomov_1 ON rsmov_1.movgest_stato_id = statomov_1.movgest_stato_id AND statomov_1.movgest_stato_code::text = 'D'::text
                     LEFT JOIN siac_r_subdoc_movgest_ts rsubmov ON tsmov_1.movgest_ts_id = rsubmov.movgest_ts_id AND rsubmov.data_cancellazione IS NULL AND rsubmov.validita_fine IS NULL
                     LEFT JOIN siac_t_subdoc sub ON rsubmov.subdoc_id = sub.subdoc_id
                  WHERE mov.bil_id = bilmov.bil_id AND bilmov.periodo_id = periodomov.periodo_id AND mov.data_cancellazione IS NULL AND mov.validita_fine IS NULL
                  GROUP BY periodomov.anno, mov.bil_id, mov.movgest_anno, mov.movgest_numero) totale_quote_anno,
            siac_t_bil bilgen
          WHERE bilgen.ente_proprietario_id = 2 AND totale_quote_anno.bil_id > bilgen.bil_id
          GROUP BY bilgen.bil_id, totale_quote_anno.movgest_anno, totale_quote_anno.movgest_numero
        )
 SELECT DISTINCT sog.soggetto_code AS codice_anagrafico_fornitore,
    sog.soggetto_desc AS nome_partecipata,
    sog.codice_fiscale::character varying(16) AS codice_fiscale_partecipata,
    sog.partita_iva AS p_iva_partecipata,
    sac.codice_sac AS responsabile_procedura,
    imp.movgest_anno AS anno_impegno,
    imp.movgest_numero AS numero_impegno,
        CASE
            WHEN tsmov.movgest_ts_code::integer::numeric = imp.movgest_numero THEN 0
            ELSE tsmov.movgest_ts_code::integer
        END AS numero_sub_impegno,
    imp.movgest_desc AS descrizione_impegno,
    importiimpiniz.movgest_ts_det_importo AS importo_origine_impegno,
    importiimpatt.movgest_ts_det_importo AS importo_assestato_impegno_3112,
    COALESCE(liq_3112.tot_liq, NULL::numeric, 0::numeric) AS liquidato_3112,
    COALESCE(pagato_3112.tot_pag, NULL::numeric, 0::numeric) AS pagamenti_3112,
    COALESCE(importiimpatt.movgest_ts_det_importo, NULL::numeric, 0::numeric) - COALESCE(pagato_3112.tot_pag, NULL::numeric, 0::numeric) AS disponibilita_3112,
    COALESCE(rate_3112.tot_quote, NULL::numeric, 0::numeric) AS rate_3112,
    COALESCE(importiimpatt.movgest_ts_det_importo, NULL::numeric, 0::numeric) AS assestato_impegno_oggi,
    COALESCE(liq_oltre_3112.tot_liq, NULL::numeric, 0::numeric) AS liquidato_oltre_3112,
    COALESCE(pagato_oltre_3112.tot_pag, NULL::numeric, 0::numeric) AS pagamenti_oltre_3112,
    COALESCE(rate_oltre_3112.tot_quote, NULL::numeric, 0::numeric) AS rate_oltre_3112,
    to_char(periodo.anno::integer) AS esercizio,
    ' '::text AS mantenimento,
    statomov.movgest_stato_code
   FROM siac_r_movgest_ts_sog rsog,
    siac_t_movgest_ts_det importiimpiniz,
    siac_d_movgest_ts_det_tipo tipoimportiiniz,
    siac_t_movgest_ts_det importiimpatt,
    siac_d_movgest_ts_det_tipo tipoimportiatt,
    siac_t_soggetto sog,
    siac_t_soc_partecipate part,
    siac_d_movgest_tipo tipomov,
    siac_r_movgest_ts_stato rsmov,
    siac_d_movgest_stato statomov,
    siac_t_bil bil,
    siac_t_periodo periodo,
    siac_t_movgest imp
     LEFT JOIN liquidato_entro liq_3112 ON imp.movgest_anno = liq_3112.movgest_anno AND imp.movgest_numero = liq_3112.movgest_numero AND imp.bil_id = liq_3112.bil_id
     LEFT JOIN liquidato_oltre liq_oltre_3112 ON imp.movgest_anno = liq_oltre_3112.movgest_anno AND imp.movgest_numero = liq_oltre_3112.movgest_numero AND imp.bil_id = liq_oltre_3112.bil_id
     LEFT JOIN pagato_entro pagato_3112 ON imp.movgest_anno = pagato_3112.movgest_anno AND imp.movgest_numero = pagato_3112.movgest_numero AND imp.bil_id = pagato_3112.bil_id
     LEFT JOIN pagato_oltre pagato_oltre_3112 ON imp.movgest_anno = pagato_oltre_3112.movgest_anno AND imp.movgest_numero = pagato_oltre_3112.movgest_numero AND imp.bil_id = pagato_oltre_3112.bil_id
     LEFT JOIN documenti_entro rate_3112 ON imp.movgest_anno = rate_3112.movgest_anno AND imp.movgest_numero = rate_3112.movgest_numero AND imp.bil_id = rate_3112.bil_id
     LEFT JOIN documenti_oltre rate_oltre_3112 ON imp.movgest_anno = rate_oltre_3112.movgest_anno AND imp.movgest_numero = rate_oltre_3112.movgest_numero AND imp.bil_id = rate_oltre_3112.bil_id
     LEFT JOIN siac_t_movgest_ts tsmov ON imp.movgest_id = tsmov.movgest_id
     LEFT JOIN sac ON tsmov.movgest_ts_id = sac.movgest_ts_id
  WHERE tipomov.movgest_tipo_id = imp.movgest_tipo_id AND tipomov.movgest_tipo_code::text = 'I'::text AND rsmov.movgest_ts_id = tsmov.movgest_ts_id AND rsmov.movgest_stato_id = statomov.movgest_stato_id AND statomov.movgest_stato_code::text = 'D'::text AND bil.bil_id = imp.bil_id AND bil.periodo_id = periodo.periodo_id AND rsog.movgest_ts_id = tsmov.movgest_ts_id AND rsog.soggetto_id = sog.soggetto_id AND sog.soggetto_code::text = part.codice::text AND part.anno::integer = periodo.anno::integer AND importiimpiniz.movgest_ts_id = tsmov.movgest_ts_id AND importiimpiniz.movgest_ts_det_tipo_id = tipoimportiiniz.movgest_ts_det_tipo_id AND tipoimportiiniz.movgest_ts_det_tipo_code::text = 'I'::text AND importiimpatt.movgest_ts_id = tsmov.movgest_ts_id AND importiimpatt.movgest_ts_det_tipo_id = tipoimportiatt.movgest_ts_det_tipo_id AND tipoimportiatt.movgest_ts_det_tipo_code::text = 'A'::text AND imp.data_cancellazione IS NULL AND imp.validita_fine IS NULL AND rsog.data_cancellazione IS NULL AND rsog.validita_fine IS NULL AND rsmov.data_cancellazione IS NULL AND rsmov.validita_fine IS NULL AND imp.movgest_anno <= periodo.anno::integer
WITH DATA;
=======
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_residui_passivi
AS WITH sac AS (
        SELECT r.movgest_ts_id,
            cl.classif_code AS codice_sac
        FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
        WHERE r.ente_proprietario_id = 2
        AND r.classif_id = cl.classif_id
        AND cl.classif_tipo_id = tipo.classif_tipo_id
        AND tipo.classif_tipo_code IN ('CDC', 'CDR')
        AND r.data_cancellazione IS NULL
        AND r.validita_fine IS NULL
    ), liquidato AS (
        SELECT imp_1.movgest_anno,
            imp_1.movgest_numero,
            periodo.anno,
            liq.liq_anno AS anno_emis,
            sum(liq.liq_importo) AS tot_liq
        FROM siac_r_liquidazione_movgest rliqmov,
            siac_t_liquidazione liq,
            siac_r_liquidazione_stato rs,
            siac_d_liquidazione_stato stato,
            siac_t_bil bil,
            siac_t_periodo periodo,
            siac_v_bko_impegno_valido imp_1
        WHERE rliqmov.liq_id = liq.liq_id
        AND rliqmov.movgest_ts_id = imp_1.movgest_ts_id
        AND liq.bil_id = bil.bil_id
        AND bil.periodo_id = periodo.periodo_id
        AND periodo.anno::integer = liq.liq_anno
        AND rs.liq_id = liq.liq_id
        AND rs.liq_stato_id = stato.liq_stato_id
        AND stato.liq_stato_code <> 'A'
        AND rliqmov.data_cancellazione IS NULL
        AND rliqmov.validita_fine IS NULL
        AND rs.data_cancellazione IS NULL
        AND rs.validita_fine IS NULL
        GROUP BY imp_1.movgest_anno, imp_1.movgest_numero, periodo.anno, liq.liq_anno
    ), pagato AS (
        SELECT imp_1.movgest_anno,
            imp_1.movgest_numero,
            mand.ord_anno AS anno_emis,
            sum(importopag.ord_ts_det_importo) AS tot_pag
        FROM siac_r_liquidazione_movgest rliqmov,
            siac_t_liquidazione liq,
            siac_r_liquidazione_ord rliqord,
            siac_t_ordinativo mand,
            siac_d_ordinativo_tipo tipo,
            siac_t_ordinativo_ts ts,
            siac_t_ordinativo_ts_det importopag,
            siac_d_ordinativo_ts_det_tipo tipopag,
            siac_v_bko_impegno_valido imp_1
        WHERE rliqmov.liq_id = liq.liq_id
        AND rliqmov.movgest_ts_id = imp_1.movgest_ts_id
        AND rliqord.liq_id = liq.liq_id
        AND rliqord.sord_id = ts.ord_ts_id
        AND ts.ord_id = mand.ord_id
        AND mand.ord_tipo_id = tipo.ord_tipo_id
        AND tipo.ord_tipo_code = 'P'
        AND mand.ord_id = ts.ord_id
        AND importopag.ord_ts_id = ts.ord_ts_id
        AND tipopag.ord_ts_det_tipo_id = importopag.ord_ts_det_tipo_id
        AND tipopag.ord_ts_det_tipo_code = 'A'
        AND rliqmov.data_cancellazione IS NULL
        AND rliqmov.validita_fine IS NULL
        GROUP BY imp_1.movgest_anno, imp_1.movgest_numero, mand.ord_anno
    ), documenti AS (
        SELECT imp_1.anno_bilancio,
            imp_1.movgest_anno,
            imp_1.movgest_numero,
            sum(sub.subdoc_importo) AS tot_quote
        FROM siac_r_subdoc_movgest_ts r,
            siac_v_bko_impegno_valido imp_1,
            siac_t_subdoc sub,
            siac_t_doc doc
        WHERE imp_1.ente_proprietario_id = 2
        AND r.movgest_ts_id = imp_1.movgest_ts_id
        AND r.subdoc_id = sub.subdoc_id
        AND sub.doc_id = doc.doc_id
        AND sub.data_cancellazione IS NULL
        AND sub.validita_fine IS NULL
        AND r.data_cancellazione IS NULL
        AND r.validita_fine IS NULL
        GROUP BY imp_1.anno_bilancio, imp_1.movgest_anno, imp_1.movgest_numero
    )
    SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        sac.codice_sac AS responsabile_procedura,
        imp.movgest_anno AS anno_impegno,
        imp.movgest_numero AS numero_impegno,
        imp.movgest_subnumero AS numero_sub_impegno,
        imp.movgest_desc AS descrizione_impegno,
        importiimpiniz.movgest_ts_det_importo AS importo_origine_impegno,
        importiimpatt.movgest_ts_det_importo AS importo_assestato_impegno_3112,
        COALESCE(liq_3112.tot_liq, 0::numeric) AS liquidato_3112,
        COALESCE(pagato_3112.tot_pag, 0::numeric) AS pagamenti_3112,
        importiimpatt.movgest_ts_det_importo - COALESCE(pagato_3112.tot_pag, 0::numeric) AS disponibilita_3112,
        COALESCE(rate_3112.tot_quote, 0::numeric) AS rate_3112,
        importiimpatt.movgest_ts_det_importo AS assestato_impegno_oggi,
        COALESCE(liq_oltre_3112.tot_liq, 0::numeric) AS liquidato_oltre_3112,
        COALESCE(pagato_oltre_3112.tot_pag, 0::numeric) AS pagamenti_oltre_3112,
        COALESCE(rate_oltre_3112.tot_quote, 0::numeric) AS rate_oltre_3112,
        to_char(imp.anno_bilancio) AS esercizio,
        ' ' AS mantenimento
    FROM siac_r_movgest_ts_sog rsog,
        siac_t_movgest_ts_det importiimpiniz,
        siac_d_movgest_ts_det_tipo tipoimportiiniz,
        siac_t_movgest_ts_det importiimpatt,
        siac_d_movgest_ts_det_tipo tipoimportiatt,
        siac_t_soggetto sog,
        siac_t_soc_partecipate part,
        siac_v_bko_impegno_valido imp
    LEFT JOIN sac ON imp.movgest_ts_id = sac.movgest_ts_id
    LEFT JOIN liquidato liq_3112 ON imp.movgest_anno = liq_3112.movgest_anno AND imp.movgest_numero = liq_3112.movgest_numero AND imp.movgest_anno = liq_3112.anno_emis AND imp.anno_bilancio = liq_3112.anno::integer
    LEFT JOIN liquidato liq_oltre_3112 ON imp.movgest_anno = liq_oltre_3112.movgest_anno AND imp.movgest_numero = liq_oltre_3112.movgest_numero AND imp.movgest_anno < liq_oltre_3112.anno_emis
    LEFT JOIN pagato pagato_3112 ON imp.movgest_anno = pagato_3112.movgest_anno AND imp.movgest_numero = pagato_3112.movgest_numero AND imp.movgest_anno = pagato_3112.anno_emis
    LEFT JOIN pagato pagato_oltre_3112 ON imp.movgest_anno = pagato_oltre_3112.movgest_anno AND imp.movgest_numero = pagato_oltre_3112.movgest_numero AND imp.movgest_anno < pagato_oltre_3112.anno_emis
    LEFT JOIN documenti rate_3112 ON imp.movgest_anno = rate_3112.movgest_anno AND imp.movgest_numero = rate_3112.movgest_numero AND imp.anno_bilancio = rate_3112.anno_bilancio
    LEFT JOIN documenti rate_oltre_3112 ON imp.movgest_anno = rate_oltre_3112.movgest_anno AND imp.movgest_numero = rate_oltre_3112.movgest_numero AND imp.anno_bilancio < rate_oltre_3112.anno_bilancio
    WHERE rsog.movgest_ts_id = imp.movgest_ts_id
    AND rsog.soggetto_id = sog.soggetto_id
    AND sog.soggetto_code = part.codice
    AND part.anno::integer = imp.anno_bilancio
    AND importiimpiniz.movgest_ts_id = imp.movgest_ts_id
    AND importiimpiniz.movgest_ts_det_tipo_id = tipoimportiiniz.movgest_ts_det_tipo_id
    AND tipoimportiiniz.movgest_ts_det_tipo_code = 'I'
    AND importiimpatt.movgest_ts_id = imp.movgest_ts_id
    AND importiimpatt.movgest_ts_det_tipo_id = tipoimportiatt.movgest_ts_det_tipo_id
    AND tipoimportiatt.movgest_ts_det_tipo_code = 'A'
    AND rsog.data_cancellazione IS NULL
    AND rsog.validita_fine IS NULL
    AND imp.anno_bilancio = imp.movgest_anno
WITH DATA;
>>>>>>> b6cd016698b41511d3809c9b78b6885975325fa1
