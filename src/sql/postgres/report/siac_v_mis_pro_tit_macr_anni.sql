/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_mis_pro_tit_macr_anni as
   SELECT missione_tipo.classif_tipo_desc AS missione_tipo_desc,
         missione.classif_id AS missione_id,
         missione.classif_code AS missione_code,
         missione.classif_desc AS missione_desc,
         missione.validita_inizio AS missione_validita_inizio,
         missione.validita_fine AS missione_validita_fine,
         programma_tipo.classif_tipo_desc AS programma_tipo_desc,
         programma.classif_id AS programma_id,
         programma.classif_code AS programma_code,
         programma.classif_desc AS programma_desc,
         programma.validita_inizio AS programma_validita_inizio,
         programma.validita_fine AS programma_validita_fine,
         titusc_tipo.classif_tipo_desc AS titusc_tipo_desc,
         titusc.classif_id AS titusc_id,
         titusc.classif_code AS titusc_code,
         titusc.classif_desc AS titusc_desc,
         titusc.validita_inizio AS titusc_validita_inizio,
         titusc.validita_fine AS titusc_validita_fine,
         macroaggr_tipo.classif_tipo_desc AS macroag_tipo_desc,
         macroaggr.classif_id AS macroag_id,
         macroaggr.classif_code AS macroag_code,
         macroaggr.classif_desc AS macroag_desc,
         macroaggr.validita_inizio AS macroag_validita_inizio,
         macroaggr.validita_fine AS macroag_validita_fine,
         macroaggr.ente_proprietario_id
         FROM 
         siac_d_class_fam missione_fam,
       	 siac_t_class_fam_tree missione_tree,
         siac_r_class_fam_tree missione_r_cft,
         siac_t_class missione,
         siac_d_class_tipo missione_tipo,
         siac_d_class_tipo programma_tipo,
         siac_t_class programma,
  		 siac_d_class_fam titusc_fam,
         siac_t_class_fam_tree titusc_tree,
         siac_r_class_fam_tree titusc_r_cft,
         siac_t_class titusc,
         siac_d_class_tipo titusc_tipo,
         siac_d_class_tipo macroaggr_tipo,
         siac_t_class macroaggr
  WHERE 
  missione_fam.classif_fam_desc::text = 'Spesa - MissioniProgrammi'::text AND  
  missione_fam.classif_fam_id= missione_tree.classif_fam_id AND
  missione_tree.classif_fam_tree_id= missione_r_cft.classif_fam_tree_id AND
  missione_r_cft.classif_id_padre= missione.classif_id  AND
  missione.classif_tipo_id = missione_tipo.classif_tipo_id AND
  missione_tipo.classif_tipo_code::text = 'MISSIONE'::text AND
  programma_tipo.classif_tipo_code::text = 'PROGRAMMA'::text AND
  missione_r_cft.classif_id = programma.classif_id AND
  programma.classif_tipo_id = programma_tipo.classif_tipo_id AND
  titusc_fam.classif_fam_desc::text = 'Spesa - TitoliMacroaggregati'::text AND
  titusc_fam.classif_fam_id=titusc_tree.classif_fam_id AND
  titusc_tree.classif_fam_tree_id= titusc_r_cft.classif_fam_tree_id AND
  titusc_r_cft.classif_id_padre=titusc.classif_id  AND
  titusc_tipo.classif_tipo_code::text = 'TITOLO_SPESA'::text AND
  titusc.classif_tipo_id = titusc_tipo.classif_tipo_id AND
  macroaggr_tipo.classif_tipo_code::text = 'MACROAGGREGATO'::text AND
  titusc_r_cft.classif_id = macroaggr.classif_id AND
  macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id AND
  missione.ente_proprietario_id = programma.ente_proprietario_id AND
  programma.ente_proprietario_id = titusc.ente_proprietario_id AND
  titusc.ente_proprietario_id = macroaggr.ente_proprietario_id 
  ORDER BY missione.classif_code,
           programma.classif_code,
           titusc.classif_code,
           macroaggr.classif_code;