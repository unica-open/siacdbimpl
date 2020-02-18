/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_inserisci_capitolo_entrata (
  tipoelab varchar,
  bilancioid integer,
  annobilancio varchar,
  bilelemtipo varchar,
  parPerInsertElemBil parPerInsertElemBilType,
  capitoloentrata siac.migr_capitolo_entrata,
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

	-- fnc_inserisci_capitolo_entrata --> function che inserisce un capitolo di entrata passato in input
     -- effettua inserimento di
      -- siac_t_bil_elem --> anagrafica
      -- siac_t_bil_elem_dett  --> dettaglio importi
      -- siac_r_bil_elem_stato --> stato
      -- siac_r_bil_elem_attr  --> attributi (FlagRilevanteIva, Note)
      -- siac_r_bil_elem_class --> associazione con i vari classificatori ( siac_t_class )
        -- categoria
        -- pdc_fin_iv, pdc_fin_v
        -- siope_livello_iii
        -- cdc,cdr
        -- tipo_finanziamento, tipo_fondo
        -- classificatore_36 .. classificatore_45   --> specifici e generici
        -- classififcatore_46 .. classificatore_50  --> generici x eventuali stampe ma non gestisti
      -- richiama
		-- fnc_migr_classif --> verifica esistenza dei classificatori specifici o generici ed eventualmente inserisce
      -- restituisce
       -- messaggioRisultato=risultato in formato testo
       -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)
       -- bilElemId=elem_id del siac_t_bil_elem inserito

    bilElemIdRet integer := 0;
    bilElemTipoId integer :=0;
    periodoId integer :=0;

    bilElemIdPadre INTEGER:=null;
    livelloBilElem siac_t_bil_elem.livello%type:=1;

	classifFamentrata integer :=0;
	classifCategoria integer  :=0;
	classifTipologia integer  :=0;
	classifTitEntrata integer  :=0;
			
	classifId integer :=0;
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

    migrClassif record;

    annoBilancio1 varchar(10):='';
    annoBilancio2 varchar(10):='';
    
	-- Davide - 05.04.016 - variabile per attributo "Trasferimenti Comunitari"
	trasf_comu varchar(1):='';

	dataInizioVal timestamp:=null;

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
    FLAG_RIL_IVA CONSTANT varchar :='FlagRilevanteIva';
    NOTE_CAP     CONSTANT varchar :='Note';
    FLAG_PER_MEM CONSTANT varchar :='FlagPerMemoria';
    FLAG_ACCERTABILE CONSTANT varchar :='FlagImpegnabile';

	-- CLASSIFICATORI
	--CL_CATEGORIA CONSTANT varchar :='CATEGORIA';
    CL_CDC CONSTANT varchar :='CDC';
    CL_CDR CONSTANT varchar :='CDR';

    CL_PDC_FIN_QUARTO CONSTANT varchar :='PDC_IV';
    CL_PDC_FIN_QUINTO CONSTANT varchar :='PDC_V';
    CL_TIPO_FINANZIAMENTO CONSTANT varchar :='TIPO_FINANZIAMENTO';
	CL_TIPO_FONDO         CONSTANT varchar :='TIPO_FONDO';
	CL_SIOPE_TERZO        CONSTANT varchar:='SIOPE_ENTRATA_I'; -- 13.11.2015 Sofia gestione siope

  	-- Sofia 12.11.2015 - impostazione default ricorrente
	CL_RICORRENTE_ENTRATA CONSTANT varchar:='RICORRENTE_ENTRATA';
    CL_RICORRENTE_ENTRATA_RICORR CONSTANT varchar:= '1';
    cl_ricorrente varchar := '2';-- 12.01.2016 Il Valore di Defualt impostato è NON RICORRENTE.

    --12.01.2016 Daniela impostazione default TRANSAZIONE_UE
	CL_TRANSAZIONE_UE_ENTRATA CONSTANT varchar:='TRANSAZIONE_UE_ENTRATA';
    CL_TRANSAZIONE_UE_ENTRATA_DEF CONSTANT varchar:= '2' ;


    CL_CLASSIFICATORE_1   CONSTANT varchar :='CLASSIFICATORE_36';
    CL_CLASSIFICATORE_2   CONSTANT varchar :='CLASSIFICATORE_37';
    CL_CLASSIFICATORE_3   CONSTANT varchar :='CLASSIFICATORE_38';
    CL_CLASSIFICATORE_4   CONSTANT varchar :='CLASSIFICATORE_39';
    CL_CLASSIFICATORE_5   CONSTANT varchar :='CLASSIFICATORE_40';
    CL_CLASSIFICATORE_6   CONSTANT varchar :='CLASSIFICATORE_41';
    CL_CLASSIFICATORE_7   CONSTANT varchar :='CLASSIFICATORE_42';
    CL_CLASSIFICATORE_8   CONSTANT varchar :='CLASSIFICATORE_43';
    CL_CLASSIFICATORE_9   CONSTANT varchar :='CLASSIFICATORE_44';
    CL_CLASSIFICATORE_10   CONSTANT varchar :='CLASSIFICATORE_45';


    CL_CLASSIFICATORE_11   CONSTANT varchar :='CLASSIFICATORE_46';
    CL_CLASSIFICATORE_12   CONSTANT varchar :='CLASSIFICATORE_47';
    CL_CLASSIFICATORE_13   CONSTANT varchar :='CLASSIFICATORE_48';
    CL_CLASSIFICATORE_14   CONSTANT varchar :='CLASSIFICATORE_49';
    CL_CLASSIFICATORE_15   CONSTANT varchar :='CLASSIFICATORE_50';
    SIOPECOD_DEF           CONSTANT varchar :='XXXX';          -- 27.11.2015 Davide gestione siope

    CL_FAMIGLIA   CONSTANT varchar :='Entrata - TitoliTipologieCategorie';
	CL_CATEGORIA   CONSTANT varchar :='CATEGORIA';
	CL_TIPOLOGIA   CONSTANT varchar :='TIPOLOGIA';
	CL_TITOLO_ENTRATA  CONSTANT varchar :='TITOLO_ENTRATA';
	
	NVL_STR CONSTANT varchar :='';
    SEPARATORE CONSTANT varchar :='||';

    TIPO_ELAB_P CONSTANT varchar :='P'; -- gestione
    TIPO_ELAB_G CONSTANT varchar :='G'; -- previsione

    CDC_DEF CONSTANT varchar :='00';
    CDR_DEF CONSTANT varchar :='000';

	codResult integer:=null;
	titoloCode varchar := ''; -- Codice del titolo associato alla categoria del capitolo. Usato per determinare il classificatore RICORRENTE da usare.

