/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_fase_gen_elaborazione_fineanno_insert_pnota_sri (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  fasebilelabid integer,
  bilancioid integer,
  tipoconto varchar,
  ordineelabdet integer,
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


	relRiscontoTipoId  integer:=null;
    pnotaStatoAId      integer:=null;

    AMBITO_FIN        CONSTANT varchar:='AMBITO_FIN';

    SEGNO_DARE      CONSTANT varchar:='DARE';
    SEGNO_DARE_MOV  CONSTANT varchar:='Dare';
    SEGNO_AVERE     CONSTANT varchar:='AVERE';
    SEGNO_AVERE_MOV CONSTANT varchar:='Avere';

    PNOTA_STATO_PROV   CONSTANT varchar:='P';
    PNOTA_STATO_AN     CONSTANT varchar:='A';
    PNOTA_REL_RISC     CONSTANT varchar:='RISCONTO';

    LOG_OP_FINE       CONSTANT varchar:='_gen_chiape_sri';


BEGIN
	faseBilElabDetRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= (annoBilancio::varchar||'-01-01')::timestamp;

	strMessaggioFinale:='Inserimento prima nota e movimenti per '||tipoOperazioneGen||' tipo conto='||tipoConto||'  bilancioId='||bilancioId
      ||'. Inizio step '||ordineElabDet||' .';

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

    strMessaggio:='Lettura identificativo stato prima nota '||PNOTA_STATO_AN||'.';
    select stato.pnota_stato_id into pnotaStatoAId
    from siac_d_prima_nota_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.pnota_stato_code=PNOTA_STATO_AN
    and   stato.data_cancellazione is null
    and   stato.validita_fine is null;
    if pnotaStatoAId is null then
    	raise exception ' Identificativo non reperito.';
    end if;

    strMessaggio:='Lettura identificativo relazione prima nota tipo '||PNOTA_REL_RISC||'.';
    select tipo.pnota_rel_tipo_id into relRiscontoTipoId
    from siac_d_prima_nota_rel_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.pnota_rel_tipo_code=PNOTA_REL_RISC
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if relRiscontoTipoId is null then
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


    strMessaggio:='Verifica esistenza progressivi prima nota [siac_t_prima_nota_num] per annoBilancio='||annoBilancio||'.';
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

    codResult:=null;
	select num.pnota_num_id into codResult
    from  siac_t_prima_nota_num num
	where num.ente_proprietario_id=enteProprietarioId
	and   num.pnota_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   num.validita_fine is null;
    if codResult is null then
        strMessaggio:='Inserimento progressivi prima nota [siac_t_prima_nota_num] per annoBilancio='||annoBilancio||'.';
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


    strMessaggio:='Verifica esistenza progressivi prima nota [siac_t_mov_ep_num] per annoBilancio='||annoBilancio||'.';
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
    codResult:=null;
    select num.movep_num_id into codResult
    from siac_t_mov_ep_num num
	where num.ente_proprietario_id=enteProprietarioId
	and   num.movep_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   num.validita_fine is null;
    if codResult is null then
  	    strMessaggio:='Inserimento progressivi prima nota [siac_t_mov_ep_num] per annoBilancio='||annoBilancio||'.';
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
         annoBilancio::varchar,
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

	strMessaggio:='Inserimento step '||ordineElabDet||' elaborazione [fase_gen_t_elaborazione_fineanno_det].';
    codResult:=null;
	insert into fase_gen_t_elaborazione_fineanno_log
   	(fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
   	)
    values
    (faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   	returning fase_gen_elab_log_id into codResult;
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
            'ELABORAZIONE SCRITTURE GEN DI CHIUSURA/APERTURA FINE ANNO - INSERIMENTO '||tipoOperazioneGen||'. CONTI '||tipoConto||' - INIZIO',
            clock_timestamp(),
            loginOperazione||LOG_OP_FINE,
        	fase.ente_proprietario_id
	from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo fasetipo
	where fase.fase_gen_elab_id=faseBilElabId
	and   fase.fase_gen_elab_esito like 'IN%'
	and   fasetipo.ente_proprietario_id=enteProprietarioId
	and   fasetipo.ordine=ordineElabDet
	and   fase.data_cancellazione is null
	and   fase.validita_fine is null)
    returning fase_gen_elab_det_id into faseBilElabDetId;
    if faseBilElabDetId is null then
    	raise exception ' Inserimento non effettuato.';
    end if;

    codResult:=null;
    strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||tipoConto||' - INIZIO.';
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



	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||tipoConto||' [siac_t_prima_nota].';

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
	 (select num.pnota_numero+( row_number() over (order by pnota_a.pnota_id)),
     	     fasetipo.fase_gen_elab_tipo_desc,
	         dataElaborazione,
    	     bilancioId,
	         c.causale_ep_tipo_id,
	         dataInizioVal,
	         enteProprietarioId,
	         loginOperazione||LOG_OP_FINE||'@'||faseBilElabDetId::varchar||'*'||pnota_a.pnota_id::varchar,
	         loginOperazione||LOG_OP_FINE,
	         ambitoId
 	 from fase_gen_t_elaborazione_fineanno_det fasedet,
	      fase_gen_d_elaborazione_fineanno_tipo fasetipo,
	      siac_t_prima_nota_num num, siac_t_causale_ep c,
          siac_t_prima_nota_ratei_risconti pnota,
          siac_r_prima_nota rel,
          siac_t_prima_nota pnota_da, siac_r_prima_nota_stato rstato_da,
          siac_t_prima_nota pnota_a, siac_r_prima_nota_stato rstato_a
	 where fasedet.fase_gen_elab_det_id=faseBilElabDetId
	 and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
	 and   num.ente_proprietario_id=enteProprietarioId
	 and   num.pnota_anno::integer=annoBilancio
	 and   c.causale_ep_id=fasetipo.causale_ep_id
     and   pnota.ente_proprietario_id=enteProprietarioId -- prima nota risconto anno=annoBilancio
	 and   pnota.anno::integer=annoBilancio
	 and   pnota.pnota_rel_tipo_id=relRiscontoTipoId     -- tipoRisconto
     and   rel.pnota_id_da=pnota.pnota_id                -- relazione tra prima nota di partenza risconto
     and   rel.pnota_rel_tipo_id=relRiscontoTipoId       -- tipoRisconto
     and   pnota_da.pnota_id=rel.pnota_id_da
     and   rstato_da.pnota_id=pnota.pnota_id
     and   rstato_da.pnota_stato_id!=pnotaStatoAId       -- non annullata
     and   pnota_a.pnota_id=rel.pnota_id_a               -- a prima nota di risconto
     and   rstato_a.pnota_id=pnota_a.pnota_id
     and   rstato_a.pnota_stato_id!=pnotaStatoAId        -- non annullata
	 and   c.data_cancellazione is null
	 and   c.validita_fine is null
     and   pnota.data_cancellazione is null
     and   pnota.validita_fine is null
     and   rel.data_cancellazione is null
     and   rel.validita_fine is null
     and   pnota_da.data_cancellazione is null
     and   pnota_da.validita_fine is null
     and   rstato_da.data_cancellazione is null
     and   rstato_da.validita_fine is null
     and   pnota_a.data_cancellazione is null
     and   pnota_a.validita_fine is null
     and   rstato_a.data_cancellazione is null
     and   rstato_a.validita_fine is null
    );


    strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||tipoConto||' aggiornamento progressivo [siac_t_prima_nota_num].';
	update siac_t_prima_nota_num num
	set pnota_numero=(select max(pnota.pnota_numero)
                      from siac_t_prima_nota pnota,
     			           siac_r_prima_nota_stato r
                 	  where   pnota.bil_id=bilancioId
						and   r.pnota_id=pnota.pnota_id
						and   r.pnota_stato_id!=pnotaStatoAId
                    	and   pnota.data_cancellazione is null
						and   pnota.validita_fine is null
						and   r.data_cancellazione is null
						and   r.validita_fine is null
                  	),
    	data_modifica=clock_timestamp(),
        login_operazione=loginOperazione||LOG_OP_FINE
	where num.ente_proprietario_id=enteProprietarioId
	and   num.pnota_anno::integer=annoBilancio
	and   num.data_cancellazione is null
	and   num.validita_fine is null
	and   exists (select 1
                  from siac_t_prima_nota pnota,
     			       siac_r_prima_nota_stato r
                  where   pnota.bil_id=bilancioId
					and   r.pnota_id=pnota.pnota_id
					and   r.pnota_stato_id!=pnotaStatoAId
                    and   pnota.data_cancellazione is null
					and   pnota.validita_fine is null
					and   r.data_cancellazione is null
					and   r.validita_fine is null);


    codResult:=null;
   	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||tipoConto||' [siac_r_prima_nota_stato].';
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
    (select
     pnota.pnota_id,
     pnStatoProvId,
     dataInizioVal,
     loginOperazione||LOG_OP_FINE,
     enteProprietarioId
     from  siac_t_prima_nota pnota
     where pnota.bil_id=bilancioId
     and   pnota.login_operazione like '%'||LOG_OP_FINE||'%'
 	 and   substring(pnota.login_operazione from strpos (pnota.login_operazione,'@')+1
                     for (strpos (pnota.login_operazione,'*')-strpos (pnota.login_operazione,'@')-1)
                     )::integer = faseBilElabDetId
     and   pnota.data_cancellazione is null
     and   pnota.validita_fine is null
    );


    codResult:=null;
	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||tipoConto||' [siac_r_prima_nota].';
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


    insert into siac_r_prima_nota
	( pnota_id_da,
      pnota_id_a,
      pnota_rel_tipo_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
	)
	(select r.pnota_id_da,
            pnota.pnota_id,
            relRiscontoTipoId,
	        dataInizioVal,
	        loginOperazione||LOG_OP_FINE,
       	    enteProprietarioId
	 from  siac_t_prima_nota pnota, siac_t_prima_nota pnota_a, siac_r_prima_nota r
	 where pnota.bil_id=bilancioId
     and   pnota.login_operazione like '%'||LOG_OP_FINE||'%'
	 and   substring(pnota.login_operazione from strpos (pnota.login_operazione,'@')+1
                     for (strpos (pnota.login_operazione,'*')-strpos (pnota.login_operazione,'@')-1)
                     )::integer = faseBilElabDetId
     and   pnota_a.pnota_id=substring(pnota.login_operazione from strpos (pnota.login_operazione,'*')+1)::integer
     and   r.pnota_id_a=pnota_a.pnota_id
     and   r.pnota_rel_tipo_id=relRiscontoTipoId
     and   pnota.data_cancellazione is null
     and   pnota.validita_fine is null
     and   pnota_a.data_cancellazione is null
     and   pnota_a.validita_fine is null
     and   r.data_cancellazione is null
     and   r.validita_fine is null
    );


    codResult:=null;
	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||tipoConto||' [siac_t_mov_ep].';
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
	(select num.movep_code+( row_number() over (order by pnota.pnota_id)),
     	    fasetipo.fase_gen_elab_tipo_desc,
	        fasetipo.causale_ep_id,
	        pnota.pnota_id,
	        dataInizioVal,
    	    enteProprietarioId,
	        loginOperazione||LOG_OP_FINE||'@'||epa.movep_id::varchar,
    	    ambitoId
	 from fase_gen_t_elaborazione_fineanno_det fasedet,
     	  fase_gen_d_elaborazione_fineanno_tipo fasetipo,
	      siac_t_mov_ep_num num,
          siac_t_mov_ep epa,
          siac_t_prima_nota pnota, siac_t_prima_nota pnota_a
	 where fasedet.fase_gen_elab_det_id=faseBilElabDetId
	 and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
	 and   fasetipo.ente_proprietario_id=enteProprietarioId
	 and   fasetipo.ordine=ordineElabDet
	 and   num.ente_proprietario_id=enteProprietarioId
	 and   num.movep_anno::integer=annoBilancio
     and   pnota.bil_id=bilancioId
     and   pnota.login_operazione like '%'||LOG_OP_FINE||'%'
	 and   substring(pnota.login_operazione from strpos (pnota.login_operazione,'@')+1
                     for (strpos (pnota.login_operazione,'*')-strpos (pnota.login_operazione,'@')-1)
                     )::integer = faseBilElabDetId
     and   pnota_a.pnota_id=substring(pnota.login_operazione from strpos (pnota.login_operazione,'*')+1)::integer
     and   epa.regep_id=pnota_a.pnota_id
     and   pnota.data_cancellazione is null
     and   pnota.validita_fine is null
     and   pnota_a.data_cancellazione is null
     and   pnota_a.validita_fine is null
     and   epa.data_cancellazione is null
     and   epa.validita_fine is null
    );


	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||tipoConto||' aggiornamento progressivo [siac_t_mov_ep_num].';
	update siac_t_mov_ep_num num
	set movep_code=(select max(ep.movep_code)
    				from siac_t_mov_ep ep, siac_t_prima_nota pn,siac_r_prima_nota_stato r
                    where pn.bil_id=bilancioId
                    and   r.pnota_id=pn.pnota_id
                    and   r.pnota_stato_id!=pnotaStatoAId
                    and   ep.regep_id=pn.pnota_id
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   pn.data_cancellazione is null
                    and   pn.validita_fine is null
                    and   ep.data_cancellazione is null
                    and   ep.validita_fine is null
    			   ),
        data_modifica=clock_timestamp(),
        login_operazione=loginOperazione||LOG_OP_FINE
	where num.ente_proprietario_id=enteProprietarioId
	and   num.movep_anno::integer=annoBilancio
    and   exists ( select 1
                   from siac_t_mov_ep ep, siac_t_prima_nota pn,siac_r_prima_nota_stato r
                   where pn.bil_id=bilancioId
                   and   r.pnota_id=pn.pnota_id
                   and   r.pnota_stato_id!=pnotaStatoAId
                   and   ep.regep_id=pn.pnota_id
                   and   r.data_cancellazione is null
                   and   r.validita_fine is null
                   and   pn.data_cancellazione is null
                   and   pn.validita_fine is null
                   and   ep.data_cancellazione is null
                   and   ep.validita_fine is null
                  )
    and   num.data_cancellazione is null
    and   num.validita_fine is null;

 	codResult:=null;
	strMessaggio:='Inserimento prima nota '||tipoOperazioneGen||'. CONTI '||tipoConto||' [siac_t_mov_ep_det].';
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
		ep.movep_id,
    	det.pdce_conto_id,
	    dataInizioVal,
     	enteProprietarioId,
        loginOperazione||LOG_OP_FINE,
        ambitoId
		from fase_gen_t_elaborazione_fineanno_det fasedet,
     	     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
          	 siac_t_prima_nota pnota,siac_t_mov_ep ep,
             siac_t_mov_ep_det det
	 	where fasedet.fase_gen_elab_det_id=faseBilElabDetId
	 	and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
	 	and   fasetipo.ente_proprietario_id=enteProprietarioId
	 	and   fasetipo.ordine=ordineElabDet
     	and   pnota.bil_id=bilancioId
        and   pnota.login_operazione like '%'||LOG_OP_FINE||'%'
        and   substring(pnota.login_operazione from strpos (pnota.login_operazione,'@')+1
                     for (strpos (pnota.login_operazione,'*')-strpos (pnota.login_operazione,'@')-1)
                     )::integer = faseBilElabDetId
        and   ep.regep_id=pnota.pnota_id
        and   det.movep_id=substring(ep.login_operazione from strpos (ep.login_operazione,'@')+1)::integer
        and   det.data_cancellazione is null
        and   det.validita_fine is null
		order by det.movep_det_code::integer
     );


     strMessaggio:='Chiusura elaborazione step '|| ordineElabDet ||' OK.';
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
	 set  fase_gen_det_elab_esito='OK',
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