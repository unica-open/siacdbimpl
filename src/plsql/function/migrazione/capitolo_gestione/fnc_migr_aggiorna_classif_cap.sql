/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_aggiorna_classif_cap (bilElemTipo varchar,
		  							                      enteProprietarioId integer,
		  											      loginOperazione    varchar,
													      dataElaborazione   timestamp,
		  											      out codiceRisultato integer,
													      out messaggioRisultato     varchar
												          )
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_aggiorna_classif_cap -- riceve gli estremi di un tipo classificatore (CAP-UG, CAP-EG,CAP-UP,CAP-EP ..... )
  -- legge tutti i classicatori passati in migr_classif_capitolo per bilElemTipo
  -- aggiorna la rispettiva descrizione in siac_d_class_tipo per
  -- siac_d_class_tipo.classif_tipo_code=migr_classif_capitolo.codice
 -- restitusce
   -- messaggioRisultato=risultato in formato testo
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)

 strMessaggioFinale VARCHAR(1500):='';

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

	strMessaggioFinale:='Aggiornamento descri classificatori tipo  '||bilElemTipo||'.';


    update siac_d_class_tipo tipo
    	set classif_tipo_desc=
     		(select migr.descrizione
	  	 	 from migr_classif_capitolo migr
	     	 where tipo.ente_proprietario_id=enteProprietarioId and
		           migr.ente_proprietario_id=enteProprietarioId and
    	           migr.tipo_capitolo=bilElemTipo and
    	           tipo.classif_tipo_code=migr.codice ),
            login_operazione=loginOperazione,data_modifica=statement_timestamp()
     where tipo.ente_proprietario_id=enteProprietarioId and
           tipo.classif_tipo_code in
           (select codice
            from migr_classif_capitolo
            where ente_proprietario_id=enteProprietarioId and
                  tipo_capitolo=bilElemTipo);


   messaggioRisultato:=strMessaggioFinale||'OK .';

   return;

exception
	when others  THEN
		raise notice '% Errore DB % %',strMessaggioFinale,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;