/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*drop FUNCTION fnc_siac_bko_sposta_regmovfin_prima_nota(annoBilancio integer,
                                                                    enteproprietarioid integer,
																    loginoperazione varchar,
                                                                    genImpegno  boolean,
                                                                    genLiquidazione boolean,
                                                                    genDocumento boolean, -- da implementare
                                                                    genOrdinativo BOOLEAN,
																    out codicerisultato integer,
																    out messaggiorisultato varchar
                                                                   );*/

/*drop function   fnc_siac_bko_sposta_regmovfin_prima_nota(annoBilancio integer,
                                                                    enteproprietarioid integer,
																    loginoperazione varchar,
                                                                    genAnnulla  boolean, -- true per annullare tutto, false NO
                                                                    genImpegno  boolean, -- inserire genImpegni ( fin,gsa )
                                                                    genLiquidazione boolean,-- inserire genLiq
                                                                    genDocumento boolean, -- da implementare
                                                                    genOrdinativo BOOLEAN, -- inserire genOrd ( fin,gsa )
																    out codicerisultato integer,
																    out messaggiorisultato varchar
                                                                   );*/
drop FUNCTION if exists siac.fnc_siac_bko_sposta_regmovfin_prima_nota(annoBilancio integer,
                                                                    enteproprietarioid integer,
																    loginoperazione varchar,
                                                                    genAnnulla  boolean, -- true per annullare AMBITO_FIN, false NO
                                                                    genAnnullaGsa  boolean, -- true per annullare AMBITO_GSA, false NO
                                                                    genImpegno  boolean, -- inserire genImpegni ( fin,gsa )
                                                                    genLiquidazione boolean,-- inserire genLiq
                                                                    genDocumento boolean, -- da implementare
                                                                    genOrdinativo BOOLEAN, -- inserire genOrd ( fin,gsa )
																    out codicerisultato integer,
																    out messaggiorisultato varchar
                                                                   );


