/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- 09.07.2021 Sofia JIRA SIAC-8221 - inizio
insert into pagopa_d_riconciliazione_errore
(
 pagopa_ric_errore_code, 
 pagopa_ric_errore_desc, 
 validita_inizio, 
 login_operazione,
 ente_proprietario_id
	
)
select '52',
       'DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA ANNULLATO O CON DATA DI REGOLARIZZAZIONE',
       now(),
       'SIAC-8221',
       ente.ente_proprietario_id
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   not exists
(
select 1
from pagopa_d_riconciliazione_errore err 
where err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code='52'
and   err.data_cancellazione is null 
);



update pagopa_d_riconciliazione_errore err 
set    pagopa_ric_errore_desc='DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE O NON DEFINITIVO',
       data_modifica=now(),
       login_operazione=err.login_operazione||'-SIAC-8221'
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   err.ente_proprietario_id=ente.ente_proprietario_id
and   err.pagopa_ric_errore_code ='23'
and   err.login_operazione not like '%SIAC-8221';

drop FUNCTION if exists siac.fnc_pagopa_t_elaborazione_riconc_insert
(
  filepagopaid integer,
  filepagopaFileXMLId     varchar,
  filepagopaFileOra       varchar,
  filepagopaFileEnte      varchar,
  filepagopaFileFruitore  varchar,
  inPagoPaElabId          integer,
  annoBilancioElab        integer,
  enteproprietarioid      integer,
  loginoperazione         varchar,
  dataelaborazione        timestamp,
  out outPagoPaElabId     integer,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
);

drop function if exists 
siac.fnc_pagopa_t_elaborazione_riconc_esegui 
(
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out pagopaBckSubdoc             BOOLEAN,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_insert
(
  filepagopaid integer,
  filepagopaFileXMLId     varchar,
  filepagopaFileOra       varchar,
  filepagopaFileEnte      varchar,
  filepagopaFileFruitore  varchar,
  inPagoPaElabId          integer,
  annoBilancioElab        integer,
  enteproprietarioid      integer,
  loginoperazione         varchar,
  dataelaborazione        timestamp,
  out outPagoPaElabId     integer,
  out codicerisultato     integer,
  out messaggiorisultato  varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
    strMessaggioBck  VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	strErrore VARCHAR(1500):='';
    strMessaggioLog VARCHAR(2500):='';
	codResult integer:=null;
	annoBilancio integer:=null;

    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione

    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
	PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE
    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO

    PAGOPA_ERR_40   CONSTANT  varchar :='40';--PROVVISORIO DI CASSA REGOLARIZZATO
    -- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO

    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    -- 23.06.2021 Sofia jira SIAC-8221
    PAGOPA_ERR_52	CONSTANT  varchar :='52';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA ANNULLATO O CON DATA DI REGOLARIZZAZIONE
    
    -- 30.05.2019 siac-6720
  	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';


    FL_COLL_FATT_ATTR CONSTANT varchar :='FlagCollegamentoAccertamentoFattura';
    FL_COLL_CORR_ATTR CONSTANT varchar :='FlagCollegamentoAccertamentoCorrispettivo';

	docTipoIpaId integer :=null;
    docTipoFatId integer :=null;
    docTipoCorId integer :=null;

    attrAccFatturaId integer:=null;
    attrAccCorrispettivoId integer:=null;


    filePagoPaElabId integer:=null;

    pagoPaFlussoAnnoEsercizio integer:=null;
    pagoPaFlussoNomeMittente  varchar(500):=null;
    pagoPaFlussoData  varchar(50):=null;
    pagoPaFlussoTotPagam  numeric:=null;

    pagoPaFlussoRec record;

    pagopaElabFlussoId integer:=null;
    strNote varchar(500):=null;

    bilancioId integer:=null;
    periodoid integer:=null;
    pagoPaErrCode varchar(10):=null;

BEGIN

    if coalesce(filepagopaFileXMLId,'')='' THEN
     strMessaggioFinale:='Elaborazione PAGOPA per file_pagopa_id='||filepagopaid::varchar||'.';
    else
	 strMessaggioFinale:='Elaborazione PAGOPA per file_pagopa_id='||filepagopaid::varchar
                       ||' filepagopaFileXMLId='||coalesce(filepagopaFileXMLId,' ')||'.';
    end if;

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale;
--    raise notice 'strMessaggioLog=% ',strMessaggioLog;
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
     inPagoPaElabId,
     filepagopaid,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );

   	outPagoPaElabId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';

    if coalesce(inPagoPaElabId,0)!=0 then
    	outPagoPaElabId:=inPagoPaElabId;
        filePagoPaElabId:=inPagoPaElabId;
    end if;


    ---------- inizio controlli su siac_t_file_pagopa e piano_t_riconciliazione  --------------------------------
	-- verifica esistenza file_pagopa per filePagoPaId passato
    -- un file XML puo essere in stato
    -- ACQUISITO - dati XML flussi caricati - pronti per inizio elaborazione
    -- ELABORATO_IN_CORSO* - dati XML flussi caricati - elaborazione in corso
    -- ELABORATO_OK - dati XML flussi elaborati e conclusi correttamente
    -- ANNULLATO, RIFIUTATO  - errore - file chiuso

   strMessaggio:='Verifica esistenza filePagoPa da elaborare per filePagoPaid e filepagopaFileXMLId.';
   codResult:=null;
   select 1 into codResult
   from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
   where pagopa.file_pagopa_id=filePagoPaId
   and   pagopa.file_pagopa_code=(case when coalesce(filepagopaFileXMLId,'')!='' then filepagopaFileXMLId
                                 else pagopa.file_pagopa_code end )
   and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
   and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
   and   pagopa.data_cancellazione is null
   and   pagopa.validita_fine is null;

   if codResult is  null then
      -- errore bloccante
      strErrore:=' File non esistente o in stato differente.Verificare.';
      codiceRisultato:=-1;
      --outPagoPaElabId:=-1;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
--      raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
   end if;


   if codResult is null then
     strMessaggio:='Verifica esistenza filePagoPa  elaborato per filePagoPaid e filepagopaFileXMLId.';
     select 1 into codResult
     from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
     where pagopa.file_pagopa_id=filePagoPaId
     and   pagopa.file_pagopa_code=(case when coalesce(filepagopaFileXMLId,'')!='' then filepagopaFileXMLId
                                   else pagopa.file_pagopa_code end )
     and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code=ELABORATO_OK_ST
     and   pagopa.data_cancellazione is null;
     if codResult is not null then
      -- errore bloccante
      strErrore:=' File gia'' elaborato.Verificare.';
      codiceRisultato:=-1;
      -- pagoPaElabId:=-1;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      messaggioRisultato:=strMessaggioFinale||strMessaggio||strErrore;
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
--      raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );
      return;
     end if;
   end if;



   codResult:=null;
   if coalesce(filepagopaFileXMLId,'')!=''  then
      strMessaggio:='Verifica univocita'' file filepagopaFileXMLId.';
      select count(*) into codResult
      from siac_t_file_pagopa pagopa,siac_d_file_pagopa_stato stato
      where pagopa.file_pagopa_code=filepagopaFileXMLId
      and   stato.file_pagopa_stato_id=pagopa.file_pagopa_stato_id
      and   stato.file_pagopa_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
      and   pagopa.data_cancellazione is null
      and   pagopa.validita_fine is null;

      if codResult is not null and codResult>1 then
          strErrore:=' File caricato piu'' volte. Verificare.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_5;
      else codResult:=null;
      end if;
   end if;

   if codResult is null then
        -- errore bloccante
        strMessaggio:='Verifica esistenza pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;

		if codResult is null then
        	codResult:=-1;
            strErrore:=' Non esistente.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_6;
        else codResult:=null;
        end if;

		-- errore bloccante
		if codResult is null then
         strMessaggio:='Verifica esistenza pagopa_t_riconciliazione da elaborare.';
    	 select 1 into codResult
         from pagopa_t_riconciliazione ric
         where ric.file_pagopa_id=filePagoPaId
         and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--         and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
         /*and   not exists
         (select 1
          from pagopa_t_riconciliazione_doc doc
          where doc.pagopa_ric_id=ric.pagopa_ric_id
          and   doc.pagopa_ric_doc_subdoc_id is not null
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )*/
         /*and   not exists
         (select 1
          from pagopa_t_riconciliazione_doc doc
          where doc.pagopa_ric_id=ric.pagopa_ric_id
          and   doc.pagopa_ric_doc_subdoc_id is null
          and   doc.pagopa_ric_doc_stato_elab in ('E')
          and   doc.data_cancellazione is null
          and   doc.validita_fine is null
         )*/
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null;

         if codResult is null then
         	codResult:=-1;
            strErrore:=' Non esistente.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_7;
         else codResult:=null;
         end if;
        end if;
   end if;


   -- controlli correttezza del filepagopaFileXMLId in pagopa_t_riconciliazione
   if codResult is null and coalesce(filepagopaFileXMLId,'')!='' then
    strMessaggio:='Verifica congruenza filepagopaFileXMLId su pagopa_t_riconciliazione.';
    select count(distinct ric.file_pagopa_id) into codResult
   	from pagopa_t_riconciliazione ric
    where ric.pagopa_ric_file_id=filepagopaFileXMLId
    and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is null then
    	codResult:=-1;
        strErrore:=' File non presenti per identificativo.Verificare.';
    else
      if codResult >1 then
           codResult:=-1;
           strErrore:=' Esistenza diversi file presenti con stesso identificativo.Verificare.';
		   pagoPaErrCode:=PAGOPA_ERR_9;
      else codResult:=null;
      end if;
   end if;

  end if;

  if codResult is null then
    	strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
        -- lettura tipodocumento
        select tipo.doc_tipo_id into docTipoIpaId
        from siac_d_doc_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.doc_tipo_code=DOC_TIPO_IPA;
        if docTipoIpaId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_24;
        else codResult:=null;
        end if;
  end if;

  if codResult is null then
    	strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
        -- lettura tipodocumento
        select tipo.doc_tipo_id into docTipoCorId
        from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.doc_tipo_code=DOC_TIPO_COR
        and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
        and   fam.doc_fam_tipo_code='E';
        if docTipoCorId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_24;
        else codResult:=null;
        end if;
  end if;

  if codResult is null then
    	strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
        -- lettura tipodocumento
        select tipo.doc_tipo_id into docTipoFatId
        from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.doc_tipo_code=DOC_TIPO_FAT
        and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
        and   fam.doc_fam_tipo_code='E';
        if docTipoFatId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_24;
        else codResult:=null;
        end if;
  end if;


  --FlagCollegamentoAccertamentoFattura
  --FL_COLL_FATT_ATTR
  if codResult is null  then
    strMessaggio:='Verifica esistenza attributo='||FL_COLL_FATT_ATTR||'.';
    select attr.attr_id into attrAccFatturaId
    from siac_t_attr attr
    where attr.ente_proprietario_id=enteProprietarioId
    and   attr.attr_code=FL_COLL_FATT_ATTR;
    if attrAccFatturaId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_47;
     else codResult:=null;
    end if;
  end if;

  --FlagCollegamentoAccertamentoCorrispettivo
  --FL_COLL_CORR_ATTR
  if codResult is null  then
    strMessaggio:='Verifica esistenza attributo='||FL_COLL_CORR_ATTR||'.';
    select attr.attr_id into attrAccCorrispettivoId
    from siac_t_attr attr
    where attr.ente_proprietario_id=enteProprietarioId
    and   attr.attr_code=FL_COLL_CORR_ATTR;
    if attrAccCorrispettivoId is null then
          strErrore:=' Identificativo insesistente.';
          codResult:=-1;
          pagoPaErrCode:=PAGOPA_ERR_47;
     else codResult:=null;
    end if;
  end if;

   -- errore bloccante - da verificare se possono in un file XML inserire dati di diversi anno_esercizio
   -- commentato in quanto anno_esercizio=annoProvvisorio univoco per flusso
   /*if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select count(distinct ric.pagopa_ric_flusso_anno_esercizio) into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if coalesce(codResult,0)>1 then
        	codResult:=-1;
            strErrore:=' Esistenza diversi annoEsercizio su dati riconciliazione.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_10;


            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
	        update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=ric.login_operazione||'-'||loginOperazione
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        else codResult:=null;
        end if;


    end if;*/


   ----- 04.06.2019 SIAC-6720
   ----  qui inserimento in pagopa_t_riconciliazione
   ----  dei dati con pagopa_ric_flusso_flag_dett=true
   ----- forse meglio da servizio java altrimenti ad ogni elaborazione creo diversi record

   -- errore bloccante
   if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ric.pagopa_ric_flusso_anno_esercizio>annoBilancioElab
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza annoEsercizio su dati riconciliazione successivo ad annoBilancio di elab .Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_11;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
            update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--            and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
            and   ric.pagopa_ric_flusso_anno_esercizio>annoBilancioElab
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        end if;


    end if;

    if codResult is null then
    	strMessaggio:='Lettura annoEsercizio su pagopa_t_riconciliazione.';
    	select distinct ric.pagopa_ric_flusso_anno_esercizio into annoBilancio
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null
        limit 1;
        if annoBilancio is  null or AnnoBilancio!=annoBilancioElab then
        	codResult:=-1;
            strErrore:=' Non effettuata .Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_12;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';
            update pagopa_t_riconciliazione ric
    	    set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	       data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='E',
            	   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	        from pagopa_d_riconciliazione_errore err
    	    where ric.file_pagopa_id=filePagoPaId
            and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--            and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        	and   err.ente_proprietario_id=ric.ente_proprietario_id
	        and   err.pagopa_ric_errore_code=pagoPaErrCode
    	    and   ric.data_cancellazione is null
	        and   ric.validita_fine is null;

        end if;
    end if;

    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - controllo dati pagopa_t_riconciliazione - '||strMessaggioFinale;
--    raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
       inPagoPaElabId,
       filepagopaid,
       strMessaggioLog,
	   enteProprietarioId,
       loginOperazione,
       clock_timestamp()
    );

    -- controlli campi obbligatori su pagopa_t_riconciliazione
    -- senza anno_esercizio
    if codResult is null then
    	strMessaggio:='Verifica annoEsercizio su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   coalesce(ric.pagopa_ric_flusso_anno_esercizio,0)=0
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza annoEsercizio.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_12;

           strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
	       and   coalesce(ric.pagopa_ric_flusso_anno_esercizio,0)=0
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;
        end if;
    end if;

    -- senza dati provvisori
    if codResult is null then
    	strMessaggio:='Verifica Provvisori di cassa su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ( coalesce(ric.pagopa_ric_flusso_anno_provvisorio,0)=0  or coalesce(ric.pagopa_ric_flusso_num_provvisorio,0)=0)
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza provvisorio di cassa.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_13;

           strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
           and   ( coalesce(ric.pagopa_ric_flusso_anno_provvisorio,0)=0  or coalesce(ric.pagopa_ric_flusso_num_provvisorio,0)=0)
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;


        end if;
    end if;


    -- senza accertamento
    if codResult is null then
    	strMessaggio:='Verifica Accertamenti su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
        and   ( coalesce(ric.pagopa_ric_flusso_anno_accertamento,0)=0  or coalesce(ric.pagopa_ric_flusso_num_accertamento,0)=0)
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza accertamento.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_14;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--	       and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
           and   ( coalesce(ric.pagopa_ric_flusso_anno_accertamento,0)=0  or coalesce(ric.pagopa_ric_flusso_num_accertamento,0)=0)
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;
        end if;
    end if;

	-- senza voce/sottovoce
    if codResult is null then
    	strMessaggio:='Verifica Voci su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   ( coalesce(ric.pagopa_ric_flusso_voce_code,'')=''  or coalesce(ric.pagopa_ric_flusso_sottovoce_code,'')='')
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza estremi voce/sottovoce.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_15;


            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
           and   ( coalesce(ric.pagopa_ric_flusso_voce_code,'')=''  or coalesce(ric.pagopa_ric_flusso_sottovoce_code,'')='')
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;

        end if;
    end if;

    -- senza importo
    if codResult is null then
    	strMessaggio:='Verifica importi su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
        and   coalesce(ric.pagopa_ric_flusso_sottovoce_importo,0)=0
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione senza importo.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_16;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
           and   coalesce(ric.pagopa_ric_flusso_sottovoce_importo,0)=0
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;

        end if;
    end if;

    -- siac-6720 31.05.2019 controlli
    -- dettaglio senza codice fiscale soggetto
    -- si può valutare di intercettare questo errore gia'' in caricamento di pagopa_t_riconciliazione
    /*if codResult is null then
    	strMessaggio:='Verifica estremi soggetto su dati di dettaglio fatture su pagopa_t_riconciliazione.';
    	select 1 into codResult
        from pagopa_t_riconciliazione ric
        where ric.file_pagopa_id=filePagoPaId
        and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- con dettaglio
        and   ric.pagopa_ric_flusso_flag_dett=true -- dettaglio
        and   coalesce(ric.pagopa_ric_flusso_codfisc_benef,'')=''
        and   ric.data_cancellazione is null
        and   ric.validita_fine is null;
        if codResult is not null then
        	codResult:=-1;
            strErrore:=' Esistenza dati riconciliazione-fatt senza estremi soggetto.Verificare.';
            pagoPaErrCode:=PAGOPA_ERR_41;

            strMessaggio:=strMessaggio||' Aggiornamento PAGOPA_ERR='||pagoPaErrCode||'.';

           update pagopa_t_riconciliazione ric
           set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
         	      data_modifica=clock_timestamp(),
                  pagopa_ric_flusso_stato_elab='E',
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
	       from pagopa_d_riconciliazione_errore err
    	   where ric.file_pagopa_id=filePagoPaId
           and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--           and   ric.pagopa_ric_flusso_flag_con_dett=false -- con dettaglio
	       and   ric.pagopa_ric_flusso_flag_dett=true -- dettaglio
               and   coalesce(ric.pagopa_ric_flusso_codfisc_benef,'')=''
           and   err.ente_proprietario_id=ric.ente_proprietario_id
	       and   err.pagopa_ric_errore_code=pagoPaErrCode
    	   and   ric.data_cancellazione is null
	       and   ric.validita_fine is null;

        end if;
    end if;*/

    -- chiusura siac_t_file_pagopa
    if codResult is not null then
        -- errore bloccante
        strMessaggioBck:=strMessaggio;
        strMessaggio:=' Chiusura siac_t_file_pagopa.';
    	update siac_t_file_pagopa file
        set    data_modifica=clock_timestamp(),
         	   validita_fine=clock_timestamp(),
               file_pagopa_stato_id=stato.file_pagopa_stato_id,
               file_pagopa_errore_id=err.pagopa_ric_errore_id,
               file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
               file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,'  ')||coalesce(strErrore,' ')),
               login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
        from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where file.file_pagopa_id=filePagoPaId
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_ERRATO_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaErrCode;

		-- errore bloccante per elaborazione del filePagoPaId passato per cui si esce ma senza errore bloccante per elaborazione complessiva
        -- pagoPaElabId:=-1;
        -- codiceRisultato:=-1;
        messaggioRisultato:=strMessaggioFinale||strMessaggioBck||strErrore||strMessaggio;
        strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
--        raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
          inPagoPaElabId,
          filepagopaid,
          strMessaggioLog,
          enteProprietarioId,
          loginOperazione,
          clock_timestamp()
        );

        return;
    end if;


    ---------- fine controlli su siac_t_file_pagopa e piano_t_riconciliazione  --------------------------------


    ---------- inizio inserimento pagopa_t_elaborazione -------------------------------
    -- se inPagoPaElabId=0 inizio nuovo idElaborazione
    if coalesce(inPagoPaElabId,0) = 0 then
      codResult:=null;
      strMessaggio:='Inserimento elaborazione PagoPa in stato '||acquisito_st||'.';
      --- inserimento in stato ACQUISITO
      insert into pagopa_t_elaborazione
      (
          pagopa_elab_data,
          pagopa_elab_stato_id,
          pagopa_elab_file_id,
          pagopa_elab_file_ora,
          pagopa_elab_file_ente,
          pagopa_elab_file_fruitore,
          pagopa_elab_note,
         -- file_pagopa_id ,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
             dataelaborazione,
             stato.pagopa_elab_stato_id,
             filepagopaFileXMLId,
             filepagopaFileOra,
             filepagopaFileEnte,
             filepagopaFileFruitore,
             'AVVIO ELABORAZIONE SU FILE file_pagopa_id='||filePagoPaId::varchar||' IN STATO '||ACQUISITO_ST||' ',
           --  filePagoPaId,
             clock_timestamp(),
             loginOperazione,
             stato.ente_proprietario_id
      from pagopa_d_elaborazione_stato stato
      where stato.ente_proprietario_id=enteProprietarioId
      and   stato.pagopa_elab_stato_code=ACQUISITO_ST
      returning pagopa_elab_id into filePagoPaElabId;


      if filePagoPaElabId is null then
          -- bloccante per elaborazione del file ma puo essere rielaborato
          strMessaggioBck:=strMessaggio;
          strMessaggio:=strMessaggio||' Inserimento non effettuato. Aggiornamento siac_t_file_pagopa.';
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,' ')||' Inserimento non effettuato. Aggiornamento siac_t_file_pagopa.'),
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17;


          strMessaggio:=strMessaggioBck||'  Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_17||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from pagopa_d_riconciliazione_errore err
          where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--          and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
          and   err.ente_proprietario_id=ric.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and   ric.data_cancellazione is null
          and   ric.validita_fine is null;

          --pagoPaElabId:=-1;
          codiceRisultato:=0; -- può essere rielaborato
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Inserimento non effettuato.Aggiornamento siac_t_file_pagopa e pagopa_t_riconciliazione.';

		  strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
--          raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
     	     inPagoPaElabId,
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );

          return;

      else
          -- elaborazione in corso
          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
--          raise notice 'strMessaggioLog=% ',strMessaggioLog;

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
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );

/**          -- fare qui modifica per aggiornare solo se non in stato IN_CORSO_ST
          strMessaggioBck:=strMessaggio;
          strMessaggio:=strMessaggio||' Aggiornamento siac_t_file_pagopa.';

          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=(case when statocor.file_pagopa_stato_code not in (ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST) then stato.file_pagopa_stato_id
                                       else  file.file_pagopa_stato_id end ),
                 file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                 login_operazione=file.login_operazione||'-'||loginOperazione
          from siac_d_file_pagopa_stato stato, siac_d_file_pagopa_stato statocor
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ST
          and   statocor.file_pagopa_stato_id=file.file_pagopa_stato_id;
	  */
      end if;
    end if;

    -- elaborazione in corso
    -- fare qui modifica per aggiornare solo se non in stato IN_CORSO_ST
    strMessaggio:='Aggiornamento siac_t_file_pagopa per elaborazione in corso.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=(case when statocor.file_pagopa_stato_code not in (ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST) then stato.file_pagopa_stato_id
                                 else  file.file_pagopa_stato_id end ),
           file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
           file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggio,' ')),
           login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
    from siac_d_file_pagopa_stato stato, siac_d_file_pagopa_stato statocor
    where file.file_pagopa_id=filePagoPaId
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ST
    and   statocor.file_pagopa_stato_id=file.file_pagopa_stato_id;

    -- inserimento pagopa_r_elaborazione_file
    codResult:=null;
    strMessaggio:='Inserimento pagopa_r_elaborazione_file.';
    insert into pagopa_r_elaborazione_file
    (
          pagopa_elab_id,
          file_pagopa_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
	)
    values
    (
        filePagoPaElabId,
        filePagoPaId,
        clock_timestamp(),
        loginOperazione,
        enteProprietarioId
    )
    returning pagopa_r_elab_id into codResult;
    if codResult is null then
    	 -- bloccante per elaborazione, ma il file può essere rielaborato
    	 -- chiusura elaborazione
    	 codResult:=null;
         strMessaggioBck:=strMessaggio;
         strmessaggio:=strMessaggioBck||' Non effettuato. Aggiornamento pagopa_t_elaborazione.';
       	 update pagopa_t_elaborazione elab
         set    data_modifica=clock_timestamp(),
                validita_fine=clock_timestamp(),
                pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
         from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
         where elab.pagopa_elab_id=filePagoPaElabId
          and  stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
          and  stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
          and  statonew.ente_proprietario_id=stato.ente_proprietario_id
          and  statonew.pagopa_elab_stato_code=ELABORATO_ERRATO_ST
          and  err.ente_proprietario_id=stato.ente_proprietario_id
          and  err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and  elab.data_cancellazione is null
          and  elab.validita_fine is null;

          strmessaggio:=strMessaggioBck||' Non effettuato. Aggiornamento siac_t_file_pagopa.';
          -- chiusura file_pagopa
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,pagopa.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strmessaggio,' ')),
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_17;


		  strMessaggio:=strMessaggioBck||' Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_17||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from pagopa_d_riconciliazione_errore err
      	  where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--          and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
          and   err.ente_proprietario_id=ric.ente_proprietario_id
	      and   err.pagopa_ric_errore_code=PAGOPA_ERR_17
          and   ric.data_cancellazione is null
  	      and   ric.validita_fine is null;


          outPagoPaElabId:=filePagoPaElabId;
          codiceRisultato:=0;
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Inserimento non effettuato.';
          strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
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
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );
         return;
    end if;


	-- controllo su annoBilancio
    strMessaggio:='Verifica stato annoBilancio di elaborazione='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per, siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
    where fase.ente_proprietario_id=enteProprietarioid
    and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST)
    and   per.ente_proprietario_id=fase.ente_proprietario_id
    and   per.anno::integer=annoBilancio
    and   bil.periodo_id=per.periodo_id
    and   r.fase_operativa_id=fase.fase_operativa_id
    and   r.bil_id=r.bil_id;

    if bilancioId is null then
         -- bloccante per elaborazione, ma il file può essere rielaborato
    	 -- chiusura elaborazione
    	 codResult:=null;
         strMessaggioBck:=strMessaggio;
         strmessaggio:=strMessaggioBck||' Fase non valida. Aggiornamento pagopa_t_elaborazione.';
       	 update pagopa_t_elaborazione elab
         set    data_modifica=clock_timestamp(),
                validita_fine=clock_timestamp(),
                pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggioBck||'Fase bilancio non valida.')
         from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
         where elab.pagopa_elab_id=filePagoPaElabId
          and  stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
          and  stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
          and  statonew.ente_proprietario_id=stato.ente_proprietario_id
          and  statonew.pagopa_elab_stato_code=ELABORATO_ERRATO_ST
          and  err.ente_proprietario_id=stato.ente_proprietario_id
          and  err.pagopa_ric_errore_code=PAGOPA_ERR_18
          and  elab.data_cancellazione is null
          and  elab.validita_fine is null;

          strMessaggio:=strMessaggioBck;
          strmessaggio:=strMessaggioBck||' Fase non valida. Aggiornamento siac_t_file_pagopa.';
          -- chiusura file_pagopa
          update siac_t_file_pagopa file
          set    data_modifica=clock_timestamp(),
                 file_pagopa_stato_id=stato.file_pagopa_stato_id,
                 file_pagopa_errore_id=err.pagopa_ric_errore_id,
                 file_pagopa_code=coalesce(filepagopaFileXMLId,pagopa.file_pagopa_code),
                 file_pagopa_note=upper(coalesce(strMessaggioFinale,' ' )||coalesce(strMessaggioBck,' ')||' Fase bilancio non valida.'),
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
          where file.file_pagopa_id=filePagoPaId
          and   stato.ente_proprietario_id=file.ente_proprietario_id
          and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
          and   err.ente_proprietario_id=stato.ente_proprietario_id
          and   err.pagopa_ric_errore_code=PAGOPA_ERR_18;


		  strMessaggio:=strMessaggioBck||'  Inserimento non effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_18||'.';

          update pagopa_t_riconciliazione ric
          set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                 data_modifica=clock_timestamp(),
                 pagopa_ric_flusso_stato_elab='X',
                 login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
          from pagopa_d_riconciliazione_errore err
      	  where ric.file_pagopa_id=filePagoPaId
          and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--          and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
          and   err.ente_proprietario_id=ric.ente_proprietario_id
	      and   err.pagopa_ric_errore_code=PAGOPA_ERR_18
          and   ric.data_cancellazione is null
  	      and   ric.validita_fine is null;


          outPagoPaElabId:=filePagoPaElabId;
          codiceRisultato:=0; -- il file puo essere rielaborato
          messaggioRisultato:=strMessaggioFinale||strMessaggioBck||' Fase bilancio non valida.';

          strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
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
        	 filepagopaid,
	         strMessaggioLog,
    	     enteProprietarioId,
	         loginOperazione,
             clock_timestamp()
    	  );
         return;
    end if;


    codResult:=null;
    ---------- fine inserimento pagopa_t_elaborazione --------------------------------

    ---------- inizio gestione flussi su piano_t_riconciliazione per pagopa_elab_id ----------------


    -- per file_pagopa_id, file_pagopa_id ( XML )
    -- distinct su pagopa_t_riconciliazione su file_pagopa_id, file_pagopa_id ( XML ) pagopa_flusso_id ( XML )
    -- per cui non esiste corrispondenza su
    --   pagopa_t_riconciliazione_doc con subdoc_id valorizzato
    --   pagopa_t_riconciliazione_doc con subdoc_id non valorizzato e errore bloccante
    --   pagopa_t_riconciliazione con errore bloccante
    strMessaggio:='Inserimento dati per elaborazione flussi.Inizio ciclo.';
    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
       filepagopaid,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
    );

    for pagoPaFlussoRec in
    (
    select distinct ric.pagopa_ric_file_id pagopa_file_id,
                    ric.pagopa_ric_flusso_id pagopa_flusso_id,
                    ric.pagopa_ric_flusso_anno_provvisorio pagopa_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio pagopa_num_provvisorio
    from pagopa_t_riconciliazione ric
    where ric.file_pagopa_id=filePagoPaId
    and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
    /*and   not exists
    ( select 1
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_ric_id=ric.pagopa_ric_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
    )*/
   /* and   not exists
    ( select 1
      from pagopa_t_riconciliazione_doc doc
      where doc.pagopa_ric_id=ric.pagopa_ric_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_stato_elab in ('E')
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
    )*/
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null
    order by        ric.pagopa_ric_flusso_anno_provvisorio,
					ric.pagopa_ric_flusso_num_provvisorio
    )
    loop

        codResult:=null;
	    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.';

        strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );


	    --   inserimento in pagopa_t_elaborazione_flusso

        pagoPaFlussoAnnoEsercizio :=null;
	    pagoPaFlussoNomeMittente  :=null;
	    pagoPaFlussoData  :=null;
    	pagoPaFlussoTotPagam  :=null;
        codResult:=null;
        strNote:=null;
        pagopaElabFlussoId:=null;

        strMessaggio:=strmessaggio||' Ricava dati.';
		select ric.pagopa_ric_flusso_anno_esercizio,
    	       ric.pagopa_ric_flusso_nome_mittente,
 	    	   ric.pagopa_ric_flusso_data::varchar,
			   ric.pagopa_ric_flusso_tot_pagam,
               ric.pagopa_ric_id
    	       into
        	   pagoPaFlussoAnnoEsercizio,
	           pagoPaFlussoNomeMittente,
    	       pagoPaFlussoData,
	       	   pagoPaFlussoTotPagam,
               codResult
	    from pagopa_t_riconciliazione ric
	    where ric.file_pagopa_id=filePagoPaId
    	and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--        and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
	    and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
    	and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
		and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
        /*and   not exists
	    ( select 1
    	  from pagopa_t_riconciliazione_doc doc
	      where doc.pagopa_ric_id=ric.pagopa_ric_id
    	  and   doc.pagopa_ric_doc_subdoc_id is not null
	      and   doc.data_cancellazione is null
    	  and   doc.validita_fine is null
	    )*/
    	/*and   not exists
	    ( select 1
    	  from pagopa_t_riconciliazione_doc doc
	      where doc.pagopa_ric_id=ric.pagopa_ric_id
    	  and   doc.pagopa_ric_doc_subdoc_id is null
	      and   doc.pagopa_ric_doc_stato_elab in ('E')
    	  and  doc.data_cancellazione is null
	      and   doc.validita_fine is null
	    )*/
    	and   ric.data_cancellazione is null
	    and   ric.validita_fine is null
    	limit 1;

		if  codResult is null then
        	strNote:='Dati testata mancanti.';
        end if;

	    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Inserimento pagopa_t_elaborazione_flusso.';

	    insert into pagopa_t_elaborazione_flusso
    	(
    	 pagopa_elab_flusso_data,
	     pagopa_elab_flusso_stato_id,
		 pagopa_elab_flusso_note,
		 pagopa_elab_ric_flusso_id,
		 pagopa_elab_flusso_nome_mittente,
		 pagopa_elab_ric_flusso_data,
	     pagopa_elab_flusso_tot_pagam,
	     pagopa_elab_flusso_anno_esercizio,
	     pagopa_elab_flusso_anno_provvisorio,
	     pagopa_elab_flusso_num_provvisorio,
		 pagopa_elab_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
	    )
    	select dataElaborazione,
        	   stato.pagopa_elab_stato_id,
	           'AVVIO ELABORAZIONE FILE file_pagopa_id='||filePagoPaId::varchar||
               upper(' FLUSSO_ID='||pagoPaFlussoRec.pagopa_flusso_id||' IN STATO '||ACQUISITO_ST||' '||
               coalesce(strNote,' ')),
               pagoPaFlussoRec.pagopa_flusso_id,
   	           pagoPaFlussoNomeMittente,
			   pagoPaFlussoData,
               pagoPaFlussoTotPagam,
               pagoPaFlussoAnnoEsercizio,
               pagoPaFlussoRec.pagopa_anno_provvisorio,
               pagoPaFlussoRec.pagopa_num_provvisorio,
               filePagoPaElabId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
    	from pagopa_d_elaborazione_stato stato
	    where stato.ente_proprietario_id=enteProprietarioId
    	and   stato.pagopa_elab_stato_code=ACQUISITO_ST
        returning pagopa_elab_flusso_id into pagopaElabFlussoId;

        codResult:=null;
        if pagopaElabFlussoId is null then
            strMessaggioBck:=strMessaggio;
            strmessaggio:=strMessaggioBck||' NON Effettuato. Aggiornamento pagopa_t_elaborazione.';
        	update pagopa_t_elaborazione elab
            set    data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
            where elab.pagopa_elab_id=filePagoPaElabId
            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
            and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            and   statonew.ente_proprietario_id=stato.ente_proprietario_id
            and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_19
            and   elab.data_cancellazione is null
            and   elab.validita_fine is null;

             strMessaggio:=strMessaggioBck||' NON effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_19||'.';
             update pagopa_t_riconciliazione ric
             set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                    data_modifica=clock_timestamp(),
                    pagopa_ric_flusso_stato_elab='X',
                    login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
             from pagopa_d_riconciliazione_errore err
             where ric.file_pagopa_id=filePagoPaId
             and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--             and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
             and   err.ente_proprietario_id=ric.ente_proprietario_id
             and   err.pagopa_ric_errore_code=PAGOPA_ERR_19
             and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
             and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
             and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
             /*and   not exists
             ( select 1
               from pagopa_t_riconciliazione_doc doc
               where doc.pagopa_ric_id=ric.pagopa_ric_id
               and   doc.pagopa_ric_doc_subdoc_id is not null
               and   doc.data_cancellazione is null
               and   doc.validita_fine is null
             )*/
             /*and   not exists
             ( select 1
               from pagopa_t_riconciliazione_doc doc
               where doc.pagopa_ric_id=ric.pagopa_ric_id
               and   doc.pagopa_ric_doc_subdoc_id is null
               and   doc.pagopa_ric_doc_stato_elab in ('E')
               and   doc.data_cancellazione is null
               and   doc.validita_fine is null
             )*/
             and   ric.data_cancellazione is null
             and   ric.validita_fine is null;

            codResult:=-1;
            pagoPaErrCode:=PAGOPA_ERR_19;

        end if;

        if  pagopaElabFlussoId is not null then
         strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                        pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                        pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                        pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                        ' Inserimento pagopa_t_riconciliazione_doc.';
		 --   inserimento in pagopa_t_riconciliazione_doc
         insert into pagopa_t_riconciliazione_doc
         (
        	pagopa_ric_doc_data,
            pagopa_ric_doc_voce_tematica,
  	        pagopa_ric_doc_voce_code,
			pagopa_ric_doc_voce_desc,
			pagopa_ric_doc_sottovoce_code,
		    pagopa_ric_doc_sottovoce_desc,
			pagopa_ric_doc_sottovoce_importo,
		    pagopa_ric_doc_anno_esercizio,
		    pagopa_ric_doc_anno_accertamento,
			pagopa_ric_doc_num_accertamento,
		    pagopa_ric_doc_num_capitolo,
		    pagopa_ric_doc_num_articolo,
		    pagopa_ric_doc_pdc_v_fin,
		    pagopa_ric_doc_titolo,
		    pagopa_ric_doc_tipologia,
		    pagopa_ric_doc_categoria,
		    pagopa_ric_doc_str_amm,
            --- 31.05.2019 siac-6720
		    pagopa_ric_doc_codice_benef,
            pagopa_ric_doc_ragsoc_benef,
            pagopa_ric_doc_nome_benef,
            pagopa_ric_doc_cognome_benef,
            pagopa_ric_doc_codfisc_benef,
        --    pagopa_ric_doc_flag_dett,
            --- 31.05.2019 siac-6720
            pagopa_ric_id,
	        pagopa_elab_flusso_id,
            file_pagopa_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select dataElaborazione,
                ric.pagopa_ric_flusso_tematica,
                ric.pagopa_ric_flusso_voce_code,
                ric.pagopa_ric_flusso_voce_desc,
                ric.pagopa_ric_flusso_sottovoce_code,
                ric.pagopa_ric_flusso_sottovoce_desc,
                ric.pagopa_ric_flusso_sottovoce_importo,
                ric.pagopa_ric_flusso_anno_esercizio,
                ric.pagopa_ric_flusso_anno_accertamento,
                ric.pagopa_ric_flusso_num_accertamento,
                ric.pagopa_ric_flusso_num_capitolo,
                ric.pagopa_ric_flusso_num_articolo,
                ric.pagopa_ric_flusso_pdc_v_fin,
                ric.pagopa_ric_flusso_titolo,
                ric.pagopa_ric_flusso_tipologia,
                ric.pagopa_ric_flusso_categoria,
                ric.pagopa_ric_flusso_str_amm,
                -- 31.05.2019 siac-6720
				ric.pagopa_ric_flusso_codice_benef,
                ric.pagopa_ric_flusso_ragsoc_benef,
           	    ric.pagopa_ric_flusso_nome_benef,
                ric.pagopa_ric_flusso_cognome_benef,
                ric.pagopa_ric_flusso_codfisc_benef,
              --  ric.pagopa_ric_flusso_flag_dett,
                -- 31.05.2019 siac-6720
                ric.pagopa_ric_id,
                pagopaElabFlussoId,
                filePagoPaId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         from pagopa_t_riconciliazione ric
         where ric.file_pagopa_id=filePagoPaId
    	 and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--         and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
	     and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
    	 and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
		 and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
         /*and   not exists
    	 ( select 1
	       from pagopa_t_riconciliazione_doc doc
    	   where doc.pagopa_ric_id=ric.pagopa_ric_id
	       and   doc.pagopa_ric_doc_subdoc_id is not null
    	   and   doc.data_cancellazione is null
	       and   doc.validita_fine is null
    	 )*/
	     /*and   not exists
	     ( select 1
    	   from pagopa_t_riconciliazione_doc doc
	       where doc.pagopa_ric_id=ric.pagopa_ric_id
      	   and   doc.pagopa_ric_doc_subdoc_id is null
	       and   doc.pagopa_ric_doc_stato_elab in ('E')
    	   and   doc.data_cancellazione is null
	       and   doc.validita_fine is null
    	 )*/
    	 and   ric.data_cancellazione is null
	     and   ric.validita_fine is null;

         strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica inserimento pagopa_t_riconciliazione_doc.';
         -- controllo inserimento
		 codResult:=null;
         select 1 into codResult
         from pagopa_t_riconciliazione_doc doc
         where doc.pagopa_elab_flusso_id=pagopaElabFlussoId;
         if codResult is null then
             strMessaggioBck:=strMessaggio;
             strmessaggio:=strMessaggioBck||'. NON Effettuato. Aggiornamento pagopa_t_elaborazione.';
          	 update pagopa_t_elaborazione elab
             set   data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
             from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
             where elab.pagopa_elab_id=filePagoPaElabId
             and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
             and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
             and   statonew.ente_proprietario_id=stato.ente_proprietario_id
             and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
             and   err.ente_proprietario_id=stato.ente_proprietario_id
             and   err.pagopa_ric_errore_code=PAGOPA_ERR_21
             and   elab.data_cancellazione is null
             and   elab.validita_fine is null;


             codResult:=-1;
             pagoPaErrCode:=PAGOPA_ERR_21;

             strMessaggio:=strMessaggioBck||' NON effettuato.Aggiornamento PAGOPA_ERR='||PAGOPA_ERR_19||'.';
			 update pagopa_t_riconciliazione ric
    	     set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	        data_modifica=clock_timestamp(),
            	    pagopa_ric_flusso_stato_elab='X',
                	login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	         from pagopa_d_riconciliazione_errore err
    	     where ric.file_pagopa_id=filePagoPaId
    		 and   ric.pagopa_ric_flusso_stato_elab not in ('S','E')
--             and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
	         and   err.ente_proprietario_id=ric.ente_proprietario_id
    	     and   err.pagopa_ric_errore_code=PAGOPA_ERR_21
	    	 and   ric.pagopa_ric_flusso_id= pagoPaFlussoRec.pagopa_flusso_id
	    	 and   ric.pagopa_ric_flusso_anno_provvisorio=pagoPaFlussoRec.pagopa_anno_provvisorio
			 and   ric.pagopa_ric_flusso_num_provvisorio=pagoPaFlussoRec.pagopa_num_provvisorio
        	 /*and   not exists
	    	 ( select 1
		       from pagopa_t_riconciliazione_doc doc
    		   where doc.pagopa_ric_id=ric.pagopa_ric_id
		       and   doc.pagopa_ric_doc_subdoc_id is not null
    		   and   doc.data_cancellazione is null
	    	   and   doc.validita_fine is null
	    	 )*/
		     /*and   not exists
	    	 ( select 1
	    	   from pagopa_t_riconciliazione_doc doc
		       where doc.pagopa_ric_id=ric.pagopa_ric_id
      		   and   doc.pagopa_ric_doc_subdoc_id is null
		       and   doc.pagopa_ric_doc_stato_elab in ('E')
    		   and   doc.data_cancellazione is null
	    	   and   doc.validita_fine is null
	    	 )*/
    		 and   ric.data_cancellazione is null
	    	 and   ric.validita_fine is null;


         else
         	codResult:=null;
            strMessaggio:=strMessaggio||' Inserimento effettuato.';
         end if;
		end if;

	    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

        -- controllo dati su
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        if codResult is null then
        	-- esistenza provvisorio di cassa
            strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa.';
/*            select 1 into codResult
            from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
            where  tipo.ente_proprietario_id=enteProprietarioid
            and    tipo.provc_tipo_code='E'
            and    prov.provc_tipo_id=tipo.provc_tipo_id
            and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
            and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
            and    prov.provc_data_annullamento is null
            and    prov.provc_data_regolarizzazione is null
            and    prov.data_cancellazione  is null
			and    prov.validita_fine is null;
			23.06.2021 Sofia Jira SIAC-8221 */
            select 1 into codResult
            from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
            where  tipo.ente_proprietario_id=enteProprietarioid
            and    tipo.provc_tipo_code='E'
            and    prov.provc_tipo_id=tipo.provc_tipo_id
            and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
            and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
            and    prov.data_cancellazione  is null
			and    prov.validita_fine is null;          
		    if codResult is null then
            	pagoPaErrCode:=PAGOPA_ERR_22;
                codResult:=-1;
            else 
               codResult:=null;
               strMessaggio:=strMessaggio||' Annullato o Regolarizzato.';
               -- 23.06.2021 Sofia Jira SIAC-8221
               SELECT 1 INTO codResult
               from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
	           where  tipo.ente_proprietario_id=enteProprietarioid
    	       and    tipo.provc_tipo_code='E'
        	   and    prov.provc_tipo_id=tipo.provc_tipo_id
               and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
               and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
               AND   
               ( 
                      prov.provc_data_annullamento is NOT NULL OR prov.provc_data_regolarizzazione is NOT null
               )
               and    prov.data_cancellazione  is null
			   and    prov.validita_fine is null;
 			   if codResult is NOT null then
            	pagoPaErrCode:=PAGOPA_ERR_52;
                codResult:=-1;
               END IF; 
            end if;
            
            if codResult is null then
            	strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa regolarizzato [Ord.].';
                select 1 into codResult
                from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo,siac_r_ordinativo_prov_cassa rp
                where  tipo.ente_proprietario_id=enteProprietarioid
                and    tipo.provc_tipo_code='E'
                and    prov.provc_tipo_id=tipo.provc_tipo_id
                and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
                and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
                and    rp.provc_id=prov.provc_id
                and    prov.provc_data_annullamento is null
                and    prov.provc_data_regolarizzazione is null
                and    prov.data_cancellazione  is null
                and    prov.validita_fine is null
                and    rp.data_cancellazione  is null
                and    rp.validita_fine is null;
                if codResult is null then
                    strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza provvisorio di cassa regolarizzato [Doc.].';
                	select 1 into codResult
                    from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo,siac_r_subdoc_prov_cassa rp
                    where  tipo.ente_proprietario_id=enteProprietarioid
                    and    tipo.provc_tipo_code='E'
                    and    prov.provc_tipo_id=tipo.provc_tipo_id
                    and    prov.provc_anno::integer=pagoPaFlussoRec.pagopa_anno_provvisorio
                    and    prov.provc_numero::integer=pagoPaFlussoRec.pagopa_num_provvisorio
                    and    rp.provc_id=prov.provc_id
                    and    prov.provc_data_annullamento is null
                    and    prov.provc_data_regolarizzazione is null
                    and    prov.data_cancellazione  is null
                    and    prov.validita_fine is null
                    and    rp.data_cancellazione  is null
                    and    rp.validita_fine is null;
                end if;
                if codResult is not null then
                	pagoPaErrCode:=PAGOPA_ERR_38;
	                codResult:=-1;
                end if;
            end if;

            if pagoPaErrCode is not null then
              strMessaggioBck:=strMessaggio;
              strmessaggio:=strMessaggio||' NON esistente o regolarizzato. Aggiornamento pagopa_t_elaborazione.';
              update pagopa_t_elaborazione elab
              set    data_modifica=clock_timestamp(),
                     pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                     pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                     pagopa_elab_note=upper(strMessaggioFinale||' '||strMessaggio)
              from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
              where elab.pagopa_elab_id=filePagoPaElabId
              and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
              and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
              and   statonew.ente_proprietario_id=stato.ente_proprietario_id
              and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
              and   err.ente_proprietario_id=stato.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   elab.data_cancellazione is null
              and   elab.validita_fine is null;

              codResult:=-1;


              strMessaggio:=strMessaggioBck||' NON esistente o regolarizzato.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||pagoPaErrCode||'.';
              update pagopa_t_riconciliazione_doc doc
              set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                     data_modifica=clock_timestamp(),
                     pagopa_ric_doc_stato_elab='X',
                     login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
              from pagopa_d_riconciliazione_errore err
              where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
              and   err.ente_proprietario_id=doc.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   doc.data_cancellazione is null
              and   doc.validita_fine is null;


              strMessaggio:=strMessaggioBck||' NON esistente o regolarizzato.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||pagoPaErrCode||'.';
              update pagopa_t_riconciliazione ric
              set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                     data_modifica=clock_timestamp(),
                     pagopa_ric_flusso_stato_elab='X',
                     login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
              from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
              where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
              and   ric.pagopa_ric_id=doc.pagopa_ric_id
              and   err.ente_proprietario_id=doc.ente_proprietario_id
              and   err.pagopa_ric_errore_code=pagoPaErrCode
              and   doc.data_cancellazione is null
              and   doc.validita_fine is null
              and   ric.data_cancellazione is null
              and   ric.validita_fine is null;
            else codResult:=null;
            end if;

            -- esistenza accertamento
            if codResult is null then
                strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Verifica esistenza accertamenti.';
            	select 1 into codResult
                from pagopa_t_riconciliazione_doc doc
                where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
                and   not exists
                (
                select 1
				from siac_t_movgest mov, siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                     siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
                where   mov.bil_id=bilancioId
                and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
                and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
                and   tipo.movgest_tipo_id=mov.movgest_tipo_id
                and   tipo.movgest_tipo_code='A'
                and   ts.movgest_id=mov.movgest_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   tipots.movgest_ts_tipo_code='T'
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   stato.movgest_stato_id=rs.movgest_stato_id
				and   stato.movgest_stato_code='D'
                and   rs.data_cancellazione is null
                and   rs.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                );

				if codResult is not null then
             		strMessaggioBck:=strMessaggio;
		            strmessaggio:=strMessaggio||' NON esistente. Aggiornamento pagopa_t_elaborazione.';
		          	update pagopa_t_elaborazione elab
		            set    data_modifica=clock_timestamp(),
    	                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                           pagopa_elab_errore_id=err.pagopa_ric_errore_id,
        	               pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            		from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
	                where elab.pagopa_elab_id=filePagoPaElabId
    	            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
        	        and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            	    and   statonew.ente_proprietario_id=stato.ente_proprietario_id
	                and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
                    and   err.ente_proprietario_id=stato.ente_proprietario_id
                    and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    	            and   elab.data_cancellazione is null
        	        and   elab.validita_fine is null;

					pagoPaErrCode:=PAGOPA_ERR_23;
		            codResult:=-1;

                    strMessaggio:=strMessaggioBck||' NON esistente.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||PAGOPA_ERR_23||'.';
			     	update pagopa_t_riconciliazione_doc doc
	     	        set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
    	    	           data_modifica=clock_timestamp(),
        	      	       pagopa_ric_doc_stato_elab='X',
                 		   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	                from pagopa_d_riconciliazione_errore err
    	            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
                    -- 24.05.2021 Sofia Jira-SIAC-8213 - inizio
                    and   not exists
                    (
                    select 1
                    from siac_t_movgest mov, siac_d_movgest_tipo tipo,
                         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                         siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
                    where   mov.bil_id=bilancioId
                    and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
                    and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
                    and   tipo.movgest_tipo_id=mov.movgest_tipo_id
                    and   tipo.movgest_tipo_code='A'
                    and   ts.movgest_id=mov.movgest_id
                    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                    and   tipots.movgest_ts_tipo_code='T'
                    and   rs.movgest_ts_id=ts.movgest_ts_id
                    and   stato.movgest_stato_id=rs.movgest_stato_id
					and   stato.movgest_stato_code='D' 
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   mov.data_cancellazione is null
                    and   mov.validita_fine is null
                    and   ts.data_cancellazione is null
                    and   ts.validita_fine is null
                    )
                    -- 24.05.2021 Sofia Jira-SIAC-8213 - fine
	                and   err.ente_proprietario_id=doc.ente_proprietario_id
     	            and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    		        and   doc.data_cancellazione is null
	    	        and   doc.validita_fine is null;


            	    strMessaggio:=strMessaggioBck||' NON esistente.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||PAGOPA_ERR_23||'.';
			        update pagopa_t_riconciliazione ric
     	            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	               data_modifica=clock_timestamp(),
              	           pagopa_ric_flusso_stato_elab='X',
                 	       login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
	                from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
    	            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
                    -- 24.05.2021 Sofia Jira-SIAC-8213 - inizio
                    and   not exists
                    (
                    select 1
                    from siac_t_movgest mov, siac_d_movgest_tipo tipo,
                         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                         siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
                    where   mov.bil_id=bilancioId
                    and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
                    and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
                    and   tipo.movgest_tipo_id=mov.movgest_tipo_id
                    and   tipo.movgest_tipo_code='A'
                    and   ts.movgest_id=mov.movgest_id
                    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                    and   tipots.movgest_ts_tipo_code='T'
                    and   rs.movgest_ts_id=ts.movgest_ts_id
                    and   stato.movgest_stato_id=rs.movgest_stato_id
            --        and   stato.movgest_stato_code='D' -- 07.07.2021 Sofia Jira SIAC-8221
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   mov.data_cancellazione is null
                    and   mov.validita_fine is null
                    and   ts.data_cancellazione is null
                    and   ts.validita_fine is null
                    )
                    -- 24.05.2021 Sofia Jira-SIAC-8213 - inizio
                    and   ric.pagopa_ric_id=doc.pagopa_ric_id
	                and   err.ente_proprietario_id=doc.ente_proprietario_id
     	            and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    		        and   doc.data_cancellazione is null
	    	        and   doc.validita_fine is null
                    and   ric.data_cancellazione is null
	    	        and   ric.validita_fine is null;
        	    end if;
            end if;
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

        --- siac-6720 - 23.05.2019
        --  pagopa_t_riconciliazione_doc con il tipo di documento da creare
        --  trattare gli errori come sopra per accertamento non esistente
        --  se arrivo qui vuol dire che non ci sono errori e tutti i record
        --  non scartati hanno accertamento
        if codResult is null then
          strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
	                     pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
    	                 pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
        	             pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                         ' Aggiornamento tipo documento.';
          /*
          update pagopa_t_riconciliazione_doc doc
          set    pagopa_ric_doc_tipo_code=tipod.doc_tipo_code,
                 pagopa_ric_doc_tipo_id=tipod.doc_tipo_id
          from   siac_t_movgest mov, siac_d_movgest_tipo tipo,
                 siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                 siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato,
                 siac_d_doc_tipo tipod
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   mov.bil_id=bilancioId
          and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
          and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
          and   tipo.movgest_tipo_id=mov.movgest_tipo_id
          and   tipo.movgest_tipo_code='A'
          and   ts.movgest_id=mov.movgest_id
          and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
          and   tipots.movgest_ts_tipo_code='T'
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   stato.movgest_stato_id=rs.movgest_stato_id
          and   stato.movgest_stato_code='D'
          and   tipod.ente_proprietario_id=tipo.ente_proprietario_id
          and   ( case  when ts.movgest_ts_prev_fatt=true then tipod.doc_tipo_id=docTipoFatId
          				when ts.movgest_ts_prev_cor=true  then tipod.doc_tipo_id=docTipoCorId
                        else tipod.doc_tipo_id=docTipoIpaId end)
          and   rs.data_cancellazione is null
          and   rs.validita_fine is null
          and   mov.data_cancellazione is null
          and   mov.validita_fine is null
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null;*/


          update pagopa_t_riconciliazione_doc doc
          set    pagopa_ric_doc_tipo_code=tipod.doc_tipo_code,
                 pagopa_ric_doc_tipo_id=tipod.doc_tipo_id,
                 pagopa_ric_doc_flag_con_dett= (case when tipod.doc_tipo_id =docTipoFatId then true else false end )
          from
          (
          with
          accertamento as
          (
          select mov.movgest_anno::integer anno_accertamento,mov.movgest_numero::integer numero_accertamento  ,
                 ts.movgest_ts_id
          from  siac_t_movgest mov, siac_d_movgest_tipo tipo,
                siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                siac_r_movgest_ts_stato rs , siac_d_movgest_stato stato
          where mov.bil_id=bilancioId
          and   tipo.movgest_tipo_id=mov.movgest_tipo_id
          and   tipo.movgest_tipo_code='A'
          and   ts.movgest_id=mov.movgest_id
          and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
          and   tipots.movgest_ts_tipo_code='T'
          and   rs.movgest_ts_id=ts.movgest_ts_id
          and   stato.movgest_stato_id=rs.movgest_stato_id
          and   stato.movgest_stato_code='D'
          and   rs.data_cancellazione is null
          and   rs.validita_fine is null
          and   mov.data_cancellazione is null
          and   mov.validita_fine is null
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          ),
          -- FlagCollegamentoAccertamentoFattura
          acc_fattura as
          (
          select rattr.movgest_ts_id, coalesce(rattr.boolean,'N') fl_fatt
          from siac_r_movgest_ts_Attr rattr
          where rattr.ente_proprietario_id=enteProprietarioId
          and   rattr.attr_id=attrAccFatturaId
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null
          ),
          --FlagCollegamentoAccertamentoCorrispettivo
          acc_corrispettivo as
          (
          select rattr.movgest_ts_id,coalesce(rattr.boolean,'N') fl_corr
          from siac_r_movgest_ts_Attr rattr
          where rattr.ente_proprietario_id=enteProprietarioId
          and   rattr.attr_id=attrAccCorrispettivoId
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null
          )
          select accertamento.movgest_ts_id,accertamento.anno_accertamento, accertamento.numero_accertamento,
                 (case when coalesce(acc_fattura.fl_fatt,'N')='S' then docTipoFatId
                      when coalesce(acc_corrispettivo.fl_corr,'N')='S' then docTipoCorId
                      else docTipoIpaId end) doc_tipo_id
          from accertamento
               left join acc_fattura on ( accertamento.movgest_ts_id=acc_fattura.movgest_ts_id )
               left join acc_corrispettivo on ( accertamento.movgest_ts_id=acc_corrispettivo.movgest_ts_id )
          ) query,siac_d_doc_tipo tipod
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   query.anno_accertamento=doc.pagopa_ric_doc_anno_accertamento
          and   query.numero_accertamento=doc.pagopa_ric_doc_num_accertamento
          and   tipod.doc_tipo_id=query.doc_tipo_id;

          strMessaggio:=strMessaggio||' Dati NON aggiornati ';
		  select 1 into codResult
		  from pagopa_t_riconciliazione_doc doc
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   ( coalesce(doc.pagopa_ric_doc_tipo_code,'')='' or doc.pagopa_ric_doc_tipo_id is null);

          if codResult is not null then
            strMessaggioBck:=strMessaggio;
            strmessaggio:=strMessaggio||'  esistenti. Aggiornamento pagopa_t_elaborazione.';
            update pagopa_t_elaborazione elab
            set    data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
            where elab.pagopa_elab_id=filePagoPaElabId
            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
            and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            and   statonew.ente_proprietario_id=stato.ente_proprietario_id
            and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_48
            and   elab.data_cancellazione is null
            and   elab.validita_fine is null;

            pagoPaErrCode:=PAGOPA_ERR_48;
            codResult:=-1;

            strMessaggio:=strMessaggioBck||' esistenti.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||PAGOPA_ERR_48||'.';
            update pagopa_t_riconciliazione_doc doc
            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                   data_modifica=clock_timestamp(),
                   pagopa_ric_doc_stato_elab='X',
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from pagopa_d_riconciliazione_errore err
            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
            and   err.ente_proprietario_id=doc.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_48
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null;


            strMessaggio:=strMessaggioBck||' esistenti.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||PAGOPA_ERR_48||'.';
            update pagopa_t_riconciliazione ric
            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                   data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='X',
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
            and   ric.pagopa_ric_id=doc.pagopa_ric_id
            and   err.ente_proprietario_id=doc.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_48
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null
            and   ric.data_cancellazione is null
            and   ric.validita_fine is null;
          end if;


          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
             filepagopaid,
             strMessaggioLog,
             enteProprietarioId,
             loginOperazione,
             clock_timestamp()
          );
        end if;

		if codResult is null then
          --- inserire qui i dettagli ( pagopa_ric_doc_flag_dett=true) prendendoli da  tabella in più di Ale
          --- considerando quelli che hanno il tipo_code=FAT, pagopa_ric_doc_flag_con_dett=true da update sopra
          --- inserire in pagopa_t_riconciliazione_doc con pagopa_ric_doc_flag_dett=true
          --- in esegui devo poi esclure i pagopa_t_riconciliazione_doc.pagopa_ric_doc_flag_con_dett=true


		  strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
	                     pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
    	                 pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
        	             pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                         ' Inserimento pagopa_t_riconciliazione_doc -  dati di dettaglio.';
          insert into pagopa_t_riconciliazione_doc
          (
            pagopa_ric_doc_data,
            pagopa_ric_doc_voce_tematica,
  	        pagopa_ric_doc_voce_code,
			pagopa_ric_doc_voce_desc,
			pagopa_ric_doc_sottovoce_code,
		    pagopa_ric_doc_sottovoce_desc,
			pagopa_ric_doc_sottovoce_importo,
		    pagopa_ric_doc_anno_esercizio,
		    pagopa_ric_doc_anno_accertamento,
			pagopa_ric_doc_num_accertamento,
		    pagopa_ric_doc_num_capitolo,
		    pagopa_ric_doc_num_articolo,
		    pagopa_ric_doc_pdc_v_fin,
		    pagopa_ric_doc_titolo,
		    pagopa_ric_doc_tipologia,
		    pagopa_ric_doc_categoria,
		    pagopa_ric_doc_str_amm,
            pagopa_ric_doc_flag_dett,
            pagopa_ric_doc_tipo_code,
            pagopa_ric_doc_tipo_id,
		    pagopa_ric_doc_codice_benef,
            pagopa_ric_doc_ragsoc_benef,
            pagopa_ric_doc_nome_benef,
            pagopa_ric_doc_cognome_benef,
            pagopa_ric_doc_codfisc_benef,
            pagopa_ric_id,
            pagopa_ric_det_id,
	        pagopa_elab_flusso_id,
            pagopa_ric_doc_iuv, --- 12.08.2019 Sofia SIAC-6978,
            pagopa_ric_doc_data_operazione, -- 04.02.2020 Sofia SIAC-7375
            file_pagopa_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
          )
          select dataElaborazione,
	             doc.pagopa_ric_doc_voce_tematica,
	    	     doc.pagopa_ric_doc_voce_code,
	 			 doc.pagopa_ric_doc_voce_desc,
	  			 doc.pagopa_ric_doc_sottovoce_code,
	 		     doc.pagopa_ric_doc_sottovoce_desc,
	 			 det.pagopa_det_importo_versamento,
                 doc.pagopa_ric_doc_anno_esercizio,
                 doc.pagopa_ric_doc_anno_accertamento,
                 doc.pagopa_ric_doc_num_accertamento,
                 doc.pagopa_ric_doc_num_capitolo,
                 doc.pagopa_ric_doc_num_articolo,
                 doc.pagopa_ric_doc_pdc_v_fin,
                 doc.pagopa_ric_doc_titolo,
                 doc.pagopa_ric_doc_tipologia,
                 doc.pagopa_ric_doc_categoria,
                 doc.pagopa_ric_doc_str_amm,
                 true,
                 doc.pagopa_ric_doc_tipo_code,
                 doc.pagopa_ric_doc_tipo_id,
                 doc.pagopa_ric_doc_codice_benef,
                 -- det
                 det.pagopa_det_anag_ragione_sociale,
           	     det.pagopa_det_anag_nome,
                 det.pagopa_det_anag_cognome,
                 det.pagopa_det_anag_codice_fiscale,
                 doc.pagopa_ric_id,
                 det.pagopa_ric_det_id,
	             doc.pagopa_elab_flusso_id,
                 det.pagopa_det_versamento_id,  --- 12.08.2019 Sofia SIAC-6978
                 det.pagopa_det_data_pagamento, -- 04.02.2020 Sofia SIAC-7375
                 doc.file_pagopa_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
          from pagopa_t_riconciliazione_doc doc, pagopa_t_riconciliazione_det det
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   doc.pagopa_ric_doc_flag_con_dett=true
          and   doc.pagopa_ric_doc_tipo_id=docTipoFatId
          and   det.pagopa_ric_id=doc.pagopa_ric_id
          and   det.data_cancellazione is null
 	      and   det.validita_fine is null;

          strMessaggio:=strMessaggio||' Verifica.';
		  select 1 into codResult
          from  pagopa_t_riconciliazione_doc doc
          where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   doc.pagopa_ric_doc_flag_con_dett=true
          and   doc.pagopa_ric_doc_tipo_id=docTipoFatId
          and   not exists
          (
          select 1 from pagopa_t_riconciliazione_doc doc1
          where doc1.pagopa_elab_flusso_id=pagopaElabFlussoId
          and   doc1.pagopa_ric_id=doc.pagopa_ric_id
          and   doc1.pagopa_ric_doc_flag_dett=true
          );

		  if codResult is not null then
          	strMessaggioBck:=strMessaggio;
            strmessaggio:=strMessaggio||'  esistenti. Aggiornamento pagopa_t_elaborazione.';
            update pagopa_t_elaborazione elab
            set    data_modifica=clock_timestamp(),
                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
                   pagopa_elab_errore_id=err.pagopa_ric_errore_id,
                   pagopa_elab_note=upper(strMessaggioFinale||' '||strmessaggio)
            from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
            where elab.pagopa_elab_id=filePagoPaElabId
            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
            and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST,ELABORATO_IN_CORSO_SC_ST,ELABORATO_IN_CORSO_ER_ST)
            and   statonew.ente_proprietario_id=stato.ente_proprietario_id
            and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_SC_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_49
            and   elab.data_cancellazione is null
            and   elab.validita_fine is null;

            pagoPaErrCode:=PAGOPA_ERR_49;
            codResult:=-1;

            strMessaggio:=strMessaggioBck||' esistenti.Aggiornamento pagopa_t_riconciliazione_doc PAGOPA_ERR='||PAGOPA_ERR_49||'.';
            update pagopa_t_riconciliazione_doc doc
            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                   data_modifica=clock_timestamp(),
                   pagopa_ric_doc_stato_elab='X',
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from pagopa_d_riconciliazione_errore err
            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
            and   err.ente_proprietario_id=doc.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_49
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null;


            strMessaggio:=strMessaggioBck||' esistenti.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||PAGOPA_ERR_49||'.';
            update pagopa_t_riconciliazione ric
            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
                   data_modifica=clock_timestamp(),
                   pagopa_ric_flusso_stato_elab='X',
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
            and   ric.pagopa_ric_id=doc.pagopa_ric_id
            and   err.ente_proprietario_id=doc.ente_proprietario_id
            and   err.pagopa_ric_errore_code=PAGOPA_ERR_49
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null
            and   ric.data_cancellazione is null
            and   ric.validita_fine is null;
          end if;

          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
             filepagopaid,
             strMessaggioLog,
             enteProprietarioId,
             loginOperazione,
             clock_timestamp()
          );
		end if;

		-- sono stati inseriti
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        -- posso aggiornare su pagopa_t_elaborazione per elab=elaborato_in_corso
		if codResult is null then
		            strMessaggio:='Inserimento dati per elaborazione flussi.In ciclo pagopa_flusso_id='||
                       pagoPaFlussoRec.pagopa_flusso_id|| ' - Provvisorio=' ||
                       pagoPaFlussoRec.pagopa_anno_provvisorio||'/'||
                       pagoPaFlussoRec.pagopa_num_provvisorio||'.'||
                       ' Aggiornamento pagopa_t_elaborazione '||ELABORATO_IN_CORSO_ST||'.';
		          	update pagopa_t_elaborazione elab
		            set    data_modifica=clock_timestamp(),
    	                   pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
        	               pagopa_elab_note='AGGIORNAMENTO ELABORAZIONE SU FILE file_pagopa_id='||filePagoPaId::varchar||' IN STATO '||ELABORATO_IN_CORSO_ST||' '
            		from pagopa_d_elaborazione_stato stato, pagopa_d_elaborazione_stato statonew
	                where elab.pagopa_elab_id=filePagoPaElabId
    	            and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
        	        and   stato.pagopa_elab_stato_code in (ACQUISITO_ST,ELABORATO_IN_CORSO_ST)
            	    and   statonew.ente_proprietario_id=stato.ente_proprietario_id
	                and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ST
    	            and   elab.data_cancellazione is null
        	        and   elab.validita_fine is null;
        end if;

		-- non sono stati inseriti
        -- pagopa_t_elaborazione_flusso
        -- pagopa_t_riconciliazione_doc
        -- quindi aggiornare siac_t_file_pagopa
        if codResult is not null then
	        strmessaggio:=strMessaggioBck||' Errore. Aggiornamento siac_t_file_pagopa.';
	       	update siac_t_file_pagopa file
          	set    data_modifica=clock_timestamp(),
            	   file_pagopa_stato_id=stato.file_pagopa_stato_id,
                   file_pagopa_errore_id=err.pagopa_ric_errore_id,
                   file_pagopa_code=coalesce(filepagopaFileXMLId,file.file_pagopa_code),
                   file_pagopa_note=coalesce(strMessaggioFinale,' ' )||coalesce(strmessaggio,' '),
                   login_operazione=loginOperazione||'@ELAB-'||coalesce(filePagoPaElabId::varchar,' ') -- 04.02.2020 Sofia SIAC-7375
            from siac_d_file_pagopa_stato stato, pagopa_d_riconciliazione_errore err
            where file.file_pagopa_id=filePagoPaId
            and   stato.ente_proprietario_id=file.ente_proprietario_id
            and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_SC_ST
            and   err.ente_proprietario_id=stato.ente_proprietario_id
            and   err.pagopa_ric_errore_code=pagoPaErrCode;
        end if;

	    strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_insert - '||strMessaggioFinale||strMessaggio;
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
           filepagopaid,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
        );

    end loop;
    ---------- fine gestione flussi su piano_t_riconciliazione per pagopa_elab_id ----------------

    outPagoPaElabId:=filePagoPaElabId;
    messaggioRisultato:=upper(strMessaggioFinale||' OK');
    strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_insert - '||messaggioRisultato;
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
       filepagopaid,
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
       	outPagoPaElabId:=-1;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outPagoPaElabId:=-1;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outPagoPaElabId:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_esegui (
  filepagopaelabid integer,
  annobilancioelab integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioBck VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;




    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
    -- 18.01.2021 Sofia Jira SIAC-7962
    ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO


	-- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
	PAGOPA_ERR_42   CONSTANT  varchar :='42';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE
	PAGOPA_ERR_43   CONSTANT  varchar :='43';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO
 	PAGOPA_ERR_44   CONSTANT  varchar :='44';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO COD.FISC.
 	PAGOPA_ERR_45   CONSTANT  varchar :='45';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO PIVA
 	PAGOPA_ERR_46   CONSTANT  varchar :='46';--DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO
    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    PAGOPA_ERR_50   CONSTANT  varchar :='50';--DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO

    -- 22.07.2019 Sofia siac-6963 - inizio
	PAGOPA_ERR_51   CONSTANT  varchar :='51';--DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE
    
	-- 07.07.2021 Sofia jira SIAC-8221
    PAGOPA_ERR_52	CONSTANT  varchar :='52';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA ANNULLATO O CON DATA DI REGOLARIZZAZIONE
	
    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    --- 12.06.2019 SIAC-6720
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;

    --- 12.06.2019 Siac-6720
    docTipoFatId integer:=null;
    docTipoCorId integer:=null;
    docTipoCorNumAutom integer:=null;
    docTipoFatNumAutom integer:=null;
    nProgressivoFat integer:=null;
    nProgressivoCor integer:=null;
    nProgressivoTemp integer:=null;
	isDocIPA boolean:=false;

    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    -- 11.06.2019 SIAC-6720
	numModifica  integer:=null;
    attoAmmId    integer:=null;
    modificaTipoId integer:=null;
    modifId       integer:=null;
    modifStatoId  integer:=null;
    modStatoRId   integer:=Null;

	-- 13.09.2019 Sofia SIAC-7034
    numeroFattura varchar(250):=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

	-- 12.08.2019 Sofia SIAC-6978 - fine
    docIUV varchar(150):=null;
    -- 06.02.2020 Sofia jira siac-7375
    docDataOperazione timestamp:=null;
BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
--    raise notice '%',strMessaggioLog;

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
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '2222%',strMessaggioLog;
    raise notice '2222-codResult- %',codResult;
    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;
    raise notice '2222strMessaggio  %',strMessaggio;
    raise notice '2222strMessaggio CodResult %',codResult;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoFatId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_FAT
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';
      if docTipoFatId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
	      select 1 into docTipoFatNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoFatId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;
      end if;

  end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoCorId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_COR
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';

      if docTipoCorId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
   	      select 1 into docTipoCorNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoCorId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;

      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docStatoValId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
    raise notice '22229998@@%',strMessaggio;

     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
         raise notice '22229997@@%',strMessaggio;

	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     -- 18.01.2021 Sofia Jira SIAC-7962
--     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   --- 12.06.2019 Sofia SIAC-6720
   if codResult is null and
      (docTipoCorNumAutom is not null or docTipoFatNumAutom is not null ) then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num ['
                   ||DOC_TIPO_FAT||'-'
                   ||DOC_TIPO_COR
                   ||'] per anno='||annoBilancio::varchar||'.';

      nProgressivoFat:=0;
      nProgressivoCor:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivoFat,
             tipo.doc_tipo_id,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil,siac_d_doc_tipo tipo
      where bil.bil_id=bilancioId
      --and   tipo.doc_tipo_id in (docTipoFatId,docTipoCorId)
      and   tipo.doc_tipo_id in
      (select docTipoCorId doc_tipo_id where  docTipoCorNumAutom is not null
       union
       select docTipoFatId doc_tipo_id where  docTipoFatNumAutom is not null
      )
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=tipo.doc_tipo_id
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

	  codResult:=null;
      --if codResult is null then
      if docTipoCorNumAutom is not null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoCorId;

          if codResult is not null then
              nProgressivoCor:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;

      if docTipoFatNumAutom is not null and codResult is null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoFatId;

          if codResult is not null then
              nProgressivoFat:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;
--    else codResult:=null;
--    end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';
    raise notice '22229996@@%',strMessaggio;

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';
     raise notice '2222999999@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     /*and   prov.provc_data_annullamento is null -- 07.07.2021 Sofia Jira SIAC-8221 
     and   prov.provc_data_regolarizzazione is null*/
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     --     26.07.2019 Sofia questo controllo causa
     --     nelle update successive il non aggiornamento del motivo di scarto
     --     sulle righe dello stesso flusso ma con motivi diversi
     --     gli step successivi ( update successivi ) lasciano elab='N'
     --     in questo modo il flusso non viene elaborato
     --     in quanto la stessa condizione compare nel query del loop di elaborazione
     --     ma non tutti i dettagli in scarto vengono trattati ed eventualmente associati
     --     a un motivo di scarto
     --     bisogna tenerne conto quando un  flusso non viene elaborato
     --     e non tutti i dettagli hanno un motivo di scarto segnalato
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    -- 07.07.2021 Sofia Jira SIAC-8221 -- inizio 
	-- provvisorio di cassa esistente ma con data_annullamento o data_regolarizzazione impostate 
	if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_52||'.';
     raise notice '2222999999@@strMessaggio PAGOPA_ERR_52 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   ( prov.provc_data_annullamento is not null  or prov.provc_data_regolarizzazione is not null )
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_52
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_52;
        strErrore:=' Provvisori di cassa annullati o regolarizzati [data impostata].';
     end if;
	 codResult:=null;
    end if;
    -- 07.07.2021 Sofia Jira SIAC-8221 -- fine 
	
    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	  pagopa_ric_errore_id=err.pagopa_ric_errore_id,
              data_modifica=clock_timestamp(),
--               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_23 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- siac-6720 31.05.2019 controlli - inizio


   -- dettagli con codice fiscale non indicato
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_41||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_41
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_41;
        strErrore:=' Estremi soggetto non indicati per dati di dettaglio-fatt.';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_42||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_42
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_42;
        strErrore:=' Soggetto inesistente per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente ma non valido
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_43||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
           siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
           siac_d_ambito ambito
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_43
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_43;
        strErrore:=' Soggetto esistente non VALIDO per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente valido ma non univoco (diversi soggetti per stesso codice fiscale)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_44||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.codice_fiscale
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_44
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_44;
        strErrore:=' Soggetto esistente VALIDO non univoco (cod.fisc) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   --  soggetto esistente valido ma non univoco (diversi soggetti per stessa partita iva)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_45||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.partita_iva
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_45
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_45;
        strErrore:=' Soggetto esistente VALIDO non univoco (p.iva) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;


   -- aggiornare tutti i dettagli con il soggetto_id
   -- (anche il codice del soggetto !! adesso funziona gia' tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and   ambito.ambito_id=sog.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
     and    exists
     (
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1,siac_d_ambito ambito1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
     and   ambito1.ambito_id=sog1.ambito_id
     and   ambito1.ambito_code='AMBITO_FIN'
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     codResult:=null;
     strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per partita iva [pagopa_t_riconciliazione_doc].';
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato,
          siac_d_ambito ambito
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and    ambito.ambito_id=sog.ambito_id
     and    ambito.ambito_code='AMBITO_FIN'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1,siac_d_ambito ambito
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
     -- 10.05.2021 Sofia Jira SIAC-	SIAC-8167 - AMBITO
     and   ambito.ambito_id=sog1.ambito_id
     and   ambito.ambito_code='AMBITO_FIN'
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     codResult:=null;
   end if;

   --  soggetto_id non aggiornato su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_46||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_46
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_46;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza estremi soggetto aggiornato. ';
     end if;
     codResult:=null;
   end if;

   --  importo non valorizzato  su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_50||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_sottovoce_importo,0)=0
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_50
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_50;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza importo valorizzato. ';
     end if;
     codResult:=null;
   end if;

   -- siac-6720 31.05.2019 controlli - fine

   -- siac-6720 31.05.2019 controlli commentare il seguente
   -- soggetto indicato non esistente non esistente
   /*if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_34 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;*/

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_35 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;

   -- 22.07.2019 Sofia siac-6963 - inizio
   -- accertamento indicato per IPA,COR senza soggetto o soggetto  non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_51||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_51 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
--            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
            login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=false
     and    not exists
     (
      select 1
      from siac_t_movgest mov, siac_d_movgest_tipo tipo,
           siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
           siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
           siac_r_movgest_ts_sog rsog,siac_t_soggetto sog
      where tipo.ente_proprietario_id=doc.ente_proprietario_id
      and   tipo.movgest_tipo_code='A'
      and   mov.movgest_tipo_id=tipo.movgest_tipo_id
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipots.movgest_ts_tipo_code='T'
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code='D'
      and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
      and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
      and   rsog.movgest_ts_id=ts.movgest_ts_id
      and   sog.soggetto_id=rsog.soggetto_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rsog.data_cancellazione is null
      and   rsog.validita_fine is null
      and   sog.data_cancellazione is null
      and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_51
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_51;
        strErrore:=' Soggetto non indicato su accertamento o non esistente.';
     end if;
     codResult:=null;
   end if;
   -- 22.07.2019 Sofia siac-6963 - fine

--raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
--raise notice 'codResult   %',codResult;
  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';
--   raise notice '2222@@strMessaggio   %',strMessaggio;
--   raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
--          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
          login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
--    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
     raise notice 'strMessaggioStrErrore=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
		    pagopa_elab_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500), -- 09.10.2019 Sofia
            login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
     from  pagopa_r_elaborazione_file r,
           siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      -- 10.05.2021 Sofia Jira SIAC-8167
      if pagoPaCodeErr=PAGOPA_ERR_7 then
      	codiceRisultato:=0;
      else
        codiceRisultato:=-1;
      end if;

      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
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
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

--  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
   		  coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
          doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id,           -- siac-6720
          doc.pagopa_ric_doc_iuv     pagopa_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
          doc.pagopa_ric_doc_data_operazione pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   --     26.07.2019 Sofia questo controllo causa
   --     la non elaborazione di flussi che hanno dettagli in scarto
   --     righe dello stesso flusso ma con motivi diversi
   --     possono esserci righe con scarto='X' e scarto='N'
   --     per le update a step successivi che hanno la stessa condizione
   --     in questo modo il flusso non viene elaborato
   --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
   --     a un motivo di scarto
   --     bisogna tenerne conto quando un  flusso non viene elaborato
   --     e non tutti i dettagli hanno un motivo di scarto segnalato
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
            coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento,
            doc.pagopa_ric_doc_tipo_code, -- siac-6720
            doc.pagopa_ric_doc_tipo_id, -- siac-6720
            doc.pagopa_ric_doc_iuv ,   -- 06.02.2020 Sofia siac-7375
            doc.pagopa_ric_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
        left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
          left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720
           pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
            pagopa_sogg.pagopa_doc_iuv, pagopa_sogg.pagopa_doc_data_operazione -- 06.02.2020 Sofia siac-7375
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
             pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720

  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;
		docIUV:=null;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=null;

		-- 12.08.2019 Sofia SIAC-6978 - inizio
		if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT then
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                        ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                        ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].'
                        ||' Lettura codice IUV.';
          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

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

         /* select distinct query.pagopa_ric_doc_iuv into docIUV
          from
          (
             with
             pagopa_sogg as
             (
             with
             pagopa as
             (
             select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
                    coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
                    doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
                    doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
                    doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                    doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                    doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
                    doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id, -- siac-6720
                    doc.pagopa_ric_doc_iuv pagopa_ric_doc_iuv
             from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
             where flusso.pagopa_elab_id=filePagoPaElabId
             and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
             and   doc.pagopa_ric_doc_stato_elab='N'
             and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
             and   doc.pagopa_ric_doc_subdoc_id is null
             --     26.07.2019 Sofia questo controllo causa
             --     la non elaborazione di flussi che hanno dettagli in scarto
             --     righe dello stesso flusso ma con motivi diversi
             --     possono esserci righe con scarto='X' e scarto='N'
             --     per le update a step successivi che hanno la stessa condizione
             --     in questo modo il flusso non viene elaborato
             --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
             --     a un motivo di scarto
             --     bisogna tenerne conto quando un  flusso non viene elaborato
             --     e non tutti i dettagli hanno un motivo di scarto segnalato
             -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione e poi scarto
            /* and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
             (
               select 1
               from pagopa_t_riconciliazione_doc doc1
               where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
               and   doc1.pagopa_ric_doc_stato_elab!='N'
               and   doc1.data_cancellazione is null
               and   doc1.validita_fine is null
             )*/
             and   doc.data_cancellazione is null
             and   doc.validita_fine is null
             and   flusso.data_cancellazione is null
             and   flusso.validita_fine is null
             group by doc.pagopa_ric_doc_codice_benef,
                      coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
                      doc.pagopa_ric_doc_str_amm,
                      doc.pagopa_ric_doc_voce_tematica,
                      doc.pagopa_ric_doc_voce_code,
                      doc.pagopa_ric_doc_voce_desc,
                      doc.pagopa_ric_doc_anno_accertamento,
                      doc.pagopa_ric_doc_num_accertamento,
                      doc.pagopa_ric_doc_tipo_code, -- siac-6720
                      doc.pagopa_ric_doc_tipo_id, -- siac-6720
                      doc.pagopa_ric_doc_iuv
             ),
             sogg as
             (
             select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
             from siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   sog.data_cancellazione is null
             and   sog.validita_fine is null
             )
             select pagopa.*,
                    sogg.soggetto_id,
                    sogg.soggetto_desc
             from pagopa
          ---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
                  left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
             ),
             accertamenti_sogg as
             (
             with
             accertamenti as
             (
              select mov.movgest_anno::integer, mov.movgest_numero::integer,
                     mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov , siac_d_movgest_tipo tipo,
                   siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
              where tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.movgest_tipo_code='A'
              and   mov.movgest_tipo_id=tipo.movgest_tipo_id
              and   mov.bil_id=bilancioId
              and   ts.movgest_id=mov.movgest_id
              and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
              and   tipots.movgest_ts_tipo_code='T'
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   stato.movgest_stato_id=rs.movgest_stato_id
              and   stato.movgest_stato_code='D'
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
             ),
             soggetto_acc as
             (
             select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
             from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   rsog.soggetto_id=sog.soggetto_id
             and   rsog.data_cancellazione is null
             and   rsog.validita_fine is null
             )
             select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
             from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
                    left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
          --   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
             )
             select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                     pagopa_sogg.pagopa_str_amm,
                     pagopa_sogg.pagopa_voce_tematica,
                     pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                     pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720,
                     pagopa_sogg.pagopa_ric_doc_iuv
             from  pagopa_sogg, accertamenti_sogg
             where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
             and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
             group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
                      pagopa_sogg.pagopa_str_amm,
                      pagopa_sogg.pagopa_voce_tematica,
                      pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                      pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
                      pagopa_sogg.pagopa_ric_doc_iuv
             order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                       pagopa_sogg.pagopa_str_amm,
                       pagopa_sogg.pagopa_voce_tematica,
                       pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                       pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id
          )
          query
          where query.pagopa_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id
          and   coalesce(query.pagopa_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(query.pagopa_voce_tematica,''))
          and   query.pagopa_voce_code=pagoPaFlussoRec.pagopa_voce_code
          and   coalesce(query.pagopa_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(query.pagopa_voce_desc,''))
          and   coalesce(query.pagopa_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(query.pagopa_str_amm,''))
          and   query.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id;*/

        -- 06.02.2020 Sofia jira siac-7375
        docIUV:=pagoPaFlussoRec.pagopa_doc_iuv;
        raise notice 'IUUUUUUUUUV docIUV=%',docIUV;
       	if coalesce(docIUV,'')='' or docIUV is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Lettura non riuscita.';
        end if;
        -- 06.02.2020 Sofia jira siac-7375
        docDataOperazione:=pagoPaFlussoRec.pagopa_doc_data_operazione;
        raise notice 'IUUUUUUUUUV docDataOperazione=%',docDataOperazione;

       end if;
 	   -- 12.08.2019 Sofia SIAC-6978 - fine


       if bErrore=false then
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

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

		docId:=null;

        -- 12.06.2019 SIAC-6720
