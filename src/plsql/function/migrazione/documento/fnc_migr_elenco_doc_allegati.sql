/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- 01.06.2015 Sofia DUBBI
--- come numerare gli elenchi ?
--- creare un elenco per provvedimento o per provvedimento/soggetto ?

CREATE OR REPLACE FUNCTION fnc_migr_elenco_doc_allegati
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  idMin integer,
  idMax integer,
  out numeroRecordInseriti integer,
  out messaggioRisultato varchar )
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigrEleDocAll integer := 0;

 migrElencoDocAll record;
 leggiAttoAmm record;
 tipoAtto varchar(500):=null;
 tipoAttoKey varchar(500):=null;
 sacCdr varchar(500):=null;
 sacCdrKey varchar(500):=null;

 sacCdrId integer:=null;
 attoAmmId integer:=null;
 attoAmmTipoId integer:=null;
 elDocId integer:=null;
 attoAllId integer:=null;
 scartoId integer:=null;

 cdrClassifTipoId integer:=null;
 subDocSpesaTipoId integer:=null;
 subDocEntrataTipoId integer:=null;
 NVL_STR               CONSTANT VARCHAR:='';
 
 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 SUBDOC_SPESA_TIPO           CONSTANT  varchar :='SS';
 SUBDOC_ENTRATA_TIPO         CONSTANT  varchar :='SE';

 CDR_SAC     CONSTANT  varchar :='CDR';
 SEPARATORE     CONSTANT  varchar :='||';

 bilancioid integer:=0;
 eldocnumero integer:=0; -- contatore siac_t_elenco_doc_num
 maxeldocnumero integer:=0; -- aggiorna contatore siac_t_elenco_doc_num
 v_count integer := 0;

BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione elenco documenti allegati da id ['||idMin||'] a id ['||idMax||']';

    strMessaggio:='Lettura elenco documenti allegati da migrare.';
	begin
		select distinct 1 into strict countMigrEleDocAll
        from migr_elenco_doc_allegati ms
		where ms.ente_proprietario_id=enteProprietarioId
        and   ms.fl_elab='N'
        and ms.migr_elenco_doc_id  >= idMin and ms.migr_elenco_doc_id <= idMax;

	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;


	begin

		-- dani 28.09.15 per contatore siac_t_elenco_doc_num
        strMessaggio:='Lettura id bilancio.';
        select b.bil_id into strict bilancioid
        from siac_t_bil b
        join siac_t_periodo p on (b.periodo_id=p.periodo_id
            and b.ente_proprietario_id = p.ente_proprietario_id
            and p.anno = annobilancio)
        where b.ente_proprietario_id = enteproprietarioid
        and b.validita_fine is null;

        select eldoc_numero into eldocnumero
        from siac_t_elenco_doc_num
        where ente_proprietario_id = enteproprietarioid and bil_id = bilancioid
        and data_cancellazione is null
    	and date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio)
    	and (date_trunc('day',dataElaborazione)<date_trunc('day',validita_fine) or validita_fine is null);

        strMessaggio:='Lettura tipo subdocumento  '||SUBDOC_SPESA_TIPO||'.';
		-- subDocSpesaTipoId
        select tipo.subdoc_tipo_id into strict subDocSpesaTipoId
        from siac_d_subdoc_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.subdoc_tipo_code=SUBDOC_SPESA_TIPO
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura tipo subdocumento  '||SUBDOC_ENTRATA_TIPO||'.';
		 -- subDocEntrataTipoId
        select tipo.subdoc_tipo_id into strict subDocEntrataTipoId
        from siac_d_subdoc_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.subdoc_tipo_code=SUBDOC_ENTRATA_TIPO
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);


        -- cdrClassifTipoId
        strMessaggio:='Lettura tipo sac   '||CDR_SAC||'.';
        select tipo.classif_tipo_id into strict cdrClassifTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=CDR_SAC
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;

    if eldocnumero is null then eldocnumero := 0; end if;

    strMessaggio:='Lettura elenco documenti allegati da migrare.Inizio ciclo.';
    for migrElencoDocAll IN
    (select ms.*
     from migr_elenco_doc_allegati ms
     where ms.ente_proprietario_id=enteProprietarioId
     and   ms.fl_elab='N'
     and ms.migr_elenco_doc_id  >= idMin and ms.migr_elenco_doc_id <= idMax
     order by ms.tipo_provvedimento,
              ms.anno_provvedimento::integer,ms.numero_provvedimento::integer,
              ms.sac_provvedimento,
              ms.anno_elenco::integer,ms.numero_elenco
    )
    loop

    	tipoAtto:=null;
        tipoAttoKey:=null;
        sacCdr:=null;
        sacCdrKey:=null;
        sacCdrId:=null;
		attoAmmId:=null;
        attoAmmTipoId:=null;
		elDocId:=null;
		attoAllId:=null;
        scartoId:=null;

        strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
                       || migrElencoDocAll.migr_elenco_doc_id||'.Lettura Atto Amministrativo tipo='
                       || migrElencoDocAll.tipo_provvedimento||' anno='
                       || migrElencoDocAll.anno_provvedimento||' numero='
                       || migrElencoDocAll.numero_provvedimento||' sac='
                       || quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
                       || migrElencoDocAll.anno_elenco||' numero_elenco='
                       || migrElencoDocAll.numero_elenco||'.';


