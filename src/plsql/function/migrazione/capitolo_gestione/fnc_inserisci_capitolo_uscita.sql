/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_inserisci_capitolo_uscita (
  tipoelab varchar,
  bilancioid integer,
  annobilancio varchar,
  bilElemTipo varchar,
  parPerInsertElemBil parPerInsertElemBilType,
  capitolouscita siac.migr_capitolo_uscita,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar,
  out bilelemid integer
)
RETURNS record AS
$body$
DECLARE

	-- fnc_inserisci_capitolo_uscita --> function che inserisce un capitolo di uscita passato in input
     -- effettua inserimento di
      -- siac_t_bil_elem --> anagrafica
      -- siac_t_bil_elem_dett  --> dettaglio importi
      -- siac_r_bil_elem_stato --> stato
      -- siac_r_bil_elem_attr  --> attributi (FlagRilevanteIva, Note)
      -- siac_r_bil_elem_class --> associazione con i vari classificatori ( siac_t_class )
        -- macroaggregato, programma
        -- pdc_fin_iv, pdc_fin_v
        -- siope_livello_iii
        -- cdc,cdr
        -- tipo_finanziamento, tipo_fondo
        -- classificatore_1 .. classificatore_10   --> specifici e generici
        -- classififcatore_31 .. classificatore_35 --> generici x eventuali stampe ma non gestisti
      -- richiama
		-- fnc_migr_classif --> verifica esistenza dei classificatori specifici o generici ed eventualmente inserisce
      -- restituisce
       -- messaggioRisultato=risultato in formato testo
       -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)
       -- bilElemId=elem_id del siac_t_bil_elem inserito

    bilElemIdRet integer := 0;
   -- bilElemTipoId integer :=0;
    periodoId integer :=0;

    bilElemIdPadre INTEGER:=null;
    livelloBilElem siac_t_bil_elem.livello%type:=1;

    classifProgrammaId integer:=0;
	classifId integer :=0;

	classifFamiglia integer :=0;
	classifTitolo integer  :=0;
	classifMacroaggregato integer  :=0;


	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	sacCode varchar(100):='';
    sacCodeDef varchar(100):='';
    classifSac varchar(100):='';
    pdcFin     varchar(100):='';
    classifPdcFin varchar(100):='';

	classifCode varchar(250):='';
    classifDesc varchar(250):='';
    strToElab varchar(250):='';
	annoBilancio1 varchar(10):='';
    annoBilancio2 varchar(10):='';

	-- Davide - 05.04.016 - variabile per attributo "Trasferimenti Comunitari"
	trasf_comu varchar(1):='';

    migrClassif record;

    -- costanti
    -- Stato operativo valido
    STATO_VALIDO CONSTANT  varchar :='VA';
    -- Tipi di importo
    STANZ_PROP  CONSTANT  varchar :='STP';
    STANZ_INIZIALE  CONSTANT  varchar :='STI';
    STANZ_ATTUALE   CONSTANT  varchar :='STA';
    STANZ_RES_INIZIALE CONSTANT  varchar :='SRI';
    STANZ_RESIDUO CONSTANT  varchar :='STR';
    STANZ_CASSA_INIZIALE CONSTANT  varchar :='SCI';
    STANZ_CASSA CONSTANT  varchar :='SCA';
    STANZ_ASSEST_CASSA CONSTANT varchar:='STCASS';
    STANZ_ASSEST CONSTANT varchar:='STASS';
    STANZ_ASSEST_RES CONSTANT varchar:='STRASS';

	PER_TIPO_ANNO_MY CONSTANT varchar:='SY';

    -- ATTRIBUTI
    -- UP,EP, UG, EG
    FLAG_RIL_IVA CONSTANT varchar :='FlagRilevanteIva';
    NOTE_CAP CONSTANT varchar :='Note';
	FLAG_IMPEGNABILE CONSTANT varchar :='FlagImpegnabile';

    -- UG,UP
	FLAG_FONDO_SVAL_CRED CONSTANT varchar :='FlagFondoSvalutazioneCrediti';
    FLAG_FUNZ_DEL CONSTANT varchar := 'FlagFunzioniDelegate';
    FLAG_TRASF_ORG CONSTANT varchar :='FlagTrasferimentoOrganiComunitari';


	--  UP, EP
    FLAG_PER_MEM CONSTANT varchar := 'FlagPerMemoria';

	-- CLASSIFICATORI
	--CL_MACROAGGREGATO CONSTANT varchar :='MACROAGGREGATO';
	CL_PROGRAMMA CONSTANT varchar :='PROGRAMMA';
    CL_CDC CONSTANT varchar :='CDC';
    CL_CDR CONSTANT varchar :='CDR';

	-- Sofia 12.11.2015 - impostazione default ricorrente
	CL_RICORRENTE_SPESA CONSTANT varchar:='RICORRENTE_SPESA';
    CL_RICORRENTE_SPESA_RICORR CONSTANT varchar:= '3';
    cl_ricorrente varchar := '4'; -- 12.01.2016 Daniela. Il valore di default impostato per RICORRENRE è 'NON RICORRENTE' potrebbe cambiare se macro = 1 e titolo = 1

    --12.01.2016 Daniela impostazione default TRANSAZIONE_UE
	CL_TRANSAZIONE_UE_SPESA CONSTANT varchar:='TRANSAZIONE_UE_SPESA';
    CL_TRANSAZIONE_UE_SPESA_DEF CONSTANT varchar:= '8' ;

    CL_PDC_FIN_QUARTO     CONSTANT varchar :='PDC_IV';
    CL_PDC_FIN_QUINTO     CONSTANT varchar :='PDC_V';
	CL_COFOG 			  CONSTANT varchar :='GRUPPO_COFOG';
    CL_TIPO_FINANZIAMENTO CONSTANT varchar :='TIPO_FINANZIAMENTO';
    CL_TIPO_FONDO         CONSTANT varchar :='TIPO_FONDO';
	CL_SIOPE_TERZO        CONSTANT varchar:='SIOPE_SPESA_I'; -- 13.11.2015 Sofia gestione siope
    CL_CLASSIFICATORE_1   CONSTANT varchar :='CLASSIFICATORE_1';
    CL_CLASSIFICATORE_2   CONSTANT varchar :='CLASSIFICATORE_2';
    CL_CLASSIFICATORE_3   CONSTANT varchar :='CLASSIFICATORE_3';
    CL_CLASSIFICATORE_4   CONSTANT varchar :='CLASSIFICATORE_4';
    CL_CLASSIFICATORE_5   CONSTANT varchar :='CLASSIFICATORE_5';
    CL_CLASSIFICATORE_6   CONSTANT varchar :='CLASSIFICATORE_6';

	CL_CLASSIFICATORE_7   CONSTANT varchar :='CLASSIFICATORE_7';
    CL_CLASSIFICATORE_8   CONSTANT varchar :='CLASSIFICATORE_8';
    CL_CLASSIFICATORE_9   CONSTANT varchar :='CLASSIFICATORE_9';
    CL_CLASSIFICATORE_10   CONSTANT varchar :='CLASSIFICATORE_10';

    CL_CLASSIFICATORE_11   CONSTANT varchar :='CLASSIFICATORE_31';
    CL_CLASSIFICATORE_12   CONSTANT varchar :='CLASSIFICATORE_32';
    CL_CLASSIFICATORE_13   CONSTANT varchar :='CLASSIFICATORE_33';
    CL_CLASSIFICATORE_14   CONSTANT varchar :='CLASSIFICATORE_34';
    CL_CLASSIFICATORE_15   CONSTANT varchar :='CLASSIFICATORE_35';
    SIOPECOD_DEF           CONSTANT varchar :='XXXX';          -- 27.11.2015 Davide gestione siope

    CL_FAMIGLIA         CONSTANT varchar :='Spesa - TitoliMacroaggregati';
	CL_TITOLO_SPESA     CONSTANT varchar :='TITOLO_SPESA';
	CL_MACROAGGREGATO   CONSTANT varchar :='MACROAGGREGATO';




	NVL_STR CONSTANT varchar :='';
    SEPARATORE CONSTANT varchar :='||';

	TIPO_ELAB_P CONSTANT varchar :='P'; -- previsione
    TIPO_ELAB_G CONSTANT varchar :='G'; -- gestione

    CDC_DEF CONSTANT varchar :='00';
    CDR_DEF CONSTANT varchar :='000';

    dataInizioVal timestamp:=null;

	codResult integer:=null;
    titoloCode varchar := ''; -- 12.01.2016 Daniela Codice del titolo associato al macroaggregato del capitolo. Usato per determinare il classificatore RICORRENTE da usare.
    MACROAGGREGATO_1 CONSTANT varchar := '1010000'; -- Redditi da lavoro dipendente