--        nProgressivo:=nProgressivo+1;
        nProgressivoTemp:=null;
        isDocIPA:=false;
        -- 13.09.2019 Sofia SIAC-7034
        numeroFattura:=null;

        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
            -- 13.09.2019 Sofia SIAC-7034
            numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||'-'||nProgressivoTemp::varchar;
        end if;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_COR and docTipoCorNumAutom is not null then
        	nProgressivoCor:=nProgressivoCor+1;
            nProgressivoTemp:=nProgressivoCor;
        end if;
        if nProgressivoTemp is null then
	          nProgressivo:=nProgressivo+1;
              nProgressivoTemp:=nProgressivo;
              isDocIPA:=true;
        end if;

        -- 13.09.2019 Sofia SIAC-7034
        if numeroFattura is null then
           numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||' '
                          ||extract ( day from dataElaborazione)||'-'
                          ||lpad(extract ( month from dataElaborazione)::varchar,2,'0')
                          ||'-'||extract ( year from dataElaborazione)
                          -- ||' ' 20.04.2020 Sofia jira	SIAC-7586
                          ||' '||nProgressivoTemp::varchar;
        end if;



--        raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
--        raise notice 'isDocIPA=%',isDocIPA;
--		raise notice 'nProgressivo=%',nProgressivo;
--        raise notice 'nProgressivoCor=%',nProgressivoCor;
--        raise notice 'nProgressivoFat=%',nProgressivoFat;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id,
            IUV, -- null ??  -- 12.08.2019 Sofia SIAC-6978 - fine
            doc_data_operazione -- 06.02.2020 Sofia jira siac-7375
        )
        select annoBilancio,
