/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_attoamm_movgest (annoAttoAmm varchar,numeroAttoAmm integer,
			            							 tipoAttAmm varchar,
                                                     strPrimoLivAttoAmm varchar,
												     oggettoAttoAmm varchar,noteAttoAmm varchar,
												     statoAttoAmm varchar,
                                                     movgestTsId integer,
		  							                 enteProprietarioId integer,
		  											 loginOperazione    varchar,
													 dataElaborazione   timestamp,
													 datainizioval timestamp,
		  											 out codiceRisultato integer,
													 out messaggioRisultato     varchar
												    )
RETURNS record AS
$body$
DECLARE
 -- da chiarire
  -- numerazione per ATTO SPR
  -- come controllare lo stato operativo di AttoAmministrativo che in contabilia dovrebbe
  -- guidare sullo stato del movimento di gestione
 -- fnc_migr_attoamm_movgest -- riceve gli estremi di un atto amministrativo
                             --  e del movimento di gestione cui associarlo
 -- verifica esistenza Atto Amministrativo
  -- se esiste lo utilizza per associarlo al movimento gestione
  -- se non esiste lo inserisce e lo associa al movimento gestione
 -- restitusce
   -- messaggioRisultato=risultato in formato testo
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)


 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 tipoAttoAmmCode varchar(500):='';
 tipoAttoAmmKey  varchar(10):='';
 cdrAttoAmmCode varchar(500):='';
 cdrAttoAmmKey  varchar(10):='';
 statoAttoAmmaSiac VARCHAR(20):='';

 strToElab VARCHAR(1500):='';

 attoAmmRec record;

 attoAmmTipoId integer:=0;
 classCdrId integer:=0;
 attoAmmId integer:=0;
 attoAmmCdrRelId integer:=0;
 numeroAttoAmmLoc integer:=0;

 insAttoAmm boolean:=FALSE;

 NK_STR              CONSTANT VARCHAR:='NK';
 NVL_STR             CONSTANT VARCHAR:='';
 SEPARATORE			 CONSTANT  varchar :='||';
 CDR CONSTANT  varchar :='CDR';
 CDC CONSTANT  varchar :='CDC';
 DEFINITIVO   CONSTANT varchar:='DEFINITIVO';
 PROVVISORIO   CONSTANT varchar:='PROVVISORIO';

 STATO_D CONSTANT varchar:='D';
 STATO_P CONSTANT varchar:='P';

 LENGTH_STR   CONSTANT integer:=500;
 NUMERO_ATTO_INTERNO CONSTANT integer:=9999999;

 SPR CONSTANT varchar:='SPR';

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

	strMessaggioFinale:='Gestione AttoAmm  '||annoAttoAmm||'/'||coalesce(numeroAttoAmm,0)||'/'||quote_nullable(tipoAttAmm)||' Sac '||quote_nullable(strPrimoLivAttoAmm)||'.';

    begin
      	strToElab:=tipoAttAmm;
	    /*tipoAttoAmmCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        tipoAttoAmmKey:=substring(strToElab from
				                  position(SEPARATORE in strToElab)+2
			                      for char_length(strToElab)-position(SEPARATORE in strToElab)); 05.10.2015 Sofia */

        -- 05.10.2015 Sofia
        tipoAttoAmmCode:=split_part(strToElab,SEPARATORE,1);
        tipoAttoAmmKey:=split_part(strToElab,SEPARATORE,2);

		-- Lettura Tipo Atto Amm
		strMessaggio:='Lettura tipo Atto Amm '||tipoAttoAmmCode||'.';
   		-- siac_d_atto_amm_tipo --- se SPR creare numero provvedimento

       	--select coalesce(tipoAtto.attoamm_tipo_id,0)  into strict attoAmmTipoId
       	select tipoAtto.attoamm_tipo_id  into strict attoAmmTipoId
        from siac_d_atto_amm_tipo tipoAtto
        where tipoAtto.ente_proprietario_id=enteProprietarioId and
              tipoAtto.attoamm_tipo_code=tipoAttoAmmCode and
              tipoAtto.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoAtto.validita_inizio) and
			  (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoAtto.validita_fine)
		            or tipoAtto.validita_fine is null);

	    exception
    	  	when no_data_found then
    	      RAISE EXCEPTION 'Errore tipo atto amministrativo non esistente.';
	      	when others  THEN
    	      RAISE EXCEPTION 'Errore in lettura : %-%.',
            		SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
    end;

	-- Lettura Struttura Amministrativa di Primo Livello CDR
    if coalesce(strPrimoLivAttoAmm,NVL_STR)!=NVL_STR then
       	-- siac_r_atto_amm_class -- atto, struttura
	    --  siac_t_class, siac_d_class_tipo=CDR
      	strToElab:=strPrimoLivAttoAmm;
		/*cdrAttoAmmCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
        cdrAttoAmmKey:=substring(strToElab from
 				                 position(SEPARATORE in strToElab)+2
				                 for char_length(strToElab)-position(SEPARATORE in strToElab)); 05.10.2015 Sofia */
        -- 05.10.2015 Sofia
        cdrAttoAmmCode:=split_part(strToElab,SEPARATORE,1);
        cdrAttoAmmKey:=split_part(strToElab,SEPARATORE,2);


		strMessaggio:='Lettura tipo Struttura Amm Cdr '||cdrAttoAmmCode||'.';
       -- raise notice '%',strMessaggio;
   	    begin
       		--select coalesce(classCdr.classif_id,0) into  strict classCdrId
       		select classCdr.classif_id into  strict classCdrId
           	from siac_t_class classCdr, siac_d_class_tipo classTipoCdr
            where classCdr.ente_proprietario_id=enteProprietarioId and
   	              classCdr.classif_code=cdrAttoAmmCode and