BEGIN


    -- bilElemTipoId
    -- elemStatoIdValido
    -- periodoIdAnno
    -- elemDetTipoIdSti
    -- elemDetTipoIdSri
    -- elemDetTipoIdSci
    -- elemDetTipoIdSta
    -- elemDetTipoIdStr
    -- elemDetTipoIdSca
    -- elemDetTipoIdStp
    -- elemDetTipoIdStass
    -- elemDetTipoIdStcass
    -- elemDetTipoIdStrass
	-- periodoIdAnno1
    -- periodoIdAnno2
    -- tutti gli id degli attributi
    -- tutti gli id dei tipi classificatori specifici

    messaggioRisultato:='';
    codiceRisultato:=0;
	bilElemId:=0;


--    dataInizioVal:=annoBilancio||'-01-01';
--     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Inserimento capitolo uscita  '||bilElemTipo||
    					'.Elemento bilancio anno '||annoBilancio||' '||
                        capitoloUscita.numero_capitolo||'/'||capitoloUscita.numero_articolo||'/'||capitoloUscita.numero_ueb||
                        ' migr_capusc_id='||capitoloUscita.migr_capusc_id||'.';

-- 12.01.014 Sofia spostato fuori per non ripeterlo per ogni capitolo
--	strMessaggio:='Lettura Identificativo elemento tipo '||bilElemTipo||'.';
    -- Dovra esserci un unico elemento valido
--    select elem_tipo_id into bilElemTipoId
--	from siac_d_bil_elem_tipo
--	where elem_tipo_code=bilElemTipo and
--	      ente_proprietario_id=enteProprietarioId and
--          data_cancellazione is null and
--          date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
--          (date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(validita_fine,now()));
--          date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
--          (date_trunc('day',dataElaborazione)<date_trunc('day',validita_fine)
--            or validita_fine is null);

   -- siac_t_bil_elem
   strMessaggio:='Inserimento siac_t_bil_elem.';
   insert into siac_t_bil_elem
   (elem_code,elem_code2,elem_code3, elem_desc,elem_desc2,
    elem_id_padre,elem_tipo_id, bil_id,ordine,livello,
    validita_inizio , ente_proprietario_id,data_creazione,login_operazione)
   values
   (--ltrim(rtrim(to_char(capitoloUscita.numero_capitolo,'999999')))
    capitoloUscita.numero_capitolo::varchar,
    --ltrim(rtrim(to_char(capitoloUscita.numero_articolo,'999999'))),
    capitoloUscita.numero_articolo::varchar,
    coalesce(capitoloUscita.numero_ueb,'1'),
    --substring(upper(capitoloUscita.descrizione) from 1 for 500),
    capitoloUscita.descrizione,capitoloUscita.descrizione_articolo,
--    substring(upper(capitoloUscita.descrizione_articolo) from 1 for 500),
    bilElemIdPadre,parPerInsertElemBil.bilElemTipoId,bilancioId,
    lpad(capitoloUscita.numero_capitolo::varchar, 5, '0'),
    livelloBilElem, dataInizioVal,enteProprietarioId,statement_timestamp(),loginOperazione)
   returning elem_id into bilElemIdRet;

    -- stato siac_r_bil_elem_stato
    strMessaggio:='Inserimento siac_r_bil_elem_stato.';
    insert into siac_r_bil_elem_stato
    (elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,
     data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.elemStatoIdValido,dataInizioVal,enteproprietarioid,
     statement_timestamp(),loginOperazione);

-- 12.01.015 Sofia spostato fuori da function e ciclo per leggere una volta sola l'id dello stato valido
--    (select bilElemIdRet,capitoloStato.elem_stato_id,dataInizioVal,capitoloStato.ente_proprietario_id,
--           now(),loginOperazione
--     from  siac_d_bil_elem_stato capitoloStato
--     where capitoloStato.elem_stato_code= STATO_VALIDO and
--           capitoloStato.ente_proprietario_id=enteProprietarioId and
--           capitoloStato.data_cancellazione is null and
--           date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloStato.validita_inizio) and
--           (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloStato.validita_fine,now()))));
--             or capitoloStato.validita_fine is null));
	-- 12.01.015 Sofia - spostato fuori ciclo
    -- importi siac_t_bil_elem_det
    -- strMessaggio:='Lettura periodo per anno='||annoBilancio||'.';
    -- periodoId:=0;
    -- begin
    -- 	select per.periodo_id into periodoId
    --    from siac_t_periodo per , siac_d_periodo_tipo perTipo
    --    where per.anno=annoBilancio and
    --          per.ente_proprietario_id=enteProprietarioId and
    --          perTipo.periodo_tipo_id=per.periodo_tipo_id and
    --          perTipo.periodo_tipo_code=PER_TIPO_ANNO_MY and
    --          perTipo.ente_proprietario_id=enteProprietarioId;

     --   exception
     --       	when others  THEN
	 --             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
     --end;

     periodoId:=parPerInsertElemBil.periodoIdAnno;
	 -- STI - Stanziamento Iniziale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_INIZIALE|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento_iniziale,null,
	  parPerInsertElemBil.elemDetTipoIdSti,periodoId,dataInizioVal,
      enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento_iniziale,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.dataElaborazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_RES_INIZIALE|| ' .';
	 -- SRI - Stanziamento Residuo Iniziale
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
      values
      (bilElemIdRet, capitoloUscita.stanziamento_iniziale_res,null,
  	   parPerInsertElemBil.elemDetTipoIdSri, periodoId,dataInizioVal,
       enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento_iniziale_res,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_RES_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

     -- SCI - Stanziamento Cassa Iniziale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_CASSA_INIZIALE|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento_iniziale_cassa,null,
	  parPerInsertElemBil.elemDetTipoIdSci, periodoId,dataInizioVal,
      enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento_iniziale_cassa,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_CASSA_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));


     -- STA - Stanziamento Attuale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_ATTUALE|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento,null,
 	  parPerInsertElemBil.elemDetTipoIdSta, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_ATTUALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
