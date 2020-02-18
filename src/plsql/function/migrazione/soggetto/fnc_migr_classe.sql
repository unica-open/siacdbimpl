/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_classe ( enteProprietarioId integer,
		  								     loginOperazione varchar,
									 	     dataElaborazione timestamp,
											 out codiceRisultato integer,
											 out messaggioRisultato varchar
											)
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_classe -- function che effettua il caricamento di classi soggetto leggendo da migr_classe
 -- effettua inserimento di
  -- siac_d_soggetto_classe se le classi non esistono
  -- se le classi passate non esistono inserisce in siac_d_soggetto_classe
  -- siac_r_migr_classe_soggclasse -- traccia la relazine tra migr_classe.migr_classe_id e siac_d_soggetto_classe
                                   -- servira poi nei movimenti di gestione per agganciare la classe anziche il soggetto
 -- la fnc restituisce
   -- messaggioRisultato = risulato elaborazine in formato testo
   -- codiceRisultato    = codice risultato elaborazione 0 ( elaborazione OK ) -1 (errore) -12 ( dati non presenti in migr_soggetto_classe)

 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 countMigrSoggettoClasse integer:=0;
 migrSoggettoClasse record;
 soggettoClasseRec record;

 soggettoClasseId integer:=0;

 classeSoggettoCode varchar(1000):='';
 classeSoggettoDescri varchar(1000):='';

 ambitoId integer:=0;
 soggettoClasseTipoId integer:=0;

 AMBITO_SOGG         CONSTANT  varchar :='AMBITO_FIN';
 SOGG_CLASSE_TIPO_ND CONSTANT  varchar :='ND';

begin

	messaggioRisultato:='';
    codiceRisultato:=0;


	strMessaggioFinale:='Gestione inserimento classi soggetto migr_classe.';

	strMessaggio:='Verifica esistenza classi.';

	select COALESCE(count(*),0) into countMigrSoggettoClasse
    from migr_classe ms
    where ms.ente_proprietario_id=enteProprietarioId;

	if COALESCE(countMigrSoggettoClasse,0)=0 then
    	 messaggioRisultato:=strMessaggioFinale||'Nessuna classe presente.';
         codiceRisultato:=-12;
         return;
    end if;

    strMessaggio:='Lettura AMBITO_FIN.';

    select ambito.ambito_id into ambitoId
    from siac_d_ambito ambito
    where ambito.ambito_code=AMBITO_SOGG and
          ambito.ente_proprietario_id=enteProprietarioId;

	if COALESCE(ambitoId,0)=0 then
	    RAISE EXCEPTION 'Ambito FIN inesistente per ente % ',enteProprietarioId ;
    end if;

    strMessaggio:='Lettura soggetto_classe_tipo_id per AMBITO='||ambito_sogg||' TIPO '||SOGG_CLASSE_TIPO_ND;

	select soggetto_classe_tipo_id into soggettoClasseTipoId
    from siac_d_soggetto_classe_tipo soggClasseTipo
    where soggClasseTipo.ambito_id=ambitoId and
          soggClasseTipo.ente_proprietario_id=enteProprietarioId and
          soggClasseTipo.soggetto_classe_tipo_code=SOGG_CLASSE_TIPO_ND;

	if COALESCE(soggettoClasseTipoId,0)=0 then
	    RAISE EXCEPTION 'SoggettoClasseTipo inesistente per ente % ',enteProprietarioId ;
    end if;


	-- migr_classe_id
	-- classe_id
    -- classe_code
    -- classe_desc
	-- codice_soggetto
	-- note_soggetto

    strMessaggio:='Letttura classi in migr_classe.';
    for migrSoggettoClasse in
    ( select migrSoggClasse.*
     from migr_classe migrSoggClasse
     where    migrSoggClasse.ente_proprietario_id=enteProprietarioId
     order by migrSoggClasse.classe_id
    )
    loop

		classeSoggettoCode:=migrSoggettoClasse.classe_code;
		classeSoggettoDescri:=migrSoggettoClasse.classe_desc;

		strMessaggio:='Lettura esistenza classe '||classeSoggettoCode||' ' ||classeSoggettoDescri||'.';
        begin
        	select soggettoClasse.soggetto_classe_id into strict soggettoClasseId
            from siac_d_soggetto_classe soggettoClasse
            where soggettoClasse.ambito_id=ambitoId and
                  soggettoClasse.ente_proprietario_id=enteProprietarioId and
                  soggettoClasse.soggetto_classe_code=classeSoggettoCode;

			exception
         	 when no_data_found then
             	strMessaggio:='Inserimento classe soggetto '||classeSoggettoCode||' ' ||classeSoggettoDescri
                              ||'migr_classe_id='||migrSoggettoClasse.migr_classe_id||'.';

                insert into siac_d_soggetto_classe
                ( soggetto_classe_tipo_id,soggetto_classe_code,soggetto_classe_desc,
				  validita_inizio, ambito_id,ente_proprietario_id,data_creazione,login_operazione)
                values
                ( soggettoClasseTipoId,classeSoggettoCode,classeSoggettoDescri,CURRENT_TIMESTAMP,ambitoId,
                  enteProprietarioId,CURRENT_TIMESTAMP,loginOperazione)
                returning soggetto_classe_id into soggettoClasseId;

            	strMessaggio='Inserimento  siac_r_migr_classe_soggclasse migr_classe_id='
                               ||migrSoggettoClasse.migr_classe_id||'.';

	        	insert into siac_r_migr_classe_soggclasse
		        (migr_classe_id, soggetto_classe_id,data_creazione,ente_proprietario_id)
		        values
        		(migrSoggClasse.migr_classe_id,soggettoClasseId,CURRENT_TIMESTAMP,enteProprietarioId);


   			 when others  THEN
      			 RAISE EXCEPTION 'Errore lettura in migr_classe=%: %-%.',
           				migrSoggClasse.migr_classe_id,
             			SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

        end;
    end loop;

    codiceRisultato:= codRet;
    messaggioRisultato:=strMessaggioFinale||'Elaborazione OK.';

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;