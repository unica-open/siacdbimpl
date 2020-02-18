/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_docquo_entrata(enteProprietarioId integer,
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
 migrAttoAmm record;

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 codBolloId integer:=null;
 subDocId      integer:=null;
 scartoId   integer:=null;
 attoAmmId  integer:=null;
 movGestId  integer:=null;
 movGestTsId integer:=null;
 ordTsId       integer:=null;

 bilancioId integer:=null;
 bilancioPrecId integer:=null;
 movGestTipoId integer:=null;
 movGestTsTipoId_T integer:=null;
 movGestTsTipoId_S integer:=null;
 ordTipoId         integer:=null;

 SUBDOC_TIPO         CONSTANT  varchar :='SE';
 ORD_TIPO            CONSTANT  varchar :='I';

 SPR                   CONSTANT varchar:='SPR||';
 NVL_STR               CONSTANT VARCHAR:='';

 MOVGEST_IMPEGNO		  CONSTANT varchar:='A';  -- codice da ricercare  nella tabella siac_d_movgest_tipo
 MOVGEST_TS_IMPEGNI    CONSTANT varchar:='T';  -- codice da ricercare  nella tabella siac_d_movgest_ts_tipo
 MOVGEST_TS_SUBIMP     CONSTANT varchar:='S';  -- codice da ricercare  nella tabella siac_d_movgest_ts_tipo

 FLAG_ORD_SING_ATTR    CONSTANT  varchar :='flagOrdinativoSingolo';
 FLAG_RIL_IVA_ATTR     CONSTANT  varchar :='flagRilevanteIVA';
 FLAG_AVVISO_ATTR      CONSTANT  varchar :='flagAvviso';
 FLAG_ESPROPRIO_ATTR   CONSTANT  varchar :='flagEsproprio';
 FLAG_ORD_MANUALE_ATTR CONSTANT  varchar :='flagOrdinativoManuale';
 NOTE_ATTR             CONSTANT  varchar :='Note';
 TIPO_AVVISO_CL     CONSTANT  varchar :='TIPO_AVVISO';


-- ANNO_IMP_FITTIZIO CONSTANT    integer :=9999;se la quota è pagata non viene legata ad alcun impegno.
-- NUMERO_IMP_FITTIZIO CONSTANT  integer :=999999;se la quota è pagata non viene legata ad alcun impegno.
 ANNO_LIQ_FITTIZIO CONSTANT    integer :=9999;
 NUMERO_LIQ_FITTIZIO CONSTANT  integer :=999999;
 ANNO_ORD_FITTIZIO CONSTANT    integer :=9999;
 NUMERO_ORD_FITTIZIO CONSTANT  integer :=999999;

 commissioneTipoId       integer:=null;
 subDocTipoId            integer:=null;



 flagOrdSingoloAttrId    integer:=null;
 flagRilIvaAttrId        integer:=null;
 flagAvvisoAttrId        integer:=null;
 flagEsproprioAttrId    integer:=null;
 flagOrdManualeAttrId    integer:=null;
 noteAttrId              integer:=null;
 tipoAvvisoClassTipoId integer:=null;

-- movGestTsFitId integer :=null;--10.11.2015 Dani, se la quota e pagata non viene legata ad alcun accertamento.
 ordTsFitId     integer :=null;
 docIds record; -- cursore aggiornamento contatore siac_t_subdoc_num

BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione quote documenti di entrata da id ['||idMin||'] a id ['||idMin||']';

    strMessaggio:='Lettura quote documenti entrata da migrare.';
	begin
		select distinct 1 into strict countMigrDoc from migr_docquo_entrata ms
		where ms.ente_proprietario_id=enteProprietarioId
        and   ms.fl_elab='N'
		and   ms.migr_docquo_entrata_id >= idMin and ms.migr_docquo_entrata_id <=idMax
        and   exists (select 1 from migr_doc_entrata md
                      where md.docentrata_id=ms.docentrata_id
                        and md.ente_proprietario_id=ms.ente_proprietario_id
                        and md.fl_elab='S') ;
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;

    -- lettura id bilancio
	strMessaggio:='Lettura id bilancio per anno '||annoBilancio||'.';
    select bilancio.idbilancio, bilancio.messaggiorisultato into bilancioId,messaggioRisultato
	from fnc_get_bilancio(enteProprietarioId,annoBilancio) bilancio;
	if (bilancioid=-1) then
		messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
		numerorecordinseriti:=-13;
		return;
	end if;

    -- lettura id bilancio precedente
	strMessaggio:='Lettura id bilancio per anno '||annoBilancio::INTEGER-1||'.';
    select bilancio.idbilancio, bilancio.messaggiorisultato into bilancioPrecId,messaggioRisultato
	from fnc_get_bilancio(enteProprietarioId,(annoBilancio::INTEGER-1)::varchar) bilancio;
	if (bilancioid=-1) then
		messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
		numerorecordinseriti:=-13;
		return;
	end if;

    begin


        strMessaggio:='Lettura tipo subdocumento  '||SUBDOC_TIPO||'.';

        select tipo.subdoc_tipo_id into strict subDocTipoId
        from siac_d_subdoc_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.subdoc_tipo_code=SUBDOC_TIPO
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_IMPEGNO||'.';
	    select d.movgest_tipo_id into strict movGestTipoId
    	from siac_d_movgest_tipo d
	    where d.ente_proprietario_id=enteproprietarioid
    	and d.movgest_tipo_code = MOVGEST_IMPEGNO
	    and d.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                or d.validita_fine is null);


        strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_TS_IMPEGNI||'.';
    	select d.movgest_ts_tipo_id into strict movGestTsTipoId_T
        from siac_d_movgest_ts_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.movgest_ts_tipo_code = MOVGEST_TS_IMPEGNI
		and d.data_cancellazione is null and
              	date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                    or d.validita_fine is null);

    	strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_TS_SUBIMP||'.';
    	select d.movgest_ts_tipo_id into strict movGestTsTipoId_S
        from siac_d_movgest_ts_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.movgest_ts_tipo_code = MOVGEST_TS_SUBIMP
		and d.data_cancellazione is null and
              	date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                    or d.validita_fine is null);

        strMessaggio:='Lettura tipo ordinativo per codice '||ORD_TIPO||'.';
    	select d.ord_tipo_id into strict ordTipoId
        from siac_d_ordinativo_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.ord_tipo_code = ORD_TIPO
		and d.data_cancellazione is null and
              	date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                    or d.validita_fine is null);



        strMessaggio:='Lettura identificativo attributo '||FLAG_ORD_SING_ATTR||'.';

        select attr.attr_id into strict flagOrdSingoloAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_ORD_SING_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||FLAG_RIL_IVA_ATTR||'.';

        select attr.attr_id into strict flagRilIvaAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_RIL_IVA_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);



        strMessaggio:='Lettura identificativo attributo '||FLAG_AVVISO_ATTR||'.';

        select attr.attr_id into strict flagAvvisoAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_AVVISO_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||FLAG_ESPROPRIO_ATTR||'.';

        select attr.attr_id into strict flagEsproprioAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_ESPROPRIO_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);



        strMessaggio:='Lettura identificativo attributo '||FLAG_ORD_MANUALE_ATTR||'.';

        select attr.attr_id into strict flagOrdManualeAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_ORD_MANUALE_ATTR
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


        strMessaggio:='Lettura identificativo classificatore '||TIPO_AVVISO_CL||'.';

        select tipo.classif_tipo_id into strict tipoAvvisoClassTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=TIPO_AVVISO_CL
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);
	--10.11.2015 Dani, se la quota e pagata non viene legata ad alcun accertamento.
