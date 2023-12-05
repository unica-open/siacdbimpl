/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
/*DROP FUNCTION fnc_migr_vincolo_capitolo (enteProprietarioId integer,
										              --bilancioId integer,
                                                      annoBilancio in VARCHAR,
                                                      vincoloTipoBil in VARCHAR,
                                                      bilElemTipoUsc in varchar,
                                                      bilElemTipoEnt in varchar,
  											          loginOperazione varchar,
										              dataElaborazione timestamp,
											          out numeroElementiInseriti integer,
                                                      out numeroRelInserite integer,
											          out messaggioRisultato varchar
											          );*/
CREATE OR REPLACE FUNCTION fnc_migr_vincolo_capitolo (enteProprietarioId integer,
   														nomeEnte in VARCHAR,
										              --bilancioId integer,
                                                      annoBilancio in VARCHAR,
                                                      vincoloTipoBil in VARCHAR,
                                                      bilElemTipoUsc in varchar,
                                                      bilElemTipoEnt in varchar,
  											          loginOperazione varchar,
										              dataElaborazione timestamp,
											          out numeroElementiInseriti integer,
                                                      out numeroRelInserite integer,
											          out messaggioRisultato varchar
											          )
RETURNS record AS
$body$
DECLARE
    -- fnc_migr_vincolo_capitolo --> function che effettua il caricamento dei vincoli
    --                               relazionando ai capitoli di uscita e capitoli di entrata
    --                               per un tipo_vincolo
    -- leggendo in tab migr_vincolo_capitolo
    -- verifica esistenza del capitolo di uscita
    -- verifica esistenza del capitolo di entrata
    -- per ciascun vincolo_id in migr_vincolo_capitolo inserisce
       -- siac_t_vincolo
       -- siac_r_vincolo_stato
       -- siac_t_vincolo_tipo (P,G)
       -- verifica esistenza del tipo_vincolo
         -- se non esiste lo inserisce
         -- relaziona il siac_t_vincolo con il tipo_vincolo
       -- inserisce le relazioni con i capitoli di uscita e entrata
         -- siac_t_vincolo_bil_elem per capitolo_uscita
         -- siac_t_vincolo_bil_elem per capitolo_entrata
	   -- inserisce siac_r_migr_vincolo_capitolo
         -- relazione tra migr_vincolo_capitolo.vincolo_id e  siac_t_vincolo.vincolo_id
    -- richiama fnc_migr_classif per verificare esistenza del tipo_vincolo ed eventualmente inserirlo
    -- restituisce
     -- messaggioRisultato valorizzato con il risultato della elaborazione in formato testo
     -- numeroElementiInseriti (numero vincoli inseriti ) valorizzato con
        -- -12 dati da migrare non presenti in migr_vincolo_capitolo
        -- -1 errore
        -- N=numero relazioni  inserite
     -- numeroRelazioniInserite (numero di relazioni complessivi inserite tra vincoli e capitoli )
     	-- -1 errore
        -- N=numero relazioni  inserite

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';


	migrVincoloCap  record;


    countMigrVincoloCap integer:=0;

	numInseriti   integer:=0;
    numCapIns     integer:=0;

    elemIdUsc   integer:=0;
    elemIdEnt   integer:=0;
    vincoloId   INTEGER:=0;

    periodoId INTEGER:=0;
	elemTipoUscId INTEGER:=0;
    elemTipoEntId INTEGER:=0;
    vincoloStatoId INTEGER:=0;
    flTrasfVincolatiAttrId INTEGER:=0;
    noteVincoloAttrId INTEGER:=0;

    migrVincoloId   INTEGER:=0;
	vincoloGenereId       INTEGER:=0;
    classifCode varchar(250):='';
    classifDesc varchar(250):='';
    strToElab varchar(250):='';

    vincoloIdCode integer:=0;

    vincoloElemId integer:=0;
    bilancioId integer:=0;

    dataInizioVal timestamp:=null;
	--    costanti
	NVL_STR             CONSTANT VARCHAR:='';
    SEPARATORE			CONSTANT  varchar :='||';

	ST_VALIDO                CONSTANT VARCHAR:='V';
    CL_TIPO_VINCOLO          CONSTANT VARCHAR:='TIPO_VINCOLO';
    -- costanti attributi
    FL_TRASF_VINCOLATI_ATTR  CONSTANT VARCHAR := 'FlagTrasferimentiVincolati';
    NOTE_ATTR                CONSTANT VARCHAR :='Note';

