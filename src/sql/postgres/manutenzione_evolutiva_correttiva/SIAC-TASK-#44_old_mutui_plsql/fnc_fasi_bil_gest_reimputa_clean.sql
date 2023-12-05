/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid         INTEGER,
                                                              enteproprietarioid      integer,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR );
															  
CREATE OR replace FUNCTION fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid         INTEGER,
                                                              enteproprietarioid      integer,
                                                              OUT outfasebilelabretid INTEGER,
                                                              OUT codicerisultato     INTEGER,
                                                              OUT messaggiorisultato  VARCHAR ) returns RECORD
AS
  $body$
  DECLARE
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    reimputazioneRec  record;
  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio clean.';

    FOR reimputazionerec IN
    (
           SELECT reimputazione_id,
                  movgestnew_ts_id,
      		      movgestnew_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'X' )
    LOOP

        strmessaggio :='cancellazione [siac_r_movgest_bil_elem] con movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar||'.';
        DELETE from  siac_r_movgest_bil_elem where movgest_id = reimputazionerec.movgestnew_id  ;

        if reimputazionerec.movgestnew_ts_id IS not null then
          strmessaggio :='cancellazione [siac_r_movgest_ts_stato] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_stato where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_class] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_class where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_attr] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_attr where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_atto_amm] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_atto_amm where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_sog] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_sog where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_sogclasse] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_sogclasse where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_movgest_ts_programma] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_movgest_ts_programma where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

		  /** 	 16.03.2023 Sofia SIAC-TASK-#44
          strmessaggio :='cancellazione [siac_r_mutuo_voce_movgest] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_mutuo_voce_movgest where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;
		  **/

          strmessaggio :='cancellazione [siac_r_causale_movgest_ts] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_causale_movgest_ts where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_subdoc_movgest_ts] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_subdoc_movgest_ts where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_r_predoc_movgest_ts] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_r_predoc_movgest_ts where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_t_movgest_ts_det] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_t_movgest_ts_det where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;

          strmessaggio :='cancellazione [siac_t_movgest_ts] movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar ||' reimputazionerec.movgestnew_ts_id'|| reimputazionerec.movgestnew_ts_id||'.';
          DELETE from  siac_t_movgest_ts where movgest_ts_id = reimputazionerec.movgestnew_ts_id  ;
        end if;

        strmessaggio :='cancellazione [siac_t_movgest] con movgestnew_id -->'||reimputazionerec.movgestnew_id::varchar||'.';
        DELETE from  siac_t_movgest where movgest_id = reimputazionerec.movgestnew_id  ;

    END LOOP;
    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;
  
  alter function  fnc_fasi_bil_gest_reimputa_clean( INTEGER, integer, OUT  INTEGER, OUT  INTEGER,OUT  VARCHAR ) owner to siac;	