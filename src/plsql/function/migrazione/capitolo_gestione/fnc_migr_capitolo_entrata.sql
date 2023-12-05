/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_capitolo_entrata (tipoElab varchar,
													  enteProprietarioId integer,
                                                      annoBilancio in VARCHAR,
                                                      bilElemTipo in varchar,
  											          loginOperazione varchar,
										              dataElaborazione timestamp,
                                                      idMin INTEGER,
                                                      idMax integer,
											          out numeroCapitoliInseriti integer,
											          out messaggioRisultato varchar
											        )
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_capitolo_entrata --> function che effettua il caricamento dei capitoli di entrata ( elementi di bialncio)
    -- leggendo in tab migr_capitolo_entrata
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
        -- classififcatore_46 .. classificatore_50 --> generici x eventuali stampe ma non gestisti
    -- siac_r_migr_capitolo_entrata_bil_elem --> relazione tra elemento di bilancio e capitolo migrato
     -- richiama
	 -- fnc_migr_aggiorna_classif_cap
        -- per aggiornamento delle descrizioni dei classificatori caricati
        -- in migr_classif_capitolo
     -- fnc_inserisci_capitolo_entrata  per
        -- caricamento del capitolo di entrata, letto dalla migr_capitolo_entrata
    -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numeroCapitoliInseriti valorizzato con
        -- -12 dati da migrare non presenti in migr_capitolo_uscita
		-- -13 id_bilancio non recuperato da siac_t_bil
        -- -1 errore
        -- N=numero capitoli inseriti

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';


	migrCapitoloEntrata  migr_capitolo_entrata%rowtype;
    migrAggClassifCap record;
    migrCapEntrRetIns record;

    countMigrCapEntr integer:=0;

	numeroElementiInseriti   integer:=0;

	bilancioid integer:=0;
	bilElemTipoId integer:=0;
    elemStatoIdValido integer:=0;

    periodoIdAnno integer:=0;
    periodoIdAnno1 integer:=0;
    periodoIdAnno2 integer:=0;
    annoBilancio1 varchar(10):='';
    annoBilancio2 varchar(10):='';
    elemDetTipoIdSti integer:=0;
    elemDetTipoIdSri integer:=0;
    elemDetTipoIdSci integer:=0;
    elemDetTipoIdSta integer:=0;
    elemDetTipoIdStr integer:=0;
    elemDetTipoIdSca integer:=0;
    elemDetTipoIdStp integer:=0;
    elemDetTipoIdStass integer:=0;
    elemDetTipoIdStasr  integer:=0;
    elemDetTipoIdStasc  integer:=0;
    flagPerMemAttrId    integer:=0;
    flagRilIvaAttrId  integer:=0;
    flagImpegnabileAttrId  integer:=0;
    noteCapAttrId integer:=0;
    v_migr_cap_id integer:=0;

    parPerInsertElemBil parPerInsertElemBilType;

	--    costanti
	NVL_STR             CONSTANT VARCHAR:='';
    SEPARATORE			CONSTANT  varchar :='||';
    PER_TIPO_ANNO_MY    CONSTANT varchar:='SY';
    STATO_VALIDO CONSTANT  varchar :='VA';
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

	FLAG_RIL_IVA CONSTANT varchar :='FlagRilevanteIva';
    NOTE_CAP     CONSTANT varchar :='Note';
    FLAG_PER_MEM CONSTANT varchar :='FlagPerMemoria';
    FLAG_ACCERTABILE CONSTANT varchar :='FlagImpegnabile';