/*		strMessaggio:='Lettura identificativo movimento [siac_t_movgest_ts] fittizio.';
        select  dett.movgest_ts_id into strict movGestTsFitId
        from siac_t_movgest mov , siac_t_movgest_ts dett
        where mov.ente_proprietario_id=enteProprietarioId
		  and mov.bil_id=bilancioPrecId
		  and mov.movgest_tipo_id=movGestTipoId
          and mov.movgest_anno = ANNO_IMP_FITTIZIO
          and mov.movgest_numero= NUMERO_IMP_FITTIZIO
          and dett.movgest_id=mov.movgest_id
	      and dett.movgest_ts_tipo_id=movGestTsTipoId_T;*/

		strMessaggio:='Lettura identificativo ordinativo [siac_t_ordinativo_ts] fittizio.';
        select  dett.ord_ts_id into strict ordTsFitId
        from siac_t_ordinativo ord , siac_t_ordinativo_ts dett
        where ord.ente_proprietario_id=enteProprietarioId
		  and ord.bil_id=bilancioPrecId
		  and ord.ord_tipo_id=ordTipoId
          and ord.ord_anno = ANNO_ORD_FITTIZIO
          and ord.ord_numero= NUMERO_ORD_FITTIZIO
          and dett.ord_id=ord.ord_id;


        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 750);
    end;


    strMessaggio:='Lettura quote documenti entrata da migrare.Inizio ciclo.';
    for migrDocumento IN
    (select ms.*,sogg.soggetto_id, doc.doc_id,doc.doc_tipo_id,
            (case coalesce(ms.flag_manuale,'X')
                     when 'S' then 'S'
                     else 'N' end) flag_ord_manuale,
            (case ms.numero_riscossione when 0 then 'N' else 'S' end) flag_pagato
     from migr_docquo_entrata ms
         inner join migr_doc_entrata md on (md.docentrata_id=ms.docentrata_id
                                      and md.ente_proprietario_id=ms.ente_proprietario_id
                                      and md.fl_elab='S')
         inner join siac_r_migr_doc_entrata_t_doc migrRelDocEntrata on (migrRelDocEntrata.migr_doc_entrata_id=md.migr_docentrata_id)
         inner join siac_t_doc doc on (doc.doc_id=migrRelDocEntrata.doc_id
                                    and doc.ente_proprietario_id=ms.ente_proprietario_id
                                    and doc.data_cancellazione is null
                                    and date_trunc('day',dataelaborazione)>=date_trunc('day',doc.validita_inizio)
                                    and (date_trunc('day',dataelaborazione)<=date_trunc('day',doc.validita_fine)
                      						     or doc.validita_fine is null))
         inner join siac_r_doc_sog sogg on ( sogg.doc_id=doc.doc_id
		                                and sogg.ente_proprietario_id=doc.ente_proprietario_id
	                                    and sogg.data_cancellazione is null
    	                                and date_trunc('day',dataelaborazione)>=date_trunc('day',sogg.validita_inizio)
        	                            and (date_trunc('day',dataelaborazione)<=date_trunc('day',sogg.validita_fine)
                      						     or sogg.validita_fine is null))
	 where ms.ente_proprietario_id=enteProprietarioId
     and   ms.fl_elab='N'
     and   ms.migr_docquo_entrata_id >= idMin and ms.migr_docquo_entrata_id <=idMax
     order by ms.migr_docquo_entrata_id
    )
    loop

	    commissioneTipoId:=null;
		subDocId:=null;
        scartoId:=null;
        attoAmmId:=null;
        movGestId:=null;
		movGestTsId:=null;
        ordTsId:=null;

        -- se quota incassata accertamento-ordinativo associati  sono  del bilancio precedente e fittizi
        if migrDocumento.flag_pagato='S' then