--    C_ENTE_COTO				 CONSTANT  integer:=1;
    C_ENTE_COTO				 CONSTANT VARCHAR:='COTO';

BEGIN

    numeroElementiInseriti:=0;
    numeroRelInserite:=0;
    messaggioRisultato:='';

--    dataInizioVal:=annoBilancio||'-01-01';
    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione vincoli capitolo.';
    strMessaggio:='Lettura vincoli capitolo migrati.';

	select COALESCE(count(*),0) into countMigrVincoloCap
    from migr_vincolo_capitolo ms
     where ms.ente_proprietario_id=enteProprietarioId and
           ms.anno_esercizio=annoBilancio and
           ms.tipo_vincolo_bil=vincoloTipoBil and
           ms.fl_elab='N';

	if COALESCE(countMigrVincoloCap,0)=0 then
         messaggioRisultato:=strMessaggioFinale||'Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
         numeroElementiInseriti:=-12;
         return;
    end if;

     -- Modifica Sofia 10/10/2014. Recupero dell'id bilancio da tabella anziche da parametro in input
    begin
      select b.bil_id,b.periodo_id into strict bilancioid, periodoId
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
    	strMessaggio:='Lettura identificativo elemento bil tipo='||bilElemTipoUsc||'.';
		select tipoCap.elem_tipo_id into strict elemTipoUscId
    	from siac_d_bil_elem_tipo tipoCap
	    where tipoCap.ente_proprietario_id=enteProprietarioId and
		      tipoCap.elem_tipo_code=bilElemTipoUsc and
        	  tipoCap.data_cancellazione is null and
	          date_trunc('day',dataElaborazione)>=date_trunc('day',tipoCap.validita_inizio) and
    	      date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(tipoCap.validita_fine,statement_timestamp()));

        strMessaggio:='Lettura identificativo elemento bil tipo='||bilElemTipoEnt||'.';
		select tipoCap.elem_tipo_id into strict elemTipoEntId
    	from siac_d_bil_elem_tipo tipoCap
	    where tipoCap.ente_proprietario_id=enteProprietarioId and
		      tipoCap.elem_tipo_code=bilElemTipoEnt and
        	  tipoCap.data_cancellazione is null and
	          date_trunc('day',dataElaborazione)>=date_trunc('day',tipoCap.validita_inizio) and
    	      date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(tipoCap.validita_fine,statement_timestamp()));

        strMessaggio:='Lettura identificativo stato vincolo='||ST_VALIDO||'.';
        select stato.vincolo_stato_id into strict vincoloStatoId
        from siac_d_vincolo_stato stato
        where stato.ente_proprietario_id=enteProprietarioId and
              stato.vincolo_stato_code=ST_VALIDO and
              stato.data_cancellazione is null and
	          date_trunc('day',dataElaborazione)>=date_trunc('day',stato.validita_inizio) and
    	      date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(stato.validita_fine,statement_timestamp()));

        strMessaggio:='Lettura identificativo attributo vincolo='||FL_TRASF_VINCOLATI_ATTR||'.';
        select attr.attr_id into strict flTrasfVincolatiAttrId
        from siac_t_attr attr
             where attr.ente_proprietario_id=enteProprietarioId and
                   attr.attr_code=FL_TRASF_VINCOLATI_ATTR and
                   attr.data_cancellazione is null and
		           date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio) and
    		       date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(attr.validita_fine,statement_timestamp()));

        strMessaggio:='Lettura identificativo attributo vincolo='||NOTE_ATTR||'.';
        select attr.attr_id into strict noteVincoloAttrId
        from siac_t_attr attr
             where attr.ente_proprietario_id=enteProprietarioId and
                   attr.attr_code=NOTE_ATTR and
                   attr.data_cancellazione is null and
		           date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio) and
    		       date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(attr.validita_fine,statement_timestamp()));

		exception
	      when NO_DATA_FOUND THEN
    	     messaggioRisultato:=strMessaggioFinale||strMessaggio||'Dato non recueprato per ente '||enteProprietarioId||'.';
        	 numeroElementiInseriti:=-13;
	         return;
    	  when TOO_MANY_ROWS THEN
        	 messaggioRisultato:=strMessaggioFinale||'Impossibile identificare dato, troppi valori per ente '||enteProprietarioId||'.';
	         numeroElementiInseriti:=-13;
    	     return;
    end;

    for migrVincoloCap IN
    (select ms.*
     from migr_vincolo_capitolo ms
     where ms.ente_proprietario_id=enteProprietarioId and
           ms.anno_esercizio=annoBilancio and
           ms.tipo_vincolo_bil=vincoloTipoBil and
           ms.fl_elab='N'
     order by ms.vincolo_id)
    loop

        begin
        	strMessaggio:='Lettura capitolo per Uscita per migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||
                           'vincolo_cap_id='||migrVincoloCap.vincolo_cap_id||'.';
