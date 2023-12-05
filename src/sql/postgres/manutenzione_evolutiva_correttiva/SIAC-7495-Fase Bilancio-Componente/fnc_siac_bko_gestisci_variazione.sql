/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- function di
-- passaggio di stato variazione
-- da B-P
-- da B-D
-- da P-D
-- applicazione variazione
-- se variazione in stato D o passaggio a D effettua l'applicazione su capitoli e componenti
drop FUNCTION if exists siac.fnc_siac_bko_gestisci_variazione
(
  enteProprietarioId     integer,
  annoBilancio           integer,
  variazioneNum          integer,
  cambiaStatoVar         boolean,
  statoVar               varchar,
  applicaVar             boolean,
  loginOperazione         varchar,
  dataElaborazione       timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_gestisci_variazione
(
  enteProprietarioId     integer,
  annoBilancio           integer,
  variazioneNum          integer,
  cambiaStatoVar         boolean,
  statoVar               varchar,
  applicaVar             boolean,
  loginOperazione         varchar,
  dataElaborazione       timestamp
)
RETURNS  TABLE
(
codiceRisultato integer,
messaggioRisultato varchar
)

AS
$body$
DECLARE
	v_messaggiorisultato varchar;

  	v_messaggiorisultato_agg varchar;

    variazioneStatoid INTEGER:=null;
    variazioneStatoNewId integer:=null;
    variazioneStatoCode varchar(1):=null;
    variazioneId      integer:=null;

	-- 20.10.2020 Sofia SIAC-7495
    attoAmmId         integer:=null;
    attAmmVarBilId    integer:=null;

    codResult      integer:=null;
    codResult1      integer:=null;

    VAR_BOZZA_ST constant varchar(1):='B';
    VAR_DEF_ST constant varchar(1):='D';
    VAR_PRE_DEF_ST constant varchar(1):='P';
BEGIN

  codiceRisultato:=null;
  messaggioRisultato:=null;

  v_messaggiorisultato :='Gestione variazione '||variazioneNum::varchar||
                        '/'||annoBilancio::varchar||'.';

  v_messaggiorisultato_agg:=  v_messaggiorisultato;
  raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;

  v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Lettura dati variazione.';
  raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
  -- variazione_stato_id
  select r.variazione_stato_id,stato.variazione_Stato_tipo_code, var.variazione_id,
         r.attoamm_id,r.attoamm_id_varbil
         into variazioneStatoId, variazioneStatoCode,variazioneId,
              attoAmmId,attAmmVarBilId -- 20.10.2020 Sofia SIAC-7495
  from siac_t_variazione var, siac_v_bko_anno_bilancio anno,
   	   siac_r_variazione_stato r, siac_d_variazione_stato stato
  where anno.ente_proprietario_id=enteProprietarioId
  and   anno.anno_bilancio=annoBilancio
  and   var.bil_id=anno.bil_id
  and   var.variazione_num::integer=variazioneNum
  and   r.variazione_id=var.variazione_id
  and   stato.variazione_stato_tipo_id=r.variazione_stato_tipo_id
  and   stato.variazione_stato_tipo_code!='A'
  and   r.data_cancellazione is null
  and   r.validita_fine is null;

  if variazioneStatoId is null or variazioneStatoCode is null or variazioneId is null
  then
  	  v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Dato non reperito.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
  end if;

  -- se applico senza cambiamento di stato su stato non definitivo devo bloccare
  if applicaVar=true and  cambiaStatoVar = false and variazioneStatoCode!=VAR_DEF_ST
  then
      v_messaggiorisultato_agg:=  v_messaggiorisultato;
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Applicazione non effettuabile senza cambiamento di stato '||
                            ' su stato '||variazioneStatoCode||' .';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
  end if;
  -- se applico senza cambiamento di stato, lo stato deve essere definitivo
  -- quindi anche quello che uso per applicare
  if applicaVar=true and  cambiaStatoVar = false and variazioneStatoCode=VAR_DEF_ST  and statoVar!=VAR_DEF_ST
  then
  	statoVar:=VAR_DEF_ST;
  end if;

  -- se applico con cambiamento di stato senza passare a stato definitivo devo bloccare
  if applicaVar=true and  cambiaStatoVar = true and statoVar!=VAR_DEF_ST
  then
      v_messaggiorisultato_agg:=  v_messaggiorisultato;
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Applicazione non effettuabile senza cambiamento di stato a '||
                            VAR_DEF_ST||' .';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
  end if;

  -- se tento di passare allo stato D senza applicare devo bloccare
  if applicaVar=false and  cambiaStatoVar = true and statoVar=VAR_DEF_ST
  then
  	  v_messaggiorisultato_agg:=  v_messaggiorisultato;
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Passaggio allo stato DEFINITIVO non ammesso senza applicazione.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
  end if;


  -- check cambiamento di stato variazione
  if cambiaStatoVar = false then
       variazioneStatoNewId:=variazioneStatoId;
  else -- inserimento nuovi stati e dettagli
     v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
     v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovo stato variazione  '||
                            statoVar||'.';
     raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

  	insert into siac_r_variazione_stato
    (
    	variazione_id,
        variazione_Stato_tipo_id,
        attoamm_id,  -- 20.10.2020 Sofia SIAC-7495
        attoamm_id_varbil, -- 20.10.2020 Sofia SIAC-7495
        validita_Inizio,
        login_Operazione,
        ente_Proprietario_Id
    )
    select
         variazioneId,
         stato.variazione_Stato_tipo_Id,
         attoAmmId, -- 20.10.2020 Sofia SIAC-7495
         attAmmVarBilId, -- 20.10.2020 Sofia SIAC-7495
         clock_timestamp(),
         loginOperazione,
         stato.ente_proprietario_id
    from siac_d_variazione_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.variazione_stato_tipo_code=statoVar
    returning variazione_stato_id into variazioneStatoNewId;
    if variazioneStatoNewId is null then
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
    end if;

    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovo stato variazione  '||
                               statoVar||'. Chiusura prec. stato.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

    codResult:=null;
    update siac_r_variazione_stato rs
    set    data_cancellazione=clock_timestamp(),
           validita_fine=clock_timestamp(),
           login_operazione=rs.login_operazione||'-'||loginOperazione
    where rs.variazione_stato_id=variazioneStatoId
    returning rs.variazione_id into codResult;

    if codResult is null then
       v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
       raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

       codiceRisultato:=-1;
       messaggioRisultato:=v_messaggiorisultato_agg;
  	   return next;
       return;
    end if;
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione riuscita.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

    if variazioneStatoCode=VAR_BOZZA_ST and statoVar=VAR_DEF_ST then
        v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
        v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovo stato variazione  '||
                                  statoVar||' e '||VAR_PRE_DEF_ST||'.';
        raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
        codResult:=null;
    	insert into siac_r_variazione_stato
        (
            variazione_id,
            variazione_Stato_tipo_id,
            attoamm_id,  -- 20.10.2020 Sofia SIAC-7495
            attoamm_id_varbil, -- 20.10.2020 Sofia SIAC-7495
            validita_Inizio,
            validita_fine,
            data_cancellazione,
            login_Operazione,
            ente_Proprietario_Id
        )
        select
             variazioneId,
             stato.variazione_Stato_tipo_Id,
             attoAmmId, -- 20.10.2020 Sofia SIAC-7495
             attAmmVarBilId, -- 20.10.2020 Sofia SIAC-7495
             clock_timestamp(),
             clock_timestamp(),
             clock_timestamp(),
             loginOperazione,
             stato.ente_proprietario_id
        from siac_d_variazione_stato stato
        where stato.ente_proprietario_id=enteProprietarioId
        and   stato.variazione_stato_tipo_code=VAR_PRE_DEF_ST
        returning variazione_stato_id into codResult;
        if codResult is null then
            v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
            raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

       		codiceRisultato:=-1;
      		messaggioRisultato:=v_messaggiorisultato_agg;
  	  		return next;
     		return;
        end if;

    end if;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovi dettagli di variazione.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

    insert into siac_t_bil_elem_det_var
    (
    	 variazione_stato_id,
 		 elem_id,
 		 elem_det_importo,
 		 elem_det_tipo_id,
		 periodo_id,
         elem_det_flag,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         variazioneStatoNewId,
         dvar.elem_id,
 		 dvar.elem_det_importo,
 		 dvar.elem_det_tipo_id,
		 dvar.periodo_id,
         dvar.elem_det_flag,
         clock_timestamp(),
         loginOperazione||'@'||dvar.elem_Det_Var_id::varchar,
         dvar.ente_proprietario_id
    from siac_t_bil_elem_det_var dvar
    where dvar.variazione_Stato_id=variazioneStatoId
    and   dvar.data_cancellazione is null;

    v_messaggiorisultato_agg:=  v_messaggiorisultato;
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Verifica inserimento nuovi dettagli di variazione.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    -- verifica inserimento
    codResult:=null;
    select 1 into codResult
    from siac_t_bil_elem_det_var dvar
    where dvar.variazione_Stato_id=variazioneStatoNewId
    and   dvar.data_cancellazione is null;
    if codResult is null then
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
    end if;
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione riuscita.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Verifica esistenza dettagli di variazione componenti da inserire.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    -- verifica esistenza var componenti da inserire
    codResult:=null;
    select 1 into codResult
    from siac_t_bil_elem_det_var dvar,siac_t_bil_elem_det_var_comp var_comp,
         siac_t_bil_elem_Det_Var dvar_new
    where dvar.variazione_Stato_id=variazioneStatoId
    and   var_comp.elem_det_var_id=dvar.elem_det_var_id
    and   dvar_new.variazione_stato_id=variazioneStatoNewId
    and   dvar_new.login_operazione like loginOperazione||'@%'
    and   split_part(dvar_new.login_Operazione,'@',2)::integer=dvar.elem_Det_Var_id
    and   dvar.data_cancellazione is null
    and   dvar_new.data_cancellazione is null
    and   var_comp.data_cancellazione is null;

    if codResult is not null then
      codResult:=null;
      v_messaggiorisultato_agg:=  v_messaggiorisultato;
   	  v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovi dettagli di variazione componenti.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
       -- verifica esistenza var componenti da inserire
      insert into siac_t_bil_elem_det_var_comp
      (
           elem_det_var_id,
           elem_det_comp_id ,
           elem_Det_importo,
           elem_det_flag,
           validita_inizio,
           login_operazione,
           ente_proprietario_id
      )
      select
           dvar_new.elem_det_var_id,
           var_comp.elem_Det_comp_id,
           var_comp.elem_det_importo,
           var_comp.elem_det_flag,
           clock_timestamp(),
           loginOperazione,
           var_comp.ente_proprietario_id
      from siac_t_bil_elem_det_var dvar,siac_t_bil_elem_det_var_comp var_comp,
           siac_t_bil_elem_Det_Var dvar_new
      where dvar.variazione_Stato_id=variazioneStatoId
      and   var_comp.elem_det_var_id=dvar.elem_det_var_id
      and   dvar_new.variazione_stato_id=variazioneStatoNewId
      and   dvar_new.login_operazione like loginOperazione||'@%'
      and   split_part(dvar_new.login_Operazione,'@',2)::integer=dvar.elem_Det_Var_id
      and   dvar.data_cancellazione is null
      and   dvar_new.data_cancellazione is null
      and   var_comp.data_cancellazione is null;
      -- verifica inserimento

      codResult:=null;
      select 1 into codResult
      from siac_t_bil_elem_det_var dvar,siac_t_bil_elem_det_var_comp var_comp
      where dvar.variazione_Stato_id=variazioneStatoNewId
      and   var_comp.elem_det_var_id=dvar.elem_det_var_id
      and   dvar.data_cancellazione is null
      and   var_comp.data_cancellazione is null;
      if codResult is null then
        v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
        raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
        codiceRisultato:=-1;
        messaggioRisultato:=v_messaggiorisultato_agg;
  	    return next;
        return;
      end if;

      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione riuscita.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    end if;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato variazione effettuato.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
  end if;


  -- aggiornamento stanziamenti e componenti se statoVar=DEFINITIVO e applicaVar=true
  if statoVar=VAR_DEF_ST and applicaVar=true then

    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';

    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Verifica esistenza dettagli di variazione per aggiornamento stanziamenti.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    raise notice 'variazioneStatoNewId=%',variazioneStatoNewId;
    -- check se esistono det di stanziamento
    codResult:=null;
    select 1 into codResult
    from   siac_t_bil_elem_det_var dvar,siac_t_bil_elem_Det det
    where  dvar.variazione_stato_id=variazioneStatoNewId
    and    det.elem_id=dvar.elem_id
    and    det.elem_Det_tipo_id=dvar.elem_det_tipo_id
    and    det.periodo_id=dvar.periodo_id
    and    dvar.elem_det_importo!=0
    and    dvar.data_cancellazione is null
    and    det.data_cancellazione is null;
    raise notice 'codResult=%',codResult;
    if codResult is not null then
      v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';

      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Aggiornamento stanziamenti da dettagli di variazione.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
      codResult:=null;
      update siac_t_bil_elem_Det det
      set    elem_det_importo=det.elem_det_importo+dvar.elem_det_importo,
             data_modifica=clock_timestamp(),
             login_operazione=det.login_operazione||'-'||loginOperazione
      from   siac_t_bil_elem_det_var dvar
      where  dvar.variazione_stato_id=variazioneStatoNewId
      and    det.elem_id=dvar.elem_id
      and    det.elem_Det_tipo_id=dvar.elem_det_tipo_id
      and    det.periodo_id=dvar.periodo_id
      and    dvar.elem_det_importo!=0
      and    dvar.data_cancellazione is null
      and    det.data_cancellazione is null;
      GET DIAGNOSTICS codResult = ROW_COUNT;

      if codResult is null then
          v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Stanziamenti non aggiornati.';
          raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

          codiceRisultato:=-1;
          messaggioRisultato:=v_messaggiorisultato_agg;
          return next;
          return;
      end if;
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Stanziamenti  aggiornati.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

    end if;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';

    v_messaggiorisultato_agg:=v_messaggiorisultato_agg
                             ||' Verifica esistenza dettagli di variazione per aggiornamento componenti stanziamenti.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    -- check se esistono det di componente di stanziamento
    codResult:=null;
    select 1 into codResult
    from   siac_t_bil_elem_det_var dvar,siac_t_bil_elem_Det det,
           siac_t_bil_elem_Det_var_comp var_comp, siac_t_bil_elem_det_comp comp
    where  dvar.variazione_stato_id=variazioneStatoNewId
    and    det.elem_id=dvar.elem_id
    and    det.elem_Det_tipo_id=dvar.elem_det_tipo_id
    and    det.periodo_id=dvar.periodo_id
    and    dvar.elem_det_importo!=0
    and    var_comp.elem_Det_var_id=dvar.elem_det_var_id
    and    comp.elem_det_comp_id=var_comp.elem_det_comp_id
    and    comp.elem_det_id=det.elem_det_id
    and    var_comp.elem_det_importo!=0
    and    dvar.data_cancellazione is null
    and    det.data_cancellazione is null
    and    var_comp.data_cancellazione is null
    and    comp.data_cancellazione is null;
raise notice 'codResult=%',codResult;
    if codResult is not null then
      v_messaggiorisultato_agg:=  v_messaggiorisultato;

      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Aggiornamento componenti stanziamenti da dettagli di variazione.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codResult:=null;
      update siac_t_bil_elem_det_comp comp
      set    elem_det_importo=comp.elem_det_importo+var_comp.elem_det_importo,
             data_modifica=clock_timestamp(),
             login_operazione=comp.login_operazione||'-'||loginOperazione
      from   siac_t_bil_elem_det_var dvar,siac_t_bil_elem_Det det,
             siac_t_bil_elem_Det_var_comp var_comp
      where  dvar.variazione_stato_id=variazioneStatoNewId
      and    det.elem_id=dvar.elem_id
      and    det.elem_Det_tipo_id=dvar.elem_det_tipo_id
      and    det.periodo_id=dvar.periodo_id
      and    dvar.elem_det_importo!=0
      and    var_comp.elem_Det_var_id=dvar.elem_det_var_id
      and    comp.elem_det_comp_id=var_comp.elem_det_comp_id
      and    comp.elem_det_id=det.elem_det_id
      and    var_comp.elem_det_importo!=0
      and    dvar.data_cancellazione is null
      and    det.data_cancellazione is null
      and    var_comp.data_cancellazione is null
      and    comp.data_cancellazione is null;
      GET DIAGNOSTICS codResult = ROW_COUNT;

      if codResult is null then
          v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Componenti stanziamenti non aggiornati.';
          raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

          codiceRisultato:=-1;
          messaggioRisultato:=v_messaggiorisultato_agg;
          return next;
          return;
      end if;

      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Componenti stanziamenti aggiornati.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    end if;



    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';
    v_messaggiorisultato_agg:=  v_messaggiorisultato_agg||' Verifica esistenza capitoli provvisori in variazione.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    codResult:=null;
    select coalesce(count(distinct e.elem_id),0) into codResult
    from siac_t_bil_elem_det_var dvar,siac_t_bil_elem e,
         siac_r_bil_elem_Stato rs,siac_d_bil_elem_stato stato
    where dvar.variazione_stato_id=variazioneStatoNewId
    and   e.elem_id=dvar.elem_id
    and   rs.elem_id=e.elem_id
    and   stato.elem_stato_id=rs.elem_stato_id
    and   stato.elem_stato_code='PR'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null;
    raise notice 'codResult=%',codResult;

    if coalesce(codResult,0)!=0 then

      v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';
      v_messaggiorisultato_agg:=  v_messaggiorisultato_agg||' Aggiornamento stato capitoli provvisori in variazione.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
      update siac_r_bil_elem_Stato rs
      set    elem_stato_id=statoVA.elem_Stato_id,
             data_modifica=clock_timestamp(),
             login_operazione=rs.login_operazione||'-'||loginOperazione
      from siac_t_bil_elem_det_var dvar,siac_t_bil_elem e,
           siac_d_bil_elem_stato stato,siac_d_bil_elem_stato statoVA
      where dvar.variazione_stato_id=variazioneStatoNewId
      and   e.elem_id=dvar.elem_id
      and   rs.elem_id=e.elem_id
      and   stato.elem_stato_id=rs.elem_stato_id
      and   stato.elem_stato_code='PR'
      and   statoVA.ente_proprietario_id=stato.ente_proprietario_id
      and   statoVA.elem_stato_code='VA'
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null;
      GET DIAGNOSTICS codResult1 = ROW_COUNT;
      raise notice 'codResult1=%',codResult1;

      if coalesce(codResult,0)!=coalesce(codResult1,0) then
        v_messaggiorisultato_agg:=  v_messaggiorisultato_agg||' Operazione non riuscita.';
        raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
        codiceRisultato:=-1;
        messaggioRisultato:=v_messaggiorisultato_agg;
        return next;
        return;
      end if;

      v_messaggiorisultato_agg:=  v_messaggiorisultato_agg||' Operazione riuscita.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    end if;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione effettuata.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

 end if;


 codiceRisultato:=0;
 messaggioRisultato:=  v_messaggiorisultato||' Operazione terminata.';
 raise notice 'messaggioRisultato=%',messaggioRisultato;
 return next;
 return;

exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;
    messaggioRisultato:=  v_messaggiorisultato;
    codiceRisultato:=-1;
    return next;
    return;
	when others  THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;
    messaggioRisultato:=  v_messaggiorisultato;
    codiceRisultato:=-1;
    return next;
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

alter function siac.fnc_siac_bko_gestisci_variazione
(
   integer,
   integer,
   integer,
   boolean,
   varchar,
   boolean,
   varchar,
   timestamp
) owner to siac;