--10.11.2015 Dani, se la quota ? pagata non viene legata ad alcun accertamento.
--        	movGestTsId:=movGestTsFitId;
            ordTsId:=ordTsFitId;
        end if;

        -- tipo
		-- anno
		-- numero
		-- codice_soggetto
		-- frazione
        -- descrizione
        -- importo
        -- numero_iva
        -- data_scadenza
        -- flag_rilevante_iva

        -- flag_ord_singolo
        -- flag_avviso
		-- tipo_avviso
        -- flag_esproprio
        -- flag_manuale
		-- note
		-- utente_creazione
		-- utente_modifica


		-- anno_provvedimento
		-- numero_provvedimento
		-- tipo_provvedimento
		-- sac_provvedimento
		-- oggetto_provvedimento
		-- note_provvedimento
		-- stato_provvedimento


        -- anno_esercizio
		-- anno_accertamento
		-- numero_accertamento
		-- numero_subaccertamento
		-- numero_riscossione

		-- elenco_doc_id
		-- anno_elenco
		-- numero_elenco

		-- da posizionare
		-- codice_soggetto_inc




		--ATTO AMMINISTRATIVO  ###############
        -- anno_provvedimento
		-- numero_provvedimento
		-- tipo_provvedimento
		-- sac_provvedimento
		-- oggetto_provvedimento
		-- note_provvedimento
		-- stato_provvedimento
        strMessaggio:='Lettura provvedimento per inserimento siac_t_subdoc per migr_docquo_entrata_id='
                      ||migrDocumento.migr_docquo_entrata_id||'.';
        if coalesce(migrDocumento.numero_provvedimento,0)!=0
           or migrDocumento.tipo_provvedimento=SPR
           then

      	     select * into migrAttoAmm
             from fnc_migr_attoamm (migrDocumento.anno_provvedimento,migrDocumento.numero_provvedimento,
                                    migrDocumento.tipo_provvedimento,migrDocumento.sac_provvedimento,
                                    migrDocumento.oggetto_provvedimento,migrDocumento.note_provvedimento,
                                    migrDocumento.stato_provvedimento,
                                    enteProprietarioId,loginOperazione,dataElaborazione, dataInizioVal);
             if migrAttoAmm.codiceRisultato=-1 then
           	  strMessaggio:=strMessaggio||migrAttoAmm.messaggioRisultato;
             ELSE
              attoAmmId := migrAttoAmm.id;
             end if;
       		 if coalesce(attoAmmId,0) = 0 then
 				strMessaggio := strMessaggio||'Atto amm scarto.';
	            INSERT INTO migr_docquo_entrata_scarto
			    (migr_docquo_entrata_id,
	    	     motivo_scarto,
			     data_creazione,
			     ente_proprietario_id
			    )values(migrDocumento.migr_docquo_entrata_id,
	      	            strMessaggio,
        	            clock_timestamp(),
                        enteProprietarioId);
