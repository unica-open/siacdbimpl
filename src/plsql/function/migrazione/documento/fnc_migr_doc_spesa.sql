/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_doc_spesa(enteProprietarioId integer,
											  nomeEnte VARCHAR,
											  annobilancio varchar,
											  loginOperazione varchar,
											  dataElaborazione timestamp,
                                              idMin integer,
											  idMax integer,
											  out numeroRecordInseriti integer,
											  out messaggioRisultato varchar
											  )
RETURNS record AS
$body$
DECLARE

 strMessaggio VARCHAR(2500):='';
 strMessaggioFinale VARCHAR(2500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigrDoc integer := 0;

 migrDocumento record;

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 codBolloId integer:=null;
 codPccId   integer:=null;
 codUfficioId integer:=null;
 docId      integer:=null;
 scartoId   integer:=null;

 NVL_STR CONSTANT varchar :='';

 ARROTONDAMENTO_ATTR CONSTANT  varchar :='arrotondamento';
 TERMINE_PAGAM_ATTR  CONSTANT  varchar :='terminepagamento';
 DATA_REPERT_ATTR    CONSTANT  varchar :='data_repertorio';
 NUM_REPERT_ATTR     CONSTANT  varchar :='num_repertorio';
 ANNO_REPERT_ATTR    CONSTANT  varchar :='anno_repertorio';
 CAUS_SOSP_ATTR      CONSTANT  varchar :='causale_sospensione';
 DATA_SOSP_ATTR      CONSTANT  varchar :='data_sospensione';
 DATA_RIATT_ATTR     CONSTANT  varchar :='data_riattivazione';
 CODFISC_PIGN_ATTR   CONSTANT  varchar :='codiceFiscalePignorato';
 NOTE_ATTR           CONSTANT  varchar :='Note';
 DATA_SCAD_DOPOSOSP_ATTR  CONSTANT  varchar :='dataScadenzaDopoSospensione';
 DATA_RICEZIONE_ATTR CONSTANT  varchar :='dataRicezionePortale';
 TIPO_IMPRESA_CL     CONSTANT  varchar :='TIPO_IMPRESA';
 TIPO_FAM_DOC_SPESA  CONSTANT  varchar :='S';


 arrotondamentoAttrId    integer:=null;
 terminePagamAttrId      integer:=null;
 dataRepertAttrId        integer:=null;
 numRepertAttrId         integer:=null;
 annoRepertAttrId        integer:=null;
 noteAttrId              integer:=null;
 causSospensioneAttrId   integer:=null;
 dataSospensioneAttrId   integer:=null;
 dataRiattivazioneAttrId integer:=null;
 codFiscPignoratoAttrId  integer:=null;
 tipoImpresaClassTipoId  integer:=null;
 docFamTipoId            integer:=null;
 dataScadDopoSospAttrId  integer:=null;
 dataRicezioneAttrId     integer:=null;

 registrazione_anno      integer:=null;
 v_count      			 integer:=null;
 countRuf record;

 codicePccDef 		varchar := '99999';
 codPccIdDef	    integer:=null;
 codBolloDef 		varchar := '99'; -- Valore di default se codice bollo non passato o non trovato in tabella di decodifica
 codBolloIdDef	    integer:=null;

 -- 10.12.2015 Sofia
 codicePcc varchar(20):=null;

BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione documenti di spesa da id ['||idMin||'] a id ['||idMax||']';

    strMessaggio:='Lettura documenti spesa da migrare.';
	begin
		select distinct 1 into strict countMigrDoc from migr_doc_spesa ms
		where ms.ente_proprietario_id=enteProprietarioId
        and   ms.fl_elab='N'
		and   ms.migr_docspesa_id >= idMin and ms.migr_docspesa_id <=idMax;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;

    begin

        strMessaggio:='Lettura identificativo attributo '||ARROTONDAMENTO_ATTR||'.';

        select attr.attr_id into strict arrotondamentoAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=ARROTONDAMENTO_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||TERMINE_PAGAM_ATTR||'.';

        select attr.attr_id into strict terminePagamAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=TERMINE_PAGAM_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||DATA_REPERT_ATTR||'.';

        select attr.attr_id into strict dataRepertAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_REPERT_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||NUM_REPERT_ATTR||'.';

        select attr.attr_id into strict numRepertAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NUM_REPERT_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||ANNO_REPERT_ATTR||'.';

        select attr.attr_id into strict annoRepertAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=ANNO_REPERT_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||NOTE_ATTR||'.';

        select attr.attr_id into strict noteAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||CAUS_SOSP_ATTR||'.';

        select attr.attr_id into strict causSospensioneAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=CAUS_SOSP_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


		strMessaggio:='Lettura identificativo attributo '||DATA_SOSP_ATTR||'.';

        select attr.attr_id into strict dataSospensioneAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_SOSP_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||DATA_RIATT_ATTR||'.';

        select attr.attr_id into strict dataRiattivazioneAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_RIATT_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||CODFISC_PIGN_ATTR||'.';

        select attr.attr_id into strict codFiscPignoratoAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=CODFISC_PIGN_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo classificatore '||TIPO_IMPRESA_CL||'.';

        select tipo.classif_tipo_id into strict tipoImpresaClassTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=TIPO_IMPRESA_CL
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

		strMessaggio:='Lettura identificativo famiglia tipo documento  '||TIPO_FAM_DOC_SPESA||'.';

        select tipo.doc_fam_tipo_id into strict docFamTipoId
        from siac_d_doc_fam_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.doc_fam_tipo_code=TIPO_FAM_DOC_SPESA
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||DATA_SCAD_DOPOSOSP_ATTR||'.';

        select attr.attr_id into strict dataScadDopoSospAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_SCAD_DOPOSOSP_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||DATA_RICEZIONE_ATTR||'.';

        select attr.attr_id into strict dataRicezioneAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_RICEZIONE_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        select d.pcccod_id into codPccIdDef
        from siac_d_pcc_codice d
        where d.pcccod_code=codicePccDef
        and   d.ente_proprietario_id=enteProprietarioId
        and   d.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio)
        and  (date_trunc('day',dataElaborazione)<date_trunc('day',d.validita_fine) or d.validita_fine is null);


		strMessaggio:='Lettura identificativo bollo default.';

        select d.codbollo_id into codBolloIdDef
        from siac_d_codicebollo d
        where d.codbollo_code=codBolloDef
        and   d.ente_proprietario_id=enteProprietarioId
        and   d.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio)
        and  (date_trunc('day',dataElaborazione)<date_trunc('day',d.validita_fine) or d.validita_fine is null);

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

    strMessaggio:='Lettura documenti spesa da migrare.Inizio ciclo.';
    for migrDocumento IN
    (select ms.*
     from migr_doc_spesa ms
	 where ms.ente_proprietario_id=enteProprietarioId
     and   ms.fl_elab='N'
     and   ms.migr_docspesa_id >= idMin and ms.migr_docspesa_id <=idMax
     order by ms.migr_docspesa_id
     )
    loop

	    codBolloId:=null;
	    codPccId:=null;
	    codUfficioId:=null;
		docId:=null;
        scartoId:=null;
		-- 10.12.2015 Sofia
        codicePcc:=trim(both ' ' from migrDocumento.codice_pcc);

        -- tipo
	    -- anno
	    -- numero
        -- bollo
	    -- codice_soggetto
        -- stato
        -- descrizione
        -- date_emissione
        -- data_scadenza
        -- importo
        -- utente_creazione
        -- utente_modifica
		-- arrotondamento
        -- termine_pagamento
		-- data_repertorio
		-- numero_repertorio
        -- note
        -- causale_sospensione
        -- data_sospensione
        -- data_riattivazione
		-- codice_fiscale_pign


        -- da posizionare
        -- codice_soggetto_pag
        -- data_scandenza_new (data scadenza dopo sospensione)
		-- codice_pcc
        -- codice_ufficio
        -- data_ricezione (data ricezione portale)
		-- data_registro_fatt
        -- numero_registro_fatt

        strMessaggio:='Lettura codice bollo='||quote_nullable(migrDocumento.bollo)||' per inserimento siac_t_doc per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
    	-- bollo
        if coalesce(migrDocumento.bollo,NVL_STR)!=NVL_STR then
 	    	select d.codbollo_id into codBolloId
    	    from siac_d_codicebollo d
	        where d.codbollo_code=migrDocumento.bollo
    	    and   d.ente_proprietario_id=enteProprietarioId
        	and   d.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio)
    	    and  (date_trunc('day',dataElaborazione)<date_trunc('day',d.validita_fine) or d.validita_fine is null);

            if codBolloId is null then
              	  codBolloId:=codBolloIdDef; -- 29.12.2015 Dani. Se non passato in migrazione viene impostato il default e segnalato il record
