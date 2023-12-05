/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- PACKAGE MIGRAZIONE SOGGETTI REGP
CREATE OR REPLACE PACKAGE BODY PCK_MIGRAZIONE_SOGGETTI_SIAC IS

  function fnc_migrazione_mod_accredito(p_ente_proprietario_id number,
                                        p_msg_res              out varchar2)
    return number is

    msgRes            varchar2(1500) := null;
    codRes            integer := 0;
    tipoAccreditoSiac varchar2(10) := '';
    decodificaOIL     varchar2(150) := '';
  begin

    msgRes:='Migrazione modalita di accredito.Pulizia migr_mod_accredito.';
  -- DAVIDE : operazioni sulle tabelle di migrazione filtrate per ente_id
    --delete migr_mod_accredito where fl_migrato='N';
    delete migr_mod_accredito
   where fl_migrato='N'
     and ente_proprietario_id=p_ente_proprietario_id;
  -- DAVIDE fine
    commit;

    msgRes := 'Migrazione modalita di accredito.';

    for modAccredito in (select distinct t.codaccre, t.descri
                           from tabaccre t
                          where 0 != (select count(*)
                                      from migr_modpag m
                                      where m.codice_accredito = t.codaccre
                                        and m.ente_proprietario_id = p_ente_proprietario_id
                                        and m.fl_migrato = 'N')
                                      order by 1) loop
      decodificaOIL := '';

      if modAccredito.codaccre in (CODACCRE_CB, CODACCRE_BP, CODACCRE_CD, CODACCRE_BD) then
         tipoAccreditoSiac := SIAC_TIPOACCRE_CB;
      elsif modAccredito.codaccre = CODACCRE_CT then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CO;
      elsif modAccredito.codaccre in (CODACCRE_CP, CODACCRE_PP) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CCP;
      elsif modAccredito.codaccre in (CODACCRE_CC, CODACCRE_PE) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CSI;
