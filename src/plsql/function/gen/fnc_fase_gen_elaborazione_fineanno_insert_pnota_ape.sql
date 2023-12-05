/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_fase_gen_elaborazione_fineanno_insert_pnota_ape (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  fasebilelabid integer,
  bilancioid integer,
  classeconto varchar,
  ordineelabchidet integer,
  ordineelabapedet integer,
  tipooperazionegen varchar,
  out fasebilelabdetretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabDetId     integer:=null;


	dataInizioVal     timestamp:=null;

	pnStatoProvId      integer:=null;
    ambitoId           integer:=null;
    pnotaId            integer:=null;
    movepId            integer:=null;



    AMBITO_FIN        CONSTANT varchar:='AMBITO_FIN'; -- ordine attivo

    SEGNO_DARE      CONSTANT varchar:='DARE';
    SEGNO_DARE_MOV  CONSTANT varchar:='Dare';
    SEGNO_AVERE     CONSTANT varchar:='AVERE';
    SEGNO_AVERE_MOV CONSTANT varchar:='Avere';

    PNOTA_STATO_PROV   CONSTANT varchar:='P';

    LOG_OP_FINE       CONSTANT varchar:='_gen_chiape';


BEGIN
	faseBilElabDetRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= (annoBilancio::varchar||'-01-01')::timestamp;

	strMessaggioFinale:='Inserimento prima nota e movimenti per '||tipoOperazioneGen||' classe conto='||classeConto||'  bilancioId='||bilancioId
      ||'. Inizio step '||ordineElabAPEDet||' .';

    codResult:=null;
	insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    strMessaggio:='Lettura identificativo stato prima nota '||PNOTA_STATO_PROV||'.';
    select stato.pnota_stato_id into pnStatoProvId
    from siac_d_prima_nota_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.pnota_stato_code=PNOTA_STATO_PROV
    and   stato.data_cancellazione is null
    and   stato.validita_fine is null;
    if pnStatoProvId is null then
    	raise exception ' Identificativo non reperito.';
    end if;

    strMessaggio:='Lettura identificativo ambito '||AMBITO_FIN||'.';
    select a.ambito_id into ambitoId
    from siac_d_ambito a
    where a.ente_proprietario_id=enteProprietarioId
    and   a.ambito_code=AMBITO_FIN
    and   a.data_cancellazione is null
    and   a.validita_fine is null;
    if ambitoId is null then
    	raise exception ' Identificativo non reperito.';
    end if;

    codResult:=null;
    strMessaggio:='Verifica esistenza progressivi prima nota [siac_t_prima_nota_num] per annoBilancio='||annoBilancio||'.';
	select num.pnota_num_id into codResult
    from  siac_t_prima_nota_num num
	where num.ente_proprietario_id=enteProprietarioId
	and   num.pnota_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   num.validita_fine is null;
    if codResult is null then
        strMessaggio:='Inserimento progressivi prima nota [siac_t_prima_nota_num] per annoBilancio='||annoBilancio||'.';
    	insert into siac_t_prima_nota_num
        (pnota_anno,
  		 pnota_numero,
         ambito_id,
		 validita_inizio,
		 ente_proprietario_id,
		 login_operazione
        )
        values
        (
         annoBilancio::varchar,
         0,
         ambitoId,
         dataInizioVal,
         enteProprietarioId,
		 loginOperazione||LOG_OP_FINE
        )
        returning pnota_num_id into codResult;
        if codResult is null then
        	raise exception ' Errore in fase di inserimento.';
        end if;

    end if;

    codResult:=null;
    strMessaggio:='Verifica esistenza progressivi prima nota [siac_t_mov_ep_num] per annoBilancio='||annoBilancio||'.';

    select num.movep_num_id into codResult
    from siac_t_mov_ep_num num
	where num.ente_proprietario_id=enteProprietarioId
	--and   num.movep_anno::integer=annoBilancio
    and   num.movep_anno=annoBilancio
    and   num.data_cancellazione is null
    and   num.validita_fine is null;
    if codResult is null then
  	    strMessaggio:='Inserimento progressivi prima nota [siac_t_mov_ep_num] per annoBilancio='||annoBilancio||'.';
    	insert into siac_t_mov_ep_num
        (movep_anno,
	     movep_code,
   		 ambito_id,
		 validita_inizio,
		 ente_proprietario_id,
		 login_operazione
        )
        values
        (
         --annoBilancio::varchar,
         annoBilancio,
         0,
         ambitoId,
         dataInizioVal,
         enteProprietarioId,
		 loginOperazione||LOG_OP_FINE
        )
        returning movep_num_id into codResult;
        if codResult is null then
	       	raise exception ' Errore in fase di inserimento.';
        end if;
    end if;

	strMessaggio:='Inserimento step '||ordineElabAPEDet||' elaborazione [fase_gen_t_elaborazione_fineanno_det].';
	insert into fase_gen_t_elaborazione_fineanno_det
    (fase_gen_elab_id,
	 fase_gen_elab_tipo_id,
	 fase_gen_det_elab_esito,
	 fase_gen_det_elab_esito_msg,
	 validita_inizio,
	 login_operazione,
	 ente_proprietario_id
	)
	(select fase.fase_gen_elab_id,
            fasetipo.fase_gen_elab_tipo_id,
            'IN',
            'ELABORAZIONE SCRITTURE GEN DI CHIUSURA/APERTURA FINE ANNO - INSERIMENTO '||tipoOperazioneGen||'. CONTI '||classeConto||' - INIZIO',
            clock_timestamp(),
            loginOperazione||LOG_OP_FINE,
        	fase.ente_proprietario_id
	from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo fasetipo
	where fase.fase_gen_elab_id=faseBilElabId
	and   fase.fase_gen_elab_esito like 'IN%'
	and   fasetipo.ente_proprietario_id=enteProprietarioId
	and   fasetipo.ordine=ordineElabApeDet
	and   fase.data_cancellazione is null
	and   fase.validita_fine is null)
    returning fase_gen_elab_det_id into faseBilElabDetId;
    if faseBilElabDetId is null then
    	raise exception ' Inserimento non effettuato.';
    end if;

    codResult:=null;
    strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||classeConto||' - INIZIO.';
	insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||classeConto||' [siac_t_prima_nota].';
	insert into siac_t_prima_nota
	(pnota_numero,
	 pnota_desc,
	 pnota_data,
	 bil_id,
	 causale_ep_tipo_id,
	 validita_inizio,
	 ente_proprietario_id,
	 login_operazione,
	 login_creazione,
	 ambito_id)
	 (select num.pnota_numero+1,
     	     fasetipo.fase_gen_elab_tipo_desc,
	         dataElaborazione,
    	     bilancioId,
	         c.causale_ep_tipo_id,
	         dataInizioVal,
	         enteProprietarioId,
	         loginOperazione||LOG_OP_FINE,
	         loginOperazione||LOG_OP_FINE,
	         ambitoId
 	 from fase_gen_t_elaborazione_fineanno_det fasedet,
	      fase_gen_d_elaborazione_fineanno_tipo fasetipo,
	      siac_t_prima_nota_num num, siac_t_causale_ep c
	 where fasedet.fase_gen_elab_det_id=faseBilElabDetId
	 and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
	 and   num.ente_proprietario_id=enteProprietarioId
	 and   num.pnota_anno::integer=annoBilancio
	 and   c.causale_ep_id=fasetipo.causale_ep_id
	 and   c.data_cancellazione is null
	 and   c.validita_fine is null
    )
    returning pnota_id into pnotaId;
    if pnotaId is null then
    	raise exception ' Inserimento non effettuato.';
    end if;

    strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||classeConto||' aggiornamento progressivo [siac_t_prima_nota_num].';
	update siac_t_prima_nota_num num
	set pnota_numero=num.pnota_numero+1,
        data_modifica=clock_timestamp(),
        login_operazione=loginOperazione||LOG_OP_FINE
	where num.ente_proprietario_id=enteProprietarioId
	and   num.pnota_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   num.validita_fine is null;

    codResult:=null;
   	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||classeConto||' [siac_r_prima_nota_stato].';
	insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;
	if codResult is null then
    	raise exception ' Inserimento log non effettuato';
    end if;

    codResult:=null;
    insert into siac_r_prima_nota_stato
	( pnota_id,
	  pnota_stato_id,
	  validita_inizio,
	  login_operazione,
	  ente_proprietario_id
	)
	values
    (pnotaId,
     pnStatoProvId,
     dataInizioVal,
     loginOperazione||LOG_OP_FINE,
     enteProprietarioId
    )
    returning pnota_stato_r_id into codResult;
    if codResult is null then
    	raise exception ' Inserimento non effettuato.';
    end if;

    codResult:=null;
	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||classeConto||' [siac_t_mov_ep].';
	insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;
	if codResult is null then
    	raise exception ' Inserimento log non effettuato';
    end if;


    insert into siac_t_mov_ep
	( movep_code,
	  movep_desc,
	  causale_ep_id,
	  regep_id,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione,
	  ambito_id
	)
	(select num.movep_code+1,
     	    fasetipo.fase_gen_elab_tipo_desc,
	        fasetipo.causale_ep_id,
	        pnotaId,
	        dataInizioVal,
    	    enteProprietarioId,
	        loginOperazione||LOG_OP_FINE,
    	    ambitoId
	 from fase_gen_t_elaborazione_fineanno_det fasedet,
     	  fase_gen_d_elaborazione_fineanno_tipo fasetipo,
	      siac_t_mov_ep_num num
	 where fasedet.fase_gen_elab_det_id=faseBilElabDetId
	 and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
	 and   fasetipo.ente_proprietario_id=enteProprietarioId
	 and   fasetipo.ordine=ordineElabApeDet
	 and   num.ente_proprietario_id=enteProprietarioId
	 --and   num.movep_anno::integer=annoBilancio
     and   num.movep_anno=annoBilancio
    )
    returning movep_id into movepId;
    if movepId is null then
    	raise exception ' Inserimento non effettuato.';
    end if;

	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||classeConto||' aggiornamento progressivo [siac_t_mov_ep_num].';
	update siac_t_mov_ep_num num
	set movep_code=num.movep_code+1,
        data_modifica=clock_timestamp(),
        login_operazione=loginOperazione||LOG_OP_FINE
	where num.ente_proprietario_id=enteProprietarioId
	--and   num.movep_anno::integer=annoBilancio
    and   num.movep_anno=annoBilancio
    and   num.data_cancellazione is null
    and   num.validita_fine is null;

 	codResult:=null;
	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||classeConto||' [siac_t_mov_ep_det].';
	insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;
	if codResult is null then
    	raise exception ' Inserimento log non effettuato';
    end if;

	insert into siac_t_mov_ep_det
	(movep_det_code,
	 movep_det_importo,
	 movep_det_segno,
	 movep_id,
	 pdce_conto_id,
	 validita_inizio,
	 ente_proprietario_id,
	 login_operazione,
	 ambito_id
	)
    (
		select
        det.movep_det_code::integer,
	    det.movep_det_importo,
		(case when det.movep_det_segno=SEGNO_DARE_MOV then SEGNO_AVERE_MOV else SEGNO_DARE_MOV end),
		movepId,
    	det.pdce_conto_id,
	    dataInizioVal,
     	enteProprietarioId,
        loginOperazione||LOG_OP_FINE,
        ambitoId
		from fase_gen_t_elaborazione_fineanno_det   fasedetCHI,
		     fase_gen_d_elaborazione_fineanno_tipo  fasetipoCHI,
             siac_t_mov_ep_det det
		where fasedetCHI.fase_gen_elab_id=faseBilElabId
        and   fasetipoCHI.fase_gen_elab_tipo_id=fasedetCHI.fase_gen_elab_tipo_id
        and   fasedetCHI.fase_gen_det_elab_esito='OK'
   		and   fasetipoCHI.ordine=ordineElabChiDet
        and   det.movep_id=fasedetCHI.movep_id
		and   fasedetCHI.data_cancellazione is null
        and   fasedetCHI.validita_fine is null
        and   det.data_cancellazione is null
        and   det.validita_fine is null
		order by det.movep_det_code::integer
     );

	 strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||classeConto||' [siac_t_mov_ep_det]. Verifica dettagli inseriti.';
	 codResult:=null;
     select count(*) into codResult
     from siac_t_mov_ep_det det
     where det.movep_id=movEpId;
     if codResult is null or codResult<2 then
     	raise exception ' Errore in inserimento.';
     end if;


     strMessaggio:='Chiusura elaborazione step '|| ordineElabCHIDet ||' OK.';
     codResult:=null;
 	 insert into fase_gen_t_elaborazione_fineanno_log
	 (fase_gen_elab_id,fase_gen_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
	 )
     values
	 (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
      returning fase_gen_elab_log_id into codResult;

	 if codResult is null then
    		raise exception ' Errore in inserimento LOG.';
     end if;

	 update  fase_gen_t_elaborazione_fineanno_det fasedet
	 set  movep_id=movepId,
     	  pnota_id=pnotaId,
	      fase_gen_det_elab_esito='OK',
    	  fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - OK - TERMINE',
	      data_modifica=now(),
	      login_operazione=fasedet.login_operazione||'_TERMINE'
	 from fase_gen_d_elaborazione_fineanno_tipo fasetipo
	 where fasedet.fase_gen_elab_det_id=faseBilElabDetId
     and   fasedet.data_cancellazione is null
     and   fasedet.validita_fine is null;



    codResult:=null;
	insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    faseBilElabDetRetId:=faseBilElabDetId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
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
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;