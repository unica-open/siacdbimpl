/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_comune (  estremiComune      varchar,
											  estremiProvincia   varchar,
											  estremiNazione     varchar,
  							                  enteProprietarioId integer,
  											  loginOperazione    varchar,
											  dataElaborazione   timestamp,
                                              annoBilancio varchar,
											  out codiceRisultato integer,
											  out messaggioRisultato     varchar,
                                              out comuneId     integer
											 )
RETURNS record AS
$body$
DECLARE
 -- fnc_migr_comune -- riceve gli estremi di comune, provincia e nazione nel formato
 --   descrizione||codice (Istat per il comune )
 --   legge siac_t_comune per siac_t_comune.comune_desc=descri passata, per l'ente
  --   se esiste restituisce in comuneParId il comune_id ricavato
  --   diversamente legge la nazione in siac_t_nazione per siac_t_nazione.nazione_desc=descri passata, per l'ente
   --   se esiste  ne ricava nazione_id , diversamente provvede ad inserirla
   --   quindi inserisce il comune , per nazione_id ricavato o inserito
 -- se ha inserito il comune verifica  esistenza della provincia passata leggendo
 -- siac_t_provincia per    siac_t_provincia.provincia_desc=descri passata, per l'ente
 -- se esite ne ricava provincia_id, diversamete la inserisce
 -- quindi inserisce la reazione tra comune_id e provincia_id in siac_r_comune_provincia
 -- il trattamento sulla provincia effettuato solo se provDescri!=EE (estero )
 -- restitusce
   -- comuneParId=comune_id
   -- messaggioRisultato=risultato in formato testo
   -- codiceRisultato=risultato operazione valorizzato con 0 ( elaborazione OK ) -1 (errore)

 SEPARATORE			CONSTANT  varchar :='||';
 COD_ESTERO			CONSTANT  varchar :='EE';

 codRet integer :=0;
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 comuneRec record;
 provinciaRec record;
 nazioneRec record;

 nazioneId integer:=0;
 comuneRetId integer:=0;
 comuneNewId integer:=0;
 provinciaId integer:=0;

 nazioneDescri varchar(1000):='';

 comuneCode varchar(1000):='';
 comuneDescri varchar(1000):='';
 comuneBelfiore varchar(1000):='';

 provDescri varchar(1000):='';
 provCode varchar(1000):='';

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

begin

	messaggioRisultato:='';
    codiceRisultato:=0;
    comuneId:=null;

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Gestione comuni-nazioni-province : ';

	if estremiNazione is not null and estremiNazione!='' then
    	strMessaggio:='Leggo estremiNazione.';
