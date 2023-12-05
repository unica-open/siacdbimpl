/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-8404 - Sofia - 04.03.2022 - inizio 
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
-- SIAC-8404 Sofia 03.03.2022                 
--                 pagopa_ric_doc_flag_con_dett= (case when tipod.doc_tipo_id =docTipoFatId then true else false end )
                 pagopa_ric_doc_flag_con_dett= (case when tipod.doc_tipo_id =docTipoFatId  or query.is_doc_tipo_ipa_dett=true
                                                          then true else false end )
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
          ),
          --- SIAC-8404 Sofia 03.03.2022
          acc_class as
          (
          select distinct rsog.movgest_ts_id
          from siac_r_movgest_ts_sogclasse rsog,siac_d_soggetto_classe cl 
          where rsog.ente_proprietario_id=enteProprietarioId
          and   cl.soggetto_classe_id=rsog.soggetto_classe_id
          and   cl.data_cancellazione is null 
          and   cl.validita_fine is null 
          and   rsog.data_cancellazione is null 
          and   rsog.validita_fine is null 
          )
          select accertamento.movgest_ts_id,accertamento.anno_accertamento, accertamento.numero_accertamento,
                 (case when coalesce(acc_fattura.fl_fatt,'N')='S' then docTipoFatId
                      when coalesce(acc_corrispettivo.fl_corr,'N')='S' then docTipoCorId
                      else docTipoIpaId end) doc_tipo_id,
                 --- SIAC-8404 Sofia 03.03.2022
                 ( case when coalesce(acc_class.movgest_ts_id::varchar,'X')!='X' then true else false end )  is_doc_tipo_ipa_dett   
          from accertamento
               left join acc_fattura on ( accertamento.movgest_ts_id=acc_fattura.movgest_ts_id )
               left join acc_corrispettivo on ( accertamento.movgest_ts_id=acc_corrispettivo.movgest_ts_id )
               --- SIAC-8404 Sofia 03.03.2022
               left join acc_class on (accertamento.movgest_ts_id=acc_class.movgest_ts_id)
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
--          and   doc.pagopa_ric_doc_tipo_id=docTipoFatId -- SIAC-8404 Sofia 03.03.2022
          and   doc.pagopa_ric_doc_tipo_id in (docTipoFatId, docTipoIpaId)  -- SIAC-8404 Sofia 03.03.2022
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

    -- 12.10.2021 Sofia JIRA SIAC-8371
	movgestTsDetTipoUId integer:=null;

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
 
   
    -- 12.10.2021 Sofia JIRA SIAC-8371
   	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo UTILIZZABILE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoUId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='U';
        if movgestTsDetTipoUId is null then
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
      if pagoPaCodeErr=PAGOPA_ERR_7  or 
	     pagoPaCodeErr=PAGOPA_ERR_12 then -- SIAC-8585 24.01.2022 Sofia Jira 
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
--		if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT then -- SIAC-8404 Sofia 03.03.2022
	    if ( pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT or 		-- SIAC-8404 Sofia 03.03.2022
   		    ( pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_IPA and coalesce(pagoPaFlussoRec.pagopa_doc_iuv,'X')!='X' ) ) then -- SIAC-8404 Sofia 03.03.2022
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
--               dataElaborazione,
--               dataElaborazione,
               date_trunc('DAY',dataElaborazione), -- 04.03.2022 SIAC-8404
               date_trunc('DAY',dataElaborazione), -- 04.03.2022 SIAC-8404
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
					  --- 29.11.2021 Sofia JIRA SIAC-8371
					  if codResult is not null then 
					   codResult:=null;
					   update siac_t_movgest_ts_det det
                       set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                              data_modifica=clock_timestamp(),
                              --login_operazione=det.login_operazione||'-'||loginOperazione -- 27.02.2020 Sofia jira SIAC-7449
                              login_operazione=loginOperazione||'@ELAB_PAGOPA-'||filePagoPaElabId::varchar -- 27.02.2020 Sofia jira SIAC-7449
                       where det.movgest_ts_id=movgestTsId
--                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                        -- 12.10.2021 Sofia JIRA SIAC-8371
                       and   det.movgest_ts_det_tipo_id=movgestTsDetTipoUId
                       and   det.data_cancellazione is null
                       and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                       returning det.movgest_ts_det_id into codResult;
					  end if;
					   --- 29.11.2021 Sofia JIRA SIAC-8371
					  
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
--               clock_timestamp(), siac-8543 Sofia 10.01.2022
               now(),-- siac-8543 Sofia 10.01.2022
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

alter function siac.fnc_pagopa_t_elaborazione_riconc_esegui
( integer, integer, integer , varchar , timestamp ,  
  out integer,
  out varchar) owner to siac;
  
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

-- SIAC-8404 - Sofia - 04.03.2022 - fine


-- SIAC-8660- Haitham - 08.03.2022 - inizio

CREATE OR REPLACE VIEW siac.siac_v_dwh_mod_impegno
AS WITH zz AS (
         SELECT l.anno,
            b.movgest_anno,
            b.movgest_numero,
            c.movgest_ts_code,
            c.movgest_ts_desc,
            dmtt.movgest_ts_tipo_code,
            a.movgest_ts_det_importo,
            d.mod_num,
            d.mod_desc,
            f.mod_stato_code,
            g.mod_tipo_code,
            g.mod_tipo_desc,
            h.attoamm_anno,
            h.attoamm_numero,
            daat.attoamm_tipo_code,
            a.ente_proprietario_id,
            h.attoamm_id,
            f.mod_stato_desc,
            a.mtdm_reimputazione_flag,
                CASE
                    WHEN a.mtdm_reimputazione_flag = true THEN a.mtdm_reimputazione_anno
                    ELSE NULL::integer
                END AS mtdm_reimputazione_anno,
            d.elab_ror_reanno,
            d.validita_inizio,
            d.data_creazione
           FROM siac_t_movgest_ts_det_mod a
             JOIN siac_t_movgest_ts c ON c.movgest_ts_id = a.movgest_ts_id
             JOIN siac_t_movgest b ON b.movgest_id = c.movgest_id
             JOIN siac_d_movgest_tipo tt ON tt.movgest_tipo_id = b.movgest_tipo_id
             JOIN siac_r_modifica_stato e ON e.mod_stato_r_id = a.mod_stato_r_id
             JOIN siac_t_modifica d ON d.mod_id = e.mod_id
             JOIN siac_d_modifica_stato f ON f.mod_stato_id = e.mod_stato_id
             LEFT JOIN siac_d_modifica_tipo g ON g.mod_tipo_id = d.mod_tipo_id AND g.data_cancellazione IS NULL
             JOIN siac_t_atto_amm h ON h.attoamm_id = d.attoamm_id
             JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = h.attoamm_tipo_id
             JOIN siac_t_bil i ON i.bil_id = b.bil_id
             JOIN siac_t_periodo l ON i.periodo_id = l.periodo_id
             JOIN siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = c.movgest_ts_tipo_id
          WHERE tt.movgest_tipo_code::text = 'I'::text AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND tt.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL AND h.data_cancellazione IS NULL AND daat.data_cancellazione IS NULL AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND dmtt.data_cancellazione IS NULL
        ), aa AS (
         SELECT i.attoamm_id,
            l.classif_id,
            l.classif_code,
            l.classif_desc,
            m.classif_tipo_code
           FROM siac_r_atto_amm_class i,
            siac_t_class l,
            siac_d_class_tipo m,
            siac_r_class_fam_tree n,
            siac_t_class_fam_tree o,
            siac_d_class_fam p
          WHERE i.classif_id = l.classif_id AND m.classif_tipo_id = l.classif_tipo_id AND n.classif_id = l.classif_id AND n.classif_fam_tree_id = o.classif_fam_tree_id AND o.classif_fam_id = p.classif_fam_id AND p.classif_fam_code::text = '00005'::text AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND m.data_cancellazione IS NULL AND n.data_cancellazione IS NULL AND o.data_cancellazione IS NULL AND p.data_cancellazione IS NULL
        )
 select distinct 
    zz.anno AS bil_anno,
    zz.movgest_anno AS anno_impegno,
    zz.movgest_numero AS num_impegno,
    zz.movgest_ts_code AS cod_movgest_ts,
    zz.movgest_ts_desc AS desc_movgest_ts,
    zz.movgest_ts_tipo_code AS tipo_movgest_ts,
    zz.movgest_ts_det_importo AS importo_modifica,
    zz.mod_num AS numero_modifica,
    zz.mod_desc AS desc_modifica,
    zz.mod_stato_code AS stato_modifica,
    zz.mod_tipo_code AS cod_tipo_modifica,
    zz.mod_tipo_desc AS desc_tipo_modifica,
    zz.attoamm_anno AS anno_atto_amministrativo,
    zz.attoamm_numero AS num_atto_amministrativo,
    zz.attoamm_tipo_code AS cod_tipo_atto_amministrativo,
    aa.classif_code AS cod_sac,
    aa.classif_desc AS desc_sac,
    aa.classif_tipo_code AS tipo_sac,
    zz.ente_proprietario_id,
    zz.mod_stato_desc AS desc_stato_modifica,
    zz.mtdm_reimputazione_flag AS flag_reimputazione,
    zz.mtdm_reimputazione_anno AS anno_reimputazione,
    zz.elab_ror_reanno,
    zz.validita_inizio,
    zz.data_creazione
   FROM zz
     LEFT JOIN aa ON zz.attoamm_id = aa.attoamm_id;

-- SIAC-8660- Haitham - 08.03.2022 - fine






-- SIAC-8597- Haitham - 09.03.2022 - inizio
CREATE OR REPLACE FUNCTION siac.fnc_770_estrai_tracciato_quadro_c_f(p_anno_elab character varying, p_ente_proprietario_id integer, p_quadro_c_f character varying)
 RETURNS TABLE(riga_tracciato text)
 LANGUAGE plpgsql
AS $function$
DECLARE

RTN_MESSAGGIO text;

BEGIN

	
IF p_quadro_c_f IS NULL THEN
    RTN_MESSAGGIO := 'Parametro Quadro C-F nullo.';
END IF;


IF upper(p_quadro_c_f) = 'C' THEN
 return query
select 	'CODICE_MATRICOLA;COGNOME;NOME;CODICE_FISCALE;SESSO;DATA_NASCITA;COMUNE_NASCITA;PROVINCIA;VIA_DOMICILIO;CAP;LOC_DOMICILIO;PROV_DOMICILIO;CAUSALE(CAMPO 1);AMMONTARE LORDO (CAMPO 4);CODICE ESENZIONE(CAMPO 6);ALTRE SOMME NON SOGGETTE A RIT(CAMPO 7);IMPONIBILE(CAMPO 8);RITENUTE A TITOLO D''ACCONTO(CAMPO 9);ANNOTAZIONE'  --as quadro_SC, 0 progressivo
union all
select  
        ('0'  || ';' ||
        query.cognome_denominazione  || ';' ||
		coalesce(query.nome,null,'')  || ';' ||
		query.codice_fiscale_percipiente   || ';' ||
		coalesce(query.sesso,null,'')   || ';' ||
	    coalesce(query.data_nascita,null,'')   || ';' ||
		coalesce(query.comune_nascita,null,'')  || ';' ||
		coalesce(query.provincia_nascita,null,'')   || ';' ||
		query.indirizzo_domicilio_spedizione   || ';' ||
		query.cap_domicilio_spedizione  || ';' ||
		query.comune_domicilio_spedizione  || ';' ||
		query.provincia_domicilio_spedizione   || ';' ||
		query.causale || ';' ||		 
		replace(query.ammontare_lordo_corrisposto::varchar, '.', ',')  || ';' ||
		replace(query.codice,'0', 'null')::varchar || ';' ||
		replace(query.altre_somme_no_ritenute::varchar, '.', ',')  || ';' ||
		replace(query.imponibile_b::varchar, '.', ',')  || ';' ||
		replace(query.ritenute_titolo_acconto_b::varchar, '.', ',')  || ';' ||	'') --as quadro_SC, 0 progressivo
from 
(
select  t.cognome_denominazione,
		t.nome,
		t.codice_fiscale_percipiente, 
	    t.sesso,
		to_char(t.data_nascita, 'DD/MM/YYYY') data_nascita,
		t.comune_nascita,
		t.provincia_nascita,
		t.indirizzo_domicilio_spedizione,
		t.cap_domicilio_spedizione,
		t.comune_domicilio_spedizione,
		t.provincia_domicilio_spedizione,
		t.causale,		 
		sum(coalesce(t.ammontare_lordo_corrisposto,null,'0')) as ammontare_lordo_corrisposto,
		sum(coalesce(t.altre_somme_no_ritenute,null,'0')) as altre_somme_no_ritenute,
		sum(coalesce(t.imponibile_b,null,'0')) as imponibile_b,
		sum(coalesce(t.ritenute_titolo_acconto_b,null,'0')) as ritenute_titolo_acconto_b,
		replace (t.codice, '12', '24')  as codice
from tracciato_770_quadro_c_temp t
where t.ente_proprietario_id = p_ente_proprietario_id
and   t.anno_competenza = p_anno_elab
group by 
        t.cognome_denominazione,
		t.nome,
		t.codice_fiscale_percipiente, 
	    t.sesso,
		to_char(t.data_nascita, 'DD/MM/YYYY'),
		t.comune_nascita,
		t.provincia_nascita,
		t.indirizzo_domicilio_spedizione,
		t.cap_domicilio_spedizione,
		t.comune_domicilio_spedizione,
		t.provincia_domicilio_spedizione,
		t.causale,		 
		t.codice
order by t.cognome_denominazione
) query
--order by  progressivo, 1
;

ELSIF upper(p_quadro_c_f) = 'F' THEN
 return query
select  'CODICE_MATRICOLA;COGNOME;NOME;CODICE_FISCALE;SESSO;DATA_NASCITA;COMUNE_NASCITA;PROVINCIA;VIA_DOMICILIO;CAP;LOC_DOMICILIO;PROV_DOMICILIO;CAUSALE;AMMONTARE LORDO CORRISPOSTO;SOMME NON SOGGETTE A RITENUTA;ALIQUOTA;RITENUTE OPERATE;RITENUTE SOSPESE;RIMBORSI' --quadro_sf, 1 progressivo
union all
select  
        ('0'  || ';' ||
        query.cognome_denominazione  || ';' ||
		coalesce(query.nome,null,'')  || ';' ||
		query.codice_fiscale_percipiente   || ';' ||
		coalesce(query.sesso,null,'')   || ';' ||
	    coalesce(query.data_nascita,null,'')   || ';' ||
		coalesce(query.comune_nascita,null,'')  || ';' ||
		coalesce(query.provincia_nascita,null,'')   || ';' ||
		coalesce(query.indirizzo_domicilio_fiscale,null,'')  || ';' ||
		coalesce(query.cap_domicilio_spedizione,null,'')  || ';' ||
		coalesce(query.comune_domicilio_fiscale,null,'')  || ';' ||
		coalesce(query.provincia_domicilio_fiscale,null,'')   || ';' ||
		query.causale || ';' ||		 
		replace(query.ammontare_lordo_corrisposto::varchar, '.', ',')  || ';' ||
		replace(query.altre_somme_no_ritenute::varchar, '.', ',')  || ';' ||		
		replace(query.aliquota::varchar, '.', ',')  || ';' ||		
		replace(query.ritenute_operate::varchar, '.', ',')  || ';' ||
		replace(query.ritenute_sospese::varchar, '.', ',')  || ';' ||
		replace(query.rimborsi::varchar, '.', ',')  || ';' || '') --quadro_sf,2 progressivo
from 
(
select  t.cognome_denominazione,
		t.nome,
		t.codice_fiscale_percipiente, 
	    t.sesso,
		to_char(t.data_nascita, 'DD/MM/YYYY') data_nascita,
		t.comune_nascita,
		t.provincia_nascita,
		t.indirizzo_domicilio_fiscale,
		t.cap_domicilio_spedizione,
		t.comune_domicilio_fiscale,
		t.provincia_domicilio_fiscale, 
		t.causale,		 
		sum(coalesce(t.ammontare_lordo_corrisposto,null,'0')) as ammontare_lordo_corrisposto,
		sum(coalesce(t.altre_somme_no_ritenute,null,'0')) as altre_somme_no_ritenute,
		coalesce(t.aliquota,null,'0') as aliquota,
		sum(coalesce(t.ritenute_operate,null,'0')) as ritenute_operate,
		sum(coalesce(t.ritenute_sospese ,null,'0')) as ritenute_sospese,
		sum(coalesce(t.rimborsi ,null,'0')) as rimborsi
from tracciato_770_quadro_f_temp t
where  t.ente_proprietario_id = p_ente_proprietario_id
 and   t.anno_competenza = p_anno_elab
group by 
        t.cognome_denominazione,
		t.nome,
		t.codice_fiscale_percipiente, 
	    t.sesso,
		to_char(t.data_nascita, 'DD/MM/YYYY'),
		t.comune_nascita,
		t.provincia_nascita,
		t.indirizzo_domicilio_fiscale,
		t.cap_domicilio_spedizione,
		t.comune_domicilio_fiscale,
		t.provincia_domicilio_fiscale, 
		t.causale,
		t.aliquota
order by t.cognome_denominazione
) query
--order by  progressivo, 1
;

END IF;

exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato';
		return;
	when others  THEN
		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
		return;

END;
$function$
;
-- SIAC-8597- Haitham - 09.03.2022 - fine

--- SIAC-8529,SIAC-8630 Sofia - 11.03.2022 - inizio 

drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_up( id_in integer);
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_ug ( id_in integer, tipo_importo_in varchar );
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_iniziale_ug ( id_in integer);
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug ( id_in integer);
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_ug_annoprec ( id_in integer, tipo_importo_in varchar );
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_iniziale_ug_annoprec ( id_in integer);
drop function if exists siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug_annoprec ( id_in integer);


CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_up
(
  id_in integer
)
RETURNS NUMERIC
AS
$body$
DECLARE

annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

elemIdGestEq integer:=null;
bilIdElemGestEq integer:=0;
elemIdRelTempo integer:=null;
NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;
elemTipoCode VARCHAR(20):=NVL_STR;
elemCode varchar(50):=NVL_STR;
elemCode2 varchar(50):=NVL_STR;
elemCode3 varchar(50):=NVL_STR;
enteProprietarioId INTEGER:=0;

TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_UP constant varchar:='CAP-UP';

FASE_OP_BIL_PREV constant VARCHAR:='P';

STATO_A     constant varchar:='A';

TIPO_IMP    constant varchar:='I';

movGestStatoIdAnnullato integer:=0;
movGestTipoId integer:=0;

IMPORTO_ATT constant varchar:='A';
movGestTsDetTipoId integer:=0;
IMPORTO_INIZIALE constant varchar:='I';
movGestTsDetTipoIdIniziale integer:=0;



--pluriennalidaribaltamento integer:=0;
impegniDaRibaltamento integer:=0;

flagDeltaPagamenti boolean:=false;
importoImpegnato numeric:=0;
impegnatoDefinitivo numeric:=0;
importoPagatoDelta numeric:=0;

ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;

-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO
-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato residuo effettivo elem_id='||id_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
	strMessaggio:='Calcolo totale impegnato residuo effettivo elem_id='||id_in||
    			  '.Lettura anno di bilancio del capitolo UP.';

	select per.anno into  annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil,siac_t_periodo per 
	where bilElem.elem_id=id_in 
	AND   bil.bil_id=bilElem.bil_id
	and   per.periodo_id=bil.periodo_id
	AND   bilElem.data_cancellazione is null 
	and   bilElem.validita_fine is null;
	if annoBilancio is null then 
		RAISE EXCEPTION '%. Dato non trovato.',strMessaggio;
	end if;

		  

	strMessaggio:='Calcolo totale impegnato residuo effettivo elem_id='||id_in||
    			  '. Determina estremi capitolo - bilancioId e elem_tipo_code.';
    select bilelem.elem_code, bilElem.elem_code2, bilElem.elem_code3, bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	into  elemCode, elemCode2, elemCode3, bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	from  siac_t_bil_elem bilElem, 
	      siac_d_bil_elem_tipo tipoBilElem,
		  siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
 	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
 	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null;
     
	 if annoBilancio is null or enteProprietarioId is null or bilancioId  is null 
	    or elemCode is null or elemCode2 is null or elemTipoCode is null then 
		RAISE EXCEPTION '%. Dati non reperiti.',strMessaggio;
	 end if; 
	  	
	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UP then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;


	 strMessaggio:='Calcolo totale impegnato residuo effettivo elem_id='||id_in||
		 	       '.Lettura fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;


		
	 if NOT FOUND or faseOpCode is null THEN
	   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;
	 
	 if movGestTipoId is null then 
	 	RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;
	
	 strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO.';

	 select movGestStato.movgest_stato_id into  movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;

	 
 	 if movGestStatoIdAnnullato is null then 
		RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;
	
	 strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoId per movgest_ts_det_tipo_code=IMPORTO ATTUALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into  movGestTsDetTipoId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 if movGestTsDetTipoId is null then 
		RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;
	
	 strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;

	 if movGestTsDetTipoIdIniziale is null then 
		RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	


	impegniDaRibaltamento:=0;
--	pluriennaliDaRibaltamento:=0;
	importoImpegnato:=0;	
	
	select  count(*) into impegniDaRibaltamento 
	from fase_bil_t_gest_apertura_liq_imp fb 
	where fb.bil_id = bilancioId
	and   fb.movgest_Ts_id is not null
	and   fb.data_cancellazione is null
	and   fb.validita_fine is null;
    if impegniDaRibaltamento is null then impegniDaRibaltamento:=0; end if;
   
   raise notice 'impegniDaRibaltamento=%',impegniDaRibaltamento;
  
/*	select  count(*) into  pluriennaliDaRibaltamento
	from fase_bil_t_gest_apertura_pluri fb 
	where fb.bil_id = bilancioId
	and   fb.movgest_Ts_id is not null
	and fb.data_cancellazione is null
	and fb.validita_fine is null;
	if pluriennaliDaRibaltamento is null then pluriennaliDaRibaltamento:=0; end if;
    
    raise notice 'pluriennaliDaRibaltamento=%',pluriennaliDaRibaltamento;*/
--	if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then
--     impegniDaRibaltamento:=0;
	if impegniDaRibaltamento>0  then	

		-- - Se presenti i movimenti gestione provenienti dal ribaltamento 
		--		Residuo Finale = 
		--	 		Sommatoria dell importo attuale di tutti gli Impegni assunti sul capitolo in questione
		--			con anno movimento < N e anno esercizio N.
	    -- Sofia : ma sui residui passati al nuovo anno non si dovrebbe considerare iniziale - dubbio

		annoEsercizio:=annoBilancio;
		annoMovimento:=annoBilancio;
 		flagDeltaPagamenti:=false; -- non e' necessario scomputare il pagato
		
 	else

		-- - Se non presenti i movimenti gestione provenienti dal ribaltamento 
		-- 		Residuo Finale =	
		--			Sommatoria di tutti gli Impegni (valore effettivo aka finale) assunti sul capitolo in questione
		--			con anno movimento < N e anno esercizio N-1  
		--			diminuiti dalla sommatoria del pagato sui medesimi impegni nell esercizio N-1.
		annoEsercizio:=((annoBilancio::INTEGER)-1)::varchar;
        annoMovimento:=annoBilancio;
		flagDeltaPagamenti:=true; -- bisogna sottrarre la sommatoria del pagato sui medesimi impegni nell'esercizio N-1
        
		strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in
				  ||'. Lettura capitolo equivalente in annoEsercizio='||annoEsercizio::varchar
				  ||'  attraverso siac_r_bil_elem_rel_tempo.';
		select rel.elem_id_old into elemIdGestEq
		from siac_r_bil_elem_rel_tempo rel 
		where rel.elem_id=id_in
		and   rel.data_cancellazione is null 
		and   rel.validita_fine is null;
		raise notice '>> siac_r_bil_elem_rel_tempo elemIdGestEq=%',elemIdGestEq::varchar;
	end if;

	strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
				   '.Determina capitolo di gestione equivalente in anno esercizio calcolato' || 
				   '. Calcolo bilancioId per elem_id equivalente per faseOp='||faseOpCode
				  ||' per ente='||enteProprietarioId||' per elem_id='||id_in||'.';
	-- lettura elemento bil di gestione equivalente
   	-- lettura bilancioId annoEsercizio per lettura elemento di bilancio equivalente
	select bil.bil_id into bilIdElemGestEq
	from siac_t_bil bil , siac_t_periodo per, siac_d_periodo_tipo perTipo
	where per.ente_proprietario_id=enteProprietarioId
    and   per.anno=annoEsercizio
    and   perTipo.periodo_tipo_id=per.periodo_tipo_id
	and   perTipo.periodo_tipo_code='SY'    
    and   bil.periodo_id=per.periodo_id;

    if bilIdElemGestEq is null then
    	RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
    end if;
   
    if elemIdGestEq is null then
	    -- lettura elemIdGestEq
   		strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
		              'Calcolo elem_id equivalente per bilancioId='||bilIdElemGestEq
				      ||' per ente='||enteProprietarioId||'.';

		select bilelem.elem_id into elemIdGestEq
		from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
		where bilElemTipo.ente_proprietario_id=enteProprietarioId
		and   bilElemTipo.elem_tipo_code=TIPO_CAP_UG
    	and   bilElem.elem_tipo_id=bilElemTipo.elem_tipo_id	
	    and   bilElem.bil_id=bilIdElemGestEq
		and   bilElem.elem_code=elemCode
	    and   bilElem.elem_code2=elemCode2
		and   bilElem.elem_code3=elemCode3
	    and   bilElem.data_cancellazione is null
		and   bilElem.validita_fine is null;
	else
	    strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
		              'Verifica validita'' elem_id equivalente per bilancioId='||bilIdElemGestEq
				      ||' per ente='||enteProprietarioId||' da siac_r_bil_elem_rel_tempo.';

	    select bilelem.elem_id into elemIdRelTempo
		from siac_t_bil_elem bilElem, siac_d_bil_elem_tipo bilElemTipo
		where bilElemTipo.ente_proprietario_id=enteProprietarioId
		and   bilElemTipo.elem_tipo_code=TIPO_CAP_UG
    	and   bilElem.elem_tipo_id=bilElemTipo.elem_tipo_id	
	    and   bilElem.bil_id=bilIdElemGestEq
	    and   bilElem.elem_id=elemIdGestEq
	    and   bilElem.data_cancellazione is null
		and   bilElem.validita_fine is null;
	    if elemIdRelTempo is null then
	    	raise notice 'elemIdRelTempo=%',elemIdRelTempo::varchar;
	        elemIdGestEq:=null;
	    end if;
	   
	end if;


	if NOT FOUND or elemIdGestEq is null  THEN
		impegnatoDefinitivo:=0;  
	else

   	    strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
						'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
						'. Inizio calcolo totale importo attuale impegni per anno esercizio ='||annoEsercizio||
						'. Inizio calcolo totale importo attuale impegni per anno movimento ='||annoMovimento||'.'; 

		impegnatoDefinitivo:=0;

