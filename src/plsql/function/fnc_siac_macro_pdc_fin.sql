/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function fnc_siac_macro_pdc_fin
(
    pdc_fin_classif_id integer,
    p_ente_proprietario_id integer
);

create or replace function fnc_siac_macro_pdc_fin
(
    pdc_fin_classif_padre_id integer,
    pdc_fin_classif_figlio_id integer,
    p_ente_proprietario_id integer
)
returns TABLE
( classif_id_padre integer,
  classif_tipo_padre varchar,
  classif_code_padre varchar,
  classif_desc_padre varchar,
  classif_id_figlio integer,
  classif_tipo_figlio varchar,
  classif_code_figlio varchar,
  classif_desc_figlio varchar,
  ordine       varchar
)
as
$body$
DECLARE

BEGIN



return query
WITH
RECURSIVE pdc_fin(classid_id_padre) AS
(
 select cp.classif_id classif_id_padre,
        tipop.classif_tipo_code classif_tipo_padre,
        cp.classif_code classif_code_padre,
        cp.classif_desc classif_desc_padre,
        r.classif_id classif_id_figlio,
        tipo.classif_tipo_code classif_tipo_figlio,
        c.classif_code classif_code_figlio,
        c.classif_desc classif_desc_figlio,
        r.ordine ordine
from siac_d_class_fam fam, siac_t_class_fam_tree tr,
     siac_r_class_fam_tree r,
     siac_t_class c, siac_d_class_tipo tipo,
     siac_t_class cp, siac_d_class_tipo tipop
where fam.ente_proprietario_id=p_ente_proprietario_id
and   tr.classif_fam_id=fam.classif_fam_id
and   tr.class_fam_code='Piano dei Conti'
and   r.classif_fam_tree_id=tr.classif_fam_tree_id
and   c.classif_id=r.classif_id
and   substring(c.classif_code,1,1)='U'
and   tipo.classif_tipo_id=c.classif_tipo_id
and   cp.classif_id=r.classif_id_padre
and   substring(cp.classif_code,1,1)='U'
and   tipop.classif_tipo_id=cp.classif_tipo_id
and   tipop.classif_tipo_code like 'PDC_%'
and   tipop.classif_tipo_code !='PDC_I'
and   cp.classif_id=pdc_fin_classif_padre_id
and   tr.data_cancellazione is null
and   tr.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   c.data_cancellazione is null
and   cp.data_cancellazione is null
union
SELECT cp.classif_id classif_id_padre,
       tipop.classif_tipo_code classif_tipo_padre,
       cp.classif_code classif_code_padre,
       cp.classif_desc classif_desc_padre,
       r.classif_id classif_id_figlio,
       tipo.classif_tipo_code classif_tipo_figlio,
       c.classif_code classif_code_figlio,
       c.classif_desc classif_desc_figlio,
       r.ordine ordine
FROM pdc_fin padre,
     siac_d_class_fam fam, siac_t_class_fam_tree tr,
     siac_r_class_fam_tree r,
     siac_t_class c, siac_d_class_tipo tipo,
     siac_t_class cp, siac_d_class_tipo tipop
where fam.ente_proprietario_id=p_ente_proprietario_id
and   tr.classif_fam_id=fam.classif_fam_id
and   tr.class_fam_code='Piano dei Conti'
and   r.classif_fam_tree_id=tr.classif_fam_tree_id
and   c.classif_id=r.classif_id
and   substring(c.classif_code,1,1)='U'
and   tipo.classif_tipo_id=c.classif_tipo_id
and   cp.classif_id=r.classif_id_padre
and   cp.classif_id=padre.classif_id_figlio
and   substring(cp.classif_code,1,1)='U'
and   tipop.classif_tipo_id=cp.classif_tipo_id
and   tipop.classif_tipo_code like 'PDC_%'
and   tipop.classif_tipo_code !='PDC_I'
and   tr.data_cancellazione is null
and   tr.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   c.data_cancellazione is null
and   cp.data_cancellazione is null
)
select pdc_fin.*
from pdc_fin
where pdc_fin.classif_id_figlio=pdc_fin_classif_figlio_id
order by pdc_fin.ordine;


exception
 	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;