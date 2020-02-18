/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_leggi_attoamm (
  annoattoamm varchar,
  numeroattoamm integer,
  tipoattamm varchar,
  strprimolivattoamm varchar,
--  oggettoattoamm varchar,
--  noteattoamm varchar,
--  statoattoamm varchar,
  enteproprietarioid integer,
  loginoperazione varchar, -- si potrebbe anche togliere
  dataelaborazione timestamp,
--  datainizioval timestamp,
  out id integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
 -- da chiarire
  -- numerazione per ATTO SPR
  -- come controllare lo stato operativo di AttoAmministrativo che in contabilia dovrebbe
  -- guidare sullo stato del movimento di gestione
 -- fnc_migr_attoamm -- riceve gli estremi di un atto amministrativo
 -- verifica esistenza Atto Amministrativo
  -- se esiste restituisce l'id già presente
  -- se non esiste lo inserisce e restituisce l'id
 -- restitusce
   -- messaggioRisultato=risultato in formato testo
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)


 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 tipoAttoAmmCode varchar(500):='';
 tipoAttoAmmKey  varchar(10):='';
 cdrAttoAmmCode varchar(500):='';
 cdrAttoAmmKey  varchar(10):='';

 strToElab VARCHAR(1500):='';

 attoAmmRec record;

 attoAmmTipoId integer:=0;
 classCdrId integer:=0;
 attoAmmCdrRelId integer:=0;
 numeroAttoAmmLoc integer:=0;

 NK_STR              CONSTANT VARCHAR:='NK';
 NVL_STR             CONSTANT VARCHAR:='';
 SEPARATORE			 CONSTANT  varchar :='||';
 CDR CONSTANT  varchar :='CDR';
 CDC CONSTANT  varchar :='CDC';

 NUMERO_ATTO_INTERNO CONSTANT integer:=9999999;

 SPR CONSTANT varchar:='SPR';

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

	strMessaggioFinale:='Lettura AttoAmm  '||annoAttoAmm||'/'||coalesce(numeroAttoAmm,0)||'/'||quote_nullable(tipoAttAmm)||' Sac '||quote_nullable(strPrimoLivAttoAmm)||'.';

    begin
      	strToElab:=tipoAttAmm;
		tipoAttoAmmCode:=split_part(strToElab,SEPARATORE,1);
        tipoAttoAmmKey:=split_part(strToElab,SEPARATORE,2);

		strMessaggio:='Lettura tipo Atto Amm '||tipoAttoAmmCode||'.';

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
		cdrAttoAmmCode:=split_part(strToElab,SEPARATORE,1);
        cdrAttoAmmKey:=split_part(strToElab,SEPARATORE,2);

		strMessaggio:='Lettura tipo Struttura Amm Cdr '||cdrAttoAmmCode||'.';
   	    begin
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
                     -- RAISE EXCEPTION 'Errore Struttura non esistente.';
	       		when others  THEN
	    	         RAISE EXCEPTION 'Errore  in lettura : %-%.',
       		    		SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
   		end;
	end if;

    --  siac_t_atto_amm
    begin
    	strMessaggio:='Lettura Atto Amm '||tipoAttoAmmKey||' .';
        if tipoAttoAmmCode=SPR and coalesce( numeroAttoAmm,0)=0 THEN
        	  numeroAttoAmmLoc:=NUMERO_ATTO_INTERNO;
        else  numeroAttoAmmLoc:=numeroAttoAmm;
        end if;

		if classCdrId!=0 and coalesce(cdrAttoAmmKey,NK_STR)='K' then
            strMessaggio:='SELECT 1: [annoAttoAmm]['||annoAttoAmm||'][numeroAttoAmmLoc]['||numeroAttoAmmLoc||'][dataElaborazione]['||dataElaborazione||'][classCdrId]['||classCdrId||'].';
        	select coalesce(attoAmm.attoamm_id,0) attoamm_id into strict attoAmmRec
--                   coalesce( attoAmm.attoamm_tipo_id ,0) attoamm_tipo_id, 29.09.015 SofiaDaniela
--         	       attoAmmStato.attoamm_stato_code into strict attoAmmRec
            from siac_t_atto_amm attoAmm, siac_r_atto_amm_stato attoAmmStatoRel,
           	     siac_d_atto_amm_stato attoAmmStato, siac_r_atto_amm_class attoAmmCdrRel
            where
              -- 13.03.2015 daniela:
              -- necessario controllo su login_operazione perchè lato web non c'è alcun controllo in fase di inserimento della presenza dell'atto per medesimi anno, nro
--              	  attoAmm.login_operazione = loginOperazione and -- 29.09.015 SofiaDaniela aggiunto perchè il 10.03 in questo ramo if non c'era
				  attoamm.login_operazione like 'migr_%' and -- 14.10.2015 recuperare il record se inserito da utente di migrazione
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
            strMessaggio:='SELECT 2:[loginOperazione]['||loginOperazione||'][annoAttoAmm]['||annoAttoAmm||'][numeroAttoAmmLoc]['||numeroAttoAmmLoc||'][dataElaborazione]['||dataElaborazione||'][tipoAttoAmmCode]['||tipoAttoAmmCode||'].';
			select coalesce(attoAmm.attoamm_id,0) attoamm_id into strict attoAmmRec
--		           attoAmmStato.attoamm_stato_code  into strict attoAmmRec 29.09.015 SofiaDaniela
            from siac_t_atto_amm attoAmm, siac_r_atto_amm_stato attoAmmStatoRel,
           	     siac_d_atto_amm_stato attoAmmStato
            where
            	-- 13.03.2015 daniela:
                -- necessario controllo su login_operazione perchè lato web non c'è alcun controllo in fase di inserimento della presenza dell'atto per medesimi anno, nro
--	              attoAmm.login_operazione = loginOperazione and
				  attoamm.login_operazione like 'migr_%'  and -- 14.10.2015 recuperare il record se inserito da utente di migrazione
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
            strMessaggio:='SELECT 3:[loginOperazione]['||loginOperazione||'][annoAttoAmm]['||annoAttoAmm||'][numeroAttoAmmLoc]['||numeroAttoAmmLoc||'][dataElaborazione]['||dataElaborazione||'].';
	        select coalesce(attoAmm.attoamm_id,0) attoamm_id into strict attoAmmRec
--                   coalesce( attoAmm.attoamm_tipo_id ,0) attoamm_tipo_id, 29.09.015 SofiaDaniela
--         	       attoAmmStato.attoamm_stato_code  into strict attoAmmRec
            from siac_t_atto_amm attoAmm, siac_r_atto_amm_stato attoAmmStatoRel,
           	     siac_d_atto_amm_stato attoAmmStato
            where
            	-- 13.03.2015 daniela:
                -- necessario controllo su login_operazione perchè lato web non c'è alcun controllo in fase di inserimento della presenza dell'atto per medesimi anno, nro
--	              attoAmm.login_operazione = loginOperazione and
				  attoamm.login_operazione like 'migr_%'  and -- 14.10.2015 recuperare il record se inserito da utente di migrazione
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
        id:=attoAmmRec.attoamm_id;
     exception
    	when no_data_found then
             --- atto da inserire
             id:=0;
        when too_many_rows then
             RAISE EXCEPTION 'Chiave non univoca [diversi atti gia'' presenti].';
	    when others  THEN
		        RAISE EXCEPTION 'Errore  in lettura : %-%.',
        				SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

    end;

   if id=0 then
	   messaggioRisultato:=strMessaggioFinale||'Atto Amm Non Trovato.';
   else
	   messaggioRisultato:=strMessaggioFinale||'Atto Amm Trovato.';
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