--               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               numeroFattura,-- 13.09.2019 Sofia SIAC-7034
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
--			   docTipoId, siac-6720 28.05.2019 Sofia
               pagoPaFlussoRec.pagopa_doc_tipo_id, -- siac-6720 28.05.2019 Sofia
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null,
               docIUV,   -- 12.08.2019 Sofia SIAC-6978 - fine
               docDataOperazione -- 06.02.2020 Sofia jira siac-7375
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;
       end if;


	   if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                --clock_timestamp(), 06.07.2021 Sofia Jira SIAC-8277
                now(), -- 06.07.2021 Sofia Jira SIAC-8277
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         --- 12.06.2019 Siac-6720
--         raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code2=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
         if isDocIPA=true then
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id=docTipoId
           returning num.doc_num_id into codResult;
         else
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id =pagoPaFlussoRec.pagopa_doc_tipo_id
           returning num.doc_num_id into codResult;
         end if;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
--        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

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
raise notice 'prima di quote berrore=%',berrore;
        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
           and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                 coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
           and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti -- , soggetto_acc -- 22.07.2019 siac-6963
                  left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
--        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', --- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
--        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
--		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica. Calcolo numero.';


                    numModifica:=null;
                    codResult:=null;
                    select coalesce(max(query.mod_num),0) into numModifica
                    from
                    (
					select  modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_t_movgest_ts_det_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sog_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sogclasse_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    ) query;

                    if numModifica is null then
                     numModifica:=0;
                    end if;

                    strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica.';
                    attoAmmId:=null;
                    select ratto.attoamm_id into attoAmmId
                    from siac_r_movgest_ts_atto_amm ratto
                    where ratto.movgest_ts_id=movgestTsId
                    and   ratto.data_cancellazione is null
                    and   ratto.validita_fine is null;
					if attoAmmId is null then
                    	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in lettura atto amministrativo.';
                    end if;

                    if codResult is null and modificaTipoId is null then
                    	select tipo.mod_tipo_id into modificaTipoId
                        from siac_d_modifica_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.mod_tipo_code='ALT';
                        if modificaTipoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura modifica tipo.';
                        end if;
                    end if;

                    if codResult is null then
                      modifId:=null;
                      insert into siac_t_modifica
                      (
                          mod_num,
                          mod_desc,
                          mod_data,
                          mod_tipo_id,
                          attoamm_id,
                          login_operazione,
                          validita_inizio,
                          ente_proprietario_id
                      )
                      values
                      (
                          numModifica+1,
                          'Modifica automatica per predisposizione di incasso',
                          dataElaborazione,
                          modificaTipoId,
                          attoAmmId,
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          clock_timestamp(),
                          enteProprietarioId
                      )
                      returning mod_id into modifId;
                      if modifId is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_modifica.';
                      end if;
					end if;

                    if codResult is null and modifStatoId is null then
	                    select stato.mod_stato_id into modifStatoId
                        from siac_d_modifica_stato stato
                        where stato.ente_proprietario_id=enteProprietarioId
                        and   stato.mod_stato_code='V';
                        if modifStatoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura stato modifica.';
                        end if;
                    end if;
                    if codResult is null then
                      modStatoRId:=null;
                      insert into siac_r_modifica_stato
                      (
                          mod_id,
                          mod_stato_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          modifId,
                          modifStatoId,
                          clock_timestamp(),
                          loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          enteProprietarioId
                      )
                      returning mod_stato_r_id into modStatoRId;
                      if modStatoRId is  null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_r_modifica_stato.';
                      end if;
                    end if;
                    if codResult is null then
                      insert into siac_t_movgest_ts_det_mod
                      (
                          mod_stato_r_id,
                          movgest_ts_det_id,
                          movgest_ts_id,
                          movgest_ts_det_tipo_id,
                          movgest_ts_det_importo,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      select modStatoRId,
                             det.movgest_ts_det_id,
                             det.movgest_ts_id,
                             det.movgest_ts_det_tipo_id,
                             pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                             clock_timestamp(),
                             loginOperazione||'@ELAB_PAGOPA'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                             det.ente_proprietario_id
                      from siac_t_movgest_ts_det det
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      returning movgest_ts_det_mod_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_movgest_ts_det_mod.';
                      else
                        codResult:=null;
                      end if;
                	end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';
                      update siac_t_movgest_ts_det det
                      set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                             data_modifica=clock_timestamp(),
                             --login_operazione=det.login_operazione||'-'||loginOperazione -- 27.02.2020 Sofia jira SIAC-7449
                             login_operazione=loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar -- 27.02.2020 Sofia jira SIAC-7449
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in aggiornamento siac_t_movgest_ts_det.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento pagopa_t_modifica_elab.';
                      insert into pagopa_t_modifica_elab
                      (
                          pagopa_modifica_elab_importo,
                          pagopa_elab_id,
                          subdoc_id,
                          mod_id,
                          movgest_ts_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                          filePagoPaElabId,
                          subDocId,
                          modifId,
                          movgestTsId,
                          clock_timestamp(),
                          loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar, -- 27.02.2020 Sofia jira SIAC-7449
                          enteProprietarioId
                      )
                      returning pagopa_modifica_elab_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento pagopa_t_modifica_elab.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is not null then
                        --bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggioBck:=strMessaggio||' PAGOPA_ERR_31='||PAGOPA_ERR_31||' .';
--                        raise notice '%', strMessaggioBck;
                        strMessaggio:=' ';
                        raise exception '%', strMessaggioBck;
                    end if;
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
--        raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;

        -- siac-6720 30.05.2019 - per i corrispettivi non collegare atto_amm
--        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then -- Jira SIAC-7089 14.10.2019 Sofia
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_IPA  then    -- Jira SIAC-7089 14.10.2019 Sofia


          -- siac_r_subdoc_atto_amm
          codResult:=null;
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
          insert into siac_r_subdoc_atto_amm
          (
              subdoc_id,
              attoamm_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select subdocId,
                 atto.attoamm_id,
                 clock_timestamp(),
                 loginOperazione,
                 atto.ente_proprietario_id
          from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
          where rts.subdoc_movgest_ts_id=subdocMovgestTsId
          and   atto.movgest_ts_id=rts.movgest_ts_id
          and   atto.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
          returning subdoc_atto_amm_id into codResult;
          if codResult is null then
              bErrore:=true;
              strMessaggio:=strMessaggio||' Errore in inserimento.';
              continue;
          end if;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
--        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
--            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
--            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
--               clock_timestamp(), 06.07.2021 Sofia Jira SIAC-8277
               now(), --06.07.2021 Sofia Jira SIAC-8277
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
---        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
--               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
			and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
              select ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=movgestTipoId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_tipo_id=movgestTsTipoId
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id=movgestStatoId
              and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
              and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
              and   mov.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
              and   ts.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
              and   rs.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
              select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
              from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
              where sog.ente_proprietario_id=enteProprietarioId
              and   rsog.soggetto_id=sog.soggetto_id
              and   sog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
              and   rsog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))

           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id
          from --pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog ,-- 22.07.2019 siac-6963
               pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code)
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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


        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
--               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
               login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;
		raise notice 'dnumQuote %',dnumQuote;
	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
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
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
--                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                --login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar      -- 04.02.2020 Sofia SIAC-7375
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and   coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and   coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                  coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
        --    and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
        --    and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
        --           coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
        --    and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
        --    and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
        --    and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        --    and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        --   and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        --	 and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     	/*	and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog AS
          (
           with
           accertamenti as
           (
                select ts.movgest_ts_id
                from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
                where mov.bil_id=bilancioId
                and   mov.movgest_tipo_id=movgestTipoId
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_tipo_id=movgestTsTipoId
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   rs.movgest_stato_id=movgestStatoId
            --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
             --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
                and   mov.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
                and   ts.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
                and   rs.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
	           select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
    		   from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
	           where sog.ente_proprietario_id=enteProprietarioId
               and   rsog.soggetto_id=sog.soggetto_id
	           and   sog.data_cancellazione is null
	           and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
               and   rsog.data_cancellazione is null
               and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--                accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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




         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar             -- 04.02.2020 Sofia SIAC-7375
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
--                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
                login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar          -- 04.02.2020 Sofia SIAC-7375
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_iuv,'')=coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'') -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_data_operazione,'2020-01-01'::timestamp)=
                   coalesce(pagoPaFlussoRec.pagopa_doc_data_operazione,'2020-01-01'::timestamp) -- 06.02.2020 Sofia siac-7375
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
--            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
--            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
--                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
--            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
--            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
--            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
--            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
--            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
            and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
  /*   		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
            select ts.movgest_ts_id
            from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
            where mov.bil_id=bilancioID
            and   mov.movgest_tipo_id=movgestTipoId
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_tipo_id=movgestTsTipoId
            and   rs.movgest_ts_id=ts.movgest_ts_id
            and   rs.movgest_stato_id=movgestStatoId
--            and   rsog.movgest_ts_id=ts.movgest_ts_id -- 06.12.2019 Sofia jira SIAC-7251  -- errore in esecuzione
  --          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
  --          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and   mov.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
            and   ts.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
            and   rs.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
            select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
            from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
            where sog.ente_proprietario_id=enteProprietarioId
            and   rsog.soggetto_id=sog.soggetto_id
            and   sog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
            and   rsog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
---               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963

         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
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

         -- 11.06.2019 SIAC-6720
         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_modifica_elab].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_modifica_elab r
         set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN ESEGUI PER pagoPaCodeErr='||pagoPaCodeErr||' ',
                subdoc_id=null
         from 	siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
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

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
--  raise notice 'strMessaggioLog=%',strMessaggioLog;
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

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp()--, 26.08.2020 Sofia Jira SIAC-7747
         -- login_operazione=num.login_operazione||'-'||loginOperazione 26.08.2020 Sofia Jira SIAC-7747
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=
            substr(
             (
              'AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
              ||elab.pagopa_elab_note
             ),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=
                  substr(
                    ('AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
                     ||file.file_pagopa_note
                    ),1,1500), -- 09.10.2019 Sofia
           login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
--  raise notice 'strMessaggio=%',strMessaggio;

  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';

  --  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
  strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
  --    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
    --  and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
   --   and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';

--       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
       strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
--              login_operazione=file.login_operazione||'-'||loginOperazione
              login_operazione=loginOperazione||'@ELAB-'||filePagoPaElabId::varchar  -- 04.02.2020 Sofia SIAC-7375

       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);
-- raise notice 'messaggioRisultato=%',messaggioRisultato;
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

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out pagopaBckSubdoc             BOOLEAN,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):='';
	strMessaggioBck VARCHAR(2500):='';
    strMessaggioLog VARCHAR(2500):='';
	strMessaggioFinale VARCHAR(2500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(10):='';
	codResult integer:=null;


	PagoPaRecClean record;
    AggRec record;

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA


begin

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' Pulizia documenti creati per provvisori in errore-non completi.';
    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale;
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
--	raise notice 'strMessaggioFinale=%',strMessaggioFinale;
    codiceRisultato:=0;
    messaggioRisultato:='';
    pagopaBckSubdoc:=false;

    strMessaggio:='Inizio ciclo su pagopa_t_riconciliazione_doc.';
  --        raise notice 'strMessaggio=%',strMessaggio;

    for PagoPaRecClean in
    (
     select doc.pagopa_ric_doc_provc_id pagopa_provc_id,
            flusso.pagopa_elab_flusso_anno_esercizio pagopa_anno_esercizio,
            flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
            flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio
     from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
	 and   doc.pagopa_ric_doc_subdoc_id is not null
	 and   doc.pagopa_ric_doc_stato_elab='S'
	 and   exists
	 (
      select 1
	  from  pagopa_t_elaborazione_flusso flusso1, pagopa_t_riconciliazione_doc doc1,
            pagopa_t_riconciliazione ric1
	  where flusso1.pagopa_elab_id=flusso.pagopa_elab_id
	  and   flusso1.pagopa_elab_flusso_anno_esercizio=flusso.pagopa_elab_flusso_anno_esercizio
	  and   flusso1.pagopa_elab_flusso_anno_provvisorio=flusso.pagopa_elab_flusso_anno_provvisorio
	  and   flusso1.pagopa_elab_flusso_num_provvisorio=flusso.pagopa_elab_flusso_num_provvisorio
	  and   doc1.pagopa_elab_flusso_id=flusso1.pagopa_elab_flusso_id
      and   ric1.pagopa_ric_id=doc1.pagopa_ric_id
	  and   doc1.pagopa_ric_doc_subdoc_id is null
      -- 07.06.2019 SIAC-6720
	  and   ((doc1.pagopa_ric_doc_stato_elab!='S' and doc1.pagopa_ric_doc_flag_con_dett=false ) or
              ric1.pagopa_ric_flusso_stato_elab!='S'
            )
	  and   flusso1.data_cancellazione is null
	  and   flusso1.validita_fine is null
	  and   doc1.data_cancellazione is null
	  and   doc1.validita_fine is null
      and   ric1.data_cancellazione is null
      and   ric1.validita_fine is null

	 ) -- per provvisorio scarti,non elaborati o errori
     and flusso.data_cancellazione is null
	 and flusso.validita_fine is null
	 and doc.data_cancellazione is null
	 and doc.validita_fine is null
	 order by 2,3,4
	)
    loop

	  codResult:=null;
      -- tabelle backup
      -- pagopa_bck_t_subdoc
      --  raise notice '@@@@@@@@@@@@@@@@@@@@ strMessaggio=%',strMessaggio;
      strMessaggio:='In ciclo su pagopa_t_riconciliazione_doc. Per provvisorio di cassa Prov. '
                  ||PagoPaRecClean.pagopa_anno_provvisorio::varchar||'/'||PagoPaRecClean.pagopa_num_provvisorio::varchar
                  ||' provcId='||PagoPaRecClean.pagopa_provc_id::varchar||'.';
      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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

      strMessaggioBck:=strMessaggio;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc.';
      insert into pagopa_bck_t_subdoc
      (
        pagopa_provc_id,
        pagopa_elab_id,
        subdoc_id,
        subdoc_numero,
        subdoc_desc,
        subdoc_importo,
        subdoc_nreg_iva,
        subdoc_data_scadenza,
        subdoc_convalida_manuale,
        subdoc_importo_da_dedurre,
        subdoc_splitreverse_importo,
        subdoc_pagato_cec,
        subdoc_data_pagamento_cec,
        contotes_id,
        dist_id,
        comm_tipo_id,
        doc_id,
        subdoc_tipo_id,
        notetes_id,
        bck_validita_inizio,
        bck_validita_fine,
        bck_data_creazione,
        bck_data_modifica,
        bck_data_cancellazione,
        bck_login_operazione,
        bck_login_creazione,
        bck_login_modifica,
        bck_login_cancellazione,
        siope_tipo_debito_id,
        siope_assenza_motivazione_id,
        siope_scadenza_motivo_id,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
      )
      select
        PagoPaRecClean.pagopa_provc_id,
        filePagoPaElabId,
        sub.subdoc_id,
        sub.subdoc_numero,
        sub.subdoc_desc,
        sub.subdoc_importo,
        sub.subdoc_nreg_iva,
        sub.subdoc_data_scadenza,
        sub.subdoc_convalida_manuale,
        sub.subdoc_importo_da_dedurre,
        sub.subdoc_splitreverse_importo,
        sub.subdoc_pagato_cec,
        sub.subdoc_data_pagamento_cec,
        sub.contotes_id,
        sub.dist_id,
        sub.comm_tipo_id,
        sub.doc_id,
        sub.subdoc_tipo_id,
        sub.notetes_id,
        sub.validita_inizio,
        sub.validita_fine,
        sub.data_creazione,
        sub.data_modifica,
        sub.data_cancellazione,
        sub.login_operazione,
        sub.login_creazione,
        sub.login_modifica,
        sub.login_cancellazione,
        sub.siope_tipo_debito_id,
        sub.siope_assenza_motivazione_id,
        sub.siope_scadenza_motivo_id,
        clock_timestamp(),
        sub.ente_proprietario_id,
        loginOperazione
      from siac_t_subdoc sub,siac_r_doc_stato rs, siac_d_doc_stato stato,
	   	   pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc ric
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   ric.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   ric.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   ric.pagopa_ric_doc_stato_elab='S'
      and   sub.subdoc_id=ric.pagopa_ric_doc_subdoc_id
      and   rs.doc_id=sub.doc_id
      and   stato.doc_stato_id=rs.doc_stato_id
      and   stato.doc_stato_code not in ('A','ST','EM')
      and   not exists
      (
        select 1
        from siac_r_subdoc_ordinativo_ts rsub
        where rsub.subdoc_id=sub.subdoc_id
        and   rsub.data_cancellazione is null
        and   rsub.validita_fine is null
      )
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null
     -- and   sub.data_cancellazione is null
     -- and   sub.validita_fine is null
      and   rs.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())));
      GET DIAGNOSTICS codResult = ROW_COUNT;

      if pagopaBckSubdoc=false and coalesce(codResult,0) !=0 then
      	pagopaBckSubdoc:=true;
      end if;

	  -- pagopa_bck_t_subdoc_attr
      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_attr.';
      insert into pagopa_bck_t_subdoc_attr
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_attr_id,
          subdoc_id,
          attr_id,
          tabella_id,
          boolean,
          percentuale,
          testo,
          numerico,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_attr_id,
          r.subdoc_id,
          r.attr_id,
          r.tabella_id,
          r.boolean,
          r.percentuale,
          r.testo,
          r.numerico,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          r.ente_proprietario_id,
          loginOperazione
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_attr r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_atto_amm
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_atto_amm.';
      insert into pagopa_bck_t_subdoc_atto_amm
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_atto_amm_id,
          subdoc_id,
          attoamm_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_atto_amm_id,
          r.subdoc_id,
          r.attoamm_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_atto_amm r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_prov_cassa
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_prov_cassa.';

      insert into pagopa_bck_t_subdoc_prov_cassa
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_provc_id,
          subdoc_id,
          provc_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_provc_id,
          r.subdoc_id,
          r.provc_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_prov_cassa r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_subdoc_movgest_ts
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_movgest_ts.';

      insert into pagopa_bck_t_subdoc_movgest_ts
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_movgest_ts_id,
          subdoc_id,
          movgest_ts_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.subdoc_movgest_ts_id,
          r.subdoc_id,
          r.movgest_ts_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_r_subdoc_movgest_ts r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.subdoc_id=sub.subdoc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc.';
      insert into pagopa_bck_t_doc
      (
          pagopa_provc_id,
          pagopa_elab_id,
          doc_id,
          doc_anno,
          doc_numero,
          doc_desc,
          doc_importo,
          doc_beneficiariomult,
          doc_data_emissione,
          doc_data_scadenza,
          doc_tipo_id,
          codbollo_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          bck_login_creazione,
          bck_login_modifica,
          bck_login_cancellazione,
          pcccod_id,
          pccuff_id,
          doc_collegato_cec,
          doc_contabilizza_genpcc,
          siope_documento_tipo_id,
          siope_documento_tipo_analogico_id,
          doc_sdi_lotto_siope,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select distinct
          sub.pagopa_provc_id,
          sub.pagopa_elab_id,
          r.doc_id,
          r.doc_anno,
          r.doc_numero,
          r.doc_desc,
          r.doc_importo,
          r.doc_beneficiariomult,
          r.doc_data_emissione,
          r.doc_data_scadenza,
          r.doc_tipo_id,
          r.codbollo_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          r.login_creazione,
          r.login_modifica,
          r.login_cancellazione,
          r.pcccod_id,
          r.pccuff_id,
          r.doc_collegato_cec,
          r.doc_contabilizza_genpcc,
          r.siope_documento_tipo_id,
          r.siope_documento_tipo_analogico_id,
          r.doc_sdi_lotto_siope,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_subdoc sub, siac_t_doc r
      where sub.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	sub.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=sub.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


	  -- pagopa_bck_t_doc_stato
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_stato.';
      insert into pagopa_bck_t_doc_stato
      (
          pagopa_provc_id,
          pagopa_elab_id,
          doc_stato_r_id,
          doc_id,
          doc_stato_id,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_stato_r_id,
          r.doc_id,
          r.doc_stato_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_stato r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


	  -- pagopa_bck_t_subdoc_num
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_subdoc_num.';
      insert into pagopa_bck_t_subdoc_num
      (
          pagopa_provc_id,
          pagopa_elab_id,
          subdoc_num_id,
          doc_id,
          subdoc_numero,
          bck_validita_inizio,
          bck_validita_fine,
          bck_data_creazione,
          bck_data_modifica,
          bck_data_cancellazione,
          bck_login_operazione,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.subdoc_num_id,
          r.doc_id,
          r.subdoc_numero,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_t_subdoc_num r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


      -- pagopa_bck_t_doc_sog
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_sog.';
      insert into pagopa_bck_t_doc_sog
      (
         pagopa_provc_id,
         pagopa_elab_id,
         doc_sog_id,
         doc_id,
         soggetto_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_sog_id,
          r.doc_id,
          r.soggetto_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_sog r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc_attr
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_attr.';

      insert into pagopa_bck_t_doc_attr
      (
         pagopa_provc_id,
         pagopa_elab_id,
         doc_attr_id,
         doc_id,
         attr_id,
         tabella_id,
         boolean,
         percentuale,
         testo,
         numerico,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_attr_id,
          r.doc_id,
          r.attr_id,
          r.tabella_id,
          r.boolean,
          r.percentuale,
          r.testo,
          r.numerico,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_attr r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_doc_class
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_doc_class.';

      insert into pagopa_bck_t_doc_class
      (
      	 pagopa_provc_id,
         pagopa_elab_id,
         doc_classif_id,
         doc_id,
         classif_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.doc_classif_id,
          r.doc_id,
          r.classif_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_r_doc_class r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));

	  -- pagopa_bck_t_registrounico_doc
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Inserimento pagopa_bck_t_registrounico_doc.';

      insert into pagopa_bck_t_registrounico_doc
      (
         pagopa_provc_id,
         pagopa_elab_id,
         rudoc_id,
         rudoc_registrazione_anno,
         rudoc_registrazione_numero,
         rudoc_registrazione_data,
         doc_id,
         bck_validita_inizio,
         bck_validita_fine,
         bck_data_creazione,
         bck_data_modifica,
         bck_data_cancellazione,
         bck_login_operazione,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
      )
      select
          doc.pagopa_provc_id,
          doc.pagopa_elab_id,
          r.rudoc_id,
          r.rudoc_registrazione_anno,
          r.rudoc_registrazione_numero,
          r.rudoc_registrazione_data,
          r.doc_id,
          r.validita_inizio,
          r.validita_fine,
          r.data_creazione,
          r.data_modifica,
          r.data_cancellazione,
          r.login_operazione,
          clock_timestamp(),
          loginOperazione,
          r.ente_proprietario_id
      from pagopa_bck_t_doc doc, siac_t_registrounico_doc r
      where doc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and	doc.pagopa_elab_id=filePagoPaElabId
      and   r.doc_id=doc.doc_id;
--      and   r.data_cancellazione is null
--      and   now()>=date_trunc('DAY',r.validita_inizio) and now<=date_trunc('DAY',coalesce(r.validita_fine,now()));


   	  -- aggiornare importo documenti collegati
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento importo documenti.';

      update siac_t_doc doc
      set    doc_importo=doc.doc_importo-coalesce(query.subdoc_importo,0),
             data_modifica=clock_timestamp(),
             -- login_operazione=doc.login_operazione||'-'||loginOperazione -- 07.07.2021 Sofia Jira SIAC-8221 
			 login_operazione=loginOperazione||'@ELAB_ID='||filePagoPaElabId::varchar -- 07.07.2021 Sofia Jira SIAC-8221 
      from
      (
      select sub.doc_id,coalesce(sum(sub.subdoc_importo),0) subdoc_importo
      from siac_t_subdoc sub, pagopa_bck_t_doc pagodoc, pagopa_bck_t_subdoc pagosubdoc
      where pagodoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc.pagopa_elab_id=filePagoPaElabId
      and   pagosubdoc.pagopa_provc_id=pagodoc.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=pagodoc.pagopa_elab_id
      and   pagosubdoc.doc_id=pagodoc.doc_id
      and   sub.subdoc_id=pagosubdoc.subdoc_id
      and   pagodoc.data_cancellazione is null
      and   pagodoc.validita_fine is null
      and   pagosubdoc.data_cancellazione is null
      and   pagosubdoc.validita_fine is null
      and   sub.data_cancellazione is null
      and   sub.validita_fine is null
      group by sub.doc_id
      ) query
      where doc.ente_proprietario_id=enteProprietarioId
      and   doc.doc_id=query.doc_id
      and   exists
      (
      select 1
      from pagopa_bck_t_doc pagodoc1, pagopa_bck_t_subdoc pagosubdoc1
      where pagodoc1.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagodoc1.pagopa_elab_id=filePagoPaElabId
      and   pagodoc1.doc_id=doc.doc_id
      and   pagosubdoc1.pagopa_provc_id=pagodoc1.pagopa_provc_id
      and   pagosubdoc1.pagopa_elab_id=pagodoc1.pagopa_elab_id
      and   pagosubdoc1.doc_id=pagodoc1.doc_id
      and   pagodoc1.data_cancellazione is null
      and   pagodoc1.validita_fine is null
      and   pagosubdoc1.data_cancellazione is null
      and   pagosubdoc1.validita_fine is null
      )
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;


      -- cancellare quote documenti collegati
  	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_attr].';

      -- siac_r_subdoc_attr
      delete from siac_r_subdoc_attr r
      using pagopa_bck_t_subdoc_attr pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_attr_id=pagosubdoc.subdoc_attr_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
 --     and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_atto_amm].';
      -- siac_r_subdoc_atto_amm
      delete from siac_r_subdoc_atto_amm r
      using pagopa_bck_t_subdoc_atto_amm pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_atto_amm_id=pagosubdoc.subdoc_atto_amm_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_prov_cassa].';

      -- siac_r_subdoc_prov_cassa
      delete from siac_r_subdoc_prov_cassa r
      using pagopa_bck_t_subdoc_prov_cassa pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_provc_id=pagosubdoc.subdoc_provc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_r_subdoc_movgest_ts].';

      -- siac_r_subdoc_movgest_ts
      delete from siac_r_subdoc_movgest_ts r
      using pagopa_bck_t_subdoc_movgest_ts pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_movgest_ts_id=pagosubdoc.subdoc_movgest_ts_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione-pulizia [pagopa_t_modifica_elab].';
      update pagopa_t_modifica_elab r
      set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN CLEAN PER pagoPaCodeErr='||PAGOPA_ERR_36||' ',
             subdoc_id=null
      from 	pagopa_bck_t_subdoc pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_id=pagosubdoc.subdoc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione [siac_t_subdoc].';

      -- siac_t_subdoc
      delete from siac_t_subdoc r
      using pagopa_bck_t_subdoc pagosubdoc
      where r.ente_proprietario_id=enteProprietarioId
      and   r.subdoc_id=pagosubdoc.subdoc_id
      and   pagosubdoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagosubdoc.pagopa_elab_id=filePagoPaElabId;
--      and   r.data_cancellazione is null
--      and   r.validita_fine is null;


	  -- cancellazione su documenti senza quote
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_sog].';

      -- siac_r_doc_sog

      delete from siac_r_doc_sog r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_sog pagopaDel
      where r.doc_sog_id=pagopaDel.doc_sog_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
     -- and   sub.data_cancellazione is null
     -- and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_stato].';

      -- siac_r_doc_stato
      delete from siac_r_doc_stato r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_stato pagopaDel
      where r.doc_stato_r_id=pagopaDel.doc_stato_r_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
   --   and   sub.data_cancellazione is null
--      and   sub.validita_fine is null
      );


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_attr].';

      -- siac_r_doc_attr
      delete from siac_r_doc_attr r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_attr pagopaDel
      where r.doc_attr_id=pagopaDel.doc_attr_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
    --  and   sub.data_cancellazione is null
    --  and   sub.validita_fine is null
      );


	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_r_doc_class].';

      -- siac_r_doc_class
      delete from siac_r_doc_class r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_doc_class pagopaDel
      where r.doc_classif_id=pagopaDel.doc_classif_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
    --  and   sub.data_cancellazione is null
    --  and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_registrounico_doc].';

      -- siac_t_registrounico_doc
      delete from siac_t_registrounico_doc r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_registrounico_doc pagopaDel
      where r.rudoc_id=pagopaDel.rudoc_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
   --   and   sub.data_cancellazione is null
   --   and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_subdoc_num].';

      -- siac_t_subdoc_num
      delete from siac_t_subdoc_num r
      using pagopa_bck_t_doc pagopa, pagopa_bck_t_subdoc_num pagopaDel
      where r.subdoc_num_id=pagopaDel.subdoc_num_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   pagopa.doc_id=pagopaDel.doc_id
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopa.doc_id
  --    and   sub.data_cancellazione is null
  --    and   sub.validita_fine is null
      );

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Cancellazione Documenti senza quote [siac_t_doc].';

      -- siac_t_doc
      delete from siac_t_doc r
      using pagopa_bck_t_doc pagopaDel
      where r.doc_id=pagopaDel.doc_id
      and   pagopaDel.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopaDel.pagopa_elab_id=filePagoPaElabId
      and   not exists
      (
      select 1 from siac_t_subdoc sub
      where sub.doc_id=pagopaDel.doc_id
  --    and   sub.data_cancellazione is null
  --    and   sub.validita_fine is null
      );


      strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||' Aggiornamento stato documenti rimanenti in vita.';
      -- aggiornamento stato documenti per rimanenti in vita con quote
      -- esecuzione fnc per
      select
       fnc_pagopa_t_elaborazione_riconc_esegui_aggiorna_stato_doc
	   (
		pagopadoc.doc_id,
        filePagoPaElabId,
		enteProprietarioId,
		loginOperazione
		) into AggRec
	  from pagopa_bck_t_doc pagopadoc, pagopa_bck_t_subdoc pagopasub
      where pagopadoc.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopadoc.pagopa_elab_id=filePagoPaElabId
      and   pagopasub.pagopa_provc_id=pagopadoc.pagopa_provc_id
      and   pagopasub.pagopa_elab_id=pagopadoc.pagopa_elab_id
      and   pagopasub.doc_id=pagopadoc.doc_id
      and   pagopadoc.data_cancellazione is null
      and   pagopadoc.validita_fine is null
      and   pagopasub.data_cancellazione is null
      and   pagopasub.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - Fine cancellazione doc. - '||strMessaggioFinale;
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

	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||'Aggiornamento  pagopa_t_riconciliazione.';

      -- aggiornare pagopa_t_riconciliazione
      update pagopa_t_riconciliazione ric
      set    pagopa_ric_flusso_stato_elab='X',
             data_modifica=clock_timestamp(),
             pagopa_ric_errore_id=errore.pagopa_ric_errore_id
      from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc,
           pagopa_d_riconciliazione_errore errore, pagopa_bck_t_subdoc pagopa
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.pagopa_ric_doc_stato_elab='S'
      and   doc.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.subdoc_id=doc.pagopa_ric_doc_subdoc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   ric.pagopa_ric_id=doc.pagopa_ric_id
      and   errore.ente_proprietario_id=flusso.ente_proprietario_id
      and   errore.pagopa_ric_errore_code=PAGOPA_ERR_36
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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
	  strMessaggio:=strMessaggioBck;
      strMessaggio:=strMessaggio||'Aggiornamento  pagopa_t_riconciliazione_doc.';
      -- aggiornare pagopa_t_riconciliazione_doc
      update pagopa_t_riconciliazione_doc doc
      set    pagopa_ric_doc_stato_elab='X',
             pagopa_ric_doc_subdoc_id=null,
             pagopa_ric_doc_provc_id=null,
             pagopa_ric_doc_movgest_ts_id=null,
             data_modifica=clock_timestamp(),
             pagopa_ric_errore_id=errore.pagopa_ric_errore_id
      from pagopa_t_elaborazione_flusso flusso,
           pagopa_d_riconciliazione_errore errore, pagopa_bck_t_subdoc pagopa
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is not null
      and   doc.pagopa_ric_doc_stato_elab='S'
      and   doc.pagopa_ric_doc_provc_id=PagoPaRecClean.pagopa_provc_id
      and   pagopa.subdoc_id=doc.pagopa_ric_doc_subdoc_id
      and   pagopa.pagopa_elab_id=filePagoPaElabId
      and   pagopa.pagopa_provc_id=PagoPaRecClean.pagopa_provc_id
      and   errore.ente_proprietario_id=flusso.ente_proprietario_id
      and   errore.pagopa_ric_errore_code=PAGOPA_ERR_36
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null;

      strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||strMessaggioFinale||strMessaggio;
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

  end loop;

  /* sostituito con diagnostic dopo insert tabella
  strMessaggio:=' Verifica esistenza in pagopa_bck_t_subdoc a termine aggiornamento.';
  select (case when count(*)!=0 then true else false end ) into pagopaBckSubdoc
  from pagopa_bck_t_subdoc bck
  where bck.pagopa_elab_id=filePagoPaElabId
  and   bck.data_cancellazione is null
  and   bck.validita_fine is null;*/



  messaggioRisultato:='OK - '||upper(strMessaggioFinale);

  strMessaggioLog:='Fine fnc_pagopa_t_elaborazione_riconc_esegui_clean - '||messaggioRisultato;
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

