/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿/*DROP FUNCTION fnc_migr_atto_allegato
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out numeroRecordInseriti integer,
  out messaggioRisultato varchar );*/

CREATE OR REPLACE FUNCTION fnc_migr_atto_allegato
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  loginOperazione varchar,
  dataElaborazione timestamp,
  idMin INTEGER,
  idMax INTEGER,
  out numeroRecordInseriti integer,
  out messaggioRisultato varchar )
RETURNS record AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigrAttoAll integer := 0;

 migrAttoAll record;
 migrAttoAllSog record;
 leggiAttoAmm record;
 tipoAtto varchar(500):=null;
 tipoAttoKey varchar(500):=null;
 sacCdr varchar(500):=null;
 sacCdrKey varchar(500):=null;

 sacCdrId integer:=null;
 attoAmmId integer:=null;
 attoAmmTipoId integer:=null;
 attoAlId integer:=null;
 scartoId integer:=null;
 attoalFlgRitenute boolean := false; -- DAVIDE - 04.01.2017
 
 cdrClassifTipoId integer:=null;
 NVL_STR               CONSTANT VARCHAR:='';

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 inSubLoop boolean:=false;

 CDR_SAC     CONSTANT  varchar :='CDR';
 SEPARATORE     CONSTANT  varchar :='||';
BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione atti allegati da id ['||idMin||'] a id ['||idMax||']';

    strMessaggio:='Lettura atti allegati da migrare.';
	begin
		select distinct 1 into strict countMigrAttoAll
        from migr_atto_allegato ms
		where ms.ente_proprietario_id=enteProprietarioId
        and ms.migr_atto_allegato_id >= idMin and ms.migr_atto_allegato_id <=idMax
        and   ms.fl_elab='N';

	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;


	begin

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

    strMessaggio:='Lettura atti allegati da migrare.Inizio ciclo.';
    for migrAttoAll IN
    (select ms.*
     from migr_atto_allegato ms
     where ms.ente_proprietario_id=enteProprietarioId
     and   ms.fl_elab='N'
     and ms.migr_atto_allegato_id >= idMin and ms.migr_atto_allegato_id <=idMax
     order by ms.tipo_provvedimento,
              ms.anno_provvedimento::integer,ms.numero_provvedimento::integer,
              ms.sac_provvedimento
    )
    loop

    	tipoAtto:=null;
        tipoAttoKey:=null;
        sacCdr:=null;
        sacCdrKey:=null;
        sacCdrId:=null;
		attoAmmId:=null;
        attoAmmTipoId:=null;
		attoAlId:=null;
        scartoId:=null;
		inSubLoop:=false;