--		if impegniDaRibaltamento>0 and pluriennaliDaRibaltamento>0 then
        raise notice 'flagDeltaPagamenti=%',flagDeltaPagamenti;
		if flagDeltaPagamenti=false then
			--  Sommatoria dell'importo attuale di tutti gli Impegni assunti sul capitolo in questione 
			--	con anno movimento < N e anno esercizio N

			importoImpegnato:=0;			
			select tb.importo into importoImpegnato
			from 
			(
			  select coalesce(sum(det.movgest_ts_det_importo),0) importo, ts.movgest_ts_tipo_id
			  from    siac_t_movgest mov,		  
					  siac_t_movgest_ts ts,
				      siac_r_movgest_ts_stato rs,
			  		  siac_r_movgest_bil_elem re,
			  		  siac_d_movgest_ts_det_tipo tipo_det,
					  siac_t_movgest_ts_det det
			  where mov.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
			  and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
			  and   mov.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento
			  and   ts.movgest_id=mov.movgest_id
			  and   rs.movgest_ts_id=ts.movgest_ts_id
			  and   rs.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO			  
			  and   re.movgest_id=mov.movgest_id
			  and   re.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
			  and   det.movgest_ts_id=ts.movgest_ts_id
			  and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
			  and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoIdIniziale -- considerare l'importo iniziale
			  and   rs.data_cancellazione is null
			  and   rs.validita_fine is null
			  and   re.validita_fine is null 
			  and   re.data_cancellazione is null
			  and   mov.data_cancellazione is null
			  and   ts.data_cancellazione is null
			  group by ts.movgest_ts_tipo_id
			) tb, siac_d_movgest_ts_tipo tipo
			where tb.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
			order by tipo.movgest_ts_tipo_code desc
			limit 1;		
			if importoImpegnato is null then importoImpegnato:=0; end if;
			raise notice 'importoImpegnato=%',importoImpegnato;
		else
			-- Sommatoria di tutti gli Impegni assunti (valore effettivo aka finale) sul capitolo in questione su Componente X 
			-- con anno movimento < N e anno esercizio N-1
			-- diminuiti dalla sommatoria del pagato sui medesimi impegni nell'esercizio N-1.
			importoImpegnato:=0;			
			select tb.importo into importoImpegnato
			from 
			(
			  select coalesce(sum(det.movgest_ts_det_importo),0) importo, ts.movgest_ts_tipo_id
			  from    siac_t_movgest mov,		  
					  siac_t_movgest_ts ts,
				      siac_r_movgest_ts_stato rs,
			  		  siac_r_movgest_bil_elem re,
			  		  siac_d_movgest_ts_det_tipo tipo_det,
					  siac_t_movgest_ts_det det
			  where mov.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
			  and   mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO
			  and   mov.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento
			  and   ts.movgest_id=mov.movgest_id
			  and   rs.movgest_ts_id=ts.movgest_ts_id
			  and   rs.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO			  
			  and   re.movgest_id=mov.movgest_id
			  and   re.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
			  and   det.movgest_ts_id=ts.movgest_ts_id
			  and   tipo_det.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
			  and   tipo_det.movgest_ts_det_tipo_id=movGestTsDetTipoId -- considerare l'importo attuale
			  and   rs.data_cancellazione is null
			  and   rs.validita_fine is null
			  and   re.validita_fine is null 
			  and   re.data_cancellazione is null
			  and   mov.data_cancellazione is null
			  and   ts.data_cancellazione is null
			  group by ts.movgest_ts_tipo_id
			) tb, siac_d_movgest_ts_tipo tipo
			where tb.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
			order by tipo.movgest_ts_tipo_code desc
			limit 1;		
			if importoImpegnato is null then importoImpegnato:=0; end if;
			raise notice 'importoImpegnato=%',importoImpegnato;

			if importoImpegnato>=0 then

   	    		strMessaggio:='Calcolo impegnato residuo effettivo elem_id='||id_in||
				'. Esercizio bilIdElemGestEq='||bilIdElemGestEq||' capitolo gestione equivalente elemIdGestEq='||elemIdGestEq|| 
				'. Calcolo sommatoria del pagato sui medesimi impegni nell''esercizio N-1.';

			   select ordstato.ord_stato_id into ordStatoAId
			   from siac_d_ordinativo_stato ordstato
			   where ordstato.ente_proprietario_id=enteProprietarioId
			   and   ordstato.ord_stato_code=STATO_ORD_A;
				
			   if ordStatoAId is null then
			   	RAISE EXCEPTION '% Identificativo ord_stato_code=% non reperito.',strMessaggio,STATO_ORD_A;
			   end if;
			  
			   select tipo.ord_ts_det_tipo_id into ordTsDetTipoAId
			   from siac_d_ordinativo_ts_det_tipo tipo
			   where tipo.ente_proprietario_id=enteProprietarioId
			   and   tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A;

			   if ordTsDetTipoAId is null then
			   	RAISE EXCEPTION '% Identificativo ord_ts_det_tipo_code=% non reperito.',strMessaggio,ORD_TS_DET_TIPO_A;
			   end if;
			  
 
			   select coalesce(sum(det.ord_ts_det_importo),0) into importoPagatoDelta
				from  
					 siac_r_movgest_bil_elem re,
					 siac_t_movgest  mov, -- mov, 
					 siac_t_movgest_ts ts, --ts,
					 siac_r_liquidazione_movgest rliq,
					 siac_r_liquidazione_ord rord, 
					 siac_t_ordinativo_ts ordts, 
					 siac_t_ordinativo ord,
					 siac_r_ordinativo_stato rordstato,
					 siac_t_ordinativo_ts_det det, --tsdet,
					 siac_r_movgest_ts_stato rmov_stato
				where  re.elem_id=elemIdGestEq -- UID del capitolo di gestione equivalente
				and    mov.movgest_id=re.movgest_id 
				and    mov.movgest_tipo_id=movGestTipoId -- deve essere IMPEGNO				
				and    mov.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
			    and    mov.movgest_anno < annoMovimento::integer -- anno dell impegno < annoMovimento
				and    ts.movgest_id=mov.movgest_id
			    and    rmov_stato.movgest_ts_id=ts.movgest_ts_id			    
				and    rmov_stato.movgest_stato_id<>movGestStatoIdAnnullato -- non ANNULLATO			    
		     	and    rliq.movgest_ts_id=ts.movgest_ts_id				
				and    rord.liq_id=rliq.liq_id
				and    ordts.ord_ts_id=rord.sord_id		     	
				and    ord.ord_id=ordts.ord_id
			    and    ord.bil_id = bilIdElemGestEq -- UID del bilancio in annoEsercizio
				and    rordstato.ord_id=ord.ord_id
				and    rordstato.ord_stato_id!=ordStatoAId -- non deve essere Annullato
				and    det.ord_ts_id=ordts.ord_ts_id
				and    det.ord_ts_det_tipo_id=ordTsDetTipoAId -- importo attuale
				and    det.data_cancellazione is null
				and    det.validita_fine is null
				and    mov.data_cancellazione is null
				and    mov.validita_fine is null
				and    ts.data_cancellazione is null
				and    ts.validita_fine is null
				and    re.data_cancellazione is null
				and    re.validita_fine is null
				and    rord.data_cancellazione is null
				and    rord.validita_fine is null
				and    rliq.data_cancellazione is null
				and    rliq.validita_fine is null
				and    ordts.data_cancellazione is null
				and    ordts.validita_fine is null
				and    ord.data_cancellazione is null
				and    ord.validita_fine is null
				and    rordstato.data_cancellazione is null
				and    rordstato.validita_fine is null
				and    rmov_stato.data_cancellazione is null
				and    rmov_stato.validita_fine is null;

				if importoPagatoDelta is null then importoPagatoDelta:=0; end if;
   			    raise notice 'importoPagatoDelta=%',importoPagatoDelta;

			end if;		
		end if;
	end if;


	impegnatoDefinitivo:=0; 
	impegnatoDefinitivo:=impegnatoDefinitivo+importoImpegnato-(importoPagatoDelta);
    raise notice 'impegnatoDefinitivo=%',impegnatoDefinitivo;
	return impegnatoDefinitivo;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return impegnatoDefinitivo;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return impegnatoDefinitivo;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return impegnatoDefinitivo;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_up (id_in integer)
  OWNER TO siac;


CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_ug ( id_in integer, tipo_importo_in varchar )
RETURNS numeric  AS
$body$
DECLARE


annoBilancio varchar:=null;
annoEsercizio varchar:=null;
annoMovimento varchar:=null;

NVL_STR     constant varchar:='';
faseOpCode varchar(20):=NVL_STR;
bilancioId integer:=0;

elemTipoCode VARCHAR(20):=NVL_STR;

enteProprietarioId INTEGER:=0;

TIPO_CAP_UG constant varchar:='CAP-UG';


FASE_OP_BIL_PREV constant VARCHAR:='P';

STATO_A     constant varchar:='A';
TIPO_IMP    constant varchar:='I';

movGestStatoIdAnnullato integer:=0;
movGestTipoId integer:=0;

movGestTsDetTipoAttualeId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsDetTipoIdIniziale integer:=0;

IMPORTO_ATT constant varchar:='A';
IMPORTO_INIZIALE constant varchar:='I';

importoImpegnato numeric:=0;


strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato residuo definitvo elem_id='||id_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
    if coalesce(tipo_importo_in,NVL_STR)=NVL_STR or
       coalesce(tipo_importo_in,NVL_STR) not in (IMPORTO_ATT,IMPORTO_INIZIALE) then 
       RAISE EXCEPTION '% Parametro tipo importo non presente o non valido.',strMessaggio;
    end if;

	strMessaggio:='Calcolo totale impegnato residuo definitvo elem_id='||id_in||
    			  '. Lettura informazioni elemento di bilancio passato.' || 
				   '. Calcolo annoBilancio, bilancioId e elem_tipo_code.';
	 select  bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id
	 into   bilancioId, elemTipoCode , annoBilancio,enteProprietarioId
	 from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	 where bilElem.elem_id=id_in
	   and bilElem.data_cancellazione is null
	   and bilElem.validita_fine is null
	   and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	   and bil.bil_id=bilElem.bil_id
	   and per.periodo_id=bil.periodo_id;
     
	 if annoBilancio is null then
		 RAISE EXCEPTION '% Anno bilancio non reperito.',strMessaggio;
	 end if;

	 if enteProprietarioId is null then
		 RAISE EXCEPTION '% enteProprietarioId non reperito.',strMessaggio;
	 end if;
	
	 if elemTipoCode is null then
		 RAISE EXCEPTION '% elemTipoCode non reperito.',strMessaggio;
	 end if;
	
	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
	 end if;

	 strMessaggio:='Calcolo totale impegnato residuo definitvo elem_id='||id_in||
				   'Calcolo fase operativa per bilancioId='||bilancioId
				   ||' per ente='||enteProprietarioId||'.';

	 select  faseOp.fase_operativa_code into  faseOpCode
	 from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
	 where bilFase.bil_id =bilancioId
	   and bilfase.data_cancellazione is null
	   and bilFase.validita_fine is null
	   and faseOp.fase_operativa_id=bilFase.fase_operativa_id
	   and faseOp.data_cancellazione is null
	 order by bilFase.bil_fase_operativa_id desc;

	 if NOT FOUND or faseOpCode is null THEN
	   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;
 
	 if movGestTipoId is null then
	   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	  end if;
		
	 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO.';

	 select movGestStato.movgest_stato_id into movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;
	
	 if movGestStatoIdAnnullato is null then
	 		   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	
	 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoAttualeId per movgest_ts_det_tipo_code=IMPORTO ATTUALE.';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into movGestTsDetTipoAttualeId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 if movGestTsDetTipoAttualeId is null then
	 		   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	
	 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE.';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into  movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;

	 if movGestTsDetTipoIdIniziale is null then
	 		   RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	 end if;

	
	 annoEsercizio:=annoBilancio;
	 annoMovimento:=annoBilancio;
		
 	
	 if tipo_importo_in = IMPORTO_INIZIALE then 
	    strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
 						||'.Inizio calcolo totale importo iniziale   impegni residui per anno esercizio ='||annoEsercizio||
						' anno movimento ='||annoMovimento||'.';
	    movGestTsDetTipoId:=movGestTsDetTipoIdIniziale;
					
    else 
		 strMessaggio:='Calcolo impegnato residuo definitivo elem_id='||id_in
						||'.Inizio calcolo totale importo attuale   impegni residui per anno esercizio ='||annoEsercizio||
						' anno movimento ='||annoMovimento||'.';

   	    movGestTsDetTipoId:=movGestTsDetTipoAttualeId;
    end if;
   
	importoImpegnato:=0;			
	select tb.importo into importoImpegnato
	from 
	(
	  select coalesce(sum(det.movgest_ts_det_importo),0) importo, ts.movgest_ts_tipo_id
	  from  siac_r_movgest_bil_elem re,
		    siac_t_movgest mov,
		    siac_t_movgest_ts ts,
		    siac_r_movgest_ts_stato rs,
		    siac_t_movgest_ts_det det
	  where re.elem_id=id_in
	  and   mov.movgest_id=re.movgest_id 
	  and   mov.bil_id=bilancioId
	  and   mov.movgest_tipo_Id=movGestTipoId
	  and   mov.movgest_anno<annoMovimento::integer
	  and   ts.movgest_id=mov.movgest_id 
	  and   rs.movgest_ts_id=ts.movgest_ts_id 
	  and   rs.movgest_stato_id!=movGestStatoIdAnnullato
	  and   det.movgest_ts_id=ts.movgest_ts_id 
	  and   det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   re.data_cancellazione is null 
      and   re.validita_fine is null 
      and   mov.data_cancellazione is null 
      and   ts.data_cancellazione is null 
      and   rs.data_cancellazione is null 
      and   rs.validita_fine is null
      group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo tipo
	where tb.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
	order by tipo.movgest_ts_tipo_code desc
	limit 1;		
	if importoImpegnato is null then importoImpegnato:=0; end if;

	raise notice 'importoImpegnato=%',importoImpegnato;
	return importoImpegnato;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return importoImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return importoImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return importoImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_ug (id_in integer, tipo_importo_in varchar ) OWNER TO siac;
 
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_iniziale_ug ( id_in integer)
RETURNS numeric  AS
$body$
DECLARE



importoImpegnato numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN
    
    strMessaggio:='Calcolo totale impegnato residuo effettivo iniziale elem_id='||id_in|| '.';
    importoImpegnato:=fnc_siac_impegnatoresiduo_effettivo_ug ( id_in, 'I');
		if importoImpegnato is null then importoImpegnato:=0; end if;

	raise notice 'importoImpegnato=%',importoImpegnato;
	return importoImpegnato;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return importoImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return importoImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return importoImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_iniziale_ug (id_in integer) OWNER TO siac;

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug ( id_in integer)
RETURNS numeric  AS
$body$
DECLARE



importoImpegnato numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN
    
    strMessaggio:='Calcolo totale impegnato residuo effettivo iniziale elem_id='||id_in|| '.';
    importoImpegnato:=fnc_siac_impegnatoresiduo_effettivo_ug ( id_in, 'A');
		if importoImpegnato is null then importoImpegnato:=0; end if;

	raise notice 'importoImpegnato=%',importoImpegnato;
	return importoImpegnato;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return importoImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return importoImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return importoImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug (id_in integer) OWNER TO siac;
 
CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_ug_annoprec ( id_in integer, tipo_importo_in varchar )
RETURNS numeric  AS
$body$
DECLARE


annoBilancio varchar:=null;
annoBilancioPrec varchar:=null;



NVL_STR     constant varchar:='';
bilancioId integer:=0;
bilancioPrecId integer:=0;

elemTipoCode VARCHAR(20):=NVL_STR;

enteProprietarioId INTEGER:=0;

TIPO_CAP_UG constant varchar:='CAP-UG';

elemPrecId integer:=null;

elemCode varchar(100):=null;
elemCode2 varchar(100):=null;
elemCode3 varchar(100):=null;

STATO_A     constant varchar:='A';
TIPO_IMP    constant varchar:='I';

movGestStatoIdAnnullato integer:=0;
movGestTipoId integer:=0;

movGestTsDetTipoAttualeId integer:=0;
movGestTsDetTipoId integer:=0;

movGestTsDetTipoIdIniziale integer:=0;

IMPORTO_ATT constant varchar:='A';
IMPORTO_INIZIALE constant varchar:='I';

importoImpegnato numeric:=0;


strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in|| '.';

	-- Controllo parametri in input
	if id_in is null or id_in=0 then
		 RAISE EXCEPTION '% Identificativo elemento di bilancio mancante.',strMessaggio;
	end if;
 
    if coalesce(tipo_importo_in,NVL_STR)=NVL_STR or
       coalesce(tipo_importo_in,NVL_STR) not in (IMPORTO_ATT,IMPORTO_INIZIALE) then 
       RAISE EXCEPTION '% Parametro tipo importo non presente o non valido.',strMessaggio;
    end if;

	strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in||
    			  '. Lettura informazioni elemento di bilancio.' || 
				   '. Calcolo annoBilancio, bilancioId e elem_tipo_code.';
	select  bil.bil_id ,tipoBilElem.elem_tipo_code, per.anno , bil.ente_proprietario_id,
	        bilElem.elem_code, bilelem.elem_code2,bilElem.elem_code3
	into   bilancioId, elemTipoCode , annoBilancio,enteProprietarioId, elemCode, elemCode2,elemCode3
	from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
	  and bilElem.data_cancellazione is null
	  and bilElem.validita_fine is null
	  and tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id
	  and bil.bil_id=bilElem.bil_id
	  and per.periodo_id=bil.periodo_id;
     
	 if annoBilancio is null then
		 --RAISE EXCEPTION '% Anno bilancio non reperito.',strMessaggio;
		 RAISE notice '% Anno bilancio non reperito.',strMessaggio;
		 importoImpegnato:=0;
	     return importoImpegnato;
	   
	 end if;

	 if enteProprietarioId is null then
		 --RAISE EXCEPTION '% enteProprietarioId non reperito.',strMessaggio;
		 RAISE notice '% enteProprietarioId non reperito.',strMessaggio;
		 importoImpegnato:=0;
	     return importoImpegnato;
	 end if;
	
	 if elemTipoCode is null then
		 --RAISE EXCEPTION '% elemTipoCode non reperito.',strMessaggio;
		 RAISE notice '% elemTipoCode non reperito.',strMessaggio;
		 importoImpegnato:=0;
	     return importoImpegnato;		 
	 end if;
	
	 if elemTipoCode is not null and elemTipoCode!=NVL_STR and elemTipoCode!=TIPO_CAP_UG then
			--RAISE EXCEPTION '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
			RAISE notice '% elemTipoCode=%  non ammesso per tipo di calcolo.',strMessaggio,elemTipoCode;
		    importoImpegnato:=0;
	        return importoImpegnato;		 			
	 end if;

	 if elemCode is null or elemCode2 is null or elemCode3 is null then 
		 --RAISE EXCEPTION '% chiave logica elemento bilancio non reperita.',strMessaggio;
		 RAISE notice '% chiave logica elemento bilancio non reperita.',strMessaggio;
		 importoImpegnato:=0;
	     return importoImpegnato;		 					 
	 end if;

 	 strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in||
    			  '. Lettura informazioni elemento di bilancio anno prec.';	
	 select rel.elem_id_old into elemPrecId
	 from siac_r_bil_elem_rel_tempo rel 
	 where rel.ente_proprietario_id=enteProprietarioId
	 and   rel.elem_id=id_in
	 and   rel.data_cancellazione is null 
	 and   rel.validita_fine is null;
	 raise notice 'elemPrecId=%',elemPrecId;
	
     if elemPrecId is null then
  	    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in||
    			      '. Lettura informazioni elemento di bilancio anno prec in anno prec - equivalente .';	
 		select  bil.bil_id , per.anno ,bilElem.elem_id
		into    bilancioPrecId, annoBilancioPrec,elemPrecId
		from 	siac_t_bil_elem bilElem, 
	 		siac_d_bil_elem_tipo tipoBilElem,
		  	siac_t_bil bil, siac_t_periodo per
		where bilElem.ente_proprietario_id=enteProprietarioId
		and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id 
		and   tipoBilElem.elem_tipo_code=TIPO_CAP_UG
		and   bilElem.elem_code=elemCode
		and   bilElem.elem_code2=elemCode2
		and   bilElem.elem_code3=elemCode3
		and   bil.bil_id=bilElem.bil_id 
		and   per.periodo_id=bil.periodo_id
		and   per.anno::integer=(annoBilancio::integer)-1
	    and   bilElem.data_cancellazione is null
		and   bilElem.validita_fine is null;
	 else
	    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in||
    			      '. Lettura informazioni elemento di bilancio anno prec in anno prec - rel_tempo .';	
	    select  bil.bil_id , per.anno
		into    bilancioPrecId, annoBilancioPrec
		from 	siac_t_bil_elem bilElem, 
  		 		siac_d_bil_elem_tipo tipoBilElem,
			  	siac_t_bil bil, siac_t_periodo per
		where bilElem.ente_proprietario_id=enteProprietarioId
		and   bilElem.elem_id=elemPrecId
		and   tipoBilElem.elem_tipo_id=bilElem.elem_tipo_id 
		and   tipoBilElem.elem_tipo_code=TIPO_CAP_UG
		and   bil.bil_id=bilElem.bil_id 
		and   per.periodo_id=bil.periodo_id
		and   per.anno::integer=(annoBilancio::integer)-1
	    and   bilElem.data_cancellazione is null
		and   bilElem.validita_fine is null;
     end if;
	 
    
     if elemPrecId is null then 
     	RAISE NOTICE '%  Identificativo elemento bilancio anno prec non reperita.',strMessaggio; 
	    importoImpegnato:=0;
	    return importoImpegnato;
	   
     end if;

     if bilancioPrecId is null or annoBilancioPrec is null then 
     	--RAISE EXCEPTION '%  Informazioni elemento bilancio anno prec non reperite.',strMessaggio; 
        RAISE notice '%  Informazioni elemento bilancio anno prec non reperite.',strMessaggio; 
		importoImpegnato:=0;
	    return importoImpegnato;		 					 		
     end if;
    
  	 strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
				  ||'. Calcolo movGestTipoId per movgest_tipo_code=IMPEGNO';
	 select tipoMovGest.movgest_tipo_id into movGestTipoId
	 from  siac_d_movgest_tipo tipoMovGest
	 where tipoMovGest.ente_proprietario_id=enteProprietarioId
	 and   tipoMovGest.movgest_tipo_code= TIPO_IMP;
 
	 if movGestTipoId is null then
	   --RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	   RAISE notice '% Dato non reperito.',strMessaggio;
	   importoImpegnato:=0;
	   return importoImpegnato;		 					 			   
	  end if;
		
     strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
				  ||'. Calcolo movGestTsStatoIdAnnullato per movgest_stato_code=ANNULLATO.';

	 select movGestStato.movgest_stato_id into movGestStatoIdAnnullato
	 from siac_d_movgest_stato movGestStato
	 where movGestStato.ente_proprietario_id=enteProprietarioId
	 and   movGestStato.movgest_stato_code=STATO_A;
	
	 if movGestStatoIdAnnullato is null then
	   --RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	   RAISE notice '% Dato non reperito.',strMessaggio;
	   importoImpegnato:=0;
	   return importoImpegnato;		 					 			   			   
	 end if;

	
     strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoAttualeId per movgest_ts_det_tipo_code=IMPORTO ATTUALE.';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into movGestTsDetTipoAttualeId
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_ATT;

	 if movGestTsDetTipoAttualeId is null then
	 		   --RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
			   RAISE notice '% Dato non reperito.',strMessaggio;
	           importoImpegnato:=0;
	           return importoImpegnato;		 					 			   			   
	 end if;

	
     strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
				  ||'. Calcolo movGestTsDetTipoIdIniziale per movgest_ts_det_tipo_code=IMPORTO INIZIALE.';

	 select movGestTsDetTipo.movgest_ts_det_tipo_id into  movGestTsDetTipoIdIniziale
	 from siac_d_movgest_ts_det_tipo movGestTsDetTipo
	 where movGestTsDetTipo.ente_proprietario_id=enteProprietarioId
	 and   movGestTsDetTipo.movgest_ts_det_tipo_code=IMPORTO_INIZIALE;

	 if movGestTsDetTipoIdIniziale is null then
	 		   --RAISE EXCEPTION '% Dato non reperito.',strMessaggio;
	   RAISE notice '% Dato non reperito.',strMessaggio;
	   importoImpegnato:=0;
	   return importoImpegnato;		 					 			   			   			   
	 end if;

	
 	
	 if tipo_importo_in = IMPORTO_INIZIALE then 
  	    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
 						||'.Inizio calcolo totale importo iniziale  impegni residui per anno esercizio ='||annoBilancioPrec||'.';
	    movGestTsDetTipoId:=movGestTsDetTipoIdIniziale;
					
    else 
  	    strMessaggio:='Calcolo totale impegnato residuo effettivo anno prec. elem_id='||id_in
						||'.Inizio calcolo totale importo attuale   impegni residui per anno esercizio ='||annoBilancioPrec||'.';

   	    movGestTsDetTipoId:=movGestTsDetTipoAttualeId;
    end if;
   
	importoImpegnato:=0;			
	select tb.importo into importoImpegnato
	from 
	(
	  select coalesce(sum(det.movgest_ts_det_importo),0) importo, ts.movgest_ts_tipo_id
	  from  siac_r_movgest_bil_elem re,
		    siac_t_movgest mov,
		    siac_t_movgest_ts ts,
		    siac_r_movgest_ts_stato rs,
		    siac_t_movgest_ts_det det
	  where re.elem_id=elemPrecId
	  and   mov.movgest_id=re.movgest_id 
	  and   mov.bil_id=bilancioPrecId
	  and   mov.movgest_tipo_Id=movGestTipoId
	  and   mov.movgest_anno<annoBilancioPrec::integer
	  and   ts.movgest_id=mov.movgest_id 
	  and   rs.movgest_ts_id=ts.movgest_ts_id 
	  and   rs.movgest_stato_id!=movGestStatoIdAnnullato
	  and   det.movgest_ts_id=ts.movgest_ts_id 
	  and   det.movgest_ts_det_tipo_id=movGestTsDetTipoId
      and   re.data_cancellazione is null 
      and   re.validita_fine is null 
      and   mov.data_cancellazione is null 
      and   ts.data_cancellazione is null 
      and   rs.data_cancellazione is null 
      and   rs.validita_fine is null
      group by ts.movgest_ts_tipo_id
    ) tb, siac_d_movgest_ts_tipo tipo
	where tb.movgest_ts_tipo_id=tipo.movgest_ts_tipo_id
	order by tipo.movgest_ts_tipo_code desc
	limit 1;		
	if importoImpegnato is null then importoImpegnato:=0; end if;

	raise notice 'importoImpegnato=%',importoImpegnato;
	return importoImpegnato;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return importoImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return importoImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return importoImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_ug_annoprec ( id_in integer, tipo_importo_in varchar ) OWNER TO siac;

CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_iniziale_ug_annoprec ( id_in integer)
RETURNS numeric  AS
$body$
DECLARE



importoImpegnato numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN
    
    strMessaggio:='Calcolo totale impegnato residuo effettivo iniziale anno prec. elem_id='||id_in|| '.';
    importoImpegnato:=fnc_siac_impegnatoresiduo_effettivo_ug_annoprec ( id_in, 'I');
		if importoImpegnato is null then importoImpegnato:=0; end if;

	raise notice 'importoImpegnato=%',importoImpegnato;
	return importoImpegnato;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return importoImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return importoImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return importoImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_iniziale_ug_annoprec (id_in integer) OWNER TO siac;
 CREATE OR REPLACE FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug_annoprec ( id_in integer)
RETURNS numeric  AS
$body$
DECLARE



importoImpegnato numeric:=0;
strMessaggio varchar(1500):=null;

BEGIN
    
    strMessaggio:='Calcolo totale impegnato residuo effettivo attuale anno prec. elem_id='||id_in|| '.';
    importoImpegnato:=fnc_siac_impegnatoresiduo_effettivo_ug_annoprec ( id_in, 'A');
		if importoImpegnato is null then importoImpegnato:=0; end if;

	raise notice 'importoImpegnato=%',importoImpegnato;
	return importoImpegnato;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
		return importoImpegnato;
	when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
		return importoImpegnato;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
		return importoImpegnato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_siac_impegnatoresiduo_effettivo_attuale_ug_annoprec (id_in integer) OWNER TO siac;
  
--- SIAC-8529,SIAC-8630 Sofia - 11.03.2022 - fine 

--SIAC-8412 e SIAC-8694 - Maurizio - INIZIO


-- Aggiornamento posizione variabili e creazione nuova variabile per REPORT BILR141 
update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=1
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>1
and rep_imp.repimp_codice='util_avanz_amm_finanz_spese_corr'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=2
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>2
and rep_imp.repimp_codice='dis_amm_prec_rend'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=3
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>3
and rep_imp.repimp_codice='e_cc_est_ant_pres'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=4
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>4
and rep_imp.repimp_codice='e_acc_ant_pres'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=5
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>5
and rep_imp.repimp_codice='e_pc_spese_cor'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=7
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>7
and rep_imp.repimp_codice='di_cui_ant_pres'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=8
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>8
and rep_imp.repimp_codice='di_cui_ant_liq_spese_rend'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=9
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>9
and rep_imp.repimp_codice='risorse_accant_parte_corr_reg'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=10
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>10
and rep_imp.repimp_codice='risorse_vincolate_parte_corr_reg'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=11
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>11
and rep_imp.repimp_codice='var_accant_parte_corr_sede_rend_reg'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=12
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>12
and rep_imp.repimp_codice='ris_amm_spese'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=13
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>13
and rep_imp.repimp_codice='disav_debito_non_contr_rip_acc_prestiti'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=14
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>14
and rep_imp.repimp_codice='ris_accant_cc_stanz_eserc'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=15
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>15
and rep_imp.repimp_codice='ris_vincol_cc_bilancio'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=16
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>16
and rep_imp.repimp_codice='variaz_accant_cc_rend'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=17
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>17
and rep_imp.repimp_codice='B3_dicui_disav_deb_autor'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=18
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>18
and rep_imp.repimp_codice='ris_amm_att_fin'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=19
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>19
and rep_imp.repimp_codice='ris_accant_att_finanz_stanz_eserc'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=20
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>20
and rep_imp.repimp_codice='ris_vincol_att_finanz_bilancio'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=21
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>21
and rep_imp.repimp_codice='variaz_accant_att_finanz_rend'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=22
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>22
and rep_imp.repimp_codice='ent_non_ricorr_copert_impegni'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=23
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>23
and rep_imp.repimp_codice='fpv_spese_corr_non_riacc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=24
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>24
and rep_imp.repimp_codice='risorse_accant_parte_corr_non_sanit_eserc'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=25
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>25
and rep_imp.repimp_codice='variaz_accant_parte_corr_non_sanit_rend'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=26
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>26
and rep_imp.repimp_codice='variaz_accant_parte_corr_non_sanit'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=27
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>27
and rep_imp.repimp_codice='ent_titoli_123_SSN'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=28
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in(2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR141'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>28
and rep_imp.repimp_codice='spese_correnti_SSN'
and r_rep_imp.data_cancellazione IS NULL);



INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_spese_non_ricorr',
	'Spese correnti - di cui spese correnti non ricorrenti finanziate con utilizzo del risultato di amministrazione',
	NULL,
	'N',
	32,
	bil.bil_id,
    per2.periodo_id,
	now(),
	NULL,
	bil.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'SIAC-8412'
from  siac_t_bil bil, 
siac_t_periodo per, siac_d_periodo_tipo tipo_per,
siac_t_periodo per2, siac_d_periodo_tipo tipo_per2
where bil.periodo_id = per.periodo_id
and tipo_per.periodo_tipo_id=per.periodo_tipo_id
and per2.ente_proprietario_id=per.ente_proprietario_id
and tipo_per2.periodo_tipo_id=per2.periodo_tipo_id
and bil.ente_proprietario_id  in (2,3,4,5,10,11,14,16)
and per.anno::integer >= 2021
and tipo_per.periodo_tipo_code='SY'
and per2.anno = per.anno
and tipo_per2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=bil.ente_proprietario_id 
	  and z.bil_id = bil.bil_id
	  and z.periodo_id = per2.periodo_id
      and z.repimp_codice='di_cui_spese_non_ricorr');
      

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR141'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
6 posizione_stampa, 
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-8412' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_spese_non_ricorr')
and c.anno::INTEGER>=2021
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR141'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));
      
-- Aggiornamento posizione variabili e creazione nuova variabile per REPORT BILR142
update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=1
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>1
and rep_imp.repimp_codice='dis_amm_prec_rec'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=2
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>2
and rep_imp.repimp_codice='di_cui_e_t_123'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=4
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>4
and rep_imp.repimp_codice='di_cui_s_t_4'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=5
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>5
and rep_imp.repimp_codice='di_cui_ant_liq_spese_rend'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=6
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>6
and rep_imp.repimp_codice='ava_amm_s_c'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=7
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>7
and rep_imp.repimp_codice='di_cui_ava_amm_s_c'
and r_rep_imp.data_cancellazione IS NULL);



update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=8
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>8
and rep_imp.repimp_codice='e_cap_des_s_c'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=9
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>9
and rep_imp.repimp_codice='di_cui_e_cap_des_s_c'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=10
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>10
and rep_imp.repimp_codice='e_cor_des_s_i'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=11
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>11
and rep_imp.repimp_codice='e_pres_des_e_a'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=12
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>12
and rep_imp.repimp_codice='risorse_accant_parte_corr'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=13
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>13
and rep_imp.repimp_codice='risorse_vincolate_parte_corr'
and r_rep_imp.data_cancellazione IS NULL);




update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=14
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>14
and rep_imp.repimp_codice='ava_amm_s_i'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=15
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>15
and rep_imp.repimp_codice='z_1_risor_accant_cc_stanz_eserc'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=16
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>16
and rep_imp.repimp_codice='risor_vinc_cc_bilancio'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=17
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>17
and rep_imp.repimp_codice='var_accant_cc_sede_rend'
and r_rep_imp.data_cancellazione IS NULL);

update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=18
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>18
and rep_imp.repimp_codice='entr_non_ricor_senza_coper_impegni'
and r_rep_imp.data_cancellazione IS NULL);


update siac_r_report_importi
set data_modifica=now(),
	login_operazione=login_operazione|| ' - SIAC-8412',
    posizione_stampa=19
