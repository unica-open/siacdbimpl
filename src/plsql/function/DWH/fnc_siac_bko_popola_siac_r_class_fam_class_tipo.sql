/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_popola_siac_r_class_fam_class_tipo (
  ente_proprietario integer
)
RETURNS void AS
$body$
DECLARE

begin

INSERT INTO
    siac.siac_r_class_fam_class_tipo
(
  classif_fam_id,
  classif_tipo_id,
  validita_inizio,
  validita_fine,
  ente_proprietario_id,
  login_operazione
)
select distinct b.classif_fam_id,e.classif_tipo_id,
e.validita_inizio,e.validita_fine,
e.ente_proprietario_id,'admin'
 from siac_t_class_fam_tree a, siac_d_class_fam b, siac_r_class_fam_tree c, siac_t_class d, siac_d_class_tipo e
where
a.classif_fam_id=b.classif_fam_id
and c.classif_fam_tree_id=a.classif_fam_tree_id
and d.classif_id=c.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and e.ente_proprietario_id=ente_proprietario
and not exists
(select 1 from siac_r_class_fam_class_tipo z where z.classif_fam_id=b.classif_fam_id
and z.classif_tipo_id=e.classif_tipo_id
and z.validita_inizio=e.validita_inizio
);

exception
    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;
        when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',' altro errore',SQLSTATE,SQLERRM;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;