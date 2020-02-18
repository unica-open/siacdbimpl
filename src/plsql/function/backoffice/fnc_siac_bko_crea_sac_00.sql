/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_crea_sac_00 (
  data_ini timestamp
)
RETURNS void AS
$body$
DECLARE

/*cre la sac con cdr e cdc fittizi*/

/*max_anno integer;
delta_anni integer;
anno_aggiornamento integer;
risultato varchar;
anno_aggiornamento_v varchar;*/

begin

INSERT INTO
  siac.siac_t_class_fam_tree
(
  class_fam_code,
  class_fam_desc,
  classif_fam_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select 'Struttura Amministrativa Contabile','Struttura Amministrativa Contabile',
a.classif_fam_id,data_ini, a.ente_proprietario_id,
'admin'||to_char(now(),'yyyymmdd')
 from siac_d_class_fam a where a.classif_fam_code='00005'
and not EXISTS
(select 1 from siac_t_class_fam_tree b where b.ente_proprietario_id=a.ente_proprietario_id
and b.classif_fam_id=a.classif_fam_id);

INSERT INTO
  siac.siac_t_class
(
  classif_code,
  classif_desc,
  classif_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '000','cdr 000',
t.classif_tipo_id,data_ini, a.ente_proprietario_id,
'admin'||to_char(now(),'yyyymmdd')
 from siac_d_class_fam a,siac_d_class_tipo t
 where
 t.ente_proprietario_id=a.ente_proprietario_id
 and t.classif_tipo_code='CDR' and
 a.classif_fam_code='00005'
 and not exists
 (select 1 from siac_t_class cc where cc.classif_code='000' and cc.classif_tipo_id=t.classif_tipo_id and cc.ente_proprietario_id=
 a.ente_proprietario_id
 );



INSERT INTO
  siac.siac_t_class
(
  classif_code,
  classif_desc,
  classif_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select '00','cdc 00',
t.classif_tipo_id,data_ini, a.ente_proprietario_id,
'admin'||to_char(now(),'yyyymmdd')
 from siac_d_class_fam a,siac_d_class_tipo t
 where
 t.ente_proprietario_id=a.ente_proprietario_id
 and t.classif_tipo_code='CDC' and
 a.classif_fam_code='00005'
 and not exists
 (select 1 from siac_t_class cc where cc.classif_code='00' and cc.classif_tipo_id=t.classif_tipo_id and cc.ente_proprietario_id=
 a.ente_proprietario_id
 );

INSERT INTO
  siac.siac_r_class_fam_tree
(
  classif_fam_tree_id,
  classif_id,
  classif_id_padre,
  ordine,
  livello,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select b.classif_fam_tree_id,
c.classif_id,NULL,c.classif_code,1, data_ini,
b.ente_proprietario_id,'admin'||to_char(now(),'yyyymmdd')
from siac_t_class_fam_tree b, siac_d_class_fam a, siac_t_class c, siac_d_class_tipo d
where a.classif_fam_id=b.classif_fam_id
and a.classif_fam_code='00005'
and a.ente_proprietario_id=c.ente_proprietario_id
and d.classif_tipo_id=c.classif_tipo_id
and c.classif_code='000'
and d.classif_tipo_code='CDR'
and now() between b.validita_inizio and coalesce (b.validita_fine,now())
and not exists (select 1 from siac_r_class_fam_tree rr where rr.classif_id=c.classif_id and b.classif_fam_tree_id=rr.classif_classif_fam_tree_id);


INSERT INTO
  siac.siac_r_class_fam_tree
(
  classif_fam_tree_id,
  classif_id,
  classif_id_padre,
  ordine,
  livello,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select b.classif_fam_tree_id,
c2.classif_id,c.classif_id,c.classif_code||'.'||c2.classif_code,2, data_ini,
b.ente_proprietario_id,'admin'||to_char(now(),'yyyymmdd')
from siac_t_class_fam_tree b, siac_d_class_fam a, siac_t_class c, siac_d_class_tipo d,
 siac_t_class c2, siac_d_class_tipo d2
where a.classif_fam_id=b.classif_fam_id
and a.classif_fam_code='00005'
and a.ente_proprietario_id=c.ente_proprietario_id
and d.classif_tipo_id=c.classif_tipo_id
and c.classif_code='000'
and d.classif_tipo_code='CDR'
and c2.ente_proprietario_id=c.ente_proprietario_id
and d2.classif_tipo_id=c2.classif_tipo_id
and d2.classif_tipo_code='CDC'
and c2.classif_code='00'
and now() between b.validita_inizio and coalesce (b.validita_fine,now())
and not exists (select 1 from siac_r_class_fam_tree rr where rr.classif_id=c2.classif_id
and b.classif_fam_tree_id=rr.classif_classif_fam_tree_id)
;

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
SECURITY INVOKER
COST 100
;