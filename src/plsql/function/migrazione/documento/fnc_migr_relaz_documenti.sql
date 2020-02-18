/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_relaz_documenti
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out numeroRecordInseriti integer,
  out messaggioRisultato varchar )
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigrRelDoc integer := 0;

 migrRelDoc record;
 migrQuoteDoc record;                -- DAVIDE - 07.10.2016 - aggiunta importo da dedurre se il documento è un NCD
 docDaId integer:=null;
 docAId integer:=null;
 docRId integer:=null;
 scartoId integer:=null;
 relazTipoId integer:=null;
 relazTipoNcdId integer:=null;
 relazTipoSubId integer:=null;
 sumimportodadedurre numeric := null; -- DAVIDE - 07.10.2016 - aggiunta importo da dedurre se il documento è un NCD
 ImportoNCD          numeric := null; -- DAVIDE - 28.10.2016 - se la somma è 0, allora importodadedurre sarà uguale all'importo della NCD

 NVL_STR                   CONSTANT VARCHAR:='';

 REL_DOC_NCD               CONSTANT VARCHAR:='NCD';
 REL_DOC_SUB               CONSTANT VARCHAR:='SUB';

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione relazione documenti.';

    strMessaggio:='Lettura relazione documenti da migrare.';
	begin
		select distinct 1 into strict countMigrRelDoc
        from migr_relaz_documenti ms
		where ms.ente_proprietario_id=enteProprietarioId
        and   ms.fl_elab='N';

	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;


	begin

        -- relazTipoNcdId
        strMessaggio:='Lettura tipo relazione doc   '||REL_DOC_NCD||'.';
        select tipo.relaz_tipo_id into strict relazTipoNcdId
        from siac_d_relaz_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.relaz_tipo_code=REL_DOC_NCD
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


		-- relazTipoSubId
        strMessaggio:='Lettura tipo relazione doc   '||REL_DOC_SUB||'.';
        select tipo.relaz_tipo_id into strict relazTipoSubId
        from siac_d_relaz_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.relaz_tipo_code=REL_DOC_SUB
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;

    strMessaggio:='Lettura migrazione documenti da migrare.Inizio ciclo.';
    for migrRelDoc IN
    (select ms.*
     from migr_relaz_documenti ms
     where ms.ente_proprietario_id=enteProprietarioId
     and   ms.fl_elab='N'
     order by ms.migr_relaz_doc_id
    )
    loop

        scartoId:=null;
        docDaId:=null;
        docAId:=null;
        docRId:=null;
        relazTipoId:=null;
        sumimportodadedurre := null; -- DAVIDE - 07.10.2016 - aggiunta importo da dedurre se il documento è un NCD
        ImportoNCD := null;          -- DAVIDE - 28.10.2016 - se la somma è 0, allora importodadedurre sarà uguale all'importo della NCD

        strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||'  da migrare per migr_relaz_doc_id='
                       || migrRelDoc.migr_relaz_doc_id||'. Lettura documento doc_id_da.';

		select coalesce(relDoc.doc_id,0) into docDaId
        from siac_r_migr_doc_spesa_t_doc relDoc, migr_doc_spesa migrDoc
        where migrDoc.docspesa_id=migrRelDoc.doc_id_da
        and   migrDoc.ente_proprietario_id=enteProprietarioId
        and   relDoc.migr_doc_spesa_id=migrDoc.migr_docspesa_id
        and   relDoc.ente_proprietario_id=enteProprietarioId
        and   exists (select 1 from siac_t_doc doc
                      where doc.doc_id=relDoc.doc_id
                      and   doc.data_cancellazione is null
                      and   date_trunc('day',dataElaborazione)>=date_trunc('day',doc.validita_inizio) and
                            (date_trunc('day',dataElaborazione)<=date_trunc('day',doc.validita_fine)
                             or doc.validita_fine is null));

        if coalesce(docDaId,0)=0 then
        	-- scarto
			strMessaggio:=strMessaggio||'Documento doc_id_da='||migrRelDoc.doc_id_da
                                      ||' in migr_relaz_documenti non migrato.';
            insert into migr_relaz_documenti_scarto
            ( migr_relaz_doc_id,
              motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrRelDoc.migr_relaz_doc_id,
         	         strMessaggio,
	                 clock_timestamp(),
     	             enteProprietarioId);
