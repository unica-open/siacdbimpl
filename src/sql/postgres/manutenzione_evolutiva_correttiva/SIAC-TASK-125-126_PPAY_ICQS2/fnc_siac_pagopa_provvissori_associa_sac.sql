/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_siac_pagopa_provvissori_associa_sac
(
  enteProprietarioId integer,
  loginOperazione varchar, 
  dataElaborazione timestamp, 
  OUT codiceRisultato integer, 
  OUT messaggioRisultato varchar
);
CREATE OR REPLACE FUNCTION siac.fnc_siac_pagopa_provvissori_associa_sac
(
  enteProprietarioId integer,
  loginOperazione varchar, 
  dataElaborazione timestamp, 
  OUT codiceRisultato integer, 
  OUT messaggioRisultato varchar)
 RETURNS record
 AS $body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioBck  VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
	strMessaggioLog VARCHAR(2500):='';

	codResult integer:=null;

    n_timestamp varchar:=null;
   
    elabRec record;
   elabCodiceRec record;

    annoBilancio integer:=null;
    annoBilancio_ini integer:=null;
    
   ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
   ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
   ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
   ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti   

   
   ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E';
   ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G';
   ESERCIZIO_CONSUNTIVO_ST CONSTANT  varchar :='O';
  
   COD_ASSOCIA_SAC              CONSTANT  varchar :='UC1';
   nomeTabella varchar:='pagopa_t_elabora_provv_associa_sac';
    
BEGIN

	codiceRisultato:=0;
    messaggioRisultato:='';
   
	strMessaggioFinale:='Provvisori di cassa PPAY - associazione SAC.';
    strMessaggioLog:='Inizio fnc_siac_pagopa_provvissori_associa_sac - '||strMessaggioFinale;
    raise notice '%',strMessaggioLog;
   
    SELECT  to_char(current_timestamp, 'YYYYMMDDHH24MISSMS') into n_timestamp;
  


    annoBilancio:=extract('YEAR' from now())::integer;
    annoBilancio_ini:=annoBilancio;
    strMessaggio:='Verifica fase bilancio annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    strMessaggioLog:=strMessaggioLog||strMessaggio;
    select 1 into codResult
    from siac_t_bil bil,siac_t_periodo per,
         siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
    where per.ente_proprietario_id=enteProprietarioid
    and   per.anno::integer=annoBilancio-1
    and   bil.periodo_id=per.periodo_id
    and   r.bil_id=bil.bil_id
    and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_id=r.fase_operativa_id
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
    if codResult is not null then
    	annoBilancio_ini:=annoBilancio-1;
    end if;
   
    strMessaggioLog:='Continua fnc_siac_pagopa_provvissori_associa_sac - '||strMessaggioFinale;
    strMessaggio:='Creazione tabella pagopa_t_elabora_provv_associa_sac.';
    strMessaggioLog:=strMessaggioLog||strMessaggio;
    raise notice '%',strMessaggioLog;
    create temporary table pagopa_t_elabora_provv_associa_sac
    as select distinct ric.pagopa_ric_flusso_anno_provvisorio as provc_anno, ric.pagopa_ric_flusso_num_provvisorio  as provc_numero, COD_ASSOCIA_SAC  as associa_sac_code
    from siac_t_file_pagopa pagopa, siac_d_file_pagopa_stato stato,pagopa_t_riconciliazione  ric
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
    and   pagopa.file_pagopa_stato_id=stato.file_pagopa_stato_id
    and   pagopa.file_pagopa_anno in (annoBilancio_ini,annoBilancio)
    and   ric.file_pagopa_id =pagopa.file_pagopa_id 
    and   ric.pagopa_ric_flusso_stato_elab ='N'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null
    and   pagopa.data_cancellazione is null
    and   pagopa.validita_fine is null;
   
    strMessaggioLog:='Continua fnc_siac_pagopa_provvissori_associa_sac - '||strMessaggioFinale;
    strMessaggio:='Esecuzione fnc_siac_provvisorio_associa_sac.';
    strMessaggioLog:=strMessaggioLog||strMessaggio;
    raise notice '%',strMessaggioLog;

    select * into elabRec
    from fnc_siac_provvisorio_associa_sac
     (
      enteProprietarioId,
      nomeTabella,
      0,
      null,
      loginOperazione, 
      dataElaborazione
     );
    
     if elabRec.codiceRisultato!=0 then
          	  codiceRisultato:=elabRec.codiceRisultato;
              strMessaggio:=elabRec.messaggiorisultato;
    else   strMessaggio:=elabRec.messaggiorisultato;
    end if;
   
   strMessaggioLog:='Fine fnc_siac_pagopa_provvissori_associa_sac - '||strMessaggioFinale;
    if codiceRisultato=0 then
      	messaggioRisultato:=upper(strMessaggioLog||' Provvisori aggiornati '||' TERMINE OK.' ||strMessaggio);
    else
    	messaggioRisultato:=upper(strMessaggioLog||' Provvisori aggiornati '||' TERMINE KO.'||strMessaggio);
    end if;
    raise notice '%',messaggioRisultato;

   
   return;
exception
    when RAISE_EXCEPTION then
        raise notice '%',strMessaggioLog;
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND then
        raise notice '%',strMessaggioLog;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
     when TOO_MANY_ROWS then
        raise notice '%',strMessaggioLog;
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
	when others  then
        raise notice '%',strMessaggioLog;
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

alter function
siac.fnc_siac_pagopa_provvissori_associa_sac
(
  integer,
  varchar,
  timestamp, 
  OUT  integer, 
  OUT  varchar)
 OWNER to siac;