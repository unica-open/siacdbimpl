/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

/*DROP FUNCTION if exists siac.fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer, -- indicare per I, E
  annoBilancioFinale   integer, -- indicare per F,E, per I serve ma se omesso viene ricavato
  ricalcoloSaldi       varchar, -- S,N (opzionale a caricamento da tabella)
  caricaDaTabella      varchar, -- S,N|<nome_tabella> (opzionare a ricalcolo saldi)
  tipoAggiornamento    varchar, -- I-iniziale,F-finale,E-entrambi
  loginoperazione      varchar, 
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
);*/

DROP FUNCTION if exists siac.fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer, -- indicare per I, E
  annoBilancioFinale   integer, -- indicare per F,E, per I serve ma se omesso viene ricavato
  ricalcoloSaldi       varchar, -- S,N (opzionale a caricamento da tabella)
  caricaDaTabella      varchar, -- S,N|<nome_tabella> (opzionare a ricalcolo saldi)
  tipoAggiornamento    varchar, -- I-iniziale,F-finale,E-entrambi
  checkFinale          boolean,
  loginoperazione      varchar, 
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
);


CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  --  i due anni di bilancio devono essere sempre consecutivi
  annoBilancioIniziale integer, -- indicare per I, E
  annoBilancioFinale   integer, -- indicare per F,E, per I serve ma se omesso viene ricavato
  ricalcoloSaldi       varchar, -- S,N (opzionale a caricamento da tabella)
  caricaDaTabella      varchar, -- S,N|<nome_tabella> (opzionare a ricalcolo saldi)
  tipoAggiornamento    varchar, -- I-iniziale,F-finale,E-entrambi
  loginoperazione      varchar,
  dataelaborazione     timestamp,
  checkFinale          boolean default true,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
)
RETURNS record
 AS $body$
DECLARE

-- parametri di input  : ente_proprietario, anno_finale, anno_iniziale, ricalcolo (true,false),
--                       tipo_aggiornamento ( iniziale, finale, entrambi)
--  i due anni di bilancio devono essere sempre consecutivi
--  annoBilancioIniziale integer, -- indicare per I, E
--  annoBilancioFinale   integer, -- indicare per F,E, per I serve ma se omesso viene ricavato
--  ricalcoloSaldi       varchar, -- S,N (opzionale a caricamento da tabella)
--  caricaDaTabella      varchar, -- S,N|<nome_tabella> (opzionare a ricalcolo saldi)
--  tipoAggiornamento    varchar, -- I-iniziale,F-finale,E-entrambi
--  NOTE. 
--  I saldi non possono essere mai ricalcolati, quindi se esistono saldi validi sia iniziali che validi 
--  devono essere prima invalidati manualmente, diversamente la fnc restituisce errore
--  solo se eseguita da fnc di approviazione del bil.prev sono effettuate invalidazioni automatiche
--  Caricamente da Tabella : sono caricati i saldi sia iniziali che finali 
--  in questo caso vengono caricati i saldi così come presenti in tabella 
--  i saldi devono essere positivi, i valori di ripiano devono essere negativi
--  Devono essere caricati valori distinti in tabella per i saldi iniziali e per quelli finali 

strMessaggio VARCHAR(2500):=''; 
strMessaggioBck  VARCHAR(2500):=''; 
strMessaggioFinale VARCHAR(1500):='';
strErrore VARCHAR(1500):='';
strMessaggioLog VARCHAR(2500):='';

codResult integer:=null;
annoBilancio integer:=null;
annoBilancioIni integer:=null;
annoBilancioFin integer:=null;

elabId integer:=null;

elabRec record;
elabResRec record;
   

sql_insert varchar(5000):=null;
flagRicalcoloSaldi boolean:=false;
flagCaricaDaTabella boolean:=false;
nomeTabella varchar(250):=null;

bilFinaleId integer:=null;
bilInizialeId integer:=null;

faseOp varchar(50):=null;


NVL_STR CONSTANT             varchar :='';
BIL_GESTIONE_STR CONSTANT    varchar :='G';
BIL_PROVVISORIO_STR CONSTANT varchar :='E';
BIL_CONSUNTIVO_STR CONSTANT  varchar :='O';


BEGIN

strMessaggioFinale:='Elaborazione calcolo saldi sottoconti-vincolati - inizio.';

raise notice '%',strMessaggioFinale;
raise notice 'tipoAggiornamento=%',tipoAggiornamento;
raise notice 'annoBilancioIniziale=%',annoBilancioIniziale::varchar;
raise notice 'annoBilancioFinale=%',annoBilancioFinale::varchar;
raise notice 'ricalcoloSaldi=%',ricalcoloSaldi;
raise notice 'caricaDaTabella=%',caricaDaTabella;

