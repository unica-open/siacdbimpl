/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- 21.04.2016 Sofia - versione senza gestione blocchi presa da prod bilmult
CREATE OR REPLACE FUNCTION fnc_migr_relaz_documenti_iva (
  enteproprietarioid integer,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out numerorecordinseriti integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigrRelDoc integer := 0;

 migrRelDoc record;
 docDaId integer:=null;
 docAId integer:=null;
 docRId integer:=null;
 scartoId integer:=null;
 relazTipoId integer:=null;
 relazTipoNcdiId integer:=null;

 REL_DOC_NCDI CONSTANT VARCHAR:='NCDI';

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione relazione documenti iva.';

    strMessaggio:='Lettura relazione documenti iva da migrare.';
	begin
		select distinct 1 into strict countMigrRelDoc
        from migr_relaz_docquo_spesa_iva ms
		where ms.ente_proprietario_id=enteProprietarioId
        and   ms.fl_elab='N';

	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;

	begin

        -- relazTipoNcdiId
        strMessaggio:='Lettura tipo relazione doc   '||REL_DOC_NCDI||'.';
        select tipo.relaz_tipo_id into strict relazTipoNcdiId
        from siac_d_relaz_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.relaz_tipo_code=REL_DOC_NCDI
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
     from migr_relaz_docquo_spesa_iva ms
     where ms.ente_proprietario_id=enteProprietarioId
     and   ms.fl_elab='N'
     order by ms.migr_relazdocquo_id
    )
    loop

        scartoId:=null;
        docDaId:=null;
        docAId:=null;
        docRId:=null;

        strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||' da migrare per migr_relazdocquo_id='
                       || migrRelDoc.migr_relazdocquo_id||'. Lettura documento doc_id_da.';

		select coalesce(relDoc.subdociva_id,0) into docDaId
        from siac_r_migr_docquospesaiva_t_subdoc_iva relDoc, migr_docquo_spesa_iva migrDoc
        where migrDoc.docquo_spesa_iva_id=migrRelDoc.docquo_spesa_iva_id_da
        and   migrDoc.ente_proprietario_id=enteProprietarioId
        and   relDoc.migr_docquo_spesa_iva_id=migrDoc.migr_docquo_spesa_iva_id
        and   relDoc.ente_proprietario_id=enteProprietarioId
        and   exists (select 1 from siac_t_subdoc_iva doc
                      where doc.subdociva_id=relDoc.subdociva_id
                      and   doc.data_cancellazione is null
                      and   date_trunc('day',dataElaborazione)>=date_trunc('day',doc.validita_inizio) and
                            (date_trunc('day',dataElaborazione)<=date_trunc('day',doc.validita_fine)
                             or doc.validita_fine is null));

        if coalesce(docDaId,0)=0 then
        	-- scarto
			strMessaggio:=strMessaggio||'Documento docquo_spesa_iva_id_da='||migrRelDoc.docquo_spesa_iva_id_da
                                      ||' in migr_relaz_docquo_spesa_iva non migrato.';
            insert into migr_relaz_docquo_spesa_iva_scarto
            ( migr_relazdocquo_id,
              motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrRelDoc.migr_relazdocquo_id,
         	         strMessaggio,
	                 clock_timestamp(),
     	             enteProprietarioId);
            continue;
        end if;

        strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||'  da migrare per migr_relaz_doc_id='
                       || migrRelDoc.migr_relazdocquo_id||'. Lettura documento doc_id_a.';

		select coalesce(relDoc.subdociva_id,0) into docAId
        from siac_r_migr_docquospesaiva_t_subdoc_iva relDoc, migr_docquo_spesa_iva migrDoc
        where migrDoc.docquo_spesa_iva_id=migrRelDoc.docquo_spesa_iva_id_a
        and   migrDoc.ente_proprietario_id=enteProprietarioId
        and   relDoc.migr_docquo_spesa_iva_id=migrDoc.migr_docquo_spesa_iva_id
        and   relDoc.ente_proprietario_id=enteProprietarioId
        and   exists (select 1 from siac_t_subdoc_iva doc
                      where doc.subdociva_id=relDoc.subdociva_id
                      and   doc.data_cancellazione is null
                      and   date_trunc('day',dataElaborazione)>=date_trunc('day',doc.validita_inizio) and
                            (date_trunc('day',dataElaborazione)<=date_trunc('day',doc.validita_fine)
                             or doc.validita_fine is null));

        if coalesce(docAId,0)=0 then
        	-- scarto
   			strMessaggio:=strmessaggio||'Documento docquo_spesa_iva_id_a='||migrRelDoc.docquo_spesa_iva_id_a
	                                  ||' in migr_relaz_docquo_spesa_iva non migrato.';
            insert into migr_relaz_docquo_spesa_iva_scarto
            ( migr_relazdocquo_id,
              motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrRelDoc.migr_relazdocquo_id,
         	         strMessaggio,
	                 clock_timestamp(),
     	             enteProprietarioId);

		    continue;
        end if;

        scartoId:=null;
		strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||'  da migrare per migr_relazdocquo_id='
                       || migrRelDoc.migr_relazdocquo_id||'. Inserimento siac_r_subdoc_iva.';
        insert into siac_r_subdoc_iva
        (
          relaz_tipo_id,
          subdociva_id_da,
          subdociva_id_a,
          validita_inizio,
          data_creazione,
          ente_proprietario_id,
          login_operazione)
        values
        (relazTipoNcdiId,
         docDaId,
         docAId,
         dataInizioVal::timestamp,
         clock_timestamp(),
         enteProprietarioId,
         loginOperazione
		 )
        returning doc_r_id into docRId;

		if docRId is null then
        	-- scarto
   			strMessaggio:=strmessaggio||' Inserimento non riuscito.';
            insert into migr_relaz_docquo_spesa_iva_scarto
            ( migr_relazdocquo_id,
              motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrRelDoc.migr_relazdocquo_id,
         	         strMessaggio,
	                 clock_timestamp(),
     	             enteProprietarioId);
		    continue;
        end if;

        scartoId:=null;
        strMessaggio:='Relazione documento tipo='
        			   ||migrRelDoc.relaz_tipo||'  da migrare per migr_relaz_doc_id='
                       || migrRelDoc.migr_relazdocquo_id||'. Inserimento siac_r_migr_relazdocquospesaiva_subdoc.';

		insert into siac_r_migr_relazdocquospesaiva_subdoc
        (migr_relazdocquo_id,
  		 doc_r_id,
         data_creazione,
		 ente_proprietario_id)
         values
        (migrRelDoc.migr_relazdocquo_id,
         docRId,
         clock_timestamp(),
         enteProprietarioId
        )
        returning migr_relazdocquo_rel_id into scartoId;

    	if scartoId is null then
        	--scarto
 		    strMessaggio:=' Inserimento non riuscito.';
            insert into migr_relaz_docquo_spesa_iva_scarto
            ( migr_relazdocquo_id,
              motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrRelDoc.migr_relazdocquo_id,
         	         strMessaggio,
	                 clock_timestamp(),
     	             enteProprietarioId);

            delete from siac_r_subdoc_iva where doc_r_id=docRId;
            continue;
        end if;

       strMessaggio:='Update migr_relaz_docquo_spesa_iva, set fl_elab per migr_relazdocquo_id ' ||migrRelDoc.migr_relazdocquo_id||'.';
		update migr_relaz_docquo_spesa_iva
        set fl_elab='S'
        where migr_relazdocquo_id=migrRelDoc.migr_relazdocquo_id
        and fl_elab='N';

        numeroRecordInseriti:=numeroRecordInseriti+1;

    end loop;

	RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||'Inserite '||numeroRecordInseriti||' relazioni.';
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