drop FUNCTION if exists siac.fnc_siac_bko_sposta_regmovfin_prima_nota(annoBilancio integer,
                                                                    enteproprietarioid integer,
																    loginoperazione varchar,
                                                                    genAnnulla  boolean, -- true per annullare AMBITO_FIN, false NO
                                                                    genAnnullaGsa  boolean, -- true per annullare AMBITO_GSA, false NO
                                                                    genImpegno  boolean, -- inserire genImpegni ( fin,gsa )
                                                                    genLiquidazione boolean,-- inserire genLiq
                                                                    genDocumento boolean, -- da implementare
                                                                    genOrdinativo BOOLEAN, -- inserire genOrd ( fin,gsa )
																	sequenceElabId integer,      -- 31.08.2022 Sofia Jira SIAC-8405
																	svuotaTabellaBko boolean, -- 31.08.2022 Sofia Jira SIAC-8405                                                                    
																    out codicerisultato integer,
																    out messaggiorisultato varchar
                                                                   );

                                                                  
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_sposta_regmovfin_prima_nota(annoBilancio integer,
                                                                    enteproprietarioid integer,
																    loginoperazione varchar,
                                                                    genAnnulla  boolean, -- true per annullare AMBITO_FIN, false NO
                                                                    genAnnullaGsa  boolean, -- true per annullare AMBITO_GSA, false NO
                                                                    genImpegno  boolean, -- inserire genImpegni ( fin,gsa )
                                                                    genLiquidazione boolean,-- inserire genLiq
                                                                    genDocumento boolean, -- da implementare
                                                                    genOrdinativo BOOLEAN, -- inserire genOrd ( fin,gsa )
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
 -- siac_bko_sposta_regmovfin_prima_nota

 strMessaggioFinale:='Sposta registro prima nota su nuovo PDC_V.';
 codiceRisultato:=0;

 -- 31.08.2022 Sofia Jira SIAC-8405 - inizio
 raise notice '% sequenceElabId=%',strMessaggioFinale,coalesce(sequenceElabId::varchar,' ');
 
  if coalesce(sequenceElabId,0)=0 then 
  	raise exception ' Indicare un sequenceElabId calcolato con  fnc_siac_bko_spostamenti_id_seq_incrementa.';
  end if;
 
 
  select 1 into codiceRisultato
  from siac_bko_sposta_regmovfin_prima_nota bko 
  where bko.ente_proprietario_id =enteproprietarioid
  and     bko.bko_spostamenti_id !=sequenceElabId;
  if coalesce(codiceRisultato,0)!=0 then 
  	codiceRisultato:=-1;
    raise exception ' Esistono dati in tabella siac_bko_sposta_regmovfin_prima_nota per l'' ente caricati con  bko_spostamenti_id diverso da sequenceElabId=% passato.Verificare e cancellarli prima di procedere.',sequenceElabId::varchar;
  end if;
 
 -- 31.08.2022 Sofia Jira SIAC-8405 - fine 

 
 if genAnnulla=true or genAnnullaGSA=true then
 -- impegno

 strMessaggio:= 'collegamento tra impegno e prima nota : inserimento stato annullato.';
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
                  loginOperazione||'-IMP',
                  tipo.ente_proprietario_id
 from siac_d_movgest_tipo tipo, siac_t_movgest mov,
      siac_v_bko_anno_bilancio anno,
      siac_bko_sposta_regmovfin_prima_nota bko,
      siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
      siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
      siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
      siac_d_prima_nota_stato statoA, siac_d_ambito a
 where  tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.movgest_tipo_code='I'
  and   mov.movgest_tipo_id=tipo.movgest_tipo_id
  and   anno.bil_id=mov.bil_id
  and   anno.anno_bilancio=annoBilancio
  and   bko.ente_proprietario_id=tipo.ente_proprietario_id
  and   bko.anno_bilancio=anno.anno_bilancio
  and   mov.movgest_anno::integer=bko.movgest_anno
  and   mov.movgest_numero::integer=bko.movgest_numero
  and   revento.campo_pk_id=mov.movgest_id
  and   evento.evento_id=revento.evento_id
  and   evento.evento_code=bko.evento_code
  and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
  and   coll.collegamento_tipo_code='I' --- impegno
  and   reg.regmovfin_id=revento.regmovfin_id
  and   rrstato.regmovfin_id=reg.regmovfin_id
  and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
  and   rstato.regmovfin_stato_code!='A'
  and   ep.regmovfin_id=reg.regmovfin_id
  and   pnota.pnota_id=ep.regep_id
  and   r.pnota_id=pnota.pnota_id
  and   pnstato.pnota_stato_id=r.pnota_stato_id
  and   pnstato.pnota_stato_code!='A'
  and   a.ambito_id=pnota.ambito_id
  and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
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
  and   r.validita_fine is null;

  -- annullare prima nota, se presente non annullata
  strMessaggio:= 'collegamento tra impegno e prima nota : annullamento stato non annullato prima nota.';
  raise notice 'strMessaggio=%',strMessaggio;

  update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||loginOperazione||'-IMP'
  from  siac_d_movgest_tipo tipo, siac_t_movgest mov,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_d_ambito a
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_tipo_code='I'
   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
   and   anno.bil_id=mov.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=anno.anno_bilancio
   and   mov.movgest_anno::integer=bko.movgest_anno
   and   mov.movgest_numero::integer=bko.movgest_numero
   and   revento.campo_pk_id=mov.movgest_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='I'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   a.ambito_id=pnota.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
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
   strMessaggio:= 'collegamento tra impegno e registro prima nota precedente : inserimento stato annullato.';
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
                   loginOperazione||'-IMP',
                   tipo.ente_proprietario_id
   from siac_d_movgest_tipo tipo, siac_t_movgest mov,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_d_reg_movfin_stato statoA,siac_d_ambito a
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_tipo_code='I'
   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
   and   anno.bil_id=mov.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=anno.anno_bilancio
   and   mov.movgest_anno::integer=bko.movgest_anno
   and   mov.movgest_numero::integer=bko.movgest_numero
   and   revento.campo_pk_id=mov.movgest_id
   and   evento.evento_id=revento.evento_id
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='I'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   a.ambito_id=reg.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.regmovfin_stato_code='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null;


   strMessaggio:= 'collegamento tra impegno e registro prima nota precedente : annullamento stato non annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   update siac_r_reg_movfin_stato rrstato
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstato.login_operazione||'-'||loginOperazione||'-IMP'
   from siac_d_movgest_tipo tipo, siac_t_movgest mov,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg,  siac_d_reg_movfin_stato rstato,siac_d_ambito a
   where  tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='I'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   anno.bil_id=mov.bil_id
    and   anno.anno_bilancio=annoBilancio
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   bko.anno_bilancio=anno.anno_bilancio
    and   mov.movgest_anno::integer=bko.movgest_anno
    and   mov.movgest_numero::integer=bko.movgest_numero
    and   revento.campo_pk_id=mov.movgest_id
    and   evento.evento_id=revento.evento_id
    and   evento.evento_code=bko.evento_code
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='I'
    and   reg.regmovfin_id=revento.regmovfin_id
    and   a.ambito_id=reg.ambito_id
    and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
    and   rrstato.regmovfin_id=reg.regmovfin_id
    and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
    and   rstato.regmovfin_stato_code!='A'
    and   revento.data_cancellazione is null
    and   revento.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null
    and   rrstato.data_cancellazione is null
    and   rrstato.validita_fine is null;


  -- liquidazione
  strMessaggio:= 'collegamento tra liquidazione e prima nota : inserimento stato annullato.';
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
                  loginOperazione||'-LIQ',
                  pnota.ente_proprietario_id
  from siac_t_liquidazione liq,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA,
       siac_d_ambito a
  where  anno.ente_proprietario_id=enteProprietarioId
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=anno.ente_proprietario_id
   and   bko.anno_bilancio=anno.anno_bilancio
   and   liq.bil_id=anno.bil_id
   and   liq.liq_anno::integer=bko.liq_anno
   and   liq.liq_numero::integer=bko.liq_numero
   and   revento.campo_pk_id=liq.liq_id
   and   evento.evento_id=revento.evento_id
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='L' --- liquidazione
   and   reg.regmovfin_id=revento.regmovfin_id
   and   a.ambito_id=pnota.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   statoA.ente_proprietario_id=liq.ente_proprietario_id
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
   and   r.validita_fine is null;


  -- annullare prima nota, se presente non annullata
  strMessaggio:= 'collegamento tra liquidazione e prima nota : annullamento stato non annullato prima nota.';
  raise notice 'strMessaggio=%',strMessaggio;

  update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||loginOperazione||'-LIQ'
  from  siac_t_liquidazione liq,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_d_ambito a
  where  anno.ente_proprietario_id=enteProprietarioId
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=anno.ente_proprietario_id
   and   bko.anno_bilancio=anno.anno_bilancio
   and   liq.bil_id=anno.bil_id
   and   liq.liq_anno::integer=bko.liq_anno
   and   liq.liq_numero::integer=bko.liq_numero
   and   revento.campo_pk_id=liq.liq_id
   and   evento.evento_id=revento.evento_id
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='L'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   a.ambito_id=pnota.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
   and   r.pnota_id=pnota.pnota_id
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
   and   r.validita_fine is null;


   -- inserire stato registro annullato, se esiste non annullato
   strMessaggio:= 'collegamento tra liquidazione e registro prima nota precedente : inserimento stato annullato.';
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
                   loginOperazione||'-LIQ',
                   reg.ente_proprietario_id
   from siac_t_liquidazione liq,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_d_reg_movfin_stato statoA, siac_d_ambito a
   where anno.ente_proprietario_id=enteProprietarioId
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=anno.ente_proprietario_id
   and   bko.anno_bilancio=anno.anno_bilancio
   and   liq.bil_id=anno.bil_id
   and   liq.liq_anno::integer=bko.liq_anno
   and   liq.liq_numero::integer=bko.liq_numero
   and   revento.campo_pk_id=liq.liq_id
   and   evento.evento_id=revento.evento_id
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='L'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   statoA.ente_proprietario_id=liq.ente_proprietario_id
   and   statoA.regmovfin_stato_code='A'
   and   a.ambito_id=reg.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null;
   -- 1

   strMessaggio:= 'collegamento tra liquidazione e registro prima nota precedente : annullamento stato non annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   update siac_r_reg_movfin_stato rrstato
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstato.login_operazione||'-'||loginOperazione||'-LIQ'
   from siac_t_liquidazione liq,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg,  siac_d_reg_movfin_stato rstato,siac_d_ambito a
   where  anno.ente_proprietario_id=enteProprietarioId
    and   anno.anno_bilancio=annoBilancio
    and   bko.ente_proprietario_id=anno.ente_proprietario_id
    and   bko.anno_bilancio=anno.anno_bilancio
    and   liq.bil_id=anno.bil_id
    and   liq.liq_anno::integer=bko.liq_anno
    and   liq.liq_numero::integer=bko.liq_numero
    and   revento.campo_pk_id=liq.liq_id
    and   evento.evento_id=revento.evento_id
    and   evento.evento_code=bko.evento_code
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='L'
    and   reg.regmovfin_id=revento.regmovfin_id
    and   a.ambito_id=reg.ambito_id
    and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
    and   rrstato.regmovfin_id=reg.regmovfin_id
    and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
    and   rstato.regmovfin_stato_code!='A'
    and   revento.data_cancellazione is null
    and   revento.validita_fine is null
    and   reg.data_cancellazione is null
    and   reg.validita_fine is null
    and   rrstato.data_cancellazione is null
    and   rrstato.validita_fine is null;

    -- 1
    -- ordinativo

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
                  loginOperazione||'-ORD',
                  tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA,siac_d_ambito a
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
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OP'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   a.ambito_id=pnota.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
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
   -- 18
   -- annullare prima nota, se presente non annullata
  strMessaggio:= 'collegamento tra ordinativo e prima nota : annullamento stato non annullato prima nota.';
  raise notice 'strMessaggio=%',strMessaggio;

  update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||loginOperazione||'-ORD'
  from  siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato, siac_d_ambito a
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
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OP'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   a.ambito_id=reg.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
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
   -- 18

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
                   loginOperazione||'-ORD',
                   tipo.ente_proprietario_id
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_d_reg_movfin_stato statoA,siac_d_ambito a
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
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OP'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   a.ambito_id=reg.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
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
   -- 177
   strMessaggio:= 'collegamento tra ordinativo e registro prima nota precedente : annullamento stato non annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   update siac_r_reg_movfin_stato rrstato
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstato.login_operazione||'-'||loginOperazione||'-ORD'
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg,  siac_d_reg_movfin_stato rstato,siac_d_ambito a
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
    and   evento.evento_code=bko.evento_code
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='OP'
    and   reg.regmovfin_id=revento.regmovfin_id
    and   a.ambito_id=reg.ambito_id
    and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )

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
    -- 177

  -- documenti - collegati ad un impegno
  strMessaggio:= 'collegamento tra documenti e prima nota : inserimento stato annullato.';
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
                  loginOperazione||'-DOC',
                  tipo.ente_proprietario_id
  from siac_d_movgest_tipo tipo,siac_t_movgest mov, siac_t_movgest_ts ts,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
       siac_r_subdoc_movgest_ts rsub,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA,siac_d_ambito a
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_tipo_code='I'
   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
   and   anno.bil_id=mov.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.movgest_anno=mov.movgest_anno::integer
   and   bko.movgest_numero=mov.movgest_numero::integer
   and   ts.movgest_id=mov.movgest_id
   and   rsub.movgest_ts_id=ts.movgest_ts_id
   and   revento.campo_pk_id=rsub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='SS'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   a.ambito_id=pnota.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   statoA.ente_proprietario_id=tipo.ente_proprietario_id
   and   statoA.pnota_stato_code='A'
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
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
  strMessaggio:= 'collegamento tra documenti e prima nota : annullamento stato non annullato prima nota.';
  raise notice 'strMessaggio=%',strMessaggio;

  update siac_r_prima_nota_stato r
  set    data_cancellazione=clock_timestamp(),
         validita_fine=clock_timestamp(),
         login_operazione=r.login_operazione||'-'||loginOperazione||'-DOC'
  from  siac_d_movgest_tipo tipo,siac_t_movgest mov, siac_t_movgest_ts ts,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_subdoc_movgest_ts rsub,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_d_ambito a
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_tipo_code='I'
   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
   and   anno.bil_id=mov.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.movgest_anno=mov.movgest_anno::integer
   and   bko.movgest_numero=mov.movgest_numero::integer
   and   ts.movgest_id=mov.movgest_id
   and   rsub.movgest_ts_id=ts.movgest_ts_id
   and   revento.campo_pk_id=rsub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   evento.evento_code=bko.evento_code
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='SS'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
   and   a.ambito_id=pnota.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )

   and   r.pnota_id=pnota.pnota_id
   and   pnstato.pnota_stato_id=r.pnota_stato_id
   and   pnstato.pnota_stato_code!='A'
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
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
   strMessaggio:= 'collegamento tra documenti e registro prima nota precedente : inserimento stato annullato.';
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
          --REG.subdoc_id,
          now(),
          loginOperazione||'-DOC',
	      statoA.ente_proprietario_id
   from siac_d_reg_movfin_stato statoA,
   (
   with
   impegno as
   (
   select distinct rsub.subdoc_id
   from siac_d_movgest_tipo tipo,siac_t_movgest mov, siac_t_movgest_ts ts,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_subdoc_movgest_ts rsub
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_tipo_code='I'
   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
   and   anno.bil_id=mov.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.movgest_anno=mov.movgest_anno::integer
   and   bko.movgest_numero=mov.movgest_numero::integer
   and   ts.movgest_id=mov.movgest_id
   and   rsub.movgest_ts_id=ts.movgest_ts_id
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   ),
   regmov as
   (
   select distinct reg.regmovfin_id,
                   revento.campo_pk_id
   from siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
		siac_d_ambito a
   where coll.ente_proprietario_id=enteProprietarioId
   and   coll.collegamento_tipo_code='SS'
   and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and   revento.evento_id=evento.evento_id
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   a.ambito_id=reg.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   )
   select impegno.subdoc_id,
          regmov.regmovfin_id
   from impegno, regmov
   where regmov.campo_pk_id=impegno.subdoc_id
   ) REG
   where statoA.ente_proprietario_id=enteProprietarioId
   and   statoA.regmovfin_stato_code='A';
   -- 267


   strMessaggio:= 'collegamento tra documenti e registro prima nota precedente : annullamento stato non annullato.';
   raise notice 'strMessaggio=%',strMessaggio;

   update siac_r_reg_movfin_stato rrstatoUPD
   set    data_cancellazione=clock_timestamp(),
          validita_fine=clock_timestamp(),
          login_operazione=rrstatoUPD.login_operazione||'-'||loginOperazione||'-DOC'
   from
   (
   with
   impegno as
   (
   select distinct rsub.subdoc_id
   from siac_d_movgest_tipo tipo,siac_t_movgest mov, siac_t_movgest_ts ts,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
        siac_r_subdoc_movgest_ts rsub
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_tipo_code='I'
   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
   and   anno.bil_id=mov.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.movgest_anno=mov.movgest_anno::integer
   and   bko.movgest_numero=mov.movgest_numero::integer
   and   ts.movgest_id=mov.movgest_id
   and   rsub.movgest_ts_id=ts.movgest_ts_id
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   ),
   regmov as
   (
   select distinct reg.regmovfin_id,
                   rrstato.regmovfin_stato_r_id,
                   revento.campo_pk_id
   from siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_d_ambito a
   where coll.ente_proprietario_id=enteProprietarioId
   and   coll.collegamento_tipo_code='SS'
   and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and   revento.evento_id=evento.evento_id
   and   reg.regmovfin_id=revento.regmovfin_id
   and   a.ambito_id=reg.ambito_id
   and   ( case when genAnnulla=true and genAnnullaGSA=true  then a.ambito_code in ('AMBITO_FIN','AMBITO_GSA')
               when genAnnullaGSA=true then a.ambito_code='AMBITO_GSA'
               when genAnnulla=true then a.ambito_code='AMBITO_FIN' end )
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   revento.data_cancellazione is null
   and   revento.validita_fine is null
   and   reg.data_cancellazione is null
   and   reg.validita_fine is null
   and   rrstato.data_cancellazione is null
   and   rrstato.validita_fine is null
   )
   select impegno.subdoc_id,
          regmov.regmovfin_id,
          regmov.regmovfin_stato_r_id
   from impegno, regmov
   where regmov.campo_pk_id=impegno.subdoc_id
   ) REG
   where rrstatoUPD.ente_proprietario_id=enteProprietarioId
   and   rrstatoUPD.regmovfin_stato_r_id=REG.regmovfin_stato_r_id;
   -- 267
 end if;