--	            (select migrDocumento.migr_docquo_entrata_id,
--	      	            strMessaggio,
--        	            clock_timestamp(),
--                        enteProprietarioId
--                 where not exists
--                       (select 1 from migr_docquo_entrata_scarto s
--                        where s.migr_docquo_entrata_id=migrDocumento.migr_docquo_entrata_id
--                        and   s.ente_proprietario_id=enteProprietarioId));
	            continue;
    	    end if;
        end if;

		-- anno_esercizio
		-- anno_accertamento
		-- numero_accertamento
		-- numero_subaccertamento

        if migrDocumento.flag_pagato='N' and migrDocumento.numero_accertamento!=0 then
        	strMessaggio:='Lettura accertamento [siac_t_movgest] per inserimento siac_t_subdoc per migr_docquo_entrata_id='
                      ||migrDocumento.migr_docquo_entrata_id||'.';
			select mov.movgest_id into movGestId
            from siac_t_movgest mov
            where mov.ente_proprietario_id=enteProprietarioId
			  and mov.bil_id=bilancioId
 			  and mov.movgest_tipo_id=movGestTipoId
              and mov.movgest_anno = migrDocumento.anno_accertamento::INTEGER
              and mov.movgest_numero= migrDocumento.numero_accertamento
              and mov.data_cancellazione is null
              and date_trunc('day',dataelaborazione)>=date_trunc('day',mov.validita_inizio) and
                  (date_trunc('day',dataelaborazione)<=date_trunc('day',mov.validita_fine)
                     or mov.validita_fine is null);

            if coalesce(movGestId,0)!=0 then
	            if migrDocumento.numero_subaccertamento=0 then
                	-- la quota doc ? legata ad un movimento di tipo ACCERTAMENTO da ricercare nella siac_t_movgest_ts
		            strMessaggio:='Lettura accertamento [siac_t_movgest_ts] per inserimento siac_t_subdoc per migr_docquo_entrata_id='
                      ||migrDocumento.migr_docquo_entrata_id||'.';
    		        select coalesce(dett.movgest_ts_id,0) into movGestTsId
        		    from siac_t_movgest_ts dett
            		where dett.ente_proprietario_id=enteProprietarioId
                    and dett.movgest_id=movGestId
	            	and dett.movgest_ts_tipo_id=movGestTsTipoId_T
                    and dett.data_cancellazione is null
                    and date_trunc('day',dataelaborazione)>=date_trunc('day',dett.validita_inizio)
                    and (date_trunc('day',dataelaborazione)<=date_trunc('day',dett.validita_fine)
                           or dett.validita_fine is null);

    	        else
             	   -- la quota doc ? legata ad un movimento di tipo ACCERTAMENTO da ricercare nella siac_t_movgest_ts
		            strMessaggio:='Lettura subimpegno [siac_t_movgest_ts] per inserimento siac_t_subdoc per migr_docquo_entrata_id='
                      ||migrDocumento.migr_docquo_entrata_id||'.';
	               select coalesce(dett.movgest_ts_id,0) into movGestTsId
	               from siac_t_movgest_ts dett
		           where dett.ente_proprietario_id=enteProprietarioId
                     and dett.movgest_id=movGestId
		             and dett.movgest_ts_tipo_id=movGestTsTipoId_S
		  			 and dett.movgest_ts_code=migrDocumento.numero_subaccertamento::VARCHAR
                     and dett.data_cancellazione is null
                     and date_trunc('day',dataelaborazione)>=date_trunc('day',dett.validita_inizio)
                     and (date_trunc('day',dataelaborazione)<=date_trunc('day',dett.validita_fine)
                            or dett.validita_fine is null);
        	    end if;

                if coalesce(movGestTsId,0) = 0 then
	                strMessaggio := strMessaggio||'Movimento non valido, presente o migrato.';
					INSERT INTO migr_docquo_entrata_scarto
			   		(migr_docquo_entrata_id,
	    	   		 motivo_scarto,
			  		 data_creazione,
				     ente_proprietario_id
			         )values(migrDocumento.migr_docquo_entrata_id,
	      	        	    strMessaggio,
        	            	clock_timestamp(),
	                        enteProprietarioId);