where reprimp_id in(select r_rep_imp.reprimp_id
from siac_t_report rep,
	siac_t_report_importi rep_imp,
    siac_r_report_importi r_rep_imp,
    siac_t_bil bil,
    siac_t_periodo per
where rep.rep_id= r_rep_imp.rep_id
and r_rep_imp.repimp_id= rep_imp.repimp_id
and rep_imp.bil_id=bil.bil_id
and rep_imp.periodo_id=per.periodo_id
and rep_imp.bil_id=bil.bil_id
and bil.periodo_id=per.periodo_id
and rep.ente_proprietario_id in (2,3,4,5,10,11,14,16)
and rep.rep_codice='BILR142'
and per.anno::integer >=2021
and r_rep_imp.posizione_stampa<>19
and rep_imp.repimp_codice='var_accant_parte_corr_sede_rend'
and r_rep_imp.data_cancellazione IS NULL);


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)
SELECT 'di_cui_spese_non_ricorr_EELL',
	'D) Spese Titolo 1.00 - Spese correnti - di cui spese correnti non ricorrenti finanziate con utilizzo del risultato di amministrazione',
	NULL,
	'N',
	30,
	bil.bil_id,
    per2.periodo_id,
	now(),
	NULL,
	bil.ente_proprietario_id,
	now(),
	now(),
	NULL,
	'SIAC-8412'
from  siac_t_bil bil, 
siac_t_periodo per, siac_d_periodo_tipo tipo_per,
siac_t_periodo per2, siac_d_periodo_tipo tipo_per2
where bil.periodo_id = per.periodo_id
and tipo_per.periodo_tipo_id=per.periodo_tipo_id
and per2.ente_proprietario_id=per.ente_proprietario_id
and tipo_per2.periodo_tipo_id=per2.periodo_tipo_id
and bil.ente_proprietario_id  in (2,3,4,5,10,11,14,16)
and per.anno::integer >= 2021
and tipo_per.periodo_tipo_code='SY'
and per2.anno = per.anno
and tipo_per2.periodo_tipo_code='SY'
	and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=bil.ente_proprietario_id 
	  and z.bil_id = bil.bil_id
	  and z.periodo_id = per2.periodo_id
      and z.repimp_codice='di_cui_spese_non_ricorr_EELL');
      

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR142'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
3 posizione_stampa, 
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-8412' login_operazione
from   siac_t_report_importi a,
		siac_t_bil b,
        siac_t_periodo c
where  a.bil_id=b.bil_id
and b.periodo_id=c.periodo_id
and a.repimp_codice in ('di_cui_spese_non_ricorr_EELL')
and c.anno::INTEGER>=2021
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id
      and z.rep_id in(select dd.rep_id
			from   siac_t_report dd
			where  dd.rep_codice = 'BILR142'
				and    dd.ente_proprietario_id = a.ente_proprietario_id));
                
                	  
	  
--Configurazione XBRL dei 2 nuovi campi.

insert into siac_t_xbrl_mapping_fatti(
xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,
   xbrl_mapfat_periodo_code , xbrl_mapfat_unit_code,
   xbrl_mapfat_decimali,  validita_inizio,
  ente_proprietario_id ,  data_creazione,  data_modifica,
  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select xbrl.xbrl_mapfat_rep_codice, 'dicui_spese_correnti_non_ricorrerenti', 
'EQREG-COR_SpeseCorrentiNonRicorrenti',
xbrl.xbrl_mapfat_periodo_code, xbrl.xbrl_mapfat_unit_code,
xbrl.xbrl_mapfat_decimali, now(), xbrl.ente_proprietario_id,now(), now(),
'SIAC-8412', xbrl.xbrl_mapfat_periodo_tipo,  xbrl.xbrl_mapfat_forza_visibilita
from siac_t_xbrl_mapping_fatti xbrl
where xbrl.xbrl_mapfat_rep_codice='BILR141'
and xbrl.xbrl_mapfat_variabile = 'Spese_correnti'  
and not exists (select 1
	from  siac_t_xbrl_mapping_fatti xbrl_1
    where xbrl_1.ente_proprietario_id=xbrl.ente_proprietario_id
    	and xbrl_1.xbrl_mapfat_rep_codice= 'BILR141'
        and xbrl_1.xbrl_mapfat_variabile='dicui_spese_correnti_non_ricorrerenti');    
     
	 

insert into siac_t_xbrl_mapping_fatti(
xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto,
   xbrl_mapfat_periodo_code , xbrl_mapfat_unit_code,
   xbrl_mapfat_decimali,  validita_inizio,
  ente_proprietario_id ,  data_creazione,  data_modifica,
  login_operazione,  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select xbrl.xbrl_mapfat_rep_codice, 'dicui_spese_correnti_non_ricorrerenti', 
'EQEL-COR_SpeseTitolo1.00NonRicorrenti',
xbrl.xbrl_mapfat_periodo_code, xbrl.xbrl_mapfat_unit_code,
xbrl.xbrl_mapfat_decimali, now(), xbrl.ente_proprietario_id,now(), now(),
'SIAC-8412', xbrl.xbrl_mapfat_periodo_tipo,  xbrl.xbrl_mapfat_forza_visibilita
from siac_t_xbrl_mapping_fatti xbrl
where xbrl.xbrl_mapfat_rep_codice='BILR142'
and xbrl.xbrl_mapfat_variabile = 'Spese_correnti'  
and not exists (select 1
	from  siac_t_xbrl_mapping_fatti xbrl_1
    where xbrl_1.ente_proprietario_id=xbrl.ente_proprietario_id
    	and xbrl_1.xbrl_mapfat_rep_codice= 'BILR142'
        and xbrl_1.xbrl_mapfat_variabile='dicui_spese_correnti_non_ricorrerenti');    
      	 
	  
--Funzione modificata.
CREATE OR REPLACE FUNCTION siac."BILR141_equilibri_bilancio_rendiconto_cap_spesa" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  pdc_finanziario varchar,
  categ_capitolo varchar
) AS
$body$
DECLARE


classifBilRec record;


annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma  varchar;
v_fam_titolomacroaggregato varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
bilancio_id integer;

BEGIN

--PROCEDURA NUOVA CREATA PER SIAC-7192

--annoCapImp:= p_anno; 
annoCapImp:=p_anno;


raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
v_fam_missioneprogramma :='00001';
v_fam_titolomacroaggregato := '00002';

-- 21/07/2016: il report funziona solo per la gestione, tolta la query
--  che legge la fase di bilancio.
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione


missione_code='';
missione_desc='';

programma_code='';
programma_desc='';

titusc_code='';
titusc_desc='';

macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;

stanziamento=0;
cassa=0;
residuo=0;


select fnc_siac_random_user()
into	user_table;

select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where b.periodo_id=a.periodo_id
	and a.ente_proprietario_id=p_ente_prop_id 
	and b.anno=p_anno;
    
insert into siac_rep_cap_ug_imp 
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
           	sum(capitolo_importi.elem_det_importo)       
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,            
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
    where 	capitolo.elem_id						=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id					=	tipo_elemento.elem_tipo_id 						
        and capitolo_importi.elem_det_tipo_id		=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id			=	capitolo_importi.periodo_id 			          
        and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
		and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
		and capitolo_importi.ente_proprietario_id 	=	p_ente_prop_id  
        and	capitolo.bil_id							= bilancio_id
        and	tipo_elemento.elem_tipo_code 			= 	elemTipoCode
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	stato_capitolo.elem_stato_code	=	'VA'												
        and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
    	and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
    	and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;


return query 
with strutt_bilancio as (select *
        		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
		capitoli as (select programma.classif_id programma_id,
						macroaggr.classif_id macroaggregato_id,        				
       					capitolo.elem_code, capitolo.elem_code2,
                        capitolo.elem_desc, capitolo.elem_desc2,
                        capitolo.elem_id, cat_del_capitolo.elem_cat_code
                from siac_d_class_tipo programma_tipo,
                     siac_t_class programma,
                     siac_d_class_tipo macroaggr_tipo,
                     siac_t_class macroaggr,
                     siac_t_bil_elem capitolo,
                     siac_d_bil_elem_tipo tipo_elemento,
                     siac_r_bil_elem_class r_capitolo_programma,
                     siac_r_bil_elem_class r_capitolo_macroaggr, 
                     siac_d_bil_elem_stato stato_capitolo, 
                     siac_r_bil_elem_stato r_capitolo_stato,
                     siac_d_bil_elem_categoria cat_del_capitolo,
                     siac_r_bil_elem_categoria r_cat_capitolo
                where programma.classif_tipo_id=programma_tipo.classif_tipo_id 				
                    and programma.classif_id=r_capitolo_programma.classif_id	
                    and macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 
                    and macroaggr.classif_id=r_capitolo_macroaggr.classif_id								
                    and capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
                    and capitolo.elem_id=r_capitolo_programma.elem_id		
                    and capitolo.elem_id=r_capitolo_macroaggr.elem_id	
                    and capitolo.elem_id		=	r_capitolo_stato.elem_id	
                    and r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
                    and capitolo.elem_id				=	r_cat_capitolo.elem_id	
                    and r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
                    and capitolo.ente_proprietario_id=p_ente_prop_id   		
                    and capitolo.bil_id= bilancio_id		
                    and programma_tipo.classif_tipo_code='PROGRAMMA'	
                    and macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'	                     							                    	
                    and tipo_elemento.elem_tipo_code = elemTipoCode			                     			                    
                    and stato_capitolo.elem_stato_code	=	'VA'				
                    and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')                    
                    and	programma_tipo.data_cancellazione 			is null
                    and	programma.data_cancellazione 				is null
                    and	macroaggr_tipo.data_cancellazione 			is null
                    and	macroaggr.data_cancellazione 				is null
                    and	capitolo.data_cancellazione 				is null
                    and	tipo_elemento.data_cancellazione 			is null
                    and	r_capitolo_programma.data_cancellazione 	is null
                    and	r_capitolo_macroaggr.data_cancellazione 	is null 
                    and	stato_capitolo.data_cancellazione 			is null 
                    and	r_capitolo_stato.data_cancellazione 		is null
                    and	cat_del_capitolo.data_cancellazione 		is null
                    and	r_cat_capitolo.data_cancellazione 			is null),
         importi_stanz as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpComp -- ''STA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_cassa as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpCassa -- ''SCA''
                        and a.utente=user_table
                        group by  a.elem_id),
         importi_residui as (select a.elem_id, sum(a.importo) importo_cap
                        from siac_rep_cap_ug_imp a
                        where a.ente_proprietario =p_ente_prop_id
                        and a.periodo_anno=p_anno
                        and a.tipo_imp=TipoImpRes -- ''STR''
                        and a.utente=user_table
                        group by  a.elem_id),
          pdc_finanziario as
            ( select tc.classif_code, rmc.elem_id
             from   siac_r_bil_elem_class rmc, siac_t_class tc, siac_d_class_tipo dct,
                      siac_t_bil_elem e
             where  rmc.classif_id = tc.classif_id
             and    tc.classif_tipo_id = dct.classif_tipo_id
             and 	dct.ente_proprietario_id = p_ente_prop_id
             and    dct.classif_tipo_code in ( 'PDC_V', 'PDC_IV')
             and    e.elem_id = rmc.elem_id
             and    e.bil_id = bilancio_id
             and    rmc.data_cancellazione  is null
             and    tc.data_cancellazione   is null 
             and    dct.data_cancellazione  is null    
             	--04/03/2022 Nell'ambito delle modifiche legate alla SIAC-8412
                --e' stato riscontrato un errore (era fisso l'anno 2020 nel controllo
                --delle data validita' invece del parametro p_anno).
            -- and    to_timestamp('31/12/'||'2020','dd/mm/yyyy') between rmc.validita_inizio 
             --and COALESCE(rmc.validita_fine,to_timestamp('31/12/'||'2020','dd/mm/yyyy')) )         
			 and    to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between rmc.validita_inizio 
             and COALESCE(rmc.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy')) )                                                                      
		select 
  			strutt_bilancio.missione_code::varchar missione_code,
            strutt_bilancio.missione_desc::varchar missione_desc,           
            strutt_bilancio.programma_code::varchar programma_code,
            strutt_bilancio.programma_desc::varchar programma_desc,
            strutt_bilancio.titusc_code::varchar titusc_code,
            strutt_bilancio.titusc_desc::varchar titusc_desc,
            strutt_bilancio.macroag_code::varchar macroag_code,
            strutt_bilancio.macroag_desc::varchar macroag_desc,
            capitoli.elem_code::varchar bil_ele_code ,
            capitoli.elem_desc::varchar bil_ele_desc,
            capitoli.elem_code2::varchar bil_ele_code2,
            capitoli.elem_desc2::varchar bil_ele_desc2,
            capitoli.elem_id::integer bil_ele_id,
            COALESCE(importi_stanz.importo_cap,0)::numeric stanziamento,
            COALESCE(importi_cassa.importo_cap,0)::numeric cassa,
            COALESCE(importi_residui.importo_cap,0)::numeric residuo,
            COALESCE(pdc_finanziario.classif_code,'') pdc_finanziario,
            capitoli.elem_cat_code categ_capitolo                 
         from strutt_bilancio
         	LEFT JOIN capitoli
            	ON (strutt_bilancio.programma_id = capitoli.programma_id
                	and strutt_bilancio.macroag_id = capitoli.macroaggregato_id)
            LEFT JOIN importi_stanz
            	ON importi_stanz.elem_id = capitoli.elem_id
            LEFT JOIN importi_cassa
            	ON importi_cassa.elem_id = capitoli.elem_id
            LEFT JOIN importi_residui
            	ON importi_residui.elem_id = capitoli.elem_id
            LEFT JOIN pdc_finanziario
            	ON pdc_finanziario.elem_id = capitoli.elem_id
          where capitoli.elem_id IS NOT NULL;
                	
delete from siac_rep_cap_ug_imp where utente=user_table;    

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;   
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR141_equilibri_bilancio_rendiconto_cap_spesa" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;

  
--Funzione nuova.  
CREATE OR REPLACE FUNCTION siac."BILR141_calcola_spese_correnti_non_ricorrenti" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  importo_spese numeric
) AS
$body$
DECLARE

DEF_NULL	  constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

bilancio_id    integer;

BEGIN

/* 
	04/03/2022 Funzione nata per la SIAC-8412.

Nei report BILR141 (regione) e BILR142 (Enti Locali).
deve essere aggiunta una riga che e' un di cui delle Spese Correnti:
- "di cui spese correnti non ricorrenti finanziate con utilizzo del risultato di amministrazione". 

Il valore di questa riga e' un parametro nell'elenco dei parametri dei report,
ma se tale parametro non e' valorizzato (NULL) deve essere calcolato come:

-sommatoria del valore attuale degli impegni di competenza anno n
	del Titolo 1 (spese correnti)
	Non Ricorrenti
	con Tipo Vincolo: AAM.
    
Questa funzione restituisce solo il valore dell'importo calcolato. 
E' il report che controlla il valore del parametro e, se questo e' NULL,
valorizza il campo con il valore restituita da questa funzione.   

*/


select bil.bil_id
	into bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno=p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;  
    
raise notice 'bilancio_id = %', bilancio_id;

importo_spese := 0;
  


  return query 
  with struttura as (select * 
  		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, p_anno,'')),
  capitoli as (
	select classific.programma_id,
    	classific.macroaggregato_id,
    	cap.elem_id
   	from   siac_t_bil_elem cap
   			LEFT JOIN (select r_capitolo_programma.elem_id, 
            		r_capitolo_programma.classif_id programma_id,
                	r_capitolo_macroaggr.classif_id macroaggregato_id
				from	siac_r_bil_elem_class r_capitolo_programma,
     					siac_r_bil_elem_class r_capitolo_macroaggr, 
                    	siac_d_class_tipo programma_tipo,
     					siac_t_class programma,
     					siac_d_class_tipo macroaggr_tipo,
     					siac_t_class macroaggr
				where   programma.classif_id=r_capitolo_programma.classif_id
    				AND programma.classif_tipo_id=programma_tipo.classif_tipo_id 
                    AND macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 
    				AND macroaggr.classif_id=r_capitolo_macroaggr.classif_id
                    AND r_capitolo_programma.elem_id=r_capitolo_macroaggr.elem_id
    				AND programma.ente_proprietario_id = p_ente_prop_id
                    AND programma_tipo.classif_tipo_code='PROGRAMMA'	
    				AND macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'	
					AND r_capitolo_programma.data_cancellazione IS NULL
    				AND r_capitolo_macroaggr.data_cancellazione IS NULL
    				AND programma_tipo.data_cancellazione IS NULL
                    AND programma.data_cancellazione IS NULL
                    AND macroaggr_tipo.data_cancellazione IS NULL
                    AND macroaggr.data_cancellazione IS NULL
    				AND now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now()) 
    				AND now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now()) 
    				AND	now() between programma.validita_inizio and coalesce (programma.validita_fine, now())
                    AND	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())) classific
            	ON classific.elem_id= cap.elem_id,                    
          siac_d_bil_elem_tipo tipo_elemento, 
          siac_d_bil_elem_stato stato_capitolo,
          siac_r_bil_elem_stato r_capitolo_stato,
          siac_d_bil_elem_categoria cat_del_capitolo,
          siac_r_bil_elem_categoria r_cat_capitolo
     where cap.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
      and	cap.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
      and	cap.elem_id						=	r_cat_capitolo.elem_id
      and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
      and cap.ente_proprietario_id 			=	p_ente_prop_id
      and cap.bil_id						= bilancio_id
      and tipo_elemento.elem_tipo_code 	= 	'CAP-UG'
      and	stato_capitolo.elem_stato_code	=	'VA'
      and cap.data_cancellazione 				is null
      and	r_capitolo_stato.data_cancellazione	is null
      and	tipo_elemento.data_cancellazione	is null
      and	stato_capitolo.data_cancellazione 	is null
      and	cat_del_capitolo.data_cancellazione	is null
      and	now() between cap.validita_inizio and coalesce (cap.validita_fine, now())
      and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
      and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
      and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
      and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
      and	now() between r_cat_capitolo.validita_inizio 
      and coalesce (r_cat_capitolo.validita_fine, now())),
  impegni as (
      select r_imp_bil_elem.elem_id, imp_ts.movgest_ts_id,
      	imp_ts_det.movgest_ts_det_importo
      from siac_t_movgest imp,
          siac_t_movgest_ts imp_ts,
          siac_t_movgest_ts_det imp_ts_det,
          siac_d_movgest_ts_det_tipo imp_ts_det_tipo,
          siac_d_movgest_tipo mov_tipo,
          siac_r_movgest_bil_elem r_imp_bil_elem
      where imp.movgest_tipo_id=mov_tipo.movgest_tipo_id
      and imp.movgest_id=imp_ts.movgest_id            
      and r_imp_bil_elem.movgest_id=imp.movgest_id
      and imp_ts_det.movgest_ts_id=imp_ts.movgest_ts_id
      and imp_ts_det.movgest_ts_det_tipo_id=imp_ts_det_tipo.movgest_ts_det_tipo_id
      and imp.ente_proprietario_id=p_ente_prop_id
      and imp.bil_id=bilancio_id
      and mov_tipo.movgest_tipo_code ='I' --Impegni
      and imp_ts_det_tipo.movgest_ts_det_tipo_code='A' --Importo Attuale.
      and imp.data_cancellazione IS NULL
      and imp_ts.data_cancellazione IS NULL
      and r_imp_bil_elem.data_cancellazione IS NULL),
	class_ricorrente as (
    	select r_mov_class.movgest_ts_id, class.classif_code
        from siac_t_class class,
            siac_d_class_tipo class_tipo,
            siac_r_movgest_class r_mov_class   
        where class.classif_tipo_id=class_tipo.classif_tipo_id
            and class.classif_id=r_mov_class.classif_id           
            and class.ente_proprietario_id= p_ente_prop_id
            and class_tipo.classif_tipo_code='RICORRENTE_SPESA'
            and class.data_cancellazione IS NULL
            and r_mov_class.data_cancellazione IS NULL ),
	imp_vincoli as (
    	select r_mov_ts.movgest_ts_b_id, av.avav_id
		from siac_t_avanzovincolo av,
            siac_d_avanzovincolo_tipo tipo,
            siac_r_movgest_ts r_mov_ts
        where av.avav_tipo_id=tipo.avav_tipo_id
        	and r_mov_ts.avav_id=av.avav_id
            and   tipo.ente_proprietario_id=p_ente_prop_id
            and   tipo.avav_tipo_code='AAM'
            and av.data_cancellazione is null
            --SIAC-8694 13/04/2022.
            --Non si deve testare che la data di fine validita' 
            --del vincolo sia NULL ma che sia compresa nell'anno
            --di bilancio in input.
            --and av.validita_fine IS NULL
			 and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
             	between av.validita_inizio 	
            		and COALESCE(av.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))             
            and r_mov_ts.data_cancellazione is null)                        
  select COALESCE(sum(impegni.movgest_ts_det_importo),0) importo_spese
  from struttura
  	join capitoli 
    	ON(struttura.programma_id = capitoli.programma_id
        	and struttura.macroag_id = capitoli.macroaggregato_id)  
    join impegni
    	on impegni.elem_id=capitoli.elem_id
    left join class_ricorrente
    	on class_ricorrente.movgest_ts_id=impegni.movgest_ts_id
	left join imp_vincoli
    	on imp_vincoli.movgest_ts_b_id=impegni.movgest_ts_id        
   where struttura.titusc_code='1'  --solo Titolo 1 - spese correnti
   		and COALESCE(class_ricorrente.classif_code,'')='4' --Impegno Non ricorrente 
        and imp_vincoli.avav_id IS NOT NULL; --Esiste un vincolo AAM 
       
  raise notice 'fine OK';
  raise notice 'ora: % ',clock_timestamp()::varchar;  
  
  EXCEPTION
  when no_data_found THEN
  raise notice 'Nessun dato trovato per le spese corrente non ricorrenti ';
  return;
  when others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
  
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR141_calcola_spese_correnti_non_ricorrenti" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;

--SIAC-8412 e SIAC-8694 - Maurizio - FINE

--- SIAC-8667 - Sofia - 16.03.2022 - inizio 
DROP FUNCTION if exists siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying,integer,integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(_uid_capitolospesa integer, _anno character varying, _filtro_crp character varying, _limit integer, _page integer)
 RETURNS TABLE
 (
 uid integer, 
 impegno_anno integer, 
 impegno_numero numeric, 
 impegno_desc character varying, 
 impegno_stato character varying, 
 impegno_importo numeric, 
 soggetto_code character varying, 
 soggetto_desc character varying, 
 attoamm_numero integer, 
 attoamm_anno character varying, 
 attoamm_oggetto character varying, 
 attoal_causale character varying, 
 attoamm_tipo_code character varying, 
 attoamm_tipo_desc character varying, 
 attoamm_stato_desc character varying, 
 attoamm_sac_code character varying, 
 attoamm_sac_desc character varying, 
 pdc_code character varying, 
 pdc_desc character varying, 
 impegno_anno_capitolo integer, 
 impegno_nro_capitolo integer, 
 impegno_nro_articolo integer, 
 impegno_flag_prenotazione character varying, 
 impegno_cup character varying, 
 impegno_cig character varying, 
 impegno_tipo_debito character varying, 
 impegno_motivo_assenza_cig character varying, 
 impegno_componente character varying, 
 cap_sac_code character varying, 
 cap_sac_desc character varying, 
 imp_sac_code character varying, 
 imp_sac_desc character varying
 )
AS
$body$

DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	raise notice 'STO LANCIANDO LA FNC GIUSTA ****';
	raise notice '_uid_capitolospesa=%',_uid_capitolospesa::varchar;
    raise notice '_anno=%',_anno;
    raise notice '_filtro_crp=%',_filtro_crp;
	RETURN QUERY 
		with imp_sogg_attoamm as (
			with imp_sogg as (
				select distinct
					soggall.elem_id,
					soggall.uid,
					soggall.movgest_anno,
					soggall.movgest_numero,
					soggall.movgest_desc,
					soggall.movgest_stato_desc,
					soggall.movgest_ts_id,
					soggall.movgest_ts_det_importo,
					case when soggall.zzz_soggetto_code is null then soggall.zzzz_soggetto_code else soggall.zzz_soggetto_code end soggetto_code,
					case when soggall.zzz_soggetto_desc is null then soggall.zzzz_soggetto_desc else soggall.zzz_soggetto_desc end soggetto_desc,
					soggall.pdc_code,
					soggall.pdc_desc,
                    -- 29.06.2018 Sofia jira siac-6193
					soggall.impegno_nro_capitolo,
					soggall.impegno_nro_articolo,
					soggall.impegno_anno_capitolo,
                    soggall.impegno_flag_prenotazione,
                    soggall.impegno_cig,
  					soggall.impegno_cup,
                    soggall.impegno_motivo_assenza_cig,
            		soggall.impegno_tipo_debito,
                    -- 11.05.2020 SIAC-7349 SR210
                    soggall.impegno_componente

				from (
					with za as (
						select
						    zzz.elem_id,
							zzz.uid,
							zzz.movgest_anno,
							zzz.movgest_numero,
							zzz.movgest_desc,
							zzz.movgest_stato_desc,
							zzz.movgest_ts_id,
							zzz.movgest_ts_det_importo,
							zzz.zzz_soggetto_code,
							zzz.zzz_soggetto_desc,
							zzz.pdc_code,
							zzz.pdc_desc,
                            -- 29.06.2018 Sofia jira siac-6193
                            zzz.impegno_nro_capitolo,
                            zzz.impegno_nro_articolo,
                            zzz.impegno_anno_capitolo,
                            zzz.impegno_flag_prenotazione,
                            zzz.impegno_cig,
  							zzz.impegno_cup,
                            zzz.impegno_motivo_assenza_cig,
            				zzz.impegno_tipo_debito,
                            --11/05/2020 SIAC-7349 SR210
                            zzz.impegno_componente
						from (
							with impegno as (


								select
									bilelem.elem_id, 
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo,
									q.classif_code pdc_code,
									q.classif_desc pdc_desc,
                                    -- 29.06.2018 Sofia jira siac-6193
                                    bilelem.elem_code::integer impegno_nro_capitolo,
                                    bilelem.elem_code2::integer impegno_nro_articolo,
                                    t.anno::integer impegno_anno_capitolo,
                                    c.siope_assenza_motivazione_id,
                                    c.siope_tipo_debito_id,
                                    --11.05.2020 Mr SIAC-7349 SR210 tiro fuori l'id per la join con la tabella del tipo componente
                                    b.elem_det_comp_tipo_id
                                    --
								from
									siac_t_bil_elem bilelem,
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_r_movgest_class p,
									siac_t_class q,
									siac_d_class_tipo r,
									siac_t_bil s,
									siac_t_periodo t,
									siac_t_movgest_ts c
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and p.movgest_ts_id = c.movgest_ts_id
								and q.classif_id = p.classif_id
								and r.classif_tipo_id = q.classif_tipo_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and s.bil_id = a.bil_id
								and t.periodo_id = s.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and p.data_cancellazione is null
								and q.data_cancellazione is null
								and r.data_cancellazione is null
								and s.data_cancellazione is null
								and t.data_cancellazione is null
								and bilelem.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
								and b.elem_id=bilelem.elem_id
								and bilelem.elem_id=_uid_capitolospesa
                                and t.anno = _anno
							),
							siope_assenza_motivazione as
                            (
								select
									d.siope_assenza_motivazione_id,
									d.siope_assenza_motivazione_code,
									d.siope_assenza_motivazione_desc
								from siac_d_siope_assenza_motivazione d
								where d.data_cancellazione is null
							),

							siope_tipo_debito as
                            (
								select
									d.siope_tipo_debito_id,
									d.siope_tipo_debito_code,
									d.siope_tipo_debito_desc
								from siac_d_siope_tipo_debito d
								where d.data_cancellazione is null
							),
							soggetto as
                            (
								select
									g.soggetto_code,
									g.soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sog h
								where h.soggetto_id=g.soggetto_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
							),
							impegno_flag_prenotazione as
                            (
								select
									r.movgest_ts_id,
									r.boolean
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'flagPrenotazione'
							),
							impegno_cig as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cig'
							),
							impegno_cup as
                            (
								select
									r.movgest_ts_id,
									r.testo
								from
									siac_r_movgest_ts_attr r,
									siac_t_attr t
								where r.attr_id = t.attr_id
								and now() between r.validita_inizio and coalesce(r.validita_fine, now())
								and r.data_cancellazione is null
								and t.data_cancellazione is null
								and t.attr_code = 'cup'
							),
                            --11.05.2020 SIAC-7349 MR SR210 lista di tutte le componenti
                            componente_desc AS
                            (
                                select * from 
                                siac_d_bil_elem_det_comp_tipo tipo
                                --where tipo.data_cancellazione is NULL --da discuterne. in questo caso prende solo le componenti non cancellate
                            )
							select
							    impegno.elem_id,
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code zzz_soggetto_code,
								soggetto.soggetto_desc zzz_soggetto_desc,
								impegno.pdc_code,
								impegno.pdc_desc,
                                -- 29.06.2018 Sofia jira siac-6193
                                impegno.impegno_nro_capitolo,
                                impegno.impegno_nro_articolo,
                                impegno.impegno_anno_capitolo,
                                siope_assenza_motivazione.siope_assenza_motivazione_desc impegno_motivo_assenza_cig,
                                siope_tipo_debito.siope_tipo_debito_desc impegno_tipo_debito,
                                coalesce(impegno_flag_prenotazione.boolean,'N') impegno_flag_prenotazione,
                                impegno_cig.testo  impegno_cig,
                                impegno_cup.testo  impegno_cup,
                                --11.05.2020 MR SIAC-7349 SR210
                                componente_desc.elem_det_comp_tipo_desc impegno_componente
							from impegno
                              left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
                              left outer join impegno_flag_prenotazione on impegno.movgest_ts_id=impegno_flag_prenotazione.movgest_ts_id
                              left outer join impegno_cig on impegno.movgest_ts_id=impegno_cig.movgest_ts_id
                              left outer join impegno_cup on impegno.movgest_ts_id=impegno_cup.movgest_ts_id
                              left outer join siope_assenza_motivazione on impegno.siope_assenza_motivazione_id=siope_assenza_motivazione.siope_assenza_motivazione_id
                              left outer join siope_tipo_debito on impegno.siope_tipo_debito_id=siope_tipo_debito.siope_tipo_debito_id
                              --11.05.2020 MR SIAC-7349 SR210
                              left outer join componente_desc on impegno.elem_det_comp_tipo_id=componente_desc.elem_det_comp_tipo_id
						) as zzz
					),
					zb as (
						select
							zzzz.elem_id,
							zzzz.uid,
							zzzz.movgest_anno,
							zzzz.movgest_numero,
							zzzz.movgest_desc,
							zzzz.movgest_stato_desc,
							zzzz.movgest_ts_id,
							zzzz.movgest_ts_det_importo,
							zzzz.soggetto_code zzzz_soggetto_code,
							zzzz.soggetto_desc zzzz_soggetto_desc
						from (
							with impegno as (
								select
									b.elem_id, 
								    a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_t_bil l,
									siac_t_periodo m
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and l.bil_id = a.bil_id
								and m.periodo_id = l.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and b.elem_id=_uid_capitolospesa
								and m.anno = _anno
							),
							soggetto as (
                                select
									l.soggetto_classe_code soggetto_code,
									l.soggetto_classe_desc soggetto_desc,
									h.movgest_ts_id
								from
									siac_r_movgest_ts_sogclasse h,
									siac_d_soggetto_classe l
								where
								    h.soggetto_classe_id=l.soggetto_classe_id
                                and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and h.data_cancellazione is null
							)
							select
								impegno.elem_id,
							    impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzzz
					)
					select
						za.*,
						zb.zzzz_soggetto_code,
						zb.zzzz_soggetto_desc
					from za
					left join zb on za.movgest_ts_id=zb.movgest_ts_id
				) soggall
			),

			attoamm as (
				select
					movgest_ts_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
                    --29.06.2018 Sofia jira siac-6193
                    n.attoamm_oggetto,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc,
					--SIAC-8188
					staa.attoal_causale
				from
					siac_r_movgest_ts_atto_amm m,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q,
					siac_t_atto_amm n
				--SIAC-8188 se ci sono corrisponsenze le ritorno
				left join siac_t_atto_allegato staa on n.attoamm_id = staa.attoamm_id 
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			)
			select
				imp_sogg.elem_id,
			    imp_sogg.uid,
				imp_sogg.movgest_anno,
				imp_sogg.movgest_numero,
				imp_sogg.movgest_desc,
				imp_sogg.movgest_stato_desc,
				imp_sogg.movgest_ts_det_importo,
				imp_sogg.soggetto_code,
				imp_sogg.soggetto_desc,
				attoamm.attoamm_id,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
                -- 29.06.2018 Sofia jira siac-6193
                attoamm.attoamm_oggetto,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				--SIAC-8188
				attoamm.attoal_causale,
				imp_sogg.pdc_code,
				imp_sogg.pdc_desc,
                -- 29.06.2018 Sofia jira siac-6193
                imp_sogg.impegno_nro_capitolo,
           		imp_sogg.impegno_nro_articolo,
           		imp_sogg.impegno_anno_capitolo,
                imp_sogg.impegno_flag_prenotazione,
                imp_sogg.impegno_cig,
                imp_sogg.impegno_cup,
                imp_sogg.impegno_motivo_assenza_cig,
                imp_sogg.impegno_tipo_debito,
                --11.05.2020 MR SIAC-7349 SR210
                imp_sogg.impegno_componente

			from imp_sogg

			 left outer join attoamm ON imp_sogg.movgest_ts_id=attoamm.movgest_ts_id
            where (case when coalesce(_filtro_crp,'X')='R' then imp_sogg.movgest_anno<_anno::integer
                     	when coalesce(_filtro_crp,'X')='C' then imp_sogg.movgest_anno=_anno::integer
                        when coalesce(_filtro_crp,'X')='P' then imp_sogg.movgest_anno>_anno::integer
		                else true end ) -- 29.06.2018 Sofia jira siac-6193
		),
		sac_attoamm as (
			select
				y.classif_code,
				y.classif_desc,
				z.attoamm_id
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		),
      --  	SIAC-8351 Haitham 05/11/2021
		sac_capitolo as (
			select
				class_cap.classif_code,
				class_cap.classif_desc,
				r_class_cap.elem_id
			from
				siac_r_bil_elem_class r_class_cap,
				siac_t_class class_cap,
				siac_d_class_tipo tipo_class_cap
			where r_class_cap.classif_id=class_cap.classif_id
			and tipo_class_cap.classif_tipo_id=class_cap.classif_tipo_id
			and now() BETWEEN r_class_cap.validita_inizio and coalesce (r_class_cap.validita_fine,now())
			and tipo_class_cap.classif_tipo_code  IN ('CDC', 'CDR')
			and r_class_cap.data_cancellazione is NULL
			and tipo_class_cap.data_cancellazione is NULL
			and class_cap.data_cancellazione is NULL
		),	
      --  	SIAC-8351 Haitham 05/11/2021
        sac_impegno as (
			select
				class_imp.classif_code,
				class_imp.classif_desc,
				mov.movgest_id 
			from
				siac_r_movgest_class  r_class_imp,
				siac_t_class class_imp,
				siac_d_class_tipo tipo_class_imp,
				siac_t_movgest mov,
				siac_t_movgest_ts ts
			where r_class_imp.classif_id=class_imp.classif_id
			and tipo_class_imp.classif_tipo_id=class_imp.classif_tipo_id
			and now() BETWEEN r_class_imp.validita_inizio and coalesce (r_class_imp.validita_fine,now())
			and tipo_class_imp.classif_tipo_code  IN ('CDC', 'CDR')
			and ts.movgest_ts_id  = r_class_imp.movgest_ts_id 
			and mov.movgest_id = ts.movgest_id 
			and r_class_imp.data_cancellazione is NULL
			and tipo_class_imp.data_cancellazione is NULL
			and class_imp.data_cancellazione is null
			-- 25.02.2022 Sofia Jira SIAC-8648
			and now() BETWEEN ts.validita_inizio and COALESCE(ts.validita_fine,now())
			and ts.data_cancellazione is null
		)
		select
			imp_sogg_attoamm.uid,
			imp_sogg_attoamm.movgest_anno as impegno_anno,
			imp_sogg_attoamm.movgest_numero as impegno_numero,
			imp_sogg_attoamm.movgest_desc as impegno_desc,
			imp_sogg_attoamm.movgest_stato_desc as impegno_stato,
			imp_sogg_attoamm.movgest_ts_det_importo as impegno_importo,
			imp_sogg_attoamm.soggetto_code,
			imp_sogg_attoamm.soggetto_desc,
			imp_sogg_attoamm.attoamm_numero,
			imp_sogg_attoamm.attoamm_anno,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.attoamm_oggetto attoamm_oggetto, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
            imp_sogg_attoamm.attoal_causale attoal_causale, --SIAC-8188 si cambia il nome del campo da attoamm_desc a attoamm_oggetto per mantenere una struttura univoca
			imp_sogg_attoamm.attoamm_tipo_code,
			imp_sogg_attoamm.attoamm_tipo_desc,
			imp_sogg_attoamm.attoamm_stato_desc,
			sac_attoamm.classif_code as attoamm_sac_code,
			sac_attoamm.classif_desc as attoamm_sac_desc,
			imp_sogg_attoamm.pdc_code,
			imp_sogg_attoamm.pdc_desc,
            -- 29.06.2018 Sofia jira siac-6193
            imp_sogg_attoamm.impegno_anno_capitolo,
            imp_sogg_attoamm.impegno_nro_capitolo,
            imp_sogg_attoamm.impegno_nro_articolo,
            imp_sogg_attoamm.impegno_flag_prenotazione::varchar,
			imp_sogg_attoamm.impegno_cup,
            imp_sogg_attoamm.impegno_cig,
            imp_sogg_attoamm.impegno_tipo_debito,
            imp_sogg_attoamm.impegno_motivo_assenza_cig,
            --11.05.2020 SIAC-7349 MR SR210
            imp_sogg_attoamm.impegno_componente,
   			sac_capitolo.classif_code as cap_sac_code,       --  	SIAC-8351 Haitham 05/11/2021
			sac_capitolo.classif_desc as cap_sac_desc,        --  	SIAC-8351 Haitham 05/11/2021
   			sac_impegno.classif_code as imp_sac_code,       --  	SIAC-8351 Haitham 05/11/2021
			sac_impegno.classif_desc as imp_sac_desc        --  	SIAC-8351 Haitham 05/11/2021
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		left outer join sac_capitolo on imp_sogg_attoamm.elem_id=sac_capitolo.elem_id
		left outer join sac_impegno on imp_sogg_attoamm.uid=sac_impegno.movgest_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero


		LIMIT _limit
		OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa(integer, character varying, character varying, integer, integer)
    OWNER TO siac;

--- SIAC-8667 - Sofia - 16.03.2022 - fine  

--SIAC-8670, SIAC-8676, SIAC-8682 e SIAC-8690 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend_new"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR147_dettaglio_colonne_nuovo"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend_new" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric
) AS
$body$
DECLARE

classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
bilancio_id integer;
bilancio_id_anno1 integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;
var_fondo_plur_anno_prec_a:=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;  
spese_da_impeg_anni_succ_f=0;

--Leggo l'id dell'anno bilancio
select bil.bil_id
into bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;    

--Leggo l'id dell'anno bilancio +1
select bil.bil_id
into bilancio_id_anno1
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = annoCapImp1
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;   
            
/*
	11/11/2021 SIAC-8250.
Funzione riscritta per rendere le query piu' leggibili.
In seguito sono state applicate le nuove regole per i vari campi indicate 
nella Jira.

Colonna A: NON MODIFICATA.
	Stanziamento Capitoli di Spesa FPV in Spesa (Anno Bilancio -1).
	Se per un codice PROGRAMMA non esiste un valore allora si prende il valore
    eventualmente caricato sulle variabili.

Colonna B: NON MODIFICATA. 
	Somma Importo VINCOLO Impegni definitivi (D, N) con anno bilancio 
	corrente e anno impegno = anno bilancio con Vincolo FPVCC+ FPVSC.
    
Colonna X: MODIFICATA
	Somma importo Modifiche non annullate su Impegni definitivi (D, N) 
	con anno bilancio corrente e anno impegno = anno bilancio 
    con Vincolo FPVCC o FPVSC
	Modifiche tipo: tutti  tranne ROR reimputazione, REANNO, AGG, RidCoi   
     
Colonna Y: MODIFICATA
	Somma importo Modifiche non annullate su Impegni definitivi (D, N) 
	con anno bilancio corrente e  anno impegno > anno bilancio 
    con Vincolo FPVCC o FPVSC
	Modifiche tipo: tutti  tranne ROR reimputazione, REANNO, AGG, RidCoi.
 
Colonna D: MODIFICATA
    Importo VINCOLO degli impegni con:
    Anno Bilancio corrente, Anno competenza dell’impegno = anno bilancio + 1
    con vincolo verso Accertamento competenza anno bilancio oppure con vinciolo AMM 
    +
    Impegni non nati da aggiudicazione e
    Anno di bilancio= anno corrente +1 e
    Anno di impegno = anno corrente +1 e
    Anno Riaccertamento = anno corrente (SIA DA ROR CHE REANNO).

    Il valore da considerare e' l'importo iniziale dell’impegno 
    con Impegno origine esercizio anno bilancio SENZA VINCOLO O CON VINCOLO VERSO 
    ACCERTAMENTO /AMM 
    (COMPET. anno bilancio -cioe' verso anno accertamento anno bilancio) 
    QUINDI NON SONO DA PRENDERE GLI IMPEGNI REIMPUTATI IL CUI IMPEGNO ORIGINE 
    ERA VINCOLATO A FPVCC/FPVSC  E NON SONO DA CONSIDERARE GLI IMPEGNI CHE 
    NASCONO NEL anno bilancio+1 A SEGUITO DI RIDUZIONE PER AGGIUDICAZIONE  
       
Colonna E: MODIFICATA
	Come colonna D ma gli anni sono anno bilancio +2
    
Colonna F: MODIFICATA
	Come colonna D ma gli anni sono > anno bilancio +2    

Colonna G: NON MODIFICATA
	La formula non e' cambiata (colonna_G =colonna_C+colonna_D+colonna_E+colonna_F)
    ma e' cambiato il modo di calcolare gli addendi.
    
*/        

/*
	Attenzione!
    Se si modifica questa funzione occorre modificare anche la funzione
    BILR147_dettaglio_colonne_nuovo che estrae il dettaglio delle colonne
    B, D, E, X, Y.

*/

return query           
with struttura as (
  select v1.missione_tipo_desc			missione_tipo_desc,
          v1.missione_code				missione_code,
          v1.missione_desc				missione_desc,
          v1.programma_tipo_desc		programma_tipo_desc,
          v1.programma_code				programma_code,
          v1.programma_desc				programma_desc,
          v1.programma_id					programma_id,
          v1.ente_proprietario_id
  from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, 
                                                      p_anno, '') v1
		/* 03/08/2021: il seguente controllo era stato inserito nella
           versione originale della procedura.
           Viene lasciato anche se non sono sicuro sia corretto */
        /* ANNA 31-05 inizio */
  where  v1.missione_code::integer <= 19
 		/* ANNA 31-05 fine */  
  group by v1.missione_tipo_desc, v1.missione_code, v1.missione_desc, 
            	v1.programma_tipo_desc, v1.programma_code, v1.programma_desc,
                v1.programma_id,
                v1.ente_proprietario_id 
            order by missione_code,programma_code  ),                      
fpv_anno_prec_da_variabili as (
select  
  importi.repimp_desc programma_code,
 sum(coalesce(importi.repimp_importo,0)) spese_fpv_anni_prec     
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,		
        siac_t_periodo 					anno_comp
where 	r_report_importi.rep_id			=	report.rep_id
        and r_report_importi.repimp_id		=	importi.repimp_id	
        and importi.periodo_id 				=	anno_comp.periodo_id              	
        and report.ente_proprietario_id		=	p_ente_prop_id
		and importi.bil_id					=	bilancio_id 			
      	and report.rep_codice				=	'BILR147'   				
      	and report.data_cancellazione IS NULL
        and importi.data_cancellazione IS NULL
        and r_report_importi.data_cancellazione IS NULL
        and anno_comp.data_cancellazione IS NULL
        group by importi.repimp_desc),
/*
	22/02/2019: SIAC-6623.
    	E' stato richiesto di estrarre gli importi FPV dell'anno precedente dai capitoli.
        Se per un codice PROGRAMMA non esiste un valore allora si prende il valore
        eventualmente caricato sulle variabili (fpv_anno_prec_da_variabili). 
*/        
 fpv_anno_prec_da_capitoli as (               
select 	 t_class.classif_code programma_code,
	sum(capitolo_importi.elem_det_importo) importo_fpv_anno_prec
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = 'CAP-UG' -- prendere i capitoli di GESTIONE
	and	t_periodo_bil.anno = annoPrec	--anno bilancio -1	
	and	capitolo_imp_periodo.anno = annoPrec	--anno bilancio -1		  	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
GROUP BY t_class.classif_code ),
tbimpaprec as (
select 
--sum(coalesce(f.movgest_ts_det_importo,0)) spese_impe_anni_prec
--Spese impegnate negli esercizi precedenti e imputate all'esercizio N e coperte dal fondo pluriennale vincolato
-- si prendono le quote di impegni di competenza   
-- gli impegni considerati devono inoltre essere vincolati a fondo
-- l'importo considerato e' quello attuale
sum(coalesce(r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec,
 class.classif_code programma_code
          from siac_t_movgest mov,              
            siac_t_movgest_ts mov_ts, 
            siac_t_movgest_ts_det mov_ts_det,
            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
            siac_t_bil_elem bil_elem, 
            siac_r_movgest_bil_elem r_mov_bil_elem,
            siac_r_movgest_ts_stato r_mov_ts_stato, 
            siac_d_movgest_stato d_mov_stato,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class class, 
            siac_d_class_tipo d_class_tipo, 
            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
            siac_t_atto_amm atto,
            siac_d_movgest_tipo d_mov_tipo,
            siac_r_movgest_ts r_movgest_ts, 
            siac_t_avanzovincolo av_vincolo, 
            siac_d_avanzovincolo_tipo av_vincolo_tipo
          where mov.movgest_id = mov_ts.movgest_id  
          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = class.classif_id
          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
          and bil_elem.elem_id=r_mov_bil_elem.elem_id
          and r_mov_bil_elem.movgest_id=mov.movgest_id 
          and r_movgest_ts.avav_id=av_vincolo.avav_id     
          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id            
          and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and mov.ente_proprietario_id= p_ente_prop_id    
          and mov.bil_id = bilancio_id            
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and mov.movgest_anno = annoBilInt 
          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_mov_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and av_vincolo_tipo.avav_tipo_code like'FPV%'
          and mov_ts.movgest_ts_id_padre is NULL  
          and r_mov_bil_elem.data_cancellazione is null
          and r_mov_bil_elem.validita_fine is NULL          
          and r_mov_ts_stato.data_cancellazione is null
          and r_mov_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and r_mov_ts_atto.data_cancellazione is null
          and r_mov_ts_atto.validita_fine is null          
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null            
          	--21/05/2020 SIAC-7643 
            --aggiunti i test sulle date che mancavano
          and mov.data_cancellazione is null
          and mov.validita_fine is NULL
          and mov_ts.data_cancellazione is null
          and mov_ts.validita_fine is NULL   
          and mov_ts_det.data_cancellazione is null
          and mov_ts_det.validita_fine is NULL   
          and d_mov_ts_det_tipo.data_cancellazione is null
          and d_mov_ts_det_tipo.validita_fine is NULL   
          and bil_elem.data_cancellazione is null
          and bil_elem.validita_fine is NULL   
          and d_mov_stato.data_cancellazione is null
          and d_mov_stato.validita_fine is NULL   
          and class.data_cancellazione is null
          and class.validita_fine is NULL   
          and d_class_tipo.data_cancellazione is null
          and d_class_tipo.validita_fine is NULL   
          and atto.data_cancellazione is null
          and atto.validita_fine is NULL   
          and av_vincolo.data_cancellazione is null
          --and av_vincolo.validita_fine is NULL 
          and av_vincolo_tipo.data_cancellazione is null
          and av_vincolo_tipo.validita_fine is NULL              
          group by class.classif_code
          ),
tbriaccx as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                                 
  select --sum(COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x,
  	(sum((COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_x,
   class.classif_code programma_code
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         mov_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */
      		left join (select r_mod_vinc.mod_id,
                    sum(r_mod_vinc.importo_delta) importo_delta 
              from siac_r_movgest_ts r_mov_ts,
                  siac_r_modifica_vincolo r_mod_vinc
              where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                and r_mov_ts.data_cancellazione IS NULL
                and r_mod_vinc.data_cancellazione IS NULL
              group by r_mod_vinc.mod_id) vincoli_acc
            on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      	siac_t_movgest_ts_det_mod mov_ts_det_mod,
      	siac_t_movgest_ts mov_ts, 
      	siac_d_modifica_stato d_mod_stato,
        siac_t_movgest mov, 
        siac_d_movgest_tipo d_mov_tipo,       
        siac_t_modifica modif, 
        siac_d_modifica_tipo d_modif_tipo,
        siac_d_modifica_stato d_modif_stato, 
        siac_t_bil_elem t_bil_elem, 
        siac_r_movgest_bil_elem r_mov_bil_elem,
        siac_r_bil_elem_class r_bil_elem_class, 
        siac_t_class class, 
        siac_d_class_tipo d_class_tipo,
        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
        siac_t_atto_amm atto_amm ,
        siac_r_movgest_ts_stato r_mov_ts_stato, 
        siac_d_movgest_stato d_mov_stato    
      where mov_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and mov_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_modif_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_movgest_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_movgest_ts_atto_amm.attoamm_id = atto_amm.attoamm_id
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mov_ts_stato.movgest_ts_id = mov_ts_det_mod.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id        
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno = anno del bilancio
        and mov.movgest_anno = annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I' 
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione 
      /*  and 
        ( d_modif_tipo.mod_tipo_code like  'ECON%'
           or d_modif_tipo.mod_tipo_desc like  'ROR%'
        )      
        and d_modif_tipo.mod_tipo_code <> 'REIMP' */          
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM') 
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and mov_ts_det_mod.data_cancellazione is null
        and mov_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_modif_tipo.data_cancellazione is null
        and d_modif_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_movgest_ts_atto_amm.data_cancellazione is null
        and r_movgest_ts_atto_amm.validita_fine is null
        and d_mov_stato.data_cancellazione is null
        and d_mov_stato.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                      siac_t_avanzovincolo av_vincolo, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id                                 
                  and mov_ts_det_mod.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%' 
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null 
                 )
      group by class.classif_code
      ),
tbriaccy as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
( select --sum(COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y,
	(sum((COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_y,
	class.classif_code programma_code
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         movgest_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */      
      	left join (select r_mod_vinc.mod_id,
                    sum(r_mod_vinc.importo_delta) importo_delta 
              from siac_r_movgest_ts r_mov_ts,
                  siac_r_modifica_vincolo r_mod_vinc
              where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                and r_mov_ts.data_cancellazione IS NULL
                and r_mod_vinc.data_cancellazione IS NULL
              group by r_mod_vinc.mod_id) vincoli_acc
        on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      siac_t_movgest_ts_det_mod movgest_ts_det_mod,
      siac_t_movgest_ts mov_ts, 
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest mov, 
      siac_d_movgest_tipo d_mov_tipo, 
      siac_t_modifica modif, 
      siac_d_modifica_tipo d_mod_tipo,
      siac_d_modifica_stato d_modif_stato, 
      siac_t_bil_elem t_bil_elem, 
      siac_r_movgest_bil_elem r_mov_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class class, 
      siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_mov_ts_atto_amm, 
      siac_t_atto_amm atto_amm ,
      siac_r_movgest_ts_stato r_mov_ts_stato, 
      siac_d_movgest_stato d_mov_stato    
      where movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and movgest_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_mod_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_mov_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_mov_ts_atto_amm.attoamm_id = atto_amm.attoamm_id        
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno > anno del bilancio
        and mov.movgest_anno > annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I'
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione         
  /*      and 
        ( d_mod_tipo.mod_tipo_code like  'ECON%'
           or d_mod_tipo.mod_tipo_desc like  'ROR%'
        )
        and d_mod_tipo.mod_tipo_code <> 'REIMP' */
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM')         
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and r_mov_ts_stato.movgest_ts_id = mov_ts.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and movgest_ts_det_mod.data_cancellazione is null
        and movgest_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_mod_tipo.data_cancellazione is null
        and d_mod_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_mov_ts_atto_amm.data_cancellazione is null
        and r_mov_ts_atto_amm.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                  siac_t_avanzovincolo av_vincolo, 
                  siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                  and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%'                                      
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null )
      group by class.classif_code
      ),
imp_colonna_d as 
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
      
      -- SIAC-8682 - 07/04/2022.
      --E' necessario NON estrarre gli impegni con anno successivo all'anno 
      --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
      --anno = all'anno dell'impegno.     
      (
      select sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d, 
      x.programma_code as programma_code from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 1
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_d, 
                          class.classif_code as programma_code
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 1
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id 
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                   
              select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_d, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 1
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                              --non esiste su siac_r_movgest_ts 
                              --SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)                                                            
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id = NULL
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo 
                                --SIAC-8682 - 07/04/2022.
                                --il legame e' con l'impegno e non quello origine del riaccertamento.
                                --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id                                  
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure esiste con un vincolo con accertamento anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id                                        
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL)))
                                   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +1).
                                AND  not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +1
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)
				--SIAC-8690 12/04/2022
                --devo escludere gli impegni riaccertati il cui impegno origine
                --l'anno precedente era vincolato verso FPV. 
                --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null  
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null                                    
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                           
                   )) AND
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                      (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code)    
              ) as x
                group by x.programma_code 
            ),
imp_colonna_e as (      
    select sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e , 
           x.programma_code as programma_code from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio
              select sum(COALESCE(r_movgest_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno2_e, 
                     		 class.classif_code as programma_code
                        from siac_t_movgest mov,  
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id 
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id                        
                        and mov.ente_proprietario_id=p_ente_prop_id
                        and mov.bil_id = bilancio_id
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 2
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and acc.movgest_anno = annoBilInt
                        and dstacc.movgest_stato_code in ('D', 'N')
                        --and atto.attoamm_anno = p_anno   
                        and mov.data_cancellazione is null
                        and mov_ts.data_cancellazione is null
                        and mov_ts.movgest_ts_id_padre is NULL                            
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and d_mov_stato.validita_fine is null
                        and d_mov_stato.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code )
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                      		spese_da_impeg_anno2_e, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato,
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id                          
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id     
                          and mov.bil_id = bilancio_id  
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null  
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                                                  
                     group by class.classif_code
              )  
               union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id   
        
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                   
				select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno2_e, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                        	  --SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
									--non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL                                     
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo
								--SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id                                                                                                      
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
									--SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id                                                                                                                    
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
								   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)                                                                               
				  --SIAC-8690 12/04/2022
                  --devo escludere gli impegni riaccertati il cui impegno origine
                  --l'anno precedente era vincolato verso FPV. 
                  --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null  
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
									  --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null                                        
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                        
                       ))
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                   AND   (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code                 
              ) 
              ) as x
                group by x.programma_code 
                ),
imp_colonna_f as (
      select sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f , x.programma_code as programma_code from (
               (
 				 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio               
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      		as spese_da_impeg_anni_succ_f, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,  
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_movgest_ts acc_ts,
                          siac_t_movgest acc,
                          siac_r_movgest_ts_stato r_acc_ts_stato,
                          siac_d_movgest_stato d_acc_stato
                        where mov.movgest_id = mov_ts.movgest_id  
                            and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                            and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                            and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                            and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                            and r_bil_elem_class.classif_id = class.classif_id
                            and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                            and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                            and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                            and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                            and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id
                            and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                            and acc_ts.movgest_id = acc.movgest_id
                            and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                            and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id
                            and r_mov_bil_elem.movgest_id=mov.movgest_id 
                            and mov.ente_proprietario_id= p_ente_prop_id 
                            and mov.bil_id = bilancio_id     
                            and d_class_tipo.classif_tipo_code='PROGRAMMA'
                            and mov.movgest_anno > annoBilInt + 2
                            and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and d_mov_stato.movgest_stato_code in ('D', 'N')
                            and d_mov_tipo.movgest_tipo_code='I' 
                            and acc.movgest_anno = annoBilInt
                            and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                            --and atto.attoamm_anno = p_anno   
                            and mov_ts.movgest_ts_id_padre is NULL  
                            and mov_ts.data_cancellazione is null
                            and mov_ts.validita_fine is NULL                           
                            and r_mov_bil_elem.data_cancellazione is null
                            and r_mov_bil_elem.validita_fine is NULL          
                            and r_mov_ts_stato.data_cancellazione is null
                            and r_mov_ts_stato.validita_fine is null
                            and mov_ts_det.data_cancellazione is null
                            and mov_ts_det.validita_fine is null
                            and d_mov_tipo.data_cancellazione is null
                            and d_mov_tipo.validita_fine is null              
                            and r_bil_elem_class.data_cancellazione is null
                            and r_bil_elem_class.validita_fine is null
                            and r_mov_ts_atto.data_cancellazione is null
                            and r_mov_ts_atto.validita_fine is null                         
                            and r_mov_ts.data_cancellazione is null
                            and r_mov_ts.validita_fine is null                         
                            and acc_ts.movgest_ts_id_padre is null                        
                            and acc.validita_fine is null
                            and acc.data_cancellazione is null
                            and acc_ts.validita_fine is null
                            and acc_ts.data_cancellazione is null                                                
                            and r_acc_ts_stato.validita_fine is null
                            and r_acc_ts_stato.data_cancellazione is null                                                
                                --21/05/2020 SIAC-7643 
                                --aggiunti i test sulle date che mancavano                        
                            and mov.validita_fine is null
                            and mov.data_cancellazione is null
                            and d_mov_ts_det_tipo.validita_fine is null
                            and d_mov_ts_det_tipo.data_cancellazione is null
                            and t_bil_elem.validita_fine is null
                            and t_bil_elem.data_cancellazione is null
                            and d_mov_stato.validita_fine is null
                            and d_mov_stato.data_cancellazione is null
                            and class.validita_fine is null
                            and class.data_cancellazione is null
                            and d_class_tipo.validita_fine is null
                            and d_class_tipo.data_cancellazione is null 
                            and atto.validita_fine is null
                            and atto.data_cancellazione is null                                                                                                                                                   
                           group by class.classif_code)
              union(
              	 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anni_succ_f, 
                          class.classif_code as programma_code
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
						  siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 	
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id  
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id    
                          and mov.bil_id = bilancio_id   
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno > annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM' 
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL    
                          and mov_ts.data_cancellazione is null
                          and mov_ts.validita_fine is NULL   
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null   
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                       
                  group by class.classif_code
              )
              union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno > anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  

    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.   
                    
             select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anni_succ_f, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno > annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null  
                  	--impegni che arrivano da reimputazione       
                  and ((mov_ts.movgest_ts_id in  (
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL 
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure l'impegno riaccertato ha un vincolo 
                               --di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo  
                                  --SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id 
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
								   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con anno > dell'anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno > annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)                                              
				  --SIAC-8690 12/04/2022
                  --devo escludere gli impegni riaccertati il cui impegno origine
                  --l'anno precedente era vincolato verso FPV. 
                  --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null  
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                        
                      )) --fine impegni che arrivano da reimputazione 
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                   AND   (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code
              )   
              ) as x
                group by x.programma_code 
                )                               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
struttura.missione_tipo_desc ,
struttura.missione_code ,
struttura.missione_desc ,
''::varchar programma_tipo_code ,
struttura.programma_tipo_desc ,
struttura.programma_code ,
struttura.programma_desc ,
	--22/02/2019: SIAC-6623. 
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0) as fondo_plur_anno_prec_a,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)) fondo_plur_anno_prec_a,
--coalesce(var_spese_impe_anni_prec_b,0) as spese_impe_anni_prec_b,
coalesce(tbimpaprec.spese_impe_anni_prec,0) as spese_impe_anni_prec_b,
	--22/02/2019: SIAC-6623. 
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) spese_da_impeg_anno1_d,
coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0) spese_da_impeg_anno2_e,
coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0) spese_da_impeg_anni_succ_f,
coalesce(tbriaccx.riacc_colonna_x,0) riacc_colonna_x,
coalesce(tbriaccy.riacc_colonna_y,0) riacc_colonna_y,
	--22/02/2019: SIAC-6623.
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
--coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) + coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0)+coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0)
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) + 
coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0)+
coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0)
as fondo_plur_anno_g 
from struttura left join tbimpaprec     
	on struttura.programma_code=tbimpaprec.programma_code
left join fpv_anno_prec_da_variabili 
	on struttura.programma_code=fpv_anno_prec_da_variabili.programma_code
left join tbriaccx     
	on struttura.programma_code=tbriaccx.programma_code
left join tbriaccy   
	on struttura.programma_code=tbriaccy.programma_code
left join imp_colonna_d   
	on struttura.programma_code=imp_colonna_d.programma_code
left join imp_colonna_e   
	on struttura.programma_code=imp_colonna_e.programma_code
left join imp_colonna_f   
	on struttura.programma_code=imp_colonna_f.programma_code
    	--22/02/2019: SIAC-6623.
left join fpv_anno_prec_da_capitoli
	on struttura.programma_code=fpv_anno_prec_da_capitoli.programma_code;
          

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='struttura bilancio altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend_new" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;
  
  
  CREATE OR REPLACE FUNCTION siac."BILR147_dettaglio_colonne_nuovo" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  colonna varchar,
  missione_programma varchar,
  capitolo varchar,
  anno_impegno integer,
  numero_impegno numeric,
  numero_modifica varchar,
  motivo_modifica_code varchar,
  motivo_modifica_desc varchar,
  importo numeric
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
bilancio_id integer;
bilancio_id_anno1 integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