-- 27.10.2015 Dani, eliminato filtro su periodo validita
--                  classCdr.data_cancellazione is null and
--                  date_trunc('day',dataElaborazione)>=date_trunc('day',classCdr.validita_inizio) and
--		 		  (date_trunc('day',dataElaborazione)<=date_trunc('day',classCdr.validita_fine)
--		            or classCdr.validita_fine is null) and
                  classTipoCdr.classif_tipo_id=classCdr.classif_tipo_id and
                  classTipoCdr.classif_tipo_code=CDR and
                  classTipoCdr.ente_proprietario_id=enteProprietarioId;

		--	raise notice 'CDR_ID %',classCdrId;
	        exception
    	    	when no_data_found then
                      -- 05.10.2015 Sofia - CTMO ha i provvedimenti collegati a servizi equivalenti a CDC
                     begin
                     	strMessaggio:='Lettura tipo Struttura Amm Cdc '||cdrAttoAmmCode||'.';
                     	select classCdr.classif_id into  strict classCdrId
			           	from siac_t_class classCdr, siac_d_class_tipo classTipoCdr
			            where classCdr.ente_proprietario_id=enteProprietarioId and
   	        			      classCdr.classif_code=cdrAttoAmmCode and
-- 27.10.2015 Dani, eliminato filtro su periodo validita
--			                  classCdr.data_cancellazione is null and
--			                  date_trunc('day',dataElaborazione)>=date_trunc('day',classCdr.validita_inizio) and
--		 					  (date_trunc('day',dataElaborazione)<=date_trunc('day',classCdr.validita_fine)
--					            or classCdr.validita_fine is null) and
			                  classTipoCdr.classif_tipo_id=classCdr.classif_tipo_id and
			                  classTipoCdr.classif_tipo_code=CDC and
			                  classTipoCdr.ente_proprietario_id=enteProprietarioId;
                        exception
			    	    	when no_data_found then
                            	RAISE EXCEPTION 'Errore Struttura non esistente.';
                            when others  THEN
				    	         RAISE EXCEPTION 'Errore  in lettura : %-%.',
    			   		    		SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
                     end;
    		         --RAISE EXCEPTION 'Errore Struttura non esistente.';
	       		when others  THEN
	    	         RAISE EXCEPTION 'Errore  in lettura : %-%.',
       		    		SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
   		end;
	end if;