BEGIN

    numeroCapitoliInseriti:=0;
    messaggioRisultato:='';

	strMessaggioFinale:='Migrazione capitoli entrata da '||idmin||' a '||idmax||'.';
    strMessaggio:='Lettura capitoli entrata migrati.';

	select COALESCE(count(*),0) into countMigrCapEntr
    from migr_capitolo_entrata ms
     where ms.ente_proprietario_id=enteProprietarioId and
           ms.anno_esercizio=annoBilancio and
           ms.tipo_capitolo=bilElemTipo and
           ms.fl_elab='N'
           and ms.migr_capent_id >=idMin and ms.migr_capent_id<=idMax;

	if COALESCE(countMigrCapEntr,0)=0 then
         messaggioRisultato:=strMessaggioFinale||'Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
         numeroCapitoliInseriti:=-12;
         return;
    end if;

   -- Modifica Daniela 22/09/2014. Recupero dell'id bilancio da tabella anziche da parametro in input
    begin
      select b.bil_id,b.periodo_id into strict bilancioid, periodoIdAnno
      from siac_t_bil b
      join siac_t_periodo p on (b.periodo_id=p.periodo_id
          and b.ente_proprietario_id = p.ente_proprietario_id
          and p.anno = annobilancio)
      where b.ente_proprietario_id = enteproprietarioid
      and b.validita_fine is null;
	exception
      when NO_DATA_FOUND THEN
         messaggioRisultato:=strMessaggioFinale||'Id bilancio non recueprato per ente '||enteProprietarioId||', anno '||annobilancio||'.';
         numeroCapitoliInseriti:=-13;
         return;
      when TOO_MANY_ROWS THEN
         messaggioRisultato:=strMessaggioFinale||'Impossibile identificare id bilancio, troppi valori per ente '||enteProprietarioId||', anno '||annobilancio||'.';
         numeroCapitoliInseriti:=-13;
         return;
    end;
    -- Fine modifica

     -- 12.01.015 Sofia -- ricavo dati comuni a tutti i capitoli da inserire
    begin

     annoBilancio1:=ltrim(rtrim(to_char((annoBilancio::integer)+1,'9999')));
     strMessaggio:='Lettura periodo per anno='||annoBilancio1||'.';
     select per.periodo_id into strict periodoIdAnno1
     from siac_t_periodo per , siac_d_periodo_tipo perTipo
     where per.anno=annoBilancio1 and
           per.ente_proprietario_id=enteProprietarioId and
           perTipo.periodo_tipo_id=per.periodo_tipo_id and
           perTipo.periodo_tipo_code=PER_TIPO_ANNO_MY and
           perTipo.ente_proprietario_id=enteProprietarioId;

	 annoBilancio2:=ltrim(rtrim(to_char((annoBilancio::integer)+2,'9999')));
     strMessaggio:='Lettura periodo per anno='||annoBilancio2||'.';
     select per.periodo_id into strict periodoIdAnno2
     from siac_t_periodo per , siac_d_periodo_tipo perTipo
     where per.anno=annoBilancio2 and
           per.ente_proprietario_id=enteProprietarioId and
           perTipo.periodo_tipo_id=per.periodo_tipo_id and
           perTipo.periodo_tipo_code=PER_TIPO_ANNO_MY and
           perTipo.ente_proprietario_id=enteProprietarioId;

     strMessaggio:='Lettura Identificativo elemento tipo '||bilElemTipo||'.';
	 select elem_tipo_id into strict bilElemTipoId
	 from siac_d_bil_elem_tipo
 	 where elem_tipo_code=bilElemTipo and
	       ente_proprietario_id=enteProprietarioId and
           data_cancellazione is null and
           date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(validita_fine,now())));

	 strMessaggio:='Lettura Identificativo stato elemento= '||STATO_VALIDO||'.';
     select  capitoloStato.elem_stato_id into strict elemStatoIdValido
     from  siac_d_bil_elem_stato capitoloStato
     where capitoloStato.elem_stato_code= STATO_VALIDO and
           capitoloStato.ente_proprietario_id=enteProprietarioId and
           capitoloStato.data_cancellazione is null and
           date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloStato.validita_inizio) and
           (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloStato.validita_fine,now())));

   	 strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_INIZIALE||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdSti
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_INIZIALE and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

   	 strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_RES_INIZIALE||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdSri
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_RES_INIZIALE and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

   	 strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_CASSA_INIZIALE||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdSci
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_CASSA_INIZIALE and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

	 strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_ATTUALE||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdSta
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_ATTUALE and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

     strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_RESIDUO||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdStr
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_RESIDUO and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

	 strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_CASSA||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdSca
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_CASSA and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

     strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_PROP||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdStp
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_PROP and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

     strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_ASSEST||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdStass
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_ASSEST and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

	 strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_ASSEST_RES||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdStasr
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_ASSEST_RES and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

	 strMessaggio:='Lettura Identificativo elementoDetTipo= '||STANZ_ASSEST_CASSA||'.';
	 select capitoloTipoDett.elem_det_tipo_id into strict elemDetTipoIdStasc
     from siac_d_bil_elem_det_tipo capitoloTipoDett
      where capitoloTipoDett.elem_det_tipo_code =STANZ_ASSEST_CASSA and
      		capitoloTipoDett.ente_proprietario_id=enteProprietarioId and
      		capitoloTipoDett.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',capitoloTipoDett.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitoloTipoDett.validita_fine,now())));

     strMessaggio:='Lettura Identificativo attr_id= '||FLAG_PER_MEM||'.';
     select attrTipi.attr_id into strict flagPerMemAttrId
	 from siac_t_attr attrTipi
     where  attrTipi.attr_code=FLAG_PER_MEM and
            attrTipi.ente_proprietario_id=enteProprietarioId and
       	    attrTipi.data_cancellazione is null and
	        date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
	        (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now())));

     strMessaggio:='Lettura Identificativo attr_id= '||FLAG_ACCERTABILE||'.';
     select attrTipi.attr_id into strict flagImpegnabileAttrId
	 from siac_t_attr attrTipi
     where  attrTipi.attr_code=FLAG_ACCERTABILE and
            attrTipi.ente_proprietario_id=enteProprietarioId and
       	    attrTipi.data_cancellazione is null and
	        date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
	        (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now())));

	 strMessaggio:='Lettura Identificativo attr_id= '||FLAG_RIL_IVA||'.';
     select attrTipi.attr_id into strict flagRilIvaAttrId
	 from siac_t_attr attrTipi
     where  attrTipi.attr_code=FLAG_RIL_IVA and
            attrTipi.ente_proprietario_id=enteProprietarioId and
       	    attrTipi.data_cancellazione is null and
	        date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
	        (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now())));

     strMessaggio:='Lettura Identificativo attr_id= '||NOTE_CAP||'.';
     select attrTipi.attr_id into strict noteCapAttrId
	 from siac_t_attr attrTipi
     where  attrTipi.attr_code=NOTE_CAP and
            attrTipi.ente_proprietario_id=enteProprietarioId and
       	    attrTipi.data_cancellazione is null and
	        date_trunc('day',dataElaborazione)>=date_trunc('day',attrTipi.validita_inizio) and
	        (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attrTipi.validita_fine,now())));

 	 exception
       when NO_DATA_FOUND THEN
          messaggioRisultato:=strMessaggioFinale||strMessaggio||'Dato non recuperato per ente '||enteProprietarioId||'.';
          numeroCapitoliInseriti:=-13;
          return;
      when TOO_MANY_ROWS THEN
         messaggioRisultato:=strMessaggioFinale||strMessaggio||'Impossibile identificare dato, troppi valori per ente '||enteProprietarioId||'.';
         numeroCapitoliInseriti:=-13;
         return;

    end;


    parPerInsertElemBil.bilElemTipoId:=bilElemTipoId;
    parPerInsertElemBil.periodoIdAnno:=periodoIdAnno;
    parPerInsertElemBil.periodoIdAnno1:=periodoIdAnno1;
    parPerInsertElemBil.annoBilancio1:=annoBilancio1;
    parPerInsertElemBil.periodoIdAnno2:=periodoIdAnno2;
    parPerInsertElemBil.annoBilancio2:=annoBilancio2;
    parPerInsertElemBil.elemStatoIdValido:=elemStatoIdValido;
    parPerInsertElemBil.elemDetTipoIdSti:=elemDetTipoIdSti;
    parPerInsertElemBil.elemDetTipoIdSri:=elemDetTipoIdSri;
    parPerInsertElemBil.elemDetTipoIdSci:=elemDetTipoIdSci;
    parPerInsertElemBil.elemDetTipoIdSta:=elemDetTipoIdSta;
    parPerInsertElemBil.elemDetTipoIdStr:=elemDetTipoIdStr;
    parPerInsertElemBil.elemDetTipoIdSca:=elemDetTipoIdSca;
    parPerInsertElemBil.elemDetTipoIdStp:=elemDetTipoIdStp;
    parPerInsertElemBil.elemDetTipoIdStass:=elemDetTipoIdStass;
    parPerInsertElemBil.elemDetTipoIdStasr:=elemDetTipoIdStasr;
    parPerInsertElemBil.elemDetTipoIdStasc:=elemDetTipoIdStasc;
    parPerInsertElemBil.flagImpegnabileAttrId:=flagImpegnabileAttrId;
	parPerInsertElemBil.flagPerMemAttrId:=flagPerMemAttrId;
    parPerInsertElemBil.flagRilIvaAttrId:=flagRilIvaAttrId;
    parPerInsertElemBil.noteCapAttrId:=noteCapAttrId;

