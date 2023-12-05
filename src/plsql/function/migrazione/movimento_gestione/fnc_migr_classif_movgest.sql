/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Function: fnc_migr_classif_movgest(character varying, character varying, character varying, integer, integer, character varying, timestamp without time zone)

-- DROP FUNCTION fnc_migr_classif_movgest(character varying, character varying, character varying, integer, integer, character varying, timestamp without time zone);

CREATE OR REPLACE FUNCTION fnc_migr_classif_movgest(IN classiftipocode varchar, IN classifcode varchar, IN classifdesc varchar, IN movgesttsid integer,
						    IN enteproprietarioid integer, IN loginoperazione character varying,
						    IN dataelaborazione timestamp without time zone,
                            IN datainizioval timestamp without time zone,
						    OUT codicerisultato integer, OUT messaggiorisultato varchar)
  RETURNS record AS
$body$
DECLARE
 -- fnc_migr_classif_movgest -- riceve gli estremi di un tipo classificatore (Impegni/Accertamenti)
  -- codiceTipoClassificatore - codice e descrizione dello specifico classificatore
  -- legge siac_t_class  per classif_code=codice passato, per l'ente e tipo classificatore passato
   -- se esiste utilizza il classif_id
   -- per inserire la relazione rispetto al movimento gestione ( movgestTsId )
   -- diversamente inserisce in siac_t_class e inserisce la relazione rispetto al nuovo classif_id
 -- restitusce
   -- messaggioRisultato=risultato in formato testo
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)


 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 classifRec record;

 classifId integer:=0;
 classifNewId integer:=0;
 classifTipoId integer:=0;

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

	strMessaggioFinale:='Gestione classificatore  '||classifTipoCode||' : ';

	strMessaggio:='Lettura codice '||classifCode||'-'||classifDesc||'.';
    begin

    	--select  coalesce( classifMovGest.classif_id,0) into strict classifId
    	select  classifMovGest.classif_id into strict classifId
	from siac_d_class_tipo tipoClass, siac_t_class classifMovGest
	where classifMovGest.classif_code=classifCode and
		classifMovGest.ente_proprietario_id=enteProprietarioId and
		classifMovGest.data_cancellazione is null and
		date_trunc('day',dataElaborazione)>=date_trunc('day',classifMovGest.validita_inizio) and
		 	  (date_trunc('day',dataElaborazione)<=date_trunc('day',classifMovGest.validita_fine)
			    or classifMovGest.validita_fine is null) and
		tipoClass.classif_tipo_id=classifMovGest.classif_tipo_id and
		tipoClass.ente_proprietario_id=enteProprietarioId and
		tipoClass.classif_tipo_code= classifTipoCode;

        exception
		when no_data_found then
			strMessaggio:='Inserimento codice '||classifCode||'-'||classifDesc||'.';

		    insert into siac_t_class
		    (classif_code, classif_desc, classif_tipo_id,validita_inizio, ente_proprietario_id,data_creazione,login_operazione)
		    (select classifCode,classifDesc, tipoClass.classif_tipo_id,datainizioval,enteProprietarioId,clock_timestamp(),loginOperazione
		     from siac_d_class_tipo  tipoClass
		     where tipoClass.ente_proprietario_id=enteProprietarioId and
			   tipoClass.classif_tipo_code=classifTipoCode and
			   tipoClass.data_cancellazione is null and
			   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoClass.validita_inizio) and
				       (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoClass.validita_fine)
					    or tipoClass.validita_fine is null)
			)
			returning classif_id into classifId;

			classifNewId:=classifId;

           	when others  THEN
			RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 100);

	end;

	strMessaggio:='Inserimento relazione rispetto movimento gestione '||movgestTsId||'.';
	INSERT INTO siac_r_movgest_class
	( movgest_ts_id, classif_id, validita_inizio, ente_proprietario_id, data_creazione,login_operazione)
	values
	(movgestTsId, classifId,datainizioval,enteProprietarioId,clock_timestamp(),loginOperazione);

	   codiceRisultato:= codRet;
	   if classifNewId!=0 then
		   messaggioRisultato:=strMessaggioFinale||classifCode||'-'||classifDesc||' inserito e inserita relazione.';
	   else
		   messaggioRisultato:=strMessaggioFinale||classifCode||'-'||classifDesc||' inserita relazione.';
	   end if;

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
