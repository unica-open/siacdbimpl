/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE VIEW siac.siac_v_bko_titolo_macroaggregato (
    titusc_tipo_desc,
    titusc_id,
    titusc_code,
    titusc_desc,
    macroag_tipo_desc,
    macroag_id,
    macroag_code,
    macroag_desc,
    ente_proprietario_id)
AS
SELECT titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc, macroaggr.ente_proprietario_id
FROM siac_t_class_fam_tree titusc_tree, siac_d_class_fam titusc_fam,
    siac_r_class_fam_tree titusc_r_cft, siac_t_class titusc,
    siac_d_class_tipo titusc_tipo, siac_d_class_tipo macroaggr_tipo,
    siac_t_class macroaggr
WHERE titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text
    AND titusc_tree.classif_fam_id = titusc_fam.classif_fam_id AND titusc_r_cft.classif_fam_tree_id = titusc_tree.classif_fam_tree_id AND titusc.classif_id = titusc_r_cft.classif_id_padre AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id AND titusc_r_cft.classif_id = macroaggr.classif_id AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id AND date_trunc('day'::text, now()) > macroaggr.validita_inizio AND (date_trunc('day'::text, now()) < macroaggr.validita_fine OR macroaggr.validita_fine IS NULL) AND date_trunc('day'::text, now()) > titusc.validita_inizio AND (date_trunc('day'::text, now()) < titusc.validita_fine OR titusc.validita_fine IS NULL) AND date_trunc('day'::text, now()) > titusc_r_cft.validita_inizio AND (date_trunc('day'::text, now()) < titusc_r_cft.validita_fine OR titusc_r_cft.validita_fine IS NULL) AND date_trunc('day'::text, now()) > macroaggr.validita_inizio AND (date_trunc('day'::text, now()) < macroaggr.validita_fine OR macroaggr.validita_fine IS NULL)
ORDER BY titusc.classif_code, macroaggr.classif_code;