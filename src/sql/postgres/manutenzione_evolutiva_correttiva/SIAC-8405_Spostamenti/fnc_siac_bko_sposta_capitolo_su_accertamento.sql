/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 10.01.2018 Sofia - gia usata una volta
-- capitolo su accertamento
-- classificatori su accertamento chiedendo pdc_V
-- capitolo su ordinativo
-- classificatori su ordinativo prendendo da accertamento

drop FUNCTION if exists siac.fnc_siac_bko_sposta_capitolo_su_accertamento
(
annobilancio integer, 
pdcfinv_accertamento boolean,
pdcfin character varying, 
enteproprietarioid integer, 
loginoperazione character varying, 
genaggiorna boolean, 
genaccertamento boolean, 
gendocumento boolean, 
genordinativo boolean, 
OUT codicerisultato integer,
OUT messaggiorisultato character varying
);

drop function if exists  siac.fnc_siac_bko_sposta_capitolo_su_accertamento
(
annobilancio integer, 
pdcfinv_accertamento boolean,
pdcfin character varying, 
enteproprietarioid integer, 
loginoperazione character varying, 
genaggiorna boolean, 
genaccertamento boolean, 
gendocumento boolean, 
genordinativo boolean, 
sequenceElabId integer, -- 24.08.2022 Sofia Jira SIAC-8405
svuotaTabellaBko boolean, -- 24.08.2022 Sofia Jira SIAC-8405
OUT codicerisultato integer,
OUT messaggiorisultato character varying
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_sposta_capitolo_su_accertamento
(
annobilancio integer, 
pdcfinv_accertamento boolean,
pdcfin character varying, 
enteproprietarioid integer, 
loginoperazione character varying, 
genaggiorna boolean, 
genaccertamento boolean, 
gendocumento boolean, 
genordinativo boolean, 
sequenceElabId integer, -- 24.08.2022 Sofia Jira SIAC-8405
svuotaTabellaBko boolean, -- 24.08.2022 Sofia Jira SIAC-8405
OUT codicerisultato integer,
OUT messaggiorisultato character varying
)


 RETURNS record
 LANGUAGE plpgsql
AS $function$
DECLARE




strMessaggio         VARCHAR(1500):='';
strMessaggioFinale   VARCHAR(1500):='';


BEGIN

 strMessaggioFinale:='Sposta capitolo su accertamento.';
 codiceRisultato:=0;

 -- 24.08.2022 Sofia Jira SIAC-8405 - inizio
 raise notice '% sequenceElabId=%',strMessaggioFinale,coalesce(sequenceElabId::varchar,' ');
 
 if coalesce(sequenceElabId,0)=0 then 
  	raise exception ' Indicare un sequenceElabId calcolato con  fnc_siac_bko_spostamenti_id_seq_incrementa.';
 end if;

 select 1 into codiceRisultato
 from siac_bko_sposta_ordinativo_inc bko 
 where bko.ente_proprietario_id =enteproprietarioid
 and     bko.bko_spostamenti_id !=sequenceElabId;
 if coalesce(codiceRisultato,0)!=0 then 
  	codiceRisultato:=-1;
    raise exception ' Esistono dati in tabella siac_bko_sposta_ordinativo_inc per l'' ente caricati con  bko_spostamenti_id diverso da sequenceElabId=% passato.Verificare e cancellarli prima di procedere.',sequenceElabId::varchar;
 end if;
 
 -- 24.08.2022 Sofia Jira SIAC-8405 - fine 
 
 -- spostamento capitolo su accertamento
 strMessaggio:='collegamento tra capitolo e accertamento : annullamento precedente relazione.';
 raise notice 'strMessaggio=%',strMessaggio;

 update siac_r_movgest_bil_elem rmov
 set    data_cancellazione=clock_timestamp(),
        validita_fine=clock_timestamp(),
        login_operazione=rmov.login_operazione||'-'||loginOperazione
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_d_movgest_tipo tipo , siac_t_movgest mov
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.movgest_tipo_code='A'
 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
 and    anno.bil_id=mov.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.anno_accertamento_da=mov.movgest_anno::integer
 and    bko.numero_accertamento_da=mov.movgest_numero::integer
 and    rmov.movgest_id=mov.movgest_id
 and    rmov.data_cancellazione is null
 and    rmov.validita_fine is null;

 strMessaggio:='collegamento tra capitolo e accertamento : inserimento nuova  relazione.';
 raise notice 'strMessaggio=%',strMessaggio;
 insert into siac_r_movgest_bil_elem
 (
 	elem_id,
    movgest_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 with
 accertamento as
 (
 select distinct mov.movgest_id,
                 tipo.ente_proprietario_id,
                 bko.numero_capitolo_a,
                 bko.numero_articolo_a
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_d_movgest_tipo tipo, siac_t_movgest mov
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.movgest_tipo_code='A'
 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
 and    anno.bil_id=mov.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.anno_accertamento_da=mov.movgest_anno::integer
 and    bko.numero_accertamento_da=mov.movgest_numero::integer
 ) ,
 capitolo as
 (
  select e.elem_id, e.elem_code::integer,e.elem_code2::integer
  from siac_d_bil_elem_tipo tipoe, siac_t_bil_elem e, siac_v_bko_anno_bilancio anno
  where tipoe.ente_proprietario_id=enteProprietarioId
  and   tipoe.elem_tipo_code='CAP-EG'
  and   e.elem_tipo_id=tipoe.elem_tipo_id
  and   anno.bil_id=e.bil_id
  and   anno.anno_bilancio=annoBilancio
 )
 select capitolo.elem_id,
        accertamento.movgest_id,
        now(),
        loginOperazione,
        accertamento.ente_proprietario_id
 from  accertamento, capitolo
 where capitolo.elem_code=accertamento.numero_capitolo_a
 --INC000006308065: errata controllo sull'articolo del capitolo.
--and       capitolo.elem_code=accertamento.numero_articolo_a;
and    capitolo.elem_code2=accertamento.numero_articolo_a;

 -- spostamento classificatori su accertamento
 strMessaggio:='collegamento tra classificatori e accertamento : annullamento precedente relazione.';
 raise notice 'strMessaggio=%',strMessaggio;
 update siac_r_movgest_class rc
 set    data_cancellazione=now(),
        validita_fine=now(),
        login_operazione=rc.login_operazione||'-'||loginOperazione
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_d_movgest_tipo tipo, siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
        siac_t_class c, siac_d_class_tipo tipoc
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.movgest_tipo_code='A'
 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
 and    anno.bil_id=mov.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.anno_accertamento_da=mov.movgest_anno::integer
 and    bko.numero_accertamento_da=mov.movgest_numero::integer
 and    ts.movgest_id=mov.movgest_id
 and    tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
 and    (case when tipots.movgest_ts_tipo_code='T' then bko.numero_subaccertamento_da=0
              else bko.numero_subaccertamento_da=ts.movgest_ts_code::integer
         end)
 and    rc.movgest_ts_id=ts.movgest_ts_id
 and    c.classif_id=rc.classif_id
 and    tipoc.classif_tipo_id=c.classif_tipo_id
 and    tipoc.classif_tipo_code in
 (
 'PDC_V',
 'PERIMETRO_SANITARIO_ENTRATA',
 'RICORRENTE_ENTRATA',
 'TRANSAZIONE_UE_ENTRATA'
 )
 and    rc.data_cancellazione is null
 and    rc.validita_fine is null;

 strMessaggio:='collegamento tra classificatori e accertamento : inserimento nuove relazioni.';
 raise notice 'strMessaggio=%',strMessaggio;
 insert into siac_r_movgest_class
 (
 	movgest_ts_id,
    classif_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
 )
 select distinct
        ts.movgest_ts_id,
        c.classif_id,
        now(),
        loginOperazione,
        tipo.ente_proprietario_id
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_d_movgest_tipo tipo, siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
        siac_r_movgest_bil_elem rmov,siac_r_bil_elem_class rc,
        siac_t_class c, siac_d_class_tipo tipoc
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.movgest_tipo_code='A'
 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
 and    anno.bil_id=mov.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.anno_accertamento_da=mov.movgest_anno::integer
 and    bko.numero_accertamento_da=mov.movgest_numero::integer
 and    ts.movgest_id=mov.movgest_id
 and    tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
 and    (case when tipots.movgest_ts_tipo_code='T' then bko.numero_subaccertamento_da=0
              else bko.numero_subaccertamento_da=ts.movgest_ts_code::integer
         end)
 and    rmov.movgest_id=mov.movgest_id
 and    rc.elem_id=rmov.elem_id
 and    c.classif_id=rc.classif_id
 and    tipoc.classif_tipo_id=c.classif_tipo_id
 and    tipoc.classif_tipo_code in
 (
 'PDC_V',
 'PERIMETRO_SANITARIO_ENTRATA',
 'RICORRENTE_ENTRATA',
 'TRANSAZIONE_UE_ENTRATA'
 )
 and rmov.data_cancellazione is null
 and rmov.validita_fine is null
 and rc.data_cancellazione is null
 and rc.validita_fine is null;

 if pdcfinv_accertamento = true then 
    strMessaggio:='collegamento tra classificatori e accertamento PDC_FIN_V : inserimento nuove relazioni.';
    raise notice 'strMessaggio=%',strMessaggio;
    insert into siac_r_movgest_class
    (
   	 movgest_ts_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select distinct
           ts.movgest_ts_id,
           c.classif_id,
           now(),
           loginOperazione,
           tipo.ente_proprietario_id
 	from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
    	   siac_d_movgest_tipo tipo, siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
    	   siac_t_class c, siac_d_class_tipo tipoc
	 where  tipo.ente_proprietario_id=enteProprietarioId
	 and    tipo.movgest_tipo_code='A'
	 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
	 and    anno.bil_id=mov.bil_id
	 and    anno.anno_bilancio=annoBilancio
	 and    bko.ente_proprietario_id=anno.ente_proprietario_id
	 and    bko.anno_bilancio=anno.anno_bilancio
	 and    bko.anno_accertamento_da=mov.movgest_anno::integer
	 and    bko.numero_accertamento_da=mov.movgest_numero::integer
	 and    ts.movgest_id=mov.movgest_id
	 and    tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	 and    (case when tipots.movgest_ts_tipo_code='T' then bko.numero_subaccertamento_da=0
	              else bko.numero_subaccertamento_da=ts.movgest_ts_code::integer
	         end)
	 and    tipoc.ente_proprietario_id=mov.ente_proprietario_id
     and    tipoc.classif_tipo_code='PDC_V'
	 and    c.classif_tipo_id=tipoc.classif_tipo_id
     and    c.classif_id=bko.pdc_fin_acc_id
     and    c.data_cancellazione is null
     and    c.validita_fine is null;
 else 
  if pdcFin is not null then
    strMessaggio:='collegamento tra classificatori e accertamento PDC_FIN_V : inserimento nuove relazioni.';
    raise notice 'strMessaggio=%',strMessaggio;

 	insert into siac_r_movgest_class
    (
   	 movgest_ts_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select distinct
           ts.movgest_ts_id,
           c.classif_id,
           now(),
           loginOperazione,
           tipo.ente_proprietario_id
 	from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
    	   siac_d_movgest_tipo tipo, siac_t_movgest mov,siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
    	   siac_t_class c, siac_d_class_tipo tipoc
	 where  tipo.ente_proprietario_id=enteProprietarioId
	 and    tipo.movgest_tipo_code='A'
	 and    mov.movgest_tipo_id=tipo.movgest_tipo_id
	 and    anno.bil_id=mov.bil_id
	 and    anno.anno_bilancio=annoBilancio
	 and    bko.ente_proprietario_id=anno.ente_proprietario_id
	 and    bko.anno_bilancio=anno.anno_bilancio
	 and    bko.anno_accertamento_da=mov.movgest_anno::integer
	 and    bko.numero_accertamento_da=mov.movgest_numero::integer
	 and    ts.movgest_id=mov.movgest_id
	 and    tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	 and    (case when tipots.movgest_ts_tipo_code='T' then bko.numero_subaccertamento_da=0
	              else bko.numero_subaccertamento_da=ts.movgest_ts_code::integer
	         end)
	 and    tipoc.ente_proprietario_id=mov.ente_proprietario_id
     and    tipoc.classif_tipo_code='PDC_V'
	 and    c.classif_tipo_id=tipoc.classif_tipo_id
     and    c.classif_code=pdcFin
     and    c.data_cancellazione is null
     and    c.validita_fine is null;
  end if;
end if; 

 -- spostamento capitolo su ordinativo

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
      siac_bko_sposta_ordinativo_inc bko
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='I'
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
  select e.elem_code::integer,e.elem_id,e.elem_code2::integer
  from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,siac_v_bko_anno_bilancio anno
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.elem_tipo_code='CAP-EG'
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
           bko.numero_articolo_a,
           ord.ente_proprietario_id
    from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
         siac_v_bko_anno_bilancio anno,
         siac_bko_sposta_ordinativo_inc bko
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.ord_tipo_code='I'
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
  and      ordin.numero_articolo_a=cap.elem_code2
 );

 -- spostamento classificatori su ordinativo

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
      siac_bko_sposta_ordinativo_inc bko,
      siac_t_class c, siac_d_class_tipo tipoc
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.ord_tipo_code='I'
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
 'PERIMETRO_SANITARIO_ENTRATA',
 'RICORRENTE_ENTRATA',
 'TRANSAZIONE_UE_ENTRATA'
 )
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null;

 -- inserimento nuovi classificatori prendendo da nuova liquidazione
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
 from   siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_t_ordinativo_ts ordts,siac_r_ordinativo_ts_movgest_ts rmov,
        siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipoc
 where  tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.ord_tipo_code='I'
 and    ord.ord_tipo_id=tipo.ord_tipo_id
 and    anno.bil_id=ord.bil_id
 and    anno.anno_bilancio=annoBilancio
 and    bko.ente_proprietario_id=anno.ente_proprietario_id
 and    bko.anno_bilancio=anno.anno_bilancio
 and    bko.ord_numero=ord.ord_numero::integer
 and    ordts.ord_id=ord.ord_id
 and    ordts.ord_ts_code::integer=bko.ord_sub_numero
 and    rmov.ord_ts_id=ordts.ord_ts_id
 and    rc.movgest_ts_id=rmov.movgest_ts_id
 and    c.classif_id=rc.classif_id
 and    tipoc.classif_tipo_id=c.classif_tipo_id
 and    tipoc.classif_tipo_code in
 (
 'PDC_V',
 'PERIMETRO_SANITARIO_ENTRATA',
 'RICORRENTE_ENTRATA',
 'TRANSAZIONE_UE_ENTRATA'
 )
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   ordts.data_cancellazione is null
 and   ordts.validita_fine is null
 and   rmov.data_cancellazione is null
 and   rmov.validita_fine is null
 and   rc.data_cancellazione is null
 and   rc.validita_fine is null
 and   c.data_cancellazione is null;




 -- annullamento di tutte le prime note-registri
 if genAggiorna=true then




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
       siac_bko_sposta_ordinativo_inc bko,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OI'
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
         login_operazione=r.login_operazione||'-'||loginOperazione||'-ORD'
  from  siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_inc bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato
  where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OI'
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
                   loginOperazione||'-ORD',
                   tipo.ente_proprietario_id
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_inc bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
        siac_d_reg_movfin_stato statoA
   where  tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   revento.campo_pk_id=ord.ord_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='OI'
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
          login_operazione=rrstato.login_operazione||'-'||loginOperazione||'-ORD'
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_inc bko,
        siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg,  siac_d_reg_movfin_stato rstato
   where  tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.ord_tipo_code='I'
    and   ord.ord_tipo_id=tipo.ord_tipo_id
    and   anno.bil_id=ord.bil_id
    and   anno.anno_bilancio=annoBilancio
    and   bko.ente_proprietario_id=tipo.ente_proprietario_id
    and   bko.anno_bilancio=annoBilancio
    and   bko.ord_numero=ord.ord_numero::integer
    and   revento.campo_pk_id=ord.ord_id
    and   evento.evento_id=revento.evento_id
    and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
    and   coll.collegamento_tipo_code='OI'
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
/* SCRITTO MA MAI PROVATO
  -- documenti
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
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
       siac_t_ordinativo_ts ordts,
       siac_r_subdoc_ordinativo_ts rsub,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato,siac_r_prima_nota_stato r,
       siac_d_prima_nota_stato statoA
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   ordts.ord_id=ord.ord_id
   and   ordts.ord_ts_code::integer=bko.ord_sub_numero
   and   rsub.ord_ts_id=ordts.ord_ts_id
   and   revento.campo_pk_id=rsub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='SE'
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
  from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
       siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
       siac_t_ordinativo_ts ordts,
       siac_r_subdoc_ordinativo_ts rsub,
       siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato,
       siac_t_mov_ep ep, siac_t_prima_nota pnota, siac_d_prima_nota_stato pnstato
  where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   ordts.ord_id=ord.ord_id
   and   ordts.ord_ts_code::integer=bko.ord_sub_numero
   and   rsub.ord_ts_id=ordts.ord_ts_id
   and   revento.campo_pk_id=rsub.subdoc_id
   and   evento.evento_id=revento.evento_id
   and   coll.collegamento_tipo_id=evento.collegamento_tipo_id
   and   coll.collegamento_tipo_code='SE'
   and   reg.regmovfin_id=revento.regmovfin_id
   and   rrstato.regmovfin_id=reg.regmovfin_id
   and   rstato.regmovfin_stato_id=rrstato.regmovfin_stato_id
   and   rstato.regmovfin_stato_code!='A'
   and   ep.regmovfin_id=reg.regmovfin_id
   and   pnota.pnota_id=ep.regep_id
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
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_t_ordinativo_ts ordts,
        siac_r_subdoc_ordinativo_ts rsub
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   ordts.ord_id=ord.ord_id
   and   ordts.ord_ts_code::integer=bko.ord_sub_numero
   and   rsub.ord_ts_id=ordts.ord_ts_id
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   ),
   regmov as
   (
   select distinct reg.regmovfin_id,
                   revento.campo_pk_id
   from siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato
   where coll.ente_proprietario_id=enteProprietarioId
   and   coll.collegamento_tipo_code='SE'
   and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and   revento.evento_id=evento.evento_id
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
   )
   select impegno.subdoc_id,
          regmov.regmovfin_id
   from impegno, regmov
   where regmov.campo_pk_id=impegno.subdoc_id
   ) REG
   where statoA.ente_proprietario_id=enteProprietarioId
   and   statoA.regmovfin_stato_code='A';


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
   from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
        siac_v_bko_anno_bilancio anno, siac_bko_sposta_ordinativo_inc bko,
        siac_t_ordinativo_ts ordts,
        siac_r_subdoc_ordinativo_ts rsub
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_tipo_code='I'
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   anno.bil_id=ord.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.ord_numero=ord.ord_numero::integer
   and   ordts.ord_id=ord.ord_id
   and   ordts.ord_ts_code::integer=bko.ord_sub_numero
   and   rsub.ord_ts_id=ordts.ord_ts_id
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   ),
   regmov as
   (
   select distinct reg.regmovfin_id,
                   rrstato.regmovfin_stato_r_id,
                   revento.campo_pk_id
   from siac_r_evento_reg_movfin revento, siac_d_evento evento, siac_d_collegamento_tipo coll,
        siac_t_reg_movfin reg, siac_r_reg_movfin_stato rrstato, siac_d_reg_movfin_stato rstato
   where coll.ente_proprietario_id=enteProprietarioId
   and   coll.collegamento_tipo_code='SE'
   and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and   revento.evento_id=evento.evento_id
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
*/
 end if;

 -- inserimento registri notificati per Ordinativi
 if genAggiorna= true and genOrdinativo=true then
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
       siac_bko_sposta_ordinativo_inc bko,
       siac_d_evento evento , siac_d_collegamento_tipo coll,siac_d_ambito a
  where  tipo.ente_proprietario_id=enteProprietarioId
   and  tipo.ord_tipo_code='I'
   and  ord.ord_tipo_id=tipo.ord_tipo_id
   and  anno.bil_id=ord.bil_id
   and  anno.anno_bilancio=annoBilancio
   and  bko.ente_proprietario_id=tipo.ente_proprietario_id
   and  bko.anno_bilancio=annoBilancio
   and  bko.ord_numero=ord.ord_numero::integer
   and  coll.ente_proprietario_id=tipo.ente_proprietario_id
   and  coll.collegamento_tipo_code='OI'
   and  evento.collegamento_tipo_id=coll.collegamento_tipo_id
   and  evento.evento_code='OIN-INS'
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
       siac_bko_sposta_ordinativo_inc bko,
	   siac_d_evento evento , siac_d_collegamento_tipo coll,
       siac_t_reg_movfin reg
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.ord_tipo_code='I'
  and   ord.ord_tipo_id=tipo.ord_tipo_id
  and   anno.bil_id=ord.bil_id
  and   anno.anno_bilancio=annoBilancio
  and   bko.ente_proprietario_id=tipo.ente_proprietario_id
  and   bko.anno_bilancio=annoBilancio
  and   bko.ord_numero=ord.ord_numero::integer
  and   coll.ente_proprietario_id=tipo.ente_proprietario_id
  and   coll.collegamento_tipo_code='OI'
  and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
  and   evento.evento_code='OIN-INS'
  and   reg.ente_proprietario_id=tipo.ente_proprietario_id
  and   reg.login_operazione like loginOperazione||'-ORD'||'@%'
  and   substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer=ord.ord_id
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   reg.data_cancellazione is null
  and   Reg.validita_fine is null;

 end if;




  -- da implementare
  -- inserimento registri notificati per Documento
/* if genAggiorna= true and genDocumento=true then
  strMessaggio:= 'registro generale documento : inserimento nuovo registro.';
  raise notice 'strMessaggio=%',strMessaggio;

  -- inserire registro in stato NOTIFICATO
    insert into siac_t_reg_movfin
   (
    classif_id_iniziale,
    classif_id_aggiornato,
    bil_id ,
    ambito_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
   )
   (
   WITH
   documenti as
   (
   select distinct rsub.subdoc_id, ts.movgest_ts_id,mov.bil_id,ts.ente_proprietario_id
   from siac_d_movgest_tipo tipo,siac_t_movgest mov, siac_t_movgest_ts ts,
        siac_v_bko_anno_bilancio anno,
        siac_bko_sposta_ordinativo_pag_liquidazione bko,
        siac_r_subdoc_movgest_ts rsub,
        siac_d_movgest_ts_tipo tsTipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_tipo_code='I'
   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
   and   anno.bil_id=mov.bil_id
   and   anno.anno_bilancio=annoBilancio
   and   bko.ente_proprietario_id=tipo.ente_proprietario_id
   and   bko.anno_bilancio=annoBilancio
   and   bko.anno_impegno_a=mov.movgest_anno::integer
   and   bko.numero_impegno_a=mov.movgest_numero::integer
   and   ts.movgest_id=mov.movgest_id
   and   rsub.movgest_ts_id=ts.movgest_ts_id
   and   rsub.data_cancellazione is null
   and   rsub.validita_fine is null
   and   ts.movgest_ts_tipo_id = tsTipo.movgest_ts_tipo_id
   and   (ts.movgest_ts_code::integer = bko.numero_subimpegno_a
 	     or
         ( bko.numero_subimpegno_a = '0' and tsTipo.movgest_ts_tipo_code = 'T'))
  ),
  PdcFin as
  (
  select rc.movgest_ts_id, c.classif_id,a.ambito_id
  from siac_r_movgest_class rc, siac_t_class c, siac_d_class_tipo tipoc,siac_d_ambito a
  where tipoc.ente_proprietario_id=enteProprietarioId
  and   tipoc.classif_tipo_code='PDC_V'
  and   c.classif_tipo_id=tipoc.classif_tipo_id
  and   rc.classif_id=c.classif_id
  and   a.ente_proprietario_id=tipoc.ente_proprietario_id
  and   a.ambito_code='AMBITO_FIN'
  and   rc.data_cancellazione is null
  and   rc.validita_fine is null
  )
  select PdcFin.classif_id,
         PdcFin.classif_id,
         documenti.bil_id,
         PdcFin.ambito_id,
	     clock_timestamp(),
         loginOperazione||'-SS@'||documenti.subdoc_id::varchar,
         documenti.ente_proprietario_id
  from  documenti,PdcFin
  where documenti.movgest_ts_id=PdcFin.movgest_ts_id
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
        loginOperazione||'-SS',
        stato.ente_proprietario_id
 from siac_t_reg_movfin reg, siac_d_reg_movfin_stato stato
 where stato.ente_proprietario_id=enteProprietarioId
 and   stato.regmovfin_stato_code='N'
 and   reg.ente_proprietario_id=stato.ente_proprietario_id
 and   reg.login_operazione like loginOperazione||'-SS%';


 strMessaggio:= 'collegamento tra registro prima nota e documento : inserimento relazione.';
 raise notice 'strMessaggio=%',strMessaggio;

 insert into siac_r_evento_reg_movfin
 (
  regmovfin_id,
  evento_id,
  campo_pk_id ,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 (select  reg.regmovfin_id,
         evento.evento_id,
         subdoc.subdoc_id,
         clock_timestamp(),
         loginOperazione||'-SS',
         coll.ente_proprietario_id
 from siac_t_reg_movfin reg,siac_d_evento evento, siac_d_collegamento_tipo coll,siac_t_subdoc subdoc
 where coll.ente_proprietario_id=enteProprietarioId
 and   coll.collegamento_tipo_code='SS'
 and   evento.collegamento_tipo_id=coll.collegamento_tipo_id
 and   evento.evento_code='DSN-INS'
 and   reg.ente_proprietario_id=coll.ente_proprietario_id
 and   reg.login_operazione like loginOperazione||'%SS%'
 and   subdoc.ente_proprietario_id=coll.ente_proprietario_id
 and   subdoc.subdoc_id=
       substring (reg.login_operazione from position('@' in reg.login_operazione)+1)::integer
);

 end if;
*/



 -- 24.08.2022 Sofia Jira SIAC-8405
 if svuotaTabellaBko=true then 
	 strMessaggio:= 'Svuotamento tabella siac_bko_sposta_ordinativo_inc per sequenceElabId='||sequenceElabId::varchar||'.';
     raise notice 'strMessaggio=%',strMessaggio;
    
     delete   from siac_bko_sposta_ordinativo_inc bko 
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
$function$
;


alter function siac.fnc_siac_bko_sposta_capitolo_su_accertamento 
(  integer,  boolean, character varying,  integer,  character varying,  boolean,  boolean,  boolean,  boolean,  integer,  boolean, out  integer,out  varchar)  OWNER to siac;