outElabId:=null;
codiceRisultato:=0;
messaggioRisultato:='';

strMessaggio:='Verifica valore parametro tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR)=NVL_STR or 
   coalesce(tipoAggiornamento,NVL_STR) not in ('I','F','E') then
   raise exception 'Valore obbligatorio [I,F,E].';
end if;

strMessaggio:='Verifica valore parametro annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR)='I' and coalesce(annoBilancioIniziale,'0')='0' then 
	   raise exception 'Valore obbligatorio.';
end if;

strMessaggio:='Verifica valore parametro annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR)='F' and coalesce(annoBilancioFinale,'0')='0' then 
	   raise exception 'Valore obbligatorio.';
end if;

if coalesce(tipoAggiornamento,NVL_STR)in ( 'I','E') then -- per iniziale devo sempre avere dati finale, quindi se non impostano annoFinale devo ricavarlo da Iniziale
	strMessaggio:='Verifica valore parametro annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')
		           ||'annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
	               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
	if  coalesce(annoBilancioIniziale,'0')='0' and coalesce(annoBilancioFinale,'0')='0' then 
		   raise exception 'Valore obbligatorio almeno dei due anni deve essere indicato.';
	end if;
    if  coalesce(annoBilancioIniziale,'0')='0' then
       annoBilancioIniziale:=annoBilancioFinale+1;
    end if;
    if  coalesce(annoBilancioFinale,'0')='0' then
       annoBilancioFinale:=annoBilancioIniziale-1;
    end if;
    raise notice 'annoBilancioIniziale=%',annoBilancioIniziale::varchar;
    raise notice 'annoBilancioFinale=%',annoBilancioFinale::varchar;
end if;

strMessaggio:='Verifica congruenza valori parametro annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')
		           ||'annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
	               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(annoBilancioIniziale,'0')!='0' and
   coalesce(annoBilancioFinale,'0')!='0' and
   annoBilancioIniziale!=annoBilancioFinale+1 then 
   raise exception 'Anni non consecutivi.';
end if;
   

	              
strMessaggio:='Verifica valore parametro caricaDaTabella='||coalesce(caricaDaTabella,'N')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(caricaDaTabella,NVL_STR)!=NVL_STR then
    flagCaricaDaTabella:=(case when coalesce(split_part(caricaDaTabella,'|',1),'N')='S' then true else false end);
    if flagCaricaDaTabella=true then
    	nomeTabella:=split_part(caricaDaTabella,'|',2);
    	if coalesce(nomeTabella,NVL_STR)=NVL_STR then
    		raise exception 'Valore nomeTabella non impostato';
    	else 
          raise notice '@@@@ VERIFICARE ESISTENZA TABELLA @@@@@@';
          
          codResult:=null;
          select 1 into codResult
	      from pg_tables
	      where tablename=nomeTabella;
	      
	      if not FOUND or codResult is null then 
	      	raise exception ' Tabella=% non esistente',nomeTabella;
	      end if;
	      codResult:=null;
    	end if;
    end if;
end if;

 
flagRicalcoloSaldi:=(case when coalesce(ricalcoloSaldi,'N')='S' then true else false end);

raise notice 'flagRicalcoloSaldi=%',(case when flagRicalcoloSaldi=true then 'S' else 'N' end);
raise notice 'flagCaricaDaTabella=%',(case when flagCaricaDaTabella=true then 'S' else 'N' end);


strMessaggio:='Verifica valori parametri ricalcoloSaldi='||coalesce(ricalcoloSaldi,'N')
             ||' per caricaDaTabella='||coalesce(split_part(caricaDaTabella,'|',1),'N')
             ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if flagCaricaDaTabella=true and flagRicalcoloSaldi=true then 
	   raise exception 'Opzione ricalcolo saldi e caricamento da tabella esclusivi.';
end if;


 

-- controllo stati anni di bilancio
-- finale deve essere in gestione o predisposizione consuntivo
strMessaggio:='Calcolo bilancioId e verifica faseOP per valore parametro annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR) in ('F','E','I') then  -- per calcolare iniziale devo avere i dati del finale
	-- caricamento dati tabella applicativa in annoBilancioFinale
    select bil.bil_id into bilFinaleId
    from siac_t_bil bil,siac_t_periodo per 
    where bil.ente_proprietario_id=enteProprietarioId 
    and   per.periodo_id=bil.periodo_id 
    and   per.anno::integer=annoBilancioFinale;
    if bilFinaleId is null then
    	raise exception 'Identificativo bilancioId non reperito';
    end if;
   
    select fase.fase_operativa_code into faseOp
    from siac_r_bil_fase_operativa r,siac_d_fase_operativa fase 
    where r.bil_id=bilFinaleId
    and   fase.fase_operativa_id=r.fase_operativa_id
    and   r.data_cancellazione is null 
    and   r.validita_fine is null;
    if coalesce(faseOp,NVL_STR) not in (BIL_GESTIONE_STR,BIL_CONSUNTIVO_STR) then
