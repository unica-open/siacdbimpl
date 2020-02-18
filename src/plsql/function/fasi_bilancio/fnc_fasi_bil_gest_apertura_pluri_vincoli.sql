/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_pluri_vincoli(
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
    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';

    bilancioPrecId    integer:=null;

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente.'
                        ||'Anno bilancio='||annoBilancio::varchar
                        ||'. Ribaltamento vincoli'
                        ||'. Fase Elaborazione Id='||faseBilElabId||'.';

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
      raise exception ' Nessun movimento per vincolo da creare.';
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


    strMessaggio:='Verifica esistenza vincoli su movimenti da ribaltare.';
    codResult:=null;
	select 1 into codResult
    from siac_r_movgest_ts r,
         siac_t_movgest ma,siac_t_movgest_ts tsa,
         siac_t_movgest mb,siac_t_movgest_ts tsb
    where ma.ente_proprietario_id=enteProprietarioId
    and   ma.bil_id=bilancioPrecId
    and   tsa.movgest_id=ma.movgest_id
    and   mb.ente_proprietario_id=enteProprietarioId
    and   mb.bil_id=bilancioPrecId
    and   tsb.movgest_id=mb.movgest_id
    and   r.movgest_ts_a_id=tsa.movgest_ts_id
    and   r.movgest_ts_b_id=tsb.movgest_ts_id
    and   ma.data_cancellazione is null
    and   ma.validita_fine is null
    and   mb.data_cancellazione is null
    and   mb.validita_fine is null
    and   tsa.data_cancellazione is null
    and   tsa.validita_fine is null
    and   tsb.data_cancellazione is null
    and   tsb.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   exists (select 1 from fase_bil_t_gest_apertura_pluri fase
   				  where fase.fase_bil_elab_id=faseBilElabId
                  and   fase.movgest_orig_id=ma.movgest_id
                  and   fase.movgest_tipo='ACC'
                  and   fase.movgest_id is not null
                  and   fase.fl_elab='S'
			      and   fase.data_cancellazione is null
			      and   fase.validita_fine is null)
    and   exists (select 1 from fase_bil_t_gest_apertura_pluri fase
   				  where fase.fase_bil_elab_id=faseBilElabId
                  and   fase.movgest_orig_id=mb.movgest_id
                  and   fase.movgest_tipo='IMP'
                  and   fase.movgest_id is not null
                  and   fase.fl_elab='S'
			      and   fase.data_cancellazione is null
			      and   fase.validita_fine is null);

    if codResult is not null then

	insert into siac_r_movgest_ts
    (
     movgest_ts_a_id,
     movgest_ts_b_id,
     movgest_ts_importo,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    (
     with
     vincoliAcc as
	 (select m.movgest_anno , m.movgest_numero ,
  	         m.movgest_id movgest_orig_id, ts.movgest_ts_id movgest_ts_orig_id,
             fase.movgest_id, fase.movgest_ts_id
	  from siac_t_movgest m, siac_t_movgest_ts ts,siac_d_movgest_tipo tipo,
           fase_bil_t_gest_apertura_pluri fase
	  where m.ente_proprietario_id=enteProprietarioId
      and   m.bil_id=bilancioPrecId
      and   ts.movgest_id=m.movgest_id
      and   tipo.movgest_tipo_id=m.movgest_tipo_id
	  and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
	  and   fase.fase_bil_elab_id=faseBilElabId
	  and   fase.movgest_orig_id=m.movgest_id
	  and   fase.movgest_orig_ts_id=ts.movgest_ts_id
	  and   fase.movgest_tipo=ACC_MOVGEST
	  and   fase.movgest_id is not null
	  and   fase.movgest_ts_id is not null
	  and   fase.fl_elab='S'
	  and   exists (Select 1 from siac_r_movgest_ts r
    	            where r.movgest_ts_a_id=ts.movgest_ts_id
        	        and   r.data_cancellazione is null
            	    and   r.validita_fine is null)
	  and   m.data_cancellazione is null
	  and   m.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	  and   fase.data_cancellazione is null
	  and   fase.validita_fine is null
	 ),
	 vincoliImp as
	 (
	  select m.movgest_anno , m.movgest_numero ,
 	  		 m.movgest_id movgest_orig_id, ts.movgest_ts_id movgest_ts_orig_id,
	        fase.movgest_id, fase.movgest_ts_id
	  from siac_t_movgest m, siac_t_movgest_ts ts,siac_d_movgest_tipo tipo,
    	   fase_bil_t_gest_apertura_pluri fase
	  where m.ente_proprietario_id=enteProprietarioId
	  and   m.bil_id=bilancioPrecId
	  and   ts.movgest_id=m.movgest_id
	  and   tipo.movgest_tipo_id=m.movgest_tipo_id
	  and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
	  and   fase.fase_bil_elab_id=faseBilElabId
	  and   fase.movgest_orig_id=m.movgest_id
	  and   fase.movgest_orig_ts_id=ts.movgest_ts_id
	  and   fase.movgest_tipo=IMP_MOVGEST
	  and   fase.movgest_id is not null
	  and   fase.movgest_ts_id is not null
	  and   fase.fl_elab='S'
	  and   exists (Select 1 from siac_r_movgest_ts r
    	            where r.movgest_ts_b_id=ts.movgest_ts_id
        	        and   r.data_cancellazione is null
            	    and   r.validita_fine is null)
	  and   m.data_cancellazione is null
	  and   m.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	  and   fase.data_cancellazione is null
	  and   fase.validita_fine is null
 	)
 	(
	 select
      acc.movgest_ts_id,
	  imp.movgest_ts_id,
      r.movgest_ts_importo,
      dataInizioVal,
      loginOperazione,
      enteProprietarioId
     from vincoliAcc acc, vincoliImp imp, siac_r_movgest_ts r
     where r.ente_proprietario_id=enteProprietarioId
     and   r.movgest_ts_a_id=acc.movgest_ts_orig_id
     and   r.movgest_ts_b_id=imp.movgest_ts_orig_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null
 	)
   );

   end if;



    strMessaggio:='Aggiornamento stato fase bilancio IN-3.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-3',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-3.'
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
COST 100;