---        		      or capitoloTipoDett.validita_fine is null));

     -- STR - Stanziamento Residuo
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_RESIDUO|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento_res,null,
      parPerInsertElemBil.elemDetTipoIdStr, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento_res,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_RESIDUO and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

     -- SCA - Stanziamento Cassa
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_CASSA|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento_cassa,null,
 	  parPerInsertElemBil.elemDetTipoIdSca, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento_cassa,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_CASSA and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

	 -- STP - Stanziamento Proposto
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_PROP|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, 0,null,
	  parPerInsertElemBil.elemDetTipoIdStp, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, 0,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code= STANZ_PROP and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

     if tipoElab=TIPO_ELAB_G then
     	-- STASS - Stanziamento Assestamento
    	-- STCASS - Stanziamento Assestamento Cassa
   	  	-- STRASS - Stanziamento Assestamento Residuo
	     strMessaggio:='Inserimento siac_t_bil_elem_det stanziamenti di assestamento.';
    	 insert into siac_t_bil_elem_det
	     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
		  ente_proprietario_id,data_creazione,login_operazione)
	     (select bilElemIdRet, 0,null,
				 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
	  		     enteProprietarioId,statement_timestamp(),loginOperazione
	      from  siac_d_bil_elem_det_tipo capitoloTipoDett
    	  where capitoloTipoDett.elem_det_tipo_id in
                (parPerInsertElemBil.elemDetTipoIdStass,parPerInsertElemBil.elemDetTipoIdStasr,
                 parPerInsertElemBil.elemDetTipoIdStasc));


--          capitoloTipoDett.elem_det_tipo_code in ( STANZ_ASSEST,STANZ_ASSEST_CASSA,STANZ_ASSEST_RES) and
--      			capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      			capitoloTipoDett.data_cancellazione is null and
--	            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--    	        (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));
       end if;

     annoBilancio1:=parPerInsertElemBil.annoBilancio1;
     periodoId:=parPerInsertElemBil.periodoIdAnno1;
-- 12.01.015 Sofia spostato fuori ciclo
--     strMessaggio:='Lettura periodo per anno='||annoBilancio1||'.';
--     begin
--     	select per.periodo_id into periodoId
--        from siac_t_periodo per , siac_d_periodo_tipo perTipo
--        where per.anno=annoBilancio1 and
--              per.ente_proprietario_id=enteProprietarioId and
--              perTipo.periodo_tipo_id=per.periodo_tipo_id and
--              perTipo.periodo_tipo_code=PER_TIPO_ANNO_MY and
--            perTipo.ente_proprietario_id=enteProprietarioId;

--        exception
--            	when others  THEN
--	              RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
--     end;

	 -- STI - Stanziamento Iniziale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_INIZIALE||  'per anno='||annoBilancio1||'.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento_iniziale_anno2,null,
      parPerInsertElemBil.elemDetTipoIdSti, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento_iniziale_anno2,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--      		      or capitoloTipoDett.validita_fine is null));

	 -- STA - Stanziamento Attuale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_ATTUALE||  'per anno='||annoBilancio1||'.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento_anno2,null,
  	  parPerInsertElemBil.elemDetTipoIdSta, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);
--     (select bilElemIdRet, capitoloUscita.stanziamento_anno2,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_ATTUALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

	 -- STP - Stanziamento Proposto
     -- SRI - Stanziamento Residuo Iniziale
     -- SCI - Stanziamento Cassa Iniziale
     -- SRA - Stanziamento Residuo
     -- SCA - Stanziamento Cassa
     -- STASS - Stanziamento Assestamento
     -- STCASS - Stanziamento Assestamento Cassa
     -- STRASS - Stanziamento Assestamento Residuo
     strMessaggio:='Inserimento siac_t_bil_elem_det vari importi per anno='||annoBilancio1||'.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemIdRet, 0,null,
			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
	  	     enteProprietarioId,statement_timestamp(),loginOperazione
      from  siac_d_bil_elem_det_tipo capitoloTipoDett
      where  capitoloTipoDett.elem_det_tipo_id in
             (parPerInsertElemBil.elemDetTipoIdStp,
              parPerInsertElemBil.elemDetTipoIdSri,
              parPerInsertElemBil.elemDetTipoIdSci,
              parPerInsertElemBil.elemDetTipoIdSca,
              parPerInsertElemBil.elemDetTipoIdStr));

--       capitoloTipoDett.elem_det_tipo_code in
--               ( STANZ_PROP,
---                 STANZ_RES_INIZIALE,STANZ_CASSA_INIZIALE,STANZ_CASSA,STANZ_RESIDUO
--                ) and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

	 if tipoElab=TIPO_ELAB_G then
      -- STASS - Stanziamento Assestamento
      -- STCASS - Stanziamento Assestamento Cassa
      -- STRASS - Stanziamento Assestamento Residuo
      strMessaggio:='Inserimento siac_t_bil_elem_det stanziamenti assestamento per anno='||annoBilancio1||'.';
      insert into siac_t_bil_elem_det
      (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	   ente_proprietario_id,data_creazione,login_operazione)
      (select bilElemIdRet, 0,null,
  			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
 	  	     enteProprietarioId,statement_timestamp(),loginOperazione
       from  siac_d_bil_elem_det_tipo capitoloTipoDett
       where capitoloTipoDett.elem_det_tipo_id in
             (parPerInsertElemBil.elemDetTipoIdStass,
              parPerInsertElemBil.elemDetTipoIdStasr,
              parPerInsertElemBil.elemDetTipoIdStasc));

--       capitoloTipoDett.elem_det_tipo_code in
--               ( STANZ_ASSEST,STANZ_ASSEST_CASSA,STANZ_ASSEST_RES ) and
--       		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--       		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

     end if;

     annoBilancio2:=parPerInsertElemBil.annoBilancio2;
     periodoId:=parPerInsertElemBil.periodoIdAnno2;
--     periodoId:=0;
--     begin
--     	select per.periodo_id into periodoId
--        from siac_t_periodo per, siac_d_periodo_tipo perTipo
--        where per.anno=annoBilancio2 and
--              per.ente_proprietario_id=enteProprietarioId and
--              perTipo.periodo_tipo_id=per.periodo_tipo_id and
--              perTipo.periodo_tipo_code=PER_TIPO_ANNO_MY and
--              perTipo.ente_proprietario_id=enteProprietarioId;

