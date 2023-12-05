/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia
-- Creazione dei capitoli di Gestione di un bilancio
-- Partendo dai capitoli di Previsione dello stesso bilancio
CREATE or replace FUNCTION fnc_creaCapitoloGestioneDaPrev(bilancioId in integer, enteProprietarioId in integer,
                                                      tipoCapEU in varchar,
                                                      bilElemPrevTipo in varchar, bilElemGestTipo in varchar,
                                                      annoBilancio in VARCHAR, loginOperazione  in VARCHAR,
                                                      dataElaborazione in timestamp,
                                                      numeroCapInseriti out integer, messaggioRisultato out varchar)
AS $$
DECLARE
    bilElemId integer := 0;
    bilElemTipoId integer :=0;

    numeroElementiInseriti integer:=0;
    capitoloPrev record;
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    -- costanti
    -- Stato operativo valido
    STATO_VALIDO CONSTANT  varchar :='VA';
    -- Tipi di importo
    STANZ_INIZIALE  CONSTANT  varchar :='STI';
    STANZ_ATTUALE   CONSTANT  varchar :='STA';
    STANZ_RES_INIZIALE CONSTANT  varchar :='SRI';
    STANZ_RESIDUO CONSTANT  varchar :='STR';
    STANZ_CASSA_INIZIALE CONSTANT  varchar :='SCI';
    STANZ_CASSA CONSTANT  varchar :='SCA';
    STANZ_ASSEST_CASSA CONSTANT varchar:='STCASS';
    STANZ_ASSEST CONSTANT varchar:='STASS';
    STANZ_ASSEST_RES CONSTANT varchar:='STRASS';

    -- ATTRIBUTI
    FLAG_PER_MEMORIA CONSTANT varchar :='FlagPerMemoria';
    FLAG_ASSEGNABILE CONSTANT varchar :='FlagAssegnabile';

BEGIN

    RAISE NOTICE 'Inizio creazione capitoli da tipo=% ', bilElemPrevTipo;

    numeroCapInseriti:=0;
    messaggioRisultato:='';

	strMessaggioFinale:='Inserimento elementi tipo '||bilElemGestTipo||' da '||bilElemPrevTipo||'.';

	strMessaggio:='Lettura Identificativo elemento tipo '||bilElemGestTipo||'.';
    -- Dovra esserci un unico elemento valido
    select elem_tipo_id into bilElemTipoId
	from siac_d_bil_elem_tipo
	where elem_tipo_code=bilElemGestTipo and
	      ente_proprietario_id=enteProprietarioId and
          data_cancellazione is null and
          date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',validita_inizio) and
          (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',validita_fine)
            or validita_fine is null);

	strMessaggio:='Lettura elemento bilancio tipo '||bilElemPrevTipo||'.';
    for capitoloPrev in
    select capitolo.*
     from siac_t_bil_elem  capitolo, siac_d_bil_elem_stato capitoloStato, siac_r_bil_elem_stato capitoloStatoRel,
          siac_d_bil_elem_tipo capitoloTipo,
          siac_t_bil bilancio,  siac_t_attr attrTipoCap, siac_r_bil_elem_attr attributiCapitolo --,siac_t_periodo periodo
     where  bilancio.bil_id = bilancioId and
     		bilancio.ente_proprietario_id= enteProprietarioId and
