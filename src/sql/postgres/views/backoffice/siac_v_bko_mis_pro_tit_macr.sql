/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_mis_pro_tit_macr (
    missione_tipo_desc,
    missione_id,
    missione_code,
    missione_desc,
    programma_tipo_desc,
    programma_id,
    programma_code,
    programma_desc,
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
SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
    missione.classif_id AS missione_id, missione.classif_code AS missione_code,
    missione.classif_desc AS missione_desc,
    programma_tipo.classif_tipo_desc AS programma_tipo_desc,
    programma.classif_id AS programma_id,
    programma.classif_code AS programma_code,
    programma.classif_desc AS programma_desc,
    titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
    titusc.classif_id AS titusc_id, titusc.classif_code AS titusc_code,
    titusc.classif_desc AS titusc_desc,
    macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
    macroaggr.classif_id AS macroag_id, macroaggr.classif_code AS macroag_code,
    macroaggr.classif_desc AS macroag_desc, macroaggr.ente_proprietario_id
FROM siac_t_class_fam_tree missione_tree, siac_d_class_fam missione_fam,
    siac_r_class_fam_tree missione_r_cft, siac_t_class missione,
    siac_d_class_tipo missione_tipo, siac_d_class_tipo programma_tipo,
    siac_t_class programma, siac_t_class_fam_tree titusc_tree,
    siac_d_class_fam titusc_fam, siac_r_class_fam_tree titusc_r_cft,
    siac_t_class titusc, siac_d_class_tipo titusc_tipo,
    siac_d_class_tipo macroaggr_tipo, siac_t_class macroaggr
WHERE missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text
    AND missione_tree.classif_fam_id = missione_fam.classif_fam_id AND missione_r_cft.classif_fam_tree_id = missione_tree.classif_fam_tree_id AND missione.classif_id = missione_r_cft.classif_id_padre AND missione_tipo.classif_tipo_code::text = 'MISSIONE'::text AND missione.classif_tipo_id = missione_tipo.classif_tipo_id AND programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text AND programma.classif_tipo_id = programma_tipo.classif_tipo_id AND missione_r_cft.classif_id = programma.classif_id AND titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text AND titusc_tree.classif_fam_id = titusc_fam.classif_fam_id AND titusc_r_cft.classif_fam_tree_id = titusc_tree.classif_fam_tree_id AND titusc.classif_id = titusc_r_cft.classif_id_padre AND titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text AND titusc.classif_tipo_id = titusc_tipo.classif_tipo_id AND macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text AND macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id AND titusc_r_cft.classif_id = macroaggr.classif_id AND missione.ente_proprietario_id = programma.ente_proprietario_id AND programma.ente_proprietario_id = titusc.ente_proprietario_id AND titusc.ente_proprietario_id = macroaggr.ente_proprietario_id AND date_trunc('day'::text, now()) > macroaggr.validita_inizio AND (date_trunc('day'::text, now()) < macroaggr.validita_fine OR macroaggr.validita_fine IS NULL) AND date_trunc('day'::text, now()) > programma.validita_inizio AND (date_trunc('day'::text, now()) < programma.validita_fine OR programma.validita_fine IS NULL) AND date_trunc('day'::text, now()) > missione.validita_inizio AND (date_trunc('day'::text, now()) < missione.validita_fine OR missione.validita_fine IS NULL) AND date_trunc('day'::text, now()) > missione_r_cft.validita_inizio AND (date_trunc('day'::text, now()) < missione_r_cft.validita_fine OR missione_r_cft.validita_fine IS NULL) AND date_trunc('day'::text, now()) > titusc.validita_inizio AND (date_trunc('day'::text, now()) < titusc.validita_fine OR titusc.validita_fine IS NULL) AND date_trunc('day'::text, now()) > titusc_r_cft.validita_inizio AND (date_trunc('day'::text, now()) < titusc_r_cft.validita_fine OR titusc_r_cft.validita_fine IS NULL) AND date_trunc('day'::text, now()) > macroaggr.validita_inizio AND (date_trunc('day'::text, now()) < macroaggr.validita_fine OR macroaggr.validita_fine IS NULL)
ORDER BY missione.classif_code, programma.classif_code, titusc.classif_code,
    macroaggr.classif_code;