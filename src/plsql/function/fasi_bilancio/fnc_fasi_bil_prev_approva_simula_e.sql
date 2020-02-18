/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

--03.04.2017 Sofia duplicazione per gestione entrata
CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_approva_simula_e (
  annobilancio integer,
  bilelemprevtipo varchar,
  bilelemgesttipo varchar,
  enteproprietarioid integer,
  loginoperazione varchar,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
 STA_IMPORTO_TIPO CONSTANT  varchar:='STA';
 SCA_IMPORTO_TIPO CONSTANT  varchar:='SCA';
 APPROVA_PREV_SIM CONSTANT varchar:='APROVA_PREV_SIM';

 PROGRAMMA_CL CONSTANT  varchar:='PROGRAMMA';
 MACRO_CL     CONSTANT  varchar:='MACROAGGREGATO';
 CATEGORIA_CL CONSTANT  varchar:='CATEGORIA';
 PDC_IV_CL CONSTANT  varchar:='PDC_IV';
 PDC_V_CL CONSTANT  varchar:='PDC_V';

 CAP_UG_TIPO CONSTANT  varchar:='CAP-UG';
 CAP_UP_TIPO CONSTANT  varchar:='CAP-UP';
 TIPO_ORD_P  CONSTANT  varchar:='P';
 TIPO_ORD_I  CONSTANT  varchar:='I';

 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 codResult         integer:=null;
 dataInizioVal     timestamp:=null;
 faseBilElabId     integer:=null;
 elemDetTipoStaId  integer:=null;
 elemDetTipoScaId  integer:=null;
 periodoTipoId     integer:=null;
 elemTipoPrevId    integer:=null;
 elemTipoGestId    integer:=null;

 tipoOrd varchar(10):=null;
 elemTipo char(1):=null;
 programmaTipoId integer:=null;
 macroTipoId     integer:=null;
 categoriaTipoId integer:=null;
 pdcFinIVTipoId  integer:=null;
 pdcFinVTipoId   integer:=null;

 -- 04.11.2016 anto JIRA-SIAC-4161
    bilElemStatoAN CONSTANT varchar:='AN';
    -- 04.11.2016 anto JIRA-SIAC-4161
	bilElemStatoANId  integer:=null;

    -- anto JIRA-SIAC-4167 15.11.2016
    dataInizioValClass timestamp:=null;
    dataFineValClass   timestamp:=null;

begin

 messaggioRisultato:='';
 codiceRisultato:=0;
 faseBilElabIdRet:=0;

 dataInizioVal:= clock_timestamp();

 -- 12.12.2016 Sofia JIRA-SIAC-4167
 dataInizioValClass:= clock_timestamp();
 dataFineValClass:= (annoBilancio||'-01-01')::timestamp;

 strMessaggioFinale:='Approvazione bilancio di previsione : simulazione calcolo disponibilita'' previsione su gestione.Inizio.';

 -- inserimento fase_bil_t_elaborazione
 strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
 insert into fase_bil_t_elaborazione
 (fase_bil_elab_esito, fase_bil_elab_esito_msg,
  fase_bil_elab_tipo_id,
  ente_proprietario_id,validita_inizio, login_operazione)
 (select 'IN','ELABORAZIONE FASE BILANCIO '||APPROVA_PREV_SIM||' IN CORSO.',
          tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
  from fase_bil_d_elaborazione_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.fase_bil_elab_tipo_code=APPROVA_PREV_SIM
  and   tipo.data_cancellazione is null
  and   tipo.validita_fine is null)
  returning fase_bil_elab_id into faseBilElabId;

 if faseBilElabId is null then
 	raise exception ' Inserimento non effettuato.';
 end if;

 if bilElemGestTipo=CAP_UG_TIPO and bilelemPrevtipo=CAP_UP_TIPO then
  tipoOrd:=TIPO_ORD_P;
  elemTipo:='U';

  strMessaggio:='Lettura classif tipo ID ['||PROGRAMMA_CL||'].';
  select tipo.classif_tipo_id into programmaTipoId
  from siac_d_class_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.classif_tipo_code=PROGRAMMA_CL;

  if programmaTipoId is null then
	 raise exception ' Identificativo non reperito.';
  end if;

  strMessaggio:='Lettura classif tipo ID ['||MACRO_CL||'].';
  select tipo.classif_tipo_id into macroTipoId
  from siac_d_class_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.classif_tipo_code=MACRO_CL;

  if macroTipoId is null then
	 raise exception ' Identificativo non reperito.';
  end if;

 else
  tipoOrd:=TIPO_ORD_I;
  elemTipo:='E';

  strMessaggio:='Lettura classif tipo ID ['||CATEGORIA_CL||'].';
  select tipo.classif_tipo_id into categoriaTipoId
  from siac_d_class_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.classif_tipo_code=CATEGORIA_CL;

  if categoriaTipoId is null then
	 raise exception ' Identificativo non reperito.';
  end if;
 end if;



 strMessaggio:='Lettura bilElemStatoAN  per tipo='||bilElemStatoAN||'.';
	select tipo.elem_stato_id into strict bilElemStatoANId
    from siac_d_bil_elem_stato tipo
    where tipo.elem_stato_code=bilElemStatoAN
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataInizioVal)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataInizioVal)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


 strMessaggio:='Lettura classif tipo ID ['||PDC_IV_CL||'].';
 select tipo.classif_tipo_id into pdcFinIVTipoId
 from siac_d_class_tipo tipo
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.classif_tipo_code=PDC_IV_CL;

 if pdcFinIVTipoId is null then
	 raise exception ' Identificativo non reperito.';
 end if;

 strMessaggio:='Lettura classif tipo ID ['||PDC_V_CL||'].';
 select tipo.classif_tipo_id into pdcFinVTipoId
 from siac_d_class_tipo tipo
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.classif_tipo_code=PDC_V_CL;

 if pdcFinVTipoId is null then
	 raise exception ' Identificativo non reperito.';
 end if;



 strMessaggio:='Lettura elem tipo ID ['||bilelemprevtipo||'].';
 select tipo.elem_tipo_id into elemTipoPrevId
 from siac_d_bil_elem_tipo tipo
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.elem_tipo_code=bilelemprevtipo;

 if elemTipoPrevId is null then
	 raise exception ' Identificativo non reperito.';
 end if;

 strMessaggio:='Lettura elem tipo ID ['||bilelemgesttipo||'].';
 select tipo.elem_tipo_id into elemTipoGestId
 from siac_d_bil_elem_tipo tipo
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.elem_tipo_code=bilelemgesttipo;

 if elemTipoGestId is null then
	 raise exception ' Identificativo non reperito.';
 end if;



 strMessaggio:='Lettura stanziamento tipo ID ['||STA_IMPORTO_TIPO||'].';
 select tipo.elem_det_tipo_id into elemDetTipoStaId
 from siac_d_bil_elem_det_tipo tipo
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.elem_det_tipo_code=STA_IMPORTO_TIPO;

 if elemDetTipoStaId is null then
	 raise exception ' Identificativo non reperito.';
 end if;

 strMessaggio:='Lettura stanziamento tipo ID ['||SCA_IMPORTO_TIPO||'].';
 select tipo.elem_det_tipo_id into elemDetTipoScaId
 from siac_d_bil_elem_det_tipo tipo
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.elem_det_tipo_code=SCA_IMPORTO_TIPO;

 if elemDetTipoScaId is null then
	 raise exception ' Identificativo non reperito.';
 end if;

 strMessaggio:='Lettura periodo tipo ID [SY].';
 select tipo.periodo_tipo_id into periodoTipoId
 from siac_d_periodo_tipo tipo
 where tipo.ente_proprietario_id=enteProprietarioId
 and   tipo.periodo_tipo_code='SY';

 if periodoTipoId is null then
	 raise exception ' Identificativo non reperito.';
 end if;



 strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||annobilancio::varchar||'.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id ,  det.elem_det_importo stanziamento,
			detCassa.elem_det_importo stanziamento_cassa,
            cap.bil_id,
            per.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det, siac_t_bil_elem_det detCassa
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   detCassa.elem_id=cap.elem_id
    and   detCassa.periodo_id=per.periodo_id
    and   detCassa.elem_det_tipo_id= elemDetTipoScaId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    and   detCassa.data_cancellazione is null
    and   detCassa.validita_fine is null),
   Prev as
   (select  cap.elem_id , det.elem_det_importo stanziamento, detCassa.elem_det_importo stanziamento_cassa,
		    cap.bil_id,
            per.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,siac_t_bil_elem_det detCassa
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoPrevId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   detCassa.elem_id=cap.elem_id
    and   detCassa.periodo_id=per.periodo_id
    and   detCassa.elem_det_tipo_id= elemDetTipoScaId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    and   detCassa.data_cancellazione is null
    and   detCassa.validita_fine is null)
 (select elemTipo,gest.bil_id, prev.elem_id, gest.elem_id, gest.elem_code, gest.elem_code2, gest.elem_code3,
         gest.periodo_id,
         prev.stanziamento,(fnc_siac_dicuiaccertatoeg_comp_anno(gest.elem_id,annobilancio::varchar)).dicuiaccertato,0,
         prev.stanziamento_cassa,(fnc_siac_totale_ordinativi(gest.elem_id,tipoOrd)),0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from   gest, prev
  where gest.elem_code=prev.elem_code
  and   gest.elem_code2=prev.elem_code2
  and   gest.elem_code3=prev.elem_code3
  )
 );

 strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||(annobilancio+1)::varchar||'.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,
  login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det, siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+1)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null),
   Prev as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,
         siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoPrevId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+1)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null)
 (select elemTipo,gest.bil_id, prev.elem_id, gest.elem_id, gest.elem_code, gest.elem_code2, gest.elem_code3,
         gest.periodo_id,
         prev.stanziamento,(fnc_siac_dicuiaccertatoeg_comp_anno(gest.elem_id,(annobilancio+1)::varchar)).dicuiaccertato,0,
         0,0,0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from   gest, prev
  where gest.elem_code=prev.elem_code
  and   gest.elem_code2=prev.elem_code2
  and   gest.elem_code3=prev.elem_code3
  )
 );

 strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||(annobilancio+2)::varchar||'.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det, siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+2)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null),
   Prev as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,
         siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoPrevId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+2)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null)
 (select elemTipo,gest.bil_id, prev.elem_id, gest.elem_id, gest.elem_code, gest.elem_code2, gest.elem_code3,
         gest.periodo_id,
         prev.stanziamento,(fnc_siac_dicuiaccertatoeg_comp_anno(gest.elem_id,(annobilancio+2)::varchar)).dicuiaccertato,0,
         0,0,0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from   gest, prev
  where gest.elem_code=prev.elem_code
  and   gest.elem_code2=prev.elem_code2
  and   gest.elem_code3=prev.elem_code3
  )
 );

strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||annobilancio::varchar||'. Nuovi capitoli di previsione.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,
  stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id , det.elem_det_importo stanziamento, detCassa.elem_det_importo stanziamento_cassa,
   		    cap.bil_id,
            per.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,siac_t_bil_elem_det detCassa
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   detCassa.elem_id=cap.elem_id
    and   detCassa.periodo_id=per.periodo_id
    and   detCassa.elem_det_tipo_id= elemDetTipoScaId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    and   cap.validita_fine is null
    and   detCassa.data_cancellazione is null
    and   detCassa.validita_fine is null),
   Prev as
   (select  cap.elem_id ,det.elem_det_importo stanziamento, detCassa.elem_det_importo stanziamento_cassa,
            cap.bil_id,
            per.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,siac_t_bil_elem_det detCassa
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoPrevId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   detCassa.elem_id=cap.elem_id
    and   detCassa.periodo_id=per.periodo_id
    and   detCassa.elem_det_tipo_id= elemDetTipoStaId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    and   detCassa.data_cancellazione is null
    and   detCassa.validita_fine is null)
 (select elemTipo,prev.bil_id, prev.elem_id, null, prev.elem_code, prev.elem_code2, prev.elem_code3,
         prev.periodo_id,
         prev.stanziamento,0,0,
         prev.stanziamento_cassa,0,0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from    prev
  where not exists (select 1 from gest
                    where gest.elem_code=prev.elem_code
				    and   gest.elem_code2=prev.elem_code2
				    and   gest.elem_code3=prev.elem_code3
                    )
  )
 );

 strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||(annobilancio+1)::varchar||'. Nuovi capitoli di previsione.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id ,det.elem_det_importo stanziamento, cap.bil_id,
           per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+1)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null),
   Prev as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det, siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoPrevId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+1)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null)
 (select elemTipo,prev.bil_id, prev.elem_id, null, prev.elem_code, prev.elem_code2, prev.elem_code3,
         prev.periodo_id, prev.stanziamento,0,0,
         0,0,0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from  prev
  where not exists (select 1 from gest
                    where gest.elem_code=prev.elem_code
				    and   gest.elem_code2=prev.elem_code2
				 	and   gest.elem_code3=prev.elem_code3
                   )
  )
 );


 strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||(annobilancio+2)::varchar||'. Nuovi capitoli di previsione.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id ,det.elem_det_importo stanziamento, cap.bil_id,
           per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det, siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+2)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )

    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null),
   Prev as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,
         siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoPrevId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+2)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null)
 (select elemTipo,prev.bil_id, prev.elem_id, null, prev.elem_code, prev.elem_code2, prev.elem_code3,
         prev.periodo_id,
         prev.stanziamento,0,0,
         0,0,0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from  prev
  where not exists (select 1 from gest
                    where gest.elem_code=prev.elem_code
				    and   gest.elem_code2=prev.elem_code2
				 	and   gest.elem_code3=prev.elem_code3
                   )
  )
 );

 strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||annobilancio::varchar||'. Previsione non esistente.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id , det.elem_det_importo stanziamento, detCassa.elem_det_importo stanziamento_cassa,
            cap.bil_id,
            per.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,siac_t_bil_elem_det detCassa
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   detCassa.elem_id=cap.elem_id
    and   detCassa.periodo_id=per.periodo_id
    and   detCassa.elem_det_tipo_id= elemDetTipoStaId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    and   detCassa.data_cancellazione is null
    and   detCassa.validita_fine is null),
   Prev as
   (select  cap.elem_id , det.elem_det_importo stanziamento, detCassa.elem_det_importo stanziamento_cassa,
            cap.bil_id,
            per.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det,siac_t_bil_elem_det detCassa
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoPrevId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   detCassa.elem_id=cap.elem_id
    and   detCassa.periodo_id=per.periodo_id
    and   detCassa.elem_det_tipo_id= elemDetTipoStaId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    and   detCassa.data_cancellazione is null
    and   detCassa.validita_fine is null)
 (select elemTipo,gest.bil_id, null, gest.elem_id, gest.elem_code, gest.elem_code2, gest.elem_code3,
         gest.periodo_id,
         0,(fnc_siac_dicuiaccertatoeg_comp_anno(gest.elem_id,annobilancio::varchar)).dicuiaccertato, 0,
         0,(fnc_siac_totale_ordinativi(gest.elem_id,tipoOrd)),0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from   gest
  where not exists (select 1 from prev
                    where prev.elem_code=gest.elem_code
                    and   prev.elem_code2=gest.elem_code2
                    and   prev.elem_code3=gest.elem_code3
                    )
  )
 );

 strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||(annobilancio+1)::varchar||'.Previsione non esistente.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det, siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+1)::varchar

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )
    and   per1.periodo_tipo_id=periodoTipoId
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null),
   Prev as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap, siac_d_bil_elem_tipo tipoCap,
         siac_t_bil_elem_det det, siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   tipoCap.ente_proprietario_id=bil.ente_proprietario_id
    and   tipoCap.elem_tipo_code=bilElemPrevTipo
    and   cap.elem_tipo_id=tipoCap.elem_tipo_id
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+1)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null)
 (select elemTipo,gest.bil_id, null, gest.elem_id, gest.elem_code, gest.elem_code2, gest.elem_code3,
         gest.periodo_id,
         0,(fnc_siac_dicuiaccertatoeg_comp_anno(gest.elem_id,(annobilancio+1)::varchar)).dicuiaccertato, 0,
         0,0,0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from   gest
  where not exists (select 1 from prev
                    where gest.elem_code=prev.elem_code
					and   gest.elem_code2=prev.elem_code2
					and   gest.elem_code3=prev.elem_code3
                   )
  )
 );

 strMessaggio:='Inserimento fase_bil_t_prev_approva_simula annoCompetenza='||(annobilancio+2)::varchar||'.Previsione non esistente.';
 insert into fase_bil_t_prev_approva_simula
 (elem_tipo,bil_id,elem_prev_id,elem_gest_id,elem_code,elem_code2,elem_code3,
  periodo_id,stanziamento,tot_impacc,disponibile,
  stanziamento_cassa,tot_ordinativi,disponibile_cassa,
  fase_bil_elab_id,login_operazione,validita_inizio,ente_proprietario_id)
  (
   with
   Gest as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det, siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoGestId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+2)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null),
   Prev as
   (select  cap.elem_id , det.elem_det_importo stanziamento, cap.bil_id,
            per1.periodo_id, cap.elem_code, cap.elem_code2, cap.elem_code3
    from siac_t_bil bil, siac_t_periodo per,
         siac_t_bil_elem cap,
         siac_t_bil_elem_det det, siac_t_periodo per1
    where bil.ente_proprietario_id=enteproprietarioid
    and   per.ente_proprietario_id=bil.ente_proprietario_id
    and   per.anno=annobilancio::varchar
    and   bil.periodo_id=per.periodo_id
    and   cap.elem_tipo_id=elemTipoPrevId
    and   cap.bil_id=bil.bil_id
    and   det.elem_id=cap.elem_id
    and   det.periodo_id=per1.periodo_id
    and   det.elem_det_tipo_id= elemDetTipoStaId
    and   per1.ente_proprietario_id=enteProprietarioId
    and   per1.anno=(annobilancio+2)::varchar
    and   per1.periodo_tipo_id=periodoTipoId

    and   exists (select 1 from siac_r_bil_elem_stato rstato -- 15.11.2016 Anto JIRA-SIAC-4161
  					 where rstato.elem_id=cap.elem_id
                     and   rstato.elem_stato_id!=bilElemStatoANId
	                 and   rstato.data_cancellazione is null
	                 and   rstato.validita_fine isnull
                     )
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null)
 (select elemTipo,gest.bil_id, null, gest.elem_id, gest.elem_code, gest.elem_code2, gest.elem_code3,
         gest.periodo_id,
         0,(fnc_siac_dicuiaccertatoeg_comp_anno(gest.elem_id,(annobilancio+2)::varchar)).dicuiaccertato,0,
         0,0,0,
         faseBilElabId,loginOperazione, now(),enteProprietarioid
  from   gest
  where not exists (select 1 from prev
                    where gest.elem_code=prev.elem_code
					and   gest.elem_code2=prev.elem_code2
					and   gest.elem_code3=prev.elem_code3
                   )
  )
 );



 strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Calcolo disponibile.';
 update fase_bil_t_prev_approva_simula set
   disponibile=stanziamento-tot_impacc,
   disponibile_cassa=stanziamento_cassa-tot_ordinativi
 where fase_bil_elab_id=faseBilElabId;

 if elemTipo='U' then
  strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Codifiche bilancio capitoli gestione ['||PROGRAMMA_CL||']. ';
  update fase_bil_t_prev_approva_simula  f
   set programma_gest=c.classif_code
  from siac_r_bil_elem_class r, siac_t_class c
  where f.fase_bil_elab_id=faseBilElabId
  and   f.elem_gest_id is not null
  and   r.elem_id=f.elem_gest_id
  and   c.classif_id=r.classif_id
  and   c.classif_tipo_id=programmaTipoId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  -- Anto JIRA-SIAC-4167
  and   c.data_cancellazione is null
  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)

  ;


  strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Codifiche bilancio capitoli gestione ['||MACRO_CL||']. ';
  update fase_bil_t_prev_approva_simula  f
   set macroaggregato_gest=c.classif_code
  from siac_r_bil_elem_class r, siac_t_class c
  where f.fase_bil_elab_id=faseBilElabId
  and   f.elem_gest_id is not null
  and   r.elem_id=f.elem_gest_id
  and   c.classif_id=r.classif_id
  and   c.classif_tipo_id=macroTipoId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  -- Anto JIRA-SIAC-4167
  and   c.data_cancellazione is null
  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
  ;

  strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Codifiche bilancio capitoli previsione ['||PROGRAMMA_CL||']. ';
  update fase_bil_t_prev_approva_simula  f
   set programma=c.classif_code
  from siac_r_bil_elem_class r, siac_t_class c
  where f.fase_bil_elab_id=faseBilElabId
  and   f.elem_prev_id is not null
  and   r.elem_id=f.elem_prev_id
  and   c.classif_id=r.classif_id
  and   c.classif_tipo_id=programmaTipoId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
    -- Anto JIRA-SIAC-4167
  and   c.data_cancellazione is null
  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
	;

  strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Codifiche bilancio capitoli previsione ['||MACRO_CL||']. ';
  update fase_bil_t_prev_approva_simula  f
   set macroaggregato=c.classif_code
  from siac_r_bil_elem_class r, siac_t_class c
  where f.fase_bil_elab_id=faseBilElabId
  and   f.elem_prev_id is not null
  and   r.elem_id=f.elem_prev_id
  and   c.classif_id=r.classif_id
  and   c.classif_tipo_id=macroTipoId
  and   r.data_cancellazione is null
  and   r.validita_fine   is null
    -- Anto JIRA-SIAC-4167
  and   c.data_cancellazione is null
  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null);


 else
  strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Codifiche bilancio capitoli gestione ['||CATEGORIA_CL||']. ';
  update fase_bil_t_prev_approva_simula  f
   set categoria_gest=c.classif_code
  from siac_r_bil_elem_class r, siac_t_class c
  where f.fase_bil_elab_id=faseBilElabId
  and   f.elem_gest_id is not null
  and   r.elem_id=f.elem_gest_id
  and   c.classif_id=r.classif_id
  and   c.classif_tipo_id=categoriaTipoId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
    -- Anto JIRA-SIAC-4167
  and   c.data_cancellazione is null
  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null);

  strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Codifiche bilancio capitoli previsione ['||CATEGORIA_CL||']. ';
  update fase_bil_t_prev_approva_simula  f
   set categoria=c.classif_code
  from siac_r_bil_elem_class r, siac_t_class c
  where f.fase_bil_elab_id=faseBilElabId
  and   f.elem_prev_id is not null
  and   r.elem_id=f.elem_prev_id
  and   c.classif_id=r.classif_id
  and   c.classif_tipo_id=categoriaTipoId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
    -- Anto JIRA-SIAC-4167
  and   c.data_cancellazione is null
  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null);
 end if;
 strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Piano conti Fin capitoli gestione.';
 update fase_bil_t_prev_approva_simula  f
   set piano_conti_fin_gest=c.classif_code
 from siac_r_bil_elem_class r, siac_t_class c
 where f.fase_bil_elab_id=faseBilElabId
  and   f.elem_gest_id is not null
  and   r.elem_id=f.elem_gest_id
  and   c.classif_id=r.classif_id
  and   c.classif_tipo_id in (pdcFinIVTipoId, pdcFinVTipoId)
  and   r.data_cancellazione is null
  and   r.validita_fine is null
    -- Anto JIRA-SIAC-4167
  and   c.data_cancellazione is null
  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
