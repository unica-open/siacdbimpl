/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 21.04.2016 Sofia senza blocchi - preso da prod bilmult
CREATE OR REPLACE FUNCTION fnc_migr_docquo_spesa_iva(enteProprietarioId integer,
                                                    annobilancio varchar,
                                                    loginOperazione varchar,
                                                    dataElaborazione timestamp,
                                                    out numeroRecordInseriti integer,
                                                    out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE

 strNTrim VARCHAR(1):='1';
 strMessaggio VARCHAR(2500):='';
 strMessaggioFinale VARCHAR(2500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigrDoc integer := 0;

 migrDocumento record;
 contatoreProv record;

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 docId      integer:=null;

 NVL_STR CONSTANT varchar :='';

 FLAG_REGISTRAZIONE_IVA_ATTR  CONSTANT varchar := 'flagRegistrazioneIva';
 FLAG_INTRACOMUNITARIO_ATTR   CONSTANT varchar := 'flagIntracomunitario';
 FLAG_RILEVANTE_IRAP_ATTR 	  CONSTANT varchar := 'flagRilevanteIRAP';
 FLAG_NOTA_CREDITO_ATTR       CONSTANT varchar := 'flagNotaCredito';
 FLAG_RILEVANTE_IVA_ATTR 	  CONSTANT varchar := 'flagRilevanteIVA';

 flagRegistrazioneIvaAttrId integer:=null;
 flagIntracomunitarioAttrId integer:=null;
 flagRilevanteIrapAttrId	integer:=null;
 flagNotaCreditoAttrId		integer:=null;
 flagRilevanteIvaAttrId     integer:=null;

 v_subdociva_numero integer:=null; -- contatore per subdoc_iva

 ivaregid	 integer := null;
 regtipoid	 integer := null;
 docivarid   integer := null;
 subdocivaid integer := null;
 scartoId    integer := null;
 maxsubdocivanumero integer := null;
 count_subdocivanum integer := null;

 affected_rows numeric := 0;

 periodoId   integer := 0;
 count_subdocivaprotprovnum integer := null;
 maxdatachar varchar:='';

BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

--	strMessaggioFinale:='Migrazione documenti iva da id ['||idMin||'] a id ['||idMax||']';
	strMessaggioFinale:='Migrazione documenti iva.';

    strMessaggio:='Lettura documenti iva da migrare.';
	begin
		select distinct 1 into strict countMigrDoc from migr_docquo_spesa_iva ms
		where ms.ente_proprietario_id=enteProprietarioId
        and   ms.fl_elab='N';
--		and   ms.migr_docspesa_id >= idMin and ms.migr_docspesa_id <=idMax;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;

    begin

        strMessaggio:='Lettura identificativo attributo '||FLAG_REGISTRAZIONE_IVA_ATTR||'.';

        select attr.attr_id into strict flagRegistrazioneIvaAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_REGISTRAZIONE_IVA_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||FLAG_INTRACOMUNITARIO_ATTR||'.';

        select attr.attr_id into strict flagIntracomunitarioAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_INTRACOMUNITARIO_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||FLAG_RILEVANTE_IRAP_ATTR||'.';

        select attr.attr_id into strict flagRilevanteIrapAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_RILEVANTE_IRAP_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||FLAG_NOTA_CREDITO_ATTR||'.';

        select attr.attr_id into strict flagNotaCreditoAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_NOTA_CREDITO_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||FLAG_RILEVANTE_IVA_ATTR||'.';

        select attr.attr_id into strict flagRilevanteIvaAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_RILEVANTE_IVA_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;


    BEGIN
    	strMessaggio:='Lettura subdociva_num per anno '||annobilancio||'.';

        select subdociva_numero into strict v_subdociva_numero
        from siac_t_subdoc_iva_num
        where ente_proprietario_id = enteProprietarioId
        and subdociva_anno = annobilancio::integer
        and   data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
        and  (date_trunc('day',dataElaborazione)<date_trunc('day',validita_fine) or validita_fine is null);

        exception
		when no_data_found then
			v_subdociva_numero:=0;
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

	strMessaggio:='Scarto documenti iva senza documento spesa migrato';

    -- Se serve dettagliare il motivo scarto con eventuale motivo scarto del doc spesa, spostare il codice
    -- all'interno del loop.
    insert into MIGR_DOCQUO_SPESA_IVA_SCARTO
	(migr_docquo_spesa_iva_id,motivo_scarto,ente_proprietario_id)
    (select iva.migr_docquo_spesa_iva_id, 'Documento spesa non migrato.',enteProprietarioId
      from migr_docquo_spesa_iva iva where
      iva.ente_proprietario_id = enteProprietarioId
      and iva.fl_elab='N'
  --    and iva.migr_docquo_spesa_iva_id >= idMin and iva.migr_docquo_spesa_iva_id <=idMax
      and iva.docspesa_id not in (select migr.docspesa_id from migr_doc_spesa migr
                                  inner join siac_r_migr_doc_spesa_t_doc r on (r.migr_doc_spesa_id=migr.migr_docspesa_id)
                                  inner join siac_t_doc doc on (doc.doc_id=r.doc_id and doc.data_cancellazione is null
                                                                and date_trunc('day',dataelaborazione)>=date_trunc('day',doc.validita_inizio)
                                                                and (date_trunc('day',dataelaborazione)<=date_trunc('day',doc.validita_fine)
                                                                  or doc.validita_fine is null))
                                  where migr.ente_proprietario_id=enteProprietarioId));

    strMessaggio:='Lettura documenti iva da migrare.Inizio ciclo.';
    for migrDocumento IN
    (select
    	ms.*
        , doc.doc_id
     from migr_docquo_spesa_iva ms
     inner join migr_doc_spesa md on (md.docspesa_id=ms.docspesa_id
                                      and md.ente_proprietario_id=ms.ente_proprietario_id
                                      and md.fl_elab='S')
     inner join siac_r_migr_doc_spesa_t_doc r on (r.migr_doc_spesa_id=md.migr_docspesa_id)
     inner join siac_t_doc doc on (doc.doc_id=r.doc_id
							       and doc.ente_proprietario_id=ms.ente_proprietario_id
                                   and doc.data_cancellazione is null
                                   and date_trunc('day',dataelaborazione)>=date_trunc('day',doc.validita_inizio)
                                   and (date_trunc('day',dataelaborazione)<=date_trunc('day',doc.validita_fine)
                                   or doc.validita_fine is null))
	 where ms.ente_proprietario_id=enteProprietarioId
     and   ms.fl_elab='N'
--     and   ms.migr_docquo_spesa_iva_id >= idMin and ms.migr_docquo_spesa_iva_id <=idMax
     order by ms.migr_docquo_spesa_iva_id
     )
    loop
        ivaregid	:= null; -- pk siac_t_iva_registro
        regtipoid	:= null; -- pk siac_d_iva_registrazione_tipo
    	docivarid 	:= null; -- pk siac_r_doc_iva
        subdocivaid := null; -- pk siac_t_subdoc_iva
        scartoId	:= null;
        affected_rows := 0;
        begin
          strMessaggio := 'Ricerca registro iva per codice '||migrDocumento.sezionale||'.';

          select ivareg_id into strict ivaregid
          from siac_t_iva_registro
          where ivareg_code = migrDocumento.sezionale
          and ente_proprietario_id = enteproprietarioid
          and data_cancellazione is null
          and date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio)
          and (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

          strMessaggio := 'Ricerca registro iva tipo per codice '||migrDocumento.flag_registrazione_tipo_iva||'.';

          select reg_tipo_id into strict regtipoid
          from siac_d_iva_registrazione_tipo
          where reg_tipo_code = migrDocumento.flag_registrazione_tipo_iva
          and ente_proprietario_id = enteproprietarioid
          and data_cancellazione is null
          and date_trunc('day',dataelaborazione)>=date_trunc('day',validita_inizio)
          and (date_trunc('day',dataelaborazione)<=date_trunc('day',validita_fine) or validita_fine is null);

 		  exception
           when no_data_found then
        	strMessaggio := strMessaggio||' Scarto per dato non trovato.';
            INSERT INTO migr_docquo_spesa_iva_scarto
            (migr_docquo_spesa_iva_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrDocumento.migr_docquo_spesa_iva_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
        	continue;
          when too_many_rows THEN
        	strMessaggio := strMessaggio||' Scarto per troppi valori trovati.';
            INSERT INTO migr_docquo_spesa_iva_scarto
            (migr_docquo_spesa_iva_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrDocumento.migr_docquo_spesa_iva_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
        	continue;
          when others  THEN
              RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		end;

    	strMessaggio := 'Inserimento siac_r_doc_iva per doc_id = '||migrDocumento.doc_id||'.';

        -- si presuppone che per un docspesa iva sia definito un solo documento iva. Comunque viene inserita sempre una nuova relazione
        -- per ogni record ciclato.
        insert into siac_r_doc_iva
		  (doc_id, validita_inizio, ente_proprietario_id, login_operazione)
        values
          (migrDocumento.doc_id,
           dataInizioVal::timestamp,
           enteProprietarioId,
           loginOperazione)
        returning dociva_r_id into docivarid;

        if docivarid is null then
        	strMessaggio := strMessaggio||' Scarto per inserimento non riuscito.';
            INSERT INTO migr_docquo_spesa_iva_scarto
            (migr_docquo_spesa_iva_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrDocumento.migr_docquo_spesa_iva_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
        	continue;
        end if;

    	strMessaggio := 'Inserimento siac_t_subdoc_iva.';
    	v_subdociva_numero := v_subdociva_numero+1;
		insert into siac_t_subdoc_iva
          ( subdociva_anno,
            subdociva_numero,
            dociva_r_id,
            subdociva_soggetto_codice,
            ivareg_id,
            subdociva_prot_prov,
            subdociva_data_prot_prov,
            subdociva_data_registrazione,
            reg_tipo_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id)
            /*subdociva_desc VARCHAR(500),
            subdociva_importo_valuta NUMERIC,
            subdociva_data_scadenza TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
            subdociva_data_emissione TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
             VARCHAR(500),
             VARCHAR(200),
            subdociva_prot_def VARCHAR(200),
            subdociva_numordinativodoc VARCHAR(200),
             TIMESTAMP WITHOUT TIME ZONE,
             TIMESTAMP WITHOUT TIME ZONE,
            subdociva_data_prot_def TIMESTAMP WITHOUT TIME ZONE,
            subdociva_data_cassadoc TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
            subdociva_data_ordinativoadoc TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
            ivaatt_id INTEGER,
             INTEGER,
            valuta_id INTEGER,
             INTEGER,
             INTEGER NOT NULL,
             TIMESTAMP WITHOUT TIME ZONE NOT NULL,
            validita_fine TIMESTAMP WITHOUT TIME ZONE,
             INTEGER NOT NULL,
            data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
            data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
            data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
             VARCHAR(200) NOT NULL)*/
         values
         (annobilancio
          ,v_subdociva_numero
          ,docivarid
          ,migrDocumento.codice_soggetto
          ,ivaregid
          ,migrDocumento.numero_prot_prov
          ,migrDocumento.data_prot_prov::timestamp
          ,migrDocumento.data_registrazione::timestamp
          ,regtipoid
          ,dataInizioVal::timestamp
          ,loginOperazione
          ,enteproprietarioid)
        returning subdociva_id into subdocivaid;

        if subdocivaid is null then
        	strMessaggio := strMessaggio||' Scarto per inserimento non riuscito.';
            INSERT INTO migr_docquo_spesa_iva_scarto
            (migr_docquo_spesa_iva_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrDocumento.migr_docquo_spesa_iva_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);

            v_subdociva_numero := v_subdociva_numero-1;
            delete from siac_r_doc_iva where dociva_r_id = docivarid;

            continue;
        end if;

		scartoId:=null;
        strMessaggio := 'Inserimento siac_r_subdoc_iva_stato.';
        insert into siac_r_subdoc_iva_stato
        (subdociva_id,
		 subdociva_stato_id,
		 validita_inizio,
	     ente_proprietario_id,
		 login_operazione)
  		(select subdocivaid
           , st.subdociva_stato_id
           , dataInizioVal::timestamp
           , enteproprietarioid
           , loginOperazione
          from siac_d_subdoc_iva_stato st
          where st.subdociva_stato_code = migrDocumento.stato
          and st.ente_proprietario_id = enteproprietarioid
          and st.data_cancellazione is null
          and date_trunc('day',dataelaborazione)>=date_trunc('day',st.validita_inizio)
          and (date_trunc('day',dataelaborazione)<=date_trunc('day',st.validita_fine) or st.validita_fine is null))
        returning subdociva_stato_r_id into scartoId;

        if scartoId is null then
        	strMessaggio := strMessaggio||' Scarto per inserimento non riuscito.';
            INSERT INTO migr_docquo_spesa_iva_scarto
            (migr_docquo_spesa_iva_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrDocumento.migr_docquo_spesa_iva_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);

			strMessaggio:=strMessaggio||' Cancellazione siac_r_doc_iva, siac_t_subdoc_iva inseriti.';
            v_subdociva_numero := v_subdociva_numero-1;
            delete from siac_r_doc_iva where dociva_r_id = docivarid;
            delete from siac_t_subdoc_iva where subdociva_id = subdocivaid;
            continue;

        end if;

		-- attributi
          strMessaggio:='Inserimento siac_r_subdoc_iva_attr per attr. '||FLAG_REGISTRAZIONE_IVA_ATTR
                       ||' per migr_docquo_spesa_iva_id='||migrDocumento.migr_docquo_spesa_iva_id||'.';
          INSERT INTO siac_r_subdoc_iva_attr
	      (subdociva_id,
	       attr_id,
           "boolean",
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subdocivaid,
           flagRegistrazioneIvaAttrId,
           migrDocumento.flag_registrazione_iva,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdociva_attr_id into scartoId;

	     if scartoId is not null then
          strMessaggio:='Inserimento siac_r_subdoc_iva_attr per attr. '||FLAG_INTRACOMUNITARIO_ATTR
                       ||' per migr_docquo_spesa_iva_id='||migrDocumento.migr_docquo_spesa_iva_id||'.';
          INSERT INTO siac_r_subdoc_iva_attr
	      (subdociva_id,
	       attr_id,
           "boolean",
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subdocivaid,
           flagIntracomunitarioAttrId,
           migrDocumento.flag_intracomunitario,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdociva_attr_id into scartoId;
         end if;

         if scartoId is not null then
          strMessaggio:='Inserimento siac_r_subdoc_iva_attr per attr. '||FLAG_RILEVANTE_IRAP_ATTR
                       ||' per migr_docquo_spesa_iva_id='||migrDocumento.migr_docquo_spesa_iva_id||'.';
          INSERT INTO siac_r_subdoc_iva_attr
	      (subdociva_id,
	       attr_id,
           "boolean",
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subdocivaid,
           flagRilevanteIrapAttrId,
           migrDocumento.flag_rilevante_irap,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdociva_attr_id into scartoId;
         end if;

         if scartoId is not null then
          strMessaggio:='Inserimento siac_r_subdoc_iva_attr per attr. '||FLAG_NOTA_CREDITO_ATTR
                       ||' per migr_docquo_spesa_iva_id='||migrDocumento.migr_docquo_spesa_iva_id||'.';
          INSERT INTO siac_r_subdoc_iva_attr
	      (subdociva_id,
	       attr_id,
           "boolean",
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subdocivaid,
           flagNotaCreditoAttrId,
           migrDocumento.flag_nota_credito,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdociva_attr_id into scartoId;
         end if;



         if scartoId is null then
            strMessaggio:=strMessaggio||'Controllare esistenza attributo.';
            INSERT INTO migr_docquo_spesa_iva_scarto
            (migr_docquo_spesa_iva_id,
             motivo_scarto,
             data_creazione,
             ente_proprietario_id
            )values(migrDocumento.migr_docquo_spesa_iva_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);

			strMessaggio:=strMessaggio||' Cancellazione siac_r_doc_iva, siac_t_subdoc_iva, siac_r_subdoc_iva* inseriti.';
            v_subdociva_numero := v_subdociva_numero-1;

            delete from siac_r_doc_iva where dociva_r_id = docivarid;
            delete from siac_r_subdoc_iva_attr where subdociva_id = subdocivaid;
            delete from siac_r_subdoc_iva_stato where subdociva_id = subdocivaid;
            delete from siac_t_subdoc_iva where subdociva_id = subdocivaid;

            continue;

         end if;

          strMessaggio:='Update siac_r_subdoc_attr per attr. '||FLAG_RILEVANTE_IVA_ATTR
                       ||' per migr_docquo_spesa_iva_id='||migrDocumento.migr_docquo_spesa_iva_id||'.';

		  UPDATE siac_r_subdoc_attr attr
          	set "boolean" = 'S'
            , login_operazione = loginOperazione
            , validita_inizio = clock_timestamp()
            where attr.attr_id=flagRilevanteIvaAttrId
            and attr.subdoc_id in
            	(select subdoc_id from siac_t_subdoc sub where sub.ente_proprietario_id=enteProprietarioId and sub.doc_id=migrDocumento.doc_id)
            and attr.ente_proprietario_id = enteProprietarioId;

			IF NOT FOUND THEN
            	strMessaggio := strMessaggio || 'Nessun record da modificare.';
				insert into migr_docquo_spesa_iva_scarto
                (migr_docquo_spesa_iva_id,
             		motivo_scarto,
             		data_creazione,
             		ente_proprietario_id
            		)values(migrDocumento.migr_docquo_spesa_iva_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
			END IF;

       strMessaggio:='update siac_t_subdoc.subdoc_nreg_iva per doc_id='||migrDocumento.doc_id||', migr_docquo_spesa_iva_id = '||migrDocumento.migr_docquo_spesa_iva_id||'.';

       update siac_t_subdoc set
       	subdoc_nreg_iva = annobilancio||'/'||v_subdociva_numero
       where ente_proprietario_id = enteProprietarioId
       and doc_id = migrDocumento.doc_id;

			IF NOT FOUND THEN
            	strMessaggio := strMessaggio || 'Nessun record da modificare.';
				insert into migr_docquo_spesa_iva_scarto
                (migr_docquo_spesa_iva_id,
             		motivo_scarto,
             		data_creazione,
             		ente_proprietario_id
            		)values(migrDocumento.migr_docquo_spesa_iva_id,
                    strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
			END IF;



	   	strMessaggio:='Inserimento siac_r_migr_docquospesaiva_t_subdoc_iva per migr_docquo_spesa_iva_id= '
                               ||migrDocumento.migr_docquo_spesa_iva_id||'.';

        insert into siac_r_migr_docquospesaiva_t_subdoc_iva
        (migr_docquo_spesa_iva_id,subdociva_id,ente_proprietario_id,data_creazione)
        values
        (migrDocumento.migr_docquo_spesa_iva_id,subdocivaid,enteProprietarioId,clock_timestamp());

        numeroRecordInseriti:=numeroRecordInseriti+1;

        update migr_docquo_spesa_iva set fl_elab='S'
        where ente_proprietario_id=enteProprietarioId
        and   migr_docquo_spesa_iva_id = migrDocumento.migr_docquo_spesa_iva_id
        and   fl_elab='N';

    end loop;

    -- update del contatore.
    strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_num per anno '||annobilancio||'.';
    select i.subdociva_numero into maxsubdocivanumero
    from siac_t_subdoc_iva i
    where i.ente_proprietario_id=enteproprietarioid
    and i.subdociva_anno = annoBilancio
    order by i.subdociva_numero desc limit 1;

    if maxsubdocivanumero is not null and maxsubdocivanumero > 0 then
		select coalesce (count(*),0) into count_subdocivanum from  siac_t_subdoc_iva_num
        where ente_proprietario_id = enteProprietarioId and subdociva_anno = annobilancio::integer and data_cancellazione is null;
        if count_subdocivanum = 0 then
		    strMessaggio := 'Inserimento del contatore siac_t_subdoc_iva_num per anno '||annobilancio||',numero '||maxsubdocivanumero||'.';
            insert into siac_t_subdoc_iva_num
            (subdociva_anno,subdociva_numero,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
            values
            (annobilancio::integer, maxsubdocivanumero,dataInizioVal::timestamp,enteproprietarioid,clock_timestamp(),loginOperazione);
        else
		    strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_num per anno '||annobilancio||',numero '||maxsubdocivanumero||'.';
            update siac_t_subdoc_iva_num
            set subdociva_numero = maxsubdocivanumero
            ,data_modifica = clock_timestamp()
            where subdociva_anno = annobilancio::integer
            and ente_proprietario_id = enteproprietarioid;
        end if;
    end if;

    -- update del contatore siac_t_subdoc_iva_prot_prov_num

    strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_prot_prov_num.';
    for contatoreProv in
    (
    	select subdoc.*,  reg.ivareg_code,reg.ivareg_desc, ct.ivachi_tipo_code, ct.ivachi_tipo_desc
		 from
          siac_t_iva_registro reg,siac_r_iva_registro_gruppo ig, siac_r_iva_gruppo_chiusura gc, siac_d_iva_chiusura_tipo ct,
            (select iva.ivareg_id, max(subdociva_data_prot_prov) maxData, max(iva.subdociva_prot_prov::numeric) maxNum
            from siac_t_subdoc_iva iva
            where ente_proprietario_id = enteproprietarioid
            and fnc_migr_isnumeric(iva.subdociva_prot_prov)
            group by ivareg_id)subdoc
          where reg.ivareg_id = ig.ivareg_id
          and   ig.ivagru_id=gc.ivagru_id
          and   gc.ivachi_tipo_id=ct.ivachi_tipo_id
          and   subdoc.ivareg_id=reg.ivareg_id )
    loop
    	strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_prot_prov_num per ivareg_id '|| contatoreProv.ivareg_id
        ||', data '||contatoreProv.maxData
        || ', num '||contatoreProv.maxNum ||'.';

        maxdatachar := to_char (contatoreProv.maxData,'dd/mm/yyyy');

        if contatoreProv.ivachi_tipo_code = 'M' then
          select p.periodo_id into strict periodoId
          from siac_t_periodo p where
              p.ente_proprietario_id = enteproprietarioid

              and p.periodo_code = split_part(maxdatachar,'/',2)||split_part(maxdatachar,'/',3);

              --and p.periodo_code = '01'||split_part(maxdatachar,'/',3);
        end if;

        if contatoreProv.ivachi_tipo_code = 'A' then
          select p.periodo_id into strict periodoId
          from siac_t_periodo p where
              p.ente_proprietario_id = enteproprietarioid
              and p.periodo_code = 'anno'||split_part(maxdatachar,'/',3);
        end if;

        if contatoreProv.ivachi_tipo_code = 'T' then

        select p.periodo_id into strict periodoId
          from siac_t_periodo p where
              p.ente_proprietario_id = enteproprietarioid
              and p.periodo_code = 'trim'
                  || case split_part(maxdatachar,'/',2)
                      when '01' then '1'
                      when '02' then '1'
                      when '03' then '1'
                      when '04' then '2'
                      when '05' then '2'
                      when '06' then '2'
                      when '07' then '3'
                      when '08' then '3'
                      when '09' then '3'
                      when '10' then '4'
                      when '11' then '4'
                      when '12' then '4'
                      else '' end;
                  --and p.periodo_code = 'trim1'|| split_part(maxdatachar,'/',3);
        end if;

		select coalesce (count(*),0) into count_subdocivaprotprovnum from  siac_t_subdoc_iva_prot_prov_num n
        where ente_proprietario_id = enteProprietarioId and n.ivareg_id = contatoreProv.ivareg_id and n.periodo_id = periodoId
        and data_cancellazione is null;
        if count_subdocivaprotprovnum = 0 then
		    strMessaggio := 'Inserimento del contatore siac_t_subdoc_iva_prot_prov_num per ivareg_id '||contatoreProv.ivareg_id||',periodo '||periodoId
            ||',data '||contatoreProv.maxData
            ||',periodo '||contatoreProv.maxNum||'.';
            insert into siac_t_subdoc_iva_prot_prov_num
			(ivareg_id,periodo_id,subdociva_data_prot_prov,subdociva_prot_prov,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
            values
            (contatoreProv.ivareg_id, periodoId,contatoreProv.maxData,contatoreProv.maxNum::integer,dataInizioVal::timestamp,enteproprietarioid,clock_timestamp(),loginOperazione);
        else
		    strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_prot_prov_num per ivareg_id '||contatoreProv.ivareg_id||',periodo '||periodoId
            ||',data '||contatoreProv.maxData
            ||',periodo '||contatoreProv.maxNum||'.';
            update siac_t_subdoc_iva_prot_prov_num
            set subdociva_data_prot_prov = contatoreProv.maxData
            ,subdociva_prot_prov = contatoreProv.maxNum::integer
            ,data_modifica = clock_timestamp()
            where ivareg_id = contatoreProv.ivareg_id
            and periodo_id = periodoId
            and ente_proprietario_id = enteproprietarioid;
        end if;
    end loop;

    RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||' Inseriti '||numeroRecordInseriti||' quote documenti iva.';
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