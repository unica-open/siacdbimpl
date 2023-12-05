/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-8633 Sofia 13.06.2023 inizio
alter table fase_bil_t_programmi_puntuale add column if not exists cronop_id integer null;

insert into fase_bil_d_elaborazione_tipo
(
 fase_bil_elab_tipo_code,
 fase_bil_elab_tipo_desc,
 fase_bil_elab_tipo_param,
 validita_inizio ,
 login_operazione ,
 ente_proprietario_id 
)
select 'APE_GEST_ALL_PROGRAMMI',
			'APERTURA BILANCIO : ALLINEAMENTO PROGRAMMI-CRONOP',
			'gp|GP|PG',
		    now(),
			'SIAC-8633',
			ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and     not exists 
(
select 1 
from fase_bil_d_elaborazione_tipo tipo 
where tipo.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo.fase_bil_elab_tipo_code ='APE_GEST_ALL_PROGRAMMI'
and      tipo.data_cancellazione is null 
and      tipo.validita_fine is null 
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_programmi_popola 
(
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);
drop FUNCTION if exists siac.fnc_fasi_bil_gest_apertura_programmi_pop_puntuale 
(
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone,
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
);

drop function if exists siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  ribalta_coll_mov boolean,    -- 17.05.2023 Sofia SIAC-8633
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);


