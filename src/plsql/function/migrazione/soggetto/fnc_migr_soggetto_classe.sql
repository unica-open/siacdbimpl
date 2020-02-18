/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_soggetto_classe ( soggettoId integer,         -- migr_soggetto.soggetto_id
													  siacSoggettoId integer,	   -- siac_t_soggetto.soggetto_id
                                                      ambitoId integer,
                                                      soggettoClasseTipoId integer,
													  enteProprietarioId integer,
		  											  loginOperazione varchar,
													  dataElaborazione timestamp,
                                                      annoBilancio VARCHAR,
													  out codiceRisultato integer,
													  out messaggioRisultato varchar
												    )
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_soggetto_classe -- function che effettua il caricamento delle relazioni tra il soggetto e le classi soggetto ( leggendo da migr_soggetto_classe )
 --                             per il  siacSoggettoId passato in input
 --                             il soggetto deve essere presente in siac_t_soggetto con soggetto_id=siacSoggettoId
 --                             soggettoId=migr_soggetto.soggetto_id
 --                             ambitoId=siac_d_ambito.ambito_id per AMBITO_FIN per ente_proprietario_id=enteProprietarioId
 -- effettua inserimento di
  -- siac_r_soggetto_classe - x tracciare la relazione tra i soggetto e le classi
  -- se le classi passate non esistono inserisce in siac_d_soggetto_classe
  -- siac_r_migr_soggetto_classe_rel_classe -- traccia la relazine tra migr_soggetto_classe.migr_soggetto_classe e siac_r_soggetto_classe.soggetto_classe_r_id
 -- la fnc restituisce
   -- messaggioRisultato = risulato elaborazine in formato testo
   -- codiceRisultato    = codice risultato elaborazione 0 ( elaborazione OK ) -1 (errore) -12 ( dati non presenti in migr_soggetto_classe)
 SEPARATORE			CONSTANT  varchar :='||';

 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 countMigrSoggettoClasse integer:=0;
 migrSoggettoClasse record;
 soggettoClasseRec record;

 soggettoClasseId integer:=0;
 soggettoClasseRId integer:=0;

 classeSoggettoCode varchar(1000):='';
 classeSoggettoDescri varchar(1000):='';

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione inserimento classi soggetto per soggetto_id '||soggettoId||' in migr_soggetto.';

	strMessaggio:='Verifica esistenza classi.';

	select COALESCE(count(*),0) into countMigrSoggettoClasse
    from migr_soggetto_classe ms
    where ms.soggetto_id=soggettoId and
          ms.ente_proprietario_id=enteProprietarioId and
          ms.fl_elab='N';

	if COALESCE(countMigrSoggettoClasse,0)=0 then
    	 messaggioRisultato:=strMessaggioFinale||'Nessuna classe presente per il soggetto indicato.';
         codiceRisultato:=-12;
         return;
    end if;

	-- migr_soggetto_classe_id
	-- soggetto_classe_id
	-- soggetto_id
	-- classe_soggetto

    strMessaggio:='Lettura classi in migr_soggetto_classe.';
    for migrSoggettoClasse in
    ( select migrSoggClasse.*
     from migr_soggetto_classe migrSoggClasse
     where migrSoggClasse.soggetto_id=soggettoId  and
           migrSoggClasse.ente_proprietario_id=enteProprietarioId and
           migrSoggClasse.fl_elab='N'
     order by migrSoggClasse.classe_soggetto
    )
    loop

		classeSoggettoCode:=substring(migrSoggettoClasse.classe_soggetto from 1 for position(SEPARATORE in migrSoggettoClasse.classe_soggetto)-1);
		classeSoggettoDescri:=substring(migrSoggettoClasse.classe_soggetto from
						                 position(SEPARATORE in migrSoggettoClasse.classe_soggetto)+2
				        				 for char_length(migrSoggettoClasse.classe_soggetto)-position(SEPARATORE in migrSoggettoClasse.classe_soggetto));

--		strMessaggio:='Lettura esistenza classe  '||classeSoggettoCode||' ' ||classeSoggettoDescri||'.';
   		strMessaggio:='Lettura esistenza classe  '||classeSoggettoCode||'.';

        begin
        	select *  into strict soggettoClasseRec
            from siac_d_soggetto_classe soggettoClasse
            where soggettoClasse.ambito_id=ambitoId and
                  soggettoClasse.ente_proprietario_id=enteProprietarioId and
                  soggettoClasse.soggetto_classe_code=classeSoggettoCode;

			soggettoClasseId:=soggettoClasseRec.soggetto_classe_id;
            --if COALESCE(soggettoClasseRec.soggetto_classe_id,0)=0 then
            exception
               when no_data_found then
				strMessaggio:='Inserimento classe  '||classeSoggettoCode||' ' ||classeSoggettoDescri||'.';

                insert into siac_d_soggetto_classe
                ( soggetto_classe_tipo_id,soggetto_classe_code,soggetto_classe_desc,
				  validita_inizio, ambito_id,ente_proprietario_id,data_creazione,login_operazione)
                values
                ( soggettoClasseTipoId,classeSoggettoCode,classeSoggettoDescri,dataInizioVal,ambitoId,
                  enteProprietarioId,clock_timestamp(),loginOperazione)
                returning soggetto_classe_id into soggettoClasseId;
               when others then
	    	         RAISE EXCEPTION 'ERRORE : %-% ', SQLSTATE,	substring(upper(SQLERRM) from 1 for 300);
--            else
--            	soggettoClasseId:=soggettoClasseRec.soggetto_classe_id;
--            end if;

--            exception
--             when others then
--	             RAISE EXCEPTION 'ERRORE : %-% ', SQLSTATE,	substring(upper(SQLERRM) from 1 for 100);
        end;

		BEGIN
	        strMessaggio='Verifica esistenza relazione  classe  '||classeSoggettoCode||'.';
    	    select r.soggetto_classe_r_id into strict soggettoClasseRId
        	from siac_r_soggetto_classe r
	        where ente_proprietario_id=enteProprietarioid and
    	          soggetto_id=siacSoggettoId and
        	      soggetto_classe_id=soggettoClasseId;

	        exception
	           when no_data_found then
    	       	 strMessaggio='Inserimento relazione  classe  '||classeSoggettoCode||'.';
		         insert into siac_r_soggetto_classe
		         (soggetto_id,soggetto_classe_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
        		 values
	             (siacSoggettoId,soggettoClasseId,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione)
		         returning soggetto_classe_r_id into soggettoClasseRId;

			  	strMessaggio='Inserimento  siac_r_migr_soggetto_classe_rel_classe classe '||classeSoggettoCode||'.';

		        insert into siac_r_migr_soggetto_classe_rel_classe
		        (migr_soggetto_classe_id, soggetto_classe_r_id,data_creazione,ente_proprietario_id)
		        values
		        (migrSoggettoClasse.migr_soggetto_classe_id,soggettoClasseRId,clock_timestamp(),enteProprietarioId);
	         when others  THEN
    	         RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
        end;

    end loop;

    codiceRisultato:= codRet;
    messaggioRisultato:=strMessaggioFinale||'Elaborazione OK.';

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 800);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 800) ;
        codiceRisultato:=-1;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 800	);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 800) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;