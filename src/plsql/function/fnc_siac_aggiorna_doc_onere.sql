/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_aggiorna_doc_onere (
  enteproprietarioid integer,
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
    enteDenominazione    VARCHAR(500):='';
    onereCode            VARCHAR(200):='';

    TIPO_SPESA           CONSTANT varchar:='S';
    ONERE_TIPO           CONSTANT varchar:='SP';

    codResult            integer:=null;
    dataInizioVal        timestamp:=null;
    docId                integer:=null;
    onereId              integer:=null;

    totImporto           numeric:=null;

    Documenti            record;

BEGIN

    messaggioRisultato:='';
    codiceRisultato:=0;

    dataInizioVal:=date_trunc('DAY', dataelaborazione);

    BEGIN
        select k.ente_denominazione into strict enteDenominazione
          from siac_t_ente_proprietario k
         where k.ente_proprietario_id=enteproprietarioid;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Errore nella lettura dell''Ente Proprietario = %', enteproprietarioid::varchar;
    END;

    strMessaggioFinale:='Aggiornamento tavola siac_r_doc_onere per Ente Proprietario = '||enteDenominazione||'.';

    -- Ciclo sui documenti di spesa per ente_proprietario e per un determinato anno bilancio passato in input
    totImporto := 0;
    docId := 0;
    onereId := 0;
    onereCode := null;

    for Documenti IN
        ( select k.doc_id, k.doc_anno, k.doc_numero, k.doc_desc, l.subdoc_splitreverse_importo, m.sriva_tipo_code as onere_code
            from siac_t_doc k,  siac_t_subdoc l, siac_d_splitreverse_iva_tipo m
           where k.ente_proprietario_id=enteProprietarioId
             and l.ente_proprietario_id=k.ente_proprietario_id
             and m.ente_proprietario_id=k.ente_proprietario_id
             and k.doc_tipo_id in (select l.doc_tipo_id
                                     from siac_d_doc_tipo l
                                    where l.ente_proprietario_id=k.ente_proprietario_id
                                      and l.doc_fam_tipo_id in (select m.doc_fam_tipo_id
                                                                  from siac_d_doc_fam_tipo m
                                                                 where m.ente_proprietario_id=l.ente_proprietario_id
                                                                   and m.doc_fam_tipo_code=TIPO_SPESA))
             and l.doc_id=k.doc_id
             and (l.subdoc_splitreverse_importo != 0 or l.subdoc_splitreverse_importo != null)
             and m.sriva_tipo_code in (select n.sriva_tipo_code
                                         from siac_d_splitreverse_iva_tipo n
                                        where n.sriva_tipo_id in (select o.sriva_tipo_id
                                                                    from siac_r_subdoc_splitreverse_iva_tipo o
                                                                   where o.subdoc_id = l.subdoc_id))
           order by k.doc_id, m.sriva_tipo_code) loop

        if docId = 0 then
            -- primo giro : resetta le variabili interne
            docId := Documenti.doc_id;
            onereCode := Documenti.onere_code;
            totImporto := Documenti.subdoc_splitreverse_importo;

        elsif docId != Documenti.doc_id or onereCode != Documenti.onere_code then
            -- INSERISCI ONERE RELATIVO ALLE QUOTE PRECEDENTI
            -- Leggi il codice onere (onere_id)
            BEGIN
                select l.onere_id   into strict onereId
                  from siac_d_onere l
                 where l.ente_proprietario_id=enteProprietarioId
                   and l.onere_code=onereCode
                   and l.onere_tipo_id in (select k.onere_tipo_id
                                             from siac_d_onere_tipo k
                                            where k.ente_proprietario_id=l.ente_proprietario_id
                                              and k.onere_tipo_code=ONERE_TIPO);

            EXCEPTION
                WHEN OTHERS THEN
                    RAISE EXCEPTION 'Errore nella lettura del codice onere relativo al documento %', Documenti.doc_anno||'/'||Documenti.doc_numero||'/'||Documenti.doc_desc;
            END;

            -- Inserisci il record nella siac_r_doc_onere
            BEGIN
                INSERT INTO siac_r_doc_onere
                (doc_id,
                 onere_id,
                 importo_imponibile,
	             importo_carico_soggetto,
                 validita_inizio,
                 ente_proprietario_id,
                 login_operazione
                )
                values
                (docId,
                 onereId,
                 totImporto,
                 totImporto, -- 28.12.2016 Sofia
                 dataInizioVal::timestamp,
                 enteProprietarioId,
                 loginoperazione);

            EXCEPTION
                WHEN OTHERS THEN
                    RAISE EXCEPTION 'Errore nell''aggiornamento siac_r_doc_onere relativa al documento %', Documenti.doc_anno||'/'||Documenti.doc_numero||'/'||Documenti.doc_desc;
            END;

            -- Resetta le variabili interne
            if docId != Documenti.doc_id then
                docId := Documenti.doc_id;
            end if;

            onereCode := Documenti.onere_code;
            totImporto := Documenti.subdoc_splitreverse_importo;
        else
            totImporto := totImporto + Documenti.subdoc_splitreverse_importo;

        end if;

    end loop;

    if totImporto != 0 then
        -- INSERISCI ONERE RELATIVO ALL'ULTIMA QUOTA
        -- Leggi il codice onere (onere_id)
        BEGIN
            select l.onere_id   into strict onereId
              from siac_d_onere l
             where l.ente_proprietario_id=enteProprietarioId
               and l.onere_code=onereCode
               and l.onere_tipo_id in (select k.onere_tipo_id
                                         from siac_d_onere_tipo k
                                        where k.ente_proprietario_id=l.ente_proprietario_id
                                          and k.onere_tipo_code=ONERE_TIPO);

        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Errore nella lettura del codice onere relativo al documento %', Documenti.doc_anno||'/'||Documenti.doc_numero||'/'||Documenti.doc_desc;
        END;

        -- Inserisci il record nella siac_r_doc_onere
        BEGIN
            INSERT INTO siac_r_doc_onere
            (doc_id,
             onere_id,
             importo_imponibile,
             importo_carico_soggetto,
             validita_inizio,
             ente_proprietario_id,
             login_operazione
            )
            values (docId,
                    onereId,
                    totImporto,
                    totImporto, -- 28.12.2016 Sofia
                    dataInizioVal::timestamp,
                    enteProprietarioId,
                    loginoperazione);

        EXCEPTION
            WHEN OTHERS THEN
                RAISE EXCEPTION 'Errore nell''aggiornamento siac_r_doc_onere relativa al documento %', Documenti.doc_anno||'/'||Documenti.doc_numero||'/'||Documenti.doc_desc;
        END;

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