drop FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_prev_approva_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_acc_elabora 
(
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists 
siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp 
(
  enteproprietarioid integer,
  annobilancio integer,
  tipoelab varchar,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists siac.fnc_fasi_bil_gest_apertura_pluri_elabora
( enteproprietarioid integer, annobilancio integer, fasebilelabid integer, tipocapitologest character varying, tipomovgest character varying, tipomovgestts character varying, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying);


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_popola (
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
    --- Sofia SIAC-8633 24.05.2023       
    GP_FASE                        CONSTANT varchar:='GP';  

	STATO_AN 			    	     CONSTANT varchar:='AN';
    numeroProgr                      integer:=null;
    numeroCronop					 integer:=0;
    programmaTipoCode                varchar(10):=null;
BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Popolamento.';

   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;




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

   --siac_t_programma
   --siac_r_programma_stato
   --siac_r_programma_class
   --siac_r_programma_attr
   --siac_r_programma_atto_amm
   --siac_r_movgest_ts_programma
   --siac_t_cronop
   --siac_r_cronop_stato
   --siac_r_cronop_attr
   --siac_t_cronop_elem
   --siac_r_cronop_elem_class
   --siac_r_cronop_elem_bil_elem
   --siac_t_cronop_elem_det

 /*  if tipoApertura=P_FASE then
 
   	bilancioElabId:=bilancioPrecId;
    programmaTipoCode=G_FASE;
   else
   	bilancioElabId:=bilancioId;
    programmaTipoCode=P_FASE;
   end if; Sofia SIAC-8633 24.05.2023         */

  -- Sofia SIAC-8633 24.05.2023         
  case  
   when tipoApertura=P_FASE then
	   	bilancioElabId:=bilancioPrecId;
    	programmaTipoCode=G_FASE;
   when tipoApertura=G_FASE then
	   bilancioElabId:=bilancioId;
       programmaTipoCode=P_FASE;
   when tipoApertura=GP_FASE then   
       bilancioElabId:=bilancioId;
       programmaTipoCode=G_FASE;
       tipoApertura=P_FASE;
  end case ;
 
   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi.';
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


   insert into fase_bil_t_programmi
   (
   	fase_bil_elab_id,
	fase_bil_programma_ape_tipo,
	programma_id,
	programma_tipo_id,
	bil_id,
    login_operazione,
    ente_proprietario_id
   )
   select faseBilElabId,
          tipoApertura,
          prog.programma_id,
          tipo.programma_tipo_id,
          prog.bil_id,
          loginOperazione,
          prog.ente_proprietario_id
   from siac_t_programma prog,siac_d_programma_tipo tipo,
	    siac_r_programma_stato rs,siac_d_programma_stato stato
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.programma_tipo_code=programmaTipoCode
   and   prog.programma_tipo_id=tipo.programma_tipo_id
   and   prog.bil_id=bilancioElabId
   and   rs.programma_id=prog.programma_id
   and   stato.programma_stato_id=rs.programma_stato_id
   and   stato.programma_stato_code!=STATO_AN
   and   prog.data_cancellazione is null
   and   prog.validita_fine is null
   and   rs.data_cancellazione is null
   and   rs.validita_fine is null;
   GET DIAGNOSTICS numeroProgr = ROW_COUNT;

   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi numero='||numeroProgr::varchar||'.';
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

   if coalesce(numeroProgr)!=0 then
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' '||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    codResult:=null;
    -- modificare qui in base a indicazioni di Floriana con n-insert diverse
    -- previsione quelli con usato_per_fpv=true
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Previsione scelti come FPV.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   cronop.usato_per_fpv=true
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=p_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Previsione scelti come FPV. numero='||codResult::varchar||'.';
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

    -- gestione   quelli con prov definitivo
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con provvedimento definitivo.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
         siac_r_cronop_atto_amm ratto,siac_r_atto_amm_stato rsatto,siac_d_atto_amm_stato statoatto
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   ratto.cronop_id=cronop.cronop_id
    and   rsatto.attoamm_id=ratto.attoamm_id
    and   statoatto.attoamm_stato_id=rsatto.attoamm_stato_id
    and   statoatto.attoamm_stato_code='DEFINITIVO'
    and   tipoApertura=g_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   rsatto.data_cancellazione is null
    and   rsatto.validita_fine is null
    and   not exists -- 17.05.2023 Sofia SIAC-8633
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con provvedimento definitivo. numero='||codResult::varchar||'.';
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


    -- gestione   quelli con impegno collegato ( se non ne ho gia ribaltati con prov def )
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con impegno collegato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=g_fase
    and   exists
    (
    select 1
    from siac_t_cronop_elem celem,siac_r_movgest_ts_cronop_elem rmov
    where celem.ente_proprietario_id=enteProprietarioId
    and   celem.cronop_id=cronop.cronop_id
    and   rmov.cronop_elem_id=celem.cronop_elem_id
    and   celem.data_cancellazione is null
    and   celem.validita_fine is null
    and   rmov.data_cancellazione is null
    and   rmov.validita_fine is null
    )
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con impegno collegato. numero='||codResult::varchar||'.';
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

    -- previsione/gestione quelli non annullati ( ultimo cronop aggiornato ) se non ne ho gia ribaltato prima
	codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Ultimo cronop aggiornato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   exists
	(
      select 1
      from siac_t_cronop c1
      where c1.ente_proprietario_id=enteProprietarioId
      and   c1.cronop_id=cronop.cronop_id
      and   c1.data_modifica=
      (
        select max(cmax.data_modifica)
        from siac_t_cronop cmax,siac_r_cronop_stato rsmax,siac_d_cronop_stato stmax
        where cmax.ente_proprietario_id=enteProprietarioId
        and   cmax.programma_id=c1.programma_id
        and   cmax.bil_id=c1.bil_id
        and   rsmax.cronop_id=cmax.cronop_id
        and   stmax.cronop_stato_id=rsmax.cronop_stato_id
        and   stmax.cronop_stato_code!=STATO_AN
        and   cmax.data_cancellazione is null
        and   cmax.validita_fine is null
        and   rsmax.data_cancellazione is null
        and   rsmax.validita_fine is null
      )
      and   c1.data_cancellazione is null
	  and   c1.validita_fine is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;


    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Ultimo cronop aggiornato. numero='||codResult::varchar||'.';
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



    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop numero='||numeroCronop::varchar||'.';
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
   raise notice 'Programmmi inseriti in fase_bil_t_programmi=%',numeroProgr;
   raise notice 'CronoProgrammmi inseriti in fase_bil_t_cronop=%',numeroCronop;


   strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
   update fase_bil_t_elaborazione fase
   set fase_bil_elab_esito='IN-1',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' IN CORSO IN-1.POPOLA PROGRAMMI-CRONOP.'
   where fase.fase_bil_elab_id=faseBilElabId;


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


   if coalesce(codiceRisultato,0)=0 then
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

alter FUNCTION  siac.fnc_fasi_bil_gest_apertura_programmi_popola (  integer, integer, integer,  varchar,  varchar,  timestamp, out integer, out  varchar) owner to siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_pop_puntuale 
(
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
    --- Sofia SIAC-8633 24.05.2023       
    GP_FASE                        CONSTANT varchar:='GP';  

	STATO_AN 			    	     CONSTANT varchar:='AN';
    numeroProgr                      integer:=null;
    numeroCronop					 integer:=0;
    programmaTipoCode                varchar(10):=null;
BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Popolamento.';

   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;




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

   --siac_t_programma
   --siac_r_programma_stato
   --siac_r_programma_class
   --siac_r_programma_attr
   --siac_r_programma_atto_amm
   --siac_r_movgest_ts_programma
   --siac_t_cronop
   --siac_r_cronop_stato
   --siac_r_cronop_attr
   --siac_t_cronop_elem
   --siac_r_cronop_elem_class
   --siac_r_cronop_elem_bil_elem
   --siac_t_cronop_elem_det

  -- Sofia SIAC-8633 24.05.2023
  /*
   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
    programmaTipoCode=G_FASE;
   else
   	bilancioElabId:=bilancioId;
    programmaTipoCode=P_FASE;
   end if;*/

  -- Sofia SIAC-8633 24.05.2023         
  case  
   when tipoApertura=P_FASE then
	   	bilancioElabId:=bilancioPrecId;
    	programmaTipoCode=G_FASE;
   when tipoApertura=G_FASE then
	   bilancioElabId:=bilancioId;
       programmaTipoCode=P_FASE;
   when tipoApertura=GP_FASE then   
       bilancioElabId:=bilancioId;
       programmaTipoCode=G_FASE;
       tipoApertura=P_FASE;
  end case ;
 
   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi.';
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


   insert into fase_bil_t_programmi
   (
   	fase_bil_elab_id,
	fase_bil_programma_ape_tipo,
	programma_id,
	programma_tipo_id,
	bil_id,
    login_operazione,
    ente_proprietario_id
   )
   select faseBilElabId,
          tipoApertura,
          prog.programma_id,
          tipo.programma_tipo_id,
          prog.bil_id,
          loginOperazione,
          prog.ente_proprietario_id
   from fase_bil_t_programmi_puntuale punt,
        siac_t_programma prog,siac_d_programma_tipo tipo,
	    siac_r_programma_stato rs,siac_d_programma_stato stato
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.programma_tipo_code=programmaTipoCode
   and   prog.programma_tipo_id=tipo.programma_tipo_id
   and   prog.bil_id=bilancioElabId
   and   rs.programma_id=prog.programma_id
   and   stato.programma_stato_id=rs.programma_stato_id
   and   stato.programma_stato_code!=STATO_AN
   and   punt.programma_id=prog.programma_id
   and   prog.data_cancellazione is null
   and   prog.validita_fine is null
   and   rs.data_cancellazione is null
   and   rs.validita_fine is null;
  -- and   punt.data_cancellazione is null
   --and   punt.validita_fine is null;
   GET DIAGNOSTICS numeroProgr = ROW_COUNT;

   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi numero='||numeroProgr::varchar||'.';
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

   if coalesce(numeroProgr)!=0 then
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' '||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    codResult:=null;
    -- modificare qui in base a indicazioni di Floriana con n-insert diverse
    -- previsione quelli con usato_per_fpv=true
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Previsione scelti come FPV.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
               fase_bil_t_programmi_puntuale  punt     --- Sofia SIAC-8633 19.06.2023
    where fase.fase_bil_elab_id=faseBilElabId
    and      punt.programma_id =fase.programma_id  --- Sofia SIAC-8633 19.06.2023
    and      cronop.programma_id=fase.programma_id
    and      cronop.bil_id=bilancioElabId
    --- Sofia SIAC-8633 19.06.2023    
    and   coalesce(punt.cronop_id, cronop.cronop_id) = cronop.cronop_id 
    and   cronop.usato_per_fpv=true
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=p_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Previsione scelti come FPV. numero='||codResult::varchar||'.';
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

    -- gestione   quelli con prov definitivo
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con provvedimento definitivo.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
         siac_r_cronop_atto_amm ratto,siac_r_atto_amm_stato rsatto,siac_d_atto_amm_stato statoatto,
         fase_bil_t_programmi_puntuale  punt     --- Sofia SIAC-8633 19.06.2023
    where fase.fase_bil_elab_id=faseBilElabId
    and      punt.programma_id =fase.programma_id --- Sofia SIAC-8633 19.06.2023
    and      cronop.programma_id=fase.programma_id
    and      cronop.bil_id=bilancioElabId
    --- Sofia SIAC-8633 19.06.2023    
    and   coalesce(punt.cronop_id, cronop.cronop_id) = cronop.cronop_id 
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   ratto.cronop_id=cronop.cronop_id
    and   rsatto.attoamm_id=ratto.attoamm_id
    and   statoatto.attoamm_stato_id=rsatto.attoamm_stato_id
    and   statoatto.attoamm_stato_code='DEFINITIVO'
    and   tipoApertura=g_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   rsatto.data_cancellazione is null
    and   rsatto.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con provvedimento definitivo. numero='||codResult::varchar||'.';
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


    -- gestione   quelli con impegno collegato ( se non ne ho gia ribaltati con prov def )
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con impegno collegato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
              fase_bil_t_programmi_puntuale  punt     --- Sofia SIAC-8633 21.06.2023
    where fase.fase_bil_elab_id=faseBilElabId
    and     punt.programma_id=fase.programma_id --- Sofia SIAC-8633 21.06.2023
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    --- Sofia SIAC-8633 21.06.2023    
    and   coalesce(punt.cronop_id, cronop.cronop_id) = cronop.cronop_id 
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=g_fase
    and   exists
    (
    select 1
    from siac_t_cronop_elem celem,siac_r_movgest_ts_cronop_elem rmov
    where celem.ente_proprietario_id=enteProprietarioId
    and   celem.cronop_id=cronop.cronop_id
    and   rmov.cronop_elem_id=celem.cronop_elem_id
    and   celem.data_cancellazione is null
    and   celem.validita_fine is null
    and   rmov.data_cancellazione is null
    and   rmov.validita_fine is null
    )
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con impegno collegato. numero='||codResult::varchar||'.';
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

    -- previsione/gestione quelli non annullati ( ultimo cronop aggiornato ) se non ne ho gia ribaltato prima
	codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Ultimo cronop aggiornato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
               fase_bil_t_programmi_puntuale  punt     --- Sofia SIAC-8633 21.06.2023
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    --- Sofia SIAC-8633 21.06.2023
    and  punt.programma_id =fase.programma_id 
    and   cronop.bil_id=bilancioElabId
    --- Sofia SIAC-8633 21.06.2023    
    and   coalesce(punt.cronop_id, cronop.cronop_id) = cronop.cronop_id 
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   exists
	(
      select 1
      from siac_t_cronop c1
      where c1.ente_proprietario_id=enteProprietarioId
      and   c1.cronop_id=cronop.cronop_id
      and   c1.data_modifica=
      (
        select max(cmax.data_modifica)
        from siac_t_cronop cmax,siac_r_cronop_stato rsmax,siac_d_cronop_stato stmax
        where cmax.ente_proprietario_id=enteProprietarioId
        and   cmax.programma_id=c1.programma_id
        and   cmax.bil_id=c1.bil_id
        and   rsmax.cronop_id=cmax.cronop_id
        and   stmax.cronop_stato_id=rsmax.cronop_stato_id
        and   stmax.cronop_stato_code!=STATO_AN
        and   cmax.data_cancellazione is null
        and   cmax.validita_fine is null
        and   rsmax.data_cancellazione is null
        and   rsmax.validita_fine is null
      )
      and   c1.data_cancellazione is null
	  and   c1.validita_fine is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;


    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Ultimo cronop aggiornato. numero='||codResult::varchar||'.';
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



    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop numero='||numeroCronop::varchar||'.';
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
   raise notice 'Programmmi inseriti in fase_bil_t_programmi=%',numeroProgr;
   raise notice 'CronoProgrammmi inseriti in fase_bil_t_cronop=%',numeroCronop;


   strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
   update fase_bil_t_elaborazione fase
   set fase_bil_elab_esito='IN-1',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' IN CORSO IN-1.POPOLA PROGRAMMI-CRONOP.'
   where fase.fase_bil_elab_id=faseBilElabId;


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

alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_pop_puntuale 
(
  integer,
  integer,
  integer,
  varchar,
  varchar,
  timestamp,
  out  integer,
  out  varchar
) owner to siac;


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean DEFAULT true, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
)
RETURNS record
AS $body$
			 
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
    -- Sofia SIAC-8633 24.05.2023      
    GP_FASE					    	 CONSTANT varchar:='GP';
   
	STATO_AN 			    	     CONSTANT varchar:='AN';

	-- 21.01.2022 Sofia Jira SIAC-8536
    FL_RIL_FPV_ATTR                  CONSTANT varchar:='FlagRilevanteFPV';
    FlagRilevanteFPVAttrId           integer:=NULL;

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


    codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null;

    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza programmi da creare in fase_bil_t_programmi.';
    select 1 into codResult
    from fase_bil_t_programmi fase
    where fase.fase_bil_elab_id=faseBilElabId
    and     fase.data_cancellazione is null;

    if codResult is null then
--      raise exception ' Nessun  programma da creare.';
      -- 10.09.2019 Sofia SIAC-7023
      codiceRisultato:=0;
      messaggioRisultato:=strMessaggio||' Nessun  programma da creare.';
      return;
    end if;


   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


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

 /*
   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
   else
   	bilancioElabId:=bilancioId;
   end if; Sofia SIAC-8633 24.05.2023      
   */
  
  --  Sofia SIAC-8633 24.05.2023      
   case 
    when tipoApertura=P_FASE THEN
	   	bilancioElabId:=bilancioPrecId;
    when tipoApertura=G_FASE THEN
	   	bilancioElabId:=bilancioId;
	when tipoApertura=GP_FASE THEN   
	   bilancioElabId:=bilancioId;
	   tipoApertura =P_FASE;
    end case;	  
  
  
   -- 30.07.2019 Sofia siac-6934
   strMessaggio:='Lettura identificativi attributi riaccertamento.';
   SELECT attr.attr_id
   INTO   flagDaRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='flagDaRiaccertamento'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   annoRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='annoRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   numeroRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='numeroRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

  
  	
   -- 21.01.2022 Sofia Jira SIAC-8536
   strMessaggio:='Lettura identificativo attributo FlagRilevanteFPV.';
   SELECT attr.attr_id
   INTO   FlagRilevanteFPVAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code =FL_RIL_FPV_ATTR
   AND    attr.ente_proprietario_id = enteproprietarioid;
  
   strMessaggio:='Inizio inserimento dati programmi da  fase_bil_t_programmi - inizio.';
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

  
  
   -- 16.05.2023 Sofia SIAC-8633 - inizio 
  --  gestione scarti per programma esistenti in bilancioId - devono essere riportati solo programmi non esistenti
  strMessaggio:='Gestione scarti programmi esistenti da creare in fase_bil_t_programmi.';
  codResult:=0;
  update  fase_bil_t_programmi fase
  set    fl_elab='X',
           scarto_code='001',
           scarto_desc ='PROGRAMMA ESISTENTE PER TIPO='||tipoApertura
  from siac_t_programma progr,
	        siac_t_programma progrNew,
            siac_d_programma_tipo tipo,
            siac_r_programma_stato rs,siac_d_programma_stato stato 
   where fase.fase_bil_elab_id=faseBilElabId
   and      fase.fl_elab='N'   
   and      progr.programma_id=fase.programma_id
   and      tipo.ente_proprietario_id=progr.ente_proprietario_id
   and      tipo.programma_tipo_code=tipoApertura
   and      progrNew.programma_tipo_id=tipo.programma_tipo_id 
   and      progrNew.programma_code =progr.programma_code 
   and      progrNew.bil_id=bilancioId 
   and      rs.programma_id=progrNew.programma_id 
   and      stato.programma_stato_id =rs.programma_stato_id 
   and      stato.programma_stato_code !='AN'
   and      progr.data_cancellazione  is null 
   and      progr.validita_fine  is null 
   and      fase.data_cancellazione is null
   and      progrNew.data_cancellazione  is null 
   and      progrNew.validita_fine  is null 
   and      rs.data_cancellazione  is null 
   and      rs.validita_fine  is null;
   GET DIAGNOSTICS codResult = ROW_COUNT;
   if codResult is null then codResult:=0; end if;
   raise notice '% Scartati=%', strMessaggio,codResult;
   
   strMessaggio:='Numero di programmi scartati per esistenza='||coalesce(codResult,0)::varchar||'.';
   raise notice '%', strMessaggio;
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
  
   /*codResult:=null;
   strMessaggio:='Verifica esistenza programmi da creare in fase_bil_t_programmi.';
   select 1 into codResult
   from fase_bil_t_programmi fase
   where fase.fase_bil_elab_id=faseBilElabId
   and      fase.fl_elab ='N'
    and     fase.data_cancellazione is null;

    if codResult is null then
--      raise exception ' Nessun  programma da creare.';
      codiceRisultato:=0;
      messaggioRisultato:=strMessaggio||' Nessun  programma da creare.';
      return;
    end if;*/
    -- 16.05.2023 Sofia SIAC-8633 - fine   

   -- siac_t_programma

   strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_t_programma].';
   insert into siac_t_programma
   (
   	 programma_code,
	 programma_desc,
     programma_tipo_id,
     bil_id,
     programma_data_gara_indizione,
	 programma_data_gara_aggiudicazione,
	 investimento_in_definizione,
     programma_responsabile_unico,
	 programma_spazi_finanziari,
     programma_affidamento_id,
     login_operazione,
     validita_inizio,
     ente_proprietario_id
   )
   select  progr.programma_code,
           progr.programma_desc,
           tipo.programma_tipo_id,
           bilancioId,
           progr.programma_data_gara_indizione,
		   progr.programma_data_gara_aggiudicazione,
	   	   progr.investimento_in_definizione,
	       progr.programma_responsabile_unico,
	   	   progr.programma_spazi_finanziari,
	       progr.programma_affidamento_id,
           loginOperazione||'@'||fase.fase_bil_programma_id::varchar,
           clock_timestamp(),
           progr.ente_proprietario_id
   from fase_bil_t_programmi fase,siac_t_programma progr,
        siac_d_programma_tipo tipo
   where fase.fase_bil_elab_id=faseBilElabId
   and   progr.programma_id=fase.programma_id
   and   fase.fl_elab='N'
   and   tipo.ente_proprietario_id=progr.ente_proprietario_id
   and   tipo.programma_tipo_code=tipoApertura
   and   fase.data_cancellazione is null;

   GET DIAGNOSTICS numeroProgr = ROW_COUNT;


   strMessaggio:='Numero di programmi inseriti='||coalesce(numeroProgr,0)::varchar||'.';
   raise notice '%', strMessaggio;
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

   -- inserimento dati programmi
   if coalesce(numeroProgr,0)!=0 then
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - aggiornamento fase_bil_t_programmi.';
    codResult:=null;
    update fase_bil_t_programmi fase
    set    programma_new_id=progr.programma_id,
             fl_elab='S'
    from   siac_t_programma progr
    where  fase.fase_bil_elab_id=faseBilElabId
    and    fase.fl_elab='N'
    and    progr.ente_proprietario_id=enteProprietarioId
    and    progr.bil_id=bilancioId -- 03.12.2021 Sofia SIAC-SIAC-8470
    and    progr.login_operazione like loginOperazione||'@%'
    and    substring(progr.login_operazione from position ('@' in progr.login_operazione)+1)::integer=fase.fase_bil_programma_id
    and    fase.data_cancellazione is null
    and    progr.data_cancellazione is null
    and    progr.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=coalesce(numeroProgr,0) then
     raise exception ' Il numero di aggiornamenti non corrisponde al numero di programmi inseriti.';
    end if;


    -- siac_r_programma_stato
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_stato].';
    codResult:=null;
    insert into siac_r_programma_stato
    (
   	 programma_id,
     programma_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rs.programma_stato_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_stato rs
    where fase.fase_bil_elab_id=faseBilElabId
    and   rs.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   fase.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=0 and coalesce(numeroProgr,0)=0 then
	   raise exception ' Il numero di stati inseriti non corrisponde al numero di programmi inseriti.';
    end if;
    raise notice '% numIns=%', strMessaggio,codResult;



    -- siac_r_programma_class
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_class].';
    codResult:=null;
    insert into siac_r_programma_class
    (
   	 programma_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rc.classif_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_class rc,siac_t_class c
    where fase.fase_bil_elab_id=faseBilElabId
    and   rc.programma_id=fase.programma_id
    and   c.classif_id=rc.classif_id
    and   fase.programma_new_id is not null
    and   c.data_cancellazione is null
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

 

    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_attr].';
    -- siac_r_programma_attr
    codResult:=null;
    insert into siac_r_programma_attr
    (
   	 programma_id,
     attr_id,
     boolean,
     testo,
     percentuale,
     numerico,
     tabella_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
   	       rattr.attr_id,
---   	       rattr.boolean     -- 21.01.2022 Sofia Jira SIAC-8563
   	       ( CASE WHEN tipoapertura=P_FASE AND rattr.attr_id=FlagRilevanteFPVAttrId THEN 'N'
   	         ELSE  rattr.boolean END 
   	       )  ,     -- 21.01.2022 Sofia Jira SIAC-8563
		   rattr.testo,
		   rattr.percentuale,
	       rattr.numerico,
	       rattr.tabella_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_attr rattr
    where fase.fase_bil_elab_id=faseBilElabId
    and   rattr.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

   
   
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_atto_amm].';
    -- siac_r_programma_atto_amm
    codResult:=null;
    insert into siac_r_programma_atto_amm
    (
     programma_id,
     attoamm_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
	       ratto.attoamm_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_atto_amm ratto
    where fase.fase_bil_elab_id=faseBilElabId
    and   ratto.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

   -- 19.04.2023 Sofia SIAC-TASK-21
   if tipoApertura=G_FASE then 
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_mutuo_programma].';
    -- siac_r_mutuo_programma
    codResult:=null;
    
   insert into siac_r_mutuo_programma
    (
     programma_id,
     mutuo_id,
     mutuo_programma_importo_iniziale,
     mutuo_programma_importo_finale,
     validita_inizio,
     login_operazione,
     login_creazione,
     login_modifica,
     ente_proprietario_id
    )
    select query.programma_id,
	            query.mutuo_id,
	            query.mutuo_programma_importo_iniziale ,
	            query.programma_importo,
	            clock_timestamp(),
                loginOperazione,
                loginOperazione,
                loginOperazione,
                enteProprietarioId
  from 
  (
    with 
    progrNew as 
    (
     select p.programma_id, p.programma_code ,coalesce(rattr.numerico ,0) programma_importo
     from fase_bil_t_programmi fase,
               siac_t_programma p 
                 left join siac_r_programma_attr rattr join siac_t_attr attr on (attr.attr_id=rattr.attr_id and   attr.attr_code='ValoreComplessivoProgramma')
                  on (rattr.programma_id=p.programma_id and rattr.data_cancellazione  is null and  rattr.validita_fine is null )
     where fase.fase_bil_elab_id=faseBilElabId
     and      p.programma_id =fase.programma_new_id
     and      fase.programma_new_id is not NULL
     and      fase.data_cancellazione is null
     and      p.data_cancellazione is null
     and      p.validita_fine is null
    ),
    progrMutuo as
    (
     select p.programma_code, r.mutuo_id, r.mutuo_programma_importo_iniziale 
     from siac_t_programma p , siac_d_programma_tipo tipo,  siac_r_programma_stato rs,siac_d_programma_stato statoP ,
               siac_r_mutuo_programma r,siac_t_mutuo mutuo,siac_d_mutuo_stato stato
    where tipo.ente_proprietario_id =enteProprietarioId 
    and      tipo.programma_tipo_code =G_FASE
    and      p.programma_tipo_id=tipo.programma_tipo_id 
    and      p.bil_id=bilancioPrecId
    and      rs.programma_id =p.programma_id 
    and      statoP.programma_stato_id =rs.programma_stato_id 
    and      statoP.programma_stato_code !='AN'
    and      r.programma_id=p.programma_id
    and      mutuo.mutuo_id=r.mutuo_id 
    and      stato.mutuo_stato_id=mutuo.mutuo_stato_id 
    and      stato.mutuo_stato_code!='A'
    and      r.data_cancellazione is null
    and      r.validita_fine is null
    and      mutuo.data_cancellazione is null
    and      mutuo.validita_fine is null
    and      p.data_cancellazione is null
    and      p.validita_fine is null
    and      rs.data_cancellazione is null
    and      rs.validita_fine is null
    )
	select progrNew.programma_id,
		        progrNew.programma_importo,
	            progrMutuo.mutuo_id,
	            progrMutuo.mutuo_programma_importo_iniziale
	from progrNew , progrMutuo 
	where progrNew.programma_code=progrMutuo.programma_code
  ) query;
  GET DIAGNOSTICS codResult = ROW_COUNT;
   raise notice '% numIns=%', strMessaggio,codResult;
  end if;   
 end if;


  strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - fine .';
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
  -- fine inserimento dati programmi
  
  -- 16.05.2023 Sofia SIAC-8633 - cronop 
 
   strMessaggio:='Inizio inserimento dati crono-programmi da  fase_bil_t_cronop - inizio.';
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
  
  strMessaggio:='Gestione scarti crono-programmi esistenti da creare in fase_bil_t_cronop.';
  codResult:=0;
  update  fase_bil_t_cronop fasec
  set    fl_elab='X',
           scarto_code='001',
           scarto_desc ='CRONOP ESISTENTE PER TIPO='||tipoApertura
 from siac_t_programma p, 
            siac_t_programma pNew, siac_d_programma_tipo tipo,siac_r_programma_stato rs,siac_d_programma_stato stato,
            siac_t_cronop cronop, 
            siac_t_cronop cNew,siac_r_cronop_stato  rs_cronop,siac_d_cronop_stato  stato_cronop 
  where fasec.fase_bil_elab_id=faseBilElabId
  and     fasec.fl_elab='N'
  and     p.programma_id =fasec.programma_id 
  and     cronop.cronop_id =fasec.cronop_id 
  and     cronop.programma_id =p.programma_id
  and     tipo.ente_proprietario_id =p.ente_proprietario_id 
  and     tipo.programma_tipo_code =tipoApertura
  and     pNew.programma_tipo_id=tipo.programma_tipo_id 
  and     pNew.programma_code =p.programma_code 
  and     pNew.bil_id=bilancioId
  and     rs.programma_id =pNew.programma_id 
  and     stato.programma_stato_id =rs.programma_stato_id 
  and     stato.programma_stato_code!='AN'
  and     cNew.programma_id=pNew.programma_id 
  and     cNew.cronop_code=cronop.cronop_code
  and     cNew.bil_id=pNew.bil_id
  and     rs_cronop.cronop_id=cNew.cronop_id 
  and     stato_cronop.cronop_stato_id =rs_cronop.cronop_stato_id 
  and     stato_cronop.cronop_stato_code !='AN'
  and     fasec.data_cancellazione is null
  and     cronop.data_cancellazione is null 
  and     cronop.validita_fine is null
  and     p.data_cancellazione is null 
  and     p.validita_fine is null
  and     pNew.data_cancellazione is null 
  and     pNew.validita_fine is null
  and     cNew.data_cancellazione is null 
  and     cNew.validita_fine is null
 and      rs.data_cancellazione is null 
 and      rs.validita_fine is null
 and      rs_cronop.data_cancellazione is null 
 and      rs_cronop.validita_fine is null;
 GET DIAGNOSTICS codResult = ROW_COUNT;
 if codResult is null then codResult:=0; end if;
 raise notice '% Scartati=%', strMessaggio,codResult;

  /*codResult:=null;
  select 1 into codResult
  from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec
  where fasep.fase_bil_elab_id=faseBilElabId
  and   fasep.programma_new_id is not null
  and   fasep.fl_elab='S'
  and   fasec.fase_bil_elab_id=faseBilElabId
  and   fasec.programma_id=fasep.programma_id
  and   fasec.fl_elab='N'
  and   fasep.data_cancellazione is null
  and   fasec.data_cancellazione is null;
  16.05.2023 Sofia SIAC-8633 - cronop */

  -- 16.05.2023 Sofia SIAC-8633 - cronop
  strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - verifica dati creare [fase_bil_t_cronop].';
  codResult:=0;
  select coalesce(count(*),0) into codResult
  from fase_bil_t_cronop fasec,siac_t_programma p, 
            siac_t_programma pNew, siac_d_programma_tipo tipo,siac_r_programma_stato rs,siac_d_programma_stato stato,
            siac_t_cronop cronop
  where fasec.fase_bil_elab_id=faseBilElabId
  and     fasec.fl_elab='N'
  and     p.programma_id =fasec.programma_id 
  and     cronop.cronop_id =fasec.cronop_id 
  and     cronop.programma_id =p.programma_id
  and     tipo.ente_proprietario_id =p.ente_proprietario_id 
  and     tipo.programma_tipo_code =tipoApertura
  and     pNew.programma_tipo_id=tipo.programma_tipo_id 
  and     pNew.programma_code =p.programma_code 
  and     pNew.bil_id=bilancioId
  and     rs.programma_id =pNew.programma_id 
  and     stato.programma_stato_id =rs.programma_stato_id 
  and     stato.programma_stato_code!='AN'
  and     not exists 
  (
   select 1 
   from   siac_t_cronop cNew,siac_r_cronop_stato  rs_cronop,siac_d_cronop_stato  stato_cronop
   where cNew.programma_id=pNew.programma_id 
   and      cNew.cronop_code=cronop.cronop_code
   and      cNew.bil_id=pNew.bil_id
   and      rs_cronop.cronop_id=cNew.cronop_id 
   and      stato_cronop.cronop_stato_id =rs_cronop.cronop_stato_id 
   and      stato_cronop.cronop_stato_code !='AN'
   and      cNew.data_cancellazione is null 
   and      cNew.validita_fine is null
   and       rs_cronop.data_cancellazione is null 
   and       rs_cronop.validita_fine is null
  )
  and     fasec.data_cancellazione is null
  and     cronop.data_cancellazione is null 
  and     cronop.validita_fine is null
  and     p.data_cancellazione is null 
  and     p.validita_fine is null
  and     pNew.data_cancellazione is null 
  and     pNew.validita_fine is null
  and      rs.data_cancellazione is null 
  and      rs.validita_fine is null;
  raise notice '% numdaIns=%', strMessaggio,codResult;


  if codResult is not null then

   	strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop da inserire numero='||codResult::varchar||'- inizio.';
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


    
    -- siac_t_cronop
   	/*-- 16.05.2023 Sofia SIAC-8633 - cronop
   	 * insert into siac_t_cronop
    (
    	 cronop_code,
	     cronop_desc,
	     programma_id,
	     bil_id,
	     usato_per_fpv,
         cronop_data_approvazione_fattibilita,
	     cronop_data_approvazione_programma_def,
		 cronop_data_approvazione_programma_esec,
		 cronop_data_avvio_procedura,
		 cronop_data_aggiudicazione_lavori,
		 cronop_data_inizio_lavori,
		 cronop_data_fine_lavori,
		 cronop_giorni_durata,
		 cronop_data_collaudo,
	     gestione_quadro_economico,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         cronop.cronop_code,
	     cronop.cronop_desc,
	     fasep.programma_new_id,
	     bilancioId,
--	     cronop.usato_per_fpv,      -- 04.10.2022 Sofia Jira SIAC-8816
   	       ( CASE WHEN tipoapertura=P_FASE  THEN false
   	         ELSE  cronop.usato_per_fpv END 
   	       )  ,     -- 04.10.2022 Sofia Jira SIAC-8816
         cronop.cronop_data_approvazione_fattibilita,
	     cronop.cronop_data_approvazione_programma_def,
		 cronop.cronop_data_approvazione_programma_esec,
		 cronop.cronop_data_avvio_procedura,
		 cronop.cronop_data_aggiudicazione_lavori,
		 cronop.cronop_data_inizio_lavori,
		 cronop.cronop_data_fine_lavori,
		 cronop.cronop_giorni_durata,
		 cronop.cronop_data_collaudo,
	     cronop.gestione_quadro_economico,
         clock_timestamp(),
         loginOperazione||'@'||fasec.fase_bil_cronop_id::varchar,
         cronop.ente_proprietario_id
    from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec,siac_t_cronop cronop
    where fasep.fase_bil_elab_id=faseBilElabId
    and   fasep.programma_new_id is not null
    and   fasep.fl_elab='S'
    and   fasec.fase_bil_elab_id=faseBilElabId
    and   fasec.programma_id=fasep.programma_id
    and   fasec.fl_elab='N'
    and   cronop.cronop_id=fasec.cronop_id
    and   fasep.data_cancellazione is null
    and   fasec.data_cancellazione is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;*/
   
    -- 16.05.2023 Sofia SIAC-8633 - cronop
    numeroCronop:=0;
    strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop].';
    
    insert into siac_t_cronop
    (
    	 cronop_code,
	     cronop_desc,
	     programma_id,
	     bil_id,
	     usato_per_fpv,
         cronop_data_approvazione_fattibilita,
	     cronop_data_approvazione_programma_def,
		 cronop_data_approvazione_programma_esec,
		 cronop_data_avvio_procedura,
		 cronop_data_aggiudicazione_lavori,
		 cronop_data_inizio_lavori,
		 cronop_data_fine_lavori,
		 cronop_giorni_durata,
		 cronop_data_collaudo,
	     gestione_quadro_economico,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         cronop.cronop_code,
	     cronop.cronop_desc,
	     pNew.programma_id,
	     bilancioId,
   	       ( CASE WHEN tipoapertura=P_FASE  THEN false
   	         ELSE  cronop.usato_per_fpv END 
   	       )  ,
         cronop.cronop_data_approvazione_fattibilita,
	     cronop.cronop_data_approvazione_programma_def,
		 cronop.cronop_data_approvazione_programma_esec,
		 cronop.cronop_data_avvio_procedura,
		 cronop.cronop_data_aggiudicazione_lavori,
		 cronop.cronop_data_inizio_lavori,
		 cronop.cronop_data_fine_lavori,
		 cronop.cronop_giorni_durata,
		 cronop.cronop_data_collaudo,
	     cronop.gestione_quadro_economico,
         clock_timestamp(),
         loginOperazione||'@'||fasec.fase_bil_cronop_id::varchar,
         cronop.ente_proprietario_id
    from fase_bil_t_cronop fasec,siac_t_programma p, 
              siac_t_programma pNew, siac_d_programma_tipo tipo,siac_r_programma_stato rs,siac_d_programma_stato stato,
              siac_t_cronop cronop 
    where fasec.fase_bil_elab_id=faseBilElabId
    and     fasec.fl_elab='N'
    and     p.programma_id =fasec.programma_id 
    and     cronop.cronop_id =fasec.cronop_id 
    and     cronop.programma_id =p.programma_id
    and     tipo.ente_proprietario_id =p.ente_proprietario_id 
    and     tipo.programma_tipo_code =tipoApertura
    and     pNew.programma_tipo_id=tipo.programma_tipo_id 
    and     pNew.programma_code =p.programma_code 
    and     pNew.bil_id=bilancioId
    and     rs.programma_id =pNew.programma_id 
    and     stato.programma_stato_id =rs.programma_stato_id 
    and     stato.programma_stato_code!='AN'
    and     not exists 
    (
    select 1 
    from   siac_t_cronop cNew,siac_r_cronop_stato  rs_cronop,siac_d_cronop_stato  stato_cronop
    where  cNew.programma_id=pNew.programma_id 
    and       cNew.cronop_code=cronop.cronop_code 
    and       cNew.bil_id=pNew.bil_id
    and       rs_cronop.cronop_id=cNew.cronop_id 
    and       stato_cronop.cronop_stato_id =rs_cronop.cronop_stato_id 
    and       stato_cronop.cronop_stato_code !='AN'
    and       cNew.data_cancellazione is null 
    and       cNew.validita_fine is null
    and       rs_cronop.data_cancellazione is null 
    and       rs_cronop.validita_fine is null
   )
   and     fasec.data_cancellazione is null
   and     cronop.data_cancellazione is null 
   and     cronop.validita_fine is null
   and     p.data_cancellazione is null 
   and     p.validita_fine is null
   and     pNew.data_cancellazione is null 
   and     pNew.validita_fine is null
   and     rs.data_cancellazione is null 
   and     rs.validita_fine is null;
   GET DIAGNOSTICS numeroCronop = ROW_COUNT;

  if coalesce(numeroCronop,0)!=0 then

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop inseriti numero='||coalesce(numeroCronop,0)::varchar||'.';
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

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  - aggiornamento fase_bil_t_cronop.';
     codResult:=null;
     update fase_bil_t_cronop fase
     set    cronop_new_id=cronop.cronop_id,
               fl_elab='S'
     from   siac_t_cronop cronop
     where  fase.fase_bil_elab_id=faseBilElabId
     and       fase.fl_elab='N'
     and    cronop.ente_proprietario_id=enteProprietarioId
     and    cronop.bil_id=bilancioId -- 03.12.2021 Sofia SIAC-8879
     and    cronop.login_operazione like loginOperazione||'@%'
     and    substring(cronop.login_operazione from position ('@' in cronop.login_operazione)+1)::integer=fase.fase_bil_cronop_id
     and    fase.data_cancellazione is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
	      raise exception ' Il numero di aggiornamenti non corrisponde al numero di crono-programmi inseriti.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_stato].';
     -- siac_r_cronop_stato
     codResult:=null;
     insert into siac_r_cronop_stato
     (
    	cronop_id,
        cronop_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            rs.cronop_stato_id,
            clock_timestamp(),
            loginOperazione,
            rs.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_stato rs
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rs.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;


     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_atto_amm].';
     -- siac_r_cronop_atto_amm
     codResult:=null;
     insert into siac_r_cronop_atto_amm
     (
    	cronop_id,
        attoamm_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            ratto.attoamm_id,
            clock_timestamp(),
            loginOperazione,
            ratto.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_atto_amm ratto
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    ratto.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    ratto.data_cancellazione is null
     and    ratto.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
/*     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;*/

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_attr].';

     -- siac_r_cronop_attr
     codResult:=null;
     insert into siac_r_cronop_attr
     (
    	cronop_id,
		attr_id,
	    boolean,
	    testo,
    	percentuale,
	    numerico,
    	tabella_id,
	    validita_inizio,
    	login_operazione,
	    ente_proprietario_id
     )
     select
        fase.cronop_new_id,
        rattr.attr_id,
	    rattr.boolean,
    	rattr.testo,
	    rattr.percentuale,
	    rattr.numerico,
    	rattr.tabella_id,
	    clock_timestamp(),
    	loginOperazione,
	    rattr.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_attr rattr
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rattr.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rattr.data_cancellazione is null
     and    rattr.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem].';
	 codResult:=null;
     -- siac_t_cronop_elem
     insert into siac_t_cronop_elem
     (
	    cronop_elem_code,
	    cronop_elem_code2,
	    cronop_elem_code3,
	    cronop_elem_desc,
	    cronop_elem_desc2,
	    cronop_id,
--	    cronop_elem_id_padre,
        cronop_elem_is_ava_amm,
	    elem_tipo_id,
	    ordine,
	    livello,
   	    login_operazione,
	    validita_inizio,
	    ente_proprietario_id
     )
     select
        celem.cronop_elem_code,
	    celem.cronop_elem_code2,
	    celem.cronop_elem_code3,
	    celem.cronop_elem_desc,
	    celem.cronop_elem_desc2,
        fase.cronop_new_id,
--        cronop_elem_id_padre,
	    celem.cronop_elem_is_ava_amm,
        tiponew.elem_tipo_id,
        celem.ordine,
	    celem.livello,
        loginOperazione||'@'||celem.cronop_elem_id::varchar,
        clock_timestamp(),
        celem.ente_proprietario_id
 	 from fase_bil_t_cronop fase,siac_t_cronop_elem celem,
          siac_d_bil_elem_tipo tipo, siac_d_bil_elem_tipo tiponew
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_id
     and    tipo.elem_tipo_id=celem.elem_tipo_id
     and    tiponew.ente_proprietario_id=tipo.ente_proprietario_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;






     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_class].';
	 codResult:=null;
	 -- siac_r_cronop_elem_class
     insert into siac_r_cronop_elem_class
     (
  	  	cronop_elem_id,
	    classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            c.classif_id,
            clock_timestamp(),
            loginOperazione,
            c.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_class r,siac_t_class c
	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    c.classif_id=r.classif_id
     and    c.data_cancellazione is null
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_bil_elem].';
	 codResult:=null;
     -- siac_r_cronop_elem_bil_elem
     insert into siac_r_cronop_elem_bil_elem
     (
	    cronop_elem_id,
	    elem_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            enew.elem_id,
            clock_timestamp(),
            loginOperazione,
            enew.ente_proprietario_id
     from  fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_bil_elem r,
           siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
           siac_t_bil_elem enew,siac_d_bil_elem_tipo tiponew,
           siac_r_bil_elem_stato rs,siac_d_bil_elem_Stato stato
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    e.elem_id=r.elem_id
     and    tipo.elem_tipo_id=e.elem_tipo_id
     and    enew.bil_id=bilancioId
     and    enew.elem_code=e.elem_code
     and    enew.elem_code2=e.elem_code2
     and    enew.elem_code3=e.elem_code3
     and    tiponew.elem_tipo_id=enew.elem_tipo_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    rs.elem_id=enew.elem_id
     and    stato.elem_stato_id=rs.elem_stato_id
     and    stato.elem_stato_code!='AN'
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    e.data_cancellazione is null
     and    enew.data_cancellazione is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem_det].';
     codResult:=null;
     -- siac_t_cronop_elem_det
     insert into siac_t_cronop_elem_det
     (
	    cronop_elem_det_desc,
	    cronop_elem_id,
	    cronop_elem_det_importo,
	    elem_det_tipo_id,
	    periodo_id,
	    anno_entrata,
        quadro_economico_id_padre,
	    quadro_economico_id_figlio,
	    quadro_economico_det_importo,
        login_operazione,
        validita_inizio,
        ente_proprietario_id
     )
     select
         det.cronop_elem_det_desc,
	     celem.cronop_elem_id,
	     det.cronop_elem_det_importo,
	     det.elem_det_tipo_id,
	     det.periodo_id,
	     det.anno_entrata,
         det.quadro_economico_id_padre,
	     det.quadro_economico_id_figlio,
	     det.quadro_economico_det_importo,
         loginOperazione,
         clock_timestamp(),
         det.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem, siac_t_cronop_elem_det det
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    det.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    det.data_cancellazione is null
     and    det.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;
   end if;
  
   strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - fine.';
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

 --- inserimento collegamenti tra programma e siac_t_movgest_Ts [siac_r_movgest_ts_programma]
 --- inserimento collegamenti tra cronop    e siac_t_movgest_ts [siac_r_movgest_ts_cronop_elem]
 --  inserimento da effettuare solo per tipoApertura='G'
 --  quindi partendo da movimenti validi e programmi - cronop nuovi, riportare le relazioni da annoBilancioPrec
 --  convertendo gli id da annoPrec a annoBilancio
 -- 06.05.2019 Sofia siac-6255
-- if tipoApertura=G_FASE then -- tutto da rivedere
-- 06.02.2020 Sofia jira SIAC-7386 aggiunto par. non aggiornare tutti i collegamenti in caso di esecuzione da puntuale
-- 16.05.2023 Sofia SIAC-8633 - aggiungere controlli su inesistenza dei legami 
 if tipoApertura=G_FASE and ribalta_coll_mov=true then

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
              mov_res_anno_prec, 
              progr progr_anno, 
              progr progr_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and      mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and      mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and      mov_res_anno.movgest_tipo_id=mov_res_anno_prec.movgest_tipo_id
    and      progr_anno_prec.programma_id=mov_res_anno_prec.programma_id
    and      progr_anno.bil_id=bilancioId
    and      progr_anno.programma_code=progr_anno_prec.programma_code
    and      not exists  -- 17.05.2023 Sofia SIAC-8633
     (
      select 1 from siac_r_movgest_ts_programma  rp 
      where rp.movgest_ts_id =mov_res_anno.movgest_ts_id 
      and      rp.programma_id=progr_anno.programma_id 
      and      rp.data_cancellazione  is null  
      and      rp.validita_fine is null 
     )
    ) query,fase_bil_t_programmi fase -- 29.05.2023 Sofia SIAC-8633 ribaltamento dei movimenti solo per i programmi effettivamente creati
    where     -- 29.05.2023 Sofia SIAC-8633
                fase.fase_bil_elab_id=faseBilElabId
    and     fase.programma_new_id=query.programma_new_id
    and     fase.programma_new_id is not NULL
    and     fase.data_cancellazione is null
    -- 29.05.2023 Sofia SIAC-8633
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
    and     mov.movgest_anno::integer>=annoBilancio
    and     ts.movgest_id=mov.movgest_id
    and     r.movgest_ts_id=ts.movgest_ts_id
    and     rs.movgest_ts_id=ts.movgest_ts_id
    and     stato.movgest_stato_id=rs.movgest_stato_id
    and     stato.movgest_stato_code!='A'
    and     tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and     mov.data_cancellazione is null
    and     mov.validita_fine is null
    and     ts.data_cancellazione is null
    and     ts.validita_fine is null
    and     rs.data_cancellazione is null
    and     rs.validita_fine is null
    and     r.data_cancellazione is null
    and     r.validita_fine is null
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
    and     mov_pluri_anno.movgest_numero=mov_pluri_anno_prec.movgest_numero
    and     mov_pluri_anno.movgest_subnumero=mov_pluri_anno_prec.movgest_subnumero
    and     mov_pluri_anno.movgest_tipo_id=mov_pluri_anno_prec.movgest_tipo_id
    and     progr_anno_prec.programma_id=mov_pluri_anno_prec.programma_id
    and     progr_anno.bil_id=bilancioId
    and     progr_anno.programma_code=progr_anno_prec.programma_code
    and      not exists  -- 17.05.2023 Sofia SIAC-8633
    (
     select 1 from siac_r_movgest_ts_programma  rp 
     where rp.movgest_ts_id =mov_pluri_anno.movgest_ts_id 
     and     rp.programma_id=progr_anno.programma_id 
     and     rp.data_cancellazione  is null  
     and     rp.validita_fine is null 
    )
    ) query,fase_bil_t_programmi fase -- 29.05.2023 Sofia SIAC-8633 ribaltamento dei movimenti solo per i programmi effettivamente creati
    where 
     -- 29.05.2023 Sofia SIAC-8633
                 fase.fase_bil_elab_id=faseBilElabId
    and     fase.programma_new_id=query.programma_new_id
    and     fase.programma_new_id is not NULL
    and     fase.data_cancellazione is null
     -- 29.05.2023 Sofia SIAC-8633
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
    from   mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and     mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
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
    and      mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and      mov_riacc_anno.movgest_tipo_id=mov_riacc_anno_prec.movgest_tipo_id
    and      progr_anno_prec.programma_id=mov_riacc_anno_prec.programma_id
    and      progr_anno.bil_id=bilancioId
    and      progr_anno.programma_code=progr_anno_prec.programma_code
    and      not exists  -- 17.05.2023 Sofia SIAC-8633
    (
     select 1 from siac_r_movgest_ts_programma  rp 
     where rp.movgest_ts_id =mov_riacc_anno.movgest_ts_id 
     and     rp.programma_id=progr_anno.programma_id 
     and     rp.data_cancellazione  is null  
     and     rp.validita_fine is null 
    )
    ) query,fase_bil_t_programmi fase -- 29.05.2023 Sofia SIAC-8633 ribaltamento dei movimenti solo per i programmi effettivamente creati
        -- 29.05.2023 Sofia SIAC-8633
   where  fase.fase_bil_elab_id=faseBilElabId
    and     fase.programma_new_id=query.programma_new_id
    and     fase.programma_new_id is not NULL
    and     fase.data_cancellazione is null
     -- 29.05.2023 Sofia SIAC-8633

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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer<annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer<annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
                  cronop.cronop_code,
                  prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
               siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'
     and      pstato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
                mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno, cronop cronop_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and     mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and     mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and     cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and     cronop_anno.bil_id=bilancioId
    and     cronop_anno.programma_code=cronop_anno_prec.programma_code
    and     cronop_anno.cronop_code=cronop_anno_prec.cronop_code
    and     not exists  -- 17.05.2023 Sofia SIAC-8633
    (
    select 1 
    from siac_r_movgest_ts_cronop_elem rc
    where rc.cronop_id=cronop_anno.cronop_id 
    and      rc.movgest_ts_id=mov_res_anno.movgest_ts_id 
    and      rc.data_cancellazione is null 
    and      rc.validita_fine is null 
    )
   ) query,fase_bil_t_cronop fase -- 29.05.2023 Sofia SIAC-8633
   where    -- 29.05.2023 Sofia SIAC-8633
                fase.fase_bil_elab_id=faseBilElabId
    and     fase.fl_elab='S'
    and     fase.cronop_new_id is not null
    and     fase.cronop_new_id=query.cronop_new_id
    and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer>=annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code!='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer>=annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code !='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
                  cronop.cronop_code,
                  prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
                siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'   -- 06.08.2019 Sofia siac-6934
     and      pstato.programma_stato_code!='AN'   -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
               mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and     mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and     mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and     cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and     cronop_anno.bil_id=bilancioId
    and     cronop_anno.programma_code=cronop_anno_prec.programma_code
    and     cronop_anno.cronop_code=cronop_anno_prec.cronop_code
    and     not exists  -- 17.05.2023 Sofia SIAC-8633
    (
    select 1 
    from siac_r_movgest_ts_cronop_elem rc
    where rc.cronop_id=cronop_anno.cronop_id 
    and      rc.movgest_ts_id=mov_res_anno.movgest_ts_id 
    and      rc.data_cancellazione is null 
    and      rc.validita_fine is null 
    )
   ) query, fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
   where     -- 29.05.2023 Sofia SIAC-8633
                fase.fase_bil_elab_id=faseBilElabId
    and     fase.fl_elab='S'
    and     fase.cronop_new_id is not null
    and     fase.cronop_new_id=query.cronop_new_id
    and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633

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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code!='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      tipo.movgest_ts_tipo_code='T'
      and      rattr.movgest_ts_id=ts.movgest_ts_id
      and      rattr.attr_id=flagDaRiaccAttrId
      and      rattr.boolean='S'
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
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
    and     mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code !='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
                  cronop.cronop_code,
                  prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
                siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and       tipo.programma_tipo_code=G_FASE
     and       prog.programma_tipo_id=tipo.programma_tipo_id
     and       cronop.programma_id=prog.programma_id
     and       rs.cronop_id=cronop.cronop_id
     and       stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and       stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and       rsp.programma_id=prog.programma_id
     and       pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and       pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and       rs.data_cancellazione is null
     and       rs.validita_fine is null
     and       rsp.data_cancellazione is null
     and       rsp.validita_fine is null
     and       prog.data_cancellazione is null
     and       prog.validita_fine is null
     and       cronop.data_cancellazione is null
     and       cronop.validita_fine is null
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
   ) query,  fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
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
   -- 29.05.2023 Sofia SIAC-8633
    and     fase.fase_bil_elab_id=faseBilElabId
    and     fase.fl_elab='S'
    and     fase.cronop_new_id is not null
    and     fase.cronop_new_id=query.cronop_new_id
    and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer<annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer<annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is not null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
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
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      celem.cronop_id=cronop.cronop_id
     and      det.cronop_elem_id=celem.cronop_elem_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and      pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
     and      celem.data_cancellazione is null
     and      celem.validita_fine is null
     and      det.data_cancellazione is null
     and      det.validita_fine is null
    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
                cronop_elem_anno.cronop_id cronop_new_id,
                mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and     mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and     mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and     cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and     cronop_elem_anno.bil_id=bilancioId
    and     cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and     cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and     cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and     cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and     cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and     cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and     cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and     cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and     cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and     cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and     cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and     cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and     cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
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
    and not exists -- 17.05.2023 Sofia SIAC-8633
    (
	 select 1 
	 from siac_r_movgest_ts_cronop_elem r
  	 where r.movgest_ts_id=mov_res_anno.movgest_ts_id
  	 and     r.cronop_id=cronop_elem_anno.cronop_id
  	 and     r.cronop_elem_id=cronop_elem_anno.cronop_elem_id
  	 and     r.data_cancellazione is null 
  	 and     r.validita_fine is null
    )
   ) query,   fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
   where   -- 29.05.2023 Sofia SIAC-8633
               fase.fase_bil_elab_id=faseBilElabId
   and     fase.fl_elab='S'
   and     fase.cronop_new_id is not null
   and     fase.cronop_new_id=query.cronop_new_id
   and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer>=annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code!='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer>=annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is not null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code!='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
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
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      celem.cronop_id=cronop.cronop_id
     and      det.cronop_elem_id=celem.cronop_elem_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and      pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
     and      celem.data_cancellazione is null
     and      celem.validita_fine is null
     and      det.data_cancellazione is null
     and      det.validita_fine is null
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
    and not exists -- 17.05.2023 Sofia SIAC-8633
    (
	 select 1 
	 from siac_r_movgest_ts_cronop_elem r
  	 where r.movgest_ts_id=mov_res_anno.movgest_ts_id
  	 and     r.cronop_id=cronop_elem_anno.cronop_id
  	 and     r.cronop_elem_id=cronop_elem_anno.cronop_elem_id
  	 and     r.data_cancellazione is null 
  	 and     r.validita_fine is null
    )
   ) query,  fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
   where 
    -- 29.05.2023 Sofia SIAC-8633
                fase.fase_bil_elab_id=faseBilElabId
    and     fase.fl_elab='S'
    and     fase.cronop_new_id is not null
    and     fase.cronop_new_id=query.cronop_new_id
    and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633
   
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      tipo.movgest_ts_tipo_code='T'
      and      rattr.movgest_ts_id=ts.movgest_ts_id
      and      rattr.attr_id=flagDaRiaccAttrId
      and      rattr.boolean='S'
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      rattr.data_cancellazione is null
      and      rattr.validita_fine is null
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
     from   mov_anno, annoRiacc, numeroRiacc
     where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
     and     mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
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
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is not null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
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
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      celem.cronop_id=cronop.cronop_id
     and      det.cronop_elem_id=celem.cronop_elem_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
