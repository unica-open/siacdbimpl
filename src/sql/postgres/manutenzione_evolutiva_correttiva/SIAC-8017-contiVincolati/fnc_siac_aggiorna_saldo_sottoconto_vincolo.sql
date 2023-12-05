/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

DROP FUNCTION if exists siac.fnc_siac_aggiorna_saldo_sottoconto_vincolo
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

CREATE OR REPLACE FUNCTION siac.fnc_siac_aggiorna_saldo_sottoconto_vincolo
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

annoApertura integer:=null;
annoChiusura integer:=null;


-- in apertura saldi sempre calcolati entrambi
RicalcoloSaldi varchar(1):='S';
tipoAggiornamento varchar(1):=null;

issaldiAttivi integer:=null;
codResult integer:=null;

BEGIN
/* 
 * RICALCOLO PER AGGIORNAMENTO SALDI SOTTO CONTI VINCOLATI - SU QUADRATURA CASSA CON TESORIERE
 * I SALDI DEI CONTI SONO RICALCOLATI AUTOMATICAMENTE SU ANNO BILANCIO IN CHIUSURA
 * GLI STESSI SALDI SONO RIPORTATATI COME INIZIALI SU ANNO BILANCIO+1 IN APERTURA
 * LA FNC di CALCOLO VIENE ESEGUITA SOLO SE I PARAMETRI DI SISTEMA AGGIORNA_%_SALDO_SOTTO_CONTI_VINC SI TROVANO  SUL DB
 * ALMENO UNO DEI DUE
 * I SALDI FINALI SONO RICALCOLATI SOLO SI TROVA IL PARAMETRO AGGIORNA_FIN_SALDO_SOTTO_CONTI_VINC SU DB
 * I SALDI INIZIALI SONO RICALCOLATI SOLO SI TROVA IL PARAMETRO AGGIORNA_INIZ_SALDO_SOTTO_CONTI_VINC SU DB
 * I SALDI SONO RICALCOLABILI AUTOMATICAMENTE 
 * SE SONO PRESENTI SALDI VALIDI PRIMA DI ESEGUIRE LA FNC DI RICALCOLO SONO INVALIDATI TUTTI AUTAMATICAMENTE
 * NON RICHIAMABILE DA UNA FNC DI FASE IN QUANTO NON ESISTENTE UNA FASE CHE IDENTIFICA
 * LA QUADRATURA DI CASSA CON TESORIERE
 */
strMessaggioFinale:='Elaborazione aggiornamento saldi sottoconti-vincolati - inizio.';
codiceRisultato:=0;
messaggioRisultato:='';



raise notice '%',strMessaggioFinale;
raise notice 'annoBilancioIniziale=%',annoBilancioIniziale::varchar;
raise notice 'annoBilancioFinale=%',annoBilancioFinale::varchar;


annoApertura:=annoBilancioIniziale;
annoChiusura:=annoBilancioFinale;

strMessaggio:='Verifica configurazione ente per aggiornamento saldi sottoconti-vincolati.';
select 1 into isSaldiAttivi
from siac_d_gestione_livello liv ,siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id =enteProprietarioId 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   liv.gestione_tipo_id =tipo.gestione_tipo_id 
and   liv.gestione_livello_code like 'AGGIORNA_%_SALDO_SOTTO_CONTI_VINC'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null
and   liv.data_cancellazione  is null 
and   liv.validita_fine is null; 

raise notice 'isSaldiAttivi=%',isSaldiAttivi::varchar;

-- se non attiva - no errore ma non viene effettuato nulla
if isSaldiAttivi is null then 
	messaggioRisultato:='Elaborazione aggiornamento saldi sottoconti-vincolati - fine - gestione non attiva.';
	return;
end if;

strMessaggio:='Verifica configurazione ente per aggiornamento saldi sottoconti-vincolati. Saldi iniziali.';
isSaldiAttivi:=null;
select 1 into isSaldiAttivi
from siac_d_gestione_livello liv ,siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id =enteProprietarioId 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   liv.gestione_tipo_id =tipo.gestione_tipo_id 
and   liv.gestione_livello_code ='AGGIORNA_INIZ_SALDO_SOTTO_CONTI_VINC'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null
and   liv.data_cancellazione  is null 
and   liv.validita_fine is null; 
raise notice 'Apertura isSaldiAttivi=%',isSaldiAttivi::varchar;
if isSaldiAttivi is null then 
	annoApertura :=null;
end if;
raise notice 'Apertura annoApertura=%',annoApertura::varchar;

strMessaggio:='Verifica configurazione ente per aggiornamento saldi sottoconti-vincolati. Saldi finali.';
isSaldiAttivi:=null;
select 1 into isSaldiAttivi
from siac_d_gestione_livello liv ,siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id =enteProprietarioId 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   liv.gestione_tipo_id =tipo.gestione_tipo_id 
and   liv.gestione_livello_code ='AGGIORNA_FINAL_SALDO_SOTTO_CONTI_VINC'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null
and   liv.data_cancellazione  is null 
and   liv.validita_fine is null; 
raise notice 'Chiusura isSaldiAttivi=%',isSaldiAttivi::varchar;
if isSaldiAttivi is null then 
	annoChiusura :=null;
