/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

DROP FUNCTION if exists siac.fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer,
  annoBilancioFinale   integer,
  loginoperazione      varchar,
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer,
  annoBilancioFinale   integer,
  loginoperazione      varchar,
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
)
RETURNS record
 AS $body$
declare

strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
strMessaggioFinale VARCHAR(1500):='';


elabId integer:=null;
elabRec record;
   

-- in apertura saldi sempre calcolati entrambi
RicalcoloSaldi varchar(1):='S';
tipoAggiornamento varchar(1):='E';

isSaldiAttivi integer:=null;

BEGIN
/*
 * APERTURA DI ESERCIZIO PROVVISORIO O DEFINITIVO DA BILANCIO APPROVATO
 * I SALDI DEI CONTI SONO RICALCOLATI AUTOMATICAMENTE SU ANNO BILANCIO IN CHIUSURA
 * GLI STESSI SALDI SONO RIPORTATATI COME INIZIALI SU ANNO BILANCIO+1 IN APERTURA
 * LA FNC di CALCOLO VIENE ESEGUITA SOLO IL PARAMETRO DI SISTEMA GEST_SALDO_SOTTO_CONTI_VINC SI TROVA SUL DB
 * IN QUESTE FASI I SALDI NON SONO RICALCOLABILI AUTOMATICAMENTE
 * QUINDI NON DEVONO ESSERE PRESENTI SALDI VALIDI - SE DEVONO ESSERE RICALCOLATI AUTOMATICAMENTE
 * BISOGNA PRIMA INVALIDARE MANUALMENTE  
 * IL RISULTATO DI QUESTA FNC NON DEVE MAI INVALIDARE ESITO DI APERTURA DEL BILANCIO COMPLESSIVO
 * RICHIAMATA DA fnc_fasi_bil_gest_apertura_all
 */
strMessaggioFinale:='Elaborazione calcolo saldi sottoconti-vincolati da fase bilancio  - inizio.';
outElabId:=null;
codiceRisultato:=0;
messaggioRisultato:='';



raise notice '%',strMessaggioFinale;
raise notice 'annoBilancioIniziale=%',annoBilancioIniziale::varchar;
raise notice 'annoBilancioFinale=%',annoBilancioFinale::varchar;




select 1 into isSaldiAttivi
from siac_d_gestione_livello liv ,siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id =enteProprietarioId 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   liv.gestione_tipo_id =tipo.gestione_tipo_id 
and   liv.gestione_livello_code ='GEST_SALDO_SOTTO_CONTI_VINC'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null
and   liv.data_cancellazione  is null 
and   liv.validita_fine is null; 

raise notice 'isSaldiAttivi=%',isSaldiAttivi::varchar;
-- se non attivo non si da errore ma non fa nulla sui saldi
if isSaldiAttivi is null then 
	messaggioRisultato:='Elaborazione calcolo saldi sottoconti-vincolati da fase bilancio - fine - gestione non attiva.';
    raise notice 'messaggioRisultato=%',messaggioRisultato::varchar;
	return;
end if;

elabRec:=null;
select * into elabRec
from 
fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  enteproprietarioid,
  annoBilancioIniziale, -- anno in apertura
  annoBilancioFinale,   -- anno in chiusura
  ricalcoloSaldi, 	    -- true
  null,
  tipoAggiornamento,
  loginoperazione,
  dataelaborazione
);

raise notice 'elabRec.codiceRisultato=%',elabRec.codiceRisultato::varchar;
raise notice 'elabRec.messaggioRisultato=%',elabRec.messaggioRisultato::varchar;
strMessaggioFinale:='Elaborazione calcolo saldi sottoconti-vincolati da fase bilancio  - fine.';
if elabRec.codiceRisultato=0 then
    elabId:=elabRec.outElabId;
    messaggioRisultato:=strMessaggioFinale||' ELABORAZIONE OK.';
else
	messaggioRisultato:=strMessaggioFinale||' ELABORAZIONE KO.'|| elabRec.messaggioRisultato;
    codiceRisultato:=elabRec.codiceRisultato;
end if;

outElabId:=	elabId;
raise notice 'codiceRisultato=%',codiceRisultato::varchar;
raise notice 'messaggioRisultato=%',messaggioRisultato::varchar;
raise notice 'outElabId=%',outElabId::varchar;

return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;


        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outElabId:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
(
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER to siac;