---     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and      pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
     and      celem.data_cancellazione is null
     and      celem.validita_fine is null
     and      det.data_cancellazione is null
     and      det.validita_fine is null
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
   ) query,  fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
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
   -- 29.05.2023 Sofia SIAC-8633
  and     fase.fase_bil_elab_id=faseBilElabId
  and     fase.fl_elab='S'
  and     fase.cronop_new_id is not null
  and     fase.cronop_new_id=query.cronop_elem_new_id
  and     fase.data_cancellazione  is null 
   -- 29.05.2023 Sofia SIAC-8633
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


 if coalesce(codiceRisultato,0)=0 then
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

alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
integer, 
integer, 
integer, 
varchar, 
varchar, 
timestamp without time zone, 
boolean, 
OUT integer, 
OUT  varchar
) owner to siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  ribalta_coll_mov boolean DEFAULT false, -- 17.05.2023 Sofia SIAC-8633
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
   strMessaggio       			VARCHAR(1500)	:='';
   strMessaggiofinale 			VARCHAR(1500)	:='';
   codResult              		INTEGER  		:=NULL;
   dataInizioVal 				timestamp		:=NULL;
   faseBilElabId 		        integer:=null;
   bilancioId                   integer:=null;
   periodoId                    integer:=null;

   faseOp                       varchar(50):=null;
   strRec record;

   APE_GEST_PROGRAMMI    	    CONSTANT varchar:='APE_GEST_PROGRAMMI';
   P_FASE						CONSTANT varchar:='P';
   G_FASE					    CONSTANT varchar:='G';
   -- 25.05.2023 Sofia Jira SIAC-8633
   E_FASE					    CONSTANT varchar:='E';
  BEGIN

   messaggioRisultato:='';
   codicerisultato:=0;
   faseBilElabIdRet:=0;
   dataInizioVal:= clock_timestamp();

   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'.';

   strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PROGRAMMI||' IN CORSO.';
   select 1 into codResult
   from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
   and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
   and   fase.fase_bil_elab_esito like 'IN%'
   and   fase.data_cancellazione is null
   and   fase.validita_fine is null
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null;
   if codResult is not null then
   	raise exception ' Esistenza fase in corso.';
   end if;


    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;

	 strMessaggio:='Inserimento LOG.';
 	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


	 strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
