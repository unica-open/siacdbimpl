/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_vincoli_elabora(
  enteProprietarioId     integer,
  annoBilancio           integer,
  faseBilElabId          integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio       VARCHAR(1500):='';
    strMessaggioTemp   VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';
	dataInizioVal      timestamp:=null;
	codResult          integer:=null;

    IMP_MOVGEST_TIPO  CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO  CONSTANT varchar:='A';
    IMP_MOVGEST       CONSTANT varchar:='IMP';
    ACC_MOVGEST       CONSTANT varchar:='ACC';

    APE_GEST_VINCOLI    CONSTANT varchar:='APE_GEST_VINCOLI';

    bilancioPrecId    integer:=null;
    --- 26.06.2019 Sofia siac-6702
    bilancioId        integer:=null;
    numeroVincoliIns  integer:=null;

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

    strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento vincoli da Gestione precedente. Anno bilancio='
                        ||annoBilancio::varchar||'. ELABORA.';


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
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_vincoli.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_vincoli fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessun  vincolo da creare.';
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


    strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id into strict bilancioPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;

    --- 26.06.2019 Sofia siac-6702
    strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id into strict bilancioId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;


    strMessaggio:='Verifica scarti per accertamento non esistente';
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

	update  fase_bil_t_gest_apertura_vincoli fase
    set    fl_elab='X',
           scarto_code='ACC',
           scarto_desc='ACCERTAMENTO NON ESISTENTE O NON VALIDO'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   fase.movgest_ts_a_id is not null -- 06.12.2017 Sofia jira siac-5276
    and   not exists (select 1 from siac_t_movgest_ts ts, siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
                      where ts.movgest_ts_id=fase.movgest_ts_a_id
                      and   r.movgest_ts_id=ts.movgest_ts_id
                      and   stato.movgest_stato_id=r.movgest_stato_id
                      and   stato.movgest_stato_code!='A'
                      and   r.data_cancellazione is null
                      and   r.validita_fine is null
                      and   ts.data_cancellazione is null
                      and   ts.validita_fine is null
                     )
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    strMessaggio:='Verifica scarti per impegno non esistente';
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


	update  fase_bil_t_gest_apertura_vincoli fase
    set    fl_elab='X',
           scarto_code='IMP',
           scarto_desc='IMPEGNO NON ESISTENTE O NON VALIDO'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   not exists (select 1 from siac_t_movgest_ts ts, siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
                      where ts.movgest_ts_id=fase.movgest_ts_b_id
                      and   r.movgest_ts_id=ts.movgest_ts_id
                      and   stato.movgest_stato_id=r.movgest_stato_id
                      and   stato.movgest_stato_code!='A'
                      and   r.data_cancellazione is null
                      and   r.validita_fine is null
                      and   ts.data_cancellazione is null
                      and   ts.validita_fine is null
                     )
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    strMessaggio:='Inserimento siac_r_movgest_ts. INIZIO.';
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

	insert into siac_r_movgest_ts
    (
     movgest_ts_a_id,
     movgest_ts_b_id,
     movgest_ts_importo,
     avav_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    (select fase.movgest_ts_a_id,
            fase.movgest_ts_b_id,
            fase.importo_vinc,
            fase.avav_id, -- 06.12.2017 Sofia jira siac-5276
            --dataInizioVal,
            clock_timestamp(), -- 12.01.2018 Sofia
            loginOperazione||'_APE_VINC@'||fase.fase_bil_gest_ape_vinc_id::varchar, -- 06.12.2017 Sofia jira siac-5276
            enteProprietarioId
     from fase_bil_t_gest_apertura_vincoli fase
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fl_elab='N'
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
    );
    -- 29.07.2019 Sofia SIAC-6702
    GET DIAGNOSTICS numeroVincoliIns = ROW_COUNT;



    strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_vincoli.';
    update  fase_bil_t_gest_apertura_vincoli fase
    set    movgest_ts_r_id=r.movgest_ts_r_id,
           fl_elab='S'
    from  siac_r_movgest_ts r
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   r.ente_proprietario_id=fase.ente_proprietario_id
    -- 06.12.2017 Sofia jira siac-5276
    and   r.login_operazione like '%_APE_VINC@%'
    and   substring(r.login_operazione , position('@' in r.login_operazione)+1)::integer=fase.fase_bil_gest_ape_vinc_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;


    strMessaggio:='Inserimento siac_r_movgest_ts. FINE.';
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

    -- 26.06.2019 Sofia SIAC-6702 - inizio
 --   if numeroVincoliIns is not null then

    -- inserire i rec. di storico per le relazioni tra impegni(anno_bilancio) e accertamenti,
    -- che esistono in anno_bilancio -1  e non esistono in anno_bilancio
    -- verificare se farlo se il ribaltamento dei vincoli e andato bene
    strMessaggio:='Inserimento SIAC_R_MOVGEST_TS_STORICO_IMP_ACC. INIZIO.';
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

    insert into SIAC_R_MOVGEST_TS_STORICO_IMP_ACC
    (
        movgest_ts_id,
        movgest_anno_acc,
        movgest_numero_acc,
        movgest_subnumero_acc,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select query.movgest_ts_id,
           query.movgest_anno_acc,
           query.movgest_numero_acc,
           query.movgest_subnumero_acc,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    FROM
    (
    with
    impegni_cur as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           ts.movgest_ts_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='I'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    ),
    impegni_prec as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           mov_a.movgest_anno::integer movgest_anno_acc, mov_a.movgest_numero::integer movgest_numero_acc,
           ( case when tipots_a.movgest_ts_tipo_code='T' then 0 else ts_a.movgest_ts_code::integer end ) movgest_subnumero_acc,
           ts.movgest_ts_id movgest_ts_b_id,
           ts_a.movgest_ts_id movgest_ts_a_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_r_movgest_ts r,
         siac_t_movgest mov_a,siac_d_movgest_tipo tipo_a,siac_t_movgest_Ts ts_a,siac_d_movgest_ts_tipo tipots_a,
         siac_r_movgest_ts_stato rs_a,siac_d_movgest_stato stato_a
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='I'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   r.movgest_ts_b_id=ts.movgest_ts_id
    and   ts_a.movgest_ts_id=r.movgest_ts_a_id
    and   mov_a.movgest_id=ts_a.movgest_id
    and   tipots_a.movgest_ts_tipo_id=ts_a.movgest_ts_tipo_id
    and   tipo_a.movgest_tipo_id=mov_a.movgest_tipo_id
    and   tipo_a.movgest_tipo_code='A'
    and   mov_a.bil_id=bilancioPrecId
    and   rs_a.movgest_ts_id=ts_a.movgest_ts_id
    and   stato_a.movgest_stato_id=rs_a.movgest_stato_id
    and   stato_a.movgest_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   rs_a.data_cancellazione is null
    and   rs_a.validita_fine is null
    and   mov_a.data_cancellazione is null
    and   mov_a.validita_fine is null
    and   ts_a.data_cancellazione is null
    and   ts_a.validita_fine is null
    ),
    acc_cur as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           r.movgest_ts_a_id,
           r.movgest_ts_b_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_r_movgest_ts r
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   r.movgest_ts_a_id=ts.movgest_ts_id
    and   r.movgest_ts_b_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    )
    select distinct
           impegni_cur.movgest_ts_id,
           impegni_prec.movgest_anno_acc,
           impegni_prec.movgest_numero_acc,
           impegni_prec.movgest_subnumero_acc
    from impegni_cur, impegni_prec
    where impegni_cur.movgest_anno=impegni_prec.movgest_anno
    and   impegni_cur.movgest_numero=impegni_prec.movgest_numero
    and   impegni_cur.movgest_subnumero=impegni_prec.movgest_subnumero
    and   not exists
    (select 1
     from acc_cur
     where acc_cur.movgest_ts_b_id=impegni_cur.movgest_ts_id
     and   acc_cur.movgest_anno=impegni_prec.movgest_anno_acc
     and   acc_cur.movgest_numero=impegni_prec.movgest_numero_acc
     and   acc_cur.movgest_subnumero=impegni_prec.movgest_subnumero_acc )
     ) query
     where
     not exists
     (select 1
      from SIAC_R_MOVGEST_TS_STORICO_IMP_ACC rStorico
      where rStorico.ente_proprietario_id=enteProprietarioId
      and   rStorico.movgest_ts_id=query.movgest_ts_id
      and   rStorico.movgest_anno_acc=query.movgest_anno_acc
      and   rStorico.movgest_numero_acc=query.movgest_numero_acc
      and   rStorico.movgest_subnumero_acc=query.movgest_subnumero_acc
      and   rStorico.data_cancellazione is null
      and   rStorico.validita_fine is null);


      strMessaggio:='Inserimento SIAC_R_MOVGEST_TS_STORICO_IMP_ACC. FINE.';
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
 --  end if:
   -- 26.06.2019 Sofia SIAC-6702 - fine


    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_VINCOLI||' IN CORSO IN-2.'
    where fase_bil_elab_id=faseBilElabId;

    codResult:=null;
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
COST 100;       c o d R e s u l t : = n u l l ; 
 
         i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
         i n s e r t   i n t o   S I A C _ R _ M O V G E S T _ T S _ S T O R I C O _ I M P _ A C C 
 
         ( 
 
                 m o v g e s t _ t s _ i d , 
 
                 m o v g e s t _ a n n o _ a c c , 
 
                 m o v g e s t _ n u m e r o _ a c c , 
 
                 m o v g e s t _ s u b n u m e r o _ a c c , 
 
                 v a l i d i t a _ i n i z i o , 
 
                 l o g i n _ o p e r a z i o n e , 
 
                 e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         s e l e c t   q u e r y . m o v g e s t _ t s _ i d , 
 
                       q u e r y . m o v g e s t _ a n n o _ a c c , 
 
                       q u e r y . m o v g e s t _ n u m e r o _ a c c , 
 
                       q u e r y . m o v g e s t _ s u b n u m e r o _ a c c , 
 
                       c l o c k _ t i m e s t a m p ( ) , 
 
                       l o g i n O p e r a z i o n e , 
 
                       e n t e P r o p r i e t a r i o I d 
 
         F R O M 
 
         ( 
 
         w i t h 
 
         i m p e g n i _ c u r   a s 
 
         ( 
 
         s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r ,   m o v . m o v g e s t _ n u m e r o : : i n t e g e r , 
 
                       (   c a s e   w h e n   t i p o t s . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d   )   m o v g e s t _ s u b n u m e r o , 
 
                       t s . m o v g e s t _ t s _ i d 
 
         f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o , s i a c _ t _ m o v g e s t _ T s   t s , s i a c _ d _ m o v g e s t _ t s _ t i p o   t i p o t s , 
 
                   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o 
 
         w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       t i p o . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
         a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o . m o v g e s t _ t i p o _ i d 
 
         a n d       m o v . b i l _ i d = b i l a n c i o I d 
 
         a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
         a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
         a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e ! = ' A ' 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         i m p e g n i _ p r e c   a s 
 
         ( 
 
         s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r ,   m o v . m o v g e s t _ n u m e r o : : i n t e g e r , 
 
                       (   c a s e   w h e n   t i p o t s . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d   )   m o v g e s t _ s u b n u m e r o , 
 
                       m o v _ a . m o v g e s t _ a n n o : : i n t e g e r   m o v g e s t _ a n n o _ a c c ,   m o v _ a . m o v g e s t _ n u m e r o : : i n t e g e r   m o v g e s t _ n u m e r o _ a c c , 
 
                       (   c a s e   w h e n   t i p o t s _ a . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s _ a . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d   )   m o v g e s t _ s u b n u m e r o _ a c c , 
 
                       t s . m o v g e s t _ t s _ i d   m o v g e s t _ t s _ b _ i d , 
 
                       t s _ a . m o v g e s t _ t s _ i d   m o v g e s t _ t s _ a _ i d 
 
         f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o , s i a c _ t _ m o v g e s t _ T s   t s , s i a c _ d _ m o v g e s t _ t s _ t i p o   t i p o t s , 
 
                   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                   s i a c _ r _ m o v g e s t _ t s   r , 
 
                   s i a c _ t _ m o v g e s t   m o v _ a , s i a c _ d _ m o v g e s t _ t i p o   t i p o _ a , s i a c _ t _ m o v g e s t _ T s   t s _ a , s i a c _ d _ m o v g e s t _ t s _ t i p o   t i p o t s _ a , 
 
                   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s _ a , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o _ a 
 
         w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       t i p o . m o v g e s t _ t i p o _ c o d e = ' I ' 
 
         a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o . m o v g e s t _ t i p o _ i d 
 
         a n d       m o v . b i l _ i d = b i l a n c i o P r e c I d 
 
         a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
         a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
         a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e ! = ' A ' 
 
         a n d       r . m o v g e s t _ t s _ b _ i d = t s . m o v g e s t _ t s _ i d 
 
         a n d       t s _ a . m o v g e s t _ t s _ i d = r . m o v g e s t _ t s _ a _ i d 
 
         a n d       m o v _ a . m o v g e s t _ i d = t s _ a . m o v g e s t _ i d 
 
         a n d       t i p o t s _ a . m o v g e s t _ t s _ t i p o _ i d = t s _ a . m o v g e s t _ t s _ t i p o _ i d 
 
         a n d       t i p o _ a . m o v g e s t _ t i p o _ i d = m o v _ a . m o v g e s t _ t i p o _ i d 
 
         a n d       t i p o _ a . m o v g e s t _ t i p o _ c o d e = ' A ' 
 
         a n d       m o v _ a . b i l _ i d = b i l a n c i o P r e c I d 
 
         a n d       r s _ a . m o v g e s t _ t s _ i d = t s _ a . m o v g e s t _ t s _ i d 
 
         a n d       s t a t o _ a . m o v g e s t _ s t a t o _ i d = r s _ a . m o v g e s t _ s t a t o _ i d 
 
         a n d       s t a t o _ a . m o v g e s t _ s t a t o _ c o d e ! = ' A ' 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r s _ a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s _ a . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       m o v _ a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       m o v _ a . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       t s _ a . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       t s _ a . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) , 
 
         a c c _ c u r   a s 
 
         ( 
 
         s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r ,   m o v . m o v g e s t _ n u m e r o : : i n t e g e r , 
 
                       (   c a s e   w h e n   t i p o t s . m o v g e s t _ t s _ t i p o _ c o d e = ' T '   t h e n   0   e l s e   t s . m o v g e s t _ t s _ c o d e : : i n t e g e r   e n d   )   m o v g e s t _ s u b n u m e r o , 
 
                       r . m o v g e s t _ t s _ a _ i d , 
 
                       r . m o v g e s t _ t s _ b _ i d 
 
         f r o m   s i a c _ t _ m o v g e s t   m o v , s i a c _ d _ m o v g e s t _ t i p o   t i p o , s i a c _ t _ m o v g e s t _ T s   t s , s i a c _ d _ m o v g e s t _ t s _ t i p o   t i p o t s , 
 
                   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s , s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                   s i a c _ r _ m o v g e s t _ t s   r 
 
         w h e r e   t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         a n d       t i p o . m o v g e s t _ t i p o _ c o d e = ' A ' 
 
         a n d       m o v . m o v g e s t _ t i p o _ i d = t i p o . m o v g e s t _ t i p o _ i d 
 
         a n d       m o v . b i l _ i d = b i l a n c i o I d 
 
         a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
         a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
         a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
         a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e ! = ' A ' 
 
         a n d       r . m o v g e s t _ t s _ a _ i d = t s . m o v g e s t _ t s _ i d 
 
         a n d       r . m o v g e s t _ t s _ b _ i d   i s   n o t   n u l l 
 
         a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
         a n d       r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) 
 
         s e l e c t   d i s t i n c t 
 
                       i m p e g n i _ c u r . m o v g e s t _ t s _ i d , 
 
                       i m p e g n i _ p r e c . m o v g e s t _ a n n o _ a c c , 
 
                       i m p e g n i _ p r e c . m o v g e s t _ n u m e r o _ a c c , 
 
                       i m p e g n i _ p r e c . m o v g e s t _ s u b n u m e r o _ a c c 
 
         f r o m   i m p e g n i _ c u r ,   i m p e g n i _ p r e c 
 
         w h e r e   i m p e g n i _ c u r . m o v g e s t _ a n n o = i m p e g n i _ p r e c . m o v g e s t _ a n n o 
 
         a n d       i m p e g n i _ c u r . m o v g e s t _ n u m e r o = i m p e g n i _ p r e c . m o v g e s t _ n u m e r o 
 
         a n d       i m p e g n i _ c u r . m o v g e s t _ s u b n u m e r o = i m p e g n i _ p r e c . m o v g e s t _ s u b n u m e r o 
 
         a n d       n o t   e x i s t s 
 
         ( s e l e c t   1 
 
           f r o m   a c c _ c u r 
 
           w h e r e   a c c _ c u r . m o v g e s t _ t s _ b _ i d = i m p e g n i _ c u r . m o v g e s t _ t s _ i d 
 
           a n d       a c c _ c u r . m o v g e s t _ a n n o = i m p e g n i _ p r e c . m o v g e s t _ a n n o _ a c c 
 
           a n d       a c c _ c u r . m o v g e s t _ n u m e r o = i m p e g n i _ p r e c . m o v g e s t _ n u m e r o _ a c c 
 
           a n d       a c c _ c u r . m o v g e s t _ s u b n u m e r o = i m p e g n i _ p r e c . m o v g e s t _ s u b n u m e r o _ a c c   ) 
 
           )   q u e r y 
 
           w h e r e 
 
           n o t   e x i s t s 
 
           ( s e l e c t   1 
 
             f r o m   S I A C _ R _ M O V G E S T _ T S _ S T O R I C O _ I M P _ A C C   r S t o r i c o 
 
             w h e r e   r S t o r i c o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
             a n d       r S t o r i c o . m o v g e s t _ t s _ i d = q u e r y . m o v g e s t _ t s _ i d 
 
             a n d       r S t o r i c o . m o v g e s t _ a n n o _ a c c = q u e r y . m o v g e s t _ a n n o _ a c c 
 
             a n d       r S t o r i c o . m o v g e s t _ n u m e r o _ a c c = q u e r y . m o v g e s t _ n u m e r o _ a c c 
 
             a n d       r S t o r i c o . m o v g e s t _ s u b n u m e r o _ a c c = q u e r y . m o v g e s t _ s u b n u m e r o _ a c c 
 
             a n d       r S t o r i c o . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       r S t o r i c o . v a l i d i t a _ f i n e   i s   n u l l ) ; 
 
 
 
 
 
             s t r M e s s a g g i o : = ' I n s e r i m e n t o   S I A C _ R _ M O V G E S T _ T S _ S T O R I C O _ I M P _ A C C .   F I N E . ' ; 
 
             c o d R e s u l t : = n u l l ; 
 
             i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
             ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
               v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
             ) 
 
             v a l u e s 
 
             ( f a s e B i l E l a b I d , s t r M e s s a g g i o , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
             r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
             i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                     r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
             e n d   i f ; 
 
   - -     e n d   i f : 
 
       - -   2 6 . 0 6 . 2 0 1 9   S o f i a   S I A C - 6 7 0 2   -   f i n e 
 
 
 
 
 
         s t r M e s s a g g i o : = ' A g g i o r n a m e n t o   s t a t o   f a s e   b i l a n c i o   I N - 2 . ' ; 
 
         u p d a t e   f a s e _ b i l _ t _ e l a b o r a z i o n e 
 
         s e t   f a s e _ b i l _ e l a b _ e s i t o = ' I N - 2 ' , 
 
                 f a s e _ b i l _ e l a b _ e s i t o _ m s g = ' E L A B O R A Z I O N E   F A S E   B I L A N C I O   ' | | A P E _ G E S T _ V I N C O L I | | '   I N   C O R S O   I N - 2 . ' 
 
         w h e r e   f a s e _ b i l _ e l a b _ i d = f a s e B i l E l a b I d ; 
 
 
 
         c o d R e s u l t : = n u l l ; 
 
 	 i n s e r t   i n t o   f a s e _ b i l _ t _ e l a b o r a z i o n e _ l o g 
 
         ( f a s e _ b i l _ e l a b _ i d , f a s e _ b i l _ e l a b _ l o g _ o p e r a z i o n e , 
 
           v a l i d i t a _ i n i z i o ,   l o g i n _ o p e r a z i o n e ,   e n t e _ p r o p r i e t a r i o _ i d 
 
         ) 
 
         v a l u e s 
 
         ( f a s e B i l E l a b I d , s t r M e s s a g g i o F i n a l e | | '   F I N E . ' , c l o c k _ t i m e s t a m p ( ) , l o g i n O p e r a z i o n e , e n t e P r o p r i e t a r i o I d ) 
 
         r e t u r n i n g   f a s e _ b i l _ e l a b _ l o g _ i d   i n t o   c o d R e s u l t ; 
 
 
 
         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
         	 r a i s e   e x c e p t i o n   '   E r r o r e   i n   i n s e r i m e n t o   L O G . ' ; 
 
         e n d   i f ; 
 
 
 
 
 
         c o d i c e R i s u l t a t o : = 0 ; 
 
         m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | '   F I N E ' ; 
 
         r e t u r n ; 
 
 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
         	 r a i s e   n o t i c e   ' %   %   E R R O R E   :   % ' , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E   : ' | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
 
 
 
 	 w h e n   n o _ d a t a _ f o u n d   T H E N 
 
 	 	 r a i s e   n o t i c e   '   %   %   N e s s u n   e l e m e n t o   t r o v a t o . '   , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' N e s s u n   e l e m e n t o   t r o v a t o . '   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
 	 	 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
 	 	 r a i s e   n o t i c e   ' %   %   E r r o r e   D B   %   % ' , s t r M e s s a g g i o F i n a l e , c o a l e s c e ( s t r M e s s a g g i o , ' ' ) , S Q L S T A T E , 
 
 	                 	 s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 ) ; 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E r r o r e   D B   ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 r e t u r n ; 
 
 
 
 E N D ; 
 
 $ b o d y $ 
 
 L A N G U A G E   ' p l p g s q l ' 
 
 V O L A T I L E 
 
 C A L L E D   O N   N U L L   I N P U T 
 
 S E C U R I T Y   I N V O K E R 
 
 C O S T   1 0 0 ; 