/* ---------------------------------------------------------------------- 14.10.2015 spostato in fnc_migr_leggi_attoamm --------------------------------------------------------------------

    --  siac_t_atto_amm
    begin
    	strMessaggio:='Lettura Atto Amm '||tipoAttoAmmKey||' .';

        if tipoAttoAmmCode=SPR and coalesce( numeroAttoAmm,0)=0 THEN
        	  numeroAttoAmmLoc:=NUMERO_ATTO_INTERNO;
        else  numeroAttoAmmLoc:=numeroAttoAmm;
        end if;


		if classCdrId!=0 and coalesce(cdrAttoAmmKey,NK_STR)='K' then
        	select coalesce(attoAmm.attoamm_id,0) attoamm_id into strict attoAmmRec
--                   coalesce( attoAmm.attoamm_tipo_id ,0) attoamm_tipo_id  29.09.015 SofiaDaniela
         	     --  attoAmmStato.attoamm_stato_code into strict attoAmmRec
            from siac_t_atto_amm attoAmm, siac_r_atto_amm_stato attoAmmStatoRel,
           	     siac_d_atto_amm_stato attoAmmStato, siac_r_atto_amm_class attoAmmCdrRel
            where
              -- 13.03.2015 daniela:
              -- necessario controllo su login_operazione perchè lato web non c'è alcun controllo in fase di inserimento della presenza dell'atto per medesimi anno, nro
--                  attoAmm.login_operazione = loginOperazione and -- 29.09.015 SofiaDaniela aggiunto perchè il 10.03 in questo ramo if non c'era
				  attoamm.login_operazione like 'migr_%' -- 14.10.2015 recuperare il record se inserito da utente di migrazione
				  attoAmm.ente_proprietario_id=enteProprietarioId and
                  attoAmm.attoamm_anno=	annoAttoAmm and
                  attoAmm.attoamm_numero= numeroAttoAmmLoc and
                  attoAmm.attoamm_tipo_id=attoAmmTipoId and -- 29.09.015 Sofia-Dani se il CDR è in chiave è in chiave anche il tipo quindi si ricerca anche per tipo
                  attoAmm.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio) and
   			     (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
		            or attoAmm.validita_fine is null) and
                 attoAmmStatoRel.attoamm_id=attoAmm.attoamm_id and
                 attoAmmStato.attoamm_stato_id=attoAmmStatoRel.attoamm_stato_id and
                 attoAmmStatoRel.ente_proprietario_id=enteProprietarioId and
                 attoAmmStatoRel.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmmStatoRel.validita_inizio) and
			     (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmmStatoRel.validita_fine)
		            or attoAmmStatoRel.validita_fine is null) and
                 attoAmmCdrRel.ente_proprietario_id=enteProprietarioId and
            	 attoAmmCdrRel.attoamm_id=attoAmm.attoamm_id and
                 attoAmmCdrRel.classif_id=classCdrId and
                 attoAmmCdrRel.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmmCdrRel.validita_inizio) and
		 		(date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmmCdrRel.validita_fine)
				 or attoAmmCdrRel.validita_fine is null);
        elseif coalesce(tipoAttoAmmKey,NK_STR)='K' then
/*        	select coalesce(attoAmm.attoamm_id,0) attoamm_id,
         	       attoAmmStato.attoamm_stato_code  into strict attoAmmRec
            from siac_t_atto_amm attoAmm, siac_r_atto_amm_stato attoAmmStatoRel,
           	     siac_d_atto_amm_stato attoAmmStato, siac_d_atto_amm_tipo attoAmmTipo
            where
            	-- 13.03.2015 daniela:
                -- necessario controllo su login_operazione perchè lato web non c'è alcun controllo in fase di inserimento della presenza dell'atto per medesimi anno, nro
	              attoAmm.login_operazione = loginOperazione and
                  attoAmm.ente_proprietario_id=enteProprietarioId and
                  attoAmm.attoamm_anno=	annoAttoAmm and
                  attoAmm.attoamm_numero= numeroAttoAmmLoc and
                  attoAmm.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio) and
   			     (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
		            or attoAmm.validita_fine is null) and
                 attoAmmTipo.attoamm_tipo_id=attoAmm.attoamm_tipo_id and
                 attoAmmTipo.attoamm_tipo_code=tipoAttoAmmCode and
                 attoAmmTipo.ente_proprietario_id=enteProprietarioId and
                 attoAmmStatoRel.attoamm_id=attoAmm.attoamm_id and
                 attoAmmStato.attoamm_stato_id=attoAmmStatoRel.attoamm_stato_id and
                 attoAmmStatoRel.ente_proprietario_id=enteProprietarioId and
                 attoAmmStatoRel.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmmStatoRel.validita_inizio) and
			     (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmmStatoRel.validita_fine)
		            or attoAmmStatoRel.validita_fine is null); 29.09.015 SofiaDaniela */
			select coalesce(attoAmm.attoamm_id,0) attoamm_id into strict attoAmmRec