--	            	(select migrDocumento.migr_docquo_entrata_id,
--	      	        	    strMessaggio,
--        	            	clock_timestamp(),
--	                        enteProprietarioId
--    	             where not exists
--        	               (select 1 from migr_docquo_entrata_scarto s
--            	            where s.migr_docquo_entrata_id=migrDocumento.migr_docquo_entrata_id
--                	        and   s.ente_proprietario_id=enteProprietarioId));
                     continue;
                end if;
			else
            	strMessaggio := strMessaggio||'Movimento non valido, presente o migrato.';
				INSERT INTO migr_docquo_entrata_scarto
			   	(migr_docquo_entrata_id,
	    	   	 motivo_scarto,
			  	 data_creazione,
				 ente_proprietario_id
			     )values(migrDocumento.migr_docquo_entrata_id,
	      	       	     strMessaggio,
        	             clock_timestamp(),
	                     enteProprietarioId);
--	             (select migrDocumento.migr_docquo_entrata_id,
--	      	       	     strMessaggio,
  --      	             clock_timestamp(),
--	                     enteProprietarioId
--   	              where not exists
--        	            (select 1 from migr_docquo_entrata_scarto s
--            	         where s.migr_docquo_entrata_id=migrDocumento.migr_docquo_entrata_id
--                         and   s.ente_proprietario_id=enteProprietarioId));
                  continue;
            end if;

        end if;


		-- siac_t_subdoc
	    strMessaggio:='Inserimento siac_t_subdoc per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
        INSERT INTO siac_t_subdoc
		(subdoc_numero,
         subdoc_desc,
         subdoc_importo,
         subdoc_nreg_iva,
         subdoc_data_scadenza,
         subdoc_convalida_manuale,
         subdoc_importo_da_dedurre,
  --       contotes_id,
  --       dist_id,
--         comm_tipo_id,
         doc_id,
         subdoc_tipo_id,
  --       notetes_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
         login_operazione,
         login_creazione,
         login_modifica
		)
        values
        (migrDocumento.frazione,
         migrDocumento.descrizione,
         abs(migrDocumento.importo),
         migrDocumento.numero_iva,
		 to_timestamp(migrDocumento.data_scadenza,'yyyy-MM-dd'),
         migrDocumento.flag_manuale,
         0,
         migrDocumento.doc_id,
         subDocTipoId,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione,
         migrDocumento.utente_creazione,
         migrDocumento.utente_modifica
        )
        returning subdoc_id into subDocId;


  	   if subDocId is null then
       	strMessaggio:=strMessaggio||' Scarto per inserimento non riuscito.';
	    INSERT INTO migr_docquo_entrata_scarto
		(migr_docquo_entrata_id,
	   	 motivo_scarto,
		 data_creazione,
	     ente_proprietario_id
	     )values(migrDocumento.migr_docquo_entrata_id,
	        	 strMessaggio,
        	     clock_timestamp(),
	             enteProprietarioId);
