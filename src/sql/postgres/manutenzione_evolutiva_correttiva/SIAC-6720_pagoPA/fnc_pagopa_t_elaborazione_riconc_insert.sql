/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_insert
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
    if attrAccFatturaId is null then
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
            	   login_operazione=ric.login_operazione||'-'||loginOperazione
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
            	   login_operazione=ric.login_operazione||'-'||loginOperazione
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
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
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
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
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
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
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
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
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
            	  login_operazione=ric.login_operazione||'-'||loginOperazione
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
               login_operazione=file.login_operazione||'-'||loginOperazione
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
                 login_operazione=file.login_operazione||'-'||loginOperazione
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
                 login_operazione=ric.login_operazione||'-'||loginOperazione
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
           login_operazione=file.login_operazione||'-'||loginOperazione
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
                 login_operazione=file.login_operazione||'-'||loginOperazione
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
                 login_operazione=ric.login_operazione||'-'||loginOperazione
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
                 login_operazione=file.login_operazione||'-'||loginOperazione
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
                 login_operazione=ric.login_operazione||'-'||loginOperazione
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
                    login_operazione=ric.login_operazione||'-'||loginOperazione
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
                	login_operazione=ric.login_operazione||'-'||loginOperazione
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
            select 1 into codResult
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
		    if codResult is null then
            	pagoPaErrCode:=PAGOPA_ERR_22;
                codResult:=-1;
            else codResult:=null;
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
                     login_operazione=doc.login_operazione||'-'||loginOperazione
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
                     login_operazione=ric.login_operazione||'-'||loginOperazione
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
                 		   login_operazione=doc.login_operazione||'-'||loginOperazione
	                from pagopa_d_riconciliazione_errore err
    	            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
	                and   err.ente_proprietario_id=doc.ente_proprietario_id
     	            and   err.pagopa_ric_errore_code=PAGOPA_ERR_23
    		        and   doc.data_cancellazione is null
	    	        and   doc.validita_fine is null;


            	    strMessaggio:=strMessaggioBck||' NON esistente.Aggiornamento pagopa_t_riconciliazione PAGOPA_ERR='||PAGOPA_ERR_23||'.';
			        update pagopa_t_riconciliazione ric
     	            set    pagopa_ric_errore_id=err.pagopa_ric_errore_id,
        	               data_modifica=clock_timestamp(),
              	           pagopa_ric_flusso_stato_elab='X',
                 	       login_operazione=ric.login_operazione||'-'||loginOperazione
	                from pagopa_d_riconciliazione_errore err,pagopa_t_riconciliazione_doc doc
    	            where doc.pagopa_elab_flusso_id=pagopaElabFlussoId
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
                   login_operazione=doc.login_operazione||'-'||loginOperazione
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
                   login_operazione=ric.login_operazione||'-'||loginOperazione
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
                   login_operazione=doc.login_operazione||'-'||loginOperazione
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
                   login_operazione=ric.login_operazione||'-'||loginOperazione
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
                   login_operazione=file.login_operazione||'-'||loginOperazione
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
COST 100; i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n i z i o   c i c l o . ' ; 
 
         s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ i n s e r t   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
         i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
         ( 
 
             p a g o p a _ e l a b _ i d , 
 
             p a g o p a _ e l a b _ f i l e _ i d , 
 
             p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d , 
 
             l o g i n _ o p e r a z i o n e , 
 
             d a t a _ c r e a z i o n e 
 
         ) 
 
         v a l u e s 
 
         ( 
 
               f i l e P a g o P a E l a b I d , 
 
               f i l e p a g o p a i d , 
 
               s t r M e s s a g g i o L o g , 
 
               e n t e P r o p r i e t a r i o I d , 
 
               l o g i n O p e r a z i o n e , 
 
               c l o c k _ t i m e s t a m p ( ) 
 
         ) ; 
 
 
 
         f o r   p a g o P a F l u s s o R e c   i n 
 
         ( 
 
         s e l e c t   d i s t i n c t   r i c . p a g o p a _ r i c _ f i l e _ i d   p a g o p a _ f i l e _ i d , 
 
                                         r i c . p a g o p a _ r i c _ f l u s s o _ i d   p a g o p a _ f l u s s o _ i d , 
 
                                         r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ p r o v v i s o r i o   p a g o p a _ a n n o _ p r o v v i s o r i o , 
 
 	 	 	 	 	 r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ p r o v v i s o r i o   p a g o p a _ n u m _ p r o v v i s o r i o 
 
         f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
         w h e r e   r i c . f i l e _ p a g o p a _ i d = f i l e P a g o P a I d 
 
         a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b   n o t   i n   ( ' S ' , ' E ' ) 
 
 - -         a n d       r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ c o n _ d e t t = f a l s e   - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
         / * a n d       n o t   e x i s t s 
 
         (   s e l e c t   1 
 
             f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
             w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n o t   n u l l 
 
             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) * / 
 
       / *   a n d       n o t   e x i s t s 
 
         (   s e l e c t   1 
 
             f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
             w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
             a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   i n   ( ' E ' ) 
 
             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
         ) * / 
 
         a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l 
 
         o r d e r   b y                 r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ p r o v v i s o r i o , 
 
 	 	 	 	 	 r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ p r o v v i s o r i o 
 
         ) 
 
         l o o p 
 
 
 
                 c o d R e s u l t : = n u l l ; 
 
 	         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' ; 
 
 
 
                 s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ i n s e r t   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                 i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                 ( 
 
                     p a g o p a _ e l a b _ i d , 
 
                     p a g o p a _ e l a b _ f i l e _ i d , 
 
                     p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                     e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e , 
 
                     d a t a _ c r e a z i o n e 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                       f i l e P a g o P a E l a b I d , 
 
                       f i l e p a g o p a i d , 
 
                       s t r M e s s a g g i o L o g , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c l o c k _ t i m e s t a m p ( ) 
 
                 ) ; 
 
 
 
 
 
 	         - -       i n s e r i m e n t o   i n   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o 
 
 
 
                 p a g o P a F l u s s o A n n o E s e r c i z i o   : = n u l l ; 
 
 	         p a g o P a F l u s s o N o m e M i t t e n t e     : = n u l l ; 
 
 	         p a g o P a F l u s s o D a t a     : = n u l l ; 
 
         	 p a g o P a F l u s s o T o t P a g a m     : = n u l l ; 
 
                 c o d R e s u l t : = n u l l ; 
 
                 s t r N o t e : = n u l l ; 
 
                 p a g o p a E l a b F l u s s o I d : = n u l l ; 
 
 
 
                 s t r M e s s a g g i o : = s t r m e s s a g g i o | | '   R i c a v a   d a t i . ' ; 
 
 	 	 s e l e c t   r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ e s e r c i z i o , 
 
         	               r i c . p a g o p a _ r i c _ f l u s s o _ n o m e _ m i t t e n t e , 
 
   	         	       r i c . p a g o p a _ r i c _ f l u s s o _ d a t a : : v a r c h a r , 
 
 	 	 	       r i c . p a g o p a _ r i c _ f l u s s o _ t o t _ p a g a m , 
 
                               r i c . p a g o p a _ r i c _ i d 
 
         	               i n t o 
 
                 	       p a g o P a F l u s s o A n n o E s e r c i z i o , 
 
 	                       p a g o P a F l u s s o N o m e M i t t e n t e , 
 
         	               p a g o P a F l u s s o D a t a , 
 
 	               	       p a g o P a F l u s s o T o t P a g a m , 
 
                               c o d R e s u l t 
 
 	         f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
 	         w h e r e   r i c . f i l e _ p a g o p a _ i d = f i l e P a g o P a I d 
 
         	 a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b   n o t   i n   ( ' S ' , ' E ' ) 
 
 - -                 a n d       r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ c o n _ d e t t = f a l s e   - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
 	         a n d       r i c . p a g o p a _ r i c _ f l u s s o _ i d =   p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d 
 
         	 a n d       r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ p r o v v i s o r i o = p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
 	 	 a n d       r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ p r o v v i s o r i o = p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                 / * a n d       n o t   e x i s t s 
 
 	         (   s e l e c t   1 
 
         	     f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
 	             w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
         	     a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n o t   n u l l 
 
 	             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
         	     a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	         ) * / 
 
         	 / * a n d       n o t   e x i s t s 
 
 	         (   s e l e c t   1 
 
         	     f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
 	             w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
         	     a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
 	             a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   i n   ( ' E ' ) 
 
         	     a n d     d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	         ) * / 
 
         	 a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l 
 
         	 l i m i t   1 ; 
 
 
 
 	 	 i f     c o d R e s u l t   i s   n u l l   t h e n 
 
                 	 s t r N o t e : = ' D a t i   t e s t a t a   m a n c a n t i . ' ; 
 
                 e n d   i f ; 
 
 
 
 	         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                               '   I n s e r i m e n t o   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o . ' ; 
 
 
 
 	         i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o 
 
         	 ( 
 
         	   p a g o p a _ e l a b _ f l u s s o _ d a t a , 
 
 	           p a g o p a _ e l a b _ f l u s s o _ s t a t o _ i d , 
 
 	 	   p a g o p a _ e l a b _ f l u s s o _ n o t e , 
 
 	 	   p a g o p a _ e l a b _ r i c _ f l u s s o _ i d , 
 
 	 	   p a g o p a _ e l a b _ f l u s s o _ n o m e _ m i t t e n t e , 
 
 	 	   p a g o p a _ e l a b _ r i c _ f l u s s o _ d a t a , 
 
 	           p a g o p a _ e l a b _ f l u s s o _ t o t _ p a g a m , 
 
 	           p a g o p a _ e l a b _ f l u s s o _ a n n o _ e s e r c i z i o , 
 
 	           p a g o p a _ e l a b _ f l u s s o _ a n n o _ p r o v v i s o r i o , 
 
 	           p a g o p a _ e l a b _ f l u s s o _ n u m _ p r o v v i s o r i o , 
 
 	 	   p a g o p a _ e l a b _ i d , 
 
                   v a l i d i t a _ i n i z i o , 
 
                   l o g i n _ o p e r a z i o n e , 
 
                   e n t e _ p r o p r i e t a r i o _ i d 
 
 	         ) 
 
         	 s e l e c t   d a t a E l a b o r a z i o n e , 
 
                 	       s t a t o . p a g o p a _ e l a b _ s t a t o _ i d , 
 
 	                       ' A V V I O   E L A B O R A Z I O N E   F I L E   f i l e _ p a g o p a _ i d = ' | | f i l e P a g o P a I d : : v a r c h a r | | 
 
                               u p p e r ( '   F L U S S O _ I D = ' | | p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | | '   I N   S T A T O   ' | | A C Q U I S I T O _ S T | | '   ' | | 
 
                               c o a l e s c e ( s t r N o t e , '   ' ) ) , 
 
                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d , 
 
       	                       p a g o P a F l u s s o N o m e M i t t e n t e , 
 
 	 	 	       p a g o P a F l u s s o D a t a , 
 
                               p a g o P a F l u s s o T o t P a g a m , 
 
                               p a g o P a F l u s s o A n n o E s e r c i z i o , 
 
                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o , 
 
                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o , 
 
                               f i l e P a g o P a E l a b I d , 
 
                               c l o c k _ t i m e s t a m p ( ) , 
 
                               l o g i n O p e r a z i o n e , 
 
                               e n t e P r o p r i e t a r i o I d 
 
         	 f r o m   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o 
 
 	         w h e r e   s t a t o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
         	 a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ c o d e = A C Q U I S I T O _ S T 
 
                 r e t u r n i n g   p a g o p a _ e l a b _ f l u s s o _ i d   i n t o   p a g o p a E l a b F l u s s o I d ; 
 
 
 
                 c o d R e s u l t : = n u l l ; 
 
                 i f   p a g o p a E l a b F l u s s o I d   i s   n u l l   t h e n 
 
                         s t r M e s s a g g i o B c k : = s t r M e s s a g g i o ; 
 
                         s t r m e s s a g g i o : = s t r M e s s a g g i o B c k | | '   N O N   E f f e t t u a t o .   A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e . ' ; 
 
                 	 u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
                         s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                       p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                                       p a g o p a _ e l a b _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       p a g o p a _ e l a b _ n o t e = u p p e r ( s t r M e s s a g g i o F i n a l e | | '   ' | | s t r m e s s a g g i o ) 
 
                         f r o m   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o ,   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                         w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
                         a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ i d = e l a b . p a g o p a _ e l a b _ s t a t o _ i d 
 
                         a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ c o d e   i n   ( A C Q U I S I T O _ S T , E L A B O R A T O _ I N _ C O R S O _ S T , E L A B O R A T O _ I N _ C O R S O _ S C _ S T , E L A B O R A T O _ I N _ C O R S O _ E R _ S T ) 
 
                         a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ E R _ S T 
 
                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 1 9 
 
                         a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                           s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   N O N   e f f e t t u a t o . A g g i o r n a m e n t o   P A G O P A _ E R R = ' | | P A G O P A _ E R R _ 1 9 | | ' . ' ; 
 
                           u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
                           s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                         p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
                                         l o g i n _ o p e r a z i o n e = r i c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                           f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                           w h e r e   r i c . f i l e _ p a g o p a _ i d = f i l e P a g o P a I d 
 
                           a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b   n o t   i n   ( ' S ' , ' E ' ) 
 
 - -                           a n d       r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ c o n _ d e t t = f a l s e   - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
                           a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = r i c . e n t e _ p r o p r i e t a r i o _ i d 
 
                           a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 1 9 
 
                           a n d       r i c . p a g o p a _ r i c _ f l u s s o _ i d =   p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d 
 
                           a n d       r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ p r o v v i s o r i o = p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
                           a n d       r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ p r o v v i s o r i o = p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                           / * a n d       n o t   e x i s t s 
 
                           (   s e l e c t   1 
 
                               f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                               w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
                               a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n o t   n u l l 
 
                               a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                               a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                           ) * / 
 
                           / * a n d       n o t   e x i s t s 
 
                           (   s e l e c t   1 
 
                               f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                               w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
                               a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
                               a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   i n   ( ' E ' ) 
 
                               a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                               a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                           ) * / 
 
                           a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         c o d R e s u l t : = - 1 ; 
 
                         p a g o P a E r r C o d e : = P A G O P A _ E R R _ 1 9 ; 
 
 
 
                 e n d   i f ; 
 
 
 
                 i f     p a g o p a E l a b F l u s s o I d   i s   n o t   n u l l   t h e n 
 
                   s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                                 p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                                 p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                                 p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                                 '   I n s e r i m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c . ' ; 
 
 	 	   - -       i n s e r i m e n t o   i n   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c 
 
                   i n s e r t   i n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c 
 
                   ( 
 
                 	 p a g o p a _ r i c _ d o c _ d a t a , 
 
                         p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , 
 
     	                 p a g o p a _ r i c _ d o c _ v o c e _ c o d e , 
 
 	 	 	 p a g o p a _ r i c _ d o c _ v o c e _ d e s c , 
 
 	 	 	 p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e , 
 
 	 	         p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , 
 
 	 	 	 p a g o p a _ r i c _ d o c _ s o t t o v o c e _ i m p o r t o , 
 
 	 	         p a g o p a _ r i c _ d o c _ a n n o _ e s e r c i z i o , 
 
 	 	         p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o , 
 
 	 	 	 p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o , 
 
 	 	         p a g o p a _ r i c _ d o c _ n u m _ c a p i t o l o , 
 
 	 	         p a g o p a _ r i c _ d o c _ n u m _ a r t i c o l o , 
 
 	 	         p a g o p a _ r i c _ d o c _ p d c _ v _ f i n , 
 
 	 	         p a g o p a _ r i c _ d o c _ t i t o l o , 
 
 	 	         p a g o p a _ r i c _ d o c _ t i p o l o g i a , 
 
 	 	         p a g o p a _ r i c _ d o c _ c a t e g o r i a , 
 
 	 	         p a g o p a _ r i c _ d o c _ s t r _ a m m , 
 
                         - - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
 	 	         p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f , 
 
                         p a g o p a _ r i c _ d o c _ r a g s o c _ b e n e f , 
 
                         p a g o p a _ r i c _ d o c _ n o m e _ b e n e f , 
 
                         p a g o p a _ r i c _ d o c _ c o g n o m e _ b e n e f , 
 
                         p a g o p a _ r i c _ d o c _ c o d f i s c _ b e n e f , 
 
                 - -         p a g o p a _ r i c _ d o c _ f l a g _ d e t t , 
 
                         - - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
                         p a g o p a _ r i c _ i d , 
 
 	                 p a g o p a _ e l a b _ f l u s s o _ i d , 
 
                         f i l e _ p a g o p a _ i d , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d 
 
                   ) 
 
                   s e l e c t   d a t a E l a b o r a z i o n e , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ t e m a t i c a , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ v o c e _ c o d e , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ v o c e _ d e s c , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ s o t t o v o c e _ c o d e , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ s o t t o v o c e _ d e s c , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ s o t t o v o c e _ i m p o r t o , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ e s e r c i z i o , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ a c c e r t a m e n t o , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ a c c e r t a m e n t o , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ c a p i t o l o , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ a r t i c o l o , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ p d c _ v _ f i n , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ t i t o l o , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ t i p o l o g i a , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ c a t e g o r i a , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ s t r _ a m m , 
 
                                 - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
 	 	 	 	 r i c . p a g o p a _ r i c _ f l u s s o _ c o d i c e _ b e n e f , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ r a g s o c _ b e n e f , 
 
                       	         r i c . p a g o p a _ r i c _ f l u s s o _ n o m e _ b e n e f , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ c o g n o m e _ b e n e f , 
 
                                 r i c . p a g o p a _ r i c _ f l u s s o _ c o d f i s c _ b e n e f , 
 
                             - -     r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ d e t t , 
 
                                 - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
                                 r i c . p a g o p a _ r i c _ i d , 
 
                                 p a g o p a E l a b F l u s s o I d , 
 
                                 f i l e P a g o P a I d , 
 
                                 c l o c k _ t i m e s t a m p ( ) , 
 
                                 l o g i n O p e r a z i o n e , 
 
                                 e n t e P r o p r i e t a r i o I d 
 
                   f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
                   w h e r e   r i c . f i l e _ p a g o p a _ i d = f i l e P a g o P a I d 
 
         	   a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b   n o t   i n   ( ' S ' , ' E ' ) 
 
 - -                   a n d       r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ c o n _ d e t t = f a l s e   - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
 	           a n d       r i c . p a g o p a _ r i c _ f l u s s o _ i d =   p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d 
 
         	   a n d       r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ p r o v v i s o r i o = p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
 	 	   a n d       r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ p r o v v i s o r i o = p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                   / * a n d       n o t   e x i s t s 
 
         	   (   s e l e c t   1 
 
 	               f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
         	       w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
 	               a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n o t   n u l l 
 
         	       a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	               a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
         	   ) * / 
 
 	           / * a n d       n o t   e x i s t s 
 
 	           (   s e l e c t   1 
 
         	       f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
 	               w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
             	       a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
 	               a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   i n   ( ' E ' ) 
 
         	       a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	               a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
         	   ) * / 
 
         	   a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	           a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                   s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                               '   V e r i f i c a   i n s e r i m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c . ' ; 
 
                   - -   c o n t r o l l o   i n s e r i m e n t o 
 
 	 	   c o d R e s u l t : = n u l l ; 
 
                   s e l e c t   1   i n t o   c o d R e s u l t 
 
                   f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                   w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d ; 
 
                   i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                           s t r M e s s a g g i o B c k : = s t r M e s s a g g i o ; 
 
                           s t r m e s s a g g i o : = s t r M e s s a g g i o B c k | | ' .   N O N   E f f e t t u a t o .   A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e . ' ; 
 
                     	   u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
                           s e t       d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                       p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                                       p a g o p a _ e l a b _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       p a g o p a _ e l a b _ n o t e = u p p e r ( s t r M e s s a g g i o F i n a l e | | '   ' | | s t r m e s s a g g i o ) 
 
                           f r o m   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o ,   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                           w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
                           a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ i d = e l a b . p a g o p a _ e l a b _ s t a t o _ i d 
 
                           a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ c o d e   i n   ( A C Q U I S I T O _ S T , E L A B O R A T O _ I N _ C O R S O _ S T , E L A B O R A T O _ I N _ C O R S O _ S C _ S T , E L A B O R A T O _ I N _ C O R S O _ E R _ S T ) 
 
                           a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                           a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ E R _ S T 
 
                           a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                           a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 2 1 
 
                           a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                           a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                           c o d R e s u l t : = - 1 ; 
 
                           p a g o P a E r r C o d e : = P A G O P A _ E R R _ 2 1 ; 
 
 
 
                           s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   N O N   e f f e t t u a t o . A g g i o r n a m e n t o   P A G O P A _ E R R = ' | | P A G O P A _ E R R _ 1 9 | | ' . ' ; 
 
 	 	 	   u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
         	           s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                 	                 d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                         	         p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
                                 	 l o g i n _ o p e r a z i o n e = r i c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	                   f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
         	           w h e r e   r i c . f i l e _ p a g o p a _ i d = f i l e P a g o P a I d 
 
         	 	   a n d       r i c . p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b   n o t   i n   ( ' S ' , ' E ' ) 
 
 - -                           a n d       r i c . p a g o p a _ r i c _ f l u s s o _ f l a g _ c o n _ d e t t = f a l s e   - -   3 1 . 0 5 . 2 0 1 9   s i a c - 6 7 2 0 
 
 	                   a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = r i c . e n t e _ p r o p r i e t a r i o _ i d 
 
         	           a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 2 1 
 
 	         	   a n d       r i c . p a g o p a _ r i c _ f l u s s o _ i d =   p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d 
 
 	         	   a n d       r i c . p a g o p a _ r i c _ f l u s s o _ a n n o _ p r o v v i s o r i o = p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
 	 	 	   a n d       r i c . p a g o p a _ r i c _ f l u s s o _ n u m _ p r o v v i s o r i o = p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                 	   / * a n d       n o t   e x i s t s 
 
 	         	   (   s e l e c t   1 
 
 	 	               f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
         	 	       w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
 	 	               a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n o t   n u l l 
 
         	 	       a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         	       a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	         	   ) * / 
 
 	 	           / * a n d       n o t   e x i s t s 
 
 	         	   (   s e l e c t   1 
 
 	         	       f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
 	 	               w h e r e   d o c . p a g o p a _ r i c _ i d = r i c . p a g o p a _ r i c _ i d 
 
             	 	       a n d       d o c . p a g o p a _ r i c _ d o c _ s u b d o c _ i d   i s   n u l l 
 
 	 	               a n d       d o c . p a g o p a _ r i c _ d o c _ s t a t o _ e l a b   i n   ( ' E ' ) 
 
         	 	       a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         	       a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
 	         	   ) * / 
 
         	 	   a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         	   a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                   e l s e 
 
                   	 c o d R e s u l t : = n u l l ; 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   I n s e r i m e n t o   e f f e t t u a t o . ' ; 
 
                   e n d   i f ; 
 
 	 	 e n d   i f ; 
 
 
 
 	         s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ i n s e r t   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                 i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                 ( 
 
                     p a g o p a _ e l a b _ i d , 
 
                     p a g o p a _ e l a b _ f i l e _ i d , 
 
                     p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                     e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e , 
 
                     d a t a _ c r e a z i o n e 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                       f i l e P a g o P a E l a b I d , 
 
                       f i l e p a g o p a i d , 
 
                       s t r M e s s a g g i o L o g , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c l o c k _ t i m e s t a m p ( ) 
 
                 ) ; 
 
 
 
                 - -   c o n t r o l l o   d a t i   s u 
 
                 - -   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o 
 
                 - -   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c 
 
                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                 	 - -   e s i s t e n z a   p r o v v i s o r i o   d i   c a s s a 
 
                         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                               '   V e r i f i c a   e s i s t e n z a   p r o v v i s o r i o   d i   c a s s a . ' ; 
 
                         s e l e c t   1   i n t o   c o d R e s u l t 
 
                         f r o m   s i a c _ t _ p r o v _ c a s s a   p r o v ,   s i a c _ d _ p r o v _ c a s s a _ t i p o   t i p o 
 
                         w h e r e     t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o i d 
 
                         a n d         t i p o . p r o v c _ t i p o _ c o d e = ' E ' 
 
                         a n d         p r o v . p r o v c _ t i p o _ i d = t i p o . p r o v c _ t i p o _ i d 
 
                         a n d         p r o v . p r o v c _ a n n o : : i n t e g e r = p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
                         a n d         p r o v . p r o v c _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                         a n d         p r o v . p r o v c _ d a t a _ a n n u l l a m e n t o   i s   n u l l 
 
                         a n d         p r o v . p r o v c _ d a t a _ r e g o l a r i z z a z i o n e   i s   n u l l 
 
                         a n d         p r o v . d a t a _ c a n c e l l a z i o n e     i s   n u l l 
 
 	 	 	 a n d         p r o v . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 	 	         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                         	 p a g o P a E r r C o d e : = P A G O P A _ E R R _ 2 2 ; 
 
                                 c o d R e s u l t : = - 1 ; 
 
                         e l s e   c o d R e s u l t : = n u l l ; 
 
                         e n d   i f ; 
 
                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                         	 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                               '   V e r i f i c a   e s i s t e n z a   p r o v v i s o r i o   d i   c a s s a   r e g o l a r i z z a t o   [ O r d . ] . ' ; 
 
                                 s e l e c t   1   i n t o   c o d R e s u l t 
 
                                 f r o m   s i a c _ t _ p r o v _ c a s s a   p r o v ,   s i a c _ d _ p r o v _ c a s s a _ t i p o   t i p o , s i a c _ r _ o r d i n a t i v o _ p r o v _ c a s s a   r p 
 
                                 w h e r e     t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o i d 
 
                                 a n d         t i p o . p r o v c _ t i p o _ c o d e = ' E ' 
 
                                 a n d         p r o v . p r o v c _ t i p o _ i d = t i p o . p r o v c _ t i p o _ i d 
 
                                 a n d         p r o v . p r o v c _ a n n o : : i n t e g e r = p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
                                 a n d         p r o v . p r o v c _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                                 a n d         r p . p r o v c _ i d = p r o v . p r o v c _ i d 
 
                                 a n d         p r o v . p r o v c _ d a t a _ a n n u l l a m e n t o   i s   n u l l 
 
                                 a n d         p r o v . p r o v c _ d a t a _ r e g o l a r i z z a z i o n e   i s   n u l l 
 
                                 a n d         p r o v . d a t a _ c a n c e l l a z i o n e     i s   n u l l 
 
                                 a n d         p r o v . v a l i d i t a _ f i n e   i s   n u l l 
 
                                 a n d         r p . d a t a _ c a n c e l l a z i o n e     i s   n u l l 
 
                                 a n d         r p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                               '   V e r i f i c a   e s i s t e n z a   p r o v v i s o r i o   d i   c a s s a   r e g o l a r i z z a t o   [ D o c . ] . ' ; 
 
                                 	 s e l e c t   1   i n t o   c o d R e s u l t 
 
                                         f r o m   s i a c _ t _ p r o v _ c a s s a   p r o v ,   s i a c _ d _ p r o v _ c a s s a _ t i p o   t i p o , s i a c _ r _ s u b d o c _ p r o v _ c a s s a   r p 
 
                                         w h e r e     t i p o . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o i d 
 
                                         a n d         t i p o . p r o v c _ t i p o _ c o d e = ' E ' 
 
                                         a n d         p r o v . p r o v c _ t i p o _ i d = t i p o . p r o v c _ t i p o _ i d 
 
                                         a n d         p r o v . p r o v c _ a n n o : : i n t e g e r = p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o 
 
                                         a n d         p r o v . p r o v c _ n u m e r o : : i n t e g e r = p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o 
 
                                         a n d         r p . p r o v c _ i d = p r o v . p r o v c _ i d 
 
                                         a n d         p r o v . p r o v c _ d a t a _ a n n u l l a m e n t o   i s   n u l l 
 
                                         a n d         p r o v . p r o v c _ d a t a _ r e g o l a r i z z a z i o n e   i s   n u l l 
 
                                         a n d         p r o v . d a t a _ c a n c e l l a z i o n e     i s   n u l l 
 
                                         a n d         p r o v . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d         r p . d a t a _ c a n c e l l a z i o n e     i s   n u l l 
 
                                         a n d         r p . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                                 e n d   i f ; 
 
                                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                                 	 p a g o P a E r r C o d e : = P A G O P A _ E R R _ 3 8 ; 
 
 	                                 c o d R e s u l t : = - 1 ; 
 
                                 e n d   i f ; 
 
                         e n d   i f ; 
 
 
 
                         i f   p a g o P a E r r C o d e   i s   n o t   n u l l   t h e n 
 
                             s t r M e s s a g g i o B c k : = s t r M e s s a g g i o ; 
 
                             s t r m e s s a g g i o : = s t r M e s s a g g i o | | '   N O N   e s i s t e n t e   o   r e g o l a r i z z a t o .   A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e . ' ; 
 
                             u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
                             s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                           p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                                           p a g o p a _ e l a b _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                           p a g o p a _ e l a b _ n o t e = u p p e r ( s t r M e s s a g g i o F i n a l e | | '   ' | | s t r M e s s a g g i o ) 
 
                             f r o m   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o ,   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                             w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
                             a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ i d = e l a b . p a g o p a _ e l a b _ s t a t o _ i d 
 
                             a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ c o d e   i n   ( A C Q U I S I T O _ S T , E L A B O R A T O _ I N _ C O R S O _ S T , E L A B O R A T O _ I N _ C O R S O _ S C _ S T , E L A B O R A T O _ I N _ C O R S O _ E R _ S T ) 
 
                             a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                             a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ S C _ S T 
 
                             a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                             a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = p a g o P a E r r C o d e 
 
                             a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                             c o d R e s u l t : = - 1 ; 
 
 
 
 
 
                             s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   N O N   e s i s t e n t e   o   r e g o l a r i z z a t o . A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   P A G O P A _ E R R = ' | | p a g o P a E r r C o d e | | ' . ' ; 
 
                             u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                             s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                           d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                           p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' X ' , 
 
                                           l o g i n _ o p e r a z i o n e = d o c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                             f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                             w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                             a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = d o c . e n t e _ p r o p r i e t a r i o _ i d 
 
                             a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = p a g o P a E r r C o d e 
 
                             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                             s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   N O N   e s i s t e n t e   o   r e g o l a r i z z a t o . A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e   P A G O P A _ E R R = ' | | p a g o P a E r r C o d e | | ' . ' ; 
 
                             u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
                             s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                           d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                           p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
                                           l o g i n _ o p e r a z i o n e = r i c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                             f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                             w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                             a n d       r i c . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
                             a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = d o c . e n t e _ p r o p r i e t a r i o _ i d 
 
                             a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = p a g o P a E r r C o d e 
 
                             a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                             a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                             a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                         e l s e   c o d R e s u l t : = n u l l ; 
 
                         e n d   i f ; 
 
 
 
                         - -   e s i s t e n z a   a c c e r t a m e n t o 
 
                         i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                                 s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                               '   V e r i f i c a   e s i s t e n z a   a c c e r t a m e n t i . ' ; 
 
                         	 s e l e c t   1   i n t o   c o d R e s u l t 
 
                                 f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                                 w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                                 a n d       n o t   e x i s t s 
 
                                 ( 
 
                                 s e l e c t   1 
 
 	 	 	 	 f r o m   s i a c _ t _ m o v g e s t   m o v ,   s i a c _ d _ m o v g e s t _ t i p o   t i p o , 
 
                                           s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ d _ m o v g e s t _ t s _ t i p o   t i p o t s , 
 
                                           s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s   ,   s i a c _ d _ m o v g e s t _ s t a t o   s t a t o 
 
                                 w h e r e       m o v . b i l _ i d = b i l a n c i o I d 
 
                                 a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o 
 
                                 a n d       m o v . m o v g e s t _ n u m e r o : : i n t e g e r = d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o 
 
                                 a n d       t i p o . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
                                 a n d       t i p o . m o v g e s t _ t i p o _ c o d e = ' A ' 
 
                                 a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
                                 a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
                                 a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ c o d e = ' T ' 
 
                                 a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                                 a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
                                 a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e = ' D ' 
 
                                 a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
                                 a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
                                 a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                                 a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
                                 ) ; 
 
 
 
 	 	 	 	 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                           	 	 s t r M e s s a g g i o B c k : = s t r M e s s a g g i o ; 
 
 	 	                         s t r m e s s a g g i o : = s t r M e s s a g g i o | | '   N O N   e s i s t e n t e .   A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e . ' ; 
 
 	 	                     	 u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
 	 	                         s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
         	                                       p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                                                       p a g o p a _ e l a b _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                 	                               p a g o p a _ e l a b _ n o t e = u p p e r ( s t r M e s s a g g i o F i n a l e | | '   ' | | s t r m e s s a g g i o ) 
 
                         	 	 f r o m   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o ,   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
 	                                 w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
         	                         a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ i d = e l a b . p a g o p a _ e l a b _ s t a t o _ i d 
 
                 	                 a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ c o d e   i n   ( A C Q U I S I T O _ S T , E L A B O R A T O _ I N _ C O R S O _ S T , E L A B O R A T O _ I N _ C O R S O _ S C _ S T , E L A B O R A T O _ I N _ C O R S O _ E R _ S T ) 
 
                         	         a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
 	                                 a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ S C _ S T 
 
                                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 2 3 
 
         	                         a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 	                 a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 	 	 	 	 	 p a g o P a E r r C o d e : = P A G O P A _ E R R _ 2 3 ; 
 
 	 	                         c o d R e s u l t : = - 1 ; 
 
 
 
                                         s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   N O N   e s i s t e n t e . A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   P A G O P A _ E R R = ' | | P A G O P A _ E R R _ 2 3 | | ' . ' ; 
 
 	 	 	           	 u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
 	           	                 s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
         	         	                       d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                 	             	               p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' X ' , 
 
                                   	 	       l o g i n _ o p e r a z i o n e = d o c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	                                 f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
         	                         w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
 	                                 a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = d o c . e n t e _ p r o p r i e t a r i o _ i d 
 
           	                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 2 3 
 
         	 	                 a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         	                 a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                         	         s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   N O N   e s i s t e n t e . A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e   P A G O P A _ E R R = ' | | P A G O P A _ E R R _ 2 3 | | ' . ' ; 
 
 	 	 	                 u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
           	                         s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                 	                               d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                             	                       p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
                                   	               l o g i n _ o p e r a z i o n e = r i c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
 	                                 f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
         	                         w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                                         a n d       r i c . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
 	                                 a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = d o c . e n t e _ p r o p r i e t a r i o _ i d 
 
           	                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 2 3 
 
         	 	                 a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         	                 a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                                         a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
 	         	                 a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                 	         e n d   i f ; 
 
                         e n d   i f ; 
 
                 e n d   i f ; 
 
 
 
 	 	 s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ i n s e r t   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                 i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                 ( 
 
                     p a g o p a _ e l a b _ i d , 
 
                     p a g o p a _ e l a b _ f i l e _ i d , 
 
                     p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                     e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e , 
 
                     d a t a _ c r e a z i o n e 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                       f i l e P a g o P a E l a b I d , 
 
                       f i l e p a g o p a i d , 
 
                       s t r M e s s a g g i o L o g , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c l o c k _ t i m e s t a m p ( ) 
 
                 ) ; 
 
 
 
                 - - -   s i a c - 6 7 2 0   -   2 3 . 0 5 . 2 0 1 9 
 
                 - -     p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   c o n   i l   t i p o   d i   d o c u m e n t o   d a   c r e a r e 
 
                 - -     t r a t t a r e   g l i   e r r o r i   c o m e   s o p r a   p e r   a c c e r t a m e n t o   n o n   e s i s t e n t e 
 
                 - -     s e   a r r i v o   q u i   v u o l   d i r e   c h e   n o n   c i   s o n o   e r r o r i   e   t u t t i   i   r e c o r d 
 
                 - -     n o n   s c a r t a t i   h a n n o   a c c e r t a m e n t o 
 
                 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                     s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
 	                                           p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
         	                                   p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                 	                           p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                                   '   A g g i o r n a m e n t o   t i p o   d o c u m e n t o . ' ; 
 
                     / * 
 
                     u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                     s e t         p a g o p a _ r i c _ d o c _ t i p o _ c o d e = t i p o d . d o c _ t i p o _ c o d e , 
 
                                   p a g o p a _ r i c _ d o c _ t i p o _ i d = t i p o d . d o c _ t i p o _ i d 
 
                     f r o m       s i a c _ t _ m o v g e s t   m o v ,   s i a c _ d _ m o v g e s t _ t i p o   t i p o , 
 
                                   s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ d _ m o v g e s t _ t s _ t i p o   t i p o t s , 
 
                                   s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s   ,   s i a c _ d _ m o v g e s t _ s t a t o   s t a t o , 
 
                                   s i a c _ d _ d o c _ t i p o   t i p o d 
 
                     w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                     a n d       m o v . b i l _ i d = b i l a n c i o I d 
 
                     a n d       m o v . m o v g e s t _ a n n o : : i n t e g e r = d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o 
 
                     a n d       m o v . m o v g e s t _ n u m e r o : : i n t e g e r = d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o 
 
                     a n d       t i p o . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
                     a n d       t i p o . m o v g e s t _ t i p o _ c o d e = ' A ' 
 
                     a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
                     a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
                     a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ c o d e = ' T ' 
 
                     a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                     a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
                     a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e = ' D ' 
 
                     a n d       t i p o d . e n t e _ p r o p r i e t a r i o _ i d = t i p o . e n t e _ p r o p r i e t a r i o _ i d 
 
                     a n d       (   c a s e     w h e n   t s . m o v g e s t _ t s _ p r e v _ f a t t = t r u e   t h e n   t i p o d . d o c _ t i p o _ i d = d o c T i p o F a t I d 
 
                     	 	 	 	 w h e n   t s . m o v g e s t _ t s _ p r e v _ c o r = t r u e     t h e n   t i p o d . d o c _ t i p o _ i d = d o c T i p o C o r I d 
 
                                                 e l s e   t i p o d . d o c _ t i p o _ i d = d o c T i p o I p a I d   e n d ) 
 
                     a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       t s . v a l i d i t a _ f i n e   i s   n u l l ; * / 
 
 
 
 
 
                     u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                     s e t         p a g o p a _ r i c _ d o c _ t i p o _ c o d e = t i p o d . d o c _ t i p o _ c o d e , 
 
                                   p a g o p a _ r i c _ d o c _ t i p o _ i d = t i p o d . d o c _ t i p o _ i d , 
 
                                   p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t =   ( c a s e   w h e n   t i p o d . d o c _ t i p o _ i d   = d o c T i p o F a t I d   t h e n   t r u e   e l s e   f a l s e   e n d   ) 
 
                     f r o m 
 
                     ( 
 
                     w i t h 
 
                     a c c e r t a m e n t o   a s 
 
                     ( 
 
                     s e l e c t   m o v . m o v g e s t _ a n n o : : i n t e g e r   a n n o _ a c c e r t a m e n t o , m o v . m o v g e s t _ n u m e r o : : i n t e g e r   n u m e r o _ a c c e r t a m e n t o     , 
 
                                   t s . m o v g e s t _ t s _ i d 
 
                     f r o m     s i a c _ t _ m o v g e s t   m o v ,   s i a c _ d _ m o v g e s t _ t i p o   t i p o , 
 
                                 s i a c _ t _ m o v g e s t _ t s   t s ,   s i a c _ d _ m o v g e s t _ t s _ t i p o   t i p o t s , 
 
                                 s i a c _ r _ m o v g e s t _ t s _ s t a t o   r s   ,   s i a c _ d _ m o v g e s t _ s t a t o   s t a t o 
 
                     w h e r e   m o v . b i l _ i d = b i l a n c i o I d 
 
                     a n d       t i p o . m o v g e s t _ t i p o _ i d = m o v . m o v g e s t _ t i p o _ i d 
 
                     a n d       t i p o . m o v g e s t _ t i p o _ c o d e = ' A ' 
 
                     a n d       t s . m o v g e s t _ i d = m o v . m o v g e s t _ i d 
 
                     a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ i d = t s . m o v g e s t _ t s _ t i p o _ i d 
 
                     a n d       t i p o t s . m o v g e s t _ t s _ t i p o _ c o d e = ' T ' 
 
                     a n d       r s . m o v g e s t _ t s _ i d = t s . m o v g e s t _ t s _ i d 
 
                     a n d       s t a t o . m o v g e s t _ s t a t o _ i d = r s . m o v g e s t _ s t a t o _ i d 
 
                     a n d       s t a t o . m o v g e s t _ s t a t o _ c o d e = ' D ' 
 
                     a n d       r s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r s . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       m o v . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       m o v . v a l i d i t a _ f i n e   i s   n u l l 
 
                     a n d       t s . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       t s . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) , 
 
                     - -   F l a g C o l l e g a m e n t o A c c e r t a m e n t o F a t t u r a 
 
                     a c c _ f a t t u r a   a s 
 
                     ( 
 
                     s e l e c t   r a t t r . m o v g e s t _ t s _ i d ,   c o a l e s c e ( r a t t r . b o o l e a n , ' N ' )   f l _ f a t t 
 
                     f r o m   s i a c _ r _ m o v g e s t _ t s _ A t t r   r a t t r 
 
                     w h e r e   r a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       r a t t r . a t t r _ i d = a t t r A c c F a t t u r a I d 
 
                     a n d       c o a l e s c e ( r a t t r . b o o l e a n , ' N ' ) = ' S ' 
 
                     a n d       r a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r a t t r . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) , 
 
                     - - F l a g C o l l e g a m e n t o A c c e r t a m e n t o C o r r i s p e t t i v o 
 
                     a c c _ c o r r i s p e t t i v o   a s 
 
                     ( 
 
                     s e l e c t   r a t t r . m o v g e s t _ t s _ i d , c o a l e s c e ( r a t t r . b o o l e a n , ' N ' )   f l _ c o r r 
 
                     f r o m   s i a c _ r _ m o v g e s t _ t s _ A t t r   r a t t r 
 
                     w h e r e   r a t t r . e n t e _ p r o p r i e t a r i o _ i d = e n t e P r o p r i e t a r i o I d 
 
                     a n d       r a t t r . a t t r _ i d = a t t r A c c C o r r i s p e t t i v o I d 
 
                     a n d       c o a l e s c e ( r a t t r . b o o l e a n , ' N ' ) = ' S ' 
 
                     a n d       r a t t r . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                     a n d       r a t t r . v a l i d i t a _ f i n e   i s   n u l l 
 
                     ) 
 
                     s e l e c t   a c c e r t a m e n t o . m o v g e s t _ t s _ i d , a c c e r t a m e n t o . a n n o _ a c c e r t a m e n t o ,   a c c e r t a m e n t o . n u m e r o _ a c c e r t a m e n t o , 
 
                                   ( c a s e   w h e n   c o a l e s c e ( a c c _ f a t t u r a . f l _ f a t t , ' N ' ) = ' S '   t h e n   d o c T i p o F a t I d 
 
                                             w h e n   c o a l e s c e ( a c c _ c o r r i s p e t t i v o . f l _ c o r r , ' N ' ) = ' S '   t h e n   d o c T i p o C o r I d 
 
                                             e l s e   d o c T i p o I p a I d   e n d )   d o c _ t i p o _ i d 
 
                     f r o m   a c c e r t a m e n t o 
 
                               l e f t   j o i n   a c c _ f a t t u r a   o n   (   a c c e r t a m e n t o . m o v g e s t _ t s _ i d = a c c _ f a t t u r a . m o v g e s t _ t s _ i d   ) 
 
                               l e f t   j o i n   a c c _ c o r r i s p e t t i v o   o n   (   a c c e r t a m e n t o . m o v g e s t _ t s _ i d = a c c _ c o r r i s p e t t i v o . m o v g e s t _ t s _ i d   ) 
 
                     )   q u e r y , s i a c _ d _ d o c _ t i p o   t i p o d 
 
                     w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                     a n d       q u e r y . a n n o _ a c c e r t a m e n t o = d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o 
 
                     a n d       q u e r y . n u m e r o _ a c c e r t a m e n t o = d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o 
 
                     a n d       t i p o d . d o c _ t i p o _ i d = q u e r y . d o c _ t i p o _ i d ; 
 
 
 
                     s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   D a t i   N O N   a g g i o r n a t i   ' ; 
 
 	 	     s e l e c t   1   i n t o   c o d R e s u l t 
 
 	 	     f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                     w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                     a n d       (   c o a l e s c e ( d o c . p a g o p a _ r i c _ d o c _ t i p o _ c o d e , ' ' ) = ' '   o r   d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d   i s   n u l l ) ; 
 
 
 
                     i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                         s t r M e s s a g g i o B c k : = s t r M e s s a g g i o ; 
 
                         s t r m e s s a g g i o : = s t r M e s s a g g i o | | '     e s i s t e n t i .   A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e . ' ; 
 
                         u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
                         s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                       p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                                       p a g o p a _ e l a b _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       p a g o p a _ e l a b _ n o t e = u p p e r ( s t r M e s s a g g i o F i n a l e | | '   ' | | s t r m e s s a g g i o ) 
 
                         f r o m   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o ,   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                         w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
                         a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ i d = e l a b . p a g o p a _ e l a b _ s t a t o _ i d 
 
                         a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ c o d e   i n   ( A C Q U I S I T O _ S T , E L A B O R A T O _ I N _ C O R S O _ S T , E L A B O R A T O _ I N _ C O R S O _ S C _ S T , E L A B O R A T O _ I N _ C O R S O _ E R _ S T ) 
 
                         a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ S C _ S T 
 
                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 4 8 
 
                         a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         p a g o P a E r r C o d e : = P A G O P A _ E R R _ 4 8 ; 
 
                         c o d R e s u l t : = - 1 ; 
 
 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   e s i s t e n t i . A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   P A G O P A _ E R R = ' | | P A G O P A _ E R R _ 4 8 | | ' . ' ; 
 
                         u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                         s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                       p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' X ' , 
 
                                       l o g i n _ o p e r a z i o n e = d o c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                         f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                         w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = d o c . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 4 8 
 
                         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   e s i s t e n t i . A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e   P A G O P A _ E R R = ' | | P A G O P A _ E R R _ 4 8 | | ' . ' ; 
 
                         u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
                         s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                       p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
                                       l o g i n _ o p e r a z i o n e = r i c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                         f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                         w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                         a n d       r i c . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = d o c . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 4 8 
 
                         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                     e n d   i f ; 
 
 
 
 
 
                     s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ i n s e r t   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                     i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                     ( 
 
                         p a g o p a _ e l a b _ i d , 
 
                         p a g o p a _ e l a b _ f i l e _ i d , 
 
                         p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         d a t a _ c r e a z i o n e 
 
                     ) 
 
                     v a l u e s 
 
                     ( 
 
                           f i l e P a g o P a E l a b I d , 
 
                           f i l e p a g o p a i d , 
 
                           s t r M e s s a g g i o L o g , 
 
                           e n t e P r o p r i e t a r i o I d , 
 
                           l o g i n O p e r a z i o n e , 
 
                           c l o c k _ t i m e s t a m p ( ) 
 
                     ) ; 
 
                 e n d   i f ; 
 
 
 
 	 	 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
                     - - -   i n s e r i r e   q u i   i   d e t t a g l i   (   p a g o p a _ r i c _ d o c _ f l a g _ d e t t = t r u e )   p r e n d e n d o l i   d a     t a b e l l a   i n   p i �   d i   A l e 
 
                     - - -   c o n s i d e r a n d o   q u e l l i   c h e   h a n n o   i l   t i p o _ c o d e = F A T ,   p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = t r u e   d a   u p d a t e   s o p r a 
 
                     - - -   i n s e r i r e   i n   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   c o n   p a g o p a _ r i c _ d o c _ f l a g _ d e t t = t r u e 
 
                     - - -   i n   e s e g u i   d e v o   p o i   e s c l u r e   i   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = t r u e 
 
 
 
 
 
 	 	     s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
 	                                           p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
         	                                   p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                 	                           p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                                   '   I n s e r i m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   -     d a t i   d i   d e t t a g l i o . ' ; 
 
                     i n s e r t   i n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c 
 
                     ( 
 
                         p a g o p a _ r i c _ d o c _ d a t a , 
 
                         p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , 
 
     	                 p a g o p a _ r i c _ d o c _ v o c e _ c o d e , 
 
 	 	 	 p a g o p a _ r i c _ d o c _ v o c e _ d e s c , 
 
 	 	 	 p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e , 
 
 	 	         p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , 
 
 	 	 	 p a g o p a _ r i c _ d o c _ s o t t o v o c e _ i m p o r t o , 
 
 	 	         p a g o p a _ r i c _ d o c _ a n n o _ e s e r c i z i o , 
 
 	 	         p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o , 
 
 	 	 	 p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o , 
 
 	 	         p a g o p a _ r i c _ d o c _ n u m _ c a p i t o l o , 
 
 	 	         p a g o p a _ r i c _ d o c _ n u m _ a r t i c o l o , 
 
 	 	         p a g o p a _ r i c _ d o c _ p d c _ v _ f i n , 
 
 	 	         p a g o p a _ r i c _ d o c _ t i t o l o , 
 
 	 	         p a g o p a _ r i c _ d o c _ t i p o l o g i a , 
 
 	 	         p a g o p a _ r i c _ d o c _ c a t e g o r i a , 
 
 	 	         p a g o p a _ r i c _ d o c _ s t r _ a m m , 
 
                         p a g o p a _ r i c _ d o c _ f l a g _ d e t t , 
 
                         p a g o p a _ r i c _ d o c _ t i p o _ c o d e , 
 
                         p a g o p a _ r i c _ d o c _ t i p o _ i d , 
 
 	 	         p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f , 
 
                         p a g o p a _ r i c _ d o c _ r a g s o c _ b e n e f , 
 
                         p a g o p a _ r i c _ d o c _ n o m e _ b e n e f , 
 
                         p a g o p a _ r i c _ d o c _ c o g n o m e _ b e n e f , 
 
                         p a g o p a _ r i c _ d o c _ c o d f i s c _ b e n e f , 
 
                         p a g o p a _ r i c _ i d , 
 
                         p a g o p a _ r i c _ d e t _ i d , 
 
 	                 p a g o p a _ e l a b _ f l u s s o _ i d , 
 
                         f i l e _ p a g o p a _ i d , 
 
                         v a l i d i t a _ i n i z i o , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d 
 
                     ) 
 
                     s e l e c t   d a t a E l a b o r a z i o n e , 
 
 	                           d o c . p a g o p a _ r i c _ d o c _ v o c e _ t e m a t i c a , 
 
 	         	           d o c . p a g o p a _ r i c _ d o c _ v o c e _ c o d e , 
 
 	   	 	 	   d o c . p a g o p a _ r i c _ d o c _ v o c e _ d e s c , 
 
 	     	 	 	   d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ c o d e , 
 
 	   	 	           d o c . p a g o p a _ r i c _ d o c _ s o t t o v o c e _ d e s c , 
 
 	   	 	 	   d e t . p a g o p a _ d e t _ i m p o r t o _ v e r s a m e n t o , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ a n n o _ e s e r c i z i o , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ a n n o _ a c c e r t a m e n t o , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ n u m _ a c c e r t a m e n t o , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ n u m _ c a p i t o l o , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ n u m _ a r t i c o l o , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ p d c _ v _ f i n , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ t i t o l o , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ t i p o l o g i a , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ c a t e g o r i a , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ s t r _ a m m , 
 
                                   t r u e , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ t i p o _ c o d e , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d , 
 
                                   d o c . p a g o p a _ r i c _ d o c _ c o d i c e _ b e n e f , 
 
                                   - -   d e t 
 
                                   d e t . p a g o p a _ d e t _ a n a g _ r a g i o n e _ s o c i a l e , 
 
                       	           d e t . p a g o p a _ d e t _ a n a g _ n o m e , 
 
                                   d e t . p a g o p a _ d e t _ a n a g _ c o g n o m e , 
 
                                   d e t . p a g o p a _ d e t _ a n a g _ c o d i c e _ f i s c a l e , 
 
                                   d o c . p a g o p a _ r i c _ i d , 
 
                                   d e t . p a g o p a _ r i c _ d e t _ i d , 
 
 	                           d o c . p a g o p a _ e l a b _ f l u s s o _ i d , 
 
                                   d o c . f i l e _ p a g o p a _ i d , 
 
                                   c l o c k _ t i m e s t a m p ( ) , 
 
                                   l o g i n O p e r a z i o n e , 
 
                                   e n t e P r o p r i e t a r i o I d 
 
                     f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c ,   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d e t   d e t 
 
                     w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                     a n d       d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = t r u e 
 
                     a n d       d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d = d o c T i p o F a t I d 
 
                     a n d       d e t . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
                     a n d       d e t . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
   	             a n d       d e t . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                     s t r M e s s a g g i o : = s t r M e s s a g g i o | | '   V e r i f i c a . ' ; 
 
 	 	     s e l e c t   1   i n t o   c o d R e s u l t 
 
                     f r o m     p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                     w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                     a n d       d o c . p a g o p a _ r i c _ d o c _ f l a g _ c o n _ d e t t = t r u e 
 
                     a n d       d o c . p a g o p a _ r i c _ d o c _ t i p o _ i d = d o c T i p o F a t I d 
 
                     a n d       n o t   e x i s t s 
 
                     ( 
 
                     s e l e c t   1   f r o m   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 1 
 
                     w h e r e   d o c 1 . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                     a n d       d o c 1 . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
                     a n d       d o c 1 . p a g o p a _ r i c _ d o c _ f l a g _ d e t t = t r u e 
 
                     ) ; 
 
 
 
 	 	     i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
                     	 s t r M e s s a g g i o B c k : = s t r M e s s a g g i o ; 
 
                         s t r m e s s a g g i o : = s t r M e s s a g g i o | | '     e s i s t e n t i .   A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e . ' ; 
 
                         u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
                         s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                       p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                                       p a g o p a _ e l a b _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       p a g o p a _ e l a b _ n o t e = u p p e r ( s t r M e s s a g g i o F i n a l e | | '   ' | | s t r m e s s a g g i o ) 
 
                         f r o m   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o ,   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w , p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                         w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
                         a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ i d = e l a b . p a g o p a _ e l a b _ s t a t o _ i d 
 
                         a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ c o d e   i n   ( A C Q U I S I T O _ S T , E L A B O R A T O _ I N _ C O R S O _ S T , E L A B O R A T O _ I N _ C O R S O _ S C _ S T , E L A B O R A T O _ I N _ C O R S O _ E R _ S T ) 
 
                         a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ S C _ S T 
 
                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 4 9 
 
                         a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
                         p a g o P a E r r C o d e : = P A G O P A _ E R R _ 4 9 ; 
 
                         c o d R e s u l t : = - 1 ; 
 
 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   e s i s t e n t i . A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   P A G O P A _ E R R = ' | | P A G O P A _ E R R _ 4 9 | | ' . ' ; 
 
                         u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                         s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                       p a g o p a _ r i c _ d o c _ s t a t o _ e l a b = ' X ' , 
 
                                       l o g i n _ o p e r a z i o n e = d o c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                         f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                         w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = d o c . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 4 9 
 
                         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
 
 
 
 
                         s t r M e s s a g g i o : = s t r M e s s a g g i o B c k | | '   e s i s t e n t i . A g g i o r n a m e n t o   p a g o p a _ t _ r i c o n c i l i a z i o n e   P A G O P A _ E R R = ' | | P A G O P A _ E R R _ 4 9 | | ' . ' ; 
 
                         u p d a t e   p a g o p a _ t _ r i c o n c i l i a z i o n e   r i c 
 
                         s e t         p a g o p a _ r i c _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                                       p a g o p a _ r i c _ f l u s s o _ s t a t o _ e l a b = ' X ' , 
 
                                       l o g i n _ o p e r a z i o n e = r i c . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                         f r o m   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r , p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c   d o c 
 
                         w h e r e   d o c . p a g o p a _ e l a b _ f l u s s o _ i d = p a g o p a E l a b F l u s s o I d 
 
                         a n d       r i c . p a g o p a _ r i c _ i d = d o c . p a g o p a _ r i c _ i d 
 
                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = d o c . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = P A G O P A _ E R R _ 4 9 
 
                         a n d       d o c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       d o c . v a l i d i t a _ f i n e   i s   n u l l 
 
                         a n d       r i c . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                         a n d       r i c . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                     e n d   i f ; 
 
 
 
                     s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ i n s e r t   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                     i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                     ( 
 
                         p a g o p a _ e l a b _ i d , 
 
                         p a g o p a _ e l a b _ f i l e _ i d , 
 
                         p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                         e n t e _ p r o p r i e t a r i o _ i d , 
 
                         l o g i n _ o p e r a z i o n e , 
 
                         d a t a _ c r e a z i o n e 
 
                     ) 
 
                     v a l u e s 
 
                     ( 
 
                           f i l e P a g o P a E l a b I d , 
 
                           f i l e p a g o p a i d , 
 
                           s t r M e s s a g g i o L o g , 
 
                           e n t e P r o p r i e t a r i o I d , 
 
                           l o g i n O p e r a z i o n e , 
 
                           c l o c k _ t i m e s t a m p ( ) 
 
                     ) ; 
 
 	 	 e n d   i f ; 
 
 
 
 	 	 - -   s o n o   s t a t i   i n s e r i t i 
 
                 - -   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o 
 
                 - -   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c 
 
                 - -   p o s s o   a g g i o r n a r e   s u   p a g o p a _ t _ e l a b o r a z i o n e   p e r   e l a b = e l a b o r a t o _ i n _ c o r s o 
 
 	 	 i f   c o d R e s u l t   i s   n u l l   t h e n 
 
 	 	                         s t r M e s s a g g i o : = ' I n s e r i m e n t o   d a t i   p e r   e l a b o r a z i o n e   f l u s s i . I n   c i c l o   p a g o p a _ f l u s s o _ i d = ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ f l u s s o _ i d | |   '   -   P r o v v i s o r i o = '   | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ a n n o _ p r o v v i s o r i o | | ' / ' | | 
 
                                               p a g o P a F l u s s o R e c . p a g o p a _ n u m _ p r o v v i s o r i o | | ' . ' | | 
 
                                               '   A g g i o r n a m e n t o   p a g o p a _ t _ e l a b o r a z i o n e   ' | | E L A B O R A T O _ I N _ C O R S O _ S T | | ' . ' ; 
 
 	 	                     	 u p d a t e   p a g o p a _ t _ e l a b o r a z i o n e   e l a b 
 
 	 	                         s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
         	                                       p a g o p a _ e l a b _ s t a t o _ i d = s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ i d , 
 
                 	                               p a g o p a _ e l a b _ n o t e = ' A G G I O R N A M E N T O   E L A B O R A Z I O N E   S U   F I L E   f i l e _ p a g o p a _ i d = ' | | f i l e P a g o P a I d : : v a r c h a r | | '   I N   S T A T O   ' | | E L A B O R A T O _ I N _ C O R S O _ S T | | '   ' 
 
                         	 	 f r o m   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o ,   p a g o p a _ d _ e l a b o r a z i o n e _ s t a t o   s t a t o n e w 
 
 	                                 w h e r e   e l a b . p a g o p a _ e l a b _ i d = f i l e P a g o P a E l a b I d 
 
         	                         a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ i d = e l a b . p a g o p a _ e l a b _ s t a t o _ i d 
 
                 	                 a n d       s t a t o . p a g o p a _ e l a b _ s t a t o _ c o d e   i n   ( A C Q U I S I T O _ S T , E L A B O R A T O _ I N _ C O R S O _ S T ) 
 
                         	         a n d       s t a t o n e w . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
 	                                 a n d       s t a t o n e w . p a g o p a _ e l a b _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ S T 
 
         	                         a n d       e l a b . d a t a _ c a n c e l l a z i o n e   i s   n u l l 
 
                 	                 a n d       e l a b . v a l i d i t a _ f i n e   i s   n u l l ; 
 
                 e n d   i f ; 
 
 
 
 	 	 - -   n o n   s o n o   s t a t i   i n s e r i t i 
 
                 - -   p a g o p a _ t _ e l a b o r a z i o n e _ f l u s s o 
 
                 - -   p a g o p a _ t _ r i c o n c i l i a z i o n e _ d o c 
 
                 - -   q u i n d i   a g g i o r n a r e   s i a c _ t _ f i l e _ p a g o p a 
 
                 i f   c o d R e s u l t   i s   n o t   n u l l   t h e n 
 
 	                 s t r m e s s a g g i o : = s t r M e s s a g g i o B c k | | '   E r r o r e .   A g g i o r n a m e n t o   s i a c _ t _ f i l e _ p a g o p a . ' ; 
 
 	               	 u p d a t e   s i a c _ t _ f i l e _ p a g o p a   f i l e 
 
                     	 s e t         d a t a _ m o d i f i c a = c l o c k _ t i m e s t a m p ( ) , 
 
                         	       f i l e _ p a g o p a _ s t a t o _ i d = s t a t o . f i l e _ p a g o p a _ s t a t o _ i d , 
 
                                       f i l e _ p a g o p a _ e r r o r e _ i d = e r r . p a g o p a _ r i c _ e r r o r e _ i d , 
 
                                       f i l e _ p a g o p a _ c o d e = c o a l e s c e ( f i l e p a g o p a F i l e X M L I d , f i l e . f i l e _ p a g o p a _ c o d e ) , 
 
                                       f i l e _ p a g o p a _ n o t e = c o a l e s c e ( s t r M e s s a g g i o F i n a l e , '   '   ) | | c o a l e s c e ( s t r m e s s a g g i o , '   ' ) , 
 
                                       l o g i n _ o p e r a z i o n e = f i l e . l o g i n _ o p e r a z i o n e | | ' - ' | | l o g i n O p e r a z i o n e 
 
                         f r o m   s i a c _ d _ f i l e _ p a g o p a _ s t a t o   s t a t o ,   p a g o p a _ d _ r i c o n c i l i a z i o n e _ e r r o r e   e r r 
 
                         w h e r e   f i l e . f i l e _ p a g o p a _ i d = f i l e P a g o P a I d 
 
                         a n d       s t a t o . e n t e _ p r o p r i e t a r i o _ i d = f i l e . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       s t a t o . f i l e _ p a g o p a _ s t a t o _ c o d e = E L A B O R A T O _ I N _ C O R S O _ S C _ S T 
 
                         a n d       e r r . e n t e _ p r o p r i e t a r i o _ i d = s t a t o . e n t e _ p r o p r i e t a r i o _ i d 
 
                         a n d       e r r . p a g o p a _ r i c _ e r r o r e _ c o d e = p a g o P a E r r C o d e ; 
 
                 e n d   i f ; 
 
 
 
 	         s t r M e s s a g g i o L o g : = ' C o n t i n u e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ i n s e r t   -   ' | | s t r M e s s a g g i o F i n a l e | | s t r M e s s a g g i o ; 
 
                 i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
                 ( 
 
                     p a g o p a _ e l a b _ i d , 
 
                     p a g o p a _ e l a b _ f i l e _ i d , 
 
                     p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
                     e n t e _ p r o p r i e t a r i o _ i d , 
 
                     l o g i n _ o p e r a z i o n e , 
 
                     d a t a _ c r e a z i o n e 
 
                 ) 
 
                 v a l u e s 
 
                 ( 
 
                       f i l e P a g o P a E l a b I d , 
 
                       f i l e p a g o p a i d , 
 
                       s t r M e s s a g g i o L o g , 
 
                       e n t e P r o p r i e t a r i o I d , 
 
                       l o g i n O p e r a z i o n e , 
 
                       c l o c k _ t i m e s t a m p ( ) 
 
                 ) ; 
 
 
 
         e n d   l o o p ; 
 
         - - - - - - - - - -   f i n e   g e s t i o n e   f l u s s i   s u   p i a n o _ t _ r i c o n c i l i a z i o n e   p e r   p a g o p a _ e l a b _ i d   - - - - - - - - - - - - - - - - 
 
 
 
         o u t P a g o P a E l a b I d : = f i l e P a g o P a E l a b I d ; 
 
         m e s s a g g i o R i s u l t a t o : = u p p e r ( s t r M e s s a g g i o F i n a l e | | '   O K ' ) ; 
 
         s t r M e s s a g g i o L o g : = ' F i n e   f n c _ p a g o p a _ t _ e l a b o r a z i o n e _ r i c o n c _ i n s e r t   -   ' | | m e s s a g g i o R i s u l t a t o ; 
 
         i n s e r t   i n t o   p a g o p a _ t _ e l a b o r a z i o n e _ l o g 
 
         ( 
 
             p a g o p a _ e l a b _ i d , 
 
             p a g o p a _ e l a b _ f i l e _ i d , 
 
             p a g o p a _ e l a b _ l o g _ o p e r a z i o n e , 
 
             e n t e _ p r o p r i e t a r i o _ i d , 
 
             l o g i n _ o p e r a z i o n e , 
 
             d a t a _ c r e a z i o n e 
 
         ) 
 
         v a l u e s 
 
         ( 
 
               f i l e P a g o P a E l a b I d , 
 
               f i l e p a g o p a i d , 
 
               s t r M e s s a g g i o L o g , 
 
               e n t e P r o p r i e t a r i o I d , 
 
               l o g i n O p e r a z i o n e , 
 
               c l o c k _ t i m e s t a m p ( ) 
 
         ) ; 
 
 
 
         r e t u r n ; 
 
 e x c e p t i o n 
 
         w h e n   R A I S E _ E X C E P T I O N   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = 
 
                 	 c o a l e s c e ( s t r M e s s a g g i o F i n a l e , ' ' ) | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E :     ' | | '   ' | | c o a l e s c e ( s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 ) , ' ' )   ; 
 
               	 c o d i c e R i s u l t a t o : = - 1 ; 
 
 
 
 	 	 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
               	 o u t P a g o P a E l a b I d : = - 1 ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   N O _ D A T A _ F O U N D   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   N e s s u n   d a t o   p r e s e n t e   i n   a r c h i v i o . ' ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
               	 o u t P a g o P a E l a b I d : = - 1 ; 
 
 
 
                 r e t u r n ; 
 
           w h e n   T O O _ M A N Y _ R O W S   T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | '   D i v e r s e   r i g h e   p r e s e n t i   i n   a r c h i v i o . ' ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
             	 o u t P a g o P a E l a b I d : = - 1 ; 
 
 
 
                 r e t u r n ; 
 
 	 w h e n   o t h e r s     T H E N 
 
                 m e s s a g g i o R i s u l t a t o : = s t r M e s s a g g i o F i n a l e | | c o a l e s c e ( s t r M e s s a g g i o , ' ' ) | | ' E R R O R E   D B : ' | | S Q L S T A T E | | '   ' | | s u b s t r i n g ( u p p e r ( S Q L E R R M )   f r o m   1   f o r   5 0 0 )   ; 
 
                 c o d i c e R i s u l t a t o : = - 1 ; 
 
                 m e s s a g g i o R i s u l t a t o : = u p p e r ( m e s s a g g i o R i s u l t a t o ) ; 
 
               	 o u t P a g o P a E l a b I d : = - 1 ; 
 
                 r e t u r n ; 
 
 
 
 E N D ; 
 
 $ b o d y $ 
 
 L A N G U A G E   ' p l p g s q l ' 
 
 V O L A T I L E 
 
 C A L L E D   O N   N U L L   I N P U T 
 
 S E C U R I T Y   I N V O K E R 
 
 C O S T   1 0 0 ; 