/*---------------------------------------------------------------- 14.10.2015 fnc_migr_leggi_attoamm -----------------------------------------------------------------------
    	-- lettura il provvedimento
        tipoAtto      := split_part(migrElencoDocAll.tipo_provvedimento,SEPARATORE,1);
        tipoAttoKey   := split_part(migrElencoDocAll.tipo_provvedimento,SEPARATORE,2);
        if coalesce(migrElencoDocAll.sac_provvedimento,NVL_STR) != NVL_STR then
        	sacCdr   :=split_part(migrElencoDocAll.sac_provvedimento,SEPARATORE,1);
            sacCdrKey:=split_part(migrElencoDocAll.sac_provvedimento,SEPARATORE,2);

            if coalesce(sacCdrKey,NVL_STR)='K' then
            	strMessaggio:=strMessaggio||' Lettura SacId per SacCdr='||SacCdr||'.';
            	select coalesce(class.classif_id,0) into sacCdrId
                from siac_t_class class
                where class.classif_code=sacCdr
                and   class.ente_proprietario_id=enteProprietarioId
                and   class.classif_tipo_id=cdrClassifTipoId
                and   class.data_cancellazione is null
                and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
                and   (date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine)
                         or class.validita_fine is null);

                if sacCdrId is null  then
                	--- scarto
                    insert into migr_elenco_doc_scarto
					(
					  migr_elenco_doc_id,
					  motivo_scarto,
					  data_creazione,
					  ente_proprietario_id
                    )
                    (select migrElencoDocAll.migr_elenco_doc_id,
	                        strMessaggio,
		        			clock_timestamp(),
	  					    enteProprietarioId
                     where not exists
                           (select 1 from  migr_elenco_doc_scarto s
                            where s.migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id
                            and   s.ente_proprietario_id=enteProprietarioId)
                    );
                    continue;
                end if;
            end if;

        end if;

        strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
                       || migrElencoDocAll.migr_elenco_doc_id||'.Lettura Atto Amministrativo tipo='
                       || migrElencoDocAll.tipo_provvedimento||' anno='
                       || migrElencoDocAll.anno_provvedimento||' numero='
                       || migrElencoDocAll.numero_provvedimento||' sac='
                       || quote_nullable( migrElencoDocAll.sac_provvedimento)||' anno_elenco='
                       || migrElencoDocAll.anno_elenco||' numero_elenco='
                       || migrElencoDocAll.numero_elenco||'.';

        if  coalesce(sacCdrId,0)!=0 and  coalesce(sacCdrKey,NVL_STR)='K' THEN

       		select coalesce(attoAmm.attoamm_id,0),coalesce( attoAmm.attoamm_tipo_id ,0)
                   into attoAmmId,attoAmmTipoId
            from siac_t_atto_amm attoAmm, siac_d_atto_amm_tipo tipoAttoAmm,siac_r_atto_amm_class attoAmmCdrRel
            where attoAmm.ente_proprietario_id=enteProprietarioId
            and   attoAmm.attoamm_anno   =	migrElencoDocAll.anno_provvedimento
            and   attoAmm.attoamm_numero = migrElencoDocAll.numero_provvedimento::integer
            and   attoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio)
   			and   (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
		            or attoAmm.validita_fine is null)
            and   tipoAttoAmm.attoamm_tipo_id=attoAmm.attoamm_tipo_id
            and   tipoAttoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoAttoAmm.validita_inizio)
            and   (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoAttoAmm.validita_fine)
                          or tipoAttoAmm.validita_fine is null)
            and  attoAmmCdrRel.ente_proprietario_id=enteProprietarioId
           	and  attoAmmCdrRel.attoamm_id=attoAmm.attoamm_id
            and  attoAmmCdrRel.classif_id=sacCdrId
            and  attoAmmCdrRel.data_cancellazione is null
            and  date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmmCdrRel.validita_inizio)
		 	and	 (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmmCdrRel.validita_fine)
				  or attoAmmCdrRel.validita_fine is null);
        elseif  coalesce(tipoAttoKey,NVL_STR)='K' then
	      	select  coalesce(attoAmm.attoamm_id,0), coalesce( attoAmm.attoamm_tipo_id ,0)
                    into attoAmmId,attoAmmTipoId
    	    from siac_t_atto_amm attoAmm,siac_d_atto_amm_tipo tipoAttoAmm
        	where attoAmm.ente_proprietario_id=enteProprietarioId
            and   attoAmm.attoamm_anno=migrElencoDocAll.anno_provvedimento
            and   attoAmm.attoamm_numero=migrElencoDocAll.numero_provvedimento::integer
            and   attoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio)
            and   (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
                          or attoAmm.validita_fine is null)
            and   tipoAttoAmm.attoamm_tipo_id=attoAmm.attoamm_tipo_id
            and   tipoAttoAmm.attoamm_tipo_code=tipoAtto
            and   tipoAttoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoAttoAmm.validita_inizio)
            and   (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoAttoAmm.validita_fine)
                          or tipoAttoAmm.validita_fine is null);
       else
	       select  coalesce(attoAmm.attoamm_id,0), coalesce( attoAmm.attoamm_tipo_id ,0)
                   into attoAmmId,attoAmmTipoId
    	    from siac_t_atto_amm attoAmm
        	where attoAmm.ente_proprietario_id=enteProprietarioId
            and   attoAmm.attoamm_anno=migrElencoDocAll.anno_provvedimento
            and   attoAmm.attoamm_numero=migrElencoDocAll.numero_provvedimento::integer
            and   attoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio)
            and   (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
                          or attoAmm.validita_fine is null);
       end if;
---------------------------------------------------------------------------------*/

       Select * into leggiAttoAmm
       from fnc_migr_leggi_attoamm (migrElencoDocAll.anno_provvedimento,migrElencoDocAll.numero_provvedimento::INTEGER,migrElencoDocAll.tipo_provvedimento
       		,migrElencoDocAll.sac_provvedimento,enteProprietarioId,loginOperazione,dataElaborazione);

       if leggiAttoAmm.codicerisultato = -1 then
          strMessaggio:=leggiAttoAmm.messaggiorisultato;
          insert into migr_elenco_doc_scarto
          (
           migr_elenco_doc_id,
           motivo_scarto,
           data_creazione,
           ente_proprietario_id
          )values(migrElencoDocAll.migr_elenco_doc_id,
                  strMessaggio,
                  clock_timestamp(),
                  enteProprietarioId);
