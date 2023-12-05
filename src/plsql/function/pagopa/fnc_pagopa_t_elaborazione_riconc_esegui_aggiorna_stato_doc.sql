/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc
(
  docId                           integer,
  filePagoPaElabId                integer,
  enteProprietarioId	          integer,
  loginOperazione                 varchar,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioLog VARCHAR(2500):='';

 codResult integer:=null;
 statoDoc  varchar:=null;


begin

  codicerisultato:=0;
  messaggiorisultato:='';

  strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                      'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                      ' Aggiornamento stato documento docId='||docId::varchar||'.';
  strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc - '||strMessaggioFinale;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  strMessaggio:=' Verifica esistenza documento.';
  select 1 into codResult
  from siac_t_subdoc sub, siac_t_doc doc
  where doc.doc_id=docId
  and   sub.doc_id=doc.doc_id
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null
  and   sub.data_cancellazione is null
  and   sub.validita_fine is null;
  if codResult is null then
  	strMessaggio:=strMessaggio||' Non esistente.';
    codiceRisultato:=-1;
    messaggioRisultato:=strMessaggioFinale||' '||strMessaggio;
    return;
  end if;

  strMessaggio:=' Verifica esistenza quote incassate per stato EM.';
  codResult:=null;
  select 1 into codResult
  from siac_t_subdoc sub, siac_r_subdoc_ordinativo_ts rts,
       siac_t_ordinativo_ts ts, siac_t_ordinativo ord,  siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
  where sub.doc_id=docId
  and   rts.subdoc_id=sub.subdoc_id
  and   ts.ord_ts_id=rts.ord_ts_id
  and   ord.ord_id=ts.ord_id
  and   rs.ord_id=ord.ord_id
  and   stato.ord_stato_id=rs.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   rs.data_cancellazione is null
  and   rs.validita_fine is null
  and   rts.data_cancellazione is null
  and   rts.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   sub.data_cancellazione is null
  and   sub.validita_fine is null;
  if codResult is not null then
  	statoDoc:='EM';
  end if;

  strMessaggio:=' Verifica esistenza quote incassate per stato PE.';
  if codResult is not null	 then
   codResult:=null;
   select 1 into codResult
   from siac_t_subdoc sub
   where sub.doc_id=docId
   and   not exists
   (select 1
    from siac_r_subdoc_ordinativo_ts rts,
         siac_t_ordinativo_ts ts, siac_t_ordinativo ord,  siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
    where rts.subdoc_id=sub.subdoc_id
    and   ts.ord_ts_id=rts.ord_ts_id
    and   ord.ord_id=ts.ord_id
    and   rs.ord_id=ord.ord_id
    and   stato.ord_stato_id=rs.ord_stato_id
    and   stato.ord_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   rts.data_cancellazione is null
    and   rts.validita_fine is null
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
   )
   and   sub.data_cancellazione is null
   and   sub.validita_fine is null;
   if codResult is not null then
   	statoDoc:='PE';
   end if;
  end if;

  if statoDoc is null then
    strMessaggio:=' Verifica esistenza quote incassate per stati V,I.';
  	codResult:=null;
    select 1 into codResult
    from siac_t_subdoc sub,siac_r_subdoc_movgest_ts rmov, siac_t_movgest_ts ts, siac_t_movgest mov,
         siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
    where sub.doc_id=docId
    and   rmov.subdoc_id=sub.subdoc_id
    and   ts.movgest_ts_id=rmov.movgest_ts_id
    and   mov.movgest_id=ts.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   rmov.data_cancellazione is null
    and   rmov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   sub.data_cancellazione is null
    and   sub.validita_fine is null;
    if codResult is null then
    	statoDoc:='I';
    else
    	statoDoc:='V';
    end if;
  end if;

  if statoDoc is not null then
    strMessaggio:=' Chiusura stato precedente.';
    codResult:=null;
  	update siac_r_doc_stato rs
    set    data_cancellazione=clock_timestamp(),
           validita_fine=clock_timestamp(),
           login_operazione=rs.login_operazione||'-'||loginOperazione
    where rs.doc_id=docId
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    returning rs.doc_stato_r_id into codResult;
    if codResult is not null then
     codResult:=null;
     strMessaggio:=' Inserimento nuovo stato='||statoDoc||'.';
     insert into siac_r_doc_stato
     (
    	doc_id,
        doc_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select docId,
            stato.doc_stato_id,
            clock_timestamp(),
            loginOperazione,
            stato.ente_proprietario_id
     from siac_d_doc_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.doc_stato_code=statoDoc
     returning doc_stato_r_id into codResult;
   end if;

   if codResult is not null then
    strMessaggio:=strMessaggio||' Effettuato.';
   else
   	codiceRisultato:=-1;
    strMessaggio:=strMessaggio||' Non effettuato.';
   end if;
  else
     codiceRisultato:=-1;
     strMessaggio:=strMessaggio||' Nuovo stato non determinato.';
  end if;

  messaggioRisultato:=upper(strMessaggioFinale||' '||strMessaggio);
  strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc - '||messaggioRisultato;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

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