--        exception
--            	when others  THEN
--	              RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
--     end;

	 -- STI - Stanziamento Iniziale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_INIZIALE||  'per anno='||annoBilancio2||'.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento_iniziale_anno3,null,
      parPerInsertElemBil.elemDetTipoIdSti, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento_iniziale_anno3,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

	 -- STA - Stanziamento Attuale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_ATTUALE||  'per anno='||annoBilancio2||'.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloUscita.stanziamento_anno3,null,
 	  parPerInsertElemBil.elemDetTipoIdSta, periodoId,dataInizioVal,
      enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloUscita.stanziamento_anno3,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_ATTUALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

	 -- STP - Stanziamento Proposto
     -- SRI - Stanziamento Residuo Iniziale
     -- SCI - Stanziamento Cassa Iniziale
     -- SRA - Stanziamento Residuo
     -- SCA - Stanziamento Cassa
     strMessaggio:='Inserimento siac_t_bil_elem_det vari importi per anno='||annoBilancio2||'.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemIdRet, 0,null,
			 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
	  	     enteProprietarioId,statement_timestamp(),loginOperazione
      from  siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_id in
             (parPerInsertElemBil.elemDetTipoIdStp,
              parPerInsertElemBil.elemDetTipoIdSri,
              parPerInsertElemBil.elemDetTipoIdSci,
              parPerInsertElemBil.elemDetTipoIdSca,
              parPerInsertElemBil.elemDetTipoIdStr));

--      capitoloTipoDett.elem_det_tipo_code in
--               ( STANZ_PROP,
--                 STANZ_RES_INIZIALE,STANZ_CASSA_INIZIALE,STANZ_CASSA,STANZ_RESIDUO
--                ) and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

	 if tipoElab=TIPO_ELAB_G then
	     -- STASS - Stanziamento Assestamento
    	 -- STCASS - Stanziamento Assestamento Cassa
	     -- STRASS - Stanziamento Assestamento Residuo
    	 strMessaggio:='Inserimento siac_t_bil_elem_det stanziamenti assestamento per anno='||annoBilancio2||'.';
	     insert into siac_t_bil_elem_det
    	 (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
		  ente_proprietario_id,data_creazione,login_operazione)
    	 (select bilElemIdRet, 0,null,
				 capitoloTipoDett.elem_det_tipo_id, periodoId,dataInizioVal,
	  	    	 enteProprietarioId,statement_timestamp(),loginOperazione
	      from  siac_d_bil_elem_det_tipo capitoloTipoDett
    	  where capitoloTipoDett.elem_det_tipo_id in
                (parPerInsertElemBil.elemDetTipoIdStass,
                 parPerInsertElemBil.elemDetTipoIdStasr,
                 parPerInsertElemBil.elemDetTipoIdStasc));

--          capitoloTipoDett.elem_det_tipo_code in
--        	       ( STANZ_ASSEST,STANZ_ASSEST_CASSA,STANZ_ASSEST_RES ) and
--    	  		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      			capitoloTipoDett.data_cancellazione is null and
--            	date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--    	    		      or capitoloTipoDett.validita_fine is null));
       end if;

     -- DAVIDE - 05.11.015 - popolamento tabella siac_t_dicuiimpegnato_bilprev
	 --DICUIIMPEGNATO_ANNO1
	 --DICUIIMPEGNATO_ANNO2
	 --DICUIIMPEGNATO_ANNO3
	 if tipoElab=TIPO_ELAB_P then
    	 strMessaggio:='Inserimento siac_t_dicuiimpegnato_bilprev dicuiimpegnato per anno='||annoBilancio||'.';
	     insert into siac_t_dicuiimpegnato_bilprev
    	 (bil_id,  elem_id,  dicuiimpegnato_anno1,
          dicuiimpegnato_anno2, dicuiimpegnato_anno3, ente_proprietario_id,
          data_creazione, login_operazione)
		 values
    	 (bilancioId, bilElemIdRet, capitolouscita.dicuiimpegnato_anno1,
		  capitolouscita.dicuiimpegnato_anno2, capitolouscita.dicuiimpegnato_anno3,
		  enteProprietarioId, statement_timestamp(), loginOperazione);
     end if;
     -- DAVIDE - 05.11.015 - Fine

    --- tipo_capitolo siac_r_bil_elem_categoria
    strMessaggio:='Inserimento tipo_capitolo '||capitoloUscita.classe_capitolo||'.';
    insert into siac_r_bil_elem_categoria
    (elem_id,  elem_cat_id, validita_inizio,
     ente_proprietario_id, data_creazione,login_operazione)
    (select bilElemIdRet,catBilElem.elem_cat_id, dataInizioVal,
        	enteProprietarioId,statement_timestamp(),loginOperazione
     from siac_d_bil_elem_categoria catBilElem
     where  catBilElem.elem_cat_code=capitoloUscita.classe_capitolo and
   	        catBilElem.ente_proprietario_id=enteProprietarioId and
            catBilElem.data_cancellazione is null and
	        date_trunc('day',dataElaborazione)>=date_trunc('day',catBilElem.validita_inizio) and
		    (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(catBilElem.validita_fine,statement_timestamp()))));
--      			      or catBilElem.validita_fine is null));

    --- attributi siac_r_bil_elem_attr

	if tipoElab=TIPO_ELAB_P then
		strMessaggio:='Inserimento attributo '||FLAG_PER_MEM||'.';
	    insert into siac_r_bil_elem_attr
    	(elem_id,attr_id,boolean,validita_inizio,
	     ente_proprietario_id,data_creazione,login_operazione)
        values
        (bilElemIdRet,parPerInsertElemBil.flagPerMemAttrId,
    	 COALESCE(capitoloUscita.flag_per_memoria,'N'), dataInizioVal,
	     enteProprietarioId,statement_timestamp(),loginOperazione);

--    	(select bilElemIdRet,attrTipi.attr_id,
--        	    COALESCE(capitoloUscita.flag_per_memoria,'N'), dataInizioVal,
--	        	enteProprietarioId,now(),loginOperazione
--	         from siac_t_attr attrTipi
--    	     where  attrTipi.attr_code=FLAG_PER_MEM and
--        	        attrTipi.ente_proprietario_id=enteProprietarioId and
--            	    attrTipi.data_cancellazione is null and
--	                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--		            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      			      or attrTipi.validita_fine is null));
     end if;


    strMessaggio:='Inserimento attributo '||FLAG_IMPEGNABILE||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,boolean,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.flagImpegnabileAttrId,
     COALESCE(capitoloUscita.flag_impegnabile,'S'), dataInizioVal,
	 enteProprietarioId,statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,attrTipi.attr_id,
--            COALESCE(capitoloUscita.flag_impegnabile,'S'), dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--         from siac_t_attr attrTipi
--         where  attrTipi.attr_code=FLAG_IMPEGNABILE and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));

	strMessaggio:='Inserimento attributo '||FLAG_RIL_IVA||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,boolean,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.flagRilIvaAttrId,
     COALESCE(capitoloUscita.flag_rilevante_iva,'N'), dataInizioVal,
     enteProprietarioId,statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,attrTipi.attr_id,