--          (select migrElencoDocAll.migr_elenco_doc_id,
--                  strMessaggio,
--                  clock_timestamp(),
--                  enteProprietarioId
--           where not exists
--                 (select 1 from  migr_elenco_doc_scarto s
--                  where s.migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id
--                  and   s.ente_proprietario_id=enteProprietarioId)
--           );
          continue;
       end if;
       attoAmmId := leggiAttoAmm.id;

	   if coalesce(attoAmmId,0)=0 then
       	-- scarto
        strMessaggio:=strMessaggio||' Atto Amministrativo non migrato,non presente.';
        insert into migr_elenco_doc_scarto
  	    (
		 migr_elenco_doc_id,
		 motivo_scarto,
		 data_creazione,
		 ente_proprietario_id
        )values(migrElencoDocAll.migr_elenco_doc_id,
	            strMessaggio,
	            clock_timestamp(),
		        enteProprietarioId);
--        (select migrElencoDocAll.migr_elenco_doc_id,
--	            strMessaggio,
--	            clock_timestamp(),
--		        enteProprietarioId
--         where not exists
--               (select 1 from  migr_elenco_doc_scarto s
--                where s.migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id
--                and   s.ente_proprietario_id=enteProprietarioId)
--         );
        continue;
       end if;

       -- lettura atto allegato
       strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
                       || migrElencoDocAll.migr_elenco_doc_id||' tipo='
                       || migrElencoDocAll.tipo_provvedimento||' anno='
                       || migrElencoDocAll.anno_provvedimento||' numero='
                       || migrElencoDocAll.numero_provvedimento||' sac='
                       || quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
                       || migrElencoDocAll.anno_elenco||' numero_elenco='
                       || migrElencoDocAll.numero_elenco||'. Lettura atto allegato.';
       select coalesce(attoAll.attoal_id,0) into attoAllId
       from siac_t_atto_allegato  attoAll, siac_r_migr_atto_all_t_atto_allegato migrRel, migr_atto_allegato migr
       where  attoAll.attoamm_id=attoAmmId
       and    migrRel.attoal_id=attoAll.attoal_id
       and    migrRel.ente_proprietario_id=attoAll.ente_proprietario_id
       and    migr.migr_atto_allegato_id=migrRel.migr_atto_allegato_id
       and    migr.ente_proprietario_id=migrRel.ente_proprietario_id
       and    migr.fl_elab='S'
       and    attoAll.data_cancellazione is null
       and    date_trunc('day',dataElaborazione)>=date_trunc('day',attoAll.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAll.validita_fine)
                or attoAll.validita_fine is null);

       if coalesce(attoAllId,0)=0 then
        -- scarto
        strMessaggio:=strMessaggio||' Atto allegato non migrato,non presente.';
        insert into migr_elenco_doc_scarto
  	    (
		 migr_elenco_doc_id,
		 motivo_scarto,
		 data_creazione,
		 ente_proprietario_id
        )values(migrElencoDocAll.migr_elenco_doc_id,
	            strMessaggio,
		        clock_timestamp(),
			    enteProprietarioId);