--	   	 (select migrDocumento.migr_docquo_entrata_id,
--	        	 strMessaggio,
--        	     clock_timestamp(),
--	             enteProprietarioId
--           where not exists
--		         (select 1 from migr_docquo_entrata_scarto s
--                  where s.migr_docquo_entrata_id=migrDocumento.migr_docquo_entrata_id
--                  and   s.ente_proprietario_id=enteProprietarioId));

         continue;

       end if;

	   scartoId:=null;
       -- siac_r_subdoc_atto_amm
       if coalesce(attoAmmId,0)!=0 then
        strMessaggio:='Inserimento siac_r_subdoc_atto_amm per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
       	insert into siac_r_subdoc_atto_amm
        (subdoc_id,
         attoamm_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
	     login_operazione )
        values
        (subDocId,
         attoAmmId,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione
        )
        returning subdoc_atto_amm_id into scartoId;

        if scartoId is null then
			strMessaggio:=strMessaggio||' Scarto per inserimento attoAmm.';
	       	INSERT INTO migr_docquo_entrata_scarto
			(migr_docquo_entrata_id,
	         motivo_scarto,
			 data_creazione,
		     ente_proprietario_id
			)
            values
            (migrDocumento.migr_docquo_entrata_id,
             strMessaggio,
             clock_timestamp(),
             loginOperazione);

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc inserito.';
             delete from siac_t_subdoc       where subdoc_id=subDocId;

            continue;
        end if;
       end if;

       scartoId:=null;
       -- siac_r_subdoc_movgest_ts
       if coalesce(movGestTsId,0)!=0 then
        strMessaggio:='Inserimento siac_r_subdoc_movgest_ts per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
       	insert into siac_r_subdoc_movgest_ts
        (subdoc_id,
         movgest_ts_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
         login_operazione )
        values
        (subDocId,
         movGestTsId,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione
         )
         returning subdoc_movgest_ts_id into scartoId;

         if scartoId is null then
			strMessaggio:=strMessaggio||' Scarto per inserimento movgest_ts.';
			INSERT INTO migr_docquo_entrata_scarto
   		    (migr_docquo_entrata_id,
	    	 motivo_scarto,
			 data_creazione,
			 ente_proprietario_id
			 )values(migrDocumento.migr_docquo_entrata_id,
	      	    	 strMessaggio,
        	         clock_timestamp(),
	                 enteProprietarioId);
