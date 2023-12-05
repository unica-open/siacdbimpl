/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 05.06.014 Sofia
CREATE OR REPLACE FUNCTION fnc_migr_classif(classifTipoCode varchar,classifCode varchar,classifDesc varchar,
 						    				enteProprietarioId integer,loginOperazione varchar,
						   					dataElaborazione timestamp,
                                            dataInizioVal timestamp,
                                            OUT classifId INTEGER,
										    OUT codiceRisultato integer,
                                            OUT messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_classif -- riceve gli estremi di un tipo classificatore
  -- codiceTipoClassificatore - codice e descrizione dello specifico classificatore
  -- legge siac_t_class  per classif_code=codice passato, per l'ente e tipo classificatore passato
   -- se esiste utilizza il classif_id per la restituzione
   -- diversamente inserisce in siac_t_class e resituisce il nuovo classif_id
 -- restitusce
   -- classifId= Id del classificatore esistente o inserito
   -- messaggioRisultato=risultato in formato testo
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)


 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 classifRetId integer:=0;
 classifTipoId integer:=0;

begin

	messaggioRisultato:='';
    codiceRisultato:=0;
    classifId:=0;

	strMessaggioFinale:='Gestione classificatore  '||classifTipoCode||'.';

    begin
     strMessaggio:='Lettura identificativo per classif tipo codice='||classifTipoCode||'.';
     select tipoClass.classif_tipo_id into strict classifTipoId
     from siac_d_class_tipo tipoClass
     where tipoClass.ente_proprietario_id=enteProprietarioId and
     	   tipoClass.classif_tipo_code= classifTipoCode and
           tipoClass.data_cancellazione is null and
           date_trunc('day',dataElaborazione)>=date_trunc('day',tipoClass.validita_inizio) and
		   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipoClass.validita_fine,now()));

     exception
        	when no_data_found then
	             RAISE EXCEPTION 'Dato non presente.';
            when others then
                 RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;

	strMessaggio:='Lettura codice '||classifCode||'-'||classifDesc||'.';
    begin
    	select  coalesce( classif.classif_id,0) into strict classifRetId
	    from  siac_t_class classif--, siac_d_class_tipo tipoClass
    	where classif.classif_code=classifCode and
        	  classif.ente_proprietario_id=enteProprietarioId and
              classif.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',classif.validita_inizio) and
		 	  (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classif.validita_fine,now()))) and
              classif.classif_tipo_id=classifTipoId;
--			            or classif.validita_fine is null) and
--		      tipoClass.classif_tipo_id=classif.classif_tipo_id and
--              tipoClass.ente_proprietario_id=enteProprietarioId and
--              tipoClass.classif_tipo_code= classifTipoCode and
--              tipoClass.data_cancellazione is null and
--              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoClass.validita_inizio) and
--		 	  (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipoClass.validita_fine,now())));

        exception
        	when no_data_found then
	        strMessaggio:='Inserimento codice '||classifCode||'-'||classifDesc||'.';

            insert into siac_t_class
            (classif_code, classif_desc, classif_tipo_id,
			 validita_inizio, ente_proprietario_id,data_creazione,login_operazione)
            values
            (classifCode,classifDesc, classifTipoId,
    	     dataInizioVal,enteProprietarioId,statement_timestamp(),loginOperazione)
            returning classif_id into classifRetId;
 --   	    (select classifCode,classifDesc, tipoClass.classif_tipo_id,
--        	        dataInizioVal,enteProprietarioId,now(),loginOperazione
--             from siac_d_class_tipo  tipoClass
--             where tipoClass.ente_proprietario_id=enteProprietarioId and
--                   tipoClass.classif_tipo_code=classifTipoCode and
--                   tipoClass.data_cancellazione is null and
--                   date_trunc('day',dataElaborazione)>=date_trunc('day',tipoClass.validita_inizio) and
--	 	           (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipoClass.validita_fine,now())))
			  --          or tipoClass.validita_fine is null)
--            )

         	when others  THEN
             RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);

   end;


   codiceRisultato:= codRet;
   messaggioRisultato:=strMessaggioFinale||'OK.';
   classifId:=classifRetId;

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        classifId:=0;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        classifId:=0;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;