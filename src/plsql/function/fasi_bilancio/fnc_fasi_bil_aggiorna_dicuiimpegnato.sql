/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 13.09.2016 Davide - aggiornamento della tavola siac_t_dicuiimpegnato_bilprev
-- 13.09.2016 Davide - chiamata da fnc_fasi_bil_aggiorna_importi_bilprev.

CREATE OR REPLACE FUNCTION fnc_fasi_bil_aggiorna_dicuiimpegnato (
  annobilancio integer,
  bilancioid integer,
  prevelemid integer,
  gestelemid integer,
  enteproprietarioid integer,
  faseep boolean,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

    strMessaggio         VARCHAR(1500):='';
    strMessaggioFinale   VARCHAR(1500):='';

    codResult            integer:=null;
    esistecap            integer:=0;
    --dataInizioVal      timestamp:=null;
    IdImpbilprev         numeric:= null;

	-- Importi
	capDicuiimpegnatoAnno1 numeric := 0;
	capDicuiimpegnatoAnno2 numeric := 0;
	capDicuiimpegnatoAnno3 numeric := 0;

    calcdicuiimpe        record;

BEGIN

    messaggioRisultato:='';
    codiceRisultato:=0;

	raise notice 'annoBilancio=% faseEP=% ', annoBilancio,faseEP;
    --dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;
    strMessaggioFinale:='Aggiornamento importi dicuiimpegnato da capitoli equivalenti Gestione.Anno bilancio='||annoBilancio::varchar||'.';
    begin
        -- ricava dicuiimpegnato_anno1,dicuiimpegnato_anno2,dicuiimpegnato_anno3
        -- utilizzando le funzioni fnc_siac_dicuiimpegnatoup_anno1, fnc_siac_dicuiimpegnatoup_anno2
		-- fnc_siac_dicuiimpegnatoup_anno3
        select * into calcdicuiimpe
          from fnc_siac_dicuiimpegnatoup_comp_anno_fasi (prevelemid,annoBilancio::varchar,faseEP);

        capDicuiimpegnatoAnno1 := calcdicuiimpe.dicuiimpegnato;

        select * into calcdicuiimpe
          from fnc_siac_dicuiimpegnatoup_comp_anno_fasi (prevelemid,(annoBilancio+1)::varchar,faseEP);

        capDicuiimpegnatoAnno2 := calcdicuiimpe.dicuiimpegnato;

        select * into calcdicuiimpe
          from fnc_siac_dicuiimpegnatoup_comp_anno_fasi (prevelemid,(annoBilancio+2)::varchar,faseEP);

        capDicuiimpegnatoAnno3 := calcdicuiimpe.dicuiimpegnato;

        -- Inserisci il capitolo sulla tavola
        IdImpbilprev := 0;

        insert into siac_t_dicuiimpegnato_bilprev
            (bil_id, elem_id, dicuiimpegnato_anno1, dicuiimpegnato_anno2,
             dicuiimpegnato_anno3, ente_proprietario_id, data_creazione,
             login_operazione)
        values
            (bilancioid, prevelemid, capDicuiimpegnatoAnno1, capDicuiimpegnatoAnno2,
			 capDicuiimpegnatoAnno3, enteProprietarioId, clock_timestamp(),
			 loginOperazione)
        returning impbilprev_id into IdImpbilprev;

    exception
        when others then null;
    end;

    -- Controlla inserimento ok
    if IdImpbilprev = 0 then
        RAISE EXCEPTION 'Errore nell''inserimento siac_t_dicuiimpegnato_bilprev.';
    end if;

    messaggioRisultato:=strMessaggioFinale||'OK .';
    return;

exception
    when RAISE_EXCEPTION THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
                substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

    when no_data_found THEN
        raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        return;
    when others  THEN
        raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
                substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;