--        (select migrElencoDocAll.migr_elenco_doc_id,
--	            strMessaggio,
--		        clock_timestamp(),
--			    enteProprietarioId
--		 where not exists
--               (select 1 from  migr_elenco_doc_scarto s
--                where s.migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id
--                  and   s.ente_proprietario_id=enteProprietarioId)
--         );
        continue;
       end if;

	   -- inserimento elenco siac_t_elenco_doc
       -- capire come gestire numerazione
	   if migrElencoDocAll.numero_elenco = 0 then
	       eldocnumero := eldocnumero+1;
       else
	       eldocnumero := migrElencoDocAll.numero_elenco;
       end if;

       strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
                    || migrElencoDocAll.migr_elenco_doc_id||' tipo='
                    || migrElencoDocAll.tipo_provvedimento||' anno='
                    || migrElencoDocAll.anno_provvedimento||' numero='
                    || migrElencoDocAll.numero_provvedimento||' eldocnumero='
                    || eldocnumero||' sac='
                    || quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
                    || migrElencoDocAll.anno_elenco||' numero_elenco='
                    || migrElencoDocAll.numero_elenco||'. Inserimento elenco doc.';


       insert into siac_t_elenco_doc
       ( eldoc_anno,-- INTEGER NOT NULL,
         eldoc_numero,-- INTEGER NOT NULL,
		--  eldoc_sysesterno_anno,
		--  eldoc_sysesterno_numero,
		--  eldoc_sysesterno VARCHAR,
		  eldoc_data_trasmissione,
	      validita_inizio,
	      ente_proprietario_id,
	      data_creazione,
	      login_operazione,
          login_creazione
       )
       values
       (migrElencoDocAll.anno_elenco::integer,
--        migrElencoDocAll.numero_elenco,
		eldocnumero,
        coalesce(to_timestamp(migrElencoDocAll.data_trasmissione,'yyyy-MM-dd'), dataInizioVal::timestamp), -- 14.10.2015 impostata a 01/01/anno migrazione anzich? data di sistema
        dataInizioVal::timestamp,
        enteProprietarioId,
        clock_timestamp(),
        loginOperazione,
        loginOperazione)
       returning eldoc_id  into elDocId;

      if coalesce(elDocId,0) = 0 then
       	-- scarto
        strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        insert into migr_elenco_doc_scarto
  	    ( migr_elenco_doc_id,
	      motivo_scarto,
   	      data_creazione,
	      ente_proprietario_id
         )values(migrElencoDocAll.migr_elenco_doc_id,
	             strMessaggio,
                 clock_timestamp(),
                 enteProprietarioId);