BEGIN

    messaggioRisultato:='';
    codiceRisultato:=0;
	bilElemId:=0;

--    dataInizioVal:=annoBilancio||'-01-01';
    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Inserimento capitolo entrata  '||bilElemTipo||
    					'.Elemento bilancio anno '||annoBilancio||' '||
                        capitoloEntrata.numero_capitolo||'/'||capitoloEntrata.numero_articolo||'/'||capitoloEntrata.numero_ueb||
                        ' migr_capent_id='||capitoloEntrata.migr_capent_id||'.';

-- 12.01.015 Sofia spostato fuori
--	strMessaggio:='Lettura Identificativo elemento tipo '||bilElemTipo||'.';
    -- Dovra esserci un unico elemento valido
--    select elem_tipo_id into bilElemTipoId
--	from siac_d_bil_elem_tipo
--	where elem_tipo_code=bilElemTipo and
--	      ente_proprietario_id=enteProprietarioId and
--          data_cancellazione is null and
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
   (--rtrim(ltrim(to_char(capitoloEntrata.numero_capitolo,'999999'))),
    capitoloEntrata.numero_capitolo::varchar,
--    rtrim(ltrim(to_char(capitoloEntrata.numero_articolo,'999999'))),
    capitoloEntrata.numero_articolo::varchar,
    coalesce(capitoloEntrata.numero_ueb,'1'),
    capitoloEntrata.descrizione,capitoloEntrata.descrizione_articolo,
    bilElemIdPadre,parPerInsertElemBil.bilElemTipoId,bilancioId,
--    lpad(ltrim(rtrim(to_char(capitoloEntrata.numero_capitolo,'999999'))), 5, '0'),
    lpad(capitoloEntrata.numero_capitolo::varchar, 5, '0'),
    livelloBilElem, dataInizioVal,enteProprietarioId,statement_timestamp(),loginOperazione)
   returning elem_id into bilElemIdRet;

    -- stato siac_r_bil_elem_stato
    strMessaggio:='Inserimento siac_r_bil_elem_stato.';
    insert into siac_r_bil_elem_stato
    (elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,
     data_creazione,login_operazione)
     values
    (bilElemIdRet,parPerInsertElemBil.elemStatoIdValido,dataInizioVal,enteProprietarioId,
     statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,capitoloStato.elem_stato_id,now(),capitoloStato.ente_proprietario_id,
--           now(),loginOperazione
--     from  siac_d_bil_elem_stato capitoloStato
--     where capitoloStato.elem_stato_code= STATO_VALIDO and
--           capitoloStato.ente_proprietario_id=enteProprietarioId and
--           capitoloStato.data_cancellazione is null and
--           date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloStato.validita_inizio) and
--           (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloStato.validita_fine)
--             or capitoloStato.validita_fine is null));

     -- importi siac_t_bil_elem_det
     periodoId:=parPerInsertElemBil.periodoIdAnno;