--            COALESCE(capitoloUscita.flag_rilevante_iva,'N'), dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--         from siac_t_attr attrTipi
--         where  attrTipi.attr_code=FLAG_RIL_IVA and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));

	strMessaggio:='Inserimento attributo '||FLAG_FONDO_SVAL_CRED||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,boolean,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.flagFondoSvalCredAttrId,
     'N', dataInizioVal,
     enteProprietarioId,statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,attrTipi.attr_id,
--           'N', dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--     from siac_t_attr attrTipi
--     where  attrTipi.attr_code=FLAG_FONDO_SVAL_CRED and
--            attrTipi.ente_proprietario_id=enteProprietarioId and
--            attrTipi.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));

	strMessaggio:='Inserimento attributo '||FLAG_FUNZ_DEL||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,boolean,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.flagFunzDelAttrId,
     (case when capitoloUscita.funzioni_delegate is not null then capitoloUscita.funzioni_delegate
           else 'N' END), dataInizioVal,      -- Davide - 05.04.016 - flag funzioni delegate se presente, si prende dalla migr
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,attrTipi.attr_id,
--           'N', dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--         from siac_t_attr attrTipi
--         where  attrTipi.attr_code=FLAG_FUNZ_DEL and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));




    strMessaggio:='Inserimento attributo '||FLAG_TRASF_ORG||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,boolean,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.flagTrasfOrgAttrId,
     'N', dataInizioVal,
	 enteProprietarioId,statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,attrTipi.attr_id,
--           'N', dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--         from siac_t_attr attrTipi
--         where  attrTipi.attr_code=FLAG_TRASF_ORG and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));

    strMessaggio:='Inserimento attributo '||NOTE_CAP||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,testo,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.noteCapAttrId,
     capitoloUscita.note, dataInizioVal,
     enteProprietarioId,statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,attrTipi.attr_id,
--            capitoloUscita.note, dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--      from siac_t_attr attrTipi
--         where  attrTipi.attr_code=NOTE_CAP and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));

   if coalesce(capitoloUscita.macroaggregato,NVL_STR)!=NVL_STR then
    -- macroaggragato
    classifId:=0;
    begin
    	strMessaggio:='Lettura macroaggregato codice= '||capitoloUscita.macroaggregato||'.';
    	select classif.classif_id into strict  classifId
        from siac_t_class classif, siac_d_class_tipo classTipo
        where classif.classif_code=capitoloUscita.macroaggregato and
              classif.ente_proprietario_id=enteProprietarioId and
              classif.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
	          (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,statement_timestamp()))) and
--      		      or classif.validita_fine is null) and
--              classTipo.ente_proprietario_id=enteProprietarioId and
              classTipo.classif_tipo_id=classif.classif_tipo_id and
              classTipo.classif_tipo_code=CL_MACROAGGREGATO and
              classTipo.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio) and
	          (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,statement_timestamp())));


      exception
       		when no_data_found then
                 --RAISE EXCEPTION 'Non esistente.';
                 strMessaggio:='Inserimento scarto per macroaggregato codice= '||capitoloUscita.macroaggregato||
                               ' elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_uscita_scarto
                 (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
                  statement_timestamp() , enteProprietarioId);

           	when others  THEN
	             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

	if classifId!=0 then
    	 strMessaggio:='Inserimento relazione macroaggregato codice= '||capitoloUscita.macroaggregato||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,classifId,dataInizioVal, enteProprietarioId,
		  statement_timestamp(),loginOperazione);

		  -- 12.01.2016	Daniela se macroaggregato Redditi per lavoro dipendete e titolo = 1 il class. RICORRENTE_SPESA impostato sarà RICORRENTE altrimenti NON RICORRENTE.
          if capitoloUscita.macroaggregato = MACROAGGREGATO_1 then
	          strMessaggio:='Ricerca Titolo per MacroAggregato id '||classifId||'.';

	          /*
              select titolo.classif_code into titoloCode
              from siac_t_class titolo,
              siac_v_bko_tit_mac v
              where v.classif_id=classifId -- id macroaggregato
              and v.classif_id_padre=titolo.classif_id;
				*/

	        select classif_fam_tree_id
				into strict classifFamiglia
            from  siac_t_class_fam_tree
            where ente_proprietario_id =enteProprietarioId
            	and class_fam_desc= CL_FAMIGLIA
            	and validita_fine is null;

			select classif_tipo_id
				into strict classifTitolo
			from siac_d_class_tipo
			where ente_proprietario_id =enteProprietarioId
				and validita_fine is null
				and classif_tipo_code = CL_TITOLO_SPESA;

			select classif_tipo_id into strict classifMacroaggregato
			from siac_d_class_tipo
			where ente_proprietario_id =enteProprietarioId
				and validita_fine is null
				and classif_tipo_code = CL_MACROAGGREGATO;



             select  cp.classif_code
             	into titoloCode
			 from
			 	siac_t_class cf,
			 	siac_r_class_fam_tree r,
			 	siac_t_class cp
			 where
			          cf.classif_id=classifId
				and   cf.data_cancellazione is null
				and   cf.validita_fine is null
				and   cf.classif_tipo_id= classifMacroaggregato
				and   r.classif_id=cf.classif_id
				and   r.classif_id_padre is not null
				and   r.classif_fam_tree_id=classifFamiglia -- famiglia
				and   r.data_cancellazione is null
				and   r.validita_fine is null
				and   cp.classif_id=r.classif_id_padre
				and   cp.data_cancellazione is null
				and   cp.validita_fine is null
				and   cp.classif_tipo_id=classifTitolo ;-- titolo_spesa






              if titoloCode = '1' then
                cl_ricorrente := CL_RICORRENTE_SPESA_RICORR;
              end if;

          end if;
    end if;
  ELSE
      strMessaggio:='Inserimento scarto per macroaggregato non indicato per  elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_uscita_scarto
                 (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
                  statement_timestamp() , enteProprietarioId);
  end if;

  -- DAVIDE - 07.10.2016 - inserimento valore RICORRENTE_SPESA dal tracciato dei capitoli se presente
  if coalesce(capitoloUscita.spesa_ricorrente,NVL_STR)!=NVL_STR then
      cl_ricorrente := capitoloUscita.spesa_ricorrente;
  end if;

  -- CL_RICORRENTE_SPESA 12.11.2015 Sofia impostare al valore corrispondente TRUE [3] di default
  begin
  		strMessaggio:='Inserimento relazione classif='||CL_RICORRENTE_SPESA||
                      ' elem_id='||bilElemIdRet||'.';
 		insert into siac_r_bil_elem_class
	    (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		 data_creazione,login_operazione)
	    (select bilElemIdRet,class.classif_id,dataInizioVal, enteProprietarioId,
   		        statement_timestamp(),loginOperazione
         from siac_t_class class, siac_d_class_tipo tipo
         where tipo.classif_tipo_code=CL_RICORRENTE_SPESA
         and   tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null
         and   class.classif_tipo_id=tipo.classif_tipo_id
--         and   class.classif_code=CL_RICORRENTE_SPESA_RICORR -- 12.01.2016 dipende dalla coppia macro/titolo
         and   class.classif_code=cl_ricorrente
         and   class.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
         and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(class.validita_fine,statement_timestamp())))
        )
        returning elem_classif_id into codResult;

        if codResult is null then
	        strMessaggio:='Inserimento scarto per classif='||CL_RICORRENTE_SPESA||
                          ' elem_id='||bilElemIdRet||'.Relazione siac_r_bil_elem_class non inserita per valore='||cl_ricorrente||'.';
            insert into migr_capitolo_uscita_scarto
            (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
             values
            (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
             statement_timestamp() , enteProprietarioId);
        end if;

		exception
       		when others  THEN
		    RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;


  -- 12.11.2015 Sofia calcolo cofog da programma
  classifProgrammaId:=0;
  if coalesce(capitoloUscita.programma,NVL_STR)!=NVL_STR then
    -- programma
    classifId:=0;
    begin
    	strMessaggio:='Lettura programma codice= '||capitoloUscita.programma||'.';
    	select classif.classif_id into strict  classifId
        from siac_t_class classif, siac_d_class_tipo classTipo
        where classif.classif_code=capitoloUscita.programma and
              classif.ente_proprietario_id=enteProprietarioId and
              classif.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
	          (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now()))) and