--         (select migrElencoDocAll.migr_elenco_doc_id,
--	             strMessaggio,
--                 clock_timestamp(),
--                 enteProprietarioId
--		  where not exists
--               (select 1 from  migr_elenco_doc_scarto s
--                where s.migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id
--                and   s.ente_proprietario_id=enteProprietarioId)
--          );
          continue;
      end if;

      scartoId:=null;
      -- siac_r_atto_allegato_elenco_doc
      if coalesce(elDocId,0) != 0 then
            strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
                       || migrElencoDocAll.migr_elenco_doc_id||' tipo='
                       || migrElencoDocAll.tipo_provvedimento||' anno='
                       || migrElencoDocAll.anno_provvedimento||' numero='
                       || migrElencoDocAll.numero_provvedimento||' sac='
                       || quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
                       || migrElencoDocAll.anno_elenco||' numero_elenco='
                       || migrElencoDocAll.numero_elenco||'. Inserimento siac_r_atto_allegato_elenco_doc.';
            insert into siac_r_atto_allegato_elenco_doc
            (attoal_id,
             eldoc_id,
             validita_inizio,
		     ente_proprietario_id,
	         data_creazione,
	         login_operazione
            )
            values
            (attoAllId,
             elDocId,
             dataInizioVal::timestamp,
       		 enteProprietarioId,
             clock_timestamp(),
             loginOperazione)
             returning attoaleldoc_id into scartoId;

             if scartoId is null then
             	--scarto
                 strMessaggio:=strMessaggio||' Inserimento non riuscito.';
       			 insert into migr_elenco_doc_scarto
  	   			 ( migr_elenco_doc_id,
			       motivo_scarto,
   				   data_creazione,
	 		       ente_proprietario_id
                  )values(migrElencoDocAll.migr_elenco_doc_id,
		                 strMessaggio,
		                 clock_timestamp(),
		       		     enteProprietarioId);
