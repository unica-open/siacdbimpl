/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_rinumera_registrounico
( enteProprietarioId     integer,
  nomeEnte               varchar,
  annoRegistrazione      integer,
  tipiDocumento          varchar,  -- vanno passati in questo modo : quote_literal('FAT') oppure quote_literal('FAT')||', '||quote_literal('FPR')||', '||quote_literal('NCD')||', '||quote_literal('NTE')
  loginOperazione        varchar,
  aggiorna_docnum        boolean,
  out codiceRisultato    integer,
  out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE
    strMessaggio       VARCHAR(1500):='';
    strMessaggioFinale VARCHAR(1500):='';

    recTipiDocumenti   record;
    recRegistro        record;
    progrNumero        integer;
    MaxNumero          integer;
    idTipodoc          integer;
BEGIN

    strMessaggioFinale:='Rinumerazione registro unico per Ente='||nomeEnte||' - anno registrazione= '||annoRegistrazione||' - tipi documento= '||coalesce(tipiDocumento,'TUTTI')||'.';

    codiceRisultato:=0;
    messaggioRisultato:='';
    progrNumero :=1;

    -- Cerca la numerazione dei documenti per Ente, anno e tipi documento  
    -- se + di 1 tipo passato, spezzare con split (ciclo ulteriore)
    if tipiDocumento is not null then
        for recTipiDocumenti IN 
        (SELECT tipo FROM regexp_split_to_table(tipiDocumento, ',') AS tipo
        )
        loop
            -- Lettura dell'id tipo documento
            select l.doc_tipo_id 
              into idTipodoc
              from siac_d_doc_tipo l
             where l.ente_proprietario_id=enteProprietarioId
               and l.doc_tipo_code=recTipiDocumenti.tipo;

            -- Ciclo per anno e tipi documento
            for recRegistro IN 
            (select * 
               from siac_t_registrounico_doc m
              where m.ente_proprietario_id=enteProprietarioId
                and m.doc_id in (select k.doc_id from siac_t_doc k
                                  where k.ente_proprietario_id=enteProprietarioId
                                    and k.doc_tipo_id=idTipodoc)
                and m.rudoc_registrazione_anno=annoRegistrazione
              order by m.rudoc_registrazione_numero
            )
            loop
                update siac_t_registrounico_doc m
                   set (rudoc_registrazione_numero, data_modifica, login_operazione)=
                       (progrNumero, now()::timestamp, loginOperazione)
                 where m.ente_proprietario_id=enteProprietarioId
                   and m.rudoc_registrazione_anno=recRegistro.rudoc_registrazione_anno
                   and m.doc_id=recRegistro.doc_id;

                progrNumero := progrNumero + 1;           
            end loop;

        end loop;

    else
        -- Ciclo solo per anno
        for recRegistro IN 
        (select * from siac_t_registrounico_doc m
          where m.ente_proprietario_id=enteProprietarioId
            and m.rudoc_registrazione_anno=annoRegistrazione
            and m.data_cancellazione is null
          order by m.rudoc_registrazione_numero
        )
        loop
            update siac_t_registrounico_doc m  
               set (rudoc_registrazione_numero, data_modifica, login_operazione)=
                   (progrNumero, now()::timestamp, loginOperazione)
             where m.ente_proprietario_id=enteProprietarioId
               and m.rudoc_registrazione_anno=recRegistro.rudoc_registrazione_anno
               and m.doc_id=recRegistro.doc_id;

            progrNumero := progrNumero + 1;           
        end loop;

    end if;

    if aggiorna_docnum = true then
        -- Trova il massimo numero di registrazione per l'anno in esame
        select max(n.rudoc_registrazione_numero)
          into MaxNumero
          from siac_t_registrounico_doc n
         where n.ente_proprietario_id=enteProprietarioId 
           and n.rudoc_registrazione_anno=annoRegistrazione;    
    
        update siac_t_registrounico_doc_num m
           set (rudoc_registrazione_numero, data_modifica, login_operazione)= 
               (MaxNumero, now()::timestamp, loginOperazione)
         where m.ente_proprietario_id=enteProprietarioId
           and m.rudoc_registrazione_anno=annoRegistrazione;
    end if;

    messaggioRisultato:=upper(strMessaggioFinale||' - OK.');
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