------------- INSERIMENTI

 -- inserimento registri notificati per Impegni
 if genImpegno=true then
  strMessaggio:= 'registro generale impegno : inserimento nuovo registro.';
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
  with
  pdcFin as
  (
  select rc.movgest_ts_id, c.classif_id
  from siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipoc
  where tipoc.ente_proprietario_id=enteProprietarioId
  and   tipoc.classif_tipo_code='PDC_V'
  and   c.classif_tipo_id=tipoc.classif_tipo_id
  and   rc.classif_id=c.classif_id
  and  rc.data_cancellazione is null
  and  rc.validita_fine is null
  and  c.data_cancellazione is null
  ),
  impegno as
  (select distinct
          mov.bil_id,
          mov.movgest_id,
          ts.movgest_ts_id,
          a.ambito_id,
          mov.ente_proprietario_id,
          tipots.movgest_ts_tipo_code
  from siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_tipo tipoimp,siac_d_movgest_ts_tipo tipots,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
       siac_d_evento evento , siac_d_collegamento_tipo coll,siac_d_ambito a
  where tipoimp.ente_proprietario_id=enteProprietarioId
   and  tipoimp.movgest_tipo_code='I'
   and  mov.movgest_tipo_id=tipoimp.movgest_tipo_id
   and  anno.bil_id=mov.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=mov.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.mov_genera=true
   and  bko.movgest_anno=mov.movgest_anno::integer
   and  bko.movgest_numero=mov.movgest_numero::integer
   and  ts.movgest_id=mov.movgest_id
   and  tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
   and  (case when bko.movgest_subnumero=0 then tipots.movgest_ts_tipo_code='T' else
                   ts.movgest_ts_code::integer=bko.movgest_subnumero and tipots.movgest_ts_tipo_code='S' end )
   and  coll.ente_proprietario_id=mov.ente_proprietario_id
   and  coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and  evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and  a.ente_proprietario_id=mov.ente_proprietario_id
   and  a.ambito_code='AMBITO_FIN'
   and  mov.data_cancellazione is null
   and  mov.validita_fine is null
   and  ts.data_cancellazione is null
   and  ts.validita_fine is null

  )
  select pdcFin.classif_id,
		 pdcFin.classif_id,
         impegno.bil_id,
         impegno.ambito_id,
         now(),
         loginOperazione||'-IMP'||'@'||
         (case when impegno.movgest_ts_tipo_code='T' then impegno.movgest_id::varchar else impegno.movgest_ts_id::varchar end),
         impegno.ente_proprietario_id
  from pdcFin, impegno
  where impegno.movgest_ts_id=pdcFin.movgest_ts_id
  );


  strMessaggio:= 'registro prima nota  impegno  : inserimento stato NOTIFICATO.';
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
         loginOperazione||'-IMP',
         reg.ente_proprietario_id
  from siac_t_reg_movfin reg ,siac_d_reg_movfin_stato stato
  where reg.ente_proprietario_id=enteProprietarioId
  and   reg.login_operazione like loginOperazione||'-IMP'||'@%'
  and   stato.ente_proprietario_id=reg.ente_proprietario_id
  and   stato.regmovfin_stato_code='N';


  strMessaggio:= 'collegamento tra registro prima nota e impegno : inserimento relazione.';
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
          (case when bko.movgest_subnumero=0 then mov.movgest_id else ts.movgest_ts_id end ),
         now(),
         loginOperazione||'-IMP',
         mov.ente_proprietario_id
  from siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_tipo tipoimp,siac_d_movgest_ts_tipo tipots,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
	   siac_d_evento evento , siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg
  where tipoimp.ente_proprietario_id=enteProprietarioId
   and  tipoimp.movgest_tipo_code='I'
   and  mov.movgest_tipo_id=tipoimp.movgest_tipo_id
   and  anno.bil_id=mov.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=mov.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.movgest_anno=mov.movgest_anno::integer
   and  bko.movgest_numero=mov.movgest_numero::integer
   and  bko.mov_genera=true
   and  ts.movgest_id=mov.movgest_id
   and  tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
   and  (case when bko.movgest_subnumero=0 then tipots.movgest_ts_tipo_code='T' else
                   ts.movgest_ts_code::integer=bko.movgest_subnumero and tipots.movgest_ts_tipo_code='S' end )
  and   coll.ente_proprietario_id=mov.ente_proprietario_id
  and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
  and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
  and   evento.evento_code=bko.evento_code
  and   reg.ente_proprietario_id=mov.ente_proprietario_id
  and   reg.login_operazione like loginOperazione||'-IMP'||'@%'
  and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=
         (case when tipots.movgest_ts_tipo_code='T' then mov.movgest_id else ts.movgest_ts_id end)
  and   mov.data_cancellazione is null
  and   mov.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   reg.data_cancellazione is null
  and   Reg.validita_fine is null;

  strMessaggio:= 'registro generale impegno AMBITO_GSA: inserimento nuovo registro.';
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
   with
   pdcFin as
   (
    select rc.movgest_ts_id, c.classif_id
    from siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipoc
    where tipoc.ente_proprietario_id=enteProprietarioId
    and   tipoc.classif_tipo_code='PDC_V'
    and   c.classif_tipo_id=tipoc.classif_tipo_id
    and   rc.classif_id=c.classif_id
    and  rc.data_cancellazione is null
    and  rc.validita_fine is null
    and  c.data_cancellazione is null
   ),
   impegno as
   (select distinct
           mov.bil_id,
           mov.movgest_id,
           ts.movgest_ts_id,
           a.ambito_id,
           mov.ente_proprietario_id,
           tipots.movgest_ts_tipo_code
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_tipo tipoimp,siac_d_movgest_ts_tipo tipots,
         siac_v_bko_anno_bilancio anno,
         siac_bko_sposta_regmovfin_prima_nota bko,
         siac_d_evento evento , siac_d_collegamento_tipo coll,siac_d_ambito a
    where tipoimp.ente_proprietario_id=enteProprietarioId
     and  tipoimp.movgest_tipo_code='I'
     and  mov.movgest_tipo_id=tipoimp.movgest_tipo_id
     and  anno.bil_id=mov.bil_id
     and  anno.anno_bilancio=annoBilancio
     and  bko.ente_proprietario_id=mov.ente_proprietario_id
     and  bko.anno_bilancio=annoBilancio
--     and  bko.mov_genera=true
     and  bko.mov_genera_gsa=true
     and  bko.movgest_anno=mov.movgest_anno::integer
     and  bko.movgest_numero=mov.movgest_numero::integer
     and  ts.movgest_id=mov.movgest_id
     and  tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and  (case when bko.movgest_subnumero=0 then tipots.movgest_ts_tipo_code='T' else
                     ts.movgest_ts_code::integer=bko.movgest_subnumero and tipots.movgest_ts_tipo_code='S' end )
     and  coll.ente_proprietario_id=mov.ente_proprietario_id
     and  coll.collegamento_tipo_code=bko.collegamento_tipo_code
     and  evento.collegamento_tipo_id=coll.collegamento_tipo_id
     and  evento.evento_code=bko.evento_code
     and  a.ente_proprietario_id=mov.ente_proprietario_id
     and  a.ambito_code='AMBITO_GSA'
     and  mov.data_cancellazione is null
     and  mov.validita_fine is null
     and  ts.data_cancellazione is null
     and  ts.validita_fine is null
    )
    select pdcFin.classif_id,
	   	   pdcFin.classif_id,
           impegno.bil_id,
           impegno.ambito_id,
           now(),
           loginOperazione||'-IMP-GSA'||'@'||
           (case when impegno.movgest_ts_tipo_code='T' then impegno.movgest_id::varchar else impegno.movgest_ts_id::varchar end),
           impegno.ente_proprietario_id
    from pdcFin, impegno
    where impegno.movgest_ts_id=pdcFin.movgest_ts_id
  );

  strMessaggio:= 'registro prima nota  impegno AMBITO_GSA : inserimento stato NOTIFICATO.';
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
          loginOperazione||'-IMP-GSA',
          reg.ente_proprietario_id
  from siac_t_reg_movfin reg ,siac_d_reg_movfin_stato stato
  where reg.ente_proprietario_id=enteProprietarioId
  and   reg.login_operazione like loginOperazione||'-IMP-GSA'||'@%'
  and   stato.ente_proprietario_id=reg.ente_proprietario_id
  and   stato.regmovfin_stato_code='N';



  strMessaggio:= 'collegamento tra registro prima nota e impegno AMBITO_GSA : inserimento relazione.';
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
          (case when bko.movgest_subnumero=0 then mov.movgest_id else ts.movgest_ts_id end ),
          now(),
          loginOperazione||'-IMP-GSA',
          mov.ente_proprietario_id
   from siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_tipo tipoimp,siac_d_movgest_ts_tipo tipots,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_regmovfin_prima_nota bko,
	    siac_d_evento evento , siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg
   where tipoimp.ente_proprietario_id=enteProprietarioId
   and  tipoimp.movgest_tipo_code='I'
   and  mov.movgest_tipo_id=tipoimp.movgest_tipo_id
   and  anno.bil_id=mov.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=mov.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.movgest_anno=mov.movgest_anno::integer
   and  bko.movgest_numero=mov.movgest_numero::integer