--  	   	raise exception 'Fase operativa non reperita o non ammessa [%-%]', BIL_GESTIONE_STR,BIL_CONSUNTIVO_STR;
    raise notice 'Fase operativa non reperita o non ammessa [%-%]', BIL_GESTIONE_STR,BIL_CONSUNTIVO_STR;
    end if;
end if;

-- inziale deve essere in provvisorio o gestione
strMessaggio:='Calcolo bilancioId e verifica faseOP per valore parametro annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then 
	-- caricamento dati tabella applicativa in annoBilancioFinale
    select bil.bil_id into bilInizialeId
    from siac_t_bil bil,siac_t_periodo per 
    where bil.ente_proprietario_id=enteProprietarioId 
    and   per.periodo_id=bil.periodo_id 
    and   per.anno::integer=annoBilancioIniziale;
    if bilInizialeId is null then
    	raise exception 'Identificativo bilancioId non reperito';
    end if;
   
    faseOp:=null;
    select fase.fase_operativa_code into faseOp
    from siac_r_bil_fase_operativa r,siac_d_fase_operativa fase 
    where r.bil_id=bilInizialeId
    and   fase.fase_operativa_id=r.fase_operativa_id
    and   r.data_cancellazione is null 
    and   r.validita_fine is null;
    if coalesce(faseOp,NVL_STR) not in (BIL_GESTIONE_STR,BIL_PROVVISORIO_STR) then
--    		raise exception 'Fase operativa non reperita o non ammessa [%-%]',BIL_PROVVISORIO_STR,BIL_GESTIONE_STR;
     raise notice 'Fase operativa non reperita o non ammessa [%-%]',BIL_PROVVISORIO_STR,BIL_GESTIONE_STR;    	
    end if;
end if;


if coalesce(tipoAggiornamento,NVL_STR) in ('E','I') then 
    strMessaggio:='Verifica esistenza saldi per  annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
    codResult:=null;
	select 1 into codResult
	from siac_r_saldo_vincolo_sotto_conto r 
	where r.ente_proprietario_id=enteProprietarioId 
	and   r.bil_id=bilInizialeId
	and   r.data_cancellazione is null 
	and   r.validita_fine is null;
    if coalesce(codResult,0)!=0  then
    	raise exception ' Saldi gia'' caricati - elaborazione non rieseguibile previa cancellazione.';
    end if;
    
end if;

if coalesce(tipoAggiornamento,NVL_STR) in ('E','F') and checkFinale=true then 
    strMessaggio:='Verifica esistenza  saldi finali per annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
    codResult:=null;
	select 1 into codResult
	from siac_r_saldo_vincolo_sotto_conto r 
	where r.ente_proprietario_id=enteProprietarioId 
	and   r.bil_id=bilFinaleId
	and   ( coalesce(r.saldo_finale,0) !=0 or coalesce(r.ripiano_finale,0) !=0)
	and   r.data_cancellazione is null 
	and   r.validita_fine is null;
    if coalesce(codResult,0)!=0  then
    	raise exception ' Saldi gia'' caricati - elaborazione non rieseguibile previa cancellazione.';
    end if;
    
end if;


-- calcolo elab_id
strMessaggio:='Calcolo elabId per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
elabId:=null;
select max(elab.saldo_vincolo_conto_elab_id) into elabId
from siac_t_saldo_vincolo_sotto_conto_elab elab 
where elab.ente_proprietario_id=enteProprietarioId;
if elabId is null or elabId=0 then elabId:=1; 
else    elabId:=elabId+1;
end if;
raise notice 'elabId=%',elabId::varchar;

