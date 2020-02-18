/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿drop function fnc_fasi_bil_gest_reimputa(
  enteProprietarioId     	integer,
  annoBilancio           	integer,
  loginOperazione        	varchar,
  p_dataElaborazione       	timestamp,
  p_movgest_tipo_code      	varchar,
  out outfaseBilElabRetId   integer,
  out codiceRisultato    	integer,
  out messaggioRisultato 	varchar
);

drop FUNCTION fnc_fasi_bil_gest_reimputa
(
  enteProprietarioId     	integer,
  annoBilancio           	integer,
  impostaProvvedimento	    varchar, -- 07.02.2018 Sofia siac-5368
  loginOperazione        	varchar,
  p_dataElaborazione       	timestamp,
  p_movgest_tipo_code      	varchar,
  out outfaseBilElabRetId   integer,
  out codiceRisultato    	integer,
  out messaggioRisultato 	varchar
);

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa
(
  enteProprietarioId     	integer,
  annoBilancio           	integer,
  loginOperazione        	varchar,
  p_dataElaborazione       	timestamp,
  p_movgest_tipo_code      	varchar,
  impostaProvvedimento	    varchar = 'true', -- 07.02.2018 Sofia siac-5368
  out outfaseBilElabRetId   integer,
  out codiceRisultato    	integer,
  out messaggioRisultato 	varchar
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


    strMessaggio:='Inserimento fase elaborazione [fnc_fasi_bil_gest_reimputa].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE REIMPUTAZIONE IN CORSO.',tipo.fase_bil_elab_tipo_id,ente_proprietario_id, p_dataElaborazione, loginOperazione
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

/*
A)
Il sistema verifica che l’elaborazione non sia gia stata effettuata:
SE per l’anno di bilancio in elaborazione il flagReimputaSpese e a TRUE l’elaborazione viene interrotta con l’errore
- quindi se su siac_t_bil per annoBilancio=2017
               siac_r_bil_attr per attr_code in flagReimputaSpese,flagReimputaEntrate il valore e impostato a S, se si blocchi elaborazione, se no procedi

Verificare che non ci siano elaborazioni in corso per APE_GEST_REIMP in fase_bil_t_elaborazione ( come fanno le altre function )
Inserire nella fase_bil_t_elaborazione il fase_elab_id per  APE_GEST_REIMP
*/

    if p_movgest_tipo_code = 'I' then
        v_attr_code := 'flagReimputaSpese';
        select attr_id into v_attr_id  from siac_t_attr where ente_proprietario_id = enteProprietarioId and   data_cancellazione is null and      attr_code = 'flagReimputaSpese';
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

	select * into faseRec
    from fnc_fasi_bil_gest_reimputa_popola
    	 (
    	  v_faseBilElabId            ,
    	  enteProprietarioId     	,
          annoBilancio           	,
          loginOperazione        	,
          p_dataElaborazione       	,
          p_movgest_tipo_code
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
          );
    if faseRec.codiceRisultato=-1  then
     strMessaggio:='Lancio elaborazione.'||faseRec.messaggioRisultato;
     raise exception ' Errore Lancio elaborazione % .',faseRec.messaggioRisultato;
     return;
    end if;

    strMessaggio:='Aggiornamento attributo reimputazione avvenuta con succeeo poi chiusura.';
    update  siac_r_bil_attr set BOOLEAN='S',login_operazione = loginoperazione , data_modifica = now()
    where   bil_attr_id = v_bil_attr_id;

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