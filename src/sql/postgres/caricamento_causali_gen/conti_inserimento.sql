/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac_t_pdce_conto
/*pdce_conto_code VARCHAR(200) NOT NULL,
  pdce_conto_desc VARCHAR(500) NOT NULL,
  pdce_conto_id_padre INTEGER,
  pdce_conto_a_partita BOOLEAN DEFAULT false NOT NULL,
  livello INTEGER NOT NULL,
  ordine VARCHAR,
  pdce_fam_tree_id INTEGER NOT NULL,
  pdce_ct_tipo_id INTEGER NOT NULL,
  cescat_id INTEGER,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  login_creazione VARCHAR(200) NOT NULL,
  login_modifica VARCHAR(200),
  login_cancellazione VARCHAR(200),
  ambito_id INTEGER NOT NULL,*/

-- siac_r_pdce_conto_attr ( tutti boolean, tranne pdce_conto_codifica_interna )
 -- pdce_conto_foglia S/N
 -- pdce_conto_di_legge S
 -- pdce_conto_codifica_interna ??
 -- pdce_ammortamento  N
 -- pdce_conto_attivo  S
 -- pdce_conto_segno_negativo ???


-- siac_r_pdce_conto_class
 -- CE_CODBIL
 -- CO_CODBIL
 -- SPA_CODBIL
 -- SPP_CODBIL


select tree.pdce_fam_code, fam.pdce_fam_code, fam.pdce_fam_segno, pdce.*
from siac_t_pdce_conto pdce,siac_r_pdce_conto_attr r,siac_t_attr attr, siac_t_pdce_fam_tree tree,
     siac_d_pdce_fam fam
where attr.ente_proprietario_id=2
and   r.attr_id=attr.attr_id
and   attr.attr_code='pdce_conto_segno_negativo'
and   pdce.pdce_conto_id=r.pdce_conto_id
and   r.boolean='S'
and   tree.pdce_fam_tree_id=pdce.pdce_fam_tree_id
and   fam.pdce_fam_id=tree.pdce_fam_id
and   r.data_cancellazione is null
and   r.validita_fine is null



 -- siac_r_pdce_conto ??
select distinct attr.attr_code, r.boolean, r.testo,r.numerico
from siac_t_pdce_conto pdce,siac_r_pdce_conto_attr r,siac_t_attr attr
where attr.ente_proprietario_id=2
and   r.attr_id=attr.attr_id
and   pdce.pdce_conto_id=r.pdce_conto_id
and   pdce.pdce_conto_code='3.1.1.02.01.01.001'
and   r.data_cancellazione is null
and   r.validita_fine is null


select distinct tipo.classif_tipo_code,attr.classif_code,attr.classif_desc,
       cpadre.classif_code, cpadre.classif_desc,pdce.pdce_conto_code
from siac_t_pdce_conto pdce,siac_r_pdce_conto_class r,siac_t_Class attr , siac_d_class_tipo tipo,
siac_r_class_fam_tree rr,siac_t_class cpadre
where attr.ente_proprietario_id=2
and   r.classif_id=attr.classif_id
and   pdce.pdce_conto_id=r.pdce_conto_id
and   tipo.classif_tipo_id=attr.classif_tipo_id
and   pdce.pdce_conto_code ='2.4.3.01.02.09.001'
and   rr.classif_id=attr.classif_id
and   cpadre.classif_id=rr.classif_id_padre
and   r.data_cancellazione is null
and   r.validita_fine is null

select distinct tipo.classif_tipo_code
from siac_r_causale_ep_class r,siac_t_class c,siac_d_class_tipo tipo
where tipo.ente_proprietario_id=2
and   c.classif_tipo_id=tipo.classif_tipo_id
and   r.classif_id=c.classif_id
and   r.data_cancellazione is null
and   r.validita_fine is null

--- P	D	 	4	 	b
--  D.4.b
select *
from siac_v_bko_codifiche_econpatr_pdce bko
where  bko.ente_proprietario_id=2
and    bko.pdce_conto_code='2.4.3.01.02.09.001'



select *
from siac_v_dwh_codifiche_econpatr dwh
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero='D.4.b'
--- A	B	IV	1	 	c
select *
from siac_v_dwh_codifiche_econpatr dwh
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero='B.13'
-- E	25	c
select *
from siac_v_dwh_codifiche_econpatr dwh
where dwh.ente_proprietario_id=2
--and   dwh.codice_codifica_albero='E.25.c'
--and   dwh.codice_codifica_albero='A.8'
and   dwh.codice_codifica_albero like 'B.13%'--a%'