--	      nazioneDescri:= substring(estremiNazione from 1 for position(SEPARATORE in estremiNazione)-1);
          nazioneDescri:= trim (both ' ' from split_part(estremiNazione,SEPARATORE,1));
    else  nazioneDescri:='MIGRAZIONE';
    end if;


    if estremiComune is not null and estremiComune!='' then
    	strMessaggio:='Leggo estremiComune '||estremiComune||'.';
        /* 05.05.15 daniela: usiamo la funzione split_part
	    comuneDescri:=substring(estremiComune from 1 for position(SEPARATORE in estremiComune)-1);

        estremiComune := substring(estremiComune from
		                 position(SEPARATORE in estremiComune)+2
				         for char_length(estremiComune)-position(SEPARATORE in estremiComune));

        	strMessaggio:='Leggo estremiComune2.';

			comuneCode:=substring(estremiComune from 1 for position(SEPARATORE in estremiComune)-1);

			comuneBelfiore:=substring(estremiComune from
		                 position(SEPARATORE in estremiComune)+2
				         for char_length(estremiComune)-position(SEPARATORE in estremiComune));
	     */
         comuneDescri   := trim (both ' ' from split_part(estremiComune,SEPARATORE,1));
		 -- DAVIDE - Normalizzare il Comune qui 
         if comuneDescri='' then 
		     comuneDescri:=NULL; 
		 else
		     comuneDescri := replace(replace(replace(comuneDescri, '`', ''), '¿', ''), '0', 'o');
		     comuneDescri := replace(replace(replace(comuneDescri, '\\', ''), '!', ''), '£', '');
		     comuneDescri := replace(replace(replace(comuneDescri, '$', ''), '%', ''), '&', '');
		     comuneDescri := replace(replace(replace(comuneDescri, '/', ''), '=', ''), '?', '');
		     comuneDescri := replace(replace(replace(comuneDescri, '^', ''), '{', ''), '}', '');
		     comuneDescri := replace(replace(replace(comuneDescri, '[', ''), ']', ''), '+', '');
		     comuneDescri := replace(replace(replace(comuneDescri, '*', ''), '@', ''), '€', '');
		     comuneDescri := replace(replace(replace(comuneDescri, '#', ''), '°', ''), ',', '');
		     comuneDescri := replace(replace(replace(comuneDescri, ';', ''), ':', ''), '>', '');
		     comuneDescri := replace(comuneDescri, '<', '');
		 end if;
         -- DAVIDE - Fine
		 
         comuneCode     := trim (both ' ' from split_part(estremiComune,SEPARATORE,2));
         comuneBelfiore := trim (both ' ' from split_part(estremiComune,SEPARATORE,3));
         if comuneCode='' then comuneCode:=NULL; end if;
         if comuneBelfiore='' then comuneBelfiore:=NULL; end if;

    end if;

	if estremiProvincia is not null and estremiProvincia!='' then
    	strMessaggio:='Leggo estremiProvincia '||estremiProvincia||'.';
        /* 05.05.15 daniela: usiamo la funzione split_part
     	provDescri:=substring(estremiProvincia from 1 for position(SEPARATORE in estremiProvincia)-1);
 	 	provCode:=substring(estremiProvincia from
			                 position(SEPARATORE in estremiProvincia)+2
					         for char_length(estremiProvincia)-position(SEPARATORE in estremiProvincia));*/

         provDescri   := trim (both ' ' from split_part(estremiProvincia,SEPARATORE,1));
         provCode     := trim (both ' ' from split_part(estremiProvincia,SEPARATORE,2));
         if provCode = '' then provCode:=NULL; end if;
    end if;

	strMessaggio:='Lettura comune '||comuneDescri||'.';
    begin


-- DAVIDE - normalizzazione nome Comune in 3 fasi - Modifica alla query
-- 1) eliminare apici e spazi
-- 2) se ci sono vocali accentate, sostituirle con le vocali normali
-- 3) UPPER del Comune e confrontare 
/*    	select *  into comuneRec
	    from siac_t_comune comune
    	where upper(comune.comune_desc)=upper(comuneDescri) and */
              /*(
               (comune.comune_belfiore_catastale_code is not null and
               upper(comune.comune_belfiore_catastale_code) = COALESCE (comuneBelfiore, upper(comune.comune_belfiore_catastale_code)))
               or comune.comune_belfiore_catastale_code is null
               ) and */
