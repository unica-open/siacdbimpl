/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- FUNCTION: siac.fnc_fasi_bil_gest_reimputa(integer, integer, character varying, timestamp without time zone, character varying, character varying)

-- DROP FUNCTION siac.fnc_fasi_bil_gest_reimputa(integer, integer, character varying, timestamp without time zone, character varying, character varying);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	impostaprovvedimento character varying DEFAULT 'true'::character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying)
    RETURNS record
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE

	strMessaggio       VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';                                                                                                                                                           
	codResult          integer;  
    faseRec             record; 
    v_motivo           VARCHAR(1500):='';                                                                                                                                                           

BEGIN

    outfasebilelabretid:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    v_motivo:=TRIM(SUBSTR(p_movgest_tipo_code,3,6)); 

    if SUBSTR(p_movgest_tipo_code,1,1) = 'I' or SUBSTR(p_movgest_tipo_code,1,1) = 'E' then  
       strMessaggioFinale:='1 - Reimputazione Principale (Impieghi) a partire anno = '||annoBilancio::varchar||'.';
 
	   select * into faseRec   
         from fnc_fasi_bil_gest_reimputa_sing
    	     (                           
               enteProprietarioId,
               annoBilancio,
               loginOperazione,
               p_dataElaborazione,
               'I',
               v_motivo,
               impostaProvvedimento 
              );                   
       if faseRec.codiceRisultato=-1  then  
          strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;   
          raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;  
          return;  
       end if;   
       outfasebilelabretid:=faseRec.outfasebilelabretid;
    end if;   



    if SUBSTR(p_movgest_tipo_code,1,1) = 'A' or SUBSTR(p_movgest_tipo_code,1,1) = 'E' then 
       strMessaggioFinale:='2 - Reimputazione Principale Accertamenti a partire anno = '||annoBilancio::varchar||'.'; 
 
  	   select * into faseRec   
         from fnc_fasi_bil_gest_reimputa_sing
    	     (                           
              enteProprietarioId,
              annoBilancio,
              loginOperazione,
              p_dataElaborazione,
              'A',
              v_motivo,
              impostaProvvedimento 
              );                   
       if faseRec.codiceRisultato=-1  then  
          strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;   
          raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;  
          return;  
       end if;   
       if SUBSTR(p_movgest_tipo_code,1,1) = 'A' then
          outfasebilelabretid:=faseRec.outfasebilelabretid;
       end if;
	end if;


    if SUBSTR(p_movgest_tipo_code,1,1) = 'E' then 
       strMessaggioFinale:='3 - Reimputazione Principale Vincoli a partire anno = '||annoBilancio::varchar||'.';  
 
       select * into faseRec                                                                                                                                                                           
         from fnc_fasi_bil_gest_reimputa_vincoli
         	 (                                                                                                                                                                                          
              enteProprietarioId,
              annoBilancio,
              loginOperazione,
              p_dataElaborazione
              );                                                                                                                                                                                      
        if faseRec.codiceRisultato=-1  then                                                                                                                                                           
           strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;                                                                                                                      
           raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;                                                                                                                  
           return;                                                                                                                                                                                      
        end if; 
	end if;

    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
 
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$BODY$;

LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
