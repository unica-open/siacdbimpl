/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_fase_gen_elaborazione_fineanno_contabilizza (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  fasebilelabid integer,
  bilancioid integer,
  ordineelabdet integer,
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

	pnStatoDefId      integer:=null;
    ambitoId           integer:=null;

	relRiscontoTipoId  integer:=null;
    pnotaStatoAId      integer:=null;

    PNOTA_STATO_DEF   CONSTANT varchar:='D';

    LOG_OP_FINE       CONSTANT varchar:='_gen_contabilizza';

	elenco_elab record;
    
BEGIN
	faseBilElabDetRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= (annoBilancio::varchar||'-01-01')::timestamp;

	strMessaggioFinale:='Inizio attivita'' di contabilizzazione  bilancioId='||bilancioId
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

    strMessaggio:='Lettura identificativo stato prima nota '||PNOTA_STATO_DEF||'.';

    select stato.pnota_stato_id into pnStatoDefId
    from siac_d_prima_nota_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.pnota_stato_code=PNOTA_STATO_DEF
    and   stato.data_cancellazione is null
    and   stato.validita_fine is null;
    if pnStatoDefId is null then
    	raise exception ' Identificativo stato definitivo prima nota non reperito.';
    end if;


	strMessaggio:='Inserimento step '||ordineElabDet||' elaborazione [fase_gen_t_elaborazione_fineanno_det].';
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
            'ELABORAZIONE SCRITTURE GEN DI CHIUSURA/APERTURA FINE ANNO - CONTABILIZZAZIONE - INIZIO',
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

     -- 20.09.2017 Sofia
     -- leggere in fase_gen_t_elaborazione_fineanno_det per fasebilelabid
     -- i dettagli di tipo
     -- CHIPP
     -- CHIAP
     -- EPCE
     -- EPRE
     -- DETREE
     -- APEPP
     -- APEAP
     -- STRISC

     -- per ogni dettaglio trovato ( che deve essere in stato OK ) ricavare la siac_t_prima_nota da
     -- fase_gen_t_elaborazione_fineanno_det.pnota_id
     -- quindi fare quello indicato di seguito
     /* DEVO METTERE IL RECORD ESISTENTE DELLA PRIMA NOTA SU siac_r_prima_nota_stato
   CON  VALIDITA_FINE E DATA MODIFICA.
   POI INSERIRE UN RECORD NUOVO CON STATO DEFINITIVO.
   */
   
     
	strMessaggio:='Inizio ciclo elaborazione dati su fase_gen_t_elaborazione_fineanno_det.';
	 for elenco_elab in
     	SELECT fasedet.*
     	FROM fase_gen_t_elaborazione_fineanno_det fasedet,
        fase_gen_d_elaborazione_fineanno_tipo fase_tipo
        WHERE fasedet.fase_gen_elab_tipo_id=fase_tipo.fase_gen_elab_tipo_id
        	AND fasedet.ente_proprietario_id = enteproprietarioid
        	AND fasedet.fase_gen_elab_id=fasebilelabid  
            AND fase_tipo.fase_gen_elab_tipo_code IN ('CHIPP',
            	'CHIAP', 'EPCE', 'EPRE', 'DETREE', 'APEPP',
                'APEAP', 'STRISC')
            AND fasedet.fase_gen_det_elab_esito='OK'
            AND fasedet.pnota_id IS NOT NULL
            AND fasedet.data_cancellazione IS NULL
            AND fase_tipo.data_cancellazione IS NULL         
     loop
     raise notice 'PNOTA_ID = %', elenco_elab.pnota_id;
     	strMessaggio:='Cancellazione del record su siac_r_prima_nota_stato per pnota_id = '||elenco_elab.pnota_id;
     	UPDATE siac_r_prima_nota_stato
        	SET validita_fine = clock_timestamp(),
        		data_cancellazione = clock_timestamp(), --????
            	data_modifica = clock_timestamp()
            WHERE ente_proprietario_id = enteproprietarioid
            	AND pnota_id = elenco_elab.pnota_id
                AND data_cancellazione IS NULL
            	AND validita_fine IS NULL;
                
        strMessaggio:='Inserimento su siac_r_prima_nota_stato del record con stato definitivo per pnota_id = '||elenco_elab.pnota_id;
        INSERT INTO  siac_r_prima_nota_stato
        	 (pnota_id, pnota_stato_id, validita_inizio, validita_fine,
              ente_proprietario_id, data_creazione, data_modifica,
              data_cancellazione, login_operazione)
        VALUES (elenco_elab.pnota_id, pnStatoDefId, now(), NULL,
        		enteproprietarioid, clock_timestamp(), clock_timestamp(), 
                NULL, loginoperazione||LOG_OP_FINE);
    
     end loop;
     
     strMessaggio:='Chiusura elaborazione step '|| ordineElabDet ||' OK.';
     codResult:=null;
 	 insert into fase_gen_t_elaborazione_fineanno_log
	 (fase_gen_elab_id,fase_gen_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
	 )
     values
	 (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione||LOG_OP_FINE,enteProprietarioId)
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
    (faseBilElabId,strMessaggioFinale||' FINE.',clock_timestamp(),loginOperazione||LOG_OP_FINE,enteProprietarioId)
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