--     	    ( select migrRelDoc.migr_relaz_doc_id,
--         	         strMessaggio,
--	                 clock_timestamp(),
--     	             enteProprietarioId
--              where not exists
--                    (select 1 from migr_relaz_documenti_scarto s
--                     where s.migr_relaz_doc_id=migrRelDoc.migr_relaz_doc_id
--                     and   s.ente_proprietario_id=enteProprietarioId)
--            );
            continue;
        end if;


        strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||'  da migrare per migr_relaz_doc_id='
                       || migrRelDoc.migr_relaz_doc_id||'. Lettura documento doc_id_a.';

        if   migrRelDoc.relaz_tipo=REL_DOC_NCD then
        	relazTipoId=relazTipoNcdId;

        	select coalesce(relDoc.doc_id,0), migrDoc.Importo into docAId, ImportoNCD
	        from siac_r_migr_doc_spesa_t_doc relDoc, migr_doc_spesa migrDoc
    	    where migrDoc.docspesa_id=migrRelDoc.doc_id_a
        	and   migrDoc.ente_proprietario_id=enteProprietarioId
	        and   relDoc.migr_doc_spesa_id=migrDoc.migr_docspesa_id
    	    and   relDoc.ente_proprietario_id=enteProprietarioId
        	and   exists (select 1 from siac_t_doc doc
            	          where doc.doc_id=relDoc.doc_id
                	      and   doc.data_cancellazione is null
                    	  and   date_trunc('day',dataElaborazione)>=date_trunc('day',doc.validita_inizio) and
                        	    (date_trunc('day',dataElaborazione)<=date_trunc('day',doc.validita_fine)
                            	 or doc.validita_fine is null));

            -- 02.11.2016 Sofia
            if ImportoNCD is null then ImportoNCD:=0; end if;

            -- DAVIDE - 07.10.2016 - ricava importo da dedurre se il documento è un NCD
			-- come somma degli importi da dedurre di tutte le quote collegate al documento
            strMessaggio:='Lettura quote documento per determinare l''importo da dedurre da inserire nella relazione.';
            -- 02.11.2016 Sofia
			sumimportodadedurre:=0;
            for migrQuoteDoc IN
            (select mq.*
               from siac_t_subdoc mq
              where mq.ente_proprietario_id=enteProprietarioId
                and mq.doc_id=docDaId)
            loop
                sumimportodadedurre := sumimportodadedurre+migrQuoteDoc.subdoc_importo_da_dedurre;
            end loop;

	        -- DAVIDE - 28.10.2016 - se la somma è 0, allora importodadedurre sarà uguale all'importo della NCD
            if sumimportodadedurre = 0 then
			    sumimportodadedurre := abs(ImportoNCD);
            end if;

        else
        	relazTipoId=relazTipoSubId;
        	select coalesce(relDoc.doc_id,0) into docAId
	        from siac_r_migr_doc_entrata_t_doc relDoc, migr_doc_entrata migrDoc
    	    where migrDoc.docentrata_id=migrRelDoc.doc_id_a
        	and   migrDoc.ente_proprietario_id=enteProprietarioId
	        and   relDoc.migr_doc_entrata_id=migrDoc.migr_docentrata_id
    	    and   relDoc.ente_proprietario_id=enteProprietarioId
        	and   exists (select 1 from siac_t_doc doc
            	          where doc.doc_id=relDoc.doc_id
                	      and   doc.data_cancellazione is null
                    	  and   date_trunc('day',dataElaborazione)>=date_trunc('day',doc.validita_inizio) and
                        	    (date_trunc('day',dataElaborazione)<=date_trunc('day',doc.validita_fine)
                            	 or doc.validita_fine is null));

        end if;

        if coalesce(docAId,0)=0 then
        	-- scarto
   			strMessaggio:=strmessaggio||'Documento doc_id_a='||migrRelDoc.doc_id_a
	                                  ||' in migr_relaz_documenti non migrato.';
            insert into migr_relaz_documenti_scarto
            ( migr_relaz_doc_id,
              motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrRelDoc.migr_relaz_doc_id,
         	         strMessaggio,
	                 clock_timestamp(),
     	             enteProprietarioId);