annoBilInt=p_anno::INTEGER;


missione_programma:='';
colonna:='';
capitolo:='';
anno_impegno:=0;
numero_impegno:=0;
numero_modifica:='';
motivo_modifica_code:='';
motivo_modifica_desc:='';
importo=0;

--Leggo l'id dell'anno bilancio
select bil.bil_id
into bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;    

--Leggo l'id dell'anno bilancio +1
select bil.bil_id
into bilancio_id_anno1
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = annoCapImp1
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;   
            
raise notice 'Id bilancio anno % = % - Id bilancio anno % = %',
	p_anno, bilancio_id, annoCapImp1, bilancio_id_anno1;
        
/*
	15/02/2022. 
Questa funzione serve per estrarre il dettaglio degli impegni che popolano
le colonne del report BILR147.
Serve per soddisfare le richieste di dettaglio che arrivano dal CSI.
Per ora le colonne estratte sono: B, D, E, X e Y.

Le query eseguite sono quelle del report BILR147 nuovo, attualmente presente 
nel menu' 7.
    
*/        

return query 
--Dati della Colonna B.
select 'colonna_B'::VARCHAR, class.classif_code missione_programma,
  bil_elem.elem_code capitolo, mov.movgest_anno anno_impegno, 
  mov.movgest_numero numero_impegno, 
  ''::varchar numero_modifica,
  ''::varchar motivo_modif_code,
  ''::varchar motivo_modif_desc,
	sum(coalesce( r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec
          from siac_t_movgest mov,              
            siac_t_movgest_ts mov_ts, 
            siac_t_movgest_ts_det mov_ts_det,
            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
            siac_t_bil_elem bil_elem, 
            siac_r_movgest_bil_elem r_mov_bil_elem,
            siac_r_movgest_ts_stato r_mov_ts_stato, 
            siac_d_movgest_stato d_mov_stato,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class class, 
            siac_d_class_tipo d_class_tipo, 
            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
            siac_t_atto_amm atto,
            siac_d_movgest_tipo d_mov_tipo,
            siac_r_movgest_ts r_movgest_ts, 
            siac_t_avanzovincolo av_vincolo, 
            siac_d_avanzovincolo_tipo av_vincolo_tipo
          where mov.movgest_id = mov_ts.movgest_id  
          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = class.classif_id
          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
          and bil_elem.elem_id=r_mov_bil_elem.elem_id
          and r_mov_bil_elem.movgest_id=mov.movgest_id 
          and r_movgest_ts.avav_id=av_vincolo.avav_id     
          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id            
          and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and mov.ente_proprietario_id= p_ente_prop_id    
          and mov.bil_id = bilancio_id            
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and mov.movgest_anno = annoBilInt 
          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_mov_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and av_vincolo_tipo.avav_tipo_code like'FPV%'
          and mov_ts.movgest_ts_id_padre is NULL  
          and r_mov_bil_elem.data_cancellazione is null
          and r_mov_bil_elem.validita_fine is NULL          
          and r_mov_ts_stato.data_cancellazione is null
          and r_mov_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and r_mov_ts_atto.data_cancellazione is null
          and r_mov_ts_atto.validita_fine is null          
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null            
          and mov.data_cancellazione is null
          and mov.validita_fine is NULL
          and mov_ts.data_cancellazione is null
          and mov_ts.validita_fine is NULL   
          and mov_ts_det.data_cancellazione is null
          and mov_ts_det.validita_fine is NULL   
          and d_mov_ts_det_tipo.data_cancellazione is null
          and d_mov_ts_det_tipo.validita_fine is NULL   
          and bil_elem.data_cancellazione is null
          and bil_elem.validita_fine is NULL   
          and d_mov_stato.data_cancellazione is null
          and d_mov_stato.validita_fine is NULL   
          and class.data_cancellazione is null
          and class.validita_fine is NULL   
          and d_class_tipo.data_cancellazione is null
          and d_class_tipo.validita_fine is NULL   
          and atto.data_cancellazione is null
          and atto.validita_fine is NULL   
          and av_vincolo.data_cancellazione is null
          and av_vincolo_tipo.data_cancellazione is null
          and av_vincolo_tipo.validita_fine is NULL              
        group by class.classif_code ,bil_elem.elem_code , 
        	mov.movgest_anno , mov.movgest_numero,
            numero_modifica,
            motivo_modif_code, motivo_modif_desc
union
--Colonna X		
select 'colonna_X'::varchar,  class.classif_code programma_code, 
		t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
        modif.mod_num::varchar numero_modifica,
        d_modif_tipo.mod_tipo_code || ' - '|| d_modif_tipo.mod_tipo_desc motivo_modif_code,
        modif.mod_desc motivo_modif_desc, 
	--sum(COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x
        (sum((COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_x
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         mov_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */      
      	left join (select r_mod_vinc.mod_id,
                    sum(r_mod_vinc.importo_delta) importo_delta 
              from siac_r_movgest_ts r_mov_ts,
                  siac_r_modifica_vincolo r_mod_vinc
              where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                and r_mov_ts.data_cancellazione IS NULL
                and r_mod_vinc.data_cancellazione IS NULL
              group by r_mod_vinc.mod_id) vincoli_acc
            on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      	siac_t_movgest_ts_det_mod mov_ts_det_mod,
      	siac_t_movgest_ts mov_ts, 
      	siac_d_modifica_stato d_mod_stato,
        siac_t_movgest mov, 
        siac_d_movgest_tipo d_mov_tipo,       
        siac_t_modifica modif, 
        siac_d_modifica_tipo d_modif_tipo,
        siac_d_modifica_stato d_modif_stato, 
        siac_t_bil_elem t_bil_elem, 
        siac_r_movgest_bil_elem r_mov_bil_elem,
        siac_r_bil_elem_class r_bil_elem_class, 
        siac_t_class class, 
        siac_d_class_tipo d_class_tipo,
        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
        siac_t_atto_amm atto_amm ,
        siac_r_movgest_ts_stato r_mov_ts_stato, 
        siac_d_movgest_stato d_mov_stato    
      where mov_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and mov_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_modif_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_movgest_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_movgest_ts_atto_amm.attoamm_id = atto_amm.attoamm_id
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mov_ts_stato.movgest_ts_id = mov_ts_det_mod.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id        
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno = anno del bilancio
        and mov.movgest_anno = annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I' 
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione 
      /*  and 
        ( d_modif_tipo.mod_tipo_code like  'ECON%'
           or d_modif_tipo.mod_tipo_desc like  'ROR%'
        )      
        and d_modif_tipo.mod_tipo_code <> 'REIMP' */                  
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM') 
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and mov_ts_det_mod.data_cancellazione is null
        and mov_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_modif_tipo.data_cancellazione is null
        and d_modif_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_movgest_ts_atto_amm.data_cancellazione is null
        and r_movgest_ts_atto_amm.validita_fine is null
        and d_mov_stato.data_cancellazione is null
        and d_mov_stato.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                      siac_t_avanzovincolo av_vincolo, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id                                 
                  and mov_ts_det_mod.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%' 
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null 
                 )        
      group by class.classif_code ,t_bil_elem.elem_code , 
      mov.movgest_anno , mov.movgest_numero,
      modif.mod_num,
      motivo_modif_code,
      motivo_modif_desc
union    
--colonna Y
select 'colonna_Y'::varchar, class.classif_code programma_code, 
	t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
    modif.mod_num::varchar numero_modifica,
    d_mod_tipo.mod_tipo_code || ' - '|| d_mod_tipo.mod_tipo_desc motivo_modif_code,
    modif.mod_desc motivo_modif_desc, 
	--sum(COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y
    (sum((COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_y  
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         movgest_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */      
      	left join (select r_mod_vinc.mod_id,
            				sum(r_mod_vinc.importo_delta) importo_delta 
                      from siac_r_movgest_ts r_mov_ts,
                          siac_r_modifica_vincolo r_mod_vinc
                      where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                        and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                        and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                        and r_mov_ts.data_cancellazione IS NULL
                        and r_mod_vinc.data_cancellazione IS NULL
                      group by r_mod_vinc.mod_id) vincoli_acc
            on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      siac_t_movgest_ts_det_mod movgest_ts_det_mod,
      siac_t_movgest_ts mov_ts, 
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest mov, 
      siac_d_movgest_tipo d_mov_tipo, 
      siac_t_modifica modif, 
      siac_d_modifica_tipo d_mod_tipo,
      siac_d_modifica_stato d_modif_stato, 
      siac_t_bil_elem t_bil_elem, 
      siac_r_movgest_bil_elem r_mov_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class class, 
      siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_mov_ts_atto_amm, 
      siac_t_atto_amm atto_amm ,
      siac_r_movgest_ts_stato r_mov_ts_stato, 
      siac_d_movgest_stato d_mov_stato    
      where movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and movgest_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_mod_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_mov_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_mov_ts_atto_amm.attoamm_id = atto_amm.attoamm_id        
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno > anno del bilancio
        and mov.movgest_anno > annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I'
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione         
  /*      and 
        ( d_mod_tipo.mod_tipo_code like  'ECON%'
           or d_mod_tipo.mod_tipo_desc like  'ROR%'
        )
        and d_mod_tipo.mod_tipo_code <> 'REIMP' */
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM')       
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and r_mov_ts_stato.movgest_ts_id = mov_ts.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and movgest_ts_det_mod.data_cancellazione is null
        and movgest_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_mod_tipo.data_cancellazione is null
        and d_mod_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_mov_ts_atto_amm.data_cancellazione is null
        and r_mov_ts_atto_amm.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                  siac_t_avanzovincolo av_vincolo, 
                  siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                  and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%'                                      
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null )
      group by class.classif_code ,t_bil_elem.elem_code , 
      	mov.movgest_anno , mov.movgest_numero,
        modif.mod_num,
        motivo_modif_code,
        motivo_modif_desc        
union
--colonna D		
select 'colonna_D'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno, 
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
  		''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,        
		sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 1
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code ,t_bil_elem.elem_code , 
                           mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              	mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_d
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 1
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = '2021'   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code ,t_bil_elem.elem_code , 
                      	mov.movgest_anno , mov.movgest_numero
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_d
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 1
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                    		--16/03/2022: corretto id del bilancio.
                        --and reimp.bil_id=147  --anno bilancio 
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                              --SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)                              
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id = NULL
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                  --SIAC-8682 - 07/04/2022.
                                  --il legame e' con l'impegno e non quello origine del riaccertamento.
                                --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure esiste con un vincolo con accertamento anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL)))
								   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +1).
                              AND  not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +1
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)
				--SIAC-8690 12/04/2022
                --devo escludere gli impegni riaccertati il cui impegno origine
                --l'anno precedente era vincolato verso FPV. 
                --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null                                      
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                          
                             )) AND
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                      (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code ,t_bil_elem.elem_code , 
              mov.movgest_anno , mov.movgest_numero)    
              ) as x
     group by x.programma_code ,x.elem_code, 
     	x.movgest_anno,x.movgest_numero,
        numero_modifica,
        motivo_modif_code, motivo_modif_desc      
union
--colonna E		
select 'colonna_E'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno,         
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
        ''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,
		sum(x.spese_da_impeg_anno1_e) as spese_da_impeg_anno1_e from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_e
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 2
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code ,t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_e
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = '2021'   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code ,t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  .
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.            
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_e
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null    
                  	--impegni che arrivano da reimputazione    
                  and ((mov_ts.movgest_ts_id in  (                          
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL 
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure l'impegno riaccertato ha un vincolo 
                               --di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                 --SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                     --SIAC-8682 - 07/04/2022.
                                     --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
                                   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL) 
          --SIAC-8690 12/04/2022
          --devo escludere gli impegni riaccertati il cui impegno origine
          --l'anno precedente era vincolato verso FPV. 
          --AAM e' accettato.                                       
              AND  not exists (select 1                          
                    from siac_t_movgest_ts t_mov_ts1                                                            
                     join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                            from siac_r_movgest_ts_attr r_mov_attr1,
                             siac_t_attr attr1
                            where r_mov_attr1.attr_id=attr1.attr_id
                                and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                and upper(r_mov_attr1.testo) <> 'NULL'                                
                                and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                            on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                      join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                            from siac_r_movgest_ts_attr r_mov_attr2,
                             siac_t_attr attr2
                            where r_mov_attr2.attr_id=attr2.attr_id
                                and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                and upper(r_mov_attr2.testo) <> 'NULL'                                
                                and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                          on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                      siac_r_movgest_ts r_mov_ts1,
                      siac_t_movgest_ts imp_ts1,
                      siac_t_movgest imp1,
                      siac_t_avanzovincolo av_vincolo1, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                     where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                     and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                      and imp_ts1.movgest_id=imp1.movgest_id
                      and r_mov_ts1.avav_id=av_vincolo1.avav_id
                      and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                      and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                      and imp1.bil_id=bilancio_id --anno bilancio
                      and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                      and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                      and av_vincolo_tipo1.avav_tipo_code<>'AAM'
                          --se movgest_ts_a_id = NULL
                          --il vincolo non e' verso accertamento.
                      and r_mov_ts1.movgest_ts_a_id IS NULL
                      and r_mov_ts1.data_cancellazione IS NULL   
                      and imp_ts1.data_cancellazione IS NULL 
                      and imp1.data_cancellazione IS NULL
                      and av_vincolo1.data_cancellazione IS NULL)                                                                                      
                  )))--fine impegni che arrivano da reimputazione  
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                    AND  (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL))                                                                                                          
              group by class.classif_code ,t_bil_elem.elem_code , 
              	mov.movgest_anno , mov.movgest_numero)    
              ) as x
        group by x.programma_code ,x.elem_code, x.movgest_anno,
            x.movgest_numero,
            numero_modifica,
            motivo_modif_code,
            motivo_modif_desc   
union                   
--Colonna F
select 'colonna_F'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno,         
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
        ''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,
		sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f from (
               (
 				 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio               
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      		as spese_da_impeg_anni_succ_f
                        from siac_t_movgest mov,  
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_movgest_ts acc_ts,
                          siac_t_movgest acc,
                          siac_r_movgest_ts_stato r_acc_ts_stato,
                          siac_d_movgest_stato d_acc_stato
                        where mov.movgest_id = mov_ts.movgest_id  
                            and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                            and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                            and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                            and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                            and r_bil_elem_class.classif_id = class.classif_id
                            and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                            and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                            and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                            and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                            and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id
                            and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                            and acc_ts.movgest_id = acc.movgest_id
                            and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                            and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id
                            and r_mov_bil_elem.movgest_id=mov.movgest_id 
                            and mov.ente_proprietario_id= p_ente_prop_id 
                            and mov.bil_id = bilancio_id     
                            and d_class_tipo.classif_tipo_code='PROGRAMMA'
                            and mov.movgest_anno > annoBilInt + 2
                            and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and d_mov_stato.movgest_stato_code in ('D', 'N')
                            and d_mov_tipo.movgest_tipo_code='I' 
                            and acc.movgest_anno = annoBilInt
                            and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                            --and atto.attoamm_anno = p_anno   
                            and mov_ts.movgest_ts_id_padre is NULL  
                            and mov_ts.data_cancellazione is null
                            and mov_ts.validita_fine is NULL                           
                            and r_mov_bil_elem.data_cancellazione is null
                            and r_mov_bil_elem.validita_fine is NULL          
                            and r_mov_ts_stato.data_cancellazione is null
                            and r_mov_ts_stato.validita_fine is null
                            and mov_ts_det.data_cancellazione is null
                            and mov_ts_det.validita_fine is null
                            and d_mov_tipo.data_cancellazione is null
                            and d_mov_tipo.validita_fine is null              
                            and r_bil_elem_class.data_cancellazione is null
                            and r_bil_elem_class.validita_fine is null
                            and r_mov_ts_atto.data_cancellazione is null
                            and r_mov_ts_atto.validita_fine is null                         
                            and r_mov_ts.data_cancellazione is null
                            and r_mov_ts.validita_fine is null                         
                            and acc_ts.movgest_ts_id_padre is null                        
                            and acc.validita_fine is null
                            and acc.data_cancellazione is null
                            and acc_ts.validita_fine is null
                            and acc_ts.data_cancellazione is null                                                
                            and r_acc_ts_stato.validita_fine is null
                            and r_acc_ts_stato.data_cancellazione is null                                                
                                --21/05/2020 SIAC-7643 
                                --aggiunti i test sulle date che mancavano                        
                            and mov.validita_fine is null
                            and mov.data_cancellazione is null
                            and d_mov_ts_det_tipo.validita_fine is null
                            and d_mov_ts_det_tipo.data_cancellazione is null
                            and t_bil_elem.validita_fine is null
                            and t_bil_elem.data_cancellazione is null
                            and d_mov_stato.validita_fine is null
                            and d_mov_stato.data_cancellazione is null
                            and class.validita_fine is null
                            and class.data_cancellazione is null
                            and d_class_tipo.validita_fine is null
                            and d_class_tipo.data_cancellazione is null 
                            and atto.validita_fine is null
                            and atto.data_cancellazione is null                                                                                                                                                   
                           group by class.classif_code,
                             t_bil_elem.elem_code , 
                              mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anni_succ_f
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
						  siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 	
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id  
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id    
                          and mov.bil_id = bilancio_id   
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno > annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM' 
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL    
                          and mov_ts.data_cancellazione is null
                          and mov_ts.validita_fine is NULL   
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null   
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                       
                  group by class.classif_code,
                  	t_bil_elem.elem_code , 
              				mov.movgest_anno , mov.movgest_numero)
              union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno > anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                  
             select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
             sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anni_succ_f
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno > annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                     --impegni che arrivano da reimputazione 
                  and ((mov_ts.movgest_ts_id in  (
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL 
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure l'impegno riaccertato ha un vincolo 
                               --di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                  --SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                     --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
                                  --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con anno > dell'anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno > annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)  
                  --SIAC-8690 12/04/2022
                  --devo escludere gli impegni riaccertati il cui impegno origine
                  --l'anno precedente era vincolato verso FPV. 
                  --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr1.testo) <> 'NULL'                                      
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr2.testo) <> 'NULL'                                      
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                        
                 ))--fine impegni che arrivano da reimputazione 
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                  AND    (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code,
              	t_bil_elem.elem_code, mov.movgest_anno,
              	mov.movgest_numero)   
            ) as x
        group by x.programma_code ,x.elem_code, x.movgest_anno,
            x.movgest_numero, numero_modifica,
            motivo_modif_code, motivo_modif_desc                                 
order by 1,2,3,4,5;          

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato ';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR147_dettaglio_colonne_nuovo" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;
  
  
--SIAC-8670, SIAC-8676, SIAC-8682 e SIAC-8690 - Maurizio - FINE


-- SIAC-8663 - A. Todesco - INIZIO  
DROP FUNCTION IF EXISTS siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER);

CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_media_di_confronto_acc_gestione(p_uid_elem_gestione INTEGER, p_uid_ente_proprietario INTEGER , p_anno_bilancio INTEGER)
RETURNS SETOF VARCHAR AS 
$body$
DECLARE
    v_messaggiorisultato VARCHAR;
    v_perc_media_confronto NUMERIC;
    v_tipo_media_confronto VARCHAR;
    v_uid_capitolo_previsione INTEGER;
    v_elem_code VARCHAR;
    v_elem_code2 VARCHAR;
BEGIN

	SELECT stbe.elem_code, stbe.elem_code2 
	FROM siac_t_bil_elem stbe 
	WHERE stbe.elem_id = p_uid_elem_gestione
	AND stbe.data_cancellazione IS NULL INTO v_elem_code, v_elem_code2;

	v_messaggiorisultato := 'Ricerca per capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di GESTIONE';
	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	
    v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti defintivi precedenti in GESTIONE';
    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

    v_tipo_media_confronto := 'GESTIONE';

    -- GESTIONE DEFINITIVA
    SELECT tafdeEquiv.perc_acc_fondi
    FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
    JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
    JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
    JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
    JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
    JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
    JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
    WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
    AND tafdeEquiv.elem_id = p_uid_elem_gestione
    AND step.ente_proprietario_id = p_uid_ente_proprietario
    AND sdafdes.afde_stato_code = 'DEFINITIVA'
    AND tafdeEquiv.data_cancellazione IS NULL 
    AND tafdeEquiv.validita_fine IS NULL 
    ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    -- PREVISIONE DEFINITIVA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO DEFINITIVA - GESTIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco uid del capitolo ' || p_anno_bilancio || '/' || v_elem_code || '/' || v_elem_code2 || ' di PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT stbe.elem_id
        FROM siac_t_bil_elem stbe 
        JOIN siac_t_bil stb ON stbe.bil_id = stb.bil_id 
        JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
        JOIN siac_d_bil_elem_tipo sdbet ON stbe.elem_tipo_id = sdbet.elem_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = stbe.ente_proprietario_id 
        WHERE stbe.elem_code = v_elem_code 
        AND stbe.elem_code2 = v_elem_code2
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND stp.anno = p_anno_bilancio::VARCHAR
        AND sdbet.elem_tipo_code = 'CAP-EP'
        AND stbe.data_cancellazione IS NULL INTO v_uid_capitolo_previsione;
        
        IF v_uid_capitolo_previsione IS NOT NULL THEN
            v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - UID: [' || v_uid_capitolo_previsione || '] TROVATO.';
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
	    END IF;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti DEFINTIVI precedenti in PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'PREVISIONE';

        SELECT tafdeEquiv.perc_acc_fondi
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
        AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'DEFINITIVA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;
    
    END IF;

    -- PREVISIONE BOZZA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO DEFINITIVA - PREVISIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti in BOZZA in PREVISIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        SELECT tafdeEquiv.perc_acc_fondi
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        WHERE sdafdet.afde_tipo_code = 'PREVISIONE' 
        AND tafdeEquiv.elem_id = v_uid_capitolo_previsione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'BOZZA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    END IF;   

    -- GESTIONE BOZZA
    IF v_perc_media_confronto IS NULL THEN

        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO BOZZA - PREVISIONE';
    	raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_messaggiorisultato := 'Cerco la media di confronto tra gli accantonamenti in BOZZA in GESTIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

        v_tipo_media_confronto := 'GESTIONE';

        SELECT tafdeEquiv.perc_acc_fondi
        FROM siac_t_acc_fondi_dubbia_esig tafdeEquiv
        JOIN siac_t_bil_elem tbe ON tafdeEquiv.elem_id = tbe.elem_id 
        JOIN siac_d_acc_fondi_dubbia_esig_tipo sdafdet ON tafdeEquiv.afde_tipo_id = sdafdet.afde_tipo_id 
        JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = tafdeEquiv.ente_proprietario_id 
        JOIN siac_t_acc_fondi_dubbia_esig_bil stafdeb ON tafdeEquiv.afde_bil_id = stafdeb.afde_bil_id 
        JOIN siac_d_acc_fondi_dubbia_esig_stato sdafdes ON stafdeb.afde_stato_id = sdafdes.afde_stato_id 
        JOIN siac_t_bil stb ON stb.bil_id = stafdeb.bil_id 
        WHERE sdafdet.afde_tipo_code = 'GESTIONE' 
        AND tafdeEquiv.elem_id = p_uid_elem_gestione
        AND step.ente_proprietario_id = p_uid_ente_proprietario
        AND sdafdes.afde_stato_code = 'BOZZA'
        AND tafdeEquiv.data_cancellazione IS NULL 
        AND tafdeEquiv.validita_fine IS NULL 
        ORDER BY stafdeb.afde_bil_versione DESC LIMIT 1 INTO v_perc_media_confronto;

    END IF;   

    IF v_perc_media_confronto IS NULL THEN
        v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO BOZZA - GESTIONE';
        raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;
    END IF;

    IF v_perc_media_confronto IS NOT NULL THEN
		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - MEDIA DI CONFRONTO: [' || v_perc_media_confronto || ' - ' || v_tipo_media_confronto || ' ]';
--	ELSE 
--		v_messaggiorisultato := '[fnc_siac_calcolo_media_di_confronto_acc_gestione] - NESSUNA MEDIA DI CONFRONTO TROVATA';
    END IF;

    raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] v_messaggiorisultato=%', v_messaggiorisultato;

	-- [0, 1] => [0] percentuale incasso precedente, [1] => tipoMedia
    RETURN QUERY VALUES (v_perc_media_confronto::VARCHAR), (v_tipo_media_confronto);

    EXCEPTION
        WHEN RAISE_EXCEPTION THEN
            v_messaggiorisultato := v_messaggiorisultato || ' - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;
        WHEN others THEN
            v_messaggiorisultato := v_messaggiorisultato || ' others - ' || substring(upper(sqlerrm) from 1 for 2500);
            raise notice '[fnc_siac_calcolo_media_di_confronto_acc_gestione] ERROR %', v_messaggiorisultato;


END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
-- SIAC-8663 - A. Todesco - FINE  

--SIAC-8642 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR248_conto_economico_allegato_A_gsa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_cod_bilancio varchar,
  p_data_pnota_da date,
  p_data_pnota_a date
)
RETURNS TABLE (
  classif_id integer,
  codice_voce varchar,
  descrizione_voce varchar,
  livello_codifica integer,
  padre varchar,
  foglia varchar,
  pdce_conto_code varchar,
  pdce_conto_descr varchar,
  pdce_conto_numerico varchar,
  pdce_fam_code varchar,
  importo_dare numeric,
  importo_avere numeric,
  importo_saldo numeric,
  segno integer,
  titolo varchar,
  display_error varchar
) AS
$body$
DECLARE

classifGestione record;
pdce            record;

v_imp_dare           NUMERIC :=0;
v_imp_avere          NUMERIC :=0;
v_imp_saldo		 	 NUMERIC :=0;
v_imp_dare_meno 	 NUMERIC :=0;
v_imp_avere_meno	 NUMERIC :=0;
v_imp_saldo_meno	 NUMERIC :=0;

v_importo 			 NUMERIC :=0;
v_pdce_fam_code      VARCHAR;
v_classificatori     VARCHAR;
v_classificatori1    VARCHAR;
v_codice_subraggruppamento VARCHAR;
v_anno_int integer;

DEF_NULL	constant VARCHAR:='';
RTN_MESSAGGIO 		 VARCHAR(1000):=DEF_NULL;
user_table			 VARCHAR;
conta_livelli integer;
maxLivello integer;
id_bil integer;
conta integer;

BEGIN


RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into   user_table;

v_anno_int := p_anno::integer;

classif_id:=0;
codice_voce := '';
descrizione_voce := '';
livello_codifica := 0;
padre := '';
foglia := '';
pdce_conto_code := '';
pdce_conto_descr := '';
importo_dare :=0;
importo_avere :=0;
display_error:='';

RTN_MESSAGGIO:='Inserimento nella tabella di appoggio.';
raise notice '1 - %' , clock_timestamp()::text;

v_classificatori  := '';
v_classificatori1 := '';
v_codice_subraggruppamento := '';
    
if (p_data_pnota_da IS NOT NULL and p_data_pnota_a IS NULL) OR
	(p_data_pnota_da IS NULL and p_data_pnota_a IS NOT NULL) then
    display_error:='Specificare entrambe le date della prima nota.';
    return next;
    return;
end if;
    
if p_data_pnota_da > p_data_pnota_a THEN
	display_error:='La data Da della prima nota non puo'' essere successiva alla data A.';
    return next;
    return;
end if;

