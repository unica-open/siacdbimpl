/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- 05.12.2016 Sofia fnc aggiornamento utilizzabile accertamento
--- accertamenti residui e pluriennali vincolati
CREATE OR REPLACE FUNCTION fnc_siac_aggiorna_utilizzabile_acc (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio       VARCHAR(1500):='';
    strMessaggioTemp   VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';
	dataInizioVal      timestamp:=null;
	codResult          integer:=null;

    ACC_MOVGEST_TIPO  CONSTANT varchar:='A';
    A_MOVGEST_STATO   CONSTANT varchar:='A';
    U_MOVGEST_TS_IMPORTO CONSTANT varchar:='U';

    bilancioPrecId    integer:=null;
    bilancioId        integer:=null;
  	tipoMovGestAId    integer:=null;
    tipoMovGestStatoAId    integer:=null;
    tipoMovGestTsDetTipoUId integer:=null;

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Aggiornamento importo utilizzabile accertamenti.'
                        ||'Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Lettura bilancioId per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id into strict bilancioPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;

    strMessaggio:='Lettura bilancioId per annoBilancio='||(annoBilancio)::varchar||'.';
    select bil.bil_id into strict bilancioId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;

    strMessaggio:='Lettura tipoMovGestId per tipoMovGest='||ACC_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into strict tipoMovGestAId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO;

    strMessaggio:='Lettura tipoMovGestStatoAId per tipoMovGestStatoA='||A_MOVGEST_STATO||'.';
    select stato.movgest_stato_id into strict tipoMovGestStatoAId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.movgest_stato_code=A_MOVGEST_STATO;

    strMessaggio:='Lettura tipoMovGestTsDetTipoUId per tipoMovGestTsDetTipoU='||U_MOVGEST_TS_IMPORTO||'.';
    select tipo.movgest_ts_det_tipo_id into strict tipoMovGestTsDetTipoUId
    from siac_d_movgest_ts_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_ts_det_tipo_code=U_MOVGEST_TS_IMPORTO;


  /* 06.12.2017 Sofia siac-5276
    strMessaggio:='Aggiornmento.';
    update siac_t_movgest_ts_det detacc
    set    movgest_ts_det_importo=Q.utilizzabile_prec - (Q.importo_vincolo_new-Q.importo_vincolo_prec),
           data_modifica=dataInizioVal,
           login_operazione=detacc.login_operazione||'-'||loginOperazione
 	from siac_t_movgest acc,
	     siac_t_movgest_ts tsacc,siac_r_movgest_ts_stato rsacc,
      ( with
		vincoliprec as
		( select r.movgest_ts_a_id , r.movgest_ts_b_id ,
        		 ma.movgest_anno::integer anno_accertamento,
		         ma.movgest_numero::integer numero_accertamento,
		         tsa.movgest_ts_code::integer numero_subaccertamento,
		         mb.movgest_anno::integer anno_impegno,
		         mb.movgest_numero::integer numero_impegno,
		         tsb.movgest_ts_code::integer numero_subimpegno,
		         r.movgest_ts_importo
		  from siac_r_movgest_ts r,
		       siac_t_movgest ma, siac_t_movgest_ts tsa,siac_r_movgest_ts_stato ra,
		       siac_t_movgest mb, siac_t_movgest_ts tsb,siac_r_movgest_ts_stato rb
		  where r.ente_proprietario_id=enteProprietarioId
          and   tsa.movgest_ts_id=r.movgest_ts_a_id
  		  and   ma.movgest_id=tsa.movgest_id
		  and   ma.bil_id=bilancioPrecId
		  and   tsb.movgest_ts_id=r.movgest_ts_b_id
		  and   mb.movgest_id=tsb.movgest_id
		  and   mb.bil_id=bilancioPrecId
		  and   ra.movgest_ts_id=tsa.movgest_ts_id
		  and   ra.movgest_stato_id!=tipoMovGestStatoAId
		  and   ra.data_cancellazione is null
		  and   ra.validita_fine is null
		  and   rb.movgest_ts_id=tsb.movgest_ts_id
		  and   rb.movgest_stato_id!=tipoMovGestStatoAId
		  and   rb.data_cancellazione is null
		  and   rb.validita_fine is null
		  and   r.data_cancellazione is null
		  and   r.validita_fine is null
		  and   ma.data_cancellazione is null
		  and   ma.validita_fine is null
		  and   tsa.data_cancellazione is null
		  and   tsa.validita_fine is null
		  and   mb.data_cancellazione is null
		  and   mb.validita_fine is null
		  and   tsb.data_cancellazione is null
		  and   tsb.validita_fine is null
		),
		vincolinew as
		( select r.movgest_ts_a_id , r.movgest_ts_b_id ,
        		 ma.movgest_anno::integer anno_accertamento,
		         ma.movgest_numero::integer numero_accertamento,
		         tsa.movgest_ts_code::integer numero_subaccertamento,
		         mb.movgest_anno::integer anno_impegno,
		         mb.movgest_numero::integer numero_impegno,
		         tsb.movgest_ts_code::integer numero_subimpegno,
		         r.movgest_ts_importo
		  from siac_r_movgest_ts r,
		       siac_t_movgest ma, siac_t_movgest_ts tsa,siac_r_movgest_ts_stato ra,
		       siac_t_movgest mb, siac_t_movgest_ts tsb,siac_r_movgest_ts_stato rb
		  where r.ente_proprietario_id=enteProprietarioId
		  and   tsa.movgest_ts_id=r.movgest_ts_a_id
		  and   ma.movgest_id=tsa.movgest_id
		  and   ma.bil_id=bilancioId
		  and   tsb.movgest_ts_id=r.movgest_ts_b_id
		  and   mb.movgest_id=tsb.movgest_id
		  and   mb.bil_id=bilancioId
		  and   ra.movgest_ts_id=tsa.movgest_ts_id
		  and   ra.movgest_stato_id!=tipoMovGestStatoAId
		  and   ra.data_cancellazione is null
		  and   ra.validita_fine is null
		  and   rb.movgest_ts_id=tsb.movgest_ts_id
		  and   rb.movgest_stato_id!=tipoMovGestStatoAId
		  and   rb.data_cancellazione is null
		  and   rb.validita_fine is null
		  and   r.data_cancellazione is null
		  and   r.validita_fine is null
		  and   ma.data_cancellazione is null
		  and   ma.validita_fine is null
		  and   tsa.data_cancellazione is null
		  and   tsa.validita_fine is null
		  and   mb.data_cancellazione is null
		  and   mb.validita_fine is null
		  and   tsb.data_cancellazione is null
		  and   tsb.validita_fine is null
		),
		accvincprec as
		(select tsacc.movgest_ts_id , detacc.movgest_ts_det_id, detacc.movgest_ts_det_importo
		 from siac_t_movgest acc,
		      siac_t_movgest_ts tsacc,siac_r_movgest_ts_stato rsacc,
		      siac_t_movgest_ts_det detacc
		 where acc.bil_id=bilancioPrecId
		 and   acc.movgest_tipo_id=tipoMovGestAId
		 and   tsacc.movgest_id=acc.movgest_id
		 and   rsacc.movgest_ts_id=tsacc.movgest_ts_id
		 and   rsacc.movgest_stato_id!=tipoMovGestStatoAId
		 and   detacc.movgest_ts_id=tsacc.movgest_ts_id
		 and   detacc.movgest_ts_det_tipo_id=tipoMovGestTsDetTipoUId
		 and   exists (select 1 from siac_r_movgest_ts racc
        		       where racc.movgest_ts_a_id=tsacc.movgest_ts_id
		               and   racc.data_cancellazione is null
        		       and   racc.validita_fine is null )
		 and rsacc.data_cancellazione is null
		 and rsacc.validita_fine is null
		 and acc.data_cancellazione is null
		 and acc.validita_fine is null
		 and tsacc.data_cancellazione is null
		 and tsacc.validita_fine is null
		 and detacc.data_cancellazione is null
		 and detacc.validita_fine is null
		)
	(select vincolinew.anno_accertamento, vincolinew.numero_accertamento,vincolinew.numero_subaccertamento,
    	    coalesce(sum(coalesce(vincoliprec.movgest_ts_importo,0)),0) importo_vincolo_prec,
        	coalesce(sum(vincolinew.movgest_ts_importo),0) importo_vincolo_new,
	        accvincprec.movgest_ts_det_id,
            accvincprec.movgest_ts_det_importo utilizzabile_prec
      from    vincolinew left outer join ( vincoliprec join accvincprec on (accvincprec.movgest_ts_id=vincoliprec.movgest_ts_a_id))
               on  ( vincolinew.anno_accertamento=vincoliprec.anno_accertamento
                 and vincolinew.numero_accertamento=vincoliprec.numero_accertamento
                 and vincolinew.numero_subaccertamento=vincoliprec.numero_subaccertamento
                 and vincolinew.anno_impegno=vincoliprec.anno_impegno
                 and vincolinew.numero_impegno=vincoliprec.numero_impegno
                 and vincolinew.numero_subimpegno=vincoliprec.numero_subimpegno
                   )
         group by vincolinew.anno_accertamento, vincolinew.numero_accertamento,vincolinew.numero_subaccertamento,
                   accvincprec.movgest_ts_det_importo,accvincprec.movgest_ts_det_id
     )
    ) Q
	where acc.bil_id=bilancioId
	and   acc.movgest_tipo_id=tipoMovGestAId
	and   tsacc.movgest_id=acc.movgest_id
	and   rsacc.movgest_ts_id=tsacc.movgest_ts_id
	and   rsacc.movgest_stato_id!=tipoMovGestStatoAId
	and   detacc.movgest_ts_id=tsacc.movgest_ts_id
	and   detacc.movgest_ts_det_tipo_id=tipoMovGestTsDetTipoUId
	and   acc.movgest_anno::integer=Q.anno_accertamento
	and   acc.movgest_numero::integer=Q.numero_accertamento
	and   tsacc.movgest_ts_code::integer=Q.numero_subaccertamento
	and   exists (select 1 from siac_r_movgest_ts racc
    	           where racc.movgest_ts_a_id=tsacc.movgest_ts_id
        	       and   racc.data_cancellazione is null
            	   and   racc.validita_fine is null )
	and rsacc.data_cancellazione is null
	and rsacc.validita_fine is null
	and acc.data_cancellazione is null
	and acc.validita_fine is null
	and tsacc.data_cancellazione is null
	and tsacc.validita_fine is null
	and detacc.data_cancellazione is null
	and detacc.validita_fine is null;
*/
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