--- ricalcolo saldi
if elabId is not null and flagRicalcoloSaldi=true  then 
	-- esecuzione ricalcolo saldi su tabella temporanea di elaborazione
   raise notice '*** CALCOLO SALDI DA ORDINATIVI ***';
   if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then
   	annoBilancio:=annoBilancioIniziale-1;
   else 
    if coalesce(tipoAggiornamento,NVL_STR) ='F' then
   	 annoBilancio:=annoBilancioFinale;
    end if;	
   end if;
  
  if coalesce(tipoAggiornamento,NVL_STR) in ('F','E') then 
    raise notice '*** CARICAMENTO FINALI siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incassi per anno=% elabId=%',annoBilancio::varchar,elabId::varchar;
    strMessaggio:='Inserimento saldi FINALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incass per anno='||annoBilancio::varchar||' per elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
    insert into siac_t_saldo_vincolo_sotto_conto_elab  
    ( 
      vincolo_id,	
      contotes_id,
      saldo_iniziale,	
      saldo_finale,
      ripiano_iniziale,
      ripiano_finale,
	  bil_id,
	  tipo_caricamento, 
	  saldo_vincolo_conto_elab_id ,
      validita_inizio,
      login_operazione, 
      ente_proprietario_id 
    )
    select fnc_saldi.vincolo_id,
           fnc_saldi.contotes_disp_id,
           0,
           fnc_saldi.saldo_vincolo_conto,
           0,
           fnc_saldi.ripiano_vincolo_conto,
           bilFinaleId,
          'O',
           elabId,
           clock_timestamp(),
          loginOperazione,
          enteProprietarioId
   from fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno(enteProprietarioId,annoBilancio) fnc_saldi;
    
   codResult:=null;
   select count(*) into codResult
   from siac_t_saldo_vincolo_sotto_conto_elab elab 
   where elab.saldo_vincolo_conto_elab_id=elabId 
   and   elab.bil_id=bilFinaleId
   and   elab.data_cancellazione is null 
   and   elab.validita_fine is null;
   raise notice '*** INSERITI NUMERO REC=%',coalesce(codResult::varchar,'0');
   codResult:=null;
  end if;
  
  if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then
    raise notice '*** CARICAMENTO INIZIALI siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incassi per anno=% elabId=%',annoBilancio::varchar,elabId::varchar;
    strMessaggio:='Inserimento saldi INIZIALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incassi per anno='||annoBilancio::varchar||' per elabId='||elabId::varchar
               ||' annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
              
    insert into siac_t_saldo_vincolo_sotto_conto_elab  
    ( 
      vincolo_id,	
      contotes_id,
      saldo_iniziale,	
      saldo_finale,
      ripiano_iniziale,	
      ripiano_finale,
	  bil_id,
	  tipo_caricamento, 
	  saldo_vincolo_conto_elab_id ,
      validita_inizio,
      login_operazione, 
      ente_proprietario_id 
    )
    select       
      saldi_vincoli_conti.vincolo_id,
      saldi_vincoli_conti.contotes_disp_id,
      saldi_vincoli_conti.saldo,
      0,
      saldi_vincoli_conti.ripiano,
      0,
      bilInizialeId,
      'O',
      elabId,
      clock_timestamp(),
      loginOperazione,
      enteProprietarioId
    from   
    (
    with 
    vincoli_iniziali as
    (
    select vinc.vincolo_code,
           vinc.vincolo_id
    from siac_t_vincolo vinc, siac_d_vincolo_tipo tipo,
         siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,
         siac_t_periodo per 
    where tipo.ente_proprietario_id=enteProprietarioId 
    and   tipo.vincolo_tipo_code='G'
    and   vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
    and   rs.vincolo_id=vinc.vincolo_id 
    and   stato.vincolo_stato_id=rs.vincolo_stato_id 
    and   stato.vincolo_stato_code!='A'
    and   per.periodo_id=vinc.periodo_id 
    and   per.anno::integer=annoBilancioIniziale
    and   vinc.data_cancellazione is null 
    and   vinc.validita_fine is null 
    and   rs.data_cancellazione is null 
    and   rs.validita_fine is null
    ),
    vincoli_finali as
    (
     select 
      vinc.vincolo_code,
      fnc_saldi.vincolo_id,
      fnc_saldi.contotes_disp_id,
      fnc_saldi.saldo_vincolo_conto+coalesce(r.saldo_iniziale,0) saldo,
      fnc_saldi.ripiano_vincolo_conto+coalesce(r.ripiano_iniziale,0) ripiano
    from  
    (
      select fnc_saldi.*
      from fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno(enteProprietarioId,annoBilancio) fnc_saldi
    ) fnc_saldi left join siac_r_saldo_vincolo_sotto_conto r on 
      (     r.bil_id=bilFinaleId 
       and  r.vincolo_id=fnc_saldi.vincolo_id  
       and  r.contotes_id=fnc_saldi.contotes_disp_id 
       and  r.data_cancellazione is null
       and  r.validita_fine is null 
      ),siac_t_vincolo vinc
    where vinc.vincolo_id=fnc_saldi.vincolo_id
   )
   select vincoli_iniziali.vincolo_id,
	      vincoli_finali.contotes_disp_id,
	      vincoli_finali.saldo,
	      vincoli_finali.ripiano
   from   vincoli_finali , vincoli_iniziali 
   where vincoli_finali.vincolo_code=vincoli_iniziali.vincolo_code 
   ) saldi_vincoli_conti;
   
  strMessaggio:='Inserimento saldi INIZIALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incassi per anno='||annoBilancio::varchar||' per elabId='||elabId::varchar
               ||' annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'. Saldi senza movimenti in anno='||annoBilancio::varchar||'.';
    
   insert into siac_t_saldo_vincolo_sotto_conto_elab  
    ( 
      vincolo_id,	
      contotes_id,
      saldo_iniziale,	
      saldo_finale,
      ripiano_iniziale,	
      ripiano_finale,
	  bil_id,
	  tipo_caricamento, 
	  saldo_vincolo_conto_elab_id ,
      validita_inizio,
      login_operazione, 
      ente_proprietario_id 
    )
    select       
      saldi_vincoli_conti.vincolo_id,
      saldi_vincoli_conti.contotes_id,
      saldi_vincoli_conti.saldo,
      0,
      saldi_vincoli_conti.ripiano,
      0,
      bilInizialeId,
      'O',
      elabId,
      clock_timestamp(),
      loginOperazione,
      enteProprietarioId
    from   
    (
    with 
    vincoli_iniziali as
    (
    select vinc.vincolo_code,
           vinc.vincolo_id
    from siac_t_vincolo vinc, siac_d_vincolo_tipo tipo,
         siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,
         siac_t_periodo per 
    where tipo.ente_proprietario_id=enteProprietarioId 
    and   tipo.vincolo_tipo_code='G'
    and   vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
    and   rs.vincolo_id=vinc.vincolo_id 
    and   stato.vincolo_stato_id=rs.vincolo_stato_id 
    and   stato.vincolo_stato_code!='A'
    and   per.periodo_id=vinc.periodo_id 
    and   per.anno::integer=annoBilancioIniziale
    and   vinc.data_cancellazione is null 
    and   vinc.validita_fine is null 
    and   rs.data_cancellazione is null 
    and   rs.validita_fine is null
    ),
    vincoli_finali as
    (
     select 
      vinc.vincolo_code,
      r.vincolo_id,
      r.contotes_id,
      coalesce(r.saldo_iniziale,0) saldo,
      coalesce(r.ripiano_iniziale,0) ripiano
    from  siac_r_saldo_vincolo_sotto_conto r ,siac_t_vincolo vinc
    where   r.bil_id=bilFinaleId 
   -- and     coalesce(r.saldo_finale,0)=0
    and     vinc.vincolo_id=r.vincolo_id
    and     r.data_cancellazione is null
    and     r.validita_fine is null 
   )
   select vincoli_iniziali.vincolo_id,
	      vincoli_finali.contotes_id,
	      vincoli_finali.saldo,
	      vincoli_finali.ripiano
   from   vincoli_finali , vincoli_iniziali 
   where vincoli_finali.vincolo_code=vincoli_iniziali.vincolo_code 
   and   not exists 
   (
    select 1
    from siac_t_saldo_vincolo_sotto_conto_elab elab 
    where elab.bil_id=bilInizialeId
    and   elab.saldo_vincolo_conto_elab_id=elabId
    and   elab.vincolo_id=vincoli_iniziali.vincolo_id 
    and   elab.contotes_id=vincoli_finali.contotes_id
   )
   ) saldi_vincoli_conti;
  
    codResult:=null;
    select count(*) into codResult
    from siac_t_saldo_vincolo_sotto_conto_elab elab 
    where elab.saldo_vincolo_conto_elab_id=elabId 
    and   elab.bil_id=bilInizialeId
    and   elab.data_cancellazione is null 
    and   elab.validita_fine is null;
    raise notice '*** INSERITI NUMERO REC=%',coalesce(codResult::varchar,'0');          
    codResult:=null;
 end if;