--                 (select migrElencoDocAll.migr_elenco_doc_id,
--		                 strMessaggio,
--		                 clock_timestamp(),
--		       		     enteProprietarioId
--				  where not exists
--                           (select 1 from  migr_elenco_doc_scarto s
--                            where s.migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id
--                            and   s.ente_proprietario_id=enteProprietarioId)
--                 );

                delete from siac_t_elenco_doc where eldoc_id=elDocId;
                continue;
             end if;
      end if;

      -- siac_r_elenco_doc_stato
      scartoId:=null;
      strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
    	                || migrElencoDocAll.migr_elenco_doc_id||' tipo='
        	            || migrElencoDocAll.tipo_provvedimento||' anno='
            	        || migrElencoDocAll.anno_provvedimento||' numero='
                	    || migrElencoDocAll.numero_provvedimento||' sac='
                    	|| quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
	                    || migrElencoDocAll.anno_elenco||' numero_elenco='
    	                || migrElencoDocAll.numero_elenco||'. Inserimento siac_r_elenco_doc_stato.';
       insert into siac_r_elenco_doc_stato
       (eldoc_id ,
	    eldoc_stato_id,
        validita_inizio,
        ente_proprietario_id,
        data_creazione,
        login_operazione
       )
       (select elDocId,
       	   	   stato.eldoc_stato_id,
               dataInizioVal::timestamp,
               enteProprietarioId,
               clock_timestamp(),
               loginOperazione
        from siac_d_elenco_doc_stato stato
        where stato.eldoc_stato_code=migrElencoDocAll.stato
        and   stato.ente_proprietario_id=enteProprietarioId
        and   stato.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio)
        and   (date_trunc('day',dataElaborazione)<=date_trunc('day',stato.validita_fine)
                          or stato.validita_fine is null))
        returning eldoc_r_stato_id into scartoId;

        if scartoId is null then
        	--scarto
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
 		    insert into migr_elenco_doc_scarto
  	   		( migr_elenco_doc_id,
			  motivo_scarto,
   			  data_creazione,
	 		  ente_proprietario_id
             )values(migrElencoDocAll.migr_elenco_doc_id,
	                 strMessaggio,
		             clock_timestamp(),
		       		 enteProprietarioId);