/*---------------------------------------------------------------- 14.10.2015 fnc_migr_leggi_attoamm -----------------------------------------------------------------------
        strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||'.Lettura Atto Amministrativo tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       ||quote_nullable( migrAttoAll.sac_provvedimento)||'.';

    	-- lettura il provvedimento
        tipoAtto      := split_part(migrAttoAll.tipo_provvedimento,SEPARATORE,1);
        tipoAttoKey   := split_part(migrAttoAll.tipo_provvedimento,SEPARATORE,2);
        if coalesce(migrAttoAll.sac_provvedimento,NVL_STR) != NVL_STR then
        	sacCdr   :=split_part(migrAttoAll.sac_provvedimento,SEPARATORE,1);
            sacCdrKey:=split_part(migrAttoAll.sac_provvedimento,SEPARATORE,2);

            if coalesce(sacCdrKey,NVL_STR)='K' then
            	strMessaggio:=strMessaggio||' Lettura SacId per SacCdr='||SacCdr||'.';
            	select coalesce(class.classif_id,0) into sacCdrId
                from siac_t_class class
                where class.classif_code=sacCdr
                and   class.ente_proprietario_id=enteProprietarioId
                and   class.classif_tipo_id=cdrClassifTipoId
                and   class.data_cancellazione is null
                and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio) and
                      (date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine)
                         or class.validita_fine is null);

                if sacCdrId is null then
                	--- scarto
                    insert into migr_atto_allegato_scarto
					(
					  migr_atto_allegato_id,
					  motivo_scarto,
					  data_creazione,
					  ente_proprietario_id
                    )
                    (select migrAttoAll.migr_atto_allegato_id,
	                        strMessaggio,
        			        clock_timestamp(),
					        enteProprietarioId
                      where not exists
		        	       (select 1 from migr_atto_allegato_scarto s
            		        where s.migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
         	        		and   s.ente_proprietario_id=enteProprietarioId)
                    );
                    continue;
                end if;
            end if;

        end if;

        strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||'.Lettura Atto Amministrativo tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || quote_nullable(migrAttoAll.sac_provvedimento)||'.';

        if  coalesce(sacCdrId,0)!=0 and  coalesce(sacCdrKey,NVL_STR)='K' THEN

       		select coalesce(attoAmm.attoamm_id,0),coalesce( attoAmm.attoamm_tipo_id ,0)
                   into attoAmmId,attoAmmTipoId
            from siac_t_atto_amm attoAmm, siac_d_atto_amm_tipo tipoAttoAmm,siac_r_atto_amm_class attoAmmCdrRel
            where attoAmm.ente_proprietario_id=enteProprietarioId
            and   attoAmm.attoamm_anno   =	migrAttoAll.anno_provvedimento
            and   attoAmm.attoamm_numero = migrAttoAll.numero_provvedimento_calcolato::integer
            and   attoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio)
   			and   (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
		            or attoAmm.validita_fine is null)
            and   tipoAttoAmm.attoamm_tipo_id=attoAmm.attoamm_tipo_id
            and   tipoAttoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoAttoAmm.validita_inizio)
            and   (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoAttoAmm.validita_fine)
                          or tipoAttoAmm.validita_fine is null)
            and   attoAmmCdrRel.ente_proprietario_id=enteProprietarioId
           	and   attoAmmCdrRel.attoamm_id=attoAmm.attoamm_id
            and   attoAmmCdrRel.classif_id=sacCdrId
            and   attoAmmCdrRel.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmmCdrRel.validita_inizio)
		 	and	  (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmmCdrRel.validita_fine)
				   or attoAmmCdrRel.validita_fine is null);
        elseif  coalesce(tipoAttoKey,NVL_STR)='K' then
	      	select  coalesce(attoAmm.attoamm_id,0), coalesce( attoAmm.attoamm_tipo_id ,0)
                    into attoAmmId,attoAmmTipoId
    	    from siac_t_atto_amm attoAmm,siac_d_atto_amm_tipo tipoAttoAmm
        	where attoAmm.ente_proprietario_id=enteProprietarioId
            and   attoAmm.attoamm_anno=migrAttoAll.anno_provvedimento
            and   attoAmm.attoamm_numero=migrAttoAll.numero_provvedimento_calcolato::integer
            and   attoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio)
            and   (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
                          or attoAmm.validita_fine is null)
            and   tipoAttoAmm.attoamm_tipo_id=attoAmm.attoamm_tipo_id
            and   tipoAttoAmm.attoamm_tipo_code=tipoAtto
            and   tipoAttoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoAttoAmm.validita_inizio)
            and  (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoAttoAmm.validita_fine)
                          or tipoAttoAmm.validita_fine is null);
       else
	       select  coalesce(attoAmm.attoamm_id,0), coalesce( attoAmm.attoamm_tipo_id ,0)
                   into attoAmmId,attoAmmTipoId
    	    from siac_t_atto_amm attoAmm
        	where attoAmm.ente_proprietario_id=enteProprietarioId
            and   attoAmm.attoamm_anno=migrAttoAll.anno_provvedimento
            and   attoAmm.attoamm_numero=migrAttoAll.numero_provvedimento_calcolato::integer
            and   attoAmm.data_cancellazione is null
            and   date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio)
            and   (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
                          or attoAmm.validita_fine is null);
       end if;

---------------------------------------------------------------------------------*/

       Select * into leggiAttoAmm
       from fnc_migr_leggi_attoamm (migrAttoAll.anno_provvedimento,migrAttoAll.numero_provvedimento_calcolato::INTEGER,migrAttoAll.tipo_provvedimento
       		,migrAttoAll.sac_provvedimento,enteProprietarioId,loginOperazione,dataElaborazione);

       if leggiAttoAmm.codicerisultato = -1 then
          strMessaggio:=leggiAttoAmm.messaggiorisultato;
          insert into migr_atto_allegato_scarto
          (
           migr_atto_allegato_id,
           motivo_scarto,
           data_creazione,
           ente_proprietario_id
          )values(migrAttoAll.migr_atto_allegato_id,
                  strMessaggio,
                  clock_timestamp(),
                  enteProprietarioId);
