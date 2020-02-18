/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 08.06.2017 Sofia - predocumenti
-- definisci predocumenti
-- (A) impegno ( parametro di input ) o (B) anno,numero elenco
-- (A) annoImpegno,numeroImpegno,numeroSubimpegno : estremi dell'impegno con cui ricercare i dati e con cui creare i  doc.
-- se passato impegno
-- per ogni predoc completo associato all'impegno creare il documento, associarlo all'impegno, associare stato completo
-- passare il predoc da C a D
-- creare un elenco e associarlo a tutti i documenti creati

-- (B) annoElenco,numeroElenco : estremi dell'elenco  con cui ricercare i dati con cui creare i doc.
-- se passato elenco
-- per ogni predoc completo associato all'elenco creare il documento, associarlo all'elenco, associare stato VALIDO
-- passare il predoc da C a D

-- (A) (B) sono alternativi,ma uno dei deve essere indicato
-- (A) facoltativo , deve essere esistente ed essere usato per ricercare i dati da definire
--     usato per definire i dati
-- (B) facoltativo, se indicato deve esistere ed essere usato per ricercare i dati

-- se (B) non e'' passato e'' creato e i predoc sono ricercati sempre per elenco
-- in questo modo la ricerca e' sempre fatta per elenco
-- al termine dell'elaborazione le relazioni tra elenco e predoc in questo caso sono cancellate


--  domande.
-- fare controllo disp ??
-- controllare che abbiano tutti soggetto e MDP (controllato in caso scartato predoc)
-- controllare che abbiano tutti l'impegno (controllato in caso scartato predoc)