--             (select migrElencoDocAll.migr_elenco_doc_id,
--	                 strMessaggio,
--		             clock_timestamp(),
--		       		 enteProprietarioId
--		      where not exists
--                           (select 1 from  migr_elenco_doc_scarto s
--                            where s.migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id
--                            and   s.ente_proprietario_id=enteProprietarioId)
--              );

           delete from siac_r_atto_allegato_elenco_doc where eldoc_id=elDocId;
           delete from siac_t_elenco_doc where eldoc_id=elDocId;
           continue;
       end if;


       scartoId:=null;
       strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
    	                || migrElencoDocAll.migr_elenco_doc_id||' tipo='
        	            || migrElencoDocAll.tipo_provvedimento||' anno='
            	        || migrElencoDocAll.anno_provvedimento||' numero='
                	    || migrElencoDocAll.numero_provvedimento||' sac='
                    	|| quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
	                    || migrElencoDocAll.anno_elenco||' numero_elenco='
    	                || migrElencoDocAll.numero_elenco||'. Inserimento siac_r_elenco_doc_subdoc per subdoc spesa.';
       -- inserire le relazioni tra quote spesa e elenco
       insert into siac_r_elenco_doc_subdoc
       (subdoc_id,
	    eldoc_id ,
        validita_inizio,
        ente_proprietario_id,
        data_creazione,
        login_operazione
        )
        (select  subDoc.subdoc_id,
                 elDocId,
                 dataInizioVal::timestamp,
                 enteProprietarioId,
                 clock_timestamp(),
                 loginOperazione
         from siac_t_subdoc  subDoc, siac_r_subdoc_atto_amm subDocAttoAmm
         where subDocAttoAmm.attoamm_id=attoAmmId
         and   subDocAttoAmm.subdoc_id=subDoc.subdoc_id
         and   subDocAttoAmm.ente_proprietario_id=subDoc.ente_proprietario_id
         and   subDocAttoAmm.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',subDocAttoAmm.validita_inizio)
         and   (date_trunc('day',dataElaborazione)<=date_trunc('day',subDocAttoAmm.validita_fine)
                          or subDocAttoAmm.validita_fine is null)
		 and   subDoc.subdoc_tipo_id=subDocSpesaTipoId
         and   subDoc.ente_proprietario_id=enteProprietarioId
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',subDoc.validita_inizio)
         and   (date_trunc('day',dataElaborazione)<=date_trunc('day',subDoc.validita_fine)
                          or subDoc.validita_fine is null)
         and exists (select 1
                     from siac_r_migr_docquo_spesa_t_subdoc migrDocQuoRel,migr_docquo_spesa migrDocQuo
                     where migrDocQuoRel.subdoc_id=subDoc.subdoc_id
                     and   migrDocQuoRel.ente_proprietario_id=enteProprietarioId
                     and   migrDocQuo.migr_docquo_spesa_id = migrDocQuoRel.migr_docquo_spesa_id
                     and   migrDocQuo.elenco_doc_id=migrElencoDocAll.elenco_doc_id
                     --and   migrDocQuo.anno_elenco= migrElencoDocAll.anno_elenco
                     --and   migrDocQuo.numero_elenco= migrElencoDocAll.numero_elenco
                     ));


        -- inserire le relazioni tra quote entrata e elenco
        strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
    	                || migrElencoDocAll.migr_elenco_doc_id||' tipo='
        	            || migrElencoDocAll.tipo_provvedimento||' anno='
            	        || migrElencoDocAll.anno_provvedimento||' numero='
                	    || migrElencoDocAll.numero_provvedimento||' sac='
                    	|| quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
	                    || migrElencoDocAll.anno_elenco||' numero_elenco='
    	                || migrElencoDocAll.numero_elenco||'. Inserimento siac_r_elenco_doc_subdoc per subdoc entrata.';
        insert into siac_r_elenco_doc_subdoc
       (subdoc_id,
	    eldoc_id ,
        validita_inizio,
        ente_proprietario_id,
        data_creazione,
        login_operazione
        )
        (select  subDoc.subdoc_id,
                 elDocId,
                 dataInizioVal::timestamp,
                 enteProprietarioId,
                 clock_timestamp(),
                 loginOperazione
         from siac_t_subdoc  subDoc, siac_r_subdoc_atto_amm subDocAttoAmm
         where subDocAttoAmm.attoamm_id=attoAmmId
         and   subDocAttoAmm.subdoc_id=subDoc.subdoc_id
         and   subDocAttoAmm.ente_proprietario_id=subDoc.ente_proprietario_id
         and   subDocAttoAmm.data_cancellazione is null
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',subDocAttoAmm.validita_inizio)
         and   (date_trunc('day',dataElaborazione)<=date_trunc('day',subDocAttoAmm.validita_fine)
                          or subDocAttoAmm.validita_fine is null)
		 and   subDoc.subdoc_tipo_id=subDocEntrataTipoId
         and   subDoc.ente_proprietario_id=enteProprietarioId
         and   date_trunc('day',dataElaborazione)>=date_trunc('day',subDoc.validita_inizio)
         and   (date_trunc('day',dataElaborazione)<=date_trunc('day',subDoc.validita_fine)
                          or subDoc.validita_fine is null)
         and exists (select 1
                     from siac_r_migr_docquo_entrata_t_subdoc migrDocQuoRel,migr_docquo_entrata migrDocQuo
                     where migrDocQuoRel.subdoc_id=subDoc.subdoc_id
                     and   migrDocQuoRel.ente_proprietario_id=enteProprietarioId
                     and   migrDocQuo.migr_docquo_entrata_id= migrDocQuoRel.migr_docquo_entrata_id
                     and   migrDocQuo.elenco_doc_id=migrElencoDocAll.elenco_doc_id
                     --and   migrDocQuo.anno_elenco= migrElencoDocAll.anno_elenco
                     --and   migrDocQuo.numero_elenco= migrElencoDocAll.numero_elenco
                     ));

        scartoId:=null;
        strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
    	                || migrElencoDocAll.migr_elenco_doc_id||' tipo='
        	            || migrElencoDocAll.tipo_provvedimento||' anno='
            	        || migrElencoDocAll.anno_provvedimento||' numero='
                	    || migrElencoDocAll.numero_provvedimento||' sac='
                    	|| quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
	                    || migrElencoDocAll.anno_elenco||' numero_elenco='
    	                || migrElencoDocAll.numero_elenco||'. Inserimento siac_r_migr_elenco_doc_all_t_elenco_doc.';
		insert into siac_r_migr_elenco_doc_all_t_elenco_doc
        (migr_elenco_doc_id,
  		 eldoc_id,
         data_creazione,
		 ente_proprietario_id)
         values
        (migrElencoDocAll.migr_elenco_doc_id,
         elDocId,
         clock_timestamp(),
         enteProprietarioId
        )
        returning migr_elenco_doc_rel_id into scartoId;

    	if scartoId is null then
        	--scarto
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
 		    insert into migr_elenco_doc_scarto
  	   		( migr_elenco_doc_id,
			  motivo_scarto,
   			  data_creazione,
	 		  ente_proprietario_id
             )values(migrElencoDocAll.migr_elenco_doc_id,
		             strMessaggio,
		             clock_timestamp(),
		       		 enteProprietarioId);
