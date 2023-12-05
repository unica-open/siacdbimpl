/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-8338 Sofia 30.09.2021 - inizio

select fnc_dba_add_column_params ('siac_bko_t_caricamento_pdce_conto',  'tipo_codifica_bil',  'VARCHAR(50)');
select fnc_dba_add_column_params ('siac_bko_t_caricamento_pdce_conto',  'validita_inizio_new',  'timestamp');
select fnc_dba_add_column_params ('siac_bko_t_caricamento_pdce_conto',  'validita_fine_new',  'timestamp');


CREATE TABLE if not exists siac.siac_bko_t_adeguamento_causali 
(
	adegua_cau_id serial NOT NULL,
	file varchar null,
	tipo_operazione  varchar not null,
	codice_causale   varchar NULL,
	pdce_conto_dare  varchar NULL,
    pdce_conto_avere varchar NULL,
    pdce_segno_aggiorna varchar null,
	caricata bool NOT NULL DEFAULT false,
	ambito varchar NOT NULL DEFAULT 'AMBITO_FIN'::character varying,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL DEFAULT 'admin-carica-cau'::character varying,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_bko_t_adeguamento_causali PRIMARY KEY (adegua_cau_id),
	CONSTRAINT siac_t_ente_proprietario_siac_bko_t_adeguamento_causali FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_bko_t_adeguamento_causali_fk_ente_proprietario_id_idx ON siac.siac_bko_t_adeguamento_causali USING btree (ente_proprietario_id);

drop FUNCTION if exists siac.fnc_siac_bko_caricamento_pdce_conto
(
  annoBilancio                    integer,
  enteProprietarioId              integer,
  ambitoCode                      varchar,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);


CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_caricamento_pdce_conto
(
  annoBilancio                    integer,
  enteProprietarioId              integer,
  ambitoCode                      varchar,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    codResult integer:=null;

    dateInizVal timestamp:=null;
BEGIN

	strMessaggioFinale:='Inserimento conti PDC_ECON di generale ambitoCode='||ambitoCode||'.';

    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica esistenza conti da creare in siac_bko_t_caricamento_pdce_conto.';
    select 1 into codResult
    from siac_bko_t_caricamento_pdce_conto bko
    where bko.ente_proprietario_id=enteProprietarioId
    and   bko.ambito=ambitoCode
    and   bko.caricato=false
    and   bko.data_cancellazione is null
	and   bko.validita_fine is null;

    if codResult is null then
    	raise exception ' Conti non presenti.';
    end if;

    dateInizVal:=(annoBilancio::varchar||'-01-01')::timestamp;

   	 
    /*
      17.09.2021 Sofia SIAC-8338 -- commentato in quanto codifiche di bilancio inserite fuori fnc in TD
	codResult:=null;
	-- siac_t_class B.13.a
    strMessaggio:='Inserimento codice di bilancio B.13.a [siac_t_class].';
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
     dateInizVal,
     loginOperazione,
     tipo.ente_proprietario_id
    from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
         siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam
    where dwh.ente_proprietario_id=enteProprietarioId
    and   dwh.codice_codifica_albero = 'B.13'
    and   c.classif_id=dwh.classif_id
    and   tipo.classif_tipo_id=c.classif_tipo_id
    and   tipo.classif_tipo_code not like '%GSA'
    and   r.classif_id=c.classif_id
    and   tree.classif_fam_tree_id=r.classif_fam_tree_id
    and   fam.classif_fam_id=tree.classif_fam_id
    and   not exists -- 25.09.2019 Sofia SIAC-7012
    (
    select 1
    from siac_t_class c1
    where c1.ente_proprietario_id=tipo.ente_proprietario_id
    and   c1.classif_tipo_id=tipo.classif_tipo_id
    and   c1.classif_code='a'
    and   c1.data_cancellazione is null
    )
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    returning classif_id into codResult;
	raise notice 'strMessaggio=% %',strMessaggio,codResult;

    codResult:=null;
 	-- siac_r_class_fam_tree B.13.a

    strMessaggio:='Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree].';
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
           dateInizVal,
           loginOperazione,
           tipo.ente_proprietario_id
    from siac_v_dwh_codifiche_econpatr dwh,siac_t_class c,siac_d_class_tipo tipo,
         siac_r_class_fam_tree r,siac_t_class_fam_tree tree, siac_d_class_fam fam,
         siac_t_class cnew
    where dwh.ente_proprietario_id=enteProprietarioId
    and   dwh.codice_codifica_albero = 'B.13'
    and   c.classif_id=dwh.classif_id
    and   tipo.classif_tipo_id=c.classif_tipo_id
    and   tipo.classif_tipo_code not like '%GSA'
    and   r.classif_id=c.classif_id
    and   tree.classif_fam_tree_id=r.classif_fam_tree_id
    and   fam.classif_fam_id=tree.classif_fam_id
    and   cnew.ente_proprietario_id=enteProprietarioId
    and   cnew.login_operazione =loginOperazione
    and   not exists
    (
    select 1 from siac_r_class_fam_tree r1
    where r1.ente_proprietario_id=tipo.ente_proprietario_id
    and   r1.classif_id=cnew.classif_id
    and   r1.classif_id_padre=c.classif_id
    and   r1.classif_fam_tree_id=tree.classif_fam_tree_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    returning classif_classif_fam_tree_id into codResult;
	raise notice 'strMessaggio=% %',strMessaggio,codResult;
    */
   
   --- 17.09.2021 Sofia SIAC-8338
   -- siac_t_pdce_conto
   strMessaggio:='Cancellazione conti [siac_t_pdce_conto.validita_fine=31/12'||annoBilancio::varchar||'].';
   update siac_t_pdce_conto p
   set    validita_fine=(annoBilancio::varchar||'-12-31')::timestamp,
          data_modifica=now(),
          login_operazione=p.login_operazione||'-'||loginOperazione
   from siac_d_ambito ambito,siac_d_pdce_conto_tipo tipo  ,
        siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
        siac_bko_t_caricamento_pdce_conto bko
   where bko.ente_proprietario_id=enteProprietarioId
   and   bko.tipo_operazione='C'
   and   bko.caricato=false
   and   p.ente_proprietario_id=enteProprietarioId
   and   p.pdce_conto_code=bko.pdce_conto_code
   and   ambito.ambito_id=p.ambito_id
   and   ambito.ambito_code=bko.ambito
   and   tipo.pdce_ct_tipo_id=p.pdce_ct_tipo_id
   and   tree.pdce_fam_tree_id=p.pdce_fam_tree_id
   and   fam.pdce_fam_id=tree.pdce_fam_id
   and   fam.pdce_fam_code=bko.classe_conto
   and   p.data_cancellazione is null
   and   bko.data_cancellazione is null
   and   bko.validita_fine is null;
  
   codResult:=null;
   select count(*) into codResult 
   from siac_d_ambito ambito,siac_d_pdce_conto_tipo tipo  ,
        siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
        siac_bko_t_caricamento_pdce_conto bko,
        siac_t_pdce_conto p
   where bko.ente_proprietario_id=enteProprietarioId
   and   bko.tipo_operazione='C'
   and   bko.caricato=false
   and   p.ente_proprietario_id=enteProprietarioId
   and   p.pdce_conto_code=bko.pdce_conto_code
   and   ambito.ambito_id=p.ambito_id
   and   ambito.ambito_code=bko.ambito
   and   tipo.pdce_ct_tipo_id=p.pdce_ct_tipo_id
   and   tree.pdce_fam_tree_id=p.pdce_fam_tree_id
   and   fam.pdce_fam_id=tree.pdce_fam_id
   and   fam.pdce_fam_code=bko.classe_conto
   and   p.validita_fine is not null 
   and   p.login_operazione like '%-'||loginOperazione
   and   p.data_cancellazione is null
   and   bko.data_cancellazione is null
   and   bko.validita_fine is null;
   if codResult is null then codResult:=0;
   end if;
   raise notice 'Conti cancellati=%',codResult; 
  
    --- 17.09.2021 Sofia SIAC-8338
    codResult:=null;
    -- siac_t_pdce_conto
    strMessaggio:='Inserimento conti livello III [siac_t_pdce_conto].';
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
      login_operazione,
      login_creazione
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
      dateInizVal,
      tipo.ente_proprietario_id,
      bko.login_operazione||'-'||loginOperazione||'@'||bko.carica_pdce_conto_id::varchar,
      bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
         siac_d_ambito ambito,
         siac_d_pdce_conto_tipo tipo,
         siac_t_pdce_conto contoPadre
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   fam.ambito_id=ambito.ambito_id
    and   fam.pdce_fam_code=bko.classe_conto
    and   tree.pdce_fam_id=fam.pdce_fam_id
    and   tipo.pdce_ct_tipo_code=bko.tipo_conto
    and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   bko.livello=3
    and   contoPadre.ente_proprietario_id=tipo.ente_proprietario_id
    and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   contoPadre.livello=bko.livello-1
    and   contoPadre.ambito_id=ambito.ambito_id
    and   contoPadre.pdce_conto_code =
          SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_pdce_conto conto
    where conto.ente_proprietario_id=enteProprietarioId
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   conto.livello=3
    and   conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
    and   conto.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null
    )
    and contoPadre.data_cancellazione is null
    and coalesce(contoPadre.validita_fine,date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp))
        >= date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp);
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Conti livello III inseriti=%',codResult;
   
	codResult:=null;
	-- siac_t_pdce_conto
    strMessaggio:='Inserimento conti livello IV [siac_t_pdce_conto].';
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
      login_operazione,
      login_creazione
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
      dateInizVal,
      tipo.ente_proprietario_id,
      bko.login_operazione||'-'||loginOperazione||'@'||bko.carica_pdce_conto_id::varchar,
      bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
         siac_d_ambito ambito,
         siac_d_pdce_conto_tipo tipo,
         siac_t_pdce_conto contoPadre
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   fam.ambito_id=ambito.ambito_id
    and   fam.pdce_fam_code=bko.classe_conto
    and   tree.pdce_fam_id=fam.pdce_fam_id
    and   tipo.pdce_ct_tipo_code=bko.tipo_conto
    and   tipo.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   bko.livello=4
    and   contoPadre.ente_proprietario_id=tipo.ente_proprietario_id
    and   contoPadre.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   contoPadre.livello=bko.livello-1
    and   contoPadre.ambito_id=ambito.ambito_id
    and   contoPadre.pdce_conto_code =
          SUBSTRING(bko.pdce_conto_code from 1 for length(bko.pdce_conto_code)- position('.' in reverse(bko.pdce_conto_code)))
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_pdce_conto conto
    where conto.ente_proprietario_id=enteProprietarioId
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   conto.livello=4
    and   conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
    and   conto.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null
    )
    and contoPadre.data_cancellazione is null
    and coalesce(contoPadre.validita_fine,date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp))
        >= date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp);
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Conti livello IV inseriti=%',codResult;

    codResult:=null;
	-- siac_t_pdce_conto
    strMessaggio:='Inserimento conti livello V [siac_t_pdce_conto].';
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
      login_operazione,
      login_creazione
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
      dateInizVal,
      tipo.ente_proprietario_id,
      bko.login_operazione||'-'||loginOperazione||'@'||bko.carica_pdce_conto_id::varchar,
      bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
         siac_d_ambito ambito,
         siac_d_pdce_conto_tipo tipo,
         siac_t_pdce_conto contoPadre
    where ente.ente_proprietario_id=enteProprietarioId
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
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_pdce_conto conto
    where conto.ente_proprietario_id=enteProprietarioId
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   conto.livello=5
    and   conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
    and   conto.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null
    )
    and contoPadre.data_cancellazione is null
    and coalesce(contoPadre.validita_fine,date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp))
        >= date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp);
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Conti livello V inseriti=%',codResult;


    codResult:=null;
	-- siac_t_pdce_conto
    strMessaggio:='Inserimento conti livello VI [siac_t_pdce_conto].';
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
      login_operazione,
      login_creazione
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
      dateInizVal,
      tipo.ente_proprietario_id,
      bko.login_operazione||'-'||loginOperazione||'@'||bko.carica_pdce_conto_id::varchar,
      bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
         siac_d_ambito ambito,
         siac_d_pdce_conto_tipo tipo,
         siac_t_pdce_conto contoPadre
    where ente.ente_proprietario_id=enteProprietarioId
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
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_pdce_conto conto
    where conto.ente_proprietario_id=enteProprietarioId
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   conto.livello=6
    and   conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
    and   conto.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null
    )
    and contoPadre.data_cancellazione is null
    and coalesce(contoPadre.validita_fine,date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp))
        >= date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp);
	GET DIAGNOSTICS codResult = ROW_COUNT;

   	raise notice 'Conti livello VI inseriti=%',codResult;

    codResult:=null;
	-- siac_t_pdce_conto
    strMessaggio:='Inserimento conti livello VII [siac_t_pdce_conto].';
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
      login_operazione,
      login_creazione
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
      dateInizVal,
      tipo.ente_proprietario_id,
      bko.login_operazione||'-'||loginOperazione||'@'||bko.carica_pdce_conto_id::varchar,
      bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_fam_tree tree,siac_d_pdce_fam fam,
         siac_d_ambito ambito,
         siac_d_pdce_conto_tipo tipo,
         siac_t_pdce_conto contoPadre
    where ente.ente_proprietario_id=enteProprietarioId
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
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_pdce_conto conto
    where conto.ente_proprietario_id=enteProprietarioId
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   conto.livello=7
    and   conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
    and   conto.pdce_fam_tree_id=tree.pdce_fam_tree_id
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null
    )
    and contoPadre.data_cancellazione is null
    and coalesce(contoPadre.validita_fine,date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp))
        >= date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp);
    GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Conti livello VII inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_conto_foglia [siac_r_pdce_conto_attr].';

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
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_conto_foglia'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.conto_foglia,'')='S'
--    and   conto.login_operazione like '%'||bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'

    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   conto.ambito_id=ambito.ambito_id
    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_conto_foglia inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_conto_di_legge [siac_r_pdce_conto_attr].';

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
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_conto_di_legge'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.conto_di_legge,'')='S'
--    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code
    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_conto_di_legge inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_ammortamento [siac_r_pdce_conto_attr].';

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
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_ammortamento'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.ammortamento,'')='S'
--    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code

    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_ammortamento inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_conto_attivo [siac_r_pdce_conto_attr].';
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
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_conto_attivo'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.conto_attivo,'')='S'
--    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code

    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_conto_attivo inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - attributi pdce_conto_segno_negativo [siac_r_pdce_conto_attr].';
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
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           attr.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko,siac_t_pdce_conto conto,siac_t_attr attr,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   attr.ente_proprietario_id=ente.ente_proprietario_id
    and   attr.attr_code='pdce_conto_segno_negativo'
    and   bko.ente_proprietario_id=attr.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ente_proprietario_id=attr.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   coalesce(bko.conto_segno_negativo,'')='S'
--    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code

    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Attributi pdce_conto_segno_negativo inseriti=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento conti - codifica_bil [siac_r_pdce_conto_class].';
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
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           conto.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_v_dwh_codifiche_econpatr dwh, siac_bko_t_caricamento_pdce_conto bko,
         siac_t_pdce_conto conto, siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ambito.ente_proprietario_id
    and   bko.tipo_operazione='I'
    and   ambito.ambito_code=bko.ambito
---    and   conto.login_operazione like bko.login_operazione||'-'||loginOperazione||'@%'
    and   conto.login_operazione like '%'||loginOperazione||'@%'
    and   conto.ambito_id=ambito.ambito_id
    and   conto.pdce_conto_code=bko.pdce_conto_code

    and   bko.carica_pdce_conto_id=SUBSTRING(conto.login_operazione, POSITION('@' in conto.login_operazione)+1)::integer
    and   coalesce(bko.codifica_bil,'')!=''
    and   dwh.ente_proprietario_id=conto.ente_proprietario_id
    and   dwh.codice_codifica_albero=bko.codifica_bil
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;

	GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Codifiche di bilancio  pdce_conto NUOVI inserite=%',codResult;


    codResult:=null;
    strMessaggio:='Aggiornamento  conti esistenti - descrizione  [siac_t_pdce_conto].';
    update  siac_t_pdce_conto conto
	set     pdce_conto_desc=bko.pdce_conto_desc,
    	    data_modifica=clock_timestamp(),
        	login_operazione=conto.login_operazione||'-'||bko.login_operazione||'-'||loginOperazione
	from siac_t_ente_proprietario ente,
    	 siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito
	where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.ambito_id=ambito.ambito_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
    and   bko.tipo_operazione='A'
    and   bko.pdce_conto_code=conto.pdce_conto_code
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;

	codResult:=null;
    strMessaggio:='Aggiornamento  conti esistenti - codif_bil - chiusura  [siac_r_pdce_conto_class].';
    update siac_r_pdce_conto_class rc
    set     --data_cancellazione=clock_timestamp(), SIAC-8338 Sofia 21.09.2021
            --validita_fine=clock_timestamp(),
            validita_fine=bko.validita_fine_new::timestamp, -- SIAC-8338 Sofia 21.09.2021
            login_operazione=rc.login_operazione||'-'||bko.login_operazione||'-'||loginOperazione
    from siac_t_ente_proprietario ente,siac_d_class_tipo tipo,siac_t_class c,
         siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito , siac_t_pdce_conto conto,
         siac_v_dwh_codifiche_econpatr dwh
    where ente.ente_proprietario_id=enteProprietarioId
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.classif_tipo_code in
    (
    'SPA_CODBIL',
    'SPP_CODBIL',
    'CE_CODBIL',
    'CO_CODBIL'
    )
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.ambito_id=ambito.ambito_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
 --   and   bko.tipo_operazione='A'
    and   bko.tipo_operazione='R' -- SIAC-8338 Sofia 21.09.2021
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
    -- SIAC-8338 Sofia 21.09.2021
    and   coalesce(rc.validita_inizio)<=bko.validita_fine_new::timestamp-interval '1 days'
    and    coalesce(rc.validita_fine,bko.validita_fine_new::timestamp-interval '1 days')<bko.validita_fine_new::timestamp;
--    and   rc.validita_fine is null; SIAC-8338 Sofia 21.09.2021

    codResult:=null;
    strMessaggio:='Aggiornamento  conti esistenti - codif_bil - inserimento  [siac_r_pdce_conto_class].';
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
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           conto.ente_proprietario_id
    from siac_t_ente_proprietario ente,
         siac_bko_t_caricamento_pdce_conto bko, siac_d_ambito ambito , siac_t_pdce_conto conto,
         siac_v_dwh_codifiche_econpatr dwh,
         siac_t_class c,siac_d_class_tipo tipo  -- SIAC-8338 Sofia 21.09.2021
    where ente.ente_proprietario_id=enteProprietarioId
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.ambito_id=ambito.ambito_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ambito=ambito.ambito_code
--    and   bko.tipo_operazione='A'
    and   bko.tipo_operazione='R' -- SIAC-8338 Sofia 21.09.2021
    and   bko.pdce_conto_code=conto.pdce_conto_code
    and   coalesce(bko.codifica_bil,'')!=''
    and   dwh.ente_proprietario_id=ente.ente_proprietario_id
    and   dwh.codice_codifica_albero=bko.codifica_bil
     -- SIAC-8338 Sofia 21.09.2021
    and   c.classif_id=dwh.classif_id
    and   tipo.classif_tipo_id=c.classif_tipo_id
    and   tipo.classif_tipo_code=bko.tipo_codifica_bil
     -- SIAC-8338 Sofia 21.09.2021
    and   bko.caricato=false
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
   	raise notice 'Codifiche di bilancio  pdce_conto inserite=%',codResult;

    messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata.';

    raise notice '%',messaggioRisultato;

    return;

exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_siac_bko_caricamento_pdce_conto (integer,integer, varchar,varchar,timestamp,  out integer,  out  varchar)    OWNER TO siac;

-- SIAC-8338 Sofia 30.09.2021 - fine 


--SIAC-8367 Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_tracciato_t2sb21s (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar,
  p_organo_provv varchar,
  p_code_report varchar,
  p_codice_ente varchar
)
RETURNS TABLE (
  record_t2sb21s varchar
) AS
$body$
DECLARE

prefisso varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

begin
	
/*
	27/05/2020. 
    Funzione nata per la SIAC-7195.
    La funziona prepara i dati del tracciato t2sb21s.
    Riceve in input i parametri di estrazione dei dati ed il codice report.
    In base al report richiama le procedure corrette.
    Funziona solo per i report BILR024 e BILR146.

*/
	
if p_code_report = 'BILR024' then
    return query 
      with query_tot as (
      	select 'E' tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
/*  SIAC-7678 26/06/2020:
	Sul file delle variazioni "normali" il tag 'NCAP' che sta sul record di 
    dettaglio (da posizione 27 a 33) deve essere allineato a dx e preceduto 
    dai necessari zeri per riempire i 7 campi previsti.            
             COALESCE(tipologia_code,'') */
            case when COALESCE(tipologia_code,'') <> '' then
            	'00'||left(tipologia_code,5) 
            else '' end codifica_bil, 
      --SIAC-8367 04/10/2021.
      --Tolta l'estrazione del tipo capitolo ed il relativo
      -- raggruppamento perche' venivano duplicati i record a parita' 
      --di codifica di bilancio.            
            COALESCE(tipologia_desc,'') descr_codifica_bil,--tipo_capitolo,
            sum(variazione_aumento_residuo) variazione_aumento_residuo,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            sum(variazione_aumento_cassa) variazione_aumento_cassa,
            sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
        from "BILR024_Allegato_7_Allegato_delibera_variazione_su_entrate_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)         
    	group by tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            codifica_bil, descr_codifica_bil--, tipo_capitolo
     UNION select 'S' tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                COALESCE(programma_code,'')||COALESCE(titusc_code,'') codifica_bil,
      --SIAC-8367 04/10/2021.
      --Tolta l'estrazione del tipo capitolo ed il relativo
      -- raggruppamento perche' venivano duplicati i record a parita' 
      --di codifica di bilancio.                  
                COALESCE(titusc_desc,'') descr_codifica_bil,--tipo_capitolo,
                sum(variazione_aumento_residuo) variazione_aumento_residuo,
                sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
                sum(variazione_aumento_cassa) variazione_aumento_cassa,
                sum(variazione_diminuzione_residuo) variazione_diminuzione_residuo,
                sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
                sum(variazione_diminuzione_cassa) variazione_diminuzione_cassa                          
            from "BILR024_Allegato_7_Allegato_delibera_variazione_su_spese_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                codifica_bil, descr_codifica_bil--, tipo_capitolo
      order by tipo_record, attoamm_id, codifica_bil)
       select (         	
              --CIST
          '00001'  || 
              --CENT codice ente 
          p_codice_ente  || 
              --CESE codice esercizio
          p_anno_competenza  || 
              -- NDEL Numero Delibera
          LPAD(query_tot.attoamm_numero::varchar,7,'0') ||          
              --SORG Organo deliberante
          case when p_organo_provv is null or p_organo_provv = '' then 
              ' ' else p_organo_provv  end || 
              -- CTIPREC tipo record
          '1'   ||
           	  -- SEOU INDICATORE ENTRATA/USCITA (1= Entrata - 2 = Uscita)
          case when query_tot.tipo_record = 'E' then '1'
          		else '2' end ||
			  -- NCAP Codifica di Bilancio
/*  SIAC-8217 31/05/2021.
	Se non esiste la codifica se il capitolo e' FCI di entrata deve essere 8888888, 
    altrimenti 9999999.
	Se in futuro ci sara' la deficienza di cassa per le spese dovra' 
    essere 8888888, ma al momento questa tipologia di capitolo non e' 
    gestita. */
          -- LPAD(query_tot.codifica_bil, 7, '0') ||
          
/* SIAC-8367 04/10/2021.
   Si deve tornare indietro sulla modifica fatta per la SIAC-8217
   perche' si duplicano i record a parita' di codifica di bilancio e
   quindi non si puo' raggruppare per tipo capitolo.
   Occerrera' capire come gestire il caso del capitolo di entrata FCI.
              
          case when query_tot.tipo_record = 'E' then --Entrata          	
          	case when query_tot.tipo_capitolo in ('FCI') THEN            	
            	case when query_tot.codifica_bil <> '' then
         			LPAD(query_tot.codifica_bil, 7, '0')
          		else '8888888' end 
           else case when query_tot.codifica_bil <>'' then
          			LPAD(query_tot.codifica_bil, 7, '0')
          		else '9999999' end 
       		end 
          else -- Spesa
            case when query_tot.codifica_bil <>'' then
              LPAD(query_tot.codifica_bil, 7, '0')
            else '9999999' end 
            end || */
          case when query_tot.codifica_bil <>'' then
              LPAD(query_tot.codifica_bil, 7, '0')
            else '9999999' end ||             
          	  -- NART Numero Articolo
          '000' ||
          		--NRES Anno Residuo 
/*  SIAC-7678 26/06/2020:
	Sempre sul file delle variazioni "normali" il tag 'NRES' (da posizione 
    37 per 4) deve essere compilato solo sui record relativamente ai residui.
    ....se il capitolo interessato e' la competenza deve essere compilato 
    con quattro zeri              
          p_anno_competenza || */ 
          '0000' ||
          		--IPIUCPT Importo Variazione PIU' Competenza
          trim(replace(to_char(query_tot.variazione_aumento_stanziato ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENCPT Importo Variazione MENO Competenza
          trim(replace(to_char(query_tot.variazione_diminuzione_stanziato ,
          		'000000000000000.00'),'.','')) ||
           		--IPIUCAS Importo Variazione PIU' Cassa
          trim(replace(to_char(query_tot.variazione_aumento_cassa ,
          		'000000000000000.00'),'.','')) ||
          		--IMENCAS Importo Variazione MENO Cassa
          trim(replace(to_char(query_tot.variazione_diminuzione_cassa ,
          		'000000000000000.00'),'.','')) ||
         		--ZDES Descrizione Codifica di Bilancio
          RPAD(left(query_tot.descr_codifica_bil,90),90,' ') ||
                --ZDESBL Descrizione Codifica di Bilancio (Bilingue)
          RPAD(' ',90,' ') || 
          		--CMEC Codice Meccanografico
          RPAD('0', 7, '0') ||
                -- SRILIVA Segnale Rilevanza IVA (0 = NO - 1 = SI) NON OBBL.
          ' ' ||
          		--ISTACPT  Importo Stanziamento di Competenza
          LPAD('0', 17,'0') ||
          		--ISTACAS  Importo Stanziamento di Cassa
          LPAD('0', 17,'0') ||
          		--NCNTRIF   Numero Conto di Riferimento
          LPAD('0', 7,'0') ||
          		-- STIPCNT  Tipo Conto di Riferimento (0 = ordinario - 1 = vincolato)
          ' ' ||
          		--ISCOCAP   Importo limite Sconfino
          LPAD('0', 17,'0') ||
          		--IIMP   Importo Impegnato
          LPAD('0', 17,'0') ||
          		--IFNDVIN   Importo Fondo Vincolato
          LPAD('0', 17,'0') ||
           		--FILLER 
          RPAD(' ', 11, ' ')
          )::varchar           
       from query_tot;
else --BILR149                
return query 
      with query_tot as (
      	select 'E' tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
/*  SIAC-7678 26/06/2020:
	Sul file delle variazioni "normali" il tag 'NCAP' che sta sul record di 
    dettaglio (da posizione 27 a 33) deve essere allineato a dx e preceduto 
    dai necessari zeri per riempire i 7 campi previsti.            
             COALESCE(tipologia_code,'') */
            case when COALESCE(tipologia_code,'') <> '' then
            	'00'||left(tipologia_code,5) 
            else '' end codifica_bil, 
            COALESCE(tipologia_desc,'') descr_codifica_bil, tipo_capitolo,
            sum(variazione_aumento_stanziato) variazione_aumento_stanziato,
            0 variazione_aumento_fpv,
            sum(variazione_diminuzione_stanziato) variazione_diminuzione_stanziato,
            0 variazione_diminuzione_fpv                             
        from "BILR149_Allegato_8_variazioni_eserc_gestprov_entrate_bozza_txt" (
          p_ente_prop_id, p_anno ,
          p_numero_delibera, p_anno_delibera, p_tipo_delibera,
          p_anno_competenza, p_ele_variazioni)            
    	group by tipo_record, attoamm_anno,
            attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
            data_provv_var, data_approvazione_provv,
            codifica_bil, descr_codifica_bil, tipo_capitolo
     UNION select 'S' tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                COALESCE(programma_code,'')||COALESCE(titusc_code,'') codifica_bil,
                COALESCE(titusc_desc,'') descr_codifica_bil, tipo_capitolo,
                	--l'importo presentato delle variazioni deve comprendere
                    --lo stanziato NON FPV piu' quello FPV.
                sum(variazione_aumento_stanziato+variazione_aumento_fpv) variazione_aumento_stanziato,
                sum(variazione_aumento_fpv) variazione_aumento_fpv,
                sum(variazione_diminuzione_stanziato+variazione_diminuzione_fpv) variazione_diminuzione_stanziato,
                sum(variazione_diminuzione_fpv) variazione_diminuzione_fpv                          
            from "BILR149_Allegato_8_variazioni_eserc_gestprov_spese_bozza_txt" (
              p_ente_prop_id, p_anno ,
              p_numero_delibera, p_anno_delibera, p_tipo_delibera,
              p_anno_competenza, p_ele_variazioni)            
        	group by tipo_record, attoamm_anno,
                attoamm_numero, tipo_atto, attoamm_oggetto, attoamm_id,
                data_provv_var, data_approvazione_provv,
                codifica_bil, descr_codifica_bil, tipo_capitolo
      order by tipo_record, attoamm_id, codifica_bil)
       select (         	
              --CIST
          '00001'  || 
              --CENT codice ente 
          p_codice_ente  || 
              --CESE codice esercizio
          p_anno_competenza  || 
              -- NDEL Numero Delibera
          LPAD(query_tot.attoamm_numero::varchar,7,'0') ||          
              --SORG Organo deliberante
          case when p_organo_provv is null or p_organo_provv = '' then 
              ' ' else p_organo_provv  end || 
              -- CTIPREC tipo record
          '1'   ||
           	  -- SEOU INDICATORE ENTRATA/USCITA (1= Entrata - 2 = Uscita)
          case when query_tot.tipo_record = 'E' then '1'
          		else '2' end ||
			  -- NCAP Codifica di Bilancio              
    /*  SIAC-8217 31/05/2021.
	Se non esiste la codifica se il capitolo e' FCI di entrata deve essere 8888888, 
    altrimenti 9999999.
	Se in futuro ci sara' la deficienza di cassa per le spese dovra' 
    essere 8888888, ma al momento questa tipologia di capitolo non e' 
    gestita. */
          -- LPAD(query_tot.codifica_bil, 7, '0') ||
          
/* SIAC-8367 04/10/2021.
   Si deve tornare indietro sulla modifica fatta per la SIAC-8217
   perche' si duplicano i record a parita' di codifica di bilancio e
   quindi non si puo' raggruppare per tipo capitolo.
   Occerrera' capire come gestire il caso del capitolo di entrata FCI.          
          case when query_tot.tipo_record = 'E' then --Entrata          	
          	case when query_tot.tipo_capitolo in ('FCI') THEN            	
            	case when query_tot.codifica_bil <> '' then
         			LPAD(query_tot.codifica_bil, 7, '0')
          		else '8888888' end 
           else case when query_tot.codifica_bil <>'' then
          			LPAD(query_tot.codifica_bil, 7, '0')
          		else '9999999' end 
       		end 
          else -- Spesa
            case when query_tot.codifica_bil <>'' then
              LPAD(query_tot.codifica_bil, 7, '0')
            else '9999999' end 
            end || */
          case when query_tot.codifica_bil <>'' then
              LPAD(query_tot.codifica_bil, 7, '0')
            else '9999999' end ||               
          	  -- NART Numero Articolo
          '000' || 
          		--NRES Anno Residuo 
/*  SIAC-7678 26/06/2020:
	Sempre sul file delle variazioni "normali" il tag 'NRES' (da posizione 
    37 per 4) deve essere compilato solo sui record relativamente ai residui.
    ....se il capitolo interessato e' la competenza deve essere compilato 
    con quattro zeri              
          p_anno_competenza || */ 
          '0000' ||                
          		--IPIUCPT Importo Variazione PIU' Competenza
          trim(replace(to_char(query_tot.variazione_aumento_stanziato ,
          		'000000000000000.00'),'.','')) ||         
          		--IMENCPT Importo Variazione MENO Competenza
          trim(replace(to_char(query_tot.variazione_diminuzione_stanziato ,
          		'000000000000000.00'),'.','')) ||
           		--IPIUCAS Importo Variazione PIU' Cassa
          LPAD('0',17,'0') ||
          		--IMENCAS Importo Variazione MENO Cassa
          LPAD('0',17,'0') ||
         		--ZDES Descrizione Codifica di Bilancio
          RPAD(left(query_tot.descr_codifica_bil,90),90,' ') ||
                --ZDESBL Descrizione Codifica di Bilancio (Bilingue)
          RPAD(' ',90,' ') || 
          		--CMEC Codice Meccanografico
          RPAD('0', 7, '0') ||
                -- SRILIVA Segnale Rilevanza IVA (0 = NO - 1 = SI) NON OBBL.
          ' ' ||
          		--ISTACPT  Importo Stanziamento di Competenza
          LPAD('0', 17,'0') ||
          		--ISTACAS  Importo Stanziamento di Cassa
          LPAD('0', 17,'0') ||
          		--NCNTRIF   Numero Conto di Riferimento
          LPAD('0', 7,'0') ||
          		-- STIPCNT  Tipo Conto di Riferimento (0 = ordinario - 1 = vincolato)
          ' ' ||
          		--ISCOCAP   Importo limite Sconfino
          LPAD('0', 17,'0') ||
          		--IIMP   Importo Impegnato
          LPAD('0', 17,'0') ||
          		--IFNDVIN   Importo Fondo Vincolato
          LPAD('0', 17,'0') ||
           		--FILLER 
          RPAD(' ', 11, ' ')
          )::varchar           
       from query_tot;                   
                
end if;
	

exception
    when syntax_error THEN
    	record_t2Sb21s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	record_t2Sb21s='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;        
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8367 Maurizio - FINE


--SIAC-8413 Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR087_distinta_mandati" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_mandato_da integer,
  p_num_mandato_a integer,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_cod_distinta varchar
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  importo_lordo_mandato numeric,
  numero_mandato integer,
  data_mandato date,
  desc_mandato varchar,
  nome_tesoriere varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  importo_competenza numeric,
  importo_residui numeric,
  importo_prec_mandati numeric,
  importo_prec_residui numeric,
  importo_prec_competenza numeric,
  stato_mandato varchar,
  display_error varchar,
  cod_distinta varchar,
  desc_distinta varchar,
  richiedente_nome varchar,
  atto_tipo_code varchar,
  atto_tipo_desc varchar,
  atto_anno varchar,
  atto_numero integer,
  atto_struttura varchar,
  conto_tesoreria varchar,
  commissioni varchar
) AS
$body$
DECLARE
elencoMandati record;
elencoImpegni record;
elencoLiquidazioni record;
elencoOneri	record;
elencoImportiPrec record;
elencoImportiAnnul record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
posizione integer;
cod_atto_amm VARCHAR;
appStr VARCHAR;

cod_tipo_onere VARCHAR;
subDocumento VARCHAR;
elemTipoCode VARCHAR;
numFatturaApp VARCHAR;
ImportoApp numeric;
ordIdReversale	INTEGER;
anno_eser_int INTEGER;
importo_prec_mandati_app NUMERIC;
importo_prec_competenza_app NUMERIC;
importo_prec_residui_app NUMERIC;



BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
importo_lordo_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
nome_tesoriere='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
importo_competenza=0;
importo_residui=0;
importo_prec_mandati=0;
importo_prec_competenza=0;
importo_prec_residui=0;
stato_mandato='';
cod_distinta='';
desc_distinta='';

importo_prec_mandati_app=0;
importo_prec_competenza_app=0;
importo_prec_residui_app=0;
anno_eser_int=p_anno :: INTEGER;

--03/04/17 Daniela: nuovi campi per jira SIAC-4698
richiedente_nome='';
atto_tipo_code='';
atto_tipo_desc='';
atto_anno='';
atto_numero=0;
atto_struttura='';
conto_tesoreria='';
commissioni='';


	/* 12/02/2015: Aggiunto questo controllo per presentare un messaggio di errore
    	sul report nel caso l'utente non abbia specificato nessun parametro di ricerca */
display_error='';
if p_num_mandato_da IS NULL AND p_num_mandato_a IS NULL AND p_data_mandato_da IS NULL AND
	p_data_mandato_a IS NULL THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO MANDATO DA/A" E "DATA MANDATO DA/A".';
    return next;
    return;
end if;

/* calcolo gli importi relativi ai riporti ANNULLATI.
    	Prendo tutti gli importi dell'anno di esercizio dello stesso periodo
        o numero di mandato indicato dall'utente ma che hanno stato A */
/*        
BEGIN
	for elencoImportiAnnul in
		SELECT t_ordinativo.ord_anno, 
        		SUM(t_ord_ts_det.ord_ts_det_importo) somma_importo
          FROM  siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_t_ordinativo t_ordinativo, 
                siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det,
                siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                siac_r_ordinativo_stato r_ord_stato,  
                siac_d_ordinativo_stato d_ord_stato ,
                 siac_d_ordinativo_tipo d_ord_tipo       
          WHERE t_ordinativo.ord_id=r_ord_stato.ord_id
           AND t_bil.bil_id=t_ordinativo.bil_id
           AND t_periodo.periodo_id=t_bil.periodo_id
           AND t_ord_ts.ord_id=t_ordinativo.ord_id           
           AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
           AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
           AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
            AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
			AND (p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL
            		AND (t_ordinativo.ord_numero between p_num_mandato_da AND p_num_mandato_a)
                OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS  NULL)
                OR (p_num_mandato_a IS  NULL AND p_num_mandato_da=t_ordinativo.ord_numero )
                OR (p_num_mandato_da IS  NULL AND p_num_mandato_a=t_ordinativo.ord_numero ))
			AND (p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
            		AND (t_ordinativo.ord_emissione_data between p_data_mandato_da AND p_data_mandato_a)
                    OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL)
                    OR (p_data_mandato_a IS NULL AND p_data_mandato_da IS NOT NULL
                    	AND p_data_mandato_da=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy')  )
                    OR (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL
                    	AND p_data_mandato_a=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') ))
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
           AND t_periodo.anno=p_anno
          AND d_ord_stato.ord_stato_code ='A' --Annullato
          AND d_ord_tipo.ord_tipo_code='P'  /* Ordinativi di pagamento */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            AND r_ord_stato.validita_fine IS NULL 
            AND  t_bil.data_cancellazione IS NULL
            AND  t_periodo.data_cancellazione IS NULL
            AND  t_ordinativo.data_cancellazione IS NULL
            AND  t_ord_ts.data_cancellazione IS NULL
            AND  t_ord_ts_det.data_cancellazione IS NULL
            AND  d_ts_det_tipo.data_cancellazione IS NULL
            AND  r_ord_stato.data_cancellazione IS NULL
            AND  d_ord_stato.data_cancellazione IS NULL
            AND  d_ord_tipo.data_cancellazione IS NULL           
            GROUP BY t_ordinativo.ord_anno          
    loop    
    	importo_annul_mandati_app= importo_annul_mandati_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        IF elencoImportiAnnul.ord_anno  < anno_ese_finanz THEN
        	importo_annul_residui_app=importo_annul_residui_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        ELSE
        	importo_annul_competenza_app=importo_annul_competenza_app+COALESCE(elencoImportiAnnul.somma_importo,0);
        END IF;
        
    end loop;   
END;*/


	/* calcolo gli importi relativi ai riporti PRECEDENTI.
    	Prendo tutti gli importi dell'anno di esercizio precedenti il periodo
        o i numeri di mandato indicati dall'utente */
/* 04/02/2016: estraggo  l'anno dell'impegno tramite la relativa liquidazione
	perche' per sapere se l'importo e' competenza o residuo devo confrontare 
    l'anno dell'impegno e non quello del mandato */        
BEGIN
	for elencoImportiPrec in              
          SELECT --t_ordinativo.ord_anno, 
          	t_movgest.movgest_anno,
          SUM(t_ord_ts_det.ord_ts_det_importo) somma_importo
          FROM  siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_t_ordinativo t_ordinativo, 
                siac_t_ordinativo_ts t_ord_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det,
                siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                siac_r_ordinativo_stato r_ord_stato,  
                siac_d_ordinativo_stato d_ord_stato ,
                siac_d_ordinativo_tipo d_ord_tipo  ,
                siac_r_liquidazione_ord r_liq_ord,
                siac_r_liquidazione_movgest r_liq_movgest,
                siac_t_movgest t_movgest,
                siac_t_movgest_ts t_movgest_ts   
          WHERE t_ordinativo.ord_id=r_ord_stato.ord_id
           AND t_bil.bil_id=t_ordinativo.bil_id
           AND t_periodo.periodo_id=t_bil.periodo_id
           AND t_ord_ts.ord_id=t_ordinativo.ord_id           
           AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
           AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
           AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
            AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
            AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
           AND r_liq_movgest.liq_id=r_liq_ord.liq_id
           AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
           AND t_movgest_ts.movgest_id=t_movgest.movgest_id
			AND ((p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL
                      AND t_ordinativo.ord_numero < p_num_mandato_da )
                  --OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS  NULL)
                  OR (p_num_mandato_a IS  NULL AND p_num_mandato_da IS NOT NULL 
                  		AND t_ordinativo.ord_numero < p_num_mandato_da)
                  OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS NOT NULL  
                  		AND t_ordinativo.ord_numero < p_num_mandato_a)
              OR (p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
                      AND t_ordinativo.ord_emissione_data < p_data_mandato_da )
                     -- OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL)
              	OR (p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS  NULL
                	AND t_ordinativo.ord_emissione_data<p_data_mandato_da)                      	                        
                OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS NOT NULL
                      		AND t_ordinativo.ord_emissione_data <p_data_mandato_a ))                                                           			
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
           AND t_periodo.anno=p_anno
           /* 01/03/2016: aggiunto il filtro per escludere i mandati annullati
           		nel calcolo dell'importo precedente */
          AND d_ord_stato.ord_stato_code <>'A' --Annullato
          AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            AND r_ord_stato.validita_fine IS NULL 
            AND  t_bil.data_cancellazione IS NULL
            AND  t_periodo.data_cancellazione IS NULL
            AND  t_ordinativo.data_cancellazione IS NULL
            AND  t_ord_ts.data_cancellazione IS NULL
            AND  t_ord_ts_det.data_cancellazione IS NULL
            AND  d_ts_det_tipo.data_cancellazione IS NULL
            AND  r_ord_stato.data_cancellazione IS NULL
            AND  d_ord_stato.data_cancellazione IS NULL
            AND  d_ord_tipo.data_cancellazione IS NULL     
            AND r_liq_ord.data_cancellazione IS NULL 
            AND r_liq_movgest.data_cancellazione IS NULL 
            AND t_movgest.data_cancellazione IS NULL
            AND t_movgest_ts.data_cancellazione IS NULL                 
            GROUP BY t_movgest.movgest_anno--t_ordinativo.ord_anno             		 
    loop
    	importo_prec_mandati_app= importo_prec_mandati_app+COALESCE(elencoImportiPrec.somma_importo,0);
        /*04/02/2016: uso l'anno dell'impegno invece che quello dell'ordinativo */
        --IF elencoImportiPrec.ord_anno  < anno_eser_int THEN
        IF elencoImportiPrec.movgest_anno  < anno_eser_int THEN
        	importo_prec_residui_app=importo_prec_residui_app+COALESCE(elencoImportiPrec.somma_importo,0);
        ELSE
        	importo_prec_competenza_app=importo_prec_competenza_app+COALESCE(elencoImportiPrec.somma_importo,0);
        END IF;
        
    end loop;   
END;

RTN_MESSAGGIO:='Estrazione dei dati dei mandati ''.';
raise notice 'Estrazione dei dati dei mandati ';
raise notice 'ora: % ',clock_timestamp()::varchar;



--dataMandatoStr= to_date(p_data_mandato,'yyyy/MM/dd') ::varchar;


for elencoMandati in
/* 04/02/2016: estraggo anche l'anno dell'impegno tramite la relativa liquidazione
	perche' per sapere se l'importo e' competenza o residuo devo confrontare 
    l'anno dell'impegno e non quello del mandato */
select 	ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente, 
		t_periodo.anno anno_eser, t_ordinativo.ord_anno,
		 t_ordinativo.ord_desc,
        t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
        t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
        OL.ente_oil_resp_ord, OL.ente_oil_tes_desc, OL.ente_oil_resp_amm,        
        t_bil_elem.elem_code cod_cap, t_bil_elem.elem_code2 cod_art,
        t_bil_elem.elem_id, d_ord_stato.ord_stato_code, 
        SUM(t_ord_ts_det.ord_ts_det_importo) IMPORTO_TOTALE,
        t_movgest.movgest_anno anno_impegno, d_distinta.dist_code, d_distinta.dist_desc
-- 03/04/17 Daniela: nuovi campi per jira SIAC-4698 
        , t_soggetto1.soggetto_desc soggetto1_desc
        , d_commisione.comm_tipo_desc
        , d_contotes.contotes_code
        -- in assenza di atto per ordinativo prendo quello legato alla liquidazione
		,case when r_ord_atto.attoamm_id is not null then COALESCE(d_ord_atto_amm_tipo.attoamm_tipo_code,'')
        	else COALESCE(d_liq_atto_amm_tipo.attoamm_tipo_code,'') end atto_tipo_code
		,case when r_ord_atto.attoamm_id is not null then COALESCE(d_ord_atto_amm_tipo.attoamm_tipo_desc,'')
        	else COALESCE(d_liq_atto_amm_tipo.attoamm_tipo_desc,'') end atto_tipo_desc
		,case when r_ord_atto.attoamm_id is not null then COALESCE(t_ord_atto.attoamm_anno,'')
        	else COALESCE(t_liq_atto.attoamm_anno,'') end attoamm_anno
		,case when r_ord_atto.attoamm_id is not null then t_ord_atto.attoamm_numero
        	else t_liq_atto.attoamm_numero end attoamm_numero
		,case when r_ord_atto.attoamm_id is not null then COALESCE(t_class.classif_code,'')||' ' ||COALESCE(t_ord_atto.attoamm_oggetto,'')
        	else COALESCE(t_class1.classif_code,'')||' ' ||COALESCE(t_liq_atto.attoamm_oggetto,'') end attoamm_struttura
 -- 03/04/17 Daniela fine
		FROM  	siac_t_ente_proprietario ep,
        		siac_t_ente_oil OL,
                siac_t_bil t_bil,
                siac_t_periodo t_periodo,
                siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
				siac_t_bil_elem t_bil_elem,                  
                siac_t_ordinativo t_ordinativo
                LEFT JOIN siac_d_distinta d_distinta
                	on (d_distinta.dist_id=t_ordinativo.dist_id
                    	AND d_distinta.data_cancellazione IS NULL)
-- 03/04/17 Daniela: nuovi campi per jira SIAC-4698
				-- Operatore che ha registrato il mandato, ha senso l'outer join? Direi di si perche' non si trova sempre il codice nella tabella dei soggetti
				LEFT JOIN siac_t_soggetto t_soggetto1 on (t_soggetto1.soggetto_code=t_ordinativo.login_creazione and t_soggetto1.data_cancellazione is NULL)
				-- Commissioni  e conto corrente 
				LEFT JOIN siac_d_commissione_tipo d_commisione on (d_commisione.comm_tipo_id = t_ordinativo.comm_tipo_id and d_commisione.data_cancellazione is null)
				LEFT JOIN siac_d_contotesoreria d_contotes on (d_contotes.contotes_id = t_ordinativo.contotes_id and d_contotes.data_cancellazione is null)
				-- Atto amministrativo ordinativo
				LEFT JOIN siac_r_ordinativo_atto_amm r_ord_atto on (r_ord_atto.ord_id = t_ordinativo.ord_id and r_ord_atto.data_cancellazione is null)
                LEFT JOIN siac_t_atto_amm t_ord_atto ON (t_ord_atto.attoamm_id=r_ord_atto.attoamm_id AND t_ord_atto.data_cancellazione IS NULL)
				LEFT JOIN siac_d_atto_amm_tipo d_ord_atto_amm_tipo ON (d_ord_atto_amm_tipo.attoamm_tipo_id=t_ord_atto.attoamm_tipo_id AND d_ord_atto_amm_tipo.data_cancellazione IS NULL)
                LEFT JOIN siac_r_atto_amm_class r_ord_atto_amm_class ON (r_ord_atto_amm_class.attoamm_id=t_ord_atto.attoamm_id AND r_ord_atto_amm_class.data_cancellazione IS NULL)
                LEFT JOIN siac_t_class t_class ON (t_class.classif_id= r_ord_atto_amm_class.classif_id AND t_class.data_cancellazione IS NULL),
 -- 03/04/17 Daniela fine
                siac_t_ordinativo_ts t_ord_ts,
                siac_r_liquidazione_ord r_liq_ord
-- 03/04/17 Daniela: nuovi campi per jira SIAC-4698
				-- Atto amministrativo liquidazione
                LEFT JOIN siac_r_liquidazione_atto_amm r_liq_atto on (r_liq_atto.liq_id = r_liq_ord.liq_id and r_liq_atto.data_cancellazione is null)
                LEFT JOIN siac_t_atto_amm t_liq_atto ON (t_liq_atto.attoamm_id=r_liq_atto.attoamm_id AND t_liq_atto.data_cancellazione IS NULL)
				LEFT JOIN siac_d_atto_amm_tipo d_liq_atto_amm_tipo ON (d_liq_atto_amm_tipo.attoamm_tipo_id=t_liq_atto.attoamm_tipo_id AND d_liq_atto_amm_tipo.data_cancellazione IS NULL)
                LEFT JOIN siac_r_atto_amm_class r_liq_atto_amm_class ON (r_liq_atto_amm_class.attoamm_id=t_liq_atto.attoamm_id AND r_liq_atto_amm_class.data_cancellazione IS NULL)
                LEFT JOIN siac_t_class t_class1 ON (t_class1.classif_id= r_liq_atto_amm_class.classif_id AND t_class1.data_cancellazione IS NULL),
 -- 03/04/17 Daniela fine
                siac_r_liquidazione_movgest r_liq_movgest,
                siac_t_movgest t_movgest,
                siac_t_movgest_ts t_movgest_ts,
                siac_t_ordinativo_ts_det t_ord_ts_det,
                siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
                siac_r_ordinativo_stato r_ord_stato,  
                siac_d_ordinativo_stato d_ord_stato ,
                 siac_d_ordinativo_tipo d_ord_tipo,
                 siac_r_ordinativo_soggetto r_ord_soggetto ,
                 siac_t_soggetto t_soggetto       		     	
        WHERE  t_ordinativo.ente_proprietario_id=ep.ente_proprietario_id
        	AND OL.ente_proprietario_id=ep.ente_proprietario_id
            AND r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id            
            AND  r_ordinativo_bil_elem.ord_id=t_ordinativo.ord_id                    
           AND t_ordinativo.ord_id=r_ord_stato.ord_id
           AND t_bil.bil_id=t_ordinativo.bil_id
           AND t_periodo.periodo_id=t_bil.periodo_id
           AND t_ord_ts.ord_id=t_ordinativo.ord_id           
           AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
           AND d_ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
           AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
           AND d_ord_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
           AND t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
           AND r_ord_soggetto.ord_id=t_ordinativo.ord_id
           AND r_liq_ord.sord_id= t_ord_ts.ord_ts_id
           AND r_liq_movgest.liq_id=r_liq_ord.liq_id
           AND t_movgest_ts.movgest_ts_id=r_liq_movgest.movgest_ts_id
           AND t_movgest_ts.movgest_id=t_movgest.movgest_id
           	/* valorizzo le condizioni in base al fatto che i parametri
            	- numero mandato DA A
                - data mandato DA A
            	siano valorizzati o meno */
		   AND ((p_num_mandato_da IS NOT NULL AND p_num_mandato_a IS NOT NULL
            		AND (t_ordinativo.ord_numero between p_num_mandato_da 
                    AND p_num_mandato_a))
                OR (p_num_mandato_da IS  NULL AND p_num_mandato_a IS  NULL)
                OR (p_num_mandato_a IS  NULL 
                	AND p_num_mandato_da=t_ordinativo.ord_numero )
                OR (p_num_mandato_da IS  NULL 
                	AND p_num_mandato_a=t_ordinativo.ord_numero ))
			AND ((p_data_mandato_da IS NOT NULL AND p_data_mandato_a IS NOT NULL
            			AND (to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
                        between p_data_mandato_da AND p_data_mandato_a))
                    OR (p_data_mandato_da IS  NULL AND p_data_mandato_a IS  NULL)
                    OR (p_data_mandato_a IS NULL AND p_data_mandato_da IS NOT NULL
                    	AND p_data_mandato_da=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy')  )
                    OR (p_data_mandato_da IS NULL AND p_data_mandato_a IS NOT NULL
                    	AND p_data_mandato_a=to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') ))
		--AND p_data_mandato_da =to_timestamp(to_char(t_ordinativo.ord_emissione_data,'dd/MM/yyyy'),'dd/MM/yyyy') 
           --14/04/2017: aggiunto anche il test su  p_cod_distinta =''
           AND (p_cod_distinta is null OR p_cod_distinta ='' or d_distinta.dist_code=trim(p_cod_distinta))
            AND t_ordinativo.ente_proprietario_id= p_ente_prop_id
            AND t_periodo.anno=p_anno
            	/* Gli stati possibili sono:
                	I = INSERITO
                    T = TRASMESSO 
                    Q = QUIETANZIATO
                    F = FIRMATO
                    A = ANNULLATO 
                  Sono estratti tutti gli stati, se e' annullato e' segnalato sulla stampa */
            --AND d_ord_stato.ord_stato_code IN ('I', 'A', 'N') 
            AND d_ord_tipo.ord_tipo_code='P' /* Ordinativi di pagamento */
            AND d_ts_det_tipo.ord_ts_det_tipo_code='A' /* importo attuale */
            	/* devo testare la data di fine validita' perche'
                	quando un ordinativo e' annullato, lo trovo 2 volte,
                    uno con stato inserito e l'altro annullato */
            AND r_ord_stato.validita_fine IS NULL 
            AND ep.data_cancellazione IS NULL
            AND OL.data_cancellazione IS NULL
            AND r_ord_stato.data_cancellazione IS NULL
            AND r_ordinativo_bil_elem.data_cancellazione IS NULL
            AND t_bil_elem.data_cancellazione IS NULL
            AND  t_bil.data_cancellazione IS NULL
            AND  t_periodo.data_cancellazione IS NULL
            AND  t_ordinativo.data_cancellazione IS NULL
            AND  t_ord_ts.data_cancellazione IS NULL
            AND  t_ord_ts_det.data_cancellazione IS NULL
            AND  d_ts_det_tipo.data_cancellazione IS NULL
            AND  r_ord_stato.data_cancellazione IS NULL
            AND  d_ord_stato.data_cancellazione IS NULL
            AND  d_ord_tipo.data_cancellazione IS NULL  
            AND r_ord_soggetto.data_cancellazione IS NULL
            --SIAC-8413 20/10/2021.
            --Non si deve fare il test sualla data cancellazione del soggetto
            --perche' il soggetto era valido al momento della creazione del 
            --mandato e quindi deve essere estratto.
            --AND t_soggetto.data_cancellazione IS NULL
            AND r_liq_ord.data_cancellazione IS NULL 
            AND r_liq_movgest.data_cancellazione IS NULL 
            AND t_movgest.data_cancellazione IS NULL
            AND t_movgest_ts.data_cancellazione IS NULL
            GROUP BY ep.ente_denominazione, ep.codice_fiscale, 
              t_periodo.anno , t_ordinativo.ord_anno,
               t_ordinativo.ord_desc,
              t_ordinativo.ord_numero,t_ordinativo.ord_emissione_data,       
              t_soggetto.soggetto_desc,t_soggetto.partita_iva,t_soggetto.codice_fiscale,
              OL.ente_oil_resp_ord, OL.ente_oil_tes_desc, OL.ente_oil_resp_amm,        
              t_bil_elem.elem_code , t_bil_elem.elem_code2 ,
              t_bil_elem.elem_id, d_ord_stato.ord_stato_code, t_movgest.movgest_anno,
              d_distinta.dist_code, d_distinta.dist_desc
-- 03/04/17 Daniela: nuovi campi per jira SIAC-4698
            , t_soggetto1.soggetto_desc
            , d_commisione.comm_tipo_desc
            , d_contotes.contotes_code
            , r_ord_atto.attoamm_id
            , d_ord_atto_amm_tipo.attoamm_tipo_code,d_ord_atto_amm_tipo.attoamm_tipo_desc, t_ord_atto.attoamm_anno,t_ord_atto.attoamm_numero,t_class.classif_code, t_ord_atto.attoamm_oggetto
            , d_liq_atto_amm_tipo.attoamm_tipo_code,d_liq_atto_amm_tipo.attoamm_tipo_desc, t_liq_atto.attoamm_anno,t_liq_atto.attoamm_numero,t_class1.classif_code, t_liq_atto.attoamm_oggetto
 -- 03/04/17 Daniela fine
            ORDER BY t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data            
loop

--raise notice 'numero mandato % ',elencoMandati.ord_numero;

  stato_mandato= elencoMandati.ord_stato_code;

  importo_prec_mandati=COALESCE(importo_prec_mandati_app,0);
  importo_prec_residui=COALESCE(importo_prec_residui_app,0);
  importo_prec_competenza=COALESCE(importo_prec_competenza_app,0);

  nome_ente=elencoMandati.ente_denominazione;
  partita_iva_ente=elencoMandati.cod_fisc_ente;
  anno_ese_finanz=elencoMandati.anno_eser;
  anno_capitolo=elencoMandati.ord_anno;
  desc_mandato=COALESCE(elencoMandati.ord_desc,'');

  cod_capitolo=elencoMandati.cod_cap;
  cod_articolo=elencoMandati.cod_art;

  numero_mandato=elencoMandati.ord_numero;
  data_mandato=elencoMandati.ord_emissione_data;

      /* se il mandato e' ANNULLATO l'importo deve essere riportato
          come negativo */
  if(stato_mandato='A') THEN
      importo_lordo_mandato= COALESCE(-elencoMandati.IMPORTO_TOTALE,0);
  else
      importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);
  end if;

  /*  04/02/2016: se l'ordinativo ha un impegno che e' di un anno precedente 
          l'anno di esercizio, l'importo e' un residuo, altrimenti e' di competenza.
          Prima confrontavo l'anno dell'ordinativo invece che dell'impegno. */        
  --IF elencoMandati.ord_anno  < anno_eser_int THEN
  IF elencoMandati.anno_impegno  < anno_eser_int THEN
    importo_competenza=0;
    importo_residui=importo_lordo_mandato;
  ELSE
    importo_competenza=importo_lordo_mandato;
    importo_residui=0;
  END IF;

  nome_tesoriere=COALESCE(elencoMandati.ente_oil_tes_desc,'');

  benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
  benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
  benef_nome=COALESCE(elencoMandati.soggetto_desc,'');

  cod_distinta=COALESCE(elencoMandati.dist_code,'');
  desc_distinta=COALESCE(elencoMandati.dist_desc,'');
  
  richiedente_nome=COALESCE(elencoMandati.soggetto1_desc,'');
  atto_tipo_code=COALESCE(elencoMandati.atto_tipo_code,'');
  atto_tipo_desc=COALESCE(elencoMandati.atto_tipo_desc,'');
  atto_anno=COALESCE(elencoMandati.attoamm_anno,'');
  atto_numero=COALESCE(elencoMandati.attoamm_numero,0);
  atto_struttura=COALESCE(elencoMandati.attoamm_struttura,'');
  conto_tesoreria=COALESCE(elencoMandati.contotes_code,'');
  commissioni=COALESCE(elencoMandati.comm_tipo_desc,'');
      
return next;


nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
importo_lordo_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
nome_tesoriere='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
importo_competenza=0;
importo_residui=0;
importo_prec_mandati=0;
importo_prec_competenza=0;
importo_prec_residui=0;
stato_mandato='';
cod_distinta='';
desc_distinta='';
richiedente_nome='';
atto_tipo_code='';
atto_tipo_desc='';
atto_anno='';
atto_numero=0;
atto_struttura='';
conto_tesoreria='';
commissioni='';

raise notice 'fine numero mandato % ',elencoMandati.ord_numero;
end loop;
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  

exception
	when no_data_found THEN
		raise notice 'nessun mandato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

--SIAC-8413 Maurizio - FINE


-- SIAC-8258  Haitham 25.10.2021 - inizio
    
select fnc_dba_add_column_params ('siac_dwh_vincolo',  'vincolo_risorse_code',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_vincolo',  'vincolo_risorse_desc',  'VARCHAR(500)');


CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_vincolo(p_anno_bilancio character varying, p_ente_proprietario_id integer, p_data timestamp without time zone)
 RETURNS TABLE(esito character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE

rec_vincolo_id record;
rec_attr record;
rec_elem_id record;
-- Variabili per campi estratti dal cursore rec_programma_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno  VARCHAR := null;
v_vincolo_code VARCHAR := null;
v_vincolo_desc VARCHAR := null;
v_vincolo_stato_code VARCHAR := null; 
v_vincolo_stato_desc VARCHAR := null;
-- Variabil genere
v_vincolo_gen_code VARCHAR := null; 
v_vincolo_gen_desc VARCHAR := null; 

v_vincolo_risorse_code VARCHAR := null; 
v_vincolo_risorse_desc VARCHAR := null; 

-- Variabili per campi estratti dal cursore rec_elem_id
v_elem_code VARCHAR := null;
v_elem_code2 VARCHAR := null;
v_elem_code3 VARCHAR := null;
v_elem_desc VARCHAR := null;
v_elem_desc2 VARCHAR := null;
v_elem_tipo_code VARCHAR := null;
v_elem_tipo_desc VARCHAR := null;
v_elem_stato_code VARCHAR := null;
v_elem_stato_desc VARCHAR := null;
v_elem_cat_code VARCHAR := null;
v_elem_cat_desc VARCHAR := null; 
-- Variabili attributo
v_FlagTrasferimentiVincolati VARCHAR := null;
v_Note VARCHAR := null;
-- Variabili utili per il caricamento 
v_vincolo_id INTEGER := null;
v_flag_attributo VARCHAR := null;

v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;   

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_vincolo',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico vincoli (FNC_SIAC_DWH_VINCOLO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_vincolo
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre vincolo_id
FOR rec_vincolo_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tv.vincolo_code, tv.vincolo_desc,
       dvs.vincolo_stato_code, dvs.vincolo_stato_desc, tv.vincolo_id,
       dv.vincolo_risorse_vincolate_code , dv.vincolo_risorse_vincolate_desc
FROM siac.siac_t_vincolo tv
INNER JOIN  siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = tv.ente_proprietario_id 
INNER JOIN  siac.siac_t_periodo tp ON tp.periodo_id = tv.periodo_id
INNER JOIN  siac.siac_r_vincolo_stato rvs ON rvs.vincolo_id = tv.vincolo_id 
INNER JOIN  siac.siac_d_vincolo_stato dvs ON dvs.vincolo_stato_id = rvs.vincolo_stato_id
left join siac_r_vincolo_risorse_vincolate rv  on tv.vincolo_id  = rv.vincolo_id 
left join siac_d_vincolo_risorse_vincolate dv  on rv.vincolo_risorse_vincolate_id = dv.vincolo_risorse_vincolate_id  
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND p_data BETWEEN tv.validita_inizio AND COALESCE(tv.validita_fine, p_data)
AND tv.data_cancellazione IS NULL 
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL 
AND p_data BETWEEN rvs.validita_inizio AND COALESCE(rvs.validita_fine, p_data)
AND rvs.data_cancellazione IS NULL 
AND p_data BETWEEN dvs.validita_inizio AND COALESCE(dvs.validita_fine, p_data)
AND dvs.data_cancellazione IS NULL
AND p_data BETWEEN COALESCE(rv.validita_inizio, p_data) AND COALESCE(rv.validita_fine, p_data)
AND rv.data_cancellazione IS NULL

LOOP

  v_ente_proprietario_id := null;
  v_ente_denominazione := null;
  v_anno := null;
  v_vincolo_code := null; 
  v_vincolo_desc := null; 
  v_vincolo_stato_code := null; 
  v_vincolo_stato_desc := null;
  v_vincolo_gen_code := null; 
  v_vincolo_gen_desc := null; 
  
  v_vincolo_id := null;

  v_vincolo_risorse_code := null; 
  v_vincolo_risorse_desc := null; 
  
  v_ente_proprietario_id := rec_vincolo_id.ente_proprietario_id;
  v_ente_denominazione := rec_vincolo_id.ente_denominazione;
  v_anno := rec_vincolo_id.anno;
  v_vincolo_code := rec_vincolo_id.vincolo_code; 
  v_vincolo_desc := rec_vincolo_id.vincolo_desc; 
  v_vincolo_stato_code := rec_vincolo_id.vincolo_stato_code; 
  v_vincolo_stato_desc := rec_vincolo_id.vincolo_stato_desc;

  v_vincolo_id := rec_vincolo_id.vincolo_id; 

  v_vincolo_risorse_code := rec_vincolo_id.vincolo_risorse_vincolate_code; 
  v_vincolo_risorse_desc := rec_vincolo_id.vincolo_risorse_vincolate_desc; 
 
  esito:= '  Inizio ciclo vincolo ('||v_vincolo_id||') - '||clock_timestamp();  --|| '++++++' || v_vincolo_risorse_desc;
  return next;
 
  SELECT dvg.vincolo_gen_code, dvg.vincolo_gen_desc
  INTO  v_vincolo_gen_code, v_vincolo_gen_desc 
  FROM  siac.siac_r_vincolo_genere rvg , siac.siac_d_vincolo_genere dvg
  WHERE rvg.vincolo_gen_id = dvg.vincolo_gen_id
  AND   rvg.vincolo_id = v_vincolo_id 
  AND 	p_data BETWEEN rvg.validita_inizio AND COALESCE(rvg.validita_fine, p_data)
  AND 	rvg.data_cancellazione IS NULL 
  AND 	p_data BETWEEN dvg.validita_inizio AND COALESCE(dvg.validita_fine, p_data)
  AND 	dvg.data_cancellazione IS NULL;

  -- Sezione pe gli attributi
  v_FlagTrasferimentiVincolati := null;
  v_Note := null;
  v_flag_attributo := null;
  -- Ciclo per estrarre gli attibuti relativi ad un vincolo_id
  FOR rec_attr IN
  SELECT ta.attr_code, dat.attr_tipo_code,
         rva.tabella_id, rva.percentuale, rva."boolean" true_false, rva.numerico, rva.testo
  FROM   siac.siac_r_vincolo_attr rva, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
  WHERE  rva.attr_id = ta.attr_id
  AND    ta.attr_tipo_id = dat.attr_tipo_id
  AND    rva.vincolo_id = v_vincolo_id
  AND    rva.data_cancellazione IS NULL
  AND    ta.data_cancellazione IS NULL
  AND    dat.data_cancellazione IS NULL
  AND    p_data BETWEEN rva.validita_inizio AND COALESCE(rva.validita_fine, p_data)
  AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
  AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

  LOOP

    IF rec_attr.attr_tipo_code = 'X' THEN
       v_flag_attributo := rec_attr.testo::varchar;
    ELSIF rec_attr.attr_tipo_code = 'N' THEN
       v_flag_attributo := rec_attr.numerico::varchar;
    ELSIF rec_attr.attr_tipo_code = 'P' THEN
       v_flag_attributo := rec_attr.percentuale::varchar;
    ELSIF rec_attr.attr_tipo_code = 'B' THEN
       v_flag_attributo := rec_attr.true_false::varchar;
    ELSIF rec_attr.attr_tipo_code = 'T' THEN
       v_flag_attributo := rec_attr.tabella_id::varchar;
    END IF;

    IF rec_attr.attr_code = 'FlagTrasferimentiVincolati' THEN
       v_FlagTrasferimentiVincolati := v_flag_attributo;
    ELSIF rec_attr.attr_code = 'Note' THEN
       v_Note := v_flag_attributo;                    
    END IF;

  END LOOP;

  FOR rec_elem_id IN
  SELECT tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, dbet.elem_tipo_code, dbet.elem_tipo_desc,
         dbes.elem_stato_code, dbes.elem_stato_desc, dbec.elem_cat_code, dbec.elem_cat_desc,
         tbe.elem_id
  FROM siac.siac_r_vincolo_bil_elem rvbe
  INNER JOIN siac.siac_t_bil_elem tbe ON tbe.elem_id = rvbe.elem_id
  INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
  INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
  INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
  LEFT JOIN  siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
                                                 AND p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
                                                 AND rbec.data_cancellazione IS NULL
  LEFT JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
                                                AND p_data BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, p_data)
                                                AND dbec.data_cancellazione IS NULL
  WHERE rvbe.vincolo_id = v_vincolo_id
  AND p_data BETWEEN rvbe.validita_inizio AND COALESCE(rvbe.validita_fine, p_data)
  AND rvbe.data_cancellazione IS NULL
  AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
  AND tbe.data_cancellazione IS NULL
  AND p_data BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, p_data)
  AND dbet.data_cancellazione IS NULL
  AND p_data BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, p_data)
  AND rbes.data_cancellazione IS NULL
  AND p_data BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, p_data)
  AND dbes.data_cancellazione IS NULL

  LOOP

    v_elem_code := NULL;
    v_elem_code2 := NULL;
    v_elem_code3 := NULL;
    v_elem_desc := NULL;
    v_elem_desc2 := NULL;
    v_elem_tipo_code := NULL;
    v_elem_tipo_desc := NULL;
    v_elem_stato_code := NULL;
    v_elem_stato_desc := NULL;
    v_elem_cat_code := NULL;
    v_elem_cat_desc := NULL;
    
    v_elem_code := rec_elem_id.elem_code;
    v_elem_code2 := rec_elem_id.elem_code2;
    v_elem_code3 := rec_elem_id.elem_code3;
    v_elem_desc := rec_elem_id.elem_desc;
    v_elem_desc2 := rec_elem_id.elem_desc2;
    v_elem_tipo_code := rec_elem_id.elem_tipo_code;
    v_elem_tipo_desc := rec_elem_id.elem_tipo_desc;
    v_elem_stato_code := rec_elem_id.elem_stato_code;
    v_elem_stato_desc := rec_elem_id.elem_stato_desc;
    v_elem_cat_code := rec_elem_id.elem_cat_code;
    v_elem_cat_desc := rec_elem_id.elem_cat_desc;

    INSERT INTO siac.siac_dwh_vincolo
    (ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_vincolo,
    desc_vincolo,
    cod_stato_vincolo,
    desc_stato_vincolo,
    cod_genere_vincolo, 
    desc_genere_vincolo,
    cod_capitolo,
    cod_articolo,
    cod_ueb,
    desc_capitolo,
    desc_articolo,
    cod_tipo_capitolo,
    desc_tipo_capitolo,
    cod_stato_capitolo,
    desc_stato_capitolo,
    cod_classificazione_capitolo,
    desc_classificazione_capitolo,
    flagtrasferimentivincolati,
    note,
    vincolo_risorse_code,
    vincolo_risorse_desc
    )
    VALUES (v_ente_proprietario_id,
            v_ente_denominazione,
            v_anno,
            v_vincolo_code,
            v_vincolo_desc,
            v_vincolo_stato_code,
            v_vincolo_stato_desc,
            v_vincolo_gen_code,
			v_vincolo_gen_desc,
            v_elem_code,
            v_elem_code2,
            v_elem_code3,
            v_elem_desc,
            v_elem_desc2,
            v_elem_tipo_code,
            v_elem_tipo_desc,
            v_elem_stato_code,
            v_elem_stato_desc,
            v_elem_cat_code,
            v_elem_cat_desc,
            v_FlagTrasferimentiVincolati,
            v_Note,
            v_vincolo_risorse_code,
            v_vincolo_risorse_desc
           );
  END LOOP;
  esito:= '  Fine ciclo vincolo ('||v_vincolo_id||') - '||clock_timestamp();
  RETURN NEXT;      
END LOOP;
esito:= 'Fine funzione carico vincoli (FNC_SIAC_DWH_VINCOLO) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico vincoli (FNC_SIAC_DWH_VINCOLO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$function$
;

-- SIAC-8258  Haitham 25.10.2021 - fine

--SIAC-8344 - Maurizio - INIZIO 

CREATE TABLE  if not exists siac.siac_d_causale_contenzioso_pcc (
  causale_cont_id SERIAL,
  causale_sospensione VARCHAR(500) NOT NULL,
  tipo_contenzioso_pcc VARCHAR(30) NOT NULL,  
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_d_causale_contenzioso_pcc PRIMARY KEY(causale_cont_id),  
  CONSTRAINT siac_t_ente_proprietario_siac_d_causale_contenzioso_pcc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
) 
WITH (oids = false);

CREATE TABLE if not exists siac.siac_d_causale_stato_debito_pcc (
  causale_stato_id SERIAL,
  tipo_contenzioso_pcc VARCHAR(30) NOT NULL,
  codice_stato_debito_pcc VARCHAR(20) NOT NULL,
  descrizione_stato_debito_pcc VARCHAR(500) NOT NULL,
  causale_pcc VARCHAR(20),
  natura VARCHAR(10) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_siac_d_causale_stato_dedito_pcc PRIMARY KEY(causale_stato_id),  
  CONSTRAINT siac_t_ente_proprietario_siac_siac_d_causale_stato_dedito_pcc FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
) 
WITH (oids = false);


--1
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'CONTENZIOSO',
	'debito in contenzioso', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='CONTENZIOSO'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);

  --2
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'DURC IRREGOLARE',
	'debito contestato', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='DURC IRREGOLARE'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);

--3
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'ERRATA FATTURAZIONE',
	'debito contestato', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='ERRATA FATTURAZIONE'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);
      
--4    
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'DOCUMENTAZIONE MANCANTE',
	'debito contestato', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='DOCUMENTAZIONE MANCANTE'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);
        
--5        
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'INADEMPIMENTI',
	'debito contestato', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='INADEMPIMENTI'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);    
    
--6                          
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'ASSENZA POLIZZ',
	'debito contestato', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='ASSENZA POLIZZ'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);
          
--7        
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'EQUITALIA IRREGOLARE',
	'debito contestato', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='EQUITALIA IRREGOLARE'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);
  
--8                    
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'PIGNORAMENTO PRESSO TERZI',
	'debito in contenzioso', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='PIGNORAMENTO PRESSO TERZI'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);        
        
--9                   
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'SEQUESTRO CAUTELATIVO',
	'debito in contenzioso', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='SEQUESTRO CAUTELATIVO'
    	and a.ente_proprietario_id=ente.ente_proprietario_id); 
        
--10                  
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'FALLIMENTO',
	'debito in contenzioso', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='FALLIMENTO'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);
        
--11
insert into siac_d_causale_contenzioso_pcc 
(causale_sospensione, tipo_contenzioso_pcc, validita_inizio,  
 ente_proprietario_id,  data_creazione, data_modifica,  login_operazione)
select 'ATTESA DI ACCETTAZIONE',
	'in attesa di accettazione', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_contenzioso_pcc a
    where a.causale_sospensione='ATTESA DI ACCETTAZIONE'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);
               
        
--*********************************

insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'debito contestato', '2.4.2.1', 
'sospeso > Debito sospeso contestato o verifica adempimenti normativi  CO-> impegno sul titolo 1',
    NULL, 'CO', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.2.1'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);    
  
insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'debito contestato', '2.4.2.2', 
    'sospeso > Debito sospeso contestato o verifica adempimenti normativi  CA-> impegno sul titolo 2',
    NULL, 'CA', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.2.2'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);
        
insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'debito contestato', '2.4.2.3', 
    'sospeso > Debito sospeso contestato o verifica adempimenti normativi  NA -> impegno su titoli differenti da 1 e 2',
    NULL, 'NA', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.2.3'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);

insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'debito in contenzioso', '2.4.3.1', 
    'sospeso > in contenzioso CO -> impegno sul titolo 1',
    'CONT', 'CO', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.3.1'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);

insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'debito in contenzioso', '2.4.3.2', 
    'sospeso > in contenzioso CA -> impegno sul titolo 2',
    'CONT', 'CA', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.3.2'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);

insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'debito in contenzioso', '2.4.3.3', 
    'sospeso > in contenzioso NA -> impegno su titoli differenti da 1 e 2',
    'CONT', 'NA', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.3.3'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);


insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'in attesa di accettazione', '2.4.1.1', 
    'sospeso > in attesa di accettazione CO -> impegno sul titolo 1',
    'ATTESECOLL', 'CO', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.1.1'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);

insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'in attesa di accettazione', '2.4.1.2', 
    'sospeso > in attesa di accettazione CA-> impegno sul titolo 2',
    'ATTESECOLL', 'CA', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.1.2'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);


insert into siac_d_causale_stato_debito_pcc (
  tipo_contenzioso_pcc,  codice_stato_debito_pcc, descrizione_stato_debito_pcc,
  causale_pcc, natura, validita_inizio, ente_proprietario_id,
  data_creazione, data_modifica,  login_operazione)
select 'in attesa di accettazione', '2.4.1.3', 
    'sospeso > in attesa di accettazione NA -> impegno su titoli differenti da 1 e 2',
    'ATTESECOLL', 'NA', now(), ente.ente_proprietario_id, now(),
    now(), 'SIAC-8344'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in(2,3,4,5,10,11,14,16)
	and ente.data_cancellazione IS NULL
    and not exists (select 1
    from siac_d_causale_stato_debito_pcc a
    where a.codice_stato_debito_pcc='2.4.1.3'
    	and a.ente_proprietario_id=ente.ente_proprietario_id);
        
DROP FUNCTION if exists siac."BILR257_modello_003_registro_operaz_pcc"(p_ente_prop_id integer, p_anno varchar, p_utente varchar, p_data_reg_da date, p_data_reg_a date);

CREATE OR REPLACE FUNCTION siac."BILR257_modello_003_registro_operaz_pcc" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_utente varchar,
  p_data_reg_da date,
  p_data_reg_a date
)
RETURNS TABLE (
  nome_ente varchar,
  bil_anno varchar,
  cod_fisc_ente_dest varchar,
  cod_ufficio varchar,
  cod_fiscale_fornitore varchar,
  piva_fornitore varchar,
  cod_tipo_operazione varchar,
  desc_tipo_operazione varchar,
  identificativo2 varchar,
  data_emissione date,
  importo_totale numeric,
  numero_quota integer,
  importo_quota numeric,
  natura_spesa varchar,
  anno_capitolo integer,
  num_capitolo varchar,
  cod_articolo varchar,
  ueb varchar,
  cod_stato_debito varchar,
  cod_causale_mov varchar,
  descr_quota varchar,
  data_emissione_impegno date,
  num_impegno varchar,
  anno_impegno integer,
  cig_documento varchar,
  cig_impegno varchar,
  cup_documento varchar,
  cup_impegno varchar,
  doc_id integer,
  subdoc_id integer,
  v_rpcc_id integer,
  movgest_ts_id integer,
  titolo_code varchar,
  titolo_desc varchar,
  importo_pagato numeric,
  num_ordinativo integer,
  data_ordinativo date,
  cod_fiscale_ordinativo varchar,
  piva_ordinativo varchar,
  estremi_impegno varchar,
  cod_fisc_utente_collegato varchar,
  data_scadenza date,
  importo_quietanza numeric,
  rpcc_registrazione_data date,
  display_error varchar
) AS
$body$
DECLARE

/* 27/10/2021.
   Funzione nata per la SIAC-8344.
   Estrae i dati delle fatture sospese e le carica sulla tabella 
   siac_t_registro_pcc per l'estrazione del report BILR257 - modello 003.
*/

 elencoRegistriRec record;

 elencoAttrib record;
 elencoClass	record;
 annoCompetenza_int integer;
 DEF_NULL	constant varchar:=''; 
 RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
 user_table varchar;
 cod_fisc VARCHAR;
 v_fam_missioneprogramma varchar :='00001';
 v_fam_titolomacroaggregato varchar := '00002';
 sql_query VARCHAR;
 eseguiEstrOld boolean;
 contaParamDate integer;
 max_data_sosp timestamp;
 sosp_causale varchar;
 tipo_contenzioso_pcc varchar;
 
 codice_report varchar :='BILR257';
 
 TIPO_CONTESTATO constant varchar := 'debito contestato';
 TIPO_CONTENZIOSO constant varchar := 'debito in contenzioso';
 TIPO_ACCETTAZIONE constant varchar := 'in attesa di accettazione';
 TIPO_NON_DEFINITO constant varchar := 'non previsto';
 
 NATURA_SPESA_CA constant varchar := 'CA';
 NATURA_SPESA_CO constant varchar := 'CO';
 NATURA_SPESA_NA constant varchar := 'NA';
 causale_pcc varchar;
 
BEGIN

nome_ente='';
bil_anno='';
cod_fisc_ente_dest='';
cod_ufficio='';
cod_fiscale_fornitore='';
piva_fornitore='';
cod_tipo_operazione='';
desc_tipo_operazione='';
identificativo2='';
data_emissione=NULL;
importo_totale=0;
importo_quota=0;
natura_spesa='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
cod_stato_debito='';
cod_causale_mov='';
descr_quota='';
data_emissione_impegno=NULL;
num_impegno='';
anno_impegno=0;
cig_documento='';
cig_impegno='';
cup_documento='';
cup_impegno='';
doc_id=0;
subdoc_id=0;
v_rpcc_id=0;
movgest_ts_id=0;
numero_quota=0;
importo_pagato=0;
num_ordinativo =0;
data_ordinativo=NULL;
cod_fiscale_ordinativo='';
piva_ordinativo='';
estremi_impegno='';
data_scadenza=NULL;
importo_quietanza=0;
rpcc_registrazione_data:=NULL;
display_error:='';

annoCompetenza_int =p_anno ::INTEGER;

select fnc_siac_random_user()
into	user_table;

contaParamDate:=0;
if p_data_reg_da is not null then
	contaParamDate:=contaParamDate+1;
end if;
if p_data_reg_a is not null then
	contaParamDate:=contaParamDate+1;
end if;

if contaParamDate = 1 then
	display_error:='INSERIRE ENTRAMBE LE DATE DI REGISTRAZIONE DELL''INTERVALLO PER ESTRARRE I DATI GIA'' INVIATI';
    return next;
    return;
end if;

eseguiEstrOld:=false;
if contaParamDate = 2 then
	eseguiEstrOld:=true;
end if;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice  'Inserimento dati su siac_t_registro_pcc ''.';

--Inserisco i dati delle quote di documento che hanno una sospensione non riattivata.
--Devo estrarre con distinct perche' una quota potrebbe avere diverse date di
--sospensione non riattivate.
--Nell'estrazione dei dati successiva si prendera' la data piu' recente.
insert into siac_t_registro_pcc(doc_id, subdoc_id, pccop_tipo_id,
	validita_inizio, data_modifica, ente_proprietario_id, login_operazione)
select distinct doc.doc_id, subdoc.subdoc_id, (select pccop_tipo_id
								from siac_d_pcc_operazione_tipo op
                                where op.ente_proprietario_id=p_ente_prop_id
                                	and op.pccop_tipo_code='CO'
                                    and op.data_cancellazione IS NULL),
	now(), now(), p_ente_prop_id, codice_report                                    
from siac_t_doc doc,
	siac_t_subdoc subdoc,
	siac_t_subdoc_sospensione sosp 
where doc.doc_id=subdoc.doc_id
and subdoc.subdoc_id=sosp.subdoc_id
and doc.ente_proprietario_id=p_ente_prop_id
and subdoc.data_cancellazione is null
and doc.data_cancellazione is null
and sosp.data_cancellazione is null
and sosp.subdoc_sosp_data_riattivazione is null
and subdoc.subdoc_id not in (select a.subdoc_id
							 from  siac_t_registro_pcc a);

	
    --dati dell'account.
SELECT distinct soggetto.codice_fiscale
    INTO cod_fisc
FROM siac_t_account acc,
    siac_r_soggetto_ruolo sog_ruolo,
    siac_t_soggetto soggetto
where sog_ruolo.soggeto_ruolo_id=acc.soggeto_ruolo_id
  and sog_ruolo.soggetto_id=soggetto.soggetto_id
  and acc.ente_proprietario_id=p_ente_prop_id
  and acc.account_code=p_utente
  and soggetto.data_cancellazione IS NULL
  and sog_ruolo.data_cancellazione IS NULL
  and acc.data_cancellazione IS NULL;
 IF NOT FOUND THEN
      cod_fisc='';
 END IF;
     
-- i capitoli sono caricati su una tabella d'appoggio perche' se la
-- query e' lasciata in quella principale rallenta troppo la 
-- procedura.
insert into siac_rep_cap_ug 
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroagg_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
         ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and			
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
    capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and               
    capitolo.ente_proprietario_id=p_ente_prop_id						and
    programma_tipo.classif_tipo_code='PROGRAMMA' 						and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'	and
    --20/07/2017: devo estrarre tutti i capitoli, perche'' possono esserci capitoli
    --   di anni di bilancio precedenti.
   	--anno_eserc.anno= p_anno 												and
    tipo_elemento.elem_tipo_code in('CAP-UG','CAP-UP')		     			and     
	stato_capitolo.elem_stato_code	=	'VA'								and    
	cat_del_capitolo.elem_cat_code	=	'STD'							
    and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
	and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
    and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
    and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
    and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
    and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
    and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
    and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
    and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
    and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
    and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
    and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
    and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;
        
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati Dati del Registro PCC ';
     
sql_query='
with strutt as (select * from 
		"fnc_bilr_struttura_cap_bilancio_spese"('||p_ente_prop_id||', '''||p_anno||''', '''')),
 capitoli as (select *
 			  from siac_rep_cap_ug
              where ente_proprietario_id='||p_ente_prop_id||'
              	and utente='''||user_table||'''), 
cup_doc as (SELECT a.subdoc_id, 
            COALESCE(a.testo,'''') cup_desc_doc
      from siac_r_subdoc_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.ente_proprietario_id='||p_ente_prop_id||'
          and upper(b.attr_code) in(''CUP'') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL), 
cig_doc as (SELECT a.subdoc_id, 
            COALESCE(a.testo,'''') cig_desc_doc
      from siac_r_subdoc_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.ente_proprietario_id='||p_ente_prop_id||'
          and upper(b.attr_code) in(''CIG'') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL),
cup_impegno as (SELECT a.movgest_ts_id, 
            COALESCE(a.testo,'''') cup_desc_imp
      from siac_r_movgest_ts_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.ente_proprietario_id='||p_ente_prop_id||'
          and upper(b.attr_code) in(''CUP'') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL),           
cig_impegno as (SELECT a.movgest_ts_id, 
            COALESCE(a.testo,'''') cig_desc_imp
      from siac_r_movgest_ts_attr a,
          siac_t_attr b
      where a.attr_id=b.attr_id
          and a.ente_proprietario_id='||p_ente_prop_id||'
          and upper(b.attr_code) in(''CIG'') 
          and a.data_cancellazione IS NULL
          and b.data_cancellazione IS NULL)                           
select t_ente.codice_fiscale cod_fisc_ente_dest, 
	t_ente.ente_denominazione,
	d_pcc_codice.pcccod_code cod_ufficio, d_pcc_codice.pcccod_desc,
    d_pcc_oper_tipo.pccop_tipo_code cod_tipo_operazione,
    d_pcc_oper_tipo.pccop_tipo_desc desc_tipo_operazione,
    d_pcc_debito_stato.pccdeb_stato_code cod_debito, 
    d_pcc_debito_stato.pccdeb_stato_desc desc_debito,
    d_pcc_causale.pcccau_code cod_causale_pcc,
    d_pcc_causale.pcccau_desc desc_causale_pcc, 
    t_doc.doc_numero identificativo2, 
    t_doc.doc_data_emissione data_emissione,
    t_doc.doc_importo importo_totale_doc,t_doc.data_creazione data_emissione_imp,
    t_doc.doc_id,t_registro_pcc.rpcc_id,t_subdoc.subdoc_id,
    t_subdoc.subdoc_numero, t_subdoc.subdoc_importo importo_quota,
    replace (replace (t_subdoc.subdoc_desc,chr(10),'' ''),chr(13),'''') desc_quota, 
    t_registro_pcc.rpcc_quietanza_importo importo_quietanza,
    t_registro_pcc.ordinativo_numero, t_registro_pcc.ordinativo_data_emissione,
    t_registro_pcc.data_scadenza,
    cap.elem_code num_capitolo, cap.elem_code2 num_articolo, 
    cap.elem_code3 ueb, cap.bil_anno,
    movimento.movgest_anno anno_impegno,    
    movimento.movgest_numero numero_impegno, movimento.movgest_ts_id,
    cap.elem_id, soggetto_doc.soggetto_code, soggetto_doc.soggetto_desc,
    soggetto_doc.codice_fiscale, soggetto_doc.partita_iva,
    t_sog_pcc.codice_fiscale cod_fisc_ordinativo, 
    t_sog_pcc.partita_iva piva_ordinativo, movimento.movgest_id,
    t_registro_pcc.rpcc_registrazione_data,
    COALESCE(strutt.titusc_code,'''') titolo_code, 
    COALESCE(strutt.titusc_desc,'''') titolo_desc,
    cig_doc.cig_desc_doc,  cup_doc.cup_desc_doc,
    cig_impegno.cig_desc_imp,  cup_impegno.cup_desc_imp    
from siac_t_registro_pcc t_registro_pcc 
	LEFT JOIN siac_d_pcc_debito_stato d_pcc_debito_stato
    	ON (d_pcc_debito_stato.pccdeb_stato_id=t_registro_pcc.pccdeb_stato_id
        	AND d_pcc_debito_stato.data_cancellazione IS NULL)
    LEFT JOIN siac_d_pcc_causale 	d_pcc_causale
    	ON (d_pcc_causale.pcccau_id=t_registro_pcc.pcccau_id
        	AND d_pcc_causale.data_cancellazione IS NULL)
    LEFT JOIN siac_t_soggetto t_sog_pcc
    	ON (t_sog_pcc.soggetto_id=t_registro_pcc.soggetto_id
        	AND t_sog_pcc.data_cancellazione IS NULL),
	siac_t_ente_proprietario t_ente,    
    siac_d_pcc_codice d_pcc_codice,
    siac_d_pcc_operazione_tipo d_pcc_oper_tipo,
    siac_t_doc t_doc
    LEFT JOIN (select r_doc_sog.doc_id, t_soggetto.codice_fiscale,
    				t_soggetto.partita_iva, t_soggetto.soggetto_code,
                    t_soggetto.soggetto_desc
    			from siac_r_doc_sog r_doc_sog,
                	siac_t_soggetto t_soggetto
                where t_soggetto.soggetto_id= r_doc_sog.soggetto_id
                	AND r_doc_sog.ente_proprietario_id='||p_ente_prop_id||'
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND t_soggetto.data_cancellazione IS NULL) soggetto_doc        
    	ON soggetto_doc.doc_id=t_doc.doc_id,
    siac_t_subdoc t_subdoc    	
    LEFT JOIN cup_doc
    	on cup_doc.subdoc_id=t_subdoc.subdoc_id
    LEFT JOIN cig_doc
    	on cig_doc.subdoc_id=t_subdoc.subdoc_id
    LEFT JOIN  (select r_subdoc_movgest_ts.subdoc_id, t_movgest_ts.movgest_ts_id,
    				t_movgest.movgest_id, t_movgest.movgest_anno, t_movgest.movgest_numero,
                    r_movgest_bil_elem.elem_id
    			from siac_r_subdoc_movgest_ts r_subdoc_movgest_ts,
                	siac_t_movgest_ts t_movgest_ts,
                    siac_t_movgest t_movgest,
                    siac_r_movgest_bil_elem r_movgest_bil_elem
                where t_movgest_ts.movgest_ts_id= r_subdoc_movgest_ts.movgest_ts_id
                	AND t_movgest.movgest_id= t_movgest_ts.movgest_id
                    AND r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
                    AND r_subdoc_movgest_ts.ente_proprietario_id='||p_ente_prop_id||'
                    AND r_subdoc_movgest_ts.data_cancellazione IS NULL
        			AND t_movgest_ts.data_cancellazione IS NULL
        			AND t_movgest_ts.data_cancellazione IS NULL
                    AND r_movgest_bil_elem.data_cancellazione IS NULL) movimento                    
    	ON movimento.subdoc_id=t_subdoc.subdoc_id      
    LEFT JOIN cup_impegno
    	on cup_impegno.movgest_ts_id=movimento.movgest_ts_id
    LEFT JOIN cig_impegno
    	on cig_impegno.movgest_ts_id=movimento.movgest_ts_id          
    LEFT JOIN capitoli cap
        ON cap.elem_id=movimento.elem_id
    LEFT JOIN strutt
    	ON (strutt.programma_id = cap.programma_id    
      		and	strutt.macroag_id	= cap.macroaggregato_id )        
where t_ente.ente_proprietario_id=t_registro_pcc.ente_proprietario_id
	AND t_doc.doc_id=t_registro_pcc.doc_id
    AND t_subdoc.subdoc_id=t_registro_pcc.subdoc_id
    AND d_pcc_codice.pcccod_id=t_doc.pcccod_id
    AND d_pcc_oper_tipo.pccop_tipo_id=t_registro_pcc.pccop_tipo_id
	AND t_ente.ente_proprietario_id='||p_ente_prop_id||'
    	/* devo estrarre solo il tipo CO */ 
    AND d_pcc_oper_tipo.pccop_tipo_code=''CO''
    AND t_registro_pcc.login_operazione like '''||codice_report||'%''
    AND t_doc.data_cancellazione IS NULL
    AND t_subdoc.data_cancellazione IS NULL
    AND t_registro_pcc.data_cancellazione IS NULL
    AND t_ente.data_cancellazione IS NULL
    AND d_pcc_oper_tipo.data_cancellazione IS NULL '; 
 	if eseguiEstrOld = true THEN
    	sql_query=sql_query|| ' AND date_trunc(''day'',t_registro_pcc.rpcc_registrazione_data) between '''||p_data_reg_da||''' and '''||p_data_reg_a||''' ';
    ELSE
    	sql_query=sql_query|| ' AND t_registro_pcc.rpcc_registrazione_data IS NULL ';
    end if;
    --AND to_char (t_registro_pcc.rpcc_registrazione_data,''dd/mm/yyyy'')=''05/08/2016''
sql_query=sql_query|| ' ORDER BY t_doc.doc_data_emissione, t_doc.doc_numero, t_subdoc.subdoc_numero';

      
raise notice 'sql_query = %', sql_query;

for elencoRegistriRec IN
	execute sql_query 
loop
	nome_ente=elencoRegistriRec.ente_denominazione;
    bil_anno=elencoRegistriRec.BIL_ANNO;
	cod_fisc_utente_collegato=cod_fisc;
    
    cod_fisc_ente_dest=elencoRegistriRec.cod_fisc_ente_dest;
    cod_ufficio=elencoRegistriRec.cod_ufficio;
    cod_fiscale_fornitore=COALESCE(elencoRegistriRec.codice_fiscale,'');
    piva_fornitore=COALESCE(elencoRegistriRec.partita_iva,'');
    cod_tipo_operazione=elencoRegistriRec.cod_tipo_operazione;
    desc_tipo_operazione=elencoRegistriRec.desc_tipo_operazione;
    identificativo2=elencoRegistriRec.identificativo2;
    data_emissione=elencoRegistriRec.data_emissione ::DATE;
    importo_totale=elencoRegistriRec.importo_totale_doc;
    numero_quota=elencoRegistriRec.subdoc_numero;
    importo_quota=elencoRegistriRec.importo_quota;    
    anno_capitolo=elencoRegistriRec.BIL_ANNO;
    num_capitolo=COALESCE(elencoRegistriRec.num_capitolo,'');
    cod_articolo=COALESCE(elencoRegistriRec.num_articolo,'');
    ueb=COALESCE(elencoRegistriRec.ueb,'');
    --cod_stato_debito=COALESCE(elencoRegistriRec.cod_debito,'');
  --  cod_causale_mov=COALESCE(elencoRegistriRec.cod_causale_pcc,'');
    	/* 16/03/2016: la descrizione della quota non deve superare i 100 caratteri */
    --descr_quota=elencoRegistriRec.desc_quota;
    --descr_quota=substr( COALESCE(elencoRegistriRec.desc_quota,''),1,100);
    --data_emissione_impegno=to_date(elencoRegistriRec.data_emissione_imp ::VARCHAR,'yyyy/MM/dd');
    data_emissione_impegno=elencoRegistriRec.data_emissione_imp ::DATE;
    num_impegno=elencoRegistriRec.numero_impegno;
    anno_impegno=elencoRegistriRec.anno_impegno;
    doc_id=elencoRegistriRec.doc_id;
    subdoc_id=elencoRegistriRec.subdoc_id;
    v_rpcc_id=elencoRegistriRec.rpcc_id;
    movgest_ts_id=elencoRegistriRec.movgest_ts_id;
    importo_pagato=elencoRegistriRec.importo_quietanza;
	num_ordinativo=elencoRegistriRec.ordinativo_numero;
	data_ordinativo=elencoRegistriRec.ordinativo_data_emissione;
   	cod_fiscale_ordinativo=COALESCE(elencoRegistriRec.cod_fisc_ordinativo,'');
	piva_ordinativo=COALESCE(elencoRegistriRec.piva_ordinativo,'');
--    estremi_impegno=to_date(elencoRegistriRec.data_emissione_imp ::VARCHAR,'dd/MM/yyyy') ||'-'||elencoRegistriRec.anno_impegno ::VARCHAR ||'-'||elencoRegistriRec.numero_impegno ::VARCHAR;
    estremi_impegno=to_char(elencoRegistriRec.data_emissione_imp ,'dd/mm/yyyy') ||'-'||elencoRegistriRec.anno_impegno ::VARCHAR ||'-'||elencoRegistriRec.numero_impegno ::VARCHAR;
    data_scadenza=elencoRegistriRec.data_scadenza;
	importo_quietanza=elencoRegistriRec.importo_quietanza;
    rpcc_registrazione_data:=elencoRegistriRec.rpcc_registrazione_data;
    titolo_code:=COALESCE(elencoRegistriRec.titolo_code,'');
    titolo_desc:=COALESCE(elencoRegistriRec.titolo_desc,'');
    cig_documento:=COALESCE(elencoRegistriRec.cig_desc_doc,'');
    cup_documento:=COALESCE(elencoRegistriRec.cup_desc_doc,'');
    cig_impegno:=COALESCE(elencoRegistriRec.cig_desc_imp,'');
    cup_impegno:=COALESCE(elencoRegistriRec.cup_desc_imp,'');
    
    max_data_sosp:=NULL;
    sosp_causale:='';
    tipo_contenzioso_pcc:='';
    
    select max(sosp.subdoc_sosp_data), sosp.subdoc_sosp_causale
    	into max_data_sosp, sosp_causale
    from siac_t_subdoc_sospensione sosp
    where sosp.ente_proprietario_id = p_ente_prop_id
    	and sosp.subdoc_id=elencoRegistriRec.subdoc_id
        and sosp.data_cancellazione IS NULL
        and sosp.subdoc_sosp_data_riattivazione IS NULL
    group by sosp.subdoc_sosp_causale;

raise notice'subdoc_id = % - data % - causale = %',elencoRegistriRec.subdoc_id,
	max_data_sosp, sosp_causale;
    
    --come descrizione quota metto la data di sospensione
    descr_quota:=to_char(max_data_sosp,'dd/mm/yyyy');
--raise notice 'Titolo = %',titolo_code;     
    	/* se il titolo e' 1, la natura spesa e' CO,
        	se e' 2 la natura spesa e' CA */
    if titolo_code= '1' THEN
    	natura_spesa=NATURA_SPESA_CO;
    elsif titolo_code= '2' THEN
    	natura_spesa=NATURA_SPESA_CA;
    else
        natura_spesa=NATURA_SPESA_NA;
    end if;
    
--raise notice 'natura_spesa = %',natura_spesa;      
 
cod_stato_debito:='';
cod_causale_mov:='';

--leggo dalle tabelle di configurazione specifiche di questo report
--i dati dello stato debito.
select distinct caus_deb.codice_stato_debito_pcc,
	caus_deb.descrizione_stato_debito_pcc,
    COALESCE(caus_deb.causale_pcc,'')
into cod_stato_debito, cod_causale_mov, causale_pcc
from siac_d_causale_contenzioso_pcc caus_cont,
	siac_d_causale_stato_debito_pcc caus_deb
where caus_cont.tipo_contenzioso_pcc=caus_deb.tipo_contenzioso_pcc
and caus_cont.ente_proprietario_id=p_ente_prop_id
and position(upper(caus_cont.causale_sospensione) in upper(sosp_causale))>0
and caus_deb.natura =natura_spesa
and caus_cont.data_cancellazione IS NULL
and caus_deb.data_cancellazione IS NULL;

raise notice 'sosp_causale = % - cod_causale_mov = % - cod_causale_mov % - causale_pcc = %', 
sosp_causale, cod_stato_debito, cod_causale_mov, causale_pcc;

    --aggiorno alcune delle informazioni 
update siac_t_registro_pcc
    set rpcc_esito_code='999',
        rpcc_esito_desc='Estrazione sospensioni report BILR257',
        rpcc_esito_data=now(),
        pcccau_id=(select caus.pcccau_id
                   from siac_d_pcc_causale caus
                   where caus.ente_proprietario_id=p_ente_prop_id
                    and caus.pcccau_code=COALESCE(causale_pcc,'')
                    and caus.data_cancellazione IS NULL),
        pccdeb_stato_id=(select deb.pccdeb_stato_id
                   from siac_d_pcc_debito_stato deb
                   where deb.ente_proprietario_id=p_ente_prop_id
                    and deb.pccdeb_stato_code='SOSP' --esigibilita' importo sospesa
                    and deb.data_cancellazione IS NULL)
where rpcc_id=elencoRegistriRec.rpcc_id;
      
/* e' eseguito l'aggiornamento della data registrazione in modo che i record
	siano estratti una volta sola ma solo se non e' stata richiesta la
	riestrazione dei dati */
if eseguiEstrOld = false then
  update siac_t_registro_pcc  
  set rpcc_registrazione_data = now(),
      login_operazione = login_operazione||' - '||p_utente
  where rpcc_id=elencoRegistriRec.rpcc_id;    
end if;

return next;


nome_ente='';
bil_anno='';
cod_fisc_ente_dest='';
cod_ufficio='';
cod_fiscale_fornitore=''; 
piva_fornitore='';
cod_tipo_operazione='';
desc_tipo_operazione='';
identificativo2='';
data_emissione=NULL;
importo_totale=0;
importo_quota=0;
natura_spesa='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
cod_stato_debito='';
cod_causale_mov='';
descr_quota='';
data_emissione_impegno=NULL;
num_impegno='';
anno_impegno=0;
cig_documento='';
cig_impegno='';
cup_documento='';
cup_impegno='';
doc_id=0;
subdoc_id=0;
v_rpcc_id=0;
movgest_ts_id=0;
numero_quota=0;
importo_pagato=0;
num_ordinativo =0;
data_ordinativo=NULL;
cod_fiscale_ordinativo='';
piva_ordinativo='';
estremi_impegno='';
data_scadenza=NULL;
importo_quietanza=0;
rpcc_registrazione_data:=NULL;

end loop;

delete from   siac_rep_cap_ug where utente=user_table;

raise notice 'ora: % ',clock_timestamp()::varchar;

exception
	when no_data_found THEN
		raise notice 'Dati del Registro PCC non trovati.' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'REGISTRO-PCC',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8344 - Maurizio - FINE 



--  SIAC-8408  Haitham 28.10.2021 - inizio

select fnc_dba_add_column_params ('siac_dwh_capitolo_spesa',  'codice_risorse_accantonamento',  'VARCHAR(200)');
select fnc_dba_add_column_params ('siac_dwh_capitolo_spesa',  'descrizione_risorse_accantonamento',  'VARCHAR(500)');



CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_capitolo_spesa(p_anno_bilancio character varying, p_ente_proprietario_id integer, p_data timestamp without time zone)
 RETURNS TABLE(esito character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE

  rec_elem_id record;
  rec_classif_id record;
  rec_attr record;
  rec_elem_dett record;
  -- Variabili per campi estratti dal cursore rec_elem_id
  v_ente_proprietario_id INTEGER := null;
  v_ente_denominazione VARCHAR := null;
  v_anno VARCHAR := null;
  v_fase_operativa_code VARCHAR := null;
  v_fase_operativa_desc VARCHAR := null;
  v_elem_code VARCHAR := null;
  v_elem_code2 VARCHAR := null;
  v_elem_code3 VARCHAR := null;
  v_elem_desc VARCHAR := null;
  v_elem_desc2 VARCHAR := null;
  v_elem_tipo_code VARCHAR := null;
  v_elem_tipo_desc VARCHAR := null;
  v_elem_stato_code VARCHAR := null;
  v_elem_stato_desc VARCHAR := null;
  v_elem_cat_code VARCHAR := null;
  v_elem_cat_desc VARCHAR := null;
  -- Variabili per classificatori in gerarchia
  v_codice_titolo_spesa VARCHAR;
  v_descrizione_titolo_spesa VARCHAR;
  v_codice_macroaggregato_spesa VARCHAR;
  v_descrizione_macroaggregato_spesa VARCHAR;
  v_codice_missione_spesa VARCHAR;
  v_descrizione_missione_spesa VARCHAR;
  v_codice_programma_spesa VARCHAR;
  v_descrizione_programma_spesa VARCHAR;
  v_codice_pdc_finanziario_I VARCHAR := null;
  v_descrizione_pdc_finanziario_I VARCHAR := null;
  v_codice_pdc_finanziario_II VARCHAR := null;
  v_descrizione_pdc_finanziario_II VARCHAR := null;
  v_codice_pdc_finanziario_III VARCHAR := null;
  v_descrizione_pdc_finanziario_III VARCHAR := null;
  v_codice_pdc_finanziario_IV VARCHAR := null;
  v_descrizione_pdc_finanziario_IV VARCHAR := null;
  v_codice_pdc_finanziario_V VARCHAR := null;
  v_descrizione_pdc_finanziario_V VARCHAR := null;
  v_codice_cofog_divisione VARCHAR := null;
  v_descrizione_cofog_divisione VARCHAR := null;
  v_codice_cofog_gruppo VARCHAR := null;
  v_descrizione_cofog_gruppo VARCHAR := null;
  v_codice_cdr VARCHAR := null;
  v_descrizione_cdr VARCHAR := null;
  v_codice_cdc VARCHAR := null;
  v_descrizione_cdc VARCHAR := null;
  v_codice_siope_I_spesa VARCHAR := null;
  v_descrizione_siope_I_spesa VARCHAR := null;
  v_codice_siope_II_spesa VARCHAR := null;
  v_descrizione_siope_II_spesa VARCHAR := null;
  v_codice_siope_III_spesa VARCHAR := null;
  v_descrizione_siope_III_spesa VARCHAR := null;
  -- Variabili per classificatori non in gerarchia
  v_codice_spesa_ricorrente VARCHAR := null;
  v_descrizione_spesa_ricorrente VARCHAR := null;
  v_codice_transazione_spesa_ue VARCHAR := null;
  v_descrizione_transazione_spesa_ue VARCHAR := null;
  v_codice_tipo_fondo VARCHAR := null;
  v_descrizione_tipo_fondo VARCHAR := null;
  v_codice_tipo_finanziamento VARCHAR := null;
  v_descrizione_tipo_finanziamento VARCHAR := null;
  v_codice_politiche_regionali_unitarie VARCHAR := null;
  v_descrizione_politiche_regionali_unitarie VARCHAR := null;
  v_codice_perimetro_sanitario_spesa VARCHAR := null;
  v_descrizione_perimetro_sanitario_spesa VARCHAR := null;
  v_classificatore_generico_1 VARCHAR := null;
  v_classificatore_generico_1_descrizione_valore VARCHAR := null;
  v_classificatore_generico_1_valore VARCHAR := null;
  v_classificatore_generico_2 VARCHAR := null;
  v_classificatore_generico_2_descrizione_valore VARCHAR := null;
  v_classificatore_generico_2_valore VARCHAR := null;
  v_classificatore_generico_3 VARCHAR := null;
  v_classificatore_generico_3_descrizione_valore VARCHAR := null;
  v_classificatore_generico_3_valore VARCHAR := null;
  v_classificatore_generico_4 VARCHAR := null;
  v_classificatore_generico_4_descrizione_valore VARCHAR := null;
  v_classificatore_generico_4_valore VARCHAR := null;
  v_classificatore_generico_5 VARCHAR := null;
  v_classificatore_generico_5_descrizione_valore VARCHAR := null;
  v_classificatore_generico_5_valore VARCHAR := null;
  v_classificatore_generico_6 VARCHAR := null;
  v_classificatore_generico_6_descrizione_valore VARCHAR := null;
  v_classificatore_generico_6_valore VARCHAR := null;
  v_classificatore_generico_7 VARCHAR := null;
  v_classificatore_generico_7_descrizione_valore VARCHAR := null;
  v_classificatore_generico_7_valore VARCHAR := null;
  v_classificatore_generico_8 VARCHAR := null;
  v_classificatore_generico_8_descrizione_valore VARCHAR := null;
  v_classificatore_generico_8_valore VARCHAR := null;
  v_classificatore_generico_9 VARCHAR := null;
  v_classificatore_generico_9_descrizione_valore VARCHAR := null;
  v_classificatore_generico_9_valore VARCHAR := null;
  v_classificatore_generico_10 VARCHAR := null;
  v_classificatore_generico_10_descrizione_valore VARCHAR := null;
  v_classificatore_generico_10_valore VARCHAR := null;
  v_classificatore_generico_11 VARCHAR := null;
  v_classificatore_generico_11_descrizione_valore VARCHAR := null;
  v_classificatore_generico_11_valore VARCHAR := null;
  v_classificatore_generico_12 VARCHAR := null;
  v_classificatore_generico_12_descrizione_valore VARCHAR := null;
  v_classificatore_generico_12_valore VARCHAR := null;
  v_classificatore_generico_13 VARCHAR := null;
  v_classificatore_generico_13_descrizione_valore VARCHAR := null;
  v_classificatore_generico_13_valore VARCHAR:= null;
  v_classificatore_generico_14 VARCHAR := null;
  v_classificatore_generico_14_descrizione_valore VARCHAR := null;
  v_classificatore_generico_14_valore VARCHAR := null;
  v_classificatore_generico_15 VARCHAR := null;
  v_classificatore_generico_15_descrizione_valore VARCHAR := null;
  v_classificatore_generico_15_valore VARCHAR := null;
  v_codice_risorse_accantonamento VARCHAR     := null;
  v_descrizione_risorse_accantonamento VARCHAR := null;
  -- Variabili per attributi
  v_FlagEntrateRicorrenti VARCHAR := null;
  v_FlagFunzioniDelegate VARCHAR := null;
  v_FlagImpegnabile VARCHAR := null;
  v_FlagPerMemoria VARCHAR := null;
  v_FlagRilevanteIva VARCHAR := null;
  v_FlagTrasferimentoOrganiComunitari VARCHAR := null;
  v_Note VARCHAR := null;
  -- Variabili per stipendio
  v_codice_stipendio VARCHAR := null;
  v_descrizione_stipendio VARCHAR := null;
  -- Variabili per attivita' iva
  v_codice_attivita_iva VARCHAR := null;
  v_descrizione_attivita_iva VARCHAR := null;
  -- Variabili per i campi di detaglio degli elementi
  v_massimo_impegnabile_anno1 NUMERIC := null;
  v_stanziamento_cassa_anno1 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno1  NUMERIC := null;
  v_stanziamento_anno1 NUMERIC := null;
  v_stanziamento_iniziale_anno1 NUMERIC := null;
  v_stanziamento_residuo_anno1  NUMERIC := null;
  v_flag_anno1 VARCHAR := null;
  v_massimo_impegnabile_anno2 NUMERIC := null;
  v_stanziamento_cassa_anno2 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno2 NUMERIC := null;
  v_stanziamento_anno2 NUMERIC := null;
  v_stanziamento_iniziale_anno2 NUMERIC := null;
  v_stanziamento_residuo_anno2 NUMERIC := null;
  v_flag_anno2 VARCHAR := null;
  v_massimo_impegnabile_anno3 NUMERIC := null;
  v_stanziamento_cassa_anno3 NUMERIC := null;
  v_stanziamento_cassa_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_iniziale_anno3 NUMERIC := null;
  v_stanziamento_anno3 NUMERIC := null;
  v_stanziamento_iniziale_anno3 NUMERIC := null;
  v_stanziamento_residuo_anno3 NUMERIC := null;
  v_flag_anno3 VARCHAR := null;
  -- Variabili per campi funzione
  v_disponibilita_impegnare_anno1 NUMERIC := null;
  v_disponibilita_impegnare_anno2 NUMERIC := null;
  v_disponibilita_impegnare_anno3 NUMERIC := null;
  -- Variabili utili per il caricamento
  v_classif_code VARCHAR := null;
  v_classif_desc VARCHAR := null;
  v_classif_tipo_code VARCHAR := null;
  v_classif_tipo_desc VARCHAR := null;
  v_elem_id INTEGER := null;
  v_classif_id INTEGER := null;
  v_classif_id_part INTEGER := null;
  v_classif_id_padre INTEGER := null;
  v_classif_tipo_id INTEGER := null;
  v_classif_fam_id INTEGER := null;
  v_conta_ciclo_classif INTEGER := null;
  v_anno_elem_dett INTEGER := null;
  v_anno_appo INTEGER := null;
  v_flag_attributo VARCHAR := null;
  v_bil_id INTEGER := null;

  v_fnc_result VARCHAR := null;
  --SIAC-5895
  v_bil_id_prec INTEGER:=null;
  v_anno_prec INTEGER:=null;
  v_elem_tipo_id INTEGER:=null;
  v_ex_anno VARCHAR:=null;
  v_ex_capitolo VARCHAR:= null;
  v_ex_articolo VARCHAR:=null;

v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

select fnc_siac_random_user()
into	v_user_table;

IF p_data IS NULL THEN
   p_data := now();
END IF;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_capitolo_spesa',
params,
clock_timestamp(),
v_user_table
);

select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) - '||clock_timestamp();
RETURN NEXT;

-- SIAC-5895
esito:= '  Inizio Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;
select tb.bil_id,tp.anno
into v_bil_id_prec, v_anno_prec
from siac.siac_t_periodo tp
INNER JOIN siac.siac_t_bil tb  ON tb.periodo_id = tp.periodo_id
where tp.ente_proprietario_id = p_ente_proprietario_id
and   tp.anno::integer = p_anno_bilancio::integer-1;
esito:= '  Fine Identificazione bilancio precedente - '||clock_timestamp();
RETURN NEXT;

-- SIAC-6007
esito:= '  Inizio Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;
select elem_tipo_id
into v_elem_tipo_id
from siac_d_bil_elem_tipo
where elem_tipo_code = 'CAP-UG'
and   ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine Identificazione tipo capitolo gestione - '||clock_timestamp();
RETURN NEXT;


esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_capitolo_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id
AND bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre gli elementi
FOR rec_elem_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, dbet.elem_tipo_code, dbet.elem_tipo_desc,
       dbes.elem_stato_code, dbes.elem_stato_desc, dbec.elem_cat_code, dbec.elem_cat_desc,
       tbe.elem_id, tb.bil_id
       --, tbe.elem_tipo_id COMMENTATO PER SIAC-6007
FROM siac.siac_t_bil_elem tbe
INNER JOIN siac.siac_t_bil tb ON tbe.bil_id = tb.bil_id
INNER JOIN siac.siac_t_periodo tp ON tb.periodo_id = tp.periodo_id
INNER JOIN siac.siac_t_ente_proprietario tep ON tb.ente_proprietario_id = tep.ente_proprietario_id
INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
LEFT JOIN  siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
                                               AND p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
                                               AND rbec.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
                                              AND p_data BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, p_data)
                                              AND dbec.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND dbet.elem_tipo_code in ('CAP-UG', 'CAP-UP')
AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
AND tbe.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, p_data)
AND dbet.data_cancellazione IS NULL
AND p_data BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, p_data)
AND rbes.data_cancellazione IS NULL
AND p_data BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, p_data)
AND dbes.data_cancellazione IS NULL

LOOP
v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_elem_code := null;
v_elem_code2 := null;
v_elem_code3 := null;
v_elem_desc := null;
v_elem_desc2 := null;
v_elem_tipo_code := null;
v_elem_tipo_desc := null;
v_elem_stato_code := null;
v_elem_stato_desc := null;
v_elem_cat_code := null;
v_elem_cat_desc := null;

v_elem_id := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_bil_id := null;

v_ente_proprietario_id := rec_elem_id.ente_proprietario_id;
v_ente_denominazione := rec_elem_id.ente_denominazione;
v_anno := rec_elem_id.anno;
v_elem_code := rec_elem_id.elem_code;
v_elem_code2 := rec_elem_id.elem_code2;
v_elem_code3 := rec_elem_id.elem_code3;

-- 14.02.2020 Sofia jira SIAC-7329
 --v_elem_desc := rec_elem_id.elem_desc;
v_elem_desc := translate( rec_elem_id.elem_desc,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);

/* sostuito con translate
  v_elem_desc := replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
     replace(
      replace(
       replace(
         replace(rec_elem_id.elem_desc::text,chr(1),' '),
          chr(2),' '),
          chr(3),' '),
          chr(4),' '),
          chr(5),' '),
          chr(6),' '),
          chr(6),' '),
          chr(7),' '),
          chr(8),' '),
          chr(9),' '),
          chr(10),' '),
          chr(11),' '),
          chr(12),' '),
          chr(13),' '),
          chr(14),' '),
          chr(15),' '),
          chr(16),' '),
          chr(17),' '),
          chr(18),' '),
          chr(19),' '),
          chr(20),' '),
          chr(21),' '),
          chr(22),' '),
          chr(23),' '),
          chr(24),' '),
          chr(25),' '),
          chr(26),' '),
          chr(27),' '),
          chr(28),' '),
          chr(29),' '),
          chr(30),' '),
          chr(31),' '),
          chr(126),' '),
          chr(127),' ');*/

-- 14.02.2020 Sofia jira SIAC-7329
--v_elem_desc2 := rec_elem_id.elem_desc2;

v_elem_desc2 :=
translate( rec_elem_id.elem_desc2,
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar);

/* sostituito con translate
 v_elem_desc2 := replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
    replace(
     replace(
      replace(
       replace(
         replace(rec_elem_id.elem_desc2::text,chr(1),' '),
          chr(2),' '),
          chr(3),' '),
          chr(4),' '),
          chr(5),' '),
          chr(6),' '),
          chr(6),' '),
          chr(7),' '),
          chr(8),' '),
          chr(9),' '),
          chr(10),' '),
          chr(11),' '),
          chr(12),' '),
          chr(13),' '),
          chr(14),' '),
          chr(15),' '),
          chr(16),' '),
          chr(17),' '),
          chr(18),' '),
          chr(19),' '),
          chr(20),' '),
          chr(21),' '),
          chr(22),' '),
          chr(23),' '),
          chr(24),' '),
          chr(25),' '),
          chr(26),' '),
          chr(27),' '),
          chr(28),' '),
          chr(29),' '),
          chr(30),' '),
          chr(31),' '),
          chr(126),' '),
          chr(127),' ');*/

v_elem_tipo_code := rec_elem_id.elem_tipo_code;
v_elem_tipo_desc := rec_elem_id.elem_tipo_desc;
v_elem_stato_code := rec_elem_id.elem_stato_code;
v_elem_stato_desc := rec_elem_id.elem_stato_desc;
v_elem_cat_code := rec_elem_id.elem_cat_code;
v_elem_cat_desc := rec_elem_id.elem_cat_desc;

v_elem_id := rec_elem_id.elem_id;
v_anno_appo := rec_elem_id.anno::integer;
v_bil_id := rec_elem_id.bil_id;

-- Sezione per estrarre i classificatori
v_codice_titolo_spesa := null;
v_descrizione_titolo_spesa := null;
v_codice_macroaggregato_spesa := null;
v_descrizione_macroaggregato_spesa := null;
v_codice_missione_spesa := null;
v_descrizione_missione_spesa := null;
v_codice_programma_spesa := null;
v_descrizione_programma_spesa := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_cofog_divisione := null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;
v_codice_cdr := null;
v_descrizione_cdr := null;
v_codice_cdc := null;
v_descrizione_cdc := null;
v_codice_siope_I_spesa := null;
v_descrizione_siope_I_spesa := null;
v_codice_siope_II_spesa:= null;
v_descrizione_siope_II_spesa := null;
v_codice_siope_III_spesa := null;
v_descrizione_siope_III_spesa := null;

v_codice_spesa_ricorrente := null;
v_descrizione_spesa_ricorrente := null;
v_codice_transazione_spesa_ue := null;
v_descrizione_transazione_spesa_ue := null;
v_codice_tipo_fondo := null;
v_descrizione_tipo_fondo := null;
v_codice_tipo_finanziamento := null;
v_descrizione_tipo_finanziamento := null;
v_codice_politiche_regionali_unitarie := null;
v_descrizione_politiche_regionali_unitarie := null;
v_codice_perimetro_sanitario_spesa := null;
v_descrizione_perimetro_sanitario_spesa := null;
v_classificatore_generico_1:= null;
v_classificatore_generico_1_descrizione_valore:= null;
v_classificatore_generico_1_valore:= null;
v_classificatore_generico_2:= null;
v_classificatore_generico_2_descrizione_valore:= null;
v_classificatore_generico_2_valore:= null;
v_classificatore_generico_3:= null;
v_classificatore_generico_3_descrizione_valore:= null;
v_classificatore_generico_3_valore:= null;
v_classificatore_generico_4:= null;
v_classificatore_generico_4_descrizione_valore:= null;
v_classificatore_generico_4_valore:= null;
v_classificatore_generico_5:= null;
v_classificatore_generico_5_descrizione_valore:= null;
v_classificatore_generico_5_valore:= null;
v_classificatore_generico_6:= null;
v_classificatore_generico_6_descrizione_valore:= null;
v_classificatore_generico_6_valore:= null;
v_classificatore_generico_7:= null;
v_classificatore_generico_7_descrizione_valore:= null;
v_classificatore_generico_7_valore:= null;
v_classificatore_generico_8:= null;
v_classificatore_generico_8_descrizione_valore:= null;
v_classificatore_generico_8_valore:= null;
v_classificatore_generico_9:= null;
v_classificatore_generico_9_descrizione_valore:= null;
v_classificatore_generico_9_valore:= null;
v_classificatore_generico_10:= null;
v_classificatore_generico_10_descrizione_valore:= null;
v_classificatore_generico_10_valore:= null;
v_classificatore_generico_11:= null;
v_classificatore_generico_11_descrizione_valore:= null;
v_classificatore_generico_11_valore:= null;
v_classificatore_generico_12:= null;
v_classificatore_generico_12_descrizione_valore:= null;
v_classificatore_generico_12_valore:= null;
v_classificatore_generico_13:= null;
v_classificatore_generico_13_descrizione_valore:= null;
v_classificatore_generico_13_valore:= null;
v_classificatore_generico_14:= null;
v_classificatore_generico_14_descrizione_valore:= null;
v_classificatore_generico_14_valore:= null;
v_classificatore_generico_15:= null;
v_classificatore_generico_15_descrizione_valore:= null;
v_classificatore_generico_15_valore:= null;
v_codice_risorse_accantonamento      := null;
v_descrizione_risorse_accantonamento := null;
--SIAC-5895
--v_elem_tipo_id := rec_elem_id.elem_tipo_id; COMMENTATO PER SIAC-6007
v_ex_anno :=null;
v_ex_capitolo := null;
v_ex_articolo :=null;
esito:= '  Inizio ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
-- Sezione per estrarre la fase operativa
SELECT dfo.fase_operativa_code, dfo.fase_operativa_desc
INTO v_fase_operativa_code, v_fase_operativa_desc
FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
WHERE dfo.fase_operativa_id = rbfo.fase_operativa_id
AND   rbfo.bil_id = v_bil_id
AND   p_data BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, p_data)
AND   p_data BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, p_data)
AND   rbfo.data_cancellazione IS NULL
AND   dfo.data_cancellazione IS NULL;
-- Ciclo per estrarre i classificatori relativi ad un dato elemento
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
FROM siac.siac_r_bil_elem_class rbec, siac.siac_t_class tc
WHERE tc.classif_id = rbec.classif_id
AND   rbec.elem_id = v_elem_id
AND   rbec.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

LOOP

v_classif_id :=  rec_classif_id.classif_id;
v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
v_classif_fam_id := null;

-- Estrazione per determinare se un classificatore e' in gerarchia
SELECT rcfct.classif_fam_id
INTO v_classif_fam_id
FROM siac.siac_r_class_fam_class_tipo rcfct
WHERE rcfct.classif_tipo_id = v_classif_tipo_id
AND   rcfct.data_cancellazione IS NULL
AND   p_data BETWEEN rcfct.validita_inizio AND COALESCE(rcfct.validita_fine, p_data);

-- Se il classificatore non e' in gerarchia
IF NOT FOUND THEN
  esito:= '    Inizio step classificatori non in gerarchia - '||clock_timestamp();
  return next;
  v_classif_tipo_code := null;
  v_classif_code := rec_classif_id.classif_code;
  v_classif_desc := rec_classif_id.classif_desc;

  SELECT dct.classif_tipo_code , dct.classif_tipo_desc
  INTO   v_classif_tipo_code, v_classif_tipo_desc
  FROM   siac.siac_d_class_tipo dct
  WHERE  dct.classif_tipo_id = v_classif_tipo_id
  AND    dct.data_cancellazione IS NULL
  AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'RICORRENTE_SPESA' THEN
     v_codice_spesa_ricorrente      := v_classif_code;
     v_descrizione_spesa_ricorrente := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TRANSAZIONE_UE_SPESA' THEN
     v_codice_transazione_spesa_ue      := v_classif_code;
     v_descrizione_transazione_spesa_ue := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FONDO' THEN
     v_codice_tipo_fondo      := v_classif_code;
     v_descrizione_tipo_fondo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TIPO_FINANZIAMENTO' THEN
     v_codice_tipo_finanziamento      := v_classif_code;
     v_descrizione_tipo_finanziamento := v_classif_desc;
  ELSIF v_classif_tipo_code = 'POLITICHE_REGIONALI_UNITARIE' THEN
     v_codice_politiche_regionali_unitarie      := v_classif_code;
     v_descrizione_politiche_regionali_unitarie := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_SPESA' THEN
     v_codice_perimetro_sanitario_spesa      := v_classif_code;
     v_descrizione_perimetro_sanitario_spesa := v_classif_desc;
 /* ELSIF v_classif_tipo_code = 'RISACC' THEN
     v_codice_risorse_accantonamento      := v_classif_code;
     v_descrizione_risorse_accantonamento := v_classif_desc;*/
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_1' THEN
     v_classificatore_generico_1      :=  v_classif_tipo_desc;
     v_classificatore_generico_1_descrizione_valore := v_classif_desc;
     v_classificatore_generico_1_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_2' THEN
     v_classificatore_generico_2      := v_classif_tipo_desc;
     v_classificatore_generico_2_descrizione_valore := v_classif_desc;
     v_classificatore_generico_2_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_3' THEN
     v_classificatore_generico_3      := v_classif_tipo_desc;
     v_classificatore_generico_3_descrizione_valore := v_classif_desc;
     v_classificatore_generico_3_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_4' THEN
     v_classificatore_generico_4      := v_classif_tipo_desc;
     v_classificatore_generico_4_descrizione_valore := v_classif_desc;
     v_classificatore_generico_4_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_5' THEN
     v_classificatore_generico_5    := v_classif_tipo_desc;
     v_classificatore_generico_5_descrizione_valore := v_classif_desc;
     v_classificatore_generico_5_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_6' THEN
     v_classificatore_generico_6      := v_classif_tipo_desc;
     v_classificatore_generico_6_descrizione_valore := v_classif_desc;
     v_classificatore_generico_6_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_7' THEN
     v_classificatore_generico_7      := v_classif_tipo_desc;
     v_classificatore_generico_7_descrizione_valore := v_classif_desc;
     v_classificatore_generico_7_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_8' THEN
     v_classificatore_generico_8      := v_classif_tipo_desc;
     v_classificatore_generico_8_descrizione_valore := v_classif_desc;
     v_classificatore_generico_8_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_9' THEN
     v_classificatore_generico_9      := v_classif_tipo_desc;
     v_classificatore_generico_9_descrizione_valore := v_classif_desc;
     v_classificatore_generico_9_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_10' THEN
     v_classificatore_generico_10     := v_classif_tipo_desc;
     v_classificatore_generico_10_descrizione_valore := v_classif_desc;
     v_classificatore_generico_10_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_31' THEN
     v_classificatore_generico_11    := v_classif_tipo_desc;
     v_classificatore_generico_11_descrizione_valore := v_classif_desc;
     v_classificatore_generico_11_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_32' THEN
     v_classificatore_generico_12     := v_classif_tipo_desc;
     v_classificatore_generico_12_descrizione_valore := v_classif_desc;
     v_classificatore_generico_12_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_33' THEN
     v_classificatore_generico_13      := v_classif_tipo_desc;
     v_classificatore_generico_13_descrizione_valore := v_classif_desc;
     v_classificatore_generico_13_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_34' THEN
     v_classificatore_generico_14      := v_classif_tipo_desc;
     v_classificatore_generico_14_descrizione_valore := v_classif_desc;
     v_classificatore_generico_14_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_35' THEN
     v_classificatore_generico_15      := v_classif_tipo_desc;
     v_classificatore_generico_15_descrizione_valore := v_classif_desc;
     v_classificatore_generico_15_valore      := v_classif_code;
  END IF;
  esito:= '    Fine step classificatori non in gerarchia - '||clock_timestamp();
  return next;
-- Se il classificatoree' in gerarchia
ELSE
 esito:= '    Inizio step classificatori in gerarchia - '||clock_timestamp();
 return next;
 v_conta_ciclo_classif :=0;
 v_classif_id_padre := null;

 -- Loop per RISALIRE la gerarchia di un dato classificatore
 LOOP

  v_classif_code := null;
  v_classif_desc := null;
  v_classif_id_part := null;
  v_classif_tipo_code := null;
  v_classif_tipo_desc:=null;

  IF v_conta_ciclo_classif = 0 THEN
     v_classif_id_part := v_classif_id;
  ELSE
     v_classif_id_part := v_classif_id_padre;
  END IF;

  SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code, dct.classif_tipo_desc
  INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code, v_classif_tipo_desc
  FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
  WHERE rcft.classif_id = tc.classif_id
  AND   dct.classif_tipo_id = tc.classif_tipo_id
  AND   tc.classif_id = v_classif_id_part
  AND   rcft.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   dct.data_cancellazione IS NULL
  AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
  AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF    v_classif_tipo_code = 'TITOLO_SPESA' THEN
        v_codice_titolo_spesa := v_classif_code;
        v_descrizione_titolo_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'MACROAGGREGATO' THEN
        v_codice_macroaggregato_spesa := v_classif_code;
        v_descrizione_macroaggregato_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'MISSIONE' THEN
        v_codice_missione_spesa := v_classif_code;
        v_descrizione_missione_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PROGRAMMA' THEN
        v_codice_programma_spesa := v_classif_code;
        v_descrizione_programma_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_I' THEN
        v_codice_pdc_finanziario_I := v_classif_code;
        v_descrizione_pdc_finanziario_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_II' THEN
        v_codice_pdc_finanziario_II := v_classif_code;
        v_descrizione_pdc_finanziario_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_III' THEN
        v_codice_pdc_finanziario_III := v_classif_code;
        v_descrizione_pdc_finanziario_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_IV' THEN
        v_codice_pdc_finanziario_IV := v_classif_code;
        v_descrizione_pdc_finanziario_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_V' THEN
        v_codice_pdc_finanziario_V := v_classif_code;
        v_descrizione_pdc_finanziario_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDR' THEN
        v_codice_cdr := v_classif_code;
        v_descrizione_cdr := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CDC' THEN
        v_codice_cdc := v_classif_code;
        v_descrizione_cdc := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_I' THEN
        v_codice_siope_I_spesa := v_classif_code;
        v_descrizione_siope_I_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_II' THEN
        v_codice_siope_II_spesa := v_classif_code;
        v_descrizione_siope_II_spesa := v_classif_desc;
  ELSIF v_classif_tipo_code = 'SIOPE_SPESA_III' THEN
        v_codice_siope_III_spesa := v_classif_code;
        v_descrizione_siope_III_spesa := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
 esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
 return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
 esito:= '    Inizio step attributi - '||clock_timestamp();
 return next;
v_FlagEntrateRicorrenti := null;
v_FlagFunzioniDelegate := null;
v_FlagImpegnabile := null;
v_FlagPerMemoria := null;
v_FlagRilevanteIva := null;
v_FlagTrasferimentoOrganiComunitari := null;
v_Note := null;
v_flag_attributo := null;

FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rbea.tabella_id, rbea.percentuale, rbea."boolean" true_false, rbea.numerico, rbea.testo
FROM   siac.siac_r_bil_elem_attr rbea, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rbea.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rbea.elem_id = v_elem_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rbea.validita_inizio AND COALESCE(rbea.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'FlagEntrateRicorrenti' THEN
     v_FlagEntrateRicorrenti := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagFunzioniDelegate' THEN
     v_FlagFunzioniDelegate := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagImpegnabile' THEN
     v_FlagImpegnabile := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagPerMemoria' THEN
     v_FlagPerMemoria := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagRilevanteIva' THEN
     v_FlagRilevanteIva := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagTrasferimentoOrganiComunitari' THEN
     v_FlagTrasferimentoOrganiComunitari := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Note' THEN
     v_Note := v_flag_attributo;
  END IF;

END LOOP;
esito:= '    Fine step attributi - '||clock_timestamp();
return next;
esito:= '    Inizio step stipendi - '||clock_timestamp();
return next;
-- Sezione per i dati di stipendio
v_codice_stipendio := null;
v_descrizione_stipendio := null;

SELECT dsc.stipcode_code, dsc.stipcode_desc
INTO v_codice_stipendio, v_descrizione_stipendio
FROM  siac.siac_r_bil_elem_stipendio_codice rbesc, siac.siac_d_stipendio_codice dsc
WHERE rbesc.stipcode_id = dsc.stipcode_id
AND   rbesc.elem_id = v_elem_id
AND   rbesc.data_cancellazione IS NULL
AND   dsc.data_cancellazione IS NULL
AND   p_data between rbesc.validita_inizio and coalesce(rbesc.validita_fine, p_data)
AND   p_data between dsc.validita_inizio and coalesce(dsc.validita_fine, p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step iva - '||clock_timestamp();
return next;
-- Sezione per i dati di iva
v_codice_attivita_iva := null;
v_descrizione_attivita_iva := null;

SELECT tia.ivaatt_code, tia.ivaatt_desc
INTO v_codice_attivita_iva, v_descrizione_attivita_iva
FROM siac.siac_r_bil_elem_iva_attivita rbeia, siac.siac_t_iva_attivita tia
WHERE rbeia.ivaatt_id = tia.ivaatt_id
AND   rbeia.elem_id = v_elem_id
AND   rbeia.data_cancellazione IS NULL
AND   tia.data_cancellazione IS NULL
AND   p_data between rbeia.validita_inizio and coalesce(rbeia.validita_fine,p_data)
AND   p_data between tia.validita_inizio and coalesce(tia.validita_fine,p_data);
esito:= '    Fine step stipendi - '||clock_timestamp();
return next;
esito:= '    Inizio step dettagli elementi - '||clock_timestamp();
return next;
-- Sezione per i dati di dettaglio degli elementi
v_massimo_impegnabile_anno1 := null;
v_stanziamento_cassa_anno1 := null;
v_stanziamento_cassa_iniziale_anno1 := null;
v_stanziamento_residuo_iniziale_anno1 := null;
v_stanziamento_anno1 := null;
v_stanziamento_iniziale_anno1 := null;
v_stanziamento_residuo_anno1 := null;
v_flag_anno1 := null;
v_massimo_impegnabile_anno2 := null;
v_stanziamento_cassa_anno2 := null;
v_stanziamento_cassa_iniziale_anno2 := null;
v_stanziamento_residuo_iniziale_anno2 := null;
v_stanziamento_anno2 := null;
v_stanziamento_iniziale_anno2 := null;
v_stanziamento_residuo_anno2 := null;
v_flag_anno2 := null;
v_massimo_impegnabile_anno3 := null;
v_stanziamento_cassa_anno3 := null;
v_stanziamento_cassa_iniziale_anno3 := null;
v_stanziamento_residuo_iniziale_anno3 := null;
v_stanziamento_anno3 := null;
v_stanziamento_iniziale_anno3 := null;
v_stanziamento_residuo_anno3 := null;
v_flag_anno3 := null;

v_anno_elem_dett := null;

FOR rec_elem_dett IN
SELECT dbedt.elem_det_tipo_code, tbed.elem_det_flag, tbed.elem_det_importo, tp.anno
FROM  siac.siac_t_bil_elem_det tbed, siac.siac_d_bil_elem_det_tipo dbedt, siac.siac_t_periodo tp
WHERE tbed.elem_det_tipo_id = dbedt.elem_det_tipo_id
AND   tbed.periodo_id = tp.periodo_id
AND   tbed.elem_id = v_elem_id
AND   tbed.data_cancellazione IS NULL
AND   dbedt.data_cancellazione IS NULL
AND   tp.data_cancellazione IS NULL
AND   p_data between tbed.validita_inizio and coalesce(tbed.validita_fine,p_data)
AND   p_data between dbedt.validita_inizio and coalesce(dbedt.validita_fine,p_data)
AND   p_data between tp.validita_inizio and coalesce(tp.validita_fine,p_data)

LOOP
v_anno_elem_dett := rec_elem_dett.anno::integer;
  IF v_anno_elem_dett = v_anno_appo THEN
    v_flag_anno1 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno1 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno1 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 1) THEN
    v_flag_anno2 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno2 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno2 := rec_elem_dett.elem_det_importo;
    END IF;
  ELSIF v_anno_elem_dett =  (v_anno_appo + 2) THEN
    v_flag_anno3 :=  rec_elem_dett.elem_det_flag;
  	IF rec_elem_dett.elem_det_tipo_code = 'MI' THEN
       v_massimo_impegnabile_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCA' THEN
       v_stanziamento_cassa_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SCI' THEN
       v_stanziamento_cassa_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'SRI' THEN
       v_stanziamento_residuo_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STA' THEN
       v_stanziamento_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STI' THEN
       v_stanziamento_iniziale_anno3 := rec_elem_dett.elem_det_importo;
    ELSIF rec_elem_dett.elem_det_tipo_code = 'STR' THEN
       v_stanziamento_residuo_anno3 := rec_elem_dett.elem_det_importo;
    END IF;
  END IF;
END LOOP;
esito:= '    Fine step dettagli elementi - '||clock_timestamp();
return next;
esito:= '    Inizio step dati da funzione - '||clock_timestamp();
return next;
-- Sezione per valorizzazione delle variabili per i campi di funzione
v_disponibilita_impegnare_anno1 := null;
v_disponibilita_impegnare_anno2 := null;
v_disponibilita_impegnare_anno3 := null;

IF v_elem_tipo_code = 'CAP-UG' THEN
   v_disponibilita_impegnare_anno1 := siac.fnc_siac_disponibilitaimpegnareug_anno1(v_elem_id);
   v_disponibilita_impegnare_anno2 := siac.fnc_siac_disponibilitaimpegnareug_anno2(v_elem_id);
   v_disponibilita_impegnare_anno3 := siac.fnc_siac_disponibilitaimpegnareug_anno3(v_elem_id);
END IF;
esito:= '    Fine step dati da funzione - '||clock_timestamp();
return next;

-- SIAC-5895
esito:= '    Inizio step dati ex capitolo - '||clock_timestamp();
return next;

select per.anno,elem.elem_code,elem.elem_code2
into v_ex_anno, v_ex_capitolo, v_ex_articolo
from siac_r_bil_elem_rel_tempo r_ex
, siac_t_bil_elem elem
, siac_t_bil bil
, siac_t_periodo per
where r_ex.elem_id = v_elem_id
and   r_ex.data_cancellazione is null
and   p_data between r_ex.validita_inizio and coalesce(r_ex.validita_fine,p_data)
and   elem.elem_id = r_ex.elem_id_old
and   elem.bil_id = bil.bil_id
and   bil.periodo_id = per.periodo_id;

IF NOT FOUND then
--SIAC-6007 Indipendentemente dal tipo di capitolo, sia esso di previsione o gestione,
--il capitolo ricercato e di Gestione
  select
    v_anno_prec, elem.elem_code,elem.elem_code2
    into v_ex_anno, v_ex_capitolo, v_ex_articolo
  from siac_t_bil_elem elem
  where elem.elem_code =  v_elem_code
  and   elem.elem_code2 = v_elem_code2
  and   elem.elem_code3 = v_elem_code3
  and   elem.elem_tipo_id = v_elem_tipo_id
  and   elem.bil_id = v_bil_id_prec;
END IF;

esito:= '    Fine step dati ex capitolo - '||clock_timestamp();
return next;
INSERT INTO siac.siac_dwh_capitolo_spesa
(ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
cod_tipo_capitolo,
desc_tipo_capitolo,
cod_stato_capitolo,
desc_stato_capitolo,
cod_classificazione_capitolo,
desc_classificazione_capitolo,
cod_titolo_spesa,
desc_titolo_spesa,
cod_macroaggregato_spesa,
desc_macroaggregato_spesa,
cod_missione_spesa,
desc_missione_spesa,
cod_programma_spesa,
desc_programma_spesa,
cod_pdc_finanziario_i,
desc_pdc_finanziario_i,
cod_pdc_finanziario_ii,
desc_pdc_finanziario_ii,
cod_pdc_finanziario_iii,
desc_pdc_finanziario_iii,
cod_pdc_finanziario_iv,
desc_pdc_finanziario_iv,
cod_pdc_finanziario_v,
desc_pdc_finanziario_v,
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
cod_cdr,
desc_cdr,
cod_cdc,
desc_cdc,
cod_siope_i_spesa,
desc_siope_i_spesa,
cod_siope_ii_spesa,
desc_siope_ii_spesa,
cod_siope_iii_spesa,
desc_siope_iii_spesa,
cod_spesa_ricorrente,
desc_spesa_ricorrente,
cod_transazione_spesa_ue,
desc_transazione_spesa_ue,
cod_tipo_fondo,
desc_tipo_fondo,
cod_tipo_finanziamento,
desc_tipo_finanziamento,
cod_politiche_regionali_unit,
desc_politiche_regionali_unit,
cod_perimetro_sanita_spesa,
desc_perimetro_sanita_spesa,
--codice_risorse_accantonamento,
--descrizione_risorse_accantonamento,
classificatore_1,
classificatore_1_valore,
classificatore_1_desc_valore,
classificatore_2,
classificatore_2_valore,
classificatore_2_desc_valore,
classificatore_3,
classificatore_3_valore,
classificatore_3_desc_valore,
classificatore_4,
classificatore_4_valore,
classificatore_4_desc_valore,
classificatore_5,
classificatore_5_valore,
classificatore_5_desc_valore,
classificatore_6,
classificatore_6_valore,
classificatore_6_desc_valore,
classificatore_7,
classificatore_7_valore,
classificatore_7_desc_valore,
classificatore_8,
classificatore_8_valore,
classificatore_8_desc_valore,
classificatore_9,
classificatore_9_valore,
classificatore_9_desc_valore,
classificatore_10,
classificatore_10_valore,
classificatore_10_desc_valore,
classificatore_11,
classificatore_11_valore,
classificatore_11_desc_valore,
classificatore_12,
classificatore_12_valore,
classificatore_12_desc_valore,
classificatore_13,
classificatore_13_valore,
classificatore_13_desc_valore,
classificatore_14,
classificatore_14_valore,
classificatore_14_desc_valore,
classificatore_15,
classificatore_15_valore,
classificatore_15_desc_valore,
flagentratericorrenti,
flagfunzionidelegate,
flagimpegnabile,
flagpermemoria,
flagrilevanteiva,
flag_trasf_organi_comunitari,
note,
cod_stipendio,
desc_stipendio,
cod_attivita_iva,
desc_attivita_iva,
massimo_impegnabile_anno1,
stanz_cassa_anno1,
stanz_cassa_iniziale_anno1,
stanz_residuo_iniziale_anno1,
stanz_anno1,
stanz_iniziale_anno1,
stanz_residuo_anno1,
flag_anno1,
massimo_impegnabile_anno2,
stanz_cassa_anno2,
stanz_cassa_iniziale_anno2,
stanz_residuo_iniziale_anno2,
stanz_anno2,
stanz_iniziale_anno2,
stanz_residuo_anno2,
flag_anno2,
massimo_impegnabile_anno3,
stanz_cassa_anno3,
stanz_cassa_iniziale_anno3,
stanz_residuo_iniziale_anno3,
stanz_anno3,
stanz_iniziale_anno3,
stanz_residuo_anno3,
flag_anno3,
disponibilita_impegnare_anno1,
disponibilita_impegnare_anno2,
disponibilita_impegnare_anno3
--SIAC-5895
,ex_anno
,ex_capitolo
,ex_articolo
)
VALUES (v_ente_proprietario_id,
        v_ente_denominazione,
        v_anno,
        v_fase_operativa_code,
        v_fase_operativa_desc,
        v_elem_code,
        v_elem_code2,
        v_elem_code3,
        v_elem_desc,
        v_elem_desc2,
        v_elem_tipo_code,
        v_elem_tipo_desc,
        v_elem_stato_code,
        v_elem_stato_desc,
        v_elem_cat_code,
        v_elem_cat_desc,
		v_codice_titolo_spesa,
		v_descrizione_titolo_spesa,
		v_codice_macroaggregato_spesa,
		v_descrizione_macroaggregato_spesa,
		v_codice_missione_spesa,
		v_descrizione_missione_spesa,
		v_codice_programma_spesa,
		v_descrizione_programma_spesa,
        v_codice_pdc_finanziario_I,
        v_descrizione_pdc_finanziario_I,
        v_codice_pdc_finanziario_II,
        v_descrizione_pdc_finanziario_II,
        v_codice_pdc_finanziario_III,
        v_descrizione_pdc_finanziario_III,
        v_codice_pdc_finanziario_IV,
        v_descrizione_pdc_finanziario_IV,
        v_codice_pdc_finanziario_V,
        v_descrizione_pdc_finanziario_V,
        v_codice_cofog_divisione,
        v_descrizione_cofog_divisione,
        v_codice_cofog_gruppo,
        v_descrizione_cofog_gruppo,
        v_codice_cdr,
        v_descrizione_cdr,
        v_codice_cdc,
        v_descrizione_cdc,
        v_codice_siope_I_spesa,
        v_descrizione_siope_I_spesa,
        v_codice_siope_II_spesa,
        v_descrizione_siope_II_spesa,
        v_codice_siope_III_spesa,
        v_descrizione_siope_III_spesa,
        v_codice_spesa_ricorrente,
        v_descrizione_spesa_ricorrente,
        v_codice_transazione_spesa_ue,
        v_descrizione_transazione_spesa_ue,
        v_codice_tipo_fondo,
        v_descrizione_tipo_fondo,
        v_codice_tipo_finanziamento,
        v_descrizione_tipo_finanziamento,
	    v_codice_politiche_regionali_unitarie,
	    v_descrizione_politiche_regionali_unitarie,
        v_codice_perimetro_sanitario_spesa,
        v_descrizione_perimetro_sanitario_spesa,
       -- v_codice_risorse_accantonamento,
       -- v_descrizione_risorse_accantonamento,
        v_classificatore_generico_1,
        v_classificatore_generico_1_valore,
        v_classificatore_generico_1_descrizione_valore,
        v_classificatore_generico_2,
        v_classificatore_generico_2_valore,
        v_classificatore_generico_2_descrizione_valore,
        v_classificatore_generico_3,
        v_classificatore_generico_3_valore,
        v_classificatore_generico_3_descrizione_valore,
        v_classificatore_generico_4,
        v_classificatore_generico_4_valore,
        v_classificatore_generico_4_descrizione_valore,
        v_classificatore_generico_5,
        v_classificatore_generico_5_valore,
        v_classificatore_generico_5_descrizione_valore,
        v_classificatore_generico_6,
        v_classificatore_generico_6_valore,
        v_classificatore_generico_6_descrizione_valore,
        v_classificatore_generico_7,
        v_classificatore_generico_7_valore,
        v_classificatore_generico_7_descrizione_valore,
        v_classificatore_generico_8,
        v_classificatore_generico_8_valore,
        v_classificatore_generico_8_descrizione_valore,
        v_classificatore_generico_9,
        v_classificatore_generico_9_valore,
        v_classificatore_generico_9_descrizione_valore,
        v_classificatore_generico_10,
        v_classificatore_generico_10_valore,
        v_classificatore_generico_10_descrizione_valore,
        v_classificatore_generico_11,
        v_classificatore_generico_11_valore,
        v_classificatore_generico_11_descrizione_valore,
        v_classificatore_generico_12,
        v_classificatore_generico_12_valore,
        v_classificatore_generico_12_descrizione_valore,
        v_classificatore_generico_13,
        v_classificatore_generico_13_valore,
        v_classificatore_generico_13_descrizione_valore,
        v_classificatore_generico_14,
        v_classificatore_generico_14_valore,
        v_classificatore_generico_14_descrizione_valore,
        v_classificatore_generico_15,
        v_classificatore_generico_15_valore,
        v_classificatore_generico_15_descrizione_valore,
        v_FlagEntrateRicorrenti,
		v_FlagFunzioniDelegate,
        v_FlagImpegnabile,
        v_FlagPerMemoria,
        v_FlagRilevanteIva,
        v_FlagTrasferimentoOrganiComunitari,
        v_Note,
        v_codice_stipendio,
        v_descrizione_stipendio,
        v_codice_attivita_iva,
        v_descrizione_attivita_iva,
        v_massimo_impegnabile_anno1,
        v_stanziamento_cassa_anno1,
        v_stanziamento_cassa_iniziale_anno1,
        v_stanziamento_residuo_iniziale_anno1,
        v_stanziamento_anno1,
        v_stanziamento_iniziale_anno1,
        v_stanziamento_residuo_anno1,
        v_flag_anno1,
        v_massimo_impegnabile_anno2,
        v_stanziamento_cassa_anno2,
        v_stanziamento_cassa_iniziale_anno2,
        v_stanziamento_residuo_iniziale_anno2,
        v_stanziamento_anno2,
        v_stanziamento_iniziale_anno2,
        v_stanziamento_residuo_anno2,
        v_flag_anno2,
        v_massimo_impegnabile_anno3,
        v_stanziamento_cassa_anno3,
        v_stanziamento_cassa_iniziale_anno3,
        v_stanziamento_residuo_iniziale_anno3,
        v_stanziamento_anno3,
        v_stanziamento_iniziale_anno3,
        v_stanziamento_residuo_anno3,
        v_flag_anno3,
        v_disponibilita_impegnare_anno1,
        v_disponibilita_impegnare_anno2,
        v_disponibilita_impegnare_anno3
        --SIAC-5895
        ,v_ex_anno
        ,v_ex_capitolo
        ,v_ex_articolo
       );
esito:= '  Fine ciclo elementi ('||v_elem_id||') - '||clock_timestamp();
return next;
END LOOP;
esito:= 'Fine funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;


EXCEPTION
WHEN others THEN
  esito:='Funzione carico capitoli di spesa (FNC_SIAC_DWH_CAPITOLO_SPESA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$function$
;


--  SIAC-8408  Haitham 28.10.2021 - fine


--SIAC-8304 INIZIO

DROP FUNCTION IF EXISTS siac.fnc_siac_importo_max_coll_spesa_collegata(p_det_mod_id integer, p_importo_residuo numeric);
DROP FUNCTION IF EXISTS siac.fnc_siac_importo_max_coll_spesa_collegata(p_det_mod_id integer,  p_movgest_id integer, p_importo_residuo numeric);

CREATE OR REPLACE FUNCTION siac.fnc_siac_importo_max_coll_spesa_collegata(p_det_mod_id integer, p_movgest_id integer, p_importo_residuo numeric)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_importo_vincolo numeric:= null;
    v_importo_residuo numeric:= null;
    v_importo_massimo_collegabile numeric:=null;
   	v_messaggiorisultato varchar;
begin
	
	v_importo_residuo := p_importo_residuo;
	
	--calcolo l'importo del vincolo
	select ABS(srmt.movgest_ts_importo) 
	from siac_r_movgest_ts srmt 
	join siac_t_movgest_ts stmt on srmt.movgest_ts_b_id = stmt.movgest_ts_id
	--SIAC-8304
	join siac_t_movgest_ts tmta on tmta.movgest_ts_id = srmt.movgest_ts_a_id
	join siac_d_movgest_ts_tipo tipoa on tipoa.movgest_ts_tipo_id = tmta.movgest_ts_tipo_id
	join siac_t_movgest_ts_det_mod stmtdm on stmt.movgest_ts_id = stmtdm.movgest_ts_id 
	join siac_r_modifica_stato srms on stmtdm.mod_stato_r_id = srms.mod_stato_r_id
	join siac_t_modifica stm on stm.mod_id = srms.mod_id
	where stm.mod_id = p_det_mod_id 
	and srmt.data_cancellazione is null 
	and srms.data_cancellazione is null 
	--SIAC-8304
	and tmta.data_cancellazione is null
	and tipoa.movgest_ts_tipo_code = 'T'
	and tmta.movgest_id = p_movgest_id
	into v_importo_vincolo;

--	v_messaggiorisultato := ' importo vincolo trovato per la modifica con uid: ' || p_det_mod_id || ' importo vincolo: ' || v_importo_vincolo;
--	raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;

	if v_importo_residuo <= v_importo_vincolo then
		v_importo_massimo_collegabile := v_importo_residuo;
  	else
  		v_importo_massimo_collegabile := v_importo_vincolo;
  	end if;
  
-- 	v_messaggiorisultato := ' importo massimo collegabile per la modifica con uid: ' || p_det_mod_id || ' importo massimo collegabile: ' || v_importo_massimo_collegabile;
--	raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
	
  	if v_importo_massimo_collegabile is null then
  		v_messaggiorisultato := ' Nessun importo massimo collegabile trovato per la modifica con uid: ' || p_det_mod_id;
  		raise notice '[fnc_siac_importo_max_coll_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
  		v_importo_massimo_collegabile := 0;
  	end if;
  	
  	return v_importo_massimo_collegabile;
  
END;
$function$
;

DROP FUNCTION IF EXISTS siac.fnc_siac_importi_modifica_spesa_collegata_set(p_mod_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_importi_modifica_spesa_collegata_set(p_mod_id integer, p_movgest_id integer)
 RETURNS SETOF numeric
 LANGUAGE plpgsql
AS $function$
DECLARE
   	v_importo_residuo numeric := null;
   	v_importo_max_collegabile numeric := null;
   	v_messaggiorisultato varchar := null;
BEGIN

	SELECT * FROM fnc_siac_importo_residuo_spesa_collegata(p_mod_id) INTO v_importo_residuo;

	SELECT * FROM fnc_siac_importo_max_coll_spesa_collegata(p_mod_id, p_movgest_id, v_importo_residuo) INTO v_importo_max_collegabile;
	
	v_messaggiorisultato := ' importo residuo : ' || v_importo_residuo || ', importo massimo collegabile: ' || v_importo_max_collegabile || '';
	RAISE NOTICE '[fnc_siac_importo_residuo_spesa_collegata] v_messaggiorisultato=%', v_messaggiorisultato;
	
	-- return numeric[] => [0] => v_importo_residuo, [1] => v_importo_max_collegabile
    RETURN query values (v_importo_residuo), (v_importo_max_collegabile);
    
END;
$function$
;


--siac-8304 FINE

-- SIAC-7858-FCDE - INIZIO ALL SQL

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac_d_acc_fondi_dubbia_esig_tipo
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo(
    afde_tipo_id SERIAL PRIMARY KEY,
    afde_tipo_code VARCHAR(50) NOT NULL,
    afde_tipo_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_stato
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_stato(
    afde_stato_id SERIAL PRIMARY KEY,
    afde_stato_code VARCHAR(50) NOT NULL,
    afde_stato_priorita INTEGER NOT NULL,
    afde_stato_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_stato FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo_media(
    afde_tipo_media_id SERIAL PRIMARY KEY,
    afde_tipo_media_code VARCHAR(50) NOT NULL,
    afde_tipo_media_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo_media FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media_confronto
CREATE TABLE IF NOT EXISTS siac.siac_d_acc_fondi_dubbia_esig_tipo_media_confronto(
    afde_tipo_media_conf_id SERIAL PRIMARY KEY,
    afde_tipo_media_conf_code VARCHAR(50) NOT NULL,
    afde_tipo_media_conf_desc VARCHAR(200) NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_ente_proprietario_siac_d_acc_fondi_dubbia_esig_tipo_media_confronto FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_t_acc_fondi_dubbia_esig_bil
CREATE TABLE IF NOT EXISTS siac.siac_t_acc_fondi_dubbia_esig_bil(
    afde_bil_id SERIAL PRIMARY KEY,
    bil_id INTEGER NOT NULL,
    afde_tipo_id INTEGER NOT NULL,
    afde_stato_id INTEGER NOT NULL,
    afde_bil_versione INTEGER NOT NULL,
    afde_bil_accantonamento_graduale NUMERIC,
    afde_bil_quinquennio_riferimento INTEGER,
    afde_bil_riscossione_virtuosa BOOLEAN,
    afde_bil_crediti_stralciati NUMERIC,
    afde_bil_crediti_stralciati_fcde NUMERIC,
    afde_bil_accertamenti_anni_successivi NUMERIC,
    afde_bil_accertamenti_anni_successivi_fcde NUMERIC,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_bil_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (afde_tipo_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_tipo(afde_tipo_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_stato_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (afde_stato_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_stato(afde_stato_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_t_ente_proprietario_siac_t_acc_fondi_dubbia_esig_bil FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_t_acc_fondi_dubbia_esig_bil_num
CREATE TABLE IF NOT EXISTS siac.siac_t_acc_fondi_dubbia_esig_bil_num (
    afde_bil_num_id SERIAL PRIMARY KEY,
    bil_id INTEGER NOT NULL,
    afde_tipo_id INTEGER NOT NULL,
    afde_bil_versione INTEGER NOT NULL,
    validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    validita_fine TIMESTAMP WITHOUT TIME ZONE,
    ente_proprietario_id INTEGER NOT NULL,
    data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
    login_operazione VARCHAR(200) NOT NULL,
    CONSTRAINT siac_t_bil_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (afde_tipo_id) REFERENCES siac.siac_d_acc_fondi_dubbia_esig_tipo(afde_tipo_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
    CONSTRAINT siac_t_ente_proprietario_siac_t_acc_fondi_dubbia_esig_bil_num FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
DROP INDEX IF EXISTS siac_t_acc_fondi_dubbia_esig_bil_num_uq;
CREATE UNIQUE INDEX siac_t_acc_fondi_dubbia_esig_bil_num_uq ON siac.siac_t_acc_fondi_dubbia_esig_bil_num USING btree (bil_id, afde_tipo_id) WHERE (data_cancellazione IS NULL);

-- siac_t_acc_fondi_dubbia_esig
-- Tutti i campi sono inizialmente nullable per evitare problematiche con il pregresso.
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_2', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_3', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_numeratore_4', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_2', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_3', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_denominatore_4', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_utente', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_semplice_totali', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_semplice_rapporti', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_ponderata_totali', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_ponderata_rapporti', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_media_confronto', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_note', 'TEXT');
-- SIAC-8393-8394 si aggiungono i campi dell'accantonamento per i 3 anni
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno1', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_accantonamento_anno2', 'NUMERIC');


-- Metadati
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_2_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_3_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_numeratore_4_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_2_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_3_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_denominatore_4_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_media_utente_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno1_originale', 'NUMERIC');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'acc_fde_meta_accantonamento_anno2_originale', 'NUMERIC');

-- FK
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_media_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_id', 'siac_d_acc_fondi_dubbia_esig_tipo_media', 'afde_tipo_media_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_conf_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_media_confronto_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_media_conf_id', 'siac_d_acc_fondi_dubbia_esig_tipo_media_confronto', 'afde_tipo_media_conf_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_tipo_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_d_acc_fondi_dubbia_esig_tipo_siac_t_acc_fondi_dubbia_esig', 'afde_tipo_id', 'siac_d_acc_fondi_dubbia_esig_tipo', 'afde_tipo_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'elem_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_t_bil_elem_siac_t_acc_fondi_dubbia_esig', 'elem_id', 'siac_t_bil_elem', 'elem_id');
SELECT * FROM siac.fnc_dba_add_column_params('siac_t_acc_fondi_dubbia_esig', 'afde_bil_id', 'INTEGER');
SELECT * FROM siac.fnc_dba_add_fk_constraint('siac_t_acc_fondi_dubbia_esig', 'siac_t_acc_fondi_dubbia_esig_bil_siac_t_acc_fondi_dubbia_esig', 'afde_bil_id', 'siac_t_acc_fondi_dubbia_esig_bil', 'afde_bil_id');

-- siac_d_tipo_campo
CREATE TABLE IF NOT EXISTS siac.siac_d_tipo_campo(
  tc_id SERIAL PRIMARY KEY,
  tc_code VARCHAR(250) NOT NULL,
  tc_desc VARCHAR(500) NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_t_ente_proprietario_siac_d_tipo_campo FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);
-- siac_t_visibilita
CREATE TABLE IF NOT EXISTS siac.siac_t_visibilita (
  vis_id SERIAL PRIMARY KEY,
  vis_campo VARCHAR(250) NOT NULL,
  vis_visibile BOOLEAN NOT NULL,
  tc_id INTEGER NOT NULL,
  vis_funzionalita VARCHAR(250),
  azione_id INTEGER,
  vis_default TEXT,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT siac_t_ente_proprietario_siac_t_visibilita FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
  CONSTRAINT siac_d_tipo_campo_siac_t_visibilita FOREIGN KEY (tc_id) REFERENCES siac.siac_d_tipo_campo(tc_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE,
  CONSTRAINT siac_t_azione_siac_t_visibilita FOREIGN KEY (azione_id) REFERENCES siac.siac_t_azione(azione_id) ON DELETE NO ACTION ON UPDATE NO ACTION NOT DEFERRABLE
);

-- siac_d_acc_fondi_dubbia_esig_tipo
INSERT INTO siac.siac_d_acc_fondi_dubbia_esig_tipo (afde_tipo_code, afde_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('PREVISIONE', 'Previsione'),
	('RENDICONTO', 'Rendiconto'),
	('GESTIONE', 'Gestione')
) AS tmp(code, descr)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_acc_fondi_dubbia_esig_tipo current
	WHERE current.afde_tipo_code = tmp.code
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- siac_d_acc_fondi_dubbia_esig_stato
INSERT INTO siac.siac_d_acc_fondi_dubbia_esig_stato (afde_stato_code, afde_stato_desc, afde_stato_priorita, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, tmp.priorita, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('BOZZA', 'Bozza', 1),
	('DEFINITIVA', 'Definitiva', 0)
) AS tmp(code, descr, priorita)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_acc_fondi_dubbia_esig_stato current
	WHERE current.afde_stato_code = tmp.code
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media
INSERT INTO siac.siac_d_acc_fondi_dubbia_esig_tipo_media (afde_tipo_media_code, afde_tipo_media_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('SEMP_TOT', 'Media semplice dei totali'),
	('SEMP_RAP', 'Media semplice dei rapporti'),
	('POND_TOT', 'Media ponderata dei totali'),
	('POND_RAP', 'Media ponderata dei rapporti'),
	('UTENTE', 'Media utente')
) AS tmp(code, descr)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_acc_fondi_dubbia_esig_tipo_media current
	WHERE current.afde_tipo_media_code = tmp.code
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- siac_d_acc_fondi_dubbia_esig_tipo_media_confronto
INSERT INTO siac.siac_d_acc_fondi_dubbia_esig_tipo_media_confronto (afde_tipo_media_conf_code, afde_tipo_media_conf_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('PREVISIONE', 'Previsione'),
	('GESTIONE', 'Gestione')
) AS tmp(code, descr)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_acc_fondi_dubbia_esig_tipo_media_confronto current
	WHERE current.afde_tipo_media_conf_code = tmp.code
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- siac_t_attr
INSERT INTO siac.siac_t_attr (attr_code, attr_desc, attr_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.attr_tipo_id, now(), dat.ente_proprietario_id, 'ADMIN'
FROM (VALUES
	('FlagEntrataDubbiaEsigFCDE', 'Entrata di dubbia esigibilità (FCDE)', 'B')
) AS tmp(code, descr, tipo)
JOIN siac_d_attr_tipo dat ON dat.attr_tipo_code = tmp.tipo
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_t_attr current
	WHERE current.attr_code = tmp.code
	AND current.ente_proprietario_id = dat.ente_proprietario_id
);

-- siac_d_tipo_campo
INSERT INTO siac.siac_d_tipo_campo(tc_code, tc_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
  ('NUMERIC', 'Numerico'),
  ('INTEGER', 'Intero'),
  ('TEXT', 'Testo'),
  ('BOOLEAN', 'Boolean')
) AS tmp(code, descr)
CROSS JOIN siac.siac_t_ente_proprietario tep
WHERE NOT EXISTS (
  SELECT 1
  FROM siac.siac_d_tipo_campo current
  WHERE current.tc_code = tmp.code
  AND current.ente_proprietario_id = tep.ente_proprietario_id
  AND current.data_cancellazione IS NULL
);

-- siac_t_azione
INSERT INTO siac.siac_t_azione(azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, verificauo, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dat.azione_tipo_id, dga.gruppo_azioni_id, tmp.url, tmp.verificauo, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
  ('OP-ENT-ConfStpFdceGes', 'Gestione Fondo Crediti Dubbia Esigibilità - Gestione', 'ATTIVITA_SINGOLA', 'BIL_CAP_GES', '/../siacbilapp/azioneRichiesta.do', FALSE)
) AS tmp(code, descr, tipo, gruppo, url, verificauo)
CROSS JOIN siac.siac_t_ente_proprietario tep
JOIN siac.siac_d_gruppo_azioni dga ON (dga.gruppo_azioni_code = tmp.gruppo AND dga.ente_proprietario_id = tep.ente_proprietario_id)
JOIN siac.siac_d_azione_tipo dat ON (dat.azione_tipo_code = tmp.tipo AND dat.ente_proprietario_id = tep.ente_proprietario_id)
WHERE NOT EXISTS (
  SELECT 1
  FROM siac.siac_t_azione current
  WHERE current.azione_code = tmp.code
  AND current.ente_proprietario_id = tep.ente_proprietario_id
  AND current.data_cancellazione IS NULL
);

-- siac_t_visibilita
INSERT INTO siac.siac_t_visibilita(vis_campo, vis_visibile, tc_id, vis_funzionalita, azione_id, vis_default, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.campo, tmp.visibile, dtc.tc_id, tmp.funzionalita, ta.azione_id, tmp.def, now(), tep.ente_proprietario_id, 'ADMIN'
FROM (VALUES
  ('quinquennio_riferimento', TRUE, 'INTEGER', 'FCDE_PREV', 'OP-ENT-ConfStpFdce', NULL),
  ('accantonamento_graduale', TRUE, 'NUMERIC', 'FCDE_PREV', 'OP-ENT-ConfStpFdce', NULL),
  ('riscossione_virtuosa', TRUE, 'BOOLEAN', 'FCDE_PREV', 'OP-ENT-ConfStpFdce', NULL),
  
  ('quinquennio_riferimento', TRUE, 'INTEGER', 'FCDE_REND', 'OP-ENT-ConfStpFdceRen', NULL),
  ('accantonamento_graduale', FALSE, 'NUMERIC', 'FCDE_REND', 'OP-ENT-ConfStpFdceRen', '100'),
  ('riscossione_virtuosa', FALSE, 'BOOLEAN', 'FCDE_REND', 'OP-ENT-ConfStpFdceRen', 'false'),
  
  ('quinquennio_riferimento', TRUE, 'INTEGER', 'FCDE_REND', 'OP-ENT-ConfStpFdceGes', NULL),
  ('accantonamento_graduale', FALSE, 'NUMERIC', 'FCDE_REND', 'OP-ENT-ConfStpFdceGes', '100'),
  ('riscossione_virtuosa', FALSE, 'BOOLEAN', 'FCDE_REND', 'OP-ENT-ConfStpFdceGes', 'false')
) AS tmp(campo, visibile, tipo, funzionalita, azione, def)
CROSS JOIN siac_t_ente_proprietario tep
JOIN siac_d_tipo_campo dtc ON (dtc.tc_code = tmp.tipo AND dtc.ente_proprietario_id = tep.ente_proprietario_id)
LEFT OUTER JOIN siac_t_azione ta ON (ta.azione_code = tmp.azione AND ta.ente_proprietario_id = tep.ente_proprietario_id)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_t_visibilita current
	WHERE current.vis_campo = tmp.campo
	AND current.vis_funzionalita = tmp.funzionalita
	AND current.azione_id = ta.azione_id
	AND current.ente_proprietario_id = tep.ente_proprietario_id
);

-- EXCEL PREVISIONE
DROP FUNCTION IF EXISTS siac.fnc_siac_acc_fondi_dubbia_esig_by_attr_bil(INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_by_attr_bil(p_afde_bil_id INTEGER)
	RETURNS TABLE(
		versione                 INTEGER,
		fase_attributi_bilancio  VARCHAR,
		stato_attributi_bilancio VARCHAR,
--		utente                   VARCHAR,
		data_ora_elaborazione    TIMESTAMP WITHOUT TIME ZONE,
		anni_esercizio           VARCHAR,
		riscossione_virtuosa     BOOLEAN,
		quinquennio_riferimento  VARCHAR,
		capitolo                 VARCHAR,
		articolo                 VARCHAR,
		ueb                      VARCHAR,
		titolo_entrata           VARCHAR,
		tipologia                VARCHAR,
		categoria                VARCHAR,
		sac                      VARCHAR,
		incassi_4                NUMERIC,
		accertamenti_4           NUMERIC,
		incassi_3                NUMERIC,
		accertamenti_3           NUMERIC,
		incassi_2                NUMERIC,
		accertamenti_2           NUMERIC,
		incassi_1                NUMERIC,
		accertamenti_1           NUMERIC,
		incassi_0                NUMERIC,
		accertamenti_0           NUMERIC,
		media_semplice_totali    NUMERIC,
		media_semplice_rapporti  NUMERIC,
		media_ponderata_totali   NUMERIC,
		media_ponderata_rapporti NUMERIC,
		media_utente             NUMERIC,
		percentuale_minima       NUMERIC,
		percentuale_effettiva    NUMERIC,
		stanziamento_0           NUMERIC,
		stanziamento_1           NUMERIC,
		stanziamento_2           NUMERIC,
		accantonamento_fcde_0    NUMERIC,
		accantonamento_fcde_1    NUMERIC,
		accantonamento_fcde_2    NUMERIC,
		accantonamento_graduale  NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				WHEN 'SEMP_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				WHEN 'POND_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				WHEN 'POND_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
				WHEN 'UTENTE'   THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS stanziamento_0
			, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS stanziamento_1
			, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS stanziamento_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
		stanziamento_0        := v_loop_var.stanziamento_0;
		stanziamento_1        := v_loop_var.stanziamento_1;
		stanziamento_2        := v_loop_var.stanziamento_2;
		-- /10000 perche' ho due percentuali per cui moltiplico (v_loop_var.acc_fde_media e accantonamento_graduale)
		-- SIAC-8446: arrotondo gli importi a due cifre decimali
		accantonamento_fcde_0 := ROUND(v_loop_var.stanziamento_0 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_1 := ROUND(v_loop_var.stanziamento_1 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_2 := ROUND(v_loop_var.stanziamento_2 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
		INTO
			incassi_4
			, accertamenti_4
			, incassi_3
			, accertamenti_3
			, incassi_2
			, accertamenti_2
			, incassi_1
			, accertamenti_1
			, incassi_0
			, accertamenti_0
			, media_semplice_totali
			, media_semplice_rapporti
			, media_ponderata_totali
			, media_ponderata_rapporti
			, media_utente
			, percentuale_minima
		FROM siac_t_acc_fondi_dubbia_esig
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- EXCEL GESTIONE
DROP FUNCTION IF EXISTS siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil(INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_gestione_by_attr_bil(p_afde_bil_id INTEGER)
	RETURNS TABLE(
		versione                     INTEGER,
		fase_attributi_bilancio      VARCHAR,
		stato_attributi_bilancio     VARCHAR,
--		utente                       VARCHAR,
		data_ora_elaborazione        TIMESTAMP WITHOUT TIME ZONE,
		anni_esercizio               VARCHAR,
		riscossione_virtuosa		 BOOLEAN,
		quinquennio_riferimento      VARCHAR,
		capitolo                     VARCHAR,
		articolo                     VARCHAR,
		ueb                          VARCHAR,
		titolo_entrata               VARCHAR,
		tipologia                    VARCHAR,
		categoria                    VARCHAR,
		sac                          VARCHAR,
		incasso_conto_competenza     NUMERIC,
		accertato_conto_competenza   NUMERIC,
--		stanziato                    NUMERIC,
--		max_stanziato_accertato_0    NUMERIC,
--		max_stanziato_accertato_1    NUMERIC,
--		max_stanziato_accertato_2    NUMERIC,
		percentuale_incasso_gestione NUMERIC,
		percentuale_accantonamento   NUMERIC,
		tipo_precedente              VARCHAR,
		percentuale_precedente       NUMERIC,
		percentuale_minima           NUMERIC,
		percentuale_effettiva        NUMERIC,
		stanziamento_0               NUMERIC,
		stanziamento_1               NUMERIC,
		stanziamento_2               NUMERIC,
		accantonamento_fcde_0        NUMERIC,
		accantonamento_fcde_1        NUMERIC,
		accantonamento_fcde_2        NUMERIC,
		accantonamento_graduale      NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				WHEN 'UTENTE'   THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS stanziamento_0
			, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS stanziamento_1
			, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS stanziamento_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
		stanziamento_0        := v_loop_var.stanziamento_0;
		stanziamento_1        := v_loop_var.stanziamento_1;
		stanziamento_2        := v_loop_var.stanziamento_2;
		-- /10000 perche' ho due percentuali per cui moltiplico (v_loop_var.acc_fde_media e accantonamento_graduale)
		-- SIAC-8446: arrotondo gli importi a due cifre decimali
		accantonamento_fcde_0 := ROUND(v_loop_var.stanziamento_0 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_1 := ROUND(v_loop_var.stanziamento_1 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		accantonamento_fcde_2 := ROUND(v_loop_var.stanziamento_2 * v_loop_var.acc_fde_media * accantonamento_graduale / 10000, 2);
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_desc
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_confronto
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
		INTO
			  incasso_conto_competenza
			, accertato_conto_competenza
			, percentuale_incasso_gestione
			, percentuale_accantonamento
			, tipo_precedente
			, percentuale_precedente
			, percentuale_minima
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media_confronto ON (siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.afde_tipo_media_conf_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_conf_id AND siac_d_acc_fondi_dubbia_esig_tipo_media_confronto.data_cancellazione IS NULL)
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- EXCEL RENDICONTO
DROP FUNCTION IF EXISTS siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil(INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_rendiconto_by_attr_bil(p_afde_bil_id INTEGER)
	RETURNS TABLE(
		versione                 INTEGER,
		fase_attributi_bilancio  VARCHAR,
		stato_attributi_bilancio VARCHAR,
--		utente                   VARCHAR,
		data_ora_elaborazione    TIMESTAMP WITHOUT TIME ZONE,
		anni_esercizio           VARCHAR,
		riscossione_virtuosa     BOOLEAN,
		quinquennio_riferimento  VARCHAR,
		capitolo                 VARCHAR,
		articolo                 VARCHAR,
		ueb                      VARCHAR,
		titolo_entrata           VARCHAR,
		tipologia                VARCHAR,
		categoria                VARCHAR,
		sac                      VARCHAR,
		residui_4                NUMERIC,
		incassi_conto_residui_4  NUMERIC,
		residui_3                NUMERIC,
		incassi_conto_residui_3  NUMERIC,
		residui_2                NUMERIC,
		incassi_conto_residui_2  NUMERIC,
		residui_1                NUMERIC,
		incassi_conto_residui_1  NUMERIC,
		residui_0                NUMERIC,
		incassi_conto_residui_0  NUMERIC,
		media_semplice_totali    NUMERIC,
		media_semplice_rapporti  NUMERIC,
		media_ponderata_totali   NUMERIC,
		media_ponderata_rapporti NUMERIC,
		media_utente             NUMERIC,
		percentuale_minima       NUMERIC,
		percentuale_effettiva    NUMERIC,
		residui_finali           NUMERIC,
	--	residui_finali_1         NUMERIC,
	--	residui_finali_2         NUMERIC,
		accantonamento_fcde      NUMERIC,
	--	accantonamento_fcde_1    NUMERIC,
	--	accantonamento_fcde_2    NUMERIC,
		accantonamento_graduale  NUMERIC
	) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
BEGIN
	-- Caricamento di dati per uso in CTE o trasversali sulle varie righe (per ottimizzazione query)
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
	
	FOR v_loop_var IN 
		WITH titent AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc titent_tipo_desc
				, siac_t_class.classif_id titent_id
				, siac_t_class.classif_code titent_code
				, siac_t_class.classif_desc titent_desc
				, siac_t_class.validita_inizio titent_validita_inizio
				, siac_t_class.validita_fine titent_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR titent_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno,'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NULL
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		tipologia AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc tipologia_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre titent_id
				, siac_t_class.classif_id tipologia_id
				, siac_t_class.classif_code tipologia_code
				, siac_t_class.classif_desc tipologia_desc
				, siac_t_class.validita_inizio tipologia_validita_inizio
				, siac_t_class.validita_fine tipologia_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR tipologia_code_desc
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 2
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		categoria AS (
			SELECT DISTINCT
				  siac_d_class_tipo.classif_tipo_desc categoria_tipo_desc
				, siac_r_class_fam_tree.classif_id_padre tipologia_id
				, siac_t_class.classif_id categoria_id
				, siac_t_class.classif_code categoria_code
				, siac_t_class.classif_desc categoria_desc
				, siac_t_class.validita_inizio categoria_validita_inizio
				, siac_t_class.validita_fine categoria_validita_fine
				, siac_t_class.ente_proprietario_id
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR categoria_code_desc
				, siac_r_bil_elem_class.elem_id categoria_elem_id
			FROM siac_t_class
			JOIN siac_r_class_fam_tree ON (siac_t_class.classif_id = siac_r_class_fam_tree.classif_id                            AND siac_r_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_t_class_fam_tree ON (siac_r_class_fam_tree.classif_fam_tree_id = siac_t_class_fam_tree.classif_fam_tree_id AND siac_t_class_fam_tree.data_cancellazione IS NULL)
			JOIN siac_d_class_fam      ON (siac_t_class_fam_tree.classif_fam_id = siac_d_class_fam.classif_fam_id                AND siac_d_class_fam.data_cancellazione IS NULL)
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id                      AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id                            AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_fam.classif_fam_code = '00003'
			--AND to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy') BETWEEN siac_r_class_fam_tree.validita_inizio AND COALESCE(siac_r_class_fam_tree.validita_fine, to_timestamp('31/12/' || p_anno, 'dd/mm/yyyy'))
			AND siac_r_class_fam_tree.classif_id_padre IS NOT NULL
			AND siac_r_class_fam_tree.livello = 3
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		sac AS (
			SELECT DISTINCT
				  siac_t_class.classif_code sac_code
				, siac_t_class.classif_desc sac_desc
				, (siac_t_class.classif_code || '-' || siac_t_class.classif_desc)::VARCHAR sac_code_desc
				, siac_t_class.ente_proprietario_id
				, siac_r_bil_elem_class.elem_id sac_elem_id
			FROM siac_t_class
			JOIN siac_d_class_tipo     ON (siac_d_class_tipo.classif_tipo_id = siac_t_class.classif_tipo_id AND siac_d_class_tipo.data_cancellazione IS NULL)
			JOIN siac_r_bil_elem_class ON (siac_r_bil_elem_class.classif_id = siac_t_class.classif_id       AND siac_r_bil_elem_class.data_cancellazione IS NULL)
			WHERE siac_d_class_tipo.classif_tipo_code IN ('CDC', 'CDR')
			AND siac_t_class.data_cancellazione IS NULL
			AND siac_t_class.ente_proprietario_id = v_ente_proprietario_id
		),
		comp_capitolo AS (
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_bil_elem_det.elem_det_importo impSta
				, siac_t_periodo.anno::INTEGER
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det      ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id                            AND siac_t_bil_elem_det.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det.periodo_id = siac_t_periodo.periodo_id                       AND siac_t_periodo.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem.data_cancellazione IS NULL
			AND siac_t_bil_elem.ente_proprietario_id = v_ente_proprietario_id
		),
		var_capitolo AS (
			-- TODO: aggiungere i dati delle variazioni non definitive e non annullate
			SELECT
				  siac_t_bil_elem.elem_id
				, siac_t_periodo.anno::INTEGER
				, SUM(siac_t_bil_elem_det_var.elem_det_importo) impSta
			FROM siac_t_bil_elem
			JOIN siac_t_bil_elem_det_var  ON (siac_t_bil_elem.elem_id = siac_t_bil_elem_det_var.elem_id                                           AND siac_t_bil_elem_det_var.data_cancellazione IS NULL)
			JOIN siac_d_bil_elem_det_tipo ON (siac_t_bil_elem_det_var.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id                AND siac_d_bil_elem_det_tipo.data_cancellazione IS NULL)
			JOIN siac_t_periodo           ON (siac_t_bil_elem_det_var.periodo_id = siac_t_periodo.periodo_id                                      AND siac_t_periodo.data_cancellazione IS NULL)
			JOIN siac_r_variazione_stato  ON (siac_r_variazione_stato.variazione_stato_id = siac_t_bil_elem_det_var.variazione_stato_id           AND siac_r_variazione_stato.data_cancellazione IS NULL)
			JOIN siac_d_variazione_stato  ON (siac_d_variazione_stato.variazione_stato_tipo_id = siac_r_variazione_stato.variazione_stato_tipo_id AND siac_d_variazione_stato.data_cancellazione IS NULL)
			WHERE siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
			AND siac_t_bil_elem_det_var.data_cancellazione IS NULL
			AND siac_t_bil_elem_det_var.ente_proprietario_id = v_ente_proprietario_id
			AND siac_d_variazione_stato.variazione_stato_tipo_code NOT IN ('A', 'D')
			GROUP BY siac_t_bil_elem.elem_id, siac_t_periodo.anno::INTEGER
		)
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_id AS acc_fde_id
			, siac_t_bil_elem.elem_code               AS capitolo
			, siac_t_bil_elem.elem_code2              AS articolo
			, siac_t_bil_elem.elem_code3              AS ueb
			, CASE siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_code
				WHEN 'SEMP_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				WHEN 'SEMP_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				WHEN 'POND_TOT' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				WHEN 'POND_RAP' THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
				WHEN 'UTENTE'   THEN v_componente_cento - siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
				ELSE NULL
			END                                                                      AS acc_fde_media
			, titent.titent_code_desc                                                AS titolo_entrata
			, tipologia.tipologia_code_desc                                          AS tipologia
			, categoria.categoria_code_desc                                          AS categoria
			, sac.sac_code_desc                                                      AS sac
			, COALESCE(comp_capitolo0.impSta, 0) + COALESCE(var_capitolo0.impSta, 0) AS residui_finali
			--, COALESCE(comp_capitolo1.impSta, 0) + COALESCE(var_capitolo1.impSta, 0) AS residui_finali_1
			--, COALESCE(comp_capitolo2.impSta, 0) + COALESCE(var_capitolo2.impSta, 0) AS residui_finali_2
		FROM siac_t_acc_fondi_dubbia_esig
		JOIN siac_t_bil_elem                            ON (siac_t_bil_elem.elem_id = siac_t_acc_fondi_dubbia_esig.elem_id AND siac_t_bil_elem.data_cancellazione IS NULL)
		JOIN siac_t_bil                                 ON (siac_t_bil.bil_id = siac_t_bil_elem.bil_id AND siac_t_bil.data_cancellazione IS NULL)
		JOIN siac_t_periodo                             ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
		JOIN siac_d_acc_fondi_dubbia_esig_tipo_media    ON (siac_d_acc_fondi_dubbia_esig_tipo_media.afde_tipo_media_id = siac_t_acc_fondi_dubbia_esig.afde_tipo_media_id AND siac_d_acc_fondi_dubbia_esig_tipo_media.data_cancellazione IS NULL)
		JOIN categoria                                  ON (categoria.categoria_elem_id = siac_t_bil_elem.elem_id)
		JOIN tipologia                                  ON (tipologia.tipologia_id = categoria.tipologia_id)
		JOIN titent                                     ON (tipologia.titent_id = titent.titent_id)
		JOIN sac                                        ON (sac.sac_elem_id = siac_t_bil_elem.elem_id)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo0 ON (siac_t_bil_elem.elem_id = comp_capitolo0.elem_id AND comp_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo1 ON (siac_t_bil_elem.elem_id = comp_capitolo1.elem_id AND comp_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN comp_capitolo AS comp_capitolo2 ON (siac_t_bil_elem.elem_id = comp_capitolo2.elem_id AND comp_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo0  ON (siac_t_bil_elem.elem_id = var_capitolo0.elem_id  AND var_capitolo0.anno = siac_t_periodo.anno::INTEGER)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo1  ON (siac_t_bil_elem.elem_id = var_capitolo1.elem_id  AND var_capitolo1.anno = siac_t_periodo.anno::INTEGER + 1)
		LEFT OUTER JOIN var_capitolo  AS var_capitolo2  ON (siac_t_bil_elem.elem_id = var_capitolo2.elem_id  AND var_capitolo2.anno = siac_t_periodo.anno::INTEGER + 2)
		WHERE siac_t_acc_fondi_dubbia_esig.afde_bil_id = p_afde_bil_id
		AND siac_t_acc_fondi_dubbia_esig.data_cancellazione IS NULL
		ORDER BY
			  titent.titent_code
			, tipologia.tipologia_code
			, categoria.categoria_code
			, siac_t_bil_elem.elem_code::INTEGER
			, siac_t_bil_elem.elem_code2::INTEGER
			, siac_t_bil_elem.elem_code3::INTEGER
			, siac_t_acc_fondi_dubbia_esig.acc_fde_id
	LOOP
		-- Set loop vars
		capitolo              := v_loop_var.capitolo;
		articolo              := v_loop_var.articolo;
		ueb                   := v_loop_var.ueb;
		titolo_entrata        := v_loop_var.titolo_entrata;
		tipologia             := v_loop_var.tipologia;
		categoria             := v_loop_var.categoria;
		sac                   := v_loop_var.sac;
		percentuale_effettiva := v_loop_var.acc_fde_media;
		residui_finali        := v_loop_var.residui_finali;
		--residui_finali_1      := v_loop_var.residui_finali_1;		
		--residui_finali_2      := v_loop_var.residui_finali_2;
		-- /100 perche' ho una percentuale per cui moltiplico (v_loop_var.acc_fde_media)
		accantonamento_fcde   := v_loop_var.residui_finali * v_loop_var.acc_fde_media / 100;
		--accantonamento_fcde_1 := v_loop_var.residui_finali_1 * v_loop_var.acc_fde_media / 100;
		--accantonamento_fcde_2 := v_loop_var.residui_finali_2 * v_loop_var.acc_fde_media / 100;
		
		SELECT
			  siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_4
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_3
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_2
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore_1
			, siac_t_acc_fondi_dubbia_esig.acc_fde_numeratore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_denominatore
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			, siac_t_acc_fondi_dubbia_esig.acc_fde_media_utente
			, LEAST(
				  siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_semplice_rapporti
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_totali
				, siac_t_acc_fondi_dubbia_esig.acc_fde_media_ponderata_rapporti
			)
			-- SIAC-8446 - lettura del dato da DB
			, siac_t_acc_fondi_dubbia_esig.acc_fde_accantonamento_anno
		INTO
			incassi_conto_residui_4
			, residui_4
			, incassi_conto_residui_3
			, residui_3
			, incassi_conto_residui_2
			, residui_2
			, incassi_conto_residui_1
			, residui_1
			, incassi_conto_residui_0
			, residui_0
			, media_semplice_totali
			, media_semplice_rapporti
			, media_ponderata_totali
			, media_ponderata_rapporti
			, media_utente
			, percentuale_minima
			, accantonamento_fcde
		FROM siac_t_acc_fondi_dubbia_esig
		-- WHERE clause
		WHERE siac_t_acc_fondi_dubbia_esig.acc_fde_id = v_loop_var.acc_fde_id;
		
		RETURN next;
	END LOOP;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


-- MEDI DI CONFRONTO PER LA GESTIONE
DROP FUNCTION IF EXISTS siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER);
CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER)
RETURNS SETOF VARCHAR AS 
$body$
DECLARE
    v_messaggiorisultato VARCHAR;
    v_perc_media_confronto NUMERIC;
    v_tipo_media_confronto VARCHAR;
    v_uid_capitolo_previsione INTEGER;
    v_elem_code VARCHAR;
    v_elem_code2 VARCHAR;
BEGIN

	SELECT stbe.elem_code, stbe.elem_code2 
	FROM siac_t_bil_elem stbe 
	WHERE stbe.elem_id = p_uid_elem_gestione
	AND stbe.data_cancellazione IS NULL INTO v_elem_code, v_elem_code2;

	v_messaggiorisultato := 'Ricerca per capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di GESTIONE';
	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	
    v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti precedenti di GESTIONE';
    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

    v_tipo_media_confronto := 'GESTIONE';

    SELECT COALESCE (
        -- (
        --     SELECT tafdeEquiv.perc_acc_fondi
        --     FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        --     JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        --     JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        --     JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        --     JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        --     JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        --     JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        --     WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
        --     AND tafdeEquiv.elem_id = p_uid_elem_gestione
        --     AND step.ente_proprietario_id = p_uid_ente_proprietario
        --     AND sdafdes.afde_stato_code = 'DEFINITIVA'
        --     AND tafdeEquiv.data_cancellazione IS NULL 
        --     AND tafdeEquiv.validita_fine IS NULL 
        --     ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
        -- ),
        (
            SELECT tafdeEquiv.perc_acc_fondi 
            FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
            JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
            JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
            JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
            JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
            --JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
            --JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
            WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
            AND tafdeEquiv.elem_id = p_uid_elem_gestione
            AND step.ente_proprietario_id = p_uid_ente_proprietario
            --AND sdafdes.afde_stato_code = 'BOZZA'
            AND tafdeEquiv.data_cancellazione IS NULL 
            AND tafdeEquiv.validita_fine IS NULL 
            ORDER BY stafdeb.afde_bil_versione ASC LIMIT 1
        )
    ) INTO v_perc_media_confronto;

    
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA IN GESTIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco uid del capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT stbe.elem_id
        FROM siac_t_bil_elem stbe 
        JOIN siac_t_bil stb ON stbe.bil_id = stb.bil_id 
        JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
        JOIN siac_d_bil_elem_tipo sdbet ON stbe.elem_tipo_id = sdbet.elem_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = stbe.ente_proprietario_id 
        WHERE stbe.elem_code = v_elem_code 
        AND stbe.elem_code2 = v_elem_code2
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND stp.anno = p_anno_bilancio::VARCHAR
        AND sdbet.elem_tipo_code = 'CAP-EP'
        AND stbe.data_cancellazione IS NULL INTO v_uid_capitolo_previsione;
        
        IF v_uid_capitolo_previsione IS NOT NULL THEN
            v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - UID: [' || v_uid_capitolo_previsione || '] TROVATO.';
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	    END IF;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti precedenti di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'PREVISIONE';

        SELECT COALESCE (
            (
                SELECT tafdeEquiv.perc_acc_fondi
                FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
                JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
                JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
                JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
                JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
                JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
                JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
                WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
                AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
                AND step.ente_proprietario_id = p_uid_ente_proprietario
                AND sdafdes.afde_stato_code = 'DEFINITIVA'
                AND tafdeEquiv.data_cancellazione IS NULL 
                AND tafdeEquiv.validita_fine IS NULL 
                ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
            ),
            (
                SELECT tafdeEquiv.perc_acc_fondi 
                FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
                JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
                JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
                JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
                JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
                JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
                JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
                WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
                AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
                AND step.ente_proprietario_id = p_uid_ente_proprietario
                AND sdafdes.afde_stato_code = 'BOZZA'
                AND tafdeEquiv.data_cancellazione IS NULL 
                AND tafdeEquiv.validita_fine IS NULL 
                ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1
            )
        ) INTO v_perc_media_confronto;
    
    END IF;

    IF v_perc_media_confronto IS NOT NULL THEN
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - MEDIA DI CONFRONTO: [' || v_perc_media_confronto || ' - ' || v_tipo_media_confronto || ' ]';
	ELSE 
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA';
    END IF;

    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

	-- [0, 1] => [0] percentuale incasso precedente, [1] => tipoMedia
    RETURN QUERY VALUES (v_perc_media_confronto::VARCHAR), (v_tipo_media_confronto);

    EXCEPTION
        WHEN RAISE_EXCEPTION THEN
            v_messaggiorisultato := v_messaggiorisultato || ' - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;
        WHEN others THEN
            v_messaggiorisultato := v_messaggiorisultato || ' others - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;


--SIAC-8154 - Maurizio - INIZIO 

DROP FUNCTION if exists siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita"(p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar);
DROP FUNCTION if exists siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_EELL"(p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar);
DROP FUNCTION if exists siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR170_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dettaglio"(p_ente_prop_id integer, p_anno varchar, p_anno_competenza varchar);
DROP FUNCTION if exists siac."BILR182_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dett_rend"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR183_FCDE_assestamento"(p_ente_prop_id integer, p_anno varchar);

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  residui_attivi numeric,
  residui_attivi_prec numeric,
  totale_residui_attivi numeric,
  importo_minimo_fondo numeric,
  bil_ele_code3 varchar,
  flag_cassa integer,
  accertamenti_succ numeric,
  crediti_stralciati numeric,
  fondo_dubbia_esig numeric,
  afde_bil_crediti_stralciati numeric,
  afde_bil_crediti_stralciati_fcde numeric,
  afde_bil_accertamenti_anni_successivi numeric,
  afde_bil_accertamenti_anni_successivi_fcde numeric,
  colonna_e numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
afde_bilancioId integer;
var_afde_bil_crediti_stralciati numeric;
var_afde_bil_crediti_stralciati_fcde numeric;
var_afde_bil_accertamenti_anni_successivi numeric;
var_afde_bil_accertamenti_anni_successivi_fcde numeric;
  
BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

/*
	SIAC-8154 13/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    
select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

if tipomedia is null then
   tipomedia = 'SEMPLICE';
end if;

*/

--SIAC-8154 21/07/2021
--devo leggere afde_bil_id che serve per l'accesso alla tabella 
--siac.siac_t_acc_fondi_dubbia_esig 
select 	fondi_bil.afde_bil_id, 
	COALESCE(fondi_bil.afde_bil_crediti_stralciati,0),
	COALESCE(fondi_bil.afde_bil_crediti_stralciati_fcde,0),
    COALESCE(fondi_bil.afde_bil_accertamenti_anni_successivi,0),
    COALESCE(fondi_bil.afde_bil_accertamenti_anni_successivi_fcde,0)    
	into afde_bilancioId, var_afde_bil_crediti_stralciati,
    var_afde_bil_crediti_stralciati_fcde, var_afde_bil_accertamenti_anni_successivi,
    var_afde_bil_accertamenti_anni_successivi_fcde    
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='RENDICONTO' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
--    var_afde_bil_crediti_stralciati:=100;
--    var_afde_bil_crediti_stralciati_fcde:=200;
--    var_afde_bil_accertamenti_anni_successivi:=300;
--    var_afde_bil_accertamenti_anni_successivi_fcde:=400;
    
return query
select zz.* from (
with clas as (
	select classif_tipo_desc1 titent_tipo_desc, titolo_code titent_code,
    	 titolo_desc titent_desc, titolo_validita_inizio titent_validita_inizio,
         titolo_validita_fine titent_validita_fine, 
         classif_tipo_desc2 tipologia_tipo_desc,
         tipologia_id, strutt.tipologia_code tipologia_code, 
         strutt.tipologia_desc tipologia_desc,
         tipologia_validita_inizio, tipologia_validita_fine,
         classif_tipo_desc3 categoria_tipo_desc,
         categoria_id, strutt.categoria_code categoria_code, 
         strutt.categoria_desc categoria_desc,
         categoria_validita_inizio, categoria_validita_fine,
         ente_proprietario_id
    from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
    											   p_anno,'') strutt 
),
capall as (
with
cap as (
select bil_elem.elem_id,bil_elem.elem_code,bil_elem.elem_desc,
  bil_elem.elem_code2,bil_elem.elem_desc2,bil_elem.elem_id_padre,
  bil_elem.elem_code3,class.classif_id , 
  fcde.acc_fde_denominatore,fcde.acc_fde_denominatore_1,
  fcde.acc_fde_denominatore_2,
  fcde.acc_fde_denominatore_3,fcde.acc_fde_denominatore_4,
  fcde.acc_fde_numeratore,fcde.acc_fde_numeratore_1,
  fcde.acc_fde_numeratore_2,
  fcde.acc_fde_numeratore_3,fcde.acc_fde_numeratore_4,
  case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
        COALESCE(fcde.acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(fcde.acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
        COALESCE(fcde.acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
        COALESCE(fcde.acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
        COALESCE(fcde.acc_fde_media_utente, 0)      
    end end end end end perc_media_applicata
from siac_t_bil_elem bil_elem,	
--SIAC-8154 07/10/2021.
--aggiunto legame con la tabella dell'fcde perche' si devono
--estrarre solo i capitoli coinvolti.
	 siac_t_acc_fondi_dubbia_esig fcde
     	left join siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
        	on tipo_media.afde_tipo_media_id=fcde.afde_tipo_media_id,
     siac_d_bil_elem_tipo bil_elem_tipo,
     siac_r_bil_elem_class r_bil_elem_class,
 	 siac_t_class class,	
     siac_d_class_tipo d_class_tipo,
	 siac_r_bil_elem_categoria r_bil_elem_categ,	
     siac_d_bil_elem_categoria d_bil_elem_categ, 
     siac_r_bil_elem_stato r_bil_elem_stato, 
     siac_d_bil_elem_stato d_bil_elem_stato 
where bil_elem.elem_tipo_id		 = bil_elem_tipo.elem_tipo_id 
and   r_bil_elem_class.elem_id   = bil_elem.elem_id
and   class.classif_id           = r_bil_elem_class.classif_id
and   d_class_tipo.classif_tipo_id      = class.classif_tipo_id
and   d_bil_elem_categ.elem_cat_id          = r_bil_elem_categ.elem_cat_id
and   r_bil_elem_categ.elem_id              = bil_elem.elem_id
and   r_bil_elem_stato.elem_id              = bil_elem.elem_id
and   d_bil_elem_stato.elem_stato_id        = r_bil_elem_stato.elem_stato_id
and   fcde.elem_id						= bil_elem.elem_id
and   bil_elem.ente_proprietario_id = p_ente_prop_id
and   bil_elem.bil_id               = bilancio_id
and   fcde.afde_bil_id				=  afde_bilancioId
and   bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'
and   d_class_tipo.classif_tipo_code	 = 'CATEGORIA'
and	  d_bil_elem_categ.elem_cat_code	     = 'STD'
and	  d_bil_elem_stato.elem_stato_code	     = 'VA'
and   bil_elem.data_cancellazione   is null
and	  bil_elem_tipo.data_cancellazione   is null
and	  r_bil_elem_class.data_cancellazione	 is null
and	  class.data_cancellazione	 is null
and	  d_class_tipo.data_cancellazione 	 is null
and	  r_bil_elem_categ.data_cancellazione 	 is null
and	  d_bil_elem_categ.data_cancellazione	 is null
and	  r_bil_elem_stato.data_cancellazione   is null
and	  d_bil_elem_stato.data_cancellazione   is null
and   fcde.data_cancellazione is null
), 
resatt as ( -- Residui Attivi 
select capitolo.elem_id,
       sum (dt_movimento.movgest_ts_det_importo) residui_accertamenti,
       CASE 
         WHEN movimento.movgest_anno < annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'I' THEN
            'RESATT' 
         WHEN movimento.movgest_anno = annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' THEN  
            'ACCERT' 
         ELSE
            'ALTRO'
       END tipo_importo         
from siac_t_bil_elem                  capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id 
inner join siac_d_movgest_tipo        tipo_mov on movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id 
inner join siac_r_movgest_ts_stato    r_movimento_stato on ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
inner join siac_d_movgest_stato       tipo_stato on r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id
inner join siac_t_movgest_ts_det      dt_movimento on ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
inner join siac_d_movgest_ts_tipo     ts_mov_tipo on ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id
inner join siac_d_movgest_ts_det_tipo dt_mov_tipo on dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
where capitolo.ente_proprietario_id     =   p_ente_prop_id
and   capitolo.bil_id      				=	bilancio_id
and   t_capitolo.elem_tipo_code    		= 	'CAP-EG'
and   movimento.movgest_anno 	        <= 	annoCapImp_int
and   movimento.bil_id					=	bilancio_id
and   tipo_mov.movgest_tipo_code    	=   'A' 
and   tipo_stato.movgest_stato_code     in  ('D','N')
and   ts_mov_tipo.movgest_ts_tipo_code  =   'T'
and   dt_mov_tipo.movgest_ts_det_tipo_code in ('I','A')
and   capitolo.data_cancellazione     	is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione    	is null 
and   movimento.data_cancellazione     	is null 
and   tipo_mov.data_cancellazione     	is null 
and   r_movimento_stato.data_cancellazione is null 
and   ts_movimento.data_cancellazione   is null 
and   tipo_stato.data_cancellazione    	is null 
and   dt_movimento.data_cancellazione   is null 
and   ts_mov_tipo.data_cancellazione    is null 
and   dt_mov_tipo.data_cancellazione    is null
and   now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and   now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
group by tipo_importo, capitolo.elem_id
),
resrisc as ( -- Riscossione residui
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_residui,
            CASE 
             WHEN movimento.movgest_anno < annoCapImp_int THEN
                'RISRES'
             ELSE
                'RISCOMP'
             END tipo_importo                    
from  siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
      siac_t_ordinativo				    ordinativo,
      siac_d_ordinativo_tipo			tipo_ordinativo,
      siac_r_ordinativo_stato			r_stato_ordinativo,
      siac_d_ordinativo_stato			stato_ordinativo,
      siac_t_ordinativo_ts 			    ordinativo_det,
      siac_t_ordinativo_ts_det 		    ordinativo_imp,
      siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
      siac_t_movgest     				movimento,
      siac_t_movgest_ts    			    ts_movimento, 
      siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
where r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
    and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
    and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
    and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
    and	ordinativo.ord_id					=	ordinativo_det.ord_id
    and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
    and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
    and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
    and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
    and	ts_movimento.movgest_id				=	movimento.movgest_id
    and ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
    and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
    ------------------------------------------------------------------------------------------		
    ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
    and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
    -----------------------------------------------------------------------------------------------
    and	ordinativo.bil_id					=	bilancio_id
    and movimento.bil_id					=	bilancio_id	
    and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
    and	movimento.movgest_anno				<=	annoCapImp_int	
    and	r_capitolo_ordinativo.data_cancellazione	is null
    and	ordinativo.data_cancellazione				is null
    and	tipo_ordinativo.data_cancellazione			is null
    and	r_stato_ordinativo.data_cancellazione		is null
    and	stato_ordinativo.data_cancellazione			is null
    and ordinativo_det.data_cancellazione			is null
    and ordinativo_imp.data_cancellazione			is null
    and ordinativo_imp_tipo.data_cancellazione		is null
    and	movimento.data_cancellazione				is null
    and	ts_movimento.data_cancellazione				is null
    and	r_ordinativo_movgest.data_cancellazione		is null
    and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
	and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())
group by tipo_importo, r_capitolo_ordinativo.elem_id
),
resriacc as ( -- Riaccertamenti residui
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riaccertamenti_residui
from siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
     siac_t_modifica t_modifica,
     siac_r_modifica_stato r_mod_stato,
     siac_d_modifica_stato d_mod_stato,
     siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
     where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
       and r_mov_capitolo.elem_id    		=	capitolo.elem_id
       and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
       and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
       and movimento.movgest_id      		= 	ts_movimento.movgest_id 
       and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
       and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
       and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
       and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
       and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
       and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
       and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
       and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id 
       and r_mod_stato.mod_id=t_modifica.mod_id              
       and capitolo.ente_proprietario_id   = p_ente_prop_id           
       and capitolo.bil_id      				=	bilancio_id
       and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
       and movimento.movgest_anno 	< 	annoCapImp_int
       and movimento.bil_id					=	bilancio_id
       and tipo_mov.movgest_tipo_code    	= 'A' 
       and tipo_stato.movgest_stato_code   in ('D','N')
       and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
       and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
       and d_mod_stato.mod_stato_code='V'    
       and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
       and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
       and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
       and capitolo.data_cancellazione     	is null 
       and r_mov_capitolo.data_cancellazione is null 
       and t_capitolo.data_cancellazione    	is null 
       and movimento.data_cancellazione     	is null 
       and tipo_mov.data_cancellazione     	is null 
       and r_movimento_stato.data_cancellazione   is null 
       and ts_movimento.data_cancellazione   is null 
       and tipo_stato.data_cancellazione    	is null 
       and dt_movimento.data_cancellazione   is null 
       and ts_mov_tipo.data_cancellazione    is null 
       and dt_mov_tipo.data_cancellazione    is null
       and t_movgest_ts_det_mod.data_cancellazione    is null
       and r_mod_stato.data_cancellazione    is null
       and t_modifica.data_cancellazione    is null     
     group by capitolo.elem_id	
),
/*
	SIAC-8154 13/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/      
/*
minfondo as ( -- Importo minimo del fondo
SELECT
 rbilelem.elem_id, 
 CASE 
   WHEN tipomedia = 'SEMPLICE' THEN
        round((COALESCE(datifcd.perc_acc_fondi,0)+
        COALESCE(datifcd.perc_acc_fondi_1,0)+
        COALESCE(datifcd.perc_acc_fondi_2,0)+
        COALESCE(datifcd.perc_acc_fondi_3,0)+
        COALESCE(datifcd.perc_acc_fondi_4,0))/5,2)
   ELSE
        round((COALESCE(datifcd.perc_acc_fondi,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_1,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_2,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_3,0)*0.35+
        COALESCE(datifcd.perc_acc_fondi_4,0)*0.35),2)
 END perc_media
 -- ,1 flag_cassa -- SIAC-5854
 , 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
 WHERE rbilelem.acc_fde_id = datifcd.acc_fde_id 
 AND   datifcd.ente_proprietario_id = p_ente_prop_id 
 AND   rbilelem.data_cancellazione is null
), */
minfondo as ( -- Importo minimo del fondo
SELECT
 datifcd.elem_id,   
 case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
    	COALESCE(acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
    	COALESCE(acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
    	COALESCE(acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
    	COALESCE(acc_fde_media_utente, 0)      
    end end end end end perc_media,        
 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, 
    siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
 WHERE tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
   AND datifcd.ente_proprietario_id = p_ente_prop_id 
   and datifcd.afde_bil_id  = afde_bilancioId
   AND datifcd.data_cancellazione is null
   AND tipo_media.data_cancellazione is null
),
accertcassa as ( -- Accertato per cassa -- SIAC-5854
SELECT rbea.elem_id, 0 flag_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.data_cancellazione is null
AND    ta.data_cancellazione is null
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S'
),
acc_succ as ( -- Accertamenti imputati agli esercizi successivi a quello cui il rendiconto si riferisce
select capitolo.elem_id,
       --sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
       sum (dt_movimento.movgest_ts_det_importo) accertamenti_succ
from siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo     
     where capitolo.bil_id      				=	bilancio_id
     and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id     
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and capitolo.ente_proprietario_id   = p_ente_prop_id
     and movimento.bil_id					=	bilancio_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int      
     and tipo_mov.movgest_tipo_code    	= 'A'       
     and tipo_stato.movgest_stato_code   in ('D','N')      
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'          
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now()) 
     and capitolo.data_cancellazione     	is null 
     and r_mov_capitolo.data_cancellazione is null 
     and t_capitolo.data_cancellazione    	is null 
     and movimento.data_cancellazione     	is null 
     and tipo_mov.data_cancellazione     	is null 
     and r_movimento_stato.data_cancellazione   is null 
     and ts_movimento.data_cancellazione   is null 
     and tipo_stato.data_cancellazione    	is null 
     and dt_movimento.data_cancellazione   is null 
     and ts_mov_tipo.data_cancellazione    is null 
     and dt_mov_tipo.data_cancellazione    is null     
     group by capitolo.elem_id	
),
cred_stra as ( -- Crediti stralciati
 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
    from siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 	        <= 	annoCapImp_int      
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      /*and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) */
      and d_modif_tipo.mod_tipo_code in ('CROR','ECON')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null      
group by capitolo.elem_id),
--SIAC-8154.
--Le query seguenti so no quelle utilizzate per il calcolo dei residui.
stanz_residuo_capitolo as(
  select bil_elem.elem_id, 
      sum(bil_elem_det.elem_det_importo) importo_residui   
  from siac_t_bil_elem bil_elem,	
       siac_t_acc_fondi_dubbia_esig fcde,
       siac_d_bil_elem_tipo bil_elem_tipo,
       siac_t_bil_elem_det bil_elem_det,
       siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
       siac_t_periodo per
  where bil_elem.elem_id = fcde.elem_id
  and bil_elem.elem_tipo_id = bil_elem_tipo.elem_tipo_id
  and bil_elem.elem_id=bil_elem_det.elem_id
  and bil_elem_det.elem_det_tipo_id=d_bil_elem_det_tipo.elem_det_tipo_id
  and per.periodo_id=bil_elem_det.periodo_id
  and bil_elem.ente_proprietario_id= p_ente_prop_id
  and fcde.afde_bil_id				=  afde_bilancioId
  and bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'    
  and d_bil_elem_det_tipo.elem_det_tipo_code='STR'
  and per.anno			= p_anno
  and bil_elem.data_cancellazione IS NULL
  and fcde.data_cancellazione IS NULL
  and bil_elem_tipo.data_cancellazione IS NULL
  and bil_elem_det.data_cancellazione IS NULL
  and d_bil_elem_det_tipo.data_cancellazione IS NULL  
  and bil_elem_det.validita_inizio < CURRENT_TIMESTAMP
  and (bil_elem_det.validita_fine IS NULL OR
       bil_elem_det.validita_fine > CURRENT_TIMESTAMP)
  group by bil_elem.elem_id),
stanz_residuo_capitolo_mod as (
  select bil_elem.elem_id, 
  sum(bil_elem_det_var.elem_det_importo) importo_residui_mod    
  from siac_t_bil_elem bil_elem,	
       siac_t_acc_fondi_dubbia_esig fcde,
       siac_d_bil_elem_tipo bil_elem_tipo,
       siac_t_bil_elem_det bil_elem_det,
       siac_d_bil_elem_det_tipo d_bil_elem_det_tipo,
       siac_t_periodo per,
       siac_t_bil_elem_det_var bil_elem_det_var,
       siac_r_variazione_stato r_var_stato,
       siac_d_variazione_stato d_var_stato
  where bil_elem.elem_id = fcde.elem_id
  and bil_elem.elem_tipo_id = bil_elem_tipo.elem_tipo_id
  and bil_elem.elem_id=bil_elem_det.elem_id
  and bil_elem_det.elem_det_tipo_id=d_bil_elem_det_tipo.elem_det_tipo_id
  and per.periodo_id=bil_elem_det.periodo_id
  and bil_elem_det_var.elem_det_id=bil_elem_det.elem_det_id
  and bil_elem_det_var.variazione_stato_id=r_var_stato.variazione_stato_id
  and r_var_stato.variazione_stato_tipo_id=d_var_stato.variazione_stato_tipo_id
  and bil_elem.ente_proprietario_id= p_ente_prop_id
  and fcde.afde_bil_id				=  afde_bilancioId
  and bil_elem_tipo.elem_tipo_code 	     = 'CAP-EG'    
  and d_bil_elem_det_tipo.elem_det_tipo_code='STR'
  and per.anno 						= p_anno
  and d_var_stato.variazione_stato_tipo_code not in ('A','D')
  and bil_elem.data_cancellazione IS NULL
  and fcde.data_cancellazione IS NULL
  and bil_elem_tipo.data_cancellazione IS NULL
  and bil_elem_det.data_cancellazione IS NULL
  and bil_elem_det_var.data_cancellazione IS NULL
  and r_var_stato.data_cancellazione IS NULL
  and d_var_stato.data_cancellazione IS NULL
  and d_bil_elem_det_tipo.data_cancellazione IS NULL  
  and bil_elem_det.validita_inizio < CURRENT_TIMESTAMP
  and (bil_elem_det.validita_fine IS NULL OR
       bil_elem_det.validita_fine > CURRENT_TIMESTAMP)
  group by bil_elem.elem_id)
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.classif_id categoria_id,
coalesce(resatt1.residui_accertamenti,0) residui_attivi,
--SIAC-8154 07/10/2021.
--i residui dell'anno precedente devono essere presi dalla tabella
--dell'fcde.
/*
(coalesce(resatt1.residui_accertamenti,0) -
	coalesce(resrisc1.importo_residui,0) +
	coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,*/
(+COALESCE(cap.acc_fde_denominatore,0)+
COALESCE(cap.acc_fde_denominatore_1,0)+COALESCE(cap.acc_fde_denominatore_2,0)+
COALESCE(cap.acc_fde_denominatore_3,0)+COALESCE(cap.acc_fde_denominatore_4,0))residui_attivi_prec,           
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
--(coalesce(resatt2.residui_accertamenti,0) -
-- coalesce(resrisc2.importo_residui,0)) importo_finale
coalesce(stanz_residuo_capitolo.importo_residui,0) importo_residui,
COALESCE(stanz_residuo_capitolo_mod.importo_residui_mod,0) importo_residui_mod,
cap.perc_media_applicata
from cap
left join resatt resatt1
	on cap.elem_id=resatt1.elem_id and resatt1.tipo_importo = 'RESATT'
left join resatt resatt2
	on cap.elem_id=resatt2.elem_id and resatt2.tipo_importo = 'ACCERT'
left join resrisc resrisc1
	on cap.elem_id=resrisc1.elem_id and resrisc1.tipo_importo = 'RISRES'
left join resrisc resrisc2
	on cap.elem_id=resrisc2.elem_id and resrisc2.tipo_importo = 'RISCOMP'
left join resriacc
	on cap.elem_id=resriacc.elem_id
left join minfondo
	on cap.elem_id=minfondo.elem_id
left join accertcassa
	on cap.elem_id=accertcassa.elem_id
left join acc_succ
	on cap.elem_id=acc_succ.elem_id
left join cred_stra
	on cap.elem_id=cred_stra.elem_id
left join stanz_residuo_capitolo
	on cap.elem_id=stanz_residuo_capitolo.elem_id
left join stanz_residuo_capitolo_mod
	on cap.elem_id=stanz_residuo_capitolo_mod.elem_id
),
fondo_dubbia_esig as (
select  importi.repimp_desc programma_code,
        coalesce(importi.repimp_importo,0) imp_fondo_dubbia_esig
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
		siac_t_bil 						bilancio,
	 	siac_t_periodo 					anno_eserc,
        siac_t_periodo 					anno_comp
where   bilancio.periodo_id				=	anno_eserc.periodo_id 		
and     importi.bil_id					=	bilancio.bil_id 			
and     r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id			
and     importi.periodo_id 				=	anno_comp.periodo_id
   				
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		anno_eserc.anno					=	p_anno 						
and 	report.rep_codice				=	'BILR148'
  --24/05/2021 SIAC-8212.
  --Cambiato il codice che identifica le variabili per aggiungere una nota utile
  --all'utente per la compilazione degli importi.
  --and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
and 	importi.repimp_codice like 'Colonna E Allegato c) FCDE Rendiconto%'
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_eserc.data_cancellazione is null
and     anno_comp.data_cancellazione is null
and     importi.repimp_desc <> ''
)
select 
p_anno::varchar bil_anno,
''::varchar titent_tipo_code,
clas.titent_tipo_desc::varchar,
clas.titent_code::varchar,
clas.titent_desc::varchar,
''::varchar tipologia_tipo_code,
clas.tipologia_tipo_desc::varchar,
clas.tipologia_code::varchar,
clas.tipologia_desc::varchar,
''::varchar	categoria_tipo_code,
clas.categoria_tipo_desc::varchar,
clas.categoria_code::varchar,
clas.categoria_desc::varchar,
capall.bil_ele_code::varchar,
capall.bil_ele_desc::varchar,
capall.bil_ele_code2::varchar,
capall.bil_ele_desc2::varchar,
capall.bil_ele_id::integer,
capall.bil_ele_id_padre::integer,
COALESCE(capall.importo_residui::numeric,0) + 
	COALESCE(capall.importo_residui_mod::numeric,0) residui_attivi,
COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
COALESCE(capall.importo_residui::numeric + capall.importo_residui_mod +
 capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_residui::numeric + 
  capall.importo_residui_mod::numeric +
  capall.residui_attivi_prec::numeric) * (1 - perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig,
var_afde_bil_crediti_stralciati,
var_afde_bil_crediti_stralciati_fcde,
var_afde_bil_accertamenti_anni_successivi,
var_afde_bil_accertamenti_anni_successivi_fcde,
(COALESCE(capall.importo_residui::numeric,0) + 
	COALESCE(capall.importo_residui_mod::numeric,0)) * 
    (100 - capall.perc_media_applicata) / 100
from clas 
	left join capall on clas.categoria_id = capall.categoria_id  
	left join fondo_dubbia_esig on fondo_dubbia_esig.programma_code = clas.tipologia_code   
) as zz;

/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/

    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR182_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dett_rend" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  residui_attivi numeric,
  residui_attivi_prec numeric,
  totale_residui_attivi numeric,
  importo_minimo_fondo numeric,
  bil_ele_code3 varchar,
  flag_cassa integer,
  accertamenti_succ numeric,
  crediti_stralciati numeric,
  fondo_dubbia_esig numeric,
  perc_media numeric,
  perc_complementare numeric
) AS
$body$
DECLARE

classifBilRec record;
bilancio_id integer;
annoCapImp_int integer;
tipomedia varchar;
RTN_MESSAGGIO text;
afde_bilancioId integer;

BEGIN
RTN_MESSAGGIO:='select 1';

annoCapImp_int:= p_anno::integer; 

select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id and 
b.periodo_id=a.periodo_id
and b.anno=p_anno;

/*
	SIAC-8154 15/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    
select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

if tipomedia is null then
   tipomedia = 'SEMPLICE';
end if;

*/

--SIAC-8154 21/07/2021
--devo leggere afde_bil_id che serve per l'accesso alla tabella 
--siac.siac_t_acc_fondi_dubbia_esig 
select 	fondi_bil.afde_bil_id
	into afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='RENDICONTO' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
return query
select zz.* from (
with clas as (
	select classif_tipo_desc1 titent_tipo_desc, titolo_code titent_code,
    	 titolo_desc titent_desc, titolo_validita_inizio titent_validita_inizio,
         titolo_validita_fine titent_validita_fine, 
         classif_tipo_desc2 tipologia_tipo_desc,
         tipologia_id, strutt.tipologia_code tipologia_code, 
         strutt.tipologia_desc tipologia_desc,
         tipologia_validita_inizio, tipologia_validita_fine,
         classif_tipo_desc3 categoria_tipo_desc,
         categoria_id, strutt.categoria_code categoria_code, 
         strutt.categoria_desc categoria_desc,
         categoria_validita_inizio, categoria_validita_fine,
         ente_proprietario_id
    from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
    											   p_anno,'') strutt 
),
capall as (
with
cap as (
select
a.elem_id,
a.elem_code,
a.elem_desc,
a.elem_code2,
a.elem_desc2,
a.elem_id_padre,
a.elem_code3,
d.classif_id
from siac_t_bil_elem a,	
     siac_d_bil_elem_tipo b,
     siac_r_bil_elem_class c,
 	 siac_t_class d,	
     siac_d_class_tipo e,
	 siac_r_bil_elem_categoria f,	
     siac_d_bil_elem_categoria g, 
     siac_r_bil_elem_stato h, 
     siac_d_bil_elem_stato i 
where a.elem_tipo_id		 = b.elem_tipo_id 
    and   c.elem_id              = a.elem_id
    and   d.classif_id           = c.classif_id
    and   e.classif_tipo_id      = d.classif_tipo_id
    and   g.elem_cat_id          = f.elem_cat_id
    and   f.elem_id              = a.elem_id
    and   h.elem_id              = a.elem_id
    and   i.elem_stato_id        = h.elem_stato_id
    and a.ente_proprietario_id = p_ente_prop_id
    and   a.bil_id               = bilancio_id
    and   b.elem_tipo_code 	     = 'CAP-EG'
    and   e.classif_tipo_code	 = 'CATEGORIA'
    and	  g.elem_cat_code	     = 'STD'
    and	  i.elem_stato_code	     = 'VA'
    and   a.data_cancellazione   is null
    and	  b.data_cancellazione   is null
    and	  c.data_cancellazione	 is null
    and	  d.data_cancellazione	 is null
    and	  e.data_cancellazione 	 is null
    and	  f.data_cancellazione 	 is null
    and	  g.data_cancellazione	 is null
    and	  h.data_cancellazione   is null
    and	  i.data_cancellazione   is null
), 
resatt as ( -- Residui Attivi 
select capitolo.elem_id,
       sum (dt_movimento.movgest_ts_det_importo) residui_accertamenti,
       CASE 
         WHEN movimento.movgest_anno < annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'I' THEN
            'RESATT' 
         WHEN movimento.movgest_anno = annoCapImp_int AND dt_mov_tipo.movgest_ts_det_tipo_code = 'A' THEN  
            'ACCERT' 
         ELSE
            'ALTRO'
       END tipo_importo         
from siac_t_bil_elem                  capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id 
inner join siac_d_movgest_tipo        tipo_mov on movimento.movgest_tipo_id = tipo_mov.movgest_tipo_id 
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id 
inner join siac_r_movgest_ts_stato    r_movimento_stato on ts_movimento.movgest_ts_id = r_movimento_stato.movgest_ts_id 
inner join siac_d_movgest_stato       tipo_stato on r_movimento_stato.movgest_stato_id = tipo_stato.movgest_stato_id
inner join siac_t_movgest_ts_det      dt_movimento on ts_movimento.movgest_ts_id = dt_movimento.movgest_ts_id 
inner join siac_d_movgest_ts_tipo     ts_mov_tipo on ts_movimento.movgest_ts_tipo_id = ts_mov_tipo.movgest_ts_tipo_id
inner join siac_d_movgest_ts_det_tipo dt_mov_tipo on dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id 
where capitolo.ente_proprietario_id     =   p_ente_prop_id
and   capitolo.bil_id      				=	bilancio_id
and   t_capitolo.elem_tipo_code    		= 	'CAP-EG'
and   movimento.movgest_anno 	        <= 	annoCapImp_int
and   movimento.bil_id					=	bilancio_id
and   tipo_mov.movgest_tipo_code    	=   'A' 
and   tipo_stato.movgest_stato_code     in  ('D','N')
and   ts_mov_tipo.movgest_ts_tipo_code  =   'T'
and   dt_mov_tipo.movgest_ts_det_tipo_code in ('I','A')
and   capitolo.data_cancellazione     	is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione    	is null 
and   movimento.data_cancellazione     	is null 
and   tipo_mov.data_cancellazione     	is null 
and   r_movimento_stato.data_cancellazione is null 
and   ts_movimento.data_cancellazione   is null 
and   tipo_stato.data_cancellazione    	is null 
and   dt_movimento.data_cancellazione   is null 
and   ts_mov_tipo.data_cancellazione    is null 
and   dt_mov_tipo.data_cancellazione    is null
and   now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and   now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
group by tipo_importo, capitolo.elem_id
),
resrisc as ( -- Riscossione residui
select 		r_capitolo_ordinativo.elem_id,
            sum(ordinativo_imp.ord_ts_det_importo) importo_residui,
            CASE 
             WHEN movimento.movgest_anno < annoCapImp_int THEN
                'RISRES'
             ELSE
                'RISCOMP'
             END tipo_importo                    
from  siac_r_ordinativo_bil_elem		r_capitolo_ordinativo,
      siac_t_ordinativo				    ordinativo,
      siac_d_ordinativo_tipo			tipo_ordinativo,
      siac_r_ordinativo_stato			r_stato_ordinativo,
      siac_d_ordinativo_stato			stato_ordinativo,
      siac_t_ordinativo_ts 			    ordinativo_det,
      siac_t_ordinativo_ts_det 		    ordinativo_imp,
      siac_d_ordinativo_ts_det_tipo 	ordinativo_imp_tipo,
      siac_t_movgest     				movimento,
      siac_t_movgest_ts    			    ts_movimento, 
      siac_r_ordinativo_ts_movgest_ts	r_ordinativo_movgest
where r_capitolo_ordinativo.ord_id		=	ordinativo.ord_id
    and	ordinativo.ord_tipo_id				=	tipo_ordinativo.ord_tipo_id
    and	ordinativo.ord_id					=	r_stato_ordinativo.ord_id
    and	r_stato_ordinativo.ord_stato_id		=	stato_ordinativo.ord_stato_id
    and	ordinativo.ord_id					=	ordinativo_det.ord_id
    and	ordinativo_det.ord_ts_id			=	ordinativo_imp.ord_ts_id
    and	ordinativo_imp.ord_ts_det_tipo_id	=	ordinativo_imp_tipo.ord_ts_det_tipo_id
    and	r_ordinativo_movgest.ord_ts_id		=	ordinativo_det.ord_ts_id
    and	r_ordinativo_movgest.movgest_ts_id	=	ts_movimento.movgest_ts_id
    and	ts_movimento.movgest_id				=	movimento.movgest_id
    and ordinativo_det.ente_proprietario_id	    =	p_ente_prop_id
    and	tipo_ordinativo.ord_tipo_code		= 	'I'	-- Incasso
    ------------------------------------------------------------------------------------------		
    ----------------------    LO STATO DEVE ESSERE MODIFICATO IN Q  --- QUIETANZATO    ------		
    and	stato_ordinativo.ord_stato_code			<> 'A' -- Annullato
    and	ordinativo.bil_id					=	bilancio_id
    and	ordinativo_imp_tipo.ord_ts_det_tipo_code	=	'A' 	-- Importo attuale
    and	movimento.movgest_anno				<=	annoCapImp_int	
    and movimento.bil_id					=	bilancio_id	
    and	r_capitolo_ordinativo.data_cancellazione	is null
    and	ordinativo.data_cancellazione				is null
    and	tipo_ordinativo.data_cancellazione			is null
    and	r_stato_ordinativo.data_cancellazione		is null
    and	stato_ordinativo.data_cancellazione			is null
    and ordinativo_det.data_cancellazione			is null
    and ordinativo_imp.data_cancellazione			is null
    and ordinativo_imp_tipo.data_cancellazione		is null
    and	movimento.data_cancellazione				is null
    and	ts_movimento.data_cancellazione				is null
    and	r_ordinativo_movgest.data_cancellazione		is null
    and now() between r_capitolo_ordinativo.validita_inizio and COALESCE(r_capitolo_ordinativo.validita_fine,now())
    and now() between r_stato_ordinativo.validita_inizio and COALESCE(r_stato_ordinativo.validita_fine,now())
    and now() between r_ordinativo_movgest.validita_inizio and COALESCE(r_ordinativo_movgest.validita_fine,now())
group by tipo_importo, r_capitolo_ordinativo.elem_id
),
resriacc as ( -- Riaccertamenti residui
select capitolo.elem_id,
       sum (t_movgest_ts_det_mod.movgest_ts_det_importo) riaccertamenti_residui
from siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
     siac_t_modifica t_modifica,
     siac_r_modifica_stato r_mod_stato,
     siac_d_modifica_stato d_mod_stato,
     siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
     where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
     and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
     and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
     and r_mod_stato.mod_id=t_modifica.mod_id
	 and capitolo.ente_proprietario_id   = p_ente_prop_id                                   
     and capitolo.bil_id      				=	bilancio_id
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	< 	annoCapImp_int
     and movimento.bil_id					=	bilancio_id
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale 
     and d_mod_stato.mod_stato_code='V'
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
     and capitolo.data_cancellazione     	is null 
     and r_mov_capitolo.data_cancellazione is null 
     and t_capitolo.data_cancellazione    	is null 
     and movimento.data_cancellazione     	is null 
     and tipo_mov.data_cancellazione     	is null 
     and r_movimento_stato.data_cancellazione   is null 
     and ts_movimento.data_cancellazione   is null 
     and tipo_stato.data_cancellazione    	is null 
     and dt_movimento.data_cancellazione   is null 
     and ts_mov_tipo.data_cancellazione    is null 
     and dt_mov_tipo.data_cancellazione    is null
     and t_movgest_ts_det_mod.data_cancellazione    is null
     and r_mod_stato.data_cancellazione    is null
     and t_modifica.data_cancellazione    is null     
   group by capitolo.elem_id	
),
/*
	SIAC-8154 13/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/    
/*
minfondo as ( -- Importo minimo del fondo
SELECT
 rbilelem.elem_id, 
 CASE 
   WHEN tipomedia = 'SEMPLICE' THEN
        round((COALESCE(datifcd.perc_acc_fondi,0)+
        COALESCE(datifcd.perc_acc_fondi_1,0)+
        COALESCE(datifcd.perc_acc_fondi_2,0)+
        COALESCE(datifcd.perc_acc_fondi_3,0)+
        COALESCE(datifcd.perc_acc_fondi_4,0))/5,2)
   ELSE
        round((COALESCE(datifcd.perc_acc_fondi,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_1,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_2,0)*0.10+
        COALESCE(datifcd.perc_acc_fondi_3,0)*0.35+
        COALESCE(datifcd.perc_acc_fondi_4,0)*0.35),2)
 END perc_media
 -- ,1 flag_cassa -- SIAC-5854
 , 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
 WHERE rbilelem.acc_fde_id = datifcd.acc_fde_id 
 AND   datifcd.ente_proprietario_id = p_ente_prop_id 
 AND   rbilelem.data_cancellazione is null
), */
minfondo as ( -- Importo minimo del fondo
SELECT
 datifcd.elem_id,   
 case when tipo_media.afde_tipo_media_code ='SEMP_RAP' then
    COALESCE(acc_fde_media_semplice_rapporti, 0)          
    else case when tipo_media.afde_tipo_media_code ='SEMP_TOT' then
      COALESCE(acc_fde_media_semplice_totali, 0)        
    else case when tipo_media.afde_tipo_media_code ='POND_RAP' then
    	COALESCE(acc_fde_media_ponderata_rapporti, 0)
    else case when tipo_media.afde_tipo_media_code ='POND_TOT' then
    	COALESCE(acc_fde_media_ponderata_totali,0)     
    else case when tipo_media.afde_tipo_media_code ='UTENTE' then
    	COALESCE(acc_fde_media_utente, 0)      
    end end end end end perc_media,          
 1 flag_fondo -- SIAC-5854
 FROM siac_t_acc_fondi_dubbia_esig datifcd, 
    siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
 WHERE tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
   AND datifcd.ente_proprietario_id = p_ente_prop_id 
   and datifcd.afde_bil_id = afde_bilancioId
   AND datifcd.data_cancellazione is null
   AND tipo_media.data_cancellazione is null
),
accertcassa as ( -- Accertato per cassa -- SIAC-5854
SELECT rbea.elem_id, 0 flag_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.data_cancellazione is null
AND    ta.data_cancellazione is null
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S'
),
acc_succ as ( -- Accertamenti imputati agli esercizi successivi a quello cui il rendiconto si riferisce
select capitolo.elem_id,
       --sum (t_movgest_ts_det_mod.movgest_ts_det_importo) accertamenti_succ
       sum (dt_movimento.movgest_ts_det_importo) accertamenti_succ
from siac_t_bil_elem     capitolo , 
     siac_r_movgest_bil_elem   r_mov_capitolo, 
     siac_d_bil_elem_tipo    t_capitolo, 
     siac_t_movgest     movimento, 
     siac_d_movgest_tipo    tipo_mov, 
     siac_t_movgest_ts    ts_movimento, 
     siac_r_movgest_ts_stato   r_movimento_stato, 
     siac_d_movgest_stato    tipo_stato, 
     siac_t_movgest_ts_det   dt_movimento, 
     siac_d_movgest_ts_tipo   ts_mov_tipo, 
     siac_d_movgest_ts_det_tipo  dt_mov_tipo 
     where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
     and r_mov_capitolo.elem_id    		=	capitolo.elem_id
     and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
     and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
     and movimento.movgest_id      		= 	ts_movimento.movgest_id 
     and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
     and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
     and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
     and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
     and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id 
     and capitolo.ente_proprietario_id   = p_ente_prop_id                              
     and capitolo.bil_id      				=	bilancio_id      
     and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
     and movimento.movgest_anno 	> 	annoCapImp_int
     and movimento.bil_id					=	bilancio_id
     and tipo_mov.movgest_tipo_code    	= 'A' 
     and tipo_stato.movgest_stato_code   in ('D','N')
     and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
     and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' -- Importo attuale      
     and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
     and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
     and capitolo.data_cancellazione     	is null 
     and r_mov_capitolo.data_cancellazione is null 
     and t_capitolo.data_cancellazione    	is null 
     and movimento.data_cancellazione     	is null 
     and tipo_mov.data_cancellazione     	is null 
     and r_movimento_stato.data_cancellazione   is null 
     and ts_movimento.data_cancellazione   is null 
     and tipo_stato.data_cancellazione    	is null 
     and dt_movimento.data_cancellazione   is null 
     and ts_mov_tipo.data_cancellazione    is null 
     and dt_mov_tipo.data_cancellazione    is null
  group by capitolo.elem_id	               
),
cred_stra as ( -- Crediti stralciati
 select    
   capitolo.elem_id,
   abs(sum (t_movgest_ts_det_mod.movgest_ts_det_importo)) crediti_stralciati
    from siac_t_bil_elem     capitolo , 
      siac_r_movgest_bil_elem   r_mov_capitolo, 
      siac_d_bil_elem_tipo    t_capitolo, 
      siac_t_movgest     movimento, 
      siac_d_movgest_tipo    tipo_mov, 
      siac_t_movgest_ts    ts_movimento, 
      siac_r_movgest_ts_stato   r_movimento_stato, 
      siac_d_movgest_stato    tipo_stato, 
      siac_t_movgest_ts_det   dt_movimento, 
      siac_d_movgest_ts_tipo   ts_mov_tipo, 
      siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
      siac_t_modifica t_modifica,
      siac_d_modifica_tipo d_modif_tipo,
      siac_r_modifica_stato r_mod_stato,
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
      where capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id 
      and r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id 
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and capitolo.ente_proprietario_id   = p_ente_prop_id  
      and capitolo.bil_id     				=	bilancio_id     
      and movimento.bil_id					=	bilancio_id                                                    
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      and movimento.movgest_anno 	        <= 	annoCapImp_int
      and tipo_mov.movgest_tipo_code    	= 'A' 
      and tipo_stato.movgest_stato_code   in ('D','N') ------ P,A,N 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
      /*and ((d_modif_tipo.mod_tipo_code in ('CROR','ECON') and p_anno <= '2016')
            or
           (d_modif_tipo.mod_tipo_code like 'FCDE%' and p_anno >= '2017')
          ) */
      and d_modif_tipo.mod_tipo_code in ('CROR','ECON')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now()) 
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null
group by capitolo.elem_id
)
select 
cap.elem_id bil_ele_id,
cap.elem_code bil_ele_code,
cap.elem_desc bil_ele_desc,
cap.elem_code2 bil_ele_code2,
cap.elem_desc2 bil_ele_desc2,
cap.elem_id_padre bil_ele_id_padre,
cap.elem_code3 bil_ele_code3,
cap.classif_id categoria_id,
coalesce(resatt1.residui_accertamenti,0) residui_attivi,
(coalesce(resatt1.residui_accertamenti,0) -
coalesce(resrisc1.importo_residui,0) +
coalesce(resriacc.riaccertamenti_residui,0)) residui_attivi_prec,
coalesce(minfondo.perc_media,0) perc_media,
-- minfondo.flag_cassa, -- SIAC-5854
coalesce(minfondo.flag_fondo,0) flag_fondo, -- SIAC-5854
coalesce(accertcassa.flag_cassa,1) flag_cassa, -- SIAC-5854
coalesce(acc_succ.accertamenti_succ,0) accertamenti_succ,
coalesce(cred_stra.crediti_stralciati,0) crediti_stralciati,
coalesce(resrisc2.importo_residui,0) residui_competenza,
coalesce(resatt2.residui_accertamenti,0) accertamenti,
(coalesce(resatt2.residui_accertamenti,0) -
 coalesce(resrisc2.importo_residui,0)) importo_finale
from cap
left join resatt resatt1
on cap.elem_id=resatt1.elem_id and resatt1.tipo_importo = 'RESATT'
left join resatt resatt2
on cap.elem_id=resatt2.elem_id and resatt2.tipo_importo = 'ACCERT'
left join resrisc resrisc1
on cap.elem_id=resrisc1.elem_id and resrisc1.tipo_importo = 'RISRES'
left join resrisc resrisc2
on cap.elem_id=resrisc2.elem_id and resrisc2.tipo_importo = 'RISCOMP'
left join resriacc
on cap.elem_id=resriacc.elem_id
left join minfondo
on cap.elem_id=minfondo.elem_id
left join accertcassa
on cap.elem_id=accertcassa.elem_id
left join acc_succ
on cap.elem_id=acc_succ.elem_id
left join cred_stra
on cap.elem_id=cred_stra.elem_id
),
fondo_dubbia_esig as (
select  importi.repimp_desc programma_code,
        coalesce(importi.repimp_importo,0) imp_fondo_dubbia_esig
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,
        siac_t_periodo 					anno_comp
where 	r_report_importi.rep_id			=	report.rep_id				
and     r_report_importi.repimp_id		=	importi.repimp_id 	
and     importi.periodo_id 				=	anno_comp.periodo_id			
and     report.ente_proprietario_id		=	p_ente_prop_id				
and		importi.bil_id					=   bilancio_id				
and 	report.rep_codice				=	'BILR148'  			
and     importi.repimp_desc <> ''
--and     importi.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
and 	importi.repimp_codice like 'Colonna E Allegato c) FCDE Rendiconto%'
and     report.data_cancellazione is null
and     importi.data_cancellazione is null
and     r_report_importi.data_cancellazione is null
and     anno_comp.data_cancellazione is null
)
select 
p_anno::varchar bil_anno,
''::varchar titent_tipo_code,
clas.titent_tipo_desc::varchar,
clas.titent_code::varchar,
clas.titent_desc::varchar,
''::varchar tipologia_tipo_code,
clas.tipologia_tipo_desc::varchar,
clas.tipologia_code::varchar,
clas.tipologia_desc::varchar,
''::varchar	categoria_tipo_code,
clas.categoria_tipo_desc::varchar,
clas.categoria_code::varchar,
clas.categoria_desc::varchar,
capall.bil_ele_code::varchar,
capall.bil_ele_desc::varchar,
capall.bil_ele_code2::varchar,
capall.bil_ele_desc2::varchar,
capall.bil_ele_id::integer,
capall.bil_ele_id_padre::integer,
COALESCE(capall.importo_finale::numeric,0) residui_attivi,
COALESCE(capall.residui_attivi_prec::numeric,0) residui_attivi_prec,
COALESCE(capall.importo_finale::numeric + capall.residui_attivi_prec::numeric,0) totale_residui_attivi,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  COALESCE(round((capall.importo_finale::numeric + capall.residui_attivi_prec::numeric) * (1 - capall.perc_media::numeric/100),2),0)
 ELSE
 0
END 
importo_minimo_fondo,
capall.bil_ele_code3::varchar,
--COALESCE(capall.flag_cassa::integer,0) flag_cassa, -- SAIC-5854
COALESCE(capall.flag_cassa::integer,1) flag_cassa, -- SAIC-5854       
COALESCE(capall.accertamenti_succ::numeric,0) accertamenti_succ,
COALESCE(capall.crediti_stralciati::numeric,0) crediti_stralciati,
imp_fondo_dubbia_esig,
COALESCE(capall.perc_media::numeric,0) perc_media,
CASE
 --WHEN perc_media::numeric <> 0 THEN
 WHEN capall.flag_cassa::numeric = 1 AND capall.flag_fondo::numeric = 1 THEN
  (100 - COALESCE(capall.perc_media,0))::numeric
 ELSE
 0
END 
perc_complementare
from clas 
left join capall on clas.categoria_id = capall.categoria_id  
left join fondo_dubbia_esig on fondo_dubbia_esig.programma_code = clas.tipologia_code   
) as zz;

/*raise notice 'query: %',queryfin;
RETURN QUERY queryfin;*/

    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR183_FCDE_assestamento" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titolo_id integer,
  code_titolo varchar,
  desc_titolo varchar,
  tipologia_id integer,
  code_tipologia varchar,
  desc_tipologia varchar,
  categoria_id integer,
  code_categoria varchar,
  desc_categoria varchar,
  elem_id integer,
  capitolo_prev varchar,
  elem_desc varchar,
  flag_acc_cassa varchar,
  pdce_code varchar,
  perc_delta numeric,
  imp_stanziamento_comp numeric,
  imp_accertamento_comp numeric,
  imp_reversale_comp numeric,
  percaccantonamento numeric
) AS
$body$
DECLARE

bilancio_id integer;
anno_int integer;
flagAccantGrad varchar;
RTN_MESSAGGIO text;
afde_bilancioId integer;

BEGIN
RTN_MESSAGGIO:='select 1';

anno_int:= p_anno::integer;

select a.bil_id
into  bilancio_id
from  siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id
and   b.periodo_id = a.periodo_id
and   b.anno = p_anno;

/*
	SIAC-8154 20/07/2021
    Gli attributi sono sulla tabella siac_t_acc_fondi_dubbia_esig_bil
select attr_bilancio."boolean"
into flagAccantGrad
from siac_r_bil_attr attr_bilancio, siac_t_attr attr
where attr_bilancio.bil_id = bilancio_id
and   attr_bilancio.attr_id = attr.attr_id
and   attr.attr_code = 'accantonamentoGraduale'
and   attr_bilancio.data_cancellazione is null
and   attr_bilancio.ente_proprietario_id = p_ente_prop_id;

if flagAccantGrad = 'N' then
    percAccantonamento = 100;
else
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento
    from siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where attr_bilancio.bil_id = bilancio_id
    and attr_bilancio.attr_id = attr.attr_id
    and attr.attr_code = 'percentualeAccantonamentoAnno'
    and attr_bilancio.data_cancellazione is null
    and attr_bilancio.ente_proprietario_id = p_ente_prop_id;
end if;
*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='PREVISIONE' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
raise notice 'percAccantonamento = %', percAccantonamento;

return query
select zz.* from (
with strut_bilancio as(
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, null)),
capitoli as(
  select cl.classif_id categoria_id,
  anno_eserc.anno anno_bilancio,
  e.elem_id,
  e.elem_code||'/'||e.elem_code2||'/'||e.elem_code3 capitolo_prev,
  e.elem_desc
    --SIAC-8154 20/07/2021
    -- il capitolo e' su siac_t_acc_fondi_dubbia_esig
  --r_bil_elem_dubbia_esig.acc_fde_id
  from  siac_r_bil_elem_class rc,
        siac_t_bil_elem e,
        siac_d_class_tipo ct,
        siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento,
        siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
        siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
        	--SIAC-8154 20/07/2021
        	-- il capitolo e' su siac_t_acc_fondi_dubbia_esig
        --siac_r_bil_elem_acc_fondi_dubbia_esig r_bil_elem_dubbia_esig
  where ct.classif_tipo_id				=	cl.classif_tipo_id
  and cl.classif_id					=	rc.classif_id
  and bilancio.periodo_id				=	anno_eserc.periodo_id
  and e.bil_id						=	bilancio.bil_id
  and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id
  and e.elem_id						=	rc.elem_id
  and	e.elem_id						=	r_capitolo_stato.elem_id
  and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
  and	e.elem_id						=	r_cat_capitolo.elem_id
  and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
  --and r_bil_elem_dubbia_esig.elem_id  =   e.elem_id
  and e.ente_proprietario_id			=	p_ente_prop_id
  and e.bil_id                        =   bilancio_id
  and tipo_elemento.elem_tipo_code 	= 	'CAP-EP'
  and	stato_capitolo.elem_stato_code	=	'VA'
  and ct.classif_tipo_code			=	'CATEGORIA'
  and	cat_del_capitolo.elem_cat_code	=	'STD'
  and e.data_cancellazione 				is null
  and	r_capitolo_stato.data_cancellazione	is null
  and	r_cat_capitolo.data_cancellazione	is null
  and	rc.data_cancellazione				is null
  and	ct.data_cancellazione 				is null
  and	cl.data_cancellazione 				is null
  and	bilancio.data_cancellazione 		is null
  and	anno_eserc.data_cancellazione 		is null
  and	tipo_elemento.data_cancellazione	is null
  and	stato_capitolo.data_cancellazione 	is null
  and	cat_del_capitolo.data_cancellazione	is null
  --and r_bil_elem_dubbia_esig.data_cancellazione is null
),
conto_pdce as(
select t_class_upb.classif_code, r_capitolo_upb.elem_id
from
    siac_d_class_tipo	class_upb,
    siac_t_class		t_class_upb,
    siac_r_bil_elem_class r_capitolo_upb
where
    t_class_upb.classif_tipo_id = class_upb.classif_tipo_id
    and t_class_upb.classif_id = r_capitolo_upb.classif_id
    and t_class_upb.ente_proprietario_id = p_ente_prop_id
    and class_upb.classif_tipo_code like 'PDC_%'
    and	class_upb.data_cancellazione 			is null
    and t_class_upb.data_cancellazione 			is null
    and r_capitolo_upb.data_cancellazione 			is null
),
flag_acc_cassa as (
select rbea."boolean", rbea.elem_id
from   siac_r_bil_elem_attr rbea, siac_t_attr ta
where  rbea.attr_id = ta.attr_id
and    rbea.data_cancellazione is null
and    ta.data_cancellazione is null
and    ta.attr_code = 'FlagAccertatoPerCassa'
and    ta.ente_proprietario_id = p_ente_prop_id
),
/*
	SIAC-8154 13/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/  
/*fondo  as (
select fondi_dubbia_esig.acc_fde_id, fondi_dubbia_esig.perc_delta
from   siac_t_acc_fondi_dubbia_esig fondi_dubbia_esig
where  fondi_dubbia_esig.ente_proprietario_id = p_ente_prop_id
and    fondi_dubbia_esig.data_cancellazione is null
),*/
fondo  as (
select fondi_dubbia_esig.elem_id, fondi_dubbia_esig.perc_delta
from   siac_t_acc_fondi_dubbia_esig fondi_dubbia_esig
where  fondi_dubbia_esig.ente_proprietario_id = p_ente_prop_id
and    fondi_dubbia_esig.afde_bil_id  = afde_bilancioId
and    fondi_dubbia_esig.data_cancellazione is null
),
stanziamento_comp as (
select 	capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
        sum(capitolo_importi.elem_det_importo) imp_stanziamento_comp
from 	siac_t_bil_elem_det capitolo_importi,
        siac_d_bil_elem_det_tipo capitolo_imp_tipo,
        siac_t_periodo capitolo_imp_periodo,
        siac_t_bil_elem capitolo,
        siac_d_bil_elem_tipo tipo_elemento,
        siac_t_bil bilancio,
        siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
        siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where 	bilancio.periodo_id				=	capitolo_imp_periodo.periodo_id
and	capitolo.bil_id						=	bilancio_id
and	capitolo.elem_id					=	capitolo_importi.elem_id
and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id
and	capitolo.elem_id					=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
and	capitolo.elem_id					=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
and capitolo_importi.ente_proprietario_id = p_ente_prop_id
and	tipo_elemento.elem_tipo_code 		= 	'CAP-EG'
and	stato_capitolo.elem_stato_code		=	'VA'
and	capitolo_imp_periodo.anno           = 	p_anno
and	cat_del_capitolo.elem_cat_code		=	'STD'
and capitolo_imp_tipo.elem_det_tipo_code  = 'STA'
and	capitolo_importi.data_cancellazione 	is null
and	capitolo_imp_tipo.data_cancellazione 	is null
and	capitolo_imp_periodo.data_cancellazione is null
and	capitolo.data_cancellazione 			is null
and	tipo_elemento.data_cancellazione 		is null
and	bilancio.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 		is null
and	r_capitolo_stato.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione 	is null
and	r_cat_capitolo.data_cancellazione 		is null
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
),
accertamento_comp as (
select capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
       sum (dt_movimento.movgest_ts_det_importo) imp_accertamento_comp
from   siac_t_bil_elem     capitolo ,
       siac_r_movgest_bil_elem   r_mov_capitolo,
       siac_d_bil_elem_tipo    t_capitolo,
       siac_t_movgest     movimento,
       siac_d_movgest_tipo    tipo_mov,
       siac_t_movgest_ts    ts_movimento,
       siac_r_movgest_ts_stato   r_movimento_stato,
       siac_d_movgest_stato    tipo_stato,
       siac_t_movgest_ts_det   dt_movimento,
       siac_d_movgest_ts_tipo   ts_mov_tipo,
       siac_d_movgest_ts_det_tipo  dt_mov_tipo
where capitolo.elem_tipo_id      		= t_capitolo.elem_tipo_id
and r_mov_capitolo.elem_id    		    = capitolo.elem_id
and r_mov_capitolo.movgest_id    		= movimento.movgest_id
and movimento.movgest_tipo_id    		= tipo_mov.movgest_tipo_id
and movimento.movgest_id      		    = ts_movimento.movgest_id
and ts_movimento.movgest_ts_id    	    = r_movimento_stato.movgest_ts_id
and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id
and ts_movimento.movgest_ts_tipo_id     = ts_mov_tipo.movgest_ts_tipo_id
and ts_movimento.movgest_ts_id    	    = dt_movimento.movgest_ts_id
and dt_movimento.movgest_ts_det_tipo_id = dt_mov_tipo.movgest_ts_det_tipo_id
and movimento.ente_proprietario_id      = p_ente_prop_id
and t_capitolo.elem_tipo_code    		= 'CAP-EG'
and movimento.movgest_anno              = anno_int
and movimento.bil_id                    = bilancio_id
and capitolo.bil_id     				= bilancio_id
and tipo_mov.movgest_tipo_code    	    = 'A'
and tipo_stato.movgest_stato_code       in ('D','N')
and ts_mov_tipo.movgest_ts_tipo_code    = 'T'
and dt_mov_tipo.movgest_ts_det_tipo_code = 'A'
and now()
  between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
and now()
  between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
and capitolo.data_cancellazione     	is null
and r_mov_capitolo.data_cancellazione is null
and t_capitolo.data_cancellazione    	is null
and movimento.data_cancellazione     	is null
and tipo_mov.data_cancellazione     	is null
and r_movimento_stato.data_cancellazione   is null
and ts_movimento.data_cancellazione   is null
and tipo_stato.data_cancellazione    	is null
and dt_movimento.data_cancellazione   is null
and ts_mov_tipo.data_cancellazione    is null
and dt_mov_tipo.data_cancellazione    is null
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
),
reversale_comp as (
select capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3 capitolo_rend,
       sum (t_ord_ts_det.ord_ts_det_importo) imp_reversale_comp
from   siac_t_bil_elem     capitolo ,
       siac_r_ordinativo_bil_elem   r_ord_capitolo,
       siac_d_bil_elem_tipo    t_capitolo,
       siac_t_ordinativo t_ordinativo,
       siac_t_ordinativo_ts t_ord_ts,
       siac_t_ordinativo_ts_det t_ord_ts_det,
       siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
       siac_r_ordinativo_stato r_ord_stato,
       siac_d_ordinativo_stato d_ord_stato,
       siac_d_ordinativo_tipo d_ord_tipo,
-- ST SIAC-6291 inserita condizione per movimento di competenza: tavole
       siac_r_ordinativo_ts_movgest_ts    r_ord_mov,
       siac_t_movgest     movimento,
       siac_t_movgest_ts    ts_movimento
where capitolo.elem_tipo_id      		 = t_capitolo.elem_tipo_id
and   r_ord_capitolo.elem_id    		 = capitolo.elem_id
and   t_ordinativo.ord_id                = r_ord_capitolo.ord_id
and   t_ordinativo.ord_id                = t_ord_ts.ord_id
and   t_ord_ts.ord_ts_id                 = t_ord_ts_det.ord_ts_id
and   t_ordinativo.ord_id                = r_ord_stato.ord_id
and   r_ord_stato.ord_stato_id           = d_ord_stato.ord_stato_id
and   d_ord_tipo.ord_tipo_id             = t_ordinativo.ord_tipo_id
AND   d_ts_det_tipo.ord_ts_det_tipo_id   = t_ord_ts_det.ord_ts_det_tipo_id
and   t_ordinativo.ente_proprietario_id  = p_ente_prop_id
--ST SIAC-6291 condizione per movimento di competenza: Join
and   movimento.movgest_id      		 = ts_movimento.movgest_id
and   r_ord_mov.movgest_ts_id      		 = ts_movimento.movgest_ts_id
and   r_ord_mov.ord_ts_id                = t_ord_ts.ord_ts_id
--
and   t_capitolo.elem_tipo_code    		 =  'CAP-EG'
and   t_ordinativo.ord_anno              = anno_int
and   capitolo.bil_id                    = bilancio_id
and   t_ordinativo.bil_id                = bilancio_id
and   d_ord_stato.ord_stato_code         <>'A'
and   d_ord_tipo.ord_tipo_code           = 'I'
and   d_ts_det_tipo.ord_ts_det_tipo_code = 'A'
and   capitolo.data_cancellazione     	is null
and   r_ord_capitolo.data_cancellazione     	is null
and   t_capitolo.data_cancellazione     	is null
and   t_ordinativo.data_cancellazione     	is null
and   t_ord_ts.data_cancellazione     	is null
and   t_ord_ts_det.data_cancellazione     	is null
and   d_ts_det_tipo.data_cancellazione     	is null
and   r_ord_stato.data_cancellazione     	is null
and   r_ord_stato.validita_fine is null -- S.T. SIACC-6280
and   d_ord_stato.data_cancellazione     	is null
and   d_ord_tipo.data_cancellazione     	is null
-- ST SIAC-6291 condizione per movimento di competenza
and   r_ord_mov.data_cancellazione      is null
and movimento.movgest_anno              = anno_int
--
group by capitolo.elem_code||'/'||capitolo.elem_code2||'/'||capitolo.elem_code3
)
select
p_anno,
strut_bilancio.titolo_id::integer titolo_id,
strut_bilancio.titolo_code::varchar code_titolo,
strut_bilancio.titolo_desc::varchar desc_titolo,
strut_bilancio.tipologia_id::integer tipologia_id,
strut_bilancio.tipologia_code::varchar code_tipologia,
strut_bilancio.tipologia_desc::varchar desc_tipologia,
strut_bilancio.categoria_id::integer categoria_id,
strut_bilancio.categoria_code::varchar code_categoria,
strut_bilancio.categoria_desc::varchar desc_categoria,
capitoli.elem_id::integer elem_id,
capitoli.capitolo_prev::varchar capitolo_prev,
capitoli.elem_desc::varchar elem_desc,
COALESCE(flag_acc_cassa."boolean", 'N')::varchar flag_acc_cassa,
conto_pdce.classif_code::varchar pdce_code,
COALESCE(fondo.perc_delta,0)::numeric perc_delta,
COALESCE(stanziamento_comp.imp_stanziamento_comp,0)::numeric imp_stanziamento_comp,
COALESCE(accertamento_comp.imp_accertamento_comp,0)::numeric imp_accertamento_comp,
COALESCE(reversale_comp.imp_reversale_comp,0)::numeric imp_reversale_comp,
percAccantonamento::numeric
from strut_bilancio
inner join capitoli on strut_bilancio.categoria_id = capitoli.categoria_id
inner join conto_pdce on conto_pdce.elem_id = capitoli.elem_id
--left join  fondo on fondo.acc_fde_id = capitoli.acc_fde_id
left join  fondo on fondo.elem_id = capitoli.elem_id
left join  flag_acc_cassa on flag_acc_cassa.elem_id = capitoli.elem_id
left join  stanziamento_comp on stanziamento_comp.capitolo_rend = capitoli.capitolo_prev
left join  accertamento_comp on accertamento_comp.capitolo_rend = capitoli.capitolo_prev
left join  reversale_comp on reversale_comp.capitolo_rend = capitoli.capitolo_prev
) as zz;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR170_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_dettaglio" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean,
  perc_delta numeric,
  perc_media numeric,
  percaccantonamento numeric
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
--percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
fde_media_utente  numeric;
fde_media_semplice_totali numeric;
fde_media_semplice_rapporti  numeric;
fde_media_ponderata_totali  numeric;
fde_media_ponderata_rapporti  numeric;
afde_bilancioId integer;

h_count integer :=0;



BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

flag_acc_cassa:= true;


/*
	SIAC-8154 20/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    Gli attributi sono sulla tabella siac_t_acc_fondi_dubbia_esig_bil.
    
-- percentuale accantonamento bilancio
if p_anno_competenza = annoCapImp then
   	strpercAccantonamento = 'percentualeAccantonamentoAnno';
elseif  p_anno_competenza = annoCapImp1 then
	strpercAccantonamento = 'percentualeAccantonamentoAnno1';
else 
	strpercAccantonamento = 'percentualeAccantonamentoAnno2';
end if;




select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

select attr_bilancio."boolean"
into flagAccantGrad  from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'accantonamentoGraduale' and 
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;


if flagAccantGrad = 'N' then
   percAccantonamento = 100;
else  
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
    siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where 
    bilancio.periodo_id = anno_eserc.periodo_id and
    anno_eserc.anno = 	p_anno and
    bilancio.bil_id =  attr_bilancio.bil_id and
    attr_bilancio.attr_id= attr.attr_id and
    attr.attr_code = strpercAccantonamento and 
    attr_bilancio.data_cancellazione is null and
    attr_bilancio.ente_proprietario_id=p_ente_prop_id;
end if;

if tipomedia is null then
	tipomedia = 'SEMPLICE';
end if;

*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='PREVISIONE' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;
    
raise notice 'percAccantonamento = % - afde_bil_id = %', 
	percAccantonamento, afde_bilancioId;

TipoImpComp='STA';  -- competenza 
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

select fnc_siac_random_user()
into	user_table;

insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, 
	user_table);

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id		
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno 
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		--and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null      
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente
    order by capitolo_imp_tipo.elem_det_tipo_code, 
    	capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;

for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;

-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.elem_id = classifBilRec.bil_ele_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S';

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE

/*
	SIAC-8154 21/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/ 
/*
select COALESCE(datifcd.perc_acc_fondi,0), 
COALESCE(datifcd.perc_acc_fondi_1,0), COALESCE(datifcd.perc_acc_fondi_2,0),
COALESCE(datifcd.perc_acc_fondi_3,0), COALESCE(datifcd.perc_acc_fondi_4,0), 
COALESCE(datifcd.perc_delta,0), 
-- false -- SIAC-5854
1
into perc1, perc2, perc3, perc4, perc5, perc_delta
-- , flag_acc_cassa -- SIAC-5854
, h_count
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
where
  rbilelem.elem_id=classifBilRec.bil_ele_id and  
  rbilelem.acc_fde_id = datifcd.acc_fde_id and
  rbilelem.data_cancellazione is null;

if tipomedia = 'SEMPLICE' then
    perc_media = round((perc1+perc2+perc3+perc4+perc5)/5,2);
else 
    perc_media = round((perc1*0.10+perc2*0.10+perc3*0.10+perc4*0.35+perc5*0.35),2);
end if;

if perc_media is null then
   perc_media := 0;
end if;

if perc_delta is null then
   perc_delta := 0;
end if;
*/

raise notice 'bil_ele_id = %', classifBilRec.bil_ele_id;

fde_media_utente:=0;
fde_media_semplice_totali:=0; 
fde_media_semplice_rapporti:=0;
fde_media_ponderata_totali:=0; 
fde_media_ponderata_rapporti:=0;
perc_delta:=0;
perc_media:=0;
tipomedia:='';

if classifBilRec.bil_ele_id IS NOT NULL then
  select  datifcd.perc_delta, 1, tipo_media.afde_tipo_media_code,
  COALESCE(datifcd.acc_fde_media_utente,0), 
  COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  COALESCE(datifcd.acc_fde_media_semplice_rapporti,0), 
  COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
  COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0)
  into perc_delta, h_count, tipomedia,
  fde_media_utente, fde_media_semplice_totali, fde_media_semplice_rapporti,
  fde_media_ponderata_totali, fde_media_ponderata_rapporti
   FROM siac_t_acc_fondi_dubbia_esig datifcd, 
      siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
  where tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
    and datifcd.elem_id=classifBilRec.bil_ele_id 
    and datifcd.afde_bil_id  = afde_bilancioId
    and datifcd.data_cancellazione is null
    and tipo_media.data_cancellazione is null;
end if;

if tipomedia = 'SEMP_RAP' then
    perc_media = fde_media_semplice_rapporti;         
elsif tipomedia = 'SEMP_TOT' then
    perc_media = fde_media_semplice_totali;        
elsif tipomedia = 'POND_RAP' then
      perc_media = fde_media_ponderata_rapporti;  
elsif tipomedia = 'POND_TOT' then
      perc_media = fde_media_ponderata_totali;    
elsif tipomedia = 'UTENTE' then  --Media utente
      perc_media = fde_media_utente;   
end if;

raise notice 'tipomedia % - media: % - delta: %', tipomedia , perc_media, perc_delta ;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

---if p_anno_competenza = annoCapImp then
   	importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
    importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);
--elseif  p_anno_competenza = annoCapImp1 then
--	importo_collb:= round(classifBilRec.stanziamento_prev_anno1 * (perc_media/100) * percAccantonamento/100,2);
--    importo_collc:= round(classifBilRec.stanziamento_prev_anno1 * perc_delta/100,2);
--else 
--	importo_collb:= round(classifBilRec.stanziamento_prev_anno2 * (perc_media/100) * percAccantonamento/100,2);
--    importo_collc:= round(classifBilRec.stanziamento_prev_anno2 * perc_delta/100,2);
--end if;

raise notice 'bil_ele_id % - importo_collb %', classifBilRec.bil_ele_id , importo_collb;

raise notice 'bil_ele_id % - percAccantonamento %', classifBilRec.bil_ele_id , percAccantonamento ;

if h_count is null or flag_acc_cassa = true then  -- SIAC-5854
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

/*raise notice 'record';*/
return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;
perc_delta:=0;
perc_media:=0;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar,
  importo_collb numeric,
  importo_collc numeric,
  flag_acc_cassa boolean
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
flagAccantGrad varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strpercAccantonamento varchar;
percAccantonamento numeric;
tipomedia varchar;
perc1 numeric;
perc2 numeric;
perc3 numeric;
perc4 numeric;
perc5 numeric;
fde_media_utente  numeric;
fde_media_semplice_totali numeric;
fde_media_semplice_rapporti  numeric;
fde_media_ponderata_totali  numeric;
fde_media_ponderata_rapporti  numeric;

perc_delta numeric;
perc_media numeric;
afde_bilancioId integer;
perc_massima numeric;

h_count integer :=0;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

flag_acc_cassa:= true;

/*
	SIAC-8154 20/07/2021
    La tipologia di media non e' piu' un attributo ma e' un valore presente su
    siac_t_acc_fondi_dubbia_esig.
    Gli attributi sono sulla tabella siac_t_acc_fondi_dubbia_esig_bil.

-- percentuale accantonamento bilancio
if p_anno_competenza = annoCapImp then
   	strpercAccantonamento = 'percentualeAccantonamentoAnno';
elseif  p_anno_competenza = annoCapImp1 then
	strpercAccantonamento = 'percentualeAccantonamentoAnno1';
else 
	strpercAccantonamento = 'percentualeAccantonamentoAnno2';
end if;



select attr_bilancio.testo
into tipomedia from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'mediaApplicata' and
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;

select attr_bilancio."boolean"
into flagAccantGrad  from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
siac_r_bil_attr attr_bilancio, siac_t_attr attr
where 
bilancio.periodo_id = anno_eserc.periodo_id and
anno_eserc.anno = 	p_anno and
bilancio.bil_id =  attr_bilancio.bil_id and
attr_bilancio.attr_id= attr.attr_id and
attr.attr_code = 'accantonamentoGraduale' and 
attr_bilancio.data_cancellazione is null and
attr_bilancio.ente_proprietario_id=p_ente_prop_id;


if flagAccantGrad = 'N' then
   percAccantonamento = 100;
else  
    select COALESCE(attr_bilancio.numerico, 0)
    into percAccantonamento from siac_t_bil bilancio, siac_t_periodo anno_eserc, 
    siac_r_bil_attr attr_bilancio, siac_t_attr attr
    where 
    bilancio.periodo_id = anno_eserc.periodo_id and
    anno_eserc.anno = 	p_anno and
    bilancio.bil_id =  attr_bilancio.bil_id and
    attr_bilancio.attr_id= attr.attr_id and
    attr.attr_code = strpercAccantonamento and 
    attr_bilancio.data_cancellazione is null and
    attr_bilancio.ente_proprietario_id=p_ente_prop_id;
end if;

if tipomedia is null then
	tipomedia = 'SEMPLICE';
end if;
*/

percAccantonamento:=0;
select COALESCE(fondi_bil.afde_bil_accantonamento_graduale,0),
	fondi_bil.afde_bil_id
	into percAccantonamento, afde_bilancioId
from siac_t_acc_fondi_dubbia_esig_bil fondi_bil,
	siac_d_acc_fondi_dubbia_esig_tipo tipo,
    siac_d_acc_fondi_dubbia_esig_stato stato,
    siac_t_bil bil,
    siac_t_periodo per
where fondi_bil.afde_tipo_id =tipo.afde_tipo_id
	and fondi_bil.afde_stato_id = stato.afde_stato_id
	and fondi_bil.bil_id=bil.bil_id
    and bil.periodo_id=per.periodo_id
	and fondi_bil.ente_proprietario_id = p_ente_prop_id
	and per.anno= p_anno
    and tipo.afde_tipo_code ='PREVISIONE' 
    and stato.afde_stato_code = 'DEFINITIVA'
    and fondi_bil.data_cancellazione IS NULL
    and tipo.data_cancellazione IS NULL
    and stato.data_cancellazione IS NULL;

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

select fnc_siac_random_user()
into	user_table;


insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, 
	user_table);
 

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and ct.classif_tipo_code			=	'CATEGORIA' 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo,
            siac_t_acc_fondi_dubbia_esig fcde
    where 	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and   fcde.elem_id						= capitolo.elem_id
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno				
        and   fcde.afde_bil_id				=  afde_bilancioId
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		--and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null 
        and fcde.data_cancellazione IS NULL     
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               
for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop


titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;


-- SIAC-5854 INIZIO
SELECT true
INTO   flag_acc_cassa
FROM   siac_r_bil_elem_attr rbea, siac_t_attr ta
WHERE  rbea.attr_id = ta.attr_id
AND    rbea.elem_id = classifBilRec.bil_ele_id
AND    rbea.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    ta.attr_code = 'FlagAccertatoPerCassa'
AND    ta.ente_proprietario_id = p_ente_prop_id
AND    rbea."boolean" = 'S';

IF flag_acc_cassa IS NULL THEN
   flag_acc_cassa := false;
END IF;
-- SIAC-5854 FINE

/*
	SIAC-8154 21/07/2021
	Cambia la gestione dei dati per l'importo minimo del fondo:
	- la relazione con i capitoli e' diretta sulla tabella 
      siac_t_acc_fondi_dubbia_esig.
    - la tipologia di media non e' più un attributo ma e' anch'essa sulla
      tabella siac_t_acc_fondi_dubbia_esig con i relativi importi. 
*/ 
/*
select COALESCE(datifcd.perc_acc_fondi,0), 
COALESCE(datifcd.perc_acc_fondi_1,0), COALESCE(datifcd.perc_acc_fondi_2,0),
COALESCE(datifcd.perc_acc_fondi_3,0), COALESCE(datifcd.perc_acc_fondi_4,0), 
COALESCE(datifcd.perc_delta,0), 
-- false -- SIAC-5854
1
into perc1, perc2, perc3, perc4, perc5, perc_delta
-- , flag_acc_cassa -- SIAC-5854
, h_count
 FROM siac_t_acc_fondi_dubbia_esig datifcd, siac_r_bil_elem_acc_fondi_dubbia_esig rbilelem
where
  rbilelem.elem_id=classifBilRec.bil_ele_id and  
  rbilelem.acc_fde_id = datifcd.acc_fde_id and
  rbilelem.data_cancellazione is null;

if tipomedia = 'SEMPLICE' then
    perc_media = round((perc1+perc2+perc3+perc4+perc5)/5,2);
else 
    perc_media = round((perc1*0.10+perc2*0.10+perc3*0.10+perc4*0.35+perc5*0.35),2);
end if;

if perc_media is null then
   perc_media := 0;
end if;

if perc_delta is null then
   perc_delta := 0;
end if;
*/

raise notice 'bil_ele_id = %', classifBilRec.bil_ele_id;

fde_media_utente:=0;
fde_media_semplice_totali:=0; 
fde_media_semplice_rapporti:=0;
fde_media_ponderata_totali:=0; 
fde_media_ponderata_rapporti:=0;
perc_delta:=0;
perc_media:=0;
tipomedia:='';

if classifBilRec.bil_ele_id IS NOT NULL then
  select  datifcd.perc_delta, 1, tipo_media.afde_tipo_media_code,
  COALESCE(datifcd.acc_fde_media_utente,0), 
  COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  COALESCE(datifcd.acc_fde_media_semplice_rapporti,0), 
  COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
  COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0),
  greatest (COALESCE(datifcd.acc_fde_media_semplice_totali,0),
  	 COALESCE(datifcd.acc_fde_media_semplice_rapporti,0),
  	COALESCE(datifcd.acc_fde_media_ponderata_totali,0),
    COALESCE(datifcd.acc_fde_media_ponderata_rapporti,0))
  into perc_delta, h_count, tipomedia,
  fde_media_utente, fde_media_semplice_totali, fde_media_semplice_rapporti,
  fde_media_ponderata_totali, fde_media_ponderata_rapporti, perc_massima
   FROM siac_t_acc_fondi_dubbia_esig datifcd, 
      siac_d_acc_fondi_dubbia_esig_tipo_media tipo_media
  where tipo_media.afde_tipo_media_id=datifcd.afde_tipo_media_id
    and datifcd.elem_id=classifBilRec.bil_ele_id 
    and datifcd.afde_bil_id  = afde_bilancioId
    and datifcd.data_cancellazione is null
    and tipo_media.data_cancellazione is null;
end if;

if tipomedia = 'SEMP_RAP' then
    perc_media = fde_media_semplice_rapporti;         
elsif tipomedia = 'SEMP_TOT' then
    perc_media = fde_media_semplice_totali;        
elsif tipomedia = 'POND_RAP' then
      perc_media = fde_media_ponderata_rapporti;  
elsif tipomedia = 'POND_TOT' then
      perc_media = fde_media_ponderata_totali;    
elsif tipomedia = 'UTENTE' then  --Media utente
      perc_media = fde_media_utente;   
end if;

raise notice 'tipomedia % - media: % - delta: % - massima %', tipomedia , perc_media, perc_delta, perc_massima ;

--- colonna b del report = stanziamento capitolo * percentualeAccantonamentoAnno(1,2) * perc_media
--- colonna c del report = stanziamento capitolo * perc_delta della tabella 

--SIAC-8154 14/10/2021
--la colonna C diventa quello che prima era la colonna B
--la colonna B invece della percentuale media deve usa la percentuale 
--che ha il valore massimo (esclusa quella utente).
--importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);
--importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_delta/100) * percAccantonamento/100,2);   
importo_collb:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_massima/100) * percAccantonamento/100,2);
importo_collc:= round(classifBilRec.stanziamento_prev_anno * (1 - perc_media/100) * percAccantonamento/100,2);

raise notice 'importo_collb % - %', classifBilRec.bil_ele_id , importo_collb;

raise notice 'percAccantonamento % - %', classifBilRec.bil_ele_id , percAccantonamento ;

if h_count is null or flag_acc_cassa = true then
  importo_collb:=0;
  importo_collc:=0;
  -- flag_acc_cassa:=true; -- SIAC-5854
END if;

-- importi capitolo

return next;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc:=0;
importo_collb:=0;
importo_collc:=0;
flag_acc_cassa:=true;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR009_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_EELL" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento_prev_anno numeric,
  stanziamento_prev_anno1 numeric,
  stanziamento_prev_anno2 numeric,
  codice_pdc varchar
) AS
$body$
DECLARE
classifBilRec record;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
elemTipoCode varchar;
user_table	varchar;
h_count integer :=0;
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 

TipoImpComp='STA';  -- competenza
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc='';

select fnc_siac_random_user()
into	user_table;



insert into siac_rep_tit_tip_cat_riga_anni
select  *
from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno, 
	user_table);

insert into siac_rep_cap_ep
select 	cl.classif_id,
  		anno_eserc.anno anno_bilancio,
  		e.*, 
        user_table utente,
  		pdc.classif_code
 from 	siac_r_bil_elem_class rc, 
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl,
 		siac_t_bil bilancio, 
 		siac_t_periodo anno_eserc, 
 		siac_d_bil_elem_tipo tipo_elemento,
        siac_r_bil_elem_class r_capitolo_pdc,
     	siac_t_class pdc,
     	siac_d_class_tipo pdc_tipo, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_id			=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and e.elem_id						=	rc.elem_id
and r_capitolo_pdc.classif_id 		= 	pdc.classif_id
and pdc.classif_tipo_id 			= 	pdc_tipo.classif_tipo_id
and e.elem_id 						= 	r_capitolo_pdc.elem_id
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and e.ente_proprietario_id			=	p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and ct.classif_tipo_code			=	'CATEGORIA'
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and pdc_tipo.classif_tipo_code like 'PDC_%'
and	stato_capitolo.elem_stato_code	=	'VA'
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and rc.data_cancellazione 				is null
and ct.data_cancellazione 				is null
and cl.data_cancellazione 				is null
and bilancio.data_cancellazione 		is null
and anno_eserc.data_cancellazione 		is null
and tipo_elemento.data_cancellazione 	is null
and r_capitolo_pdc.data_cancellazione 	is null
and pdc.data_cancellazione 				is null
and pdc_tipo.data_cancellazione 		is null
and stato_capitolo.data_cancellazione 	is null
and r_capitolo_stato.data_cancellazione is null
and cat_del_capitolo.data_cancellazione is null
and r_cat_capitolo.data_cancellazione 	is null;

insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
             siac_d_bil_elem_tipo tipo_elemento,
             siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	bilancio.periodo_id						=	anno_eserc.periodo_id 								
        and	capitolo.bil_id							=	bilancio.bil_id 			 
        and	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
        and	capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id		
        and capitolo_importi.ente_proprietario_id 	= 	p_ente_prop_id  
    	and	anno_eserc.anno							= 	p_anno 												    							
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno 				in (p_anno_competenza)
        and	stato_capitolo.elem_stato_code		=	'VA'
		and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null      
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   	capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	0,
    	0,
   	 	0,
    	0,
    	0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1
	where			tb1.periodo_anno = p_anno_competenza	
    				AND	tb1.tipo_imp =	TipoImpComp	
                    and tb1.utente 	= 	user_table;
               


for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        tb.pdc							codice_pdc,
	   	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
		COALESCE (tb1.stanziamento_prev_anno1,0)		stanziamento_prev_anno1,
    	COALESCE (tb1.stanziamento_prev_anno2,0)		stanziamento_prev_anno2
from  	siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					----------and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            		on (tb1.elem_id	=	tb.elem_id
                    	and	tb.utente=user_table
                        and tb1.utente	=	tb.utente)
    where v1.utente = user_table 	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop

titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
stanziamento_prev_anno1:=classifBilRec.stanziamento_prev_anno1;
stanziamento_prev_anno2:=classifBilRec.stanziamento_prev_anno2;
codice_pdc:=classifBilRec.codice_pdc;


-- importi capitolo

/*raise notice 'record';*/
return next;
bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento_prev_anno=0;
stanziamento_prev_anno1=0;
stanziamento_prev_anno2=0;
codice_pdc:=0;


end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_ep where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='Ricerca dati capitolo';
		 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


update siac_t_xbrl_mapping_fatti
set xbrl_mapfat_variabile='totale_crediti_bil',
	data_modifica=now(),
    login_operazione= login_operazione|| ' - SIAC-8154'
where xbrl_mapfat_rep_codice='BILR148'
and xbrl_mapfat_variabile='crediti_stralciati_tot_crediti';

update siac_t_xbrl_mapping_fatti
set xbrl_mapfat_variabile='fondo_sval_crediti_bil',
	data_modifica=now(),
    login_operazione= login_operazione|| ' - SIAC-8154'
where xbrl_mapfat_rep_codice='BILR148'
and xbrl_mapfat_variabile='Copia_crediti_stralciati_tot_crediti';

update siac_t_xbrl_mapping_fatti
set xbrl_mapfat_variabile='totale_crediti_accert',
	data_modifica=now(),
    login_operazione= login_operazione|| ' - SIAC-8154'
where xbrl_mapfat_rep_codice='BILR148'
and xbrl_mapfat_variabile='accertamenti_successivi';


--SIAC-8154 - Maurizio - FINE


-- FNC CALCOLO CREDITI STRALCIATI
CREATE OR REPLACE FUNCTION siac.fnc_calcola_crediti_stralciati (
  p_ente_prop_id integer,
  p_anno varchar,
  p_afde_bilancio_id integer
)
RETURNS TABLE (
  afde_bil_crediti_stralciati numeric,
  afde_bil_crediti_stralciati_fcde numeric,
  afde_bil_accertamenti_anni_successivi numeric,
  afde_bil_accertamenti_anni_successivi_fcde numeric
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;

BEGIN

/* SIAC-8384 15/10/2021.
	Funzione creata per resitutire i valori dei crediti stralciati secondo le
    nuove regole comunicate.
    E' richiamata direttamente da Contabilia per presentare i campi nella
    maschera di FCDE.
*/

afde_bil_crediti_stralciati:=0;
afde_bil_crediti_stralciati_fcde:=0;
afde_bil_accertamenti_anni_successivi:=0;
afde_bil_accertamenti_anni_successivi_fcde:=0;


select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id  
  and b.periodo_id=a.periodo_id
  and b.anno=p_anno;


--Somma delle modifiche di accertamento (INEROR - ROR - Cancellazione per Inesigibilita' - entrate) 
-- + (INESIG - Cancellazione per Inesigibilita') con anno <=n
--Quindi rendiconto 2021 : modifiche accertamenti <=2021 - senza perimetro capitoli di pertinenza, 
--Titolo 1, 2, 3, 4 e 5.      
with struttura as (select *
 from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as (      
    select class.classif_id categoria_id,
       t_movgest_ts_det_mod.movgest_ts_det_importo
      from siac_t_bil_elem     capitolo , 
        siac_r_movgest_bil_elem   r_mov_capitolo, 
        siac_d_bil_elem_tipo    t_capitolo, 
        siac_t_movgest     movimento, 
        siac_d_movgest_tipo    tipo_mov, 
        siac_t_movgest_ts    ts_movimento, 
        siac_r_movgest_ts_stato   r_movimento_stato, 
        siac_d_movgest_stato    tipo_stato, 
        siac_t_movgest_ts_det   dt_movimento, 
        siac_d_movgest_ts_tipo   ts_mov_tipo, 
        siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
        siac_t_modifica t_modifica,
        siac_d_modifica_tipo d_modif_tipo,
        siac_r_modifica_stato r_mod_stato,
        siac_d_modifica_stato d_mod_stato,
        siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,
        siac_t_class class,	
        siac_d_class_tipo d_class_tipo,
        siac_r_bil_elem_class r_bil_elem_class
      where r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id
      and   class.classif_id           = r_bil_elem_class.classif_id
	  and   d_class_tipo.classif_tipo_id      = class.classif_tipo_id
      and   r_bil_elem_class.elem_id   = capitolo.elem_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id 
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      	--accertamenti con anno <=anno bilancio
      and movimento.movgest_anno 	        <= 	p_anno::integer 
      and tipo_mov.movgest_tipo_code    	= 'A' --accertamenti
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      --Prima era:
      --and d_modif_tipo.mod_tipo_code in ('CROR','ECON')
      and d_modif_tipo.mod_tipo_code in ('INEROR','INESIG')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0
      and d_class_tipo.classif_tipo_code	 = 'CATEGORIA'      
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())
      and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null  
      and class.data_cancellazione    is null  
      and d_class_tipo.data_cancellazione is null  
      and r_bil_elem_class.data_cancellazione is null)   
select  COALESCE(abs(sum(movgest_ts_det_importo)),0) afde_bil_crediti_stralciati,
    	COALESCE(abs(sum(movgest_ts_det_importo)),0) afde_bil_crediti_stralciati_fcde
into afde_bil_crediti_stralciati, afde_bil_crediti_stralciati_fcde
from struttura
	left join capitoli 
    	on struttura.categoria_id=capitoli.categoria_id 
where struttura.titolo_code::integer between 1 and 5   ;


--Sommatoria di accertamenti pluriennali >2021 SOLO del titolo 5 + accertamenti
-- pluriennali RATEIZZATI del Titolo 1 e del Titolo 3 - 
--Nel perimetro dei capitoli pertinenti ed utilizzati per il calcolo del fondo

--NB: ad oggi non e' possibile distinguere gli accertamenti pluriennali Rateizzati
-- dagli accertaementi pluriennali normali perche' non ci sono flag/menu' che li 
--identifichino. Proporremo agli enti di utilizzare un classificatore che verra' 
--settato con la dicitura "Rateizzazione del credito" per cui vi arrivera' 
--dettagliata richiesta a strettissimo giro.


with struttura as (select *
 from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, p_anno,'')),
capitoli as (      
    select class.classif_id categoria_id,       
       dt_movimento.movgest_ts_det_importo
      from siac_t_bil_elem     capitolo , 
        siac_r_movgest_bil_elem   r_mov_capitolo, 
        siac_d_bil_elem_tipo    t_capitolo, 
        siac_t_movgest     movimento, 
        siac_d_movgest_tipo    tipo_mov, 
        siac_t_movgest_ts    ts_movimento, 
        siac_r_movgest_ts_stato   r_movimento_stato, 
        siac_d_movgest_stato    tipo_stato, 
        siac_t_movgest_ts_det   dt_movimento, 
        siac_d_movgest_ts_tipo   ts_mov_tipo, 
        siac_d_movgest_ts_det_tipo  dt_mov_tipo ,        
        siac_t_class class,	
        siac_d_class_tipo d_class_tipo,
        siac_r_bil_elem_class r_bil_elem_class,
        siac_t_acc_fondi_dubbia_esig fcde
      where r_mov_capitolo.elem_id    		=	capitolo.elem_id
      and r_mov_capitolo.movgest_id    		= 	movimento.movgest_id
      and capitolo.elem_tipo_id      		= 	t_capitolo.elem_tipo_id
      and movimento.movgest_tipo_id    		= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and class.classif_id           = r_bil_elem_class.classif_id
	  and d_class_tipo.classif_tipo_id      = class.classif_tipo_id
      and r_bil_elem_class.elem_id   = capitolo.elem_id
      and fcde.elem_id						= capitolo.elem_id
	  and movimento.ente_proprietario_id   = p_ente_prop_id 
      and movimento.bil_id					=	bilancio_id 
      and t_capitolo.elem_tipo_code    		= 	'CAP-EG'
      	--accertamenti con anno > anno bilancio     
      and movimento.movgest_anno 	        > 	p_anno::integer 
      and tipo_mov.movgest_tipo_code    	= 'A' --accertamenti
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale        
      and d_class_tipo.classif_tipo_code	 = 'CATEGORIA'  
      and fcde.afde_bil_id				=  p_afde_bilancio_id    
      and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and capitolo.data_cancellazione     	is null 
      and r_mov_capitolo.data_cancellazione is null 
      and t_capitolo.data_cancellazione    	is null 
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and class.data_cancellazione    is null  
      and d_class_tipo.data_cancellazione is null  
      and r_bil_elem_class.data_cancellazione is null
      and fcde.data_cancellazione is null)   
select	COALESCE(sum(movgest_ts_det_importo),0) afde_bil_accertamenti_anni_successivi,
    	COALESCE(sum(movgest_ts_det_importo),0) afde_bil_accertamenti_anni_successivi_fcde
	into afde_bil_accertamenti_anni_successivi, afde_bil_accertamenti_anni_successivi_fcde
from struttura
	left join capitoli 
    	on struttura.categoria_id=capitoli.categoria_id 
	--devono essere presi solo i pluriennali del titolo 5 e i pluriennali
    --rateizzati dei titoli 1 e 3.
    --Al momento non si sa come distinguere quelli rateizzati.        
where struttura.titolo_code::integer in (1,3,5) ;      


return next;


exception
when no_data_found THEN
    raise notice 'nessun dato trovato.';
    return;
when others  THEN
    RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
        
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

-- SIAC-7858-FCDE -  FINE ALL SQL


-- INIZIO TEFA

select fnc_siac_bko_inserisci_azione('OP-FLUSSO-TEFA', 'Gestione Flusso TEFA', 
	'/../siacintegser/ElaboraFileService', 'AZIONE_SECONDARIA', 'FIN_BASE2');
	

	
INSERT INTO siac_d_file_tipo
( file_tipo_code,
  file_tipo_desc,
  azione_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione)
SELECT 
	'FLUSSO_TEFA',
    'Flusso TEFA',
    (SELECT a.azione_id FROM siac_t_azione a 
    WHERE a.azione_code='OP-FLUSSO-TEFA' 
    AND a.ente_proprietario_id=e.ente_proprietario_id),
    NOW(),
    e.ente_proprietario_id,
	'admin'    
FROM siac_t_ente_proprietario e
WHERE NOT EXISTS (
	SELECT 1 FROM siac_d_file_tipo ft
    WHERE ft.file_tipo_code='FLUSSO_TEFA' 
    AND ft.ente_proprietario_id=e.ente_proprietario_id
);


-- Drop table

DROP TABLE if exists siac.siac_d_tefa_trib_tipologia;

CREATE TABLE if not exists siac_d_tefa_trib_tipologia (
	tefa_trib_tipologia_id serial NOT NULL,
	tefa_trib_tipologia_code varchar(50) NULL,
	tefa_trib_tipologia_desc varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_tipo PRIMARY KEY (tefa_trib_tipologia_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_tipo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_d_tefa_trib_tipologia_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_tipologia USING btree (ente_proprietario_id);



-- Drop table

 DROP TABLE if exists siac.siac_d_tefa_tributo;

CREATE TABLE if not exists siac_d_tefa_tributo (
	tefa_trib_id serial NOT NULL,
	tefa_trib_code varchar(50) NULL,
	tefa_trib_desc varchar(250) NULL,
	tefa_trib_tipologia_id int4 NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib PRIMARY KEY (tefa_trib_id),
	CONSTRAINT siac_d_tefa_trib_tipoologia_siac_d_tefa_tributo FOREIGN KEY (tefa_trib_tipologia_id) REFERENCES siac_d_tefa_trib_tipologia(tefa_trib_tipologia_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_d_tefa_tributo_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_tributo USING btree (ente_proprietario_id);
CREATE INDEX if not exists siac_d_tefa_tributo_fk_siac_d_tefa_tipologia_idx ON siac.siac_d_tefa_tributo USING btree (tefa_trib_tipologia_id);

-- Drop table

 DROP TABLE if exists siac.siac_d_tefa_trib_comune;

CREATE TABLE if not exists siac_d_tefa_trib_comune (
	tefa_trib_comune_id serial NOT NULL,
	tefa_trib_comune_code varchar(50) NULL,
	tefa_trib_comune_desc varchar(250) NULL,
	tefa_trib_comune_cat_code varchar(50) NULL,
	tefa_trib_comune_cat_desc varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_comune PRIMARY KEY (tefa_trib_comune_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_tefa_trib_comune FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_d_tefa_trib_comune_fk_ente_proprietario_id_idx ON siac.siac_d_tefa_trib_comune USING btree (ente_proprietario_id);





-- Drop table

 DROP TABLE if exists siac.siac_d_tefa_trib_gruppo_tipo;

CREATE TABLE IF NOT EXISTS siac_d_tefa_trib_gruppo_tipo (
	tefa_trib_gruppo_tipo_id serial NOT NULL,
	tefa_trib_gruppo_tipo_code varchar(10) NULL,
	tefa_trib_gruppo_tipo_desc varchar(50) NULL,
	tefa_trib_gruppo_tipo_f1_id int4 NULL,
	tefa_trib_gruppo_tipo_f2_id int4 NULL,
	tefa_trib_gruppo_tipo_f3_id int4 NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_gruppo_tipo PRIMARY KEY (tefa_trib_gruppo_tipo_id)
);

-- Drop table

 DROP TABLE if exists siac.siac_d_tefa_trib_gruppo;

CREATE TABLE IF NOT EXISTS siac_d_tefa_trib_gruppo (
	tefa_trib_gruppo_id serial NOT NULL,
	tefa_trib_gruppo_code varchar(50) NULL,
	tefa_trib_gruppo_desc varchar(250) NULL,
	tefa_trib_gruppo_anno varchar(50) NULL,
	tefa_trib_gruppo_f1_id int4 NULL,
	tefa_trib_gruppo_f2_id int4 NULL,
	tefa_trib_gruppo_f3_id int4 NULL,
	tefa_trib_tipologia_id int4 NOT NULL,
	tefa_trib_gruppo_tipo_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_d_tefa_trib_gruppo PRIMARY KEY (tefa_trib_gruppo_id)
);



-- Drop table

 DROP TABLE if exists siac.siac_r_tefa_tributo_gruppo;

CREATE TABLE if not exists siac_r_tefa_tributo_gruppo (
	tefa_trib_gruppo_r_id serial NOT NULL,
	tefa_trib_id int4 NOT NULL,
	tefa_trib_gruppo_id int4 NOT NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_r_tefa_trib_gruooi PRIMARY KEY (tefa_trib_gruppo_r_id),
	CONSTRAINT siac_d_tefa_trib_gruppo_siac_r_tefa_trib_gruppo FOREIGN KEY (tefa_trib_gruppo_id) REFERENCES siac_d_tefa_trib_gruppo(tefa_trib_gruppo_id),
	CONSTRAINT siac_d_tefa_trib_siac_r_tefa_trib_gruppo FOREIGN KEY (tefa_trib_id) REFERENCES siac_d_tefa_tributo(tefa_trib_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_tefa_trib_gruppo FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists siac_r_tefa_trib_gruppo_fk_ente_proprietario_id_idx ON siac.siac_r_tefa_tributo_gruppo USING btree (ente_proprietario_id);
CREATE INDEX if not exists siac_r_tefa_trib_gruppo_fk_siac_d_tefa_trib_gruppo_idx ON siac.siac_r_tefa_tributo_gruppo USING btree (tefa_trib_gruppo_id);
CREATE INDEX if not exists siac_r_tefa_trib_gruppo_fk_siac_d_tefa_trib_idx ON siac.siac_r_tefa_tributo_gruppo USING btree (tefa_trib_id);


-- Drop table

 DROP TABLE if exists siac.siac_t_tefa_trib_gruppo_upload;

CREATE TABLE IF NOT EXISTS siac_t_tefa_trib_gruppo_upload (
	tefa_trib_gruppo_upload_id serial NOT NULL,
	tefa_trib_file_id int4 NOT NULL,
	tefa_trib_gruppo_tipo_id int4 NULL,
	tefa_trib_gruppo_id int4 NULL,
	tefa_trib_gruppo_upload varchar(250) NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_t_tefa_trib_gruppo_upd PRIMARY KEY (tefa_trib_gruppo_upload_id),
	CONSTRAINT siac_d_tefa_trib_gruppo_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_gruppo_id) REFERENCES siac_d_tefa_trib_gruppo(tefa_trib_gruppo_id),
	CONSTRAINT siac_d_tefa_trib_gruppo_tipo_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_gruppo_tipo_id) REFERENCES siac_d_tefa_trib_gruppo_tipo(tefa_trib_gruppo_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_file_siac_t_tefa_trib_gruppo_upd FOREIGN KEY (tefa_trib_file_id) REFERENCES siac_t_file(file_id)
);
CREATE INDEX IF NOT EXISTS siac_t_tefa_trib_gruppo_upd_fk_ente_proprietario_id_idx ON siac.siac_t_tefa_trib_gruppo_upload USING btree (ente_proprietario_id);
CREATE INDEX IF NOT EXISTS siac_t_tefa_trib_gruppo_upd_fk_tefa_trib_gruppo_idx ON siac.siac_t_tefa_trib_gruppo_upload USING btree (tefa_trib_gruppo_id);
CREATE INDEX IF NOT EXISTS siac_t_tefa_trib_gruppo_upd_fk_tefa_trib_gruppo_tipo_idx ON siac.siac_t_tefa_trib_gruppo_upload USING btree (tefa_trib_gruppo_tipo_id);
CREATE INDEX IF NOT EXISTS siac_t_tefa_trib_gruppo_upd_tefa_trib_upload_id_idx ON siac.siac_t_tefa_trib_gruppo_upload USING btree (tefa_trib_file_id);

-- Drop table

--DROP TABLE siac.siac_t_tefa_trib_importi;

CREATE TABLE IF NOT EXISTS siac_t_tefa_trib_importi (
	tefa_trib_id serial NOT NULL,
	tefa_trib_tipo_record varchar(50) NULL,
	tefa_trib_data_ripart varchar(50) NULL,
	tefa_trib_progr_ripart varchar(250) NULL,
	tefa_trib_provincia_code varchar(100) NULL,
	tefa_trib_ente_code varchar(100) NULL,
	tefa_trib_data_bonifico varchar(50) NULL,
	tefa_trib_progr_trasm varchar(250) NULL,
	tefa_trib_progr_delega varchar(250) NULL,
	tefa_trib_progr_modello varchar(250) NULL,
	tefa_trib_tipo_modello varchar(100) NULL,
	tefa_trib_comune_code varchar(100) NULL,
	tefa_trib_tributo_code varchar(100) NULL,
	tefa_trib_valuta varchar(50) NULL,
	tefa_trib_importo_versato_deb numeric NULL,
	tefa_trib_importo_compensato_cred numeric NULL,
	tefa_trib_numero_immobili varchar(100) NULL,
	tefa_trib_rateazione varchar(100) NULL,
	tefa_trib_anno_rif varchar(50) NULL,
	tefa_trib_anno_rif_str varchar(50) NULL,
	tefa_trib_file_id int4 NOT NULL,
	tefa_nome_file varchar(255) NOT NULL,
	validita_inizio timestamp NOT NULL DEFAULT now(),
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NULL,
	data_cancellazione timestamp NULL,
	login_operazione varchar(250) NULL,
	ente_proprietario_id int4 NOT NULL,
	CONSTRAINT pk_siac_t_tefa_trib PRIMARY KEY (tefa_trib_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_tefa_trib_imp FOREIGN KEY (ente_proprietario_id) REFERENCES siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_file_siac_t_tefa_trib_imp FOREIGN KEY (tefa_trib_file_id) REFERENCES siac_t_file(file_id)
);
CREATE INDEX IF NOT EXISTS  siac_t_tefa_trib_fk_ente_proprietario_id_idx ON siac.siac_t_tefa_trib_importi USING btree (ente_proprietario_id);
CREATE INDEX IF NOT EXISTS  siac_t_tefa_trib_fk_upload_id_idx ON siac.siac_t_tefa_trib_importi USING btree (tefa_trib_file_id);






/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_id integer);
drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento_all( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_raggruppamento_all( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer)
RETURNS TEXT AS
$body$
DECLARE

elenco_trib text:=null;
rec_trib record;
BEGIN


for rec_trib IN
(
WITH
gruppi as
(
select trib.tefa_trib_code,gruppo.tefa_trib_gruppo_anno
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and   r_tefa.data_cancellazione is null
and   r_tefa.validita_fine is null
and   trib.data_cancellazione is null
and   trib.validita_fine is null
and   gruppo.data_cancellazione is null
and   gruppo.validita_fine is null
order by 1 desc
)
select gruppi.tefa_trib_code,gruppi.tefa_trib_gruppo_anno
from gruppi
order by 1 desc
)
loop
 elenco_trib:= coalesce(elenco_trib,' ')||rec_trib.tefa_trib_code||'-';

end loop;

if elenco_trib is not null then
 elenco_trib:=trim(both from substring(elenco_trib,1,length(elenco_trib)-1));
end if;

return elenco_trib;


exception
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return elenco_trib;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;




/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_id integer);
drop FUNCTION if exists siac.fnc_tefa_trib_raggruppamento( p_tefa_trib_gruppo_tipo_id integer,p_tefa_trib_gruppo_id integer,p_tefa_trib_upload_id integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_raggruppamento(p_tefa_trib_gruppo_tipo_id integer, p_tefa_trib_gruppo_id integer, p_tefa_trib_upload_id integer)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE

elenco_trib text:=null;
rec_trib record;
BEGIN


for rec_trib IN
(
with 
raggruppa_sel as
(
select gruppo.tefa_trib_gruppo_anno, trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and  trib.data_cancellazione is null
and  trib.validita_fine is null
and  gruppo.data_cancellazione is null
and  gruppo.validita_fine is null
and  r_tefa.data_cancellazione is null
and  r_tefa.validita_fine is null
),
tefa_sel as
(
select trib_imp.tefa_trib_tributo_code, trib_imp.tefa_trib_anno_rif_str
from siac_t_tefa_trib_importi trib_imp
where trib_imp.tefa_trib_file_id=p_tefa_trib_upload_id
and   trib_imp.tefa_trib_tipo_record='D'
and   trib_imp.data_cancellazione is null
and   trib_imp.validita_fine is null
)
select  distinct raggruppa_sel.tefa_trib_code 
from raggruppa_sel, tefa_sel 
where tefa_sel.tefa_trib_tributo_code=raggruppa_sel.tefa_trib_code
and   tefa_sel.tefa_trib_anno_rif_str=raggruppa_sel.tefa_trib_gruppo_anno
order by 1 DESC
/*select distinct trib.tefa_trib_code
from siac_r_tefa_tributo_gruppo r_tefa,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo,
     siac_t_tefa_trib_importi trib_imp
where gruppo.tefa_trib_gruppo_tipo_id=coalesce(p_tefa_trib_gruppo_tipo_id,gruppo.tefa_trib_gruppo_tipo_id)
and   gruppo.tefa_trib_gruppo_id=coalesce(p_tefa_trib_gruppo_id,gruppo.tefa_trib_gruppo_id)
and   r_tefa.tefa_trib_id=trib.tefa_trib_id
and   gruppo.tefa_trib_gruppo_id=r_tefa.tefa_trib_gruppo_id
and   trib_imp.ente_proprietario_id=gruppo.ente_proprietario_id
and   trib_imp.tefa_trib_file_id=p_tefa_trib_upload_id
and   trib_imp.tefa_trib_tributo_code=trib.tefa_trib_code
and   trib_imp.tefa_trib_tipo_record='D'
and   gruppo.tefa_trib_gruppo_anno=trib_imp.tefa_trib_anno_rif_str*/
/*     ( case when trib_imp.tefa_trib_anno_rif::INTEGER<=2019 then '<=2019'
           when trib_imp.tefa_trib_anno_rif::INTEGER=2020 then '=2020'
           when trib_imp.tefa_trib_anno_rif::INTEGER>=2021 then '>=2021' end )*/
/*and  trib.data_cancellazione is null
and  trib.validita_fine is null
and  trib_imp.data_cancellazione is null
and  trib_imp.validita_fine is null
and  gruppo.data_cancellazione is null
and  gruppo.validita_fine is null
and  r_tefa.data_cancellazione is null
and  r_tefa.validita_fine is null
order by 1 DESC*/
)
loop
-- raise notice 'tefa_trib_code=%',rec_trib.tefa_trib_code;
 elenco_trib:= coalesce(elenco_trib,' ')||rec_trib.tefa_trib_code||'-';
-- raise notice 'elenco_trib=%',elenco_trib;

end loop;

if elenco_trib is not null then
 elenco_trib:=trim(both from substring(elenco_trib,1,length(elenco_trib)-1));
end if;

return elenco_trib;


exception
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return elenco_trib;
END;
$function$
;






/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_tefa_trib_calcolo_formule(p_tefa_trib_formula_id integer, p_tefa_trib_importo numeric);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_calcolo_formule(p_tefa_trib_formula_id integer, p_tefa_trib_importo numeric)
 RETURNS numeric
 LANGUAGE plpgsql
AS $function$
DECLARE

tefa_trib_importo numeric:=0;

BEGIN


case coalesce(p_tefa_trib_formula_id,0)
  when 1 then  -- ARROTONDA((C/100)*5/105;5)
--    tefa_trib_importo:=round((p_tefa_trib_importo/100)*5/105,5);
    tefa_trib_importo:=round((p_tefa_trib_importo)*5/105,5);
  when 2 then  -- ARROTONDA((C/100);5)
--    tefa_trib_importo:=round((p_tefa_trib_importo/100),5);
    tefa_trib_importo:=round((p_tefa_trib_importo),5);
  when 3 then  -- ARROTONDA(H*0,3/100;5)
--    tefa_trib_importo:=round((p_tefa_trib_importo*0.3/100),5);
    tefa_trib_importo:=round((p_tefa_trib_importo/100*0.3),5);   
  else   tefa_trib_importo:=null;
end case;

return tefa_trib_importo;


exception
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return tefa_trib_importo;
END;
$function$
;


--' and   com.ente_proprietario_id='||p_ente_proprietario_id::varchar||
--' and   com.tefa_trib_comune_code=tefa.tefa_trib_comune_code

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_comune_anno_rif_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
 RETURNS TABLE(codice_comune character varying, raggruppamento_codice_tributo character varying, importo_a_debito_versato numeric, importo_a_credito_compensato numeric, anno_di_riferimento_str character varying, ente character varying, anno_di_riferimento character varying, tipologia character varying, importo_tefa_lordo numeric, importo_credito numeric, importo_comm numeric, importo_tefa_netto numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE

annoPrec integer;
annoPrecPrec integer;

sql_query text;

BEGIN

 raise notice 'p_ente_proprietario_id=%',p_ente_proprietario_id::varchar;
 raise notice 'p_tefa_trib_upload_id=%',p_tefa_trib_upload_id::varchar;
 raise notice 'p_tefa_trib_comune_anno=%',p_tefa_trib_comune_anno::varchar;

 annoPrecPrec:=p_tefa_trib_comune_anno-2;
 annoPrec:=p_tefa_trib_comune_anno-1;

 raise notice 'annoPrecPrec=%',annoPrecPrec::varchar;
 raise notice 'annoPrec=%',annoPrec::varchar;

 sql_query:=
 'select query.codice_comune::varchar,
       upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,
       query.importo_a_debito_versato::numeric,
       query.importo_a_credito_compensato::numeric,
       query.anno_di_riferimento_str::varchar,
       query.ente::varchar,
       query.anno_di_riferimento::varchar,
       query.tipologia::varchar,
       query.importo_tefa_lordo::numeric,
       query.importo_credito::numeric,
       query.importo_comm::numeric,
       query.importo_tefa_netto::numeric
 from
 (

 with 
 raggruppa_sel as
 (
 select tipo.tefa_trib_tipologia_code,
        tipo.tefa_trib_tipologia_desc,
        gruppo.tefa_trib_gruppo_code,
        gruppo.tefa_trib_gruppo_desc,
        gruppo.tefa_trib_gruppo_anno,
        gruppo.tefa_trib_gruppo_f1_id,
        gruppo.tefa_trib_gruppo_f2_id,
        gruppo.tefa_trib_gruppo_f3_id,
        trib.tefa_trib_code,
        trib.tefa_trib_desc,
        trib.tefa_trib_id,
        gruppo.tefa_trib_gruppo_id,        
        tipo.tefa_trib_tipologia_id
 from  siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
       siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
  where trib.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and  r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and  gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and  tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
  and  trib.data_cancellazione is null
  and  trib.validita_fine is null
  and  gruppo.data_cancellazione is null
  and  gruppo.validita_fine is null
  and  tipo.data_cancellazione is null
  and  tipo.validita_fine is null
  and  r_gruppo.data_cancellazione is null
  and  r_gruppo.validita_fine is null
 ),
 tefa_sel as 
 (
 select tefa.tefa_trib_file_id,
        tefa.tefa_trib_tributo_code,
        tefa.tefa_trib_comune_code,
        tefa.tefa_trib_importo_versato_deb,
        tefa.tefa_trib_importo_compensato_cred,
        tefa.tefa_trib_anno_rif_str,
		tefa.tefa_trib_anno_rif,
        com.tefa_trib_comune_cat_desc
 from siac_t_tefa_trib_importi tefa 
      left join siac_d_tefa_trib_comune com on (com.ente_proprietario_id=tefa.ente_proprietario_id and com.tefa_trib_comune_code=tefa.tefa_trib_comune_code and com.data_cancellazione is null )
 where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar||      
' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar||
' and   tefa.tefa_trib_tipo_record=''D''
 and   tefa.data_cancellazione is null
 and   tefa.validita_fine is null
 )
 select
   tefa_sel.tefa_trib_file_id,
   tefa_sel.tefa_trib_comune_code codice_comune,
   raggruppa_sel.tefa_trib_gruppo_id ,
   raggruppa_sel.tefa_trib_gruppo_code,
   sum(tefa_sel.tefa_trib_importo_versato_deb) importo_a_debito_versato,
   sum(tefa_sel.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   ( case when tefa_sel.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ) anno_di_riferimento_str,
   tefa_sel.tefa_trib_comune_cat_desc ente,
  (case when tefa_sel.tefa_trib_anno_rif::integer<='||annoPrecPrec::VARCHAR||' then '||annoPrecPrec::VARCHAR||
   	     ' when tefa_sel.tefa_trib_anno_rif::integer='||annoPrec::varchar||' then tefa_sel.tefa_trib_anno_rif::integer
           when tefa_sel.tefa_trib_anno_rif::integer>='||p_tefa_trib_comune_anno::varchar||' then tefa_sel.tefa_trib_anno_rif::integer else null end ) anno_di_riferimento,   
   raggruppa_sel.tefa_trib_tipologia_desc tipologia,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_compensato_cred)
                                  ) importo_credito,
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa_sel.tefa_trib_importo_versato_deb))
                                )  importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_versato_deb)) -
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_compensato_cred)) -
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_versato_deb) )
                                  ) importo_tefa_netto
from  raggruppa_sel , tefa_sel
where raggruppa_sel.tefa_trib_code=tefa_sel.tefa_trib_tributo_code
  and raggruppa_sel.tefa_trib_gruppo_anno=tefa_sel.tefa_trib_anno_rif_str
group by tefa_sel.tefa_trib_file_id,
	     tefa_sel.tefa_trib_comune_code,
         raggruppa_sel.tefa_trib_gruppo_id,
		 raggruppa_sel.tefa_trib_gruppo_code,
         raggruppa_sel.tefa_trib_gruppo_f1_id,raggruppa_sel.tefa_trib_gruppo_f2_id,raggruppa_sel.tefa_trib_gruppo_f3_id,
		 ( case when tefa_sel.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ),
         tefa_sel.tefa_trib_comune_cat_desc,
         (case when tefa_sel.tefa_trib_anno_rif::integer<='||annoPrecPrec::VARCHAR||' then '||annoPrecPrec::VARCHAR||
   	     ' when tefa_sel.tefa_trib_anno_rif::integer='||annoPrec::varchar||' then tefa_sel.tefa_trib_anno_rif::integer
           when tefa_sel.tefa_trib_anno_rif::integer>='||p_tefa_trib_comune_anno::varchar||' then tefa_sel.tefa_trib_anno_rif::integer else null end ),
         raggruppa_sel.tefa_trib_tipologia_desc
order by 2,4
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
and   upd.data_cancellazione is null 
and   upd.validita_fine is null
order by 1,query.tefa_trib_gruppo_code::integer;'::text;

raise notice 'sql_query=%',sql_query::varchar;
return query execute sql_query;

exception
	when no_data_found THEN
    raise notice 'Nessun dato trovato.';
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return;
END;
$function$
;




/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


drop FUNCTION if exists siac.fnc_tefa_trib_comune_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_comune_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
 RETURNS TABLE(codice_comune character varying, raggruppamento_codice_tributo character varying, importo_a_debito_versato numeric, importo_a_credito_compensato numeric, anno_di_riferimento_str character varying, ente character varying, tipologia character varying, importo_tefa_lordo numeric, importo_credito numeric, importo_comm numeric, importo_tefa_netto numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE

annoPrec integer;
annoPrecPrec integer;

sql_query text;

BEGIN

 raise notice 'p_ente_proprietario_id=%',p_ente_proprietario_id::varchar;
 raise notice 'p_tefa_trib_upload_id=%',p_tefa_trib_upload_id::varchar;
 raise notice 'p_tefa_trib_comune_anno=%',p_tefa_trib_comune_anno::varchar;

 annoPrecPrec:=p_tefa_trib_comune_anno-2;
 annoPrec:=p_tefa_trib_comune_anno-1;

 raise notice 'annoPrecPrec=%',annoPrecPrec::varchar;
 raise notice 'annoPrec=%',annoPrec::varchar;

 sql_query:=
 'select query.codice_comune::varchar,
       upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,
       query.importo_a_debito_versato::numeric,
       query.importo_a_credito_compensato::numeric,
       query.anno_di_riferimento_str::varchar,
       query.ente::varchar,
       query.tipologia::varchar,
       query.importo_tefa_lordo::numeric,
       query.importo_credito::numeric,
       query.importo_comm::numeric,
       query.importo_tefa_netto::numeric
 from
 (

select
    tefa.tefa_trib_file_id,
    tefa.tefa_trib_comune_code codice_comune,
    gruppo.tefa_trib_gruppo_id ,
    sum(tefa.tefa_trib_importo_versato_deb) importo_a_debito_versato,
    sum(tefa.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ) anno_di_riferimento_str,
   com.tefa_trib_comune_cat_desc ente,
   tipo.tefa_trib_tipologia_desc tipologia,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                  ) importo_credito,
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa.tefa_trib_importo_versato_deb))
                                )  importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb)) -
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_compensato_cred)) -
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb) )
                                  ) importo_tefa_netto
from siac_t_tefa_trib_importi tefa,siac_d_tefa_trib_comune com,
     siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar||
' and   com.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   com.tefa_trib_comune_code=tefa.tefa_trib_comune_code
  and   trib.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   trib.tefa_trib_code=tefa.tefa_trib_tributo_code
  and   r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and   gruppo.tefa_trib_gruppo_anno=
       ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::varchar||' then ''<='||annoPrecPrec::varchar||''''||
       '   when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''='||annoPrec::varchar||''''||
       '   when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::VARCHAR||' then ''>='||p_tefa_trib_comune_anno::VARCHAR||''' end )
  and   tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
  and   tefa.tefa_trib_tipo_record=''D''
  and   tefa.data_cancellazione is null
  and   tefa.validita_fine is null
  and   r_gruppo.data_cancellazione is null
  and   r_gruppo.validita_fine is null
  group by tefa.tefa_trib_file_id,
	     tefa.tefa_trib_comune_code,
         gruppo.tefa_trib_gruppo_id,
         gruppo.tefa_trib_gruppo_f1_id,gruppo.tefa_trib_gruppo_f2_id,gruppo.tefa_trib_gruppo_f3_id,
		 ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ),
         com.tefa_trib_comune_cat_desc,
         tipo.tefa_trib_tipologia_desc
order by 2,3
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
order by 1,query.tefa_trib_gruppo_id;'::text;

raise notice 'sql_query=%',sql_query::varchar;
return query execute sql_query;

exception
	when no_data_found THEN
    raise notice 'Nessun dato trovato.';
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return;
END;
$function$
;





/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_tefa_trib_versamenti_estrai(p_ente_proprietario_id integer,p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_versamenti_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
 RETURNS TABLE(data_ripartizione character varying, data_bonifico character varying, raggruppamento_codice_tributo character varying, importo_a_debito_versato numeric, importo_a_credito_compensato numeric, anno_di_riferimento_str character varying, importo_tefa_lordo numeric, importo_credito numeric, importo_comm numeric, importo_tefa_netto numeric)
 LANGUAGE plpgsql
AS $function$ DECLARE  annoPrec integer; annoPrecPrec integer;  sql_query text;  BEGIN   raise notice 'p_ente_proprietario_id=%',p_ente_proprietario_id::varchar;  raise notice 'p_tefa_trib_upload_id=%',p_tefa_trib_upload_id::varchar;  raise notice 'p_tefa_trib_comune_anno=%',p_tefa_trib_comune_anno::varchar;   annoPrecPrec:=p_tefa_trib_comune_anno-2;  annoPrec:=p_tefa_trib_comune_anno-1;   raise notice 'annoPrecPrec=%',annoPrecPrec::varchar;  raise notice 'annoPrec=%',annoPrec::varchar;   sql_query:=   'select query.data_ripartizione::varchar,           query.data_bonifico::varchar,           upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,           query.importo_a_debito_versato::numeric,           query.importo_a_credito_compensato::numeric,           query.anno_di_riferimento_str::varchar,           query.importo_tefa_lordo::numeric,           query.importo_credito::numeric,           query.importo_comm::numeric,           query.importo_tefa_netto::numeric   from   (    with   raggruppa_sel as    (    select trib.tefa_trib_code, trib.tefa_trib_desc,           gruppo.tefa_trib_gruppo_code,           gruppo.tefa_trib_gruppo_desc,           gruppo.tefa_trib_gruppo_f1_id,           gruppo.tefa_trib_gruppo_f2_id,           gruppo.tefa_trib_gruppo_f3_id,           gruppo.tefa_trib_gruppo_anno, 	      tipo.tefa_trib_gruppo_tipo_code, 	      tipo.tefa_trib_gruppo_tipo_desc,  	      tipo.tefa_trib_gruppo_tipo_f1_id, 	      tipo.tefa_trib_gruppo_tipo_f2_id, 	      tipo.tefa_trib_gruppo_tipo_f3_id	, 	      trib.tefa_trib_id, 	      gruppo.tefa_trib_gruppo_id, 	      gruppo.tefa_trib_gruppo_tipo_id    from siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,         siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_gruppo_tipo tipo    where trib.ente_proprietario_id='||p_ente_proprietario_id::varchar|| '  and   r_gruppo.tefa_trib_id=trib.tefa_trib_id    and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id    and   tipo.tefa_trib_gruppo_tipo_id=gruppo.tefa_trib_gruppo_tipo_id    and   trib.data_cancellazione is null    and   trib.validita_fine is null    and   gruppo.data_cancellazione is null     and   gruppo.validita_fine is null     and   tipo.data_cancellazione is null     and   tipo.validita_fine is null     and   r_gruppo.data_cancellazione is null    and   r_gruppo.validita_fine  is null   ), '|| ' tefa_sel as    (   select tefa.tefa_trib_file_id ,tefa.tefa_trib_tributo_code,tefa.tefa_trib_data_ripart,tefa.tefa_trib_data_bonifico,tefa.tefa_trib_anno_rif,tefa.tefa_trib_anno_rif_str,          tefa.tefa_trib_importo_versato_deb,tefa.tefa_trib_importo_compensato_cred   from  siac_t_tefa_trib_importi tefa   where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar|| ' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar|| ' and   tefa.tefa_trib_tipo_record=''D''   and   tefa.data_cancellazione is null    and   tefa.validita_fine is null    ) '||  ' select    tefa_sel.tefa_trib_file_id,    (case when tefa_sel.tefa_trib_data_ripart like '''||chr(37)||'-'||chr(37)||''' then               tefa_sel.tefa_trib_data_ripart           else              substring(tefa_sel.tefa_trib_data_ripart,7,4)||''/''||substring(tefa_sel.tefa_trib_data_ripart,4,2)||''/''||substring(tefa_sel.tefa_trib_data_ripart,1,2)     end)::timestamp  data_ripartizione_dt,    (case when tefa_sel.tefa_trib_data_bonifico like '''||chr(37)||'-'||chr(37)||''' then               tefa_sel.tefa_trib_data_bonifico           else              substring(tefa_sel.tefa_trib_data_bonifico,7,4)||''/''||substring(tefa_sel.tefa_trib_data_bonifico,4,2)||''/''||substring(tefa_sel.tefa_trib_data_bonifico,1,2)     end)::timestamp  data_bonifico_dt,    (case when tefa_sel.tefa_trib_data_ripart like '''||chr(37)||'-'||chr(37)||''' then          substring(tefa_sel.tefa_trib_data_ripart,9,2)||''/''||substring(tefa_sel.tefa_trib_data_ripart,6,2)||''/''||substring(tefa_sel.tefa_trib_data_ripart,1,4)          else      tefa_sel.tefa_trib_data_ripart end)  data_ripartizione,    (case when tefa_sel.tefa_trib_data_bonifico like '''||chr(37)||'-'||chr(37)||''' then          substring(tefa_sel.tefa_trib_data_bonifico,9,2)||''/''||substring(tefa_sel.tefa_trib_data_bonifico,6,2)||''/''||substring(tefa_sel.tefa_trib_data_bonifico,1,4)          else      tefa_sel.tefa_trib_data_bonifico end)  data_bonifico,    raggruppa_sel.tefa_trib_gruppo_tipo_id,    tefa_sel.tefa_trib_anno_rif_str anno_di_riferimento_str,    sum(tefa_sel.tefa_trib_importo_versato_deb) importo_a_debito_versato ,    sum(tefa_sel.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,    fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_versato_deb)                                  ) importo_tefa_lordo ,    fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_compensato_cred)                                  ) importo_credito,    fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f3_id                                    else null                                    end                                   ),                                   fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_versato_deb)                                  )                                  ) importo_comm,    fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_versato_deb)                                  ) -   fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_compensato_cred)                                  ) -  (  fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f3_id                                    else null                                    end                                   ),                                   fnc_tefa_trib_calcolo_formule( (case      							   when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f1_id                                    when coalesce(raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_tipo_f2_id                                    else null                                    end                                   ),                                   sum(tefa_sel.tefa_trib_importo_versato_deb)                                  )                                  )  ) importo_tefa_netto from tefa_sel, raggruppa_sel where raggruppa_sel.tefa_trib_code=tefa_sel.tefa_trib_tributo_code and   raggruppa_sel.tefa_trib_gruppo_anno=tefa_sel.tefa_trib_anno_rif_str group by tefa_sel.tefa_trib_file_id, 	     tefa_sel.tefa_trib_data_ripart,          tefa_sel.tefa_trib_data_bonifico,          raggruppa_sel.tefa_trib_gruppo_tipo_id,          raggruppa_sel.tefa_trib_gruppo_tipo_f1_id,raggruppa_sel.tefa_trib_gruppo_tipo_f2_id,raggruppa_sel.tefa_trib_gruppo_tipo_f3_id,          tefa_sel.tefa_trib_anno_rif_str order by 2,3,raggruppa_sel.tefa_trib_gruppo_tipo_id ) query,siac_t_tefa_trib_gruppo_upload upd where upd.tefa_trib_file_id=query.tefa_trib_file_id and   upd.tefa_trib_gruppo_tipo_id=query.tefa_trib_gruppo_tipo_id order by query.data_ripartizione_dt,query.data_bonifico_dt,          query.tefa_trib_gruppo_tipo_id;'::text;  raise notice 'sql_query=%',sql_query::varchar;  return query execute sql_query;  exception 	when no_data_found THEN     raise notice 'Nessun dato trovato.'; 	when others  THEN  	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);     return; END; $function$
;



-- /////////////////////////////








insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '16','>=2021 TARI','>=2021',4,2,2,NULL,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='16' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );


insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '17','>=2021 TARI INTERESSI','>=2021',5,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='17' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
			
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '18','>=2021 TARI SANZIONE','>=2021',6,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='18' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
            












-- siac_d_tefa_trib_tipologia
INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
select 'TEFA', 'TEFA', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='TEFA'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
select 'INTERESSI', 'INTERESSI', now(),'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='INTERESSI'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
select 'SANZIONE', 'SANZIONE', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='SANZIONE'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
select 'TARI', 'TARI', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='TARI'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
Select 'TARI INTERESSI', 'TARI INTERESSI', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='TARI INTERESSI'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);

INSERT INTO siac.siac_d_tefa_trib_tipologia
(tefa_trib_tipologia_code, tefa_trib_tipologia_desc, validita_inizio, login_operazione, ente_proprietario_id)
Select 'TARI SANZIONE', 'TARI SANZIONE', now(), 'SIAC-8206', ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists 
(
select 1 
from siac_d_tefa_trib_tipologia tefa
where tefa.ente_proprietario_id=ente.ente_proprietario_id
and   tefa.tefa_trib_tipologia_code='TARI SANZIONE'
and   tefa.data_cancellazione is null
and   tefa.validita_fine is null
);


--- siac_d_tefa_trib_gruppo_tipo
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '1','1-2-3',1,1,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='1' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '2','4-5-6',2,2,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='2' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '3','7-12',1,1,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='3' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '4','13-14-15',2,2,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='4' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '5','16-17-18',1,1,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='5' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );
insert into siac_d_tefa_trib_gruppo_tipo 
 (tefa_trib_gruppo_tipo_code, tefa_trib_gruppo_tipo_desc,tefa_trib_gruppo_tipo_f1_id,tefa_trib_gruppo_tipo_f2_id, tefa_trib_gruppo_tipo_f3_id,validita_inizio,login_operazione,ente_proprietario_Id ) 
 select '6','19-20-21',2,2,3,now(),'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
 where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
 and   not exists
 (
 select 1
 from siac_d_tefa_trib_gruppo_tipo tipo
 where tipo.ente_proprietario_id=ente.ente_proprietario_id
 and   tipo.tefa_trib_gruppo_tipo_code='6' 
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
 );

 
 
 
 -- siac_d_tefa_trib_gruppo
 insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) 
 select '1','<=2019 TEFA','<=2019',1,1,1,3,1, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='1'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='1' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) 
   select '2','<=2019 INTERESSI','<=2019',2,1,1,3,1, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='1'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='2' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '3','<=2019 SANZIONE','<=2019',3,1,1,3,1, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='1'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='3' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '4','<=2019 TEFA','<=2019',1,2,2,3,2, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='2'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='4' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '5','<=2019 INTERESSI','<=2019',2,2,2,3,2, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='2'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='5' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '6','<=2019 SANZIONE','<=2019',3,2,2,3,2, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='2'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='6' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '7','=2020 TEFA','=2020',1,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='7' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '8','=2020 INTERESSI','=2020',2,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='8' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '9','=2020 SANZIONE','=2020',3,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='9' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '10','=2020 TEFA','=2020',1,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='10' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '11','=2020 INTERESSI','=2020',2,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='11' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '12','=2020 SANZIONE','=2020',3,1,1,3,3, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='3'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='12' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '13','=2020 TEFA','=2020',1,2,2,3,4, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='4'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='13' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '14','=2020 INTERESSI','=2020',2,2,2,3,4, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='4'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='14' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '15','=2020 SANZIONE','=2020',3,2,2,3,4, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='4'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='15' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );



insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '19','>=2021 TEFA','>=2021',1,2,2,3,6, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TEFA'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='6'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='19' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '20','>=2021 INTERESSI','>=2021',2,2,2,3,6, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='6'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='20' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '21','>=2021 SANZIONE','>=2021',3,2,2,3,6, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='6'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='21' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '16','>=2021 TARI','>=2021',4,2,2,NULL,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='16' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );


insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '17','>=2021 TARI INTERESSI','>=2021',5,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI INTERESSI'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='17' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
			
insert into siac_d_tefa_trib_gruppo 
        (tefa_trib_gruppo_code,tefa_trib_gruppo_desc,tefa_trib_gruppo_anno,tefa_trib_tipologia_id,
         tefa_trib_gruppo_f1_id,tefa_trib_gruppo_f2_id,tefa_trib_gruppo_f3_id,
         tefa_trib_gruppo_tipo_id,ente_proprietario_id,validita_inizio,login_operazione ) select '18','>=2021 TARI SANZIONE','>=2021',6,2,2,null,5, ente.ente_proprietario_id,now(),'SIAC-8206' 
       from siac_t_ente_proprietario ente , siac_d_tefa_trib_gruppo_tipo gr_tipo,siac_d_tefa_trib_tipologia  tipo
       where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
       and   tipo.ente_proprietario_id=ente.ente_proprietario_id
       and   tipo.tefa_trib_tipologia_code='TARI SANZIONE'  and gr_tipo.ente_proprietario_id=ente.ente_proprietario_id 
           and gr_tipo.tefa_trib_gruppo_tipo_code='5'  and not exists 
          ( select 1 from siac_d_tefa_trib_gruppo gruppo 
            where gruppo.ente_proprietario_id=ente.ente_proprietario_id     
            and   gruppo.tefa_trib_gruppo_code='18' and   gruppo.tefa_trib_tipologia_id=tipo.tefa_trib_tipologia_id
            and   gruppo.tefa_trib_gruppo_tipo_id=gr_tipo.tefa_trib_gruppo_tipo_id
            and   gruppo.data_cancellazione is null
            and   gruppo.validita_fine is null  );
            
            
            
            

			
-- siac_d_tefa_tributo

insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3920','3920', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3920' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3921','3921', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3921' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3922','3922', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3922' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3944','3944', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3944' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3945','3945', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3945' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3946','3946', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3946' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3950','3950', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3950' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3951','3951', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3951' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '3952','3952', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='3952' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '365E','365E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='365E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '366E','366E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='366E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '367E','367E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='367E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '368E','368E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='368E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '369E','369E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='369E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select '370E','370E', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='370E' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'TEFA','TEFA', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='TEFA' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'TEFN','TEFN', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='TEFN' and tefa.data_cancellazione is null and tefa.validita_fine is null );
insert into siac_d_tefa_tributo  ( tefa_trib_code,tefa_trib_desc,validita_inizio,login_operazione,ente_proprietario_id )  
select 'TEFZ','TEFZ', now(), 'SIAC-8206', ente.ente_proprietario_id  from siac_t_ente_proprietario ente 
           where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
           and   not exists 
           (select 1 
            from siac_d_tefa_tributo tefa
            where tefa.ente_proprietario_id=ente.ente_proprietario_id
            and   tefa.tefa_trib_code='TEFZ' and tefa.data_cancellazione is null and tefa.validita_fine is null );
			
-- siac_d_tefa_trib_comune
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A074','AGLIE''','A074','AGLIE'' (07044)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A074'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A109','AIRASCA','A109','AIRASCA (07166)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A109'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A117','ALA DI STURA','A117','ALA DI STURA (07117)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A117'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A157','ALBIANO D''IVREA','A157','ALBIANO D''IVREA (07073)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A157'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A199','ALICE SUPERIORE','A199','ALICE SUPERIORE (07102)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A199'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A218','ALMESE','A218','ALMESE (06963)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A218'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A221','ALPETTE','A221','ALPETTE (07056)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A221'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A222','ALPIGNANO','A222','ALPIGNANO (07204)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A222'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A275','ANDEZENO','A275','ANDEZENO (06979)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A275'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A282','ANDRATE','A282','ANDRATE (07089)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A282'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A295','ANGROGNA','A295','ANGROGNA (07174)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A295'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A405','ARIGNANO','A405','ARIGNANO (06980)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A405'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A518','AVIGLIANA','A518','AVIGLIANA (06959)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A518'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A525','AZEGLIO','A525','AZEGLIO (07072)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A525'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A584','BAIRO','A584','BAIRO (07045)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A584'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A587','BALANGERO','A587','BALANGERO (07108)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A587'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A590','BALDISSERO CANAVESE','A590','BALDISSERO CANAVESE (07048)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A590'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A591','BALDISSERO TORINESE','A591','BALDISSERO TORINESE (06981)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A591'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A599','BALME','A599','BALME (07118)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A599'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A607','BANCHETTE','A607','BANCHETTE (07080)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A607'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A625','BARBANIA','A625','BARBANIA (07015)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A625'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A651','BARDONECCHIA','A651','BARDONECCHIA (07244)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A651'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A673','BARONE CANAVESE','A673','BARONE CANAVESE (07227)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A673'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A734','BEINASCO','A734','BEINASCO (07198)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A734'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A853','BIBIANA','A853','BIBIANA (07152)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A853'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A910','BOBBIO PELLICE','A910','BOBBIO PELLICE (07175)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A910'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A941','BOLLENGO','A941','BOLLENGO (07067)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A941'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'A990','BORGARO TORINESE','A990','BORGARO TORINESE (07024)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='A990'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B003','BORGIALLO','B003','BORGIALLO (07033)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B003'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B015','BORGOFRANCO D''IVREA','B015','BORGOFRANCO D''IVREA (07090)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B015'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B021','BORGOMASINO','B021','BORGOMASINO (07221)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B021'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B024','BORGONE SUSA','B024','BORGONE SUSA (07256)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B024'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B075','BOSCONERO','B075','BOSCONERO (07189)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B075'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B121','BRANDIZZO','B121','BRANDIZZO (06993)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B121'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B171','BRICHERASIO','B171','BRICHERASIO (07148)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B171'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B205','BROSSO','B205','BROSSO (07097)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B205'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B209','BROZOLO','B209','BROZOLO (06999)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B209'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B216','BRUINO','B216','BRUINO (07199)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B216'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B225','BRUSASCO','B225','BRUSASCO (06998)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B225'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B232','BRUZOLO','B232','BRUZOLO (07246)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B232'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B278','BURIASCO','B278','BURIASCO (07153)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B278'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B279','BUROLO','B279','BUROLO (07068)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B279'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B284','BUSANO','B284','BUSANO (07185)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B284'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B297','BUSSOLENO','B297','BUSSOLENO (07245)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B297'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B305','BUTTIGLIERA ALTA','B305','BUTTIGLIERA ALTA (06960)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B305'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B350','CAFASSE','B350','CAFASSE (07115)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B350'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B435','CALUSO','B435','CALUSO (07226)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B435'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B462','CAMBIANO','B462','CAMBIANO (06982)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B462'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B512','CAMPIGLIONE FENILE','B512','CAMPIGLIONE FENILE (07157)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B512'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B588','CANDIA CANAVESE','B588','CANDIA CANAVESE (07228)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B588'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B592','CANDIOLO','B592','CANDIOLO (07200)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B592'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B605','CANISCHIO','B605','CANISCHIO (07034)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B605'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B628','CANTALUPA','B628','CANTALUPA (07159)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B628'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B637','CANTOIRA','B637','CANTOIRA (07119)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B637'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B705','CAPRIE','B705','CAPRIE (06967)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B705'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B733','CARAVINO','B733','CARAVINO (07222)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B733'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B762','CAREMA','B762','CAREMA (07091)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B762'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B777','CARIGNANO','B777','CARIGNANO (07130)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B777'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B791','CARMAGNOLA','B791','CARMAGNOLA (06973)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B791'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B867','CASALBORGONE','B867','CASALBORGONE (07003)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B867'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B953','CASCINETTE D''IVREA','B953','CASCINETTE D''IVREA (07069)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B953'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B955','CASELETTE','B955','CASELETTE (07205)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B955'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B960','CASELLE TORINESE','B960','CASELLE TORINESE (07023)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B960'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C045','CASTAGNETO PO','C045','CASTAGNETO PO (06994)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C045'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C048','CASTAGNOLE PIEMONTE','C048','CASTAGNOLE PIEMONTE (07167)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C048'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C133','CASTELLAMONTE','C133','CASTELLAMONTE (07047)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C133'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C241','CASTELNUOVO NIGRA','C241','CASTELNUOVO NIGRA (07049)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C241'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C307','CASTIGLIONE TORINESE','C307','CASTIGLIONE TORINESE (07007)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C307'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C369','CAVAGNOLO','C369','CAVAGNOLO (07000)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C369'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C404','CAVOUR','C404','CAVOUR (07156)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C404'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C487','CERCENASCO','C487','CERCENASCO (07262)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C487'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C497','CERES','C497','CERES (07116)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C497'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C505','CERESOLE REALE','C505','CERESOLE REALE (07053)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C505'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C564','CESANA TORINESE','C564','CESANA TORINESE (07251)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C564'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C604','CHIALAMBERTO','C604','CHIALAMBERTO (07120)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C604'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C610','CHIANOCCO','C610','CHIANOCCO (07247)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C610'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C624','CHIAVERANO','C624','CHIAVERANO (07070)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C624'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C627','CHIERI','C627','CHIERI (06978)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C627'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C629','CHIESANUOVA','C629','CHIESANUOVA (07035)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C629'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C639','CHIOMONTE','C639','CHIOMONTE (07234)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C639'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C655','CHIUSA DI SAN MICHELE','C655','CHIUSA DI SAN MICHELE (06961)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C655'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C665','CHIVASSO','C665','CHIVASSO (06992)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C665'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C679','CICONIO','C679','CICONIO (07183)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C679'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C711','CINTANO','C711','CINTANO (07050)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C711'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C715','CINZANO','C715','CINZANO (07013)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C715'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C722','CIRIE''','C722','CIRIE'' (07014)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C722'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C793','CLAVIERE','C793','CLAVIERE (07252)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C793'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C801','COASSOLO TORINESE','C801','COASSOLO TORINESE (07109)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C801'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C803','COAZZE','C803','COAZZE (06969)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C803'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C860','COLLEGNO','C860','COLLEGNO (07206)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C860'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C867','COLLERETTO CASTELNUOVO','C867','COLLERETTO CASTELNUOVO (07036)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C867'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C868','COLLERETTO GIACOSA','C868','COLLERETTO GIACOSA (07081)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C868'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'C955','CONDOVE','C955','CONDOVE (06966)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='C955'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D008','CORIO','D008','CORIO (07025)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D008'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D092','COSSANO CANAVESE','D092','COSSANO CANAVESE (07223)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D092'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D197','CUCEGLIO','D197','CUCEGLIO (07213)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D197'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D202','CUMIANA','D202','CUMIANA (07158)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D202'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D208','CUORGNE''','D208','CUORGNE'' (07032)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D208'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D373','DRUENTO','D373','DRUENTO (06955)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D373'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D433','EXILLES','D433','EXILLES (07235)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D433'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D520','FAVRIA','D520','FAVRIA (07179)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D520'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D524','FELETTO','D524','FELETTO (07180)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D524'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D532','FENESTRELLE','D532','FENESTRELLE (07139)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D532'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D562','FIANO','D562','FIANO (07027)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D562'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D608','FIORANO CANAVESE','D608','FIORANO CANAVESE (07078)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D608'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D646','FOGLIZZO','D646','FOGLIZZO (07011)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D646'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D725','FORNO CANAVESE','D725','FORNO CANAVESE (07186)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D725'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D781','FRASSINETTO','D781','FRASSINETTO (07057)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D781'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D805','FRONT','D805','FRONT (07016)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D805'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D812','FROSSASCO','D812','FROSSASCO (07160)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D812'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D931','GARZIGLIANA','D931','GARZIGLIANA (07149)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D931'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D933','GASSINO TORINESE','D933','GASSINO TORINESE (07006)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D933'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D983','GERMAGNANO','D983','GERMAGNANO (07110)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D983'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E009','GIAGLIONE','E009','GIAGLIONE (07236)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E009'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E020','GIAVENO','E020','GIAVENO (06968)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E020'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E067','GIVOLETTO','E067','GIVOLETTO (07207)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E067'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E154','GRAVERE','E154','GRAVERE (07237)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E154'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E199','GROSCAVALLO','E199','GROSCAVALLO (07121)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E199'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E203','GROSSO','E203','GROSSO (07111)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E203'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E216','GRUGLIASCO','E216','GRUGLIASCO (07194)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E216'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E301','INGRIA','E301','INGRIA (07058)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E301'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E311','INVERSO PINASCA','E311','INVERSO PINASCA (07135)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E311'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E345','ISOLABELLA','E345','ISOLABELLA (06975)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E345'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E368','ISSIGLIO','E368','ISSIGLIO (07103)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E368'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E379','IVREA','E379','IVREA (07066)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E379'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E394','LA CASSA','E394','LA CASSA (07208)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E394'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E423','LA LOGGIA','E423','LA LOGGIA (07131)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E423'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E445','LANZO TORINESE','E445','LANZO TORINESE (07107)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E445'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E484','LAURIANO','E484','LAURIANO (07004)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E484'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E518','LEINI','E518','LEINI (07031)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E518'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E520','LEMIE','E520','LEMIE (07122)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E520'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E551','LESSOLO','E551','LESSOLO (07077)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E551'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E566','LEVONE','E566','LEVONE (07187)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E566'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E635','LOCANA','E635','LOCANA (07052)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E635'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E660','LOMBARDORE','E660','LOMBARDORE (07190)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E660'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E661','LOMBRIASCO','E661','LOMBRIASCO (07265)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E661'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E683','LORANZE''','E683','LORANZE'' (07082)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E683'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E727','LUGNACCO','E727','LUGNACCO (07104)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E727'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E758','LUSERNA SAN GIOVANNI','E758','LUSERNA SAN GIOVANNI (07162)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E758'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E759','LUSERNETTA','E759','LUSERNETTA (07163)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E759'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E763','LUSIGLIE''','E763','LUSIGLIE'' (07064)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E763'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E782','MACELLO','E782','MACELLO (07154)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E782'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E817','MAGLIONE','E817','MAGLIONE (07224)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E817'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M316','MAPPANO','M316','MAPPANO (00000)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M316'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'E941','MARENTINO','E941','MARENTINO (06983)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='E941'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F041','MASSELLO','F041','MASSELLO (07144)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F041'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F053','MATHI','F053','MATHI (07112)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F053'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F058','MATTIE','F058','MATTIE (07238)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F058'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F067','MAZZE''','F067','MAZZE'' (07229)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F067'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F074','MEANA DI SUSA','F074','MEANA DI SUSA (07239)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F074'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F140','MERCENASCO','F140','MERCENASCO (07214)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F140'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F164','MEUGLIANO','F164','MEUGLIANO (07098)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F164'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F182','MEZZENILE','F182','MEZZENILE (07123)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F182'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F315','MOMBELLO DI TORINO','F315','MOMBELLO DI TORINO (06984)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F315'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F318','MOMPANTERO','F318','MOMPANTERO (07240)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F318'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F327','MONASTERO DI LANZO','F327','MONASTERO DI LANZO (07113)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F327'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F335','MONCALIERI','F335','MONCALIERI (07127)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F335'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'D553','MONCENISIO','D553','MONCENISIO (07241)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='D553'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F407','MONTALDO TORINESE','F407','MONTALDO TORINESE (06985)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F407'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F411','MONTALENGHE','F411','MONTALENGHE (07230)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F411'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F420','MONTALTO DORA','F420','MONTALTO DORA (07071)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F420'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F422','MONTANARO','F422','MONTANARO (07010)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F422'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F651','MONTEU DA PO','F651','MONTEU DA PO (07002)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F651'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F733','MORIONDO TORINESE','F733','MORIONDO TORINESE (06986)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F733'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F889','NICHELINO','F889','NICHELINO (07128)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F889'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F906','NOASCA','F906','NOASCA (07054)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F906'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F925','NOLE','F925','NOLE (07017)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F925'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F927','NOMAGLIO','F927','NOMAGLIO (07092)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F927'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F931','NONE','F931','NONE (07165)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F931'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'F948','NOVALESA','F948','NOVALESA (07242)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='F948'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G010','OGLIANICO','G010','OGLIANICO (07181)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G010'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G087','ORBASSANO','G087','ORBASSANO (07197)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G087'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G109','ORIO CANAVESE','G109','ORIO CANAVESE (07231)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G109'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G151','OSASCO','G151','OSASCO (07169)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G151'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G152','OSASIO','G152','OSASIO (07266)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G152'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G196','OULX','G196','OULX (07258)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G196'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G202','OZEGNA','G202','OZEGNA (07182)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G202'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G262','PALAZZO CANAVESE','G262','PALAZZO CANAVESE (07074)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G262'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G303','PANCALIERI','G303','PANCALIERI (07264)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G303'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G330','PARELLA','G330','PARELLA (07083)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G330'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G387','PAVAROLO','G387','PAVAROLO (06987)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G387'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G392','PAVONE CANAVESE','G392','PAVONE CANAVESE (07079)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G392'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G396','PECCO','G396','PECCO (07105)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G396'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G398','PECETTO TORINESE','G398','PECETTO TORINESE (06988)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G398'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G463','PEROSA ARGENTINA','G463','PEROSA ARGENTINA (07134)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G463'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G462','PEROSA CANAVESE','G462','PEROSA CANAVESE (07215)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G462'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G465','PERRERO','G465','PERRERO (07143)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G465'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G477','PERTUSIO','G477','PERTUSIO (07037)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G477'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G505','PESSINETTO','G505','PESSINETTO (07124)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G505'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G559','PIANEZZA','G559','PIANEZZA (07203)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G559'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G672','PINASCA','G672','PINASCA (07136)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G672'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G674','PINEROLO','G674','PINEROLO (07147)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G674'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G678','PINO TORINESE','G678','PINO TORINESE (06989)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G678'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G684','PIOBESI TORINESE','G684','PIOBESI TORINESE (07133)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G684'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G691','PIOSSASCO','G691','PIOSSASCO (07211)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G691'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G705','PISCINA','G705','PISCINA (07155)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G705'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G719','PIVERONE','G719','PIVERONE (07075)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G719'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G777','POIRINO','G777','POIRINO (06974)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G777'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G805','POMARETTO','G805','POMARETTO (07137)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G805'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G826','PONT CANAVESE','G826','PONT CANAVESE (07055)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G826'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G900','PORTE','G900','PORTE (07150)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G900'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G973','PRAGELATO','G973','PRAGELATO (07140)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G973'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G978','PRALI','G978','PRALI (07145)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G978'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G979','PRALORMO','G979','PRALORMO (06976)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G979'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G982','PRAMOLLO','G982','PRAMOLLO (07170)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G982'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G986','PRAROSTINO','G986','PRAROSTINO (07171)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G986'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G988','PRASCORSANO','G988','PRASCORSANO (07038)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G988'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'G997','PRATIGLIONE','G997','PRATIGLIONE (07039)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='G997'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H100','QUAGLIUZZO','H100','QUAGLIUZZO (07084)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H100'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H120','QUASSOLO','H120','QUASSOLO (07093)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H120'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H127','QUINCINETTO','H127','QUINCINETTO (07094)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H127'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H207','REANO','H207','REANO (06970)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H207'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H270','RIBORDONE','H270','RIBORDONE (07059)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H270'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H337','RIVA PRESSO CHIERI','H337','RIVA PRESSO CHIERI (06990)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H337'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H333','RIVALBA','H333','RIVALBA (07008)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H333'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H335','RIVALTA DI TORINO','H335','RIVALTA DI TORINO (07201)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H335'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H338','RIVARA','H338','RIVARA (07184)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H338'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H340','RIVAROLO CANAVESE','H340','RIVAROLO CANAVESE (07178)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H340'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H344','RIVAROSSA','H344','RIVAROSSA (07191)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H344'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H355','RIVOLI','H355','RIVOLI (07193)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H355'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H367','ROBASSOMERO','H367','ROBASSOMERO (07028)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H367'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H386','ROCCA CANAVESE','H386','ROCCA CANAVESE (07026)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H386'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H498','ROLETTO','H498','ROLETTO (07161)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H498'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H511','ROMANO CANAVESE','H511','ROMANO CANAVESE (07216)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H511'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H539','RONCO CANAVESE','H539','RONCO CANAVESE (07060)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H539'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H547','RONDISSONE','H547','RONDISSONE (06995)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H547'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H554','RORA''','H554','RORA'' (07164)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H554'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H583','ROSTA','H583','ROSTA (07195)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H583'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H555','ROURE','H555','ROURE (07141)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H555'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H627','RUBIANA','H627','RUBIANA (06964)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H627'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H631','RUEGLIO','H631','RUEGLIO (07106)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H631'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H691','SALASSA','H691','SALASSA (07040)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H691'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H684','SALBERTRAND','H684','SALBERTRAND (07259)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H684'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H702','SALERANO CANAVESE','H702','SALERANO CANAVESE (07085)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H702'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H734','SALZA DI PINEROLO','H734','SALZA DI PINEROLO (07146)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H734'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H753','SAMONE','H753','SAMONE (07086)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H753'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H775','SAN BENIGNO CANAVESE','H775','SAN BENIGNO CANAVESE (07188)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H775'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H789','SAN CARLO CANAVESE','H789','SAN CARLO CANAVESE (07018)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H789'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H804','SAN COLOMBANO BELMONTE','H804','SAN COLOMBANO BELMONTE (07041)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H804'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H820','SAN DIDERO','H820','SAN DIDERO (07248)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H820'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H847','SAN FRANCESCO AL CAMPO','H847','SAN FRANCESCO AL CAMPO (07019)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H847'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H862','SAN GERMANO CHISONE','H862','SAN GERMANO CHISONE (07172)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H862'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H873','SAN GILLIO','H873','SAN GILLIO (07209)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H873'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H890','SAN GIORGIO CANAVESE','H890','SAN GIORGIO CANAVESE (07063)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H890'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H900','SAN GIORIO DI SUSA','H900','SAN GIORIO DI SUSA (07249)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H900'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H936','SAN GIUSTO CANAVESE','H936','SAN GIUSTO CANAVESE (07065)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H936'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H997','SAN MARTINO CANAVESE','H997','SAN MARTINO CANAVESE (07217)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H997'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I024','SAN MAURIZIO CANAVESE','I024','SAN MAURIZIO CANAVESE (07020)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I024'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I030','SAN MAURO TORINESE','I030','SAN MAURO TORINESE (06956)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I030'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I090','SAN PIETRO VAL LEMINA','I090','SAN PIETRO VAL LEMINA (07151)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I090'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I126','SAN PONSO','I126','SAN PONSO (07042)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I126'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I137','SAN RAFFAELE CIMENA','I137','SAN RAFFAELE CIMENA (07009)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I137'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I152','SAN SEBASTIANO DA PO','I152','SAN SEBASTIANO DA PO (07005)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I152'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I154','SAN SECONDO DI PINEROLO','I154','SAN SECONDO DI PINEROLO (07168)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I154'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'H855','SANGANO','H855','SANGANO (07202)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='H855'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I258','SANT''AMBROGIO DI TORINO','I258','SANT'' AMBROGIO DI TORINO (06962)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I258'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I296','SANT''ANTONINO DI SUSA','I296','SANT''ANTONINO DI SUSA (07255)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I296'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I327','SANTENA','I327','SANTENA (06991)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I327'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I466','SAUZE D''OULX','I466','SAUZE D''OULX (07260)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I466'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I465','SAUZE DI CESANA','I465','SAUZE DI CESANA (07253)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I465'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I490','SCALENGHE','I490','SCALENGHE (07263)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I490'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I511','SCARMAGNO','I511','SCARMAGNO (07218)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I511'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I539','SCIOLZE','I539','SCIOLZE (07012)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I539'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I692','SESTRIERE','I692','SESTRIERE (07254)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I692'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I701','SETTIMO ROTTARO','I701','SETTIMO ROTTARO (07076)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I701'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I703','SETTIMO TORINESE','I703','SETTIMO TORINESE (06957)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I703'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I702','SETTIMO VITTONE','I702','SETTIMO VITTONE (07088)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I702'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I886','SPARONE','I886','SPARONE (07061)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I886'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I969','STRAMBINELLO','I969','STRAMBINELLO (07087)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I969'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'I970','STRAMBINO','I970','STRAMBINO (07212)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='I970'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L013','SUSA','L013','SUSA (07233)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L013'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L066','TAVAGNASCO','L066','TAVAGNASCO (07095)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L066'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L219','TORINO','L219','TORINO (06954)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L219'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L238','TORRAZZA PIEMONTE','L238','TORRAZZA PIEMONTE (06996)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L238'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L247','TORRE CANAVESE','L247','TORRE CANAVESE (07046)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L247'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L277','TORRE PELLICE','L277','TORRE PELLICE (07173)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L277'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L327','TRANA','L327','TRANA (06971)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L327'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L338','TRAUSELLA','L338','TRAUSELLA (07099)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L338'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L345','TRAVERSELLA','L345','TRAVERSELLA (07100)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L345'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L340','TRAVES','L340','TRAVES (07114)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L340'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L445','TROFARELLO','L445','TROFARELLO (07129)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L445'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L515','USSEAUX','L515','USSEAUX (07142)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L515'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L516','USSEGLIO','L516','USSEGLIO (07125)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L516'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L538','VAIE','L538','VAIE (07257)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L538'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L555','VAL DELLA TORRE','L555','VAL DELLA TORRE (07210)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L555'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M405','VAL DI CHY','M405','VAL DI CHY (99997)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M405'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M415','VALCHIUSA','M415','VALCHIUSA (99998)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M415'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L578','VALGIOIE','L578','VALGIOIE (06972)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L578'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L629','VALLO TORINESE','L629','VALLO TORINESE (07029)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L629'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L644','VALPERGA','L644','VALPERGA (07043)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L644'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'B510','VALPRATO SOANA','B510','VALPRATO SOANA (07062)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='B510'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L685','VARISELLA','L685','VARISELLA (07030)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L685'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L698','VAUDA CANAVESE','L698','VAUDA CANAVESE (07021)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L698'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L727','VENARIA REALE','L727','VENARIA REALE (06958)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L727'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L726','VENAUS','L726','VENAUS (07243)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L726'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L779','VEROLENGO','L779','VEROLENGO (06997)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L779'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L787','VERRUA SAVOIA','L787','VERRUA SAVOIA (07001)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L787'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L811','VESTIGNE''','L811','VESTIGNE'' (07225)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L811'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L830','VIALFRE''','L830','VIALFRE'' (07219)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L830'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L548','VICO CANAVESE','L548','VICO CANAVESE (07096)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L548'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L857','VIDRACCO','L857','VIDRACCO (07051)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L857'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L898','VIGONE','L898','VIGONE (07261)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L898'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L948','VILLAFRANCA PIEMONTE','L948','VILLAFRANCA PIEMONTE (07268)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L948'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L982','VILLANOVA CANAVESE','L982','VILLANOVA CANAVESE (07022)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L982'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'L999','VILLAR DORA','L999','VILLAR DORA (06965)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='L999'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M007','VILLAR FOCCHIARDO','M007','VILLAR FOCCHIARDO (07250)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M007'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M013','VILLAR PELLICE','M013','VILLAR PELLICE (07176)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M013'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M014','VILLAR PEROSA','M014','VILLAR PEROSA (07138)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M014'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M002','VILLARBASSE','M002','VILLARBASSE (07196)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M002'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M004','VILLAREGGIA','M004','VILLAREGGIA (07232)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M004'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M027','VILLASTELLONE','M027','VILLASTELLONE (06977)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M027'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M060','VINOVO','M060','VINOVO (07132)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M060'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M069','VIRLE PIEMONTE','M069','VIRLE PIEMONTE (07267)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M069'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M071','VISCHE','M071','VISCHE (07220)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M071'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M080','VISTRORIO','M080','VISTRORIO (07101)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M080'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M094','VIU''','M094','VIU'' (07126)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M094'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M122','VOLPIANO','M122','VOLPIANO (07192)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M122'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );
insert into siac_d_tefa_trib_comune (tefa_trib_comune_code,tefa_trib_comune_desc , tefa_trib_comune_cat_code,tefa_trib_comune_cat_desc,validita_inizio,login_operazione,ente_proprietario_id )  select 'M133','VOLVERA','M133','VOLVERA (07177)', now(), 'SIAC-8206',  ente.ente_proprietario_id  from siac_t_ente_proprietario ente
            where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
            and   not exists 
           (
            select 1
            from siac_d_tefa_trib_comune com 
            where com.ente_proprietario_id=ente.ente_proprietario_id
            and   com.tefa_trib_comune_code='M133'
            and   com.data_cancellazione is null
            and   com.validita_fine is null
           );

			
-- siac_r_tefa_tributo_gruppo
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3920' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3944' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3950' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='365E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='368E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='1' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3921' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3945' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3951' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='366E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='369E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='2' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3922' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3946' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3952' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='367E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='370E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='3' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFA' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='4' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFN' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='5' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFZ' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='6' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3920' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='7' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3921' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='8' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3922' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='9' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3944' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='10' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3950' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='10' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='365E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='10' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='368E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='10' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3945' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='11' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3951' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='11' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='366E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='11' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='369E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='11' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3946' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='12' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3952' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='12' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='367E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='12' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='370E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='12' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFA' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='13' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFN' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='14' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFZ' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='15' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3920' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3944' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3950' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='365E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='368E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='16' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3921' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3945' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3951' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='366E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='369E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='17' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3922' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3946' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='3952' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='367E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='370E' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='18' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFA' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='19' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFN' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='20' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );
insert into siac_r_tefa_tributo_gruppo (tefa_trib_gruppo_id,tefa_trib_id,validita_inizio,login_operazione,ente_proprietario_id )  select gruppo.tefa_trib_gruppo_id,trib.tefa_trib_id,now(),'SIAC-8206',ente.ente_proprietario_id  from siac_t_ente_proprietario ente,siac_d_tefa_tributo trib,siac_d_tefa_trib_gruppo gruppo   where ente.ente_proprietario_id in (2,3,4,5,10,14,16) 
           and   trib.ente_proprietario_id=ente.ente_proprietario_id 
           and   trib.tefa_trib_code='TEFZ' and   gruppo.ente_proprietario_id=ente.ente_proprietario_id 
           and   gruppo.tefa_trib_gruppo_code='21' and   trib.data_cancellazione is null and trib.validita_fine is null  and   gruppo.data_cancellazione is null and gruppo.validita_fine is null  and   not exists 
           (
                 select 1 
                 from siac_r_tefa_tributo_gruppo r
                 where r.ente_proprietario_id=ente.ente_proprietario_id
			     and   r.tefa_trib_id=trib.tefa_trib_id
                 and   r.tefa_trib_gruppo_id=gruppo.tefa_trib_gruppo_id
                 and   r.data_cancellazione is null
                 and   r.validita_fine is null
           );

           
 --//////////////////////////// 



CREATE INDEX if not exists siac_t_tefa_trib_fk_tefa_nome_file_idx ON siac_t_tefa_trib_importi USING btree (tefa_nome_file);

            
 CREATE INDEX if not exists siac_d_tefa_tributo_fk_siac_d_tefa_trib_code_idx ON siac.siac_d_tefa_tributo USING btree (ente_proprietario_id, tefa_trib_code);






-- FINE TEFA