--   and  bko.mov_genera=true
   and  bko.mov_genera_gsa=true
   and  ts.movgest_id=mov.movgest_id
   and  tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
   and  (case when bko.movgest_subnumero=0 then tipots.movgest_ts_tipo_code='T' else
                   ts.movgest_ts_code::integer=bko.movgest_subnumero and tipots.movgest_ts_tipo_code='S' end )
   and   coll.ente_proprietario_id=mov.ente_proprietario_id
   and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and   evento.evento_code=bko.evento_code
   and   reg.ente_proprietario_id=mov.ente_proprietario_id
   and   reg.login_operazione like loginOperazione||'-IMP-GSA'||'@%'
   and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=
         (case when tipots.movgest_ts_tipo_code='T' then mov.movgest_id else ts.movgest_ts_id end)
   and   mov.data_cancellazione is null
   and   mov.validita_fine is null
   and   ts.data_cancellazione is null
   and   ts.validita_fine is null
   and   reg.data_cancellazione is null
   and   Reg.validita_fine is null;

 end if;


 -- inserimento registri notificati per Liquidazione
 if genLiquidazione=true then
  strMessaggio:= 'registro generale liquidazione : inserimento nuovo registro.';
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
  with
  pdcFin as
  (
  select rc.liq_id, c.classif_id
  from siac_r_liquidazione_class rc, siac_t_class c, siac_d_class_tipo tipoc
  where tipoc.ente_proprietario_id=enteProprietarioId
  and   tipoc.classif_tipo_code='PDC_V'
  and   c.classif_tipo_id=tipoc.classif_tipo_id
  and   rc.classif_id=c.classif_id
  and  rc.data_cancellazione is null
  and  rc.validita_fine is null
  and  c.data_cancellazione is null
  ),
  liquid as
  (select distinct
          liq.bil_id,
          liq.liq_id,
          a.ambito_id,
          liq.ente_proprietario_id
  from siac_t_liquidazione liq,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
       siac_d_evento evento , siac_d_collegamento_tipo coll,siac_d_ambito a
  where liq.ente_proprietario_id=enteProprietarioId
   and  anno.bil_id=liq.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=liq.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.liq_anno=liq.liq_anno::integer
   and  bko.liq_numero=liq.liq_numero::integer
   and  bko.liq_genera=true
   and  coll.ente_proprietario_id=liq.ente_proprietario_id
   and  coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and  evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and  evento.evento_code=bko.evento_code
   and  a.ente_proprietario_id=liq.ente_proprietario_id
   and  a.ambito_code='AMBITO_FIN'
   and  liq.data_cancellazione is null
   and  liq.validita_fine is null
  )
  select pdcFin.classif_id,
		 pdcFin.classif_id,
         liquid.bil_id,
         liquid.ambito_id,
         now(),
         loginOperazione||'-LIQ'||'@'||liquid.liq_id::varchar,
         liquid.ente_proprietario_id
  from pdcFin, liquid
  where liquid.liq_id=pdcFin.liq_id
  );


  strMessaggio:= 'registro prima nota  liquidazione  : inserimento stato NOTIFICATO.';
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
         loginOperazione||'-LIQ',
         reg.ente_proprietario_id
  from siac_t_reg_movfin reg ,siac_d_reg_movfin_stato stato
  where reg.ente_proprietario_id=enteProprietarioId
  and   reg.login_operazione like loginOperazione||'-LIQ'||'@%'
  and   stato.ente_proprietario_id=reg.ente_proprietario_id
  and   stato.regmovfin_stato_code='N';


  strMessaggio:= 'collegamento tra registro prima nota e liquidazione : inserimento relazione.';
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
         liq.liq_id,
         now(),
         loginOperazione||'-LIQ',
         liq.ente_proprietario_id
  from siac_t_liquidazione liq,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
	   siac_d_evento evento , siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg
  where liq.ente_proprietario_id=enteProprietarioId
  and   anno.bil_id=liq.bil_id
  and   anno.anno_bilancio=annoBilancio
  and   bko.ente_proprietario_id=liq.ente_proprietario_id
  and   bko.anno_bilancio=annoBilancio
  and   bko.liq_anno=liq.liq_anno::integer
  and   bko.liq_numero=liq.liq_numero::integer
  and   bko.liq_genera=true
  and   coll.ente_proprietario_id=liq.ente_proprietario_id
  and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
  and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