--             ( select migrRelDoc.migr_relaz_doc_id,
--         	         strMessaggio,
--	                 clock_timestamp(),
--     	             enteProprietarioId
--                where not exists
--                    (select 1 from migr_relaz_documenti_scarto s
--                     where s.migr_relaz_doc_id=migrRelDoc.migr_relaz_doc_id
--                     and   s.ente_proprietario_id=enteProprietarioId)
--            );

		    continue;
        end if;

        scartoId:=null;
		strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||'  da migrare per migr_relaz_doc_id='
                       || migrRelDoc.migr_relaz_doc_id||'. Inserimento siac_r_doc.';
        insert into siac_r_doc
        (relaz_tipo_id,
	     doc_id_da,
	     doc_id_a,
         validita_inizio,
         data_creazione,
         login_operazione,
         doc_importo_da_dedurre,  -- DAVIDE - 07.10.2016 - aggiunta importo da dedurre se il documento è un NCD
         ente_proprietario_id)
        values
        (relazTipoId,
         docDaId,
         docAId,
         dataInizioVal::timestamp,
         clock_timestamp(),
         loginOperazione,
		 sumimportodadedurre,     -- DAVIDE - 07.10.2016 - aggiunta importo da dedurre se il documento è un NCD
         enteProprietarioId)
        returning doc_r_id into docRId;

		if docRId is null then
        	-- scarto
   			strMessaggio:=strmessaggio||' Inserimento non riuscito.';
            insert into migr_relaz_documenti_scarto
            ( migr_relaz_doc_id,
              motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrRelDoc.migr_relaz_doc_id,
         	         strMessaggio,
	                 clock_timestamp(),
     	             enteProprietarioId);
--       	    ( select migrRelDoc.migr_relaz_doc_id,
--         	         strMessaggio,
--	                 clock_timestamp(),
--     	             enteProprietarioId
--              where not exists
--                    (select 1 from migr_relaz_documenti_scarto s
--                     where s.migr_relaz_doc_id=migrRelDoc.migr_relaz_doc_id
--                     and   s.ente_proprietario_id=enteProprietarioId)
--            );

		    continue;
        end if;

        scartoId:=null;
        strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||'  da migrare per migr_relaz_doc_id='
                       || migrRelDoc.migr_relaz_doc_id||'. Inserimento siac_r_migr_relaz_documenti_doc.';
		insert into siac_r_migr_relaz_documenti_doc
        (migr_relaz_doc_id,
  		 doc_r_id,
         data_creazione,
		 ente_proprietario_id)
         values
        (migrRelDoc.migr_relaz_doc_id,
         docRId,
         clock_timestamp(),
         enteProprietarioId
        )
        returning migr_relaz_doc_rel_id into scartoId;

    	if scartoId is null then
        	--scarto
 		    strMessaggio:=strmessaggio||'Documento doc_id_da='||migrRelDoc.doc_id_da
                                      ||' inserimento non riuscito.';
            insert into migr_relaz_documenti_scarto
            ( migr_relaz_doc_id,
              motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrRelDoc.migr_relaz_doc_id,
         	         strMessaggio,
	                 clock_timestamp(),
     	             enteProprietarioId);
--      	    ( select migrRelDoc.migr_relaz_doc_id,
--         	         strMessaggio,
--	                 clock_timestamp(),
--     	             enteProprietarioId
--              where not exists
--                    (select 1 from migr_relaz_documenti_scarto s
--                     where s.migr_relaz_doc_id=migrRelDoc.migr_relaz_doc_id
--                     and   s.ente_proprietario_id=enteProprietarioId)
--            );



            delete from siac_r_doc where doc_r_id=docRId;
            continue;
        end if;



       strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||'  da migrare per migr_relaz_doc_id='
                       || migrRelDoc.migr_relaz_doc_id||'. Aggiornamento migr_relaz_documenti per fl_elab.';
		update migr_relaz_documenti
        set fl_elab='S'
        where migr_relaz_doc_id=migrRelDoc.migr_relaz_doc_id
        and   fl_elab='N';


        numeroRecordInseriti:=numeroRecordInseriti+1;

    end loop;

	RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||'Inseriti '||numeroRecordInseriti||' elenchi doc.';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=
        	quote_nullable(strMessaggioFinale)||quote_nullable(strMessaggio)||'ERRORE:  '||' '||quote_nullable(substring(upper(SQLERRM) from 1 for 500)) ;
        numerorecordinseriti:=-1;
        return;
     when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Diverse righe presenti in archivio.';
        numerorecordinseriti:=-1;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;