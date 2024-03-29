/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_bko_caricamento_pdce_conto
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
/*    and   not exists
    (
    select 1
    from siac_t_class c1
    where c1.ente_proprietario_id=tipo.ente_proprietario_id
    and   c1.classif_tipo_id=tipo.classif_tipo_id
    and   c1.classif_code='a'
    and   c1.data_cancellazione is null
    )*/
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
    );
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
    );
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
    );
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
   	raise notice 'Codifiche di bilancio  pdce_conto inserite=%',codResult;


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
    set     data_cancellazione=clock_timestamp(),
            validita_fine=clock_timestamp(),
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
         siac_v_dwh_codifiche_econpatr dwh
    where ente.ente_proprietario_id=enteProprietarioId
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



CREATE OR REPLACE FUNCTION fnc_siac_bko_caricamento_causali
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
    numeroCausali integer:=null;
    dateInizVal timestamp:=null;
BEGIN

	strMessaggioFinale:='Inserimento causale di generale ambitoCode='||ambitoCode||'.';

    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica esistenza causali da creare in siac_bko_t_caricamento_causali.';
    select 1 into codResult
    from siac_bko_t_caricamento_causali bko
    where bko.ente_proprietario_id=enteProprietarioId
    and   bko.ambito=ambitoCode
    and   bko.caricata=false
    and   bko.data_cancellazione is null
	and   bko.validita_fine is null;

    if codResult is null then
    	raise exception ' Causali non presenti.';
    end if;

    strMessaggio:='Pulizia blanck siac_bko_t_caricamento_causali.';
    update siac_bko_t_caricamento_causali bko
    set    pdc_fin=ltrim(rtrim(bko.pdc_fin)),
           codice_causale=ltrim(rtrim(bko.codice_causale)),
           descrizione_causale=ltrim(rtrim(bko.descrizione_causale)),
           pdc_econ_patr=ltrim(rtrim(bko.pdc_econ_patr)),
           segno=ltrim(rtrim(bko.segno)),
           conto_iva=ltrim(rtrim(bko.conto_iva)),
           livelli=ltrim(rtrim(bko.livelli)),
           tipo_conto=ltrim(rtrim(bko.tipo_conto)),
           tipo_importo=ltrim(rtrim(bko.tipo_importo)),
           utilizzo_conto=ltrim(rtrim(bko.utilizzo_conto)),
           utilizzo_importo=ltrim(rtrim(bko.utilizzo_importo)),
           causale_default=ltrim(rtrim(bko.causale_default))
    where bko.ente_proprietario_id=enteProprietarioId
    and   bko.ambito=ambitoCode
    and   bko.caricata=false
    and   bko.data_cancellazione is null
	and   bko.validita_fine is null;

	strMessaggio:='Pulizia blanck siac_bko_t_causale_evento.';
	update siac_bko_t_causale_evento bko
	set    pdc_fin=ltrim(rtrim(bko.pdc_fin)),
    	   codice_causale=ltrim(rtrim(bko.codice_causale)),
		   tipo_evento=ltrim(rtrim(bko.tipo_evento)),
		   evento=ltrim(rtrim(bko.evento))
    where bko.ente_proprietario_id=enteProprietarioId
    and   bko.ambito=ambitoCode
    and   bko.caricata=false
    and   bko.data_cancellazione is null
	and   bko.validita_fine is null;

    dateInizVal:=(annoBilancio::varchar||'-01-01')::timestamp;

    -- siac_t_causale_ep
    strMessaggio:='Inserimento causali [siac_t_causale_ep].';
    insert into siac_t_causale_ep
    (
      causale_ep_code,
      causale_ep_desc,
      causale_ep_tipo_id,
      ambito_id,
      validita_inizio,
      login_operazione,
      login_creazione,
      ente_proprietario_id
    )
    select distinct bko.codice_causale,
           bko.descrizione_causale,
           tipo.causale_ep_tipo_id,
           ambito.ambito_id,
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione||'-'||bko.eu||'@'||bko.pdc_fin,
           bko.login_operazione||'-'||loginOperazione||'-'||bko.eu,
           tipo.ente_proprietario_id
    from siac_bko_t_caricamento_causali bko,siac_t_ente_proprietario ente,siac_d_causale_ep_tipo tipo,
         siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.causale_ep_tipo_code=bko.causale_tipo
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   bko.caricata=false
 --   and   bko.eu='U'
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   not exists
    (
    select 1 from siac_t_causale_ep ep
    where ep.ente_proprietario_id=enteProprietarioId
    and   ep.causale_ep_code=bko.codice_causale
    and   ep.ambito_id=ambito.ambito_id
    and   ep.data_cancellazione is null
    and   ep.validita_fine is null
    );
	GET DIAGNOSTICS numeroCausali = ROW_COUNT;
	if coalesce(numeroCausali,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;

    raise notice 'numeroCausali=%',numeroCausali;

    codResult:=null;
    strMessaggio:='Inserimento causali  - stato [siac_r_causale_ep_stato].';
    -- siac_r_causale_ep_stato
    insert into siac_r_causale_ep_stato
    (
        causale_ep_id,
        causale_ep_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select ep.causale_ep_id,
           stato.causale_ep_stato_id,
           dateInizVal,
           ep.login_operazione,
           stato.ente_proprietario_id
    from siac_d_causale_ep_stato stato ,siac_t_causale_ep ep, siac_t_ente_proprietario ente
    where ente.ente_proprietario_id=enteProprietarioId
    and   stato.ente_proprietario_id=ente.ente_proprietario_id
    and   stato.causale_ep_stato_code='V'
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
--    and   ep.login_operazione like '%'||loginOperazione||'%U%';
    and   ep.login_operazione like '%'||loginOperazione||'%';

    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroStatoCausali=%',codResult;
    codResult:=null;
    strMessaggio:='Inserimento causali  - PdcFin [siac_r_causale_ep_class].';

    -- siac_r_causale_ep_class
    insert into siac_r_causale_ep_class
    (
        causale_ep_id,
        classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select ep.causale_ep_id,
           c.classif_id,
           dateInizVal,
           ep.login_operazione,
           ente.ente_proprietario_id
    from siac_t_causale_ep ep, siac_t_ente_proprietario ente,siac_t_class c,siac_d_class_tipo tipo
    where ente.ente_proprietario_id=enteProprietarioId
    and   tipo.ente_proprietario_id =ente.ente_proprietario_id
    and   tipo.classif_tipo_code='PDC_V'
    and   c.classif_tipo_id=tipo.classif_tipo_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
--    and   ep.login_operazione like '%'||loginOperazione||'%U%'
    and   ep.login_operazione like '%'||loginOperazione||'%'
    and   c.classif_code=substring(ep.login_operazione, position('@' in ep.login_operazione)+1)
    and   c.data_cancellazione is null;
	GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroPdcFinCausali=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - PdcFin [siac_r_causale_ep_pdce_conto].';
    -- siac_r_causale_ep_pdce_conto
    insert into siac_r_causale_ep_pdce_conto
    (
      causale_ep_id,
      pdce_conto_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           ep.causale_ep_id,
           conto.pdce_conto_id,
           dateInizVal,
--           bko.login_operazione||'-'||bko.eu||'@'||bko.carica_cau_id::varchar,
           bko.login_operazione||'-'||loginOperazione||'-'||bko.eu,
           conto.ente_proprietario_id
    from siac_t_causale_ep ep, siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko,
         siac_t_pdce_conto conto,siac_d_ambito ambito
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
--    and   ep.login_operazione like '%'||loginOperazione||'%U%'
    and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ep.ambito_id
    and   bko.caricata=false
    and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto r1
    where r1.ente_proprietario_id=ente.ente_proprietario_id
    and   r1.causale_ep_id=ep.causale_ep_id
    and   r1.pdce_conto_id=conto.pdce_conto_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
--    and   bko.eu='U'
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null
    and   conto.data_cancellazione is null
    and   conto.validita_fine is null;

	GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroContiCausali=%',codResult;

    -- segno
    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - SEGNO  [siac_r_causale_ep_pdce_conto_oper].';
	insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper, siac_t_causale_ep ep,siac_d_ambito ambito,siac_t_pdce_conto conto
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
	and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ambito.ambito_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu--||'%'
    and   r.causale_ep_id=ep.causale_ep_id
    and   r.pdce_conto_id=conto.pdce_conto_id
--    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.segno)
    and   bko.caricata=false
--    and   bko.eu='U'
	and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroContiSEGNOCausali=%',codResult;

    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - TIPO IMPORTO  [siac_r_causale_ep_pdce_conto_oper].';
    -- tipo_importo
   /* insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper
    where ente.ente_proprietario_id=enteProprietarioId
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
--    and   r.login_operazione like '%'||loginOperazione||'%U%'
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.tipo_importo)
    and   bko.caricata=false
    and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
  --  and   bko.eu='U'
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;*/

    insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper, siac_t_causale_ep ep,siac_d_ambito ambito,siac_t_pdce_conto conto
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
	and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ambito.ambito_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu--||'%'
    and   r.causale_ep_id=ep.causale_ep_id
    and   r.pdce_conto_id=conto.pdce_conto_id
--    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.tipo_importo)
    and   bko.caricata=false
--    and   bko.eu='U'
	and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;

    raise notice 'numeroContiTIPOIMPORTOCausali=%',codResult;

    -- utilizzo_conto
    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - UTILIZZO CONTO  [siac_r_causale_ep_pdce_conto_oper].';
    /*insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper
    where ente.ente_proprietario_id=enteProprietarioId
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
--    and   r.login_operazione like '%'||loginOperazione||'%U%'
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.utilizzo_conto)
    and   bko.caricata=false
--    and   bko.eu='U'
    and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;*/

    insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper, siac_t_causale_ep ep,siac_d_ambito ambito,siac_t_pdce_conto conto
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
	and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ambito.ambito_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu--||'%'
    and   r.causale_ep_id=ep.causale_ep_id
    and   r.pdce_conto_id=conto.pdce_conto_id
--    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.utilizzo_conto)
    and   bko.caricata=false
--    and   bko.eu='U'
	and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroContiUTILIZZOCONTOCausali=%',codResult;

    -- utilizzo_importo
    codResult:=null;
    strMessaggio:='Inserimento causali - pdcContoEcon - UTILIZZO IMPORTO  [siac_r_causale_ep_pdce_conto_oper].';
    /*insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper
    where ente.ente_proprietario_id=enteProprietarioId
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
--    and   r.login_operazione like '%'||loginOperazione||'%U%'
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.utilizzo_importo)
    and   bko.caricata=false
  --  and   bko.eu='U'
    and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;*/

    insert into siac_r_causale_ep_pdce_conto_oper
    (
      causale_ep_pdce_conto_id,
      oper_ep_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           r.causale_ep_pdce_conto_id,
           oper.oper_ep_id,
           dateInizVal,
           r.login_operazione,
           ente.ente_proprietario_id
    from siac_t_ente_proprietario ente, siac_bko_t_caricamento_causali bko , siac_r_causale_ep_pdce_conto r,
         siac_d_operazione_ep oper, siac_t_causale_ep ep,siac_d_ambito ambito,siac_t_pdce_conto conto
    where ente.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
	and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   ep.causale_ep_code=bko.codice_causale
    and   ambito.ente_proprietario_id=ente.ente_proprietario_id
    and   ambito.ambito_code=bko.ambito
    and   ep.ambito_id=ambito.ambito_id
    and   conto.ente_proprietario_id=ente.ente_proprietario_id
    and   conto.pdce_conto_code=bko.pdc_econ_patr
    and   conto.ambito_id=ambito.ambito_id
    and   r.ente_proprietario_id=ente.ente_proprietario_id
    and   r.login_operazione like '%'||loginOperazione||'-'||bko.eu--||'%'
    and   r.causale_ep_id=ep.causale_ep_id
    and   r.pdce_conto_id=conto.pdce_conto_id
--    and   bko.carica_cau_id=substring(r.login_operazione, position('@' in r.login_operazione)+1)::integer
    and   oper.ente_proprietario_id=ente.ente_proprietario_id
    and   oper.oper_ep_code=upper(bko.utilizzo_importo)
    and   bko.caricata=false
--    and   bko.eu='U'
	and   not exists
    (
    select 1 from siac_r_causale_ep_pdce_conto_oper r1
    where r1.causale_ep_pdce_conto_id=r.causale_ep_pdce_conto_id
    and   r1.oper_ep_id=oper.oper_ep_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
	if coalesce(codResult,0)=0  then
    	raise exception ' Inserimento non effettuato.';
    end if;
    raise notice 'numeroContiUTILIZZOIMPORTOCausali=%',codResult;

	codResult:=null;
    strMessaggio:='Inserimento causali - evento   [siac_r_causale_evento].';
    -- siac_r_evento_causale
    insert into siac_r_evento_causale
    (
      causale_ep_id,
      evento_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select distinct
           ep.causale_ep_id,
           evento.evento_id,
           dateInizVal,
           bko.login_operazione||'-'||loginOperazione,
           ep.ente_proprietario_id
    from siac_t_ente_proprietario ente,siac_bko_t_causale_evento bko,siac_t_causale_ep ep,
         siac_d_evento evento,siac_d_evento_tipo tipo
    where ente.ente_proprietario_id=enteProprietarioId
    and   ep.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.login_operazione like '%'||loginOperazione||'-'||bko.eu||'%'
    and   bko.ente_proprietario_id=ente.ente_proprietario_id
    and   ep.causale_ep_code=bko.codice_causale
    and   tipo.ente_proprietario_id=ente.ente_proprietario_id
    and   tipo.evento_tipo_code=bko.tipo_evento
    and   evento.evento_tipo_id=tipo.evento_tipo_id
    and   evento.evento_code=bko.evento
    and   bko.caricata=false
    and   not exists
    (
    select 1 from siac_r_evento_causale r1
    where r1.causale_ep_id = ep.causale_ep_id
    and   r1.evento_id=evento.evento_id
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
    )
   -- and   bko.eu='U'
    and   bko.data_cancellazione is null
    and   bko.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'numeroCausaliEvento=%',codResult;

    messaggioRisultato:=strMessaggioFinale||' Inserite '||numeroCausali::varchar||' causali.';

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