--      		      or classif.validita_fine is null) and
--              classTipo.ente_proprietario_id=enteProprietarioId and
              classTipo.classif_tipo_id=classif.classif_tipo_id and
              classTipo.classif_tipo_code=CL_PROGRAMMA and
              classTipo.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio) and
	          (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,now())));

      exception
       		when no_data_found then
                -- RAISE EXCEPTION 'Non esistente.';
                strMessaggio:='Inserimento scarto per programma codice= '||capitoloUscita.programma||
                               ' elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_uscita_scarto
                 (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
                  statement_timestamp() , enteProprietarioId);
           	when others  THEN
	             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

	if classifId!=0 then
    	 codResult:=null;
    	 strMessaggio:='Inserimento relazione programma codice= '||capitoloUscita.programma||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione)
         returning elem_classif_id into codResult;

	     -- 12.11.2015 Sofia gestione salvataggio programmaId
         if codResult is null then
	        strMessaggio:='Inserimento scarto per classif='||CL_PROGRAMMA||
                          ' elem_id='||bilElemIdRet||'.Relazione siac_r_bil_elem_class non inserita per valore='||capitoloUscita.programma||'.';
            insert into migr_capitolo_uscita_scarto
            (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
             values
            (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
             statement_timestamp() , enteProprietarioId);
         else
         	classifProgrammaId:=classifId;    -- 12.11.2015 Sofia gestione salvataggio programmaId
         end if;

    end if;
 else
  				strMessaggio:='Inserimento scarto per programma non indicato per  elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_uscita_scarto
                 (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
                  statement_timestamp() , enteProprietarioId);
 end if;


 -- 20.04.2015 dani gestione info cofog come classificatore
 if coalesce(capitoloUscita.cofog,NVL_STR)!=NVL_STR then
    -- cofog
    classifId:=0;
    begin
    	strMessaggio:='Lettura cofog codice= '||capitoloUscita.cofog||'.';
    	select classif.classif_id into strict  classifId
        from siac_t_class classif, siac_d_class_tipo classTipo
        where classif.classif_code=capitoloUscita.cofog and
              classif.ente_proprietario_id=enteProprietarioId and
              classif.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
	          (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,statement_timestamp()))) and
              classTipo.classif_tipo_id=classif.classif_tipo_id and
              classTipo.classif_tipo_code=CL_COFOG and
              classTipo.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio) and
	          (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,statement_timestamp())));
      exception
       		when no_data_found then
                 strMessaggio:='Inserimento scarto per cofog codice= '||capitoloUscita.cofog||
                               ' elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_uscita_scarto
                 (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
                  statement_timestamp() , enteProprietarioId);

           	when others  THEN
	             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

	if classifId!=0 then
    	 strMessaggio:='Inserimento relazione cofog codice= '||capitoloUscita.cofog||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,classifId,dataInizioVal, enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;
  ELSE -- 12.11.2015 Sofia calcolo cofog da programma
     classifId:=0;
     if classifProgrammaId!=0 then
      begin
      strMessaggio:='Cofog non indicato letture per programma codice= '||capitoloUscita.programma||'.';
      select classCofog.classif_id into classifId
	  from siac_r_class r,
     	   siac_t_class classCofog,siac_d_class_tipo classCofogTipo
	  where r.ente_proprietario_id=enteProprietarioid
	  and   r.data_cancellazione is null
	  and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
      and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(r.validita_fine,statement_timestamp())))
	  and   r.classif_a_id=classifProgrammaId
	  and   classCofog.classif_id=r.classif_b_id
	  and   classCofog.data_cancellazione is null
	  and   date_trunc('day',dataElaborazione)>=date_trunc('day',classCofog.validita_inizio)
      and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classCofog.validita_fine,statement_timestamp())))
	  and   classCofogTipo.classif_tipo_id=classCofog.classif_tipo_id
	  and   classCofogTipo.classif_tipo_code=CL_COFOG
      and   classCofogTipo.data_cancellazione is null
	  and   date_trunc('day',dataElaborazione)>=date_trunc('day',classCofogTipo.validita_inizio)
      and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classCofogTipo.validita_fine,statement_timestamp())))
      order by  classCofog.classif_code
      limit 1;

      if classifId is not null and classifId!=0 then
         codResult:=null;
      	 strMessaggio:='Inserimento relazione cofog per programma codice= '||capitoloUscita.programma||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,classifId,dataInizioVal, enteProprietarioId,
		  statement_timestamp(),loginOperazione)
         returning elem_classif_id into codResult;

         if codResult is null then
	        strMessaggio:='Inserimento scarto per cofog ricavato da programma='||capitoloUscita.programma||
                          ' elem_id='||bilElemIdRet||'.Relazione siac_r_bil_elem_class non inserita.';
            insert into migr_capitolo_uscita_scarto
            (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
             values
            (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
             statement_timestamp() , enteProprietarioId);
         end if;
      else
         	strMessaggio:='Inserimento scarto per cofog non ricavato da programma='||capitoloUscita.programma||
                          ' elem_id='||bilElemIdRet||'.';
            insert into migr_capitolo_uscita_scarto
            (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
             values
            (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
             statement_timestamp() , enteProprietarioId);
      end if;

      exception
         	when others  THEN
	             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
      end;
    else
      strMessaggio:='Inserimento scarto per cofog non indicato e programma non ricavato per  elem_id='||bilElemIdRet||'.';
      insert into migr_capitolo_uscita_scarto
      (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
       values
      (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
      statement_timestamp() , enteProprietarioId);
    end if;
  end if;




    -- PDC_FIN
    pdcFin:=null;
    classifPdcFin:=null;
    if coalesce(capitoloUscita.pdc_fin_quinto,NVL_STR)!=NVL_STR then
    	pdcFin:=capitoloUscita.pdc_fin_quinto;
        classifPdcFin:=CL_PDC_FIN_QUINTO;
    elsif coalesce(capitoloUscita.pdc_fin_quarto,NVL_STR)!=NVL_STR then
    	pdcFin:=capitoloUscita.pdc_fin_quarto;
        classifPdcFin:=CL_PDC_FIN_QUARTO;
    end if;

    if coalesce(pdcFin,NVL_STR)!=NVL_STR then
    	classifId:=0;
    	begin
    		strMessaggio:='Lettura '||classifPdcFin||' codice= '||pdcFin||'.';
    		select classif.classif_id into strict classifId
        	from siac_t_class classif, siac_d_class_tipo classTipo
       		where classif.classif_code=pdcFin and
            	  classif.ente_proprietario_id=enteProprietarioId and
    	       	  classif.data_cancellazione is null and
	              date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
	              (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now()))) and
--      			      or classif.validita_fine is null) and
--            	  classTipo.ente_proprietario_id=enteProprietarioId and
	              classTipo.classif_tipo_id=classif.classif_tipo_id and
    	          classTipo.classif_tipo_code=classifPdcFin and
                  classTipo.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio) and
	              (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,now())));

	      exception
    	   		when no_data_found then
        	         --RAISE EXCEPTION 'Non esistente.';
                      strMessaggio:='Inserimento scarto per '||classifPdcFin||' codice= '||pdcFin||
                               ' elem_id='||bilElemIdRet||'.';
	                  insert into migr_capitolo_uscita_scarto
	                  (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                       values
                      (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
                        statement_timestamp() , enteProprietarioId);

	           	when others  THEN
		             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

	    end;

        if classifId!=0 then
    	 strMessaggio:='Inserimento relazione '||classifPdcFin||' codice= '||pdcFin||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    	end if;
    else
    	  strMessaggio:='Inserimento scarto per PdcFin non presente per elem_id='||bilElemIdRet||'.';
          insert into migr_capitolo_uscita_scarto
          (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
          values
          (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
           statement_timestamp() , enteProprietarioId);
    end if;





    -- SAC
    strMessaggio:='Lettura Struttura amministrativo contabile.';
    sacCode:=null;
    classifSac:=null;
    if coalesce(capitoloUscita.cdc,NVL_STR)!=NVL_STR then
    	sacCode:=capitoloUscita.cdc;
        classifSac:=CL_CDC;
        sacCodeDef:=CDC_DEF;
    elsif coalesce(capitoloUscita.centro_resp,NVL_STR)!=NVL_STR then
    	sacCode:=capitoloUscita.centro_resp;
        classifSac:=CL_CDR;
        sacCodeDef:=CDR_DEF;
--    else
 --   	RAISE EXCEPTION 'Informazione non migrata.';
    end if;

    if coalesce(sacCode,NVL_STR)!=NVL_STR then
    	classifId:=0;
    	begin
    		strMessaggio:='Lettura '||classifSac||' codice= '||sacCode||'.';
    		select classif.classif_id into strict classifId
        	from siac_t_class classif, siac_d_class_tipo classTipo
       		where classif.classif_code=sacCode and
            	  classif.ente_proprietario_id=enteProprietarioId and
    	       	  classif.data_cancellazione is null and
	              date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
	              (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now()))) and