--	         (select migrDocumento.migr_docquo_entrata_id,
--	      	    	 strMessaggio,
--        	         clock_timestamp(),
--	                 enteProprietarioId
--              where not exists
--        	        (select 1 from migr_docquo_entrata_scarto s
--                     where s.migr_docquo_entrata_id=migrDocumento.migr_docquo_entrata_id
--                    and   s.ente_proprietario_id=enteProprietarioId));

             strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inserito.';

			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_t_subdoc          where subdoc_id=subDocId;
             continue;
        end if;

       end if;


       scartoId:=null;
       -- ordinativo sara quello fittizio
       -- siac_r_subdoc_ordinativo_ts
       if coalesce(ordTsId,0)!=0 then
       		insert into siac_r_subdoc_ordinativo_ts
            (subdoc_id,
	         ord_ts_id,
             validita_inizio,
             ente_proprietario_id,
             data_creazione,
	         login_operazione )
           values
           (subDocId,
            ordTsId,
            dataInizioVal::timestamp,
            enteProprietarioId,
            clock_timestamp(),
            loginOperazione
           )
           returning subdoc_liq_id into scartoId;

       	   if scartoId is null then

       	    strMessaggio:=strMessaggio||' Scarto per inserimento ordinativo.';
			INSERT INTO migr_docquo_entrata_scarto
			(migr_docquo_entrata_id,
	    	 motivo_scarto,
			 data_creazione,
			 ente_proprietario_id
			)values(migrDocumento.migr_docquo_entrata_id,
	      	   	    strMessaggio,
        	       	clock_timestamp(),
	                enteProprietarioId);