v_anno_int:=p_anno::integer;    
conta:=0;
if p_cod_bilancio is not null and p_cod_bilancio <> '' then
	select count(*)
    	into conta
    from siac_t_class class,
        siac_d_class_tipo tipo_class
	where class.classif_tipo_id=tipo_class.classif_tipo_id
    	and class.ente_proprietario_id=p_ente_prop_id
        and upper(right(class.classif_code,length(class.classif_code)-1))=
        	upper(p_cod_bilancio)
        and class.data_cancellazione IS NULL;       
    if conta = 0 then 
    	display_error:='Il codice bilancio '''||p_cod_bilancio|| ''' non esiste';
    	return next;
    	return;
    end if;
end if;

select a.bil_id
into id_bil
from siac_t_bil a,
	siac_t_periodo b
where a.periodo_id=b.periodo_id
and a.data_cancellazione IS NULL
and a.ente_proprietario_id=p_ente_prop_id
and b.anno =p_anno;

--cerco le voci di conto economico e gli importi registrati sui conti
--solo per le voci "foglia".  
--I dati sono salvati sulla tabella di appoggio "siac_rep_ce_sp_gsa".
with voci as(select class.classif_id, 
 right(class.classif_code,length(class.classif_code)-1) classif_code,
class.classif_desc, r_class_fam.livello,
 	COALESCE(padre.classif_code,'') padre, 
 	case when figlio.classif_id_padre is null then 'S' else 'N' end foglia,
    case when figlio.classif_id_padre is null then class.classif_id 
    	else 0 end classif_id_foglia
    from siac_t_class class,
        siac_d_class_tipo tipo_class,
        siac_r_class_fam_tree r_class_fam
            left join (select r_fam1.classif_id, 
            	right(class1.classif_code,length(class1.classif_code)-1) classif_code
                        from siac_r_class_fam_tree r_fam1,
                            siac_t_class class1
                        where  r_fam1.classif_id=class1.classif_id
                            and r_fam1.ente_proprietario_id=p_ente_prop_id
                            and r_fam1.data_cancellazione IS NULL) padre
              on padre.classif_id=r_class_fam.classif_id_padre
             left join (select distinct r_tree2.classif_id_padre
                        from siac_r_class_fam_tree r_tree2
                        where r_tree2.ente_proprietario_id=p_ente_prop_id
                            and r_tree2.data_cancellazione IS NULL) figlio
                on r_class_fam.classif_id=figlio.classif_id_padre,
        siac_t_class_fam_tree t_class_fam        
    where class.classif_tipo_id=tipo_class.classif_tipo_id
    and class.classif_id=r_class_fam.classif_id
    and r_class_fam.classif_fam_tree_id=t_class_fam.classif_fam_tree_id
    and class.ente_proprietario_id=p_ente_prop_id
    and tipo_class.classif_tipo_code='CE_CODBIL_GSA'
    and class.data_cancellazione IS NULL
    AND v_anno_int BETWEEN date_part('year',class.validita_inizio) AND
           date_part('year',COALESCE(class.validita_fine,now())) 
    and r_class_fam.data_cancellazione IS NULL
    and r_class_fam.validita_fine IS NULL
    AND v_anno_int BETWEEN date_part('year',r_class_fam.validita_inizio) AND
           date_part('year',COALESCE(r_class_fam.validita_fine,now())) ),
conti AS( SELECT fam.pdce_fam_code,fam.pdce_fam_segno, r.classif_id,
                   conto.pdce_conto_code, conto.pdce_conto_desc,
                   conto.pdce_conto_id
            from siac_r_pdce_conto_class r,  siac_t_pdce_conto conto,
                 siac_t_pdce_fam_tree famtree, siac_d_pdce_fam fam,siac_d_ambito ambito
            where conto.pdce_conto_id=r.pdce_conto_id
            and   famtree.pdce_fam_tree_id=conto.pdce_fam_tree_id
            and   fam.pdce_fam_id=famtree.pdce_fam_id
            and   ambito.ambito_id=conto.ambito_id
            and   r.ente_proprietario_id=p_ente_prop_id
            and   ambito.ambito_code='AMBITO_GSA'
            and   r.data_cancellazione is null
            and   conto.data_cancellazione is null
            and   v_anno_int BETWEEN date_part('year',r.validita_inizio)::integer and  coalesce (date_part('year',r.validita_fine)::integer ,v_anno_int)
            and   v_anno_int BETWEEN date_part('year',conto.validita_inizio) AND date_part('year',COALESCE(conto.validita_fine,now()))
           ),
           movimenti as
           (
            select det.pdce_conto_id,
                   sum( case  when det.movep_det_segno='Dare' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_dare,
                   sum( case  when det.movep_det_segno='Avere' then COALESCE(det.movep_det_importo,0) else 0 end ) as importo_avere
            from  siac_t_periodo per,   siac_t_bil bil,
                  siac_t_prima_nota pn, siac_r_prima_nota_stato rs, siac_d_prima_nota_stato stato,
                  siac_t_mov_ep ep, siac_t_mov_ep_det det,siac_d_ambito ambito
            where per.periodo_id=bil.periodo_id            
            and   pn.bil_id=bil.bil_id
            and   rs.pnota_id=pn.pnota_id
            and   stato.pnota_stato_id=rs.pnota_stato_id
            and   ep.regep_id=pn.pnota_id
            and   det.movep_id=ep.movep_id           
            and   ambito.ambito_id=pn.ambito_id 
            and   bil.ente_proprietario_id=p_ente_prop_id
            and   per.anno::integer=v_anno_int
            and   stato.pnota_stato_code='D'            
            and   ambito.ambito_code='AMBITO_GSA'    
            and   ((p_data_pnota_da is NOT NULL and 
    				trunc(pn.pnota_dataregistrazionegiornale) between 
    					  p_data_pnota_da and p_data_pnota_a) OR
            p_data_pnota_da IS NULL)                  
            and   pn.data_cancellazione is null
            and   pn.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   ep.data_cancellazione is null
            and   ep.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            group by det.pdce_conto_id)      
insert into siac_rep_ce_sp_gsa                  
select voci.classif_id::integer, 
		voci.classif_code::varchar,
        voci.classif_desc::varchar,
        voci.livello::integer,
        voci.padre::varchar,
        voci.foglia::varchar,
        'CE_CODBIL_GSA'::varchar,
        COALESCE(conti.pdce_conto_code,'')::varchar,
        COALESCE(conti.pdce_conto_desc,'')::varchar,
        COALESCE(replace(conti.pdce_conto_code,'.',''),'')::varchar,
        COALESCE(conti.pdce_fam_code,'')::varchar,
        COALESCE(movimenti.importo_dare,0)::numeric,
        COALESCE(movimenti.importo_avere,0)::numeric,
        --PP OP RE = Avere
        	--'PP','OP','OA','RE' = Ricavi
        case when UPPER(conti.pdce_fam_segno) ='AVERE' then 
        	COALESCE(movimenti.importo_avere,0) - COALESCE(movimenti.importo_dare,0)
        	--AP OA CE = Dare
            --'AP','CE' = Costi 
        else COALESCE(movimenti.importo_dare,0) - COALESCE(movimenti.importo_avere,0)
        end ::numeric,
        p_ente_prop_id::integer,
        user_table::varchar
from voci 
	left join conti 
    	on voci.classif_id_foglia = conti.classif_id              
	left join movimenti
    	on conti.pdce_conto_id=movimenti.pdce_conto_id
order by voci.classif_code;

  
--inserisco il record per il totale finale
insert into siac_rep_ce_sp_gsa
values (0,'ZZ9999','RISULTATO DI ESERCIZIO',1,'CE_CODBIL_GSA','','S','','','','',
	0,0,0,p_ente_prop_id,user_table);
    
RTN_MESSAGGIO:='Lettura livello massimo.';
--leggo qual e' il massimo livello per le voci di conto NON "foglia".
maxLivello:=0;
SELECT max(a.livello_codifica) 
	into maxLivello
from siac_rep_ce_sp_gsa a
where a.foglia='N'
	and a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id;
    
raise notice 'maxLivello = %', maxLivello;

RTN_MESSAGGIO:='Ciclo sui livelli';
--ciclo sui livelli partendo dal massimo in quanto devo ricostruire
--al contrario gli importi per i conti che non sono "foglia".
for conta_livelli in reverse maxLivello..1
loop     
	RTN_MESSAGGIO:='Ciclo sui conti non foglia.';
	raise notice 'conta_livelli = %', conta_livelli;
    	--ciclo su tutti i conti non "foglia" del livello che sto gestendo.
    for classifGestione IN
    	select a.cod_voce, a.classif_id
        from siac_rep_ce_sp_gsa a
        where a.foglia='N'
          and a.livello_codifica=conta_livelli
          and a.utente = user_table
          and a.ente_proprietario_id = p_ente_prop_id
     	order by a.cod_voce
     loop
        v_imp_dare:=0;
        v_imp_avere:=0;
        RTN_MESSAGGIO:='Calcolo importi.';
        
        	--calcolo gli importi come somma dei suoi figli.
        select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
        	into v_imp_dare, v_imp_avere, v_imp_saldo
        from siac_rep_ce_sp_gsa a
        where a.padre=classifGestione.cod_voce
         	and a.utente = user_table
          	and a.ente_proprietario_id = p_ente_prop_id;
        
        raise notice 'codice_voce = % - importo_dare= %, importo_avere = %', 
        	classifGestione.cod_voce, v_imp_dare,v_imp_avere;
        RTN_MESSAGGIO:='Update importi.';
        
            --aggiorno gli importi 
        update siac_rep_ce_sp_gsa a
        	set imp_dare=v_imp_dare,
            	imp_avere=v_imp_avere,
                imp_saldo=v_imp_saldo
        where cod_voce=classifGestione.cod_voce
        	and utente = user_table
          	and ente_proprietario_id = p_ente_prop_id;
            
     end loop; --loop voci NON "foglie" del livello gestito.     
end loop; --loop livelli

--devo aggiornare alcuni importi totali secondo le seguenti formule.

--AZ9999= AA0010+AA0240+AA0270+AA0320+AA0750+AA0940+AA0980+AA1050+AA1060
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('AA0010','AA0240','AA0270','AA0320','AA0750','AA0940','AA0980',
	'AA1050','AA1060')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'AZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
                   
--BZ9999= BA0010+BA0390+BA1910+BA1990+BA2080+BA2500+BA2560+BA2630+BA2660+BA2690
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('BA0010','BA0390','BA1910','BA1990','BA2080','BA2500','BA2560',
	'BA2630','BA2660','BA2690')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'BZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;
    
--CZ9999= CA0010+CA0050-CA0110-CA0150    
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0010','CA0050')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('CA0110','CA0150')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'CZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
    
--DZ9999= DA0010-DA0020
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('DA0010')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('DA00200')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'DZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;      
      
/* SIAC-8642 28/03/2022  
	Il campo EZ9999 deve essere calcolato con la stessa logica del campo:
    "EA0000 - E) Proventi e oneri straordinari".
    Pertanto prendo quanto gia' calcolato per  EA0000 e imposto gli stessi
    valori per EZ9999.
    Prima era calcolato come:
 		EZ9999= EA0010-EA0260
    L'importo del saldo che serve per il report BILR248 rimane calcolato come 
    saldo di EA0010 - saldo di EA0260.
*/
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select --sum(a.imp_dare), sum(a.imp_avere), 
		sum(a.imp_saldo)
    into --v_imp_dare, v_imp_avere, 
    	v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('EA0010')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select --sum(a.imp_dare), sum(a.imp_avere), 
		sum(a.imp_saldo)
    into --v_imp_dare_meno, v_imp_avere_meno, 
    	v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('EA0260')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id; 
select sum(a.imp_dare), sum(a.imp_avere)
    into v_imp_dare, v_imp_avere
from siac_rep_ce_sp_gsa a
where a.cod_voce in('EA0000')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;        

update siac_rep_ce_sp_gsa a
      set --imp_dare=v_imp_dare-v_imp_dare_meno,
          --imp_avere=v_imp_avere-v_imp_avere_meno,
          --imp_saldo=v_imp_saldo-v_imp_saldo_meno
          imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'EZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;      
    
--XA0000= AZ9999-BZ9999+CZ9999+DZ9999+EZ9999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('AZ9999','CZ9999','DZ9999','EZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('BZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'XA0000'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
    
--YZ9999= YA0010+YA0060+YA0090
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('YA0010','YA0060','YA0090')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare,
          imp_avere=v_imp_avere,
          imp_saldo=v_imp_saldo
where a.cod_voce= 'YZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id; 
        
--ZZ9999= XA0000-YZ9999
v_imp_dare:=0;
v_imp_avere:=0;
v_imp_saldo:=0;
v_imp_dare_meno:=0;
v_imp_avere_meno:=0;
v_imp_saldo_meno:=0;
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare, v_imp_avere, v_imp_saldo
from siac_rep_ce_sp_gsa a
where a.cod_voce in('XA0000')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;    
select sum(a.imp_dare), sum(a.imp_avere), sum(a.imp_saldo)
    into v_imp_dare_meno, v_imp_avere_meno, v_imp_saldo_meno
from siac_rep_ce_sp_gsa a
where a.cod_voce in('YZ9999')
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;     
update siac_rep_ce_sp_gsa a
      set imp_dare=v_imp_dare-v_imp_dare_meno,
          imp_avere=v_imp_avere-v_imp_avere_meno,
          imp_saldo=v_imp_saldo-v_imp_saldo_meno
where a.cod_voce= 'ZZ9999'
    and a.utente = user_table
    and a.ente_proprietario_id = p_ente_prop_id;  
        
--restituisco i dati presenti sulla tabella di appoggio.
return query
select tutto.*, 
	COALESCE(config.segno,1)::integer segno, 
    COALESCE(config.titolo,'') titolo,
    ''::varchar
from (select a.classif_id::integer, 
  a.cod_voce::varchar cod_voce,
  a.descrizione_voce::varchar,
  a.livello_codifica::integer,
  a.padre::varchar,
  a.foglia::varchar,
  COALESCE(a.pdce_conto_code,'')::varchar,
  COALESCE(a.pdce_conto_descr,'')::varchar,
  COALESCE(a.pdce_conto_numerico,'')::varchar,
  COALESCE(a.pdce_fam_code,'')::varchar,
  COALESCE(a.imp_dare,0)::numeric,
  COALESCE(a.imp_avere,0)::numeric,
  COALESCE(a.imp_saldo,0)::numeric--,
  --case when a.pdce_fam_code in ('PP','OP','OA','RE') then 1
  --	else -1 end::integer,
--  ''::varchar
from siac_rep_ce_sp_gsa a
where a.utente = user_table
	and a.ente_proprietario_id = p_ente_prop_id
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (upper(a.cod_voce) = upper(p_cod_bilancio) OR 
          	upper(a.padre) = upper(p_cod_bilancio))))    
UNION
select b.classif_id::integer, 
  b.cod_voce::varchar cod_voce,
  b.descrizione_voce::varchar,
  b.livello_codifica::integer,
  b.padre::varchar,
  b.foglia::varchar,
  ''::varchar,
  ''::varchar,
  ''::varchar,
  ''::varchar,
  COALESCE(sum(b.imp_dare),0)::numeric,
  COALESCE(sum(b.imp_avere),0)::numeric,
  COALESCE(sum(b.imp_saldo),0)::numeric--,
 -- 0::integer,
 -- ''::varchar
from siac_rep_ce_sp_gsa b
where b.utente = user_table
	and b.ente_proprietario_id = p_ente_prop_id
    and b.foglia='S'
    and ((p_cod_bilancio is null OR p_cod_bilancio = '') OR
    	 (p_cod_bilancio is not null and p_cod_bilancio <> '' and
          (b.cod_voce = p_cod_bilancio OR b.padre = p_cod_bilancio)))
    and b.classif_id not in (select c.classif_id
    		from siac_rep_ce_sp_gsa c
            where c.utente = user_table
				and c.ente_proprietario_id = p_ente_prop_id
                and c.pdce_conto_code ='')
group by b.classif_id, b.cod_voce, b.descrizione_voce, b.livello_codifica,
  b.padre, b.foglia) tutto 
  left join (select conf.cod_voce, conf.titolo, conf.segno
  			 from siac_t_config_rep_ce_sp_gsa conf
             where conf.bil_id=id_bil
             and conf.tipo_report='CE'
             and conf.data_cancellazione IS NULL) config
  	on tutto.cod_voce=config.cod_voce   
order by 2,6;
    
delete from siac_rep_ce_sp_gsa where utente = user_table;

raise notice '2 - %' , clock_timestamp()::text;
raise notice 'fine OK';

  EXCEPTION
  WHEN no_data_found THEN
  raise notice 'Nessun dato trovato per rendiconto gestione GSA';
  return;
  WHEN others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR248_conto_economico_allegato_A_gsa" (p_ente_prop_id integer, p_anno varchar, p_cod_bilancio varchar, p_data_pnota_da date, p_data_pnota_a date)
  OWNER TO siac;
  
--SIAC-8642 - Maurizio - FINE  



--SIAC-8687 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR255_stampa_variazione_Prev_definitive_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_anno_variazione varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  anno_riferimento varchar,
  display_error varchar,
  flag_visualizzazione numeric
) AS
$body$
DECLARE

/* 01/07/2021 SIAC-8152.
	Funzione copia della BILR226_stampa_variazione_spese_prev per il nuovo report
    BILR255 che differisce dal BILR266 per il fatto che le variazioni estratte sono
    in stato DEFINITIVO.
*/

classifBilRec record;
annoCapImp varchar;
annoCapImp2 varchar;
annoCapImp3 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
sql_query varchar;
strApp varchar;
intApp numeric;

BEGIN

annoCapImp:= p_anno; 
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 01/04/2016: il report funziona solo per la previsione
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;


bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
display_error='';
flag_visualizzazione = -111;
---------------------------------------------------------------------------------------------------------------------

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.';  


-- carico struttura del bilancio
insert into siac_rep_mis_pro_tit_mac_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, 
														p_anno, user_table);

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
	-- INC000001570761 stato_capitolo.elem_stato_code	=	'VA'								and
    stato_capitolo.elem_stato_code	in ('VA', 'PR')							and
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		
    ------cat_del_capitolo.elem_cat_code	=	'STD'	
    -- 06/09/2016: aggiunto FPVC
	--and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	

          
    insert into siac_rep_cap_ug
      select null, null,
        anno_eserc.anno anno_bilancio,
        e.*, ' ', user_table utente
       from 	
              siac_t_bil_elem e,
              siac_t_bil bilancio,
              siac_t_periodo anno_eserc,
              siac_d_bil_elem_tipo tipo_elemento, 
              siac_d_bil_elem_stato stato_capitolo,
              siac_r_bil_elem_stato r_capitolo_stato
      where e.ente_proprietario_id=p_ente_prop_id
      and anno_eserc.anno					= 	p_anno
      and bilancio.periodo_id				=	anno_eserc.periodo_id 
      and e.bil_id						=	bilancio.bil_id 
      and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
      and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
      and	e.elem_id						=	r_capitolo_stato.elem_id
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id								
      and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
      and e.data_cancellazione 				is null
      and	r_capitolo_stato.data_cancellazione	is null
      and	bilancio.data_cancellazione 		is null
      and	anno_eserc.data_cancellazione 		is null
      and	tipo_elemento.data_cancellazione	is null
      and	stato_capitolo.data_cancellazione 	is null
      and not EXISTS
      (
         select 1 from siac_rep_cap_ug x
         where x.elem_id = e.elem_id
         and x.utente=user_table
    );

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  
  
INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,  
            user_table utente,            
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno = p_anno_variazione
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
	 	-- INC000001570761 and stato_capitolo.elem_stato_code	=	'VA'								
        and stato_capitolo.elem_stato_code	in ('VA', 'PR')			
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and capitolo_imp_tipo.elem_det_tipo_code in ('STA', 'SCA','STR')
        -- 06/09/2016: aggiunto FPVC
        --and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')						
 		and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
 
     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente ,
        tb1.periodo_anno
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		tb1.periodo_anno 		= p_anno_variazione	AND	 
                tb1.tipo_imp 	=	tipoImpComp		        AND      
        		tb2.periodo_anno		= tb1.periodo_anno	AND	
                tb2.tipo_imp 	= 	tipoImpCassa	        and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	
                tb4.tipo_imp 	= 	TipoImpRes		        and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  
     
sql_query='insert into siac_rep_var_spese
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, '''; 
sql_query=sql_query ||user_table||''' utente, 
        testata_variazione.ente_proprietario_id,
        anno_importo.anno     	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo ,
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id   
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id 
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id ';
sql_query=sql_query ||'and		tipo_capitolo.elem_tipo_code						= '''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||''''; 												
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';  
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'') and 
		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno';
            
raise notice 'sql_query = % ', sql_query;

EXECUTE sql_query;

        
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
     
insert into siac_rep_var_spese_riga
select  tb0.elem_id,        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_variazione
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and     tb1.periodo_anno=p_anno_variazione
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and     tb2.periodo_anno=p_anno_variazione
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and     tb3.periodo_anno=p_anno_variazione
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and     tb4.periodo_anno=p_anno_variazione
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0
        and     tb5.periodo_anno=p_anno_variazione
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and     tb6.periodo_anno=p_anno_variazione
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  

for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
		,COALESCE (vu.elem_id,-111) flag_visualizzazione   ---- cle -nuovo 
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
         	LEFT join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table
                    )      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)     
       left join siac_rep_var_spese vu
     on (	tb.elem_id	=vu.elem_id	
        and  vu.periodo_anno=p_anno_variazione
        and vu.utente = tb.utente ) 
    where v1.utente = user_table 
    	and tb1.periodo_anno = p_anno_variazione
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id                        
    )	
    union
    select	
    	'0000000'							macroag_code,
      	' '									macroag_desc,
        'Macroaggregato'					macroag_tipo_desc,
        '00'								missione_code,
        ' '									missione_desc,
        'Missione'							missione_tipo_desc,
        '0000'								programma_code,
        ' '									programma_desc,
        'Programma'							programma_tipo_desc,
        '0'									titusc_code,
        ' '									titusc_desc,
        'Titolo Spesa'						titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
	,COALESCE (vu.elem_id,-111) flag_visualizzazione  
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_ug tb
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
       left join siac_rep_var_spese vu
     on (	tb.elem_id	=vu.elem_id	
        and  vu.periodo_anno=p_anno_variazione
        and vu.utente = tb.utente ) 
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and (tb.programma_id is null or tb.macroaggregato_id is NULL)
   
                        	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop

missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;
flag_visualizzazione  =  classifBilRec.flag_visualizzazione ; 

--SIAC-8687: 11/04/2022.
--L'importo di stanziamento, cassa e residuo deve essere quello prima 
-- della modifica, quindi dal totale calcolato escludo l'importo della
--modifica.
--stanziamento:=classifBilRec.stanziamento;
--cassa:=classifBilRec.cassa;
--residuo:=classifBilRec.residuo;
stanziamento:=classifBilRec.stanziamento-variazione_aumento_stanziato+
	variazione_diminuzione_stanziato;
cassa:=classifBilRec.cassa-variazione_aumento_cassa+
	   variazione_diminuzione_cassa;
residuo:=classifBilRec.residuo-variazione_aumento_residuo+
	variazione_diminuzione_residuo;       

return next;

bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
flag_visualizzazione = -111;

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;

delete from siac_rep_cap_ug where utente=user_table;

delete from siac_rep_cap_ug_imp where utente=user_table;

delete from siac_rep_cap_ug_imp_riga where utente=user_table;

delete from	siac_rep_var_spese	where utente=user_table;

delete from siac_rep_var_spese_riga where utente=user_table;




raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM;
    	return next;
    	return;        
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR255_stampa_variazione_Prev_definitive_spese" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_anno_variazione varchar)
  OWNER TO siac;
  
  
CREATE OR REPLACE FUNCTION siac."BILR255_stampa_variazione_Prev_definitive_entrate" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_ele_variazioni varchar,
  p_anno_variazione varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  anno_riferimento varchar,
  ente_denominazione varchar,
  display_error varchar,
  flag_visualizzazione numeric
) AS
$body$
DECLARE

/* 01/07/2021 SIAC-8152.
	Funzione copia della BILR226_stampa_variazione_entrate_prev per il nuovo report
    BILR255 che differisce dal BILR226 per il fatto che le variazioni estratte sono
    in stato DEFINITIVO.
*/


classifBilRec record;
annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
sql_query varchar;

BEGIN

annoCapImp:= p_anno; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 01/04/2016: il report funziona solo per la previsione
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione


IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
ente_denominazione ='';
display_error='';
flag_visualizzazione = -111;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  


/* carico la struttura di bilancio completa */
insert into siac_rep_tit_tip_cat_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
														p_anno, user_table);


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
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
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--and	cat_del_capitolo.elem_cat_code	=	'STD'
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


insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	
 		siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and not EXISTS
(
   select 1 from siac_rep_cap_eg x
   where x.elem_id = e.elem_id
   and x.utente=user_table
);


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  


INSERT INTO siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,   
            sum(capitolo_importi.elem_det_importo)    importo_cap 
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
       -- and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code	=	'VA'
		and	stato_capitolo.elem_stato_code	in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and	cat_del_capitolo.elem_cat_code		=	'STD'
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
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb4.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb4
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb4.elem_id	 								and												
        			--tb1.periodo_anno 	= annoCapImp		AND	
                    tb1.tipo_imp =	tipoImpComp		        and  
        			tb2.periodo_anno	= tb1.periodo_anno	AND	
                    tb2.tipo_imp = 	tipoImpCassa	        and
                    tb4.periodo_anno	= tb1.periodo_anno	AND	
                    tb4.tipo_imp = 	tipoImpRes		        and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb4.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  


sql_query='insert into siac_rep_var_entrate
select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),        
        tipo_elemento.elem_det_tipo_code, '''; 