--     periodoId:=0;
--     strMessaggio:='Lettura periodo per anno='||annoBilancio||'.';
--     begin
--     	select per.periodo_id into periodoId
--        from siac_t_periodo per, siac_d_periodo_tipo perTipo
--        where per.anno=annoBilancio and
--              per.ente_proprietario_id=enteProprietarioId and
--              perTipo.periodo_tipo_id=per.periodo_tipo_id and
--              perTipo.periodo_tipo_code=PER_TIPO_ANNO_MY and
--              perTipo.ente_proprietario_id=enteProprietarioId;

--        exception
--            	when others  THEN
--	              RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
--     end;

	 -- STI - Stanziamento Iniziale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_INIZIALE|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloEntrata.stanziamento_iniziale,null,
      parPerInsertElemBil.elemDetTipoIdSti, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);
--     (select bilElemIdRet, capitoloEntrata.stanziamento_iniziale,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));

     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_RES_INIZIALE|| ' .';
	 -- SRI - Stanziamento Residuo Iniziale
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloEntrata.stanziamento_iniziale_res,null,
      parPerInsertElemBil.elemDetTipoIdSri, periodoId,dataInizioVal,
      enteProprietarioId,statement_timestamp(),loginOperazione);
--     (select bilElemIdRet, capitoloEntrata.stanziamento_iniziale_res,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_RES_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));

     -- SCI - Stanziamento Cassa Iniziale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_CASSA_INIZIALE|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloEntrata.stanziamento_iniziale_cassa,null,
	  parPerInsertElemBil.elemDetTipoIdSci, periodoId,dataInizioVal,
      enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloEntrata.stanziamento_iniziale_cassa,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_CASSA_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));


     -- STA - Stanziamento Attuale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_ATTUALE|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloEntrata.stanziamento,null,
	  parPerInsertElemBil.elemDetTipoIdSta, periodoId,dataInizioVal,
      enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloEntrata.stanziamento,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_ATTUALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));

     -- STR - Stanziamento Residuo
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_RESIDUO|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloEntrata.stanziamento_res,null,
      parPerInsertElemBil.elemDetTipoIdStr, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloEntrata.stanziamento_res,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_RESIDUO and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));

     -- SCA - Stanziamento Cassa
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_CASSA|| ' .';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloEntrata.stanziamento_cassa,null,
	  parPerInsertElemBil.elemDetTipoIdSca, periodoId,dataInizioVal,
      enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloEntrata.stanziamento_cassa,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_CASSA and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
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
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code=STANZ_PROP and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
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
       from siac_d_bil_elem_det_tipo capitoloTipoDett
       where capitoloTipoDett.elem_det_tipo_id in
             (parPerInsertElemBil.elemDetTipoIdStass,
              parPerInsertElemBil.elemDetTipoIdStasr,
              parPerInsertElemBil.elemDetTipoIdStasc));


--       capitoloTipoDett.elem_det_tipo_code in ( STANZ_ASSEST,STANZ_ASSEST_CASSA,STANZ_ASSEST_RES) and
--       	     capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--        	 capitoloTipoDett.data_cancellazione is null and
--             date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--             (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));
     end if;

	 annoBilancio1:=parPerInsertElemBil.annoBilancio1;
	 periodoId:=parPerInsertElemBil.periodoIdAnno1;