--     if faseOp is null or faseOp not in (P_FASE,G_FASE) then 25.05.2023 Sofia Jira SIAC-8633
     -- 25.05.2023 Sofia Jira SIAC-8633
     if faseOp is null or faseOp not in (P_FASE,G_FASE,E_FASE) then
      	raise exception ' Il bilancio deve essere in fase % o % o %.',P_FASE,G_FASE,E_FASE;
     end if;

     strMessaggio:='Verifica coerenza tipo di apertura programmi-fase di bilancio di corrente.';
    --	 if tipoApertura!=faseOp then  25.05.2023 Sofia Jira SIAC-8633
    -- 25.05.2023 Sofia Jira SIAC-8633
	 if ( ( tipoApertura=P_FASE and tipoApertura!=faseOp ) or (tipoApertura=G_FASE and faseOp not in (G_FASE,E_FASE)) ) then 
     	raise exception ' Tipo di apertura % non consentita in fase di bilancio %.', tipoApertura,faseOp;
     end if;

 	 strMessaggio:='Inizio Popola programmi-cronop da elaborare.';
     select * into strRec
     from fnc_fasi_bil_gest_apertura_programmi_popola
     (
      faseBilElabId,
      enteproprietarioid,
      annobilancio,
      tipoApertura,
      loginoperazione,
	  dataelaborazione
     );
     if strRec.codiceRisultato!=0 then
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
     end if;

     if codiceRisultato=0 then
	     strMessaggio:='Inizio Elabora programmi-cronop.';
    	 select * into strRec
	     from fnc_fasi_bil_gest_apertura_programmi_elabora
    	 (
	      faseBilElabId,
    	  enteproprietarioid,
	      annobilancio,
          tipoApertura,
          loginoperazione,
          dataelaborazione,
          ribalta_coll_mov -- 17.05.2023 Sofia SIAC-8633          
         );
         if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;

     end if;


     if codiceRisultato=0 and faseBilElabId is not null then
	   strMessaggio:=' Chiusura fase_bil_t_elaborazione OK.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||'TERMINATA CON SUCCESSO.'
       where fase_bil_elab_id=faseBilElabId;

       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggioFinale||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

	 else
      if codiceRisultato!=0 and faseBilElabId is not null then
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||'TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      end if;

     end if;
     
	 if  codiceRisultato=0 then
	  	 messaggioRisultato := strMessaggioFinale||' Operazione terminata correttamente';
	  	fasebilelabidret:=coalesce(faseBilElabId,0);
	 else
  	  	 messaggioRisultato := strMessaggioFinale||strMessaggio;
     end if;

	 RETURN;
EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi
(
integer, 
integer, 
varchar, 
varchar, 
timestamp without time zone, 
boolean, 
OUT integer,
OUT integer, 
OUT  varchar
) owner to siac;


DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar, 
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
   strMessaggio       			VARCHAR(1500)	:='';
   strMessaggioErr       			VARCHAR(1500)	:='';
   strMessaggiofinale 			VARCHAR(1500)	:='';
   codResult              		INTEGER  		:=NULL;
   dataInizioVal 				timestamp		:=NULL;
   faseBilElabId 		        integer:=null;
   faseBilElabPGId          integer:=null;
   faseBilElabGPId          integer:=null;
   bilancioId                   integer:=null;
   periodoId                    integer:=null;
   tipoOperazioni varchar(50):=null;
  
   faseOp                       varchar(50):=null;
   strRec record;

   APE_GEST_PROGRAMMI    	    CONSTANT varchar:='APE_GEST_ALL_PROGRAMMI';
   P_FASE						CONSTANT varchar:='P';
   E_FASE					    CONSTANT varchar:='E';
   
  BEGIN

   messaggioRisultato:='';
   codicerisultato:=0;
   faseBilElabIdRet:=0;
   dataInizioVal:= clock_timestamp();

   strmessaggiofinale:='Allineamento '||coalesce(tipoAllineamento,' ')||' Programmi-Cronoprogrammi per annoBilancio='||annoBilancio::varchar||'.';
   raise notice '%',strmessaggiofinale;
   strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PROGRAMMI||' IN CORSO.';
   select 1 into codResult
   from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
   and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
   and   fase.fase_bil_elab_esito like 'IN%'
   and   fase.data_cancellazione is null
   and   fase.validita_fine is null
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null;
   if codResult is not null then
   	raise exception ' Esistenza fase in corso.';
   end if;

   -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
   -- da g anno     a  p anno GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti 
   -- da p anno     a g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
   --     'gp|GP|PG'
   strMessaggio:='Verifica tipo allineamenti da eseguire per  '||APE_GEST_PROGRAMMI||'.';
   select tipo.fase_bil_elab_tipo_param  into tipoOperazioni
   from fase_bil_d_elaborazione_tipo  tipo 
   where tipo.ente_proprietario_id =enteProprietarioId 
   and      tipo.fase_bil_elab_tipo_code =APE_GEST_PROGRAMMI
   and      tipo.data_cancellazione  is null 
   and      tipo.validita_fine is null;
   if tipoOperazioni is null then 
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Nessun tipo di allineamento predisposto in esecuzione.';
	   return;
   end if;


    
    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 P ANNO IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;

	 strMessaggio:='Inserimento LOG.';
 	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


	 strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null or faseOp not in (P_FASE,E_FASE) then
      	raise notice ' Il bilancio deve essere in fase % o %.',P_FASE,E_FASE;
	--	strMessaggio:='Allineamento Programmi-Cronoprogrammi gp -  da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	    strMessaggio:=strMessaggio||' Il bilancio deve essere in fase '||P_FASE||' o '||E_FASE||'. Chiusura fase_bil_t_elaborazione KO.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Fase di bilancio non ammessa.';
	   return;
     end if;
    
    -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%gp%' then 
	 -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
     strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
     if tipoOperazioni like '%gp%'  then
      raise notice '%',strmessaggio;
      strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.';
 	
	  select * into strRec
      from fnc_fasi_bil_gest_apertura_programmi_popola
      (
       faseBilElabId,
       enteproprietarioid,
       annobilancio,
       'P',
       loginoperazione,
	   dataelaborazione
      );
      if strRec.codiceRisultato!=0 then
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
      end if;
     
      if codiceRisultato = 0 then
          strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
          strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	 select * into strRec
	     from fnc_fasi_bil_gest_apertura_programmi_elabora
    	 (
	      faseBilElabId,
    	  enteproprietarioid,
	      annobilancio,
          'P',
          loginoperazione,
          dataelaborazione,
          false -- no colleg. movimenti
         );
         if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
         end if;
      end if;
     end if;
    
      if codiceRisultato=0 and faseBilElabId is not null then
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 a P ANNO TERMINATA CON SUCCESSO.'
       where fase_bil_elab_id=faseBilElabId;

       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

	 else
      if codiceRisultato!=0 and faseBilElabId is not null then
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      end if;

     end if;
    end if;
   
     -- da g anno   a  p anno GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti
     -- da modificare fnc interne tutto nello stesso annoBilancio
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%GP%'  and
        tipoOperazioni like '%GP%' and codiceRisultato=0 and faseOp=E_FASE  then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';

       insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO A P ANNO IN CORSO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabGPId;

    
        if faseBilElabGPId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabGPId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.'; 
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabGPId,
           enteproprietarioid,
           annobilancio,
           'GP',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
       
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabGPId,
    	    enteproprietarioid,
	        annobilancio,
            'GP',
            loginoperazione,
            dataelaborazione,
            false -- no colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if; 
      end if;
     end if;
    
     if faseBilElabGPId is not null then
      strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
      if codiceRisultato=0 then 
     	   strMessaggio:=strMessaggio||'  Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabGPId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO a P ANNO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabGPId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabGPId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabGPId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;
	
    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabGPId;
      end if;
     end if;
    
    -- da p anno     a g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%PG%' and
        tipoOperazioni like '%PG%'  and codiceRisultato=0 and faseOp=E_FASE then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';
       
        insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO A G ANNO IN CORSO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabPGId;
        
        if faseBilElabPGId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabPGId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.';
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabPGId,
           enteproprietarioid,
           annobilancio,
           'G',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabPGId,
    	    enteproprietarioid,
	        annobilancio,
            'G',
            loginoperazione,
            dataelaborazione,
            true -- si colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if;
       end if; 
     end if;
    
 	 
     if faseBilElabPGId is not null then
     strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
     if codiceRisultato=0 then 
           
     	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabPGId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO a G ANNO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabPGId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabPGId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabPGId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;

    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO A G ANNO TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabPGId;
      end if;
    end if;

 
	 if  codiceRisultato=0 then
	  	 messaggioRisultato := strMessaggioFinale||' Operazione terminata correttamente';
	  	 if faseBilElabId is not null then 
 	  	 	faseBilElabIdRet:=faseBilElabId;
 	  	 else 
 	  	    if faseBilElabPGId is not null then 
   	   	     faseBilElabIdRet:=faseBilElabPGId;
   	   	    else 
   	   	     if faseBilElabGPId is not null then 
   	   	      faseBilElabIdRet:=faseBilElabGPId;
   	   	     end if;
   	   	    end if; 
   	   	 end if; 
	 else
  	  	 messaggioRisultato := strMessaggioFinale||strMessaggio||strMessaggioErr;
     end if;

	 RETURN;
EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter FUNCTION siac.fnc_fasi_bil_gest_allinea_programmi
(
integer, 
integer, 
varchar,
varchar, 
timestamp without time zone, 
OUT integer,
OUT integer, 
OUT  varchar
) owner to siac;


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    faseBilElabId     integer:=null;

    strRec record;

    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';

    U_STR               CONSTANT varchar:='U';
    E_STR               CONSTANT varchar:='E';


BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Fase Bilancio di apertura='||faseBilancio||'.';

    if not (stepPartenza=99 or stepPartenza>=1) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=1 99.';
        codiceRisultato:=-1;
    end if;

    -- STEP 1 - capitoli di uscita eseguiro per stepPartenza 1, 99
    if stepPartenza=1 or stepPartenza=99 then
 	 strMessaggio:='Capitolo di uscita.';
     select * into strRec
     from fnc_fasi_bil_gest_apertura
     (annobilancio,
      U_STR,
      CAP_UP_STR,
      CAP_UG_STR,
      faseBilancio,
      checkGest,
      impostaImporti,
      enteProprietarioId,
      loginOperazione,
      dataElaborazione
     );
     if strRec.codiceRisultato=0 then
      	faseBilElabId:=strRec.faseBilElabIdRet;
     else
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
     end if;
   end if;

   -- STEP 2 - capitoli di entrata eseguiro per stepPartenza >=2
   if codiceRisultato=0 and stepPartenza>=2 then
    	strMessaggio:='Capitolo di entrata.';
    	select * into strRec
	    from fnc_fasi_bil_gest_apertura
    	(annobilancio,
	     E_STR,
    	 CAP_EP_STR,
	     CAP_EG_STR,
	     faseBilancio,
	     checkGest,
     	 impostaImporti,
	     enteProprietarioId,
    	 loginOperazione,
	     dataElaborazione
    	);
        if strRec.codiceRisultato=0 then
      		faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else
    	messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;


    -- STEP 3 -- popolamento dei vincoli di gestione
    if codiceRisultato=0 and stepPartenza>=2 then
		strMessaggio:='Ribaltamento vincoli.';
    	if faseBilancio = 'E' then
	    	select * into strRec from fnc_fasi_bil_gest_ribaltamento_vincoli ('GEST-GEST',annobilancio,enteproprietarioid,loginoperazione, dataelaborazione );
		else
			select * into strRec from fnc_fasi_bil_gest_ribaltamento_vincoli ('PREV-GEST',annobilancio,enteproprietarioid,loginoperazione, dataelaborazione );
		end if;

	    if strRec.codiceRisultato=0 then
            faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;


    end if;

    -- STEP 4 -- popolamento dei programmi-cronop di gestione
    if codiceRisultato=0 and stepPartenza>=2 then
--    	if faseBilancio = 'G' then -- 17.05.2023 Sofia SIAC-8633 ribaltamento dei progetti-cronop sia in esercizio provvisorio che in gestione def
                                                  -- sempre da previsione corrente riportando sempre solo progetti non esistenti in gestione con relativi cronop
                                                  -- e cronop non esistenti di progetti anche esistenti
            strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di gestione da previsione corrente.';
        	select * into strRec
        	from fnc_fasi_bil_gest_apertura_programmi
	             (
				  annoBilancio,
				  enteProprietarioId,
				  'G',
				  loginOperazione,
				  dataElaborazione
                 );
            if  strRec.codiceRisultato!=0 then
            	strMessaggio:=strRec.messaggioRisultato;
        		codiceRisultato:=strRec.codiceRisultato;
            end if;
--        end if;
    end if;

   -- 08.04.2022 Sofia SIAC-8017
    -- STEP 6 -- popolamento dei programmi-cronoprogrammi di previsione
	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
    	strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di previsione da gestione precedente.';
       	select * into strRec
       	from fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
		(
	     enteProprietarioId,
	     annoBilancio,   -- iniziale
	     annoBilancio-1, -- finale
	     loginOperazione,
	     dataelaborazione
	    );