sql_query=sql_query ||user_table||''' utente, 
        testata_variazione.ente_proprietario_id	,
        anno_importo.anno      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo,
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id 
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id  
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id ';
sql_query=sql_query ||' and		tipo_capitolo.elem_tipo_code =	'''||elemTipoCode||'''';
sql_query=sql_query ||' and 	testata_variazione.ente_proprietario_id 	= 	'||p_ente_prop_id;
sql_query=sql_query ||' and		anno_eserc.anno					= 	'''||p_anno||''''; 												
sql_query=sql_query ||' and 	testata_variazione.variazione_num in ('||p_ele_variazioni||') ';  
sql_query=sql_query ||' and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'')
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno'  ;    
            
raise notice 'sql_query = %',sql_query;
                    
EXECUTE sql_query;

    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,    
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno=p_anno
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno=p_anno
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno=p_anno
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno=p_anno
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno=p_anno
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and tb6.periodo_anno=p_anno
        and tb6.utente = tb0.utente 	)
  union 
     select  tb0.elem_id,     
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and tb6.periodo_anno= (p_anno::INTEGER + 1)::varchar
        and tb6.utente = tb0.utente 	)
    union 
    select  tb0.elem_id,     
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar	from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo >= 0	
        and tb1.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo <= 0	
        and tb2.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo >= 0	
        and tb3.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo <= 0	
        and tb4.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo >= 0	
        and tb5.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo <= 0
        and tb6.periodo_anno= (p_anno::INTEGER + 2)::varchar
        and tb6.utente = tb0.utente 	);

        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
for classifBilRec in
select 	t_ente.ente_denominazione 		ente_denominazione,
		v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
           ,COALESCE (ve.elem_id,-111) flag_visualizzazione   ---- cle -nuovo 
from  	siac_t_ente_proprietario t_ente,
		siac_rep_tit_tip_cat_riga_anni v1
			left  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)
---- cle -nuovo  
       left join siac_rep_var_entrate ve
     on (	tb.elem_id	=ve.elem_id	
        and ve.periodo_anno=p_anno
        and ve.utente = TB.utente ) 
---- fine cle -nuovo  
    where t_ente.ente_proprietario_id=v1.ente_proprietario_id
    and v1.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id
            /*  AND (COALESCE(x.variazione_aumento_cassa,0) <>0 OR
                 		COALESCE(x.variazione_aumento_residuo,0) <>0  OR
                        COALESCE(x.variazione_aumento_stanziato,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_cassa,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_residuo,0) <>0 OR
                        COALESCE(x.variazione_diminuzione_stanziato,0) <>0)*/
                        
    )	
    union
    select 	t_ente.ente_denominazione 		ente_denominazione,
		'Titolo'    			titoloe_TIPO_DESC,
       	NULL              		titoloe_ID,
       	'0'            			titoloe_CODE,
       	' '             	titoloe_DESC,
       	'Tipologia'	  			tipologia_TIPO_DESC,
       	null	              	tipologia_ID,
       	'0000000'            	tipologia_CODE,
       	' '           tipologia_DESC,
       	'Categoria'     		categoria_TIPO_DESC,
      	null	              	categoria_ID,
       	'0000000'            	categoria_CODE,
       	' '           categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
        	,COALESCE (ve.elem_id,-111) flag_visualizzazione  
from  	siac_t_ente_proprietario t_ente,
		 siac_rep_cap_eg tb
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
 ---- cle -nuovo  
       left join siac_rep_var_entrate ve
     on (	tb.elem_id	=ve.elem_id	
        and ve.periodo_anno=p_anno
        and ve.utente = TB.utente ) 
---- fine cle -nuovo  
    where t_ente.ente_proprietario_id=tb.ente_proprietario_id
    and tb.utente = user_table    	
    and  tb1.periodo_anno=p_anno_variazione
   and tb.classif_id is null
			order by titoloe_CODE,tipologia_CODE,categoria_CODE

loop



---titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--------tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
-------categoria_tipo_code := classifBilRec.categoria_tipo_code;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;
ente_denominazione =classifBilRec.ente_denominazione;
flag_visualizzazione  =  classifBilRec.flag_visualizzazione ; 

--SIAC-8687: 11/04/2022.
--L'importo di stanziamento, cassa e residuo deve essere quello prima 
-- della modifica, quindi dal totale calcolato escludo l'importo della
--modifica.
--stanziamento:=classifBilRec.stanziamento;
--cassa:=classifBilRec.cassa;
--residuo:=classifBilRec.residuo;
stanziamento:=classifBilRec.stanziamento-variazione_aumento_stanziato+
	variazione_diminuzione_stanziato;
cassa:=classifBilRec.cassa-variazione_aumento_cassa+
	variazione_diminuzione_cassa;
residuo:=classifBilRec.residuo-variazione_aumento_residuo+
	variazione_diminuzione_residuo;

return next;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
ente_denominazione ='';
flag_visualizzazione = -111;

end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;


delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';

exception
	when no_data_found THEN
		raise notice 'Variazioni non trovate' ;
		--return next;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
	when others  THEN
		--raise notice 'errore nella lettura delle variazioni ';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR255_stampa_variazione_Prev_definitive_entrate" (p_ente_prop_id integer, p_anno varchar, p_ele_variazioni varchar, p_anno_variazione varchar)
  OWNER TO siac;

CREATE OR REPLACE FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  titusc_tipo_desc varchar,
  titusc_code varchar,
  titusc_desc varchar,
  macroag_tipo_desc varchar,
  macroag_code varchar,
  macroag_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

/* 02/07/2021 SIAC-8152.
	Funzione copia della BILR227_Allegato_7_delibera_variazione_su_spese_bozza_Prev
    per il nuovo report BILR257 che differisce dal BILR227 per il fatto 
    che le variazioni estratte sono in stato DEFINITIVO.
*/

classifBilRec record;
annoCapImp varchar;
annoCapImp2 varchar;
annoCapImp3 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;


BEGIN

annoCapImp:= p_anno; 
annocapimp2:=(p_anno::INTEGER + 1)::varchar;
annocapimp3:=(p_anno::INTEGER + 2)::varchar;

raise notice '%', annoCapImp;


TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
display_error:='';


-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_mis_pro_tit_mac_riga_anni''.'; 
 
 -- carico struttura del bilancio
insert into siac_rep_mis_pro_tit_mac_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, 
													p_anno, user_table);

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug''.';  
 
insert into siac_rep_cap_ug 
select 	programma.classif_id,
		macroaggr.classif_id,
        anno_eserc.anno anno_bilancio,
       	capitolo.*,
        ' ',
       user_table utente
from siac_t_bil bilancio,
	 siac_t_periodo anno_eserc,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr,
	 siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 
	 siac_d_bil_elem_stato stato_capitolo, 
     siac_r_bil_elem_stato r_capitolo_stato,
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo
where 
	programma_tipo.classif_tipo_code='PROGRAMMA' 							and		
    programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    programma.classif_id=r_capitolo_programma.classif_id					and
    macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    capitolo.ente_proprietario_id=p_ente_prop_id      						and
   	anno_eserc.anno= p_anno 												and
    bilancio.periodo_id=anno_eserc.periodo_id 								and
    capitolo.bil_id=bilancio.bil_id 										and
   	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    capitolo.elem_id=r_capitolo_programma.elem_id							and
    capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
    capitolo.elem_id				=	r_capitolo_stato.elem_id			and
	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and	
    stato_capitolo.elem_stato_code		in ('VA', 'PR')						and			
    capitolo.elem_id				=	r_cat_capitolo.elem_id				and
	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
	cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')
    and	bilancio.data_cancellazione 				is null
	and	anno_eserc.data_cancellazione 				is null
   	and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
   	and	r_capitolo_macroaggr.data_cancellazione 	is null 
	and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
	and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione 			is null;	

  

RTN_MESSAGGIO:='insert tabella siac_rep_cap_ug_imp standard''.';  


/* Si deve tener conto di eventuali variazioni successive e decrementare 
   l'importo del capitolo.
*/

INSERT INTO siac_rep_cap_ug_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,  
            user_table utente,            
            sum(capitolo_importi.elem_det_importo) importo_cap
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,            
            siac_d_bil_elem_tipo 		tipo_elemento,
            siac_t_bil 					bilancio,
	 		siac_t_periodo 				anno_eserc, 
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_t_bil_elem 			capitolo				            
    where 	capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id			
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id		
		and	stato_capitolo.elem_stato_code		in ('VA', 'PR')								
        and	capitolo.elem_id					=	r_cat_capitolo.elem_id				
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
        and cat_del_capitolo.elem_cat_code	in ('STD','FPV','FSC','FPVC')	
        and capitolo_imp_periodo.anno =	p_anno_competenza					
        and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 		
        and	capitolo_importi.data_cancellazione 		is null
        and	capitolo_imp_tipo.data_cancellazione 		is null
       	and	capitolo_imp_periodo.data_cancellazione 	is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	bilancio.data_cancellazione 				is null
	 	and	anno_eserc.data_cancellazione 				is null 
	 	and	stato_capitolo.data_cancellazione 			is null 
    	and	r_capitolo_stato.data_cancellazione 		is null
	 	and cat_del_capitolo.data_cancellazione 		is null
    	and	r_cat_capitolo.data_cancellazione 			is null
    group by	capitolo_importi.elem_id,
    capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,
    capitolo_importi.ente_proprietario_id, utente;
 
     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  

insert into siac_rep_cap_ug_imp_riga
select  tb1.elem_id, 
   	 	tb4.importo		as		residui_passivi,
    	tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente ,
        tb1.periodo_anno
from 
        siac_rep_cap_ug_imp tb1, siac_rep_cap_ug_imp tb2, siac_rep_cap_ug_imp tb4
where			tb1.elem_id				= tb2.elem_id							and
				tb1.elem_id 			= tb4.elem_id							and
        		--tb1.periodo_anno 		= annoCapImp		AND	 
                tb1.tipo_imp 	=	tipoImpComp		        AND      
        		tb2.periodo_anno		= tb1.periodo_anno	AND	
                tb2.tipo_imp 	= 	tipoImpCassa	        and
                tb4.periodo_anno    	= tb1.periodo_anno 	AND	
                tb4.tipo_imp 	= 	TipoImpRes		        and 	
                tb1.ente_proprietario 	=	p_ente_prop_id						and	
                tb2.ente_proprietario	=	tb1.ente_proprietario				and	
                tb4.ente_proprietario	=	tb1.ente_proprietario				and
                tb1.utente				=	user_table							AND
                tb2.utente				=	tb1.utente							and	
                tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  
     
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
insert into siac_rep_var_spese            
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          tipo_elemento.elem_det_tipo_code, 
          user_table utente,
          atto.ente_proprietario_id	,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_t_periodo 				anno_eserc ,
          siac_t_periodo              anno_importo,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id
            or r_variazione_stato.attoamm_id_varbil           =	atto.attoamm_id) 
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id  
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and 	atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno	
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and     anno_importo.anno                                   =   p_anno_competenza		
  and		tipologia_stato_var.variazione_stato_tipo_code		 in	('D')
  and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
  and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 		dettaglio_variazione.data_cancellazione		is null
  and 		capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id,
              tipo_elemento.elem_det_tipo_code, 
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno	  ;       
else --specificati i numeri di variazione.
	strQuery:='
	insert into siac_rep_var_spese 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	,
        anno_importo.anno	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo,
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num					in ('||p_ele_variazioni||')
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''				
and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno	  ';
raise notice 'query: %', strQuery;      

execute  strQuery;     
end if;                               
        

--/13/02/2017 : e'  rimasto solo il filtro su anno_competenza
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  
insert into siac_rep_var_spese_riga
select  tb0.elem_id,        
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_competenza 
from   
	siac_rep_cap_ug tb0 
    left join siac_rep_var_spese tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno_competenza
        and     tb1.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb1.tipologia
        ) 
    left join siac_rep_var_spese tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and     tb2.periodo_anno=p_anno_competenza
        and     tb2.utente = tb0.utente 
        -- and tb0.tipo_imp =  tb2.tipologia 
        )
    left join siac_rep_var_spese tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and     tb3.periodo_anno=p_anno_competenza
        and     tb3.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb3.tipologia
          ) 
    left join siac_rep_var_spese tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and     tb4.periodo_anno=p_anno_competenza
        and     tb4.utente = tb0.utente  
        -- and tb0.tipo_imp =  tb4.tipologia 
         )
    left join siac_rep_var_spese tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0
        and     tb5.periodo_anno=p_anno_competenza
        and     tb5.utente = tb0.utente	
         --and tb0.tipo_imp =  tb5.tipologia
          ) 
    left join siac_rep_var_spese tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and     tb6.periodo_anno=p_anno_competenza
        and     tb6.utente = tb0.utente 
         --and tb0.tipo_imp =  tb6.tipologia 
         )
        where  tb0.utente = user_table  ; 
        
        
     RTN_MESSAGGIO:='preparazione file output ''.';  
         
for classifBilRec in
select	v1.macroag_code						macroag_code,
      	v1.macroag_desc						macroag_desc,
        v1.macroag_tipo_desc				macroag_tipo_desc,
        v1.missione_code					missione_code,
        v1.missione_desc					missione_desc,
        v1.missione_tipo_desc				missione_tipo_desc,
        v1.programma_code					programma_code,
        v1.programma_desc					programma_desc,
        v1.programma_tipo_desc				programma_tipo_desc,
        v1.titusc_code						titusc_code,
        v1.titusc_desc						titusc_desc,
        v1.titusc_tipo_desc					titusc_tipo_desc,
    	tb.bil_anno   						BIL_ANNO,
       	tb.elem_code     					BIL_ELE_CODE,
       	tb.elem_desc     					BIL_ELE_DESC,
       	tb.elem_code2     					BIL_ELE_CODE2,
       	tb.elem_desc2     					BIL_ELE_DESC2,
       	tb.elem_id      					BIL_ELE_ID,
       	tb.elem_id_padre   		 			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_passivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)	variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)		variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_mis_pro_tit_mac_riga_anni v1
			join siac_rep_cap_ug tb
           on    	(v1.programma_id = tb.programma_id    
           			and	v1.macroag_id	= tb.macroaggregato_id
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)     
            left	join    siac_rep_cap_ug_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table
                    )      	
            left	join    siac_rep_var_spese_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno)     
    where v1.utente = user_table 
    and exists ( select 1 from siac_rep_var_spese_riga x, siac_rep_cap_ug y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.macroaggregato_id = z.classif_id
                 and z.classif_id_padre = v1.titusc_id
                 and y.programma_id=v1.programma_id                                     
    )	
			order by missione_code,programma_code,titusc_code,macroag_code,	BIL_ELE_ID

loop



missione_tipo_desc:= classifBilRec.missione_tipo_desc;
missione_code:= classifBilRec.missione_code;
missione_desc:= classifBilRec.missione_desc;
programma_tipo_desc := classifBilRec.programma_tipo_desc;
programma_code := classifBilRec.programma_code;
programma_desc := classifBilRec.programma_desc;
titusc_tipo_desc := classifBilRec.titusc_tipo_desc;
titusc_code := classifBilRec.titusc_code;
titusc_desc := classifBilRec.titusc_desc;
macroag_tipo_desc := classifBilRec.macroag_tipo_desc;
macroag_code := classifBilRec.macroag_code;
macroag_desc := classifBilRec.macroag_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;

--SIAC-8687: 11/04/2022.
--L'importo di stanziamento, cassa e residuo deve essere quello prima 
-- della modifica, quindi dal totale calcolato escludo l'importo della
--modifica.
--stanziamento:=classifBilRec.stanziamento;
--cassa:=classifBilRec.cassa;
--residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;

--INC000006082542
stanziamento:=classifBilRec.stanziamento-variazione_aumento_stanziato+
	variazione_diminuzione_stanziato;
cassa:=classifBilRec.cassa-variazione_aumento_cassa + 
	variazione_diminuzione_cassa;
residuo:=classifBilRec.residuo - variazione_aumento_residuo +
	variazione_diminuzione_residuo;
    
return next;

bil_anno='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_desc='';
programma_code='';
programma_desc='';
titusc_tipo_desc='';
titusc_code='';
titusc_desc='';
macroag_tipo_desc='';
macroag_code='';
macroag_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';

end loop;


delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
delete from siac_rep_cap_ug where utente=user_table;
delete from siac_rep_cap_ug_imp where utente=user_table;
delete from siac_rep_cap_ug_imp_riga where utente=user_table;
delete from	siac_rep_var_spese	where utente=user_table;
delete from siac_rep_var_spese_riga where utente=user_table;

raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;                 
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_spese" (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar)
  OWNER TO siac;

CREATE OR REPLACE FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_ent" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  bil_anno varchar,
  titoloe_tipo_code varchar,
  titoloe_tipo_desc varchar,
  titoloe_code varchar,
  titoloe_desc varchar,
  tipologia_tipo_code varchar,
  tipologia_tipo_desc varchar,
  tipologia_code varchar,
  tipologia_desc varchar,
  categoria_tipo_code varchar,
  categoria_tipo_desc varchar,
  categoria_code varchar,
  categoria_desc varchar,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_id integer,
  bil_ele_id_padre integer,
  stanziamento numeric,
  cassa numeric,
  residuo numeric,
  variazione_aumento_stanziato numeric,
  variazione_diminuzione_stanziato numeric,
  variazione_aumento_cassa numeric,
  variazione_diminuzione_cassa numeric,
  variazione_aumento_residuo numeric,
  variazione_diminuzione_residuo numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

/* 02/07/2021 SIAC-8152.
	Funzione copia della BILR227_Allegato_7_delibera_variazione_su_entrate_bozza_Prev
    per il nuovo report BILR257 che differisce dal BILR227 per il fatto 
    che le variazioni estratte sono in stato DEFINITIVO.
*/

classifBilRec record;
annoCapImp varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
v_fam_titolotipologiacategoria varchar:='00003';
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;

BEGIN

annoCapImp:= p_anno; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCode:='CAP-EP'; -- tipo capitolo previsione


bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
display_error:='';


-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;

select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_tit_tip_cat_riga_anni''.';  


/* carico la struttura di bilancio completa */
insert into siac_rep_tit_tip_cat_riga_anni
select * from "fnc_bilr_struttura_cap_bilancio_entrate"(p_ente_prop_id, 
														p_anno, user_table);

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
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
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	elemTipoCode
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code ='VA' 
and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
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


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

/* 18/05/2016: introdotta modifica all'estrazione degli importi dei capitoli.
	Si deve tener conto di eventuali variazioni successive e decrementare 
    l'importo del capitolo.
*/

INSERT INTO siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,   
            sum(capitolo_importi.elem_det_importo)    importo_cap 
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		= 	elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
       -- and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code ='VA' 
		and	stato_capitolo.elem_stato_code	in	('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD'
        -- 13/02/2017: aggiunto filtro su anno competenza e sugli importi
        and capitolo_imp_periodo.anno =	p_anno_competenza					
        and	capitolo_imp_tipo.elem_det_tipo_code in ('STA','SCA','STR') 		
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
    group by capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;

     RTN_MESSAGGIO:='preparazione tabella importi riga capitolo ''.';  


insert into siac_rep_cap_eg_imp_riga
select  tb1.elem_id,
		tb4.importo		as		residui_attivi,
        tb1.importo 	as 		previsioni_definitive_comp,
        tb2.importo		as		previsioni_definitive_cassa,
        tb1.ente_proprietario,
        user_table utente,
        tb1.periodo_anno
from   
	siac_rep_cap_eg_imp tb1, siac_rep_cap_eg_imp tb2, siac_rep_cap_eg_imp tb4
	where			tb1.elem_id	=	tb2.elem_id	 								and
    				tb1.elem_id	=	tb4.elem_id	 								and												
        			--tb1.periodo_anno 	= annoCapImp		AND	
                    tb1.tipo_imp =	tipoImpComp		        and  
        			tb2.periodo_anno	= tb1.periodo_anno	AND	
                    tb2.tipo_imp = 	tipoImpCassa	        and
                    tb4.periodo_anno	= tb1.periodo_anno	AND	
                    tb4.tipo_imp = 	tipoImpRes		        and
                    tb1.ente_proprietario =	p_ente_prop_id						and
                  	tb2.ente_proprietario	=	tb1.ente_proprietario			and
                    tb4.ente_proprietario	=	tb1.ente_proprietario			and
                    tb1.utente				=	user_table						and
                    tb2.utente				=	tb1.utente						and
                    tb4.utente				=	tb1.utente;
                  
     RTN_MESSAGGIO:='preparazione tabella variazioni''.';  


--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate            
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          tipo_elemento.elem_det_tipo_code, 
          user_table utente,
          atto.ente_proprietario_id	,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_t_periodo 				anno_eserc ,
          siac_t_periodo              anno_importo,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id
            or r_variazione_stato.attoamm_id_varbil           =	atto.attoamm_id) 
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id  
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and 		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno	
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera 
  and     	anno_importo.anno                                   =   p_anno_competenza--anno competenza			
  and		tipologia_stato_var.variazione_stato_tipo_code		 in	('D')
  and		tipo_capitolo.elem_tipo_code						=	elemTipoCode
  and		tipo_elemento.elem_det_tipo_code					in ('STA','SCA','STR')
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id,
              tipo_elemento.elem_det_tipo_code, 
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno	  ;       
else --specificati i numeri di variazione.
	strQuery:='
	insert into siac_rep_var_entrate 
    select	dettaglio_variazione.elem_id,
		sum(dettaglio_variazione.elem_det_importo),
        tipo_elemento.elem_det_tipo_code, 
        '''||user_table||''' utente,
        testata_variazione.ente_proprietario_id	,
        anno_importo.anno	      	
from 	siac_r_variazione_stato		r_variazione_stato,
        siac_t_variazione 			testata_variazione,
        siac_d_variazione_tipo		tipologia_variazione,
        siac_d_variazione_stato 	tipologia_stato_var,
        siac_t_bil_elem_det_var 	dettaglio_variazione,
        siac_t_bil_elem				capitolo,
        siac_d_bil_elem_tipo 		tipo_capitolo,
        siac_d_bil_elem_det_tipo	tipo_elemento,
        siac_t_periodo 				anno_eserc ,
        siac_t_periodo              anno_importo,
        siac_t_bil                  bilancio  
where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id										
and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id					
and     anno_eserc.periodo_id                               = bilancio.periodo_id
and     testata_variazione.bil_id                           = bilancio.bil_id 
and     capitolo.bil_id                                     = bilancio.bil_id  
and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
and		dettaglio_variazione.elem_id						=	capitolo.elem_id
and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
and 	testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
and		anno_eserc.anno										= 	'''||p_anno||'''
and 	testata_variazione.variazione_num					in ('||p_ele_variazioni||')
and     anno_importo.anno                                   =   '''||p_anno_competenza||'''	--anno variazione				
and		tipologia_stato_var.variazione_stato_tipo_code		 in	(''D'')
and		tipo_capitolo.elem_tipo_code						=	'''||elemTipoCode||'''
and		tipo_elemento.elem_det_tipo_code					in (''STA'',''SCA'',''STR'')
and		r_variazione_stato.data_cancellazione		is null
and		testata_variazione.data_cancellazione		is null
and		tipologia_variazione.data_cancellazione		is null
and		tipologia_stato_var.data_cancellazione		is null
and 	dettaglio_variazione.data_cancellazione		is null
and 	capitolo.data_cancellazione					is null
and		tipo_capitolo.data_cancellazione			is null
and		tipo_elemento.data_cancellazione			is null
group by 	dettaglio_variazione.elem_id,
        	tipo_elemento.elem_det_tipo_code, 
        	utente,
        	testata_variazione.ente_proprietario_id,
            anno_importo.anno	  ';
raise notice 'query: %', strQuery;      

execute  strQuery;     
end if;                   


    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

--/13/02/2017 : e'  rimasto solo il filtro su anno_competenza
insert into siac_rep_var_entrate_riga
select  tb0.elem_id,
     
		tb1.importo   as 		variazione_aumento_stanziato,
        tb2.importo   as 		variazione_diminuzione_stanziato,
        tb3.importo   as 		variazione_aumento_cassa,
        tb4.importo   as 		variazione_diminuzione_cassa,
        tb5.importo   as 		variazione_aumento_residuo,
        tb6.importo   as 		variazione_diminuzione_residuo,
        user_table utente,
        p_ente_prop_id,
        p_anno_competenza
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
     	and tb1.tipologia  	= 'STA'	AND	tb1.importo > 0	
        and tb1.periodo_anno=p_anno_competenza
        and tb1.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	and tb2.tipologia  	= 'STA'	AND	tb2.importo < 0	
        and tb2.periodo_anno=p_anno_competenza
        and tb2.utente = tb0.utente )
    left join siac_rep_var_entrate tb3
     on (tb3.elem_id		=	tb0.elem_id	
     	and tb3.tipologia  	= 'SCA'	AND	tb3.importo > 0	
        and tb3.periodo_anno=p_anno_competenza
        and tb3.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb4
    on (tb4.elem_id		=	tb0.elem_id
     	and tb4.tipologia  	= 'SCA'	AND	tb4.importo < 0	
        and tb4.periodo_anno=p_anno_competenza
        and tb4.utente = tb0.utente )
    left join siac_rep_var_entrate tb5
     on (tb5.elem_id		=	tb0.elem_id	
     	and tb5.tipologia  	= 'STR'	AND	tb5.importo > 0	
        and tb5.periodo_anno=p_anno_competenza
        and tb5.utente = tb0.utente ) 
    left join siac_rep_var_entrate tb6
    on (tb6.elem_id		=	tb0.elem_id
     	and tb6.tipologia  	= 'STR'	AND	tb6.importo < 0
        and tb6.periodo_anno=p_anno_competenza
        and tb6.utente = tb0.utente 	);
 
        
     RTN_MESSAGGIO:='preparazione file output ''.';          
  
/* 20/05/2016: aggiunto il controllo se il capitolo ha subito delle variazioni, tramite
	il test su siac_rep_var_entrate_riga x, siac_rep_cap_eg y, siac_r_class_fam_tree z
*/
for classifBilRec in
select 	v1.classif_tipo_desc1    		titoloe_TIPO_DESC,
       	v1.titolo_id              		titoloe_ID,
       	v1.titolo_code             		titoloe_CODE,
       	v1.titolo_desc             		titoloe_DESC,
       	v1.classif_tipo_desc2  			tipologia_TIPO_DESC,
       	v1.tipologia_id              	tipologia_ID,
       	v1.tipologia_code            	tipologia_CODE,
       	v1.tipologia_desc            	tipologia_DESC,
       	v1.classif_tipo_desc3     		categoria_TIPO_DESC,
      	v1.categoria_id              	categoria_ID,
       	v1.categoria_code            	categoria_CODE,
       	v1.categoria_desc            	categoria_DESC,
    	tb.anno_bilancio    			BIL_ANNO,
       	tb.elem_code     				BIL_ELE_CODE,
       	tb.elem_desc     				BIL_ELE_DESC,
       	tb.elem_code2     				BIL_ELE_CODE2,
       	tb.elem_desc2     				BIL_ELE_DESC2,
       	tb.elem_id      				BIL_ELE_ID,
       	tb.elem_id_padre    			BIL_ELE_ID_PADRE,
        COALESCE (tb1.previsioni_definitive_comp,0)					stanziamento,
    	COALESCE (tb1.previsioni_definitive_cassa,0)			cassa,
        COALESCE (tb1.residui_attivi,0)				residuo,
	   	COALESCE (tb2.variazione_aumento_stanziato,0)			variazione_aumento_stanziato,
		COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)		variazione_diminuzione_stanziato,
    	COALESCE (tb2.variazione_aumento_cassa,0)				variazione_aumento_cassa,
   	 	COALESCE (tb2.variazione_diminuzione_cassa* -1,0)			variazione_diminuzione_cassa,
        COALESCE (tb2.variazione_aumento_residuo,0)				variazione_aumento_residuo,
   	 	COALESCE (tb2.variazione_diminuzione_residuo * -1,0)	variazione_diminuzione_residuo,
        tb1.periodo_anno  anno_riferimento
from  	siac_rep_tit_tip_cat_riga_anni v1
			  join siac_rep_cap_eg tb
           on    	(v1.categoria_id = tb.classif_id    
           			and v1.ente_proprietario_id=p_ente_prop_id
					and	tb.ente_proprietario_id	=v1.ente_proprietario_id
					AND TB.utente=V1.utente
                    and v1.utente=user_table)
            left	join    siac_rep_cap_eg_imp_riga tb1  
            on (tb1.elem_id	=	tb.elem_id 
            		AND tb.utente=tb1.utente
                    and tb.utente=user_table)
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table
                    and tb2.periodo_anno=tb1.periodo_anno) 
    where v1.utente = user_table
   and exists ( select 1 from siac_rep_var_entrate_riga x, siac_rep_cap_eg y, 
                                siac_r_class_fam_tree z
                where x.elem_id= y.elem_id
                 and x.utente=user_table
                 and y.utente=user_table
                 and y.classif_id = z.classif_id
                 and z.classif_id_padre = v1.tipologia_id)	
			order by titoloe_CODE,tipologia_CODE,categoria_CODE
loop



---titoloe_tipo_code := classifBilRec.titoloe_tipo_code;
titoloe_TIPO_DESC := classifBilRec.titoloe_TIPO_DESC;
titoloe_CODE := classifBilRec.titoloe_CODE;
titoloe_DESC := classifBilRec.titoloe_DESC;
--------tipologia_tipo_code := classifBilRec.tipologia_tipo_code;
tipologia_tipo_desc := classifBilRec.tipologia_tipo_desc;
tipologia_code := classifBilRec.tipologia_code;
tipologia_desc := classifBilRec.tipologia_desc;
-------categoria_tipo_code := classifBilRec.categoria_tipo_code;
categoria_tipo_desc := classifBilRec.categoria_tipo_desc;
categoria_code := classifBilRec.categoria_code;
categoria_desc := classifBilRec.categoria_desc;
bil_anno:=classifBilRec.bil_anno;
bil_ele_code:=classifBilRec.bil_ele_code;
bil_ele_desc:=classifBilRec.bil_ele_desc;
bil_ele_code2:=classifBilRec.bil_ele_code2;
bil_ele_desc2:=classifBilRec.bil_ele_desc2;
bil_ele_id:=classifBilRec.bil_ele_id;
bil_ele_id_padre:=classifBilRec.bil_ele_id_padre;

--SIAC-8687: 11/04/2022.
--L'importo di stanziamento, cassa e residuo deve essere quello prima 
-- della modifica, quindi dal totale calcolato escludo l'importo della
--modifica.
--stanziamento:=classifBilRec.stanziamento;
--cassa:=classifBilRec.cassa;
--residuo:=classifBilRec.residuo;
variazione_aumento_stanziato:=classifBilRec.variazione_aumento_stanziato;
variazione_diminuzione_stanziato:=classifBilRec.variazione_diminuzione_stanziato;
variazione_aumento_cassa:=classifBilRec.variazione_aumento_cassa;
variazione_diminuzione_cassa:=classifBilRec.variazione_diminuzione_cassa;
variazione_aumento_residuo:=classifBilRec.variazione_aumento_residuo;
variazione_diminuzione_residuo:=classifBilRec.variazione_diminuzione_residuo;
anno_riferimento:=classifBilRec.anno_riferimento;

--INC000006082542 Correggere anche spese
stanziamento:=classifBilRec.stanziamento-variazione_aumento_stanziato+
	variazione_diminuzione_stanziato;
cassa:=classifBilRec.cassa-variazione_aumento_cassa + 
	variazione_diminuzione_cassa;
residuo:=classifBilRec.residuo - variazione_aumento_residuo +
	variazione_diminuzione_residuo;
    
return next;

bil_anno='';
titoloe_tipo_code='';
titoloe_TIPO_DESC='';
titoloe_CODE='';
titoloe_DESC='';
tipologia_tipo_code='';
tipologia_tipo_desc='';
tipologia_code='';
tipologia_desc='';
categoria_tipo_code='';
categoria_tipo_desc='';
categoria_code='';
categoria_desc='';
bil_ele_code='';
bil_ele_desc='';
bil_ele_code2='';
bil_ele_desc2='';
bil_ele_id=0;
bil_ele_id_padre=0;
stanziamento=0;
cassa=0;
residuo=0;
variazione_aumento_stanziato=0;
variazione_diminuzione_stanziato=0;
variazione_aumento_cassa=0;
variazione_diminuzione_cassa=0;
variazione_aumento_residuo=0;
variazione_diminuzione_residuo=0;
anno_riferimento='';
end loop;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;

delete from siac_rep_cap_eg where utente=user_table;

delete from siac_rep_cap_eg_imp where utente=user_table;

delete from siac_rep_cap_eg_imp_riga where utente=user_table;

delete from	siac_rep_var_entrate	where utente=user_table;

delete from siac_rep_var_entrate_riga where utente=user_table; 


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;           
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_ent" (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar)
  OWNER TO siac;

--SIAC-8687 - Maurizio - FINE
  
  
--SIAC-8688 - Maurizio - INIZIO

CREATE OR REPLACE FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_variab" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_delibera integer,
  p_anno_delibera varchar,
  p_tipo_delibera varchar,
  p_anno_competenza varchar,
  p_ele_variazioni varchar
)
RETURNS TABLE (
  id_capitolo integer,
  tipologia_capitolo varchar,
  stanziato numeric,
  variazione_aumento numeric,
  variazione_diminuzione numeric,
  anno_riferimento varchar,
  display_error varchar
) AS
$body$
DECLARE

/* 02/07/2021 SIAC-8152.
	Funzione copia della BILR227_Allegato_7_delibera_variazione_variabili_bozza_Prev
    per il nuovo report BILR257 che differisce dal BILR227 per il fatto 
    che le variazioni estratte sono in stato DEFINITIVO.
*/

classifBilRec record;


annoCapImp varchar;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
h_count integer :=0;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
fase_bilancio varchar;
strApp varchar;
intApp numeric;
contaParametri integer;
contaParametriParz integer;
strQuery varchar;
tipoFci varchar;

BEGIN

annoCapImp:= p_anno; 

tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFci='FCI';

-- 04/04/2019: il report funziona solo per la previsione
elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione

id_capitolo=0;
tipologia_capitolo='';
stanziato=0;
variazione_aumento=0;
variazione_diminuzione=0;
anno_riferimento='';
display_error:='';

-- se e' presente il parametro con l'elenco delle variazioni verifico che abbia
-- solo dei numeri oltre le virgole.
IF p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '' THEN
  strApp=REPLACE(p_ele_variazioni,',','');
  raise notice 'VAR: %', strApp;
 intApp = strApp::numeric;
END IF;

contaParametriParz:=0;
contaParametri:=0;

if p_numero_delibera IS NOT NULL THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_anno_delibera IS NOT NULL AND p_anno_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;
if p_tipo_delibera IS NOT NULL AND p_tipo_delibera <> '' THEN
	contaParametriParz := contaParametriParz +1;
end if;

if contaParametriParz = 1 OR contaParametriParz = 2 then
	display_error:= 'ERRORE NEI PARAMETRI: Specificare tutti i dati relativi al parametro ''Provvedimento di variazione''';
    return next;
    return;
elsif contaParametriParz = 3 THEN -- parametro corretto
	contaParametri := contaParametri + 1;
end if;

contaParametriParz:=0;

if (p_ele_variazioni IS NOT NULL AND p_ele_variazioni <> '') THEN
	contaParametri := contaParametri + 1;
end if;


if contaParametri = 0 THEN
	display_error:= 'ERRORE NEI PARAMETRI: Specificare un parametro tra ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
elsif contaParametri = 2 THEN    
	display_error:= 'ERRORE NEI PARAMETRI: Specificare uno solo tra i parametri ''Provvedimento di variazione'' e ''Elenco delle variazioni''';
    return next;
    return;	
end if;


select fnc_siac_random_user()
into	user_table;

 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep''.';  

insert into siac_rep_cap_eg
select null,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_t_bil_elem e,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	in (elemTipoCodeE,elemTipoCodeS)
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
--28/06/2021 SIAC-8139
--Aggiunto tipoFci
and	cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
	tipoFpvcc,tipoFpvsc,tipoFci)
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null;


 RTN_MESSAGGIO:='insert tabella siac_rep_cap_ep_imp''.';  

insert into siac_rep_cap_eg_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
            cat_del_capitolo.elem_cat_code			tipo_imp,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
            sum(capitolo_importi.elem_det_importo)     
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
            siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
        and	anno_eserc.anno						= 	p_anno 												
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        --and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        --and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		-- INC000001570761 and	stato_capitolo.elem_stato_code		=	'VA'	
        and	stato_capitolo.elem_stato_code		in ('VA', 'PR')
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
            --28/06/2021 SIAC-8139
            --Aggiunto tipoFci      
  --SIAC-8322 30/08/2021.
  -- Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  -- quello stanziato.            
		--and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFci)	
        and	((cat_del_capitolo.elem_cat_code in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,
        			tipoFpvsc)  	 
               and	capitolo_imp_tipo.elem_det_tipo_code	in('STA')) OR
             (cat_del_capitolo.elem_cat_code in (tipoFci) 
              and capitolo_imp_tipo.elem_det_tipo_code	in('SCA')))                    		
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
    group by capitolo_importi.elem_id,cat_del_capitolo.elem_cat_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente;
   
     RTN_MESSAGGIO:='preparazione tabella importi variazioni ''.';  

            
--SIAC-6163: 16/05/2018.
-- la query cambia a seconda del tipo parametro: atto/numeri di variazioni.
if p_numero_delibera IS NOT NULL THEN
  insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
  select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo), -- 30.08.2017 siac-5203 Sofia - aggiunto sum
          --------cat_del_capitolo.elem_cat_code,     -- 30.08.2017 siac-5203 Sofia - commentato
          user_table utente,
          atto.ente_proprietario_id,
          anno_importo.anno	      	
  from 	siac_t_atto_amm 			atto,
          siac_d_atto_amm_tipo		tipo_atto,
          siac_r_atto_amm_stato 		r_atto_stato,
          siac_d_atto_amm_stato 		stato_atto,
          siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	atto.attoamm_tipo_id								=	tipo_atto.attoamm_tipo_id
  and		r_atto_stato.attoamm_id								=	atto.attoamm_id
  and		r_atto_stato.attoamm_stato_id						=	stato_atto.attoamm_stato_id
  and		( r_variazione_stato.attoamm_id						=	atto.attoamm_id or
            r_variazione_stato.attoamm_id_varbil				=	atto.attoamm_id)
  and		r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		atto.ente_proprietario_id 							= 	p_ente_prop_id
  and		anno_eserc.anno										= 	p_anno 		
  and		atto.attoamm_numero 								= 	p_numero_delibera
  and		atto.attoamm_anno									=	p_anno_delibera
  and		tipo_atto.attoamm_tipo_code							=	p_tipo_delibera
  and		tipologia_stato_var.variazione_stato_tipo_code		in	('D')										
  and     anno_importo.anno                                   =   p_anno_competenza					
  and		tipo_capitolo.elem_tipo_code						in (elemTipoCodeE,elemTipoCodeS)
