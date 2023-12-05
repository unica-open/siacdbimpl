/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_attilegge_entrata (enteProprietarioId integer,
                                                      annoBilancio in VARCHAR,
                                                      bilElemTipo in varchar,
  											          loginOperazione varchar,
										              dataElaborazione timestamp,
											          out numeroElementiInseriti integer,
											          out messaggioRisultato varchar
											          )
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_attilegge_entrata --> function che effettua il caricamento dei atti di legge
    --                                relazionandoli ai capitoli di entrata
    -- leggendo in tab migr_attilegge_entrata
    -- verifica esistenza del capitolo di entrata
    -- verifica esistenza di un atto di legge nel caso in cui non esista lo inserisce
       -- siac_t_atto_legge
       -- siac_r_atto_legge_stato
    -- effettua inserimento di
     -- siac_r_bil_elem_attilegge --> relazione tra capitolo di entrata e atto di legge
    -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numeroElementiInseriti valorizzato con
        -- -12 dati da migrare non presenti in migr_attilegge_entrata
        -- -1 errore
        -- N=numero relazioni  inserite

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';


	migrAttiLeggeCap  record;


    countMigrAttiLeggeCap integer:=0;

	numInseriti   integer:=0;
    attoLeggeId   integer:=0;
    elemId   integer:=0;
	attoLeggeBilElemId integer:=0;
    bilancioId   integer:=0;

	dataInizioVal timestamp:=null;
	attoLeggeStatoId integer:=0;
    elemTipoId integer:=0;

	--    costanti
	NVL_STR             CONSTANT VARCHAR:='';
    SEPARATORE			CONSTANT  varchar :='||';

	ST_DEFINITIVO       CONSTANT VARCHAR:='DEFINITIVO';
BEGIN

    numeroElementiInseriti:=0;
    messaggioRisultato:='';

	--dataInizioVal:=annoBilancio||'-01-01';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione atti legge entrata.';
    strMessaggio:='Lettura atti legge entrata migrati.';

	select COALESCE(count(*),0) into countMigrAttiLeggeCap
    from migr_attilegge_entrata ms
     where ms.ente_proprietario_id=enteProprietarioId and
           ms.anno_esercizio=annoBilancio and
           ms.tipo_capitolo=bilElemTipo and
           ms.fl_elab='N';

	if COALESCE(countMigrAttiLeggeCap,0)=0 then
         messaggioRisultato:=strMessaggioFinale||'Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
         numeroElementiInseriti:=-12;
         return;
    end if;

	-- Modifica 21/10/2014. Recupero dell'id bilancio da tabella anziche da parametro in input
    begin
      select b.bil_id into strict bilancioid
      from siac_t_bil b
      join siac_t_periodo p on (b.periodo_id=p.periodo_id
          and b.ente_proprietario_id = p.ente_proprietario_id
          and p.anno = annobilancio)
      where b.ente_proprietario_id = enteproprietarioid
      and b.validita_fine is null;
	exception
      when NO_DATA_FOUND THEN
         messaggioRisultato:=strMessaggioFinale||'Id bilancio non recueprato per ente '||enteProprietarioId||', anno '||annobilancio||'.';
         numeroElementiInseriti:=-13;
         return;
      when TOO_MANY_ROWS THEN
         messaggioRisultato:=strMessaggioFinale||'Impossibile identificare id bilancio, troppi valori per ente '||enteProprietarioId||', anno '||annobilancio||'.';
         numeroElementiInseriti:=-13;
         return;
    end;
    -- Fine modifica


	begin
    	strMessaggio:='Lettura identificativo atto legge stato='||ST_DEFINITIVO;
		select stato.attolegge_stato_id into strict attoLeggeStatoId
        from siac_d_atto_legge_stato stato
        where stato.ente_proprietario_id=enteProprietarioId and
              stato.attolegge_stato_code=ST_DEFINITIVO and
              stato.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio) and
	          date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(stato.validita_fine,statement_timestamp()));


		strMessaggio:='Lettura identificativo bil elem tipo='||bilElemTipo;
		select tipocap.elem_tipo_id into strict elemTipoId
        from siac_d_bil_elem_tipo tipocap
        where tipoCap.ente_proprietario_id=enteProprietarioId and
        	  tipoCap.elem_tipo_code=bilElemTipo and
              tipoCap.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoCap.validita_inizio) and
	          date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipoCap.validita_fine,statement_timestamp()));

        exception
      		when NO_DATA_FOUND THEN
       	 		RAISE EXCEPTION 'Inesistente.';
            when others then
           		RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;

    for migrAttiLeggeCap IN
    (select ms.*
     from migr_attilegge_entrata ms
     where ms.ente_proprietario_id=enteProprietarioId and
           ms.anno_esercizio=annoBilancio and
           ms.tipo_capitolo=bilElemTipo and
           ms.fl_elab='N'
     order by ms.migr_attilegge_ent_id)
    loop

        begin
        	strMessaggio:='Lettura capitolo per migr_attilegge_ent_id='||migrAttiLeggeCap.migr_attilegge_ent_id||'.';
        	select coalesce(capitolo.elem_id) into strict elemId
            from siac_t_bil_elem capitolo--,