--             (select migrElencoDocAll.migr_elenco_doc_id,
--		             strMessaggio,
--		             clock_timestamp(),
--		       		 enteProprietarioId
--			  where not exists
--                           (select 1 from  migr_elenco_doc_scarto s
--                            where s.migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id
--                            and   s.ente_proprietario_id=enteProprietarioId)
--              );


           delete from siac_r_atto_allegato_elenco_doc where eldoc_id=elDocId;
           delete from siac_r_elenco_doc_stato where eldoc_id=elDocId;
           delete from siac_r_elenco_doc_subdoc where eldoc_id=elDocId;
           delete from siac_t_elenco_doc where eldoc_id=elDocId;
           continue;
        end if;


        strMessaggio:='Elenco documenti allegati da migrare per migr_elenco_doc_id='
    	                || migrElencoDocAll.migr_elenco_doc_id||' tipo='
        	            || migrElencoDocAll.tipo_provvedimento||' anno='
            	        || migrElencoDocAll.anno_provvedimento||' numero='
                	    || migrElencoDocAll.numero_provvedimento||' sac='
                    	|| quote_nullable(migrElencoDocAll.sac_provvedimento)||' anno_elenco='
	                    || migrElencoDocAll.anno_elenco||' numero_elenco='
    	                || migrElencoDocAll.numero_elenco||'. Aggiornamento migr_elenco_doc_allegati per fl_elab';
		update migr_elenco_doc_allegati
        set fl_elab='S'
        where migr_elenco_doc_id=migrElencoDocAll.migr_elenco_doc_id;

        numeroRecordInseriti:=numeroRecordInseriti+1;

    end loop;

-- update contatore
	select el.eldoc_numero into maxeldocnumero
    from siac_t_elenco_doc el
    where el.ente_proprietario_id = enteProprietarioId::integer
    and el.eldoc_anno=annobilancio::integer
    order by el.eldoc_numero desc limit 1;

    if maxeldocnumero is not null and maxeldocnumero > 0 THEN
      select coalesce (count(*),0) into v_count from  siac_t_elenco_doc_num where ente_proprietario_id = enteProprietarioId::integer and bil_id = bilancioid;
	  if v_count = 0 then
	    strMessaggio:='Inserimento record in siac_t_elenco_doc_num per bilancioid '|| bilancioid||
                      ', ente '||enteProprietarioId||
                      ', eldoc_numero '||maxeldocnumero||'.';
        insert into siac_t_elenco_doc_num
		  (bil_id,
		   eldoc_numero,
  		   validita_inizio,
		   ente_proprietario_id,
  		   login_operazione)
        values
        (bilancioid
        ,maxeldocnumero
        ,dataInizioVal::timestamp
        ,enteProprietarioId::integer
        ,loginOperazione);
      else
	    strMessaggio:='update record in siac_t_elenco_doc_num per bilancioid '|| bilancioid||
                      ', ente '||enteProprietarioId||
                      ', eldoc_numero '||maxeldocnumero||'.';
        update siac_t_elenco_doc_num set eldoc_numero = maxeldocnumero where ente_proprietario_id = enteProprietarioId::integer and bil_id = bilancioid;
      end if;
    end if;

	RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||'. Inseriti '||numeroRecordInseriti||' elenchi doc.';
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