--  and   evento.evento_code='LIQ-RES-INS'
  and   evento.evento_code=bko.evento_code
  and   reg.ente_proprietario_id=liq.ente_proprietario_id
  and   reg.login_operazione like loginOperazione||'-LIQ'||'@%'
  and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=liq.liq_id
  and   liq.data_cancellazione is null
  and   liq.validita_fine is null
  and   reg.data_cancellazione is null
  and   Reg.validita_fine is null;

 end if;


 -- inserimento registri notificati per Ordinativi
 if genOrdinativo=true then
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
  (
  with
  pdcFin as
  (
  select rc.ord_id, c.classif_id
  from siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipoc
  where tipoc.ente_proprietario_id=enteProprietarioId
  and   tipoc.classif_tipo_code='PDC_V'
  and   c.classif_tipo_id=tipoc.classif_tipo_id
  and   rc.classif_id=c.classif_id
  and  rc.data_cancellazione is null
  and  rc.validita_fine is null
  and  c.data_cancellazione is null
  ),
  ordin as
  (select distinct
          ord.bil_id,
          ord.ord_id,
          a.ambito_id,
          tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
       siac_d_evento evento , siac_d_collegamento_tipo coll,siac_d_ambito a
  where  tipo.ente_proprietario_id=enteProprietarioId
   and  tipo.ord_tipo_code='P'
   and  ord.ord_tipo_id=tipo.ord_tipo_id
   and  anno.bil_id=ord.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=tipo.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.ord_numero=ord.ord_numero::integer
   and  bko.ord_genera=true
   and  coll.ente_proprietario_id=tipo.ente_proprietario_id
   and  coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and  evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and  evento.evento_code=bko.evento_code
   and  a.ente_proprietario_id=tipo.ente_proprietario_id
   and  a.ambito_code='AMBITO_FIN'
   and  ord.data_cancellazione is null
   and  ord.validita_fine is null
  )
  select pdcFin.classif_id,
		 pdcFin.classif_id,
         ordin.bil_id,
         ordin.ambito_id,
         now(),
         loginOperazione||'-ORD'||'@'||ordin.ord_id::varchar,
         ordin.ente_proprietario_id
  from pdcFin, ordin
  where ordin.ord_id=pdcFin.ord_id
  );


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
         loginOperazione||'-ORD',
         reg.ente_proprietario_id
  from siac_t_reg_movfin reg ,siac_d_reg_movfin_stato stato
  where reg.ente_proprietario_id=enteProprietarioId
  and   reg.login_operazione like loginOperazione||'-ORD'||'@%'
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
         loginOperazione||'-ORD',
         tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
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
  and  bko.ord_genera=true
  and   coll.ente_proprietario_id=tipo.ente_proprietario_id
  and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
  and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
  and   evento.evento_code=bko.evento_code
  and   reg.ente_proprietario_id=tipo.ente_proprietario_id
  and   reg.login_operazione like loginOperazione||'-ORD'||'@%'
  and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=ord.ord_id
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   reg.data_cancellazione is null
  and   Reg.validita_fine is null;

  strMessaggio:= 'registro generale ordinativo AMBITO_GSA : inserimento nuovo registro.';
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
  with
  pdcFin as
  (
  select rc.ord_id, c.classif_id
  from siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipoc
  where tipoc.ente_proprietario_id=enteProprietarioId
  and   tipoc.classif_tipo_code='PDC_V'
  and   c.classif_tipo_id=tipoc.classif_tipo_id
  and   rc.classif_id=c.classif_id
  and  rc.data_cancellazione is null
  and  rc.validita_fine is null
  and  c.data_cancellazione is null
  ),
  ordin as
  (select distinct
          ord.bil_id,
          ord.ord_id,
          a.ambito_id,
          tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
       siac_d_evento evento , siac_d_collegamento_tipo coll,siac_d_ambito a
  where  tipo.ente_proprietario_id=enteProprietarioId
   and  tipo.ord_tipo_code='P'
   and  ord.ord_tipo_id=tipo.ord_tipo_id
   and  anno.bil_id=ord.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=tipo.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.ord_numero=ord.ord_numero::integer
   and  bko.ord_genera_gsa=true
   and  coll.ente_proprietario_id=tipo.ente_proprietario_id
   and  coll.collegamento_tipo_code=bko.collegamento_tipo_code
   and  evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and  evento.evento_code=bko.evento_code
   and  a.ente_proprietario_id=tipo.ente_proprietario_id
   and  a.ambito_code='AMBITO_GSA'
   and  ord.data_cancellazione is null
   and  ord.validita_fine is null
  )
  select pdcFin.classif_id,
		 pdcFin.classif_id,
         ordin.bil_id,
         ordin.ambito_id,
         now(),
         loginOperazione||'-GSA-ORD'||'@'||ordin.ord_id::varchar,
         ordin.ente_proprietario_id
  from pdcFin, ordin
  where ordin.ord_id=pdcFin.ord_id
  );


  strMessaggio:= 'registro prima nota  ordinativo AMBITO_GSA : inserimento stato NOTIFICATO.';
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
         loginOperazione||'-GSA-ORD',
         reg.ente_proprietario_id
  from siac_t_reg_movfin reg ,siac_d_reg_movfin_stato stato
  where reg.ente_proprietario_id=enteProprietarioId
  and   reg.login_operazione like loginOperazione||'-GSA-ORD'||'@%'
  and   stato.ente_proprietario_id=reg.ente_proprietario_id
  and   stato.regmovfin_stato_code='N';


  strMessaggio:= 'collegamento tra registro prima nota e ordinativo AMBITO_GSA : inserimento relazione.';
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
         loginOperazione||'-GSA-ORD',
         tipo.ente_proprietario_id
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno,
       siac_bko_sposta_regmovfin_prima_nota bko,
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
  and   bko.ord_genera_gsa=true
  and   coll.ente_proprietario_id=tipo.ente_proprietario_id
  and   coll.collegamento_tipo_code=bko.collegamento_tipo_code
  and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
  and   evento.evento_code=bko.evento_code
  and   reg.ente_proprietario_id=tipo.ente_proprietario_id
  and   reg.login_operazione like loginOperazione||'-GSA-ORD'||'@%'
  and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=ord.ord_id
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   reg.data_cancellazione is null
  and   Reg.validita_fine is null;

 end if;



-- 31.08.2022 Sofia Jira SIAC-8405
 if svuotaTabellaBko=true then 
	 strMessaggio:= 'Svuotamento tabella siac_bko_sposta_regmovfin_prima_nota per sequenceElabId='||sequenceElabId::varchar||'.';
     raise notice 'strMessaggio=%',strMessaggio;
    
     delete   from siac_bko_sposta_regmovfin_prima_nota bko 
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


alter function  siac.fnc_siac_bko_sposta_regmovfin_prima_nota( integer,  integer,	varchar,  boolean,    boolean,   boolean,  boolean,  boolean,   BOOLEAN, 	 integer,   boolean,  out  integer,  out  varchar)  OWNER to siac;
