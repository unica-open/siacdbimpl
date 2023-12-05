/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_cancella_registrounico
( enteProprietarioId     integer,
  nomeEnte               varchar,
  annoRegistrazione      integer,
  tipiDocumento          varchar,
  loginOperazione        varchar,
  out codiceRisultato    integer,
  out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE
    strMessaggio       VARCHAR(1500):='';
    strMessaggioFinale VARCHAR(1500):='';
    cursor1            refcursor;

    recTipiDocumenti   record;
    recIdTipiDocumenti record;
    recRegistro        record;
    progrNumero        integer;
    sqlstringa         varchar;
    prima              boolean := true;

BEGIN

    strMessaggioFinale:='Cancellazione logica su registro unico per Ente='||nomeEnte||' - anno registrazione= '||annoRegistrazione||' - tipi documento= '||coalesce(tipiDocumento,'TUTTI')||'.';

    codiceRisultato:=0;
    messaggioRisultato:='';
    progrNumero :=1;

    sqlstringa := 'select l.doc_tipo_id from siac_d_doc_tipo l '||
                  'where l.ente_proprietario_id='||enteProprietarioId||'and l.doc_tipo_code not in (';
    
    -- Ciclo per anno e tipi documento
    for recTipiDocumenti IN 
    (SELECT tipo FROM regexp_split_to_table(tipiDocumento, ',') AS tipo
    )
    loop
        if prima = true then
            sqlstringa:=concat(sqlstringa,quote_literal(recTipiDocumenti.tipo));
            prima := false;
        else
            sqlstringa:=concat(sqlstringa,','||quote_literal(recTipiDocumenti.tipo));
        end if;
    end loop;

    -- Termina la query da eseguire
    sqlstringa:=concat(sqlstringa,')');

    open cursor1 for execute sqlstringa;
    loop
        FETCH cursor1 INTO recIdTipiDocumenti;
        EXIT WHEN NOT FOUND;

        for recRegistro IN 
        (select m.rudoc_registrazione_anno, m.doc_id
           from siac_t_registrounico_doc m
          where m.ente_proprietario_id=enteProprietarioId
            and m.doc_id in (select k.doc_id 
                               from siac_t_doc k
                              where k.ente_proprietario_id=enteProprietarioId
                                and k.doc_tipo_id = recIdTipiDocumenti.doc_tipo_id)
            and m.rudoc_registrazione_anno=annoRegistrazione
          order by m.rudoc_registrazione_numero
        )
        loop

            update siac_t_registrounico_doc m
               set (data_cancellazione, login_operazione)=
                   (now()::timestamp, loginOperazione)
             where m.ente_proprietario_id=enteProprietarioId
               and m.rudoc_registrazione_anno=recRegistro.rudoc_registrazione_anno
               and m.doc_id=recRegistro.doc_id;

            progrNumero := progrNumero + 1;

        end loop;

    end loop;

    close cursor1;

    messaggioRisultato:=upper(strMessaggioFinale||' - movimenti aggiornati='||(progrNumero-1)||' - OK.');
    return;

exception
    when RAISE_EXCEPTION THEN
         messaggioRisultato:=
            coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
         codiceRisultato:=-1;

        messaggioRisultato:=upper(messaggioRisultato);
        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
    when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;