--            periodo.periodo_id=bilancio.periodo_id and
--            periodo.periodo_id=periodoId and
     		capitolo.bil_id=bilancio.bil_id and
            capitolo.data_cancellazione is null and
			date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitolo.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitolo.validita_fine)
              or capitolo.validita_fine is null) and
            capitoloStatoRel.elem_id=capitolo.elem_id and
            capitoloStato.elem_stato_id = capitoloStatoRel.elem_stato_id and
            capitoloStato.elem_stato_code=STATO_VALIDO and
            capitoloTipo.elem_tipo_id=capitolo.elem_tipo_id and
            capitoloTipo.elem_tipo_code=bilElemPrevTipo and
            attributiCapitolo.elem_id=capitolo.elem_id and
            attrTipoCap.attr_id=attributiCapitolo.attr_id and
            attrTipoCap.attr_code=FLAG_PER_MEMORIA and -- si includono i capitoli di previsione PerMemoria=FALSE
            attributiCapitolo.boolean='N' and
            capitoloStatoRel.data_cancellazione is null and
			date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloStatoRel.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloStatoRel.validita_fine)
              or capitoloStatoRel.validita_fine is null) and
            attributiCapitolo.data_cancellazione is null and
			date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',attributiCapitolo.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',attributiCapitolo.validita_fine)
              or attributiCapitolo.validita_fine is null)
    order by capitolo.elem_code,capitolo.elem_code2,capitolo.elem_code3


    loop

    -- RAISE NOTICE 'Capitolo Prev tipo=% id=%', bilElemPrevTipo, capitoloPrev.elem_id;

	strMessaggio:='Inserimento elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloPrev.elem_code||'/'||capitoloPrev.elem_code2||'/'||capitoloPrev.elem_code3||
    ' da Id '||capitoloPrev.elem_id||' '||bilElemPrevTipo||'.';

    -- inserimento del capitolo Gestione
	insert into siac_t_bil_elem
	(elem_code,elem_code2,elem_code3, elem_desc,elem_desc2,
	 elem_id_padre,elem_tipo_id, bil_id,ordine,livello,
	 validita_inizio , ente_proprietario_id,data_creazione,login_operazione)
	(select capitoloPrev.elem_code,capitoloPrev.elem_code2,capitoloPrev.elem_code3,capitoloPrev.elem_desc,capitoloPrev.elem_desc2,
           capitoloPrev.elem_id_padre,bilElemTipoId,capitoloPrev.bil_id,capitoloPrev.ordine,capitoloPrev.livello,
           CURRENT_TIMESTAMP,capitoloPrev.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
	 from siac_t_bil_elem capitolo
 	 where capitolo.elem_id=capitoloPrev.elem_id)
     returning elem_id into bilElemId ;

    -- RAISE NOTICE 'Capitolo Gest tipo=%  id=%', bilElemGestTipo,bilElemId;

	strMessaggio:='Inserimento stato op. elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloPrev.elem_code||'/'||capitoloPrev.elem_code2||'/'||capitoloPrev.elem_code3||
    ' da Id '||capitoloPrev.elem_id||' '||bilElemPrevTipo||'.';

	 -- Inserimento dello stato capitolo Gestione  VA-Valido
	 -- dovra esserci un unico elemento valido per lo stato VA
	 insert into siac_r_bil_elem_stato
     (elem_id,elem_stato_id,validita_inizio,ente_proprietario_id,
     data_creazione,login_operazione)
     (select bilElemId,capitoloStato.elem_stato_id,CURRENT_TIMESTAMP,capitoloStato.ente_proprietario_id,
      CURRENT_TIMESTAMP,loginOperazione
      from  siac_d_bil_elem_stato capitoloStato
      where capitoloStato.elem_stato_code= STATO_VALIDO and
            capitoloStato.ente_proprietario_id=enteProprietarioId and
            capitoloStato.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloStato.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloStato.validita_fine)
              or capitoloStato.validita_fine is null));



	strMessaggio:='Inserimento dettagli elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloPrev.elem_code||'/'||capitoloPrev.elem_code2||'/'||capitoloPrev.elem_code3||
    ' da Id '||capitoloPrev.elem_id||' '||bilElemPrevTipo||'.';

     -- Stanziamenti iniziale presi dagli attuali di previsione
	 -- STI - Stanziamento Iniziale
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, capitoloDett.elem_det_importo,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
              		capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_INIZIALE),
             capitoloDett.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloDett.elem_id=capitoloPrev.elem_id and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
        		      or capitoloDett.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_ATTUALE);

     -- SRI - Stanziamento Residuo Iniziale
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, capitoloDett.elem_det_importo,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
                    capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_RES_INIZIALE),
             capitoloDett.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloDett.elem_id=capitoloPrev.elem_id and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
        		      or capitoloDett.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_RESIDUO);

	 -- SCI - Stanziamento Cassa Iniziale
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, capitoloDett.elem_det_importo,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
                    capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_CASSA_INIZIALE),
             capitoloDett.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloDett.elem_id=capitoloPrev.elem_id and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_CASSA);

	 -- STP - Stanziamento Proposto
     -- STA - Stanziamento Attuale
     -- STR - Stanziamento Residuo
     -- SCA - Stanziamento Cassa
       insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, capitoloDett.elem_det_importo,capitoloDett.elem_det_flag,
			 capitoloDett.elem_det_tipo_id,
             capitoloDett.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloDett.elem_id=capitoloPrev.elem_id and
            capitoloDett.data_cancellazione is null and
		    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code not in (STANZ_INIZIALE,STANZ_RES_INIZIALE,STANZ_CASSA_INIZIALE));

     -- STASS - Stanziamento Assestamento
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, 0,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
                    capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_ASSEST),
             capitoloDett.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloDett.elem_id=capitoloPrev.elem_id and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_ATTUALE);

     -- STCASS - Stanziamento Assestamento Cassa
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, 0,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
                    capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_ASSEST_CASSA),
             capitoloDett.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloDett.elem_id=capitoloPrev.elem_id and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_ATTUALE);

     -- STRASS - Stanziamento Assestamento Residuo
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo,elem_det_flag,elem_det_tipo_id, periodo_id,validita_inizio,
	  ente_proprietario_id,data_creazione,login_operazione)
     (select bilElemId, 0,capitoloDett.elem_det_flag,
             (select elem_det_tipo_id from siac_d_bil_elem_det_tipo capitoloTipoDettIniz
              where capitoloTipoDettIniz.ente_proprietario_id=enteProprietarioId and
                    capitoloTipoDettIniz.data_cancellazione is null and
                    date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloTipoDettIniz.validita_inizio) and
		            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloTipoDettIniz.validita_fine)
        		      or capitoloTipoDettIniz.validita_fine is null) and
                    capitoloTipoDettIniz.elem_det_tipo_code=STANZ_ASSEST_RES),
             capitoloDett.periodo_id,CURRENT_TIMESTAMP,
	  	     capitoloDett.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
      from siac_t_bil_elem_det capitoloDett, siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloDett.elem_id=capitoloPrev.elem_id and
            capitoloDett.data_cancellazione is null and
            date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloDett.validita_inizio) and
            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloDett.validita_fine)
       		      or capitoloDett.validita_fine is null) and
            capitoloTipoDett.elem_det_tipo_id = capitoloDett.elem_det_tipo_id and
            capitoloTipoDett.elem_det_tipo_code=STANZ_ATTUALE);


     -- RAISE NOTICE 'Capitolo Dettagli inseriti ';

	strMessaggio:='Inserimento attributi elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloPrev.elem_code||'/'||capitoloPrev.elem_code2||'/'||capitoloPrev.elem_code3||
    ' da Id '||capitoloPrev.elem_id||' '||bilElemPrevTipo||'.';

 	 insert into siac_r_bil_elem_attr
     (elem_id,attr_id,tabella_id,boolean,percentuale,testo,numerico,validita_inizio,
     ente_proprietario_id,data_creazione,login_operazione)
    (select bilElemId,capitoloAttr.attr_id,capitoloAttr.tabella_id,
            capitoloAttr.boolean,capitoloAttr.percentuale,capitoloAttr.testo,capitoloAttr.numerico,
            CURRENT_TIMESTAMP,
	        capitoloAttr.ente_proprietario_id,CURRENT_TIMESTAMP,loginOperazione
     from siac_r_bil_elem_attr capitoloAttr, siac_t_attr attrTipi
     where capitoloAttr.elem_id= capitoloPrev.elem_id and
           capitoloAttr.data_cancellazione is null and
           date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloAttr.validita_inizio) and
           (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloAttr.validita_fine)
      		      or capitoloAttr.validita_fine is null) and
           attrTipi.attr_id=capitoloAttr.attr_id and
           attrTipi.attr_code!= FLAG_PER_MEMORIA ); -- escludo il FlagPerMemoria

     if tipoCapEU='U' then
      -- Attributo FlagAssegnabile
   	  insert into siac_r_bil_elem_attr
      (elem_id,attr_id,boolean,validita_inizio,
       ente_proprietario_id,data_creazione,login_operazione)
       (select bilElemId,attrTipi.attr_id,
            'N', CURRENT_TIMESTAMP,
	        enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione
         from siac_t_attr attrTipi
         where  attrTipi.attr_code=FLAG_ASSEGNABILE and
                attrTipi.ente_proprietario_id=enteProprietarioId and
                attrTipi.data_cancellazione is null and
                date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',attrTipi.validita_inizio) and
	            (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',attrTipi.validita_fine)
      		      or attrTipi.validita_fine is null));
     end if;

    -- RAISE NOTICE 'Capitolo attributi inseriti ';

	strMessaggio:='Inserimento classificatori elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloPrev.elem_code||'/'||capitoloPrev.elem_code2||'/'||capitoloPrev.elem_code3||
    ' da Id '||capitoloPrev.elem_id||' '||bilElemPrevTipo||'.';

     insert into siac_r_bil_elem_class
     (elem_id,classif_id, validita_inizio, ente_proprietario_id,
	  data_creazione,login_operazione)
     (select bilElemId,capitoloAttrClass.classif_id,CURRENT_TIMESTAMP , capitoloAttrClass.ente_proprietario_id,
	  CURRENT_TIMESTAMP,loginOperazione
      from siac_r_bil_elem_class capitoloAttrClass
      where capitoloAttrClass.elem_id= capitoloPrev.elem_id and
            capitoloAttrClass.data_cancellazione is null and
			date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloAttrClass.validita_inizio) and
	        (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloAttrClass.validita_fine)
      		      or capitoloAttrClass.validita_fine is null));

    -- RAISE NOTICE 'Capitolo attributi classificatori inseriti ';

	strMessaggio:='Inserimento atti di legge relazionati a elemento bilancio tipo '||bilElemGestTipo||' '||
    capitoloPrev.elem_code||'/'||capitoloPrev.elem_code2||'/'||capitoloPrev.elem_code3||
    ' da Id '||capitoloPrev.elem_id||' '||bilElemPrevTipo||'.';

	INSERT INTO siac_r_bil_elem_atto_legge
    (elem_id,attolegge_id,descrizione,gerarchia,finanziamento_inizio,finanziamento_fine,
	 validita_inizio,ente_proprietario_id, data_creazione,login_operazione
	)
    (select bilElemId, capitoloAttoLegge.attolegge_id,capitoloAttoLegge.descrizione,
            capitoloAttoLegge.gerarchia,capitoloAttoLegge.finanziamento_inizio,capitoloAttoLegge.finanziamento_fine,
	  	    CURRENT_TIMESTAMP,capitoloAttoLegge.ente_proprietario_id, CURRENT_TIMESTAMP,loginOperazione
     from siac_r_bil_elem_atto_legge capitoloAttoLegge
     where capitoloAttoLegge.elem_id= capitoloPrev.elem_id and
           capitoloAttoLegge.data_cancellazione is null and
           date_trunc('seconds',dataElaborazione)>=date_trunc('seconds',capitoloAttoLegge.validita_inizio) and
	        (date_trunc('seconds',dataElaborazione)<date_trunc('seconds',capitoloAttoLegge.validita_fine)
      		      or capitoloAttoLegge.validita_fine is null)
    );

     numeroElementiInseriti:=numeroElementiInseriti+1;
   end loop;

   RAISE NOTICE 'NumeroElementiInseriti %', numeroElementiInseriti;

   messaggioRisultato:=strMessaggioFinale||'Inseriti '||numeroElementiInseriti||' elementi di bilancio.';
   numeroCapInseriti:= numeroElementiInseriti;
   return;

exception
	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        numeroCapInseriti:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        numeroCapInseriti:=-1;
        return;
END;
$$ LANGUAGE plpgsql;