select tipo.classif_tipo_code, c.*
from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero='B.IV.1.c'
and   c.classif_id=dwh.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
-- E	25	c
-- A	8

-- stato patrimoniale attivo (codice di bilancio)
select *
from siac_d_class_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.classif_tipo_desc='stato patrimoniale passivo (codice di bilancio)'

select *
from siac_d_pdce_conto_tipo tipo
where tipo.ente_proprietario_id=2

select tree.*
from siac_t_pdce_conto bko,siac_t_pdce_fam_tree tree
where  bko.ente_proprietario_id=2
and    bko.pdce_conto_code='3.1.2.01.01.01.001'
and    tree.pdce_fam_tree_id=bko.pdce_fam_tree_id

select attr.attr_code, rattr.*
from siac_t_pdce_conto bko,siac_t_pdce_fam_tree tree,siac_r_pdce_conto_attr rattr,siac_t_attr attr
where  bko.ente_proprietario_id=2
and    bko.pdce_conto_code='2.3.1.01.05.999'
and    tree.pdce_fam_tree_id=bko.pdce_fam_tree_id
and   rattr.pdce_conto_id=bko.pdce_conto_id
and   attr.attr_id=rattr.attr_id
and   rattr.validita_fine is null
and   rattr.data_cancellazione is null



select bko.pdce_conto_code,bko.pdce_conto_desc, attr.attr_code, rattr.*
from siac_t_pdce_conto bko,siac_t_pdce_fam_tree tree,siac_r_pdce_conto_attr rattr,siac_t_attr attr
where  bko.ente_proprietario_id=2
and    tree.pdce_fam_tree_id=bko.pdce_fam_tree_id
and    rattr.pdce_conto_id=bko.pdce_conto_id
and    attr.attr_id=rattr.attr_id
--and    attr.attr_code in ('pdce_conto_codifica_interna','pdce_conto_segno_negativo')
and    attr.attr_code in ('pdce_conto_segno_negativo')
and    rattr.validita_fine is null
and    rattr.data_cancellazione is null


drop table if exists siac_bko_t_caricamento_pdce_conto
CREATE TABLE siac_bko_t_caricamento_pdce_conto
(
  carica_pdce_conto_id SERIAL,
  pdce_conto_code      VARCHAR not null,
  pdce_conto_desc      VARCHAR not null,
  tipo_operazione      varchar not null,
  classe_conto         varchar not null,
  livello              integer not null,
  codifica_bil         varchar not null,
  tipo_conto           varchar not null,
  conto_foglia         varchar,
  conto_di_legge       varchar,
  conto_codifica_interna varchar,
  ammortamento        varchar,
  conto_attivo        varchar not null default 'S',
  conto_segno_negativo varchar,
  caricato BOOLEAN DEFAULT false NOT NULL,
  ambito VARCHAR DEFAULT 'AMBITO_FIN'::character varying NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) DEFAULT 'admin-carica-pdce' NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  validita_fine   TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id integer not null,
  CONSTRAINT pk_siac_bko_t_caricamento_pdce_conto PRIMARY KEY(carica_pdce_conto_id),
  CONSTRAINT siac_t_ente_proprietario_siac_bko_t_caricamento_pdce_conto FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

CREATE UNIQUE INDEX siac_bko_t_caricamento_pdce_conto_idx ON siac_bko_t_caricamento_pdce_conto
  USING btree (pdce_conto_code COLLATE pg_catalog."default",
               pdce_conto_desc COLLATE pg_catalog."default",
               ambito COLLATE pg_catalog."default"
               )
  WHERE (data_cancellazione IS NULL);


CREATE INDEX siac_bko_t_caricamento_pdce_conto_fk_ente_proprietario_id_idx ON siac_bko_t_caricamento_pdce_conto
  USING btree (ente_proprietario_id);

select *
from siac_bko_t_caricamento_pdce_conto
where tipo_operazione='A'
-- 71
select distinct pdce_conto_code
from siac_bko_t_caricamento_pdce_conto

select bko.*
from siac_bko_t_caricamento_pdce_conto  bko,siac_t_pdce_conto conto
where conto.ente_proprietario_id=2
and   conto.pdce_conto_code=bko.pdce_conto_code
and   bko.tipo_operazione='A'

select bko.*
from siac_v_dwh_codifiche_econpatr dwh,siac_bko_t_caricamento_pdce_conto bko
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero=bko.codifica_bil
and   coalesce(bko.codifica_bil,'')!=''
-- 25