--      elsif modAccredito.codaccre in (CODACCRE_CD, CODACCRE_BD) then
--        tipoAccreditoSiac := SIAC_TIPOACCRE_CSC;
      elsif modAccredito.codaccre = CODACCRE_GF then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CBI;
                    -- DAVIDE : inserire modalit� accredito per CRP, EDISU, ARPEA, APL, ARAI, PARCHI
      elsif modAccredito.codaccre in (CODACCRE_BE, CODACCRE_FT, CODACCRE_GC, CODACCRE_QD, CODACCRE_SP,
                                      CODACCRE_LA, CODACCRE_MV, CODACCRE_TB, CODACCRE_ST, CODACCRE_DB,
                                      CODACCRE_D3, CODACCRE_MD, CODACCRE_MS, CODACCRE_RC, CODACCRE_RP,
                                      CODACCRE_CO, CODACCRE_CR, CODACCRE_PR, CODACCRE_VA, CODACCRE_WU,
                                      CODACCRE_AE, CODACCRE_BA, CODACCRE_DA, CODACCRE_EA, CODACCRE_PO,
                                      CODACCRE_RB, CODACCRE_RD, CODACCRE_SE, CODACCRE_TS, CODACCRE_F4,
                                      CODACCRE_FV, CODACCRE_GI, CODACCRE_IE, CODACCRE_CA, CODACCRE_GG,
                                      CODACCRE_GR, CODACCRE_RE, CODACCRE_RA, CODACCRE_BB, CODACCRE_GB,
                                      CODACCRE_SS, CODACCRE_AT, CODACCRE_CS, CODACCRE_EP, CODACCRE_MP,
                                      CODACCRE_ID, CODACCRE_BL, CODACCRE_DC, CODACCRE_DM, CODACCRE_EU,
                                      CODACCRE_MA, CODACCRE_VT
                                      -- 21.12.2015 Spostate da CO a GE
                                      ,CODACCRE_F2, CODACCRE_F3, CODACCRE_FI, CODACCRE_RI,
                                      CODACCRE_AB, CODACCRE_AC, CODACCRE_AS, CODACCRE_AI, CODACCRE_AP,
                                      CODACCRE_CE, CODACCRE_CI, CODACCRE_DP, CODACCRE_MF, CODACCRE_PC,
                                      CODACCRE_TE, CODACCRE_TT, CODACCRE_QT, CODACCRE_TC,
                                      CODACCRE_AV, CODACCRE_AD, CODACCRE_QP) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_GE;
      else
        tipoAccreditoSiac := SIAC_TIPOACCRE_ND;
      end if;

      begin
        select t1.codaccre_tes || '||' || t1.descri
          into decodificaOIL
          from tabaccre_modpag_tes t1
         where t1.codaccre = modAccredito.codaccre;
      exception
        when NO_DATA_FOUND then
          null;
        when others then
          null;
      end;

      msgRes := 'Migrazione modalita di accredito.Inserimento modalita ' || modAccredito.codaccre;

      insert into migr_mod_accredito
        (accredito_id,
         codice,
         descri,
         tipo_accredito,
         priorita,
         decodificaOIL,
         ente_proprietario_id)
      values
        (migr_accredito_id_seq.nextval,
         modAccredito.codaccre,
         modAccredito.descri,
         tipoAccreditoSiac,
         0,
         decodificaOIL,
         p_ente_proprietario_id);

    end loop;

    p_msg_res := 'Migrazione modalita di accredito OK';
    return codRes;

  exception
    when others then
      p_msg_res := msgRes || ' ' || SQLCODE || '-' ||
                   SUBSTR(SQLERRM, 1, 100) || '.';
      codRes    := -1;
      return codRes;
  end fnc_migrazione_mod_accredito;

  procedure migrazione_soggetto_temp(p_ente           number,
                                     p_anno_esercizio varchar2,
                                     p_anni           number,
                                     pCodRes out number,
                                     pMsgRes out varchar2) is

    h_anno_inizio_migr varchar2(4) := null;
    codRes number:=0;
    msgRes varchar2(1500):=null;
  begin

    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.';

    h_anno_inizio_migr := to_char(to_number(p_anno_esercizio) - p_anni);


    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Pulizia soggetto_temp.';
    delete migr_soggetto_temp;
    -- la chiave della tabella e composta dal codice_soggetto.
    -- where ente_proprietario_id=p_ente;

    commit;


    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Inserimento soggetti con ORD/REV da '||p_anni||' anni.';
    -- soggetti validi che hanno ordinativi a partire da un certo anno in poi escludendo BBE,AST ( bonus beb� e buoni scuola )
    insert into migr_soggetto_temp
      (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'ORD', p_ente
        from fornitori f
       where f.blocco_pag = 'N'
         and (f.classben is null or
             (f.classben is not null and f.classben not in ('BBE', 'AST')))
         and ((f.codben in (select m.codben
                              from mandati m
                             where m.anno_esercizio >= h_anno_inizio_migr
                               and m.staoper != 'A') or
             f.codben in
             (select b.codben_ceduto
                  from beneficiari b, fornitori f1, mandati m
                 where b.codben_ceduto != 0
                   and f1.codben = b.codben
                   and f1.blocco_pag = 'N'
                   and b.blocco_pag = 'N'
                   and m.codben = b.codben
                   and m.progben = b.progben
                   and m.staoper != 'A'
                   and m.anno_esercizio >= h_anno_inizio_migr)) OR
             f.codben in (select r.codben
                             from riscossioni r
                            where r.anno_esercizio >= h_anno_inizio_migr
                              and r.staoper != 'A'));

    -- cedenti
    insert into migr_soggetto_temp
      (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'ORD', p_ente
        from fornitori f
       where f.blocco_pag = 'N'
         and (f.classben is null or
             (f.classben is not null and f.classben not in ('BBE', 'AST')))
         and f.codben in
             (select b.codben_cedente
                from beneficiari b, fornitori f1, mandati m
               where b.codben_cedente != 0
                 and f1.codben = b.codben
                 and f1.blocco_pag = 'N'
                 and b.blocco_pag = 'N'
                 and m.codben = b.codben
                 and m.progben = b.progben
                 and m.staoper != 'A'
                 and m.anno_esercizio >= h_anno_inizio_migr)
         and f.codben not in
             (select codice_soggetto from migr_soggetto_temp
			  where ente_proprietario_id=p_ente);

    commit;

    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti collegati ad impegni/accertamenti nell'' anno.';
    -- impegni/accertamenti - su soggetti anche non validi ma da migrare poich� migreranno impegni/accertamenti
    insert into migr_soggetto_temp
      (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'IAC', p_ente
        from fornitori f
       where f.blocco_pag != 'P'
-- DAVIDE - 19.11.015 - soggetti presi anche su Impegni / Accertamenti Pluriennali
         /*and (f.codben in (select codben  from impegni      where anno_esercizio = p_anno_esercizio and staoper != 'A') or
              f.codben in (select codben  from accertamenti where anno_esercizio = p_anno_esercizio and staoper != 'A') or
              f.codben in (select codben  from subimp       where anno_esercizio = p_anno_esercizio and staoper != 'A') or
              f.codben in (select codben  from subacc       where anno_esercizio = p_anno_esercizio and staoper != 'A'))*/
         and (f.codben in (select codben  from impegni      where anno_esercizio >= p_anno_esercizio and staoper != 'A') or
              f.codben in (select codben  from accertamenti where anno_esercizio >= p_anno_esercizio and staoper != 'A') or
              f.codben in (select codben  from subimp       where anno_esercizio >= p_anno_esercizio and staoper != 'A') or
              f.codben in (select codben  from subacc       where anno_esercizio >= p_anno_esercizio and staoper != 'A'))
-- DAVIDE - 19.11.015 - Fine
         and f.codben not in (select codice_soggetto from migr_soggetto_temp
		                      where ente_proprietario_id=p_ente);


    commit;

    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti con liquidazioni nell'' anno.';
    -- liquidazioni dell'anno di migrazione, prendendo eventualmente anche BBE e AST
    -- anche bloccati perch�  potrebbero avere bloccato il soggetto o la MDP ma la liquidazione esiste
    -- quindi deve esistere anche il soggetto e la relativa MDP
    -- questi soggetti dovranno essere pagati !
    insert into migr_soggetto_temp
   (codice_soggetto, motivo, ente_proprietario_id)
    select distinct f.codben, 'LIQ', p_ente
    from fornitori f
    where f.blocco_pag != 'P'
       and (f.codben in (select codben from liquidazioni where anno_esercizio = p_anno_esercizio and staoper != 'A') or
             f.codben in (select b.codben_ceduto from beneficiari b, fornitori f1, liquidazioni m
                          where b.codben_ceduto != 0
                           and f1.codben = b.codben
                           and f1.blocco_pag != 'P'
                           and b.blocco_pag != 'P'
                           and m.codben = b.codben
                           and m.progben = b.progben
                           and m.staoper != 'A'
                           and m.anno_esercizio = p_anno_esercizio))
         and f.codben not in (select codice_soggetto from migr_soggetto_temp
		                      where ente_proprietario_id=p_ente);

    -- cedenti
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
    select distinct f.codben, 'LIQ', p_ente
    from fornitori f where f.blocco_pag != 'P'
         and f.codben in (select b.codben_cedente
                          from beneficiari b, fornitori f1, liquidazioni m
                          where b.codben_cedente != 0
                            and f1.codben = b.codben
                            and f1.blocco_pag != 'P'
                            and b.blocco_pag != 'P'
                            and m.codben = b.codben
                            and m.progben = b.progben
                            and m.staoper != 'A'
                            and m.anno_esercizio = p_anno_esercizio)
         and f.codben not in (select codice_soggetto from migr_soggetto_temp
		                      where ente_proprietario_id=p_ente);
  commit;

  msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti con carte contabili nell''anno.';
  -- soggetti anche bloccati legati a movimenti nell'anno -- probabilmente in ottica di migrazione in corso di un anno
  -- carte contabili dell'anno di migrazione, prendendo eventualmente anche BBE e AST
  -- anche bloccati perch�  potrebbero avere bloccato il soggetto o la MDP ma la carta esiste
  -- quindi deve esistere anche il soggetto e la relativa MDP
  insert into migr_soggetto_temp
  (codice_soggetto,motivo,ente_proprietario_id)
  select distinct f.codben,'CAC',p_ente
  from fornitori f
  where f.blocco_pag!='P' and
        f.codben in (select codben from carte_cont where anno_esercizio=p_anno_esercizio and staoper!='A') and
        f.codben not in (select codice_soggetto from migr_soggetto_temp
		                 where ente_proprietario_id=p_ente);

  -- ceduto
  insert into migr_soggetto_temp
  (codice_soggetto,motivo,ente_proprietario_id)
  select distinct f.codben,'CAC',p_ente
  from fornitori f
  where f.blocco_pag!='P' and
             f.codben in (select b.codben_ceduto from beneficiari b, fornitori f1, carte_cont m
                          where  b.codben_ceduto!=0 and
                                 f1.codben=b.codben and f1.blocco_pag!='P' and b.blocco_pag!='P' and
                                 m.codben = b.codben  and m.progben=b.progben and m.staoper!='A' and
                                 m.anno_esercizio=p_anno_esercizio)
     and f.codben not in (select codice_soggetto from migr_soggetto_temp
	                      where ente_proprietario_id=p_ente);

   -- cedente
   insert into migr_soggetto_temp
   (codice_soggetto,motivo,ente_proprietario_id)
   --select distinct f.codben,'CAC',2
   select distinct f.codben,'CAC',p_ente
   from fornitori f
   where f.blocco_pag!='P' and
         f.codben in (select b.codben_cedente from beneficiari b, fornitori f1, carte_cont m
                   where  b.codben_cedente!=0 and
                          f1.codben=b.codben and f1.blocco_pag!='P' and b.blocco_pag!='P' and
                          m.codben = b.codben  and m.progben=b.progben and m.staoper!='A' and
                          m.anno_esercizio=p_anno_esercizio) and
      f.codben not in (select codice_soggetto from migr_soggetto_temp
	                   where ente_proprietario_id=p_ente);

   commit;

   msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti con fatture da pagare/incassare.';
   -- fatture non pagate o parzialmente pagate
   insert into migr_soggetto_temp
   (codice_soggetto,motivo,ente_proprietario_id)
   select  distinct f.codben,'FAT',p_ente
   from fornitori f
   where f.codben in (select codben from fatquo where pagato='N') and
         f.codben not in (select codice_soggetto from migr_soggetto_temp
		                  where ente_proprietario_id=p_ente);

   commit;

   msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti bloccati con pagamenti/incassi nell'' anno.';
   -- bloccati di pagamenti/incassi dell'anno in corso
   insert into migr_soggetto_temp
   (codice_soggetto,motivo,ente_proprietario_id)
   select distinct f.codben,'MAN',p_ente
   from fornitori f
   where f.blocco_pag='S' and
         f.codben in (select codben from mandati where anno_esercizio=p_anno_esercizio and staoper!='A')  and
         f.codben not in (select codice_soggetto from migr_soggetto_temp
		                  where ente_proprietario_id=p_ente);

   -- ceduto
   insert into migr_soggetto_temp
   (codice_soggetto,motivo,ente_proprietario_id)
   select distinct f.codben,'MAN',p_ente
   from fornitori f
   where f.blocco_pag='S' and
         f.codben in (select b.codben_ceduto from beneficiari b, fornitori f1, mandati m
                      where  b.codben_ceduto!=0 and
                             f1.codben=b.codben and f1.blocco_pag!='P' and b.blocco_pag!='P' and
                             m.codben = b.codben  and m.progben=b.progben and m.staoper!='A' and
                             m.anno_esercizio=p_anno_esercizio) and
         f.codben not in (select codice_soggetto from migr_soggetto_temp
		                  where ente_proprietario_id=p_ente);

   -- cedente
   insert into migr_soggetto_temp
   (codice_soggetto,motivo,ente_proprietario_id)
   select distinct f.codben,'MAN',p_ente
   from fornitori f
   where f.blocco_pag='S' and
         f.codben in (select b.codben_cedente from beneficiari b, fornitori f1, mandati m
                      where  b.codben_cedente!=0 and
                             f1.codben=b.codben and f1.blocco_pag!='P' and b.blocco_pag!='P' and
                             m.codben = b.codben  and m.progben=b.progben and m.staoper!='A' and
                             m.anno_esercizio=p_anno_esercizio) and
         f.codben not in (select codice_soggetto from migr_soggetto_temp
		                  where ente_proprietario_id=p_ente);
   commit;

   insert into migr_soggetto_temp
   (codice_soggetto,motivo,ente_proprietario_id)
   select distinct f.codben,'REV',p_ente
   from fornitori f
   where f.blocco_pag='S' and
         f.codben in (select codben from riscossioni where anno_esercizio=p_anno_esercizio and staoper!='A') and
         f.codben not in (select codice_soggetto from migr_soggetto_temp
		                  where ente_proprietario_id=p_ente);

   commit;

   pMsgRes:='Migrazione Soggetto_temp OK.';
   pCodRes:=codRes;

  exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
  end migrazione_soggetto_temp;


  procedure migrazione_soggetto(pEnte           number,
                                pCodRes out number,
                                pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;

  -- DAVIDE : operazioni sulle tabelle di migrazione filtrate per ente_id
  procedure  migrazione_soggetto_agg_via (pEnte  number,
                                          pCodRes out number,
                                          pMsgRes out varchar2) is
    msgRes            varchar2(1500) := null;
    codRes            integer := 0;
  begin


   msgRes:='Migrazione Soggetto.Aggiornamento campo VIA.';
   -- VIA

  update migr_soggetto m set
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='VIA'
  --where m.via like 'VIA%' and m.fl_migrato='N';
  where m.via like 'VIA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='VIA'
  --where m.via like 'V.%' and m.fl_migrato='N';
  where m.via like 'V.%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,3,length(m.via)-2),m.tipo_via='VIA'
  --where m.via like 'V %' and m.fl_migrato='N';
  where m.via like 'V %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- CORSO
  update migr_soggetto m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CORSO'
  --where m.via like 'CORSO%' and m.fl_migrato='N';
  where m.via like 'CORSO%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='CORSO'
  --where m.via like 'CSO %' and m.fl_migrato='N';
  where m.via like 'CSO %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='CORSO'
  --where m.via like 'C.SO%' and m.fl_migrato='N';
  where m.via like 'C.SO%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='CORSO'
  --where m.via like 'C. %' and m.fl_migrato='N';
  where m.via like 'C. %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  --- VIALE
  update migr_soggetto m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='VIALE'
  --where m.via like 'VIALE%' and m.fl_migrato='N';
  where m.via like 'VIALE%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='VIALE'
  --where m.via like 'V.LE%' and m.fl_migrato='N';
  where m.via like 'V.LE%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- VICOLO
  update migr_soggetto m set
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='VICOLO'
  --where m.via like 'VICOLO%' and m.fl_migrato='N';
  where m.via like 'VICOLO%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- LARGO
  update migr_soggetto m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='LARGO'
  --where m.via like 'LARGO%' and m.fl_migrato='N';
  where m.via like 'LARGO%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LARGO'
  --where m.via like 'L.GO%' and m.fl_migrato='N';
  where m.via like 'L.GO%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- STRADA
  update migr_soggetto m set
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='STRADA'
  --where m.via like 'STRADA%' and m.fl_migrato='N';
  where m.via like 'STRADA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='STRADA'
  --where m.via like 'STR.%' and m.fl_migrato='N';
  where m.via like 'STR.%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_soggetto m set
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='STRADA'
  --where m.via like 'STR %' and m.fl_migrato='N';
  where m.via like 'STR %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- CALLE
  update migr_soggetto m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CALLE'
  --where m.via like 'CALLE%' and m.fl_migrato='N';
  where m.via like 'CALLE%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 -- PIAZZA
 update migr_soggetto m set
 m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='PIAZZA'
 --where m.via like 'PIAZZA%' and m.fl_migrato='N';
 where m.via like 'PIAZZA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 update migr_soggetto m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='PIAZZA'
  --where m.via like 'P.ZZA%' and m.fl_migrato='N';
  where m.via like 'P.ZZA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 update migr_soggetto m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='PIAZZA'
  --where m.via like 'P.ZA%' and m.fl_migrato='N';
  where m.via like 'P.ZA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 update migr_soggetto m set
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='PIAZZA'
  --where m.via like 'P. %' and m.fl_migrato='N';
  where m.via like 'P. %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 -- BIVIO
 update migr_soggetto m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='BIVIO'
  --where m.via like 'BIVIO%' and m.fl_migrato='N';
  where m.via like 'BIVIO%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 -- BORGATA
 update migr_soggetto m set
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='BORGATA'
  --where m.via like 'BORGATA%' and m.fl_migrato='N';
  where m.via like 'BORGATA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 -- FRAZIONE
 update migr_soggetto m set
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='FRAZIONE'
  --where m.via like 'FRAZIONE%' and m.fl_migrato='N';
  where m.via like 'FRAZIONE%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 -- REGIONE

 update migr_soggetto m set
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='REGIONE'
  --where m.via like 'REGIONE%' and m.fl_migrato='N';
  where m.via like 'REGIONE%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 -- LOCALITA
 update migr_soggetto m set
  m.via=substr(m.via,11,length(m.via)-10),m.tipo_via='LOCALITA'
  --where m.via like 'LOCALITA''%' and m.fl_migrato='N';
  where m.via like 'LOCALITA''%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 update migr_soggetto m set
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='LOCALITA'
  --where m.via like 'LOCALITA%' and m.fl_migrato='N';
  where m.via like 'LOCALITA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 update migr_soggetto m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LOCALITA'
  --where m.via like 'LOC.%' and m.fl_migrato='N';
  where m.via like 'LOC.%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 update migr_soggetto m set
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='LOCALITA'
  --where m.via like 'LOC %' and m.fl_migrato='N';
  where m.via like 'LOC %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

 commit;

  pMsgRes:= msgRes||' ' ||'Migrazione OK.';
  pCodRes:=codRes;

 exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
 end migrazione_soggetto_agg_via;
 -- DAVIDE : fine


  begin


    msgRes:='Migrazione soggetto.Popolamento migr_soggetto.Pulizia migr_soggetto.';
  -- DAVIDE : operazioni sulle tabelle di migrazione filtrate per ente_id
    -- delete migr_soggetto where fl_migrato='N';
    delete migr_soggetto
   where fl_migrato='N'
     and ente_proprietario_id=pEnte;
  -- DAVIDE : fine
    commit;


   --- NATURA GIURIDICA  PF
   --- CON PARTIVA

   --- codfisc=16 --> PFI
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' con partita IVA codfisc 16--> '|| PFI_NATGIU||'.';
   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PFI_NATGIU,t.codnatgiu||'||'||t.descri,
           decode(instr(f.ragsoc,'.',1,2),0,
                     decode(instr(f.ragsoc,'.'),0,f.ragsoc,replace(f.ragsoc,'.',' ')),
                     f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),
           --21.12.2015 cognome e nome, tolto decode su dtns
           --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(instr(f.ragsoc,'.',1,2),0,
              decode(instr(f.ragsoc,'.'),0,
                f.ragsoc,substr(f.ragsoc,1,instr(f.ragsoc,'.')-1)),f.ragsoc)--)
             ,
           --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
                decode(instr(f.ragsoc,'.',1,2),0,
                 decode(instr(f.ragsoc,'.'),0,' ',
                 substr(f.ragsoc,instr(f.ragsoc,'.')+1,length(f.ragsoc)- instr(f.ragsoc,'.'))),f.ragsoc)--)
           ,decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,f.ssso),
           decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,to_char(f.dtns,'YYYY-MM-DD')),
           decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
           decode(nvl(f.cmns,' '),' ',null,f.cmns||'||')),
           decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
               decode(nvl(f.prns,' '),' ',null,f.prns||'||')),
           decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
                  decode(substr(f.codfisc,12,1),'Z','E'||substr(f.codfisc,12,4),'ITALIA||')),
          'S','MIGRAZIONE','',f.via,f.cap,
          decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),
          null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),
          f.note,f.generico,f.classben,null,pEnte
   from   fornitori f, tabnatgiu t, migr_soggetto_temp tmp
   where  f.codben    = tmp.codice_soggetto and
          tmp.ente_proprietario_id=pEnte and
          t.codnatgiu = f.codnatgiu and
          f.codnatgiu =PF_NATGIU and
          f.codfisc is not null and
          length(f.codfisc)=16 and
          f.partiva is not null
   );

  commit;


  -- codfisc=11 and 8,9 --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' con partita IVA codfisc 11 (8,9 no Iva) --> '
          || PG_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,null,
           decode(instr(f.ragsoc,'.',1,2),0,
           decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          f.codnatgiu=PF_NATGIU and
          f.partiva is not null and
          length(f.codfisc)=11 and
          substr(f.codfisc,1,1) in ('8','9')
    );

  -- codfisc=11 and not 8,9 --> PGI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' con partita IVA codfisc 11 (!=8,9 Iva) --> '
          || PGI_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,null,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          f.codnatgiu=PF_NATGIU and
          f.partiva is not null and
          length(f.codfisc)=11 and
          substr(f.codfisc,1,1) not in ('8','9')
  );
  commit;

  -- codfisc!= (11 and 16 ) and 8,9 --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' con partita IVA codfisc!= 11,16 (=8,9 no Iva) --> '
          || PG_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         f.codnatgiu=PF_NATGIU and
         f.partiva is not null and
         length(f.codfisc)!=11 and length(f.codfisc)!=16 and
         substr(f.codfisc,1,1) in ('8','9')
  );
  commit;

  -- codfisc!= (11 and 16 ) and not 8,9 --> PGI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' con partita IVA codfisc!= 11,16 (!=8,9  Iva) --> '
          || PGI_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
  partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
  indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
  email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
         f.codnatgiu=PF_NATGIU and
         f.partiva is not null and
         length(f.codfisc)!=11 and length(f.codfisc)!=16 and
         substr(f.codfisc,1,1) not in ('8','9')
  );
  commit;

  -- senza  codfisc , partiva not 8,9
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' con partita IVA senza codfisc (partiva!=8,9  Iva) --> '
          || PGI_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
          decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         f.codnatgiu=PF_NATGIU and
         f.partiva is not null and
         substr(f.partiva,1,1) not in ('8','9') and
         f.codfisc is null
   );
  commit;

   -- senza  codfisc , partiva 8,9
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' con partita IVA senza codfisc (partiva=8,9 no Iva) --> '
          || PG_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
          decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.partiva,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         f.codnatgiu=PF_NATGIU and
         f.partiva is not null and
         substr(f.partiva,1,1) in ('8','9') and
         f.codfisc is null
   );
  commit;

   --- NATURA GIURIDICA  PF
   --- SENZA PARTIVA


   -- codfisc=16 --> PF
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' senza partita IVA codfisc=16 --> '
            || PF_NATGIU||'.';

   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PF_NATGIU,t.codnatgiu||'||'||t.descri,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),
           --21.12.2015 cognome e nome, tolto decode su dtns
           --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(instr(f.ragsoc,'.',1,2),0,
                  decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                    substr(f.ragsoc,1,instr(f.ragsoc,'.')-1)),f.ragsoc)--)
           ,
           --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
            decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,' ',
                substr(f.ragsoc,instr(f.ragsoc,'.')+1,length(f.ragsoc)- instr(f.ragsoc,'.'))),f.ragsoc)--)
           ,decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,f.ssso),
           decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,to_char(f.dtns,'YYYY-MM-DD')),
           decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
            decode(nvl(f.cmns,' '),' ',null,f.cmns||'||')),
           decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
            decode(nvl(f.prns,' '),' ',null,f.prns||'||')),
           decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
                  decode(substr(f.codfisc,12,1),'Z','E'||substr(f.codfisc,12,4),'ITALIA||')),
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          f.codnatgiu=PF_NATGIU and
          f.codfisc is not null and
          length(f.codfisc)=16 and
          f.partiva is null
   );
  commit;

  -- codfisc=11 and 8,9 --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' senza partita IVA codfisc=11 (8,9 no Iva)--> '
            || PG_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         f.codnatgiu=PF_NATGIU and
         f.partiva is null and
         length(f.codfisc)=11 and
         substr(f.codfisc,1,1) in ('8','9')
   );
   commit;

  -- codfisc=11 and not 8,9 --> PGI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' senza partita IVA codfisc=11 (!=8,9 Iva)--> '
            || PGI_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),'',f.codfisc,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         f.codnatgiu=PF_NATGIU and
         f.partiva is null and
         length(f.codfisc)=11 and
         substr(f.codfisc,1,1) not in ('8','9')
  );


  -- codfisc!= (11 and 16 ) and 8,9 --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' senza partita IVA codfisc!=11,16 (=8,9 no Iva)--> '
            || PG_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,null,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         f.codnatgiu =PF_NATGIU and
         f.partiva is null and
         length(f.codfisc)!=11 and   length(f.codfisc)!=16 and
         substr(f.codfisc,1,1) in ('8','9')
  );
  commit;


  -- codfisc!= (11 and 16 ) and not 8,9 --> PGI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' senza partita IVA codfisc!=11,16 (!=8,9  Iva)--> '
            || PGI_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
           decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                  replace(f.ragsoc,'.',' ')),f.ragsoc),null,f.codfisc,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         f.codnatgiu=PF_NATGIU and
         f.partiva is null and
         length(f.codfisc)!=11 and   length(f.codfisc)!=16 and
         substr(f.codfisc,1,1) not in ('8','9')
   );
  commit;


  -- senza codice_fiscale e senza partita iva --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. '||PF_NATGIU||' senza codice fisaale senza partita IVA --> '
            || PG_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),'','',
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         f.codnatgiu =PF_NATGIU and
         f.partiva is null and
         f.codfisc is null
  );
  commit;


  -- NATURA GIURIDICA  'DG','EN','PN','SP', [Aipo] 'SN','SC'
  -- CON PARTITA IVA

  -- codfisc=16 --> PFI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' con partita IVA codfisc=16--> '
            || PFI_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PFI_NATGIU,t.codnatgiu||'||'||t.descri,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),
          --21.12.2015 cognome e nome, tolto decode su dtns
          --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(instr(f.ragsoc,'.',1,2),0,
                  decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                    substr(f.ragsoc,1,instr(f.ragsoc,'.')-1)),f.ragsoc)--)
          ,
          --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,' ',
                substr(f.ragsoc,instr(f.ragsoc,'.')+1,length(f.ragsoc)- instr(f.ragsoc,'.'))),f.ragsoc)--)
          ,decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,f.ssso),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,to_char(f.dtns,'YYYY-MM-DD')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
           decode(nvl(f.cmns,' '),' ',null,f.cmns||'||')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
           decode(nvl(f.prns,' '),' ',null,f.prns||'||')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
                  decode(substr(f.codfisc,12,1),'Z','E'||substr(f.codfisc,12,4),'ITALIA||')),
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
         --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
         f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                   AS_NATGIU, EP_NATGIU, SI_NATGIU) and
         -- DAVIDE FINE
         f.codfisc is not null and
         length(f.codfisc)=16 and
         f.partiva is not null
   );
   commit;

   -- codfisc=11 and 8,9 --> PG
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' con partita IVA codfisc=11 (8,9 no Iva)--> '
            || PG_NATGIU||'.';
   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,t.codnatgiu||'||'||t.descri,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
          --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
          f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                    AS_NATGIU, EP_NATGIU, SI_NATGIU) and
          -- DAVIDE FINE
   	     f.partiva is not null and
         length(f.codfisc)=11 and
         substr(f.codfisc,1,1) in ('8','9')
   );
   commit;

   -- codfisc=11 and not 8,9 --> PGI
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' con partita IVA codfisc=11 (!=8,9  Iva)--> '
            || PGI_NATGIU||'.';
   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,t.codnatgiu||'||'||t.descri,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
          --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
          f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                    AS_NATGIU, EP_NATGIU, SI_NATGIU) and
          -- DAVIDE FINE
  	      f.partiva is not null and
          length(f.codfisc)=11 and
          substr(f.codfisc,1,1) not in ('8','9')
   );
   commit;

   -- codfisc!= (11 and 16 ) and 8,9 --> PG
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' con partita IVA codfisc!=11,16 (=8,9 no Iva)--> '
            || PG_NATGIU||'.';
   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,t.codnatgiu||'||'||t.descri,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
          --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
          f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                    AS_NATGIU, EP_NATGIU, SI_NATGIU) and
          -- DAVIDE FINE
	      f.partiva is not null and
          length(f.codfisc)!=11 and length(f.codfisc)!=16 and
          substr(f.codfisc,1,1) in ('8','9')
   );
  commit;

  -- codfisc!= (11 and 16 ) and not 8,9 --> PGI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' con partita IVA codfisc!=11,16 (!=8,9  Iva)--> '
            || PGI_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,t.codnatgiu||'||'||t.descri,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
         --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
         f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                   AS_NATGIU, EP_NATGIU, SI_NATGIU) and
         -- DAVIDE FINE
  	     f.partiva is not null and
         length(f.codfisc)!=11 and length(f.codfisc)!=16 and
         substr(f.codfisc,1,1) not in ('8','9')
  );
  commit;

  -- senza codfisc and partita iva not 8,9 --> PGI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' senza codfisc con partita IVA  (!=8,9  Iva)--> '
            || PGI_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,t.codnatgiu||'||'||t.descri,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
         --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
         f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                   AS_NATGIU, EP_NATGIU, SI_NATGIU) and
         -- DAVIDE FINE
  	     f.codfisc is null and
         f.partiva is not null and
         substr(f.partiva,1,1) not in ('8','9')
  );
  commit;

  -- senza codfisc and partita iva 8,9 --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' senza codfisc con partita IVA  (=8,9 no Iva)--> '
            || PG_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,t.codnatgiu||'||'||t.descri,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.partiva,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
         --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
         f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                   AS_NATGIU, EP_NATGIU, SI_NATGIU) and
         -- DAVIDE FINE
   	     f.codfisc is null and
         f.partiva is not null and
         substr(f.partiva,1,1) in ('8','9')
  );
  commit;

  -- SENZA PARTITA IVA
  -- codfisc=16 --> PF
  -- sembrano PG ...
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' senza partita IVA codfisc=16 --> '
            || PG_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,t.codnatgiu||'||'||t.descri,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(instr(f.ragsoc,'.',1,2),0,
                  decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                    substr(f.ragsoc,1,instr(f.ragsoc,'.')-1)),f.ragsoc)),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
            decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,' ',
                substr(f.ragsoc,instr(f.ragsoc,'.')+1,length(f.ragsoc)- instr(f.ragsoc,'.'))),f.ragsoc)),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,f.ssso),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,to_char(f.dtns,'YYYY-MM-DD')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
           decode(nvl(f.cmns,' '),' ',null,f.cmns||'||')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
           decode(nvl(f.prns,' '),' ',null,f.prns||'||')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
                  decode(substr(f.codfisc,12,1),'Z','E'||substr(f.codfisc,12,4),'ITALIA||')),
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
     from fornitori f,tabnatgiu t,migr_soggetto_temp mt
     where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
           t.codnatgiu  =f.codnatgiu and
           -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
           --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
           f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                     AS_NATGIU, EP_NATGIU, SI_NATGIU) and
           -- DAVIDE FINE
		   f.codfisc is not null and
           length(f.codfisc)=16 and
           f.partiva is null
    );
  commit;


  -- codfisc=11 and 8,9 --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' senza partita IVA codfisc=11 (8,9 no Iva) --> '
            || PG_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,t.codnatgiu||'||'||t.descri,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
         --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
         f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                   AS_NATGIU, EP_NATGIU, SI_NATGIU) and
         -- DAVIDE FINE
	     f.partiva is null and
         length(f.codfisc)=11 and
         substr(f.codfisc,1,1) in ('8','9')
  );
  commit;

   -- codfisc=11 and not 8,9 --> PGI
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' senza partita IVA codfisc=11 (!=8,9 Iva) --> '
            || PGI_NATGIU||'.';
   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,t.codnatgiu||'||'||t.descri,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),'',f.codfisc,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
          --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
          f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                    AS_NATGIU, EP_NATGIU, SI_NATGIU) and
          -- DAVIDE FINE
	      f.partiva is null and
          length(f.codfisc)=11 and
          substr(f.codfisc,1,1) not in ('8','9')
   );
  commit;

  -- codfisc!= (11 and 16 ) and 8,9 --> PG
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' senza partita IVA codfisc!=11,16 (=8,9 no Iva) --> '
            || PG_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,t.codnatgiu||'||'||t.descri,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,'',
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,tabnatgiu t,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         t.codnatgiu  =f.codnatgiu and
         -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
         --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
         f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                   AS_NATGIU, EP_NATGIU, SI_NATGIU) and
         -- DAVIDE FINE
	     f.partiva is null and
         length(f.codfisc)!=11 and   length(f.codfisc)!=16 and
         substr(f.codfisc,1,1) in ('8','9')
   );
   commit;

   -- codfisc!= (11 and 16 ) and not 8,9 --> PGI
   -- sembrano esteri quindi li lascio PG
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' senza partita IVA codfisc!=11,16 (!=8,9  Iva) --> '
            || PG_NATGIU||'.';

   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,t.codnatgiu||'||'||t.descri,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,null,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
          --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
          f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                    AS_NATGIU, EP_NATGIU, SI_NATGIU) and
          -- DAVIDE FINE
	      f.partiva is null and
          length(f.codfisc)!=11 and   length(f.codfisc)!=16 and
          substr(f.codfisc,1,1) not in ('8','9')
   );
   commit;

   -- senza codice_fiscale e senza partita iva --> PG
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Natura giurifica!='||PF_NATGIU||' senza partita IVA e codfisc --> '
            || PG_NATGIU||'.';

   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,t.codnatgiu||'||'||t.descri,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),'','',
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,tabnatgiu t,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          t.codnatgiu  =f.codnatgiu and
          -- DAVIDE : tira su anche i soggetti con codnatgiu in 'PG', 'AS', 'EP', 'SI'
          --f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU) and
          f.codnatgiu  in ( DG_NATGIU,EN_NATGIU,PN_NATGIU,SP_NATGIU,SC_NATGIU,SN_NATGIU,PG_NATGIU,
		                    AS_NATGIU, EP_NATGIU, SI_NATGIU) and
          -- DAVIDE FINE
	      f.partiva is null and
          f.codfisc is null
   );
   commit;

   -- SENZA NATURA GIURIDICA

   -- CON PARTITA IVA
   -- codice_fiscale=16 --> PFI
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica con partita IVA e codfisc=16 --> '
            || PFI_NATGIU||'.';

   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
    (select  migr_soggetto_id_seq.nextval,f.codben,PFI_NATGIU,null,
             decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
            decode(f.prov,'EE','9999999999999999',null),
            --21.12.2015 cognome e nome, tolto decode su dtns
            --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(instr(f.ragsoc,'.',1,2),0,
                  decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                    substr(f.ragsoc,1,instr(f.ragsoc,'.')-1)),f.ragsoc)--)
                    ,
            --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
            decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,' ',
                substr(f.ragsoc,instr(f.ragsoc,'.')+1,length(f.ragsoc)- instr(f.ragsoc,'.'))),f.ragsoc)--)
            ,decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,f.ssso),
            decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,to_char(f.dtns,'YYYY-MM-DD')),
            decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(nvl(f.cmns,' '),' ',null,f.cmns||'||')),
            decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(nvl(f.prns,' '),' ',null,f.prns||'||')),
            decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
                  decode(substr(f.codfisc,12,1),'Z','E'||substr(f.codfisc,12,4),'ITALIA||')),
            'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
            decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
            decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
            decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
      from fornitori f ,migr_soggetto_temp mt
      where f.codben = mt.codice_soggetto and
          mt.ente_proprietario_id=pEnte and
            f.codnatgiu is null and
            length(f.codfisc) = 16 and
            f.partiva is not null
     );
   commit;

   -- codfisc=11 and 8,9 --> PG
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica con partita IVA e codfisc=11 (8,9 no Iva) --> '
            || PG_NATGIU||'.';

   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,null,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          f.codnatgiu is null and
          length(f.codfisc) = 11 and
          substr(f.codfisc,1,1) in ('8','9') and
          f.partiva is not null
   );
  commit;

  -- codfisc=11 and not 8,9 --> PGI
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica con partita IVA e codfisc=11 (!=8,9 Iva) --> '
            || PGI_NATGIU||'.';
  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         f.codnatgiu is null and
         length(f.codfisc) = 11 and
         substr(f.codfisc,1,1) not in ('8','9') and
         f.partiva is not null
  );
  commit;


  -- codfisc!= (11 and 16 ) and 8,9 --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica con partita IVA e codfisc!=11,16 (8,9 no Iva) --> '
            || PG_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PG_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         f.codnatgiu is null and
         length(f.codfisc) != 11 and length(f.codfisc) != 16 and
         substr(f.codfisc,1,1) in ('8','9') and
         f.partiva is not null
  );
  commit;

  -- codfisc!= (11 and 16 ) and not 8,9 --> PGI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica con partita IVA e codfisc!=11,16 (!=8,9 Iva) --> '
            || PGI_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select migr_soggetto_id_seq.nextval,f.codben,PGI_NATGIU,null,
          decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),null,null,
          null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         f.codnatgiu is null and
         length(f.codfisc) != 11 and length(f.codfisc) != 16 and
         substr(f.codfisc,1,1) not in ('8','9') and
         f.partiva is not null
   );
  commit;

  -- codfisc mancante e partiva not 8,9 --> PGI
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica senza codfisc e con partita IVA (!=8,9 Iva) --> '
            || PGI_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select  migr_soggetto_id_seq.nextval, f.codben,PGI_NATGIU,null,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f ,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         f.codnatgiu is null and
         f.codfisc is null and
         f.partiva is not null  and
         substr(f.partiva,1,1) not in ('8','9')
  );
  commit;

  -- codfisc mancante e partiva  8,9 --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica senza codfisc e con partita IVA (=8,9 no Iva) --> '
            || PG_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select  migr_soggetto_id_seq.nextval, f.codben,PG_NATGIU,null,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.partiva,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f ,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         f.codnatgiu is null and
         f.codfisc is null and
         f.partiva is not null  and
         substr(f.partiva,1,1)  in ('8','9')
  );
  commit;


  -- SENZA PARTITA IVA

  -- codice_fiscale=16 --> PF
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica senza partita IVA codfisc=16  --> '
            || PF_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select  migr_soggetto_id_seq.nextval,f.codben,PF_NATGIU,null,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
          decode(f.prov,'EE','9999999999999999',null),
          --21.12.2015 cognome e nome, tolto decode su dtns
          --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
             decode(instr(f.ragsoc,'.',1,2),0,
                  decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                    substr(f.ragsoc,1,instr(f.ragsoc,'.')-1)),f.ragsoc)--)
          ,
          --decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
            decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,' ',
                substr(f.ragsoc,instr(f.ragsoc,'.')+1,length(f.ragsoc)- instr(f.ragsoc,'.'))),f.ragsoc)--)
          ,decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,f.ssso),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,to_char(f.dtns,'YYYY-MM-DD')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
           decode(nvl(f.cmns,' '),' ',null,f.cmns||'||')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
           decode(nvl(f.prns,' '),' ',null,f.prns||'||')),
          decode(nvl(to_char(f.dtns,'YYYY-MM-DD'),'X'),'X',null,
                  decode(substr(f.codfisc,12,1),'Z','E'||substr(f.codfisc,12,4),'ITALIA||')),
          'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
          decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
          decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
          decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
        from fornitori f ,migr_soggetto_temp mt
        where f.codben = mt.codice_soggetto and
          mt.ente_proprietario_id=pEnte and
              f.codnatgiu is null and
              length(f.codfisc) = 16 and
              f.partiva is  null
       );
    commit;


    -- codfisc=11 and 8,9 --> PG
    msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica senza partita IVA codfisc=11 (8,9 no Iva)  --> '
            || PG_NATGIU||'.';
    insert into  migr_soggetto
    (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
     partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
     indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
     email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
    (select  migr_soggetto_id_seq.nextval, f.codben,PG_NATGIU,null,
             decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
             decode(f.prov,'EE','9999999999999999',null),null,null,
             null,null,null,null,null,
             'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
             decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
             decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
             decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
     from fornitori f ,migr_soggetto_temp mt
     where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
           f.codnatgiu is null and
           length(f.codfisc) = 11 and
           substr(f.codfisc,1,1) in ('8','9') and
           f.partiva is  null
    );
   commit;


   -- codfisc=11 and not 8,9 --> PGI
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica senza partita IVA codfisc=11 (!=8,9 Iva)  --> '
            || PGI_NATGIU||'.';

   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select  migr_soggetto_id_seq.nextval, f.codben,PGI_NATGIU,null,
            decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),'',f.codfisc,
            decode(f.prov,'EE','9999999999999999',null),null,null,
            null,null,null,null,null,
            'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
            decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
            decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
            decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f ,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          f.codnatgiu is null and
          length(f.codfisc) = 11 and
          substr(f.codfisc,1,1) not in ('8','9') and
          f.partiva is  null
    );
   commit;

   -- codfisc!= (11 and 16 ) and 8,9 --> PG
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica senza partita IVA codfisc!=11,16 (=8,9 no Iva)  --> '
            || PG_NATGIU||'.';
   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select migr_soggetto_id_seq.nextval, f.codben,PG_NATGIU,null,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f ,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          f.codnatgiu is null and
          length(f.codfisc) != 11 and length(f.codfisc) != 16 and
          substr(f.codfisc,1,1) in ('8','9') and
          f.partiva is  null
   );
   commit;

   -- codfisc!= (11 and 16 ) and not 8,9 --> PGI
   -- sembrano esteri li lascio PG
   msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica senza partita IVA codfisc!=11,16 (!=8,9 Iva)  --> '
            || PG_NATGIU||'.';

   insert into  migr_soggetto
   (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
    partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
    indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
    email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
   (select  migr_soggetto_id_seq.nextval, f.codben,PG_NATGIU,null,
            decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,null,
            decode(f.prov,'EE','9999999999999999',null),null,null,
            null,null,null,null,null,
            'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
            decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
            decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
            decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
    from fornitori f ,migr_soggetto_temp mt
    where f.codben = mt.codice_soggetto and
        mt.ente_proprietario_id=pEnte and
          f.codnatgiu is null and
          length(f.codfisc)!= 11 and length(f.codfisc)!= 16 and
          substr(f.codfisc,1,1) not in ('8','9') and
          f.partiva is  null
    );

  -- senza codice fiscale --> PG
  msgRes := 'Migrazione soggetti.Popolamento migr_soggetto. Senza Natura giurifica senza partita IVA e codice fiscale)  --> '
            || PG_NATGIU||'.';

  insert into  migr_soggetto
  (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
   partita_iva,codice_fiscale_estero,cognome,nome,sesso,data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
   indirizzo_principale,tipo_indirizzo,tipo_via,via,cap,comune,prov,nazione,avviso,tel1,tel2,fax,sito_www,
   email,stato_soggetto,note,generico,classif,matricola_hr_spi,ente_proprietario_id)
  (select  migr_soggetto_id_seq.nextval, f.codben,PG_NATGIU,null,
           decode(instr(f.ragsoc,'.',1,2),0,
             decode(instr(f.ragsoc,'.'),0,f.ragsoc,
                   replace(f.ragsoc,'.',' ')),f.ragsoc),f.codfisc,f.partiva,
           decode(f.prov,'EE','9999999999999999',null),null,null,
           null,null,null,null,null,
           'S','MIGRAZIONE','',f.via,f.cap,decode(nvl(f.comune,' '),' ',null,f.comune||'||'),
           decode(nvl(f.prov,' '),' ',null,f.prov||'||'),null,f.fl_avviso,f.pref||f.tel1,f.tel2,f.fax,null,
           decode(nvl(f.email,' '),' ',null,'email'||'||'||f.email||'||'||f.fl_avviso),
           decode(f.blocco_pag,'N','VALIDO','BLOCCATO'),f.note,f.generico,f.classben,null,pEnte
   from fornitori f ,migr_soggetto_temp mt
   where f.codben = mt.codice_soggetto and
         mt.ente_proprietario_id=pEnte and
         f.codnatgiu is null and
         f.codfisc is null and
         f.partiva is  null
  );
  commit;



  msgRes:='Migrazione Soggetto.Aggiorna campo tipo_indirizzo RESIDENZA per PF';
  update migr_soggetto set tipo_indirizzo='RESIDENZA'
  where tipo_soggetto =PF_NATGIU
    and ente_proprietario_id=pEnte;
  commit;

  msgRes:='Migrazione Soggetto.Aggiorna campo tipo_indirizzo SEDE_AMM per !=PF';
  update migr_soggetto set tipo_indirizzo='SEDE_AMM'
  where tipo_soggetto !=PF_NATGIU
    and ente_proprietario_id=pEnte;
  commit;

  msgRes:='Migrazione Soggetto.Aggiorna campo nazione_nascita.Esteri  da comuni_codfisc.';
  update migr_soggetto m
   set  nazione_nascita= ( select c.des_comune||'||' from comuni_codfisc c where c.cod_belfiore=substr(m.nazione_nascita,2,4) and rownum<=1)
  where m.nazione_nascita is not null and m.nazione_nascita!='ITALIA||' and
        0!=(select nvl(count(*),0) from comuni_codfisc c where c.cod_belfiore=substr(m.nazione_nascita,2,4) )
    and m.ente_proprietario_id=pEnte;
  commit;

  msgRes:='Migrazione Soggetto.Aggiorna campo nazione_nascita.Esteri senza comuni_codfisc';
  update migr_soggetto m
   set  nazione_nascita= null
  where m.nazione_nascita is not null and m.nazione_nascita!='ITALIA||' and instr(m.nazione_nascita,'||')=0  and
        0=(select nvl(count(*),0) from comuni_codfisc c where c.cod_belfiore=substr(m.nazione_nascita,2,4) )
    and m.ente_proprietario_id=pEnte;
  commit;

  -- Formato comune passato: descrizione||codistat||codbelfiore.
  -- Il codice istato non viene valorizzato quindi se le altre informazioni sono presenti risulter� descrizione||||codbelfiore.
  msgRes:='Migrazione Soggetto.Aggiorna campo comune nascita con codice belfiore.';
  update migr_soggetto m set
   comune_nascita =
     (select Q2.comune_nascita||'||'||Q2.cod_belfiore from
      (
         select m1.soggetto_id, m1.comune_nascita, c.cod_belfiore from comuni_codfisc c, migr_soggetto m1
         where c.prov = substr(m1.provincia_nascita,0,instr(m1.provincia_nascita,'|')-1)
         and c.des_comune = substr (m1.comune_nascita,0,instr(m1.comune_nascita,'|')-1)
--         and m1.comune_nascita is not null and m1.comune_nascita <> '||'
         order by c.data_ins desc
      ) Q2 , migr_soggetto m1
      where rownum=1
      and Q2.soggetto_id=m1.soggetto_id
      and m1.soggetto_id=m.soggetto_id
    ) ----m.comune_nascita is not null and comune_nascita <> '||' and m.soggetto_id=1143
  where exists (select 1 from comuni_codfisc c where c.des_comune=substr (m.comune_nascita,0,instr(m.comune_nascita,'|')-1)
              and c.prov = substr(m.provincia_nascita,0,instr(m.provincia_nascita,'|')-1))
    and m.ente_proprietario_id=pEnte;
  commit;

  -- Formato comune passato: descrizione||codistat||codbelfiore.
  -- Il codice istato non viene valorizzato quindi se le altre informazioni sono presenti risulter� descrizione||||codbelfiore.
  msgRes:='Migrazione Soggetto.Aggiorna campo comune residenza con codice belfiore.';
  update migr_soggetto m set
   comune =
     (select Q2.comune||'||'||Q2.cod_belfiore from
      (
         select m1.soggetto_id, m1.comune, c.cod_belfiore from comuni_codfisc c, migr_soggetto m1
         where c.prov = substr(m1.prov,0,instr(m1.prov,'|')-1)
         and c.des_comune = substr (m1.comune,0,instr(m1.comune,'|')-1)
--         and m1.comune is not null and m1.comune <> '||'
         order by c.data_ins desc
      ) Q2 , migr_soggetto m1
      where rownum=1
      and Q2.soggetto_id=m1.soggetto_id
      and m1.soggetto_id=m.soggetto_id
    )
  where exists (select 1 from comuni_codfisc c where c.des_comune=substr (m.comune,0,instr(m.comune,'|')-1)
              and c.prov = substr(m.prov,0,instr(m.prov,'|')-1))
    and m.ente_proprietario_id=pEnte;
  commit;

   msgRes:='Migrazione Soggetto. Aggiorna campo VIA.';
   migrazione_soggetto_agg_via (pEnte,codRes,msgRes);

  if codRes=0 then
      pMsgRes:='Migrazione Soggetto OK.';
  else   pMsgRes:=msgRes;
  end if;

  pCodRes:=codRes;


exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_soggetto;

procedure migrazione_soggetto_classe(pEnte   number,
                                     pCodRes out number,
                                     pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
begin

  msgRes:='Migrazione soggetto classe.Pulizia migr_soggetto_classe.';
  -- DAVIDE : operazioni sulle tabelle di migrazione filtrate per ente_id
  -- delete migr_soggetto_classe where fl_migrato='N';
  delete migr_soggetto_classe
   where fl_migrato='N'
     and ente_proprietario_id=pEnte;
  -- DAVIDE : fine
  commit;

  msgRes:='Migrazione soggetto classe.Popolamento migr_soggetto_classe.';

  insert into migr_soggetto_classe
  (soggetto_classe_id,soggetto_id,classe_soggetto,ente_proprietario_id)
  (select  migr_soggetto_classe_id_seq.nextval,migrSogg.Soggetto_Id,classeSogg.Tipoforn||'||'||classeSogg.Descri,pEnte
   from migr_soggetto migrSogg,
       tab_tipi_forn classeSogg,benef_tipi soggTipi
    where soggTipi.Codben=migrSogg.Codice_Soggetto and
        migrSogg.ente_proprietario_id=pEnte and
          classeSogg.Tipoforn=soggTipi.Tipoforn and
        migrSogg.Fl_Migrato='N');

  commit;

  pMsgRes:= 'Migrazione Soggetto Classe OK.';
  pCodRes:=codRes;


exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;

end   migrazione_soggetto_classe;

procedure migrazione_soggetto_mdp(pEnte   number,pAnnoEsercizio varchar2,
                                  pCodRes out number,
                                  pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
begin

  msgRes:='Migrazione Soggetto MDP.Pulizia migr_modpag.';
  -- DAVIDE : operazioni sulle tabelle di migrazione filtrate per ente_id
  -- delete migr_modpag where fl_migrato='N';
  delete migr_modpag
   where fl_migrato='N'
     and ente_proprietario_id=pEnte;
  -- DAVIDE : fine
  commit;


  --- MDP SENZA CESSIONE INCASSO/CREDITO CON E SENZA SEDE SECONDARIA
  msgRes:='Migrazione Soggetto MDP.MDP senza cessione di credito/incasso  con e senza sede secondaria.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
   quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,null,decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
   b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'VALIDO',null,
   decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
   from migr_soggetto ms, beneficiari b
   where  b.codben_ceduto = '0' and  b.codben_cedente=0 and
          b.blocco_pag='N' and
          --b.ragsoc_agg is null and
          b.codben = ms.codice_soggetto and
      ms.ente_proprietario_id=pEnte and
          ms.fl_migrato='N'
  );
  commit;

  --  bloccate con pagamenti/liquidazioni/carte contabili nell'anno
  msgRes:='Migrazione Soggetto MDP.MDP senza cessione di credito/incasso con e senza sede secondaria.Bloccate ma con pagamenti nell''anno.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
   quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,null,decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
          b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
          decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
    from migr_soggetto ms, beneficiari b
    where  b.codben_ceduto = '0' and  b.codben_cedente=0 and
           b.blocco_pag='S' and
           --b.ragsoc_agg is null and
           ms.codice_soggetto = b.codben and
       ms.ente_proprietario_id=pEnte and
           0!=(select count(*)  from mandati m
               where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben) and
            ms.fl_migrato='N'
   );
   commit;

   msgRes:='Migrazione Soggetto MDP.MDP senza cessione di credito/incasso  con e senza sede secondaria.Bloccate ma con liquidazioni nell''anno.';
   insert into migr_modpag
   (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
    quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
   (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,null,decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
           b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
           decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
    from migr_soggetto ms, beneficiari b
    where  b.codben_ceduto = '0' and  b.codben_cedente=0 and
           b.blocco_pag='S' and
           --b.ragsoc_agg is null and
           ms.codice_soggetto= b.codben and
       ms.ente_proprietario_id=pEnte and
           0!=(select count(*)  from liquidazioni m
               where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben) and
           ms.fl_migrato='N' and
           0=(select nvl(count(*),0) from migr_modpag mdp where mdp.soggetto_id=ms.soggetto_id and mdp.codice_modpag=b.progben
          and ms.ente_proprietario_id=pEnte)
    );
    commit;


  msgRes:='Migrazione Soggetto MDP.MDP senza cessione di credito/incasso con e senza sede secondaria.Bloccate ma con carte contabili nell''anno.';
    insert into migr_modpag
    (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
     quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
    (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,null,decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
            b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms, beneficiari b
     where  b.codben_ceduto = '0' and  b.codben_cedente=0 and
            b.blocco_pag='S' and
            --b.ragsoc_agg is null and
            b.codben = ms.codice_soggetto and
      ms.ente_proprietario_id=pEnte and
            0!=(select count(*)  from carte_cont m
                where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben) and
            ms.fl_migrato='N' and
            0=(select nvl(count(*),0) from migr_modpag mdp where mdp.soggetto_id=ms.soggetto_id and mdp.codice_modpag=b.progben
         and ms.ente_proprietario_id=pEnte)
    );
  commit;

  --- MDP CON CESSIONE INCASSO CON E SENZA SEDE SECONDARIA
  msgRes:='Migrazione Soggetto MDP.MDP con cessione di incasso  con e senza sede secondaria.';
  insert into migr_modpag
    (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
     quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
    (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,'CSI',decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
            b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'VALIDO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms,  beneficiari b
     where   b.blocco_pag='N' and
             --b.ragsoc_agg is not null and
             b.codben_ceduto != '0' and
             ms.codice_soggetto = b.codben and
             0!=(select nvl(count(*),0)
                 from migr_soggetto ms1, migr_modpag md
                 where ms1.codice_soggetto=b.codben_ceduto and
               ms1.ente_proprietario_id=pEnte and
                       md.soggetto_id=ms1.soggetto_id and
                       md.codice_modpag=b.progben_ceduto) and
       ms.ente_proprietario_id=pEnte and
             ms.fl_migrato='N'
    );
  commit;

  msgRes:='Migrazione Soggetto MDP.MDP con cessione di incasso  con e senza sede secondaria.MDP bloccata con mandati emessi nell''anno.';
  insert into migr_modpag
    (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
     quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
    (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,'CSI',decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
            b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms, beneficiari b
     where  b.blocco_pag='S' and
            --b.ragsoc_agg is not null and
            b.codben_ceduto != '0' and
            ms.codice_soggetto = b.codben and
            0!=(select nvl(count(*),0)
             from migr_soggetto ms1, migr_modpag md
                where ms1.codice_soggetto=b.codben_ceduto and
        ms1.ente_proprietario_id=pEnte and
                md.soggetto_id=ms1.soggetto_id and
                md.codice_modpag=b.progben_ceduto) and
         ms.ente_proprietario_id=pEnte and
             ms.fl_migrato='N' and
            0!=(select count(*)  from mandati m where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben)
    );
  commit;


  msgRes:='Migrazione Soggetto MDP.MDP con cessione di incasso con e senza sede secondaria.MDP bloccata con liquidazioni emesse nell''anno.';
  insert into migr_modpag
    (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
     quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
    (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,'CSI',decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
            b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms, beneficiari b
     where  b.blocco_pag='S' and
            --b.ragsoc_agg is not null and
            b.codben_ceduto != '0' and
            ms.codice_soggetto = b.codben and
            0!=(select nvl(count(*),0)
                from migr_soggetto ms1, migr_modpag md
                where ms1.codice_soggetto=b.codben_ceduto and
              ms1.ente_proprietario_id=pEnte and
                      md.soggetto_id=ms1.soggetto_id and
                      md.codice_modpag=b.progben_ceduto) and
        ms.ente_proprietario_id=pEnte and
            ms.fl_migrato='N' and
            0!=(select count(*)  from liquidazioni m
                where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben) and
            0=(select nvl(count(*),0) from migr_modpag mdp where mdp.soggetto_id=ms.soggetto_id and mdp.codice_modpag=b.progben)
    );

  msgRes:='Migrazione Soggetto MDP.MDP con cessione di incasso con e senza sede secondaria.MDP bloccata con carte contabili emesse nell''anno.';
  insert into migr_modpag
    (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
     quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
    (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,'CSI',decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
            b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms, beneficiari b
     where  b.blocco_pag='S' and
            --b.ragsoc_agg is not null and
            b.codben_ceduto != '0' and
            ms.codice_soggetto = b.codben and
            0!=(select nvl(count(*),0)
                from migr_soggetto ms1, migr_modpag md
                where ms1.codice_soggetto=b.codben_ceduto and
              ms1.ente_proprietario_id=pEnte and
                      md.soggetto_id=ms1.soggetto_id and
                      md.codice_modpag=b.progben_ceduto) and
      ms.ente_proprietario_id=pEnte and
            ms.fl_migrato='N' and
            0!=(select count(*)  from carte_cont m
                where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben) and
            0=(select nvl(count(*),0) from migr_modpag mdp where mdp.soggetto_id=ms.soggetto_id and mdp.codice_modpag=b.progben)
    );
  commit;

  --- MDP CON CESSIONE CREDITO CON E SENZA SEDE SECONDARIA
  msgRes:='Migrazione Soggetto MDP.MDP con cessione di credito  con e senza sede secondaria.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
   quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,'CSC',decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
          b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'VALIDO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms, beneficiari b
     where  b.codben_cedente != '0' and
            0!=(select nvl(count(*),0) from migr_soggetto ms1 where ms1.codice_soggetto=b.codben_cedente
           and ms1.ente_proprietario_id=pEnte) and
            b.blocco_pag='N' and
            --b.ragsoc_agg is null and
            ms.codice_soggetto = b.codben and
      ms.ente_proprietario_id=pEnte and
            ms.fl_migrato='N'
    );
  commit;

  msgRes:='Migrazione Soggetto MDP.MDP con cessione di credito con e senza sede secondaria.MDP bloccata con mandati emessi nell''anno.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
     quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
    (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,'CSC',decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
            b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms, beneficiari b
     where  b.codben_cedente != '0' and
            0!=(select nvl(count(*),0) from migr_soggetto ms1  where ms1.codice_soggetto=b.codben_cedente
           and ms1.ente_proprietario_id=pEnte) and
            b.blocco_pag='S' and
            --b.ragsoc_agg is null and
            ms.codice_soggetto = b.codben  and
      ms.ente_proprietario_id=pEnte and
            ms.fl_migrato='N' and
            0!=(select count(*)  from mandati m
                where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben)
    );
  commit;

  msgRes:='Migrazione Soggetto MDP.MDP con cessione di credito con e senza sede secondaria.MDP bloccata con liquidazioni emesse nell''anno.';
    insert into migr_modpag
    (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
     quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
    (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,'CSC',decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
            b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms, beneficiari b
     where  b.codben_cedente != '0' and
            0!=(select nvl(count(*),0) from migr_soggetto ms1 where ms1.codice_soggetto=b.codben_cedente
           and ms1.ente_proprietario_id=pEnte) and
            b.blocco_pag='S' and
            --b.ragsoc_agg is null and
            ms.codice_soggetto = b.codben  and
      ms.ente_proprietario_id=pEnte and
            ms.fl_migrato='N' and
            0!=(select count(*)  from liquidazioni m
               where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben) and
            0=(select nvl(count(*),0) from migr_modpag mdp where mdp.soggetto_id=ms.soggetto_id and mdp.codice_modpag=b.progben
          and mdp.ente_proprietario_id=pEnte)
    );
  commit;

  msgRes:='Migrazione Soggetto MDP.MDP con cessione di credito con e senza sede secondaria.MDP bloccata con carte contabili emesse nell''anno.';
    insert into migr_modpag
    (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,codice_accredito,iban,bic,abi,cab,conto_corrente,
     quietanzante,codice_fiscale_quiet,stato_modpag,note,email,ente_proprietario_id)
    (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,'CSC',decode(nvl(b.ragsoc_agg,'N'),'N','N','S'),
            b.codaccre,b.iban,b.bic,b.codbanca,b.codagen,b.codcc,b.quietanz,b.codfisc_quiet,'BLOCCATO',null,
            decode(nvl(b.email,' '),' ',null,'email'||'||'||b.email),pEnte
     from migr_soggetto ms, beneficiari b
     where  b.codben_cedente != '0' and
            0!=(select nvl(count(*),0) from migr_soggetto ms1  where ms1.codice_soggetto=b.codben_cedente
           and ms1.ente_proprietario_id=pEnte) and
            b.blocco_pag='S' and
            --b.ragsoc_agg is null and
            ms.codice_soggetto = b.codben  and
      ms.ente_proprietario_id=pEnte and
            ms.fl_migrato='N' and
            0!=(select count(*)  from carte_cont m
                where m.anno_esercizio=pAnnoEsercizio and m.staoper!='A' and m.codben=b.codben and m.progben=b.progben) and
            0=(select nvl(count(*),0)
               from migr_modpag mdp
               where mdp.soggetto_id=ms.soggetto_id and
                     mdp.codice_modpag=b.progben)
    );
    commit;


    pMsgRes:= 'Migrazione Soggetto MDP OK.';
    pCodRes:=codRes;




exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_soggetto_mdp;

-- DAVIDE : operazioni sulle tabelle di migrazione filtrate per ente_id
procedure migrazione_soggetto_sede_sec(pEnte   number,
                                       pCodRes out number,
                                       pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;

  procedure migrazione_aggiorna_via_sede ( pEnte   number,
                                           pCodRes out number,
                                           pMsgRes out varchar2) is

  msgRes            varchar2(1500) := null;
  codRes            integer := 0;

  begin

  msgRes:='Migrazione Soggetto Sedi Secondarie.Aggiornamento via su sede.';
  -- VIA
  update migr_sede_secondaria m set
  m.via=nvl(substr(m.via,5,length(m.via)-4),'   '),m.tipo_via='VIA'
  --where m.via like 'VIA%';
  where m.via like 'VIA%' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='VIA'
  --where m.via like 'V.%';
  where m.via like 'V.%' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,3,length(m.via)-2),m.tipo_via='VIA'
  --where m.via like 'V %';
  where m.via like 'V %' and m.ente_proprietario_id=pEnte;

  -- CORSO
  update migr_sede_secondaria m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CORSO'
  --where m.via like 'CORSO%';
  where m.via like 'CORSO%' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='CORSO'
  --where m.via like 'CSO %';
  where m.via like 'CSO %' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='CORSO'
  --where m.via like 'C.SO%';
  where m.via like 'C.SO%' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='CORSO'
  --where m.via like 'C. %';
  where m.via like 'C. %' and m.ente_proprietario_id=pEnte;

  --- VIALE
  update migr_sede_secondaria m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='VIALE'
  --where m.via like 'VIALE%';
  where m.via like 'VIALE%' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='VIALE'
  --where m.via like 'V.LE%';
  where m.via like 'V.LE%' and m.ente_proprietario_id=pEnte;

  -- VICOLO
  update migr_sede_secondaria m set
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='VICOLO'
  --where m.via like 'VICOLO%';
  where m.via like 'VICOLO%' and m.ente_proprietario_id=pEnte;

  -- LARGO
  update migr_sede_secondaria m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='LARGO'
  --where m.via like 'LARGO%';
  where m.via like 'LARGO%' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LARGO'
  --where m.via like 'L.GO%';
  where m.via like 'L.GO%' and m.ente_proprietario_id=pEnte;

  -- STRADA
  update migr_sede_secondaria m set
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='STRADA'
  --where m.via like 'STRADA%' and m.fl_migrato='N';
  where m.via like 'STRADA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='STRADA'
  --where m.via like 'STR.%' and m.fl_migrato='N';
  where m.via like 'STR.%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='STRADA'
  --where m.via like 'STR %' and m.fl_migrato='N';
  where m.via like 'STR %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- CALLE

  update migr_sede_secondaria m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CALLE'
  --where m.via like 'CALLE%' and m.fl_migrato='N';
  where m.via like 'CALLE%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- PIAZZA

  update migr_sede_secondaria m set
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='PIAZZA'
  --where m.via like 'PIAZZA%' and m.fl_migrato='N';
  where m.via like 'PIAZZA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='PIAZZA'
  --where m.via like 'P.ZZA%' and m.fl_migrato='N';
  where m.via like 'P.ZZA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='PIAZZA'
  --where m.via like 'P.ZA%' and m.fl_migrato='N';
  where m.via like 'P.ZA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='PIAZZA'
  --where m.via like 'P. %' and m.fl_migrato='N';
  where m.via like 'P. %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- BIVIO

  update migr_sede_secondaria m set
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='BIVIO'
  --where m.via like 'BIVIO%' and m.fl_migrato='N';
  where m.via like 'BIVIO%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- BORGATA

  update migr_sede_secondaria m set
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='BORGATA'
  --where m.via like 'BORGATA%' and m.fl_migrato='N';
  where m.via like 'BORGATA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- FRAZIONE

  update migr_sede_secondaria m set
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='FRAZIONE'
  --where m.via like 'FRAZIONE%' and m.fl_migrato='N';
  where m.via like 'FRAZIONE%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- REGIONE

  update migr_sede_secondaria m set
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='REGIONE'
  --where m.via like 'REGIONE%' and m.fl_migrato='N';
  where m.via like 'REGIONE%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  -- LOCALITA

  update migr_sede_secondaria m set
  m.via=substr(m.via,11,length(m.via)-10),m.tipo_via='LOCALITA'
  --where m.via like 'LOCALITA''%' and m.fl_migrato='N';
  where m.via like 'LOCALITA''%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='LOCALITA'
  --where m.via like 'LOCALITA%' and m.fl_migrato='N';
  where m.via like 'LOCALITA%' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LOCALITA'
  --where m.via like 'LOC.%';
  where m.via like 'LOC.%' and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='LOCALITA'
  --where m.via like 'LOC %' and m.fl_migrato='N';
  where m.via like 'LOC %' and m.fl_migrato='N' and m.ente_proprietario_id=pEnte;
  commit;

  pMsgRes:= msgRes||' ' ||'Migrazione OK.';
  pCodRes:=codRes;

 exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
 end migrazione_aggiorna_via_sede;

begin

  msgRes:='Migrazione Soggetto Sedi Secondarie.Pulizia migr_sede_secondaria.';
  -- DAVIDE : operazioni sulle tabelle di migrazione filtrate per ente_id
  -- delete migr_sede_secondaria where fl_migrato='N';
  delete migr_sede_secondaria
   where fl_migrato='N'
     and ente_proprietario_id=pEnte;
  -- DAVIDE : fine
  commit;

  msgRes:='Migrazione Soggetto Sedi Secondarie cessione incasso.';
  insert into migr_sede_secondaria
  (sede_id,soggetto_id,codice_indirizzo,codice_modpag,ragione_sociale,tipo_relazione,tipo_indirizzo,
   indirizzo_principale,tipo_via,via,cap,comune,prov,nazione,avviso,ente_proprietario_id)
  (select migr_sede_id_seq.nextval,ms.soggetto_id,null,b.progben,b.ragsoc_agg,'SEDE_SECONDARIA','SEDE_LEGALE',
      'N','',b.via,b.cap,
      decode(nvl(b.comune,' '),' ',null,b.comune||'||'),
      decode(nvl(b.prov,' '),' ',null,b.prov||'||'),null,'N',pEnte
  from migr_soggetto ms, beneficiari b, migr_modpag mdp
  where ms.codice_soggetto=b.codben and
      mdp.soggetto_id=ms.soggetto_id and
    ms.ente_proprietario_id=pEnte and
      mdp.codice_modpag=b.progben and
      ms.fl_migrato='N' and mdp.fl_migrato='N' and
      b.ragsoc_agg is not null and
      b.blocco_pag!='P' and
        b.codben_ceduto != '0' and
          0!=(select nvl(count(*),0)
              from migr_soggetto ms1, migr_modpag mdp1
              where ms1.codice_soggetto=b.codben_ceduto and
                  mdp1.soggetto_id=ms1.soggetto_id  and
                  mdp1.codice_modpag=b.progben_ceduto and
          ms1.ente_proprietario_id=pEnte)
    );
    commit;

  msgRes:='Migrazione Soggetto Sedi Secondarie cessione credito.';
  insert into migr_sede_secondaria
  (sede_id,soggetto_id,codice_indirizzo,codice_modpag,ragione_sociale,tipo_relazione,tipo_indirizzo,
   indirizzo_principale,tipo_via,via,cap,comune,prov,nazione,avviso,ente_proprietario_id)
  (select migr_sede_id_seq.nextval,ms.soggetto_id,null,b.progben,b.ragsoc_agg,'SEDE_SECONDARIA','SEDE_LEGALE',
      'N','',b.via,b.cap,
      decode(nvl(b.comune,' '),' ',null,b.comune||'||'),
      decode(nvl(b.prov,' '),' ',null,b.prov||'||'),null,'N',pEnte
   from migr_soggetto ms, migr_modpag mdp, beneficiari b
    where ms.codice_soggetto=b.codben and
      mdp.soggetto_id=ms.soggetto_id and
    ms.ente_proprietario_id=pEnte and
      mdp.codice_modpag=b.progben and
      ms.fl_migrato='N' and mdp.fl_migrato='N' and
      b.ragsoc_agg is not null and
      b.blocco_pag!='P' and
      b.codben_cedente != '0' and
      0!=(select nvl(count(*),0) from migr_soggetto ms1 where ms1.codice_soggetto=b.codben_cedente
         and ms1.ente_proprietario_id=pEnte)
  );
  commit;

  msgRes:='Migrazione Soggetto Sedi Secondarie senza cessione.';
  insert into migr_sede_secondaria
  (sede_id,soggetto_id,codice_indirizzo,codice_modpag,ragione_sociale,tipo_relazione,tipo_indirizzo,
   indirizzo_principale,tipo_via,via,cap,comune,prov,nazione,avviso,ente_proprietario_id)
  (select migr_sede_id_seq.nextval,ms.soggetto_id,null,b.progben,b.ragsoc_agg,'SEDE_SECONDARIA','SEDE_LEGALE',
      'N','',b.via,b.cap,
      decode(nvl(b.comune,' '),' ',null,b.comune||'||'),
      decode(nvl(b.prov,' '),' ',null,b.prov||'||'),null,'N',pEnte
   from migr_soggetto ms, beneficiari b, migr_modpag mdp
   where ms.codice_soggetto=b.codben and
       mdp.soggetto_id=ms.soggetto_id and
     ms.ente_proprietario_id=pEnte and
       mdp.codice_modpag=b.progben and
       ms.fl_migrato='N' and mdp.fl_migrato='N' and
       ms.fl_migrato='N' and
       b.ragsoc_agg is not null and
       b.blocco_pag = 'N' and
         b.codben_cedente = '0' and b.codben_ceduto=0
  );
  commit;

  insert into migr_sede_secondaria
  (sede_id,soggetto_id,codice_indirizzo,codice_modpag,ragione_sociale,tipo_relazione,tipo_indirizzo,
   indirizzo_principale,tipo_via,via,cap,comune,prov,nazione,avviso,ente_proprietario_id)
  (select migr_sede_id_seq.nextval,ms.soggetto_id,null,b.progben,b.ragsoc_agg,'SEDE_SECONDARIA','SEDE_LEGALE',
      'N','',b.via,b.cap,
      decode(nvl(b.comune,' '),' ',null,b.comune||'||'),
      decode(nvl(b.prov,' '),' ',null,b.prov||'||'),null,'N',pEnte
  from migr_soggetto ms, beneficiari b, migr_modpag mdp
  where ms.codice_soggetto=b.codben and
      mdp.soggetto_id=ms.soggetto_id and
    ms.ente_proprietario_id=pEnte and
      mdp.codice_modpag=b.progben and
      ms.fl_migrato='N' and mdp.fl_migrato='N' and
      ms.fl_migrato='N' and
      b.ragsoc_agg is not null and
      b.blocco_pag = 'S' and
        b.codben_cedente = '0' and b.codben_ceduto=0
    );
  commit;

  msgRes:='Migrazione Soggetto Sedi Secondarie.Aggiornamento via su sede.';
  migrazione_aggiorna_via_sede(pEnte,codRes,msgRes);

  -- Formato comune passato: descrizione||codistat||codbelfiore.
  -- Il codice istato non viene valorizzato quindi se le altre informazioni sono presenti risulter� descrizione||||codbelfiore.
  msgRes:='Migrazione Soggetto Sedi Secondarie.Aggiorna campo comune con codice belfiore.';
  update migr_sede_secondaria m set
   comune =
     (select Q2.comune||'||'||Q2.cod_belfiore from
      (
         select m1.sede_id, m1.comune, c.cod_belfiore from comuni_codfisc c, migr_sede_secondaria m1
         where c.prov = substr(m1.prov,0,instr(m1.prov,'|')-1)
         and c.des_comune = substr (m1.comune,0,instr(m1.comune,'|')-1)
         order by c.data_ins desc
      ) Q2 , migr_sede_secondaria m1
      where rownum=1
      and Q2.sede_id=m1.sede_id
      and m1.sede_id=m.sede_id
    )
    -- in questo modo modifico solo quelli per cui data la descrizione viene trovato il codice belfiore  sulla tab. BIL_REG comuni_codfisc
  where exists (select 1 from comuni_codfisc c where c.des_comune=substr (m.comune,0,instr(m.comune,'|')-1)
              and c.prov = substr(m.prov,0,instr(m.prov,'|')-1))
    and m.ente_proprietario_id=pEnte;
  commit;

  -- trattamento per aggiornamento sede_id su MDP
  msgRes:='Migrazione Soggetto Sedi Secondarie.Aggiornamento sede_id su MDP.';
  update migr_modpag mdp
  set mdp.sede_id = (select ms.sede_id
                   from migr_sede_secondaria ms
                   where  ms.soggetto_id=mdp.soggetto_id and ms.codice_modpag=mdp.codice_modpag and ms.fl_migrato='N')
  where mdp.sede_secondaria='S' and mdp.fl_migrato='N'
    and mdp.ente_proprietario_id=pEnte;

  if codRes=0 then
        pMsgRes:= 'Migrazione Soggetto sede secondaria OK.';
  else   pMsgRes:= msgRes;
  end if;
    pCodRes:=codRes;

exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;

end migrazione_soggetto_sede_sec;
-- DAVIDE : fine

procedure migrazione_soggetto_relaz   (pEnte   number,
                                       pCodRes out number,
                                       pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
begin

  msgRes:='Migrazione Soggetto Relaz. Pulizia migr_relaz_soggetto.';
  -- DAVIDE : operazioni sulle tabelle di migrazione filtrate per ente_id
  -- delete migr_relaz_soggetto where fl_migrato='N';
  delete migr_relaz_soggetto
   where fl_migrato='N'
     and ente_proprietario_id=pEnte;
  -- DAVIDE : fine
  commit;

  msgRes:='Migrazione Soggetto Relaz Cessione Incasso.';
  insert into migr_relaz_soggetto
  (tipo_relazione,relaz_id,soggetto_id_da,modpag_id_da,soggetto_id_a,modpag_id_a,ente_proprietario_id)
  (select 'CSI',migr_relaz_id_seq.nextval ,md.soggetto_id,md.modpag_id,mo1.soggetto_id,md1.modpag_id,pEnte
   from migr_modpag md, migr_soggetto mo, beneficiari b, migr_soggetto mo1, migr_modpag md1
   where md.cessione='CSI' and
       md.fl_migrato='N' and
       mo.soggetto_id=md.soggetto_id and
     mo.ente_proprietario_id=pEnte and
       mo.fl_migrato='N' and
       b.codben=mo.codice_soggetto and
       b.progben=md.codice_modpag  and
       b.codben_ceduto!=0 and
       mo1.codice_soggetto=b.codben_ceduto and
       --dani 30.10.2015 (filtro per ente)
       mo1.ente_proprietario_id = pEnte and
       md1.soggetto_id=mo1.soggetto_id and
       md1.codice_modpag=b.progben_ceduto);
  commit;

  msgRes:='Migrazione Soggetto Relaz Cessione Credito.';
  insert into migr_relaz_soggetto
  (tipo_relazione,relaz_id,soggetto_id_da,modpag_id_da,soggetto_id_a,modpag_id_a,ente_proprietario_id)
  (select 'CSC',migr_relaz_id_seq.nextval ,mo1.soggetto_id,null,md.soggetto_id,md.modpag_id, pEnte
   from migr_modpag md, migr_soggetto mo, beneficiari b, migr_soggetto mo1
   where md.cessione='CSC' and
       mo.soggetto_id=md.soggetto_id and
       mo.ente_proprietario_id=pEnte and
       b.codben=mo.codice_soggetto and
       b.progben=md.codice_modpag  and
       b.codben_cedente!=0 and
       mo1.codice_soggetto=b.codben_cedente and 
       --dani 30.10.2015 (filtro per ente)
       mo1.ente_proprietario_id=pEnte
  );
  commit;

    pMsgRes:= 'Migrazione Soggetto Relaz OK.';
    pCodRes:=codRes;


exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end  migrazione_soggetto_relaz;

-- procedura cappello per la migrazione dei soggetti
procedure migrazione_soggetti(pEnte  number, pAnnoEsercizio varchar2, pAnni  number, pCodRes out number, pMsgRes out varchar2)
is
    msgRes            varchar2(1500) := null;
    codRes            integer := 0;
    ERROR_SOGGETTO EXCEPTION;
    begin

        -- popolamento migr_soggetto_temp
         migrazione_soggetto_temp(pEnte,pAnnoEsercizio,pAnni,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;

         -- popolamento migr_soggetto
         migrazione_soggetto(pEnte,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;

         -- popolamento migr_soggetto_classe
        migrazione_soggetto_classe(pEnte,codRes,msgRes);
        if (codRes!=0) then
            raise ERROR_SOGGETTO;
        end if;

         -- popolamento migr_modpag
         migrazione_soggetto_mdp(pEnte,pAnnoEsercizio,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;

         -- popolamento migr_modaccre
         codRes:=fnc_migrazione_mod_accredito(pEnte,msgRes);
         if (codRes!=0) then
            raise ERROR_SOGGETTO;
         end if;

         --popolamento migr_sede_secondaria
         migrazione_soggetto_sede_sec(pEnte,codRes,msgRes);
        if (codRes!=0) then
            raise ERROR_SOGGETTO;
        end if;

         -- popolamento migr_relaz_soggetto
         migrazione_soggetto_relaz(pEnte,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;

         pMsgRes:= 'Migrazione Soggetti OK.';
        pCodRes:=codRes;
     exception
        when ERROR_SOGGETTO then
             pMsgRes    := msgRes;
             pCodRes    := -1;
             rollback;
        when others then
             pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
             pCodRes    := -1;
            rollback;

 end migrazione_soggetti;

end PCK_MIGRAZIONE_SOGGETTI_SIAC;
/