--                 siac_d_bil_elem_tipo tipoCap
            where capitolo.ente_proprietario_id=enteProprietarioId and
                  capitolo.bil_id=bilancioId and
--                  capitolo.elem_code=rtrim(ltrim(to_char(migrAttiLeggeCap.numero_capitolo,'999999'))) and
                  capitolo.elem_code=migrAttiLeggeCap.numero_capitolo::varchar and
--                  capitolo.elem_code2=rtrim(ltrim(to_char(migrAttiLeggeCap.numero_articolo,'999999'))) and
                  capitolo.elem_code2=migrAttiLeggeCap.numero_articolo::varchar and
                  capitolo.elem_code3='1' and
                  capitolo.elem_tipo_id=elemTipoId and
                  capitolo.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',capitolo.validita_inizio) and
	              date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(capitolo.validita_fine,statement_timestamp()));
--                  tipoCap.elem_tipo_id=capitolo.elem_tipo_id and
--                  tipoCap.ente_proprietario_id=enteProprietarioId and
--                  tipoCap.elem_tipo_code=bilElemTipo;
		   exception
	           when no_data_found then
    	       	 RAISE EXCEPTION 'Inesistente.';
	           when others  THEN
    	         RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);

        end;

		begin
         -- anno, numero, articolo, tipo,comma , punto
		 strMessaggio:='Lettura atto Legge migr_attilegge_ent_id='||migrAttiLeggeCap.migr_attilegge_ent_id||'.';

         select coalesce(attoLegge.attolegge_id) into strict attoLeggeId
         from siac_t_atto_legge  attoLegge,
              siac_d_atto_legge_tipo attoTipo
         where attoLegge.ente_proprietario_id=enteProprietarioId and
               attoLegge.attolegge_anno=migrAttiLeggeCap.anno_legge and
               attoLegge.attolegge_numero=(migrAttiLeggeCap.nro_legge::numeric) and
               attoLegge.attolegge_articolo=migrAttiLeggeCap.articolo and
               attoLegge.attolegge_punto=migrAttiLeggeCap.punto and
               attoLegge.attolegge_comma=migrAttiLeggeCap.comma and
               attoLegge.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',attoLegge.validita_inizio) and
               date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attoLegge.validita_fine,statement_timestamp())) and
               attoTipo.attolegge_tipo_id=attoLegge.attolegge_tipo_id and
