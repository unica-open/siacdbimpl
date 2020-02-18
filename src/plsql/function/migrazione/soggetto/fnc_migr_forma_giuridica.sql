/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_forma_giuridica (  estremiFormaGiuridica      varchar,
		  							                   enteProprietarioId integer,
		  											   loginOperazione    varchar,
													   dataElaborazione   timestamp,
                                                       annoBilancio varchar,
		  											   out codiceRisultato integer,
													   out messaggioRisultato     varchar,
                                                       out formaGiuridicaId integer
												    )
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_forma_giuridica -- riceve gli estremi della forma giuridica
 --   codice||descrizione
 --   legge siac_t_forma_giuridica  per siac_t_forma_giuridica.forma_giuridica_istat_codice=codice passato, per l'ente
  --   se esiste restituisce in formaGiuridicaParId il forma_giuridica_id ricavato
  --   diversamente la inserisce
 -- restitusce
   -- formaGiuridicaParId=forma_giuridica_id
   -- messaggioRisultato=risultato in formato testo
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)

 SEPARATORE			CONSTANT  varchar :='||';

 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 formaGiuridicaRec record;

 formaGiuridicaRetId integer:=0;
 formaGiuridicaNewId integer:=0;

 formaGiuridicaCode varchar(1000):='';
 formaGiuridicaDescri varchar(1000):='';

--     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
--dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

begin

	messaggioRisultato:='';
    codiceRisultato:=0;
    formaGiuridicaId:=null;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione forma giuridica : ';


   formaGiuridicaCode:=substring(estremiFormaGiuridica from 1 for position(SEPARATORE in estremiFormaGiuridica)-1);
   formaGiuridicaDescri:=substring(estremiFormaGiuridica from
		                 position(SEPARATORE in estremiFormaGiuridica)+2
				         for char_length(estremiFormaGiuridica)-position(SEPARATORE in estremiFormaGiuridica));

	strMessaggio:='Lettura  forma giuridica '||formaGiuridicaCode||'-'||formaGiuridicaDescri||'.';
    begin

    	select *  into formaGiuridicaRec
	    from siac_t_forma_giuridica formaGiuridica
    	where upper(formaGiuridica.forma_giuridica_istat_codice)=formaGiuridicaCode and
        	  formaGiuridica.ente_proprietario_id=enteProprietarioId;

        if COALESCE(formaGiuridicaRec.forma_giuridica_id,0)=0 then
				strMessaggio:='Inserimento  forma giuridica '||formaGiuridicaCode||'-'||formaGiuridicaDescri||'.';
		    	insert into siac_t_forma_giuridica
		        (forma_giuridica_istat_codice,forma_giuridica_desc, validita_inizio,
		         ente_proprietario_id, data_creazione,login_operazione
				)
			    VALUES
				(formaGiuridicaCode,formaGiuridicaDescri,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
		        )
                returning forma_giuridica_id into formaGiuridicaRetId;

                formaGiuridicaNewId =formaGiuridicaRetId;
          else
               	formaGiuridicaRetId=formaGiuridicaRec.forma_giuridica_id;
          end if;
 	      exception
			   when others then
			       RAISE EXCEPTION 'ERRORE : %-% ', SQLSTATE,	substring(upper(SQLERRM) from 1 for 100);
    end;


    codiceRisultato:= codRet;
	formaGiuridicaId:=formaGiuridicaRetId;

    if formaGiuridicaNewId!=0 then
	    messaggioRisultato:=strMessaggioFinale||'Forma giuridica '||formaGiuridicaDescri||' inserita.';
    else
	    messaggioRisultato:=strMessaggioFinale||'Forma giuridica '||formaGiuridicaDescri||' reperita.';
    end if;



   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        formaGiuridicaId:=null;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        formaGiuridicaId:=null;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;