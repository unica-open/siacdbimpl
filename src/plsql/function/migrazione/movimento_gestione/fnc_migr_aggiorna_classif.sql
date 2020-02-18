/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_aggiorna_classif (tipoClass varchar,
		  							                 enteProprietarioId integer,
		  											 loginOperazione    varchar,
													 dataElaborazione   timestamp,
		  											 out codiceRisultato integer,
													 out messaggioRisultato     varchar
												    )
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_aggiorna_classif -- riceve gli estremi di un tipo classificatore (Impegni/Accertamenti)
   -- legge tutti i classicatori passati in migr_classif_impacc per tipoClass
   -- aggiorna la rispettiva descrizione in siac_d_class_tipo per
   -- siac_d_class_tipo.classif_tipo_code=migr_classif_impacc.codice
 -- restitusce
   -- messaggioRisultato=risultato in formato testo
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)


 strMessaggioFinale VARCHAR(1500):='';

begin

	messaggioRisultato:='';
    codiceRisultato:=0;

	strMessaggioFinale:='Aggiornamento descri classificatori tipo  '||tipoClass||'.';


    update siac_d_class_tipo tipo
    	set classif_tipo_desc=migr.descrizione, login_operazione=loginOperazione,data_modifica=dataElaborazione
	from migr_classif_impacc migr
	where tipo.ente_proprietario_id=enteProprietarioId and
		  migr.ente_proprietario_id=enteProprietarioId and
    	  migr.tipo=tipoClass and
    	  tipo.classif_tipo_code=migr.codice;


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