--                  strMessaggio:=strMessaggio||' Codice Bollo='||migrDocumento.bollo||' non presente in archivio.';
                  strMessaggio:=strMessaggio||' Codice Bollo='||migrDocumento.bollo||' non presente in archivio. Impostato default 99.';
	       		  INSERT INTO migr_doc_spesa_scarto
				  (migr_doc_spesa_id,
	               motivo_scarto,
			       data_creazione,
		           ente_proprietario_id
			      )
                  values (migrDocumento.migr_docspesa_id,
 	                      strMessaggio,
		                  clock_timestamp(),
	                   	  enteProprietarioId);
--                  continue;
             end if;
        else
      	    codBolloId:=codBolloIdDef; -- 29.12.2015 Dani. Se non passato in migrazione viene impostato il default
        end if;

--        strMessaggio:='Lettura codice pcc ='||quote_nullable(migrDocumento.codice_pcc)||' per inserimento siac_t_doc per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
	    strMessaggio:='Lettura codice pcc ='||quote_nullable(codicePcc)||' per inserimento siac_t_doc per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';

    	-- codice_pcc
--        if coalesce(migrDocumento.codice_pcc,NVL_STR)!=NVL_STR then
        if coalesce(codicePcc,NVL_STR)!=NVL_STR then
 	    	select d.pcccod_id into codPccId
    	    from siac_d_pcc_codice d