alter function siac.fnc_pagopa_t_elaborazione_riconc_insert
(
  integer,
  varchar,
  varchar,
  varchar,
  varchar,
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER to siac;

alter function siac.fnc_pagopa_t_elaborazione_riconc_esegui
( integer, integer, integer , varchar , timestamp ,  
  out integer,
  out varchar) owner to siac;
  
  alter function siac.fnc_pagopa_t_elaborazione_riconc_esegui_clean
(
  integer,integer,integer,varchar,timestamp,
  out BOOLEAN,out integer,out varchar
)  OWNER to siac;

-- 09.07.2021 Sofia JIRA SIAC-8221 - fine

--SIAC-8285 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR120_Bilancio_Previsione_Entrate_per_Trasparenza" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_competenza varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_id integer,
  stanziamento_prev_anno numeric,
  cassa_prev_anno numeric,
  entrata_gest_sanitaria_anno_stanz numeric,
  entrata_gest_sanitaria_anno_cassa numeric,
  categoria_id numeric,
  denom_ente varchar
) AS
$body$
DECLARE
classifBilRec record;



annoCapImp varchar;
tipoImpComp varchar;
TipoImpstanzresidui varchar;
tipoImpCassa varchar;
TipoImpresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
v_fam_titolotipologiacategoria varchar:='00003';


BEGIN

annoCapImp:= p_anno_competenza;   

TipoImpComp='STA';  -- competenza
TipoImpresidui='SRI'; -- residui
TipoImpstanzresidui='STI'; -- stanziamento residuo
TipoImpCassa ='SCA'; ----- previsioni di cassa

elemTipoCode:='CAP-EP';

bil_anno='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_code='';
tipologia_desc='';
categoria_code='';
categoria_desc='';
bil_ele_id=0;

stanziamento_prev_anno=0;
cassa_prev_anno=0;
entrata_gest_sanitaria_anno_stanz=0;
entrata_gest_sanitaria_anno_cassa=0;
denom_ente='';

select fnc_siac_random_user()
into	user_table;



--06/09/2016: cambiata la query che carica la struttura di bilancio
--  per motivi prestazionali
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;
 

insert into siac_rep_cap_ep
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e, 
        siac_d_class_tipo ct,
		siac_t_class cl, 
        siac_t_bil bilancio, 
        siac_t_periodo anno_eserc, 
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code='CATEGORIA'
and ct.classif_tipo_id=cl.classif_tipo_id
and cl.classif_id=rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno= p_anno
and bilancio.periodo_id=anno_eserc.periodo_id 
and e.bil_id=bilancio.bil_id 
and e.elem_tipo_id=tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code = elemTipoCode
and e.elem_id=rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;


insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det 			capitolo_importi,
         	siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
         	siac_t_periodo 					capitolo_imp_periodo,
            siac_t_bil_elem 				capitolo,
            siac_d_bil_elem_tipo 			tipo_elemento,
            siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc, 
			siac_d_bil_elem_stato 			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
 	group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		stanziamento_prev_anno,
    	--tb2.importo 	as		stanziamento_prev_anno1,
    	--tb3.importo		as		stanziamento_prev_anno2,
        0, 0,
   	 	tb4.importo		as		residui_presunti,
    	tb5.importo		as		previsioni_anno_prec,
    	tb6.importo		as		stanziamento_prev_cassa_anno,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1,-- siac_rep_cap_ep_imp tb2, siac_rep_cap_ep_imp tb3,
	siac_rep_cap_ep_imp tb4, siac_rep_cap_ep_imp tb5, siac_rep_cap_ep_imp tb6
	where			tb1.elem_id	=	tb4.elem_id								and	
        			--tb2.elem_id	=	tb3.elem_id								and
        			--tb3.elem_id	=	tb4.elem_id								and
        			tb4.elem_id	=	tb5.elem_id								and
        			tb5.elem_id	=	tb6.elem_id								and
        			tb1.periodo_anno = annoCapImp		AND	tb1.tipo_imp =	TipoImpComp	AND
        			--tb2.periodo_anno = annoCapImp1		AND	tb1.tipo_imp =	tb2.tipo_imp	AND
        			--tb3.periodo_anno = annoCapImp2		AND	tb2.tipo_imp =	tb3.tipo_imp	AND
        			tb4.periodo_anno = tb1.periodo_anno	AND	tb4.tipo_imp = 	TipoImpresidui	AND
        			tb5.periodo_anno = tb1.periodo_anno	AND	tb5.tipo_imp = 	TipoImpstanzresidui	AND
        			tb6.periodo_anno = tb1.periodo_anno	AND	tb6.tipo_imp = 	TipoImpCassa
                    and tb1.utente 	= 	tb4.utente	
        			--and	tb2.utente	=	tb3.utente
        			--and	tb3.utente	=	tb4.utente
        			and	tb4.utente	=	tb5.utente
        			and tb5.utente	=	tb6.utente
        			and	tb6.utente	=	user_table;                 


insert into siac_rep_ep_imp_gest_sanit
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det 			capitolo_importi,
         	siac_d_bil_elem_det_tipo 		capitolo_imp_tipo,
         	siac_t_periodo 					capitolo_imp_periodo,
            siac_t_bil_elem 				capitolo,
            siac_d_bil_elem_tipo 			tipo_elemento,
            siac_t_bil 						bilancio,
	 		siac_t_periodo 					anno_eserc,
            siac_d_bil_elem_stato 			stato_capitolo, 
            siac_r_bil_elem_stato 			r_capitolo_stato,
			siac_d_bil_elem_categoria 		cat_del_capitolo, 
            siac_r_bil_elem_categoria 		r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno= p_anno 												
    	and	bilancio.periodo_id=anno_eserc.periodo_id 								
        and	capitolo.bil_id=bilancio.bil_id 			 
        and	capitolo.elem_id	=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code = elemTipoCode
        and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        and capitolo_importi.elem_id     in
        (select r_class.elem_id   
        from  	siac_r_bil_elem_class	r_class,
				siac_t_class 			b,
        		siac_d_class_tipo 		c
		where 	b.classif_id 		= 	r_class.classif_id
		and 	b.classif_tipo_id 	= 	c.classif_tipo_id
		and 	c.classif_tipo_code  = 'PERIMETRO_SANITARIO_ENTRATA'
       -- and		b.classif_desc	=	'Ricorrente'
        and	r_class.data_cancellazione				is null
        and	b.data_cancellazione					is null
        and c.data_cancellazione					is null
        --12/07/2021 SIAC-8285
        --Occorre prendere solo i capitolo che per l'attributo
        --PERIMETRO_SANITARIO_ENTRATA hanno il valore '2'.
        --and b.classif_code <> 'XX')
        and b.classif_code ='2')
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null            
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


insert into siac_rep_ep_imp_gest_sanit_riga
select  tb1.elem_id,      
    	tb1.importo 	as 		entrata_gest_sanit_comp_anno,
        0, 0,
    	tb2.importo 	as		entrata_gest_sanit_cassa_anno,
        0, 0,
    	tb3.importo		as		entrata_gest_sanit_resid_anno,
        0, 0,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_ep_imp_gest_sanit tb1, siac_rep_ep_imp_gest_sanit tb2, siac_rep_ep_imp_gest_sanit tb3
	where			tb1.elem_id	=	tb2.elem_id								and	
        			tb2.elem_id	=	tb3.elem_id								and
        			tb1.periodo_anno = annoCapImp	AND	tb1.tipo_imp =	TipoImpComp		AND
        			tb2.periodo_anno = annoCapImp	AND	tb2.tipo_imp =	TipoImpCassa	AND
        			tb3.periodo_anno = annoCapImp	AND	tb3.tipo_imp =	TipoImpstanzresidui
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	tb3.utente
        			and	tb3.utente	=	user_table;
    

for classifBilRec in
select 	t_ente_prop.ente_denominazione	denom_ente,
		v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
       	tb.elem_id   					bil_ele_id,
       	COALESCE (tb1.stanziamento_prev_anno,0)		stanziamento_prev_anno,
        COALESCE (tb1.stanziamento_prev_cassa_anno,0) cassa_prev_anno,
		--COALESCE (tb1.stanziamento_prev_anno1,0)	stanziamento_prev_anno1,
    	--COALESCE (tb1.stanziamento_prev_anno2,0)	stanziamento_prev_anno2,
        COALESCE (tb2.entrata_gest_sanit_comp_anno,0)	entrata_gest_sanit_comp_anno,
		COALESCE (tb2.entrata_gest_sanit_cassa_anno,0)	entrata_gest_sanit_cassa_anno
from	 siac_t_ente_proprietario t_ente_prop,
		 siac_rep_tit_tip_cat_riga_anni v1
			FULL  join siac_rep_cap_ep tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					-----and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_ep_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 	
            	and	tb.utente=user_table
                and tb1.utente	=	tb.utente)
            left 	join	siac_rep_ep_imp_gest_sanit_riga	tb2	
            on	(tb2.elem_id	=	tb.elem_id
            		and	tb1.utente=user_table
                    and tb1.utente	=	tb2.utente)
    where t_ente_prop.ente_proprietario_id= v1.ente_proprietario_id
    	and v1.utente = user_table 	
        and t_ente_prop.data_cancellazione IS NULL
			order by titoloe_CODE,tipologia_CODE,categoria_CODE                  
loop
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
categoria_id := classifBilRec.categoria_id;
bil_ele_id := classifBilRec.bil_ele_id;
stanziamento_prev_anno:=classifBilRec.stanziamento_prev_anno;
cassa_prev_anno=classifBilRec.cassa_prev_anno;
entrata_gest_sanitaria_anno_stanz=classifBilRec.entrata_gest_sanit_comp_anno;
entrata_gest_sanitaria_anno_cassa=classifBilRec.entrata_gest_sanit_cassa_anno;

denom_ente=classifBilRec.denom_ente;

return next;

bil_anno='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_code='';
tipologia_desc='';
categoria_code='';
categoria_desc='';
bil_ele_id=0;
stanziamento_prev_anno=0;
cassa_prev_anno=0;
entrata_gest_sanitaria_anno_stanz=0;
entrata_gest_sanitaria_anno_cassa=0;
denom_ente='';

end loop;

raise notice 'fine OK';

delete from siac_rep_tit_tip_cat_riga_anni		where utente=user_table;
delete from siac_rep_cap_ep 					where utente=user_table;
delete from siac_rep_cap_ep_imp 				where utente=user_table;
delete from siac_rep_cap_ep_imp_riga 			where utente=user_table;
delete from siac_rep_ep_imp_gest_sanit 			where utente=user_table;
delete from siac_rep_ep_imp_gest_sanit_riga 	where utente=user_table;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RTN_MESSAGGIO:='struttura bilancio altro errore';
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

--SIAC-8285 - Maurizio - FINE

-- 8216 inizio





/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/



drop FUNCTION IF EXISTS  siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, anno_atto_amm integer, numero_atto_amm integer, codice_soggetto text, id_modpag integer, login_oper text);

drop FUNCTION IF EXISTS  siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, id_attoamm integer, codice_soggetto text, id_modpag integer, login_oper text);

-- 04.08.2021 Sofia JIRA SIAC-8216
--CREATE OR REPLACE 
--FUNCTION siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, anno_atto_amm integer, numero_atto_amm integer, codice_soggetto text, id_modpag integer, login_oper text)
CREATE OR REPLACE 
FUNCTION siac.fnc_siac_bko_modifica_modpag_atto_amm(id_ente integer, id_bilancio integer, id_attoamm integer, codice_soggetto text, id_modpag integer, login_oper text)

 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE

atto_amministrativo siac_t_atto_amm%ROWTYPE;
liquidazione siac_t_liquidazione%ROWTYPE;
ordinativo siac_t_ordinativo%ROWTYPE;
soggetto siac_t_soggetto%ROWTYPE;
id_soggetto_relazione siac_r_soggetto_relaz.soggetto_relaz_id%type;


begin
	
	-- return 'MANUTENZIONE IN CORSO';

	
	/* 04.08.2021 Sofia JIRA SIAC-8216
	  select * into atto_amministrativo from siac_t_atto_amm staa, siac_d_atto_amm_tipo sdaat 
		where staa.attoamm_anno = CAST(anno_atto_amm AS varchar)
		and staa.attoamm_numero = numero_atto_amm
		and staa.ente_proprietario_id = id_ente
		and sdaat.attoamm_tipo_code = 'ALG' 
		AND sdaat.ente_proprietario_id= staa.ente_proprietario_id
		AND sdaat.attoamm_tipo_id = staa.attoamm_tipo_id;*/
	
	-- 04.08.2021 Sofia JIRA SIAC-8216
	select * into atto_amministrativo from siac_t_atto_amm staa, siac_d_atto_amm_tipo sdaat 
		WHERE staa.attoamm_id=id_attoamm
		and staa.ente_proprietario_id = id_ente
		AND sdaat.ente_proprietario_id= staa.ente_proprietario_id
		AND sdaat.attoamm_tipo_id = staa.attoamm_tipo_id;
	
	--return atto_amministrativo.attoamm_oggetto::text;

	select sts.* into soggetto from siac_t_soggetto sts, siac_d_ambito sda
		where sts.soggetto_code = codice_soggetto
		and sts.ente_proprietario_id = id_ente
		and sda.ambito_id = sts.ambito_id 
		and sda.ambito_code = 'AMBITO_FIN'
		and sda.ente_proprietario_id = sts.ente_proprietario_id
		and not exists (
			select 1 from siac_r_soggetto_relaz srsr, siac_d_relaz_tipo sdrt 
			where srsr.soggetto_id_a=sts.soggetto_id 
			and srsr.relaz_tipo_id=sdrt.relaz_tipo_id 
			and sdrt.relaz_tipo_code = 'SEDE_SECONDARIA'
			and sdrt.ente_proprietario_id = sts.ente_proprietario_id
		)
	;

	
	-- controlli
	
	select stl.* into liquidazione from 
		 siac_t_liquidazione stl, 
		 siac_r_liquidazione_atto_amm srlaa , 
		 siac_r_liquidazione_soggetto srls,
		 siac_r_liquidazione_stato srlst,  
		 siac_d_liquidazione_stato sdls
    where atto_amministrativo.attoamm_id = srlaa.attoamm_id
		and srlaa.liq_id = stl.liq_id
		and srlaa.data_cancellazione is null
		and srlaa.validita_fine is null
		and stl.liq_id = srls.liq_id
		and srls.soggetto_id = soggetto.soggetto_id
		and stl.liq_id = srlst.liq_id
		and srlst.data_cancellazione is NULL
		AND srlst.validita_inizio < CURRENT_TIMESTAMP    
		AND (srlst.validita_fine IS NULL OR srlst.validita_fine > CURRENT_TIMESTAMP)  
		and srlst.liq_stato_id = sdls.liq_stato_id
		and sdls.liq_stato_code != 'A'
		and sdls.ente_proprietario_id= id_ente
		and stl.bil_id = id_bilancio;
	

	if liquidazione is NULL then
		return 'la liquidazione associata non e'' presente sull''anno di bilancio corrente';
	end if;

		
	select sto.* into ordinativo from 
			siac_r_liquidazione_ord srlo, siac_t_ordinativo_ts stot, siac_t_ordinativo sto, siac_r_ordinativo_stato sros, siac_d_ordinativo_stato sdos 
		where srlo.liq_id = liquidazione.liq_id
		and stot.ord_ts_id=srlo.sord_id 
		and sto.ord_id=stot.ord_id 
		and sros.ord_id=sto.ord_id 
		and sdos.ord_stato_id=sros.ord_stato_id
		and sdos.ord_stato_code != 'A'
		AND sto.data_cancellazione is null   
		AND sto.validita_inizio < CURRENT_TIMESTAMP    
		AND (sto.validita_fine IS NULL OR sto.validita_fine > CURRENT_TIMESTAMP)  
		AND stot.data_cancellazione is null   
		AND stot.validita_inizio < CURRENT_TIMESTAMP    
		AND (stot.validita_fine IS NULL OR stot.validita_fine > CURRENT_TIMESTAMP)  
		AND sros.data_cancellazione is null   
		AND sros.validita_inizio < CURRENT_TIMESTAMP    
		AND (sros.validita_fine IS NULL OR sros.validita_fine > CURRENT_TIMESTAMP) 
		limit 1;

	if ordinativo.ord_id is not null then
		return 'la liquidazione ' || liquidazione.liq_anno || '/' || liquidazione.liq_numero || ' e'' associata all''ordinativo ' || ordinativo.ord_anno || '/' || ordinativo.ord_numero;
	end if;
	
	
	-- aggiornamenti
	
		update siac_r_subdoc_modpag srsm
		set    data_cancellazione=CURRENT_TIMESTAMP,
			   validita_fine=CURRENT_TIMESTAMP,
			   login_Operazione=login_oper
 		from siac_r_subdoc_atto_amm srsaa, siac_t_subdoc sts, 
 			siac_r_doc_sog srds 
 		where srsaa.attoamm_id = atto_amministrativo.attoamm_id 
		and srsaa.subdoc_id = sts.subdoc_id 
		and srds.doc_id = sts.doc_id 
		and soggetto.soggetto_id = srds.soggetto_id 
		and srsm.subdoc_id = sts.subdoc_id 
 		and srsaa.data_cancellazione is NULL
		AND srsaa.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsaa.validita_fine IS NULL OR srsaa.validita_fine > CURRENT_TIMESTAMP)  
 		and srsm.data_cancellazione is NULL
		AND srsm.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsm.validita_fine IS NULL OR srsm.validita_fine > CURRENT_TIMESTAMP)  
;



	insert into siac_r_subdoc_modpag
	(
		subdoc_id,
		modpag_id,
		validita_inizio,
		login_Operazione,
		ente_proprietario_id
	)
	select sts.subdoc_id,
		   id_modpag,
		   CURRENT_TIMESTAMP,
		   login_oper,
		   id_ente
	from siac_r_subdoc_atto_amm srsaa, 
		siac_t_subdoc sts,
		siac_t_doc std, 
		siac_r_doc_sog srds
	where atto_amministrativo.attoamm_id = srsaa.attoamm_id
		and srsaa.subdoc_id = sts.subdoc_id
		and sts.ente_proprietario_id = id_ente
		and sts.doc_id = std.doc_id
		and std.doc_id = srds.doc_id
		and std.ente_proprietario_id = id_ente
		and srds.soggetto_id = soggetto.soggetto_id
		and srsaa.data_cancellazione is NULL
		AND srsaa.validita_inizio < CURRENT_TIMESTAMP    
		AND (srsaa.validita_fine IS NULL OR srsaa.validita_fine > CURRENT_TIMESTAMP)  
		and srds.data_cancellazione is NULL
		AND srds.validita_inizio < CURRENT_TIMESTAMP    
		AND (srds.validita_fine IS NULL OR srds.validita_fine > CURRENT_TIMESTAMP)  
	;
	

	select srsr.soggetto_relaz_id into id_soggetto_relazione from siac_r_soggrel_modpag srsm, siac_r_soggetto_relaz srsr 
		where srsm.modpag_id = id_modpag
		and srsr.soggetto_relaz_id = srsm.soggetto_relaz_id 
		and srsr.soggetto_id_da = soggetto.soggetto_id;
	

	update siac_t_liquidazione stl
	   set modpag_id = case when id_soggetto_relazione is NULL then id_modpag else NULL end,
	   	   soggetto_relaz_id = case when id_soggetto_relazione is NULL then NULL else id_soggetto_relazione end, 
		   data_modifica = CURRENT_TIMESTAMP,
		   login_operazione = login_oper 
	from siac_r_liquidazione_atto_amm srlaa , 
		 siac_r_liquidazione_soggetto srls,
		 siac_r_liquidazione_stato srlst,  
		 siac_d_liquidazione_stato sdls
    where atto_amministrativo.attoamm_id = srlaa.attoamm_id
		and srlaa.liq_id = stl.liq_id
		and srlaa.data_cancellazione is null
		and srlaa.validita_fine is null
		and stl.liq_id = srls.liq_id
		and srls.soggetto_id = soggetto.soggetto_id
		and stl.bil_id = id_bilancio
		and stl.liq_id = srlst.liq_id
		and srlst.liq_stato_id = sdls.liq_stato_id
		and srlst.data_cancellazione is NULL
		AND srlst.validita_inizio < CURRENT_TIMESTAMP    
		AND (srlst.validita_fine IS NULL OR srlst.validita_fine > CURRENT_TIMESTAMP)  
		and sdls.liq_stato_code != 'A'
		and sdls.ente_proprietario_id=id_ente
	;

	--

	
    return null;

exception
        when others  THEN
            return SQLERRM;
END;
$function$
;

alter function
siac.fnc_siac_bko_modifica_modpag_atto_amm
(
 integer, integer, integer, text, integer, text) OWNER to siac;


 
 -- 8216 fine
 
 -- SIAC-8178 - Sofia 10.09.2021 - inizio
 insert into siac_t_attr 
(
	attr_code,
	attr_desc,
	attr_tipo_id,
	login_operazione,
	validita_inizio,
	ente_proprietario_id
)
select 'codVerbaleAccertamento',
       'Codice verbale accertamento',
       tipo.attr_tipo_id,
       'SIAC-8178',
        now(),
       tipo.ente_proprietario_id
from siac_d_attr_tipo tipo,siac_t_ente_proprietario ente 
where ente.ente_proprietario_id in (2,3,4,5,10,14,16)
and   tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.attr_tipo_code='X'
and   not exists
(
select 1
from siac_t_attr attr1
where attr1.attr_tipo_id=tipo.attr_tipo_id
and   attr1.attr_code='codVerbaleAccertamento'
and   attr1.data_cancellazione is null
);

select fnc_dba_add_column_params ('siac_dwh_accertamento',  'codice_verbale',  'VARCHAR(250)');