--          (select migrAttoAll.migr_atto_allegato_id,
--                  strMessaggio,
--                  clock_timestamp(),
--                  enteProprietarioId
--           where not exists
--                (select 1 from migr_atto_allegato_scarto s
--                 where s.migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
--                  and   s.ente_proprietario_id=enteProprietarioId)
--           );
          continue;
       end if;
       attoAmmId := leggiAttoAmm.id;

	   if coalesce(attoAmmId,0)=0 then
       	-- scarto
        strMessaggio:=strMessaggio||' Atto Amministrativo non migrato,non presente.';
        insert into migr_atto_allegato_scarto
  	    (
		 migr_atto_allegato_id,
		 motivo_scarto,
		 data_creazione,
		 ente_proprietario_id
        )values(migrAttoAll.migr_atto_allegato_id,
	            strMessaggio,
		        clock_timestamp(),
		   	    enteProprietarioId);
--        (select migrAttoAll.migr_atto_allegato_id,
--	            strMessaggio,
--		        clock_timestamp(),
--		   	    enteProprietarioId
--		 where not exists
--		      (select 1 from migr_atto_allegato_scarto s
--               where s.migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
--          		and   s.ente_proprietario_id=enteProprietarioId)
--         );
        continue;
       end if;

	   -- DAVIDE - 04.01.2017 - imposta il valore del campo ATTOAL_FLAG_RITENUTE a seconda del dato migrato
       if migrAttoAll.attoal_flag_ritenute = 'S' then	       
           attoalFlgRitenute:=true; 
	   else
           attoalFlgRitenute:=false; 
	   end if;
	   
	   -- inserimento elenco siac_t_atto_allegato
       strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       ||quote_nullable( migrAttoAll.sac_provvedimento)||'. Inserimento atto allegato.';
       insert into siac_t_atto_allegato
       (  attoamm_id,
	      attoal_causale,
		  attoal_altriallegati,
		  attoal_dati_sensibili,
		  attoal_data_scadenza,
		  attoal_note,
		  attoal_annotazioni,
		  attoal_pratica,
		  attoal_responsabile_amm,
		  attoal_responsabile_con,
          attoal_titolario_anno,
          attoal_titolario_numero,
          attoal_versione_invio_firma,
          ATTOAL_FLAG_RITENUTE, -- 22.12.2016 Sofia-Davide campo aggiunto not null
		  validita_inizio,
		  ente_proprietario_id,
		  data_creazione,
		  login_operazione,
		  login_creazione
       )
       values
       (
          attoAmmId,
          migrAttoAll.causale,
          migrAttoAll.altri_allegati,
          migrAttoAll.dati_sensibili,
          to_timestamp(migrAttoAll.data_scadenza,'yyyy-MM-dd'),
          migrAttoAll.note,
          migrAttoAll.annotazioni,
          migrAttoAll.pratica,
          migrAttoAll.responsabile_amm,
          migrAttoAll.responsabile_cont,
          migrAttoAll.anno_titolario::INTEGER,
          migrAttoAll.numero_titolario,
          migrAttoAll.versione,
          --false,                  22.12.2016 Sofia-Davide campo aggiunto not null
		  attoalFlgRitenute,        -- DAVIDE - 04.01.2017 - imposta il valore del campo ATTOAL_FLAG_RITENUTE 
	      dataInizioVal::timestamp,
          enteProprietarioId,
          clock_timestamp(),
          loginOperazione,
          loginOperazione)
        returning attoal_id  into attoAlId;

      if coalesce(attoAlId,0) = 0 then
       	-- scarto
        strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        insert into migr_atto_allegato_scarto
  	    ( migr_atto_allegato_id,
	      motivo_scarto,
   	      data_creazione,
	      ente_proprietario_id
         )values(migrAttoAll.migr_atto_allegato_id,
		         strMessaggio,
		         clock_timestamp(),
        	     enteProprietarioId);
