/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_entrata_chiu_elab
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  flussoElabMifId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar )
RETURNS record AS
$body$
DECLARE

strMessaggio VARCHAR(1500):='';
strMessaggioFinale VARCHAR(1500):='';

flussoElabRec record;
ordStatoCodeIId integer:=null;
ordStatoCodeTId integer:=null;

MANDMIF_TIPO CONSTANT varchar:='REVMIF';
ORD_STATO_CODE_I CONSTANT  varchar :='I';
ORD_STATO_CODE_T CONSTANT  varchar :='T';
-- 12.08.2019 Sofia SIAC-6950
ORD_STATO_CODE_V CONSTANT  varchar :='V';

dataFineVal timestamp :=annoBilancio||'-12-31';

BEGIN

	codiceRisultato:=0;
    messaggioRisultato:='';


	strMessaggioFinale:='Invio ordinativi di spesa al MIF tipo_flusso='||MANDMIF_TIPO||'.Aggiornamento data trasmissione.';

	-- ordStatoCodeIId
    strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_I||'.';
    select ord_tipo.ord_stato_id into strict ordStatoCodeIId
    from siac_d_ordinativo_stato ord_tipo
    where ord_tipo.ente_proprietario_id=enteProprietarioId
    and   ord_tipo.ord_stato_code=ORD_STATO_CODE_I
    and   ord_tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
-- 	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));
    and   ord_tipo.validita_fine is null;

	-- ordStatoCodeTId
    strMessaggio:='Lettura ordinativo stato Code Id '||ORD_STATO_CODE_T||'.';
    select ord_tipo.ord_stato_id into strict ordStatoCodeTId
    from siac_d_ordinativo_stato ord_tipo
    where ord_tipo.ente_proprietario_id=enteProprietarioId
    and   ord_tipo.ord_stato_code=ORD_STATO_CODE_T
    and   ord_tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',ord_tipo.validita_inizio)
-- 	and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(ord_tipo.validita_fine,dataFineVal));
    and   ord_tipo.validita_fine is null;



    -- inserimento record in tabella mif_t_flusso_elaborato
    strMessaggio:='Lettura mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId||'.';

    -- lettura mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId per verificare stato elaborazione

	select * into flussoElabRec
    from mif_t_flusso_elaborato mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.flusso_elab_mif_esito='IN'
    and   mif.data_cancellazione is null
    and   mif.validita_fine is null;

	if NOT FOUND then
    	raise exception ' Dati elaborazione non presenti in stato IN.';
    end if;

    --- aggiornamento di siac_t_ordinativo per ord_id in
    --- mif_t_ordinativo_entrata.mif_ord_flusso_elab_mif_id=flussoElabMifId
	strMessaggio:='Aggiornamento data su ordinativi per flussoElabMifId='||flussoElabMifId||'.';
	update siac_t_ordinativo o
    set  ord_trasm_oil_data=dataElaborazione,
         ord_spostamento_data=
         (case when substring(mif.mif_ord_codice_funzione from 1 for 1)=ORD_STATO_CODE_V  and
                    date_trunc('DAY',o.ord_spostamento_data)=date_trunc('DAY',dataElaborazione)
               then date_trunc('DAY',date_trunc('DAY',dataElaborazione)-interval '1 day')
               else o.ord_spostamento_data end ) -- 12.08.2019 Sofia SIAC-6950
    from  mif_t_ordinativo_entrata mif
    where mif.mif_ord_flusso_elab_mif_id=flussoElabMifId
    and   o.ord_id =mif.mif_ord_ord_id;

    strMessaggio:='Aggiornamento validita_fine stato operativo='||ORD_STATO_CODE_I||' su ordinativi per flussoElabMifId='||flussoElabMifId||'.';
    update siac_r_ordinativo_stato r set validita_fine=now()
    from mif_t_ordinativo_entrata mif
    where mif.mif_ord_flusso_elab_mif_id=flussoElabMifId
    and r.ord_id=mif.mif_ord_ord_id
    and   r.data_cancellazione is null
    and   r.validita_fine is NULL
    and   r.ord_stato_id=ordStatoCodeIId;

    strMessaggio:='Inserimento  stato operativo='||ORD_STATO_CODE_T||' su ordinativi per flussoElabMifId='||flussoElabMifId||'.';
    insert into siac_r_ordinativo_stato
    ( ord_id,
	  ord_stato_id,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione)
    (select  mif.mif_ord_ord_id, ordStatoCodeTId,now(),enteProprietarioId,loginOperazione
     from  mif_t_ordinativo_entrata mif
     where mif.mif_ord_flusso_elab_mif_id=flussoElabMifId
     and   substring(mif.mif_ord_codice_funzione from 1 for 1)=ORD_STATO_CODE_I
    );

    -- cancellazione mif_ordinativo_spesa_id
    strMessaggio:='Cancellazione tabella temporanea mif_t_ordinativo_entrata_id flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_ordinativo_entrata_id where ente_proprietario_id=enteProprietarioId;

    -- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
    strMessaggio:='Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId||'.';
    update  mif_t_flusso_elaborato
    set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	   ('OK','ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '||MANDMIF_TIPO||'.',now())
    where flusso_elab_mif_id=flussoElabMifId;

    messaggioRisultato:=strMessaggioFinale||' Elaborazione conclusa OK.';
    messaggioRisultato:=upper(messaggioRisultato);
    return;

exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
     	codiceRisultato:=-1;
		messaggioRisultato:=upper(messaggioRisultato);
		update  mif_t_flusso_elaborato
   		set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg)=
            ('KO',messaggioRisultato)
		where flusso_elab_mif_id=flussoElabMifId;
        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;