--            if enteProprietarioId!=C_ENTE_COTO then
            if nomeEnte!=C_ENTE_COTO then
 	        	select coalesce(capitolo.elem_id,0) into strict elemIdUsc
    	        from siac_t_bil_elem capitolo--,
--        	         siac_d_bil_elem_tipo tipoCap
            	where capitolo.ente_proprietario_id=enteProprietarioId and
                	  capitolo.bil_id=bilancioId and
--	                  capitolo.elem_code=rtrim(ltrim(to_char(migrVincoloCap.numero_capitolo_u,'999999'))) and
	                  capitolo.elem_code=migrVincoloCap.numero_capitolo_u::varchar and
--    	              capitolo.elem_code2=rtrim(ltrim(to_char(migrVincoloCap.numero_articolo_u,'999999'))) and
    	              capitolo.elem_code2=migrVincoloCap.numero_articolo_u::varchar and
        	          capitolo.elem_code3='1' and
                      capitolo.data_cancellazione is null and
			          date_trunc('day',dataElaborazione)>=date_trunc('day',capitolo.validita_inizio) and
    			      date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(capitolo.validita_fine,statement_timestamp())) and
                      capitolo.elem_tipo_id=elemTipoUscId;
--            	      tipoCap.elem_tipo_id=capitolo.elem_tipo_id and
--                      tipoCap.elem_tipo_id=bilElemTipoUsc;
--                	  tipoCap.ente_proprietario_id=enteProprietarioId and
--	                  tipoCap.elem_tipo_code=bilElemTipoUsc;
             else
	            select coalesce(min(capitolo.elem_id),0) into strict elemIdUsc
    	        from siac_t_bil_elem capitolo--,
--        	         siac_d_bil_elem_tipo tipoCap
            	where capitolo.ente_proprietario_id=enteProprietarioId and
                	  capitolo.bil_id=bilancioId and
--	                  capitolo.elem_code=rtrim(ltrim(to_char(migrVincoloCap.numero_capitolo_u,'999999'))) and
	                  capitolo.elem_code=migrVincoloCap.numero_capitolo_u::varchar and
--    	              capitolo.elem_code2=rtrim(ltrim(to_char(migrVincoloCap.numero_articolo_u,'999999'))) and
    	              capitolo.elem_code2=migrVincoloCap.numero_articolo_u::varchar and
--        	          capitolo.elem_code3='1' and
                      capitolo.data_cancellazione is null and
			          date_trunc('day',dataElaborazione)>=date_trunc('day',capitolo.validita_inizio) and
    			      date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(capitolo.validita_fine,statement_timestamp())) and
                      capitolo.elem_tipo_id=elemTipoUscId;
