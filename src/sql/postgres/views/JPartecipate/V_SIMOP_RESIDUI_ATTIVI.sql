<<<<<<< HEAD
-- siac.v_simop_residui_attivi source
drop MATERIALIZED VIEW siac.v_simop_residui_attivi;


CREATE MATERIALIZED VIEW siac.v_simop_residui_attivi
TABLESPACE pg_default
AS WITH sac AS (
         SELECT r.movgest_ts_id,
            cl.classif_code AS codice_sac
           FROM siac_r_movgest_class r,
            siac_t_class cl,
            siac_d_class_tipo tipo
          WHERE r.ente_proprietario_id = 2 AND r.classif_id = cl.classif_id AND cl.classif_tipo_id = tipo.classif_tipo_id AND (tipo.classif_tipo_code::text = ANY (ARRAY['CDC'::character varying::text, 'CDR'::character varying::text])) AND r.data_cancellazione IS NULL AND r.validita_fine IS NULL
        ), incassato_entro AS (
         SELECT DISTINCT mov.bil_id,
            mov.movgest_anno,
            mov.movgest_numero,
            sum(COALESCE(importoinc.ord_ts_det_importo, NULL::numeric, 0::numeric)) AS tot_inc
           FROM siac_t_bil bilmov,
            siac_t_periodo periodomov,
            siac_t_movgest mov
             LEFT JOIN siac_d_movgest_tipo tipomov ON mov.movgest_tipo_id = tipomov.movgest_tipo_id AND tipomov.movgest_tipo_code::text = 'A'::text
             LEFT JOIN siac_t_movgest_ts tsmov ON mov.movgest_id = tsmov.movgest_id
             LEFT JOIN siac_r_movgest_ts_stato rsmov ON tsmov.movgest_ts_id = rsmov.movgest_ts_id AND rsmov.data_cancellazione IS NULL AND rsmov.validita_fine IS NULL
             LEFT JOIN siac_d_movgest_stato statomov ON rsmov.movgest_stato_id = statomov.movgest_stato_id AND statomov.movgest_stato_code::text = 'D'::text
             LEFT JOIN siac_r_ordinativo_ts_movgest_ts raccrev ON tsmov.movgest_ts_id = raccrev.movgest_ts_id AND raccrev.data_cancellazione IS NULL AND raccrev.validita_fine IS NULL
             LEFT JOIN siac_t_ordinativo_ts tsord ON raccrev.ord_ts_id = tsord.ord_ts_id
             LEFT JOIN siac_t_ordinativo ord ON tsord.ord_id = ord.ord_id
             LEFT JOIN siac_r_ordinativo_stato rsord ON ord.ord_id = rsord.ord_id AND rsord.data_cancellazione IS NULL AND rsord.validita_fine IS NULL
             JOIN siac_d_ordinativo_stato statorev ON rsord.ord_stato_id = statorev.ord_stato_id AND statorev.ord_stato_code::text = 'Q'::text
             LEFT JOIN siac_t_ordinativo_ts_det importoinc ON tsord.ord_ts_id = importoinc.ord_ts_id
             JOIN siac_d_ordinativo_ts_det_tipo tipopag ON importoinc.ord_ts_det_tipo_id = tipopag.ord_ts_det_tipo_id AND tipopag.ord_ts_det_tipo_code::text = 'A'::text
          WHERE mov.bil_id = bilmov.bil_id AND bilmov.periodo_id = periodomov.periodo_id AND mov.data_cancellazione IS NULL AND mov.validita_fine IS NULL
          GROUP BY mov.bil_id, mov.movgest_anno, mov.movgest_numero
        ), incassato_oltre AS (
         SELECT bilgen.bil_id,
            totale_inc_anno.movgest_anno,
            totale_inc_anno.movgest_numero,
            sum(totale_inc_anno.incassato) AS tot_inc
           FROM ( SELECT DISTINCT mov.bil_id,
                    mov.movgest_anno,
                    mov.movgest_numero,
                    sum(COALESCE(importoinc.ord_ts_det_importo, NULL::numeric, 0::numeric)) AS incassato
                   FROM siac_t_bil bilmov,
                    siac_t_periodo periodomov,
                    siac_t_movgest mov
                     LEFT JOIN siac_d_movgest_tipo tipomov ON mov.movgest_tipo_id = tipomov.movgest_tipo_id AND tipomov.movgest_tipo_code::text = 'A'::text
                     LEFT JOIN siac_t_movgest_ts tsmov ON mov.movgest_id = tsmov.movgest_id
                     LEFT JOIN siac_r_movgest_ts_stato rsmov ON tsmov.movgest_ts_id = rsmov.movgest_ts_id AND rsmov.data_cancellazione IS NULL AND rsmov.validita_fine IS NULL
                     LEFT JOIN siac_d_movgest_stato statomov ON rsmov.movgest_stato_id = statomov.movgest_stato_id AND statomov.movgest_stato_code::text = 'D'::text
                     LEFT JOIN siac_r_ordinativo_ts_movgest_ts raccrev ON tsmov.movgest_ts_id = raccrev.movgest_ts_id AND raccrev.data_cancellazione IS NULL AND raccrev.validita_fine IS NULL
                     LEFT JOIN siac_t_ordinativo_ts tsord ON raccrev.ord_ts_id = tsord.ord_ts_id
                     LEFT JOIN siac_t_ordinativo ord ON tsord.ord_id = ord.ord_id
                     LEFT JOIN siac_r_ordinativo_stato rsord ON ord.ord_id = rsord.ord_id AND rsord.data_cancellazione IS NULL AND rsord.validita_fine IS NULL
                     JOIN siac_d_ordinativo_stato statorev ON rsord.ord_stato_id = statorev.ord_stato_id AND statorev.ord_stato_code::text = 'Q'::text
                     LEFT JOIN siac_t_ordinativo_ts_det importoinc ON tsord.ord_ts_id = importoinc.ord_ts_id
                     JOIN siac_d_ordinativo_ts_det_tipo tipopag ON importoinc.ord_ts_det_tipo_id = tipopag.ord_ts_det_tipo_id AND tipopag.ord_ts_det_tipo_code::text = 'A'::text
                  WHERE mov.bil_id = bilmov.bil_id AND bilmov.periodo_id = periodomov.periodo_id AND mov.data_cancellazione IS NULL AND mov.validita_fine IS NULL
                  GROUP BY mov.bil_id, mov.movgest_anno, mov.movgest_numero) totale_inc_anno,
            siac_t_bil bilgen
          WHERE bilgen.ente_proprietario_id = 2 AND totale_inc_anno.bil_id > bilgen.bil_id
          GROUP BY bilgen.bil_id, totale_inc_anno.movgest_anno, totale_inc_anno.movgest_numero
        )
 SELECT DISTINCT sog.soggetto_code AS codice_anagrafico_fornitore,
    sog.soggetto_desc AS nome_partecipata,
    sog.codice_fiscale::character varying(16) AS codice_fiscale_partecipata,
    sog.partita_iva AS p_iva_partecipata,
    sac.codice_sac AS responsabile_procedura,
    acc.movgest_anno AS anno_accertamento,
    acc.movgest_numero AS numero_accertamento,
    acc.movgest_subnumero AS numero_subaccertamento,
    acc.movgest_desc AS descrizione_accertamento,
    importiimpiniz.movgest_ts_det_importo AS importo_origine_accertamento,
    importiimpatt.movgest_ts_det_importo AS importo_assestato_accert_3112,
    COALESCE(reversali_3112.tot_inc, NULL::numeric, 0::numeric) AS reversali_3112,
    importiimpatt.movgest_ts_det_importo - COALESCE(reversali_3112.tot_inc, NULL::numeric, 0::numeric) AS disponibilita_3112,
    importiimpatt.movgest_ts_det_importo AS assestato_accertamento_oggi,
    COALESCE(reversali_oltre_3112.tot_inc, NULL::numeric, 0::numeric) AS reversali_oltre_3112,
    to_char(acc.anno_bilancio) AS esercizio,
    ' '::text AS mantenimento
   FROM siac_r_movgest_ts_sog rsog,
    siac_t_movgest_ts_det importiimpiniz,
    siac_d_movgest_ts_det_tipo tipoimportiiniz,
    siac_t_movgest_ts_det importiimpatt,
    siac_d_movgest_ts_det_tipo tipoimportiatt,
    siac_t_soggetto sog,
    siac_t_soc_partecipate part,
    siac_v_bko_accertamento_valido acc
     LEFT JOIN sac ON acc.movgest_ts_id = sac.movgest_ts_id
     LEFT JOIN incassato_entro reversali_3112 ON acc.movgest_anno = reversali_3112.movgest_anno AND acc.movgest_numero::numeric = reversali_3112.movgest_numero AND acc.bil_id = reversali_3112.bil_id
     LEFT JOIN incassato_oltre reversali_oltre_3112 ON acc.movgest_anno = reversali_oltre_3112.movgest_anno AND acc.movgest_numero::numeric = reversali_oltre_3112.movgest_numero AND acc.bil_id = reversali_oltre_3112.bil_id
  WHERE rsog.movgest_ts_id = acc.movgest_ts_id AND rsog.soggetto_id = sog.soggetto_id AND sog.soggetto_code::text = part.codice::text AND part.anno::integer = acc.anno_bilancio AND importiimpiniz.movgest_ts_id = acc.movgest_ts_id AND importiimpiniz.movgest_ts_det_tipo_id = tipoimportiiniz.movgest_ts_det_tipo_id AND tipoimportiiniz.movgest_ts_det_tipo_code::text = 'I'::text AND importiimpatt.movgest_ts_id = acc.movgest_ts_id AND importiimpatt.movgest_ts_det_tipo_id = tipoimportiatt.movgest_ts_det_tipo_id AND tipoimportiatt.movgest_ts_det_tipo_code::text = 'A'::text AND rsog.data_cancellazione IS NULL AND rsog.validita_fine IS NULL AND acc.movgest_anno <= acc.anno_bilancio
