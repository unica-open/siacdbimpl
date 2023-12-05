/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_fase_gen_elaborazione_fineanno_calcolo_saldi (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  fasebilelabid integer,
  bilancioid integer,
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
	attrContoFogliaId integer:=null;

	saldiContiErrati  integer:=null;

    pdceContoReeId    integer:=null;

	saldoContiSegnoDiverso boolean:=false;
    saldoContiUguale boolean:=false;
    chiusuraStep     boolean:=true;

    isUtile          boolean:=false;
    isPerdita        boolean:=false;
    importoREEAvere  numeric:=0;
    importoREEDare   numeric:=0;

    -- classe conti

    COSTI_CLASSE      CONSTANT varchar:='CE'; -- costi
    RICAVI_CLASSE     CONSTANT varchar:='RE'; -- ricavi
    ATT_PATR_CLASSE   CONSTANT varchar:='AP'; -- patrimonio attivo
    PAS_PATR_CLASSE   CONSTANT varchar:='PP'; -- patrimonio passivo
    OP_PATR_CLASSE    CONSTANT varchar:='OP'; -- ordine passivo
    OA_PATR_CLASSE    CONSTANT varchar:='OA'; -- ordine attivo


    SEGNO_DARE     CONSTANT varchar:='DARE';
    SEGNO_AVERE    CONSTANT varchar:='AVERE';

    PNOTA_STATO_DEF   CONSTANT varchar:='D';
    CONTO_FOGLIA_ATTR CONSTANT varchar:='pdce_conto_foglia';

    LOG_OP_FINE       CONSTANT varchar:='_gen_chiape';

	saldiRec record;
	importoTotSaldoDare numeric;
    importoTotSaldoAvere numeric;

BEGIN
	faseBilElabDetRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Calcolo saldi conti economico patrimoniali bilancioId='||bilancioId||'.';

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
    	raise exception ' Identificativo non reperito.';
    end if;

    strMessaggio:='Lettura identificativo attributo '||CONTO_FOGLIA_ATTR||'.';
    select a.attr_id into attrContoFogliaId
    from siac_t_attr a
    where a.ente_proprietario_id=enteProprietarioId
    and   a.attr_code=CONTO_FOGLIA_ATTR
    and   a.data_cancellazione is null
    and   a.validita_fine is null;
    if attrContoFogliaId is null then
    	raise exception ' Identificativo non reperito.';
    end if;


    -- 20.09.2017 Sofia
    strMessaggio:='Lettura identificativo conto REE.';
    select det.pdce_conto_id into pdceContoReeId
    from  fase_gen_d_elaborazione_fineanno_tipo tipo, fase_gen_d_elaborazione_fineanno_tipo_det det
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_gen_elab_tipo_code='DETREE'
    and   det.fase_gen_elab_tipo_id=tipo.fase_gen_elab_tipo_id
    limit 1;
    if pdceContoReeId is null then
    	raise exception ' Identificativo non reperito.';
    end if;


	strMessaggio:='Inserimento step 1 elaborazione [fase_gen_t_elaborazione_fineanno_det].';
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
            'ELABORAZIONE SCRITTURE GEN DI CHIUSURA/APERTURA FINE ANNO - CALCOLO SALDI - INIZIO',
            clock_timestamp(),
            loginOperazione||LOG_OP_FINE,
        	fase.ente_proprietario_id
	from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo fasetipo
	where fase.fase_gen_elab_id=faseBilElabId
	and   fase.fase_gen_elab_esito like 'IN%'
	and   fasetipo.ente_proprietario_id=enteProprietarioId
	and   fasetipo.ordine=1
	and   fase.data_cancellazione is null
	and   fase.validita_fine is null)
    returning fase_gen_elab_det_id into faseBilElabDetId;
    if faseBilElabDetId is null then
    	raise exception ' Inserimento non effettuato.';
    end if;

    codResult:=null;
    strMessaggio:='Inserimento saldi conti '||COSTI_CLASSE||' - INIZIO.';
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

   strMessaggio:='Inserimento saldi conti '||COSTI_CLASSE||' [fase_gen_t_elaborazione_fineanno_saldi].';
