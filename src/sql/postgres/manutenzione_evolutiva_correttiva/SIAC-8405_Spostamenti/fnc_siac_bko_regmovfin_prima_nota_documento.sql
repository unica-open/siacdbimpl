/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_siac_bko_regmovfin_prima_nota_documento
(
annoBilancio integer,
enteproprietarioid integer,
loginoperazione varchar,
genRegistro boolean,
genRegistroGsa boolean,
out codicerisultato integer,
out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_siac_bko_regmovfin_prima_nota_documento
(
annoBilancio integer,
enteproprietarioid integer,
loginoperazione varchar,
genRegistro boolean,
genRegistroGsa boolean,
sequenceElabId integer, -- 06.07.2022 Sofia Jira SIAC-8405
svuotaTabellaBko boolean, -- 06.07.2022 Sofia Jira SIAC-8405
out codicerisultato integer,
out messaggiorisultato varchar
);
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_regmovfin_prima_nota_documento
(
annoBilancio integer,
enteproprietarioid integer,
loginoperazione varchar,
genRegistro boolean,
genRegistroGsa boolean,
sequenceElabId integer, -- 06.07.2022 Sofia Jira SIAC-8405
svuotaTabellaBko boolean, -- 06.07.2022 Sofia Jira SIAC-8405
out codicerisultato integer,
out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE




strMessaggio         VARCHAR(1500):='';
strMessaggioFinale   VARCHAR(1500):='';


BEGIN

 -- fnc_siac_bko_regmovfin_prima_nota_documento

 strMessaggioFinale:='Registro prima nota documento.';
 codiceRisultato:=0;

 -- 06.07.2022 Sofia Jira SIAC-8405 - inizio
 raise notice '% sequenceElabId=%',strMessaggioFinale,coalesce(sequenceElabId::varchar,' ');
 
  if coalesce(sequenceElabId,0)=0 then 
  	raise exception ' Indicare un sequenceElabId calcolato con  fnc_siac_bko_spostamenti_id_seq_incrementa.';
  end if;
 
 
  select 1 into codiceRisultato
  from siac_bko_regmovfin_prima_nota_documento bko 
  where bko.ente_proprietario_id =enteproprietarioid
  and     bko.bko_spostamenti_id !=sequenceElabId;
  if coalesce(codiceRisultato,0)!=0 then 
  	codiceRisultato:=-1;
    raise exception ' Esistono dati in tabella siac_bko_regmovfin_prima_nota_documento per l'' ente caricati con  bko_spostamenti_id diverso da sequenceElabId=% passato.Verificare e cancellarli prima di procedere.',sequenceElabId::varchar;
  end if;
 
 -- 06.07.2022 Sofia Jira SIAC-8405 - fine 
 
  strMessaggio:= 'collegamento tra documento e prima nota : inserimento stato annullato.';
  raise notice 'strMessaggio=%',strMessaggio;


  -- inserire stato prima nota annullato, se esiste non annullata
  insert into siac_r_prima_nota_stato
  (
 	pnota_id,
    pnota_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  select distinct pnota.pnota_id,
                  statoA.pnota_stato_id,
                  now(),
                  loginOperazione,
                  tipo.ente_proprietario_id
  from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota,
       siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=annoBilancio
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnota.bil_id=anno.bil_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.pnota_stato_code='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null;

  -- annullare prima nota, se presente non annullata
  strMessaggio:= 'collegamento tra documento e prima nota : annullamento stato non annullato prima nota.';
  raise notice 'strMessaggio=%',strMessaggio;

  update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||loginOperazione
 from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota,
       siac_d_prima_nota_stato pnstato
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=annoBilancio
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnota.bil_id=anno.bil_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   ep.data_cancellazione is null
   and   ep.validita_fine is null
   and   pnota.data_cancellazione is null
   and   pnota.validita_fine is null
   and   r.data_cancellazione is null
   and   r.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null;

   -- inserire stato registro annullato, se esiste non annullato
   strMessaggio:= 'collegamento tra documento e registro prima nota precedente : inserimento stato annullato.';
   raise notice 'strMessaggio=%',strMessaggio;


   insert into siac_r_reg_movfin_stato
   (
  	 regmovfin_id,
     regmovfin_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
   )
   select REG.regmovfin_id,
          statoA.regmovfin_stato_id,
          now(),
          loginOperazione,
	      statoA.ente_proprietario_id
   from siac_d_reg_movfin_stato statoA,
   (
   select distinct reg.regmovfin_id
   from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato
   where  tipo.ente_proprietario_id=enteProprietarioId
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=annoBilancio
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   reg.bil_id = anno.bil_id
   ) REG
   where statoA.ente_proprietario_id=enteProprietarioId
   and   statoA.regmovfin_stato_code='A';



   strMessaggio:= 'collegamento tra documento e registro prima nota precedente : annullamento stato non annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   update siac_r_reg_movfin_stato rrstato
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstato.login_operazione||'-'||loginOperazione
   from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
       siac_bko_regmovfin_prima_nota_documento bko,
       siac_t_subdoc sub,
       siac_v_bko_anno_bilancio anno,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_d_reg_movfin_stato rstato
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.ente_proprietario_id=tipo.ente_proprietario_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=annoBilancio
   and   revento.campo_pk_id=sub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.evento_code=bko.evento_code
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   reg.bil_id = anno.bil_id;

  if genRegistro=true then
   strMessaggio:= 'registro generale documento : inserimento nuovo registro.';
   raise notice 'strMessaggio=%',strMessaggio;

   -- inserire registro in stato NOTIFICATO
   insert into siac_t_reg_movfin
   (
  	classif_id_iniziale,
    classif_id_aggiornato,
    bil_id,
    ambito_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   (
   select  c.classif_id,
           c.classif_id,
           anno.bil_id,
           a.ambito_id,
           clock_timestamp(),
           loginOperazione||'@'||sub.subdoc_id::varchar,
           c.ente_proprietario_id
   from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
        siac_bko_regmovfin_prima_nota_documento bko,
        siac_t_subdoc sub,
        siac_v_bko_anno_bilancio anno,
        siac_d_ambito a,
        siac_r_subdoc_movgest_ts rsub,
        siac_r_movgest_class  rc,siac_t_class c, siac_d_class_tipo tipoc
   where tipo.ente_proprietario_id=enteProprietarioId
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.doc_tipo_id=tipo.doc_tipo_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   bko.doc_genera=true
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=annoBilancio
   and   a.ente_proprietario_id=tipo.ente_proprietario_id
   and   a.ambito_code='AMBITO_FIN'
   and   rsub.subdoc_id=sub.subdoc_id
   and   rc.movgest_ts_id=rsub.movgest_ts_id
   and   c.classif_id=rc.classif_id
   and   tipoc.classif_tipo_id=c.classif_tipo_id
   and   tipoc.classif_tipo_code='PDC_V'
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   and   rc.data_cancellazione is null
   and   rc.validita_fine is null
   and   c.data_cancellazione is null
   );

   strMessaggio:= 'registro prima nota  documento  : inserimento stato NOTIFICATO.';
   raise notice 'strMessaggio=%',strMessaggio;

   insert into siac_r_reg_movfin_stato
   (
  	regmovfin_id,
    regmovfin_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   select reg.regmovfin_id,
          stato.regmovfin_stato_id,
          clock_timestamp(),
          loginOperazione,
          reg.ente_proprietario_id
   from siac_t_reg_movfin reg ,siac_d_reg_movfin_stato stato
   where reg.ente_proprietario_id=enteProprietarioId
   and   reg.login_operazione like loginOperazione||'@%'
   and   stato.ente_proprietario_id=reg.ente_proprietario_id
   and   stato.regmovfin_stato_code='N';

   strMessaggio:= 'collegamento tra registro prima nota e documento : inserimento relazione.';
   raise notice 'strMessaggio=%',strMessaggio;

   insert into siac_r_evento_reg_movfin
   (
  	regmovfin_id,
    evento_id,
    campo_pk_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   (
    select reg.regmovfin_id,
           evento.evento_id,
           sub.subdoc_id,
           clock_timestamp(),
           loginOperazione,
           tipo.ente_proprietario_id
    from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
         siac_bko_regmovfin_prima_nota_documento bko,
         siac_t_subdoc sub,
         siac_v_bko_anno_bilancio anno,
         siac_d_collegamento_tipo coll,siac_d_evento evento,
         siac_t_reg_movfin reg
    where tipo.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   tipo.doc_tipo_code=bko.doc_tipo_code
    and   doc.doc_tipo_id=tipo.doc_tipo_id
    and   doc.doc_anno::integer=bko.doc_anno
    and   doc.doc_numero=bko.doc_numero
    and   rdoc.doc_id=doc.doc_id
    and   sog.soggetto_id=rdoc.soggetto_id
    and   sog.soggetto_code=bko.doc_soggetto_code
    and   sub.doc_id=doc.doc_id
    and   sub.subdoc_numero=bko.doc_subnumero
    and   bko.doc_genera=true
    and   anno.ente_proprietario_id=tipo.ente_proprietario_id
    and   anno.anno_bilancio=annoBilancio
    and   coll.ente_proprietario_id=tipo.ente_proprietario_id
    and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
    and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
    and   evento.evento_code=bko.evento_code
    and   reg.ente_proprietario_id=tipo.ente_proprietario_id
    and   reg.login_operazione like loginOperazione||'@%'
    and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=sub.subdoc_id
    and   rdoc.data_cancellazione is null
    and   rdoc.validita_fine is null
    and   sub.data_cancellazione is null
    and   sub.validita_fine is null
    and   doc.data_cancellazione is null
    and   doc.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null
   );
  end if;



  if genRegistroGsa=true then
   strMessaggio:= 'registro generale GSA documento : inserimento nuovo registro.';
   raise notice 'strMessaggio=%',strMessaggio;

   -- inserire registro in stato NOTIFICATO
   insert into siac_t_reg_movfin
   (
  	classif_id_iniziale,
    classif_id_aggiornato,
    bil_id,
    ambito_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   (
   select  c.classif_id,
           c.classif_id,
           anno.bil_id,
           a.ambito_id,
           clock_timestamp(),
           loginOperazione||'-GSA@'||sub.subdoc_id::varchar,
           c.ente_proprietario_id
   from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
        siac_bko_regmovfin_prima_nota_documento bko,
        siac_t_subdoc sub,
        siac_v_bko_anno_bilancio anno,
        siac_d_ambito a,
        siac_r_subdoc_movgest_ts rsub,
        siac_r_movgest_class  rc,siac_t_class c, siac_d_class_tipo tipoc
   where tipo.ente_proprietario_id=enteProprietarioId
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   tipo.doc_tipo_code=bko.doc_tipo_code
   and   doc.doc_tipo_id=tipo.doc_tipo_id
   and   doc.doc_anno::integer=bko.doc_anno
   and   doc.doc_numero=bko.doc_numero
   and   rdoc.doc_id=doc.doc_id
   and   sog.soggetto_id=rdoc.soggetto_id
   and   sog.soggetto_code=bko.doc_soggetto_code
   and   bko.doc_genera_gsa=true
   and   sub.doc_id=doc.doc_id
   and   sub.subdoc_numero=bko.doc_subnumero
   and   anno.ente_proprietario_id=tipo.ente_proprietario_id
   and   anno.anno_bilancio=annoBilancio
   and   a.ente_proprietario_id=tipo.ente_proprietario_id
   and   a.ambito_code='AMBITO_GSA'
   and   rsub.subdoc_id=sub.subdoc_id
   and   rc.movgest_ts_id=rsub.movgest_ts_id
   and   c.classif_id=rc.classif_id
   and   tipoc.classif_tipo_id=c.classif_tipo_id
   and   tipoc.classif_tipo_code='PDC_V'
   and   rdoc.data_cancellazione is null
   and   rdoc.validita_fine is null
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   and   rc.data_cancellazione is null
   and   rc.validita_fine is null
   and   c.data_cancellazione is null
   );

   strMessaggio:= 'registro prima nota GSA documento  : inserimento stato NOTIFICATO.';
   raise notice 'strMessaggio=%',strMessaggio;

   insert into siac_r_reg_movfin_stato
   (
  	regmovfin_id,
    regmovfin_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   select reg.regmovfin_id,
          stato.regmovfin_stato_id,
          clock_timestamp(),
          loginOperazione,
          reg.ente_proprietario_id
   from siac_t_reg_movfin reg ,siac_d_reg_movfin_stato stato
   where reg.ente_proprietario_id=enteProprietarioId
   and   reg.login_operazione like loginOperazione||'-GSA@%'
   and   stato.ente_proprietario_id=reg.ente_proprietario_id
   and   stato.regmovfin_stato_code='N';

   strMessaggio:= 'collegamento tra registro prima nota GSA e documento : inserimento relazione.';
   raise notice 'strMessaggio=%',strMessaggio;

   insert into siac_r_evento_reg_movfin
   (
  	regmovfin_id,
    evento_id,
    campo_pk_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   (
    select reg.regmovfin_id,
           evento.evento_id,
           sub.subdoc_id,
           clock_timestamp(),
           loginOperazione,
           tipo.ente_proprietario_id
    from siac_d_doc_tipo tipo, siac_t_doc doc , siac_r_doc_sog rdoc, siac_t_soggetto sog,
         siac_bko_regmovfin_prima_nota_documento bko,
         siac_t_subdoc sub,
         siac_v_bko_anno_bilancio anno,
         siac_d_collegamento_tipo coll,siac_d_evento evento,
         siac_t_reg_movfin reg
    where tipo.ente_proprietario_id=enteProprietarioId
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   tipo.doc_tipo_code=bko.doc_tipo_code
    and   doc.doc_tipo_id=tipo.doc_tipo_id
    and   doc.doc_anno::integer=bko.doc_anno
    and   doc.doc_numero=bko.doc_numero
    and   rdoc.doc_id=doc.doc_id
    and   sog.soggetto_id=rdoc.soggetto_id
    and   sog.soggetto_code=bko.doc_soggetto_code
    and   bko.doc_genera_gsa=true
    and   sub.doc_id=doc.doc_id
    and   sub.subdoc_numero=bko.doc_subnumero
    and   anno.ente_proprietario_id=tipo.ente_proprietario_id
    and   anno.anno_bilancio=annoBilancio
    and   coll.ente_proprietario_id=tipo.ente_proprietario_id
    and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
    and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
    and   evento.evento_code=bko.evento_code
    and   reg.ente_proprietario_id=tipo.ente_proprietario_id
    and   reg.login_operazione like loginOperazione||'-GSA@%'
    and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=sub.subdoc_id
    and   rdoc.data_cancellazione is null
    and   rdoc.validita_fine is null
    and   sub.data_cancellazione is null
    and   sub.validita_fine is null
    and   doc.data_cancellazione is null
    and   doc.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null
   );
  end if;


-- 06.07.2022 Sofia Jira SIAC-8405
if svuotaTabellaBko=true then 
	 strMessaggio:= 'Svuotamento tabella siac_bko_regmovfin_prima_nota_documento per sequenceElabId='||sequenceElabId::varchar||'.';
     raise notice 'strMessaggio=%',strMessaggio;
    
     delete   from siac_bko_regmovfin_prima_nota_documento bko 
     where bko.ente_proprietario_id =enteProprietarioId
     and     bko.bko_spostamenti_id =sequenceElabId;
end if;

 messaggioRisultato:=strMessaggioFinale||' OK .';

 raise notice 'messaggioRisultato=%',messaggioRisultato;

 return;

exception
    when RAISE_EXCEPTION THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
                substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

    when no_data_found THEN
        raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        return;
    when others  THEN
        raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
                substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_siac_bko_regmovfin_prima_nota_documento ( integer, integer, varchar, boolean, boolean,integer,boolean, out  integer,out  varchar)  OWNER to siac;