--		           attoAmmStato.attoamm_stato_code  into strict attoAmmRec 29.09.015 SofiaDaniela
            from siac_t_atto_amm attoAmm, siac_r_atto_amm_stato attoAmmStatoRel,
           	     siac_d_atto_amm_stato attoAmmStato
            where
            	-- 13.03.2015 daniela:
                -- necessario controllo su login_operazione perchè lato web non c'è alcun controllo in fase di inserimento della presenza dell'atto per medesimi anno, nro
--	              attoAmm.login_operazione = loginOperazione and
				  attoamm.login_operazione like 'migr_%' -- 14.10.2015 recuperare il record se inserito da utente di migrazione
                  attoAmm.ente_proprietario_id=enteProprietarioId and
                  attoAmm.attoamm_anno=	annoAttoAmm and
                  attoAmm.attoamm_numero= numeroAttoAmmLoc and
                  attoAmm.attoamm_tipo_id=attoAmmTipoId and
                  attoAmm.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio) and
   			     (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
		            or attoAmm.validita_fine is null) and
                 attoAmmStatoRel.attoamm_id=attoAmm.attoamm_id and
                 attoAmmStato.attoamm_stato_id=attoAmmStatoRel.attoamm_stato_id and
                 attoAmmStatoRel.ente_proprietario_id=enteProprietarioId and
                 attoAmmStatoRel.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmmStatoRel.validita_inizio) and
			     (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmmStatoRel.validita_fine)
		            or attoAmmStatoRel.validita_fine is null);
        else
	        select coalesce(attoAmm.attoamm_id,0) attoamm_id into strict attoAmmRec
--                   coalesce( attoAmm.attoamm_tipo_id ,0) attoamm_tipo_id, 29.09.015 SofiaDaniela
  --       	       attoAmmStato.attoamm_stato_code  into strict attoAmmRec
            from siac_t_atto_amm attoAmm, siac_r_atto_amm_stato attoAmmStatoRel,
           	     siac_d_atto_amm_stato attoAmmStato
            where
            	-- 13.03.2015 daniela:
                -- necessario controllo su login_operazione perchè lato web non c'è alcun controllo in fase di inserimento della presenza dell'atto per medesimi anno, nro