--   raise notice 'Prima di inseriment in fase_gen_t_elaborazione_fineanno_saldi=%',strMessaggio;

   -- costi
   insert into fase_gen_t_elaborazione_fineanno_saldi
   (fase_gen_elab_det_id,
	pdce_conto_id,
	pdce_conto_segno,
	pdce_conto_dare,
	pdce_conto_avere,
	validita_inizio,
	login_operazione,
	ente_proprietario_id
   )
   select
      faseBilElabDetId,
      pdce.pdce_conto_id,
      f.pdce_fam_segno,
      sum( ( case when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                  when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                  when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
	 	    	  else 0 end )),
      sum( ( case when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                  when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                  when f.pdce_fam_segno=SEGNO_DARE  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
  	   	          else 0 end )),
      clock_timestamp(),
      loginOperazione||LOG_OP_FINE,
      enteProprietarioId
   from  siac_t_pdce_conto pdce,
   		 siac_t_pdce_fam_tree ft,
	     siac_d_pdce_fam f,
	     siac_r_pdce_conto_attr r,
	     siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota,
	     siac_t_mov_ep movep, siac_t_mov_ep_det movdet
	where pnota.bil_id=bilancioId
	and   rpnota.pnota_id=pnota.pnota_id
	and   rpnota.pnota_stato_id=pnStatoDefId
	and   movep.regep_id=pnota.pnota_id
	and   movdet.movep_id=movep.movep_id
	and   pdce.pdce_conto_id=movdet.pdce_conto_id
	and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
	and   f.pdce_fam_id=ft.pdce_fam_id
	and   f.pdce_fam_code=COSTI_CLASSE
	and   f.ente_proprietario_id=pnota.ente_proprietario_id
	and   r.pdce_conto_id=pdce.pdce_conto_id
	and   r.attr_id=attrContoFogliaId
	and   r.boolean='S'
	and   pnota.data_cancellazione is null
	and   pnota.validita_fine is null
	and   rpnota.data_cancellazione is null
	and   rpnota.validita_fine is null
	and   movdet.data_cancellazione is null
	and   movdet.validita_fine is null
	and   movep.data_cancellazione is null
	and   movep.validita_fine is null
	and   pdce.data_cancellazione is null
	and   pdce.validita_fine is null
	and   r.data_cancellazione is null
	and   r.validita_fine is null
	group by faseBilElabDetId,
    	     pdce.pdce_conto_id,
        	 f.pdce_fam_segno,
	         bilancioId
	having sum( ( case when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end ))-
	       sum( ( case when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_DARE  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end ))!=0;

 --  raise notice 'Dopo di inseriment in fase_gen_t_elaborazione_fineanno_saldi=%',strMessaggio;

	codResult:=null;
    strMessaggio:='Inserimento saldi conti '||COSTI_CLASSE||' - FINE.';
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
    strMessaggio:='Inserimento saldi conti '||RICAVI_CLASSE||' - INIZIO.';
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

    strMessaggio:='Inserimento saldi conti '||RICAVI_CLASSE||' [fase_gen_t_elaborazione_fineanno_saldi].';
  --  raise notice 'Prima di inseriment in fase_gen_t_elaborazione_fineanno_saldi=%',strMessaggio;
    -- ricavi
	insert into fase_gen_t_elaborazione_fineanno_saldi
	(
	  fase_gen_elab_det_id,
	  pdce_conto_id,
	  pdce_conto_segno,
	  pdce_conto_dare,
	  pdce_conto_avere,
	  validita_inizio,
	  login_operazione,
	  ente_proprietario_id
	)
	select faseBilElabDetId,
    	   pdce.pdce_conto_id,
	       f.pdce_fam_segno,
    	   sum( ( case when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
        	           when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
            	       when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end )),
	       sum( ( case when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_DARE  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end )),
	       clock_timestamp(),
    	   loginOperazione||LOG_OP_FINE,
	       enteProprietarioId
	from siac_t_pdce_conto pdce,
	     siac_t_pdce_fam_tree ft,
	     siac_d_pdce_fam f,
	     siac_r_pdce_conto_attr r,
	     siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota,
	     siac_t_mov_ep movep, siac_t_mov_ep_det movdet
	where pnota.bil_id=bilancioId
	and   rpnota.pnota_id=pnota.pnota_id
	and   rpnota.pnota_stato_id=pnStatoDefId
	and   movep.regep_id=pnota.pnota_id
	and   movdet.movep_id=movep.movep_id
	and   pdce.pdce_conto_id=movdet.pdce_conto_id
	and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
	and   f.pdce_fam_id=ft.pdce_fam_id
	and   f.pdce_fam_code=RICAVI_CLASSE
    and   f.ente_proprietario_id=pnota.ente_proprietario_id
	and   r.pdce_conto_id=pdce.pdce_conto_id
	and   r.attr_id=attrContoFogliaId
	and   r.boolean='S'
	and   pnota.data_cancellazione is null
	and   pnota.validita_fine is null
	and   rpnota.data_cancellazione is null
	and   rpnota.validita_fine is null
	and   movdet.data_cancellazione is null
	and   movdet.validita_fine is null
	and   movep.data_cancellazione is null
	and   movep.validita_fine is null
	and   pdce.data_cancellazione is null
	and   pdce.validita_fine is null
	and   r.data_cancellazione is null
	and   r.validita_fine is null
	group by faseBilElabDetId,
    	     pdce.pdce_conto_id,
	         f.pdce_fam_segno,
			 bilancioId
	having sum( ( case when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end ))-
	       sum( ( case when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_DARE  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end ))!=0;

  --  raise notice 'Dopo di inseriment in fase_gen_t_elaborazione_fineanno_saldi=%',strMessaggio;
    codResult:=null;
    strMessaggio:='Inserimento saldi conti '||RICAVI_CLASSE||' - FINE.';
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
    strMessaggio:='Inserimento saldi conti '||PAS_PATR_CLASSE||'-'||OP_PATR_CLASSE||' - INIZIO.';
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

    strMessaggio:='Inserimento saldi conti '||PAS_PATR_CLASSE||'-'||OP_PATR_CLASSE||' [fase_gen_t_elaborazione_fineanno_saldi].';
    -- debiti, conti ordine passivi
	insert into fase_gen_t_elaborazione_fineanno_saldi
	(
	  fase_gen_elab_det_id,
	  pdce_conto_id,
	  pdce_conto_segno,
	  pdce_conto_dare,
	  pdce_conto_avere,
	  validita_inizio,
	  login_operazione,
	  ente_proprietario_id
	)
	select faseBilElabDetId,
    	   pdce.pdce_conto_id,
	       f.pdce_fam_segno,
    	   sum( ( case when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
        	           when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
            	       when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end )),
	       sum( ( case when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_DARE  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end )),
	       clock_timestamp(),
    	   loginOperazione||LOG_OP_FINE,
	       enteProprietarioId
	from siac_t_pdce_conto pdce,
	     siac_t_pdce_fam_tree ft,
	     siac_d_pdce_fam f,
	     siac_r_pdce_conto_attr r,
    	 siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota,
	     siac_t_mov_ep movep, siac_t_mov_ep_det movdet
	where pnota.bil_id=bilancioId
	and   rpnota.pnota_id=pnota.pnota_id
	and   rpnota.pnota_stato_id=pnStatoDefId
	and   movep.regep_id=pnota.pnota_id
	and   movdet.movep_id=movep.movep_id
	and   pdce.pdce_conto_id=movdet.pdce_conto_id
	and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
	and   f.pdce_fam_id=ft.pdce_fam_id
	and   f.pdce_fam_code in (PAS_PATR_CLASSE,OP_PATR_CLASSE)
	and   f.ente_proprietario_id=pnota.ente_proprietario_id
	and   r.pdce_conto_id=pdce.pdce_conto_id
	and   r.attr_id=attrContoFogliaId
	and   r.boolean='S'
	and   pnota.data_cancellazione is null
	and   pnota.validita_fine is null
	and   rpnota.data_cancellazione is null
	and   rpnota.validita_fine is null
	and   movdet.data_cancellazione is null
	and   movdet.validita_fine is null
	and   movep.data_cancellazione is null
	and   movep.validita_fine is null
	and   pdce.data_cancellazione is null
	and   pdce.validita_fine is null
	and   r.data_cancellazione is null
	and   r.validita_fine is null
	group by faseBilElabDetId,
             pdce.pdce_conto_id,
	         f.pdce_fam_segno,
	         bilancioId
	having sum( ( case when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end ))-
    	   sum( ( case when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
        	           when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
            	       when f.pdce_fam_segno=SEGNO_DARE  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end ))!=0;

    codResult:=null;
    strMessaggio:='Inserimento saldi conti '||PAS_PATR_CLASSE||'-'||OP_PATR_CLASSE||' - FINE.';
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
    strMessaggio:='Inserimento saldi conti '||ATT_PATR_CLASSE||'-'||OA_PATR_CLASSE||' - INIZIO.';
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

    strMessaggio:='Inserimento saldi conti '||ATT_PATR_CLASSE||'-'||OA_PATR_CLASSE||' [fase_gen_t_elaborazione_fineanno_saldi].';
    -- crediti, conti ordine attivi
	insert into fase_gen_t_elaborazione_fineanno_saldi
	(
	  fase_gen_elab_det_id,
	  pdce_conto_id,
	  pdce_conto_segno,
	  pdce_conto_dare,
	  pdce_conto_avere,
	  validita_inizio,
	  login_operazione,
	  ente_proprietario_id
	)
	select faseBilElabDetId,
    	   pdce.pdce_conto_id,
	       f.pdce_fam_segno,
    	   sum( ( case when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
        	           when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
            	       when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end )),
	       sum( ( case when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_DARE  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end )),
	       clock_timestamp(),
    	   loginOperazione||LOG_OP_FINE,
	       enteProprietarioId
	from siac_t_pdce_conto pdce,
    	 siac_t_pdce_fam_tree ft,
	     siac_d_pdce_fam f,
	     siac_r_pdce_conto_attr r,
	     siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota,
	     siac_t_mov_ep movep, siac_t_mov_ep_det movdet
	where pnota.bil_id=bilancioId
	and   rpnota.pnota_id=pnota.pnota_id
	and   rpnota.pnota_stato_id=pnStatoDefId
	and   movep.regep_id=pnota.pnota_id
	and   movdet.movep_id=movep.movep_id
	and   pdce.pdce_conto_id=movdet.pdce_conto_id
	and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
	and   f.pdce_fam_id=ft.pdce_fam_id
	and   f.pdce_fam_code in (ATT_PATR_CLASSE,OA_PATR_CLASSE)
	and   f.ente_proprietario_id=pnota.ente_proprietario_id
	and   r.pdce_conto_id=pdce.pdce_conto_id
	and   r.attr_id=attrContoFogliaId
	and   r.boolean='S'
	and   pnota.data_cancellazione is null
	and   pnota.validita_fine is null
	and   rpnota.data_cancellazione is null
	and   rpnota.validita_fine is null
	and   movdet.data_cancellazione is null
	and   movdet.validita_fine is null
	and   movep.data_cancellazione is null
	and   movep.validita_fine is null
	and   pdce.data_cancellazione is null
	and   pdce.validita_fine is null
	and   r.data_cancellazione is null
	and   r.validita_fine is null
	group by faseBilElabDetId,
    	  	 pdce.pdce_conto_id,
		     f.pdce_fam_segno,
	         bilancioId
	having sum( ( case when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
	                   when f.pdce_fam_segno=SEGNO_DARE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
    	               when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end ))-
	       sum( ( case when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
    	               when f.pdce_fam_segno=SEGNO_AVERE and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
        	           when f.pdce_fam_segno=SEGNO_DARE  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
					   else 0 end ))!=0;

    codResult:=null;
    strMessaggio:='Inserimento saldi conti '||ATT_PATR_CLASSE||'-'||OA_PATR_CLASSE||' - FINE.';
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
    strMessaggio:='Aggiornamento saldi conti per saldi errati.';
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

    -- update per segno_errato su singoli conti
    -- Maurizio: escluso il conto 2.1.4.01.01.01.001 perchè trattato in modo diverso.
	/*update fase_gen_t_elaborazione_fineanno_saldi fase
	set   pdce_conto_saldo_errato=
    	   (case when fase.pdce_conto_segno=SEGNO_DARE and  fase.pdce_conto_dare-fase.pdce_conto_avere<0 then true
        	     when fase.pdce_conto_segno=SEGNO_AVERE and fase.pdce_conto_dare-fase.pdce_conto_avere>0 then true
            	 else false
	        end)
    where fase.fase_gen_elab_det_id=faseBilElabDetId;*/
	update fase_gen_t_elaborazione_fineanno_saldi fase
	set   pdce_conto_saldo_errato=
    	   (case when fase.pdce_conto_segno=SEGNO_DARE and  fase.pdce_conto_dare-fase.pdce_conto_avere<0 then true
        	     when fase.pdce_conto_segno=SEGNO_AVERE and fase.pdce_conto_dare-fase.pdce_conto_avere>0 then true
            	 else false
	        end)
    where fase.fase_gen_elab_det_id=faseBilElabDetId
    and   fase.pdce_conto_id!=pdceContoReeId;   -- 20.09.2017 Sofia letto da configurazione

    /*and   fase.pdce_conto_id not in (select pdce.pdce_conto_id
        			from siac_t_pdce_conto pdce
                    	where pdce.pdce_conto_code='2.1.4.01.01.01.001'
                        	and pdce.login_cancellazione is null);    */
