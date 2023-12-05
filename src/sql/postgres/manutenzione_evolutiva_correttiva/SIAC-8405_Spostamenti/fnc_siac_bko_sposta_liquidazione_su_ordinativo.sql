/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop function if exists  siac.fnc_siac_bko_sposta_liquidazione_su_ordinativo(annoBilancio integer,
                                                                          enteproprietarioid integer,
																	      loginoperazione varchar,
                                                                          genAggiorna boolean,
																		  out codicerisultato integer,
																		  out messaggiorisultato varchar
                                                                          );
drop function if exists siac.fnc_siac_bko_sposta_liquidazione_su_ordinativo(annoBilancio integer,
                                                                          enteproprietarioid integer,
																	      loginoperazione varchar,
                                                                          genAggiorna boolean,
                                                                          genGsa boolean,
																		  out codicerisultato integer,
																		  out messaggiorisultato varchar
																		  );

drop function if exists siac.fnc_siac_bko_sposta_liquidazione_su_ordinativo(annoBilancio integer,
                                                                          enteproprietarioid integer,
																	      loginoperazione varchar,
                                                                          genAggiorna boolean,
                                                                          genGsa boolean,
																		  sequenceElabId integer,      -- 31.08.2022 Sofia Jira SIAC-8405
																		  svuotaTabellaBko boolean, -- 31.08.2022 Sofia Jira SIAC-8405
																		  out codicerisultato integer,
																		  out messaggiorisultato varchar
																		  );

CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_sposta_liquidazione_su_ordinativo(annoBilancio integer,
                                                                          enteproprietarioid integer,
																	      loginoperazione varchar,
                                                                          genAggiorna boolean,
                                                                          genGsa boolean,
																		  sequenceElabId integer,      -- 31.08.2022 Sofia Jira SIAC-8405
																		  svuotaTabellaBko boolean, -- 31.08.2022 Sofia Jira SIAC-8405
																		  out codicerisultato integer,
																		  out messaggiorisultato varchar
                                                                          )
RETURNS record AS
$body$
DECLARE




strMessaggio         VARCHAR(1500):='';
strMessaggioFinale   VARCHAR(1500):='';