--	              attoAmm.login_operazione = loginOperazione and
				  attoamm.login_operazione like 'migr_%' -- 14.10.2015 recuperare il record se inserito da utente di migrazione
            	  attoAmm.ente_proprietario_id=enteProprietarioId and
                  attoAmm.attoamm_anno=	annoAttoAmm and
                  attoAmm.attoamm_numero= numeroAttoAmmLoc and
                  attoAmm.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmm.validita_inizio) and
   			     (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmm.validita_fine)
		            or attoAmm.validita_fine is null) and
                 attoAmmStatoRel.attoamm_id=attoAmm.attoamm_id and
                 attoAmmStato.attoamm_stato_id=attoAmmStatoRel.attoamm_stato_id and
                 attoAmmStatoRel.ente_proprietario_id=enteProprietarioId and
                 attoAmmStatoRel.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmmStatoRel.validita_inizio) and
			     (date_trunc('day',dataElaborazione)<=date_trunc('day',attoAmmStatoRel.validita_fine)
		            or attoAmmStatoRel.validita_fine is null);
		end if;
		 -- if attoAmmRec.attoamm_stato_code!=statoAttoAmm then
         -- 	RAISE EXCEPTION 'Errore Atto Amm esistente in stato diverso.';
         -- end if;

          attoAmmId:=attoAmmRec.attoamm_id;

		  --raise notice 'attoAmmId % ',attoAmmId;
          -- controllare il tipo
         -- if attoammTipoId!=attoAmmRec.attoamm_tipo_id then
	  --    	if coalesce(tipoAttoAmmKey,NK_STR)='K' then
        --    	insAttoAmm:=TRUE;
      --      else
	   --       RAISE EXCEPTION 'Atto Amm esistente collegato ad un altro tipo.';
    --	    end if;
    --      end if;

--          raise notice 'cdrAttoAmmKey %', cdrAttoAmmKey;
          -- controllare legame con struttura
        --  if classCdrId!=0 and coalesce(cdrAttoAmmKey,NK_STR)='K' then
 --            	begin
  --              	strMessaggio:='Lettura legame con Struttura Amm Cdr'||cdrAttoAmmCode||'.';

  --                  raise notice '%', strMessaggio;

 --                 	select coalesce ( attoAmmCdrRel.atto_amm_class_id,0)
 --                            into strict attoAmmCdrRelId
 --                   from siac_r_atto_amm_class attoAmmCdrRel
 --                   where attoAmmCdrRel.ente_proprietario_id=enteProprietarioId and
  --                    	  attoAmmCdrRel.attoamm_id=attoAmmId and
  --                        attoAmmCdrRel.classif_id=classCdrId and
  ----                        attoAmmCdrRel.data_cancellazione is null and
  --                        date_trunc('day',dataElaborazione)>=date_trunc('day',attoAmmCdrRel.validita_inizio) and
	--	 		  		  (date_trunc('day',dataElaborazione)<date_trunc('day',attoAmmCdrRel.validita_fine)
	--			            or attoAmmCdrRel.validita_fine is null);

      --              raise notice 'attoAmmCdrRelId %',attoAmmCdrRelId;
      --              exception
		--   		    	when no_data_found then
               		     --- atto da inserire
        --                 insAttoAmm:=TRUE;
		--           		when others  THEN
		--	   	         RAISE EXCEPTION 'Errore in lettura : %-%.',
        --    				SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
        --         end;
       --   end if;


     exception
    	when no_data_found then
             --- atto da inserire
             insAttoAmm:=TRUE;
        when too_many_rows then
             RAISE EXCEPTION 'Chiave non univoca [diversi atti gia'' presenti].';
	    when others  THEN
		        RAISE EXCEPTION 'Errore  in lettura : %-%.',
        				SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

    end;
