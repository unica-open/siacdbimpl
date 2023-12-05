/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_t_flusso_elaborato_getidelab (
  enteproprietarioid integer,
  nomeente varchar,
  tipoflussomif varchar,
  nomefilemif varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out flussoelabmifid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult integer:=null;

    ELAB_MIF_ESITO_IN       CONSTANT  varchar :='IN';


    -- costante tipo flusso presenti nei flussi non servono qui
    QUIET_MIF_FLUSSO_TIPO   CONSTANT  varchar :='R';    -- quietanze e storni
    FIRME_MIF_FLUSSO_TIPO   CONSTANT  varchar :='S';    -- firme
    PROVC_MIF_FLUSSO_TIPO   CONSTANT  varchar :='P';    -- provvisori

    -- costante tipo flusso presenti nella mif_d_flusso_elaborato_tipo
    -- valori di parametro tipoFlussoMif devono essere presenti in mif_d_flusso_elaborato_tipo
    QUIET_MIF_ELAB_FLUSSO_TIPO   CONSTANT  varchar :='RICQUMIF';    -- quietanze e storni
    FIRME_MIF_ELAB_FLUSSO_TIPO   CONSTANT  varchar :='RICFIMIF';    -- firme
    PROVC_MIF_ELAB_FLUSSO_TIPO   CONSTANT  varchar :='RICPCMIF';    -- provvisori di cassa
    GIOCASSA_MIF_ELAB_FLUSSO_TIPO CONSTANT  varchar :='GIOCASSA';    -- giornale di cassa

	flussoMifTipoId integer:=null;
    flussoElabMifLogId integer :=null;

BEGIN

	strMessaggioFinale:='Calcolo identificativo flusso elaborazione tipo flusso='||tipoFlussoMif||'.';

   	flussoElabMifId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';


	strMessaggio:='Lettura identificativo tipo flusso.';
    select tipo.flusso_elab_mif_tipo_id into strict flussoMifTipoId
    from mif_d_flusso_elaborato_tipo tipo
    where tipo.flusso_elab_mif_tipo_code=tipoFlussoMif
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    and   tipoFlussoMif in (QUIET_MIF_ELAB_FLUSSO_TIPO,FIRME_MIF_ELAB_FLUSSO_TIPO,PROVC_MIF_ELAB_FLUSSO_TIPO,GIOCASSA_MIF_ELAB_FLUSSO_TIPO);

    -- verifica di elaborazioni pendendenti per il tipo flusso
    -- sulla mif_t_flusso_elaborato
    strMessaggio:='Verifica esistenza elaborazioni in corso [mif_t_flusso_elaborato].';
	codResult:=null;
    select distinct 1 into codResult
    from mif_t_flusso_elaborato elab
    where  elab.flusso_elab_mif_tipo_id=flussoMifTipoId
    and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    and    elab.data_cancellazione is null
    and    elab.validita_fine is null;

    if codResult is not null then
    	RAISE EXCEPTION 'Verificare situazioni esistenti.';
    end if;

    -- verifica di elaborazioni pendendenti per il tipo flusso
    -- sulla mif_t_oil_ricevuta

    strMessaggio:='Verifica esistenza elaborazioni in corso [mif_t_flusso_elaborato].';
	codResult:=null;
    /*select distinct 1 into codResult
    from mif_t_oil_ricevuta ric, mif_t_flusso_elaborato elab
    where  elab.flusso_elab_mif_id=ric.flusso_elab_mif_id
    and    elab.flusso_elab_mif_tipo_id=flussoMifTipoId
    and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
    and    ric.data_cancellazione is null
    and    ric.validita_fine is null
    and    elab.data_cancellazione is null
    and    elab.validita_fine is null;*/

    select distinct 1 into codResult
    from mif_t_oil_ricevuta ric
    where    ric.data_cancellazione is null
    and    ric.validita_fine is null;

    if codResult is not null then
    	RAISE EXCEPTION 'Verificare situazioni esistenti.';
    end if;

    -- inserimento mif_t_flusso_elaborato
	strMessaggio:='Inserimento mif_t_flusso_elaborato.';
	insert into mif_t_flusso_elaborato
    (flusso_elab_mif_data ,
     flusso_elab_mif_esito,
     flusso_elab_mif_esito_msg,
     flusso_elab_mif_file_nome,
     flusso_elab_mif_tipo_id,
     validita_inizio,
     ente_proprietario_id,
     login_operazione)
     values
     (dataElaborazione,
      ELAB_MIF_ESITO_IN,
      'Elaborazione in corso per tipo flusso '||tipoFlussoMif,
      nomeFileMif,
      flussoMifTipoId,
 	  dataElaborazione,
      enteProprietarioId,
      loginOperazione
     )
     returning flusso_elab_mif_id into flussoElabMifLogId; -- valore da restituire

     raise notice 'flussoElabMifLogId %',flussoElabMifLogId;

     if flussoElabMifLogId is null then
       RAISE EXCEPTION ' Errore generico in inserimento %.',tipoFlussoMif;
     end if;


     flussoElabMifId:=flussoElabMifLogId;
     return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	  codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	flussoElabMifId:=null;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	flussoElabMifId:=null;

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	flussoElabMifId:=null;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	flussoElabMifId:=null;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;