--SIAC-8322 30/08/2021.
-- Per i capitoli di tipo FCI deve essere preso l'importo di cassa e non
  -- quello stanziato. 
 --and		tipo_elemento.elem_det_tipo_code					= 'STA'
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci  
 -- and		cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
 -- 		tipoFpvcc,tipoFpvsc,tipoFci)	
 and ((cat_del_capitolo.elem_cat_code	in (tipoAvanzo,tipoDisavanzo,
  											tipoFpvcc,tipoFpvsc)
       and	tipo_elemento.elem_det_tipo_code					= 'STA') OR
        (cat_del_capitolo.elem_cat_code	in (tipoFci)
         and tipo_elemento.elem_det_tipo_code					= 'SCA')) 
  and		atto.data_cancellazione						is null
  and		tipo_atto.data_cancellazione				is null
  and		r_atto_stato.data_cancellazione				is null
  and		stato_atto.data_cancellazione				is null
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, -- -- 30.08.2017 siac-5203 Sofia aggiunto group by per sum
              utente,
              atto.ente_proprietario_id,
              anno_importo.anno;
else
	strQuery:='
    	insert into siac_rep_var_entrate
	(elem_id, importo, utente, ente_proprietario, periodo_anno)
          select	dettaglio_variazione.elem_id,
          sum(dettaglio_variazione.elem_det_importo),
          '''||user_table||''' utente,
          testata_variazione.ente_proprietario_id,
          anno_importo.anno	      	
  from 	siac_r_variazione_stato		r_variazione_stato,
          siac_t_variazione 			testata_variazione,
          siac_d_variazione_tipo		tipologia_variazione,
          siac_d_variazione_stato 	tipologia_stato_var,
          siac_t_bil_elem_det_var 	dettaglio_variazione,
          siac_t_bil_elem				capitolo,
          siac_d_bil_elem_tipo 		tipo_capitolo,
          siac_d_bil_elem_det_tipo	tipo_elemento,
          siac_d_bil_elem_categoria 	cat_del_capitolo, 
          siac_r_bil_elem_categoria 	r_cat_capitolo,
          siac_t_periodo 				anno_eserc,
          siac_t_periodo              anno_importo ,
          siac_t_bil                  bilancio  
  where 	r_variazione_stato.variazione_id					=	testata_variazione.variazione_id
  and		testata_variazione.variazione_tipo_id				=	tipologia_variazione.variazione_tipo_id	
  and		anno_importo.periodo_id 							=	dettaglio_variazione.periodo_id			
  and     anno_eserc.periodo_id                               = bilancio.periodo_id
  and     testata_variazione.bil_id                           = bilancio.bil_id 
  and     capitolo.bil_id                                     = bilancio.bil_id 
  and 	tipologia_stato_var.variazione_stato_tipo_id		=	r_variazione_stato.variazione_stato_tipo_id
  and		r_variazione_stato.variazione_stato_id				=	dettaglio_variazione.variazione_stato_id
  and		dettaglio_variazione.elem_id						=	capitolo.elem_id
  and		capitolo.elem_tipo_id								=	tipo_capitolo.elem_tipo_id
  and		dettaglio_variazione.elem_det_tipo_id				=	tipo_elemento.elem_det_tipo_id
  and		capitolo.elem_id									=	r_cat_capitolo.elem_id
  and		r_cat_capitolo.elem_cat_id							=	cat_del_capitolo.elem_cat_id
  and		testata_variazione.ente_proprietario_id 			= 	'||p_ente_prop_id||'
  and 	testata_variazione.variazione_num 						in   ('||p_ele_variazioni||')
  and		anno_eserc.anno										= 	'''||p_anno||''' 		
  and		tipologia_stato_var.variazione_stato_tipo_code		in	(''D'')										
  and     anno_importo.anno                                   =   '''||p_anno_competenza||'''					
  and		tipo_capitolo.elem_tipo_code						in ('''||elemTipoCodeE||''','''||elemTipoCodeS||''')
  and		tipo_elemento.elem_det_tipo_code					= ''STA''
    --28/06/2021 SIAC-8139
    --Aggiunto tipoFci    
--SIAC-8322 30/08/2021.    
-- Per i capitoli di tipo FCI deve essere preso l''importo di cassa e non
  -- quello stanziato.    
  --and		cat_del_capitolo.elem_cat_code						in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''','''||tipoFci||''')	
and	((cat_del_capitolo.elem_cat_code in ('''||tipoAvanzo||''','''||tipoDisavanzo||''','''||tipoFpvcc||''','''||tipoFpvsc||''')
          and tipo_elemento.elem_det_tipo_code					= ''STA'') OR
         (cat_del_capitolo.elem_cat_code in ('''||tipoFci||''') 
          and tipo_elemento.elem_det_tipo_code					= ''SCA'')) 
  and		r_variazione_stato.data_cancellazione		is null
  and		testata_variazione.data_cancellazione		is null
  and		tipologia_variazione.data_cancellazione		is null
  and		tipologia_stato_var.data_cancellazione		is null
  and 	dettaglio_variazione.data_cancellazione		is null
  and 	capitolo.data_cancellazione					is null
  and		tipo_capitolo.data_cancellazione			is null
  and		tipo_elemento.data_cancellazione			is null
  and		cat_del_capitolo.data_cancellazione			is null 
  and     r_cat_capitolo.data_cancellazione			is null
  group by 	dettaglio_variazione.elem_id, 
              utente,
              testata_variazione.ente_proprietario_id,
              anno_importo.anno'; 

raise notice 'strQuery = %', strQuery;

execute strQuery;                    
end if;                  	                          
    
     RTN_MESSAGGIO:='preparazione tabella variazioni riga  ''.';  

insert into siac_rep_var_entrate_riga
select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        p_anno
from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=p_anno
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =p_anno 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 1)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 1)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 1)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
  union 
  select  tb0.elem_id,       
		tb1.importo        as 		variazione_aumento_stanziato,
        tb2.importo        as 		variazione_diminuzione_stanziato,
        0,
        0,
        0,
        0,
        user_table utente,
        p_ente_prop_id,
        (p_anno::INTEGER + 2)::varchar
    from   
	siac_rep_cap_eg tb0 
    left join siac_rep_var_entrate tb1
     on (tb1.elem_id		=	tb0.elem_id	
        --and tb1.tipologia  	= 'STA'	
        and 	tb1.importo > 0	
        and     tb1.periodo_anno=(p_anno::INTEGER + 2)::varchar
        and     tb1.utente = tb0.utente
         ) 
    left join siac_rep_var_entrate tb2
    on (tb2.elem_id		=	tb0.elem_id
     	--and tb2.tipologia  	= 'STA'	
        AND	tb2.importo < 0	
        and tb2.periodo_anno =(p_anno::INTEGER + 2)::varchar 
         and     tb2.utente = tb0.utente)
    where  tb0.utente = user_table 
     ;

     RTN_MESSAGGIO:='preparazione file output ''.';          

for classifBilRec in
select 	tb1.elem_id   		 											id_capitolo,
       	tb1.tipo_imp    												tipologia_capitolo,
       	tb1.importo     												stanziato,
       	COALESCE (tb2.variazione_aumento_stanziato,0)     				variazione_aumento,
       	COALESCE (tb2.variazione_diminuzione_stanziato* -1,0)			variazione_diminuzione,
        tb1.periodo_anno                                                anno_riferimento          
from  	siac_rep_cap_eg_imp tb1  
            left	join    siac_rep_var_entrate_riga tb2  
            on (tb2.elem_id	=	tb1.elem_id
                    and tb1.periodo_anno=tb2.periodo_anno
            		AND tb2.utente=tb1.utente
                    and tb1.utente=user_table) 
    where tb1.utente = user_table

loop

id_capitolo := classifBilRec.id_capitolo;
tipologia_capitolo := classifBilRec.tipologia_capitolo;
stanziato := classifBilRec.stanziato;

variazione_aumento := classifBilRec.variazione_aumento;
variazione_diminuzione := classifBilRec.variazione_diminuzione;
anno_riferimento := classifBilRec.anno_riferimento;

return next;

end loop;

--SIAC-8688: 11/04/2022.
--C'era un return next di troppo.
--return next;

delete from siac_rep_tit_tip_cat_riga_anni where utente=user_table;
delete from siac_rep_cap_eg where utente=user_table;
delete from siac_rep_cap_eg_imp where utente=user_table;
delete from siac_rep_cap_eg_imp_riga where utente=user_table;
delete from	siac_rep_var_entrate	where utente=user_table;
delete from siac_rep_var_entrate_riga where utente=user_table; 



raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
		return;
    when syntax_error THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;
    when invalid_text_representation THEN
    	display_error='ERRORE DI SINTASSI NEI PARAMETRI: '|| SQLERRM|| ' - Verificare se sono stati inseriti caratteri alfabetici oltre la virgola.';
    	return next;
    	return;                  
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR256_Allegato_8_delibera_variazione_definitive_Prev_variab" (p_ente_prop_id integer, p_anno varchar, p_numero_delibera integer, p_anno_delibera varchar, p_tipo_delibera varchar, p_anno_competenza varchar, p_ele_variazioni varchar)
  OWNER TO siac;
  
--SIAC-8688 - Maurizio - FINE


--SIAC-8696 e SIAC-8698 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR258_rend_gest_costi_missione_all_h_cont_gen"(p_ente_prop_id integer, p_anno varchar);

CREATE OR REPLACE FUNCTION siac."BILR258_rend_gest_costi_missione_all_h_cont_gen" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  code_missione varchar,
  desc_missione varchar,
  codice_codifica varchar,
  descrizione_codifica varchar,
  codice_codifica_albero varchar,
  livello_codifica integer,
  importo_dare numeric,
  importo_avere numeric,
  elem_id integer,
  collegamento_tipo_code varchar,
  tipo_prima_nota varchar,
  pnota_id integer,
  campo_pk_id integer,
  campo_pk_id_2 integer
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
idBilancio integer;
anno_bil_int integer;

BEGIN


/* 16/12/2021 - SIAC-8238.
	Funzione creata per il report BILR258 per la SIAC-8238.
    Questo report sistituisce a partire dal 2021 il report di rendiconto BILR166
    che rimane per gli anni precedenti.
    Rispetto al BILR166 i dati sono presi dalle scritture contabili (prime note)
    invece che dalla contabilita' finanziaria (capitoli).
    I dati estratti corrispondono esattamente a quelli del report BILR125 dove pero' 
    non sono raggruppati per missione.
    Per poter raggruppare per missione e' necessario passare dai capitoli che sono
    estratti partendo dalle prime note ed i relativi eventi differenti a seconda
    dell'entita' coinvolta (impegni, accertamenti, liquidazioni, modifiche...).

*/

code_missione:='';
desc_missione:='';
codice_codifica:='';
descrizione_codifica:='';
codice_codifica_albero:='';
livello_codifica:=0;
importo_dare:=0;
importo_avere:=0;
elem_id:=0;
collegamento_tipo_code:='';

anno_competenza_int=p_anno ::INTEGER;

anno_bil_int:=p_anno::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
-- leggo l'ID del bilancio x velocizzare.
 select a.bil_id
 into idBilancio
 from siac_t_bil a, siac_t_periodo b
 where a.periodo_id=b.periodo_id
 and a.ente_proprietario_id =p_ente_prop_id
 and b.anno = p_anno
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;
 

return query 
--SIAC-8698 21/04/2022.
--Devo estrarre con distinct senza estrarre l'elem_id perche' ci sono prime
--note di un anno bilancio collegate a capitoli sia dell'anno corrente che
--dell'anno successivi; in questo caso l'importo della prima nota
--veniva duplicato.
--Inoltre aggiungo anche campo_pk_id, campo_pk_id_2 nella query per essere
--certo di non escludere a causa del distinct le registrazioni che hanno
--2 importi uguali. 
select distinct
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.code_miss_lib,'')::varchar
   else 
   		COALESCE(missioni.code_missione,'')::varchar end code_missione,
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.desc_miss_lib,'')::varchar
   else
   		COALESCE(missioni.desc_missione,'')::varchar end desc_missione,
   COALESCE(query_totale.codice_codifica,'') codice_codifica,
   COALESCE(query_totale.descrizione_codifica,'') descrizione_codifica,
   COALESCE(query_totale.codice_codifica_albero,'') codice_codifica_albero,
   COALESCE(query_totale.livello_codifica,0) livello_codifica,
   COALESCE(query_totale.importo_dare,0) importo_dare,
   COALESCE(query_totale.importo_avere,0) importo_avere,
   --SIAC-8698 21/04/2022. Non estraggo il capitolo.
   0::integer elem_id,--COALESCE(query_totale.elem_id,0) elem_id,
   COALESCE(query_totale.collegamento_tipo_code,'') collegamento_tipo_code,
   COALESCE(query_totale.causale_ep_tipo_code,'') tipo_prima_nota,
   query_totale.pnota_id,
   --SIAC-8698 21/04/2022. Aggiungo questi campi
   query_totale.campo_pk_id, query_totale.campo_pk_id_2
   	from (
    	--Estraggo i capitoli di spesa gestione e i relativi dati di struttura
        --per poter avere le missioni.
	with capitoli as(
  select distinct programma.classif_id programma_id,
          macroaggr.classif_id macroaggregato_id,          
          capitolo.elem_id
  from siac_d_class_tipo programma_tipo,
       siac_t_class programma,
       siac_d_class_tipo macroaggr_tipo,
       siac_t_class macroaggr,
       siac_t_bil_elem capitolo,
       siac_d_bil_elem_tipo tipo_elemento,
       siac_r_bil_elem_class r_capitolo_programma,
       siac_r_bil_elem_class r_capitolo_macroaggr, 
       siac_d_bil_elem_stato stato_capitolo, 
       siac_r_bil_elem_stato r_capitolo_stato,
       siac_d_bil_elem_categoria cat_del_capitolo,
       siac_r_bil_elem_categoria r_cat_capitolo 
  where 	
      programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
      and	programma.classif_id=r_capitolo_programma.classif_id			    
      and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
      and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
      and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
      and	capitolo.elem_id=r_capitolo_programma.elem_id					
      and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
      and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
      and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
      and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	   	
      and	capitolo.ente_proprietario_id=p_ente_prop_id 	
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.				
      --and	capitolo.bil_id = idBilancio										 
      and	programma_tipo.classif_tipo_code='PROGRAMMA'							
      and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
      and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
      and	stato_capitolo.elem_stato_code	=	'VA'						     							
      and	programma_tipo.data_cancellazione 			is null
      and	programma.data_cancellazione 				is null
      and	macroaggr_tipo.data_cancellazione 			is null
      and	macroaggr.data_cancellazione 				is null
      and	capitolo.data_cancellazione 				is null
      and	tipo_elemento.data_cancellazione 			is null
      and	r_capitolo_programma.data_cancellazione 	is null
      and	r_capitolo_macroaggr.data_cancellazione 	is null 
      and	stato_capitolo.data_cancellazione 			is null 
      and	r_capitolo_stato.data_cancellazione 		is null
      and	cat_del_capitolo.data_cancellazione 		is null
      and	r_cat_capitolo.data_cancellazione 			is null),
   strut_bilancio as(
        select *
        from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')) 
  select COALESCE(strut_bilancio.missione_code,'') code_missione,
    COALESCE(strut_bilancio.missione_desc,'') desc_missione,
    capitoli.elem_id
  from capitoli  
    full JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
  ) missioni 
  --devo estrarre con full join perche' nella query seguente ci sono anche le
  --prime note libere che non hanno il collegamento con i capitoli.
  full join  (     
  	--Estraggo i dati dei classificatori.
    --Questa parte della query e' la stessa del report BILR125.
        with classificatori as (
  SELECT classif_tot.classif_code AS codice_codifica, 
         classif_tot.classif_desc AS descrizione_codifica,
         classif_tot.ordine AS codice_codifica_albero, 
         case when classif_tot.ordine='E.26' then 3 
         	else classif_tot.level end livello_codifica,
         classif_tot.classif_id
  FROM (
      SELECT tb.classif_classif_fam_tree_id,
             tb.classif_fam_tree_id, t1.classif_code,
             t1.classif_desc, ti1.classif_tipo_code,
             tb.classif_id, tb.classif_id_padre,
             tb.ente_proprietario_id, 
             CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
             ELSE tb.ordine
             END  ordine,
             tb.level,
             tb.arrhierarchy
      FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                   classif_fam_tree_id, 
                                   classif_id, 
                                   classif_id_padre, 
                                   ente_proprietario_id, 
                                   ordine, 
                                   livello, 
                                   level, arrhierarchy) AS (
             SELECT rt1.classif_classif_fam_tree_id,
                    rt1.classif_fam_tree_id,
                    rt1.classif_id,
                    rt1.classif_id_padre,
                    rt1.ente_proprietario_id,
                    rt1.ordine,
                    rt1.livello, 1,
                    ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
             FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf, siac_t_class c
             WHERE cf.classif_fam_id = tt1.classif_fam_id 
             and c.classif_id=rt1.classif_id
             AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
             AND rt1.classif_id_padre IS NULL 
             AND   (cf.classif_fam_code = '00020')-- OR cf.classif_fam_code = v_classificatori1)
             AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
             AND anno_bil_int BETWEEN date_part('year',tt1.validita_inizio) AND 
             date_part('year',COALESCE(tt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',rt1.validita_inizio) AND 
             date_part('year',COALESCE(rt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',c.validita_inizio) AND 
             date_part('year',COALESCE(c.validita_fine,now())) 
             AND tt1.ente_proprietario_id = p_ente_prop_id
             UNION ALL
             SELECT tn.classif_classif_fam_tree_id,
                    tn.classif_fam_tree_id,
                    tn.classif_id,
                    tn.classif_id_padre,
                    tn.ente_proprietario_id,
                    tn.ordine,
                    tn.livello,
                    tp.level + 1,
                    tp.arrhierarchy || tn.classif_id
          FROM rqname tp, siac_r_class_fam_tree tn,siac_t_class c2
          WHERE tp.classif_id = tn.classif_id_padre 
          and c2.classif_id=tn.classif_id
          AND tn.ente_proprietario_id = tp.ente_proprietario_id
          AND anno_bil_int BETWEEN date_part('year',tn.validita_inizio) AND 
             date_part('year',COALESCE(tn.validita_fine,now())) 
  AND anno_bil_int BETWEEN date_part('year',c2.validita_inizio) AND 
             date_part('year',COALESCE(c2.validita_fine,now()))            
          )
          SELECT rqname.classif_classif_fam_tree_id,
                 rqname.classif_fam_tree_id,
                 rqname.classif_id,
                 rqname.classif_id_padre,
                 rqname.ente_proprietario_id,
                 rqname.ordine, rqname.livello,
                 rqname.level,
                 rqname.arrhierarchy
          FROM rqname
          ORDER BY rqname.arrhierarchy
          ) tb,
          siac_t_class t1, siac_d_class_tipo ti1
      WHERE t1.classif_id = tb.classif_id 
      AND ti1.classif_tipo_id = t1.classif_tipo_id 
      AND t1.ente_proprietario_id = tb.ente_proprietario_id 
      AND ti1.ente_proprietario_id = t1.ente_proprietario_id
      AND anno_bil_int BETWEEN date_part('year',t1.validita_inizio) 
      AND date_part('year',COALESCE(t1.validita_fine,now()))
  ) classif_tot
  ORDER BY classif_tot.classif_tipo_code desc, classif_tot.ordine),
pdce as(  
	--Estraggo le prime note collegate ai classificatori ed anche i relativi ID
    --degli eventi coinvolti per poterli poi collegare ai capitoli.
SELECT r_pdce_conto_class.classif_id,
		d_pdce_fam.pdce_fam_code, t_mov_ep_det.movep_det_segno, 
        d_coll_tipo.collegamento_tipo_code,
        r_ev_reg_movfin.campo_pk_id, r_ev_reg_movfin.campo_pk_id_2,
        COALESCE(t_mov_ep_det.movep_det_importo,0) importo,
         t_mov_ep_det.movep_det_id,d_caus_tipo.causale_ep_tipo_code,
         t_prima_nota.pnota_id         
    FROM  siac_r_pdce_conto_class r_pdce_conto_class
    INNER JOIN siac_t_pdce_conto pdce_conto 
    	ON r_pdce_conto_class.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree t_pdce_fam_tree 
    	ON pdce_conto.pdce_fam_tree_id = t_pdce_fam_tree.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d_pdce_fam 
    	ON t_pdce_fam_tree.pdce_fam_id = d_pdce_fam.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det t_mov_ep_det 
    	ON t_mov_ep_det.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_mov_ep t_mov_ep 
    	ON t_mov_ep_det.movep_id = t_mov_ep.movep_id
    INNER JOIN siac_t_prima_nota t_prima_nota 
    	ON t_mov_ep.regep_id = t_prima_nota.pnota_id    
    INNER JOIN siac_r_prima_nota_stato r_prima_nota_stato 
    	ON t_prima_nota.pnota_id = r_prima_nota_stato.pnota_id
    INNER JOIN siac_d_prima_nota_stato d_prima_nota_stato 
    	ON r_prima_nota_stato.pnota_stato_id = d_prima_nota_stato.pnota_stato_id
    --devo estrarre con left join per prendere anche le prime note libere
    --che non hanno eventi.
    LEFT JOIN siac_r_evento_reg_movfin r_ev_reg_movfin 
    	ON r_ev_reg_movfin.regmovfin_id = t_mov_ep.regmovfin_id
    LEFT JOIN siac_d_evento d_evento 
    	ON d_evento.evento_id = r_ev_reg_movfin.evento_id
    LEFT JOIN siac_d_collegamento_tipo d_coll_tipo
    	ON d_coll_tipo.collegamento_tipo_id = d_evento.collegamento_tipo_id
    inner join siac_d_causale_ep_tipo d_caus_tipo
    	on d_caus_tipo.causale_ep_tipo_id=t_prima_nota.causale_ep_tipo_id
    WHERE r_pdce_conto_class.ente_proprietario_id = p_ente_prop_id
    AND   t_prima_nota.bil_id = idBilancio 
    AND   d_prima_nota_stato.pnota_stato_code = 'D'
    AND   r_pdce_conto_class.data_cancellazione IS NULL
    AND   pdce_conto.data_cancellazione IS NULL
    AND   t_pdce_fam_tree.data_cancellazione IS NULL
    AND   d_pdce_fam.data_cancellazione IS NULL
    AND   t_mov_ep_det.data_cancellazione IS NULL
    AND   t_mov_ep.data_cancellazione IS NULL
    AND   t_prima_nota.data_cancellazione IS NULL
    AND   r_prima_nota_stato.data_cancellazione IS NULL
    AND   d_prima_nota_stato.data_cancellazione IS NULL
    AND   r_ev_reg_movfin.data_cancellazione IS NULL
    AND   d_evento.data_cancellazione IS NULL
    AND   d_coll_tipo.data_cancellazione IS NULL
    AND   anno_bil_int BETWEEN date_part('year',pdce_conto.validita_inizio) 
    		AND date_part('year',COALESCE(pdce_conto.validita_fine,now()))  
    AND  anno_bil_int BETWEEN date_part('year',r_pdce_conto_class.validita_inizio)::integer
    		AND coalesce (date_part('year',r_pdce_conto_class.validita_fine)::integer ,anno_bil_int) 
   ),
   --Di seguito tutti gli eventi da collegarsi alle prime note come quelli estratti
   --dal report BILR159.
collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND	rms.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND 	rms.ente_proprietario_id = p_ente_prop_id
  AND   dms.mod_stato_code = 'V'
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL),
  collegamento_I_A AS ( --Impegni e Accertamenti
    SELECT DISTINCT r_mov_bil_elem.elem_id, r_mov_bil_elem.movgest_id
      FROM   siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem 
      WHERE  t_bil_elem.elem_id=r_mov_bil_elem.elem_id
      AND	 r_mov_bil_elem.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	      
     -- AND 	 t_bil_elem.bil_id = idBilancio
      AND    r_mov_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_SI_SA AS ( --Subimpegni e Subaccertamenti
  SELECT DISTINCT r_mov_bil_elem.elem_id, mov_ts.movgest_ts_id
  FROM  siac_t_movgest_ts mov_ts, siac_r_movgest_bil_elem r_mov_bil_elem,
  		siac_t_bil_elem t_bil_elem 
  WHERE mov_ts.movgest_id = r_mov_bil_elem.movgest_id
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND   mov_ts.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   mov_ts.data_cancellazione IS NULL
  AND   r_mov_bil_elem.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_SS_SE AS ( --SUBDOC
  SELECT DISTINCT r_mov_bil_elem.elem_id, r_subdoc_mov_ts.subdoc_id
  FROM   siac_r_subdoc_movgest_ts r_subdoc_mov_ts, siac_t_movgest_ts mov_ts, 
  		 siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem
  WHERE  r_subdoc_mov_ts.movgest_ts_id = mov_ts.movgest_ts_id
  AND    mov_ts.movgest_id = r_mov_bil_elem.movgest_id 
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND 	 mov_ts.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND	 t_bil_elem.bil_id = idBilancio
  AND    (r_subdoc_mov_ts.data_cancellazione IS NULL OR 
  				(r_subdoc_mov_ts.data_cancellazione IS NOT NULL
  				AND r_subdoc_mov_ts.validita_fine IS NOT NULL AND
                r_subdoc_mov_ts.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
  AND    mov_ts.data_cancellazione IS NULL
  AND    r_mov_bil_elem.data_cancellazione IS NULL
  AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_OP_OI AS ( --Ordinativi di pagamento e incasso.
    SELECT DISTINCT r_ord_bil_elem.elem_id, r_ord_bil_elem.ord_id
      FROM   siac_r_ordinativo_bil_elem r_ord_bil_elem, siac_t_bil_elem t_bil_elem
      WHERE  r_ord_bil_elem.elem_id=t_bil_elem.elem_id 
      AND	 r_ord_bil_elem.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	      
      --AND	 t_bil_elem.bil_id = idBilancio  
      AND    r_ord_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_L AS ( --Liquidazioni
    SELECT DISTINCT c.elem_id, a.liq_id
      FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, 
             siac_r_movgest_bil_elem c
      WHERE  a.movgest_ts_id = b.movgest_ts_id
      AND    b.movgest_id = c.movgest_id
      AND	 b.ente_proprietario_id = p_ente_prop_id
      AND    a.data_cancellazione IS NULL
      AND    b.data_cancellazione IS NULL
      AND    c.data_cancellazione IS NULL),
  collegamento_RR AS ( --Giustificativi.
  	SELECT DISTINCT d.elem_id, a.gst_id
      FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
      WHERE a.ente_proprietario_id = p_ente_prop_id
      AND   a.ricecon_id = b.ricecon_id
      AND   b.movgest_ts_id = c.movgest_ts_id
      AND   c.movgest_id = d.movgest_id
      AND   a.data_cancellazione  IS NULL
      AND   b.data_cancellazione  IS NULL
      AND   c.data_cancellazione  IS NULL
      AND   d.data_cancellazione  IS NULL),
  collegamento_RE AS ( --Richieste economali.
  SELECT DISTINCT c.elem_id, a.ricecon_id
    FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    WHERE b.ente_proprietario_id = p_ente_prop_id
    AND   a.movgest_ts_id = b.movgest_ts_id
    AND   b.movgest_id = c.movgest_id
    AND   a.data_cancellazione  IS NULL
    AND   b.data_cancellazione  IS NULL
    AND   c.data_cancellazione  IS NULL),
  collegamento_SS_SE_NCD AS ( --Note di credito
    select c.elem_id, a.subdoc_id
    from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    where a.movgest_ts_id = b.movgest_ts_id
    AND    b.movgest_id = c.movgest_id
    AND b.ente_proprietario_id = p_ente_prop_id
    AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
                  AND a.validita_fine IS NOT NULL AND
                  a.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL),      
--estraggo la missione collegata a siac_r_mov_ep_det_class per le 
--prime note libere.    
ele_prime_note_lib_miss as (
  	select t_class.classif_code code_miss_lib,
    t_class.classif_desc desc_miss_lib,
     r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        	--SIAC-8696 19/04/2022.
            --Era rimasto l'ide ente 3 invece che la variabile p_ente_prop_id
        --AND r_mov_ep_det_class.ente_proprietario_id=3
        AND r_mov_ep_det_class.ente_proprietario_id=p_ente_prop_id
        and d_class_tipo.classif_tipo_code='MISSIONE'
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL)                                    
SELECT classificatori.codice_codifica::varchar codice_codifica,
    classificatori.descrizione_codifica::varchar descrizione_codifica,
    classificatori.codice_codifica_albero::varchar codice_codifica_albero,
    classificatori.livello_codifica::integer livello_codifica,       
    case when upper(pdce.movep_det_segno)='DARE' then pdce.importo
    	else 0::numeric end importo_dare,
    case when upper(pdce.movep_det_segno)='AVERE' then pdce.importo
    	else 0::numeric end importo_avere,
    COALESCE(collegamento_MMGS_MMGE_a.elem_id, 
    	COALESCE(collegamento_MMGS_MMGE_b.elem_id,
        	COALESCE(collegamento_I_A.elem_id,
        		COALESCE(collegamento_SI_SA.elem_id,
                	COALESCE(collegamento_SS_SE.elem_id,
                    	COALESCE(collegamento_OP_OI.elem_id,
                        	COALESCE(collegamento_L.elem_id,
                            	COALESCE(collegamento_RR.elem_id,
                                	COALESCE(collegamento_RE.elem_id,
                                    	COALESCE(collegamento_SS_SE_NCD.elem_id,
                                          	0),0),0),0),0),0),0),0),0),0) elem_id,
	pdce.collegamento_tipo_code,--, pdce.campo_pk_id, pdce.campo_pk_id_2                                            
    ele_prime_note_lib_miss.code_miss_lib,
	ele_prime_note_lib_miss.desc_miss_lib,
	pdce.movep_det_id, pdce.causale_ep_tipo_code, pdce.pnota_id,
    --SIAC-8698 21/04/2022. Aggiungo questi campi.
    pdce.campo_pk_id, pdce.campo_pk_id_2
from classificatori
	inner join pdce
    	ON pdce.classif_id = classificatori.classif_id     
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('I','A')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SI','SA')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SS','SE')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('OP','OI')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'L'
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RR'
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RE'
  --collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = pdce.campo_pk_id_2
  										AND pdce.collegamento_tipo_code IN ('SS','SE')                
  LEFT JOIN ele_prime_note_lib_miss ON ele_prime_note_lib_miss.movep_det_id=pdce.movep_det_id
 ) query_totale
on missioni.elem_id =query_totale.elem_id  
where COALESCE(query_totale.code_miss_lib,'') <> '' OR
	COALESCE(missioni.code_missione,'')  <> ''
--where (query_totale.codice_codifica_albero = '' OR
--		left(query_totale.codice_codifica_albero,1) <> 'A')
--order by missioni.code_missione, query_totale.codice_codifica;
order by 1, 3;

RTN_MESSAGGIO:='Fine estrazione dei dati''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR258_rend_gest_costi_missione_all_h_cont_gen" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;

--SIAC-8696 e SIAC-8698 - Maurizio - FINE