----------------------------------------------------------------------------------------------------------------------------------------------------------------*/

   Select aaLetto.id, aaLetto.codiceRisultato,aaLetto.messaggioRisultato
   into attoAmmId, codRet, strMessaggio
   from fnc_migr_leggi_attoamm (annoattoamm,numeroattoamm,tipoattamm,strprimolivattoamm,enteproprietarioid,loginoperazione,dataelaborazione) aaLetto;

   if codRet != 0 then
   		RAISE EXCEPTION 'fnc_migr_leggi_attoamm : % ', strMessaggio;
   end if;
   if attoAmmId = 0 then insAttoAmm:=TRUE; end if;

    -- inserimento atto amm e relazioni
	if insAttoAmm=TRUE then
    	strMessaggio:='Inserimento Atto Amm [siac_t_atto_amm].';

       if tipoAttoAmmCode=SPR and coalesce( numeroAttoAmm,0)=0 THEN
       	  numeroAttoAmmLoc:=NUMERO_ATTO_INTERNO;
       else  numeroAttoAmmLoc:=numeroAttoAmm;
       end if;

        insert into siac_t_atto_amm
        (attoamm_anno,attoamm_numero,attoamm_oggetto, attoamm_note,
		 attoamm_tipo_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione)
        values
        (annoAttoAmm,numeroAttoAmmLoc,substring(oggettoAttoAmm from 1 for LENGTH_STR),
         substring(noteAttoAmm from 1 for LENGTH_STR),attoAmmTipoId,
         datainizioval,enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione)
        returning attoamm_id into  attoAmmId;

    	if statoAttoAmm=STATO_D THEN
        	 statoAttoAmmaSiac:=DEFINITIVO;
        ELSE statoAttoAmmaSiac:=PROVVISORIO;
        end if;

        strMessaggio:='Inserimento Atto Amm Rel Stato [siac_r_atto_amm_stato].';
        insert into siac_r_atto_amm_stato
        (attoamm_id,attoamm_stato_id,ente_proprietario_id,validita_inizio,data_creazione,login_operazione)
        (select attoAmmId,statoAtto.attoamm_stato_id, enteProprietarioId,datainizioval,CLOCK_TIMESTAMP(),loginOperazione
         from siac_d_atto_amm_stato statoAtto
         where statoAtto.ente_proprietario_id = enteProprietarioId and
               statoAtto.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',statoAtto.validita_inizio) and
	  		   (date_trunc('day',dataElaborazione)<=date_trunc('day',statoAtto.validita_fine)
			           or statoAtto.validita_fine is null) and
               statoAtto.attoamm_stato_code=statoAttoAmmaSiac
        );

        if classCdrId!=0 then
            strMessaggio:='Inserimento Atto Amm Rel Struttura Amm [siac_r_atto_amm_class].';
        	insert into siac_r_atto_amm_class
            (attoamm_id,classif_id,ente_proprietario_id,validita_inizio,data_creazione,login_operazione )
            values
            (attoAmmId,classCdrId,enteProprietarioId,datainizioval,CLOCK_TIMESTAMP(),loginOperazione);
        end if;
    else  raise notice 'ATTO ESISTENTE';
    end if;

   if coalesce ( movgestTsId,0) !=0 then
     -- siac_r_movgest_ts_atto_amm relazione tra atto e movgest_st
     strMessaggio:='Inserimento Atto Amm Rel movimento gestione '||movgestTsId||'.';
    INSERT INTO siac_r_movgest_ts_atto_amm
    ( movgest_ts_id, attoamm_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione
    )
    values
    (movgestTsId, attoAmmId,datainizioval,enteProprietarioId,CLOCK_TIMESTAMP(),loginOperazione);
   end if;



   codiceRisultato:= codRet;
   if insAttoAmm=TRUE then
	   messaggioRisultato:=strMessaggioFinale||'Inserito Atto Amm e inserita relazione con movgest_ts.';
   else
	   messaggioRisultato:=strMessaggioFinale||'Inserita relazione movgest_ts AttoAmm.';
   end if;

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=
        	quote_nullable(strMessaggioFinale)||quote_nullable(strMessaggio)||'ERRORE:  '||' '||quote_nullable(substring(upper(SQLERRM) from 1 for 500)) ;
        codiceRisultato:=-1;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;