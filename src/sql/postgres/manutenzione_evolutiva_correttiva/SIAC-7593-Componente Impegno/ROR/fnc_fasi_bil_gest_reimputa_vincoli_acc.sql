/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_fasi_bil_gest_reimputa_vincoli_acc
(
  enteproprietarioid integer,
  annobilancio integer,
  faseBilElabId integer,
  annoImpegnoRiacc integer,   -- annoImpegno riaccertato
  movgestTsImpNewId integer,  -- movgest_id_id impegno riaccertato
  avavRiaccImpId   integer,        -- avav_id nuovo
  importoVincoloRiaccertato numeric, -- importo totale vincolo impegno riaccertato
  faseBilElabReAccId integer, -- faseId di elaborazione riaccertmaento Acc
  tipoMovGestAccId integer,   -- tipoMovGestId Accertamenti
  movgestTsAccPrecId integer, -- movgest_ts_id accertamento anno precedente vincolato a impegno riaccertato
  loginoperazione varchar,
  dataelaborazione timestamp,
  out numeroVincoliCreati integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    daVincolare numeric:=0;
    importoVinc numeric:=0;
    totVincolato numeric:=0;

    daCancellare BOOLEAN:=false;
    movGestRec record;

    numeroVinc   integer:=0;
BEGIN

    codiceRisultato:=null;
    messaggioRisultato:=null;
    numeroVincoliCreati:=0;

	strMessaggioFinale:='Reimputazione vincoli su accertamento riacc. Anno bilancio='
                     ||annoBilancio::varchar
                     ||' per impegno riacc movgest_ts_id='||movgestTsImpNewId::varchar
                     ||' per avav_id='||avavRiaccImpId::varchar
                     ||' per importo vincolo='||importoVincoloRiaccertato::varchar||'.';

    raise notice 'strMessaggioFinale=%',strMessaggioFinale;
    strMessaggio:='Inizio elaborazione.';
    insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
	values
    (faseBilElabId,strMessaggioFinale||' - INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	returning fase_bil_elab_log_id into codResult;

	if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	end if;

    daVincolare:=importoVincoloRiaccertato;
	for movGestRec in
	(
	 with
	 accPrec as
	 (-- accertamento vincolato in annoBilancio-1
	  select mov.movgest_anno::integer anno_accertamento,
  			 mov.movgest_numero::integer numero_accertamento,
	         (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
    	     mov.movgest_id, ts.movgest_ts_id
	  from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
    	   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
	  where ts.movgest_ts_id=movgestTsAccPrecId
      and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   mov.movgest_id=ts.movgest_id
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
 	 accCurRiacc as
	 (-- accertamenti riaccertati per accPrec in annoBilancio
	  select mov.movgest_anno::integer anno_accertamento,
    	     mov.movgest_numero::integer numero_accertamento,
	 	     (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
		     mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
	  from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
   		   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase,siac_d_movgest_stato stato,
           siac_t_bil bil,siac_t_periodo per
	  where bil.ente_proprietario_id=enteProprietarioId
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=annoBilancio
      and   mov.bil_id=bil.bil_id
	  and   mov.movgest_tipo_id=tipoMovGestAccId
	  and   ts.movgest_id=mov.movgest_id
      and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
	  and   fase.fasebilelabid=faseBilElabReAccId
	  and   fase.fl_elab is not null and fase.fl_elab!=''
	  and   fase.fl_elab='S'
	  and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
	  and   mov.movgest_anno::integer<=annoImpegnoRiacc
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	),
	accUtilizzabile as
	(-- utlizzabile per accertamento
	 select det.movgest_ts_id, det.movgest_ts_det_importo importo_utilizzabile
	 from siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
	 where tipo.ente_proprietario_id=enteProprietarioId
	 and   tipo.movgest_ts_det_tipo_code='U'
	 and   det.movgest_ts_det_tipo_id= tipo.movgest_ts_det_tipo_id
	 and   det.data_cancellazione is null
	 and   det.validita_fine is null
	),
	vincolato as
	(-- vincolato per accertamento
	 select r.movgest_ts_a_id, sum(r.movgest_ts_importo) totale_vincolato
     from siac_r_movgest_ts r
	 where r.ente_proprietario_id=enteProprietarioId
	 and   r.data_cancellazione is null
	 and   r.validita_fine is null
     and   r.movgest_ts_a_id is not null
	 group by r.movgest_ts_a_id
	)
	select   accCurRiacc.anno_accertamento,
    	     accCurRiacc.numero_accertamento,
        	 accCurRiacc.numero_subaccertamento,
	         accUtilizzabile.importo_utilizzabile,
    	     coalesce(vincolato.totale_vincolato,0) totale_vincolato,
	         accUtilizzabile.importo_utilizzabile -  coalesce(vincolato.totale_vincolato,0) dispVincolabile,
    	     accCurRiacc.movgest_ts_new_id movgest_ts_riacc_id
	from accPrec, accUtilizzabile,
    	 accCurRiacc
	       left join vincolato on (accCurRiacc.movgest_ts_new_id=vincolato.movgest_ts_a_id)
	where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
    and   accUtilizzabile.movgest_ts_id=accCurRiacc.movgest_ts_new_id
	order by  accCurRiacc.anno_accertamento,
	          accCurRiacc.numero_accertamento,
	          accCurRiacc.numero_subaccertamento
	)
	loop
	   --daVincolare:=importoVincoloRiaccertato-(totVincolato);
       raise notice 'daVincolare=%',daVincolare;
	   raise notice 'dispVincolabile=%',movGestRec.dispVincolabile;
	   if daVincolare >= movGestRec.dispVincolabile then
   	        importoVinc:=movGestRec.dispVincolabile;
   	   else importoVinc:=daVincolare;
	   end if;

       raise notice 'importoVinc=%',importoVinc;

	   codResult:=null;
       strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - quota vincolo='||importoVinc::varchar||'.';
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

	   if importoVinc>0 then

        codResult:=null;
        update siac_r_movgest_ts rs
        set    movgest_ts_importo=rs.movgest_ts_importo+importoVinc,
               data_modifica=clock_timestamp()
        where rs.movgest_ts_b_id=movgestTsImpNewId
        and   rs.movgest_ts_a_id=movGestRec.movgest_ts_riacc_id
        and   rs.data_cancellazione is null
        and   rs.validita_fine is null
        returning movgest_ts_r_id into codResult;

        if codResult is null then
          --codResult:=null;
          -- insert into siac_r_movgest_ts
          insert into siac_r_movgest_ts
          (
              movgest_ts_a_id,
              movgest_ts_b_id,
              movgest_ts_importo,
             -- avav_id, 21.02.2018 Sofia
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          values
          (
              movGestRec.movgest_ts_riacc_id,
              movgestTsImpNewId,
              importoVinc,
             -- avavRiaccImpId, 21.02.2018 Sofia
              clock_timestamp(),
              loginOperazione,
              enteProprietarioId
          )
          returning movgest_ts_r_id into codResult;
        end if;

        if codResult is null then
        	daCancellare:=true;
        else numeroVinc:=numeroVinc+1;
        end if;
	--   else 	daCancellare:=true;
   	   end if;

       totVincolato:=totVincolato+importoVinc;
  	   daVincolare:=importoVincoloRiaccertato-(totVincolato);
       raise notice 'daVincolare=%',daVincolare;

	   exit when daVincolare<=0 or daCancellare=true;
	end loop;
       raise notice 'daVincolare=%',daVincolare;
       raise notice 'daCancellare=%',daCancellare;

	if daCancellare=false and daVincolare>0 then
    	codResult:=null;
        strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - quota vincolo residuo='||daVincolare::varchar||'.';
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

		-- insert into
        codResult:=null;
        update siac_r_movgest_ts rs
        set    movgest_ts_importo=rs.movgest_ts_importo+daVincolare,
               data_modifica=clock_timestamp()
        where rs.movgest_ts_b_id=movgestTsImpNewId
        and   rs.avav_id=avavRiaccImpId
        and   rs.data_cancellazione is null
        and   rs.validita_fine is null
        returning movgest_ts_r_id into codResult;

        if codResult is null then
          insert into siac_r_movgest_ts
          (
              movgest_ts_b_id,
              avav_id,
              movgest_ts_importo,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          values
          (
              movgestTsImpNewId,
              avavRiaccImpId,
              daVincolare,
              clock_timestamp(),
              loginOperazione,
              enteProprietarioId
          )
          returning movgest_ts_r_id into codResult;
        end if;
        raise notice 'codResult=%',codResult;

        if codResult is null then
	       	daCancellare:=true;
        else numeroVinc:=numeroVinc+1;
        end if;

	end if;

    if daCancellare = true then
    	codResult:=null;
        strMessaggio:='Accertamento da riacc movgest_ts_id='||movgestTsAccPrecId::varchar
                    ||' - accertamento riacc movgest_ts_id='||movGestRec.movgest_ts_riacc_id::varchar
                    ||' - annullamento quote inserite.';
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

    	delete  from siac_r_movgest_ts r
        where r.ente_proprietario_id=enteProprietarioId
        and   r.movgest_ts_b_id=movgestTsImpNewId
        and   r.login_operazione=loginOperazione
        and   r.data_cancellazione is null
        and   r.validita_fine is null;
        numeroVinc:=0;
    end if;

	strMessaggio:=' - Vincoli inseriti num='||numeroVinc::varchar;
	insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
	values
    (faseBilElabId,strMessaggioFinale||strMessaggio||' - FINE .',clock_timestamp(),loginOperazione,enteProprietarioId)
	returning fase_bil_elab_log_id into codResult;

	if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	end if;


    codiceRisultato:=0;
    numeroVincoliCreati:=numeroVinc;
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
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;