end if;

-- lettura dati da tabella
if elabId is not null and flagCaricaDaTabella=true then
 
  raise notice '*** LETTURA DATI TABELLA ***';
 
  if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then
    raise notice '*** CARICAMENTO INIZIALI siac_t_saldo_vincolo_sotto_conto_elab DA % per anno=% elabId=%',nomeTabella,annoBilancioIniziale::varchar,elabId::varchar;
    strMessaggio:='Inserimento saldi INIZIALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da '||nomeTabella||' per elabId='||elabId::varchar
               ||' annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
 
    -- siac_t_saldo_vincolo_sotto_conto_da_file
  	sql_insert:='insert into siac_t_saldo_vincolo_sotto_conto_elab  
                 ( vincolo_id,	contotes_id,
                   saldo_iniziale,	saldo_finale,ripiano_iniziale,	ripiano_finale,
				   bil_id,tipo_caricamento, saldo_vincolo_conto_elab_id ,
                   validita_inizio,login_operazione, ente_proprietario_id )
	             select vinc.vincolo_id, conto.contotes_id, da_file.saldo_iniziale,0,da_file.ripiano_iniziale,0, '
  	          ||'       '||bilInizialeId::varchar||', ''F'','||elabId::varchar||', '
  	          ||'       clock_timestamp(),'''||loginOperazione||''','||enteProprietarioId::varchar||' '
              ||'from '||nomeTabella||' da_file ,
                      siac_t_vincolo vinc,siac_r_vincolo_stato rs,siac_d_vincolo_stato stato, siac_d_vincolo_tipo tipo_vinc,'
              ||'     siac_t_periodo per,siac_d_periodo_tipo tipo , siac_d_contotesoreria conto '
              ||'   where da_file.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and da_file.anno_bilancio_iniziale='||annoBilancioIniziale::varchar
              ||' and da_file.fl_caricato=''N'' ' 
              ||' and vinc.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and vinc.vincolo_code=da_file.vincolo_code and per.periodo_id=vinc.periodo_id '
              ||' and per.anno::integer='||annoBilancioIniziale::varchar
              ||' and tipo.periodo_tipo_id=per.periodo_tipo_id and tipo.periodo_tipo_code=''SY'' '
              ||' and rs.vincolo_id=vinc.vincolo_id and stato.vincolo_stato_id=rs.vincolo_stato_id '
              ||' and stato.vincolo_stato_code!=''A'' '
              ||' and tipo_vinc.vincolo_tipo_id=vinc.vincolo_tipo_id and tipo_vinc.vincolo_tipo_code=''G'' '
              ||' and conto.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and conto.contotes_code=da_file.conto_code '
              ||' and vinc.data_cancellazione is null and vinc.validita_fine is null '
              ||' and conto.data_cancellazione is null and conto.validita_fine is null'
              ||' and rs.data_cancellazione is null and rs.validita_fine is null;';
              
    raise notice 'sql_insert=%', sql_insert;         
    execute sql_insert;
   
    codResult:=null;
    select count(*) into codResult
    from siac_t_saldo_vincolo_sotto_conto_elab elab 
    where elab.saldo_vincolo_conto_elab_id=elabId 
    and   elab.bil_id=bilInizialeId
    and   elab.data_cancellazione is null 
    and   elab.validita_fine is null;
    raise notice '*** INSERITI NUMERO REC=%',coalesce(codResult::varchar,'0');
    codResult:=null;
   
  end if;
  
  if coalesce(tipoAggiornamento,NVL_STR) in ('F','E') then
    raise notice '*** CARICAMENTO FINALI siac_t_saldo_vincolo_sotto_conto_elab DA % per anno=% elabId=%',nomeTabella,annoBilancioFinale::varchar,elabId::varchar;
    strMessaggio:='Inserimento saldi FINALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da '||nomeTabella||' per elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
 
    -- siac_t_saldo_vincolo_sotto_conto_da_file
  	sql_insert:='insert into siac_t_saldo_vincolo_sotto_conto_elab  
                 ( vincolo_id,	contotes_id,saldo_iniziale,	saldo_finale,ripiano_iniziale,	ripiano_finale,
				   bil_id,tipo_caricamento, saldo_vincolo_conto_elab_id ,
                   validita_inizio,login_operazione, ente_proprietario_id )
	             select vinc.vincolo_id, conto.contotes_id, 0,da_file.saldo_finale,0,da_file.ripiano_finale,'
  	          ||'       '||bilFinaleId::varchar||', ''F'','||elabId::varchar||', '
  	          ||'       clock_timestamp(),'''||loginOperazione||''','||enteProprietarioId::varchar||' '
              ||'from '||nomeTabella||' da_file ,
                      siac_t_vincolo vinc,siac_r_vincolo_stato rs,siac_d_vincolo_stato stato, siac_d_vincolo_tipo tipo_vinc,'
              ||'     siac_t_periodo per,siac_d_periodo_tipo tipo , siac_d_contotesoreria conto '
              ||'   where da_file.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and da_file.anno_bilancio_finale='||annoBilancioFinale::varchar
              ||' and da_file.fl_caricato=''N'' '              
              ||' and vinc.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and vinc.vincolo_code=da_file.vincolo_code and per.periodo_id=vinc.periodo_id '
              ||' and per.anno::integer='||annoBilancioFinale::varchar
              ||' and tipo.periodo_tipo_id=per.periodo_tipo_id and tipo.periodo_tipo_code=''SY'' '
              ||' and rs.vincolo_id=vinc.vincolo_id and stato.vincolo_stato_id=rs.vincolo_stato_id '
              ||' and stato.vincolo_stato_code!=''A'' '
              ||' and tipo_vinc.vincolo_tipo_id=vinc.vincolo_tipo_id and tipo_vinc.vincolo_tipo_code=''G'' '
              ||' and conto.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and conto.contotes_code=da_file.conto_code '
              ||' and vinc.data_cancellazione is null and vinc.validita_fine is null '
              ||' and conto.data_cancellazione is null and conto.validita_fine is null '
              ||' and rs.data_cancellazione is null and rs.validita_fine is null;';
              
    raise notice 'sql_insert=%', sql_insert;         
    execute sql_insert;
   
    codResult:=null;
    select count(*) into codResult
    from siac_t_saldo_vincolo_sotto_conto_elab elab 
    where elab.saldo_vincolo_conto_elab_id=elabId 
    and   elab.bil_id=bilFinaleId
    and   elab.data_cancellazione is null 
    and   elab.validita_fine is null;
    raise notice '*** INSERITI NUMERO REC=%',coalesce(codResult::varchar,'0');
   codResult:=null;
  end if;
end if;
 

-- ribaltamento dati da tabella di elaborazioni in tabella applicativa
if elabId is not null and codResult is null then 
 if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then
  strMessaggio:='Inserimento saldi INIZIALI in siac_r_saldo_vincolo_sotto_conto vincolo sotto-conto elabId='||elabId::varchar
               ||' annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
  raise notice '*** CARICAMENTO INIZIALI in siac_r_saldo_vincolo_sotto_conto per anno=% elabId=%',annoBilancioIniziale::varchar,elabId::varchar;
  insert into siac_r_saldo_vincolo_sotto_conto
  (
    vincolo_id,
	contotes_id,
	saldo_iniziale,
	saldo_finale,
	ripiano_iniziale,
	ripiano_finale,
	bil_id,
	validita_inizio,
	login_operazione,
	ente_proprietario_id
  )
  select 
    elab.vincolo_id,
	elab.contotes_id,
	elab.saldo_iniziale,
	0,
	elab.ripiano_iniziale,
	0,
	elab.bil_id,
	clock_timestamp(),
	loginOperazione||'@ELAB-'||elabId::varchar,
	elab.ente_proprietario_id
  from  siac_t_saldo_vincolo_sotto_conto_elab elab 
  where elab.saldo_vincolo_conto_elab_id=elabId
  and   elab.bil_id=bilInizialeId
  and   elab.data_cancellazione is null 
  and   elab.validita_fine is null;
 

 
  codResult:=null;
  select count(*) into codResult 
  from  siac_r_saldo_vincolo_sotto_conto r 
  where  r.ente_proprietario_id=enteProprietarioId 
  and    r.bil_id=bilInizialeId
  and    r.login_operazione=loginOperazione||'@ELAB-'||elabId::varchar
  and    r.data_cancellazione is null
  and    r.validita_fine is null;
  if codResult is null then codResult:=0; end if;
 
  raise notice '*** RECORD INSERITI=%',coalesce(codResult::varchar,'0');

 end if;
 
 if coalesce(tipoAggiornamento,NVL_STR) in ('F','E') then
  raise notice '*** CARICAMENTO FINALI in siac_r_saldo_vincolo_sotto_conto per anno=% elabId=%',annoBilancioFinale::varchar,elabId::varchar;

  strMessaggio:='Inserimento saldi FINALI in siac_r_saldo_vincolo_sotto_conto vincolo sotto-conto elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0') 
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
  insert into siac_r_saldo_vincolo_sotto_conto
  (
    vincolo_id,
	contotes_id,
	saldo_iniziale,
	saldo_finale,
	ripiano_iniziale,
	ripiano_finale,
	bil_id,
	validita_inizio,
	login_operazione,
	ente_proprietario_id
  )
  select 
    elab.vincolo_id,
	elab.contotes_id,
	coalesce(r_iniziale.saldo_iniziale,0),
--	elab.saldo_finale,
	(case when flagRicalcoloSaldi=true then coalesce(r_iniziale.saldo_iniziale,0)+elab.saldo_finale 
	      else elab.saldo_finale end ),
    coalesce(r_iniziale.ripiano_iniziale,0),      
	(case when flagRicalcoloSaldi=true then coalesce(r_iniziale.ripiano_iniziale,0)+elab.ripiano_finale 
	      else elab.ripiano_finale end ),
	elab.bil_id,
	clock_timestamp(),
	loginOperazione||'@ELAB-'||elabId::varchar,
	elab.ente_proprietario_id
  from  siac_t_saldo_vincolo_sotto_conto_elab elab  
          left join siac_r_saldo_vincolo_sotto_conto r_iniziale 
           on (r_iniziale.bil_id=bilFinaleId 
           and r_iniziale.vincolo_id=elab.vincolo_id 
           and r_iniziale.contotes_id=elab.contotes_id
           and r_iniziale.data_cancellazione is null 
           and r_iniziale.validita_fine is null )
  where elab.saldo_vincolo_conto_elab_id=elabId
  and   elab.bil_id=bilFinaleId
  and   elab.data_cancellazione is null 
  and   elab.validita_fine is null;
 
  if  flagRicalcoloSaldi=true then 
   strMessaggio:='Inserimento saldi FINALI in siac_r_saldo_vincolo_sotto_conto vincolo sotto-conto elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0') 
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'. Inserimento finali senza movimenti in anno.';
   insert into siac_r_saldo_vincolo_sotto_conto
   (
    vincolo_id,
	contotes_id,
	saldo_iniziale,
	saldo_finale,
	ripiano_iniziale,
	ripiano_finale,
	bil_id,
	validita_inizio,
	login_operazione,
	ente_proprietario_id
   )
   select r_iniziale.vincolo_id,
          r_iniziale.contotes_id,
          r_iniziale.saldo_iniziale,
          r_iniziale.saldo_iniziale,
          r_iniziale.ripiano_iniziale,
          r_iniziale.ripiano_iniziale,
          r_iniziale.bil_id,
          clock_timestamp(),
          loginOperazione||'@ELAB-'||elabId::varchar,
          r_iniziale.ente_proprietario_id
   from siac_r_saldo_vincolo_sotto_conto r_iniziale 
   where r_iniziale.bil_id=bilFinaleId
   and   r_iniziale.login_operazione!=loginOperazione||'@ELAB-'||elabId::varchar
  -- and   coalesce(r_iniziale.saldo_finale,0)=0
   and   not exists 
   (
   select 1 
   from  siac_r_saldo_vincolo_sotto_conto r1 
   where r1.bil_id=bilFinaleId
   and   r1.vincolo_id=r_iniziale.vincolo_id 
   and   r1.contotes_id=r_iniziale.contotes_id
   and   r1.login_operazione=loginOperazione||'@ELAB-'||elabId::varchar
   and   r1.data_cancellazione is null 
   and   r1.validita_fine is null 
   )
   and   r_iniziale.data_cancellazione is null
   and   r_iniziale.validita_fine is null;
  end if;
 
  strMessaggio:='Inserimento saldi FINALI in siac_r_saldo_vincolo_sotto_conto vincolo sotto-conto elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0') 
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'. Chiusura inziali esistenti.';
  update siac_r_saldo_vincolo_sotto_conto r 
  set    data_cancellazione=now(),
         validita_fine=now(),
         login_operazione=r.login_operazione||'-'||loginOperazione||'@ELAB-'||elabId::varchar
  where r.ente_proprietario_id=enteProprietarioId
  and   r.bil_id=bilFinaleId
  and   r.login_operazione!=loginOperazione||'@ELAB-'||elabId::varchar
  and   r.data_cancellazione is null
  and   r.validita_fine is null;

  codResult:=null;
  select count(*) into codResult 
  from  siac_r_saldo_vincolo_sotto_conto r 
  where  r.ente_proprietario_id=enteProprietarioId 
  and    r.bil_id=bilFinaleId
  and    r.login_operazione=loginOperazione||'@ELAB-'||elabId::varchar
  and    r.data_cancellazione is null
  and    r.validita_fine is null;
  if codResult is null then codResult:=0; end if;
 
  raise notice '*** RECORD INSERITI=%',coalesce(codResult::varchar,'0');

 end if; 
end if;


strMessaggioFinale:='Elaborazione calcolo saldi sottoconti-vincolati - fine. ELABORAZIONE OK.';   
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


alter function siac.fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  integer,
  integer,
  integer,
  varchar,
  varchar,
  varchar,
  varchar,
  timestamp,
  boolean,  
  out integer,
  out integer,
  out varchar
) OWNER to siac;