select bko.codifica_bil , bko.pdce_conto_code, bko.pdce_conto_desc
from siac_bko_t_caricamento_pdce_conto bko
where coalesce(bko.codifica_bil,'')!=''
and   not exists
(
select 1 from siac_v_dwh_codifiche_econpatr dwh
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero=bko.codifica_bil
);
-- 40

select fam.pdce_fam_code, t.*
from siac_t_pdce_fam_tree t,siac_d_pdce_fam fam,siac_d_ambito ambito
where t.ente_proprietario_id=2
and   fam.pdce_fam_id=t.pdce_fam_id
and   ambito.ambito_id=fam.ambito_id
and   ambito.ambito_code='AMBITO_FIN'

select position('.' in reverse('1.2.3.01.12')),length ('1.2.3.01.12'),reverse('1.2.3.01.12'),'1.2.3.01.12',length('1.2.3.01.12')- position('.' in reverse('1.2.3.01.12')),
       SUBSTRING('1.2.3.01.12' from 1 for length('1.2.3.01.12')- position('.' in reverse('1.2.3.01.12')))

select *
from siac_bko_t_caricamento_pdce_conto
where tipo_operazione='I'
and   livello=5

-- 1.2.3.01.12
select *
from siac_t_pdce_conto conto
where conto.ente_proprietario_id=2
and   conto.pdce_conto_code='1.2.3.01'