--	        where d.pcccod_code=migrDocumento.codice_pcc
	        where d.pcccod_code=codicePcc
    	    and   d.ente_proprietario_id=enteProprietarioId
        	and   d.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio)
    	    and  (date_trunc('day',dataElaborazione)<date_trunc('day',d.validita_fine) or d.validita_fine is null);

            if codPccId is null then
            	 -- assegnamo il codice pcc di default, segnaliamo e migriamo ugualmente il caso.
--                  strMessaggio:=strMessaggio||' Codice Pcc='||migrDocumento.codice_pcc||' non presente in archivio.';
                  strMessaggio:=strMessaggio||' Codice Pcc='||codicePcc||' non presente in archivio.';
                  codPccId:=codPccIdDef;
	       		  INSERT INTO migr_doc_spesa_scarto
				  (migr_doc_spesa_id,
	               motivo_scarto,
			       data_creazione,
		           ente_proprietario_id
			      )
                  values(migrDocumento.migr_docspesa_id,
 	                      strMessaggio,
		                  clock_timestamp(),
	                   	  enteProprietarioId);
--                  (select migrDocumento.migr_docspesa_id,
-- 	                      strMessaggio,
--		                  clock_timestamp(),
--	                   	  enteProprietarioId
  --                 where not exists (select 1 from migr_doc_spesa_scarto s
    --                      where s.migr_doc_spesa_id=migrDocumento.migr_docspesa_id
	--	                  and   s.ente_proprietario_id=enteProprietarioId));
