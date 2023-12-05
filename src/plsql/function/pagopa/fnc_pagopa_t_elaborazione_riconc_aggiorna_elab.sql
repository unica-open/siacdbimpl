/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_aggiorna_elab
(
  pagoPaElabId            integer,
  pagoPaElabFileXMLId     varchar,
  pagoPaElabFileOra       varchar,
  pagoPaElabFileEnte      varchar,
  pagoPaElabFileFruitore  varchar,
  pagoPaElabFileStatoCode varchar,
  dataChiusuraElab        timestamp,
  enteProprietarioId      integer,
  loginoperazione         varchar,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult integer:=null;


BEGIN

	strMessaggioFinale:='Aggiornamento elaborazione PAGOPA per pagopa_elab_id='||pagoPaElabId::varchar
                      ||'. PagoPaElabStatoCode='||coalesce(pagoPaElabFileStatoCode,' ')||'.';

    codiceRisultato:=0;
    messaggioRisultato:='';

    codResult:=null;
    strmessaggio:='Verifica esistenza elaborazione.';
	select 1 into codResult
    from pagopa_t_elaborazione elab
    where     elab.pagopa_elab_id=pagoPaElabId
    and       elab.data_cancellazione is null
    and       elab.validita_fine is null;

    if codResult is null then
    	RAISE EXCEPTION ' NON EFFETTUATO.Elaborazione non esistente.';
    end if;


    strmessaggio:='Aggiornamento [pagopa_t_elaborazione].';
    codResult:=null;
    update pagopa_t_elaborazione elab
    set    pagopa_elab_file_id= (case when coalesce(pagoPaElabFileXMLId,'')='' then elab.pagopa_elab_file_id
                                      else pagoPaElabFileXMLId end ),
           pagopa_elab_file_ora=(case when coalesce(pagoPaElabFileOra,'')='' then elab.pagopa_elab_file_ora
                                      else pagoPaElabFileOra end ),
           pagopa_elab_file_ente=(case when coalesce(pagoPaElabFileEnte,'')='' then elab.pagopa_elab_file_ente
                                      else pagoPaElabFileEnte end ),
           pagopa_elab_file_fruitore=(case when coalesce(pagoPaElabFileFruitore,'')='' then elab.pagopa_elab_file_fruitore
                                      else pagoPaElabFileFruitore end ),
    	   pagopa_elab_stato_id=(case when coalesce(pagoPaElabFileStatoCode,'')='' then elab.pagopa_elab_stato_id
                                      else (select stato.pagopa_elab_stato_id
                                            from pagopa_d_elaborazione_stato stato
                                            where stato.ente_proprietario_id=enteProprietarioId
                                            and   stato.pagopa_elab_stato_code=pagoPaElabFileStatoCode) end ),
           login_operazione=elab.login_operazione||'-'||loginOperazione,
           validita_fine=(case when dataChiusuraElab is null then null
                          else dataChiusuraElab end),
		   data_modifica=now()
    where elab.pagopa_elab_id=pagoPaElabId
    and   elab.data_cancellazione is null
    and   elab.validita_fine is null
    returning elab.pagopa_elab_id into codResult;

    if codResult is null then
    	RAISE EXCEPTION ' NON EFFETTUATO.Verificare.';
    end if;

	-- verificare quando fare chiusura della siac_t_file_pagopa

    messaggioRisultato:=upper(strMessaggioFinale||' Effettuato.');
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