drop function if exists 
siac.fnc_siac_dwh_accertamento 
(
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_accertamento
( p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
 )
 RETURNS TABLE(esito varchar)
AS 
$body$
DECLARE

rec_movgest_ts_id record;
rec_classif_id record;
rec_classif_id_attr record;
rec_attr record;
rec_movgest_ts_id_dett record;
rec_movgest_ts_id_perimp record;
-- Variabili per campi estratti dal cursore rec_movgest_ts_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno VARCHAR := null;
v_fase_operativa_code VARCHAR := null;
v_fase_operativa_desc VARCHAR := null;
v_movgest_anno INTEGER := null;
v_movgest_numero NUMERIC := null;
v_movgest_desc VARCHAR := null;
v_movgest_ts_code VARCHAR := null;
v_movgest_ts_desc VARCHAR := null;
v_movgest_stato_code VARCHAR := null;
v_movgest_stato_desc VARCHAR := null;
v_data_scadenza TIMESTAMP := null;
v_parere_finanziario VARCHAR := null;
v_codice_capitolo VARCHAR := null;
v_codice_articolo VARCHAR := null;
v_codice_ueb VARCHAR := null;
v_descrizione_capitolo VARCHAR := null;
v_descrizione_articolo VARCHAR := null;
-- Variabili relative agli attributi associati a un movgest_ts_id
v_soggetto_id INTEGER := null;
v_codice_soggetto VARCHAR := null;
v_descrizione_soggetto VARCHAR := null;
v_codice_fiscale_soggetto VARCHAR := null;
v_codice_fiscale_estero_soggetto VARCHAR := null;
v_partita_iva_soggetto VARCHAR := null;
v_codice_classe_soggetto VARCHAR := null;
v_descrizione_classe_soggetto VARCHAR := null;
-- Variabili per classificatori in gerarchia
v_codice_pdc_finanziario_I VARCHAR := null;
v_descrizione_pdc_finanziario_I VARCHAR := null;
v_codice_pdc_finanziario_II VARCHAR := null;
v_descrizione_pdc_finanziario_II VARCHAR := null;
v_codice_pdc_finanziario_III VARCHAR := null;
v_descrizione_pdc_finanziario_III VARCHAR := null;
v_codice_pdc_finanziario_IV VARCHAR := null;
v_descrizione_pdc_finanziario_IV VARCHAR := null;
v_codice_pdc_finanziario_V VARCHAR := null;
v_descrizione_pdc_finanziario_V VARCHAR := null;
v_codice_pdc_economico_I VARCHAR := null;
v_descrizione_pdc_economico_I VARCHAR := null;
v_codice_pdc_economico_II VARCHAR := null;
v_descrizione_pdc_economico_II VARCHAR := null;
v_codice_pdc_economico_III VARCHAR := null;
v_descrizione_pdc_economico_III VARCHAR := null;
v_codice_pdc_economico_IV VARCHAR := null;
v_descrizione_pdc_economico_IV VARCHAR := null;
v_codice_pdc_economico_V VARCHAR := null;
v_descrizione_pdc_economico_V VARCHAR := null;
v_codice_cofog_divisione VARCHAR := null;
v_descrizione_cofog_divisione VARCHAR := null;
v_codice_cofog_gruppo VARCHAR := null;
v_descrizione_cofog_gruppo VARCHAR := null;
-- Variabili per classificatori non in gerarchia
v_codice_entrata_ricorrente VARCHAR := null;
v_descrizione_entrata_ricorrente VARCHAR := null;
v_codice_transazione_entrata_ue VARCHAR := null;
v_descrizione_transazione_entrata_ue VARCHAR := null;
v_codice_perimetro_sanitario_entrata VARCHAR := null;
v_descrizione_perimetro_sanitario_entrata VARCHAR := null;
v_classificatore_generico_1 VARCHAR := null;
v_classificatore_generico_1_descrizione_valore VARCHAR := null;
v_classificatore_generico_1_valore VARCHAR := null;
v_classificatore_generico_2 VARCHAR := null;
v_classificatore_generico_2_descrizione_valore VARCHAR := null;
v_classificatore_generico_2_valore VARCHAR := null;
v_classificatore_generico_3 VARCHAR := null;
v_classificatore_generico_3_descrizione_valore VARCHAR := null;
v_classificatore_generico_3_valore VARCHAR := null;
v_classificatore_generico_4 VARCHAR := null;
v_classificatore_generico_4_descrizione_valore VARCHAR := null;
v_classificatore_generico_4_valore VARCHAR := null;
v_classificatore_generico_5 VARCHAR := null;
v_classificatore_generico_5_descrizione_valore VARCHAR := null;
v_classificatore_generico_5_valore VARCHAR := null;
-- Variabili attributo
v_annoCapitoloOrigine VARCHAR := null;
v_numeroCapitoloOrigine VARCHAR := null;
v_annoOriginePlur VARCHAR := null;
v_numeroArticoloOrigine VARCHAR := null;
v_annoRiaccertato VARCHAR := null;
v_numeroRiaccertato VARCHAR := null;
v_numeroOriginePlur VARCHAR := null;
v_flagDaRiaccertamento VARCHAR := null;

-- 19.02.2020 Sofia jira siac-7292
v_flagDaReanno VARCHAR := null;

v_automatico VARCHAR := null;
v_note VARCHAR := null;
v_validato VARCHAR := null;
v_numero_ueb_origine VARCHAR := null;
v_anno_atto_amministrativo VARCHAR := null;
v_numero_atto_amministrativo INTEGER := null;
v_oggetto_atto_amministrativo VARCHAR := null;
v_note_atto_amministrativo VARCHAR := null;
v_codice_tipo_atto_amministrativo VARCHAR := null;
v_descrizione_tipo_atto_amministrativo VARCHAR := null;
v_descrizione_stato_atto_amministrativo VARCHAR := null;
v_cod_cdr_atto_amministrativo VARCHAR := null;
v_desc_cdr_atto_amministrativo VARCHAR := null;
v_cod_cdc_atto_amministrativo VARCHAR := null;
v_desc_cdc_atto_amministrativo VARCHAR := null;
-- Variabili di dettaglio
v_importo_iniziale NUMERIC := null;
v_importo_attuale NUMERIC := null;
v_importo_utilizzabile NUMERIC := null;
v_importo_emesso NUMERIC := null;
v_importo_quietanziato NUMERIC := null;
v_importo_emesso_tot NUMERIC := null;
v_importo_quietanziato_tot NUMERIC := null;

v_classif_code VARCHAR := null;
v_classif_desc VARCHAR := null;
v_classif_tipo_code VARCHAR := null;
v_classif_tipo_desc VARCHAR := null;
v_flag_attributo VARCHAR := null;
v_movgest_ts_tipo_code VARCHAR := null;

v_movgest_id INTEGER := null;
v_movgest_ts_id INTEGER := null;
v_classif_id INTEGER := null;
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_classif_tipo_id INTEGER := null;
v_classif_fam_id INTEGER := null;
v_conta_ciclo_classif INTEGER := null;
v_bil_id INTEGER := null;
v_attoamm_id INTEGER := null;

v_fnc_result VARCHAR := null;

--nuova sezione coge 26-09-2016
v_FlagCollegamentoAccertamentoFattura VARCHAR := null;

-- 04.06.2018 Sofia siac-6220
v_FlagAttivaGsa VARCHAR := null;

-- SIAC-7541 27.04.2020 Sofia
v_codice_cdr_competente varchar:=null;
v_descrizione_cdr_competente varchar:=null;
v_codice_cdc_competente varchar:=null;
v_descrizione_cdc_competente varchar:=null;

v_data_inizio_val_stato_subaccer TIMESTAMP := null;
v_data_inizio_val_stato_accer TIMESTAMP := null;
v_data_creazione_subaccer TIMESTAMP := null;
v_data_inizio_val_subaccer TIMESTAMP := null;
v_data_modifica_subaccer TIMESTAMP := null;
v_data_creazione_accer TIMESTAMP := null;
v_data_inizio_val_accer TIMESTAMP := null;
v_data_modifica_accer TIMESTAMP := null;

v_programma_code VARCHAR := null;
v_programma_desc VARCHAR := null;

-- 23.10.2018 Sofia jira SIAC-6336
v_programma_stato varchar:=null;
v_versione_cronop varchar:=null;
v_desc_cronop varchar:=null;
v_anno_cronop varchar:=null;
v_programma_id integer:=null;

-- SIAC-8171 06.09.2021 Sofia
v_codice_verbale varchar:=NULL;

v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;


select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_accertamento',
params,
clock_timestamp(),
v_user_table
);



select fnc_siac_bko_popola_siac_r_class_fam_class_tipo(p_ente_proprietario_id)
into v_fnc_result;

esito:= 'Inizio funzione carico accertamenti (FNC_SIAC_DWH_ACCERTAMENTO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_accertamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
DELETE FROM siac.siac_dwh_subaccertamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre movgest_ts_id
FOR rec_movgest_ts_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tm.movgest_anno, tm.movgest_numero, tm.movgest_desc, tmt.movgest_ts_code, tmt.movgest_ts_desc, dms.movgest_stato_code, dms.movgest_stato_desc,
       tmt.movgest_ts_scadenza_data, tm.parere_finanziario, tm.movgest_id, tmt.movgest_ts_id, dmtt.movgest_ts_tipo_code,
       tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, tb.bil_id,
       rmts.validita_inizio as data_inizio_val_stato_subaccer,
       tmt.data_creazione as data_creazione_subaccer,
       tmt.validita_inizio as  data_inizio_val_subaccer,
       tmt.data_modifica as data_modifica_subaccer,
       tm.data_creazione as data_creazione_accer,
       tm.validita_inizio as data_inizio_val_accer,
       tm.data_modifica as data_modifica_accer
FROM   siac.siac_t_movgest_ts tmt
INNER JOIN  siac.siac_t_movgest tm ON  tm.movgest_id = tmt.movgest_id
INNER JOIN  siac.siac_t_bil tb ON tm.bil_id = tb.bil_id
INNER JOIN  siac.siac_t_periodo tp ON tp.periodo_id = tb.periodo_id
INNER JOIN  siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = tm.ente_proprietario_id
INNER JOIN  siac.siac_d_movgest_tipo dmt ON tm.movgest_tipo_id = dmt.movgest_tipo_id
INNER JOIN  siac.siac_d_movgest_ts_tipo dmtt ON tmt.movgest_ts_tipo_id = dmtt.movgest_ts_tipo_id
INNER JOIN  siac.siac_r_movgest_ts_stato rmts ON rmts.movgest_ts_id = tmt.movgest_ts_id
INNER JOIN  siac.siac_d_movgest_stato dms ON rmts.movgest_stato_id = dms.movgest_stato_id
LEFT JOIN   siac.siac_r_movgest_bil_elem rmbe ON rmbe.movgest_id = tm.movgest_id
                                              AND p_data BETWEEN rmbe.validita_inizio AND COALESCE(rmbe.validita_fine, p_data)
                                              AND rmbe.data_cancellazione IS NULL
LEFT JOIN  siac.siac_t_bil_elem tbe ON rmbe.elem_id = tbe.elem_id
                                    AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
                                    AND tbe.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
--and tm.movgest_anno::integer=2020
--and tm.movgest_numero::integer=1901
AND dmt.movgest_tipo_code = 'A'
AND p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
AND tmt.data_cancellazione IS NULL
AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
AND tm.data_cancellazione IS NULL
AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
AND tb.data_cancellazione IS NULL
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN dmt.validita_inizio AND COALESCE(dmt.validita_fine, p_data)
AND dmt.data_cancellazione IS NULL
AND p_data BETWEEN dmtt.validita_inizio AND COALESCE(dmtt.validita_fine, p_data)
AND dmtt.data_cancellazione IS NULL
AND p_data BETWEEN rmts.validita_inizio AND COALESCE(rmts.validita_fine, p_data)
AND rmts.data_cancellazione IS NULL
AND p_data BETWEEN dms.validita_inizio AND COALESCE(dms.validita_fine, p_data)
AND dms.data_cancellazione IS NULL

LOOP

v_ente_proprietario_id := null;
v_ente_denominazione := null;
v_anno := null;
v_fase_operativa_code := null;
v_fase_operativa_desc := null;
v_movgest_anno := null;
v_movgest_numero := null;
v_movgest_desc := null;
v_movgest_ts_code := null;
v_movgest_ts_desc := null;
v_movgest_stato_code := null;
v_movgest_stato_desc := null;
v_data_scadenza := null;
v_parere_finanziario := null;
v_codice_capitolo := null;
v_codice_articolo := null;
v_codice_ueb := null;
v_descrizione_capitolo := null;
v_descrizione_articolo := null;
v_soggetto_id := null;
v_codice_soggetto := null;
v_descrizione_soggetto := null;
v_codice_fiscale_soggetto := null;
v_codice_fiscale_estero_soggetto := null;
v_partita_iva_soggetto := null;
v_codice_classe_soggetto := null;
v_descrizione_classe_soggetto := null;
v_codice_entrata_ricorrente := null;
v_descrizione_entrata_ricorrente := null;
v_codice_transazione_entrata_ue := null;
v_descrizione_transazione_entrata_ue := null;
v_codice_perimetro_sanitario_entrata := null;
v_descrizione_perimetro_sanitario_entrata := null;
v_codice_pdc_finanziario_I := null;
v_descrizione_pdc_finanziario_I := null;
v_codice_pdc_finanziario_II := null;
v_descrizione_pdc_finanziario_II := null;
v_codice_pdc_finanziario_III  := null;
v_descrizione_pdc_finanziario_III := null;
v_codice_pdc_finanziario_IV := null;
v_descrizione_pdc_finanziario_IV := null;
v_codice_pdc_finanziario_V := null;
v_descrizione_pdc_finanziario_V := null;
v_codice_pdc_economico_I := null;
v_descrizione_pdc_economico_I := null;
v_codice_pdc_economico_II := null;
v_descrizione_pdc_economico_II := null;
v_codice_pdc_economico_III := null;
v_descrizione_pdc_economico_III := null;
v_codice_pdc_economico_IV:= null;
v_descrizione_pdc_economico_IV := null;
v_codice_pdc_economico_V := null;
v_descrizione_pdc_economico_V := null;
v_codice_cofog_divisione:= null;
v_descrizione_cofog_divisione := null;
v_codice_cofog_gruppo := null;
v_descrizione_cofog_gruppo := null;
v_importo_iniziale := null;
v_importo_attuale := null;
v_importo_utilizzabile := null;
v_importo_emesso := null;
v_importo_quietanziato := null;

v_movgest_id := null;
v_movgest_ts_id := null;
v_movgest_ts_tipo_code := null;
v_classif_id := null;
v_classif_tipo_id := null;
v_bil_id := null;

v_data_inizio_val_stato_subaccer := null;
v_data_inizio_val_stato_accer := null;
v_data_creazione_subaccer := null;
v_data_inizio_val_subaccer := null;
v_data_modifica_subaccer := null;
v_data_creazione_accer := null;
v_data_inizio_val_accer := null;
v_data_modifica_accer := null;

v_ente_proprietario_id := rec_movgest_ts_id.ente_proprietario_id;
v_ente_denominazione := rec_movgest_ts_id.ente_denominazione;
v_anno := rec_movgest_ts_id.anno;
v_movgest_anno := rec_movgest_ts_id.movgest_anno;
v_movgest_numero := rec_movgest_ts_id.movgest_numero;
v_movgest_desc := rec_movgest_ts_id.movgest_desc;
v_movgest_ts_code := rec_movgest_ts_id.movgest_ts_code;
v_movgest_ts_desc := rec_movgest_ts_id.movgest_ts_desc;
v_movgest_stato_code := rec_movgest_ts_id.movgest_stato_code;
v_movgest_stato_desc := rec_movgest_ts_id.movgest_stato_desc;
IF rec_movgest_ts_id.parere_finanziario = 'FALSE' THEN
   v_parere_finanziario := 'F';
ELSE
   v_parere_finanziario := 'T';
END IF;
v_data_scadenza := rec_movgest_ts_id.movgest_ts_scadenza_data;
v_codice_capitolo := rec_movgest_ts_id.elem_code;
v_codice_articolo := rec_movgest_ts_id.elem_code2;
v_codice_ueb := rec_movgest_ts_id.elem_code3;
v_descrizione_capitolo := rec_movgest_ts_id.elem_desc;
v_descrizione_articolo := rec_movgest_ts_id.elem_desc2;

v_movgest_id := rec_movgest_ts_id.movgest_id;
v_movgest_ts_id := rec_movgest_ts_id.movgest_ts_id;
v_movgest_ts_tipo_code := rec_movgest_ts_id.movgest_ts_tipo_code;
v_bil_id := rec_movgest_ts_id.bil_id;

v_data_inizio_val_stato_subaccer := rec_movgest_ts_id.data_inizio_val_stato_subaccer;
v_data_inizio_val_stato_accer := rec_movgest_ts_id.data_inizio_val_stato_subaccer;
v_data_creazione_subaccer := rec_movgest_ts_id.data_creazione_subaccer;
v_data_inizio_val_subaccer := rec_movgest_ts_id.data_inizio_val_subaccer;
v_data_modifica_subaccer := rec_movgest_ts_id.data_modifica_subaccer;
v_data_creazione_accer := rec_movgest_ts_id.data_creazione_accer;
v_data_inizio_val_accer := rec_movgest_ts_id.data_inizio_val_accer;
v_data_modifica_accer := rec_movgest_ts_id.data_modifica_accer;

esito:= '  Inizio ciclo movgest - movgest_ts_id ('||v_movgest_id||') - ('||v_movgest_ts_id||') - ('||v_movgest_ts_tipo_code||') - '||clock_timestamp();
return next;
-- Sezione per estrarre la fase operativa
SELECT dfo.fase_operativa_code, dfo.fase_operativa_desc
INTO v_fase_operativa_code, v_fase_operativa_desc
FROM siac.siac_r_bil_fase_operativa rbfo, siac.siac_d_fase_operativa dfo
WHERE dfo.fase_operativa_id = rbfo.fase_operativa_id
AND   rbfo.bil_id = v_bil_id
AND   p_data BETWEEN rbfo.validita_inizio AND COALESCE(rbfo.validita_fine, p_data)
AND   p_data BETWEEN dfo.validita_inizio AND COALESCE(dfo.validita_fine, p_data)
AND   rbfo.data_cancellazione IS NULL
AND   dfo.data_cancellazione IS NULL;
-- Sezione per estrarre i dati del soggetto associati ad un movgest_ts_id
SELECT ts.soggetto_code, ts.soggetto_desc, ts.codice_fiscale, ts.codice_fiscale_estero, ts.partita_iva, ts.soggetto_id
INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto, v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id
FROM siac.siac_r_movgest_ts_sog rmts, siac.siac_t_soggetto ts
WHERE rmts.soggetto_id = ts.soggetto_id
AND   rmts.movgest_ts_id = v_movgest_ts_id
AND   p_data BETWEEN rmts.validita_inizio AND COALESCE(rmts.validita_fine, p_data)
AND   p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND   rmts.data_cancellazione IS NULL
AND   ts.data_cancellazione IS NULL;
-- Sezione per estrarre i dati di classe del soggetto associati ad un movgest_ts_id
SELECT dsc.soggetto_classe_code, dsc.soggetto_classe_desc
INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac.siac_r_movgest_ts_sogclasse rmts, siac.siac_d_soggetto_classe dsc
WHERE rmts.soggetto_classe_id = dsc.soggetto_classe_id
AND   rmts.movgest_ts_id = v_movgest_ts_id
AND   p_data BETWEEN rmts.validita_inizio AND COALESCE(rmts.validita_fine, p_data)
AND   p_data BETWEEN dsc.validita_inizio AND COALESCE(dsc.validita_fine, p_data)
AND   rmts.data_cancellazione IS NULL
AND   dsc.data_cancellazione IS NULL;

v_classificatore_generico_1:= null;
v_classificatore_generico_1_descrizione_valore:= null;
v_classificatore_generico_1_valore:= null;
v_classificatore_generico_2:= null;
v_classificatore_generico_2_descrizione_valore:= null;
v_classificatore_generico_2_valore:= null;
v_classificatore_generico_3:= null;
v_classificatore_generico_3_descrizione_valore:= null;
v_classificatore_generico_3_valore:= null;
v_classificatore_generico_4:= null;
v_classificatore_generico_4_descrizione_valore:= null;
v_classificatore_generico_4_valore:= null;
v_classificatore_generico_5:= null;
v_classificatore_generico_5_descrizione_valore:= null;
v_classificatore_generico_5_valore:= null;


-- Ciclo per estrarre i classificatori relativi ad un dato movimento
FOR rec_classif_id IN
SELECT tc.classif_id, tc.classif_tipo_id,
       tc.classif_code, tc.classif_desc, dct.classif_tipo_code,dct.classif_tipo_desc
FROM  siac.siac_r_movgest_class rmc, siac.siac_t_class tc, siac.siac_d_class_tipo dct
WHERE tc.classif_id = rmc.classif_id
AND   dct.classif_tipo_id = tc.classif_tipo_id
AND   rmc.movgest_ts_id = v_movgest_ts_id
AND   rmc.data_cancellazione IS NULL
AND   tc.data_cancellazione IS NULL
AND   dct.data_cancellazione IS NULL
AND   p_data BETWEEN rmc.validita_inizio AND COALESCE(rmc.validita_fine, p_data)
AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)

LOOP

v_classif_id :=  rec_classif_id.classif_id;
v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
v_classif_fam_id := null;

-- Estrazione per determinare se un classificatore e' in gerarchia
SELECT rcfct.classif_fam_id
INTO v_classif_fam_id
FROM siac.siac_r_class_fam_class_tipo rcfct
WHERE rcfct.classif_tipo_id = v_classif_tipo_id
AND   rcfct.data_cancellazione IS NULL
AND   p_data BETWEEN rcfct.validita_inizio AND COALESCE(rcfct.validita_fine, p_data);

-- Se il classificatore non e' in gerarchia
IF NOT FOUND THEN
  esito:= '    Inizio step classificatori non in gerarchia - '||clock_timestamp();
  return next;
  v_classif_tipo_code := null;
  v_classif_tipo_desc :=null;
  v_classif_code := rec_classif_id.classif_code;
  v_classif_desc := rec_classif_id.classif_desc;

  SELECT dct.classif_tipo_code,dct.classif_tipo_desc
  INTO   v_classif_tipo_code,v_classif_tipo_desc
  FROM   siac.siac_d_class_tipo dct
  WHERE  dct.classif_tipo_id = v_classif_tipo_id
  AND    dct.data_cancellazione IS NULL
  AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'RICORRENTE_ENTRATA' THEN
     v_codice_entrata_ricorrente      := v_classif_code;
     v_descrizione_entrata_ricorrente := v_classif_desc;
  ELSIF v_classif_tipo_code = 'TRANSAZIONE_UE_ENTRATA' THEN
     v_codice_transazione_entrata_ue      := v_classif_code;
     v_descrizione_transazione_entrata_ue := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PERIMETRO_SANITARIO_ENTRATA' THEN
     v_codice_perimetro_sanitario_entrata      := v_classif_code;
     v_descrizione_perimetro_sanitario_entrata := v_classif_desc;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_16' THEN
     v_classificatore_generico_1      := v_classif_tipo_desc;
     v_classificatore_generico_1_descrizione_valore := v_classif_desc;
     v_classificatore_generico_1_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_17' THEN
     v_classificatore_generico_2     := v_classif_tipo_desc;
     v_classificatore_generico_2_descrizione_valore := v_classif_desc;
     v_classificatore_generico_2_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_18' THEN
     v_classificatore_generico_3      := v_classif_tipo_desc;
     v_classificatore_generico_3_descrizione_valore := v_classif_desc;
     v_classificatore_generico_3_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_19' THEN
     v_classificatore_generico_4     := v_classif_tipo_desc;
     v_classificatore_generico_4_descrizione_valore := v_classif_desc;
     v_classificatore_generico_4_valore      := v_classif_code;
  ELSIF v_classif_tipo_code = 'CLASSIFICATORE_20' THEN
     v_classificatore_generico_5     := v_classif_tipo_desc;
     v_classificatore_generico_5_descrizione_valore := v_classif_desc;
     v_classificatore_generico_5_valore      := v_classif_code;
  END IF;
  esito:= '    Fine step classificatori non in gerarchia - '||clock_timestamp();
  return next;
-- Se il classificatore e' in gerarchia
ELSE
 esito:= '    Inizio step classificatori in gerarchia - '||clock_timestamp();
 return next;
 v_conta_ciclo_classif :=0;
 v_classif_id_padre := null;

 -- Loop per RISALIRE la gerarchia di un dato classificatore
 LOOP

  v_classif_code := null;
  v_classif_desc := null;
  v_classif_id_part := null;
  v_classif_tipo_code := null;
  v_classif_tipo_desc := null;

  IF v_conta_ciclo_classif = 0 THEN
     v_classif_id_part := v_classif_id;
  ELSE
     v_classif_id_part := v_classif_id_padre;
  END IF;

  SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code,dct.classif_tipo_desc
  INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code,v_classif_tipo_desc
  FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
  WHERE rcft.classif_id = tc.classif_id
  AND   dct.classif_tipo_id = tc.classif_tipo_id
  AND   tc.classif_id = v_classif_id_part
  AND   rcft.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   dct.data_cancellazione IS NULL
  AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
  AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

  IF v_classif_tipo_code = 'PDC_I' THEN
        v_codice_pdc_finanziario_I := v_classif_code;
        v_descrizione_pdc_finanziario_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_II' THEN
        v_codice_pdc_finanziario_II := v_classif_code;
        v_descrizione_pdc_finanziario_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_III' THEN
        v_codice_pdc_finanziario_III := v_classif_code;
        v_descrizione_pdc_finanziario_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_IV' THEN
        v_codice_pdc_finanziario_IV := v_classif_code;
        v_descrizione_pdc_finanziario_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PDC_V' THEN
        v_codice_pdc_finanziario_V := v_classif_code;
        v_descrizione_pdc_finanziario_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_I' THEN
        v_codice_pdc_economico_I := v_classif_code;
        v_descrizione_pdc_economico_I := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_II' THEN
        v_codice_pdc_economico_II := v_classif_code;
        v_descrizione_pdc_economico_II := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_III' THEN
        v_codice_pdc_economico_III := v_classif_code;
        v_descrizione_pdc_economico_III := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_IV' THEN
        v_codice_pdc_economico_IV := v_classif_code;
        v_descrizione_pdc_economico_IV := v_classif_desc;
  ELSIF v_classif_tipo_code = 'PCE_V' THEN
        v_codice_pdc_economico_V := v_classif_code;
        v_descrizione_pdc_economico_V := v_classif_desc;
  ELSIF v_classif_tipo_code = 'DIVISIONE_COFOG' THEN
        v_codice_cofog_divisione := v_classif_code;
        v_descrizione_cofog_divisione := v_classif_desc;
  ELSIF v_classif_tipo_code = 'GRUPPO_COFOG' THEN
        v_codice_cofog_gruppo := v_classif_code;
        v_descrizione_cofog_gruppo := v_classif_desc;
  END IF;

  v_conta_ciclo_classif := v_conta_ciclo_classif +1;
  EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
 esito:= '    Fine step classificatori in gerarchia - '||clock_timestamp();
 return next;
END IF;
END LOOP;

-- Sezione pe gli attributi
v_annoCapitoloOrigine := null;
v_numeroCapitoloOrigine := null;
v_annoOriginePlur := null;
v_numeroArticoloOrigine := null;
v_annoRiaccertato := null;
v_numeroRiaccertato := null;
v_numeroOriginePlur := null;
v_flagDaRiaccertamento := null;

-- 19.02.2020 Sofia jira siac-7292
v_flagDaReanno := null;

v_automatico := null;
v_note := null;
v_validato := null;
v_numero_ueb_origine := null;
v_anno_atto_amministrativo := null;
v_numero_atto_amministrativo := null;
v_oggetto_atto_amministrativo := null;
v_note_atto_amministrativo := null;
v_codice_tipo_atto_amministrativo := null;
v_descrizione_tipo_atto_amministrativo := null;
v_descrizione_stato_atto_amministrativo := null;
v_cod_cdr_atto_amministrativo := null;
v_desc_cdr_atto_amministrativo := null;
v_cod_cdc_atto_amministrativo := null;
v_desc_cdc_atto_amministrativo := null;
v_attoamm_id := null;

v_flag_attributo := null;

--nuova sezione coge 26-09-2016
v_FlagCollegamentoAccertamentoFattura  := null;

-- 04.06.2018 Sofia siac-6220
v_FlagAttivaGsa  := null;


-- 06.09.2021 Sofia siac-8171
v_codice_verbale:=NULL;