--                  continue;
             end if;
        end if;

        strMessaggio:='Lettura codice ufficio ='||quote_nullable(migrDocumento.codice_ufficio)||' per inserimento siac_t_doc per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
    	-- codice_ufficio
        if coalesce(migrDocumento.codice_ufficio,NVL_STR)!=NVL_STR then
 	    	select d.pccuff_id into codUfficioId
    	    from siac_d_pcc_ufficio d
	        where d.pccuff_code=migrDocumento.codice_ufficio
    	    and   d.ente_proprietario_id=enteProprietarioId
        	and   d.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio)
    	    and  (date_trunc('day',dataElaborazione)<date_trunc('day',d.validita_fine) or d.validita_fine is null);

            if codUfficioId is null then
                  strMessaggio:=strMessaggio||' Codice Ufficio='||migrDocumento.codice_ufficio||' non presente in archivio.';
	       		  INSERT INTO migr_doc_spesa_scarto
				  (migr_doc_spesa_id,
	               motivo_scarto,
			       data_creazione,
		           ente_proprietario_id
			      )
                  values(migrDocumento.migr_docspesa_id,
 	                      strMessaggio,
		                  clock_timestamp(),
	                   	  enteProprietarioId);
--                  (select migrDocumento.migr_docspesa_id,
-- 	                      strMessaggio,
--		                  clock_timestamp(),
--	                   	  enteProprietarioId
--                   where not exists (select 1 from migr_doc_spesa_scarto s
--                          where s.migr_doc_spesa_id=migrDocumento.migr_docspesa_id
--		                  and   s.ente_proprietario_id=enteProprietarioId));

--	Per mancanza di codice ufficio il dato viene segnalato.
--                  continue;
             end if;
        end if;

		-- siac_t_doc
	    strMessaggio:='Inserimento siac_t_doc per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
        INSERT INTO siac_t_doc
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
         data_creazione,
	     login_operazione,
         login_creazione,
         login_modifica,
         doc_collegato_cec,
         pcccod_id,
         pccuff_id
		)
        (select  migrDocumento.anno::integer,
                 migrDocumento.numero,
                 migrDocumento.descrizione,
                 abs(migrDocumento.importo),
                 to_timestamp(migrDocumento.date_emissione,'yyyy-MM-dd'),
                 to_timestamp(migrDocumento.data_scadenza,'yyyy-MM-dd'),
                 tipo.doc_tipo_id,
                 codBolloId,
                 dataInizioVal::timestamp,
                 enteProprietarioId,
                 clock_timestamp(),
                 loginOperazione,
                 migrDocumento.utente_creazione,
                 migrDocumento.utente_modifica,
                 case migrDocumento.collegato_cec when 'S' then true else false end,
                 codPccId,
                 codUfficioId
         from siac_d_doc_tipo tipo
         where tipo.doc_tipo_code=migrDocumento.tipo
         and   tipo.doc_fam_tipo_id=docFamTipoId
         and   tipo.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
         and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null)
        )
        returning doc_id into docId;

        if docId is null THEN
        	strMessaggio:=strMessaggio||' Verificare esistenza del tipo='||quote_nullable(migrDocumento.tipo)||'.';
	       	INSERT INTO migr_doc_spesa_scarto
			(migr_doc_spesa_id,
	         motivo_scarto,
			 data_creazione,
		     ente_proprietario_id
			 )values(migrDocumento.migr_docspesa_id,
 	                 strMessaggio,
		             clock_timestamp(),
	           	     enteProprietarioId);