--            	      tipoCap.elem_tipo_id=capitolo.elem_tipo_id and
--                      tipoCap.elem_tipo_id=bilElemTipoUsc;
--                	  tipoCap.ente_proprietario_id=enteProprietarioId and
--	                  tipoCap.elem_tipo_code=bilElemTipoUsc;
             end if;
		   exception
	           when no_data_found then
    	       	 RAISE EXCEPTION 'Elemento Bil %/%/1 inesistente.',
                     migrVincoloCap.numero_capitolo_u,migrVincoloCap.numero_articolo_u;
	           when others  THEN
    	         RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

        end;

        begin
        	strMessaggio:='Lettura capitolo per Entrata per migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||
                           'vincolo_cap_id='||migrVincoloCap.vincolo_cap_id||'.';
--            if enteProprietarioId!=C_ENTE_COTO then
            if nomeEnte!=C_ENTE_COTO then
	        	select coalesce(capitolo.elem_id,0) into strict elemIdEnt
    	        from siac_t_bil_elem capitolo --,
--        	         siac_d_bil_elem_tipo tipoCap
	            where capitolo.ente_proprietario_id=enteProprietarioId and
    	              capitolo.bil_id=bilancioId and
--        	          capitolo.elem_code=ltrim(rtrim(to_char(migrVincoloCap.numero_capitolo_e,'999999'))) and
        	          capitolo.elem_code=migrVincoloCap.numero_capitolo_e::varchar and
--            	      capitolo.elem_code2=ltrim(rtrim(to_char(migrVincoloCap.numero_articolo_e,'999999'))) and
            	      capitolo.elem_code2=migrVincoloCap.numero_articolo_e::varchar and
                	  capitolo.elem_code3='1' and
                      capitolo.data_cancellazione is null and
			          date_trunc('day',dataElaborazione)>=date_trunc('day',capitolo.validita_inizio) and
    			      date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(capitolo.validita_fine,statement_timestamp())) and
                      capitolo.elem_tipo_id=elemTipoEntId;
--	                  tipoCap.elem_tipo_id=capitolo.elem_tipo_id and
--                      tipoCap.elem_tipo_id=bilElemTipoEnt;
--    	              tipoCap.ente_proprietario_id=enteProprietarioId and
--        	          tipoCap.elem_tipo_code=bilElemTipoEnt;
             else
	             select coalesce(min(capitolo.elem_id),0) into strict elemIdEnt
    	         from siac_t_bil_elem capitolo--,
          	 	      --siac_d_bil_elem_tipo tipoCap
	             where capitolo.ente_proprietario_id=enteProprietarioId and
    	               capitolo.bil_id=bilancioId and
--        	           capitolo.elem_code=ltrim(rtrim(to_char(migrVincoloCap.numero_capitolo_e,'999999'))) and
        	           capitolo.elem_code=migrVincoloCap.numero_capitolo_e::varchar and
--            	       capitolo.elem_code2=ltrim(rtrim(to_char(migrVincoloCap.numero_articolo_e,'999999'))) and
            	       capitolo.elem_code2=migrVincoloCap.numero_articolo_e::varchar and
                	--   capitolo.elem_code3='1' and
                       capitolo.data_cancellazione is null and
			           date_trunc('day',dataElaborazione)>=date_trunc('day',capitolo.validita_inizio) and
    			       date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(capitolo.validita_fine,statement_timestamp())) and
                       capitolo.elem_tipo_id=elemTipoEntId;
	    --               tipoCap.elem_tipo_id=capitolo.elem_tipo_id and
		--			   tipoCap.elem_tipo_id=bilElemTipoEnt;
