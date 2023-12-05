/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_allinea_res_imp
(
  annobilancio           integer,
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

    strRec record;

    APE_GEST_IMP_RES  CONSTANT varchar:='APE_GEST_IMP_RES';

	totaleResAggiornato numeric:=0;
    totaleResCalcolato numeric:=0;
BEGIN


	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Allineamento impegni residui.';



    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_IMP_RES||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_IMP_RES
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
	/*strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_IMP_RES||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, clock_timestamp(), loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_IMP_RES
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
     end if;*/


    /*strMessaggio:='Inserimento LOG.';
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
    end if;*/



    strmessaggio:='Calcola impegni residui.';
    select * into strRec
    from fnc_fasi_bil_gest_apertura_imp_popola
    (enteproprietarioid,
     annobilancio,
     loginoperazione,
	 dataelaborazione
    );
    if strRec.codiceRisultato=0 then
    	faseBilElabId:=strRec.faseBilElabRetId;
    else
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
    end if;


    if codiceRisultato=0 then

     strMessaggio:='Allineamento impegni residui : importo_res diverso da attuale.Allinea attuale';
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

     update siac_t_movgest_ts_det det
	 set    movgest_ts_det_importo=QUERY.importo_residuo,
            data_modifica=clock_timestamp(),
--            login_operazione=det.login_operazione||'-'||loginOperazione||'-ALLINEA-ATT-'||faseBilElabId::varchar
            login_operazione=loginOperazione||'-ALLINEA-ATT-'||faseBilElabId::varchar

     from
     (

      with
	  residui2017 as
	  (
	   select distinct mov.movgest_anno::integer anno_impegno, mov.movgest_numero::integer numero_impegno,
      	     (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) numero_subimpegno,
	         fase.imp_importo importo_residuo,
	         fase.movgest_orig_ts_id,
      	     fase.fl_elab
	   from fase_bil_t_gest_apertura_liq_imp fase,
      	    siac_t_movgest mov, siac_d_movgest_tipo tipo,
	        siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots
	   where fase.fase_bil_elab_id=faseBilElabId
	   and   mov.movgest_id=fase.movgest_orig_id
	   and   ts.movgest_ts_id=fase.movgest_orig_ts_id
	   and   ts.movgest_id=mov.movgest_id
	   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	   and   ts.movgest_ts_tipo_id=tipots.movgest_ts_tipo_id
	   and   mov.data_cancellazione is null
	   and   fase.fl_elab!='X'
	   order by 1,2,3
	  ),
	  residui2018 as
	  (
	   select distinct mov.movgest_anno::integer anno_impegno,mov.movgest_numero::integer numero_impegno,
             (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) numero_subimpegno,
	         stato.movgest_stato_code,
	         det.movgest_ts_det_importo importo_attuale,
             det.movgest_ts_det_id
	   from siac_t_movgest mov, siac_d_movgest_tipo tipo, siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
	        siac_v_bko_anno_bilancio anno,
	        siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
	        siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod
	    where tipo.ente_proprietario_id=enteProprietarioId
	    and   tipo.movgest_tipo_code='I'
	    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	    and   ts.movgest_id=mov.movgest_id
	    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	    and   anno.bil_id=mov.bil_id
	    and   anno.anno_bilancio=annoBilancio
	    and   mov.movgest_anno::integer<anno.anno_bilancio
	    and   rs.movgest_ts_id=ts.movgest_ts_id
	    and   stato.movgest_stato_id=rs.movgest_stato_id
	    and   stato.movgest_stato_code!='A'
	    and   det.movgest_ts_id=ts.movgest_ts_id
	    and   tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
	    and   tipod.movgest_ts_det_tipo_code='A'
	    and   rs.data_cancellazione is null
	    and   rs.validita_fine is null
	    and   mov.data_cancellazione is null
	    order by 1,2,3
	   )
	   select residui2017.anno_impegno,
              residui2017.numero_impegno,
	          residui2017.numero_subimpegno,
      	      residui2017.importo_residuo,
	          residui2018.anno_impegno,
	          residui2018.numero_impegno,
	          residui2018.numero_subimpegno,
	          residui2018.importo_attuale,
	          residui2017.movgest_orig_ts_id,
	          residui2017.fl_elab,
	          residui2018.movgest_ts_det_id
	   from residui2017,residui2018
	   where residui2017.anno_impegno=residui2018.anno_impegno
	   and   residui2017.numero_impegno=residui2018.numero_impegno
	   and   residui2017.numero_subimpegno=residui2018.numero_subimpegno
	   and   residui2017.importo_residuo!=residui2018.importo_attuale
	 )
	 QUERY
	 where det.ente_proprietario_id=enteProprietarioId
	 and   det.movgest_ts_det_id=QUERY.movgest_ts_det_id;


     strMessaggio:='Allineamento impegni residui : importo_res diverso da attuale.Azzera attuale';
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

     update siac_t_movgest_ts_det det
	 set    movgest_ts_det_importo=0,
     	    data_modifica=clock_timestamp(),
--       	    login_operazione=det.login_operazione||'-'||loginOperazione||'-AZZERA-ATT-'||faseBilElabId::varchar
       	    login_operazione=loginOperazione||'-AZZERA-ATT-'||faseBilElabId::varchar

 	 from
	 (
	  with
	  residui2017 as
	  (
	   select distinct mov.movgest_anno::integer anno_impegno, mov.movgest_numero::integer numero_impegno,
             (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) numero_subimpegno,
	         fase.imp_importo importo_residuo,
	         fase.movgest_orig_ts_id
	   from fase_bil_t_gest_apertura_liq_imp fase,
	        siac_t_movgest mov, siac_d_movgest_tipo tipo,
	        siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots
	   where fase.fase_bil_elab_id=faseBilElabId
	   and   mov.movgest_id=fase.movgest_orig_id
	   and   ts.movgest_ts_id=fase.movgest_orig_ts_id
	   and   ts.movgest_id=mov.movgest_id
	   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	   and   ts.movgest_ts_tipo_id=tipots.movgest_ts_tipo_id
	   and   mov.data_cancellazione is null
	   order by 1,2,3
	  ),
	  residui2018 as
	  (
	   select distinct mov.movgest_anno::integer anno_impegno,mov.movgest_numero::integer numero_impegno,
       	     (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) numero_subimpegno,
	         stato.movgest_stato_code,
	         det.movgest_ts_det_importo importo_attuale,
	         det.movgest_ts_det_id
	   from siac_t_movgest mov, siac_d_movgest_tipo tipo, siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
	        siac_v_bko_anno_bilancio anno,
	        siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
	        siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod
	   where tipo.ente_proprietario_id=enteProprietarioId
	   and   tipo.movgest_tipo_code='I'
	   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	   and   ts.movgest_id=mov.movgest_id
	   and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	   and   anno.bil_id=mov.bil_id
	   and   anno.anno_bilancio=annoBilancio
	   and   mov.movgest_anno::integer<anno.anno_bilancio
	   and   rs.movgest_ts_id=ts.movgest_ts_id
	   and   stato.movgest_stato_id=rs.movgest_stato_id
	   and   stato.movgest_stato_code!='A'
	   and   det.movgest_ts_id=ts.movgest_ts_id
	   and   tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
	   and   tipod.movgest_ts_det_tipo_code='A'
	   and   rs.data_cancellazione is null
	   and   rs.validita_fine is null
	   and   mov.data_cancellazione is null
	   order by 1,2,3
	  )
	  select residui2017.anno_impegno,
       	     residui2017.numero_impegno,
	         residui2017.numero_subimpegno,
	         residui2017.importo_residuo,
	         residui2018.anno_impegno,
      	     residui2018.numero_impegno,
	         residui2018.numero_subimpegno,
     	     residui2018.importo_attuale,
	         residui2017.movgest_orig_ts_id,
             residui2018.movgest_ts_det_id
      from residui2018
      	   left join  residui2017 on -- passati 2018 da abbattere
	       (residui2017.anno_impegno=residui2018.anno_impegno
	        and   residui2017.numero_impegno=residui2018.numero_impegno
	        and   residui2017.numero_subimpegno=residui2018.numero_subimpegno)
	  where residui2017.importo_residuo is null
	  order by 1,2,3
	 )
	 QUERY
	 where det.ente_proprietario_id=enteProprietarioId
  	 and   det.movgest_ts_det_id=QUERY.movgest_ts_det_id;


     strMessaggio:='Allineamento impegni residui : importo_res diverso da attuale.Allinea-azzera iniziale';
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

     update siac_t_movgest_ts_det det
	 set    movgest_ts_det_importo=QUERY.importo_attuale,
            data_modifica=clock_timestamp(),
--            login_operazione=det.login_operazione||'-'||loginOperazione||'-ALLINEA-AZZERA-INI-'||faseBilElabId::varchar
            login_operazione=loginOperazione||'-ALLINEA-AZZERA-INI-'||faseBilElabId::varchar

	 from
	 (
	  with
	  resAtt as
	  (
	   select distinct mov.movgest_anno::integer anno_impegno,mov.movgest_numero::integer numero_impegno,
        	  (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) numero_subimpegno,
	          stato.movgest_stato_code,
	          det.movgest_ts_det_importo importo_attuale,
	          det.movgest_ts_det_id,
	          det.movgest_ts_id
	   from siac_t_movgest mov, siac_d_movgest_tipo tipo, siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
	        siac_v_bko_anno_bilancio anno,
	        siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
	        siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod
	   where tipo.ente_proprietario_id=enteProprietarioId
	   and   tipo.movgest_tipo_code='I'
	   and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	   and   ts.movgest_id=mov.movgest_id
	   and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	   and   anno.bil_id=mov.bil_id
	   and   anno.anno_bilancio=annoBilancio
	   and   mov.movgest_anno::integer<anno.anno_bilancio
	   and   rs.movgest_ts_id=ts.movgest_ts_id
	   and   stato.movgest_stato_id=rs.movgest_stato_id
	   and   stato.movgest_stato_code!='A'
	   and   det.movgest_ts_id=ts.movgest_ts_id
	   and   tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
	   and   tipod.movgest_ts_det_tipo_code='A' --loginOperazione||'-AZZERA-ATT-'||faseBilElabId::varchar
	   and   det.login_operazione like '%'||loginOperazione||'%ATT%'||faseBilElabId::varchar
	   and   rs.data_cancellazione is null
	   and   rs.validita_fine is null
	   and   mov.data_cancellazione is null
	   order by 1,2,3
	  ),
	  resIni as
	  (
	   select det.movgest_ts_det_id, det.movgest_ts_id, det.movgest_ts_det_importo
	   from siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
	   where tipo.ente_proprietario_id=enteProprietarioId
	   and   tipo.movgest_ts_det_tipo_code='I'
	   and   det.movgest_ts_det_tipo_id=tipo.movgest_ts_det_tipo_id
	  )
	  select resatt.*, resIni.movgest_ts_det_id movgest_ts_det_id_ini, resIni.movgest_ts_det_importo
	  from resAtt, resIni
	  where resAtt.movgest_ts_id=resIni.movgest_ts_id
	  )
	 QUERY
     where det.ente_proprietario_id=enteProprietarioId
	 and   det.movgest_ts_det_id=QUERY.movgest_ts_det_id_ini;



     strMessaggio:='Allineamento impegni residui : inserimento nuovi residui.Aggiorna fase_bil_t_gest_apertura_liq_imp.';
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


	 update  fase_bil_t_gest_apertura_liq_imp fase
	 set     fl_elab='W'
	 where fase.fase_bil_elab_id=faseBilElabId
	 and   fase.fl_elab='N'
	 and   not EXISTS
	 (
	 with
	 residui2017 as
	 (
	 select distinct mov.movgest_anno::integer anno_impegno, mov.movgest_numero::integer numero_impegno,
    	   (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) numero_subimpegno,
	       fase.imp_importo importo_residuo,
    	   fase.movgest_orig_ts_id,
	       fase.fl_elab,
    	   fase.fase_bil_gest_ape_liq_imp_id
	 from fase_bil_t_gest_apertura_liq_imp fase,
    		 siac_t_movgest mov, siac_d_movgest_tipo tipo,
      	 siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots
 	 where fase.fase_bil_elab_id=faseBilElabId
	 and   mov.movgest_id=fase.movgest_orig_id
	 and   ts.movgest_ts_id=fase.movgest_orig_ts_id
	 and   ts.movgest_id=mov.movgest_id
	 and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	 and   ts.movgest_ts_tipo_id=tipots.movgest_ts_tipo_id
	 and   mov.data_cancellazione is null
	 and   fase.fl_elab!='X'
	 order by 1,2,3
	 ),
	 residui2018 as
	 (
	  select distinct mov.movgest_anno::integer anno_impegno,mov.movgest_numero::integer numero_impegno,
	       (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) numero_subimpegno,
    	   stato.movgest_stato_code,
	       det.movgest_ts_det_importo importo_attuale
	  from siac_t_movgest mov, siac_d_movgest_tipo tipo, siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
	       siac_v_bko_anno_bilancio anno,
	       siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
     	  siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod
	  where tipo.ente_proprietario_id=enteProprietarioId
  	  and   tipo.movgest_tipo_code='I'
	  and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	  and   ts.movgest_id=mov.movgest_id
	  and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   anno.bil_id=mov.bil_id
	  and   anno.anno_bilancio=annoBilancio
	  and   mov.movgest_anno::integer<anno.anno_bilancio
	  and   rs.movgest_ts_id=ts.movgest_ts_id
	  and   stato.movgest_stato_id=rs.movgest_stato_id
	  and   stato.movgest_stato_code!='A'
	  and   det.movgest_ts_id=ts.movgest_ts_id
	  and   tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
	  and   tipod.movgest_ts_det_tipo_code='A'
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is NULL
	  order by 1,2,3
     )
     select residui2017.anno_impegno,
   	  	    residui2017.numero_impegno,
	        residui2017.numero_subimpegno,
    	    residui2017.importo_residuo,
	        residui2018.anno_impegno,
    	    residui2018.numero_impegno,
		    residui2018.numero_subimpegno,
	        residui2018.importo_attuale,
	        residui2017.movgest_orig_ts_id,
	        residui2017.fl_elab,
    	    residui2017.fase_bil_gest_ape_liq_imp_id
	  from residui2017
      	   left join  residui2018 on -- non passati da inserire 2018
	       (residui2017.anno_impegno=residui2018.anno_impegno
	  and   residui2017.numero_impegno=residui2018.numero_impegno
	  and   residui2017.numero_subimpegno=residui2018.numero_subimpegno)
	  where residui2018.importo_attuale is null
	  and   residui2017.fase_bil_gest_ape_liq_imp_id=fase.fase_bil_gest_ape_liq_imp_id
     );

	 codResult:=null;
	 select count(*) into codResult
     from  fase_bil_t_gest_apertura_liq_imp fase
	 where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fl_elab='N';
     if coalesce(codResult)!=0 then

	  strMessaggio:='Allineamento impegni residui : inserimento nuovi residui.Esecuzione fnc_fasi_bil_gest_apertura_liq_elabora_imp.';
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

      strMessaggio:='Crea impegni nuovi residui.';
   	  select * into strRec
      from fnc_fasi_bil_gest_apertura_liq_elabora_imp
          (enteProprietarioId,
	       annoBilancio,
           APE_GEST_IMP_RES,
	       faseBilElabId,
	 	   0,--minId,
		   0,--maxId
	       loginOperazione,
	       dataElaborazione
          );
      if strRec.codiceRisultato!=0 then
	  	strMessaggio:=strRec.messaggioRisultato;
    	codiceRisultato:=strRec.codiceRisultato;
      end if;
     end if;

    end if;




 	if codiceRisultato=0 then
     strMessaggio:='Allineamento impegni residui : calcolo totale residuo aggiornato.';
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

     select --tipots.movgest_ts_tipo_code,
      	    sum(det.movgest_ts_det_importo) importo_res into totaleResAggiornato
	 from siac_v_bko_anno_bilancio anno, siac_t_movgest mov, siac_d_movgest_tipo tipo,
     	  siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
	      siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     	  siac_r_movgest_ts_stato rs, siac_d_movgest_Stato stato
	 where tipo.ente_proprietario_id=enteProprietarioid
	 and   tipo.movgest_tipo_code='I'
	 and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	 and   anno.bil_id=mov.bil_id
	 and   anno.anno_bilancio=annoBilancio
	 and   mov.movgest_anno::INTEGER<annoBilancio
	 and   ts.movgest_id=mov.movgest_id
	 and   det.movgest_ts_id=ts.movgest_ts_id
	 and   tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
	 and   tipod.movgest_ts_det_tipo_code='A'
	 and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	 and   tipots.movgest_ts_tipo_code='T'
	 and   rs.movgest_ts_id=ts.movgest_ts_id
	 and   stato.movgest_stato_id=rs.movgest_stato_id
	 and   stato.movgest_stato_code!='A'
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 and   mov.data_cancellazione is null;
--	 group by  tipots.movgest_ts_tipo_code

	 strMessaggio:='Allineamento impegni residui : calcolo totale residuo ricalcolato.';
     codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;

	 select --tipots.movgest_ts_tipo_code,
            sum(fase.imp_importo) into totaleResCalcolato
	 from fase_bil_t_gest_apertura_liq_imp fase,
     	  siac_t_movgest mov, siac_d_movgest_tipo tipo,
	      siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots
	 where fase.fase_bil_elab_id=faseBilElabId
	 and   mov.movgest_id=fase.movgest_orig_id
	 and   ts.movgest_ts_id=fase.movgest_orig_ts_id
	 and   ts.movgest_id=mov.movgest_id
	 and   mov.movgest_tipo_id=tipo.movgest_tipo_id
	 and   ts.movgest_ts_tipo_id=tipots.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
	 and   mov.data_cancellazione is null
	 and   fase.fl_elab!='X';
	 --group by tipots.movgest_ts_tipo_code

    end if;

    strMessaggio:='Aggiornamento stato fase bilancio OK.';
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

    if codiceRisultato=0 then

       if coalesce(totaleResCalcolato,0)!=coalesce(totaleResAggiornato) then
        update fase_bil_t_elaborazione
        set fase_bil_elab_esito='OK',
            fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_IMP_RES||'TERMINATA CON SUCCESSO.'
                                    ||'Totale residuo aggiornato diverso da quello calcolato.',
            validita_fine=clock_timestamp()
        where fase_bil_elab_id=faseBilElabId;
       else
        update fase_bil_t_elaborazione
        set fase_bil_elab_esito='OK',
            fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_IMP_RES||'TERMINATA CON SUCCESSO.'
                                    ||'Totale residuo aggiornato uguale a quello calcolato.',
            validita_fine=clock_timestamp()
        where fase_bil_elab_id=faseBilElabId;
       end if;

    else
       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_IMP_RES||'TERMINATA CON ERRORE.',
           validita_fine=clock_timestamp()
       where fase_bil_elab_id=faseBilElabId;
	end if;

	strMessaggio:='Inserimento LOG.';
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

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
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