end if;
raise notice 'Apertura annoChiusura=%',annoChiusura::varchar;

if annoApertura is not null  then 
	strMessaggio:='Verifica esistenza saldi sottoconti-vincolati iniziali per anno='||annoApertura::varchar||'.';
    codResult:=null;
	select 1 into codResult
	from siac_r_saldo_vincolo_sotto_conto r ,siac_t_periodo per, siac_t_bil bil 
	where bil.ente_proprietario_id=enteProprietarioId 
	and   per.periodo_id=bil.periodo_id 
	and   per.anno::integer=annoApertura
	and   r.bil_id=bil.bil_id
	and   r.data_cancellazione  is null 
	and   r.validita_fine is null;

	if codResult is not null then 
	    strMessaggio:='Invalidazione saldi sottoconti-vincolati iniziali per anno='||annoApertura::varchar||' pre-esistenti.';
		update siac_r_saldo_vincolo_sotto_conto r
		set    data_cancellazione=now(),
		       validita_fine=now(),
		       login_operazione=r.login_operazione||'-AGGIORN-INIZ-' ||loginOperazione
	    from siac_t_periodo per, siac_t_bil bil 
		where bil.ente_proprietario_id=enteProprietarioId 
		and   per.periodo_id=bil.periodo_id 
		and   per.anno::integer=annoApertura
		and   r.bil_id=bil.bil_id
		and   r.data_cancellazione  is null 
		and   r.validita_fine is null;
	end if;
end if;

/*if annoChiusura is not null  then 
	codResult:=null;
	strMessaggio:='Verifica esistenza saldi sottoconti-vincolati finali per anno='||annoChiusura::varchar||'.';
	select 1 into codResult
	from siac_r_saldo_vincolo_sotto_conto r ,siac_t_periodo per, siac_t_bil bil 
	where bil.ente_proprietario_id=enteProprietarioId 
	and   per.periodo_id=bil.periodo_id 
	and   per.anno::integer=annoChiusura
	and   r.bil_id=bil.bil_id
	and   ( coalesce(r.saldo_finale,0) !=0 or coalesce(r.ripiano_finale,0) !=0 )
	and   r.data_cancellazione  is null 
	and   r.validita_fine is null;

	if codResult is not null then 
	    strMessaggio:='Invalidazione saldi sottoconti-vincolati finali per anno='||annoChiusura::varchar||' pre-esistenti.';
		update siac_r_saldo_vincolo_sotto_conto r
		set    data_cancellazione=now(),
		       validita_fine=now(),
		       login_operazione=r.login_operazione ||'-AGGIORN-FINAL-'||loginOperazione
	    from siac_t_periodo per, siac_t_bil bil 
		where bil.ente_proprietario_id=enteProprietarioId 
		and   per.periodo_id=bil.periodo_id 
		and   per.anno::integer=annoChiusura
		and   r.bil_id=bil.bil_id
--	    and   ( coalesce(r.saldo_finale,0) !=0 or coalesce(r.ripiano_finale,0) !=0 )
		and   r.data_cancellazione  is null 
		and   r.validita_fine is null;
	end if;
end if;*/

strMessaggio:='Calcolo tipoAggiornamento saldi sottoconti-vincolati.';
tipoAggiornamento:=( case when annoApertura is not null and annoChiusura is not null then  'E'
						         when annoApertura is not null and annoChiusura is null     then  'I'	
	   						     when annoApertura is null and annoChiusura is not null     then  'F'
	   						     else null
			 		      end );
strMessaggio:='Calcolo tipoAggiornamento saldi sottoconti-vincolati : tipoAggiornamento='||tipoAggiornamento||'.';				    
raise notice 'strMessaggio=%',strMessaggio;
if tipoAggiornamento  is not null then 			
	strMessaggio:='Elaborazione aggiornamento saldi sottoconti-vincolati - avvio fnc_siac_calcolo_saldo_sottoconto_vincolo.';
	raise notice 'strMessaggio=%',strMessaggio;

	elabRec:=null;
	select * into elabRec
	from 
	fnc_siac_calcolo_saldo_sottoconto_vincolo
	(
	  enteproprietarioid,
	  annoApertura, -- anno in apertura
	  annoChiusura,   -- anno in chiusura
	  ricalcoloSaldi, 	    -- true
	  null,
	  tipoAggiornamento,
	  loginoperazione,
	  dataelaborazione,
	  false
	);
	if elabRec.codiceRisultato=0 then
	    elabId:=elabRec.outElabId;
	else
		strMessaggio:=elabRec.messaggioRisultato;
	    codiceRisultato:=elabRec.codiceRisultato;
	end if;
else 
	strMessaggio:='Elaborazione aggiornamento saldi sottoconti-vincolati - fnc_siac_calcolo_saldo_sottoconto_vincolo non avviata.';
	raise notice 'strMessaggio=%',strMessaggio;
end if;
raise notice 'elabId=%',elabId::varchar;

strMessaggioFinale:='Elaborazione aggiornamento saldi sottoconti-vincolati  - fine.';   


outElabId:=elabId;
messaggioRisultato:=strMessaggioFinale;

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


alter function siac.fnc_siac_aggiorna_saldo_sottoconto_vincolo
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