/* ESCLUDERE IL CONTO -	Risultato economico esercizio 2.1.4.01.01.01.001  */

    strMessaggio:='Verifica esistenza saldi conti per saldi errati.';
    select count(*) into  saldiContiErrati
    from fase_gen_t_elaborazione_fineanno_saldi fasesaldi
	where  fasesaldi.fase_gen_elab_det_id=faseBilElabDetId
    and    fasesaldi.pdce_conto_saldo_errato=true;

    if saldiContiErrati is not null and saldiContiErrati!=0 then
    	strMessaggio:='Chiusura elaborazione step1 per esistenza conti con saldi errati.';

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
		set  fase_gen_det_elab_esito='KO',
         	 fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - SALDI ERRATI - TERMINE',
		     data_modifica=now(),
		     validita_fine=now(),
	      	 login_operazione=fasedet.login_operazione||'_TERMINE'
        where fasedet.fase_gen_elab_det_id=faseBilElabDetId;

        chiusuraStep:=false; 
    end if;

    if saldiContiErrati is null or saldiContiErrati=0 then
     strMessaggio:='Verifica saldi conti EPILOGO ECONOMICO-PATRIMONIALE.';
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

   	 select
    	 ( case when
		        sign(( sum( case when f.pdce_fam_code=COSTI_CLASSE and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
	            				 then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end) +
    				   sum( case when f.pdce_fam_code=RICAVI_CLASSE and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
				            	 then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end)
                      ) -
				     ( sum( case when f.pdce_fam_code=COSTI_CLASSE and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
					             then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end) +
				       sum( case when f.pdce_fam_code=RICAVI_CLASSE and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
					             then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end)
                     )
                    )=
			    sign((sum( case when f.pdce_fam_code in (PAS_PATR_CLASSE,OP_PATR_CLASSE) and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
						        then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end) +
			          sum( case when f.pdce_fam_code in (ATT_PATR_CLASSE,OA_PATR_CLASSE) and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
					            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end)
                      ) -
				     (sum( case when f.pdce_fam_code  in (PAS_PATR_CLASSE,OP_PATR_CLASSE) and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
					            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
				      sum( case when f.pdce_fam_code  in (ATT_PATR_CLASSE,OA_PATR_CLASSE) and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
					            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end
                         )
                     )
                    )
               then false else true  end
         ),
	     ( case when
			    abs(( sum( case when f.pdce_fam_code=COSTI_CLASSE and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
					            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end) +
				      sum( case when f.pdce_fam_code=RICAVI_CLASSE and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
					            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end)
                     ) -
				    ( sum( case when f.pdce_fam_code=COSTI_CLASSE and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
					            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end) +
				      sum( case when f.pdce_fam_code=RICAVI_CLASSE and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
					            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end)
                     ) )=
       			abs(( sum( case when f.pdce_fam_code in (PAS_PATR_CLASSE,OP_PATR_CLASSE) and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
					            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
			          sum( case when f.pdce_fam_code in (ATT_PATR_CLASSE,OA_PATR_CLASSE) and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
					            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end )
                     ) -
			        ( sum( case when f.pdce_fam_code  in (PAS_PATR_CLASSE,OP_PATR_CLASSE) and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
					            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
				      sum( case when f.pdce_fam_code  in (ATT_PATR_CLASSE,OA_PATR_CLASSE) and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
					            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end )
                    )
                   )
                then true else false end
          ) into saldoContiSegnoDiverso,saldoContiUguale
     from   fase_gen_t_elaborazione_fineanno_saldi fasesaldi,
            siac_t_pdce_conto pdce,
            siac_t_pdce_fam_tree ft,
            siac_d_pdce_fam f
     where fasesaldi.fase_gen_elab_det_id=faseBilElabDetId
     and   pdce.pdce_conto_id=fasesaldi.pdce_conto_id
     and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
     and   f.pdce_fam_id=ft.pdce_fam_id
     	-- Maurizio: escluso il conto 2.1.4.01.01.01.001 perchè trattato in modo diverso.
--     and   pdce.pdce_conto_code <> '2.1.4.01.01.01.001'
     and   pdce.pdce_conto_id!=pdceContoReeId -- 20.09.2017 Sofia letto da configurazione
     and   f.ente_proprietario_id=fasesaldi.ente_proprietario_id
     and   pdce.data_cancellazione is null
     and   pdce.validita_fine is null;
     /* ESCLUDERE IL CONTO -	Risultato economico esercizio 2.1.4.01.01.01.001  */

     if saldoContiSegnoDiverso is null or saldoContiUguale is null then
     	raise exception ' Errore in verifica.';
     end if;

     if saldoContiSegnoDiverso=false or saldoContiUguale=false then

     	strMessaggio:='Chiusura elaborazione step1 per esistenza conti con saldi errati.';
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
		set fase_gen_det_elab_esito='KO',
	    	fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - SALDI EPILOGO ECON. PATR. NON COERENTI - TERMINE',
	    	data_modifica=now(),
		    validita_fine=now(),
    		login_operazione=fasedet.login_operazione||'_TERMINE'
        where fasedet.fase_gen_elab_det_id=faseBilElabDetId;

		chiusuraStep:=false;
     end if;
    end if;


    -- 20.09.2017 Sofia  -- inizio

	if chiusuraStep=true then
     strMessaggio:='Lettura risultato economico di esercizio [CE]. ';
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

     select sum(fasesaldi.pdce_conto_dare)-sum(fasesaldi.pdce_conto_avere)
            into importoREEDare
     from   fase_gen_t_elaborazione_fineanno_saldi fasesaldi,
            siac_t_pdce_conto pdce,
            siac_t_pdce_fam_tree ft,
            siac_d_pdce_fam f
     where fasesaldi.fase_gen_elab_det_id=faseBilElabDetId
     and   pdce.pdce_conto_id=fasesaldi.pdce_conto_id
     and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
     and   f.pdce_fam_id=ft.pdce_fam_id
     and   f.pdce_fam_code=COSTI_CLASSE
     and   pdce.pdce_conto_id!=pdceContoReeId
     and   f.ente_proprietario_id=fasesaldi.ente_proprietario_id
     and   pdce.data_cancellazione is null
     and   pdce.validita_fine is null;

     strMessaggio:='Lettura risultato economico di esercizio [RE]. ';
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

     select sum(fasesaldi.pdce_conto_avere)-sum(fasesaldi.pdce_conto_dare)
            into importoREEAvere
     from   fase_gen_t_elaborazione_fineanno_saldi fasesaldi,
            siac_t_pdce_conto pdce,
            siac_t_pdce_fam_tree ft,
            siac_d_pdce_fam f
     where fasesaldi.fase_gen_elab_det_id=faseBilElabDetId
     and   pdce.pdce_conto_id=fasesaldi.pdce_conto_id
     and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
     and   f.pdce_fam_id=ft.pdce_fam_id
     and   f.pdce_fam_code=RICAVI_CLASSE
     and   pdce.pdce_conto_id!=pdceContoReeId
     and   f.ente_proprietario_id=fasesaldi.ente_proprietario_id
     and   pdce.data_cancellazione is null
     and   pdce.validita_fine is null;

	 if importoREEDare!=importoREEAvere then
 	  if importoREEDare>importoREEAvere then
     	isPerdita:=true;
      else
        isUtile:=true;
      end if;
     end if;
   end if;
   -- 20.09.2017 Sofia  - fine



/*
Se passati i controlli:
-	rilevazione perdita : si incrementa l’importo dare del conto per il valore della perdita rilevata
-	rilevazione utile : si incrementa l’importa avere del contro per il valore dell’utile rilevato
Infine in seguito all’aggiornamento il saldo dei conti patrimoniali deve essere zero.

Maurizio:
Da documento WORD:
Pertanto in merito al conto 2.1.4.01.01.01.001 (risultato economico esercizio) si procede ulteriormente aggiornandone il saldo nel seguente modo
-	rilevazione perdita : si incrementa l’importo dare del conto per il valore della perdita rilevata
-	rilevazione utile : si incrementa l’importo avere del contro per il valore dell’utile rilevato

Il conto 2.1.4.01.01.01.001 è di passività, quindi la perdita è quando
Avere è maggiore di Dare???
Utile se Dare è > avere???

Se perdita sommo a DARE l'importo di differenza Avere -Dare. E' GIUSTO???
Se utile sommo ad AVERE l'importo di differenza Dare  -Avere. E' GIUSTO???
*/
    -- 20.09.2017 Sofia - inizio

   	if isPerdita=true then

	 strMessaggio:='Aggiornamento del conto 2.1.4.01.01.01.001 - perdita ';
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

 	 -- PERDITA
     UPDATE fase_gen_t_elaborazione_fineanno_saldi
     SET pdce_conto_dare = pdce_conto_dare + (importoREEDare-importoREEAvere)
--     	 abs(pdce_conto_avere - pdce_conto_dare)
     WHERE fase_gen_elab_det_id=faseBilElabDetId
    	and ente_proprietario_id=enteproprietarioid
        and pdce_conto_id=pdceContoReeId;
/*    	AND pdce_conto_id in (select pdce.pdce_conto_id
        			from siac_t_pdce_conto pdce
                    	where pdce.pdce_conto_code='2.1.4.01.01.01.001'
                        	and pdce.ente_proprietario_id=enteproprietarioid
                        	and pdce.login_cancellazione is null)
          AND  pdce_conto_avere >pdce_conto_dare;*/
    end if;

    if isUtile=true then
     strMessaggio:='Aggiornamento del conto 2.1.4.01.01.01.001 - utile ';
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

 	 --UTILE
     UPDATE fase_gen_t_elaborazione_fineanno_saldi
     SET pdce_conto_avere = pdce_conto_avere + (importoREEAvere-importoREEDare)
--    	abs(pdce_conto_dare - pdce_conto_avere)
     WHERE fase_gen_elab_det_id=faseBilElabDetId
    	and ente_proprietario_id=enteproprietarioid
        and pdce_conto_id=pdceContoReeId;
/*
    	AND pdce_conto_id in (select pdce.pdce_conto_id
        			from siac_t_pdce_conto pdce
                    	where pdce.pdce_conto_code='2.1.4.01.01.01.001'
                        	and pdce.ente_proprietario_id=enteproprietarioid
                        	and pdce.login_cancellazione is null)
          AND  pdce_conto_dare >pdce_conto_avere;*/


    end if;
   -- 20.09.2017 Sofia - fine

 /*      -- 20.09.2017 Sofia  commentato - a cosa serve ??

    /* Maurizio: verifica se il saldo patrimoniale è 0.
        	E' CORRETTO????*/
	 strMessaggio:='Verifica del saldo patrimoniale';
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
    select sum(fasesaldi.pdce_conto_avere),sum(fasesaldi.pdce_conto_dare)
    into 	importoTotSaldoAvere, importoTotSaldoDare
    from fase_gen_t_elaborazione_fineanno_saldi fasesaldi
	where  fasesaldi.fase_gen_elab_det_id=faseBilElabDetId;

    if importoTotSaldoAvere is null or importoTotSaldoDare is null then
     	raise exception ' Errore in verifica saldo finale.';
    end if;

    if importoTotSaldoAvere <> importoTotSaldoDare then
    		/* se gli importi sono diversi chiudo l'eleborazione */
        strMessaggio:='Chiusura elaborazione step1 per saldo errato. Dare = '||importoTotSaldoDare||' - Avere = '||importoTotSaldoAvere;
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
    	/* COMMENTATO PER LE PROVE
    	update  fase_gen_t_elaborazione_fineanno_det fasedet
		set fase_gen_det_elab_esito='KO',
	    	fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - SALDO FINALE ERRATO - TERMINE',
	    	data_modifica=now(),
		    validita_fine=now(),
    		login_operazione=fasedet.login_operazione||'_TERMINE'
        where fasedet.fase_gen_elab_det_id=faseBilElabDetId;

		chiusuraStep:=false;*/

    end if; */

    if chiusuraStep=true then

	    strMessaggio:='Chiusura elaborazione step1 OK.';
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

	    update fase_gen_t_elaborazione_fineanno_det fasedet
	    set fase_gen_det_elab_esito='OK',
    	    fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - OK - TERMINE',
       		data_modifica=now(),
    		login_operazione=fasedet.login_operazione||'_TERMINE'
	    where fasedet.fase_gen_elab_det_id=faseBilElabDetId;

        codiceRisultato:=0;
	    messaggioRisultato:=strMessaggioFinale||' FINE OK.';
    else
        codiceRisultato:=1;
	    messaggioRisultato:=strMessaggioFinale||StrMessaggio||' FINE KO.';
    end if;


    codResult:=null;
	insert into fase_gen_t_elaborazione_fineanno_log
    (fase_gen_elab_id,fase_gen_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,messaggioRisultato,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_gen_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    faseBilElabDetRetId:=faseBilElabDetId;

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