--    	               tipoCap.ente_proprietario_id=enteProprietarioId and
--          	           tipoCap.elem_tipo_code=bilElemTipoEnt;
             end if;
		   exception
	           when no_data_found then
    	       	 RAISE EXCEPTION 'Elemento Bil %/%/1 inesistente.',
                     migrVincoloCap.numero_capitolo_e,migrVincoloCap.numero_articolo_e;
	           when others  THEN
    	         RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

        end;

        -- inserimento del vincolo
		if migrVincoloId!=migrVincoloCap.vincolo_id then

            migrVincoloId:=migrVincoloCap.vincolo_id;

            vincoloGenereId:=0;
        	strMessaggio:='Tipo Vincolo.'||
			               ' Per vincolo_id='||migrVincoloCap.vincolo_id||
                           ' in migr_vincolo_capitolo ' ||
                           ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
    	    strToElab:=migrVincoloCap.tipo_vincolo;
        	classifCode:=substring(strToElab from 1 for position(SEPARATORE in strToElab)-1);
	        classifDesc:=substring(strToElab from
					                 position(SEPARATORE in strToElab)+2
				                     for char_length(strToElab)-position(SEPARATORE in strToElab));

			begin

	            strMessaggio:='Verifica esistenza Tipo Vincolo='||classifCode||
	   		                  '. Per vincolo_id='||migrVincoloCap.vincolo_id||
                              ' in migr_vincolo_capitolo ' ||
                              ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
            	select vincoloGenere.vincolo_gen_id into strict vincoloGenereId
                from siac_d_vincolo_genere vincoloGenere
                where vincoloGenere.ente_proprietario_id=enteProprietarioId and
                      vincoloGenere.vincolo_gen_code=classifCode and
                      vincoloGenere.data_cancellazione is null and
			          date_trunc('day',dataElaborazione)>=date_trunc('day',vincoloGenere.validita_inizio) and
    			      date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(vincoloGenere.validita_fine,statement_timestamp()));

	            exception
	    	   		when no_data_found then
    	    	         strMessaggio:='Inserimento esistenza Tipo Vincolo='||classifCode||
	   					                  '. Per vincolo_id='||migrVincoloCap.vincolo_id||
                    			          ' in migr_vincolo_capitolo ' ||
		                              ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';

			  			 insert into siac_d_vincolo_genere
          				 (vincolo_gen_code,vincolo_gen_desc,
						  validita_inizio,ente_proprietario_id,
						  data_creazione,login_operazione)
	        			 values
				         (classifCode,classifDesc,dataInizioVal,enteProprietarioId,
				          statement_timestamp(),loginOperazione)
            	          returning vincolo_gen_id into vincoloGenereId;

	             	when others  THEN
		               RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
            end;


			 strMessaggio:='Calcolo  vincolo_id per Code '||
				           ' vincolo_id='||migrVincoloCap.vincolo_id||
                           ' in migr_vincolo_capitolo ' ||
                           ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
		 	vincoloIdCode:=0;
			 select coalesce(max(vincolo_id),0) into vincoloIdCode
             from siac_t_vincolo
             where ente_proprietario_id=enteProprietarioId and
				   data_cancellazione is null and
			       date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
    			   date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(validita_fine,statement_timestamp()));

			 vincoloIdCode:=vincoloIdCode+1;

             vincoloId:=0;
			 strMessaggio:='Inserimento vincolo '||
				           ' vincolo_id='||migrVincoloCap.vincolo_id||
                           ' in migr_vincolo_capitolo ' ||
                           ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';

             INSERT INTO siac_t_vincolo
			 ( vincolo_code,vincolo_desc,vincolo_tipo_id,
			   periodo_id,validita_inizio,
			   ente_proprietario_id, data_creazione,login_operazione
			 )
            (select vincoloIdCode::varchar,classifCode||'-'||classifDesc,tipo.vincolo_tipo_id,periodoId,dataInizioVal , enteProprietarioId,
			  		 statement_timestamp(),loginOperazione
              from siac_d_vincolo_tipo tipo--, siac_t_bil bil
              where tipo.ente_proprietario_id=enteProprietarioId and
                    tipo.vincolo_tipo_code=migrVincoloCap.tipo_vincolo_bil and
                    tipo.data_cancellazione is null and
			        date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio) and
    			    date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(tipo.validita_fine,statement_timestamp())))
			returning vincolo_id into vincoloId;
