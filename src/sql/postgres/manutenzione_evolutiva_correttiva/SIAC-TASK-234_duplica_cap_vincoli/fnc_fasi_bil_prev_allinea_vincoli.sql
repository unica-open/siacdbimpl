/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_prev_allinea_vincoli 
(
  annobilancio integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_prev_allinea_vincoli 
(
  annobilancio integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
   strMessaggio       			VARCHAR(1500)	:='';
   strMessaggioErr       			VARCHAR(1500)	:='';
   strMessaggiofinale 			VARCHAR(1500)	:='';
   codResult              		INTEGER  		:=NULL;
   dataInizioVal 				timestamp		:=NULL;
   faseBilElabId 		        integer:=null;
   bilancioId                   integer:=null;
   periodoId                    integer:=null;
   
   
   tipoOperazioni varchar(50):=null;
  
   faseOp                       varchar(50):=null;
   
   strRec record;

  numeroVincoli integer:=0;
  numeroVincoliRel integer:=0;
 
  APROVA_PREV CONSTANT varchar:='APROVA_PREV';
  APE_PREV         CONSTANT varchar:='APE_PREV';
  APE_PROV         CONSTANT varchar:='APE_PROV';
  APE_GEST_VINCOLI CONSTANT varchar:='APE_GEST_VINCOLI';
 
  APE_PREV_VINCOLI CONSTANT varchar:='APE_PREV_VINCOLI';

   P_FASE						CONSTANT varchar:='P';
   E_FASE					    CONSTANT varchar:='E';
   
  BEGIN

   messaggioRisultato:='';
   codicerisultato:=0;
   faseBilElabIdRet:=0;
   dataInizioVal:= clock_timestamp();

   strmessaggiofinale:='Allineamento Vincoli da gestione anno-1 a previsione  anno. annoBilancio='||annoBilancio::varchar||'.';
   raise notice '%',strmessaggiofinale;
   strMessaggio:='Verifica esistenza fase elaborazione '||APE_PREV_VINCOLI||' IN CORSO.';
   select 1 into codResult
   from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.fase_bil_elab_tipo_code=APE_PREV_VINCOLI
   and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
   and   fase.fase_bil_elab_esito like 'IN%'
   and   fase.data_cancellazione is null
   and   fase.validita_fine is null
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null;
   if codResult is not null then
   	raise exception ' Esistenza fase in corso.';
   end if;
   
   strMessaggio:='Verifica esistenza fasi elaborazioni correlate IN CORSO.';
   select 1 into codResult
   from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.fase_bil_elab_tipo_code in (APROVA_PREV,APE_PREV,APE_PROV,APE_GEST_VINCOLI)
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
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_PREV_VINCOLI||' da gestione anno-1 a previsione anno IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_PREV_VINCOLI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
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

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;
     
 
	 strMessaggio:='Verifica fase di bilancio  corrente annoBilancio='||annoBilancio::varchar||'.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     raise notice 'FaseOp=%',faseOp;
     
     if ( faseOp is null or faseOp not in (P_FASE,E_FASE) ) then  
         faseOp:=null;
         bilancioId:=null;
         periodoId:=null;
         annoBilancio:=annoBilancio+1;
	   	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
	     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
	     from siac_t_bil bil, siac_t_periodo per
	     where bil.ente_proprietario_id=enteProprietarioId
	     and   per.periodo_id=bil.periodo_id
	     and   per.anno::INTEGER=annoBilancio
	     and   bil.data_cancellazione is null
	     and   per.data_cancellazione is null;
	    
    	 strMessaggio:='Verifica fase di bilancio successivo annoBilancio='||annoBilancio::varchar||'.';
   	     select fase.fase_operativa_code into faseOp
         from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
         where r.bil_id=bilancioId
         and   fase.fase_operativa_id=r.fase_operativa_id
         and   r.data_cancellazione is null
         and   r.validita_fine is null;
         raise notice 'FaseOp=%',faseOp;
    end if;
    
     if ( faseOp is null or faseOp not in (P_FASE,E_FASE) ) then 
    	raise notice ' Il bilancio deve essere in fase % o %.',P_FASE,E_FASE;
        strMessaggio:=strMessaggio||' Il bilancio deve essere in fase '||P_FASE||' o '||E_FASE||'. Chiusura fase_bil_t_elaborazione KO.';
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

        update fase_bil_t_elaborazione
        set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_PREV_VINCOLI||'  da gestione anno-1 a previsione previsione anno TERMINATA CON ERRORE.'||upper (strMessaggio)
        where fase_bil_elab_id=faseBilElabId;
      
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Fase di bilancio non ammessa.';
	   return;
     end if;
    
	 strMessaggio:='Inserimento LOG.';
 	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' Inserimento nuovi vincoli in annoBilancio='||annoBilancio::varchar||'. Inizio.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
     end if;    
    
    strMessaggio:='Inserimento nuovi vincoli [siac_t_vincolo] in annoBilancio='||annoBilancio::varchar||'.';
    raise notice '%',strMessaggio;
    -- vincoli nuovi 
    insert into siac_t_vincolo
    (
    vincolo_code,
	vincolo_desc,
	vincolo_tipo_id,
	periodo_id ,
    vincolo_risorse_vincolate_id,
	login_operazione,
	validita_inizio,
	ente_proprietario_id
    )
    select vinc.vincolo_code,
    		    vinc.vincolo_desc,
    		    tipo_prev.vincolo_tipo_id ,
     		    periodoId,
     		    vinc.vincolo_risorse_vincolate_id ,
     		    loginOperazione||'@'||faseBilElabId::varchar||'@'||vinc.vincolo_Id::varchar,
     		    clock_timestamp(),
     		    tipo_prev.ente_proprietario_id 
    from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo ,siac_t_periodo per,siac_r_vincolo_stato rs,siac_d_vincolo_stato stato ,siac_d_vincolo_tipo tipo_prev
    where tipo.ente_proprietario_id= enteProprietarioId 
    and      tipo.vincolo_tipo_code='G'
    and      vinc.vincolo_tipo_id=tipo.vincolo_tipo_Id 
    and      per.periodo_id=vinc.periodo_Id 
    and      per.anno::integer=annoBilancio-1
    and      rs.vincolo_id =vinc.vincolo_id 
    and      stato.vincolo_stato_id =rs.vincolo_stato_id 
    and      stato.vincolo_stato_code !='A'
    and      tipo_prev.ente_proprietario_id =tipo.ente_proprietario_id 
    and      tipo_prev.vincolo_tipo_code ='P'
    and      not exists 
    (
    select  1
    from siac_t_vincolo vinc_prev,siac_r_vincolo_Stato rs_prev,siac_d_vincolo_stato stato_prev
    where vinc_prev.vincolo_tipo_id=tipo_prev.vincolo_tipo_id 
    and     vinc_prev.vincolo_code =vinc.vincolo_code 
    and     vinc_prev.periodo_id=periodoId
    and     rs_prev.vincolo_id =vinc_prev.vincolo_id 
    and     stato_prev.vincolo_stato_id =rs_prev.vincolo_stato_id 
    and     stato_prev.vincolo_stato_code !='A'
    and     vinc_prev.data_cancellazione  is null 
    and     vinc_prev.validita_fine  is null
    and      rs_prev.data_cancellazione  is null 
    and      rs_prev.validita_fine  is null 
    )
    and      rs.data_cancellazione  is null 
    and      rs.validita_fine  is null 
    and      vinc.data_cancellazione  is null 
    and      vinc.validita_fine  is null;
    GET DIAGNOSTICS numeroVincoli = ROW_COUNT;
    raise notice 'Inseriti numeroVincoli[siac_t_vincolo]=%',coalesce(numeroVincoli::varchar,'0');
   
    strMessaggio:='Inserimento LOG.';
 	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' Inseriti nuovi vincoli  numeroVincoli='||numeroVincoli::varchar||' in annoBilancio='||annoBilancio::varchar||'.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;    
    
   if numeroVincoli is not null and numeroVincoli!=0 then 
    strMessaggio:='Inserimento nuovi vincoli [siac_r_vincolo_stato] in annoBilancio='||annoBilancio::varchar||'.';
    codResult:=null;
     --    siac_r_vincolo_stato
     insert into siac_r_vincolo_stato 
     (
      vincolo_id,
  	  vincolo_stato_id,
  	  validita_inizio,
  	  login_operazione ,
  	  ente_proprietario_id 
     )
     select vinc.vincolo_id,
                 rs.vincolo_stato_id,
                 clock_timestamp(),
                 loginOperazione,
                 vinc.ente_proprietario_id 
    from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo ,
               siac_r_vincolo_stato rs
    where tipo.ente_proprietario_id= enteProprietarioId 
    and      tipo.vincolo_tipo_code='P'
    and      vinc.vincolo_tipo_id=tipo.vincolo_tipo_Id 
    and      vinc.periodo_id=periodoId 
    and      vinc.login_operazione  like '%@'||faseBilElabId::varchar||'%'
    and      rs.vincolo_id=split_part(vinc.login_operazione,'@',3)::integer  
    and      not exists 
    (
    select 1 
    from siac_r_vincolo_stato rs 
    where rs.vincolo_id=vinc.vincolo_id 
    and      rs.data_cancellazione  is null
    and      rs.validita_fine is null
    )
    and      rs.data_cancellazione  is null 
    and      rs.validita_fine is null
    and      vinc.data_cancellazione  is null 
    and      vinc.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'Inseriti numeroVincoli[siac_r_vincolo_stato]=%',coalesce(codResult::varchar,'0');
   
    --    siac_r_vincolo_genere
    strMessaggio:='Inserimento nuovi vincoli [siac_r_vincolo_genere] in annoBilancio='||annoBilancio::varchar||'.';
    codResult:=null;
    insert into siac_r_vincolo_genere 
    (
     vincolo_id,
  	 vincolo_gen_id,
  	 validita_inizio,
  	 login_operazione ,
  	 ente_proprietario_id 
    )
    select vinc.vincolo_id,
                r.vincolo_gen_id,
                clock_timestamp(),
                loginOperazione,
                vinc.ente_proprietario_id 
    from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo ,
               siac_r_vincolo_genere r
    where tipo.ente_proprietario_id= enteProprietarioId 
    and      tipo.vincolo_tipo_code='P'
    and      vinc.vincolo_tipo_id=tipo.vincolo_tipo_Id 
    and      vinc.periodo_id=periodoId 
    and      vinc.login_operazione  like '%@'||faseBilElabId::varchar||'%'
    and      r.vincolo_id=split_part(vinc.login_operazione,'@',3)::integer  
    and      not exists 
    (
    select 1 
    from siac_r_vincolo_genere r1 
    where  r1.vincolo_id=vinc.vincolo_id 
    and      r1.vincolo_gen_id =r.vincolo_gen_id 
    and      r1.data_cancellazione  is null
    and      r1.validita_fine is null
    )
    and      r.data_cancellazione  is null 
    and      r.validita_fine is null
    and      vinc.data_cancellazione  is null 
    and      vinc.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'Inseriti numeroVincoli[siac_r_vincolo_genere]=%',coalesce(codResult::varchar,'0');
   
    strMessaggio:='Inserimento nuovi vincoli [siac_r_vincolo_risorse_vincolate] in annoBilancio='||annoBilancio::varchar||'.';
    codResult:=null;
    --    siac_r_vincolo_risorse_vincolate
    insert into siac_r_vincolo_risorse_vincolate 
    (
     vincolo_id,
  	 vincolo_risorse_vincolate_id,
  	 validita_inizio,
  	 login_operazione ,
  	 ente_proprietario_id 
    )
    select vinc.vincolo_id,
                r.vincolo_risorse_vincolate_id,
                clock_timestamp(),
                loginOperazione,
                vinc.ente_proprietario_id 
    from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo ,
               siac_r_vincolo_risorse_vincolate r
    where tipo.ente_proprietario_id= enteProprietarioId 
    and      tipo.vincolo_tipo_code='P'
    and      vinc.vincolo_tipo_id=tipo.vincolo_tipo_Id 
    and      vinc.periodo_id=periodoId 
    and      vinc.login_operazione  like '%@'||faseBilElabId::varchar||'%'
    and      r.vincolo_id=split_part(vinc.login_operazione,'@',3)::integer  
    and      not exists 
    (
    select 1 
    from siac_r_vincolo_risorse_vincolate r1 
    where  r1.vincolo_id=vinc.vincolo_id 
    and      r1.vincolo_risorse_vincolate_id =r.vincolo_risorse_vincolate_id 
    and      r1.data_cancellazione  is null
    and      r1.validita_fine is null
    )
    and      r.data_cancellazione  is null 
    and      r.validita_fine is null
    and      vinc.data_cancellazione  is null 
    and      vinc.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'Inseriti numeroVincoli[siac_r_vincolo_risorse_vincolate]=%',coalesce(codResult::varchar,'0');
   
    strMessaggio:='Inserimento nuovi vincoli [siac_r_vincolo_attr] in annoBilancio='||annoBilancio::varchar||'.';
    codResult:=null;
    --    siac_r_vincolo_attr
    insert into siac_r_vincolo_attr 
    (
     vincolo_id,
  	 attr_id,
  	 tabella_id,
	 boolean,
	 percentuale,
 	 testo,
  	 numerico,
  	 validita_inizio,
  	 login_operazione ,
  	 ente_proprietario_id 
    )
    select vinc.vincolo_id,
		    	r.attr_id,
	  	        r.tabella_id,
	     	    r.boolean,
			    r.percentuale,
	      	    r.testo,
	     	    r.numerico,
                clock_timestamp(),
                loginOperazione,
                vinc.ente_proprietario_id 
    from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo ,
               siac_r_vincolo_attr r
    where tipo.ente_proprietario_id= enteProprietarioId 
    and      tipo.vincolo_tipo_code='P'
    and      vinc.vincolo_tipo_id=tipo.vincolo_tipo_Id 
    and      vinc.periodo_Id =periodoId
    and      vinc.login_operazione  like '%@'||faseBilElabId::varchar||'%'
    and      r.vincolo_id=split_part(vinc.login_operazione,'@',3)::integer  
    and      not exists 
    (
    select 1 
    from siac_r_vincolo_attr r1 
    where  r1.vincolo_id=vinc.vincolo_id 
    and      r1.attr_id =r.attr_id 
    and      r1.data_cancellazione  is null
    and      r1.validita_fine is null
    )
    and      r.data_cancellazione  is null 
    and      r.validita_fine is null
    and      vinc.data_cancellazione  is null 
    and      vinc.validita_fine is null;
   GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'Inseriti numeroVincoli[siac_r_vincolo_attr]=%',coalesce(codResult::varchar,'0');
   
   strMessaggio:='Inserimento nuovi vincoli [siac_r_vincolo_bil_elem] in annoBilancio='||annoBilancio::varchar||'.';
   codResult:=null;
   --    siac_r_vincolo_bil_elem 
   insert into siac_r_vincolo_bil_elem 
    (
     vincolo_id,
  	 elem_id,
  	 validita_inizio,
  	 login_operazione ,
  	 ente_proprietario_id 
    )
    select vinc.vincolo_id,
		    	ePrev.elem_id,
                clock_timestamp(),
                loginOperazione,
                vinc.ente_proprietario_id 
    from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo ,
               siac_r_vincolo_bil_elem r,siac_t_bil_elem e,siac_d_bil_elem_tipo tipo_elem,
               siac_t_bil_elem ePrev,siac_d_bil_elem_tipo tipo_elem_prev,
               siac_r_bil_elem_stato rs,siac_d_bil_elem_stato stato 
    where tipo.ente_proprietario_id= enteProprietarioId 
    and      tipo.vincolo_tipo_code='P'
    and      vinc.vincolo_tipo_id=tipo.vincolo_tipo_Id 
    and      vinc.periodo_Id =periodoId
    and      vinc.login_operazione  like '%@'||faseBilElabId::varchar||'%'
    and      r.vincolo_id=split_part(vinc.login_operazione,'@',3)::integer  
    and      e.elem_id=r.elem_id 
    and      tipo_elem.elem_tipo_id=e.elem_tipo_id 
    and      tipo_elem_prev.ente_proprietario_id =tipo_elem.ente_proprietario_id 
    and     (case when tipo_elem.elem_tipo_code='CAP-UG' then tipo_elem_prev.elem_tipo_code='CAP-UP' else tipo_elem_prev.elem_tipo_code='CAP-EP' end )
    and     ePrev.elem_tipo_id=tipo_elem_prev.elem_tipo_id 
    and     ePrev.bil_id=bilancioId
    and     ePrev.elem_code=e.elem_code 
    and     ePrev.elem_code2=e.elem_code2 
    and     ePrev.elem_code3=e.elem_code3 
    and     rs.elem_id=ePrev.elem_id 
    and     stato.elem_stato_id=rs.elem_Stato_id 
    and     stato.elem_stato_code!='AN'
    and      not exists 
    (
    select 1 
    from siac_r_vincolo_bil_elem r1 
    where  r1.vincolo_id=vinc.vincolo_id 
    and      r1.elem_id=ePrev.elem_id 
    and      r1.data_cancellazione  is null
    and      r1.validita_fine is null
    )
    and      r.data_cancellazione  is null 
    and      r.validita_fine is null
    and      vinc.data_cancellazione  is null 
    and      vinc.validita_fine is null
    and      e.data_cancellazione  is null 
    and      e.validita_fine is null
    and      ePrev.data_cancellazione  is null 
    and      ePrev.validita_fine is null
    and      rs.data_cancellazione  is null 
    and      rs.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice 'Inseriti numeroVincoli[siac_r_vincolo_bil_elem]=%',coalesce(codResult::varchar,'0');
   
  	 strMessaggio:='Inserimento LOG.';
 	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
     (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
     )
     values
     (faseBilElabId,strMessaggioFinale||' Inserimento nuovi vincoli in annoBilancio='||annoBilancio::varchar||'. Fine.',clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
     end if;    

  end if;
 
  strMessaggio:='Inserimento LOG.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||' Inserimento nuovi rel. su vincoli esistenti in annoBilancio='||annoBilancio::varchar||'. Inizio.',clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
  end if;    
 
  strMessaggio:='Inserimento nuovi vincoli [siac_r_vincolo_bil_elem] su vincoli esistenti in annoBilancio='||annoBilancio::varchar||'.';
  raise notice '%',strMessaggio;
  codResult:=null;
  --    vincoli esistenti
  --    siac_t_vincolo 
  --    siac_r_vincolo_bil_elem 
  insert into siac_r_vincolo_bil_elem 
  (
    vincolo_id,
    elem_id,
    validita_inizio ,
    login_operazione ,
    ente_proprietario_id 
  )
  select vincPrev.vincolo_id,
              capPrev.elem_id,
              clock_timestamp(),
              loginOperazione,
              vinc.ente_proprietario_id 
   from siac_t_vincolo vinc, siac_d_vincolo_tipo tipo ,siac_t_periodo per ,
              siac_r_vincolo_Stato rs,siac_d_vincolo_stato stato ,
              siac_r_vincolo_bil_elem r, siac_t_bil_elem capGest,siac_d_bil_elem_tipo tipoCapGest,
              siac_t_vincolo vincPrev,siac_d_vincolo_tipo tipoPrev,
              siac_r_vincolo_stato rsPrev,siac_d_vincolo_stato statoPrev ,
              siac_t_bil_elem capPrev,siac_d_bil_elem_tipo tipoCapPrev,
              siac_r_bil_elem_stato rsCapPrev, siac_d_bil_elem_stato statoCapPrev
    where  tipo.ente_proprietario_id =enteProprietarioId 
    and       tipo.vincolo_tipo_code='G'
    and       vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
    and       per.periodo_id=vinc.periodo_id 
    and       per.anno::integer=annoBilancio-1
    and       rs.vincolo_id=vinc.vincolo_id 
    and       stato.vincolo_stato_id=rs.vincolo_stato_id 
    and       stato.vincolo_stato_code!='A'
    and       r.vincolo_id=vinc.vincolo_id 
    and       capGest.elem_id=r.elem_id 
    and       tipoCapGest.elem_tipo_id =capGest.elem_tipo_id 
    and       capPrev.bil_id=bilancioId 
    and       capPrev.elem_code=capGest.elem_code 
    and       capPrev.elem_code2=capGest.elem_code2
    and       capPrev.elem_code3=capGest.elem_code3
    and       tipoCapPrev.elem_tipo_id=capPrev.elem_tipo_id
    and       (case when tipoCapGest.elem_tipo_code='CAP-UG' then tipoCapPrev.elem_tipo_code='CAP-UP' else tipoCapPrev.elem_tipo_code='CAP-EP' end )
    and       rsCapPrev.elem_id=capPrev.elem_id 
    and       statoCapPrev.elem_Stato_id=rsCapPrev.elem_stato_id 
    and       statoCapPrev.elem_Stato_code!='AN'
    and       vincPrev.periodo_id=periodoId 
    and       tipoPrev.vincolo_tipo_id=vincPrev.vincolo_tipo_id 
    and       tipoPrev.vincolo_tipo_code='P'
    and       vincPrev.vincolo_code=vinc.vincolo_code 
    and       vincPrev.login_operazione not like '%@'||faseBilElabId::varchar||'%'
    and       rsPrev.vincolo_id=vincPrev.vincolo_id 
    and       statoPrev.vincolo_stato_id =rsPrev.vincolo_stato_id 
    and       statoPrev.vincolo_stato_code !='A'
    and       not exists 
    (
    select 1 
    from siac_r_vincolo_bil_elem rPrev
    where rPrev.elem_id=capPrev.elem_id 
    and     rPrev.vincolo_id=vincPrev.vincolo_id 
    and     rPrev.data_cancellazione  is null 
    and     rPrev.validita_fine  is null
    )
    and      vinc.data_cancellazione  is null 
    and      vinc.validita_fine  is null 
    and      rs.data_cancellazione  is null 
    and      rs.validita_fine  is null
    and      r.data_cancellazione  is null 
    and      r.validita_fine  is null
    and      vincPrev.data_cancellazione  is null 
    and      vincPrev.validita_fine  is null
    and      rsPrev.data_cancellazione  is null 
    and      rsPrev.validita_fine  is null
    and      capGest.data_cancellazione  is null 
    and      capGest.validita_fine  is null
    and      capPrev.data_cancellazione  is null 
    and      capPrev.validita_fine  is null
    and      rsCapPrev.data_cancellazione  is null 
    and      rsCapPrev.validita_fine  is null;
    GET DIAGNOSTICS numeroVincoliRel = ROW_COUNT;
    raise notice 'Inseriti numeroVincoli_rel[siac_r_vincolo_bil_elem]=%',coalesce(numeroVincoliRel,'0')::varchar;
    
    strMessaggioErr:='Vincoli nuovi inseriti='||coalesce(numeroVincoli,'0')::varchar||'.Rel. vincoli esistenti inserite='||coalesce(numeroVincoliRel,'0')::varchar||'.';
    raise notice '%',strMessaggioErr;
   
    strMessaggio:='Inserimento LOG.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' Inserimento nuovi rel.='||coalesce(numeroVincoliRel,'0')::varchar||' su vincoli esistenti in annoBilancio='||annoBilancio::varchar||'. Fine.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;    
    
   if codiceRisultato=0 and faseBilElabId is not null then
       strmessaggio:='Allineamento Vincoli da gestione anno-1='||(annoBilancio-1)::varchar||' a previsione  anno='||annoBilancio::varchar||'.';

	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
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

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_PREV_VINCOLI||' da gestione anno-1  a previsione anno TERMINATA CON SUCCESSO.'||upper(strMessaggioErr)
       where fase_bil_elab_id=faseBilElabId;

       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

	 else
      if codiceRisultato!=0 and faseBilElabId is not null then
       strmessaggio:='Allineamento Vincoli da gestione anno-1='||(annoBilancio-1)::varchar||' a previsione  anno='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
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

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_PREV_VINCOLI||' da gestione anno-1  a previsione anno TERMINATA CON ERRORE.'
       where fase_bil_elab_id=faseBilElabId;
      end if;
     end if;
   
   
    
	 if  codiceRisultato=0 then
	  	 messaggioRisultato := strMessaggioFinale||' Operazione terminata correttamente.'||strMessaggioErr;
	  	 if faseBilElabId is not null then 
 	  	 	faseBilElabIdRet:=faseBilElabId;
   	   	 end if; 
	 else
  	  	 messaggioRisultato := strMessaggioFinale||strMessaggio;
     end if;

	 RETURN;
EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter FUNCTION siac.fnc_fasi_bil_prev_allinea_vincoli
(
integer, 
integer, 
varchar, 
timestamp without time zone, 
OUT integer,
OUT integer, 
OUT  varchar
) owner to siac;