;
  strMessaggio:='Aggiornamento fase_bil_t_prev_approva_simula. Piano conti Fin capitoli previsione.';
 update fase_bil_t_prev_approva_simula  f
   set piano_conti_fin=c.classif_code
 from siac_r_bil_elem_class r, siac_t_class c
 where f.fase_bil_elab_id=faseBilElabId
  and   f.elem_prev_id is not null
  and   r.elem_id=f.elem_prev_id
  and   c.classif_id=r.classif_id
  and   c.classif_tipo_id in (pdcFinIVTipoId, pdcFinVTipoId)
  and   r.data_cancellazione is null
  and   r.validita_fine is null
    -- Anto JIRA-SIAC-4167
  and   c.data_cancellazione is null
  and   date_trunc('day',dataInizioValClass)>=date_trunc('day',c.validita_inizio)
  and   ( date_trunc('day',dataFineValClass)<=date_trunc('day',c.validita_fine) or c.validita_fine is null)
;

 strMessaggio:='Aggiornamento fase elaborazione [fase_bil_t_elaborazione].';
 update fase_bil_t_elaborazione set
      fase_bil_elab_esito='OK',
      fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APPROVA_PREV_SIM||' COMPLETATA.',
      validita_fine=now()
 where fase_bil_elab_id=faseBilElabId;

 faseBilElabIdRet:=faseBilElabId;
 messaggioRisultato:=strMessaggioFinale||'Fine.';


 return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        faseBilElabIdRet:=null;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        faseBilElabIdRet:=null;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        faseBilElabIdRet:=null;
        return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;