-- Ciclo per estrarre gli attibuti relativi ad un movgest_ts_id
FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rmta.tabella_id, rmta.percentuale, rmta."boolean" true_false, rmta.numerico, rmta.testo
FROM   siac.siac_r_movgest_ts_attr rmta, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rmta.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rmta.movgest_ts_id = v_movgest_ts_id
AND    rmta.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rmta.validita_inizio AND COALESCE(rmta.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'annoCapitoloOrigine' THEN
     v_annoCapitoloOrigine := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroCapitoloOrigine' THEN
     v_numeroCapitoloOrigine := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'annoOriginePlur' THEN
     v_annoOriginePlur := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroArticoloOrigine' THEN
     v_numeroArticoloOrigine := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'annoRiaccertato' THEN
     v_annoRiaccertato := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroRiaccertato' THEN
     v_numeroRiaccertato := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroOriginePlur' THEN
     v_numeroOriginePlur := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'flagDaRiaccertamento' THEN
     v_flagDaRiaccertamento := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'flagDaReanno' THEN -- 19.02.2020 Sofia jira siac-7292
     v_flagDaReanno := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'numeroUEBOrigine' THEN
     v_numero_ueb_origine := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'ACC_AUTO' THEN
     v_automatico := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'NOTE_MOVGEST' THEN
     v_note := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'validato' THEN
     v_validato := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'FlagCollegamentoAccertamentoFattura' THEN
     v_FlagCollegamentoAccertamentoFattura := v_flag_attributo;
     --nuova sezione coge 26-09-2016
  ELSIF rec_attr.attr_code = 'FlagAttivaGsa' THEN
     v_FlagAttivaGsa := v_flag_attributo;
     --nuova sezione GSA 04.06.2018 Sofia siac-6220
  elsif rec_attr.attr_code='codVerbaleAccertamento' THEN   -- 06.09.2021 Sofia SIAC-8171
     v_codice_verbale:=v_flag_attributo;

  END IF;

END LOOP;
-- Sezione pe i dati amministrativi
SELECT taa.attoamm_anno, taa.attoamm_numero, taa.attoamm_oggetto, taa.attoamm_note,
       daat.attoamm_tipo_code, daat.attoamm_tipo_desc, daas.attoamm_stato_desc, taa.attoamm_id
INTO   v_anno_atto_amministrativo, v_numero_atto_amministrativo, v_oggetto_atto_amministrativo,
       v_note_atto_amministrativo, v_codice_tipo_atto_amministrativo,
       v_descrizione_tipo_atto_amministrativo, v_descrizione_stato_atto_amministrativo, v_attoamm_id
FROM siac.siac_r_movgest_ts_atto_amm rmtaa, siac.siac_t_atto_amm taa, siac.siac_r_atto_amm_stato raas, siac.siac_d_atto_amm_stato daas,
     siac.siac_d_atto_amm_tipo daat
WHERE taa.attoamm_id = rmtaa.attoamm_id
AND   taa.attoamm_id = raas.attoamm_id
AND   raas.attoamm_stato_id = daas.attoamm_stato_id
AND   taa.attoamm_tipo_id = daat.attoamm_tipo_id
AND   rmtaa.movgest_ts_id = v_movgest_ts_id
AND   rmtaa.data_cancellazione IS NULL
AND   taa.data_cancellazione IS NULL
AND   raas.data_cancellazione IS NULL
AND   daas.data_cancellazione IS NULL
AND   daat.data_cancellazione IS NULL
AND   p_data BETWEEN rmtaa.validita_inizio AND COALESCE(rmtaa.validita_fine, p_data)
AND   p_data BETWEEN taa.validita_inizio AND COALESCE(taa.validita_fine, p_data)
AND   p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
AND   p_data BETWEEN daas.validita_inizio AND COALESCE(daas.validita_fine, p_data)
AND   p_data BETWEEN daat.validita_inizio AND COALESCE(daat.validita_fine, p_data);

-- Sezione per i classificatori legati agli atti amministrativi
esito:= '    Inizio step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
return next;
FOR rec_classif_id_attr IN
SELECT raac.classif_id
FROM  siac.siac_r_atto_amm_class raac
WHERE raac.attoamm_id = v_attoamm_id
AND   raac.data_cancellazione IS NULL
AND   p_data BETWEEN raac.validita_inizio AND COALESCE(raac.validita_fine, p_data)

LOOP

  v_conta_ciclo_classif :=0;
  v_classif_id_padre := null;

  -- Loop per RISALIRE la gerarchia di un dato classificatore
  LOOP

      v_classif_code := null;
      v_classif_desc := null;
      v_classif_id_part := null;
      v_classif_tipo_code := null;
      v_classif_tipo_desc := null;

      IF v_conta_ciclo_classif = 0 THEN
         v_classif_id_part := rec_classif_id_attr.classif_id;
      ELSE
         v_classif_id_part := v_classif_id_padre;
      END IF;

      SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code,dct.classif_tipo_desc
      INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code,v_classif_tipo_desc
      FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
      WHERE rcft.classif_id = tc.classif_id
      AND   dct.classif_tipo_id = tc.classif_tipo_id
      AND   tc.classif_id = v_classif_id_part
      AND   rcft.data_cancellazione IS NULL
      AND   tc.data_cancellazione IS NULL
      AND   dct.data_cancellazione IS NULL;
      -- 27.11.2018 Sofia siac-6573
--      AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
--      AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
--      AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

      IF v_classif_tipo_code = 'CDR' THEN
         v_cod_cdr_atto_amministrativo := v_classif_code;
         v_desc_cdr_atto_amministrativo := v_classif_desc;
      ELSIF v_classif_tipo_code = 'CDC' THEN
         v_cod_cdc_atto_amministrativo := v_classif_code;
         v_desc_cdc_atto_amministrativo := v_classif_desc;
      END IF;

      v_conta_ciclo_classif := v_conta_ciclo_classif +1;
      EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
END LOOP;
esito:= '    Fine step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
return next;

-- Sezione per i dati di dettaglio associati ad un movgest_ts_id
FOR rec_movgest_ts_id_dett IN
SELECT COALESCE(SUM(tmtd.movgest_ts_det_importo),0) importo, dmtdt.movgest_ts_det_tipo_code
FROM siac.siac_t_movgest_ts_det tmtd, siac.siac_d_movgest_ts_det_tipo dmtdt
WHERE tmtd.movgest_ts_det_tipo_id = dmtdt.movgest_ts_det_tipo_id
AND   tmtd.movgest_ts_id = v_movgest_ts_id
AND   tmtd.data_cancellazione IS NULL
AND   dmtdt.data_cancellazione IS NULL
AND   p_data BETWEEN tmtd.validita_inizio AND COALESCE(tmtd.validita_fine, p_data)
AND   p_data BETWEEN dmtdt.validita_inizio AND COALESCE(dmtdt.validita_fine, p_data)
GROUP BY dmtdt.movgest_ts_det_tipo_code

LOOP

	IF rec_movgest_ts_id_dett.movgest_ts_det_tipo_code = 'I' THEN
       v_importo_iniziale := rec_movgest_ts_id_dett.importo;
    ELSIF rec_movgest_ts_id_dett.movgest_ts_det_tipo_code = 'A' THEN
       v_importo_attuale := rec_movgest_ts_id_dett.importo;
    ELSIF rec_movgest_ts_id_dett.movgest_ts_det_tipo_code = 'U' THEN
       v_importo_utilizzabile := rec_movgest_ts_id_dett.importo;
    END IF;

END LOOP;

/* 30.06.2016 Sofia SIAC JIRA-5030
v_importo_emesso_tot := 0;
v_importo_quietanziato_tot := 0;

FOR rec_movgest_ts_id_perimp IN
SELECT movgest_ts_id
FROM   siac_t_movgest_ts
WHERE  movgest_id = v_movgest_id
AND    v_movgest_ts_tipo_code = 'T'
AND    ente_proprietario_id = p_ente_proprietario_id
AND    data_cancellazione IS NULL
AND    p_data BETWEEN validita_inizio AND COALESCE(validita_fine, p_data)
UNION
SELECT v_movgest_ts_id
WHERE  v_movgest_ts_tipo_code = 'S'

LOOP
    v_importo_emesso := 0;

    -- Sezione per il calcolo dell'importo emesso
    SELECT COALESCE(SUM(totd.ord_ts_det_importo),0) importo_emesso
    INTO v_importo_emesso
    FROM siac.siac_r_ordinativo_ts_movgest_ts rotmt, siac.siac_t_ordinativo_ts tot,
         siac.siac_r_ordinativo_stato ros, siac.siac_d_ordinativo_stato dos,
         siac.siac_t_ordinativo_ts_det totd, siac.siac_d_ordinativo_ts_det_tipo dotdt
    WHERE rotmt.movgest_ts_id = rec_movgest_ts_id_perimp.movgest_ts_id
    AND  rotmt.ord_ts_id = tot.ord_ts_id
    AND  ros.ord_id = tot.ord_id
    AND  ros.ord_stato_id = dos.ord_stato_id
    AND  totd.ord_ts_id = tot.ord_ts_id
    AND  dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
    AND  dos.ord_stato_code <> 'A'
    AND  dotdt.ord_ts_det_tipo_code = 'A'
    AND  p_data BETWEEN  rotmt.validita_inizio  AND COALESCE(rotmt.validita_fine, p_data)
    AND  p_data BETWEEN  tot.validita_inizio  AND COALESCE(tot.validita_fine, p_data)
    AND  p_data BETWEEN  ros.validita_inizio  AND COALESCE(ros.validita_fine, p_data)
    AND  p_data BETWEEN  dos.validita_inizio  AND COALESCE(dos.validita_fine, p_data)
    AND  p_data BETWEEN  totd.validita_inizio  AND COALESCE(totd.validita_fine, p_data)
    AND  p_data BETWEEN  dotdt.validita_inizio  AND COALESCE(dotdt.validita_fine, p_data)
    AND  rotmt.data_cancellazione IS NULL
    AND  tot.data_cancellazione IS NULL
    AND  ros.data_cancellazione IS NULL
    AND  dos.data_cancellazione IS NULL
    AND  totd.data_cancellazione IS NULL
    AND  dotdt.data_cancellazione IS NULL;
    -- Sezione per il calcolo dell'importo quietanziato
    v_importo_quietanziato := 0;
    SELECT COALESCE(SUM(totd.ord_ts_det_importo),0) importo_quietanziato
    INTO v_importo_quietanziato
    FROM siac.siac_r_ordinativo_ts_movgest_ts rotmt, siac.siac_t_ordinativo_ts tot,
         siac.siac_r_ordinativo_stato ros, siac.siac_d_ordinativo_stato dos,
         siac.siac_t_ordinativo_ts_det totd, siac.siac_d_ordinativo_ts_det_tipo dotdt
    WHERE rotmt.movgest_ts_id = rec_movgest_ts_id_perimp.movgest_ts_id
    AND  rotmt.ord_ts_id = tot.ord_ts_id
    AND  ros.ord_id = tot.ord_id
    AND  ros.ord_stato_id = dos.ord_stato_id
    AND  totd.ord_ts_id = tot.ord_ts_id
    AND  dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
    AND  dos.ord_stato_code = 'Q'
    AND  dotdt.ord_ts_det_tipo_code = 'A'
    AND  p_data BETWEEN  rotmt.validita_inizio  AND COALESCE(rotmt.validita_fine, p_data)
    AND  p_data BETWEEN  tot.validita_inizio  AND COALESCE(tot.validita_fine, p_data)
    AND  p_data BETWEEN  ros.validita_inizio  AND COALESCE(ros.validita_fine, p_data)
    AND  p_data BETWEEN  dos.validita_inizio  AND COALESCE(dos.validita_fine, p_data)
    AND  p_data BETWEEN  totd.validita_inizio  AND COALESCE(totd.validita_fine, p_data)
    AND  p_data BETWEEN  dotdt.validita_inizio  AND COALESCE(dotdt.validita_fine, p_data)
    AND  rotmt.data_cancellazione IS NULL
    AND  tot.data_cancellazione IS NULL
    AND  ros.data_cancellazione IS NULL
    AND  dos.data_cancellazione IS NULL
    AND  totd.data_cancellazione IS NULL
    AND  dotdt.data_cancellazione IS NULL;

    v_importo_quietanziato_tot := v_importo_quietanziato_tot + v_importo_quietanziato;
    v_importo_emesso_tot := v_importo_emesso_tot + v_importo_emesso;

END LOOP;
*/

-- 30.06.2016 Sofia SIAC JIRA-5030   INIZIO
-- Sezione per il calcolo dell'importo emesso
v_importo_emesso_tot := 0;
SELECT COALESCE(SUM(totd.ord_ts_det_importo),0)
INTO v_importo_emesso_tot
FROM siac.siac_r_ordinativo_ts_movgest_ts rotmt, siac.siac_t_ordinativo_ts tot,
     siac.siac_r_ordinativo_stato ros, siac.siac_d_ordinativo_stato dos,
     siac.siac_t_ordinativo_ts_det totd, siac.siac_d_ordinativo_ts_det_tipo dotdt
WHERE rotmt.movgest_ts_id = v_movgest_ts_id
 AND  rotmt.ord_ts_id = tot.ord_ts_id
 AND  ros.ord_id = tot.ord_id
 AND  ros.ord_stato_id = dos.ord_stato_id
 AND  totd.ord_ts_id = tot.ord_ts_id
 AND  dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
 AND  dos.ord_stato_code <> 'A'
 AND  dotdt.ord_ts_det_tipo_code = 'A'
 AND  p_data BETWEEN  rotmt.validita_inizio  AND COALESCE(rotmt.validita_fine, p_data)
 AND  p_data BETWEEN  tot.validita_inizio  AND COALESCE(tot.validita_fine, p_data)
 AND  p_data BETWEEN  ros.validita_inizio  AND COALESCE(ros.validita_fine, p_data)
 AND  p_data BETWEEN  dos.validita_inizio  AND COALESCE(dos.validita_fine, p_data)
 AND  p_data BETWEEN  totd.validita_inizio  AND COALESCE(totd.validita_fine, p_data)
 AND  p_data BETWEEN  dotdt.validita_inizio  AND COALESCE(dotdt.validita_fine, p_data)
 AND  rotmt.data_cancellazione IS NULL
 AND  tot.data_cancellazione IS NULL
 AND  ros.data_cancellazione IS NULL
 AND  dos.data_cancellazione IS NULL
 AND  totd.data_cancellazione IS NULL
 AND  dotdt.data_cancellazione IS NULL;
esito:='Importo emesso='||v_importo_emesso_tot::varchar||' per movgest_ts_id='||v_movgest_ts_id||'.';

return next;
-- Sezione per il calcolo dell'importo quietanziato
v_importo_quietanziato_tot := 0;
SELECT COALESCE(SUM(totd.ord_ts_det_importo),0)
    INTO v_importo_quietanziato_tot
    FROM siac.siac_r_ordinativo_ts_movgest_ts rotmt, siac.siac_t_ordinativo_ts tot,
         siac.siac_r_ordinativo_stato ros, siac.siac_d_ordinativo_stato dos,
         siac.siac_t_ordinativo_ts_det totd, siac.siac_d_ordinativo_ts_det_tipo dotdt
    WHERE rotmt.movgest_ts_id = v_movgest_ts_id
    AND  rotmt.ord_ts_id = tot.ord_ts_id
    AND  ros.ord_id = tot.ord_id
    AND  ros.ord_stato_id = dos.ord_stato_id
    AND  totd.ord_ts_id = tot.ord_ts_id
    AND  dotdt.ord_ts_det_tipo_id = totd.ord_ts_det_tipo_id
    AND  dos.ord_stato_code = 'Q'
    AND  dotdt.ord_ts_det_tipo_code = 'A'
    AND  p_data BETWEEN  rotmt.validita_inizio  AND COALESCE(rotmt.validita_fine, p_data)
    AND  p_data BETWEEN  tot.validita_inizio  AND COALESCE(tot.validita_fine, p_data)
    AND  p_data BETWEEN  ros.validita_inizio  AND COALESCE(ros.validita_fine, p_data)
    AND  p_data BETWEEN  dos.validita_inizio  AND COALESCE(dos.validita_fine, p_data)
    AND  p_data BETWEEN  totd.validita_inizio  AND COALESCE(totd.validita_fine, p_data)
    AND  p_data BETWEEN  dotdt.validita_inizio  AND COALESCE(dotdt.validita_fine, p_data)
    AND  rotmt.data_cancellazione IS NULL
    AND  tot.data_cancellazione IS NULL
    AND  ros.data_cancellazione IS NULL
    AND  dos.data_cancellazione IS NULL
    AND  totd.data_cancellazione IS NULL
    AND  dotdt.data_cancellazione IS NULL;
-- 30.06.2016 Sofia SIAC JIRA-5030   INIZIO


-- SIAC-7541 27.04.2020 Sofia
v_codice_cdc_competente := NULL;
v_descrizione_cdc_competente := null;
v_codice_cdr_competente := NULL;
v_descrizione_cdr_competente := null;

IF v_movgest_ts_tipo_code = 'T' THEN

v_programma_code := null;
v_programma_desc := null;
-- 23.10.2018 Sofia SIAC-6336
v_programma_stato:= null;
v_versione_cronop:=null;
v_desc_cronop:=null;
v_anno_cronop:=null;
v_programma_id:=null;

-- 23.10.2018 Sofia SIAC-6336
SELECT tp.programma_code, tp.programma_desc, stato.programma_stato_code, rmtp.programma_id
INTO   v_programma_code, v_programma_desc, v_programma_stato, v_programma_id
FROM   siac_r_movgest_ts_programma rmtp, siac_t_programma tp,
       siac_r_programma_stato rs, siac_d_programma_stato stato
WHERE  rmtp.movgest_ts_id = v_movgest_ts_id
AND    rmtp.programma_id = tp.programma_id
and    rs.programma_id=rmtp.programma_id
and    stato.programma_stato_id=rs.programma_stato_id
AND    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
AND    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
AND    p_data BETWEEN rs.validita_inizio and COALESCE(rs.validita_fine,p_data)
AND    rmtp.data_cancellazione IS NULL
AND    tp.data_cancellazione IS NULL
and    rs.data_cancellazione IS NULL;





-- 23.10.2018 Sofia SIAC-6336
if v_programma_id is not null then
	select cronop.cronop_code, cronop.cronop_desc, per.anno::integer
    into   v_versione_cronop, v_desc_cronop, v_anno_cronop
    from siac_t_cronop cronop, siac_r_cronop_stato rs, siac_d_cronop_stato stato,siac_t_bil bil,siac_t_periodo per
    where cronop.programma_id=v_programma_id
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code='VA'
    and   bil.bil_id=cronop.bil_id
    and   per.periodo_id=bil.periodo_id
    and   per.anno::integer=p_anno_bilancio::integer
    AND   p_data BETWEEN rs.validita_inizio and COALESCE(rs.validita_fine,p_data)
    AND   p_data BETWEEN cronop.validita_inizio and COALESCE(cronop.validita_fine,p_data)
    and   rs.data_cancellazione is null
    and   cronop.data_cancellazione is null
    order by cronop.cronop_id desc
    limit 1;



end if;

-- SIAC-7541 27.04.2020 Sofia
select  c.classif_code, c.classif_Desc
        into v_codice_cdr_competente,v_descrizione_cdr_competente
from   siac_r_movgest_class rc,siac_t_class c,siac_d_class_tipo tipo
where  rc.movgest_Ts_id=rec_movgest_ts_id.movgest_ts_id
and    c.classif_id=rc.classif_id
and    tipo.classif_tipo_id=c.classif_tipo_id
and    tipo.classif_tipo_code='CDR'
and    rc.data_cancellazione is null
and    rc.validita_fine is null;

select  c.classif_code, c.classif_Desc
        into v_codice_cdc_competente,v_descrizione_cdc_competente
from   siac_r_movgest_class rc,siac_t_class c,siac_d_class_tipo tipo
where  rc.movgest_Ts_id=rec_movgest_ts_id.movgest_ts_id
and    c.classif_id=rc.classif_id
and    tipo.classif_tipo_id=c.classif_tipo_id
and    tipo.classif_tipo_code='CDC'
and    rc.data_cancellazione is null
and    rc.validita_fine is null;






INSERT INTO siac.siac_dwh_accertamento
(ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
anno_accertamento,
num_accertamento,
desc_accertamento,
cod_accertamento,
cod_stato_accertamento,
desc_stato_accertamento,
data_scadenza,
parere_finanziario,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
soggetto_id,
cod_soggetto,
desc_soggetto,
cf_soggetto,
cf_estero_soggetto,
p_iva_soggetto,
cod_classe_soggetto,
desc_classe_soggetto,
cod_entrata_ricorrente,
desc_entrata_ricorrente,
cod_perimetro_sanita_entrata,
desc_perimetro_sanita_entrata,
cod_transazione_ue_entrata,
desc_transazione_ue_entrata,
cod_pdc_finanziario_i,
desc_pdc_finanziario_i,
cod_pdc_finanziario_ii,
desc_pdc_finanziario_ii,
cod_pdc_finanziario_iii,
desc_pdc_finanziario_iii,
cod_pdc_finanziario_iv,
desc_pdc_finanziario_iv,
cod_pdc_finanziario_v,
desc_pdc_finanziario_v,
cod_pdc_economico_i,
desc_pdc_economico_i,
cod_pdc_economico_ii,
desc_pdc_economico_ii,
cod_pdc_economico_iii,
desc_pdc_economico_iii,
cod_pdc_economico_iv,
desc_pdc_economico_iv,
cod_pdc_economico_v,
desc_pdc_economico_v,
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
classificatore_1,
classificatore_1_valore,
classificatore_1_desc_valore,
classificatore_2,
classificatore_2_valore,
classificatore_2_desc_valore,
classificatore_3,
classificatore_3_valore,
classificatore_3_desc_valore,
classificatore_4,
classificatore_4_valore,
classificatore_4_desc_valore,
classificatore_5,
classificatore_5_valore,
classificatore_5_desc_valore,
annocapitoloorigine,
numcapitoloorigine,
annoorigineplur,
numarticoloorigine,
annoriaccertato,
numriaccertato,
numorigineplur,
flagdariaccertamento,
flagdareanno, -- 19.02.2020 Sofia jira siac-7292
automatico,
note,
validato,
num_ueb_origine,
anno_atto_amministrativo,
num_atto_amministrativo,
oggetto_atto_amministrativo,
note_atto_amministrativo,
cod_tipo_atto_amministrativo,
desc_tipo_atto_amministrativo,
desc_stato_atto_amministrativo,
cod_cdr_atto_amministrativo,
desc_cdr_atto_amministrativo,
cod_cdc_atto_amministrativo,
desc_cdc_atto_amministrativo,
importo_iniziale,
importo_attuale,
importo_utilizzabile,
importo_emesso,
importo_quietanziato,
FlagCollegamentoAccertamentoFattura,
flag_attiva_gsa, -- 04.06.2018 Sofia siac-6220
data_inizio_val_stato_accer,
data_inizio_val_accer,
data_creazione_accer,
data_modifica_accer,
cod_programma,
desc_programma,
-- 23.10.2018 Sofia jira siac-6336
stato_programma,
versione_cronop,
desc_cronop,
anno_cronop,
-- SIAC-7541 27.04.2020 Sofia
cod_cdr_struttura_comp,
desc_cdr_struttura_comp,
cod_cdc_struttura_comp,
desc_cdc_struttura_comp,
-- siac-8171 06.09.2021 Sofia
codice_verbale
  )
  VALUES (v_ente_proprietario_id,
          v_ente_denominazione,
          v_anno,
          v_fase_operativa_code,
          v_fase_operativa_desc,
          v_movgest_anno,
          v_movgest_numero,
          v_movgest_desc,
          v_movgest_ts_code,
          v_movgest_stato_code,
          v_movgest_stato_desc,
          v_data_scadenza,
          v_parere_finanziario,
          v_codice_capitolo,
          v_codice_articolo,
          v_codice_ueb,
          v_descrizione_capitolo,
          v_descrizione_articolo,
          v_soggetto_id,
          v_codice_soggetto,
          v_descrizione_soggetto,
          v_codice_fiscale_soggetto,
          v_codice_fiscale_estero_soggetto,
          v_partita_iva_soggetto,
          v_codice_classe_soggetto,
          v_descrizione_classe_soggetto,
          v_codice_entrata_ricorrente,
          v_descrizione_entrata_ricorrente,
          v_codice_perimetro_sanitario_entrata,
          v_descrizione_perimetro_sanitario_entrata,
          v_codice_transazione_entrata_ue,
          v_descrizione_transazione_entrata_ue,
          v_codice_pdc_finanziario_I,
          v_descrizione_pdc_finanziario_I,
          v_codice_pdc_finanziario_II,
          v_descrizione_pdc_finanziario_II,
          v_codice_pdc_finanziario_III,
          v_descrizione_pdc_finanziario_III,
          v_codice_pdc_finanziario_IV,
          v_descrizione_pdc_finanziario_IV,
          v_codice_pdc_finanziario_V,
          v_descrizione_pdc_finanziario_V,
          v_codice_pdc_economico_I,
          v_descrizione_pdc_economico_I,
          v_codice_pdc_economico_II,
          v_descrizione_pdc_economico_II,
          v_codice_pdc_economico_III,
          v_descrizione_pdc_economico_III,
          v_codice_pdc_economico_IV,
          v_descrizione_pdc_economico_IV,
          v_codice_pdc_economico_V,
          v_descrizione_pdc_economico_V,
          v_codice_cofog_divisione,
          v_descrizione_cofog_divisione,
          v_codice_cofog_gruppo,
          v_descrizione_cofog_gruppo,
          v_classificatore_generico_1,
          v_classificatore_generico_1_valore,
          v_classificatore_generico_1_descrizione_valore,
          v_classificatore_generico_2,
          v_classificatore_generico_2_valore,
          v_classificatore_generico_2_descrizione_valore,
          v_classificatore_generico_3,
          v_classificatore_generico_3_valore,
          v_classificatore_generico_3_descrizione_valore,
          v_classificatore_generico_4,
          v_classificatore_generico_4_valore,
          v_classificatore_generico_4_descrizione_valore,
          v_classificatore_generico_5,
          v_classificatore_generico_5_valore,
          v_classificatore_generico_5_descrizione_valore,
          v_annoCapitoloOrigine,
          v_numeroCapitoloOrigine,
          v_annoOriginePlur,
          v_numeroArticoloOrigine,
          v_annoRiaccertato,
          v_numeroRiaccertato,
          v_numeroOriginePlur,
          v_flagDaRiaccertamento,
          v_flagDaReanno, -- 19.02.2020 Sofia jira siac-7292
          v_automatico,
          v_note,
          v_validato,
          v_numero_ueb_origine,
          v_anno_atto_amministrativo,
          v_numero_atto_amministrativo::varchar,
          v_oggetto_atto_amministrativo,
          v_note_atto_amministrativo,
          v_codice_tipo_atto_amministrativo,
          v_descrizione_tipo_atto_amministrativo,
          v_descrizione_stato_atto_amministrativo,
          v_cod_cdr_atto_amministrativo,
          v_desc_cdr_atto_amministrativo,
          v_cod_cdc_atto_amministrativo,
          v_desc_cdc_atto_amministrativo,
          v_importo_iniziale,
          v_importo_attuale,
          v_importo_utilizzabile,
          v_importo_emesso_tot,
          v_importo_quietanziato_tot,
          v_FlagCollegamentoAccertamentoFattura,
          coalesce(v_FlagAttivaGsa,'N'), -- 04.06.2018 Sofia siac-6220
          v_data_inizio_val_stato_accer,
          v_data_inizio_val_accer,
          v_data_creazione_accer,
          v_data_modifica_accer,
          v_programma_code,
          v_programma_desc,
          -- 23.10.2018 Sofia jira siac-6336
		  v_programma_stato,
		  v_versione_cronop,
	      v_desc_cronop,
	      v_anno_cronop,
          -- SIAC-7541 27.04.2020 Sofia
          v_codice_cdr_competente,
          v_descrizione_cdr_competente,
          v_codice_cdc_competente,
          v_descrizione_cdc_competente,
          -- siac-8171 06.09.2021 Sofia
          v_codice_verbale
         );
ELSIF v_movgest_ts_tipo_code = 'S' THEN

  -- SIAC-7541 27.04.2020 Sofia

  select  c.classif_code, c.classif_Desc
          into v_codice_cdr_competente,v_descrizione_cdr_competente
  from siac_t_movgest_Ts ts, siac_d_movgest_ts_tipo tipo_ts,
       siac_r_movgest_class rc,siac_t_class c,siac_d_class_tipo tipo
  where  ts.movgest_id=rec_movgest_ts_id.movgest_id
  and    tipo_ts.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
  and    tipo_ts.movgest_ts_tipo_code='T'
  and    rc.movgest_Ts_id=ts.movgest_ts_id
  and    c.classif_id=rc.classif_id
  and    tipo.classif_tipo_id=c.classif_tipo_id
  and    tipo.classif_tipo_code='CDR'
  and    rc.data_cancellazione is null
  and    rc.validita_fine is null
  and    ts.data_cancellazione is null
  and    ts.validita_fine is null;

  select  c.classif_code, c.classif_Desc
          into v_codice_cdc_competente,v_descrizione_cdc_competente
  from siac_t_movgest_Ts ts, siac_d_movgest_ts_tipo tipo_ts,
       siac_r_movgest_class rc,siac_t_class c,siac_d_class_tipo tipo
  where  ts.movgest_id=rec_movgest_ts_id.movgest_id
  and    tipo_ts.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
  and    tipo_ts.movgest_ts_tipo_code='T'
  and    rc.movgest_Ts_id=ts.movgest_ts_id
  and    c.classif_id=rc.classif_id
  and    tipo.classif_tipo_id=c.classif_tipo_id
  and    tipo.classif_tipo_code='CDC'
  and    rc.data_cancellazione is null
  and    rc.validita_fine is null
  and    ts.data_cancellazione is null
  and    ts.validita_fine is null;


  INSERT INTO siac.siac_dwh_subaccertamento
  (ente_proprietario_id,
ente_denominazione,
bil_anno,
cod_fase_operativa,
desc_fase_operativa,
anno_accertamento,
num_accertamento,
desc_accertamento,
cod_subaccertamento,
desc_subaccertamento,
cod_stato_subaccertamento,
desc_stato_subaccertamento,
data_scadenza,
parere_finanziario,
cod_capitolo,
cod_articolo,
cod_ueb,
desc_capitolo,
desc_articolo,
soggetto_id,
cod_soggetto,
desc_soggetto,
cf_soggetto,
cf_estero_soggetto,
p_iva_soggetto,
cod_classe_soggetto,
desc_classe_soggetto,
cod_entrata_ricorrente,
desc_entrata_ricorrente,
cod_perimetro_sanita_entrata,
desc_perimetro_sanita_entrata,
cod_transazione_ue_entrata,
desc_transazione_ue_entrata,
cod_pdc_finanziario_i,
desc_pdc_finanziario_i,
cod_pdc_finanziario_ii,
desc_pdc_finanziario_ii,
cod_pdc_finanziario_iii,
desc_pdc_finanziario_iii,
cod_pdc_finanziario_iv,
desc_pdc_finanziario_iv,
cod_pdc_finanziario_v,
desc_pdc_finanziario_v,
cod_pdc_economico_i,
desc_pdc_economico_i,
cod_pdc_economico_ii,
desc_pdc_economico_ii,
cod_pdc_economico_iii,
desc_pdc_economico_iii,
cod_pdc_economico_iv,
desc_pdc_economico_iv,
cod_pdc_economico_v,
desc_pdc_economico_v,
cod_cofog_divisione,
desc_cofog_divisione,
cod_cofog_gruppo,
desc_cofog_gruppo,
classificatore_1,
classificatore_1_valore,
classificatore_1_desc_valore,
classificatore_2,
classificatore_2_valore,
classificatore_2_desc_valore,
classificatore_3,
classificatore_3_valore,
classificatore_3_desc_valore,
classificatore_4,
classificatore_4_valore,
classificatore_4_desc_valore,
classificatore_5,
classificatore_5_valore,
classificatore_5_desc_valore,
annocapitoloorigine,
numcapitoloorigine,
annoorigineplur,
numarticoloorigine,
annoriaccertato,
numriaccertato,
numorigineplur,
flagdariaccertamento,
flagdareanno, -- 19.02.2020 Sofia jira siac-7292
automatico,
note,
validato,
num_ueb_origine,
anno_atto_amministrativo,
num_atto_amministrativo,
oggetto_atto_amministrativo,
note_atto_amministrativo,
cod_tipo_atto_amministrativo,
desc_tipo_atto_amministrativo,
desc_stato_atto_amministrativo,
cod_cdr_atto_amministrativo,
desc_cdr_atto_amministrativo,
cod_cdc_atto_amministrativo,
desc_cdc_atto_amministrativo,
importo_iniziale,
importo_attuale,
importo_utilizzabile,
importo_emesso,
importo_quietanziato,
FlagCollegamentoAccertamentoFattura,
flag_attiva_gsa, -- 04.06.2018 Sofia siac-6220
data_inizio_val_stato_subaccer,
data_inizio_val_subaccer,
data_creazione_subaccer,
data_modifica_subaccer,
-- SIAC-7541 27.04.2020 Sofia
cod_cdr_struttura_comp,
desc_cdr_struttura_comp,
cod_cdc_struttura_comp,
desc_cdc_struttura_comp
  )
  VALUES (v_ente_proprietario_id,
          v_ente_denominazione,
          v_anno,
          v_fase_operativa_code,
          v_fase_operativa_desc,
          v_movgest_anno,
          v_movgest_numero,
          v_movgest_desc,
          v_movgest_ts_code,
          v_movgest_ts_desc,
          v_movgest_stato_code,
          v_movgest_stato_desc,
          v_data_scadenza,
          v_parere_finanziario,
          v_codice_capitolo,
          v_codice_articolo,
          v_codice_ueb,
          v_descrizione_capitolo,
          v_descrizione_articolo,
          v_soggetto_id,
          v_codice_soggetto,
          v_descrizione_soggetto,
          v_codice_fiscale_soggetto,
          v_codice_fiscale_estero_soggetto,
          v_partita_iva_soggetto,
          v_codice_classe_soggetto,
          v_descrizione_classe_soggetto,
          v_codice_entrata_ricorrente,
          v_descrizione_entrata_ricorrente,
          v_codice_perimetro_sanitario_entrata,
          v_descrizione_perimetro_sanitario_entrata,
          v_codice_transazione_entrata_ue,
          v_descrizione_transazione_entrata_ue,
          v_codice_pdc_finanziario_I,
          v_descrizione_pdc_finanziario_I,
          v_codice_pdc_finanziario_II,
          v_descrizione_pdc_finanziario_II,
          v_codice_pdc_finanziario_III,
          v_descrizione_pdc_finanziario_III,
          v_codice_pdc_finanziario_IV,
          v_descrizione_pdc_finanziario_IV,
          v_codice_pdc_finanziario_V,
          v_descrizione_pdc_finanziario_V,
          v_codice_pdc_economico_I,
          v_descrizione_pdc_economico_I,
          v_codice_pdc_economico_II,
          v_descrizione_pdc_economico_II,
          v_codice_pdc_economico_III,
          v_descrizione_pdc_economico_III,
          v_codice_pdc_economico_IV,
          v_descrizione_pdc_economico_IV,
          v_codice_pdc_economico_V,
          v_descrizione_pdc_economico_V,
          v_codice_cofog_divisione,
          v_descrizione_cofog_divisione,
          v_codice_cofog_gruppo,
          v_descrizione_cofog_gruppo,
          v_classificatore_generico_1,
          v_classificatore_generico_1_valore,
          v_classificatore_generico_1_descrizione_valore,
          v_classificatore_generico_2,
          v_classificatore_generico_2_valore,
          v_classificatore_generico_2_descrizione_valore,
          v_classificatore_generico_3,
          v_classificatore_generico_3_valore,
          v_classificatore_generico_3_descrizione_valore,
          v_classificatore_generico_4,
          v_classificatore_generico_4_valore,
          v_classificatore_generico_4_descrizione_valore,
          v_classificatore_generico_5,
          v_classificatore_generico_5_valore,
          v_classificatore_generico_5_descrizione_valore,
          v_annoCapitoloOrigine,
          v_numeroCapitoloOrigine,
          v_annoOriginePlur,
          v_numeroArticoloOrigine,
          v_annoRiaccertato,
          v_numeroRiaccertato,
          v_numeroOriginePlur,
          v_flagDaRiaccertamento,
          v_flagDaReanno, -- 19.02.2020 Sofia siac-7292
          v_automatico,
          v_note,
          v_validato,
          v_numero_ueb_origine,
          v_anno_atto_amministrativo,
          v_numero_atto_amministrativo::varchar,
          v_oggetto_atto_amministrativo,
          v_note_atto_amministrativo,
          v_codice_tipo_atto_amministrativo,
          v_descrizione_tipo_atto_amministrativo,
          v_descrizione_stato_atto_amministrativo,
          v_cod_cdr_atto_amministrativo,
          v_desc_cdr_atto_amministrativo,
          v_cod_cdc_atto_amministrativo,
          v_desc_cdc_atto_amministrativo,
          v_importo_iniziale,
          v_importo_attuale,
          v_importo_utilizzabile,
          v_importo_emesso_tot,
          v_importo_quietanziato_tot ,
          v_FlagCollegamentoAccertamentoFattura,
          coalesce(v_FlagAttivaGsa,'N'), -- 04.06.2018 Sofia siac-6220
          v_data_inizio_val_stato_subaccer,
          v_data_inizio_val_subaccer,
          v_data_creazione_subaccer,
          v_data_modifica_subaccer,
          -- SIAC-7541 27.04.2020 Sofia
          v_codice_cdr_competente,
          v_descrizione_cdr_competente,
          v_codice_cdc_competente,
          v_descrizione_cdc_competente
         );
END IF;

esito:= '  Fine ciclo movgest - movgest_ts_id ('||v_movgest_id||') - ('||v_movgest_ts_id||') - ('||v_movgest_ts_tipo_code||') - '||clock_timestamp();
RETURN NEXT;
END LOOP;
esito:= 'Fine funzione carico accertamenti (FNC_SIAC_DWH_ACCERTAMENTO) - '||clock_timestamp();
RETURN NEXT;


update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico accertamenti (FNC_SIAC_DWH_ACCERTAMENTO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

alter FUNCTION siac.fnc_siac_dwh_accertamento (varchar,integer,timestamp) owner to siac;

 -- SIAC-8178 - Sofia 10.09.2021 - fine
 
-- SIAC-8349 - Sofia 16.09.2021 - inizio 
 
drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_comp_anno
(
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean
);
create OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno 
(
  id_in integer,
  anno_in varchar,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

-- 10.08.2020 Sofia jira siac-6865
importoCurAttAggiudicazione numeric:=0;
movGestStatoPId integer:=null;
BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';
/* select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;
*/
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;



 -- 10.08.2020 Sofia Jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
raise notice 'importoCurAttuale=%',importoCurAttuale;
/*select tb.importo into importoCurAttuale from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId))
    group by c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    and t.movgest_ts_tipo_code=TIPO_IMP_T;--'T'; */

 /* select
      coalesce(sum(e.movgest_ts_det_importo),0) into importoCurAttuale
      from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id= ANY (VALUES (a.movgest_id)) and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=ANY (VALUES (e.movgest_ts_det_tipo_id))
    and e.movgest_ts_det_tipo_id=ANY (VALUES (movGestTsDetTipoId));*/

  --raise notice 'importoCurAttuale:%', importoCurAttuale;
 --fine nuovo G
 /*for movGestIdRec in
 (
     select movGestRel.movgest_id
     from siac_r_movgest_bil_elem movGestRel
     where movGestRel.elem_id=id_in
     and   movGestRel.data_cancellazione is null
     and   exists (select 1 from siac_t_movgest movGest
   				   where movGest.movgest_id=movGestRel.movgest_id
			       and	 movGest.bil_id = bilancioId
			       and   movGest.movgest_tipo_id=movGestTipoId
				   and   movGest.movgest_anno = anno_in::integer)
 )
 loop
   	importoCurAttuale:=0;

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo impegnato anno_in='||anno_in
                      ||'.Lettura siac_t_movgest_ts movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';

    select movgestts.movgest_ts_id into  movGestTsId
    from siac_t_movgest_ts movGestTs
    where movGestTs.movgest_id = movGestIdRec.movgest_id
    and   movGestTs.data_cancellazione is null
    and   movGestTs.movgest_ts_tipo_id=movGestTsTipoId
    and   exists (select 1 from siac_r_movgest_ts_stato movGestTsRel
                  where movGestTsRel.movgest_ts_id=movGestTs.movgest_ts_id
                  and   movGestTsRel.movgest_stato_id!=movGestStatoId);

    strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
                      ||'.Calcolo accertato anno_in='||anno_in||'Somma siac_t_movgest_ts_det movGestTs.movgest_id='||movGestIdRec.movgest_id||'.';
    if NOT FOUND then
    else
       select coalesce(sum(movGestTsDet.movgest_ts_det_importo),0) into importoCurAttuale
           from siac_t_movgest_ts_det movGestTsDet
           where movGestTsDet.movgest_ts_id=movGestTsId
           and   movGestTsDet.movgest_ts_det_tipo_id=movGestTsDetTipoId;
    end if;

    importoAttuale:=importoAttuale+importoCurAttuale;
 end loop;*/
 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code <> 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;
raise notice 'importoModifNeg=%',importoModifNeg;
  -- 10.08.2020 Sofia jira SIAC-6865 - inizio
  -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
  if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=id_in
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilancioId
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;
  end if;
  -- 10.08.2020 Sofia jira SIAC-6865 - fine
raise notice 'importoCurAttAggiudicazione=%',importoCurAttAggiudicazione;

  -- anna_economie inizio
   select tb.importo into importoModifINS
   from
   (
      select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
      from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
           siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
           siac_t_movgest_ts_det_mod moddet,
           siac_t_modifica mod, siac_r_modifica_stato rmodstato,
           siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
           siac_d_modifica_tipo tipom
      where rbil.elem_id=id_in
      and	  mov.movgest_id=rbil.movgest_id
      and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
      and   mov.movgest_anno=anno_in::integer
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   rstato.movgest_ts_id=ts.movgest_ts_id
      and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
      and   tsdet.movgest_ts_id=ts.movgest_ts_id
      and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
      and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
      -- SIAC-7349
      -- abbiamo tolto il commento nella riga qui sotto perche' d'accordo con Pietro Gambino
      -- e visto che possono anche esserci modifiche ECONB positive
      -- e' bene escluderle dal calcolo importoModifINS
      and   moddet.movgest_ts_det_importo<0 -- importo negativo
      and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
      and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
      and   mod.mod_id=rmodstato.mod_id
      and   atto.attoamm_id=mod.attoamm_id
      and   attostato.attoamm_id=atto.attoamm_id
      and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
      and   tipom.mod_tipo_id=mod.mod_tipo_id
      and   tipom.mod_tipo_code = 'ECONB'
      -- date
      and rbil.data_cancellazione is null
      and rbil.validita_fine is null
      and mov.data_cancellazione is null
      and mov.validita_fine is null
      and ts.data_cancellazione is null
      and ts.validita_fine is null
      and rstato.data_cancellazione is null
      and rstato.validita_fine is null
      and tsdet.data_cancellazione is null
      and tsdet.validita_fine is null
      and moddet.data_cancellazione is null
      and moddet.validita_fine is null
      and mod.data_cancellazione is null
      and mod.validita_fine is null
      and rmodstato.data_cancellazione is null
      and rmodstato.validita_fine is null
      and attostato.data_cancellazione is null
      and attostato.validita_fine is null
      and atto.data_cancellazione is null
      and atto.validita_fine is null
      group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo tipo
    where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
    AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
    order by tipo.movgest_ts_tipo_code desc
    limit 1;

    if importoModifINS is null then importoModifINS:=0; end if;

  -- anna_economie fine

 end if;
raise notice 'importoModifINS=%',importoModifINS;

raise notice 'importoAttuale0=%',importoAttuale;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG
raise notice 'importoAttuale1=%',importoAttuale;

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine
raise notice 'importoAttuale2=%',importoAttuale;

 -- 10.08.2020 Sofia jira siac-6865
 importoAttuale:=importoAttuale-importoCurAttAggiudicazione;
raise notice 'importoAttuale3=%',importoAttuale;

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno(integer, character varying, boolean)
    OWNER TO siac;

	
drop FUNCTION if exists siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp 
(
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean
);


CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp (
  id_in integer,
  anno_in varchar,
  idcomp_in integer,
  verifica_mod_prov boolean = true
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiimpegnato numeric
) AS
$body$
DECLARE


-- constant
TIPO_CAP_UG constant varchar:='CAP-UG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='I';
TIPO_IMP_T  constant varchar:='T';

STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';

STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

-- anna_economie inizio
STATO_ATTO_D constant varchar:='DEFINITIVO';
attoAmmStatoDId integer:=0;
importoModifINS  numeric:=0;
-- anna_economie fine

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;

movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

-- 10.08.2020 Sofia jira siac-6865
importoCurAttAggiudicazione numeric:=0;
movGestStatoPId integer:=null;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
and el.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
;

 -- 02.02.2016 Sofia JIRA 2947
if esisteRmovgestidelemid is null then esisteRmovgestidelemid:=0; end if;

if esisteRmovgestidelemid <>0 then

 annoCompetenza:=null;
 diCuiImpegnato:=0;

 strMessaggio:='Calcolo impegnato di competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 -- 10.08.2020 Sofia Jira SIAC-6865
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestStatoPId.';

 select movGestStato.movgest_stato_id into strict movGestStatoPId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_P;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614

 -- anna_economie inizio
 select d.attoamm_stato_id into strict attoAmmStatoDId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_D;
 -- anna_economie fine

 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Inizio calcolo totale importo attuale impegni per anno_in='||anno_in||'.';

 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in and
	  a.elem_det_comp_tipo_id= idcomp_in::integer --SIAC-7349
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;


 -- 02.02.2016 Sofia JIRA 2947
 if importoCurAttuale is null then importoCurAttuale:=0; end if;

 -- 16.03.2017 Sofia JIRA-SIAC-4614
-- if importoCurAttuale>0 then
 if importoCurAttuale>=0 then -- 05.09.2017 Sofia siac-5198 il conteggio deve essere effettuato anche se impoatt=0

  strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	 and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code <> 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  -- 21.06.2017 Sofia - aggiunto parametro verifica_mod_prov, ripreso da prod CmTo dove era stato implementato
  if importoModifNeg is null or verifica_mod_prov is false then importoModifNeg:=0; end if;

-- 10.08.2020 Sofia jira SIAC-6865 - inizio
  -- impegni provvisori nati da aggiudiazione non decurtano la disp. a impegnare
  if  verifica_mod_prov=true then
   strMessaggio:='Calcolo impegnato competenza elem_id='||id_in
               ||'. Calcolo impegnato provvisorio per aggiudicazione per anno_in='||anno_in||'.';

   select tb.importo into importoCurAttAggiudicazione
   from
   (
  	select coalesce(sum(det.movgest_ts_det_importo),0)  importo, ts.movgest_ts_tipo_id
    from  siac_r_movgest_bil_elem rmov,
          siac_t_movgest mov,
      	  siac_t_movgest_ts ts,
      	  siac_r_movgest_ts_stato rs_stato,
          siac_t_movgest_ts_det det,
     	  siac_d_movgest_ts_det_tipo tipo_det
      where rmov.elem_id=id_in
      and   rmov.elem_det_comp_tipo_id=idcomp_in::integer
      and 	mov.movgest_id=rmov.movgest_id
      and   mov.bil_id = bilancioId
      and   mov.movgest_tipo_id=movGestTipoId
      and   mov.movgest_anno = anno_in::integer
      and   ts.movgest_id=mov.movgest_id
      and   rs_stato.movgest_ts_id=ts.movgest_ts_id
	  and   rs_stato.movgest_stato_id=movGestStatoPId
      and   det.movgest_ts_id=ts.movgest_ts_id
      and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
      and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   exists
      (
        select 1
        from siac_r_movgest_aggiudicazione ragg
        where   ragg.movgest_id_a=mov.movgest_id
        and     ragg.data_cancellazione is null
        and     ragg.validita_fine is null
      )
      and   rs_stato.validita_fine is null
	  and   rmov.data_cancellazione is null
      and   mov.data_cancellazione is null
      and   ts.data_cancellazione is null
      and   det.data_cancellazione is null
     group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;
    if importoCurAttAggiudicazione is null then importoCurAttAggiudicazione:=0; end if;
  end if;
  -- 10.08.2020 Sofia jira SIAC-6865 - fine

  -- anna_economie inizio
  select tb.importo into importoModifINS
  from
  (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto,
         siac_d_modifica_tipo tipom
	where rbil.elem_id=id_in
	and rbil.elem_det_comp_tipo_id=idcomp_in::integer --SIAC-7349
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento impegno
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- impegno non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id in (attoAmmStatoDId, attoAmmStatoPId) -- atto definitivo
    and   tipom.mod_tipo_id=mod.mod_tipo_id
    and   tipom.mod_tipo_code = 'ECONB'
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 15.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;

  if importoModifINS is null then importoModifINS:=0; end if;

  -- anna_economie fine

 end if;

 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614
 --fine nuovoG

 -- anna_economie inizio
 importoAttuale:=importoAttuale+abs(importoModifINS);
 -- anna_economie fine

 -- 10.08.2020 Sofia jira siac-6865
 importoAttuale:=importoAttuale-importoCurAttAggiudicazione;

 annoCompetenza:=anno_in;
 diCuiImpegnato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiImpegnato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiimpegnatoug_comp_anno_comp(integer, varchar, integer, boolean)
    OWNER TO siac;


drop function if exists siac.fnc_siac_dicuiaccertatoeg_comp_anno 
(
  id_in integer,
  anno_in varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_dicuiaccertatoeg_comp_anno (
  id_in integer,
  anno_in varchar
)
RETURNS TABLE (
  annocompetenza varchar,
  dicuiaccertato numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_EG constant varchar:='CAP-EG';
NVL_STR     constant varchar:='';
STA_IMP     constant varchar:='STA';

TIPO_IMP    constant varchar:='A';
TIPO_IMP_T  constant varchar:='T';
STATO_DEF   constant varchar:='D';
STATO_N     constant varchar:='N';
STATO_P     constant varchar:='P';
STATO_A     constant varchar:='A';
IMPORTO_ATT constant varchar:='A';
STATO_MOD_V  constant varchar:='V';
STATO_ATTO_P constant varchar:='PROVVISORIO';

strMessaggio varchar(1500):=NVL_STR;

bilancioId integer:=0;
enteProprietarioId INTEGER:=0;
annoBilancio varchar:=null;

movGestTipoId integer:=0;
movGestTsTipoId integer:=0;
movGestStatoId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsId integer:=0;

importoAttuale numeric:=0;
importoCurAttuale numeric:=0;
importoModifNeg  numeric:=0;

modStatoVId integer:=0;
attoAmmStatoPId integer:=0;


movGestIdRec record;

esisteRmovgestidelemid INTEGER:=0;

BEGIN

select el.elem_id into esisteRmovgestidelemid from siac_r_movgest_bil_elem el, siac_t_movgest mv
where
mv.movgest_id=el.movgest_id
and el.elem_id=id_in
and mv.movgest_anno=anno_in::integer
;

if esisteRmovgestidelemid <>0 then

annoCompetenza:=null;
 diCuiAccertato:=0;

 strMessaggio:='Calcolo accertato competenza elem_id='||id_in||'.Controllo parametri.';

 if anno_in is null or anno_in=NVL_STR then
	 RAISE EXCEPTION '% Anno di competenza mancante.',strMessaggio;
 end if;

 if id_in is null or id_in=0 then
	 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
 end if;


 strMessaggio:='Calcolo accertato competenza elem_id='||id_in
			   ||'.Calcolo bilancioId enteProprietarioId  annoBilancio.';

 select bil.bil_id,  bil.ente_proprietario_id,  per.anno
        into strict bilancioId, enteProprietarioId, annoBilancio
 from siac_t_bil bil,siac_t_bil_elem bilElem, siac_t_periodo per
 where bilElem.elem_id=id_in
 and   bilElem.data_cancellazione is null
 and   bil.bil_id=bilElem.bil_id
 and   per.periodo_id=bil.periodo_id;



strMessaggio:='Calcolo accertato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTipoId.';
 select tipoMovGest.movgest_tipo_id into strict movGestTipoId
 from  siac_d_movgest_tipo tipoMovGest
 where tipoMovGest.ente_proprietario_id=enteProprietarioId
 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;

 strMessaggio:='Calcolo accertato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsTipoId.';
/* select movGestTsTipo.movgest_ts_tipo_id into strict movGestTsTipoId
 from siac_d_movgest_ts_tipo movGestTsTipo
 where movGestTsTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsTipo.movgest_ts_tipo_code=TIPO_IMP_T;
*/
 strMessaggio:='Calcolo accertato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsStatoId.';

 select movGestStato.movgest_stato_id into strict movGestStatoId
 from siac_d_movgest_stato movGestStato
 where movGestStato.ente_proprietario_id=enteProprietarioId
 and   movGestStato.movgest_stato_code=STATO_A;

 strMessaggio:='Calcolo accertato competenza elem_id='||id_in||'.'
              ||'Calcolo movGestTsDetTipoId.';

 select movGestTsDetTipo.movgest_ts_det_tipo_id into strict movGestTsDetTipoId
 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;


 -- 16.03.2017 Sofia JIRA-SIAC-4614
 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo modStatoVId.';
 select d.mod_stato_id into strict modStatoVId
 from siac_d_modifica_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.mod_stato_code=STATO_MOD_V;


 strMessaggio:='Calcolo impegnato competenza elem_id='||id_in||'.'
              ||'Calcolo attoAmmStatoPId.';
 select d.attoamm_stato_id into strict attoAmmStatoPId
 from siac_d_atto_amm_stato d
 where d.ente_proprietario_id=enteProprietarioId
 and   d.attoamm_stato_code=STATO_ATTO_P;
 -- 16.03.2017 Sofia JIRA-SIAC-4614



  strMessaggio:='Calcolo accertato competenza elem_id='||id_in||'. Inizio ciclo per anno_in='||anno_in||'.';


 --nuovo G
   	importoCurAttuale:=0;

    select tb.importo into importoCurAttuale
 from (
  select
      coalesce(sum(e.movgest_ts_det_importo),0)  importo
      , c.movgest_ts_tipo_id
    from
      siac_r_movgest_bil_elem a,
      siac_t_movgest b,
      siac_t_movgest_ts c,
      siac_r_movgest_ts_stato d,
      siac_t_movgest_ts_det e
      ,siac_d_movgest_ts_det_tipo f
      where
      b.movgest_id=a.movgest_id and
      a.elem_id=id_in
      and b.bil_id = bilancioId
      and b.movgest_tipo_id=movGestTipoId
	  and d.movgest_stato_id<>movGestStatoId
	  and b.movgest_anno = anno_in::integer
      and c.movgest_id=b.movgest_id
      and d.movgest_ts_id=c.movgest_ts_id
      and d.validita_fine is null
      and e.movgest_ts_id=c.movgest_ts_id
	and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
     and e.data_cancellazione is null
     and f.movgest_ts_det_tipo_id=e.movgest_ts_det_tipo_id
    and e.movgest_ts_det_tipo_id=movGestTsDetTipoId
    group by
   c.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo t
    where tb.movgest_ts_tipo_id=t.movgest_ts_tipo_id
    order by t.movgest_ts_tipo_code desc
    limit 1;

raise notice '%',importoCurAttuale;

if importoCurAttuale is null THEN
importoCurAttuale:=0;
end if;
 -- 16.03.2017 Sofia JIRA-SIAC-4614
 if importoCurAttuale>0 then
 strMessaggio:='Calcolo accertato competenza elem_id='||id_in||'. Calcolo totale modifiche negative su atti provvisori per anno_in='||anno_in||'.';

 select tb.importo into importoModifNeg
 from
 (
 	select coalesce(sum(moddet.movgest_ts_det_importo),0) importo , ts.movgest_ts_tipo_id
	from siac_r_movgest_bil_elem rbil, siac_t_movgest mov,siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_stato rstato,siac_t_movgest_ts_det tsdet,
	     siac_t_movgest_ts_det_mod moddet,
    	 siac_t_modifica mod, siac_r_modifica_stato rmodstato,
	     siac_r_atto_amm_stato attostato, siac_t_atto_amm atto
	where rbil.elem_id=id_in
	and	  mov.movgest_id=rbil.movgest_id
	and   mov.movgest_tipo_id=movgestTipoId -- tipo movimento accertamento
    and   mov.movgest_anno=anno_in::integer
    and   mov.bil_id=bilancioId
	and   ts.movgest_id=mov.movgest_id
	and   rstato.movgest_ts_id=ts.movgest_ts_id
	and   rstato.movgest_stato_id!=movGestStatoId -- accertamento non annullato
	and   tsdet.movgest_ts_id=ts.movgest_ts_id
	and   moddet.movgest_ts_det_id=tsdet.movgest_ts_det_id
	and   moddet.movgest_ts_det_tipo_id=tsdet.movgest_ts_det_tipo_id
	and   moddet.movgest_ts_det_importo<0 -- importo negativo
	and   rmodstato.mod_stato_r_id=moddet.mod_stato_r_id
	and   rmodstato.mod_stato_id=modStatoVId   -- V modifica in stato valido
	and   mod.mod_id=rmodstato.mod_id
	and   atto.attoamm_id=mod.attoamm_id
	and   attostato.attoamm_id=atto.attoamm_id
	and   attostato.attoamm_stato_id=attoAmmStatoPId -- atto provvisorio
	-- date
	and rbil.data_cancellazione is null
	and rbil.validita_fine is null
	and mov.data_cancellazione is null
	and mov.validita_fine is null
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and rstato.data_cancellazione is null
	and rstato.validita_fine is null
	and tsdet.data_cancellazione is null
	and tsdet.validita_fine is null
	and moddet.data_cancellazione is null
	and moddet.validita_fine is null
	and mod.data_cancellazione is null
	and mod.validita_fine is null
	and rmodstato.data_cancellazione is null
	and rmodstato.validita_fine is null
	and attostato.data_cancellazione is null
	and attostato.validita_fine is null
	and atto.data_cancellazione is null
	and atto.validita_fine is null
    group by ts.movgest_ts_tipo_id
  ) tb, siac_d_movgest_ts_tipo tipo
  where tipo.movgest_ts_tipo_id=tb.movgest_ts_tipo_id
  AND   tipo.movgest_ts_tipo_code='T' -- SIAC-8349 Sofia 16.09.2021
  order by tipo.movgest_ts_tipo_code desc
  limit 1;
  if importoModifNeg is null then importoModifNeg:=0; end if;

 end if;


 --nuovo G
 importoAttuale:=importoAttuale+importoCurAttuale+abs(importoModifNeg); -- 16.03.2017 Sofia JIRA-SIAC-4614;
 --fine nuovoG

 annoCompetenza:=anno_in;
 diCuiAccertato:=importoAttuale;

 return next;

else

annoCompetenza:=anno_in;
diCuiAccertato:=0;

return next;

end if;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_dicuiaccertatoeg_comp_anno(integer, varchar)
    OWNER TO siac;
	
-- SIAC-8349 - Sofia 16.09.2021 - fine

-- SIAC-8140 - Sofia 23.09.2021 - inizio
CREATE TABLE if not exists siac.siac_s_prov_cassa 
(
	provc_st_id serial ,
	provc_id integer NOT NULL,
	sac_id integer null,
	sac_code varchar(200) null,
	sac_desc varchar(500) null,
	sac_tipo_code varchar(200) null,
	sac_tipo_desc varchar(500) null,
	provc_data_invio_servizio timestamp null,
    validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id int4 NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT null,
	CONSTRAINT pk_siac_s_prov_cassa PRIMARY KEY (provc_st_id),
	CONSTRAINT siac_t_prov_cassa_siac_s_prov_cassa FOREIGN KEY (provc_id) REFERENCES siac.siac_t_prov_cassa(provc_id),
    CONSTRAINT siac_t_class_siac_s_prov_cassa FOREIGN KEY (sac_id) REFERENCES siac.siac_t_class(classif_id),
	CONSTRAINT siac_t_ente_proprietario_siac_s_prov_cassa FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);
CREATE INDEX if not exists  siac_s_prov_cassa_fk_provc_id_idx ON siac_s_prov_cassa USING btree (provc_id);
CREATE INDEX if not exists  siac_s_prov_cassa_fk_ente_proprietario_id_idx ON siac_s_prov_cassa USING btree (ente_proprietario_id);
CREATE INDEX if not exists siac_s_prov_cassa_fk_sac_id_idx ON siac_s_prov_cassa USING btree (sac_id);
CREATE INDEX if not exists  siac_s_prov_cassa_fk_sac_code_idx ON siac_s_prov_cassa USING btree (sac_code,sac_tipo_code);

alter table siac.siac_s_prov_cassa OWNER to siac;

drop VIEW if exists siac.siac_v_dwh_storico_prov_cassa;
CREATE OR REPLACE VIEW siac.siac_v_dwh_storico_prov_cassa
(
    ente_proprietario_id,
    ente_denominazione,
    provc_tipo_code,
    provc_tipo_desc,
    provc_anno,
    provc_numero,
    sac_code,
	sac_desc,
	sac_tipo_code,
	sac_tipo_desc,
	provc_data_invio_servizio,
	validita_inizio_storico,
	validita_fine_storico
)
as
select ente.ente_proprietario_id,
       ente.ente_denominazione, 
       tipo.provc_tipo_code,
       tipo.provc_tipo_desc,
       p.provc_anno,
       p.provc_numero,
       s.sac_code,
       s.sac_desc,
       s.sac_tipo_code,
       s.sac_tipo_desc,
       s.provc_data_invio_servizio,
       s.validita_inizio,
       s.validita_fine
from siac_s_prov_cassa  s ,siac_t_prov_cassa p,siac_d_prov_cassa_tipo tipo,
     siac_t_ente_proprietario ente
where  tipo.ente_proprietario_id=ente.ente_proprietario_id 
and    p.provc_tipo_id=tipo.provc_tipo_id
and    s.provc_id=p.provc_id
and    p.data_cancellazione is null
and    s.data_cancellazione is null;


alter view siac.siac_v_dwh_storico_prov_cassa OWNER to siac;

-- SIAC-8140 - Sofia 23.09.2021 - fine 