--     strMessaggio:='Lettura periodo per anno='||annoBilancio1||'.';
--     periodoId:=0;
--     begin
--     	select per.periodo_id into periodoId
--        from siac_t_periodo per, siac_d_periodo_tipo perTipo
--        where per.anno=annoBilancio1 and
--              per.ente_proprietario_id=enteProprietarioId and
--              perTipo.periodo_tipo_id=per.periodo_tipo_id and
--              perTipo.periodo_tipo_code=PER_TIPO_ANNO_MY and
--              perTipo.ente_proprietario_id=enteProprietarioId;

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
     (bilElemIdRet, capitoloEntrata.stanziamento_iniziale_anno2,null,
      parPerInsertElemBil.elemDetTipoIdSti, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloEntrata.stanziamento_iniziale_anno2,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));

	 -- STA - Stanziamento Attuale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_ATTUALE||  'per anno='||annoBilancio1||'.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloEntrata.stanziamento_anno2,null,
 	  parPerInsertElemBil.elemDetTipoIdSta, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloEntrata.stanziamento_anno2,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_ATTUALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));

	 -- STP - Stanziamento Proposto
     -- SRI - Stanziamento Residuo Iniziale
     -- SCI - Stanziamento Cassa Iniziale
     -- SRA - Stanziamento Residuo
     -- SCA - Stanziamento Cassa
     strMessaggio:='Inserimento siac_t_bil_elem_det vari importi per anno='||annoBilancio1||'.';
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
--          (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));

	 if tipoElab=TIPO_ELAB_G then
      -- STASS - Stanziamento Assestamento
      -- STCASS - Stanziamento Assestamento Cassa
      -- STRASS - Stanziamento Assestamento Residuo
		 strMessaggio:='Inserimento siac_t_bil_elem_det stanziamento assestamento per anno='||annoBilancio1||'.';
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
--        	       ( STANZ_ASSEST,STANZ_ASSEST_CASSA,STANZ_ASSEST_RES) and
--      			capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--	      		capitoloTipoDett.data_cancellazione is null and
--    	        date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--        	    (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        			      or capitoloTipoDett.validita_fine is null));
     end if;

	 annoBilancio2:=parPerInsertElemBil.annoBilancio2;
     periodoId:=parPerInsertElemBil.periodoIdAnno2;
  --   strMessaggio:='Lettura periodo per anno='||annoBilancio2||'.';
--     begin
--     	select per.periodo_id into periodoId
--        from siac_t_periodo per, siac_d_periodo_tipo perTipo
--        where per.anno=annoBilancio2 and
--              per.ente_proprietario_id=enteProprietarioId and
--              perTipo.periodo_tipo_id=per.periodo_tipo_id and
--              perTipo.periodo_tipo_code=PER_TIPO_ANNO_MY and
--              perTipo.ente_proprietario_id=enteProprietarioId;
--
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
     (bilElemIdRet, capitoloEntrata.stanziamento_iniziale_anno3,null,
 	  parPerInsertElemBil.elemDetTipoIdSti, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloEntrata.stanziamento_iniziale_anno3,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_INIZIALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
--        		      or capitoloTipoDett.validita_fine is null));

	 -- STA - Stanziamento Attuale
     strMessaggio:='Inserimento siac_t_bil_elem_det '||STANZ_ATTUALE||  'per anno='||annoBilancio2||'.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     values
     (bilElemIdRet, capitoloEntrata.stanziamento_anno3,null,
 	  parPerInsertElemBil.elemDetTipoIdSta, periodoId,dataInizioVal,
	  enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet, capitoloEntrata.stanziamento_anno3,null,
--			 capitoloTipoDett.elem_det_tipo_id, periodoId,now(),
--	  	     enteProprietarioId,now(),loginOperazione
--      from  siac_d_bil_elem_det_tipo capitoloTipoDett
--      where capitoloTipoDett.elem_det_tipo_code =STANZ_ATTUALE and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
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
--            (date_trunc('day',dataElaborazione)<date_trunc('day',capitoloTipoDett.validita_fine)
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

--      capitoloTipoDett.elem_det_tipo_code in
--               ( STANZ_ASSEST,STANZ_ASSEST_CASSA,STANZ_ASSEST_RES  ) and
--      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
--      		capitoloTipoDett.data_cancellazione is null and
--            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
--            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now()))));
--        		      or capitoloTipoDett.validita_fine is null));

    end if;

    --- tipo_capitolo siac_r_bil_elem_categoria
    strMessaggio:='Inserimento tipo_capitolo '||capitoloEntrata.classe_capitolo||'.';
    insert into siac_r_bil_elem_categoria
    (elem_id,  elem_cat_id, validita_inizio,
     ente_proprietario_id, data_creazione,login_operazione)
    (select bilElemIdRet,catBilElem.elem_cat_id, dataInizioVal,
        	enteProprietarioId,statement_timestamp(),loginOperazione
     from siac_d_bil_elem_categoria catBilElem
     where  catBilElem.elem_cat_code=capitoloEntrata.classe_capitolo and
   	        catBilElem.ente_proprietario_id=enteProprietarioId and
            catBilElem.data_cancellazione is null and
	        date_trunc('day',dataElaborazione)>=date_trunc('day',catBilElem.validita_inizio) and
		    (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(catBilElem.validita_fine,now()))));
