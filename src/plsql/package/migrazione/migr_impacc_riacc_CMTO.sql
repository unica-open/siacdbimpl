/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace procedure migrazione_impegno_riacc(p_ente_proprietario_id number,
                               p_anno_esercizio       varchar2,
                               p_tipo_cap             varchar2, -- se U mi chiedono di migrare gli impegni, se E mi chiedono di migrare gli accertamenti
                               p_cod_res              out number,
                               p_imp_inseriti         out number,
                               p_imp_scartati         out number,
                               msgResOut              out varchar2) is
    msgRes varchar2(1500) := null;
    codRes number := 0;
    h_impegno varchar2(50) := null;
    h_pdc_finanziario MIGR_CAPITOLO_USCITA.PDC_FIN_QUINTO%type := null;
    h_sogg_determinato varchar2(1):=null;
    h_sogg_migrato number := 0;
    h_codsogg_migrato varchar2(50) := null; -- codice soggetto migrato, corrisponde a fornitore.codice se soggetto di natura 0,1,2,3 ; fornitore.codice_rif se  soggetto di natura 4 (sempre che ci sia correispondenza su migr_soggetto)
    h_num number := 0;
    h_stato_impegno varchar2(1) := null;
    h_parere_finanziario integer := 1; -- non cambia rimane impostato a TRUE

    h_anno_provvedimento   varchar2(4) := null;
    h_numero_provvedimento varchar2(10) := null;
    h_anno_riacc           varchar2(4) := null;        -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
    h_numero_riacc         number(10) := null;         -- DAVIDE - 24.10.2016
    h_tipo_provvedimento   varchar2(20) := null;
    h_stato_provvedimento   varchar2(5) := null;
    h_direzione_provvedimento varchar2(10):=null;
    msgMotivoScarto varchar2(1500) := null;
    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;
    segnalare boolean:=false;
    h_classe_soggetto         varchar2(250):=null;  -- DAVIDE - 01.12.2016 - aggiunta classe_soggetto impostata solo per impegni/accertamenti legati a soggetti 999
    numLiquidazioni           number := 0;          -- DAVIDE - 01.12.2016

  begin
    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    msgResOut := 'Migrazione mov.gestione ['||p_tipo_cap||'].';
    msgRes    := 'Lettura mov.';

    dbms_output.put_line('Movimento= '||msgResOut);

    for migrImpegno in (select
                             -- mc.anno_esercizio  22.09.015 Sofia
                              --asm.anno_peg anno_esercizio
                              p_anno_esercizio anno_esercizio -- 30.01.2017 Sofia
                              , mc.anno_intervento anno_impegno
                              , mc.nro_movimento numero_impegno
                              , 0 numero_subimpegno
                              , mc.nro_intervento as numero_capitolo
                              , 0 numero_articolo
                              , 1 numero_ueb
                              , to_char(nvl(mc.data_inserimento,mc.data_ins_mov),'yyyy-MM-dd') data_emissione
                              , decode (mc.stato, 'P', 'P', 'D', 'P', ' ', 'D', NULL) stato_operativo
                              , nvl(asm.importo_impegno_orig,0) as importo_iniziale
                              , nvl(mc.importo,0) as importo_attuale
                              , replace(asm.oggetto,'''','''''') as descrizione
                              , mc.anno_delibera as anno_provvedimento
                              , mc.nro_delibera as numero_provvedimento
                              , a.tipo_doc as tipo_provvedimento
                              , a.cod_uffprop as direzione_provvedimento
                              , replace(a.ogg1||a.ogg2||a.ogg3||a.ogg4||a.ogg5,'''','''''') as oggetto_provvedimento
                              , replace(a.note,'''','''''') as note_provvedimento
                              , NULL as stato_provvedimento
                              , decode (trim(mc.cod_fornitore),NULL,'N','','N','999','N','S') as soggetto_determinato
                              , mc.cod_fornitore as codice_soggetto
                              , f.nat_giuridica
                              , f.codice_rif
                              , replace(mc.note,'''','''''')as nota
                              , mc.codice_cup as cup
                              , mc.codice_cig as cig
                              , 'SVI' as tipo_impegno
                              --, NULL as pdc_finanziario     -- DAVIDE - 24.10.2016
                              , asm.conto_118 pdc_finanziario -- DAVIDE - 24.10.2016
                              ,decode (mc.stato, 'P', 0, 'D', 1, ' ', 1, 0) as parere_finanziario
    -- DAVIDE - 16.12.015 - Popolamento campo siope (E/U)
                              , mc.codice_gest as siope
    -- DAVIDE - 16.12.015 - Fine
    -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
                              , asm.cofog
                              , asm.trans_eu
                              , asm.eu_ricor
                              , asm.nro_mov_267
    -- DAVIDE - 24.10.2016 - Fine
                        from movimento_contab_x2migr mc, as_movimenti_mandati asm, atto a, fornitore f
                        where asm.tipo_mov=1 -- 22.09.015 Sofia - modifica dopo incontro con Valenzano
                        and   asm.tipo_eu=p_tipo_cap
--                        and   asm.anno_peg=p_anno_esercizio
                        and   asm.anno_peg=p_anno_esercizio-1 -- 30.01.2017 Sofia per migrazione effettiva                        
                        --and   asm.disponibilita>0
                        --and   nvl(asm.residuo_da_riportare,0)>0  -- 22.09.015 Sofia - modifica dopo mail Valenzano
                        and  ( ( mc.anno_intervento<=p_anno_esercizio-1 and nvl(asm.residuo_da_riportare,0)>0 ) or -- Sofia 19.12.2016 x migrPluriennali
                                 mc.anno_intervento>p_anno_esercizio-1 -- 30.01.2017 Sofia 
                             )
                        and   mc.tipo_mov=asm.tipo_mov
                        and   mc.tipo_cap=asm.tipo_eu
                        and   mc.nro_movimento = asm.nro_movimento
                        and   a.anno_prot=mc.anno_delibera
                        and   a.nro_prot=mc.nro_delibera
                        and   f.codice(+)= mc.cod_fornitore
                        /*where mc.tipo_cap=p_tipo_cap  22.09.015 Sofia - modificata dopo incontro con Valenzano
                        and mc.anno_esercizio = p_anno_esercizio
                        and nvl(mc.importo,0)-nvl(mc.pag_anno_prec,0) > 0
                        and mc.tipo_mov = 1 -- IMPEGNI/ACCERTAMENTI
                        and mc.nro_movimento = asm.nro_movimento
                        and mc.anno_esercizio = asm.anno_peg
                        and mc.anno_delibera = a.anno_prot
                        and mc.nro_delibera = a.nro_prot*/
                        order by 2,3,4) loop

      if p_tipo_cap = 'U' then
         h_impegno := 'Impegno ' || migrImpegno.anno_impegno || '/' ||
                   migrImpegno.numero_impegno || '/' ||
                   migrImpegno.numero_ueb || '.';
      elsif p_tipo_cap = 'E' THEN
         h_impegno := 'Accertamento ' || migrImpegno.anno_impegno || '/' ||
                   migrImpegno.numero_impegno || '/' ||
                   migrImpegno.numero_ueb || '.';
      end if;
      
--      dbms_output.put_line('Movimento= '||h_impegno);
      
      codRes := 0;
      h_pdc_finanziario :=null;
      h_sogg_migrato := 0;
      h_codsogg_migrato := 0;
      h_num          := 0;
      h_stato_impegno:= null;
      msgMotivoScarto:= null;
      msgRes := null;
      h_anno_provvedimento   := null;
      h_numero_provvedimento := null;
      h_tipo_provvedimento   := null;
      h_stato_provvedimento   := null;
      h_direzione_provvedimento:=null;
      h_anno_riacc:=null;         -- DAVIDE - 24.10.2016
      h_numero_riacc:=null;       -- DAVIDE - 24.10.2016
      segnalare:=false; -- 22.09.015 Sofia
      h_classe_soggetto:=null;    -- DAVIDE - 01.12.2016
      numLiquidazioni := 0;       -- DAVIDE - 01.12.2016

      -- DAVIDE - 24.10.2016 - se dal ciclo precedente non si ricava il pdc_v,
      --                       tento di ricavarlo dal capitolo legato.
      if migrImpegno.pdc_finanziario is null then
          begin
              -- verifica capitolo migrato
              -- se esite il campo valorizzato PDC_FIN_QUINTO passa al campo  migr_impegno.PDC_FINANZIARIO
              msgRes := 'Lettura capitolo migrato.';
              -- recuperare pdc Vlivello PDC_FIN_QUINTO

              if p_tipo_cap = 'U' then
                  select
                      PDC_FIN_QUINTO into h_pdc_finanziario
                   from migr_capitolo_uscita m
                  where m.anno_esercizio = p_anno_esercizio
                    and m.numero_capitolo = migrImpegno.numero_capitolo
                    and m.numero_articolo =migrImpegno.numero_articolo
                    and m.numero_ueb = migrImpegno.numero_ueb
                    and m.tipo_capitolo = 'CAP-UG'
                    -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                    and m.ente_proprietario_id=p_ente_proprietario_id;
              elsif  p_tipo_cap = 'E' then
                  select
                      PDC_FIN_QUINTO into h_pdc_finanziario
                   from migr_capitolo_entrata m
                  where m.anno_esercizio = p_anno_esercizio
                    and m.numero_capitolo = migrImpegno.numero_capitolo
                    and m.numero_articolo =migrImpegno.numero_articolo
                    and m.numero_ueb = migrImpegno.numero_ueb
                    and m.tipo_capitolo = 'CAP-EG'
                    -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                    and m.ente_proprietario_id=p_ente_proprietario_id;
              end if;
          exception
              when no_data_found then
                  codRes := -1;
                  msgRes := 'Capitolo non migrato.';
          end;
      else
          h_pdc_finanziario := migrImpegno.pdc_finanziario;
      end if;

      -- Ricavo anno e numero riaccertato
      if codRes = 0 then
          begin
              select k.anno_capitolo, k.nro_movimento
                into h_anno_riacc, h_numero_riacc
                from as_movimenti_mandati k
               where k.anno_peg      = (p_anno_esercizio-1)
                 and k.nro_movimento = migrImpegno.nro_mov_267;
          exception
              when others then
                  h_anno_riacc:=null;
                  h_numero_riacc:=null;
          end;
      end if;
      -- DAVIDE - 24.10.2016 - Fine

      -- soggetto determinato, il soggetto deve essere stato migrato.

      -- 09.10.2015 se il soggetto associato è un ati, viene trattato come soggetto non determinato
      --if migrImpegno.nat_giuridica = 5 then h_sogg_determinato := 'N'; else h_sogg_determinato:=migrImpegno.soggetto_determinato; end if; -- DAVIDE - 02.12.2016 - soggetti con natura giuridica 5 sono migrati
    h_sogg_determinato:=migrImpegno.soggetto_determinato;

      if h_sogg_determinato = 'S' and codRes = 0 then
        msgRes := 'Verifica soggetto migrato.';

        --09.10.2015 dani
        begin
          if migrImpegno.nat_giuridica = 4 then
            select ms.codice_soggetto, nvl(count(*), 0)
            into h_codsogg_migrato, h_sogg_migrato
            from migr_soggetto ms
            where ms.codice_soggetto = migrImpegno.codice_rif
            and ente_proprietario_id = p_ente_proprietario_id
            group by ms.codice_soggetto;
          else
            select ms.codice_soggetto, nvl(count(*), 0)
            into h_codsogg_migrato, h_sogg_migrato
            from migr_soggetto ms
            where ms.codice_soggetto = migrImpegno.codice_soggetto
            and ente_proprietario_id = p_ente_proprietario_id
            group by ms.codice_soggetto;
          end if;
         exception
           when no_data_found then
                  codRes := -1;
                  msgRes := 'Soggetto determinato non migrato.';
         end;

        /* sostituito da parte sopra
        begin
          select ms.codice_soggetto, nvl(count(*), 0)
          into h_codsogg_migrato, h_sogg_migrato
          from migr_soggetto ms, fornitore f
          where f.codice = migrImpegno.codice_soggetto
          and
          ((f.nat_giuridica in (0,1,2,3) and ms.codice_soggetto=f.codice)
           or
           (f.nat_giuridica = 4 and ms.codice_soggetto=f.codice_rif)
          )
          and ente_proprietario_id = p_ente_proprietario_id
          group by ms.codice_soggetto;

         exception
           when no_data_found then
                  codRes := -1;
                  msgRes := 'Soggetto determinato non migrato.';
         end;*/

      end if;
      
      --  stato_impegno da calcolare
      if codRes = 0 then
        msgRes := 'Definizione stato.';
        h_stato_impegno := migrImpegno.stato_operativo;

        if (migrImpegno.soggetto_determinato = 'N' and h_stato_impegno = 'D') then
          h_stato_impegno := 'N'; -- Impegno non liquidabile se esecutivo senza soggetto determinato.
        end if;

    -- DAVIDE - 01.12.2016 - modifiche allo stato movimento se il soggetto è 999
      IF migrImpegno.codice_soggetto = '0' AND h_stato_impegno = 'D' THEN
        migrImpegno.codice_soggetto := null;
        h_stato_impegno := 'N';
      ELSIF migrImpegno.codice_soggetto = '0' THEN
        migrImpegno.codice_soggetto := null;
      END IF;
--      dbms_output.put_line('Movimento= '||h_impegno||' QUI QUI QUI');

      IF migrImpegno.codice_soggetto = '999' THEN

            IF h_stato_impegno = 'P' THEN
                migrImpegno.codice_soggetto := null;
            ELSIF h_stato_impegno = 'N' THEN
                NULL;
            ELSIF h_stato_impegno = 'D' THEN
                h_stato_impegno := 'N';
            END IF;

            -- Aggiungi la classe soggetto SOGGETTI DIVERSI
            IF h_stato_impegno = 'N' THEN
                h_classe_soggetto:='SOGGETTI DIVERSI||SOGGETTI DIVERSI||';
            END IF;
       END IF;

 
       /* if h_stato_impegno in (PCK_MIGRAZIONE_SIAC.STATO_IMPEGNO_P, PCK_MIGRAZIONE_SIAC.STATO_IMPEGNO_N) then
            -- controlla se ci sono liquidazioni legate a questi impegni
           begin
                select count(*)
                  into numLiquidazioni
                  from movimento_contab liq,
                  as_movimenti_mandati asm, atto a
                where liq.tipo_mov=3 -- Liquidazione
                and liq.tipo_cap=PCK_MIGRAZIONE_SIAC.TIPO_CAP_USCITA -- discrimina la liquidazione sull'impegno
                and liq.importo>0
                and migrImpegno.numero_impegno = liq.nro_mov_riferim
                and liq.tipo_mov=asm.tipo_mov
                and liq.tipo_cap=asm.tipo_eu
                and liq.nro_movimento = asm.nro_movimento
--                and asm.anno_peg=p_anno_esercizio -- parametro input
                and asm.anno_peg=p_anno_esercizio-1 -- parametro input 30.01.2017 Sofia
                and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
                and a.anno_prot=liq.anno_delibera
                and a.nro_prot=liq.nro_delibera;
            exception
                when others then null;
            end;

            -- se ci sono, occorre segnalare questo movimento
            IF numLiquidazioni <> 0 THEN
                IF migrImpegno.codice_soggetto <> '999' THEN
                    segnalare:=true;
                    msgMotivoScarto:='Movimento in stato '||h_stato_impegno||' con liquidazioni da migrare';
                END IF;
            END IF;

        end if;*/

    -- DAVIDE - 01.12.2016 - Fine

      end if;

--      dbms_output.put_line('Movimento= '||h_impegno||' QUI 2 ');

      -- provvedimento
      -- 22.09.015 Sofia
      if codRes=0 and segnalare = false then
       msgRes := 'Dati Provvedimento.';
       if migrImpegno.numero_provvedimento is null or
          migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != 'P' then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := 'SPR' || '||';
            h_stato_provvedimento:='D';

            -- 22.09.015 Sofia
            segnalare:=true;
            msgMotivoScarto:='Movimento in stato '||h_stato_impegno||' senza provvedimento';

          end if;
      else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          if migrImpegno.tipo_provvedimento is not null then
                    h_tipo_provvedimento   :=migrImpegno.tipo_provvedimento||'||';
          end if;
          h_direzione_provvedimento :=migrImpegno.direzione_provvedimento;
          if h_stato_impegno='N' then
             h_stato_provvedimento:='D';
          else
             h_stato_provvedimento:=h_stato_impegno;
          end if;
      end if;
     end if;

      if codRes = 0
      then
        if p_tipo_cap = 'U' then
    
          IF migrImpegno.codice_soggetto = '999' AND       -- DAVIDE - 14.12.2016 - Impegni legati a soggetti 999 devono avere stato definito
         h_stato_impegno = 'N'       THEN
             h_stato_impegno := 'D';
          END IF;
      
          msgRes := 'Inserimento in migr_impegno.';
--           dbms_output.put_line(msgRes||' Movimento= '||h_impegno);

          insert into migr_impegno
            (impegno_id,
             tipo_movimento,
             anno_esercizio,
             anno_impegno,
             numero_impegno,
             numero_subimpegno,
             numero_capitolo,
             numero_articolo,
             numero_ueb,
             data_emissione,
             stato_operativo,
             importo_iniziale,
             importo_attuale,
             descrizione,
             anno_provvedimento,
             numero_provvedimento,
             tipo_provvedimento,
             sac_provvedimento,
             oggetto_provvedimento,
             note_provvedimento,
             stato_provvedimento,
             soggetto_determinato,
             codice_soggetto,
             nota,
             tipo_impegno,
             --opera,
             pdc_finanziario,
             ente_proprietario_id,
             parere_finanziario
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
             , siope_spesa
    -- DAVIDE - 16.12.015 - Fine
    -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
             , cup
             , cig
             , cofog
             , transazione_ue_spesa
             , spesa_ricorrente
             , anno_impegno_riacc
             , numero_impegno_riacc
    -- DAVIDE - 24.10.2016 - Fine
             , classe_soggetto      -- DAVIDE - 01.12.2016 - aggiunta classe_soggetto impostata solo per impegni/accertamenti legati a soggetti 999
       )
          values
            (migr_impegno_id_seq.nextval,
             'I',
             migrImpegno.anno_esercizio,
             migrImpegno.anno_impegno,
             migrImpegno.numero_impegno,
             migrImpegno.numero_subimpegno,
             migrImpegno.numero_capitolo,
             migrImpegno.numero_articolo,
             migrImpegno.numero_ueb,
             migrImpegno.data_emissione,
             h_stato_impegno,
             migrImpegno.importo_iniziale,
             migrImpegno.importo_attuale,
             migrImpegno.descrizione,
             h_anno_provvedimento, -- 22.09.015 Sofia
             to_number(h_numero_provvedimento), -- 22.09.015 Sofia
             h_tipo_provvedimento, -- 22.09.015 Sofia
             h_direzione_provvedimento, -- 22.09.015 Sofia
             migrImpegno.oggetto_provvedimento,  -- 22.09.015 Sofia
             migrImpegno.note_provvedimento, -- 22.09.015 Sofia
             h_stato_provvedimento, -- 22.09.015 Sofia
             h_sogg_determinato,
             h_codsogg_migrato,
             migrImpegno.Nota,
             migrImpegno.Tipo_Impegno,
             --migrImpegno.opera,
             h_pdc_finanziario,
             p_ente_proprietario_id,
             migrImpegno.parere_finanziario -- 22.09.015 Sofia aggiunto parere finanziario
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
             , migrImpegno.siope
    -- DAVIDE - 16.12.015 - Fine
    -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
             , migrImpegno.cup
             , migrImpegno.cig
             , migrImpegno.cofog
             , migrImpegno.trans_eu
             , migrImpegno.eu_ricor
             , h_anno_riacc
             , h_numero_riacc
    -- DAVIDE - 24.10.2016 - Fine
             , h_classe_soggetto        -- DAVIDE - 01.12.2016 - aggiunta classe_soggetto impostata solo per impegni/accertamenti legati a soggetti 999
       );
        elsif p_tipo_cap = 'E' then
        
          IF migrImpegno.codice_soggetto = '999' AND       -- 27.02.2017 Sofia
                   h_stato_impegno = 'N'       THEN
                   h_stato_impegno := 'D';
          END IF;
          insert into migr_accertamento
            (accertamento_id,
             tipo_movimento,
             anno_esercizio,
             anno_accertamento,
             numero_accertamento,
             numero_subaccertamento,
             numero_capitolo,
             numero_articolo,
             numero_ueb,
             data_emissione,
             stato_operativo,
             importo_iniziale,
             importo_attuale,
             descrizione,
             anno_provvedimento,
             numero_provvedimento,
             tipo_provvedimento,
             sac_provvedimento,
             oggetto_provvedimento,
             note_provvedimento,
             stato_provvedimento,
             soggetto_determinato,
             codice_soggetto,
             nota,
             --opera,
             pdc_finanziario,
             ente_proprietario_id,
             parere_finanziario
  -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
             , siope_entrata
  -- DAVIDE - 16.12.015 - Fine
  -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
             , transazione_ue_entrata
             , entrata_ricorrente
             , anno_accertamento_riacc
             , numero_accertamento_riacc
  -- DAVIDE - 24.10.2016 - Fine
             , classe_soggetto      -- DAVIDE - 01.12.2016 - aggiunta classe_soggetto impostata solo per impegni/accertamenti legati a soggetti 999
       )
          values
            (migr_accertamento_id_seq.nextval,
             'A',
             migrImpegno.anno_esercizio,
             migrImpegno.anno_impegno,
             migrImpegno.numero_impegno,
             migrImpegno.numero_subimpegno,
             migrImpegno.numero_capitolo,
             migrImpegno.numero_articolo,
             migrImpegno.numero_ueb,
             migrImpegno.data_emissione,
             h_stato_impegno,
             migrImpegno.importo_iniziale,
             migrImpegno.importo_attuale,
             migrImpegno.descrizione,
             h_anno_provvedimento,
             to_number(h_numero_provvedimento),
             h_tipo_provvedimento,
             h_direzione_provvedimento, -- 22.09.015 Sofia
             migrImpegno.oggetto_provvedimento,
             migrImpegno.note_provvedimento,
             h_stato_provvedimento,
             h_sogg_determinato,
             h_codsogg_migrato,
             migrImpegno.Nota,
             --migrImpegno.opera,
             h_pdc_finanziario,
             p_ente_proprietario_id,
             migrImpegno.parere_finanziario
    -- DAVIDE - 16.12.015 - Popolamento campo siope_entrata
             , migrImpegno.siope
    -- DAVIDE - 16.12.015 - Fine
    -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
             , migrImpegno.trans_eu
             , migrImpegno.eu_ricor
             , h_anno_riacc
             , h_numero_riacc
    -- DAVIDE - 24.10.2016 - Fine
             , h_classe_soggetto        -- DAVIDE - 01.12.2016 - aggiunta classe_soggetto impostata solo per impegni/accertamenti legati a soggetti 999
       );
        end if;
        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0
         or segnalare = true then -- 22.09.015 Sofia
        if msgMotivoScarto is null then -- 22.09.015 Sofia
                msgMotivoScarto := msgRes;
        end if;
        if p_tipo_cap = 'U' then
        msgRes := 'Inserimento in migr_impegno_scarto.';
        insert into migr_impegno_scarto
          (impegno_scarto_id,
           anno_esercizio,
           anno_impegno,
           numero_impegno,
           numero_subimpegno,
           motivo_scarto,
           ente_proprietario_id)
        values
          (migr_impegno_scarto_id_seq.nextval,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_impegno,
           migrImpegno.numero_impegno,
           migrImpegno.numero_subimpegno,
           msgMotivoScarto,
           p_ente_proprietario_id);
        elsif p_tipo_cap = 'E' then
          msgRes := 'Inserimento in migr_accertamento_scarto.';
          insert into migr_accertamento_scarto
            (accertamento_scarto_id,
             anno_esercizio,
             anno_accertamento,
             numero_accertamento,
             numero_subaccertamento,
             motivo_scarto,
             ente_proprietario_id)
          values
            (migr_accert_scarto_id_seq.nextval,
             migrImpegno.anno_esercizio,
             migrImpegno.anno_impegno,
             migrImpegno.numero_impegno,
             migrImpegno.numero_subimpegno,
             msgMotivoScarto,
             p_ente_proprietario_id);
        end if;
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
    end loop;

    msgResOut      := msgResOut || 'Elaborazione OK.Movimenti inseriti=' ||
                      cImpInseriti || ' scartati=' || cImpScartati || '.';
    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;

    commit;
  exception
    when no_data_found then
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      msgResOut := msgResOut || h_impegno || msgRes || 'Record non trovato.';
      p_cod_res := -1;
    when others then
      dbms_output.put_line('Impegno ' || h_impegno || ' msgRes ' || msgRes ||
                           ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      p_cod_res      := -1;
  end migrazione_impegno_riacc;
/  
  
  
  
 create or replace  procedure migrazione_impacc_riacc (p_ente_proprietario_id number,
                               p_anno_esercizio varchar2,
                               p_cod_res out number,
                               msgResOut out varchar2)
    is
        v_imp_inseriti number := 0;
        v_imp_scartati number:= 0;
        v_codRes number := null;
        v_msgRes varchar2(1500) := '';   -- usato come variabile in cui concatenare tutti i mess di output delle procedure chiamate
        p_msgRes varchar2(1500) := null; -- passato come parametro alle procedure locali
    begin
        msgResOut := 'Oracle.Migrazione Impegni/Accertamenti da riaccertamento residui.';
        v_codRes := 0;

        -- controllo sulla presenza dei parametri in input
        if (p_ente_proprietario_id is null or p_anno_esercizio is null) then
            v_codRes := -1;
            v_msgRes := 'Uno o più parametri in input non sono stati valorizzati correttamente';
        end if;

        -- pulizia delle tabelle migr_
        begin
            v_msgRes := 'Pulizia tabelle di migrazione.';

            DELETE FROM MIGR_ACCERTAMENTO_SCARTO
            where ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_IMPEGNO_SCARTO
            where ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_IMPEGNO WHERE FL_MIGRATO = 'N'
            and ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_ACCERTAMENTO WHERE FL_MIGRATO = 'N'
            and ente_proprietario_id=p_ente_proprietario_id;

        exception when others then
                rollback;
                v_codRes := -1;
                v_msgRes := v_msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        end;

        if v_codRes = 0 then
            -- 1) Impegni
            v_msgRes:='Migrazione impegni.';
            migrazione_impegno_riacc(p_ente_proprietario_id, p_anno_esercizio,'U', v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;

        if v_codRes = 0 then
            -- 1) Accertamenti
--            migrazione_accertamento(p_ente_proprietario_id, p_anno_esercizio, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes:='Migrazione accertamenti.';
            migrazione_impegno_riacc(p_ente_proprietario_id, p_anno_esercizio,'E', v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;

        -- 31.01.2017 Sofia update su migr per gestione pluriennali        
        if v_codRes=0 then
          v_msgRes:='Update anno_esercizio su migr_impegno.';
          update migr_impegno migr
          set    anno_esercizio=anno_impegno
          where  migr.ente_proprietario_id=p_ente_proprietario_id
          and    migr.anno_esercizio=p_anno_esercizio
          and    migr.anno_impegno>p_anno_esercizio
          and    migr.fl_migrato='N';
          
          v_msgRes:='Update anno_esercizio su migr_impegno_scarto.';          
          update migr_impegno_scarto migr
          set    anno_esercizio=anno_impegno
          where  migr.ente_proprietario_id=p_ente_proprietario_id
          and    migr.anno_esercizio=p_anno_esercizio
          and    migr.anno_impegno>p_anno_esercizio;

          v_msgRes:='Update anno_esercizio su migr_accertamento.';
          update migr_accertamento migr
          set    anno_esercizio=anno_accertamento
          where  migr.ente_proprietario_id=p_ente_proprietario_id
          and    migr.anno_esercizio=p_anno_esercizio
          and    migr.anno_accertamento>p_anno_esercizio
          and    migr.fl_migrato='N';
          
          v_msgRes:='Update anno_esercizio su migr_accertamento_scarto.';
          update migr_accertamento_scarto migr
          set    anno_esercizio=anno_accertamento
          where  migr.ente_proprietario_id=p_ente_proprietario_id
          and    migr.anno_esercizio=p_anno_esercizio
          and    migr.anno_accertamento>p_anno_esercizio;
        end if;
        
        commit;
        
        p_cod_res := v_codRes;
        msgResOut := msgResOut|| v_msgRes;
        if p_cod_res = 0 then
            msgResOut := msgResOut||'Migrazione completata.';
        else
            msgResOut := msgResOut||p_cod_res;
        end if;
        commit;
     exception when others then
        msgResOut := msgResOut || v_msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        p_cod_res := -1;
end migrazione_impacc_riacc;
/
