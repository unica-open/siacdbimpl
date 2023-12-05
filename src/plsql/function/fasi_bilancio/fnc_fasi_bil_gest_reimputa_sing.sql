/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- FUNCTION: siac.fnc_fasi_bil_gest_reimputa_sing(integer, integer, character varying, timestamp without time zone, character varying, character varying, character varying)

-- DROP FUNCTION siac.fnc_fasi_bil_gest_reimputa_sing(integer, integer, character varying, timestamp without time zone, character varying, character varying, character varying);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_sing (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  p_dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  componentedef varchar,
  impostaprovvedimento varchar = 'true'::character varying,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    v_faseBilElabId    integer;
    v_bil_attr_id      integer;
    v_attr_code        varchar;
-- SIAC-6997 ---------------- INIZIO --------------------
    v_annobilancio     integer;
-- SIAC-6997 ---------------- FINE --------------------
    MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';
    CAP_UG_TIPO        CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO        CONSTANT varchar:='CAP-EG';
    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';
    v_boolean          char(1);
    v_attr_id          integer;
    v_bil_id           integer;
    faseRec record;
    faseElabRec record;

   -- 05.06.2020 Sofia Jira siac-7593
   paramComponent       varchar:=null;
   componenteFittizia   varchar:=null;
   componenteFresco     varchar:=null;
   componenteFPV        varchar:=null;
   motivoREIMP CONSTANT varchar:='REIMP';
   motivoREANNO CONSTANT varchar:='REANNO';

   componenteDefId integer:=null;
   componenteFrescoId integer:=null;
   componenteFPVId    integer:=null;
BEGIN
	v_faseBilElabId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    strMessaggioFinale:='Reimputazione Importi/ accertamenti a partire anno ='||annoBilancio::varchar||'.';

    select bil_id into v_bil_id from siac_t_bil where ente_proprietario_id = enteProprietarioId and bil_code = 'BIL_'||annoBilancio::varchar and data_cancellazione is null;
    if v_bil_id is  null then
        strMessaggio :='Bilancio non trovato anno ='||annoBilancio::varchar||'.';
    	raise exception 'Bilancio non trovato anno =%',annoBilancio::varchar;
    	return;
    end if;

    -- 05.06.2020 Sofia Jira siac-7593
    -- check delle componenti
    if p_movgest_tipo_code ='I'  then
      strMessaggio:='Lettura param componenti in tipo fase elaborazione '||APE_GEST_REIMP||'.';
      select tipo.fase_bil_elab_tipo_param into paramComponent
      from fase_bil_d_elaborazione_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null;
      raise notice 'paramComponent=%',paramComponent;
      if coalesce(paramComponent,'')!='' then
      	if coalesce(componenteDef,'')='S'  then
        	  componenteFittizia:=trim(split_part(paramComponent,'|',1));
              if coalesce(componenteFittizia,'')='' then
              	raise exception ' Componente fittizia richiesta non impostata a parametro.';
              end if;
              strMessaggio:='Lettura componente fittizia '||componenteFittizia||'.';
              select comp_tipo.elem_det_comp_tipo_id into componenteDefId
              from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
                   siac_d_bil_elem_Det_comp_tipo_stato stato
              where comp_tipo.ente_proprietario_id=enteProprietarioId
              and   comp_tipo.elem_det_comp_tipo_desc=componenteFittizia
              and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
              and   stato.elem_det_comp_tipo_stato_code!='A'
              and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
              and   tipo_imp.elem_Det_comp_tipo_imp_desc in ('Si','Auto') -- 21.07.2020 Sofia aggiunto Auto dopo conf. con Gambino P.
              and   comp_tipo.data_cancellazione is null
              and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
              and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                    date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
              raise notice 'componenteDefId=%',componenteDefId;
              if componenteDefId is  null then
                  raise exception ' Non esistente o non valida o impegnabile.';
              end if;
        else
              componenteFresco=trim(split_part(paramComponent,'|',2));
              if motivo=motivoREIMP then
              	componenteFPV=trim(split_part(paramComponent,'|',3));
              else
                componenteFPV=trim(split_part(paramComponent,'|',4));
              end if;
              if coalesce(componenteFresco,'')=''  or coalesce(componenteFPV,'')='' then
              	raise exception ' Componente Fresco/FPV  non impostata a parametro.';
              end if;

              strMessaggio:='Lettura componente Fresco '||componenteFresco||'.';
              select comp_tipo.elem_det_comp_tipo_id into componenteFrescoId
              from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
                   siac_d_bil_elem_Det_comp_tipo_stato stato
              where comp_tipo.ente_proprietario_id=enteProprietarioId
              and   comp_tipo.elem_det_comp_tipo_desc=componenteFresco
              and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
              and   stato.elem_det_comp_tipo_stato_code!='A'
              and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
              and   tipo_imp.elem_Det_comp_tipo_imp_desc in ('Si','Auto') -- 21.07.2020 Sofia aggiunto Auto dopo conf. con Gambino P.
              and   comp_tipo.data_cancellazione is null
              and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
              and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                    date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
              raise notice 'componenteFrescoId=%',componenteFrescoId;
              if componenteFrescoId is  null then
                  raise exception ' Non esistente o non valida o impegnabile.';
              end if;

              strMessaggio:='Lettura componente FPV '||componenteFPV||'.';
              select comp_tipo.elem_det_comp_tipo_id into componenteFPVId
              from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
                   siac_d_bil_elem_Det_comp_tipo_stato stato
              where comp_tipo.ente_proprietario_id=enteProprietarioId
              and   comp_tipo.elem_det_comp_tipo_desc=componenteFPV
              and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
              and   stato.elem_det_comp_tipo_stato_code!='A'
              and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
              and   tipo_imp.elem_Det_comp_tipo_imp_desc in ('Si','Auto') -- 21.07.2020 Sofia aggiunto Auto dopo conf. con Gambino P.
              and   comp_tipo.data_cancellazione is null
              and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
              and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                    date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
              raise notice 'componenteFPVId=%',componenteFPVId;
              if componenteFPVId is  null then
                  raise exception ' Non esistente o non valida o impegnabile.';
              end if;

        end if;


      else
    	raise exception ' Parametri non ricavati.';
    	return;
      end if;

    end if;
    -- 05.06.2020 Sofia Jira siac-7593 - fine

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
        strMessaggio :=' Esistenza elaborazione reimputazione in corso.';
    	raise exception ' Esistenza elaborazione reimputazione in corso.';
    	return;
    end if;

    -- 05.06.2020 Sofia Jira siac-7593

    strMessaggio:='Inserimento fase elaborazione [fnc_fasi_bil_gest_reimputa].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE REIMPUTAZIONE IN CORSO. (TEST SERGIO)',tipo.fase_bil_elab_tipo_id,ente_proprietario_id, p_dataElaborazione, loginOperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteproprietarioid
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into v_faseBilElabId;

     if v_faseBilElabId is null then
        strMessaggio  :=' Inserimento elaborazione per tipo APE_GEST_REIMP non effettuato.';
     	raise exception ' Inserimento elaborazione per tipo APE_GEST_REIMP non effettuato.';
     	return;
     end if;

/* -- SIAC-6997 ---------------- INIZIO --------------------
   -- tolto blocco elaborazione su controllo reimputazione gia eseguita in precedenza

A)
Il sistema verifica che l'elaborazione non sia gia stata effettuata:
SE per l'anno di bilancio in elaborazione il flagReimputaSpese e a TRUE l'elaborazione viene interrotta con l'errore
- quindi se su siac_t_bil per annoBilancio=2017
               siac_r_bil_attr per attr_code in flagReimputaSpese,flagReimputaEntrate il valore e impostato a S, se si blocchi elaborazione, se no procedi

Verificare che non ci siano elaborazioni in corso per APE_GEST_REIMP in fase_bil_t_elaborazione ( come fanno le altre function )
Inserire nella fase_bil_t_elaborazione il fase_elab_id per  APE_GEST_REIMP


    if p_movgest_tipo_code = 'I' then
        v_attr_code := 'flagReimputaSpese';
        select attr_id into v_attr_id  from siac.siac_t_attr where ente_proprietario_id = enteProprietarioId and   data_cancellazione is null and      attr_code = 'flagReimputaSpese';
    else
        v_attr_code := 'flagReimputaEntrate';
        select attr_id into v_attr_id  from siac_t_attr where ente_proprietario_id = enteProprietarioId and   data_cancellazione is null and      attr_code = 'flagReimputaEntrate';
    end if;

    select
    	siac_r_bil_attr.bil_attr_id,
    	siac_r_bil_attr.boolean
    into v_bil_attr_id,v_boolean
    from
    	siac_t_bil,siac_r_bil_attr,siac_t_attr
    where
    siac_t_bil.bil_id = siac_r_bil_attr.bil_id
    and siac_r_bil_attr.attr_id =  siac_t_attr.attr_id
    and siac_r_bil_attr.data_cancellazione is null
    and siac_t_attr.attr_code = v_attr_code
    and siac_t_bil.bil_code = 'BIL_'||annoBilancio::varchar
    --and siac_r_bil_attr.boolean != 'S'
    and siac_t_bil.ente_proprietario_id = enteProprietarioId;

    raise notice ' v_bil_attr_id %',v_bil_attr_id;

    if v_bil_attr_id is  null then
        insert into  siac_r_bil_attr (bil_id ,attr_id ,tabella_id ,boolean,percentuale,testo ,numerico ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione
        )
        VALUES( v_bil_id,v_attr_id,null,'N',null,null,null,now(),null,enteProprietarioId,null,loginOperazione)
        returning bil_attr_id into v_bil_attr_id; -- 26.01.2016 Sofia
    else
		if  v_boolean = 'S' then
            strMessaggio:=' Elaborazione terminata reimputazione gia eseguita in precedenza v_bil_attr_id-->'||v_bil_attr_id::varchar||'.';
            --raise notice ' Elaborazione terminata reimputazione gia eseguita in precedenza.';
			raise exception ' Elaborazione terminata reimputazione gia eseguita in precedenza.';
			return;
        end if;
    end if;

*/ -- SIAC-6997 --------------- FINE ------------------------

	select * into faseRec
    from fnc_fasi_bil_gest_reimputa_popola
    	 (
    	  v_faseBilElabId            ,
    	  enteProprietarioId     	,
          annoBilancio           	,
          loginOperazione        	,
          p_dataElaborazione       	,
          p_movgest_tipo_code        ,
-- SIAC-6997 ---------------- INIZIO --------------------
         motivo,
-- SIAC-6997 --------------- FINE ------------------------
		  -- 05.06.2020 Sofia Jira SIAC-7593
          ( case when p_movgest_tipo_code='I' then componenteDefId else null end),
          ( case when p_movgest_tipo_code='I' then componenteFrescoId else null end),
          ( case when p_movgest_tipo_code='I' then componenteFPVId else null end)
          -- 05.06.2020 Sofia Jira SIAC-7593
          );
    if faseRec.codiceRisultato=-1  then
     strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
     raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
     return;
    end if;

	select * into faseRec
    from fnc_fasi_bil_gest_reimputa_elabora
    	 (
    	  v_faseBilElabId,
    	  enteProprietarioId,
		  annoBilancio,
          impostaProvvedimento::boolean, -- 07.02.2018 Sofia siac-5638
		  loginOperazione,
		  p_dataElaborazione,
		  p_movgest_tipo_code
-- SIAC-6997 ---------------- INIZIO --------------------
          ,motivo
-- SIAC-6997 --------------- FINE ------------------------
          );
    if faseRec.codiceRisultato=-1  then
     strMessaggio:='Lancio elaborazione.'||faseRec.messaggioRisultato;
     raise exception ' Errore Lancio elaborazione % .',faseRec.messaggioRisultato;
     return;
    end if;

-- SIAC-6997 ---------------- INIZIO --------------------
-- tolto blocco elaborazione su controllo reimputazione gia eseguita in precedenza

--    strMessaggio:='Aggiornamento attributo reimputazione avvenuta con successo poi chiusura.';
--    update  siac_r_bil_attr set BOOLEAN='S',login_operazione = loginoperazione , data_modifica = now()
--    where   bil_attr_id = v_bil_attr_id;

    strMessaggio:='Aggiornamento attributo reimputazione avvenuta con successo poi chiusura.';

    v_annobilancio := annoBilancio;
    if motivo = 'REIMP' then
       v_annobilancio := annoBilancio - 1;
    end if;

update siac_t_modifica set elab_ror_reanno = TRUE
where mod_id in (
    select  modifica.mod_id
      from  siac_t_modifica             modifica,
            siac_d_modifica_tipo        modificaTipo,
			siac_t_bil                  bil,
			siac_t_bil_elem             bilel,
			siac_r_movgest_bil_elem     rbilel,
			siac_t_movgest              movgest,
			siac_t_movgest_ts_det       detts,
			siac_t_movgest_ts_det_mod   dettsmod,
			siac_r_modifica_stato       rmodstato,
			siac_d_modifica_stato       modstato,
			siac_d_movgest_ts_det_tipo  tipodet,
			siac_t_movgest_ts           tsmov,
			siac_d_movgest_tipo         tipomov,
			siac_d_movgest_ts_tipo      tipots,
			siac_t_movgest_ts_det       dettsIniz,
			siac_d_movgest_ts_det_tipo  tipodetIniz,
			siac_t_periodo              per,
			siac_d_bil_elem_tipo        dbileltip,
            siac_r_movgest_ts_stato     rstato
	 where  bil.ente_proprietario_id             = enteProprietarioId
	   and  bilel.elem_tipo_id                   = dbileltip.elem_tipo_id
	   and  bilel.elem_id                        = rbilel.elem_id
	   and  rbilel.movgest_id                    = movgest.movgest_id
	   and  per.periodo_id                       = bil.periodo_id
       and  per.anno::integer                    = v_annobilancio
       and  modifica.ente_proprietario_id        = bil.ente_proprietario_id
	   and  rmodstato.mod_id                     = modifica.mod_id
	   and  dettsmod.mod_stato_r_id              = rmodstato.mod_stato_r_id
	   and  modstato.mod_stato_id                = rmodstato.mod_stato_id
	   and  modstato.mod_stato_code              = 'V'
   	   and  modifica.mod_tipo_id                 = modificaTipo.mod_tipo_id
       and  modifica.elab_ror_reanno             = FALSE
       and  modificaTipo.mod_tipo_code           = motivo
       and  dettsmod.movgest_ts_det_importo      < 0
	   and  tipodet.movgest_ts_det_tipo_id       = dettsmod.movgest_ts_det_tipo_id
	   and  detts.movgest_ts_det_id              = dettsmod.movgest_ts_det_id
	   and  tsmov.movgest_ts_id                  = detts.movgest_ts_id
	   and  dettsIniz.movgest_ts_id              = tsmov.movgest_ts_id
	   and  tipodetIniz.movgest_ts_det_tipo_id   = dettsIniz.movgest_ts_det_tipo_id
	   and  tipodetIniz.movgest_ts_det_tipo_code = p_movgest_tipo_code
	   and  tipots.movgest_ts_tipo_id            = tsmov.movgest_ts_tipo_id
	   and  movgest.movgest_id                   = tsmov.movgest_id
	   and  movgest.bil_id                       = bil.bil_id
	   and  tipomov.movgest_tipo_id              = movgest.movgest_tipo_id
	   and  tipomov.movgest_tipo_code            = p_movgest_tipo_code
	   and  dettsmod.mtdm_reimputazione_anno     is not null
	   and  dettsmod.mtdm_reimputazione_flag     is true
       and  rstato.movgest_ts_id                 = tsmov.movgest_ts_id
	   and  bilel.validita_fine                  is null
	   and  rbilel.validita_fine                 is null
	   and  rmodstato.validita_fine              is null
	   and  tsmov.validita_fine                  is null
	   and  dettsIniz.validita_fine              is null
	   and  bil.validita_fine                    is null
	   and  per.validita_fine                    is null
	   and  modifica.validita_fine               is null
	   and  bilel.data_cancellazione             is null
	   and  rbilel.data_cancellazione            is null
	   and  rmodstato.data_cancellazione         is null
	   and  tsmov.data_cancellazione             is null
	   and  dettsIniz.data_cancellazione         is null
	   and  bil.data_cancellazione               is null
	   and  per.data_cancellazione               is null
	   and  modifica.data_cancellazione          is null
       and  rstato.data_cancellazione            is null
       and  rstato.validita_fine                 is null);

-- SIAC-6997 ---------------- FINE --------------------

    strMessaggio:='Aggiornamento stato fase bilancio OK per chiusura v_bil_attr_id-->'||v_bil_attr_id::varchar||'.';

    update fase_bil_t_elaborazione fase
    set fase_bil_elab_esito='OK',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_REIMP||' CHIUSURA.'
    where fase.fase_bil_elab_id=v_faseBilElabId;

    outfaseBilElabRetId:=v_faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=v_faseBilElabId;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;