--      			      or catBilElem.validita_fine is null));

    --- attributi siac_r_bil_elem_attr
	strMessaggio:='Inserimento attributo '||FLAG_RIL_IVA||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,boolean,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.flagRilIvaAttrId,
     COALESCE(capitoloEntrata.flag_rilevante_iva,'N'), dataInizioVal,
     enteProprietarioId,statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,attrTipi.attr_id,
--            COALESCE(capitoloEntrata.flag_rilevante_iva,'N'), dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--         from siac_t_attr attrTipi
--         where  attrTipi.attr_code=FLAG_RIL_IVA and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));

	strMessaggio:='Inserimento attributo '||FLAG_ACCERTABILE||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,boolean,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.flagImpegnabileAttrId,
     COALESCE(capitoloEntrata.flag_accertabile,'S'), dataInizioVal,
     enteProprietarioId,statement_timestamp(),loginOperazione);

--     (select bilElemIdRet,attrTipi.attr_id,
--            COALESCE(capitoloEntrata.flag_accertabile,'S'), dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--         from siac_t_attr attrTipi
--         where  attrTipi.attr_code=FLAG_ACCERTABILE and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));

	if tipoElab=TIPO_ELAB_P then
		strMessaggio:='Inserimento attributo '||FLAG_PER_MEM||'.';
	    insert into siac_r_bil_elem_attr
    	(elem_id,attr_id,boolean,validita_inizio,
	     ente_proprietario_id,data_creazione,login_operazione)
        values
        (bilElemIdRet,parPerInsertElemBil.flagPerMemAttrId,
    	 COALESCE(capitoloEntrata.flag_per_memoria,'N'), dataInizioVal,
		 enteProprietarioId,statement_timestamp(),loginOperazione);

--    	(select bilElemIdRet,attrTipi.attr_id,
--        	    COALESCE(capitoloEntrata.flag_per_memoria,'N'), dataInizioVal,
--		        enteProprietarioId,now(),loginOperazione
--    	 from siac_t_attr attrTipi
--         where  attrTipi.attr_code=FLAG_PER_MEM and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
--	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));
	end if;

    strMessaggio:='Inserimento attributo '||NOTE_CAP||'.';
    insert into siac_r_bil_elem_attr
    (elem_id,attr_id,testo,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    values
    (bilElemIdRet,parPerInsertElemBil.noteCapAttrId,
     capitoloEntrata.note, dataInizioVal,
     enteProprietarioId,statement_timestamp(),loginOperazione);

--    (select bilElemIdRet,attrTipi.attr_id,
--            capitoloEntrata.note, dataInizioVal,
--	        enteProprietarioId,now(),loginOperazione
--         from siac_t_attr attrTipi
--         where  attrTipi.attr_code=NOTE_CAP and
--                attrTipi.ente_proprietario_id=enteProprietarioId and
--                attrTipi.data_cancellazione is null and
--                date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
---	            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now()))));
--      		      or attrTipi.validita_fine is null));

    if coalesce(capitoloEntrata.categoria,NVL_STR)!=NVL_STR then
     -- categoria
     classifId:=0;
     begin
    	strMessaggio:='Lettura categoria codice= '||capitoloEntrata.categoria||'.';
    	select classif.classif_id into strict classifId
        from siac_t_class classif, siac_d_class_tipo classTipo
        where classif.classif_code=capitoloEntrata.categoria and
              classif.ente_proprietario_id=enteProprietarioId and
              classif.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
	          (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now()))) and