--                    bil.ente_proprietario_id=enteProprietarioId and
--                    bil.bil_id=bilancioId)


              strMessaggio:='Inserimento stato vincolo '||
              				' vincolo_id='||migrVincoloCap.vincolo_id||
                            ' in migr_vincolo_capitolo ' ||
                            ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
              insert into siac_r_vincolo_stato
              ( vincolo_id, vincolo_stato_id,validita_inizio,
				ente_proprietario_id, data_creazione,login_operazione)
              values
              (vincoloId, vincoloStatoId,dataInizioVal , enteProprietarioId,
			   statement_timestamp(),loginOperazione);

--              (select vincoloId, stato.vincolo_stato_id,dataInizioVal , enteProprietarioId,
--			  		  statement_timestamp(),loginOperazione
--               from siac_d_vincolo_stato stato
--               where stato.ente_proprietario_id=enteProprietarioId and
--                     stato.vincolo_stato_code=ST_VALIDO);

	         strMessaggio:='Inserimento relazione '||CL_TIPO_VINCOLO||' codice= '||classifCode||
             				' vincolo_id='||migrVincoloCap.vincolo_id||
	                        ' in migr_vincolo_capitolo ' ||
       			            ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
   			 insert into siac_r_vincolo_genere
	    	 (vincolo_id,vincolo_gen_id,validita_inizio,
			  ente_proprietario_id, data_creazione,login_operazione)
     	      values
 	    	 (vincoloId,vincoloGenereId,dataInizioVal , enteProprietarioId,
			  statement_timestamp(),loginOperazione);

			strMessaggio:='Inserimento siac_r_vincolo_attr per attr='||FL_TRASF_VINCOLATI_ATTR||
            			   ' vincolo_id='||migrVincoloCap.vincolo_id||
	                       ' in migr_vincolo_capitolo ' ||
            			   ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
			insert into siac_r_vincolo_attr
            (vincolo_id, attr_id,boolean,
			 validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
            values
            (vincoloId,flTrasfVincolatiAttrId,'N',dataInizioVal,enteProprietarioId,
             statement_timestamp(),loginOperazione);

--            (select vincoloId,attr.attr_id,'N',statement_timestamp(),enteProprietarioId,
--                    statement_timestamp(),loginOperazione
--             from siac_t_attr attr
--             where attr.ente_proprietario_id=enteProprietarioId and
--                   attr.attr_code=FL_TRASF_VINCOLATI_ATTR
--            );


            strMessaggio:='Inserimento siac_r_vincolo_attr per attr='||NOTE_ATTR||
            			   ' vincolo_id='||migrVincoloCap.vincolo_id||
	                       ' in migr_vincolo_capitolo ' ||
            			   ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
			insert into siac_r_vincolo_attr
            (vincolo_id, attr_id,testo,
			 validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
            values
            (vincoloId,noteVincoloAttrId,' ',dataInizioVal,enteProprietarioId,
             statement_timestamp(),loginOperazione);

--            (select vincoloId,attr.attr_id,' ',statement_timestamp(),enteProprietarioId,
--                    statement_timestamp(),loginOperazione
--             from siac_t_attr attr
--             where attr.ente_proprietario_id=enteProprietarioId and
--                   attr.attr_code=NOTE_ATTR
---            );

	        strMessaggio:='Inserimento siac_r_migr_vincolo_capitolo'||
            			   ' vincolo_id='||migrVincoloCap.vincolo_id||
	                       ' in migr_vincolo_capitolo ' ||
            			   ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
		    insert into  siac_r_migr_vincolo_capitolo
    	    (migr_vincolo_id,vincolo_id,
		     tipo_vincolo_bil,data_creazione,ente_proprietario_id)
            values
            (migrVincoloCap.vincolo_id,vincoloId,
             migrVincoloCap.tipo_vincolo_bil,statement_timestamp(),enteProprietarioId);

         	numInseriti:=numInseriti+1;

         end if;

         -- verifica se il capitolo di uscita esiste in relazione
         -- rispetto al vincolo
		 begin
           vincoloElemId:=0;
		   strMessaggio:='Verifica esistenza relazione vincolo cap.usc per '||
                         ' vincolo_id='||migrVincoloCap.vincolo_id||
                         ' in migr_vincolo_capitolo ' ||
                         ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
           select rVincCap.vincolo_elem_id into strict vincoloElemId
           from siac_r_vincolo_bil_elem  rVincCap
           where rVincCap.ente_proprietario_id=enteProprietarioId and
                 rVincCap.vincolo_id=vincoloId and
                 rVincCap.elem_id=elemIdUsc and
                 rVincCap.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',rVincCap.validita_inizio) and
   			     date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(rVincCap.validita_fine,statement_timestamp()));

           exception
    	   		when no_data_found then
        	         strMessaggio:='Inserimento relazione vincolo cap.usc per '||
                         ' vincolo_id='||migrVincoloCap.vincolo_id||
                         ' in migr_vincolo_capitolo ' ||
                         ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
		  			 insert into siac_r_vincolo_bil_elem
          			 (vincolo_id,elem_id, validita_inizio,
		 			  ente_proprietario_id, data_creazione,login_operazione)
        			 values
			         (vincoloId,elemIdUsc,dataInizioVal,enteProprietarioId,
			          statement_timestamp(),loginOperazione);

	                 --if enteProprietarioId=C_ENTE_COTO then
                     if nomeEnte=C_ENTE_COTO then
	         	         strMessaggio:='Inserimento relazione vincolo cap.usc [ueb cap.usc] per '||
                         ' vincolo_id='||migrVincoloCap.vincolo_id||
                         ' in migr_vincolo_capitolo ' ||
                         ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';

                      	insert into siac_r_vincolo_bil_elem
	          			(vincolo_id,elem_id, validita_inizio,
  			 			 ente_proprietario_id, data_creazione,login_operazione)
                        (select vincoloId,capitolo.elem_id,dataInizioVal,enteProprietarioId,
			             statement_timestamp(),loginOperazione
                         from siac_t_bil_elem capitolo--,
		        	        --  siac_d_bil_elem_tipo tipoCap
	    	        	 where capitolo.ente_proprietario_id=enteProprietarioId and
    	    	         	   capitolo.bil_id=bilancioId and
--	    	    	           capitolo.elem_code=rtrim(ltrim(to_char(migrVincoloCap.numero_capitolo_u,'999999'))) and
	    	    	           capitolo.elem_code=migrVincoloCap.numero_capitolo_u::VARCHAR and
--    	    	    	       capitolo.elem_code2=rtrim(ltrim(to_char(migrVincoloCap.numero_articolo_u,'999999'))) and
    	    	    	       capitolo.elem_code2=migrVincoloCap.numero_articolo_u::varchar and
                               capitolo.elem_tipo_id=elemTipoUscId and
            	    		  -- tipoCap.elem_tipo_id=capitolo.elem_tipo_id and
		                	  -- tipoCap.ente_proprietario_id=enteProprietarioId and
			                 --  tipoCap.elem_tipo_code=bilElemTipoUsc and
                               capitolo.elem_id!=elemIdUsc);

                      end if;

                     numCapIns:=numCapIns+1;
	           	when others  THEN
		             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		 end;

         -- verifica se il capitolo di entrata esiste in relazione
         -- rispetto al vincolo
		 begin
           vincoloElemId:=0;
		   strMessaggio:='Verifica esistenza relazione vincolo cap.ent per '||
                         ' vincolo_id='||migrVincoloCap.vincolo_id||
                         ' in migr_vincolo_capitolo ' ||
                         ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
           select rVincCap.vincolo_elem_id into strict vincoloElemId
           from siac_r_vincolo_bil_elem  rVincCap
           where rVincCap.ente_proprietario_id=enteProprietarioId and
                 rVincCap.vincolo_id=vincoloId and
                 rVincCap.elem_id=elemIdEnt and
                 rVincCap.data_cancellazione is null and
                 date_trunc('day',dataElaborazione)>=date_trunc('day',rVincCap.validita_inizio) and
   			     date_trunc('day',dataElaborazione)<=date_trunc('day',COALESCE(rVincCap.validita_fine,statement_timestamp()));

  		    exception
    	   		when no_data_found then
          			strMessaggio:='Inserimento relazione vincolo cap.ent per '||
                        		  ' vincolo_id='||migrVincoloCap.vincolo_id||
   			                      ' in migr_vincolo_capitolo ' ||
            		              ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';
         			insert into siac_r_vincolo_bil_elem
			        (vincolo_id,elem_id, validita_inizio,
					 ente_proprietario_id, data_creazione,login_operazione)
			         values
			         (vincoloId,elemIdEnt,dataInizioVal,enteProprietarioId,
			          statement_timestamp(),loginOperazione);

--	                 if enteProprietarioId=C_ENTE_COTO then
	                 if nomeEnte=C_ENTE_COTO then
	          			strMessaggio:='Inserimento relazione vincolo cap.ent [ueb cap.ent] per '||
    	                    		  ' vincolo_id='||migrVincoloCap.vincolo_id||
   				                      ' in migr_vincolo_capitolo ' ||
            			              ' migr_vincolo_id='||migrVincoloCap.migr_vincolo_id||'.';

                      	insert into siac_r_vincolo_bil_elem
	          			(vincolo_id,elem_id, validita_inizio,
  			 			 ente_proprietario_id, data_creazione,login_operazione)
                        (select vincoloId,capitolo.elem_id,dataInizioVal,enteProprietarioId,
			             statement_timestamp(),loginOperazione
                         from siac_t_bil_elem capitolo--,
		        	       --   siac_d_bil_elem_tipo tipoCap
	    	        	 where capitolo.ente_proprietario_id=enteProprietarioId and
    	    	         	   capitolo.bil_id=bilancioId and
--	    	    	           capitolo.elem_code=rtrim(ltrim(to_char(migrVincoloCap.numero_capitolo_e,'999999'))) and
	    	    	           capitolo.elem_code=migrVincoloCap.numero_capitolo_e::varchar and
--    	    	    	       capitolo.elem_code2=rtrim(ltrim(to_char(migrVincoloCap.numero_articolo_e,'999999'))) and
    	    	    	       capitolo.elem_code2=migrVincoloCap.numero_articolo_e::varchar and
                               capitolo.elem_tipo_id=elemTipoEntId and
            	    		  -- tipoCap.elem_tipo_id=capitolo.elem_tipo_id and
		                	 --  tipoCap.ente_proprietario_id=enteProprietarioId and
			                 --  tipoCap.elem_tipo_code=bilElemTipoEnt and
                               capitolo.elem_id!=elemIdEnt);

                      end if;


                    numCapIns:=numCapIns+1;
               when others  THEN
		             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);
		 end;


    end loop;

	--21.10.2015 dani
     update migr_vincolo_capitolo ms
     set fl_elab = 'S'
     where ms.ente_proprietario_id=enteProprietarioId and
             ms.anno_esercizio=annoBilancio and
             ms.tipo_vincolo_bil=vincoloTipoBil and
             ms.fl_elab='N';

   messaggioRisultato:=strMessaggioFinale||'Inseriti '||numInseriti||' vincoli .'||
                       'totale relazioni capitoli ='||numCapIns;
   numeroElementiInseriti:=numInseriti;
   numeroRelInserite:=numCapIns;
   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroElementiInseriti:=-1;
        numeroRelInserite:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numeroElementiInseriti:=-1;
        numeroRelInserite:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