--       if strRec.codiceRisultato!=0 then
--       	strMessaggio:=strRec.messaggioRisultato;
  --      codiceRisultato:=strRec.codiceRisultato;
    --   end if;
    end if;
    -- 08.04.2022 Sofia SIAC-8017
   
    if codiceRisultato=0 then
	   	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
	    faseBilElabIdRet:=faseBilElabId;
	else
	  	messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

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

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_all
(
  integer,
  varchar,
  integer,
  boolean,
  boolean,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER TO siac;


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_prev_approva_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabId     integer:=null;

    prevAggImpRec record;
    prevCapRec record;
    strRec record;

    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';

    U_STR               CONSTANT varchar:='U';
    E_STR               CONSTANT varchar:='E';

    GESTIONE_FASE               CONSTANT varchar:='G';

BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;

	strMessaggioFinale:='Approvazione bilancio di previsione per Anno bilancio='||annoBilancio::varchar||'.';

    if not (stepPartenza=99 or stepPartenza>=2) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=2 99.';
        codiceRisultato:=-1;
    end if;

    if faseBilancio is null or faseBilancio!=GESTIONE_FASE then
    	raise exception 'Fase Bilancio da indicare %.',GESTIONE_FASE;
    end if;
    -- STEP 1 -- CAPITOLI USCITA
    -- ESEGUITO SOLO SE ESEGUITI TUTTI
    if codiceRisultato=0 and stepPartenza=99 then
  	 strMessaggio:='Capitoli uscita.';

     select * into prevCapRec
     from fnc_fasi_bil_prev_approva
	 (annobilancio,
      U_STR,
      CAP_UP_STR,
      CAP_UG_STR,
      faseBilancio,
      true,--checkGest
      true,--impostaImporti
	  enteProprietarioId,
	  loginoperazione,
 	  dataelaborazione
     );

     if prevCapRec.codiceRisultato=0 then
    	faseBilElabId:=prevCapRec.faseBilElabIdRet;
     else
        strMessaggio:=prevCapRec.messaggioRisultato;
        codiceRisultato:=prevCapRec.codiceRisultato;
     end if;
    end if;

    -- STEP 2 -- CAPITOLI DI ENTRATA
    -- STEP DI RIPARTENZA
    if codiceRisultato=0  and stepPartenza>=2 then
		strMessaggio:='Capitoli entrata.';
        select * into prevCapRec
        from fnc_fasi_bil_prev_approva
		(annobilancio,
		 E_STR,
		 CAP_EP_STR,
		 CAP_EG_STR,
         faseBilancio,
		 true,--checkGest
         true,--impostaImporti
		 enteproprietarioid,
		 loginoperazione,
 	     dataelaborazione);
        if prevCapRec.codiceRisultato=0 then
    		faseBilElabId:=prevCapRec.faseBilElabIdRet;
        else
	        strMessaggio:=prevCapRec.messaggioRisultato;
    	    codiceRisultato:=prevCapRec.codiceRisultato;
        end if;
    end if;


    -- STEP 3 -- popolamento dei vincoli di gestione da previsione
    if codiceRisultato=0 and stepPartenza>=2 then
	    select * into strRec
        from fnc_fasi_bil_gest_ribaltamento_vincoli
        ('PREV-GEST',
         annoBilancio,
         enteProprietarioid,
         loginOperazione,
         dataElaborazione );

         if strRec.codiceRisultato=0 then
            faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;


	-- STEP 5 -- popolamento dei programmi-cronoprogrammi di gestione
	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
    	strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di gestione da previsione corrente.';
       	select * into strRec
       	from fnc_fasi_bil_gest_apertura_programmi
             (
			  annoBilancio,
			  enteProprietarioId,
			  'G',
			  loginOperazione,
			  dataElaborazione,
			  true -- 17.05.2023 Sofia SIAC-8633 in approvazione deve sempre riportare i collegamenti con i movimenti 
             );
       if strRec.codiceRisultato!=0 then
       	strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
       end if;
    end if;

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

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


ALTER FUNCTION siac.fnc_fasi_bil_prev_approva_all
(
  integer,
  varchar,
  integer,
  boolean,
  boolean,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER TO siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_acc_elabora (
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
			 
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;
	movgGestTsIdPadre integer:=null;

    movGestRec        record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	ACC_MOVGEST_TIPO CONSTANT varchar:='A';
  	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-EG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_ACC_RES    CONSTANT varchar:='APE_GEST_ACC_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';
    U_MOV_GEST_DET_TIPO  CONSTANT varchar:='U';

    -- 17.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';

	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento accertamenti  residui  da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;

    codResult:=null;
    strMessaggio:='Verifica esistenza in fase_bil_t_gest_apertura_acc di movimenti da generare.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_acc fase
 	where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
	and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   fase.movgest_orig_id is not null
    and   fase.movgest_orig_ts_id is not null;
    if codResult is null then
    	 raise exception ' Nessun movimento presente.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_acc].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_acc_id) into maxId
        from fase_bil_t_gest_apertura_acc fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

	-- 12.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_acc per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_acc fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_acc_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

	codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_acc dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_acc fase
 	where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
	and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   fase.movgest_orig_id is not null
    and   fase.movgest_orig_ts_id is not null;
    if codResult is null then
    	 raise exception ' Nessun movimento presente.';
    end if;

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



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

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per A
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||ACC_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;





     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     -- 17.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 17.02.2017 Sofia HD-INC000001535447

	 -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
     end if;


     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     strMessaggio:='Inizio ciclo per generazione accertamenti.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_acc_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_acc fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_acc_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
 		 insert into fase_bil_t_elaborazione_log
	     (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	     )
	     values
    	 (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	     returning fase_bil_elab_log_id into codResult;

	     if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	     end if;

    	 codResult:=null;
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Accertamento [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
     	  insert into siac_t_movgest
          (movgest_anno,
		   movgest_numero,
		   movgest_desc,
		   movgest_tipo_id,
		   bil_id,
		   validita_inizio,
	       ente_proprietario_id,
	       login_operazione,
	       parere_finanziario,
	       parere_finanziario_data_modifica,
	       parere_finanziario_login_operazione)
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
          end if;
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo accertamento.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subaccertamento movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';

        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subaccertamento movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
	      siope_tipo_debito_id,
		  siope_assenza_motivazione_id

        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di accertamento padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          ts.siope_tipo_debito_id,
		  ts.siope_assenza_motivazione_id


          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                       ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO,U_MOV_GEST_DET_TIPO)
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
--          and   atto.data_cancellazione is null 17.02.2017 Sofia HD-INC000001535447
--          and   atto.validita_fine is null
         );



		select 1  into codResult
        from siac_r_movgest_ts_atto_amm det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

		-- 17.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         	strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;
        -- 17.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        /*if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;*/

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );



 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia sistemazione gestione quote per escludere quelle incassate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=sub.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        -- SIAC-8551 Sofia - inizio 
        and not exists 
        (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=det1.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
        )
     	-- SIAC-8551 Sofia - fine        		    	   
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
        ;
        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; **/
      
      -- 19.04.2023 SIAC-TASK-21
      -- siac_r_mutuo_movgest_ts
      if codResult is null then
       strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_mutuo_movgest_ts].';
      	insert into siac_r_mutuo_movgest_ts  
      	(
      		movgest_ts_id,
      		mutuo_id,
      		mutuo_movgest_ts_importo_iniziale,
      		mutuo_movgest_ts_importo_finale,
      		validita_inizio,
      		ente_proprietario_id ,
      		login_operazione,
      		login_creazione,
      		login_modifica
      	)
      	select  movGestTsIdRet,
      	             r.mutuo_id,
      	             det.movgest_ts_Det_importo,
      	             det.movgest_ts_Det_importo,
      	             dataInizioVal,
		             enteProprietarioId,
          		     loginOperazione,
          		     loginOperazione,
          		     loginOperazione
      	from siac_r_mutuo_movgest_ts r,siac_t_mutuo mutuo,siac_d_mutuo_stato stato,
      	           siac_t_movgest_ts_det det,siac_d_movgest_ts_det_tipo tipo 
      	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
      	and     mutuo.mutuo_id=r.mutuo_id 
      	and     stato.mutuo_stato_id=mutuo.mutuo_stato_id 
      	and     stato.mutuo_stato_code!='A'
      	and     det.movgest_ts_id=movGestTsIdRet
      	and     tipo.movgest_ts_det_tipo_id =det.movgest_ts_det_tipo_id 
      	and     tipo.movgest_ts_det_tipo_code='I'
      	and     mutuo.data_cancellazione is null 
      	and     mutuo.validita_fine is null
      	and     r.data_cancellazione is null 
      	and     r.validita_fine is null;
        
		select 1  into codResult
        from siac_r_mutuo_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_mutuo_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
      
      end if;
     
	   -- 03.05.2019 Sofia siac-6255
       -- siac_r_movgest_ts_programma
       if codResult is null then
	   	--if faseOp=G_FASE then 17.05.2023 Sofia SIAC-8633
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                      siac_t_programma pnew,siac_d_programma_tipo tipo,
                      siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and     prog.programma_id=r.programma_id
            and     tipo.ente_proprietario_id=prog.ente_proprietario_id
            and     tipo.programma_tipo_code='G'
            and     pnew.programma_tipo_id=tipo.programma_tipo_id
            and     pnew.bil_id=bilancioId
            and     pnew.programma_code=prog.programma_code
            and     rs.programma_id=pnew.programma_id
            and     stato.programma_stato_id=rs.programma_stato_id
--            and     stato.programma_stato_code='VA'      17.05.2023 Sofia SIAC-8633
            and     stato.programma_stato_code!='AN'  -- 17.05.2023 Sofia SIAC-8633           
            and     prog.data_cancellazione is null
            and     prog.validita_fine is null
            and     r.data_cancellazione is null
            and     r.validita_fine is null
            and     pnew.data_cancellazione is null
            and     pnew.validita_fine is null
            and     rs.data_cancellazione is null
            and     rs.validita_fine is null
           );
        --end if;
       end if;

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_acc per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
/*
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;*/

         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

 		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
	     
         -- 19.04.2023 Sofia SIAC-TASK-21
         -- siac_r_mutuo_movgest_ts
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_mutuo_movgest_ts.';
         delete from siac_r_mutuo_movgest_ts   where movgest_ts_id=movGestTsIdRet;
        
         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;

        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_acc per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_acc per scarto.';
      	update fase_bil_t_gest_apertura_acc fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento accertamento/subaccertamento residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_acc_id=movGestRec.fase_bil_gest_ape_acc_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;


       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
       	    -- 12.01.2017 Sofia sistemazione gestione quote per escludere quote incassate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        	-- SIAC-8551 Sofia - inizio  SIAC-8896 Sofia
--	        and not exists 
--    	    (
--        	  select 1
--	          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
--    	      where r.subdoc_id=r.subdoc_id 
--        	  and   p.provc_id=r.provc_id 
--	          and   p.provc_anno::integer=(annoBilancio-1)
--    	      and   p.data_cancellazione is null 
--        	  and   p.validita_fine  is null 
--	          and   r.data_cancellazione is null 
--    	      and   r.validita_fine is null 
--        	)
     		-- SIAC-8551 Sofia - fine      	     SIAC-8896 Sofia	   
            -- SIAC-8896 Sofia - inizio        		    	  
   	        and not exists 
    	    (
        	  select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
    	      where rp.subdoc_id=r.subdoc_id 
        	  and   p.provc_id=rp.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
    	      and   p.data_cancellazione is null 
        	  and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
    	      and   rp.validita_fine is null 
        	)
            -- SIAC-8896 Sofia - fine
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
			and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        	-- SIAC-8551 Sofia - inizio  SIAC-8896
--    	    and not exists 
--	        (
--        	  select 1
--	          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
--    	      where r.subdoc_id=r.subdoc_id 
--		      and   p.provc_id=r.provc_id 
--        	  and   p.provc_anno::integer=(annoBilancio-1)
--	          and   p.data_cancellazione is null 
--    	      and   p.validita_fine  is null 
--	          and   r.data_cancellazione is null 
--    	      and   r.validita_fine is null 
--	        )
        	-- SIAC-8551 Sofia - fine    SIAC-8896
        	-- SIAC-8896 Sofia - inizio 
    	    and not exists 
	        (
        	  select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
    	      where rp.subdoc_id=r.subdoc_id 
		      and   p.provc_id=rp.provc_id 
        	  and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
    	      and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
    	      and   rp.validita_fine is null 
	        )
        	-- SIAC-8896 Sofia - fine            	   	    	   
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_acc per fine elaborazione.';
      	update fase_bil_t_gest_apertura_acc fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_acc_id=movGestRec.fase_bil_gest_ape_acc_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;



     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_ACC_RES||' IN CORSO IN-2.Elabora Acc.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_acc_elabora 
(
  integer,
  integer,
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out varchar)
OWNER TO siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp
(
 enteproprietarioid integer, 
 annobilancio integer, 
 tipoelab character varying, 
 fasebilelabid integer, 
 minid integer, 
 maxid integer, 
 loginoperazione character varying, 
 dataelaborazione timestamp without time zone, 
 OUT codicerisultato integer, 
 OUT messaggiorisultato character varying
 )
 RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;
	movgGestTsIdPadre integer:=null;

    movGestRec        record;
    aggProgressivi    record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-UG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';

    APE_GEST_IMP_RES  CONSTANT varchar:='APE_GEST_IMP_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';

	-- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;

    -- 15.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';


	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

    if tipoElab=APE_GEST_LIQ_RES then
 	 strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui per ribaltamento liquidazioni res da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    else
     strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    end if;

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_liq_imp].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_liq_imp_id) into maxId
        from fase_bil_t_gest_apertura_liq_imp fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

    -- 08.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_liq_imp per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_liq_imp fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where Fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;
    -- 08.11.2019 Sofia SIAC-7145 - fine


     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



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

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per I
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||IMP_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     -- 15.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 15.02.2017 Sofia HD-INC000001535447

     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

	 -- 15.02.2017 Sofia SIAC-4425
     strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
   	 select attr.attr_id into strict flagFrazAttrId
     from siac_t_attr attr
     where attr.ente_proprietario_id=enteProprietarioId
     and   attr.attr_code=FRAZIONABILE_ATTR
     and   attr.data_cancellazione is null
     and   attr.validita_fine is null;


     -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
     end if;

     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     strMessaggio:='Inizio ciclo per generazione impegni.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_liq_imp_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
              fase.elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
              fase.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_liq_imp fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
/*      and   exists -- x test siac-6255
      (
      select 1
      from siac_r_movgest_ts_programma r
      where r.movgest_ts_id=fase.movgest_orig_ts_id
      and   r.data_cancellazione is null
      and   r.validita_fine is null
      ) */
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
 		 insert into fase_bil_t_elaborazione_log
	     (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	     )
	     values
    	 (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	     returning fase_bil_elab_log_id into codResult;

	     if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	     end if;

    	 codResult:=null;
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Impegno [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
     	  insert into siac_t_movgest
          (movgest_anno,
		   movgest_numero,
		   movgest_desc,
		   movgest_tipo_id,
		   bil_id,
		   validita_inizio,
	       ente_proprietario_id,
	       login_operazione,
	       parere_finanziario,
	       parere_finanziario_data_modifica,
	       parere_finanziario_login_operazione
		   )
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
               elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
               movGestRec.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
          end if;
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo impegno.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subimpegno movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';
			strMessaggioTemp:=strMessaggio;
        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subimpegno movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
		  siope_tipo_debito_id ,
  		  siope_assenza_motivazione_id
        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di impegno padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
		  ts.siope_tipo_debito_id ,
  		  ts.siope_assenza_motivazione_id
          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                       ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO)
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

       /* select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_movgest_ts_atto_amm det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

       -- raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        -- 15.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );



 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

      
       -- 19.04.2023 SIAC-TASK-21
      -- siac_r_mutuo_movgest_ts
      if codResult is null then
       strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_mutuo_movgest_ts].';
      	insert into siac_r_mutuo_movgest_ts  
      	(
      		movgest_ts_id,
      		mutuo_id,
      		mutuo_movgest_ts_importo_iniziale,
      		mutuo_movgest_ts_importo_finale,
      		validita_inizio,
      		ente_proprietario_id ,
      		login_operazione,
      		login_creazione,
      		login_modifica
      	)
      	select  movGestTsIdRet,
      	             r.mutuo_id,
      	             det.movgest_ts_det_importo,
      	             det.movgest_ts_det_importo,
      	             dataInizioVal,
		             enteProprietarioId,
          		     loginOperazione,
          		     loginOperazione,
          		     loginOperazione
      	from siac_r_mutuo_movgest_ts r,siac_t_mutuo mutuo,siac_d_mutuo_stato stato,
      	           siac_t_movgest_ts_det det,siac_d_movgest_Ts_det_tipo tipo 
      	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
      	and      det.movgest_ts_id=movGestTsIdRet
      	and      tipo.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id 
      	and      tipo.movgest_ts_det_tipo_code='I'
      	and      mutuo.mutuo_id=r.mutuo_id 
      	and      stato.mutuo_stato_id=mutuo.mutuo_stato_id 
      	and      stato.mutuo_stato_code!='A'
      	and      mutuo.data_cancellazione is null 
      	and      mutuo.validita_fine is null
      	and      r.data_cancellazione is null 
      	and      r.validita_fine is null;
        
		select 1  into codResult
        from siac_r_mutuo_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_mutuo_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
      
      end if;
     
       -- siac_r_movgest_ts_programma
       if codResult is null then
--	   	if faseOp=G_FASE then -- 17.05.2023 Sofia SIAC-8633 
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
--            and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN'			-- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );

		   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );

           strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
		         siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );
--        end if; ---- 17.05.2023 Sofia SIAC-8633
        end if;


       /*if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_programma].';

        insert into siac_r_movgest_ts_programma
        ( movgest_ts_id,
          programma_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_movgest_ts_programma det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_programma det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_programma movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

	   -- 16.03.2023 Sofia SIAC-TASK-#44
	   -- siac_r_mutuo_voce_movgest						   


       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_giustificativo_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/


       -- siac_r_cartacont_det_movgest_ts
       /* Non si ribalta in seguito ad indicazioni di Annalina
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_cartacont_det_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_fondo_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_fondo_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_richiesta_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_richiesta_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia correzione per esclusione quote pagate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.subdoc_pagato_cec =false -- 28.04.2023 Sofia SIAC-TASK-4
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          -- 04.05.2021 Sofia SIAC-8095
          and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=r.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
          -- 04.05.2021 Sofia SIAC-8095
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=sub.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine                
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        -- 04.05.2021 Sofia SIAC-8095
          and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=det1.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
          -- 04.05.2021 Sofia SIAC-8095
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=det1.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine                
/*        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione) -- 28.04.2023 Sofia SIAC-TASK-4*/
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det,siac_t_subdoc sub1 -- 28.04.2023 Sofia SIAC-TASK-4
				          where det.movgest_ts_id=movGestTsIdRet
				            and    sub1.subdoc_id=det.subdoc_id
				            and   sub1.subdoc_pagato_cec =false
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A');

        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
		and   det1.data_cancellazione is null
        and   det1.validita_fine is null;

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
      /*   spostato sotto dopo pulizia in caso di codResult null
           if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; */

       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
    	 	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
	                      ' movgest_orig_id='||movGestRec.movgest_orig_id||
                          ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                          ' elem_orig_id='||movGestRec.elem_orig_id||
                          ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_cartacont_det_movgest_ts].';
	        update siac_r_cartacont_det_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_cartacont_det_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;
       end if; */


	   -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null then
       	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_storico_imp_acc].';

        insert into siac_r_movgest_ts_storico_imp_acc
        ( movgest_ts_id,
          movgest_anno_acc,
          movgest_numero_acc,
          movgest_subnumero_acc,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_anno_acc,
           r.movgest_numero_acc,
           r.movgest_subnumero_acc,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_storico_imp_acc r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
        );


        select 1  into codResult
        from siac_r_movgest_ts_storico_imp_acc det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;

         -- siac_r_giustificativo_movgest
