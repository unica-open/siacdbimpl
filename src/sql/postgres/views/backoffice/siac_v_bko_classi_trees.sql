/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace view siac_v_bko_classi_trees as    
  WITH RECURSIVE my_tree AS (
  select 
  seed.ente_proprietario_id,
  seed.classif_fam_code,seed.classif_fam_desc,
  seed.classif_id, seed.classif_id_padre, 
  seed.classif_code,
  seed.codice_assoluto::text
   from (
  select 
  a.ente_proprietario_id,
   d.classif_fam_code,d.classif_fam_desc,
  a.classif_id, b.classif_id_padre, 
  a.classif_code,
  a.classif_code  as codice_assoluto
   from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d
  where a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
--  and d.classif_fam_code = '00022'
  and now() between b.validita_inizio and coalesce (b.validita_fine,now())
  and b.classif_id_padre is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ) as seed
UNION
  select 
  a.ente_proprietario_id,
  d.classif_fam_code,d.classif_fam_desc,
  a.classif_id, 
  b.classif_id_padre, 
  a.classif_code,
  t.codice_assoluto::text|| '.'||a.classif_code::text as codice_assoluto
   from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,
   my_tree t
  where a.classif_id=b.classif_id
  and b.classif_fam_tree_id=c.classif_fam_tree_id
  and c.classif_fam_id=d.classif_fam_id
--  and d.classif_fam_code = '00022'
  and t.classif_id=b.classif_id_padre
  and now() between b.validita_inizio and coalesce (b.validita_fine,now())
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
)
SELECT ente_proprietario_id,
classif_fam_code,classif_fam_desc,
classif_id, classif_id_padre,classif_code, codice_assoluto from my_tree
--where ente_proprietario_id=5 
order by ente_proprietario_id, 
classif_fam_code,
codice_assoluto
;