--             (select migrDocumento.migr_docspesa_id,
-- 	                 strMessaggio,
--		             clock_timestamp(),
--	           	     enteProprietarioId
--              where not exists (select 1 from migr_doc_spesa_scarto s
--                          where s.migr_doc_spesa_id=migrDocumento.migr_docspesa_id
--		                  and   s.ente_proprietario_id=enteProprietarioId));
            continue;
        end if;

        strMessaggio:='Inserimento siac_r_doc_stato per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
		-- siac_r_doc_stato
        INSERT INTO siac_r_doc_stato
	    (doc_id,
	     doc_stato_id,
	     validita_inizio,
	     ente_proprietario_id,
	     data_creazione,
	     login_operazione
		)
        (select docId,
                stato.doc_stato_id,
                dataInizioVal::timestamp,
                 enteProprietarioId,
                 clock_timestamp(),
                 loginOperazione
         from siac_d_doc_stato stato
         where stato.doc_stato_code=migrDocumento.stato
         and   stato.ente_proprietario_id=enteProprietarioId
         and   stato.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio)
         and  (date_trunc('day',dataElaborazione)<date_trunc('day',stato.validita_fine) or stato.validita_fine is null)
         )
         returning doc_stato_r_id into scartoId;

         if scartoId is null then
			strMessaggio:=strMessaggio||' Verificare esistenza dello stato='||quote_nullable(migrDocumento.stato)||'.';
	       	INSERT INTO migr_doc_spesa_scarto
			(migr_doc_spesa_id,
	         motivo_scarto,
			 data_creazione,
		     ente_proprietario_id
			)values(migrDocumento.migr_docspesa_id,
 	                strMessaggio,
		            clock_timestamp(),
	           	    enteProprietarioId);