/*         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet; */
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

	     -- 17.06.2019 Sofia siac-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;


         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        
         -- 19.04.2023 Sofia SIAC-TASK-21
         -- siac_r_mutuo_movgest_ts
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_mutuo_movgest_ts.';
         delete from siac_r_mutuo_movgest_ts   where movgest_ts_id=movGestTsIdRet;

        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;




/*        strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';

      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento impegno/subimpegno residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
            --- 12.01.2017 Sofia - sistemazione update per escludere le quote pagate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
            from siac_t_subdoc sub  -- 28.04.2023 Sofia SIAC-TASK-4
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and     sub.subdoc_id=r.subdoc_id  -- 28.04.2023 Sofia SIAC-TASK-4
	        and     sub.subdoc_pagato_cec =false  -- 28.04.2023 Sofia SIAC-TASK-4
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
		   -- 04.05.2021 Sofia SIAC-8095
           and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=r.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
            -- 04.05.2021 Sofia SIAC-8095
			-- SIAC-8551 Sofia - inizio 
            and not exists 
            (
	          select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
	          where rp.subdoc_id=r.subdoc_id 
	          and   p.provc_id=rp.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
	          and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
	          and   rp.validita_fine is null 
            )
     	    -- SIAC-8551 Sofia - fine                          
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub,siac_t_doc  doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r, 
    	               siac_t_subdoc sub -- 28.04.2023 Sofia SIAC-TASK-4
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        	and     sub.subdoc_id=r.subdoc_id  -- 28.04.2023 Sofia SIAC-TASK-4
        	and     sub.subdoc_pagato_cec =false -- 28.04.2023 Sofia SIAC-TASK-4
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
            -- 04.05.2021 Sofia SIAC-8095
            and  not exists (
                             select 1
                             from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                             where rord.subdoc_id=r.subdoc_id
                             and   ts.ord_ts_id=rord.ord_ts_id
                             and   ord.ord_id=ts.ord_id
                             and   ord.ord_anno>annoBilancio
                             and   rord.data_cancellazione is null
                             and   rord.validita_fine is null
                           )
            -- 04.05.2021 Sofia SIAC-8095
            -- SIAC-8551 Sofia - inizio 
	        and not exists 
            (
	          select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
	          where rp.subdoc_id=r.subdoc_id 
	          and   p.provc_id=rp.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
	          and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
	          and   rp.validita_fine is null 
            )
     	    -- SIAC-8551 Sofia - fine               
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
	    	    --strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
        end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_liq_imp per fine elaborazione.';
      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;


	 -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni residui.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni residui.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer<annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atti amministrativi antecedenti.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=2017
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile

    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||tipoElab||' IN CORSO IN-2.Elabora Imp.'
    where fase_bil_elab_id=faseBilElabId;


    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp 
(
  integer,
  integer,
  varchar,
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out varchar)
OWNER TO siac;


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_pluri_elabora
( enteproprietarioid integer, annobilancio integer, fasebilelabid integer, tipocapitologest character varying, tipomovgest character varying, tipomovgestts character varying, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying)
 RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;

    movGestRec        record;
    aggProgressivi    record;


	movgestTsTipoDetIniz integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetAtt  integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetUtil integer; -- 29.01.2018 Sofia siac-5830

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';
	SIM_MOVGEST_TS_TIPO CONSTANT varchar:='SIM';
    SAC_MOVGEST_TS_TIPO CONSTANT varchar:='SAC';


    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    A_MOV_GEST_STATO  CONSTANT varchar:='A';

	-- 14.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;


    INIZ_MOVGEST_TS_DET_TIPO  constant varchar:='I'; -- 29.01.2018 Sofia siac-5830
    ATT_MOVGEST_TS_DET_TIPO   constant varchar:='A'; -- 29.01.2018 Sofia siac-5830
    UTI_MOVGEST_TS_DET_TIPO   constant varchar:='U'; -- 29.01.2018 Sofia siac-5830

	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

    -- 14.05.2020 Sofia SIAC-7593
    elemDetCompTipoId INTEGER:=null;
BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    raise notice 'fnc_fasi_bil_gest_apertura_pluri_elabora tipoCapitoloGest=%',tipoCapitoloGest;

	if tipoMovGest=IMP_MOVGEST_TIPO then
    	 movGestTsTipoCode=SIM_MOVGEST_TS_TIPO;
    else movGestTsTipoCode=SAC_MOVGEST_TS_TIPO;
    end if;

    dataInizioVal:= clock_timestamp();
--    dataEmissione:=((annoBilancio-1)::varchar||'-12-31')::timestamp; -- da capire che data impostare come data emissione
    -- 23.08.2016 Sofia in attesa di indicazioni diverse ho deciso di impostare il primo di gennaio del nuovo anno di bilancio
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;
--    raise notice 'fasbilElabId %',faseBilElabId;
	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora tipoMovGest='||tipoMovGest||' minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
     strMessaggio:='Inserimento LOG.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

	codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_pluri.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_pluri fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna movimento da creare.';
    end if;


    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_pluri].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_pluri_id) into maxId
        from fase_bil_t_gest_apertura_pluri fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null;
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;


     strMessaggio:='Lettura id identificativo per tipo capitolo='||tipoCapitoloGest||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=tipoCapitoloGest
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



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

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per I,A
     strMessaggio:='Lettura id identificativo per tipoMovGest='||tipoMovGest||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=tipoMovGest
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;





     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
          movGestTsTipoId:=tipoMovGestTsTId;
     else movGestTsTipoId:=tipoMovGestTsSId;
     end if;

     if movGestTsTipoId is null then
      strMessaggio:='Lettura identificativo per tipoMovGestTs='||tipoMovGestTs||'.';
      select tipo.movgest_ts_tipo_id into strict movGestTsTipoId
      from siac_d_movgest_ts_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.movgest_ts_tipo_code=tipoMovGestTs
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null;
     end if;


	 -- 14.02.2017 Sofia SIAC-4425
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;
     end if;

	 -- 29.01.2018 Sofia siac-5830
     strMessaggio:='Lettura identificativo per tipo importo='||INIZ_MOVGEST_TS_DET_TIPO||'.';
     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetIniz
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=INIZ_MOVGEST_TS_DET_TIPO;

     strMessaggio:='Lettura identificativo per tipo importo='||ATT_MOVGEST_TS_DET_TIPO||'.';

     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetAtt
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=ATT_MOVGEST_TS_DET_TIPO;

--	 if tipoMovGest=ACC_MOVGEST_TIPO then
     	 strMessaggio:='Lettura identificativo per tipo importo='||UTI_MOVGEST_TS_DET_TIPO||'.';
		 select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetUtil
    	 from siac_d_movgest_ts_det_tipo tipo
	     where tipo.ente_proprietario_id=enteProprietarioId
    	 and   tipo.movgest_ts_det_tipo_code=UTI_MOVGEST_TS_DET_TIPO;
  --   end if;
     -- 29.01.2018 Sofia siac-5830

	 -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
     end if;

     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     -- se impegno-accertamento verifico che i relativi capitoli siano presenti sul nuovo Bilancio
     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. INIZIO.';
	   	codResult:=null;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
       	 validita_inizio, login_operazione, ente_proprietario_id
      	)
      	values
      	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      	returning fase_bil_elab_log_id into codResult;

      	if codResult is null then
     		raise exception ' Errore in inserimento LOG.';
      	end if;

        update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='IMAC1',
            scarto_desc='Movimento impegno/accertamento pluriennale privo di capitolo nel nuovo bilancio'
      	from siac_t_bil_elem elem
      	where fase.fase_bil_elab_id=faseBilElabId
      	and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      	and   fase.movgest_tipo=movGestTsTipoCode
     	and   fase.fl_elab='N'
        and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
     	and   elem.ente_proprietario_id=fase.ente_proprietario_id
        and   elem.elem_id=fase.elem_orig_id
    	and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
     	and   elem.data_cancellazione is null
     	and   elem.validita_fine is null
        and   not exists (select 1 from siac_t_bil_elem elemnew
                          where elemnew.ente_proprietario_id=elem.ente_proprietario_id
                          and   elemnew.elem_tipo_id=elem.elem_tipo_id
                          and   elemnew.bil_id=bilancioId
                          and   elemnew.elem_code=elem.elem_code
                          and   elemnew.elem_code2=elem.elem_code2
                          and   elemnew.elem_code3=elem.elem_code3
                          and   elemnew.data_cancellazione is null
                          and   elemnew.validita_fine is null
                         );


        strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. FINE.';
	   	codResult:=null;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
       	 validita_inizio, login_operazione, ente_proprietario_id
      	)
      	values
      	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      	returning fase_bil_elab_log_id into codResult;

      	if codResult is null then
     		raise exception ' Errore in inserimento LOG.';
      	end if;

     end if;
     -- se sub, verifico prima se i relativi padri sono stati elaborati e creati
     -- se non sono stati ribaltati scarto  i relativi sub per escluderli da elaborazione

     if tipoMovGestTs=MOVGEST_TS_S_TIPO then
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. INIZIO.';
	  codResult:=null;
	  insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
       validita_inizio, login_operazione, ente_proprietario_id
      )
      values
      (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

      if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
      end if;

      update fase_bil_t_gest_apertura_pluri fase
      set fl_elab='X',
          scarto_code='SUB1',
          scarto_desc='Movimento sub impegno/accertamento pluriennale privo di impegno/accertamento pluri nel nuovo bilancio'
      from siac_t_movgest mprec
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   fase.movgest_tipo=movGestTsTipoCode
      and   fase.fl_elab='N'
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   mprec.ente_proprietario_id=fase.ente_proprietario_id
      and   mprec.movgest_id=fase.movgest_orig_id
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   mprec.data_cancellazione is null
      and   mprec.validita_fine is null
      and   not exists (select 1 from siac_t_movgest mnew
                        where mnew.ente_proprietario_id=mprec.ente_proprietario_id
                        and   mnew.movgest_tipo_id=mprec.movgest_tipo_id
                        and   mnew.bil_id=bilancioId
                        and   mnew.movgest_anno=mprec.movgest_anno
                        and   mnew.movgest_numero=mprec.movgest_numero
                        and   mnew.data_cancellazione is null
                        and   mnew.validita_fine is null
                        );
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. FINE.';
	  codResult:=null;
	  insert into fase_bil_t_elaborazione_log
      (fase_bil_elab_id,fase_bil_elab_log_operazione,
       validita_inizio, login_operazione, ente_proprietario_id
      )
      values
      (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_bil_elab_log_id into codResult;

      if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
      end if;

     end if;

     strMessaggio:='Inizio ciclo per tipoMovGest='||tipoMovGest||' tipoMovGestTs='||tipoMovGestTs||'.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;


     for movGestRec in
     (select tipo.movgest_tipo_code,
     		 m.*,
             tstipo.movgest_ts_tipo_code,
             ts.*,
             fase.fase_bil_gest_ape_pluri_id,
             fase.movgest_orig_id,
             fase.movgest_orig_ts_id,
             fase.elem_orig_id,
             mpadre.movgest_id movgest_id_new,
             tspadre.movgest_ts_id movgest_ts_id_padre_new
      from  fase_bil_t_gest_apertura_pluri fase
             join siac_t_movgest m
               left outer join
               ( siac_t_movgest mpadre join  siac_t_movgest_ts tspadre
                   on (tspadre.movgest_id=mpadre.movgest_id
                   and tspadre.movgest_ts_tipo_id=tipoMovGestTsTId
                   and tspadre.data_cancellazione is null
                   and tspadre.validita_fine is null)
                )
                on (mpadre.movgest_anno=m.movgest_anno
                and mpadre.movgest_numero=m.movgest_numero
                and mpadre.bil_id=bilancioId
                and mpadre.ente_proprietario_id=m.ente_proprietario_id
                and mpadre.movgest_tipo_id = tipoMovGestId
                and mpadre.data_cancellazione is null
                and mpadre.validita_fine is null)
             on   ( m.ente_proprietario_id=fase.ente_proprietario_id  and   m.movgest_id=fase.movgest_orig_id),
            siac_d_movgest_tipo tipo,
            siac_t_movgest_ts ts,
            siac_d_movgest_ts_tipo tstipo
      where fase.fase_bil_elab_id=faseBilElabId
          and   tipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tipo.movgest_tipo_code=tipoMovGest
          and   tstipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tstipo.movgest_ts_tipo_code=tipoMovGestTs
          and   m.ente_proprietario_id=fase.ente_proprietario_id
          and   m.movgest_id=fase.movgest_orig_id
          and   m.movgest_tipo_id=tipo.movgest_tipo_id
          and   ts.ente_proprietario_id=fase.ente_proprietario_id
          and   ts.movgest_ts_id=fase.movgest_orig_ts_id
          and   ts.movgest_ts_tipo_id=tstipo.movgest_ts_tipo_id
          and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
          and   fase.fl_elab='N'
          and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          order by fase_bil_gest_ape_pluri_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        codResult:=null;
		elemNewId:=null;

		-- 14.05.2020 Sofia SIAC-7593
        elemDetCompTipoId:=null;

        strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
         raise notice 'strMessaggio=%  movGestRec.movgest_id_new=%', strMessaggio, movGestRec.movgest_id_new;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

    	codResult:=null;
        if movGestRec.movgest_id_new is null then
      	 strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                       ' anno='||movGestRec.movgest_anno||
                       ' numero='||movGestRec.movgest_numero||' [siac_t_movgest].';
     	 insert into siac_t_movgest
         (movgest_anno,
		  movgest_numero,
		  movgest_desc,
		  movgest_tipo_id,
		  bil_id,
		  validita_inizio,
	      ente_proprietario_id,
	      login_operazione,
	      parere_finanziario,
	      parere_finanziario_data_modifica,
	      parere_finanziario_login_operazione)
         values
         (movGestRec.movgest_anno,
		  movGestRec.movgest_numero,
		  movGestRec.movgest_desc,
		  movGestRec.movgest_tipo_id,
		  bilancioId,
		  dataInizioVal,
	      enteProprietarioId,
	      loginOperazione,
	      movGestRec.parere_finanziario,
	      movGestRec.parere_finanziario_data_modifica,
	      movGestRec.parere_finanziario_login_operazione
         )
         returning movgest_id into movGestIdRet;
         if movGestIdRet is null then
           strMessaggioTemp:=strMessaggio;
           codResult:=-1;
         end if;
			raise notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movGestIdRet;
		 if codResult is null then
         strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';

         raise notice 'strMessaggio=%',strMessaggio;
         -- 14.05.2020 Sofia SIAC-7593
         --select  new.elem_id into elemNewId
         select  new.elem_id , r.elem_det_comp_tipo_id into  elemNewId,elemDetCompTipoId -- 14.05.2020 Sofia SIAC-7593
         from siac_r_movgest_bil_elem r,
              siac_t_bil_elem prec, siac_t_bil_elem new
         where r.movgest_id=movGestRec.movgest_orig_id
         and   prec.elem_id=r.elem_id
         and   new.elem_code=prec.elem_code
         and   new.elem_code2=prec.elem_code2
         and   new.elem_code3=prec.elem_code3
         and   prec.elem_tipo_id=new.elem_tipo_id
         and   prec.bil_id=bilancioPrecId
         and   new.bil_id=bilancioId
         and   r.data_cancellazione is null
         and   r.validita_fine is null
         and   prec.data_cancellazione is null
         and   prec.validita_fine is null
         and   new.data_cancellazione is null
         and   new.validita_fine is null;
         if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
         end if;
		 raise notice 'elemNewId=%',elemNewId;
		 if codResult is null then
          	  strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
             	            ' anno='||movGestRec.movgest_anno||
                 	        ' numero='||movGestRec.movgest_numero||' [siac_r_movgest_bil_elem]';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
               elem_Det_comp_tipo_id, -- 14.05.2020 Sofia SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   elemNewId,
               elemDetCompTipoId, -- 14.05.2020 Sofia SIAC-7593
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
         end if;
        end if;
      else
        movGestIdRet:=movGestRec.movgest_id_new;
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';
        -- 14.05.2020 Sofia SIAC-7593
        --select  r.elem_id into elemNewId
        select  r.elem_id,r.elem_det_comp_tipo_id into elemNewId, elemDetCompTipoId -- 14.05.2020 Sofia SIAC-7593
        from siac_r_movgest_bil_elem r
        where r.movgest_id=movGestIdRet
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;
      end if;


      if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts].';
		raise notice 'strMessaggio=% ',strMessaggio;
/*        dataEmissione:=( (2018::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;*/

        -- 21.02.2019 Sofia SIAC-6683
        dataEmissione:=( (annoBilancio::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;
        raise notice 'dataEmissione=% ',dataEmissione;

        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
		  siope_tipo_debito_id,
		  siope_assenza_motivazione_id

        )
        values
        ( movGestRec.movgest_ts_code,
          movGestRec.movgest_ts_desc,
          movGestIdRet,    -- inserito se I/A, per SUB ricavato
          movGestRec.movgest_ts_tipo_id,
          movGestRec.movgest_ts_id_padre_new,  -- valorizzato se SUB
          movGestRec.movgest_ts_scadenza_data,
          movGestRec.ordine,
          movGestRec.livello,
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataInizioVal else dataEmissione end), -- 25.11.2016 Sofia
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataEmissione else dataInizioVal end), -- 25.11.2016 Sofia
--          dataEmissione, -- 12.04.2017 Sofia
          dataEmissione,   -- 09.02.2018 Sofia
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          movGestRec.siope_tipo_debito_id,
		  movGestRec.siope_assenza_motivazione_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;
        raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;
       -- siac_r_liquidazione_movgest --> x pluriennali non dovrebbe esserci legame e andrebbe ricreato cmq con il ribaltamento delle liq
       -- siac_r_ordinativo_ts_movgest_ts --> x pluriennali non dovrebbe esistere legame in ogni caso non deve essere  ribaltato
       -- siac_r_movgest_ts --> legame da creare alla conclusione del ribaltamento dei pluriennali e dei residui

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        -- 29.01.2018 Sofia siac-5830 - insert sostituita con le tre successive


        /*insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );*/
        --returning movgest_ts_det_id into  codResult;

        -- 29.01.2018 Sofia siac-5830 - iniziale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetIniz,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - attuale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - utilizzabile = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetUtil,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );
