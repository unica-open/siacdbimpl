/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_tit_tip_cat_riga_anni(
    classif_tipo_desc1,
    titolo_id,
    titolo_code,
    titolo_desc,
    titolo_validita_inizio,
    titolo_validita_fine,
    classif_tipo_desc2,
    tipologia_id,
    tipologia_code,
    tipologia_desc,
    tipologia_validita_inizio,
    tipologia_validita_fine,
    classif_tipo_desc3,
    categoria_id,
    categoria_code,
    categoria_desc,
    categoria_validita_inizio,
    categoria_validita_fine,
    ente_proprietario_id)
AS
  SELECT v3.classif_tipo_desc AS classif_tipo_desc1,
         v3.classif_id AS titolo_id,
         v3.classif_code AS titolo_code,
         v3.classif_desc AS titolo_desc,
         v3.validita_inizio AS titolo_validita_inizio,
         v3.validita_fine AS titolo_validita_fine,
         v2.classif_tipo_desc AS classif_tipo_desc2,
         v2.classif_id AS tipologia_id,
         v2.classif_code AS tipologia_code,
         v2.classif_desc AS tipologia_desc,
         v2.validita_inizio AS tipologia_validita_inizio,
         v2.validita_fine AS tipologia_validita_fine,
         v1.classif_tipo_desc AS classif_tipo_desc3,
         v1.classif_id AS categoria_id,
         v1.classif_code AS categoria_code,
         v1.classif_desc AS categoria_desc,
         v1.validita_inizio AS categoria_validita_inizio,
         v1.validita_fine AS categoria_validita_fine,
         v1.ente_proprietario_id
  FROM siac_v_tit_tip_cat_anni v1,
       siac_v_tit_tip_cat_anni v2,
       siac_v_tit_tip_cat_anni v3
  WHERE v1.classif_id_padre = v2.classif_id AND
        v1.classif_tipo_desc::text = 'Categoria'::text AND
        v2.classif_tipo_desc::text = 'Tipologia'::text AND
        v2.classif_id_padre = v3.classif_id AND
        v3.classif_tipo_desc::text = 'Titolo Entrata'::text AND
        v1.ente_proprietario_id = v2.ente_proprietario_id AND
        v2.ente_proprietario_id = v3.ente_proprietario_id;