CREATE OR REPLACE FUNCTION fnc_siac_predoc_spesa_definisci
 (
  annoImpegno            integer,
  numeroImpegno          integer,
  numeroSubimpegno       integer,
  annoElenco             integer,
  numeroElenco           integer,
  enteproprietarioid     integer,
  annobilancio           integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioIni VARCHAR(1500):='';
	strMessaggioScarto VARCHAR(1500):='';

	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	currTimeStamp     varchar(50):=null;

	bilancioId		  integer:=null;
    movgestId         integer:=null;
    movgestTsId       integer:=null;

    eldocId           integer:=null;
	eldocInsId        integer:=null;
    definizioneId    integer:=null;

	soggettoDaId        integer:=null;
    soggRelModPagId     integer:=null;

    movgestTsTipoCode varchar(10):=null;
    movgestTsTipoId   integer:=null;
    numeroTsCode      integer:=null;

    docTipoId         integer:=null;
    docStatoVId       integer:=null;
    subdocTipoId      integer:=null;
    relazTipoId       integer:=null;
    docId			  integer:=null;
    subDocId          integer:=null;
	docCodBolloId     integer:=null;
    causaleOrdAttrId  integer:=null;

	docAnno           integer:=null;
    docNumero         varchar(250):=null;
    docDesc           varchar(500):=null;
    nProgr            integer:=0;

	docIns            boolean:=true;

    docDataEmissione      timestamp:=null;
    docDataScadenza       timestamp:=null;
    docContabilizzaGenPcc boolean:=false;
	docContoTesCode       varchar(50):=null;

    soggettoCode		  varchar(50):=null;
    soggettoCodeDa        varchar(50):=null;
    predocRec record;

    TIPO_MOVGEST      CONSTANT varchar:='I';
    TIPO_MOVGEST_TS_T CONSTANT varchar:='T';
    TIPO_MOVGEST_TS_S CONSTANT varchar:='S';
    MOVGEST_STATO_A   CONSTANT varchar:='A';


    ELDOC_STATO_R     CONSTANT varchar:='R';
    PREDOC_STATO_D    CONSTANT varchar:='D';
    PREDOC_STATO_C    CONSTANT varchar:='C';

    DOC_TIPO_DSP      CONSTANT varchar:='DSP';
    ND_CODE           CONSTANT varchar:='N.D.';
	BOLLO_CODE_99     CONSTANT varchar:='99';
    DOC_STATO_V       CONSTANT varchar:='V';
    SUBDOC_TIPO_CODE_SS  CONSTANT varchar:='SS';

    RELAZ_TIPO_SEDE   CONSTANT varchar:='SEDE_SECONDARIA';
    CAUSALE_ORD       CONSTANT varchar:='causaleOrdinativo';
	ELDOC_STATO_B     CONSTANT varchar:='B';

	PREDOC_DEF        CONSTANT varchar:='predoc_def';
    AMBITO_FIN        CONSTANT varchar:='AMBITO_FIN';

BEGIN

  codiceRisultato:=null;
  messaggioRisultato:=null;

  strMessaggioFinale:='Definisci predocumenti di spesa '||annoBilancio::varchar||'.';


  -- controllo parametri input
  strMessaggio:='Verifica passaggio enteProprietarioId';
  if enteProprietarioId is null then
  	raise exception ' Dato obbligatorio mancante.';
  end if;

  strMessaggio:='Verifica passaggio annoBilancio.';
  if annoBilancio is null then
  	raise exception ' Dato obbligatorio mancante.';
  end if;


  strMessaggio:='Verifica passaggio estremi impegno.';
  if (annoImpegno is not null or numeroImpegno is not null) and
     not (annoImpegno is not null and numeroImpegno is not null)
   then
	raise exception ' Dati impegno non completi.';
  end if;

  strMessaggio:='Verifica passaggio estremi elenco.';
  if  ( annoElenco is not null or numeroElenco is not null ) and
      not ( annoElenco is not null and numeroElenco is not null ) then
  	raise exception ' Dati elenco non completi.';
  end if;

  strMessaggio:='Verifica passaggio estremi impegno o elenco.';
  if annoElenco is null and annoImpegno is null then
  	raise exception ' La definizione puo'' essere elaborata per impegno o per elenco.';
  end if;

  -- lettura bilancioId
  strMessaggio:='Lettura bilancioId per annoBilancio='||annoBilancio||'.';
  select bil.bil_id into bilancioId
  from siac_t_bil bil , siac_t_periodo per
  where bil.ente_proprietario_id=enteProprietarioId
  and   per.periodo_id=bil.periodo_id
  and   per.anno::integer=annoBilancio;
  if bilancioId is null then
  	raise exception ' Errore in lettura identificativo.';
  end if;

  -- lettura docTipoId
  strMessaggio:='Lettura identificativo doc_tipo_code='||DOC_TIPO_DSP||'.';
  select tipo.doc_tipo_id into docTipoId
  from siac_d_doc_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.doc_tipo_code=DOC_TIPO_DSP;
  if docTipoId is null then
  	raise exception ' Errore in lettura identificativo.';
  end if;

  -- lettura codbollo esente 99
  strMessaggio:='Lettura identificativo cod_bollo='||BOLLO_CODE_99||'.';
  select c.codbollo_id into docCodBolloId
  from siac_d_codicebollo c
  where c.ente_proprietario_id=enteProprietarioId
  and   c.codbollo_code=BOLLO_CODE_99;
  if docCodBolloId is null then
  	raise exception ' Errore in lettura identificativo.';
  end if;

  -- lettura stato documento V
  strMessaggio:='Lettura identificativo docStatoCode='||DOC_STATO_V||'.';
  select d.doc_stato_id into docStatoVId
  from siac_d_doc_stato d
  where d.ente_proprietario_id=enteProprietarioId
  and   d.doc_stato_code=DOC_STATO_V;

  strMessaggio:='Lettura identificativo subDocTipoCode='||SUBDOC_TIPO_CODE_SS||'.';
  select tipo.subdoc_tipo_id into subDocTipoId
  from siac_d_subdoc_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.subdoc_tipo_code=SUBDOC_TIPO_CODE_SS;

  if subDocTipoId is null then
  	raise exception ' Errore in lettura identificativo.';
  end if;


  strMessaggio:='Lettura identificativo relaz_tipo_code='||RELAZ_TIPO_SEDE||'.';
  select tipo.relaz_tipo_id into relazTipoId
  from siac_d_relaz_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.relaz_tipo_code=RELAZ_TIPO_SEDE;
  if relazTipoId is null then
  	raise exception ' Errore in lettura identificativo.';
  end if;

  -- lettura indentificativo attributo causaleOrdinativo
  strmessaggio:='Lettura identificativo attributo '||CAUSALE_ORD||'.';
  select attr.attr_id into causaleOrdAttrId
  from siac_t_attr attr
  where attr.ente_proprietario_id=enteProprietarioId
  and   attr.attr_code=CAUSALE_ORD;

  -- lettura impegno
  if coalesce(numeroImpegno,0)!=0 then
   if coalesce(numeroSubimpegno,0)!=0 then
  		movgestTsTipoCode:=TIPO_MOVGEST_TS_S;
        numeroTsCode:=numeroSubimpegno;
   else
  		movgestTsTipoCode:=TIPO_MOVGEST_TS_T;
        numeroTsCode:=numeroImpegno;
   end if;


   strMessaggio:='Lettura movgestTsTipoId per tipo='||movgestTsTipoCode||'.';
   select tipo.movgest_ts_tipo_id into movgestTsTipoId
   from siac_d_movgest_ts_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.movgest_ts_tipo_code=movgestTsTipoCode;



   -- lettura impegno
   strMessaggio:='Lettura impegno.';
   select mov.movgest_id, ts.movgest_ts_id into movgestId, movgestTsId
   from siac_t_movgest mov, siac_d_movgest_tipo tipo,
        siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
        siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
   where mov.bil_id=bilancioId
     and tipo.movgest_tipo_id=mov.movgest_tipo_id
     and tipo.movgest_tipo_code=TIPO_MOVGEST
     and ts.movgest_id=mov.movgest_id
     and tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and tipots.movgest_ts_tipo_code=movgestTsTipoCode
     and mov.movgest_anno::integer=annoImpegno
     and mov.movgest_numero::integer=numeroImpegno
     and ts.movgest_ts_code::integer=numeroTsCode
     and rs.movgest_ts_id=ts.movgest_ts_id
     and stato.movgest_stato_id=rs.movgest_stato_id
     and stato.movgest_stato_code!=MOVGEST_STATO_A
     and mov.data_cancellazione is null
     and mov.validita_fine is null
     and ts.data_cancellazione is null
     and ts.validita_fine is null
     and rs.data_cancellazione is null
     and rs.validita_fine is null;
   if movgestId is null  then
    	raise exception ' Non esistente o non valido.';
   end if;
 end if;


 if annoElenco is not null then
  	strMessaggio:='Lettura identificativo elenco predoc.';
  	select e.eldoc_id into eldocId
    from siac_t_elenco_doc e, siac_r_elenco_doc_stato r, siac_d_elenco_doc_stato stato
    where e.ente_proprietario_id=enteProprietarioId
    and   e.eldoc_anno::integer=annoElenco
    and   e.eldoc_numero::integer=numeroElenco
    and   r.eldoc_id=e.eldoc_id
    and   stato.eldoc_stato_id=r.eldoc_stato_id
    and   stato.eldoc_stato_code!=ELDOC_STATO_R
    and   e.data_cancellazione is null
    and   e.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    if eldocId is null then
    	raise exception ' Identificativo non reperito.';
    end if;
 end if;


 -- verifica esistenza predocumenti da definire
 if eldocId is not null then
  	strMessaggio:='Verifica esistenza predocumenti in stato='||PREDOC_STATO_C
                  ||' collegati all'' elenco '||annoElenco::varchar||'/'||numeroElenco::varchar||'.';
    codResult:=null;
  	select 1 into codResult
    from siac_r_elenco_doc_predoc r,siac_t_predoc predoc,siac_r_predoc_stato rstato, siac_d_predoc_stato stato
    where r.eldoc_id=eldocId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_C
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;
    if coalesce(codResult,0)=0 then
    	raise exception ' Predocumenti non presenti.';
    end if;
 end if;

 if codResult is null and movgestTsId is not null then
  	strMessaggio:='Verifica esistenza predocumenti in stato='||PREDOC_STATO_C
                  ||' collegati all''impegno passato.';
    codResult:=null;
  	select 1 into codResult
    from siac_r_predoc_movgest_ts r,siac_t_predoc predoc,siac_r_predoc_stato rstato, siac_d_predoc_stato stato
    where r.movgest_ts_id=movgestTsId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_C
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;
    if coalesce(codResult,0)=0 then
    	raise exception ' Predocumenti non presenti.';
    end if;
  end if;

  -- se l'elenco non era stato creato in fase di caricamento flusso
  -- lo creo
  -- associo i predoc cosi successivamente ricerco sempre per elenco
  -- alla fine in questo caso cancello le relazioni con i predoc
  -- da completare questo passaggio
  if eldocId is null then

    strMessaggio:='Creazione elenco documenti. Calcolo numero.';
    update siac_t_elenco_doc_num num
    set    eldoc_numero=num.eldoc_numero+1
    where num.ente_proprietario_id=enteProprietarioId
    and   num.bil_id=bilancioId;

    strMessaggio:='Creazione elenco documenti. Inserimento [siac_t_elenco_doc].';
    insert into siac_t_elenco_doc
    (
     eldoc_anno,
	 eldoc_numero,
     eldoc_tot_quotespese,
     eldoc_tot_dapagare,
     validita_inizio,
     login_operazione,
     login_creazione,
     ente_proprietario_id
    )
    select annoBilancio,
           num.eldoc_numero,
           null,
           NULL,
           clock_timestamp(),
	       loginOperazione,
           loginOperazione,
   	       enteProprietarioId
    from siac_t_elenco_doc_num num
    where num.ente_proprietario_id=enteProprietarioId
    and   num.bil_id=bilancioId
    returning eldoc_id into eldocInsId;
	if eldocInsId is null then
    	raise exception ' Errore in inserimento.';
    end if;

    strMessaggio:='Creazione elenco documenti. Inserimento stato='||ELDOC_STATO_B||' [siac_r_elenco_doc_stato].';
	insert into siac_r_elenco_doc_stato
    (
    	eldoc_id,
        eldoc_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    (
    select eldocInsId,
           stato.eldoc_stato_id,
           clock_timestamp(),
	       loginOperazione,
           enteProprietarioId
    from siac_d_elenco_doc_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.eldoc_stato_code=ELDOC_STATO_B
    )
    returning eldoc_r_stato_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento.';
    end if;


    eldocId:=eldocInsId;
    strMessaggio:='Inserimento relazione elenco predocumenti [siac_r_elenco_doc_predoc].';
    insert into siac_r_elenco_doc_predoc
    (
    	eldoc_id,
        predoc_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select  eldocInsId,
            predoc.predoc_id,
            clock_timestamp(),
	        loginOperazione,
            enteProprietarioId
    from siac_r_predoc_movgest_ts r,siac_t_predoc predoc,siac_r_predoc_stato rstato, siac_d_predoc_stato stato
    where r.movgest_ts_id=movgestTsId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_C
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;

    codResult:=null;
    strMessaggio:='Verifica relazioni inserite elenco-predocumenti.';
    select 1 into codResult
    from siac_r_predoc_movgest_ts r,siac_t_predoc predoc,siac_r_predoc_stato rstato, siac_d_predoc_stato stato
    where r.movgest_ts_id=movgestTsId
    and   predoc.predoc_id=r.predoc_id
    and   rstato.predoc_id=predoc.predoc_id
    and   stato.predoc_stato_id=rstato.predoc_stato_id
    and   stato.predoc_stato_code=PREDOC_STATO_C
    and   not exists
    (
    select 1 from siac_r_elenco_doc_predoc rel
    where rel.eldoc_id=eldocinsid
    and   rel.predoc_id=predoc.predoc_id
    and   rel.data_cancellazione is null
    and   rel.validita_fine is null
    )
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   predoc.data_cancellazione is null
    and   predoc.validita_fine is null
    and   rstato.data_cancellazione is null
    and   rstato.validita_fine is null;
    if codResult is not null then
    	raise exception ' Relazioni mancanti.';
    end if;
  end if;

  strMessaggio:='Lettura predocumenti da definire.';
  for predocRec in
  (
  select predoc.*,
         rmov.movgest_ts_id,
         rsog.soggetto_id, sogg.soggetto_code,
         cc.contotes_id, COALESCE(cc.contotes_code,ND_CODE) contotes_code,
         cau.caus_id,coalesce(cau.caus_code,ND_CODE) caus_code,cau.caus_desc caus_desc,
         rmdp.modpag_id
  from siac_r_elenco_doc_predoc r,
       siac_r_predoc_stato rstato, siac_d_predoc_stato stato,
       siac_t_predoc predoc left join siac_r_predoc_movgest_ts rmov
                                      on (predoc.predoc_id=rmov.predoc_id
                                      and rmov.data_cancellazione is null
                                      and rmov.validita_fine is null)
        					left join siac_r_predoc_sog rsog join siac_t_soggetto sogg on (sogg.soggetto_id=rsog.soggetto_id)
                                      on ( predoc.predoc_id=rsog.predoc_id
                                      and  rsog.data_cancellazione is null
                                      and  rsog.validita_fine is null)
                            left join siac_d_contotesoreria cc on (predoc.contotes_id=cc.contotes_id)
                            left join siac_r_predoc_causale rcau join siac_d_causale cau on (cau.caus_id=rcau.caus_id)
                                      on ( predoc.predoc_id=rcau.predoc_id
                                      and  rcau.data_cancellazione is null
                                      and  rcau.validita_fine is null )
                            left join siac_r_predoc_modpag rmdp on ( predoc.predoc_id=rmdp.predoc_id
                            									and  rmdp.data_cancellazione is null
                                                                and  rmdp.validita_fine is null )

  where r.eldoc_id=eldocId
  and   predoc.predoc_id=r.predoc_id
  and   rstato.predoc_id=predoc.predoc_id
  and   stato.predoc_stato_id=rstato.predoc_stato_id
  and   stato.predoc_stato_code=PREDOC_STATO_C
  and   rcau.predoc_id=predoc.predoc_id
  and   cau.caus_id=rcau.caus_id
  and   predoc.data_cancellazione is null
  and   predoc.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  order by predoc.predoc_id
  )
  loop
  strMessaggioIni:='Definizione predocumento predocId='||preDocRec.predoc_id||'.';
  codResult:=null;
  soggRelModPagId:=null;
  soggettoDaId:=null;
  soggettoCodeDa:=null;
  docId:=null;
  subDocId:=null;

  docIns:=true;
  nProgr:=nProgr+1;

  -- controlli
  -- impegno obbligatorio
  if predocRec.movgest_ts_id is null then
	  strMessaggio:=strMessaggioIni||' Impegno mancante.';
      docIns:=false;
  end if;

  -- soggetto obbligatorio
  if  docIns=true and
  	predocRec.soggetto_id is null then
    strMessaggio:=strMessaggioIni||' Soggetto mancante.';
    docIns:=false;
  end if;

  -- mdp obbligatoria
  if  docIns=true and
	predocRec.modpag_id is null then
    strMessaggio:=strMessaggioIni||' MDP mancante.';
    docIns:=false;
  end if;

  -- causale ordinativo obbligatoria

  if  docIns=true then
	-- verifica se soggetto_id sede secondaria
    strMessaggio:=strMessaggioIni||' Lettura codice soggetto di riferimento per sede secondaria.';
    select da.soggetto_id , da.soggetto_code
           into soggettoDaId, soggettoCodeDa
    from siac_r_soggetto_relaz r,siac_t_soggetto da
    where r.soggetto_id_a=predocRec.soggetto_id
    and   r.relaz_tipo_id=relazTipoId
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    if soggettoDaId is not null then
    	 soggettoCode:=soggettoCodeDa;
    else soggettoCode:=preDocRec.soggetto_code;
    end if;

    -- verifica se MDP CSI/CSC
    strMessaggio:=strMessaggioIni||' Verifica esistenza CSI/CSC [siac_r_soggrel_modpag].';
    select r.soggrelmpag_id into soggRelModPagId
    from siac_r_soggrel_modpag r, siac_r_soggetto_relaz rel
    where r.modpag_id=preDocRec.modpag_id
    and   rel.soggetto_relaz_id=r.soggetto_relaz_id
    and   rel.soggetto_id_da=preDocRec.soggetto_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   rel.data_cancellazione is null
    and   rel.validita_fine is null;
 end if;

 if docIns=true then
    currTimeStamp:=to_char(clock_timestamp(), 'yyyy/mm/dd HH12:MI:SS');

	docAnno:=annoBilancio;
    -- codicecausalespesa[N.D.] - contotesoreria [N.D.] - periodoCompetenza - codiceSoggetto - 'yyyy/mm/gg hh:mm:ss'[current_timestamp] - progressivo elaborazione
    docNumero:=preDocRec.caus_code||' - '||preDocRec.contotes_code
               ||' - '||preDocRec.predoc_periodo_competenza||' - '||soggettoCode||' - '||currTimeStamp||' - '||nProgr::varchar;
	-- codicecausalespesa[N.D.] - contotesoreria [N.D.] - periodoCompetenza - codiceSoggetto - 'yyyy/mm/gg hh:mm:ss'[current_timestamp]
    docDesc:=preDocRec.caus_code||' - '||preDocRec.contotes_code
             ||' - '||preDocRec.predoc_periodo_competenza||' - '||soggettoCode||' - '||currTimeStamp;


    docDataEmissione:=clock_timestamp(); -- current_timestamp
    docDataScadenza:=null;  -- null
    docContabilizzaGenPcc:=false; -- false


    strMessaggio:=strMessaggioIni||' Inserimento documento [siac_t_doc].';
    -- siac_t_doc
    insert into siac_t_doc
    (doc_anno,
     doc_numero,
     doc_desc,
     doc_importo,
     doc_data_emissione,
     doc_data_scadenza,
     doc_tipo_id,
     codbollo_id,
     validita_inizio,
     ente_proprietario_id,
     login_operazione,
     login_creazione,
     login_modifica,
     doc_contabilizza_genpcc
    )
    values
    (
     docAnno,
     docNumero,
     docDesc,
     predocRec.predoc_importo,
     docDataEmissione,
     docDataScadenza,
     docTipoId,
     docCodBolloId,
	 clock_timestamp(),
     enteProprietarioId,
     loginOperazione,
     loginOperazione,
     loginOperazione,
     docContabilizzaGenPcc
    )
    returning doc_id into docId;

    if docId is null THEN
        strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;

 if docIns=true then
	strMessaggio:=strMessaggioIni||' Inserimento stato documento VALIDO [siac_r_doc_stato].';
    codResult:=null;
    -- siac_r_doc_stato - VALIDO
    insert into siac_r_doc_stato
    (
    	doc_id,
        doc_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    values
    (
    	docId,
        docStatoVId,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning doc_stato_r_id into codResult;
    if codResult is null then
    	strMessaggio:=strMessaggio|| ' Errore in inserimento.';
        docIns:=false;
    end if;
  end if;

  if docIns=true then
    -- siac_r_doc_sog
	strMessaggio:=strMessaggioIni||' Inserimento relazione con soggetto [siac_r_doc_sog].';
    codResult:=null;
    insert into siac_r_doc_sog
    (
    	doc_id,
        soggetto_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    values
    (
    	docId,
        docStatoVId,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning doc_sog_id into codResult;
    if codResult is null then
    	strMessaggio:=strMessaggio||' Errore in inserimento.';
        docIns:=false;
    end if;
 end if;

 -- siac_r_doc_class
 -- nessun classificatore

 -- siac_r_doc_attr
 -- nessun attributo

 if docIns=true then
    -- siac_t_subdoc
    strMessaggio:=strMessaggioIni||' Inserimento quota documento [siac_t_subdoc].';
    insert into siac_t_subdoc
    (
	 subdoc_numero,
	 subdoc_desc,                 -- desc documento - numero predocumento
	 subdoc_importo,
     subdoc_data_scadenza,        -- null
	 subdoc_convalida_manuale,    -- null
	 subdoc_splitreverse_importo, -- null
     contotes_id,                 -- null
	 dist_id,                     -- null
	 comm_tipo_id,                -- null
	 doc_id,
	 subdoc_tipo_id,  		      -- spesa
	 notetes_id,                  -- null
	 validita_inizio,
     ente_proprietario_id,
     login_operazione,
	 login_creazione,
     login_modifica
    )
    values
    (
     1,
	 docDesc||' - '||preDocRec.predoc_numero,                     -- subdoc_desc desc documento - numero predocumento
	 preDocRec.predoc_importo,
     null, 						  -- subdoc_data_scadenza
	 null,                        -- subdoc_convalida_manuale
	 null,                        -- subdoc_splitreverse_importo
     null,                        -- contotes_id
	 null,                        -- dist_id
	 null,                        -- comm_tipo_id
	 docId,                       -- doc_id
	 subDocTipoId,  		      -- subdoc_tipo_id  SS
	 null,                        -- notetes_id
	 clock_timestamp(),
     enteProprietarioId,
     loginOperazione,
	 loginOperazione,
     loginOperazione
    )
    returning subdoc_id into subDocId;
	if subDocId is null then
    	strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;

 if docIns=true then
    -- siac_t_subdoc_num
    strMessaggio:=strMessaggioIni||' Inserimento progressivo subDoc [siac_t_subdoc_num].';
    codResult:=null;
    insert into siac_t_subdoc_num
    (
    	doc_id,
        subdoc_numero,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    values
    (
    	docId,
        1,
        clock_timestamp(),
        loginOperazione,
	    enteProprietarioId
    )
    returning subdoc_num_id into codResult;
    if codResult is null then
    	strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;


 if docIns=true then
 	-- siac_r_subdoc_attr
    -- causale_ordinativo =  codice_causale||' '||causale_spesa_desc [causaleOrdinativo]
    codResult:=null;
    strMessaggio:=strMessaggioIni||' Inserimento attributo '||CAUSALE_ORD||' [siac_r_subdoc_attr].';
    insert into siac_r_subdoc_attr
    (
    	subdoc_id,
        attr_id,
        testo,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    values
    (
    	subDocId,
        causaleOrdAttrId,
        (case when preDocRec.caus_desc is not null then preDocRec.caus_code||' '||preDocRec.caus_desc else null end),
        clock_timestamp(),
        loginOperazione,
	    enteProprietarioId
    )
    returning subdoc_attr_id into codResult;
    if codResult is null then
    	strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;



 -- siac_r_subdoc_class
 -- nessun classificatore

 if docIns=true then



	-- siac_r_subdoc_movgest_ts
    strMessaggio:=strMessaggioIni||' Inserimento relazione con impegno [siac_r_subdoc_movgest_ts].';
    codResult:=null;
    insert into siac_r_subdoc_movgest_ts
    (
    	subdoc_id,
        movgest_ts_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    values
    (
    	subDocId,
        preDocRec.movgest_ts_id,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning subdoc_movgest_ts_id into codResult;
    if codResult is null then
    	strMessaggio:=strmessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;

 if docIns=true then
    -- siac_r_subdoc_modpag
    codResult:=null;
    strMessaggio:=strMessaggioIni||' Inserimento relazione con MDP [siac_r_subdoc_modpag].';
    insert into siac_r_subdoc_modpag
    (
      subdoc_id,
	  modpag_id,
	  soggrelmpag_id,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    values
    (
    	subDocId,
        preDocRec.modpag_id,
        soggRelModPagId,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning subdoc_modpag_id into codResult;
    if codResult is null then
    	strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
  end if;

  if docIns=true then
    -- siac_r_subdoc_prov_cassa
    codResult:=null;
    strMessaggio:=strMessaggioIni||' Inserimento relazione con provvisori di cassa [siac_r_subdoc_prov_cassa].';
    insert into siac_r_subdoc_prov_cassa
    (
    	subdoc_id,
        provc_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select subDocId,
    	   r.provc_id,
           clock_timestamp(),
           loginOperazione,
	       enteProprietarioId
    from siac_r_predoc_prov_cassa r
    where r.predoc_id=preDocRec.predoc_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

    --- controllo  inserimento
    strMessaggio:=strMessaggio||' Verifica inserimento.';
    select 1 into codResult
    from siac_r_predoc_prov_cassa rpre
    where rpre.predoc_id=preDocRec.predoc_id
    and   not exists
    (
    select 1 from siac_r_subdoc_prov_cassa rsub
    where rsub.subdoc_id=subDocId
    and   rsub.data_cancellazione is null
    and   rsub.validita_fine is null
    )
    and rpre.data_cancellazione is null
    and rpre.validita_fine is null;
    if codResult is not null then
    	strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;


 if docIns=true then
 	codResult:=null;
    strMessaggio:=strMessaggioIni||' Inserimento relazione voce mutuo [siac_r_mutuo_voce_subdoc]'||'.';
 	-- siac_r_mutuo_voce_subdoc
    insert into siac_r_mutuo_voce_subdoc
    (
    	subdoc_id,
        mut_voce_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    (
    select subDocId,
           r.mut_voce_id,
           clock_timestamp(),
	       loginOperazione,
	       enteProprietarioId
    from siac_r_mutuo_voce_predoc r
    where r.predoc_id=preDocRec.predoc_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    );

    select 1 into codResult
    from siac_r_mutuo_voce_predoc r
    where r.predoc_id=preDocRec.predoc_id
    and   not exists
    (
    select 1 from siac_r_mutuo_voce_subdoc rsub
    where rsub.subdoc_id=subDocId
    and   rsub.data_cancellazione is null
    and   rsub.validita_fine is null
    )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;
    if codResult is not null then
    	strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;

 if docIns=true then
    -- siac_r_elenco_doc_subdoc
    codResult:=null;
    strMessaggio:=strMessaggioIni||' Inserimento relazione tra elenco e documento [siac_r_elenco_doc_subdoc].';
    insert into siac_r_elenco_doc_subdoc
    (
    	subdoc_id,
        eldoc_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    values
    (
    	subDocId,
    	eldocId,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning subdoc_atto_amm_id into codResult;
    if codResult is null then
    	strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;

 if docIns=true then
    -- siac_r_predoc_subdoc
	codResult:=null;
    strMessaggio:=strMessaggioIni||' Inserimento relazione tra predocumento e documento [siac_r_predoc_subdoc].';
    insert into siac_r_predoc_subdoc
    (
    	predoc_id,
        subdoc_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    values
    (
    	preDocRec.predoc_id,
        subDocId,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning predoc_subdoc_id into codResult;
	if codResult is null then
    	strMessaggio:=strMessaggio||' Inserimento non effettuato.';
        docIns:=false;
    end if;
 end if;

 if docIns=false then
        strMessaggioScarto:=strMessaggio;

        if docId is not null then
          if subDocId is not null then
          	strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_predoc_subdoc].';
        	delete from siac_r_predoc_subdoc r
            where r.subdoc_id=subDocId;
          	strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_elenco_doc_subdoc].';
            delete from siac_r_elenco_doc_subdoc r
            where r.subdoc_id=subDocId;
          	strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_subdoc_prov_cassa].';
            delete from siac_r_subdoc_prov_cassa r
            where r.subdoc_id=subDocId;
          	strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_subdoc_modpag].';
            delete from siac_r_subdoc_modpag r
            where r.subdoc_id=subDocId;
          	strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_subdoc_movgest_ts].';
            delete from siac_r_subdoc_movgest_ts r
            where r.subdoc_id=subDocId;
          	strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_mutuo_voce_subdoc].';
            delete from siac_r_mutuo_voce_subdoc r
            where r.subdoc_id=subDocId;
			strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_subdoc_attr].';
            delete from siac_r_subdoc_attr r
            where r.subdoc_id=subDocId;
          	strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_t_subdoc_num].';
            delete from siac_t_subdoc_num r
            where r.subdoc_id=subDocId;

          	strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_t_subdoc].';
            delete from siac_t_subdoc r
            where r.subdoc_id=subDocId;
          end if;

          strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_doc_sog].';
          delete from siac_r_doc_sog
          where r.doc_id=docId;
          strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_r_doc_stato].';
          delete from siac_r_doc_stato r
          where r.doc_id=docId;

          strMessaggio:=strMessaggioScarto||' Cancellazione per scarto [siac_t_doc].';
          delete from siac_t_doc r
          where r.doc_id=docId;
        end if;

        strMessaggio:=strMessaggioScarto||' Inserimento scarto.';
        -- gestione tab. scarto
		if definizioneId is null then
        	strMessaggio:=strMessaggioScarto||' Lettura definizioneId per '||PREDOC_DEF||'_'||annoBilancio::varchar||' [siac_t_progressivo].';
        	select progr.prog_value::integer into definizioneId
            from siac_t_progressivo progr
            where progr.ente_proprietario_id=enteProprietarioId
            and   progr.prog_key=PREDOC_DEF||'_'||annoBilancio::varchar;

            if definizioneId is null then
            	codResult:=null;
        	    strMessaggio:=strMessaggioScarto||' Inserimento definizioneId=1 per '||PREDOC_DEF||'_'||annoBilancio::varchar||' [siac_t_progressivo].';
            	definizioneId:=1;
            	insert into siac_t_progressivo
                (
				 prog_key,
                 prog_value,
				 ambito_id,
                 validita_inizio,
                 login_operazione,
                 ente_proprietario_id
                )
			    (
                 select
                 PREDOC_DEF||'_'||annoBilancio::varchar,
                 definizioneId,
                 a.ambito_id,
                 clock_timestamp(),
				 loginOperazione,
				 enteProprietarioId
                 from siac_d_ambito a
                 where a.ente_proprietario_id=enteProprietarioId
                 and   a.ambito_code=AMBITO_FIN
                )
                returning prog_id into codResult;
                if codResult is null then
                	raise exception ' Errore in inserimento.';
                end if;
            else
            	definizioneId:=definizioneId+1;
                strMessaggio:=strMessaggioScarto||' Aggiornamento definizioneId per '||PREDOC_DEF||'_'||annoBilancio::varchar||' [siac_t_progressivo].';
                update siac_t_progressivo p
                set    prog_value=definizioneId,
                       data_modifica=clock_timestamp(),
                       login_operazione=p.login_operazione||loginOperazione
                where  progr.ente_proprietario_id=enteProprietarioId
		         and   progr.prog_key=PREDOC_DEF||'_'||annoBilancio::varchar;
            end if;
        end if;

        codResult:=null;
        strMessaggio:=strMessaggioScarto||' Inserimento scarto [siac_t_predoc_definisci_scarto].';
        raise notice 'strMessaggio=%', strMessaggio;
        insert into siac_t_predoc_definisci_scarto
        (
         definizione_data,
  	     definizione_id,
	 	 predoc_id,
		 eldoc_id,
		 motivo_scarto,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         dataElaborazione,
         definizioneId,
         preDocRec.predoc_id,
         elDocId,
         strMessaggioScarto,
         clock_timestamp(),
	     loginOperazione,
		 enteProprietarioId
        )
        returning predoc_def_scarto_id into codResult;
        if codResult is null then
          	raise exception ' Errore in inserimento.';
        end if;

        nProgr:=nProgr-1;
  end if;


  end loop;

  -- se ho inserito nella function l''elenco e quindi questa relazione - cancello la relazione
  if eldocInsId is not null then
  	strMessaggio:='Cancellazione relazione predocumenti elenco [siac_r_elenco_doc_predoc].';
  	delete from siac_r_elenco_doc_predoc r
    where r.ente_proprietario_id=enteProprietarioId
    and   r.eldoc_id=elDocInsId;
  end if;

  if eldocId is not null then
    -- aggiornamento siac_t_elenco_doc per
    -- eldoc_tot_quotespese
    -- eldoc_tot_dapagare
    strMessaggio:='Aggiornamento importi elenco.';
    update siac_t_elenco_doc e
	set eldoc_tot_quotespese=QUERY.tot_subdoc,
    	eldoc_tot_dapagare=QUERY.tot_liquidato,
        data_modifica=clock_timestamp(),
        login_operazione=(case when eldocInsId is not null then e.login_operazione else e.login_operazione||loginOperazione end)
	from
	(
	with
	tot_doc as
	(
		select coalesce(sum(sub.subdoc_importo - coalesce(sub.subdoc_importo_da_dedurre,0)),0) tot_subdoc
		from siac_r_elenco_doc_subdoc r, siac_t_subdoc sub,
			 siac_t_doc doc, siac_d_doc_tipo tipo, siac_d_doc_fam_tipo fam,
	     	 siac_r_doc_stato rdoc, siac_d_doc_stato stato
		where r.eldoc_id=eldocId
		and   sub.subdoc_id=r.subdoc_id
		and   doc.doc_id=sub.doc_id
		and   rdoc.doc_id=doc.doc_id
		and   stato.doc_stato_id=rdoc.doc_stato_id
		and   stato.doc_stato_code not in ('A','ST')
		and   tipo.doc_tipo_id=doc.doc_tipo_id
		and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
		and   fam.doc_fam_tipo_code in ('IS','S')
		and   tipo.doc_tipo_code not in ('NTE','NOT','NCD')
		and   r.data_cancellazione is null
		and   r.validita_fine is null
		and   sub.data_cancellazione is null
		and   sub.validita_fine is null
		and   doc.data_cancellazione is null
		and   doc.validita_fine is null
		and   rdoc.data_cancellazione is null
		and   rdoc.validita_fine is null
	),
	tot_da_pag as
	(
		select coalesce(sum(liq.liq_importo),0) tot_liquidato
		from siac_r_elenco_doc_subdoc r, siac_t_subdoc sub, siac_r_subdoc_liquidazione rliq,
		     siac_t_liquidazione liq, siac_r_liquidazione_stato rliqstato, siac_d_liquidazione_stato liqstato
		where r.eldoc_id=eldocId
		and   sub.subdoc_id=r.subdoc_id
		and   rliq.subdoc_id=sub.subdoc_id
		and   liq.liq_id=rliq.liq_id
		and   rliqstato.liq_id=liq.liq_id
		and   liqstato.liq_stato_id=rliqstato.liq_stato_id
		and   liqstato.liq_stato_code='V'
		and   not exists
		(
		select 1
		from siac_r_liquidazione_ord rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord,
		     siac_r_ordinativo_stato rordstato, siac_d_ordinativo_stato ordstato
		where rord.liq_id=liq.liq_id
		and   ts.ord_ts_id=rord.sord_id
		and   ord.ord_id=ts.ord_id
		and   rordstato.ord_id=ord.ord_id
		and   ordstato.ord_stato_id=rordstato.ord_stato_id
		and   ordstato.ord_stato_code!='A'
		and   rord.data_cancellazione is null
		and   rord.validita_fine is null
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   ord.data_cancellazione is null
		and   ord.validita_fine is null
		and   rordstato.data_cancellazione is null
		and   rordstato.validita_fine is null
		)
		and   r.data_cancellazione is null
		and   r.validita_fine is null
		and   sub.data_cancellazione is null
		and   sub.validita_fine is null
		and   rliq.data_cancellazione is null
		and   rliq.validita_fine is null
		and   liq.data_cancellazione is null
		and   liq.validita_fine is null
		and   rliqstato.data_cancellazione is null
		and   rliqstato.validita_fine is null
	)
	select tot_doc.tot_subdoc, tot_da_pag.tot_liquidato
	from tot_doc, tot_da_pag
	) QUERY
	where e.ente_proprietario_id=enteProprietarioId
	and   e.eldoc_id=eldocId;
  end if;

  codiceRisultato:=0;
  messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata. Inseriti n.documenti='||nProgr||'.';
  if elDocInsId is not null then
  	messaggioRisultato:=messaggioRisultato||' Inserito identificativo elencoDocId='||elDocInsId||'.';
  end if;

  return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;