--        returning movgest_classif_id into  codResult;

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;


        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );
        --returning bil_elem_attr_id into  codResult;

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

        /*select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        --returning movgest_atto_amm_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
         end if;
       end if;*/

       -- se movimento provvisorio atto_amm potrebbe non esserci
	   select 1  into codResult
       from siac_r_movgest_ts_atto_amm det1
       where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
       and   det1.data_cancellazione is null
       and   det1.validita_fine is null
       and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
			             where det.movgest_ts_id=movGestTsIdRet
					       and   det.data_cancellazione is null
					       and   det.validita_fine is null
					       and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning movgest_ts_sog_id into  codResult;

        /*select 1 into codResult
        from siac_r_movgest_ts_sog det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
          and   classe.data_cancellazione is null
          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning soggetto_classe_id into  codResult;

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- 03.05.2019 Sofia siac-6255
       if codResult is null then
         -- siac_r_movgest_ts_programma
--         if faseOp=G_FASE then -- 17.05.2023 Sofia SIAC-8633
          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' [siac_r_movgest_ts_programma].';

          insert into siac_r_movgest_ts_programma
          ( movgest_ts_id,
            programma_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );
          --returning movgest_ts_programma_id into  codResult;
          /*select 1 into codResult
          from siac_r_movgest_ts_programma det
          where det.movgest_ts_id=movGestTsIdRet
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   det.login_operazione=loginOperazione;*/

		  -- 03.05.2019 Sofia siac-6255
          /*
          insert into siac_r_movgest_ts_programma
        ( movgest_ts_id,
          programma_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
          select 1  into codResult
          from siac_r_movgest_ts_programma det1
          where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   det1.data_cancellazione is null
          and   det1.validita_fine is null
          and   not exists (select 1 from siac_r_movgest_ts_programma det
                            where det.movgest_ts_id=movGestTsIdRet
                              and   det.data_cancellazione is null
                              and   det.validita_fine is null
                              and   det.login_operazione=loginOperazione);

          if codResult is not null then
           codResult:=-1;
           strMessaggioTemp:=strMessaggio;
          else codResult:=null;
          end if;*/

          -- siac_r_movgest_ts_cronop_elem
          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          (
          	movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
            and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null;

          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          (
          	movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
                 siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null;
--         end if; -- 17.05.2023 Sofia SIAC-8633
       end if; 
       -- 03.05.2019 Sofia siac-6255
     
      
            -- 19.04.2023 SIAC-TASK-21
      -- siac_r_mutuo_movgest_ts
      if codResult is null then
       strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_mutuo_voce_movgest_ts].';
      	insert into siac_r_mutuo_movgest_ts  
      	(
      		movgest_ts_id,
      		mutuo_id,
      		mutuo_movgest_ts_importo_iniziale,
      		mutuo_movgest_ts_importo_finale,
      		validita_inizio,
      		ente_proprietario_id ,
      		login_operazione,
      		login_creazione,
      		login_modifica
      	)
      	select  movGestTsIdRet,
      	             r.mutuo_id,
      	             det.movgest_ts_det_importo,
      	             det.movgest_ts_det_importo,
      	             dataInizioVal,
		             enteProprietarioId,
          		     loginOperazione,
          		     loginOperazione,
          		     loginOperazione
      	from siac_r_mutuo_movgest_ts r,siac_t_mutuo mutuo,siac_d_mutuo_stato stato, 
      	           siac_t_movgest_ts_det det ,siac_d_movgest_ts_det_tipo tipo 
      	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
      	and     det.movgest_ts_id=movGestTsIdRet
      	and     tipo.movgest_ts_det_tipo_id = det.movgest_ts_det_tipo_id 
      	and     tipo.movgest_ts_det_tipo_code='I'
      	and     mutuo.mutuo_id=r.mutuo_id 
      	and     stato.mutuo_stato_id=mutuo.mutuo_stato_id 
      	and     stato.mutuo_stato_code!='A'
      	and     mutuo.data_cancellazione is null 
      	and     mutuo.validita_fine is null
      	and     r.data_cancellazione is null 
      	and     r.validita_fine is null;
        
		select 1  into codResult
        from siac_r_mutuo_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_mutuo_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
      
      end if;
     
	/*	16.03.2023 Sofia SIAC-TASK-#44							
	   -- siac_r_mutuo_voce_movgest
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_mutuo_voce_movgest].';

        insert into siac_r_mutuo_voce_movgest
        ( movgest_ts_id,
          mut_voce_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.mut_voce_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_mutuo_voce_movgest r,siac_t_mutuo_voce voce
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   voce.mut_voce_id=r.mut_voce_id
          and   voce.data_cancellazione is null
          and   voce.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning mut_voce_movgest_id into  codResult;

        **select 1 into codResult
        from siac_r_mutuo_voce_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;**

		select 1  into codResult
        from siac_r_mutuo_voce_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_voce_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
	  */ 

       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa economale - da non ricreare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning gstmovgest_id into  codResult;

    *    select 1 into codResult
        from siac_r_giustificativo_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*

		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

        *select 1 into codResult
        from siac_r_cartacont_det_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_causale_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning caus_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_causale_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_fondo_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning liq_movgest_id into  codResult;

       /* select 1 into codResult
        from siac_r_fondo_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_richiesta_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning riceconsog_id into  codResult;

       /* select 1 into codResult
        from siac_r_richiesta_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_subdoc_movgest_ts].';

        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

       /* select 1 into codResult
        from siac_r_subdoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning predoc_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_predoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- cancellazione logica relazioni anno precedente
       -- siac_r_cartacont_det_movgest_ts
/*  non si gestisce in seguito ad indicazioni con Annalina
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' . Cancellazione siac_r_cartacont_det_movgest_ts anno bilancio precedente.';

        update siac_r_cartacont_det_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_cartacont_det_movgest_ts r,	siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if codResult is not null then
        	 strMessaggioTemp:=strMessaggio;
        	 codResult:=-1;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

       -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null and tipoMovGest=IMP_MOVGEST_TIPO then
		strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_storico_imp_acc].';
          insert into siac_r_movgest_ts_storico_imp_acc
          ( movgest_ts_id,
            movgest_anno_acc,
            movgest_numero_acc,
            movgest_subnumero_acc,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             r.movgest_anno_acc,
             r.movgest_numero_acc,
             r.movgest_subnumero_acc,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_storico_imp_acc r
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
          );


          select 1  into codResult
          from siac_r_movgest_ts_storico_imp_acc det1
          where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   det1.data_cancellazione is null
          and   det1.validita_fine is null
          and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
                            where det.movgest_ts_id=movGestTsIdRet
                              and   det.data_cancellazione is null
                              and   det.validita_fine is null
                              and   det.login_operazione=loginOperazione);
          raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

          if codResult is not null then
           codResult:=-1;
           strMessaggioTemp:=strMessaggio;
          else codResult:=null;
          end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_pluri per scarto
	   if codResult=-1 then
       	/*if movGestRec.movgest_id_new is null then
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        end if; spostato sotto */

        if movGestTsIdRet is not null then
         -- siac_t_movgest_ts
 	    /*strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet; spostato sotto */

         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;
/*
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_mutuo_voce_movgest.';
         delete from siac_r_mutuo_voce_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_giustificativo_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet;*/
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

		 -- 17.06.2019 Sofia SIAC-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;

		-- 19.04.2023 Sofia SIAC-TASK-21
         -- siac_r_mutuo_movgest_ts
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_mutuo_movgest_ts.';
         delete from siac_r_mutuo_movgest_ts   where movgest_ts_id=movGestTsIdRet;
        
         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if movGestRec.movgest_id_new is null then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;


        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';*/
	    strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='PLUR1',
            scarto_desc='Movimento impegno/accertamento sub  pluriennale non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

		continue;
       end if;

	   -- annullamento relazioni movimenti precedenti
       -- siac_r_subdoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             --strMessaggioTemp:=strMessaggio;
             raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
--             strMessaggioTemp:=strMessaggio;
               raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'. Aggiornamento fase_bil_t_gest_apertura_pluri per fine elaborazione.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='S',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet,
            elem_id=elemNewId,
            elem_Det_comp_tipo_id=elemDetCompTipoId, -- 14.05.2020 Sofia Jira SIAC-7593
            bil_id=bilancioId
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

       strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;


     -- aggiornamento progressivi
	 if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	 strMessaggio:='Aggiornamento progressivi.';
		 select * into aggProgressivi
   		 from fnc_aggiorna_progressivi(enteProprietarioId, tipoMovGest, loginOperazione);
	     if aggProgressivi.codresult=-1 then
			RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
     	 end if;
     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     	INSERT INTO siac_r_movgest_ts_attr
		(
		  movgest_ts_id,
		  attr_id,
		  boolean,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
		)
		select ts.movgest_ts_id,
		       flagFrazAttrId,
               'N',
		       dataInizioVal,
		       ts.ente_proprietario_id,
		       loginOperazione
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
        and   mov.movgest_anno::integer>annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   not exists (select 1 from siac_r_movgest_ts_attr r1
        		          where r1.movgest_ts_id=ts.movgest_ts_id
                          and   r1.attr_id=flagFrazAttrId
                          and   r1.data_cancellazione is null
                          and   r1.validita_fine is null);

        -- insert S per impegni mov.movgest_anno::integer=annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
		INSERT INTO siac_r_movgest_ts_attr
		(
		  movgest_ts_id,
		  attr_id,
		  boolean,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
		)
		select ts.movgest_ts_id,
		       flagFrazAttrId,
               'S',
		       dataInizioVal,
		       ts.ente_proprietario_id,
		       loginOperazione
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::integer=annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   not exists (select 1 from siac_r_movgest_ts_attr r1
        		          where r1.movgest_ts_id=ts.movgest_ts_id
                          and   r1.attr_id=flagFrazAttrId
                          and   r1.data_cancellazione is null
                          and   r1.validita_fine is null)
        and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
						 where ra.movgest_ts_id=ts.movgest_ts_id
						 and   atto.attoamm_id=ra.attoamm_id
				 		 and   atto.attoamm_anno::integer < annoBilancio
		     			 and   ra.data_cancellazione is null
				         and   ra.validita_fine is null);

        -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
		update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
		and   mov.movgest_anno::integer>annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   r.movgest_ts_id=ts.movgest_ts_id
        and   r.attr_id=flagFrazAttrId
		and   r.boolean='S'
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atto amministrativo antecedente.';
        update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts,
		     siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::INTEGER=annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   r.movgest_ts_id=ts.movgest_ts_id
        and   r.attr_id=flagFrazAttrId
		and   ra.movgest_ts_id=ts.movgest_ts_id
		and   atto.attoamm_id=ra.attoamm_id
		and   atto.attoamm_anno::integer < annoBilancio
		and   r.boolean='S'
        and   r.data_cancellazione is null
        and   r.validita_fine is null
        and   ra.data_cancellazione is null
        and   ra.validita_fine is null;

     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-2.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_fasi_bil_gest_apertura_pluri_elabora
(  integer,  integer,  integer,  character varying,  character varying,  character varying,  integer,  integer,  character varying,  timestamp without time zone, OUT  integer, OUT  character varying) owner to siac;



-- SIAC-8633 Sofia 13.06.2023 fine 