--      			      or classif.validita_fine is null) and
--            	  classTipo.ente_proprietario_id=enteProprietarioId and
	              classTipo.classif_tipo_id=classif.classif_tipo_id and
    	          classTipo.classif_tipo_code=classifSac and
                  classTipo.data_cancellazione is null and
	              date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio) and
	              (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,now())));

	      exception
    	   		when no_data_found then
        	     --    RAISE EXCEPTION 'Non esistente.';
                 begin
                  strMessaggio:='Lettura '||classifSac||' default codice= '||sacCodeDef||' codice='||
                                 sacCode||' non presente.';
	    		  select classif.classif_id into strict classifId
	          	  from siac_t_class classif, siac_d_class_tipo classTipo
	         	  where classif.classif_code=sacCodeDef and
            	        classif.ente_proprietario_id=enteProprietarioId and
    	       	        classif.data_cancellazione is null and
	                    date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
	                    (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now()))) and
--      			           or classif.validita_fine is null) and
--            	        classTipo.ente_proprietario_id=enteProprietarioId and
	                    classTipo.classif_tipo_id=classif.classif_tipo_id and
    	                classTipo.classif_tipo_code=classifSac and
                        classTipo.data_cancellazione is null and
	                    date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio) and
	                    (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,now())));

                   sacCode:=sacCodeDef;

                   exception
	    	   		when no_data_found then
    	    	       RAISE EXCEPTION 'Non esistente.';
                    when others  THEN
	  	               RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
                  end;
	           	when others  THEN
		             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	    end;

        if classifId!=0 then
    	 strMessaggio:='Inserimento relazione '||classifSac||' codice= '||sacCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    	end if;
    else
	      strMessaggio:='Inserimento scarto per Sac non presente per elem_id='||bilElemIdRet||'.';
          insert into migr_capitolo_uscita_scarto
          (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
          values
          (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
           statement_timestamp() , enteProprietarioId);
    end if;

	-- siope_livello_1
    -- siope_livello_2
    -- siope_livello_3
    -- 27.11.2015 Davide gestione siope
    begin
	-- Cerca se l'Ente ha il SIOPE di default e prendi quello se esiste
    	classifId:=0;
	    select classif.classif_id into classifId
		   from siac_t_class classif, siac_d_class_tipo classTipo
		  where classif.ente_proprietario_id=enteproprietarioid
		    and classif.classif_code=SIOPECOD_DEF
            and classif.data_cancellazione is null
	        and date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio)
	        and (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now())))
            and classTipo.classif_tipo_id=classif.classif_tipo_id
            and classTipo.classif_tipo_code=CL_SIOPE_TERZO
            and classTipo.data_cancellazione is null
	        and date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio)
	        and (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,now())));
	exception
      	 when others  THEN
    	     classifId:=0;
	end;

    if classifId=0 or classifId is null  then
	    if coalesce(capitoloUscita.siope_livello_3,NVL_STR)!=NVL_STR then
    	    begin
    	        strMessaggio:='Lettura '||CL_SIOPE_TERZO||' codice= '||capitoloUscita.siope_livello_3||'.';
    	        select classif.classif_id into classifId
                  from siac_t_class classif, siac_d_class_tipo classTipo
       	         where classif.classif_code=capitoloUscita.siope_livello_3 and
                       classif.ente_proprietario_id=enteProprietarioId and
    	               classif.data_cancellazione is null and
	                   date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
	                   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now()))) and