--         (select migrAttoAll.migr_atto_allegato_id,
--		         strMessaggio,
--		         clock_timestamp(),
--        	     enteProprietarioId
--		  where not exists
--		        (select 1 from migr_atto_allegato_scarto s
--                 where s.migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
--            	 and   s.ente_proprietario_id=enteProprietarioId)
--          );
          continue;
      end if;


      -- siac_r_atto_allegato_stato
      scartoId:=null;
      strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || quote_nullable(migrAttoAll.sac_provvedimento)||'. Inserimento siac_r_atto_allegato_stato.';
       insert into siac_r_atto_allegato_stato
       (attoal_id ,
	    attoal_stato_id,
        validita_inizio,
        ente_proprietario_id,
        data_creazione,
        login_operazione
       )
       (select attoAlId,
       	   	   stato.attoal_stato_id,
               coalesce(migrAttoAll.data_completamento::timestamp,dataInizioVal::timestamp),
               enteProprietarioId,
               clock_timestamp(),
               loginOperazione
        from siac_d_atto_allegato_stato stato
        where stato.attoal_stato_code=migrAttoAll.stato
        and   stato.ente_proprietario_id=enteProprietarioId
        and   stato.data_cancellazione is null
        and   date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',stato.validita_fine)
                          or stato.validita_fine is null))
        returning attoal_r_stato_id into scartoId;

        if scartoId is null then
        	--scarto
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
 		    insert into migr_atto_allegato_scarto
  	    	( migr_atto_allegato_id,
	    	  motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrAttoAll.migr_atto_allegato_id,
	        	     strMessaggio,
      	             clock_timestamp(),
        	         enteProprietarioId);
--     	    (select  migrAttoAll.migr_atto_allegato_id,
--	        	     strMessaggio,
--      	             clock_timestamp(),
--        	         enteProprietarioId
--			 where not exists
--		          (select 1 from migr_atto_allegato_scarto s
--                   where s.migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
--         	   		and   s.ente_proprietario_id=enteProprietarioId)
--            );

            delete from siac_t_atto_allegato where attoal_id=attoAlId;
            continue;
       end if;