-- 20.10.2015 eseguire solo per il primo blocco
    select ms.migr_capent_id into v_migr_cap_id
      from migr_capitolo_entrata ms
      where ms.ente_proprietario_id=enteProprietarioId
      and ms.anno_esercizio=annoBilancio
      and ms.tipo_capitolo=bilElemTipo
      and ms.fl_elab='N'
      order by ms.migr_capent_id limit 1;
    if v_migr_cap_id = idMin then
      select * into migrAggClassifCap
      from fnc_migr_aggiorna_classif_cap (bilElemTipo,
                                          enteProprietarioId,loginOperazione,dataElaborazione);

      if migrAggClassifCap.codiceRisultato=-1 then
          RAISE EXCEPTION ' % ', migrAggClassifCap.messaggioRisultato;
      end if;
    end if;

    for migrCapitoloEntrata IN
    (select ms.*
     from migr_capitolo_entrata ms
     where ms.ente_proprietario_id=enteProprietarioId and
           ms.anno_esercizio=annoBilancio and
           ms.tipo_capitolo=bilElemTipo and
           ms.fl_elab='N'
           and ms.migr_capent_id >=idMin and ms.migr_capent_id<=idMax
     order by ms.migr_capent_id)
    loop

    	strMessaggio:='Inserimento capitolo di entrata per migr_capent_id= '
	                               ||migrCapitoloEntrata.migr_capent_id||'.';
		select * into migrCapEntrRetIns
        from fnc_inserisci_capitolo_entrata (tipoElab,bilancioId,annoBilancio,
        									 bilElemTipo,parPerInsertElemBil,
                                             migrCapitoloEntrata,
                                             enteProprietarioId,loginOperazione,dataElaborazione);
        if migrCapEntrRetIns.codiceRisultato=-1 then
         RAISE EXCEPTION ' % ', migrCapEntrRetIns.messaggioRisultato;
        end if;


         strMessaggio:='Inserimento siac_r_migr_capitolo_entrata_bil_elem per migr_capent_id= '
                               ||migrCapitoloEntrata.migr_capent_id||'.';
	     insert into siac_r_migr_capitolo_entrata_bil_elem
	    (migr_capent_id,elem_id,ente_proprietario_id,data_creazione)
	     values
	    (migrCapitoloEntrata.migr_capent_id,migrCapEntrRetIns.bilElemId,enteProprietarioId,now());

         numeroElementiInseriti:=numeroElementiInseriti+1;
    end loop;

	strMessaggio:='Set fl_elab in migr_capitolo_entrata.';

	update migr_capitolo_entrata
    set fl_elab = 'S'
    where ente_proprietario_id = enteProprietarioId
    and anno_esercizio=annoBilancio
    and tipo_capitolo=bilElemTipo
    and migr_capent_id >= idMin and migr_capent_id <= idMax
    and fl_elab = 'N'
    and migr_capent_id in (select r.migr_capent_id from siac_r_migr_capitolo_entrata_bil_elem r where r.ente_proprietario_id=enteProprietarioId);


   RAISE NOTICE 'NumeroImpegniInseriti %', numeroElementiInseriti;


   messaggioRisultato:=strMessaggioFinale||'Inseriti '||numeroElementiInseriti||' capitoli entrata.';
   numeroCapitoliInseriti:= numeroElementiInseriti;
   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroCapitoliInseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroCapitoliInseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;