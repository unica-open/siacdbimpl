/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_programmi_elabora_solo_r_mov (
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;


    bilancioElabId                   integer:=null;

    APE_GEST_PROGRAMMI    	    	 CONSTANT varchar:='APE_GEST_PROGRAMMI';

    P_FASE							 CONSTANT varchar:='P';
    G_FASE					    	 CONSTANT varchar:='G';

	STATO_AN 			    	     CONSTANT varchar:='AN';
    numeroProgr                      integer:=null;
    numeroCronop					 integer:=null;

     -- 30.07.2019 Sofia siac-6934
    flagDaRiaccAttrId                integer:=null;
    annoRiaccAttrId                  integer:=null;
    numeroRiaccAttrId                integer:=null;

BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Elaborazione.';




   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;

   strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
   select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
   from siac_t_bil bil, siac_t_periodo per
   where bil.ente_proprietario_id=enteProprietarioId
   and   per.periodo_id=bil.periodo_id
   and   per.anno::INTEGER=annoBilancio-1
   and   bil.data_cancellazione is null
   and   per.data_cancellazione is null;



   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
   else
   	bilancioElabId:=bilancioId;
   end if;


 --- inserimento collegamenti tra programma e siac_t_movgest_Ts [siac_r_movgest_ts_programma]
 --- inserimento collegamenti tra cronop    e siac_t_movgest_ts [siac_r_movgest_ts_cronop_elem]
 --  inserimento da effettuare solo per tipoApertura='G'
 --  quindi partendo da movimenti validi e programmi - cronop nuovi, riportare le relazioni da annoBilancioPrec
 --  convertendo gli id da annoPrec a annoBilancio
 -- 06.05.2019 Sofia siac-6255
 if tipoApertura=G_FASE then -- tutto da rivedere
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inizio.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;

  -- inserimento legami aperti esistenti su impegni/accertamenti residui
  -- siac_r_movgest_ts_programma
  -- residui
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma residui.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_res_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           mov.movgest_tipo_id,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia siac-6934

      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_res_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_res_anno,
         mov_res_anno_prec, progr progr_anno, progr progr_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   mov_res_anno.movgest_tipo_id=mov_res_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_res_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- pluriennali
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma pluriennali.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_pluri_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_pluri_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_pluri_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_pluri_anno,
         mov_pluri_anno_prec, progr progr_anno_prec,
         progr progr_anno
    where mov_pluri_anno.movgest_anno=mov_pluri_anno_prec.movgest_anno
    and   mov_pluri_anno.movgest_numero=mov_pluri_anno_prec.movgest_numero
    and   mov_pluri_anno.movgest_subnumero=mov_pluri_anno_prec.movgest_subnumero
    and   mov_pluri_anno.movgest_tipo_id=mov_pluri_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_pluri_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- 30.07.2019 Sofia siac-6934
  -- riaccertati
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma riaccertati.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
           query.programma_new_id,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    from
    (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,
           siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
    select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipo.movgest_ts_tipo_code='T' -- non il legame ad un sub sugli attributi quindi associo solo i programmi del padre
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_riacc_anno.movgest_ts_id,
           progr_anno.programma_id programma_new_id
    from mov_riacc_anno,
         mov_riacc_anno_prec, progr progr_anno_prec,
         progr progr_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   mov_riacc_anno.movgest_tipo_id=mov_riacc_anno_prec.movgest_tipo_id
    and   progr_anno_prec.programma_id=mov_riacc_anno_prec.programma_id
    and   progr_anno.bil_id=bilancioId
    and   progr_anno.programma_code=progr_anno_prec.programma_code
    ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'
     and    pstato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno, cronop cronop_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code !='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'   -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'   -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  --- 30.07.2019 Sofia siac-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
         query.cronop_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipo.movgest_ts_tipo_code='T'
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code !='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_anno_prec.cronop_id=mov_riacc_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query
   where
   not exists
   (select 1
    from siac_r_movgest_ts_cronop_elem r1
    where r1.movgest_ts_id=query.movgest_ts_id
    and   r1.cronop_id=query.cronop_new_id
    and   r1.cronop_elem_id is null
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
   )
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer<annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   mov.movgest_anno::integer>=annoBilancio
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)      elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'')  cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  --- 31.07.2019 Sofia SIAC-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	     query.cronop_new_id,
         query.cronop_elem_new_id,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
     with
     mov_anno as
     (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
             mov.movgest_tipo_id,
             ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipo.movgest_ts_tipo_code='T'
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     annoRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=annoRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     numeroRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=numeroRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     )
     select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
     from mov_anno, annoRiacc, numeroRiacc
     where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
     and   mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
             (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
             mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
           siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
           siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and   tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and   tipomov.movgest_tipo_code='I'
      and   ts.movgest_id=mov.movgest_id
      and   r.movgest_ts_id=ts.movgest_ts_id
      and   r.cronop_elem_id is not null
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code in ('D','N')
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   r.data_cancellazione is null
      and   r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
          siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
          siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and    tipo.programma_tipo_code=G_FASE
     and    prog.programma_tipo_id=tipo.programma_tipo_id
     and    cronop.programma_id=prog.programma_id
     and    celem.cronop_id=cronop.cronop_id
     and    det.cronop_elem_id=celem.cronop_elem_id
     and    rs.cronop_id=cronop.cronop_id
     and    stato.cronop_stato_id=rs.cronop_stato_id
---     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and    stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and    rsp.programma_id=prog.programma_id
     and    pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and    pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    rsp.data_cancellazione is null
     and    rsp.validita_fine is null
     and    prog.data_cancellazione is null
     and    prog.validita_fine is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    det.data_cancellazione is null
     and    det.validita_fine is null

    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
           cronop_elem_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_riacc_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query
   where not exists
   (
   select 1
   from siac_r_movgest_ts_cronop_elem r1
   where r1.movgest_ts_id=query.movgest_ts_id
   and   r1.cronop_id=query.cronop_new_id
   and   r1.cronop_elem_id=query.cronop_elem_new_id
   and   r1.data_cancellazione is null
   and   r1.validita_fine is null
   )
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;



  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - fine.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;
 end if;
 -- 06.05.2019 Sofia siac-6255



 strMessaggio:='Inserimento LOG.';
 codResult:=null;
 insert into fase_bil_t_elaborazione_log
 (fase_bil_elab_id,fase_bil_elab_log_operazione,
  validita_inizio, login_operazione, ente_proprietario_id
 )
 values
 (faseBilElabId,strMessaggioFinale||'-FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
 if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
 end if;

codiceRisultato:=0;
 if codiceRisultato=0 then
   	messaggioRisultato:=strMessaggioFinale||'- FINE.';
 else messaggioRisultato:=strMessaggioFinale||strMessaggio;
 end if;

 return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;