WITH DATA;
=======
/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE MATERIALIZED VIEW siac.v_simop_residui_attivi
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
    ), incassato AS (
        SELECT acc_1.movgest_anno,
            acc_1.movgest_numero,
            rev.ord_anno AS anno_emis,
            sum(importopag.ord_ts_det_importo) AS tot_pag
        FROM siac_r_ordinativo_ts_movgest_ts raccrev,
            siac_t_ordinativo rev,
            siac_r_ordinativo_stato rs,
            siac_d_ordinativo_stato stato,
            siac_d_ordinativo_tipo tipo,
            siac_t_ordinativo_ts ts,
            siac_t_ordinativo_ts_det importopag,
            siac_d_ordinativo_ts_det_tipo tipopag,
            siac_v_bko_accertamento_valido acc_1
        WHERE raccrev.movgest_ts_id = acc_1.movgest_ts_id
        AND raccrev.ord_ts_id = ts.ord_ts_id
        AND ts.ord_id = rev.ord_id
        AND rev.ord_tipo_id = tipo.ord_tipo_id
        AND rs.ord_id = rev.ord_id
        AND rs.ord_stato_id = stato.ord_stato_id
        AND stato.ord_stato_code <> 'A'
        AND tipo.ord_tipo_code = 'I'
        AND importopag.ord_ts_id = ts.ord_ts_id
        AND tipopag.ord_ts_det_tipo_id = importopag.ord_ts_det_tipo_id
        AND tipopag.ord_ts_det_tipo_code = 'A'
        AND raccrev.data_cancellazione IS NULL
        AND raccrev.validita_fine IS NULL
        AND rs.data_cancellazione IS NULL
        AND rs.validita_fine IS NULL
        GROUP BY acc_1.movgest_anno, acc_1.movgest_numero, rev.ord_anno
    )
    SELECT DISTINCT
        sog.soggetto_code AS codice_anagrafico_fornitore,
        sog.soggetto_desc AS nome_partecipata,
        sog.codice_fiscale AS codice_fiscale_partecipata,
        sog.partita_iva AS p_iva_partecipata,
        sac.codice_sac AS responsabile_procedura,
        acc.movgest_anno AS anno_accertamento,
        acc.movgest_numero AS numero_accertamento,
        acc.movgest_subnumero AS numero_subaccertamento,
        acc.movgest_desc AS descrizione_accertamento,
        importiimpiniz.movgest_ts_det_importo AS importo_origine_accertamento,
        importiimpatt.movgest_ts_det_importo AS importo_assestato_accert_3112,
        COALESCE(reversali_3112.tot_pag, 0::numeric) AS reversali_3112,
        importiimpatt.movgest_ts_det_importo - COALESCE(reversali_3112.tot_pag, 0::numeric) AS disponibilita_3112,
        importiimpatt.movgest_ts_det_importo AS assestato_accertamento_oggi,
        COALESCE(reversali_oltre_3112.tot_pag, 0::numeric) AS reversali_oltre_3112,
        to_char(acc.anno_bilancio) AS esercizio,
        ' ' AS mantenimento
    FROM siac_r_movgest_ts_sog rsog,
        siac_t_movgest_ts_det importiimpiniz,
        siac_d_movgest_ts_det_tipo tipoimportiiniz,
        siac_t_movgest_ts_det importiimpatt,
        siac_d_movgest_ts_det_tipo tipoimportiatt,
        siac_t_soggetto sog,
        siac_t_soc_partecipate part,
        siac_v_bko_accertamento_valido acc
    LEFT JOIN sac ON acc.movgest_ts_id = sac.movgest_ts_id
    LEFT JOIN incassato reversali_3112 ON acc.movgest_anno = reversali_3112.movgest_anno AND acc.movgest_numero = reversali_3112.movgest_numero AND acc.movgest_anno = reversali_3112.anno_emis
    LEFT JOIN incassato reversali_oltre_3112 ON acc.movgest_anno = reversali_oltre_3112.movgest_anno AND acc.movgest_numero = reversali_oltre_3112.movgest_numero AND acc.movgest_anno < reversali_oltre_3112.anno_emis
    WHERE rsog.movgest_ts_id = acc.movgest_ts_id
    AND rsog.soggetto_id = sog.soggetto_id
    AND sog.soggetto_code = part.codice
    AND part.anno::integer = acc.anno_bilancio
    AND importiimpiniz.movgest_ts_id = acc.movgest_ts_id
    AND importiimpiniz.movgest_ts_det_tipo_id = tipoimportiiniz.movgest_ts_det_tipo_id
    AND tipoimportiiniz.movgest_ts_det_tipo_code = 'I'
    AND importiimpatt.movgest_ts_id = acc.movgest_ts_id
    AND importiimpatt.movgest_ts_det_tipo_id = tipoimportiatt.movgest_ts_det_tipo_id
    AND tipoimportiatt.movgest_ts_det_tipo_code = 'A'
    AND rsog.data_cancellazione IS NULL
    AND rsog.validita_fine IS NULL
    AND acc.anno_bilancio = acc.movgest_anno
WITH DATA;
>>>>>>> b6cd016698b41511d3809c9b78b6885975325fa1