--      		      or classif.validita_fine is null) and
--              classTipo.ente_proprietario_id=enteProprietarioId and
              classTipo.classif_tipo_id=classif.classif_tipo_id and
              classTipo.classif_tipo_code=CL_CATEGORIA and
              classTipo.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classTipo.validita_inizio) and
	          (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classTipo.validita_fine,now())));

      exception
       		when no_data_found then
                 --RAISE EXCEPTION 'Non esistente.';
                  strMessaggio:='Inserimento scarto per categoria codice= '||capitoloEntrata.categoria||
                               ' elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_entrata_scarto
                 (migr_capent_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloEntrata.migr_capent_id,bilElemIdRet,bilElemTipo,strMessaggio,
                  statement_timestamp() , enteProprietarioId);
           	when others  THEN
	             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

	if classifId!=0 then
    	 strMessaggio:='Inserimento relazione categoria codice= '||capitoloEntrata.categoria||'.';
   		 insert into siac_r_bil_elem_class
	     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		  data_creazione,login_operazione)
          values
	     (bilElemIdRet,classifId,dataInizioVal , enteProprietarioId,
		  statement_timestamp(),loginOperazione);

          -- 12.01.2016 Se il titolo = 1 impostato RICORRENTE A TRUE altrimenti lasciato 'Non ricorrente'
          strMessaggio:='Ricerca titolo per categora id = '||classifId||'.';
          --select titolo_code into titoloCode from siac_v_tit_tip_cat_riga  v where v.categoria_id=classifId;

           -- 23.01.2016 sostituzione per migliorare le prestazioni

            select classif_fam_tree_id 
				into strict classifFamentrata
            from  siac_t_class_fam_tree 
            where ente_proprietario_id =enteProprietarioId 
            	and class_fam_desc= CL_FAMIGLIA
            	and validita_fine is null;
			
			select classif_tipo_id 
				into strict classifCategoria
			from siac_d_class_tipo 
			where ente_proprietario_id =enteProprietarioId  
				and validita_fine is null 
				and classif_tipo_code =CL_CATEGORIA;
			
			select classif_tipo_id 
				into strict classifTipologia
			from siac_d_class_tipo 
			where ente_proprietario_id =enteProprietarioId  
				and validita_fine is null 
				and classif_tipo_code =CL_TIPOLOGIA;

			select classif_tipo_id 
				into strict classifTitEntrata
			from siac_d_class_tipo 
			where ente_proprietario_id =enteProprietarioId  
				and validita_fine is null 
				and classif_tipo_code = CL_TITOLO_ENTRATA;
          
          with
			tipologia as
			( select cp.classif_id
			  from  siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
			  where
			     cf.classif_id=classifId
				and   cf.data_cancellazione is null
				and   cf.validita_fine is null
				and   cf.classif_tipo_id= classifCategoria
				and   r.classif_id=cf.classif_id
				and   r.classif_id_padre is not null
				and   r.classif_fam_tree_id=classifFamentrata
				and   r.data_cancellazione is null
				and   r.validita_fine is null
				and   cp.classif_id=r.classif_id_padre
				and   cp.data_cancellazione is null
				and   cp.validita_fine is null
				and   cp.classif_tipo_id=classifTipologia
			 )
			 select  cp.classif_code into titoloCode
			 from  siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp, tipologia
			 where
			     cf.classif_id=tipologia.classif_id
				and   cf.data_cancellazione is null
				and   cf.validita_fine is null
				and   cf.classif_tipo_id= classifTipologia
				and   r.classif_id=cf.classif_id
				and   r.classif_id_padre is not null
				and   r.classif_fam_tree_id=classifFamentrata
				and   r.data_cancellazione is null
				and   r.validita_fine is null
				and   cp.classif_id=r.classif_id_padre
				and   cp.data_cancellazione is null
				and   cp.validita_fine is null
				and   cp.classif_tipo_id=classifTitEntrata; -- titolo_entrata
          
          if titoloCode = '1' then
          	cl_ricorrente := CL_RICORRENTE_ENTRATA_RICORR;
          end if;

    end if;
    else
        strMessaggio:='Inserimento scarto per categoria non indicata per elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_entrata_scarto
                 (migr_capent_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloEntrata.migr_capent_id,bilElemIdRet,bilElemTipo,strMessaggio,
                  statement_timestamp() , enteProprietarioId);
    end if;



    -- PDC_FIN
    pdcFin:=null;
    classifPdcFin:=null;
    if coalesce(capitoloEntrata.pdc_fin_quinto,NVL_STR)!=NVL_STR then
    	pdcFin:=capitoloEntrata.pdc_fin_quinto;
        classifPdcFin:=CL_PDC_FIN_QUINTO;
    elsif coalesce(capitoloEntrata.pdc_fin_quarto,NVL_STR)!=NVL_STR then
    	pdcFin:=capitoloEntrata.pdc_fin_quarto;
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
        	        -- RAISE EXCEPTION 'Non esistente.';
                      
    	   		strMessaggio:='Inserimento scarto per '||classifPdcFin||' codice= '||pdcFin||' elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_entrata_scarto
                 (migr_capent_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloEntrata.migr_capent_id,bilElemIdRet,bilElemTipo,strMessaggio,
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
		     	 strMessaggio:='Inserimento scarto per PdcFin non classificato per  elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_entrata_scarto
                 (migr_capent_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloEntrata.migr_capent_id,bilElemIdRet,bilElemTipo,strMessaggio,
                  statement_timestamp() , enteProprietarioId);
    end if;


    -- SAC
    strMessaggio:='Lettura Struttura amministrativo contabile.';
    sacCode:=null;
    classifSac:=null;
    if coalesce(capitoloEntrata.cdc,NVL_STR)!=NVL_STR then
    	sacCode:=capitoloEntrata.cdc;
        classifSac:=CL_CDC;
        sacCodeDef:=CDC_DEF;
    elsif coalesce(capitoloEntrata.centro_resp,NVL_STR)!=NVL_STR then
    	sacCode:=capitoloEntrata.centro_resp;
        classifSac:=CL_CDR;
        sacCodeDef:=CDR_DEF;
--    else
--    	RAISE EXCEPTION 'Informazione non migrata.';
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
        	         -- RAISE EXCEPTION 'Non esistente.';
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
    			 strMessaggio:='Inserimento scarto per Sac non classificato per  elem_id='||bilElemIdRet||'.';
                 insert into migr_capitolo_entrata_scarto
                 (migr_capent_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                 values
                 (capitoloEntrata.migr_capent_id,bilElemIdRet,bilElemTipo,strMessaggio,
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
        if coalesce(capitoloEntrata.siope_livello_3,NVL_STR)!=NVL_STR then
    	    begin
    	        strMessaggio:='Lettura '||CL_SIOPE_TERZO||' codice= '||capitoloEntrata.siope_livello_3||'.';
    	        select classif.classif_id into classifId
                  from siac_t_class classif, siac_d_class_tipo classTipo
       	         where classif.classif_code=capitoloEntrata.siope_livello_3 and
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
          	        strMessaggio:='Inserimento scarto per Siope codice='||capitoloEntrata.siope_livello_3||' non presente per elem_id='||bilElemIdRet||'.';
         	        insert into migr_capitolo_entrata_scarto
                    (migr_capent_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
                    values
                    (capitoloEntrata.migr_capent_id,bilElemIdRet,bilElemTipo,strMessaggio,
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
        strMessaggio:='Inserimento relazione '||CL_SIOPE_TERZO||' codice= '||capitoloEntrata.siope_livello_3||'.';
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
	if coalesce(capitoloEntrata.tipo_finanziamento)!=NVL_STR then
    	strMessaggio:='Tipo Finanziamento.';
        strToElab:=capitoloEntrata.tipo_finanziamento;
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
    if coalesce(capitoloEntrata.tipo_fondo)!=NVL_STR then
    	strMessaggio:='Tipo Fondo.';
        strToElab:=capitoloEntrata.tipo_fondo;
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

    -- DAVIDE - 07.10.2016 - inserimento valore RICORRENTE_ENTRATA dal tracciato dei capitoli se presente
    if coalesce(capitoloEntrata.entrata_ricorrente,NVL_STR)!=NVL_STR then
        cl_ricorrente := capitoloEntrata.entrata_ricorrente;
    end if;

    -- CL_RICORRENTE_ENTRATA 12.11.2015 Sofia impostare al valore corrispondente TRUE [1] di default
 	begin
  		strMessaggio:='Inserimento relazione classif='||CL_RICORRENTE_ENTRATA||
                      ' elem_id='||bilElemIdRet||'.';
 		insert into siac_r_bil_elem_class
	    (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		 data_creazione,login_operazione)
	    (select bilElemIdRet,class.classif_id,dataInizioVal, enteProprietarioId,
   		        statement_timestamp(),loginOperazione
         from siac_t_class class, siac_d_class_tipo tipo
         where tipo.classif_tipo_code=CL_RICORRENTE_ENTRATA
         and   tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null
         and   class.classif_tipo_id=tipo.classif_tipo_id
--         and   class.classif_code=CL_RICORRENTE_ENTRATA_RICORR
         and   class.classif_code=cl_ricorrente
         and   class.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
         and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(class.validita_fine,statement_timestamp())))
        )
        returning elem_classif_id into codResult;

        if codResult is null then
	        strMessaggio:='Inserimento scarto per classif='||CL_RICORRENTE_ENTRATA||
                          ' elem_id='||bilElemIdRet||'.Relazione siac_r_bil_elem_class non inserita per valore='||cl_ricorrente||'.';
            insert into migr_capitolo_entrata_scarto
            (migr_capent_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
             values
            (capitoloEntrata.migr_capent_id,bilElemIdRet,bilElemTipo,strMessaggio,
             statement_timestamp() , enteProprietarioId);
        end if;

		exception
       		when others  THEN
		    RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

    -- CL_TRANSAZIONE_UE_ENTRATA 12.01.2016 Daniela impostare al valore di default
 	begin
  		strMessaggio:='Inserimento relazione classif='||CL_TRANSAZIONE_UE_ENTRATA||
                      ' elem_id='||bilElemIdRet||'.';
		-- Davide - 05.04.016 - se presente, l'attributo TRASF_COMU si prende dalla migr.
		if capitoloentrata.trasferimenti_comunitari is not null then
		    trasf_comu := capitoloentrata.trasferimenti_comunitari;
		else 
		    trasf_comu := CL_TRANSAZIONE_UE_ENTRATA_DEF;
        end if;		

 		insert into siac_r_bil_elem_class
	    (elem_id,classif_id, validita_inizio, ente_proprietario_id,
		 data_creazione,login_operazione)
	    (select bilElemIdRet,class.classif_id,dataInizioVal, enteProprietarioId,
   		        statement_timestamp(),loginOperazione
         from siac_t_class class, siac_d_class_tipo tipo
         where tipo.classif_tipo_code=CL_TRANSAZIONE_UE_ENTRATA
         and   tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null
         and   class.classif_tipo_id=tipo.classif_tipo_id
         --and   class.classif_code=CL_TRANSAZIONE_UE_ENTRATA_DEF
         and   class.classif_code=trasf_comu          -- Davide - 05.04.016
         and   class.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
         and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(class.validita_fine,statement_timestamp())))
        )
        returning elem_classif_id into codResult;

        if codResult is null then
	        strMessaggio:='Inserimento scarto per classif='||CL_TRANSAZIONE_UE_ENTRATA||
             --             ' elem_id='||bilElemIdRet||'.Relazione siac_r_bil_elem_class non inserita per valore='||CL_TRANSAZIONE_UE_ENTRATA_DEF||'.';
                          ' elem_id='||bilElemIdRet||'.Relazione siac_r_bil_elem_class non inserita per valore='||trasf_comu||'.';
            insert into migr_capitolo_entrata_scarto
            (migr_capent_id,elem_id,tipo_capitolo, motivo_scarto,data_creazione,ente_proprietario_id)
             values
            (capitoloEntrata.migr_capent_id,bilElemIdRet,bilElemTipo,strMessaggio,
             statement_timestamp() , enteProprietarioId);
        end if;

		exception
       		when others  THEN
		    RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

    -- classificatore_1
    if coalesce(capitoloEntrata.classificatore_1)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_1||'.';
        strToElab:=capitoloEntrata.classificatore_1;
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
    if coalesce(capitoloEntrata.classificatore_2)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_2||'.';
        strToElab:=capitoloEntrata.classificatore_2;
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
    if coalesce(capitoloEntrata.classificatore_3)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_3||'.';
        strToElab:=capitoloEntrata.classificatore_3;
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
    if coalesce(capitoloEntrata.classificatore_4)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_4||'.';
        strToElab:=capitoloEntrata.classificatore_4;
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
    if coalesce(capitoloEntrata.classificatore_5)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_5||'.';
        strToElab:=capitoloEntrata.classificatore_5;
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
    if coalesce(capitoloEntrata.classificatore_6)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_6||'.';
        strToElab:=capitoloEntrata.classificatore_6;
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
    if coalesce(capitoloEntrata.classificatore_7)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_7||'.';
        strToElab:=capitoloEntrata.classificatore_7;
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
    if coalesce(capitoloEntrata.classificatore_8)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_8||'.';
        strToElab:=capitoloEntrata.classificatore_8;
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
    if coalesce(capitoloEntrata.classificatore_9)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_9||'.';
        strToElab:=capitoloEntrata.classificatore_9;
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
    if coalesce(capitoloEntrata.classificatore_10)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_10||'.';
        strToElab:=capitoloEntrata.classificatore_10;
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
    if coalesce(capitoloEntrata.classificatore_11)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_11||'.';
        strToElab:=capitoloEntrata.classificatore_11;
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
    if coalesce(capitoloEntrata.classificatore_12)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_12||'.';
        strToElab:=capitoloEntrata.classificatore_12;
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
    if coalesce(capitoloEntrata.classificatore_13)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_13||'.';
        strToElab:=capitoloEntrata.classificatore_13;
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
    if coalesce(capitoloEntrata.classificatore_14)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_14||'.';
        strToElab:=capitoloEntrata.classificatore_14;
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
    if coalesce(capitoloEntrata.classificatore_15)!=NVL_STR then
    	strMessaggio:='Classificatore '||capitoloEntrata.classificatore_15||'.';
        strToElab:=capitoloEntrata.classificatore_15;
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
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 800) ;
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
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 800) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;