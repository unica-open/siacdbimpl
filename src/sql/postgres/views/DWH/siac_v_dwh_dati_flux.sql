/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_dati_flux(
ente_proprietario_id,
attoamm_anno,
attoamm_numero,
attoamm_tipo_code,
attoamm_tipo_desc,
cod_sac,
desc_sac,
attoal_data_invio_firma,
attoal_login_invio_firma,
attoal_versione_invio_firma)
AS
WITH zz AS
(
select a.ente_proprietario_id,
h.attoamm_anno,
h.attoamm_numero,
daat.attoamm_tipo_code,
daat.attoamm_tipo_desc,
a.attoal_data_invio_firma,
a.attoal_login_invio_firma,
a.attoal_versione_invio_firma,
h.attoamm_id
--,attrimp.attr_code
from siac_t_atto_allegato a, siac_t_atto_amm h,siac_d_atto_amm_tipo daat 
where 
a.attoamm_id=h.attoamm_id and
h.attoamm_tipo_id=daat.attoamm_tipo_id 
and a.data_cancellazione is null
and h.data_cancellazione is null
and daat.data_cancellazione is null
)
,aa AS (
SELECT i.attoamm_id,
l.classif_id,
l.classif_code,
l.classif_desc,
m.classif_tipo_code
FROM siac_r_atto_amm_class i,
siac_t_class l,
siac_d_class_tipo m,
siac_r_class_fam_tree n,
siac_t_class_fam_tree o,
siac_d_class_fam p 
WHERE i.classif_id = l.classif_id 
AND m.classif_tipo_id = l.classif_tipo_id 
AND n.classif_id =l.classif_id 
AND n.classif_fam_tree_id = o.classif_fam_tree_id
AND o.classif_fam_id = p.classif_fam_id 
AND p.classif_fam_code::text ='00005'::text 
AND i.data_cancellazione IS NULL 
AND l.data_cancellazione IS NULL 
AND m.data_cancellazione IS NULL
AND n.data_cancellazione IS NULL 
AND o.data_cancellazione IS NULL 
AND p.data_cancellazione IS NULL)
SELECT
zz.ente_proprietario_id,
zz.attoamm_anno,
zz.attoamm_numero,
zz.attoamm_tipo_code,
zz.attoamm_tipo_desc,
aa.classif_code AS cod_sac,
aa.classif_desc AS desc_sac,
zz.attoal_data_invio_firma,
zz.attoal_login_invio_firma,
zz.attoal_versione_invio_firma
FROM zz
LEFT JOIN aa ON zz.attoamm_id =
aa.attoamm_id;