--               attoTipo.ente_proprietario_id=enteProprietarioId and
               attoTipo.attolegge_tipo_code=migrAttiLeggeCap.tipo_legge and
			   attoTipo.data_cancellazione is null and
               date_trunc('day',dataElaborazione)>=date_trunc('day',attoTipo.validita_inizio) and
               date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(attoTipo.validita_fine,statement_timestamp()));

          exception
        	when no_data_found then
	        strMessaggio:='Inserimento atto Legge migr_attilegge_ent_id='||migrAttiLeggeCap.migr_attilegge_ent_id||'.';

            insert into siac_t_atto_legge
            (attolegge_anno,attolegge_numero,attolegge_articolo,attolegge_comma,
             attolegge_punto,attolegge_tipo_id,validita_inizio,
		     ente_proprietario_id,data_creazione,login_operazione)
    	    (select migrAttiLeggeCap.anno_legge,migrAttiLeggeCap.nro_legge::numeric,
                    migrAttiLeggeCap.articolo,migrAttiLeggeCap.comma,migrAttiLeggeCap.punto,tipoAttoLegge.attolegge_tipo_id,
        	        dataInizioVal,enteProprietarioId,statement_timestamp(),loginOperazione
             from siac_d_atto_legge_tipo  tipoAttoLegge
             where tipoAttoLegge.ente_proprietario_id=enteProprietarioId and
                   tipoAttoLegge.attolegge_tipo_code=migrAttiLeggeCap.tipo_legge and
                   tipoAttoLegge.data_cancellazione is null and
                   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoAttoLegge.validita_inizio) and
		 	       date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipoAttoLegge.validita_fine,statement_timestamp()))
            )
            returning attolegge_id into attoLeggeId;

	        strMessaggio:='Inserimento atto Legge stato migr_attilegge_ent_id='||migrAttiLeggeCap.migr_attilegge_ent_id||'.';
            insert into siac_r_atto_legge_stato
            (attolegge_id,attolegge_stato_id,validita_inizio,data_creazione,
             login_operazione,ente_proprietario_id)
             values
            (attoLeggeId,attoLeggeStatoId,dataInizioVal,statement_timestamp(),
             loginOperazione,enteProprietarioId);

--            (select attoLeggeId,stato.attolegge_stato_id,statement_timestamp(),statement_timestamp(),
--	                 loginOperazione,enteProprietarioId
--             from siac_d_atto_legge_stato stato
--             where stato.ente_proprietario_id=enteProprietarioId and
--                   stato.attolegge_stato_code=ST_DEFINITIVO and
--                   stato.data_cancellazione is null and
--                   date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio) and
--		 	       (date_trunc('day',dataElaborazione)<date_trunc('day',stato.validita_fine)
--			            or stato.validita_fine is null));
           	when others  THEN
             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
		end;


        strMessaggio:='Inserimento siac_r_bil_elem_atto_legge per migr_attilegge_ent_id= '
                               ||migrAttiLeggeCap.migr_attilegge_ent_id||'.';
	    insert into siac_r_bil_elem_atto_legge
	    (attolegge_id,elem_id,gerarchia,validita_inizio,data_creazione,ente_proprietario_id,login_operazione)
	    values
	    (attoleggeId, elemId,migrAttiLeggeCap.gerarchia,dataInizioVal,statement_timestamp(),enteProprietarioId,loginOperazione)
        returning attolegge_bil_elem_id into attoLeggeBilElemId;


      	 strMessaggio:='Inserimento siac_r_migr_attilegge_ent per migr_attilegge_ent_id= '
                               ||migrAttiLeggeCap.migr_attilegge_ent_id||'.';

		 insert into  siac_r_migr_attilegge_ent
         (migr_attilegge_ent_id,attolegge_bil_elem_id,
		  tipo_bil_elem,data_creazione,ente_proprietario_id)
         values
         (migrAttiLeggeCap.migr_attilegge_ent_id,attoLeggeBilElemId,
          migrAttiLeggeCap.tipo_capitolo,statement_timestamp(),enteProprietarioId);

         numInseriti:=numInseriti+1;
    end loop;

	--21.102.2015 dani
     update migr_attilegge_entrata ms
     set fl_elab = 'S'
     where ms.ente_proprietario_id=enteProprietarioId and
           ms.anno_esercizio=annoBilancio and
           ms.tipo_capitolo=bilElemTipo and
           ms.fl_elab='N';



   messaggioRisultato:=strMessaggioFinale||'Inseriti '||numInseriti||' atti legge cap. entrata .';
   numeroElementiInseriti:=numInseriti;
   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroElementiInseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroElementiInseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