--            (select migrDocumento.migr_docspesa_id,
-- 	                strMessaggio,
--		            clock_timestamp(),
--	           	    enteProprietarioId
--             where not exists (select 1 from migr_doc_spesa_scarto s
--             		           where s.migr_doc_spesa_id=migrDocumento.migr_docspesa_id
--		            	       and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_doc inserito.';
             delete from siac_t_doc where doc_id=docId;

            continue;
         end if;

         strMessaggio:='Inserimento siac_r_doc_sog per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
         scartoId:=null;
         -- siac_r_doc_sog
		 INSERT INTO siac_r_doc_sog
		 (doc_id,
	      soggetto_id,
	      validita_inizio,
		  ente_proprietario_id,
	      data_creazione,
	 	  login_operazione
	 	 )
         (select docId,
                 sogg.soggetto_id,
                 dataInizioVal::timestamp,
                 enteProprietarioId,
                 clock_timestamp(),
                 loginOperazione
          from siac_t_soggetto sogg
          where sogg.soggetto_code = migrDocumento.codice_soggetto::varchar
          and   sogg.ente_proprietario_id = enteProprietarioId
          and   sogg.data_cancellazione is null
          and date_trunc('day',dataElaborazione)>=date_trunc('day',sogg.validita_inizio)
          and (date_trunc('day',dataElaborazione)<date_trunc('day',sogg.validita_fine) or sogg.validita_fine is null)
          and exists
          (select 1 from siac_r_migr_soggetto_soggetto r
           where r.ente_proprietario_id = sogg.ente_proprietario_id
           and   r.soggetto_id=sogg.soggetto_id))
        returning doc_sog_id into scartoId;

        if scartoId is null then
			strMessaggio:=strMessaggio||' Verificare esistenza del soggetto='||quote_nullable(migrDocumento.codice_soggetto::varchar)||'.';
	       	INSERT INTO migr_doc_spesa_scarto
	 	 	(migr_doc_spesa_id,
             motivo_scarto,
			 data_creazione,
		     ente_proprietario_id
			 )values(migrDocumento.migr_docspesa_id,
 	                 strMessaggio,
		             clock_timestamp(),
	           	     enteProprietarioId);
--             (select migrDocumento.migr_docspesa_id,
-- 	                 strMessaggio,
--		             clock_timestamp(),
--	           	     enteProprietarioId
--               where not exists (select 1 from migr_doc_spesa_scarto s
--                         		 where s.migr_doc_spesa_id=migrDocumento.migr_docspesa_id
--		                 		 and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_doc,siac_r_doc_stato inserito.';
             delete from siac_r_doc_stato where doc_id=docId;
             delete from siac_t_doc       where doc_id=docId;
            continue;
       end if;


	   -- 28.09.2015, inserimento registro unico fatture
	   if coalesce(migrDocumento.data_registro_fatt,NVL_STR)!=NVL_STR then
       -- 10.11.2015 Se l'anno di registrazione fattura ? passato in migrazione lo usiamo altrimenti si deduce dalla data.
           if coalesce(migrDocumento.anno_registro_fatt,NVL_STR)!=NVL_STR THEN
	           registrazione_anno := migrDocumento.anno_registro_fatt::integer;
           else
	           registrazione_anno := split_part(migrDocumento.data_registro_fatt,'-',1)::integer;
           end if;
           strMessaggio:='Inserimento siac_t_registrounico_doc per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
           scartoId:=null;
           -- siac_t_registrounico_doc
           INSERT INTO siac_t_registrounico_doc
           (rudoc_registrazione_anno,
           	rudoc_registrazione_numero,
            rudoc_registrazione_data,
            doc_id,
            validita_inizio,
            ente_proprietario_id,
            data_creazione,
            login_operazione
           )
           values
           (
			registrazione_anno,
            migrDocumento.numero_registro_fatt,
            migrDocumento.data_registro_fatt::timestamp,
            docId,
            dataInizioVal::timestamp,
            enteProprietarioId,
            clock_timestamp(),
            loginOperazione
           )
          returning rudoc_id into scartoId;

          if scartoId is null then
              strMessaggio:=strMessaggio||' Verificare inserimento registro unico fattura data='||migrDocumento.data_registro_fatt||' numero '|| migrDocumento.numero_registro_fatt||'.';
              INSERT INTO migr_doc_spesa_scarto
              (migr_doc_spesa_id,
               motivo_scarto,
               data_creazione,
               ente_proprietario_id
               )values(migrDocumento.migr_docspesa_id,
                       strMessaggio,
                       clock_timestamp(),
                       enteProprietarioId);
--               (select migrDocumento.migr_docspesa_id,
--                       strMessaggio,
  --                     clock_timestamp(),
--                       enteProprietarioId
--                 where not exists (select 1 from migr_doc_spesa_scarto s
--                                   where s.migr_doc_spesa_id=migrDocumento.migr_docspesa_id
--                                   and   s.ente_proprietario_id=enteProprietarioId));

               strMessaggio:=strMessaggio||' Cancellazione siac_t_doc,siac_r_doc_stato,siac_r_doc_sog inserito.';
               delete from siac_r_doc_stato where doc_id=docId;
               delete from siac_t_doc       where doc_id=docId;
               delete from siac_r_doc_sog   where doc_id=docId;
              continue;
         end if;
       end if;
	   -- fine registro unico fatture

       -- siac_r_doc_attr
       -- arrotondamento
       scartoId:=null;
       strMessaggio:='Inserimento siac_r_doc_attr per attr. '||ARROTONDAMENTO_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
       INSERT INTO siac_r_doc_attr
	   (doc_id,
	    attr_id,
        numerico,
        validita_inizio,
        ente_proprietario_id,
        data_creazione,
	    login_operazione
       )
       values
       (docId,
        arrotondamentoAttrId,
        migrDocumento.arrotondamento,
        dataInizioVal::timestamp,
        enteProprietarioId,
        clock_timestamp(),
        loginOperazione)
        returning doc_attr_id into scartoId;

         if scartoId is not null then
          -- termine_pagamento
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||TERMINE_PAGAM_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           numerico,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (docId,
           terminePagamAttrId,
           migrDocumento.termine_pagamento,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
          returning doc_attr_id into scartoId;
         end if;


         if scartoId is not null  then
          -- -- data_repertorio
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||DATA_REPERT_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
         )
         values
         (docId,
          dataRepertAttrId,
          migrDocumento.data_repertorio,
          dataInizioVal::timestamp,
          enteProprietarioId,
          clock_timestamp(),
          loginOperazione)
          returning doc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- numero_repertorio
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||NUM_REPERT_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
         )
         values
         (docId,
          numRepertAttrId,
          migrDocumento.numero_repertorio::varchar,
          dataInizioVal::timestamp,
          enteProprietarioId,
          clock_timestamp(),
          loginOperazione)
          returning doc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- anno_repertorio
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||ANNO_REPERT_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           --testo,   -- DAVIDE - 28.06.2016 - anno_repertorio gestito come numerico e non testo
           numerico,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
         )
         values
         (docId,
          annoRepertAttrId,
          migrDocumento.anno_repertorio::numeric, -- DAVIDE - 28.06.2016 - anno_repertorio gestito come numerico e non testo
          dataInizioVal::timestamp,
          enteProprietarioId,
          clock_timestamp(),
          loginOperazione)
          returning doc_attr_id into scartoId;
         end if;

		if scartoId is not null then
          -- note
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||NOTE_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (docId,
           noteAttrId,
           migrDocumento.note,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning doc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- causale_sospensione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||CAUS_SOSP_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (docId,
           causSospensioneAttrId,
           migrDocumento.causale_sospensione,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning doc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- data_sospensione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||DATA_SOSP_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (docId,
           dataSospensioneAttrId,
           migrDocumento.data_sospensione,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning doc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- data_riattivazione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||DATA_RIATT_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (docId,
           dataRiattivazioneAttrId,
           migrDocumento.data_riattivazione,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning doc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- codiceFiscalePignorato
          -- codice_fiscale_pign
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||CODFISC_PIGN_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (docId,
           codFiscPignoratoAttrId,
           migrDocumento.codice_fiscale_pign,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning doc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- dataScadenzaDopoSospensione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||DATA_SCAD_DOPOSOSP_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (docId,
           dataScadDopoSospAttrId,
           migrDocumento.data_scandenza_new,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning doc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- dataRicezione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||DATA_RICEZIONE_ATTR
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_attr
	      (doc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (docId,
           dataRicezioneAttrId,
           migrDocumento.data_ricezione,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning doc_attr_id into scartoId;
         end if;

         -- siac_r_doc_class
	     if   scartoId is not null
          and coalesce(migrDocumento.tipo_impresa,NVL_STR)!=NVL_STR then
          -- tipo_impresa
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_class per '||TIPO_IMPRESA_CL
                       ||'='||migrDocumento.tipo_impresa
                       ||' per migr_docspesa_id='||migrDocumento.migr_docspesa_id||'.';
          INSERT INTO siac_r_doc_class
          (doc_id,
           classif_id,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
           )
          (select docId,
                  class.classif_id,
                  dataInizioVal::timestamp,
                  enteProprietarioId,
                  clock_timestamp(),
                  loginOperazione
           from siac_t_class class
           where class.classif_tipo_id=tipoImpresaClassTipoId
           and   class.classif_code=migrDocumento.tipo_impresa
           and   class.data_cancellazione is null
           and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
           and  (date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine)
			      or class.validita_fine is null))
          returning doc_classif_id into scartoId;

         end if;

         if scartoId is null then
           strMessaggio:=strMessaggio||'Controllare esistenza attributo/classificatore.';
           INSERT INTO migr_doc_spesa_scarto
		   (migr_doc_spesa_id,
	        motivo_scarto,
		    data_creazione,
		    ente_proprietario_id
		    )values(migrDocumento.migr_docspesa_id,
 	                strMessaggio,
		            clock_timestamp(),
	          	    enteProprietarioId);
--           (select migrDocumento.migr_docspesa_id,
-- 	                strMessaggio,
--		            clock_timestamp(),
--	          	    enteProprietarioId
--             where not exists (select 1 from migr_doc_spesa_scarto s
--                          where s.migr_doc_spesa_id=migrDocumento.migr_docspesa_id
--		                  and   s.ente_proprietario_id=enteProprietarioId));

           strMessaggio:=strMessaggio||' Cancellazione siac_t_doc,siac_r_doc_stato, siac_r_doc_attr, siac_r_doc_class,siac_t_registrounico_doc inseriti.';

		   delete from siac_t_registrounico_doc where doc_id=docId;
           delete from siac_r_doc_stato where doc_id=docId;
           delete from siac_r_doc_attr  where doc_id=docId;
           delete from siac_r_doc_class where doc_id=docId;
           delete from siac_r_doc_sog where doc_id=docId;
		   delete from siac_t_doc       where doc_id=docId;

           continue;
        end if;


	   	strMessaggio:='Inserimento siac_r_migr_doc_spesa_t_doc per migr_docspesa_id= '
                               ||migrDocumento.migr_docspesa_id||'.';
        insert into siac_r_migr_doc_spesa_t_doc
        (migr_doc_spesa_id,doc_id,ente_proprietario_id,data_creazione)
        values
        (migrDocumento.migr_docspesa_id,docId,enteProprietarioId,clock_timestamp());

        numeroRecordInseriti:=numeroRecordInseriti+1;

        -- valorizzare fl_elab = 'S'
        update migr_doc_spesa set fl_elab='S'
        where ente_proprietario_id=enteProprietarioId
        and   migr_docspesa_id = migrDocumento.migr_docspesa_id
        and   fl_elab='N';

    end loop;

	-- AGGIORNARE siac_t_registrounico_doc_num per ente / anno col max(num)
    strMessaggio:='Aggiornamento contatore per registro unico fattura.';
    FOR countRuf in (
        select rudoc_registrazione_anno, max(rudoc_registrazione_numero) as numero
        from siac_t_registrounico_doc
        where ente_proprietario_id = enteProprietarioId
        and data_cancellazione is null
        group by rudoc_registrazione_anno)
    loop
    	select count(*) into v_count from siac_t_registrounico_doc_num where ente_proprietario_id = enteProprietarioId and rudoc_registrazione_anno = countRuf.rudoc_registrazione_anno
        and data_cancellazione is null
        and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
        and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine)
              or validita_fine is null);
        if v_count = 0 then
            strMessaggio:='Inserimento contatore ruf per anno '||countRuf.rudoc_registrazione_anno||
            	', numero '||countRuf.numero;
        	insert into siac_t_registrounico_doc_num
            (rudoc_registrazione_anno,
            rudoc_registrazione_numero,
            validita_inizio,
            ente_proprietario_id,
            data_creazione,
            login_operazione)
            values
            (countRuf.rudoc_registrazione_anno,
            countRuf.numero,
            dataInizioVal::timestamp,
            enteProprietarioId,
            clock_timestamp(),
            loginOperazione);
        else
          strMessaggio:='Aggiornamento contatore ruf per anno '||countRuf.rudoc_registrazione_anno||
			          ', numero '||countRuf.numero;
           update siac_t_registrounico_doc_num
           set rudoc_registrazione_numero = countRuf.numero
           where ente_proprietario_id = enteProprietarioId and rudoc_registrazione_anno = countRuf.rudoc_registrazione_anno
    	    and data_cancellazione is null
	        and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
        	and (date_trunc('day',dataElaborazione)<=date_trunc('day',validita_fine)
              or validita_fine is null);
        end if;

    end loop;


    RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||'. Inseriti '||numeroRecordInseriti||' documenti di spesa.';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
    when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||' Diverse righe presenti in archivio.';
        numerorecordinseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;