insert into siac_t_pdce_conto
(
  pdce_conto_code,
  pdce_conto_desc,
  pdce_conto_id_padre,
  livello,
  ordine,
  pdce_fam_tree_id,
  pdce_ct_tipo_id,
  ambito_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
  bko.pdce_conto_code,
  bko.pdce_conto_desc,
  contoPadre.pdce_conto_id,
  bko.livello,
  bko.pdce_conto_code,
  tree.pdce_fam_tree_id,
  tipo.pdce_ct_tipo_id,
  ambito.ambito_id,
  now(),
  tipo.ente_proprietario_id,
  bko.login_operazione||'@'||bko.carica_pdce_conto_id::varchar
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko,
     siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
     siac_d_ambito ambito,
     siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_conto contoPadre
where ente.ente_proprietario_id=2
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ente_proprietario_id=ambito.ente_proprietario_id
and   bko.ambito=ambito.ambito_code
and   fam.ambito_id=ambito.ambito_id
and   fam.pdce_fam_code=bko.classe_conto
and   tree.pdce_fam_id=fam.pdce_fam_id
and   tipo.pdce_ct_tipo_code=bko.tipo_conto
and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
and   bko.tipo_operazione='I'
and   bko.livello=5
and   contoPadre.ente_proprietario_id=tipo.ente_proprietario_id
and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
and   contoPadre.livello=bko.livello-1
and   contoPadre.ambito_id=ambito.ambito_id
and   contoPadre.pdce_conto_code =
      SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;


insert into siac_t_pdce_conto
(
  pdce_conto_code,
  pdce_conto_desc,
  pdce_conto_id_padre,
  livello,
  ordine,
  pdce_fam_tree_id,
  pdce_ct_tipo_id,
  ambito_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
  bko.pdce_conto_code,
  bko.pdce_conto_desc,
  contoPadre.pdce_conto_id,
  bko.livello,
  bko.pdce_conto_code,
  tree.pdce_fam_tree_id,
  tipo.pdce_ct_tipo_id,
  ambito.ambito_id,
  now(),
  tipo.ente_proprietario_id,
  bko.login_operazione||'@'||bko.carica_pdce_conto_id::varchar
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko,
     siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
     siac_d_ambito ambito,
     siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_conto contoPadre
where ente.ente_proprietario_id=2
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ente_proprietario_id=ambito.ente_proprietario_id
and   bko.ambito=ambito.ambito_code
and   fam.ambito_id=ambito.ambito_id
and   fam.pdce_fam_code=bko.classe_conto
and   tree.pdce_fam_id=fam.pdce_fam_id
and   tipo.pdce_ct_tipo_code=bko.tipo_conto
and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
and   bko.tipo_operazione='I'
and   bko.livello=6
and   contoPadre.ente_proprietario_id=tipo.ente_proprietario_id
and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
and   contoPadre.livello=bko.livello-1
and   contoPadre.ambito_id=ambito.ambito_id
and   contoPadre.pdce_conto_code =
      SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;




insert into siac_t_pdce_conto
(
  pdce_conto_code,
  pdce_conto_desc,
  pdce_conto_id_padre,
  livello,
  ordine,
  pdce_fam_tree_id,
  pdce_ct_tipo_id,
  ambito_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select
  bko.pdce_conto_code,
  bko.pdce_conto_desc,
  contoPadre.pdce_conto_id,
  bko.livello,
  bko.pdce_conto_code,
  tree.pdce_fam_tree_id,
  tipo.pdce_ct_tipo_id,
  ambito.ambito_id,
  now(),
  tipo.ente_proprietario_id,
  bko.login_operazione||'@'||bko.carica_pdce_conto_id::varchar
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko,
     siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
     siac_d_ambito ambito,
     siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_conto contoPadre
where ente.ente_proprietario_id=2
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ente_proprietario_id=ambito.ente_proprietario_id
and   bko.ambito=ambito.ambito_code
and   fam.ambito_id=ambito.ambito_id
and   fam.pdce_fam_code=bko.classe_conto
and   tree.pdce_fam_id=fam.pdce_fam_id
and   tipo.pdce_ct_tipo_code=bko.tipo_conto
and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
and   bko.tipo_operazione='I'
and   bko.livello=7
and   contoPadre.ente_proprietario_id=tipo.ente_proprietario_id
and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
and   contoPadre.livello=bko.livello-1
and   contoPadre.ambito_id=ambito.ambito_id
and   contoPadre.pdce_conto_code =
      SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;


-- siac_r_pdce_conto_attr ( tutti boolean, tranne pdce_conto_codifica_interna )
-- pdce_conto_codifica_interna ??

-- siac_r_pdce_conto_attr
-- pdce_conto_foglia
insert into siac_r_pdce_conto_attr
(
	pdce_conto_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select conto.pdce_conto_id,
       attr.attr_id,
       'S',
       now(),
       bko.login_operazione,
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
     siac_d_ambito ambito
where ente.ente_proprietario_id=2
and   attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='pdce_conto_foglia'
and   bko.ente_proprietario_id=attr.ente_proprietario_id
and   bko.tipo_operazione='I'
and   ambito.ente_proprietario_id=attr.ente_proprietario_id
and   ambito.ambito_code=bko.ambito
and   coalesce(bko.conto_foglia,'')='S'
and   conto.ambito_id=ambito.ambito_id
and   conto.pdce_conto_code=bko.pdce_conto_code
and   conto.login_operazione like bko.login_operazione||'@%'
and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;


-- pdce_conto_di_legge
insert into siac_r_pdce_conto_attr
(
	pdce_conto_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select conto.pdce_conto_id,
       attr.attr_id,
       'S',
       now(),
       bko.login_operazione,
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
     siac_d_ambito ambito
where ente.ente_proprietario_id=2
and   attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='pdce_conto_di_legge'
and   bko.ente_proprietario_id=attr.ente_proprietario_id
and   bko.tipo_operazione='I'
and   ambito.ente_proprietario_id=attr.ente_proprietario_id
and   ambito.ambito_code=bko.ambito
and   coalesce(bko.conto_di_legge,'')='S'
and   conto.ambito_id=ambito.ambito_id
and   conto.pdce_conto_code=bko.pdce_conto_code
and   conto.login_operazione like bko.login_operazione||'@%'
and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;


-- pdce_ammortamento
insert into siac_r_pdce_conto_attr
(
	pdce_conto_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select conto.pdce_conto_id,
       attr.attr_id,
       'S',
       now(),
       bko.login_operazione,
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
     siac_d_ambito ambito
where ente.ente_proprietario_id=2
and   attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='pdce_conto_di_legge'
and   bko.ente_proprietario_id=attr.ente_proprietario_id
and   bko.tipo_operazione='I'
and   ambito.ente_proprietario_id=attr.ente_proprietario_id
and   ambito.ambito_code=bko.ambito
and   coalesce(bko.conto_di_legge,'')='S'
and   conto.ambito_id=ambito.ambito_id
and   conto.pdce_conto_code=bko.pdce_conto_code
and   conto.login_operazione like bko.login_operazione||'@%'
and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;


-- pdce_conto_attivo
insert into siac_r_pdce_conto_attr
(
	pdce_conto_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select conto.pdce_conto_id,
       attr.attr_id,
       'S',
       now(),
       bko.login_operazione,
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
     siac_d_ambito ambito
where ente.ente_proprietario_id=2
and   attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='pdce_conto_attivo'
and   bko.ente_proprietario_id=attr.ente_proprietario_id
and   bko.tipo_operazione='I'
and   ambito.ente_proprietario_id=attr.ente_proprietario_id
and   ambito.ambito_code=bko.ambito
and   coalesce(bko.conto_di_legge,'')='S'
and   conto.ambito_id=ambito.ambito_id
and   conto.pdce_conto_code=bko.pdce_conto_code
and   conto.login_operazione like bko.login_operazione||'@%'
and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;


-- pdce_conto_segno_negativo
insert into siac_r_pdce_conto_attr
(
	pdce_conto_id,
    attr_id,
    boolean,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select conto.pdce_conto_id,
       attr.attr_id,
       'S',
       now(),
       bko.login_operazione,
       attr.ente_proprietario_id
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
     siac_d_ambito ambito
where ente.ente_proprietario_id=2
and   attr.ente_proprietario_id=ente.ente_proprietario_id
and   attr.attr_code='pdce_conto_attivo'
and   bko.ente_proprietario_id=attr.ente_proprietario_id
and   bko.tipo_operazione='I'
and   ambito.ente_proprietario_id=attr.ente_proprietario_id
and   ambito.ambito_code=bko.ambito
and   coalesce(bko.conto_di_legge,'')='S'
and   conto.ambito_id=ambito.ambito_id
and   conto.pdce_conto_code=bko.pdce_conto_code
and   conto.login_operazione like bko.login_operazione||'@%'
and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;


-- siac_r_pdce_conto_class
insert into siac_r_pdce_conto_class
(
	pdce_conto_id,
    classif_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select conto.pdce_conto_id,
       dwh.classif_id,
       now(),
       bko.login_operazione,
       conto.ente_proprietario_id
from siac_t_ente_proprietario ente,
     siac_v_dwh_codifiche_econpatr dwh, siac_bko_t_caricamento_pdce_conto bko,
     siac_t_pdce_conto conto, siac_d_ambito ambito
where ente.ente_proprietario_id=2
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ente_proprietario_id=ambito.ente_proprietario_id
and   bko.tipo_operazione='I'
and   ambito.ambito_code=bko.ambito
and   conto.ambito_id=ambito.ambito_id
and   conto.pdce_conto_code=bko.pdce_conto_code
and   conto.login_operazione like bko.login_operazione||'@%'
and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
and   coalesce(bko.codifica_bil,'')!=''
and   dwh.ente_proprietario_id=conto.ente_proprietario_id
and   dwh.codice_codifica_albero=bko.codifica_bil
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;

select bko.*
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito , siac_t_pdce_conto conto
where ente.ente_proprietario_id=2
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   conto.ambito_id=ambito.ambito_id
and   bko.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ambito=ambito.ambito_code
and   bko.tipo_operazione='A'
and   bko.pdce_conto_code=conto.pdce_conto_code
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;


select bko.*
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito , siac_t_pdce_conto conto,
     siac_v_dwh_codifiche_econpatr dwh
where ente.ente_proprietario_id=2
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   conto.ambito_id=ambito.ambito_id
and   bko.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ambito=ambito.ambito_code
and   bko.tipo_operazione='A'
and   bko.pdce_conto_code=conto.pdce_conto_code
and   coalesce(bko.codifica_bil,'')!=''
and   dwh.ente_proprietario_id=ente.ente_proprietario_id
and   dwh.codice_codifica_albero=bko.codifica_bil
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;
-- 23

update  siac_t_pdce_conto conto
set     pdce_conto_desc=bko.pdce_conto_desc,
        data_modifica=now(),
        login_operazione=conto.login_operazione||'-'||bko.login_operazione
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito
where ente.ente_proprietario_id=2
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   conto.ambito_id=ambito.ambito_id
and   bko.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ambito=ambito.ambito_code
and   bko.tipo_operazione='A'
and   bko.pdce_conto_code=conto.pdce_conto_code
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;



update siac_r_pdce_conto_class rc
set     data_cancellazione=now(),
        validita_fine=now(),
        login_operazione=rc.login_operazione||'-'||bko.login_operazione
from siac_t_ente_proprietario ente,siac_d_class_tipo tipo,siac_t_class c,
     siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito , siac_t_pdce_conto conto,
     siac_v_dwh_codifiche_econpatr dwh
where ente.ente_proprietario_id=2
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.classif_tipo_code in
(
'SPA_CODBIL',
'SPP_CODBIL',
'CE_CODBIL',
'CO_CODBIL',
)
and   c.classif_tipo_id=tipo.classif_tipo_id
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   conto.ambito_id=ambito.ambito_id
and   bko.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ambito=ambito.ambito_code
and   bko.tipo_operazione='A'
and   bko.pdce_conto_code=conto.pdce_conto_code
and   coalesce(bko.codifica_bil,'')!=''
and   dwh.ente_proprietario_id=ente.ente_proprietario_id
and   dwh.codice_codifica_albero=bko.codifica_bil
and   rc.classif_id=c.classif_id
and   rc.pdce_conto_id=conto.pdce_conto_id
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null
and   rc.data_cancellazione is null
and   rc.validita_fine is null;


insert into siac_r_pdce_conto_class
(
	pdce_conto_id,
    classif_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select conto.pdce_conto_id,
       dwh.classif_id,
       now(),
       bko.login_operazione,
       conto.ente_proprietario_id
from siac_t_ente_proprietario ente,
     siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito , siac_t_pdce_conto conto,
     siac_v_dwh_codifiche_econpatr dwh
where ente.ente_proprietario_id=2
and   ambito.ente_proprietario_id=ente.ente_proprietario_id
and   conto.ambito_id=ambito.ambito_id
and   bko.ente_proprietario_id=ente.ente_proprietario_id
and   bko.ambito=ambito.ambito_code
and   bko.tipo_operazione='A'
and   bko.pdce_conto_code=conto.pdce_conto_code
and   coalesce(bko.codifica_bil,'')!=''
and   dwh.ente_proprietario_id=ente.ente_proprietario_id
and   dwh.codice_codifica_albero=bko.codifica_bil
and   bko.caricato=false
and   bko.data_cancellazione is null
and   bko.validita_fine is null;




select *
from siac_v_dwh_codifiche_econpatr dwh
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero='D.4.b'

-- classif_id=75607078
select tipo.classif_tipo_code, c.*
from siac_t_class c,siac_d_class_tipo tipo
--where c.classif_id=75607078
where c.classif_id=75607076
and  tipo.classif_tipo_id=c.classif_tipo_id

-- A.B.IV.1.c

-- 00020
-- conto economico (codice di bilancio)
select tipo.classif_tipo_code,fam.classif_fam_code,tree.class_fam_code, dwh.*
from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
     siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero like 'B.13%'
and   c.classif_id=dwh.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code not like '%GSA'
and   r.classif_id=c.classif_id
and   tree.classif_fam_tree_id=r.classif_fam_tree_id
and   fam.classif_fam_id=tree.classif_fam_id
and   r.data_cancellazione is null
and   r.validita_fine is null


begin;
insert into siac_t_class
(
  classif_code,
  classif_desc,
  classif_tipo_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
 'a',
 'Personale',
 tipo.classif_tipo_id,
 clock_timestamp(),
 'admin-pdce-carica',
 tipo.ente_proprietario_id
from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
     siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero = 'B.13'
and   c.classif_id=dwh.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code not like '%GSA'
and   r.classif_id=c.classif_id
and   tree.classif_fam_tree_id=r.classif_fam_tree_id
and   fam.classif_fam_id=tree.classif_fam_id
and   r.data_cancellazione is null
and   r.validita_fine is null;



insert into siac_r_class_fam_tree
(
  classif_fam_tree_id,
  classif_id,
  classif_id_padre,
  ordine,
  livello,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select tree.classif_fam_tree_id,
       cnew.classif_id,
       c.classif_id,
       r.ordine||'.'||cnew.classif_code,
       r.livello+1,
       clock_timestamp(),
       'admin-pdce-carica',
       tipo.ente_proprietario_id
from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
     siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam,
     siac_t_class cnew
where dwh.ente_proprietario_id=2
and   dwh.codice_codifica_albero = 'B.13'
and   c.classif_id=dwh.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code not like '%GSA'
and   r.classif_id=c.classif_id
and   tree.classif_fam_tree_id=r.classif_fam_tree_id
and   fam.classif_fam_id=tree.classif_fam_id
and   cnew.ente_proprietario_id=2
and   cnew.login_operazione ='admin-pdce-carica'
and   r.data_cancellazione is null
and   r.validita_fine is null;

delete from siac_bko_t_caricamento_pdce_conto
-- 71
select *
from siac_bko_t_caricamento_pdce_conto
where tipo_operazione='A'
-- 48 I
-- 23 A


select livello,count(*)
from siac_bko_t_caricamento_pdce_conto
where tipo_operazione='I'
group by livello





select distinct pdce_conto_code from siac_bko_t_caricamento_pdce_conto
begin;
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.01.01.002','Multe e sanzioni per violazioni delle norme di polizia amministrativa a carico delle amministrazioni pubbliche','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.01.01.003','Multe e sanzioni per violazioni delle norme urbanistiche a carico delle amministrazioni pubbliche','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.01.01.004','Multe e sanzioni per violazioni delle norme del codice della strada a carico delle amministrazioni pubbliche','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.01.01.999','Altre multe, ammende, sanzioni e oblazioni a carico delle amministrazioni pubbliche','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.02.01.002','Multe e sanzioni per violazioni delle norme di polizia amministrativa a carico delle famiglie','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.02.01.003','Multe e sanzioni per violazioni delle norme urbanistiche a carico delle famiglie','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.02.01.004','Multe e sanzioni per violazioni delle norme del codice della strada a carico delle famiglie','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.02.01.999','Altre multe, ammende, sanzioni e oblazioni a carico delle famiglie','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.03.01.002','Multe e sanzioni per violazioni delle norme di polizia amministrativa a carico delle imprese','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.03.01.003','Multe e sanzioni per violazioni delle norme urbanistiche a carico delle imprese','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.03.01.004','Multe e sanzioni per violazioni delle norme del codice della strada a carico delle imprese','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.03.01.999','Altre multe, ammende, sanzioni e oblazioni a carico delle imprese','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.04.01.002','Multe e sanzioni per violazioni delle norme di polizia amministrativa a carico delle Istituzioni Sociali Private','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.04.01.003','Multe e sanzioni per violazioni delle norme urbanistiche a carico delle Istituzioni Sociali Private','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.04.01.004','Multe e sanzioni per violazioni delle norme del codice della strada a carico delle Istituzioni Sociali Private','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.4.2.04.01.999','Altre multe, ammende, sanzioni e oblazioni a carico delle Istituzioni Sociali Private','I','RE',6,'A.8','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.3.1.01.05.999','Altri tributi trasferiti a titolo di devoluzioni','A','CE',6,'B.13.a','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.4.2.01.01.002','Accantonamenti al fondo perdite società partecipate','I','CE',6,'B.16','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.4.2.01.01.003','Accantonamenti a fondo perdite enti partecipate','I','CE',6,'B.16','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.4.2.01.01.999','Accantonamenti per altri rischi','I','CE',6,'B.16','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '5.1.4.04.05','Minusvalenze da alienazione di partecipazioni in PA  incluse nelle Amministrazioni locali','I','CE',5,'E.25.c','GE','S','S','','','S','',2);

insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '5.1.4.04.05.001','Minusvalenze da alienazione di partecipazioni in PA controllate incluse nelle Amministrazioni locali','I','CE',6,'E.25.c','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '5.1.4.04.05.002','Minusvalenze da alienazione di partecipazioni in PA partecipate incluse nelle Amministrazioni locali','I','CE',6,'E.25.c','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '5.1.4.04.05.003','Minusvalenze da alienazione di partecipazioni in altre PA incluse nelle Amministrazioni locali','I','CE',6,'E.25.c','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '5.2.4.04.05','Plusvalenze da alienazione di partecipazioni in PA  incluse nelle Amministrazioni locali','I','RE',5,'E.24.d','GE','S','S','','','S','',2);

insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '5.2.4.04.05.001','Plusvalenze da alienazione di partecipazioni in PA controllate incluse nelle Amministrazioni locali','I','RE',6,'E.24.d','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '5.2.4.04.05.002','Plusvalenze da alienazione di partecipazioni in PA partecipate incluse nelle Amministrazioni locali','I','RE',6,'E.24.d','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '5.2.4.04.05.003','Plusvalenze da alienazione di partecipazioni in altre PA incluse nelle Amministrazioni locali','I','RE',6,'E.24.d','GE','S','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.12','Partecipazioni in PA controllate incluse nelle  Amministrazioni locali ','I','AP',5,'B.IV.1.c','GE','','S','','','S','',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.12.01','Partecipazioni in PA controllate incluse nelle  Amministrazioni locali ','I','AP',6,'B.IV.1.c','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.12.01.001','Partecipazioni in PA controllate incluse nelle Amministrazioni locali ','I','AP',7,'B.IV.1.c','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.13','Partecipazioni in PA partecipate incluse nelle Amministrazioni locali ','I','AP',5,'B.IV.1.c','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.13.01','Partecipazioni in PA partecipate incluse nelle Amministrazioni locali ','I','AP',6,'B.IV.1.c','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.13.01.001','Partecipazioni in PA partecipate incluse nelle Amministrazioni locali ','I','AP',7,'B.IV.1.c','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.14','Partecipazioni in altre PA incluse  nelle Amministrazioni locali','I','AP',5,'B.IV.1.c','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.14.01','Partecipazioni in altre PA incluse  nelle Amministrazioni locali','I','AP',6,'B.IV.1.c','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.2.3.01.14.01.001','Partecipazioni in altre PA incluse nelle Amministrazioni locali','I','AP',7,'B.IV.1.c','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.3.2.02.10.01.012','Crediti da Alienazione di partecipazioni in PA controllate incluse nelle Amministrazioni locali','I','AP',7,'C.II.3','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.3.2.02.10.01.013','Crediti da Alienazione di partecipazioni in PA partecipate incluse nelle Amministrazioni locali','I','AP',7,'C.II.3','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '1.3.2.02.10.01.014','Crediti da Alienazione di partecipazioni in altre  PA  incluse nelle Amministrazioni locali','I','AP',7,'C.II.3','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.2.9.99.01','Fondo perdite società e enti partecipati','I','PP',5,'','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.2.9.99.01.01','Fondo perdite società e enti partecipati','I','PP',6,'','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.2.9.99.01.01.001','Fondo perdite società partecipate','I','PP',7,'B.3','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.2.9.99.01.01.002','Fondo perdite enti partecipati ','I','PP',7,'B.3','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.3.1.01.01.01.001','Fondo per trattamento fine rapporto','A','PP',7,'C','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '2.4.3.01.02.99.999','Altri tributi trasferiti a titolo di devoluzioni','I','PP',7,'D.4.b','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.1.01.08','Creditori per impegni su esercizi futuri','I','OP',5,'','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.1.01.08.01','Creditori per impegni su esercizi futuri','I','OP',6,'','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.1.01.08.01.001','Creditori per impegni su esercizi futuri','I','OP',7,'1','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.1.02.01.01.001','Contributi agli investimenti e trasferimenti in conto capitale da effettuare','A','OP',7,'1','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.1.02.02','Creditori per Contributi agli investimenti e trasferimenti in conto capitale da effettuare','I','OP',5,'','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.1.02.02.01','Creditori per Contributi agli investimenti e trasferimenti in conto capitale da effettuare','I','OP',6,'','GE','','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.1.02.02.01.001','Creditori per Contributi agli investimenti e trasferimenti in conto capitale da effettuare','I','OP',7,'1','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.2.01.01.01.001','Beni dati in uso a terzi','A','OP',7,'3','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.2.01.02.01.001','Depositari  beni propri','A','OP',7,'3','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.2.02.01.01.001','Beni di terzi in uso','A','OP',7,'2','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.2.02.02.01.001','Depositanti beni ','A','OP',7,'2','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.01.01.01.001','Fidejussioni per conto di altre Amministrazioni pubbliche','A','OP',7,'4','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.01.02.01.001','Debitori per fidejussioni a favore di altre Amministrazioni pubbliche','A','OP',7,'4','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.01.03.01.001','Altre garanzie per conto di altre Amministrazioni pubbliche','A','OP',7,'4','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.01.04.01.001','Debitori per altre garanzie a favore di altre Amministrazioni pubbliche','A','OP',7,'4','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.02.01.01.001','Fidejussioni per conto di imprese controllate','A','OP',7,'5','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.02.02.01.001','Debitori per fidejussioni a favore di imprese controllate','A','OP',7,'5','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.02.03.01.001','Altre garanzie per conto di imprese controllate','A','OP',7,'5','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.02.04.01.001','Debitori per altre garanzie a favore di imprese controllate','A','OP',7,'5','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.03.01.01.001','Fidejussioni per conto di imprese partecipate','A','OP',7,'6','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.03.02.01.001','Debitori per fidejussioni a favore di imprese partecipate','A','OP',7,'6','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.03.03.01.001','Altre garanzie per conto di imprese partecipate','A','OP',7,'6','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.03.04.01.001','Debitori per altre garanzie a favore di imprese partecipate','A','OP',7,'6','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.04.01.01.001','Fidejussioni per conto di altre imprese','A','OP',7,'7','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.04.02.01.001','Debitori per fidejussioni a favore di altre imprese','A','OP',7,'7','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.04.03.01.001','Altre garanzie per conto di altre imprese','A','OP',7,'7','GE','S','S','','','S','2',2);
insert into siac_bko_t_caricamento_pdce_conto (pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '3.1.3.04.04.01.001','Debitori per altre garanzie a favore di altre imprese','A','OP',7,'7','GE','S','S','','','S','2',2);