/* 28.12.2015 inizio gestione relazione atto allegato / soggetto

	   strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || quote_nullable(migrAttoAll.sac_provvedimento)||'. Inserimento siac_r_atto_allegato_sog.';
        scartoId:=null;
        -- gestione di siac_r_atto_allegato_sog
		if migrAttoAll.codice_soggetto!=0 then
	        strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || migrAttoAll.sac_provvedimento||'. Inserimento siac_r_atto_allegato_sog singolo.';
        	INSERT INTO siac_r_atto_allegato_sog
			(attoal_id,
	         soggetto_id,
			 attoal_sog_causale_sosp,
			 attoal_sog_data_sosp,
			 attoal_sog_data_riatt,
	         validita_inizio,
		     ente_proprietario_id,
	         data_creazione,
	 	     login_operazione
	 	    )
            (select attoAlId,
                    sogg.soggetto_id,
                    migrAttoAll.causale_sospensione,
                    to_timestamp(migrAttoAll.data_sospensione,'yyyy-MM-dd'),
                    to_timestamp(migrAttoAll.data_riattivazione,'yyyy-MM-dd'),
                    dataInizioVal::timestamp,
                    enteProprietarioId,
                    clock_timestamp(),
                    loginOperazione
         	 from siac_t_soggetto sogg
	         where sogg.soggetto_code = migrAttoAll.codice_soggetto::varchar
	         and   sogg.ente_proprietario_id = enteProprietarioId
    	     and   sogg.data_cancellazione is null
        	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',sogg.validita_inizio)
	         and   (date_trunc('day',dataElaborazione)<date_trunc('day',sogg.validita_fine) or sogg.validita_fine is null)
    	     and exists
        		  (select 1 from siac_r_migr_soggetto_soggetto r
		           where r.ente_proprietario_id = sogg.ente_proprietario_id
        		   and sogg.soggetto_id=r.soggetto_id))
	        returning attoal_sog_id into scartoId;

            if scartoId is null then
        		--scarto
	   	        strMessaggio:=strMessaggio||' Inserimento non riuscito.';
 			    insert into migr_atto_allegato_scarto
  	    		( migr_atto_allegato_id,
		    	  motivo_scarto,
   		    	  data_creazione,
	   			  ente_proprietario_id
	        	 )select(migrAttoAll.migr_atto_allegato_id,
	    	    	     strMessaggio,
	   	    	         clock_timestamp(),
	       	    	     enteProprietarioId);
--	     	    (select migrAttoAll.migr_atto_allegato_id,
--	    	    	     strMessaggio,
--	   	    	         clock_timestamp(),
--	       	    	     enteProprietarioId
--				 where not exists
--		        	       (select 1 from migr_atto_allegato_scarto s
--            		        where s.migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
--         	        		and   s.ente_proprietario_id=enteProprietarioId)
--	            );

	            delete from siac_r_atto_allegato_stato where attoal_id=attoAlId;
                delete from siac_t_atto_allegato where attoal_id=attoAlId;

    	        continue;
      		end if;
        else
            strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || quote_nullable(migrAttoAll.sac_provvedimento)||'.  Lettura migr_atto_allegato_sog per inserimento siac_r_atto_allegato_sog.';
        	for migrAttoAllSog in
            (select ms.*
		     from migr_atto_allegato_sog ms
		     where ms.atto_allegato_id=migrAttoAll.atto_allegato_id
             and   ms.ente_proprietario_id=enteProprietarioId
		     and   ms.fl_elab='N'
		     order by ms.codice_soggetto
		    )
		    loop
            	scartoId:=null;
                strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || quote_nullable(migrAttoAll.sac_provvedimento)||
                       '. Inserimento siac_r_atto_allegato_sog codice_soggetto='
                       || migrAttoAllSog.codice_soggetto||'.';
        		INSERT INTO siac_r_atto_allegato_sog
				(attoal_id,
	       		 soggetto_id,
				 attoal_sog_causale_sosp,
				 attoal_sog_data_sosp,
				 attoal_sog_data_riatt,
	        	 validita_inizio,
			     ente_proprietario_id,
		         data_creazione,
	 		     login_operazione
	 	    	)
	            (select attoAlId,
    	                sogg.soggetto_id,
        	            migrAttoAllSog.causale_sospensione,
            	        to_timestamp(migrAttoAllSog.data_sospensione,'yyyy-MM-dd'),
                	    to_timestamp(migrAttoAllSog.data_riattivazione,'yyyy-MM-dd'),
                    	dataInizioVal::timestamp,
	                    enteProprietarioId,
    	                clock_timestamp(),
        	            loginOperazione
         		 from siac_t_soggetto sogg
		         where sogg.soggetto_code = migrAttoAllSog.codice_soggetto::varchar
		         and   sogg.ente_proprietario_id = enteProprietarioId
    		     and   sogg.data_cancellazione is null
        		 and   date_trunc('day',dataElaborazione)>=date_trunc('day',sogg.validita_inizio)
		         and   (date_trunc('day',dataElaborazione)<date_trunc('day',sogg.validita_fine) or sogg.validita_fine is null)
    		     and exists
        			  (select 1 from siac_r_migr_soggetto_soggetto r
		    	       where r.ente_proprietario_id = sogg.ente_proprietario_id
        			   and   r.soggetto_id=sogg.soggetto_id))
		        returning attoal_sog_id into scartoId;
                if scartoId is null then
                	continue;
                end if;
            end loop;

            if inSubLoop= true and scartoId is null then
	   	        strMessaggio:=strMessaggio||' Inserimento non riuscito.';
 			    insert into migr_atto_allegato_scarto
  	    		( migr_atto_allegato_id,
		    	  motivo_scarto,
   		    	  data_creazione,
	   			  ente_proprietario_id
	        	 )values(migrAttoAll.migr_atto_allegato_id,
    	    			 strMessaggio,
		    	         clock_timestamp(),
		     	    	 enteProprietarioId);
--	     	    (select  migrAttoAll.migr_atto_allegato_id,
--    	    			 strMessaggio,
--		    	         clock_timestamp(),
--		     	    	 enteProprietarioId
--				 where not exists
--		               (select 1 from migr_atto_allegato_scarto s
--            	        where s.migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
--         	       		and   s.ente_proprietario_id=enteProprietarioId)
--	            );

	            delete from siac_r_atto_allegato_stato where attoal_id=attoAlId;
                delete from siac_r_atto_allegato_sog where attoal_id=attoAlId;
       	        delete from siac_t_atto_allegato where attoal_id=attoAlId;

    	        continue;
            end if;

        end if;

28.12.2015 fine gestione relazione atto allegato / soggetto */


        scartoId:=null;
        strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || quote_nullable(migrAttoAll.sac_provvedimento)||'. Inserimento siac_r_migr_atto_all_t_atto_allegato.';
		insert into siac_r_migr_atto_all_t_atto_allegato
        (migr_atto_allegato_id,
  		 attoal_id,
         data_creazione,
		 ente_proprietario_id)
         values
        (migrAttoAll.migr_atto_allegato_id,
         attoAlId,
         clock_timestamp(),
         enteProprietarioId
        )
        returning migr_atto_allegato_rel_id into scartoId;

    	if scartoId is null then
        	--scarto
   	        strMessaggio:=strMessaggio||' Inserimento non riuscito.';
 		    insert into migr_atto_allegato_scarto
  	    	( migr_atto_allegato_id,
	    	  motivo_scarto,
   	    	  data_creazione,
	   		  ente_proprietario_id
	         )values(migrAttoAll.migr_atto_allegato_id,
		        	 strMessaggio,
		             clock_timestamp(),
	        	     enteProprietarioId);
