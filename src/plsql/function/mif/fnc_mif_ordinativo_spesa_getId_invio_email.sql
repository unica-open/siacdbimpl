/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_getId_invio_email
( enteProprietarioId integer,
  annoBilancio integer,
  nomeEnte VARCHAR,
  tipoFlussoMif varchar,
  out flussoElabMifRetId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
    flussoMifTipoId         integer:=null;
    nomeFileMif             varchar:=null;
    flussoElabMifId         integer:=null;
    codResult               integer :=null;
    invioEmailCb            boolean :=null;

    INVIO_AVVISO_EMAIL_BONIF_TIPO CONSTANT  varchar :='INVIO_AVVISO_EMAIL_BONIF';    -- invii avvisi per quietanzamento
    ELAB_MIF_ESITO_IN             CONSTANT  varchar :='IN';

BEGIN

 	strMessaggioFinale:='Elaborazione predisposizione dati per invio email '||tipoFlussoMif||'. Lettura Id Elaborazione.';

    codiceRisultato:=0;
    messaggioRisultato:='';

    strMessaggio:='Verifica gestione attiva su ente.';
	select oil.ente_oil_invio_email_cb into invioEmailCb
    from siac_t_ente_oil oil
    where oil.ente_proprietario_id=enteProprietarioId;
    if invioEmailCb is null then
    	raise exception ' Errore in reperimento configurazione ente_oil.';
    end if;
    if invioEmailCb=false then
    	codiceRisultato:=-2;
        messaggioRisultato:=strmessaggio||'Gestione non attiva.';
        return;
    end if;

    -- controlla esistenza , deve esistere in mif_t_flusso_elaborato per tipoFlussoMif in corso per flussoElabMifId
	strMessaggio:='Lettura identificativo tipo flusso.';
    select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file
    into flussoMifTipoId, nomeFileMif
    from mif_d_flusso_elaborato_tipo tipo
    where tipo.flusso_elab_mif_tipo_code=tipoFlussoMif
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
	if flussoMifTipoId is null then
    	raise exception ' Identificativo non reperito.';
    end if;


    strMessaggio:='Verifica esistenza elaborazione aperta [mif_t_flusso_elaborato].';
    select distinct 1, mif.flusso_elab_mif_id
    into codResult, flussoElabMifId
      from mif_t_flusso_elaborato mif
     where mif.flusso_elab_mif_tipo_id=flussoMifTipoId
       and mif.data_cancellazione is null
       and mif.validita_fine is null
       and mif.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    order by mif.flusso_elab_mif_id;

    if codResult is null then
        messaggioRisultato:='Non ci sono elaborazione aperta [mif_t_flusso_elaborato] - tipo flusso = '||tipoFlussoMif||'.';
        codiceRisultato:=0;
    else
        -- utilizza   flussoElabMifId
        flussoElabMifRetId:=flussoElabMifId;
    end if;

    messaggioRisultato:=upper(strMessaggioFinale||' - OK.');
    return;

exception
    when RAISE_EXCEPTION THEN
         messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
     	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
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