--	        (select migrDocumento.migr_docquo_entrata_id,
--	      	   	    strMessaggio,
--        	       	clock_timestamp(),
--	                enteProprietarioId
--    	     where not exists
--        	       (select 1 from migr_docquo_entrata_scarto s
--                    where s.migr_docquo_entrata_id=migrDocumento.migr_docquo_entrata_id
--                    and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inserito.';

			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_r_subdoc_movgest_ts where subdoc_id=subDocId;
             delete from siac_t_subdoc          where subdoc_id=subDocId;
             continue;
          end if;
       end if;






       -- siac_r_doc_attr
       -- flag_rilevante_iva
        scartoId:=null;

        strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_RIL_IVA_ATTR
                       ||' per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
        INSERT INTO siac_r_subdoc_attr
	    (subdoc_id,
	     attr_id,
         boolean,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
	     login_operazione
        )
        values
        (subDocId,
         flagRilIvaAttrId,
         migrDocumento.flag_rilevante_iva,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione)
         returning subdoc_attr_id into scartoId;




         if scartoId is not null then
          -- -- flag_ord_singolo
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_ORD_SING_ATTR
                       ||' per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagOrdSingoloAttrId,
           migrDocumento.flag_ord_singolo,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;



         if scartoId is not null then
          -- flag_avviso
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_AVVISO_ATTR
                       ||' per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagAvvisoAttrId,
           migrDocumento.flag_avviso,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- flag_esproprio
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_ESPROPRIO_ATTR
                       ||' per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagEsproprioAttrId,
           migrDocumento.flag_esproprio,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- flag_ord_manuale
          scartoId:=null;


          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_ORD_MANUALE_ATTR
                       ||' per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagOrdManualeAttrId,
           migrDocumento.flag_ord_manuale,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- note
          scartoId:=null;


          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||NOTE_ATTR
                       ||' per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           noteAttrId,
           migrDocumento.note,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;


         -- siac_r_doc_class
	     if   scartoId is not null
          and coalesce(migrDocumento.tipo_avviso,NVL_STR)!=NVL_STR then
          -- tipo_avviso
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_class per '||TIPO_AVVISO_CL
                       ||'='||migrDocumento.tipo_avviso
                       ||' per migr_docquo_entrata_id='||migrDocumento.migr_docquo_entrata_id||'.';
          INSERT INTO siac_r_subdoc_class
          (subdoc_id,
           classif_id,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
           )
          (select subDocId,
                  class.classif_id,
                  dataInizioVal::timestamp,
                  enteProprietarioId,
                  clock_timestamp(),
                  loginOperazione
           from siac_t_class class
           where class.classif_tipo_id=tipoAvvisoClassTipoId
           and   class.classif_code=migrDocumento.tipo_avviso
           and   class.data_cancellazione is null
           and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
           and  (date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine)
			      or class.validita_fine is null))
          returning subdoc_classif_id into scartoId;

         end if;

         if scartoId is null then
           strMessaggio:=strMessaggio||'Controllare esistenza attributo/classificatore.';

           INSERT INTO migr_docquo_entrata_scarto
		   (migr_docquo_entrata_id,
	        motivo_scarto,
		    data_creazione,
		    ente_proprietario_id
		    )values(migrDocumento.migr_docquo_entrata_id,
	                strMessaggio,
                    clock_timestamp(),
                    loginOperazione);
--            (select migrDocumento.migr_docquo_entrata_id,
--	                strMessaggio,
--                    clock_timestamp(),
--                    loginOperazione
--			 where not exists
--        	       (select 1 from migr_docquo_entrata_scarto s
--                    where s.migr_docquo_entrata_id=migrDocumento.migr_docquo_entrata_id
--                    and   s.ente_proprietario_id=enteProprietarioId));

            strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inseriti.';
            delete from siac_t_subdoc          where subdoc_id=subDocId;
			delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			delete from siac_r_subdoc_movgest_ts where subdoc_id=subDocId;
            delete from siac_r_subdoc_ordinativo_ts where subdoc_id=subDocId;
            delete from siac_r_subdoc_attr     where subdoc_id=subDocId;
            delete from siac_r_subdoc_class    where subdoc_id=subDocId;

            continue;
	    end if;


	   	strMessaggio:='Inserimento siac_r_migr_docquo_spesa_t_subdoc per migr_docquo_entrata_id= '
                               ||migrDocumento.migr_docquo_entrata_id||'.';
        insert into siac_r_migr_docquo_entrata_t_subdoc
        (migr_docquo_entrata_id,subdoc_id,ente_proprietario_id,data_creazione)
        values
        (migrDocumento.migr_docquo_entrata_id,subDocId,enteProprietarioId,clock_timestamp());

        numeroRecordInseriti:=numeroRecordInseriti+1;

        -- valorizzare fl_elab = 'S'
        update migr_docquo_entrata set fl_elab='S'
        where ente_proprietario_id=enteProprietarioId
        and   migr_docquo_entrata_id = migrDocumento.migr_docquo_entrata_id
        and   fl_elab='N';

    end loop;

    -- 09.02.2016 Aggiornamento del contatore siac_t_subdoc_num
    strMessaggio:='Aggiornamento contatore siac_t_subdoc_num.';
    for docIds in
      (
      select sub.doc_id, max(sub.subdoc_numero) as maxSubDocNum
      from siac_T_subdoc sub, siac_r_migr_docquo_entrata_t_subdoc rMigr
      where sub.subdoc_id = rMigr.subdoc_id
      and rMigr.migr_docquo_entrata_id  >= idMin and rMigr.migr_docquo_entrata_id <=idMax
      and sub.ente_proprietario_id = enteProprietarioId
      group by doc_id
      )loop

		UPDATE siac_t_subdoc_num
        	SET subdoc_numero = docIds.maxSubDocNum
            , login_operazione =  loginOperazione
            , data_modifica = clock_timestamp()
            WHERE doc_id = docIds.doc_id and ente_proprietario_id = enteProprietarioId;

        INSERT INTO siac_t_subdoc_num  (doc_id, subdoc_numero,validita_inizio,ente_proprietario_id,login_operazione)
        Select docIds.doc_id, docIds.maxSubDocNum, clock_timestamp(),enteProprietarioId, loginOperazione
        where not exists (select 1 from siac_t_subdoc_num where doc_id = docIds.doc_id and ente_proprietario_id = enteProprietarioId);

      end loop;


    RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||'. Inserite '||numeroRecordInseriti||' quote documenti di entrata.';
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