BEGIN

 strMessaggioFinale:='Sposta liquidazione su ordinativo.';
 codiceRisultato:=0;


 -- 31.08.2022 Sofia Jira SIAC-8405 - inizio
 raise notice '% sequenceElabId=%',strMessaggioFinale,coalesce(sequenceElabId::varchar,' ');
 
  if coalesce(sequenceElabId,0)=0 then 
  	raise exception ' Indicare un sequenceElabId calcolato con  fnc_siac_bko_spostamenti_id_seq_incrementa.';
  end if;
 
 
  select 1 into codiceRisultato
  from siac_bko_sposta_ordinativo_pag_liquidazione bko 
  where bko.ente_proprietario_id =enteproprietarioid
  and     bko.bko_spostamenti_id !=sequenceElabId;
  if coalesce(codiceRisultato,0)!=0 then 
  	codiceRisultato:=-1;
    raise exception ' Esistono dati in tabella siac_bko_sposta_ordinativo_pag_liquidazione per l'' ente caricati con  bko_spostamenti_id diverso da sequenceElabId=% passato.Verificare e cancellarli prima di procedere.',sequenceElabId::varchar;
  end if;
 
 -- 31.08.2022 Sofia Jira SIAC-8405 - fine 

 
 strMessaggio:='collegamento tra ordinativo e liquidazione : annullamento precedente relazione.';
 raise notice 'strMessaggio=%',strMessaggio;


 -- collegamento tra ordinativo e liquidazione
 -- annullamento vecchia relazione
 update siac_r_liquidazione_ord rord
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=rord.login_operazione||'-'||loginOperazione
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
      siac_t_ordinativo_ts ts,
      siac_v_bko_anno_bilancio anno,
      siac_t_liquidazione liq,
      siac_bko_sposta_ordinativo_pag_liquidazione bko
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   ts.ord_id=ord.ord_id
 and   rord.sord_id=ts.ord_ts_id
 and   liq.liq_id=rord.liq_id
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   bko.ord_sub_numero=ts.ord_ts_code::integer
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ts.data_cancellazione is null
 and   ts.validita_fine is null
 and   rord.data_cancellazione is null
 and   rord.validita_fine is null
 and   liq.data_cancellazione is null
 and   liq.validita_fine is null;

 strMessaggio:='collegamento tra ordinativo e liquidazione : inserimento nuova relazione.';

 raise notice 'strMessaggio=%',strMessaggio;
 -- inserimento nuova relazione
 insert into siac_r_liquidazione_ord
 (
 	liq_id,
    sord_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 select liq.liq_id,
        ts.ord_ts_id,
        clock_timestamp(),
        loginOperazione,
        liq.ente_proprietario_id
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
      siac_t_ordinativo_ts ts,
      siac_v_bko_anno_bilancio anno,
      siac_t_liquidazione liq,
      siac_bko_sposta_ordinativo_pag_liquidazione bko
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   ts.ord_id=ord.ord_id
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   bko.ord_sub_numero=ts.ord_ts_code::integer
 and   liq.bil_id=ord.bil_id
 and   liq.liq_anno::integer=bko.liq_anno_a
 and   liq.liq_numero::integer=bko.liq_numero_a
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ts.data_cancellazione is null
 and   ts.validita_fine is null
 and   liq.data_cancellazione is null
 and   liq.validita_fine is null;


 strMessaggio:='collegamento tra ordinativo e capitolo : annullamento precedente relazione.';
 raise notice 'strMessaggio=%',strMessaggio;

 -- collegamento tra ordinativo e capitolo
 -- annullamento vecchia relazione
 update siac_r_ordinativo_bil_elem r
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=r.login_operazione||'-'||loginOperazione
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_pag_liquidazione bko
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   r.ord_id=ord.ord_id
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   r.data_cancellazione is null
 and   r.validita_fine is null;

 strMessaggio:= 'collegamento tra ordinativo e capitolo : inserimento nuova relazione.';
 raise notice 'strMessaggio=%',strMessaggio;

 -- inserimento nuova relazione
 -- attenzione ( distinct su numero_ordinativo, numero_capitolo_da, numero_capitolo_a )
 insert into siac_r_ordinativo_bil_elem
 (
  ord_id,
  elem_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 (
 WITH
 cap as
 (
  select e.elem_code::integer,e.elem_id
  from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,siac_v_bko_anno_bilancio anno
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.elem_tipo_code='CAP-UG'
  and   e.elem_tipo_id=tipo.elem_tipo_id
  and   anno.bil_id=e.bil_id
  and   anno.anno_bilancio=annoBilancio
  and   e.data_cancellazione is null
  and   e.validita_fine is null
 ),
 ordin as
 (
 	select distinct
           ord.ord_id,
           bko.numero_capitolo_a,
           ord.ente_proprietario_id
    from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
         siac_v_bko_anno_bilancio anno,
         siac_bko_sposta_ordinativo_pag_liquidazione bko
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.ord_tipo_code='P'
    and   ord.ord_tipo_id=tipo.ord_tipo_id
    and   anno.bil_id=ord.bil_id
    and   anno.anno_bilancio=annoBilancio
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   bko.anno_bilancio=annoBilancio
    and   bko.ord_numero=ord.ord_numero::integer
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
  )
  select distinct ordin.ord_id,
                  cap.elem_id,
                  now(),
                  loginOperazione,
                  ordin.ente_proprietario_id
  from cap, ordin
  where ordin.numero_capitolo_a=cap.elem_code
 );

 strMessaggio:= 'collegamento tra ordinativo e classificatori : annullamento precedenti relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;

 -- collegamento tra ordinativo e classificatori
 -- annullamento tra classificatori ordinativo
 update siac_r_ordinativo_class rc
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=rc.login_operazione||'-'||loginoperazione
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_pag_liquidazione bko,
      siac_t_class c, siac_d_class_tipo tipoc
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   rc.ord_id=ord.ord_id
 and   c.classif_id=rc.classif_id
 and   tipoc.classif_tipo_id=c.classif_tipo_id
 and   tipoc.classif_tipo_code in
 (
 'PDC_V',
 'GRUPPO_COFOG',
 'PERIMETRO_SANITARIO_SPESA',
 'RICORRENTE_SPESA',
 'TRANSAZIONE_UE_SPESA'
 )
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null;

 -- inserimento nuovi classificatori prendendo da nuova liquidazione
 -- -- GRUPPO_COFOG   09.6
    -- PDC_V          U.1.04.01.02.003
    -- PERIMETRO_SANITARIO_SPESA  3
    -- RICORRENTE_SPESA           3
    -- TRANSAZIONE_UE_SPESA       8
 strMessaggio:= 'collegamento tra ordinativo e classificatori : inserimento nuove relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;

 insert into siac_r_ordinativo_class
 (
	ord_id,
    classif_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 select distinct ord.ord_id,
                 c.classif_id,
                 now(),
                 loginOperazione,
                 c.ente_proprietario_id
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_t_ordinativo_ts ts,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_pag_liquidazione bko,
      siac_r_liquidazione_ord rord, siac_r_liquidazione_class rc,
      siac_t_class c, siac_d_class_tipo tipoc
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   ts.ord_id=ord.ord_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   bko.ord_sub_numero=ts.ord_ts_code::integer
 and   rord.sord_id=ts.ord_ts_id
 and   rc.liq_id=rord.liq_id
 and   c.classif_id=rc.classif_id
 and   tipoc.classif_tipo_id=c.classif_tipo_id
 and   tipoc.classif_tipo_code in
 (
 'PDC_V',
 'GRUPPO_COFOG',
 'PERIMETRO_SANITARIO_SPESA',
 'RICORRENTE_SPESA',
 'TRANSAZIONE_UE_SPESA'
 )
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ts.data_cancellazione is null
 and   ts.validita_fine is null
 and   rord.data_cancellazione is null
 and   rord.validita_fine is null
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null
 and   c.data_cancellazione is null;



 strMessaggio:= 'collegamento tra liquidazione_da e documenti  : annullamento  relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;

 -- collegamento tra liquidazione_da e documenti
 -- annullare i collegamenti con documenti e liquidazioni_da
 update siac_r_subdoc_liquidazione rliq
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=rliq.login_operazione||'-'||loginOperazione
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_t_ordinativo_ts ts,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_pag_liquidazione bko,
      siac_r_subdoc_ordinativo_ts rord
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   ts.ord_id=ord.ord_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   bko.ord_sub_numero=ts.ord_ts_code::integer
 and   rord.ord_ts_id=ts.ord_ts_id
 and   rliq.subdoc_id=rord.subdoc_id
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ts.data_cancellazione is null
 and   ts.validita_fine is null
 and   rord.data_cancellazione is null
 and   rord.validita_fine is null
 and   rliq.data_cancellazione is null
 and   rliq.validita_fine is null;


 strMessaggio:= 'collegamento tra liquidazione_a e documenti  : inserimento  relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;
 insert into siac_r_subdoc_liquidazione
 (
 	subdoc_id,
    liq_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 select rord.subdoc_id,
        rliq.liq_id,
        clock_timestamp(),
        loginOperazione,
        tipo.ente_proprietario_id
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_t_ordinativo_ts ts,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_pag_liquidazione bko,
      siac_r_subdoc_ordinativo_ts rord,
      siac_r_liquidazione_ord rliq
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   ts.ord_id=ord.ord_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   bko.ord_sub_numero=ts.ord_ts_code::integer
 and   rord.ord_ts_id=ts.ord_ts_id
 and   rliq.sord_id=ts.ord_ts_id
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ts.data_cancellazione is null
 and   ts.validita_fine is null
 and   rord.data_cancellazione is null
 and   rord.validita_fine is null
 and   rliq.data_cancellazione is null
 and   rliq.validita_fine is null;


 strMessaggio:= 'collegamento tra impegno_da e documenti  : annullamento  relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;

 -- collegamento tra impegno_da e documenti
 -- annullare i collegamenti con documenti e impegno_da
 update siac_r_subdoc_movgest_ts rmov
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=rmov.login_operazione||'-'||loginOperazione
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_t_ordinativo_ts ts,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_pag_liquidazione bko,
      siac_r_subdoc_ordinativo_ts rord
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   ts.ord_id=ord.ord_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   bko.ord_sub_numero=ts.ord_ts_code::integer
 and   rord.ord_ts_id=ts.ord_ts_id
 and   rmov.subdoc_id=rord.subdoc_id
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ts.data_cancellazione is null
 and   ts.validita_fine is null
 and   rord.data_cancellazione is null
 and   rord.validita_fine is null
 and   rmov.data_cancellazione is null
 and   rmov.validita_fine is null;


 strMessaggio:= 'collegamento tra liquidazione_a e documenti  : inserimento  relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;
 insert into siac_r_subdoc_movgest_ts
 (
 	subdoc_id,
    movgest_ts_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 select rord.subdoc_id,
        rmov.movgest_ts_id,
        clock_timestamp(),
        loginOperazione,
        tipo.ente_proprietario_id
 from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_t_ordinativo_ts ts,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_ordinativo_pag_liquidazione bko,
      siac_r_subdoc_ordinativo_ts rord,
      siac_r_liquidazione_ord rliq,siac_r_liquidazione_movgest rmov
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='P'
 and   ord.ord_tipo_id=tipo.ord_tipo_id
 and   ts.ord_id=ord.ord_id
 and   anno.bil_id=ord.bil_id
 and   anno.anno_bilancio=annoBilancio
 and   bko.ente_proprietario_id=tipo.ente_proprietario_id
 and   bko.anno_bilancio=annoBilancio
 and   bko.ord_numero=ord.ord_numero::integer
 and   bko.ord_sub_numero=ts.ord_ts_code::integer
 and   rord.ord_ts_id=ts.ord_ts_id
 and   rliq.sord_id=ts.ord_ts_id
 and   rmov.liq_id=rliq.liq_id
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ts.data_cancellazione is null
 and   ts.validita_fine is null
 and   rord.data_cancellazione is null
 and   rord.validita_fine is null
 and   rliq.data_cancellazione is null
 and   rliq.validita_fine is null
 and   rmov.data_cancellazione is null
 and   rmov.validita_fine is null;

 if genAggiorna=true then
  -- movgen ordinativo
  -- attenzione sempre a distinct su ord_numero

  strMessaggio:= 'collegamento tra ordinativo e prima nota : inserimento stato annullato.';
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
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_ordinativo_pag_liquidazione bko,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='P'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OP'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.pnota_stato_code='A'
   and   ord.data_cancellazione is null
   and   ord.validita_fine is null
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
   and   r.validita_fine is null;


  -- annullare prima nota, se presente non annullata
  strMessaggio:= 'collegamento tra ordinativo e prima nota : annullamento stato non annullato prima nota.';
  raise notice 'strMessaggio=%',strMessaggio;

  update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||loginOperazione
  from  siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_pag_liquidazione bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='P'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OP'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   ord.data_cancellazione is null
   and   ord.validita_fine is null
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
   and   r.validita_fine is null;


   -- inserire stato registro annullato, se esiste non annullato
   strMessaggio:= 'collegamento tra ordinativo e registro prima nota precedente : inserimento stato annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   insert into siac_r_reg_movfin_stato
   (
  	 regmovfin_id,
     regmovfin_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
   )
   select distinct reg.regmovfin_id,
                   statoA.regmovfin_stato_id,
                   now(),
                   loginOperazione,
                   tipo.ente_proprietario_id
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_pag_liquidazione bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_d_reg_movfin_stato statoA
   where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='P'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OP'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.regmovfin_stato_code='A'
   and   ord.data_cancellazione is null
   and   ord.validita_fine is null
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null;

   strMessaggio:= 'collegamento tra ordinativo e registro prima nota precedente : annullamento stato non annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   update siac_r_reg_movfin_stato rrstato
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstato.login_operazione||'-'||loginOperazione
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_pag_liquidazione bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg,  siac_d_reg_movfin_stato rstato
   where  tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.ord_tipo_code='P'
    and   ord.ord_tipo_id=tipo.ord_tipo_id
    and   anno.bil_id=ord.bil_id
    and   anno.anno_bilancio=annoBilancio
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   bko.anno_bilancio=annoBilancio
    and   bko.ord_numero=ord.ord_numero::integer
    and   revento.campo_pk_id=ord.ord_id
    and   evento.evento_id=revento.evento_id
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='OP'
    and   reg.regmovfin_id=revento.regmovfin_id
    and   rrstato.regmovfin_id=reg.regmovfin_id
    and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
    and   rstato.regmovfin_stato_code!='A'
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
    and   revento.data_cancellazione is null
    and   revento.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null
    and   rrstato.data_cancellazione is null
    and   rrstato.validita_fine is null;

  strMessaggio:= 'registro generale ordinativo : inserimento nuovo registro.';
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
  select distinct
         c.classif_id,
         c.classif_id,
         ord.bil_id,
         a.ambito_id,
         now(),
         loginOperazione||'@'||ord.ord_id::varchar,
         tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_ordinativo_pag_liquidazione bko,
       siac_d_evento evento , siac_d_collegamento_tipo coll,
       siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipoc,siac_d_ambito a
 where  tipo.ente_proprietario_id=enteProprietarioId
   and  tipo.ord_tipo_code='P'
   and  ord.ord_tipo_id=tipo.ord_tipo_id
   and  anno.bil_id=ord.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=tipo.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.ord_numero=ord.ord_numero::integer
   and  coll.ente_proprietario_id=tipo.ente_proprietario_id
   and  coll.collegamento_tipo_code='OP'
   and  evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and  evento.evento_code='OPA-INS'
   and  rc.ord_id=ord.ord_id
   and  c.classif_id=rc.classif_id
   and  tipoc.classif_tipo_id=c.classif_tipo_id
   and  tipoc.classif_tipo_code='PDC_V'
   and  a.ente_proprietario_id=tipo.ente_proprietario_id
   and  a.ambito_code='AMBITO_FIN'
   and  ord.data_cancellazione is null
   and  ord.validita_fine is null
   and  rc.data_cancellazione is null
   and  rc.validita_fine is null
   and  c.data_cancellazione is null
   /*and  exists
   (
   select 1
   from
   (
    select distinct ord.ord_id
    from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
         siac_v_bko_anno_bilancio anno,
         siac_bko_sposta_ordinativo_pag_liquidazione bko,
         siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
         siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
         siac_d_reg_movfin_stato statoA
    where  tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.ord_tipo_code='P'
    and   ord.ord_tipo_id=tipo.ord_tipo_id
    and   anno.bil_id=ord.bil_id
    and   anno.anno_bilancio=annoBilancio
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   bko.anno_bilancio=annoBilancio
    and   bko.ord_numero=ord.ord_numero::integer
    and   revento.campo_pk_id=ord.ord_id
    and   evento.evento_id=revento.evento_id
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='OP'
    and   reg.regmovfin_id=revento.regmovfin_id
    and   rrstato.regmovfin_id=reg.regmovfin_id
    and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
    and   rstato.regmovfin_stato_code='A'
    and   rrstato.login_operazione =loginOperazione
    and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
    and   statoA.regmovfin_stato_code='A'
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
    and   revento.data_cancellazione is null
    and   revento.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null
    and   rrstato.data_cancellazione is null
    and   rrstato.validita_fine is null
   ) QUERY
   where QUERY.ord_id=ord.ord_id
   )*/;


  strMessaggio:= 'registro prima nota  ordinativo  : inserimento stato NOTIFICATO.';
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


  strMessaggio:= 'collegamento tra registro prima nota e ordinativo : inserimento relazione.';
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
  select distinct
         reg.regmovfin_id,
         evento.evento_id,
         ord.ord_id,
         now(),
         loginOperazione,
         tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_ordinativo_pag_liquidazione bko,
	   siac_d_evento evento , siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.ord_tipo_code='P'
  and   ord.ord_tipo_id=tipo.ord_tipo_id
  and   anno.bil_id=ord.bil_id
  and   anno.anno_bilancio=annoBilancio
  and   bko.ente_proprietario_id=tipo.ente_proprietario_id
  and   bko.anno_bilancio=annoBilancio
  and   bko.ord_numero=ord.ord_numero::integer
  and   coll.ente_proprietario_id=tipo.ente_proprietario_id
  and   coll.collegamento_tipo_code='OP'
  and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
  and   evento.evento_code='OPA-INS'
  and   reg.ente_proprietario_id=tipo.ente_proprietario_id
  and   reg.login_operazione like loginOperazione||'@%'
  and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=ord.ord_id
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   reg.data_cancellazione is null
  and   Reg.validita_fine is null;

  -- 06.02.2018 Sofia - x remedy INC000002297633
  if genGsa=true then
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
    select reg.classif_id_iniziale,
		   reg.classif_id_aggiornato,
	       reg.bil_id,
	       aGSA.ambito_id,
		   clock_timestamp(),
	       aGSA.ambito_code||'-'||reg.login_operazione,
	       reg.ente_proprietario_id
    from siac_t_reg_movfin reg, siac_d_ambito a, siac_d_ambito aGSA
    where reg.ente_proprietario_id=enteProprietarioId
    and   reg.login_operazione like loginOperazione||'@%'
    and   a.ambito_id=reg.ambito_id
    and   a.ambito_code='AMBITO_FIN'
    and   aGSA.ente_proprietario_id=a.ente_proprietario_id
    and   aGSA.ambito_code='AMBITO_GSA'
    );

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
    and   reg.login_operazione like 'AMBITO_GSA-'||loginOperazione||'@%'
    and   stato.ente_proprietario_id=reg.ente_proprietario_id
    and   stato.regmovfin_stato_code='N';


   insert into siac_r_evento_reg_movfin
   (
  	regmovfin_id,
    evento_id,
    campo_pk_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   select distinct
          reg.regmovfin_id,
          evento.evento_id,
          ord.ord_id,
          now(),
          loginOperazione,
          tipo.ente_proprietario_id
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_pag_liquidazione bko,
	    siac_d_evento evento , siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='P'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   coll.ente_proprietario_id=tipo.ente_proprietario_id
   and   coll.collegamento_tipo_code='OP'
   and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and   evento.evento_code='OPA-INS'
   and   reg.ente_proprietario_id=tipo.ente_proprietario_id
   and   reg.login_operazione like 'AMBITO_GSA-'||loginOperazione||'@%'
   and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=ord.ord_id
   and   ord.data_cancellazione is null
   and   ord.validita_fine is null
   and   reg.data_cancellazione is null
   and   Reg.validita_fine is null;

  end if; -- genGsa

 end if; -- if genAggiorna



 -- 31.08.2022 Sofia Jira SIAC-8405
 if svuotaTabellaBko=true then 
	 strMessaggio:= 'Svuotamento tabella siac_bko_sposta_ordinativo_pag_liquidazione per sequenceElabId='||sequenceElabId::varchar||'.';
     raise notice 'strMessaggio=%',strMessaggio;
    
     delete   from siac_bko_sposta_ordinativo_pag_liquidazione bko 
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
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_siac_bko_sposta_liquidazione_su_ordinativo( integer,  integer,  varchar,  boolean,  boolean, integer,   boolean,   out  integer, out  varchar )  OWNER to siac;