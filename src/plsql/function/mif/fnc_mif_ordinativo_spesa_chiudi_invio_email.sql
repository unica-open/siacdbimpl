/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_chiudi_invio_email (
  enteproprietarioid integer,
  annobilancio integer,
  nomeente varchar,
  tipoflussomif varchar,
  flussoelabmifid integer,
  oilricevutaemailid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
    strMessaggio VARCHAR(1500):='';
    strMessaggioFinale VARCHAR(1500):='';
    flussoMifTipoId         integer:=null;
    nomeFileMif             varchar:=null;
    flussoElabMifNewId      integer:=null;
    countAggOrd             numeric:=null;
    codResult               integer :=null;
    codResult1              integer :=null;
    statoElab               varchar(100):=null;

    INVIO_AVVISO_EMAIL_BONIF_TIPO CONSTANT  varchar :='INVIO_AVVISO_EMAIL_BONIF';    -- invii avvisi per quietanzamento
    ELAB_MIF_ESITO_IN             CONSTANT  varchar :='IN';
    ELAB_MIF_ESITO_OK             CONSTANT  varchar :='OK';
    ELAB_MIF_ESITO_KO             CONSTANT  varchar :='KO';


BEGIN
    strMessaggioFinale:='Elaborazione predisposizione dati per invio email '||tipoFlussoMif||'. Chiusura dati.';

    codiceRisultato:=0;
    messaggioRisultato:='';

    -- controlla esistenza , deve esistere in mif_t_flusso_elaborato per tipoFlussoMif in corso per flussoElabMifId
    strMessaggio:='Lettura identificativo tipo flusso.';
    select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file
    into  flussoMifTipoId, nomeFileMif
    from mif_d_flusso_elaborato_tipo tipo
    where tipo.flusso_elab_mif_tipo_code=tipoFlussoMif
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
	if flussoMifTipoId is null then
    	raise exception ' Identificativo non reperito.';
    end if;

    strMessaggio:='Verifica esistenza elaborazione [mif_t_flusso_elaborato].';
    select  1, coalesce(mif.flusso_elab_mif_num_ord_elab,0), mif.flusso_elab_mif_esito
     into codResult,countAggOrd, statoElab
      from mif_t_flusso_elaborato mif
    where mif.flusso_elab_mif_id=flussoElabMifId
      and mif.flusso_elab_mif_tipo_id=flussoMifTipoId
      and mif.data_cancellazione is null
      and mif.validita_fine is null;
--       and mif.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN;

    if codResult is null then
        messaggioRisultato:='Parametro Id Elaborazione non presente-verificare.';
        codiceRisultato:=-1;
        return;
    else
        -- utilizza   flussoElabMifId
        flussoElabMifNewId:=flussoElabMifId;
    end if;

	if oilricevutaemailid is not null then
     if	statoElab!=ELAB_MIF_ESITO_IN then
     	messaggioRisultato:='Elaborazione non presente in stato '||ELAB_MIF_ESITO_IN||' ma in stato '||statoElab||' .';
        codiceRisultato:=-1;
        return;
     end if;

     codResult:=null;
     strMessaggio:='Verifica esistenza elaborazione aperta [mif_t_oil_ricevuta_invio_email] per oil_ricevuta_email_id='||oilricevutaemailid||'.';

     select 1 into codResult
     from mif_t_oil_ricevuta_invio_email mail
     where mail.oil_ricevuta_email_id=oilricevutaemailid
     and   mail.flusso_elab_mif_id=flussoElabMifNewId
     and   mail.oil_ricevuta_email_data_invio is null
     and   mail.oil_ricevuta_email_invio=false
     and   mail.data_cancellazione is null
     and   mail.validita_fine is null;
     if codResult is null then
    	raise exception ' Dati non reperiti.';
     end if;


     -- aggiornamento mif_t_oil_ricevuta_invio_email per flussoElabMifId
     -- oil_ricevuta_email_data_invio=dataElaborazione e oil_ricevuta_email_invio=true
     strMessaggio:='Aggiornamento mif_t_oil_ricevuta_invio_email  per oil_ricevuta_email_id='||oilricevutaemailid||'.';
     update  mif_t_oil_ricevuta_invio_email mail
     set oil_ricevuta_email_data_invio=dataElaborazione,
        oil_ricevuta_email_invio=true,
        login_operazione=mail.login_operazione||'-'||loginOperazione
     where   mail.flusso_elab_mif_id=flussoElabMifNewId
      and   mail.oil_ricevuta_email_id=oilRicevutaEmailId
      and   mail.oil_ricevuta_email_data_invio is null
      and   mail.oil_ricevuta_email_invio=false
      and   mail.data_cancellazione is null
      and   mail.validita_fine is null;

     if COALESCE(countAggOrd,0)=0 THEN
         countAggOrd := 1;
     else
         countAggOrd := countAggOrd + 1;
     end if;


     -- Determina quante email non sono ancora state spedite
     /*strMessaggio:='Verifica esistenza mif_t_oil_ricevuta_invio_email ulteriormente aperte.';
     codResult:=null;
     select distinct 1 into codResult
     from mif_t_oil_ricevuta_invio_email ric
     where ric.flusso_elab_mif_id=flussoElabMifNewId
     and ric.oil_ricevuta_email_data_invio is null
     and ric.oil_ricevuta_email_invio is false
     and ric.data_cancellazione is null
     and ric.validita_fine is null;*/

     /*if codResult is null then
        -- chiudere elaborazione solo se tutte le email sono state spedite
        -- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
        strMessaggio:='Elaborazione email avvisi quietanzamento.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifNewId||' - Email spedite='||countAggOrd||'.';

        update  mif_t_flusso_elaborato
        set flusso_elab_mif_esito='OK',
            flusso_elab_mif_esito_msg='ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '||INVIO_AVVISO_EMAIL_BONIF_TIPO||'.',
            flusso_elab_mif_num_ord_elab=COALESCE(countAggOrd,0),
            validita_fine=now()
         where flusso_elab_mif_id=flussoElabMifNewId
         and   data_cancellazione is null
         and   validita_fine is null;
     else*/
     -- 08.05.2017 Sofia chiusura solo se non viene passato oilRicevutaEmailId
     -- lascio aggiornamento per numero email spedita
     strMessaggio:='Elaborazione email avvisi quietanzamento ancora in corso [stato IN] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifNewId||' - Email spedite='||countAggOrd||'.';

     update  mif_t_flusso_elaborato
     set flusso_elab_mif_num_ord_elab=COALESCE(countAggOrd,0)
     where flusso_elab_mif_id=flussoElabMifNewId
     and   data_cancellazione is null
     and   validita_fine is null;

     --end if;
    else
        strMessaggio:='Verifica esistenza mif_t_oil_ricevuta_invio_email ulteriormente aperte.';
  	    codResult:=null;
	    select distinct 1 into codResult
	    from mif_t_oil_ricevuta_invio_email ric
	    where ric.flusso_elab_mif_id=flussoElabMifNewId
	    and ric.oil_ricevuta_email_data_invio is null
	    and ric.oil_ricevuta_email_invio = false
	    and ric.data_cancellazione is null
		and ric.validita_fine is null;
    	if	codResult is not null  then
            if statoElab!=ELAB_MIF_ESITO_OK and statoElab!=ELAB_MIF_ESITO_KO then

	           	strMessaggio:='Elaborazione email avvisi quietanzamento.Chiusura elaborazione [stato KO] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifNewId||' - Esistenza email da inviare.';

		        update  mif_t_flusso_elaborato
		        set flusso_elab_mif_esito='KO',
	    	        flusso_elab_mif_esito_msg='ELABORAZIONE CONCLUSA [STATO KO] PER TIPO FLUSSO '||INVIO_AVVISO_EMAIL_BONIF_TIPO
                                             ||'. ESISTENZA EMAIL DA INVIARE.',
        	    	validita_fine=now()
		         where flusso_elab_mif_id=flussoElabMifNewId
		         and   data_cancellazione is null
		         and   validita_fine is null;
            else
            	strMessaggio:='Elaborazione email avvisi quietanzamento precedentemente chiusa in stato '||statoElab||' .';
            end if;
        else
        	if statoElab!=ELAB_MIF_ESITO_OK and statoElab!=ELAB_MIF_ESITO_KO then
	            strMessaggio:='Elaborazione email avvisi quietanzamento.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifNewId||'.';

		        update  mif_t_flusso_elaborato
        		set flusso_elab_mif_esito='OK',
		            flusso_elab_mif_esito_msg='ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '||INVIO_AVVISO_EMAIL_BONIF_TIPO||'.',
                    flusso_elab_mif_num_ord_elab=COALESCE(countAggOrd,0),
   	                validita_fine=now()
		         where flusso_elab_mif_id=flussoElabMifNewId
		         and   data_cancellazione is null
		         and   validita_fine is null;
            else
            	strMessaggio:='Elaborazione email avvisi quietanzamento precedentemente chiusa in stato '||statoElab||' .';
            end if;

        end if;

    end if;

    messaggioRisultato:=strMessaggio;
    messaggioRisultato:=upper(messaggioRisultato);

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