--        	  comune.ente_proprietario_id=enteProprietarioId;
        select *  into comuneRec
  	    from siac_t_comune comune
      	where upper(
                    translate(replace(replace(comune.comune_desc, ' ', ''), '''', ''),
                    'ÇáÓüíßéóÔâúÒäñõàÑÕåªãµçÃþêÞëÚèÛïÙîýì¡ÝÄ�
É¶ÛæÐÆÊôËöÈ¶òÁi§ûÂÍùÀÎÿÏÖÜ',
                    'caouibeooauoanoanoaaaucapepeueuiuiyiiyaaetuedeeoeoetoaisuaiuaiyiou')) = upper(
					translate(replace(replace(comuneDescri, ' ', ''), '''', ''),
                            		 'ÇáÓüíßéóÔâúÒäñõàÑÕåªãµçÃþêÞëÚèÛïÙîýì¡ÝÄ�
É¶ÛæÐÆÊôËöÈ¶òÁi§ûÂÍùÀÎÿÏÖÜ', 
									 'caouibeooauoanoanoaaaucapepeueuiuiyiiyaaetuedeeoeoetoaisuaiuaiyiou')) and
          	  comune.ente_proprietario_id=enteProprietarioId 
              order by comune.data_creazione desc limit 1;
-- DAVIDE - Fine
			  
        if COALESCE(comuneRec.comune_id,0)=0 then
	    	begin
    	            strMessaggio:='Lettura nazione '||nazioneDescri||' per comune '||comuneDescri||'.';
					select *  into nazioneRec
				    from siac_t_nazione nazione
				    where upper(nazione.nazione_desc)=upper(nazioneDescri) and
			        	  nazione.ente_proprietario_id=enteProprietarioId;

                    if COALESCE(nazioneRec.nazione_id,0)=0 then
	                    	strMessaggio:='Inserimento nazione '||nazioneDescri||' per comune '||comuneDescri||'.';
					    	insert into siac_t_nazione
					        (nazione_code,nazione_desc, validita_inizio,
					         ente_proprietario_id, data_creazione,login_operazione
							)
						    VALUES
					        (upper(nazioneDescri),upper(nazioneDescri),dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
					        )
                            returning nazione_id into nazioneId;
                    else
                    	nazioneId=nazioneRec.nazione_id;
                    end if;
		 		   exception
					    when others then
					       RAISE EXCEPTION 'ERRORE : %-% ', SQLSTATE,	substring(upper(SQLERRM) from 1 for 100);
  		    end;


 		 -- DAVIDE - Testa anche che la descrizione del Comune non sia vuota
           --if COALESCE(nazioneId,0)!=0 then
           if COALESCE(nazioneId,0)!=0 and comuneDescri is not null then
         -- DAVIDE - Fine
              strMessaggio:='Inserimento comune '||comuneDescri||'.';
   			  insert into siac_t_comune
	          (comune_istat_code,comune_desc, validita_inizio,nazione_id,
			   ente_proprietario_id,data_creazione,login_operazione, comune_belfiore_catastale_code
		       )
		        values
		        (comuneCode,upper(comuneDescri),dataInizioVal,nazioneId,enteProprietarioId,clock_timestamp(),loginOperazione,upper(comuneBelfiore))
		 	      returning comune_id into comuneRetId;

               comuneNewId:=comuneRetId;
            end if;
 		else
       	    nazioneId:= comuneRec.nazione_id;
	        comuneRetId:= comuneRec.comune_id;

        end if;

        exception
            when others then
		       RAISE EXCEPTION 'ERRORE : %-% ',SQLSTATE,	substring(upper(SQLERRM) from 1 for 100);
    end;

    if provDescri!='' and provDescri is not null and provDescri!=COD_ESTERO and
       comuneNewId!=0 then
   		begin
        	strMessaggio:='Lettura provincia '||provDescri||' per comune '||comuneDescri||' nazione '||nazioneDescri||'.';
        	select * into provinciaRec
            from siac_t_provincia provincia
            where upper(provincia.sigla_automobilistica)=upper(provDescri) and
	              provincia.ente_proprietario_id=enteProprietarioId;

			if COALESCE(provinciaRec.provincia_id,0)= 0 then
            	strMessaggio:='Inserimento provincia '||provDescri||' per comune '||comuneDescri||' nazione '||nazioneDescri||'.';
		    	insert into siac_t_provincia
		        (provincia_istat_code,provincia_desc, sigla_automobilistica,validita_inizio,ente_proprietario_id, data_creazione,login_operazione
				)
			    VALUES
			    (provCode,upper(provDescri),upper(provDescri),
                 dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione
			   )
               returning provincia_id into provinciaId;
            else
	            provinciaId:=provinciaRec.provincia_id;
            end if;


	        if provinciaId!=0 then
		    	strMessaggio:='Inserimento relazione tra provincia '||provDescri||' e comune '||comuneDescri||' di nazione '||nazioneDescri||'.';
	    		insert into siac_r_comune_provincia
		    	(comune_id,provincia_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
        		values
			    (comuneRetId,provinciaId,dataInizioVal,enteProprietarioId,clock_timestamp(),loginOperazione);
		    end if;


            exception
			    when others then
			      RAISE EXCEPTION 'ERRORE : %-% ', SQLSTATE,	substring(upper(SQLERRM) from 1 for 100);
	  end;
    end if;

    comuneId:= comuneRetId;
    codiceRisultato:= codRet;

    if comuneNewId!=0 then
	    messaggioRisultato:=strMessaggioFinale||'Comune '||comuneDescri||' inserito.';
    else
	    messaggioRisultato:=strMessaggioFinale||'Comune  '||comuneDescri||' reperito.';
    end if;



   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE :  %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 300);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :  '||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        comuneId:=null;
        return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 300);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB :'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 100) ;
        codiceRisultato:=-1;
        comuneId:=null;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;