--      			      or classif.validita_fine is null) and
--            	  classTipo.ente_proprietario_id=enteProprietarioId and
	                   classTipo.classif_tipo_id=classif.classif_tipo_id and
    	               classTipo.classif_tipo_code=CL_SIOPE_TERZO and
                       classTipo.data_cancellazione is null and
	                   date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio) and
	                   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,now())));

                     -- 13.11.2015 Sofia gestione siope
	            if classifId=0 or classifId is null then
          	        strMessaggio:='Inserimento scarto per Siope codice='||capitoloUscita.siope_livello_3||' non presente per elem_id='||bilElemIdRet||'.';
         	        insert into migr_capitolo_uscita_scarto
         	        (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
         	        values
        	        (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
           	         statement_timestamp() , enteProprietarioId);
                end if;

	        exception
    	   		when no_data_found then
        	        RAISE EXCEPTION 'Non esistente.';
	            when others  THEN
		            RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
	        end;

        end if;
    end if;

    -- 27.11.2015 Davide gestione siope - inserimento relazione in un'unico punto
	if classifId!=0 then
        strMessaggio:='Inserimento relazione '||CL_SIOPE_TERZO||' codice= '||capitoloUscita.siope_livello_3||'.';
   		insert into siac_r_bil_elem_class
	    (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		 data_creazione,login_operazione)
        values
	    (bilElemIdRet,classifId,dataInizioVal , enteProprietarioId,
		 statement_timestamp(),loginOperazione);
 	else
	    -- segnalazione di relazione non inserita per mancanza totale del SIOPE
 		RAISE NOTICE '% % WARNING : %',strMessaggioFinale,strMessaggio, 'Relazione non inserita causa non reperimento Codice SIOPE!!!';
    end if;

    -- classificatori specifici e generici
    -- tipo_finanziamento
	if coalesce(capitoloUscita.tipo_finanziamento)!=NVL_STR then
    	strMessaggio:='Tipo Finanziamento.';
        strToElab:=capitoloUscita.tipo_finanziamento;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_TIPO_FINANZIAMENTO,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_TIPO_FINANZIAMENTO||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);

    end if;


    -- tipo_fondo
    if coalesce(capitoloUscita.tipo_fondo)!=NVL_STR then
    	strMessaggio:='Tipo Fondo.';
        strToElab:=capitoloUscita.tipo_fondo;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_TIPO_FONDO,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_TIPO_FONDO||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

  -- CL_TRANSAZIONE_UE_SPESA 12.01.2016 Daniela impostare al valore di default
    begin
  		strMessaggio:='Inserimento relazione classif='||CL_TRANSAZIONE_UE_SPESA||
                      ' elem_id='||bilElemIdRet||'.';
		-- Davide - 05.04.016 - se presente, l'attributo TRASF_COMU si prende dalla migr.
		if capitolouscita.trasferimenti_comunitari is not null then
		    trasf_comu := capitolouscita.trasferimenti_comunitari;
		else
		    trasf_comu := CL_TRANSAZIONE_UE_SPESA_DEF;
        end if;

 		insert into siac_r_bil_elem_class
	    (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		 data_creazione,login_operazione)
	    (select bilElemIdRet,class.classif_id,dataInizioVal, enteProprietarioId,
   		        statement_timestamp(),loginOperazione
         from siac_t_class class, siac_d_class_tipo tipo
         where tipo.classif_tipo_code=CL_TRANSAZIONE_UE_SPESA
         and   tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null
         and   class.classif_tipo_id=tipo.classif_tipo_id
         --and   class.classif_code=CL_TRANSAZIONE_UE_SPESA_DEF
         and   class.classif_code=trasf_comu          -- Davide - 05.04.016
         and   class.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
         and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(class.validita_fine,statement_timestamp())))
        )
        returning elem_classif_id into codResult;

        if codResult is null then
	        strMessaggio:='Inserimento scarto per classif='||CL_TRANSAZIONE_UE_SPESA||
             --             ' elem_id='||bilElemIdRet||'.Relazione siac_r_bil_elem_class non inserita per valore='||CL_TRANSAZIONE_UE_SPESA_DEF||'.';
                          ' elem_id='||bilElemIdRet||'.Relazione siac_r_bil_elem_class non inserita per valore='||trasf_comu||'.';
            insert into migr_capitolo_uscita_scarto
            (migr_capusc_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
             values
            (capitoloUscita.migr_capusc_id,bilElemIdRet,bilElemTipo,strMessaggio,
             statement_timestamp() , enteProprietarioId);
        end if;

		exception
       		when others  THEN
		    RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

    -- classificatore_1
    if coalesce(capitoloUscita.classificatore_1)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_1||'.';
        strToElab:=capitoloUscita.classificatore_1;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_1,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_1||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_2
    if coalesce(capitoloUscita.classificatore_2)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_2||'.';
        strToElab:=capitoloUscita.classificatore_2;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_2,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_2||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_3
    if coalesce(capitoloUscita.classificatore_3)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_3||'.';
        strToElab:=capitoloUscita.classificatore_3;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_3,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_3||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_4
    if coalesce(capitoloUscita.classificatore_4)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_4||'.';
        strToElab:=capitoloUscita.classificatore_4;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_4,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_4||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_5
    if coalesce(capitoloUscita.classificatore_5)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_5||'.';
        strToElab:=capitoloUscita.classificatore_5;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_5,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_5||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_6
    if coalesce(capitoloUscita.classificatore_6)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_6||'.';
        strToElab:=capitoloUscita.classificatore_6;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_6,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_6||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_7
    if coalesce(capitoloUscita.classificatore_7)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_7||'.';
        strToElab:=capitoloUscita.classificatore_7;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_7,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_7||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

	 -- classificatore_8
    if coalesce(capitoloUscita.classificatore_8)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_8||'.';
        strToElab:=capitoloUscita.classificatore_8;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_8,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_8||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_9
    if coalesce(capitoloUscita.classificatore_9)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_9||'.';
        strToElab:=capitoloUscita.classificatore_9;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_9,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_9||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_10
    if coalesce(capitoloUscita.classificatore_10)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_10||'.';
        strToElab:=capitoloUscita.classificatore_10;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_10,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_10||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- oltre i primi 10
    -- classificatore_11
    if coalesce(capitoloUscita.classificatore_11)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_11||'.';
        strToElab:=capitoloUscita.classificatore_11;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_11,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_11||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_12
    if coalesce(capitoloUscita.classificatore_12)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_12||'.';
        strToElab:=capitoloUscita.classificatore_12;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_12,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_12||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_13
    if coalesce(capitoloUscita.classificatore_13)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_13||'.';
        strToElab:=capitoloUscita.classificatore_13;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_13,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_13||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_14
	if coalesce(capitoloUscita.classificatore_14)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_14||'.';
        strToElab:=capitoloUscita.classificatore_14;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_14,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_14||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;

    -- classificatore_15
	if coalesce(capitoloUscita.classificatore_15)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloUscita.classificatore_14||'.';
        strToElab:=capitoloUscita.classificatore_15;
        classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));
    	select * into migrClassif
        from fnc_migr_classif(CL_CLASSIFICATORE_15,
        				      classifCode,classifDesc,
 						      enteProprietarioId,loginOperazione,dataElaborazione,dataInizioVal);
         if migrClassif.codiceRisultato=-1 then
         		RAISE EXCEPTION ' % ', migrClassif.messaggioRisultato;
         end if;

         strMessaggio:='Inserimento relazione '||CL_CLASSIFICATORE_15||' codice= '||classifCode||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,migrClassif.classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);
    end if;


    bilElemId:=bilElemIdRet;
    messaggioRisultato:=strMessaggioFinale||'OK .';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;