--     	    ( select migrAttoAll.migr_atto_allegato_id,
--		        	 strMessaggio,
--		             clock_timestamp(),
--	        	     enteProprietarioId
--			  where not exists
--		            (select 1 from migr_atto_allegato_scarto s
--                     where s.migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
--         	      		and   s.ente_proprietario_id=enteProprietarioId)
--            );

            delete from siac_r_atto_allegato_stato where attoal_id=attoAlId;
            delete from siac_r_atto_allegato_sog  where attoal_id=attoAlId;
   	        delete from siac_t_atto_allegato where attoal_id=attoAlId;
            continue;
        end if;



       strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || quote_nullable(migrAttoAll.sac_provvedimento)||'. Aggiornamento migr_atto_allegato per fl_elab';
		update migr_atto_allegato
        set fl_elab='S'
        where migr_atto_allegato_id=migrAttoAll.migr_atto_allegato_id
        and   fl_elab='N';

		 strMessaggio:='Atto allegato da migrare per migr_atto_allegato_id='
                       || migrAttoAll.migr_atto_allegato_id||' tipo='
                       || migrAttoAll.tipo_provvedimento||' anno='
                       || migrAttoAll.anno_provvedimento||' numero='
                       || migrAttoAll.numero_provvedimento_calcolato||' sac='
                       || quote_nullable(migrAttoAll.sac_provvedimento)||'. Aggiornamento migr_atto_allegato_sog per fl_elab';
		update migr_atto_allegato_sog
        set fl_elab='S'
        where atto_allegato_id=migrAttoAll.atto_allegato_id
        and   ente_proprietario_id=enteProprietarioId
        and   fl_elab='N';

        numeroRecordInseriti:=numeroRecordInseriti+1;

    end loop;

	RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||'. Inseriti '||numeroRecordInseriti||' atti allegati.';
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