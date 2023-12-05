/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE PACKAGE BODY PCK_MIGRAZIONE_SIAC IS

procedure migrazione_cpu(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;

  -- DAVIDE - 04.11.015 aggiunta eccezione per procedura d118_di_cui_gia_impegnato
  excCaricadicui  EXCEPTION;
  -- DAVIDE - 04.11.015 - Fine

begin
    msgRes:='Pulizia migr_capitolo_uscita CAP-UP.';
    -- pulizia tabella migrazione per capitoli di previsione d'uscita
    delete migr_capitolo_uscita
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-UP'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

     -- Davide 23.09.015
     -- ECCEZIONE -- inserire delete della migr_capitolo_eccezione per ente e tipo_capitolo='P' e eu='U'
    delete migr_capitolo_eccezione
     where anno_esercizio = p_anno_esercizio
	 and tipo_capitolo='P'
	 and eu='U'
     and ente_proprietario_id=p_ente;

     -- ECCEZIONE -- inserire i record dei capitoli come da mail per i tipi
     -- FPV,FCI, ... != STD
     -- 'FPV' -- Fondo Pluriennale Vincolato (SPESA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'P','U',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','FPV',p_ente
        from previsione_uscita p
       where anno_creazione=p_anno_esercizio
	     and anno_esercizio=p_anno_esercizio
		 and p.rip_autom='P');

     -- 'FSC' -- Fondo Svalutazione Crediti (SPESA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'P','U',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','FSC',p_ente
        from d118_prev_usc p, previsione_uscita u
       where p.anno_creazione=p_anno_esercizio
	     and p.anno_esercizio=p_anno_esercizio
         and u.anno_creazione=p.anno_creazione
         and u.anno_esercizio=p.anno_esercizio
         and u.nro_capitolo=p.nro_capitolo
         and u.nro_articolo=p.nro_articolo
         and p.missione='20' and p.programma='02');

     -- 'DAM' -- Disavanzo di amministrazione (SPESA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'P','U',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','DAM',p_ente
        from previsione_uscita p
       where anno_creazione=p_anno_esercizio
	     and anno_esercizio=p_anno_esercizio
		 and p.titolo='0');

     commit;

	 -- DAVIDE - 04.11.015 aggiunta gestione tavola d118_prev_usc_impegnato
	 msgRes:='Gestione d118_prev_usc_impegnato.';
     d118_di_cui_gia_impegnato(p_anno_esercizio, codRes, msgRes);

	 if codRes!=0 then
	     RAISE excCaricadicui;
     end if;

     -- DAVIDE - 04.11.015 - Fine

    msgRes:='Inserimento migr_capitolo_uscita CAP-UP.';
    insert into migr_capitolo_uscita
      (capusc_id, tipo_capitolo, anno_esercizio, numero_capitolo, numero_articolo,numero_ueb,
       descrizione,descrizione_articolo, titolo, macroaggregato,missione, programma,
       pdc_fin_quarto, pdc_fin_quinto,
       note, flag_per_memoria, flag_rilevante_iva,
       tipo_finanziamento, tipo_vincolo,tipo_fondo,
       siope_livello_1,siope_livello_2,siope_livello_3,
       classificatore_1,classificatore_2,classificatore_3,classificatore_4, classificatore_5,
       classificatore_6, classificatore_7, classificatore_8,classificatore_9,classificatore_10,
       classificatore_11,classificatore_12,classificatore_13, classificatore_14, classificatore_15,
       centro_resp, cdc,
       classe_capitolo,flag_impegnabile,
       stanziamento_iniziale, stanziamento_iniziale_res, stanziamento_iniziale_cassa,
       stanziamento,stanziamento_res,stanziamento_cassa,
       stanziamento_iniziale_anno2,stanziamento_anno2,
       stanziamento_iniziale_anno3,stanziamento_anno3,
       ente_proprietario_id
	   -- DAVIDE - 04.11.015 aggiunti campi da migrare "di cui impegnato"
	   , dicuiimpegnato_anno1, dicuiimpegnato_anno2, dicuiimpegnato_anno3
       -- DAVIDE - 04.11.015 - Fine
	  )
      (select migr_capusc_id_seq.nextval,
              'CAP-UP', cAnno.anno_esercizio,cAnno.nro_capitolo, cAnno.nro_articolo, 1,
              cAnno.descri,null, tit118.titolo,macr118.titolo || macr118.macroaggreg || '0000',
              miss118.missione, progr118.missione || progr118.programma,
              decode(nvl(cap118.conto, ' '),' ', null, decode(pdcFin.Livello, 4, pdcFin.Conto, null)),
              decode(nvl(cap118.conto, ' '),' ', null, decode(pdcFin.Livello, 5, pdcFin.Conto, null)),
              cAnno.Note,cAnno.Permem_Prev, cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '), ' ', null,tipoFin.Tipofin || '||' || tipoFin.Descri),
              decode(nvl(tipoVinc.Tipovinc, ' '),' ',null,tipoVinc.Tipovinc || '||' || tipoVinc.Descri),
              decode(nvl(tipoFondi.Tipofondi, ' '),' ', null,tipoFondi.Tipofondi || '||' || tipoFondi.Descri),
    -- DAVIDE - 12.11.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.cod_gest,
	-- DAVIDE - 12.11.015 - Fine
              decode(nvl(cAnno.upb, ' '),' ', null,'U' || '/' || upb.upb || '||' || upb.descri),
              decode(nvl(cAnno.tipocontr, ' '), ' ',null,tipoContr.Tipocontr || '||' || tipoContr.Descri),
              decode(nvl(cAnno.area, ' '), ' ', null,a.area || '||' || a.descri),
              decode(nvl(cAnno.programma, ' '),' ',null,progr.area || '.' || progr.programma || '||' ||progr.descri),
              decode(nvl(cAnno.progetto, ' '),' ',null, prog.area || '.' || prog.programma || '.' ||prog.progetto || '||' || prog.descri),
              decode(nvl(cAnno.flmutuo, ' '), ' ',null,tipoMutuo.flmutuo || '||' || tipoMutuo.descri),
              nvl(cAnno.ex_cap,'0')||'||'
              ||decode(nvl(cAnno.ex_cap,'0'),'0','***********','EX-CAPITOLO'), -- classif_7 16.02.2017 Sofia
              decode(nvl(cAnno.Codelenchi, ' '), ' ',null,codEle.Codelenchi|| '||' || codEle.Descri), -- classif_8 16.02.2017 Sofia
              null,null,
              decode(cAnno.prop_vista,'F','F||FONDINO',
                                      'N','N||NORMALE',
                                      'S','S||GENERALE', null),
              'U' || '/' || cAnno.titolo || '||' || tit.descri,
              'U' || '/' || cat.titolo || '.' || cat.categoria || '||' ||cat.descri,
              decode(nvl(vusc.voce_eco, ' '),' ',null, 'U' || '/' || vusc.titolo || '.' || vusc.categoria || '.' ||
                     vusc.voce_eco || '||' || vusc.descri),
              null,
              dir.direzione,
              --dir.direzione || '.' || dir.settore,
              dir.direzione || dir.settore, -- 26.10.2015   Sofia
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
	-- DAVIDE - 23.09.015 : stanziamento_iniziale v� inizializzato con st_anno_prec
    --cAnno.St_Prev, cAnno.st_prev_res,cAnno.st_prev_cassa,
    --        cAnno.St_Anno_Prec, cAnno.st_Anno_Prec_res,cAnno.st_Anno_Prec_cassa, -- 17.02.2017 Sofia
              cAnno.St_Prev, cAnno.st_prev_res,cAnno.st_prev_cassa, -- 17.02.2017 Sofia vedi update al fondo
              cAnno.St_Prev,cAnno.st_prev_res,cAnno.st_prev_cassa,
              cAnno2.st_prev,cAnno2.st_prev,
              cAnno3.st_prev,cAnno3.st_prev, p_ente
	         -- DAVIDE - 04.11.015 aggiunti campi da migrare "di cui impegnato"
		      ,cdicuiimpe.gia_impegnato_anno1, cdicuiimpe.gia_impegnato_anno2, cdicuiimpe.gia_impegnato_anno3
             -- DAVIDE - 04.11.015 - Fine
         from previsione_uscita       cAnno,
              previsione_uscita       cAnno2,
              previsione_uscita       cAnno3,
              d118_prev_usc           cap118,
              d118_titusc             tit118,
              d118_macroaggreg        macr118,
              d118_missioni           miss118,
              d118_programmi          progr118,
              d118_piano_conti_usc    pdcFin,
              bil_st_tipofin_out      tipoFin,
              bil_st_tipovinc_out     tipoVinc,
              bil_st_tipofondi_out    tipoFondi,
              unita_previsionali_base upb,
              bil_st_tipocontr_out    tipoContr,
              aree                    a,
              programmi               progr,
              progetti                prog,
              bil_st_tipimutuo_out    tipoMutuo,
              dirsetuff_capitolo      dir,
              titusc                  tit,
              categ_usc               cat,
              vocecousc               vusc,
              migr_capitolo_eccezione capEcc,
			-- DAVIDE - 04.11.015 aggiunti campi da migrare "di cui impegnato"
      			  d118_prev_usc_impegnato cdicuiimpe,
            -- DAVIDE - 04.11.015 - Fine
              bil_st_codelenchi_out codEle  -- 16.02.2017 Sofia
        where cAnno.anno_creazione = p_anno_esercizio
          and cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno.nro_capitolo >= 0
          and cAnno.nro_articolo = 0
          and cAnno2.anno_creazione = cAnno.anno_creazione
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_creazione = cAnno.anno_creazione
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.anno_esercizio = cAnno.anno_esercizio
          and cap118.nro_capitolo = cAnno.nro_capitolo
          and cap118.nro_articolo = cAnno.nro_articolo
          and tit118.anno_esercizio = cap118.anno_esercizio
          and tit118.titolo = cap118.titolo
          and macr118.anno_esercizio = cap118.Anno_Esercizio
          and macr118.titolo = cap118.titolo
          and macr118.macroaggreg = cap118.macroaggreg
          and miss118.anno_esercizio = cap118.anno_esercizio
          and miss118.missione = cap118.missione
          and progr118.anno_esercizio = cap118.anno_esercizio
          and progr118.missione = cap118.missione
          and progr118.programma = cap118.programma
          and pdcFin.Anno_Esercizio(+) = cap118.anno_esercizio
          and pdcFin.Conto(+) = cap118.conto
          and tipoFin.tipofin(+) = cAnno.Tipofin
          and tipoVinc.Tipovinc(+) = cAnno.Tipovinc
          and tipoFondi.Tipofondi(+) = cAnno.Tipofondi
          and upb.anno_creazione(+) = cAnno.anno_esercizio
          and upb.upb(+) = cAnno.Upb
          and tipoContr.Tipocontr(+) = cAnno.Tipocontr
          and a.area(+) = cAnno.area
          and progr.area(+) = cAnno.area
          and progr.programma(+) = cAnno.programma
          and prog.area(+) = cAnno.area
          and prog.programma(+) = cAnno.programma
          and prog.progetto(+) = cAnno.progetto
          and tipoMutuo.Flmutuo(+) = cAnno.Flmutuo
          and tit.anno_esercizio = cAnno.anno_esercizio
          and tit.titolo = cAnno.titolo
          and cat.anno_esercizio = cAnno.anno_esercizio
          and cat.titolo = cAnno.titolo
          and cat.categoria = cAnno.categoria
          and vusc.anno_esercizio(+) = cAnno.anno_esercizio
          and vusc.titolo(+) = cAnno.titolo
          and vusc.categoria(+) = cAnno.Categoria
          and vusc.voce_eco(+) = cAnno.Voce_Eco
          and dir.anno_creazione = cAnno.anno_esercizio
          and dir.anno_esercizio = cAnno.Anno_Esercizio
          and dir.eu = 'U'
          and dir.nro_capitolo = cAnno.nro_capitolo
          and dir.nro_articolo = cAnno.nro_articolo
          and dir.gerarchia = 1
          and capEcc.Tipo_Capitolo (+)='P'
          and capEcc.Eu (+)  ='U'
          and capEcc.Anno_Esercizio (+) = cAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cAnno.Nro_Articolo
          and capEcc.numero_ueb (+)= 1 and
          capEcc.ente_proprietario_id (+)=p_ente -- 07.01.2016 Sofia aggiunto

	      -- DAVIDE - 04.11.015 aggiunti campi da migrare "di cui impegnato"
	      and cdicuiimpe.Anno_Esercizio (+) = cAnno.anno_esercizio and
              cdicuiimpe.nro_capitolo (+) = cAnno.Nro_Capitolo and
              cdicuiimpe.nro_articolo (+) = cAnno.Nro_Articolo
          -- DAVIDE - 04.11.015 - Fine
           and codEle.Codelenchi (+) = cAnno.Codelenchi -- 16.02.2017 Sofia
	   );

     -- 17.02.2017 Sofia 
     msgRes:='Aggiornamento stanziamento_iniziale migr_capitolo_uscita CAP-UP.';
     update migr_capitolo_uscita m 
     set  m.stanziamento_iniziale=
     (select m.stanziamento_iniziale- nvl(sum(vdet.importo), 0)
      from variazioni_dett vdet, variazioni v
      where   v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'U' 
      and   vdet.anno_esercizio = p_anno_esercizio
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-UP'
      and   m.ente_proprietario_id=p_ente;
      
     msgRes:='Aggiornamento stanziamento_iniziale_res migr_capitolo_uscita CAP-UP.';
     update migr_capitolo_uscita m 
     set  m.stanziamento_iniziale_res=
     (select m.stanziamento_iniziale_res-nvl(sum(vdet.importo_res), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'U' 
      and   vdet.anno_esercizio = p_anno_esercizio
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-UP'
      and   m.ente_proprietario_id=p_ente; 
      

     msgRes:='Aggiornamento stanziamento_iniziale_cassa migr_capitolo_uscita CAP-UP.';
     update migr_capitolo_uscita m 
     set  m.stanziamento_iniziale_cassa=
     (select m.stanziamento_iniziale_cassa-nvl(sum(vdet.importo_cassa), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'U' 
      and   vdet.anno_esercizio = p_anno_esercizio
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-UP'
      and   m.ente_proprietario_id=p_ente; 

     msgRes:='Aggiornamento stanziamento_iniziale_anno2 migr_capitolo_uscita CAP-UP.';
     update migr_capitolo_uscita m 
     set  m.stanziamento_iniziale_anno2=
     (select m.stanziamento_iniziale_anno2-nvl(sum(vdet.importo), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'U' 
      and   vdet.anno_esercizio = p_anno_esercizio+1
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-UP'
      and   m.ente_proprietario_id=p_ente;
      
      
      msgRes:='Aggiornamento stanziamento_iniziale_anno3 migr_capitolo_uscita CAP-UP.';
     update migr_capitolo_uscita m 
     set  m.stanziamento_iniziale_anno3=
     (select m.stanziamento_iniziale_anno3-nvl(sum(vdet.importo), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'U' 
      and   vdet.anno_esercizio = p_anno_esercizio+2
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-UP'
      and   m.ente_proprietario_id=p_ente;
      -- 17.02.2017 Sofia
      
      
   pCodRes:=codRes;
   pMsgRes:='Migrazione capitolo uscita previsione OK.';
   commit;

exception
   -- DAVIDE - 04.11.015 aggiunta gestione tavola d118_prev_usc_impegnato
   --                    aggiunta trattamento eccezione
   when excCaricadicui then
      pMsgRes := msgRes;
      pCodRes := -1;
      rollback;
   -- DAVIDE - 04.11.015 - Fine

   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_cpu;

procedure migrazione_cgu(p_anno_esercizio varchar2, p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;

begin
    msgRes:='Pulizia migr_capitolo_uscita CAP-UG.';
    -- pulizia tabella migrazione per capitoli di gestione d'uscita
    delete migr_capitolo_uscita
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-UG'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

     -- Davide 23.09.015
     -- ECCEZIONE -- inserire delete della migr_capitolo_eccezione per ente e tipo_capitolo='G' e eu='U'
    delete migr_capitolo_eccezione
     where anno_esercizio = p_anno_esercizio
	 and tipo_capitolo='G'
	 and eu='U'
     and ente_proprietario_id=p_ente;

     -- ECCEZIONE -- inserire i record dei capitoli come da mail per i tipi
     -- FPV,FCI, ... != STD
     -- 'FPV' -- Fondo Pluriennale Vincolato (SPESA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'G','U',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','FPV',p_ente
        from cap_uscita p
       where anno_esercizio=p_anno_esercizio
		 and p.rip_autom='P');

     -- 'FSC' -- Fondo Svalutazione Crediti (SPESA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'G','U',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','FSC',p_ente
        from d118_cap_usc p, cap_uscita u
       where p.anno_esercizio=p_anno_esercizio
         and u.anno_esercizio=p.anno_esercizio
         and u.nro_capitolo=p.nro_capitolo
         and u.nro_articolo=p.nro_articolo
         and p.missione='20' and p.programma='02');

     -- 'DAM' -- Disavanzo di amministrazione (SPESA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'G','U',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','DAM',p_ente
        from cap_uscita p
       where anno_esercizio=p_anno_esercizio
		 and p.titolo='0');

     commit;

    msgRes:='Inserimento migr_capitolo_uscita CAP-UG.';
    insert into migr_capitolo_uscita
      (capusc_id, tipo_capitolo,anno_esercizio, numero_capitolo, numero_articolo, numero_ueb,
       descrizione,descrizione_articolo,titolo,macroaggregato,
       missione,programma,pdc_fin_quarto,pdc_fin_quinto,
       note,flag_rilevante_iva, tipo_finanziamento,tipo_vincolo,tipo_fondo,
       siope_livello_1,siope_livello_2,siope_livello_3,
       classificatore_1,classificatore_2,classificatore_3,classificatore_4,classificatore_5,
       classificatore_6,classificatore_7,classificatore_8,classificatore_9,classificatore_10,
       classificatore_11, classificatore_12,classificatore_13,classificatore_14,classificatore_15,
       centro_resp,cdc,
       classe_capitolo,flag_impegnabile,
       stanziamento_iniziale, stanziamento_iniziale_res,stanziamento_iniziale_cassa,
       stanziamento,stanziamento_res,stanziamento_cassa,
       stanziamento_iniziale_anno2,stanziamento_anno2,
       stanziamento_iniziale_anno3,stanziamento_anno3, ente_proprietario_id)
      (select migr_capusc_id_seq.nextval,
              'CAP-UG',cAnno.anno_esercizio, cAnno.nro_capitolo,cAnno.nro_articolo,1,
              cAnno.descri, null,
              tit118.titolo,macr118.titolo || macr118.macroaggreg || '0000',
              miss118.missione,progr118.missione || progr118.programma,
              decode(nvl(cap118.conto, ' '),' ',null,decode(pdcFin.Livello, 4, pdcFin.Conto, null)),
              decode(nvl(cap118.conto, ' '),' ',null,decode(pdcFin.Livello, 5, pdcFin.Conto, null)),
              cAnno.Note,cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ', null,tipoFin.Tipofin || '||' || tipoFin.Descri),
              decode(nvl(tipoVinc.Tipovinc, ' '),' ',null,tipoVinc.Tipovinc || '||' || tipoVinc.Descri),
              decode(nvl(tipoFondi.Tipofondi, ' '),' ',null,tipoFondi.Tipofondi || '||' || tipoFondi.Descri),
    -- DAVIDE - 12.11.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.cod_gest,
	-- DAVIDE - 12.11.015 - Fine
              decode(nvl(cAnno.upb, ' '),' ',null,'U' || '/' || upb.upb || '||' || upb.descri),
              decode(nvl(cAnno.tipocontr, ' '),' ',null, tipoContr.Tipocontr || '||' || tipoContr.Descri),
              decode(nvl(cAnno.area, ' '),' ', null,a.area || '||' || a.descri),
              decode(nvl(cAnno.programma, ' '),' ',null, progr.area || '.' || progr.programma || '||' ||progr.descri),
              decode(nvl(cAnno.progetto, ' '),' ',null,prog.area || '.' || prog.programma || '.' || prog.progetto || '||' || prog.descri),
              decode(nvl(cAnno.flmutuo, ' '),' ',null,tipoMutuo.flmutuo || '||' || tipoMutuo.descri),
              null,                          
              null,null,null,
              decode(cAnno.prop_vista,'F','F||FONDINO',
                                      'N','N||NORMALE',
                                      'S','S||GENERALE', null),
              'U' || '/' || cAnno.titolo || '||' || tit.descri,
              'U' || '/' || cat.titolo || '.' || cat.categoria || '||' ||cat.descri,
              decode(nvl(vusc.voce_eco, ' '),' ',null,'U' || '/' || vusc.titolo || '.' || vusc.categoria || '.' ||
                     vusc.voce_eco || '||' || vusc.descri),
              null,
              dir.direzione,
   --           dir.direzione || '.' || dir.settore,
              dir.direzione || dir.settore, -- 26.10.2016 Sofia
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
              cAnno.st_attu,cAnno.st_attu_res,cAnno.st_attu_cassa,
              cAnno.st_attu,cAnno.st_attu_res,cAnno.st_attu_cassa,
              cAnno2.st_attu, cAnno2.st_attu,
              cAnno3.st_attu, cAnno3.st_attu,p_ente
         from cap_uscita              cAnno,
              cap_uscita              cAnno2,
              cap_uscita              cAnno3,
              d118_cap_usc            cap118,
              d118_titusc             tit118,
              d118_macroaggreg        macr118,
              d118_missioni           miss118,
              d118_programmi          progr118,
              d118_piano_conti_usc    pdcFin,
              bil_st_tipofin_out      tipoFin,
              bil_st_tipovinc_out     tipoVinc,
              bil_st_tipofondi_out    tipoFondi,
              unita_previsionali_base upb,
              bil_st_tipocontr_out    tipoContr,
              aree                    a,
              programmi               progr,
              progetti                prog,
              bil_st_tipimutuo_out    tipoMutuo,
              dirsetuff_capitolo      dir,
              titusc                  tit,
              categ_usc               cat,
              vocecousc               vusc,
              migr_capitolo_eccezione capEcc
        where cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno.nro_capitolo >= 0
          and cAnno.nro_articolo = 0
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.anno_esercizio = cAnno.anno_esercizio
          and cap118.nro_capitolo = cAnno.nro_capitolo
          and cap118.nro_articolo = cAnno.nro_articolo
          and tit118.anno_esercizio = cap118.anno_esercizio
          and tit118.titolo = cap118.titolo
          and macr118.anno_esercizio = cap118.Anno_Esercizio
          and macr118.titolo = cap118.titolo
          and macr118.macroaggreg = cap118.macroaggreg
          and miss118.anno_esercizio = cap118.anno_esercizio
          and miss118.missione = cap118.missione
          and progr118.anno_esercizio = cap118.anno_esercizio
          and progr118.missione = cap118.missione
          and progr118.programma = cap118.programma
          and pdcFin.Anno_Esercizio(+) = cap118.anno_esercizio
          and pdcFin.Conto(+) = cap118.conto
          and tipoFin.tipofin(+) = cAnno.Tipofin
          and tipoVinc.Tipovinc(+) = cAnno.Tipovinc
          and tipoFondi.Tipofondi(+) = cAnno.Tipofondi
          and upb.anno_creazione(+) = cAnno.anno_esercizio
          and upb.upb(+) = cAnno.Upb
          and tipoContr.Tipocontr(+) = cAnno.Tipocontr
          and a.area(+) = cAnno.area
          and progr.area(+) = cAnno.area
          and progr.programma(+) = cAnno.programma
          and prog.area(+) = cAnno.area
          and prog.programma(+) = cAnno.programma
          and prog.progetto(+) = cAnno.progetto
          and tipoMutuo.Flmutuo(+) = cAnno.Flmutuo
          and tit.anno_esercizio = cAnno.anno_esercizio
          and tit.titolo = cAnno.titolo
          and cat.anno_esercizio = cAnno.anno_esercizio
          and cat.titolo = cAnno.titolo
          and cat.categoria = cAnno.categoria
          and vusc.anno_esercizio(+) = cAnno.anno_esercizio
          and vusc.titolo(+) = cAnno.titolo
          and vusc.categoria(+) = cAnno.Categoria
          and vusc.voce_eco(+) = cAnno.Voce_Eco
          and dir.anno_creazione = cAnno.anno_esercizio
          and dir.anno_esercizio = cAnno.Anno_Esercizio
          and dir.eu = 'U'
          and dir.nro_capitolo = cAnno.nro_capitolo
          and dir.nro_articolo = cAnno.nro_articolo
          and dir.gerarchia = 1
          and capEcc.Tipo_Capitolo (+)='G'
          and capEcc.Eu (+)  ='U'
          and capEcc.Anno_Esercizio (+) = cAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cAnno.Nro_Articolo
          and capEcc.numero_ueb (+)= 1
          and capEcc.ente_proprietario_id (+)=p_ente); -- 07.01.2016 Sofia aggiunto

   pCodRes:=codRes;
   pMsgRes:='Migrazione capitolo uscita gestione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
     -- dbms_output.put_line('migrazione_cgu pCodRes='||pCodRes);
     -- dbms_output.put_line('migrazione_cgu pMsgRes='||pMsgRes);
      rollback;
end migrazione_cgu;

procedure migrazione_cpe(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin

    msgRes:='Pulizia migr_capitolo_entrata CAP-EP.';
    -- pulizia tabella migrazione per capitoli di previsione di entrata
    delete migr_capitolo_entrata
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-EP'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

     -- Davide 23.09.015
     -- ECCEZIONE -- inserire delete della migr_capitolo_eccezione per ente e tipo_capitolo='P' e eu='E'
    delete migr_capitolo_eccezione
     where anno_esercizio = p_anno_esercizio
	 and tipo_capitolo='P'
	 and eu='E'
     and ente_proprietario_id=p_ente;

     -- ECCEZIONE -- inserire i record dei capitoli come da mail per i tipi
     -- FPV,FCI, ... != STD
	 -- 'FCI' -- FONDO INIZIALE DI CASSA (ENTRATA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'P','E',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','FCI',p_ente
        from previsione_entrata p
       where anno_creazione=p_anno_esercizio
	     and anno_esercizio=p_anno_esercizio
		 and p.titolo='0' and p.categoria = '02');

     -- 'FPV' -- Fondo Pluriennale Vincolato (ENTRATA)
     -- DAVIDE - 18.11.2016 - distinzione tra fondi spese correnti e conto capitale  	  
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     --(select 'P','E',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','FPV',p_ente
     (select 'P','E',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N',decode(p.categoria,'03','FPVSC','04','FPVCC'),p_ente
        from previsione_entrata p
       where anno_creazione=p_anno_esercizio
	     and anno_esercizio=p_anno_esercizio
		 and p.titolo='0' and p.categoria in ('03','04'));  
     -- DAVIDE - 18.11.2016 - Fine

     -- 'AAM' -- Avanzo Amministrazione (ENTRATA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'P','E',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','AAM',p_ente
        from previsione_entrata p
       where anno_creazione=p_anno_esercizio
	     and anno_esercizio=p_anno_esercizio
		 and p.titolo='0' and p.categoria = '01');

     commit;

    msgRes:='Inserimento migr_capitolo_entrata CAP-EP.';
    insert into migr_capitolo_entrata
      (capent_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
       descrizione, descrizione_articolo,titolo,tipologia,categoria,
       pdc_fin_quarto,pdc_fin_quinto,
       note,flag_per_memoria,flag_rilevante_iva,
       tipo_finanziamento,tipo_vincolo,tipo_fondo,
       siope_livello_1,siope_livello_2,siope_livello_3,
       classificatore_1,classificatore_2,classificatore_3,classificatore_4,classificatore_5,
       classificatore_6,classificatore_7,classificatore_8,classificatore_9,classificatore_10,
       classificatore_11,classificatore_12,classificatore_13,classificatore_14,classificatore_15,
       centro_resp,cdc,
       classe_capitolo,flag_accertabile,
       stanziamento_iniziale, stanziamento_iniziale_res,stanziamento_iniziale_cassa,
       stanziamento,stanziamento_res,stanziamento_cassa,
       stanziamento_iniziale_anno2,stanziamento_anno2,
       stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id)
      (select migr_capent_id_seq.nextval,
              'CAP-EP',cAnno.anno_esercizio,cAnno.nro_capitolo,cAnno.nro_articolo, 1,
              cAnno.descri,null,
              tit118.titolo, tip118.titolo || '0' || tip118.tipologia || '00',cat118.categoria,
              decode(nvl(cap118.conto, ' '),' ',null,decode(pdcFin.Livello, 4, pdcFin.Conto, null)),
              decode(nvl(cap118.conto, ' '),' ',null,decode(pdcFin.Livello, 5, pdcFin.Conto, null)),
              cAnno.Note,cAnno.Permem_Prev,cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ',null,tipoFin.Tipofin || '||' || tipoFin.Descri),
              decode(nvl(tipoVinc.Tipovinc, ' '),' ',null,tipoVinc.Tipovinc || '||' || tipoVinc.Descri),
              decode(nvl(tipoFondi.Tipofondi, ' '),' ',null,tipoFondi.Tipofondi || '||' || tipoFondi.Descri),
    -- DAVIDE - 12.11.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.cod_gest,
	-- DAVIDE - 12.11.015 - Fine
              decode(nvl(cAnno.upb, ' '),' ', null,'E' || '/' || upb.upb || '||' || upb.descri),
              decode(nvl(cAnno.tipocontr, ' '),' ',null,tipoContr.Tipocontr || '||' || tipoContr.Descri),
              nvl(cAnno.ex_cap,'0')||'||'
              ||decode(nvl(cAnno.ex_cap,'0'),'0','***********','EX-CAPITOLO'), -- classif_3 16.02.2017 Sofia
              null,null,null,null,null,null, null,
              'E' || '/' || cAnno.titolo || '||' || tit.descri,
              'E' || '/' || cat.titolo || '.' || cat.categoria || '||' ||cat.descri,
              decode(nvl(vusc.voce_eco, ' '),' ',null,'E' || '/' || vusc.titolo || '.' || vusc.categoria || '.' ||
                     vusc.voce_eco || '||' || vusc.descri),
              null,null,
              dir.direzione,
--              dir.direzione || '.' || dir.settore,
              dir.direzione ||  dir.settore, -- 26.10.2015 Sofia
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
	-- DAVIDE - 23.09.015 : stanziamento_iniziale v� inizializzato con st_anno_prec
    --cAnno.St_Prev, cAnno.st_prev_res,cAnno.st_prev_cassa,
--            cAnno.St_Anno_Prec, cAnno.st_Anno_Prec_res,cAnno.st_Anno_Prec_cassa, 17.02.2017 Sofia
              cAnno.St_Prev, cAnno.st_prev_res,cAnno.st_prev_cassa,     -- 17.02.2017 Sofia vedi update al fondo                             
              cAnno.st_prev,cAnno.st_prev_res,cAnno.st_prev_cassa,
              cAnno2.st_prev,cAnno2.st_prev,
              cAnno3.st_prev,cAnno3.st_prev,p_ente
         from previsione_entrata           cAnno,
              previsione_entrata           cAnno2,
              previsione_entrata           cAnno3,
              d118_prev_ent                cap118,
              d118_titent                  tit118,
              d118_tipologie               tip118,
              d118_categorie               cat118,
              d118_piano_conti_ent         pdcFin,
              bil_st_tipofin_out           tipoFin,
              bil_st_tipovinc_out          tipoVinc,
              bil_st_tipofondi_out         tipoFondi,
              unita_previsionali_base_entr upb,
              bil_st_tipocontr_out         tipoContr,
              dirsetuff_capitolo           dir,
              titent                       tit,
              categorie                    cat,
              vocecoent                    vusc,
              migr_capitolo_eccezione      capEcc,
              ( select  nro_capitolo,nro_articolo, count(*) dir_count
                from dirsetuff_capitolo
                where anno_creazione=p_anno_esercizio and anno_esercizio=p_anno_esercizio and eu='E'
                group by nro_capitolo,nro_articolo
              ) CAP_DIR_COUNT
        where cAnno.anno_creazione = p_anno_esercizio
          and cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno.nro_capitolo >= 0
          and cAnno.nro_articolo = 0
          and cAnno2.anno_creazione = cAnno.anno_creazione
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_creazione = cAnno.anno_creazione
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.anno_esercizio = cAnno.anno_esercizio
          and cap118.nro_capitolo = cAnno.nro_capitolo
          and cap118.nro_articolo = cAnno.nro_articolo
          and tit118.anno_esercizio = cap118.anno_esercizio
          and tit118.titolo = cap118.titolo
          and tip118.anno_esercizio = cap118.anno_esercizio
          and tip118.titolo = cap118.titolo
          and tip118.tipologia = cap118.tipologia
          and cat118.anno_esercizio = cap118.anno_esercizio
          and cat118.titolo = cap118.titolo
          and cat118.tipologia = cap118.tipologia
          and cat118.categoria = cap118.categoria
          and pdcFin.Anno_Esercizio(+) = cap118.anno_esercizio
          and pdcFin.Conto(+) = cap118.conto
          and tipoFin.tipofin(+) = cAnno.Tipofin
          and tipoVinc.Tipovinc(+) = cAnno.Tipovinc
          and tipoFondi.Tipofondi(+) = cAnno.Tipofondi
          and upb.anno_creazione(+) = cAnno.anno_esercizio
          and upb.upb(+) = cAnno.Upb
          and tipoContr.Tipocontr(+) = cAnno.Tipocontr
          and tit.anno_esercizio = cAnno.anno_esercizio
          and tit.titolo = cAnno.titolo
          and cat.anno_esercizio = cAnno.anno_esercizio
          and cat.titolo = cAnno.titolo
          and cat.categoria = cAnno.categoria
          and vusc.anno_esercizio(+) = cAnno.anno_esercizio
          and vusc.titolo(+) = cAnno.titolo
          and vusc.categoria(+) = cAnno.Categoria
          and vusc.voce_eco(+) = cAnno.Voce_Eco
          and CAP_DIR_COUNT.nro_capitolo = cAnno.nro_capitolo
          and CAP_DIR_COUNT.nro_articolo = cAnno.nro_articolo
          and dir.anno_creazione = cAnno.anno_esercizio
          and dir.anno_esercizio = cAnno.Anno_Esercizio
          and dir.eu = 'E'
          and dir.nro_capitolo = cAnno.nro_capitolo
          and dir.nro_articolo = cAnno.nro_articolo
          and ((CAP_DIR_COUNT.dir_count = 1 and dir.gerarchia = 1) or
               (CAP_DIR_COUNT.dir_count >1 and dir.gerarchia = 2))
          and capEcc.Tipo_Capitolo (+)='P'
          and capEcc.Eu (+)  ='E'
          and capEcc.Anno_Esercizio (+) = cAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cAnno.Nro_Articolo
          and capEcc.numero_ueb (+)= 1
          and  capEcc.ente_proprietario_id (+)=p_ente ); -- 07.01.2016 Sofia aggiunto


     -- 17.02.2017 Sofia 
     msgRes:='Aggiornamento stanziamento_iniziale migr_capitolo_entrata CAP-EP.';
     update migr_capitolo_entrata m 
     set  m.stanziamento_iniziale=
     (select m.stanziamento_iniziale-nvl(sum(vdet.importo), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'E' 
      and   vdet.anno_esercizio = p_anno_esercizio
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-EP'
      and   m.ente_proprietario_id=p_ente;
      
     msgRes:='Aggiornamento stanziamento_iniziale_res migr_capitolo_entrata CAP-EP.';
     update migr_capitolo_entrata m 
     set  m.stanziamento_iniziale_res=
     (select m.stanziamento_iniziale_res-nvl(sum(vdet.importo_res), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'E' 
      and   vdet.anno_esercizio = p_anno_esercizio
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-EP'
      and   m.ente_proprietario_id=p_ente; 
      

     msgRes:='Aggiornamento stanziamento_iniziale_cassa migr_capitolo_entrata CAP-EP.';
     update migr_capitolo_entrata m 
     set  m.stanziamento_iniziale_cassa=
     (select m.stanziamento_iniziale_cassa-nvl(sum(vdet.importo_cassa), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'E' 
      and   vdet.anno_esercizio = p_anno_esercizio
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-EP'
      and   m.ente_proprietario_id=p_ente; 

     msgRes:='Aggiornamento stanziamento_iniziale_anno2 migr_capitolo_entrata CAP-EP.';
     update migr_capitolo_entrata m 
     set  m.stanziamento_iniziale_anno2=
     (select m.stanziamento_iniziale_anno2-nvl(sum(vdet.importo), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'E' 
      and   vdet.anno_esercizio = p_anno_esercizio+1
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-EP'
      and   m.ente_proprietario_id=p_ente;
      
      
     msgRes:='Aggiornamento stanziamento_iniziale_anno3 migr_capitolo_entrata CAP-EP.';
     update migr_capitolo_entrata m 
     set  m.stanziamento_iniziale_anno3=
     (select m.stanziamento_iniziale_anno3-nvl(sum(vdet.importo), 0)
      from variazioni_dett vdet, variazioni v
      where v.anno_creazione = p_anno_esercizio
      and   v.applicazione='P'
      and   v.staoper='D'
      and   vdet.anno_creazione=v.anno_creazione
      and   vdet.nvar=v.nvar
      and   vdet.eu = 'E' 
      and   vdet.anno_esercizio = p_anno_esercizio+2
      and   vdet.nro_capitolo = m.numero_capitolo
      and   vdet.nro_articolo = m.numero_articolo
      )
      where m.anno_esercizio=p_anno_esercizio
      and   m.tipo_capitolo='CAP-EP'
      and   m.ente_proprietario_id=p_ente;
      -- 17.02.2017 Sofia
      
   pCodRes:=codRes;
   pMsgRes:='Migrazione capitolo entrata previsione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_cpe;

procedure migrazione_cge(p_anno_esercizio varchar2, p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin
    msgRes:='Pulizia migr_capitolo_entrata CAP-EG.';
    -- pulizia tabella migrazione per capitoli di gestione di entrata
    delete migr_capitolo_entrata
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-EG'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

     -- Davide 23.09.015
     -- ECCEZIONE -- inserire delete della migr_capitolo_eccezione per ente e tipo_capitolo='G' e eu='E'
    delete migr_capitolo_eccezione
     where anno_esercizio = p_anno_esercizio
	 and tipo_capitolo='G'
	 and eu='E'
     and ente_proprietario_id=p_ente;

     -- ECCEZIONE -- inserire i record dei capitoli come da mail per i tipi
     -- FPV,FCI, ... != STD
	 -- 'FCI' -- FONDO INIZIALE DI CASSA (ENTRATA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'G','E',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','FCI',p_ente
        from cap_entrata p
       where anno_esercizio=p_anno_esercizio
		 and p.titolo='0' and p.categoria = '02');

     -- 'FPV' -- Fondo Pluriennale Vincolato (ENTRATA)
     -- DAVIDE - 18.11.2016 - distinzione tra fondi spese correnti e conto capitale  	  
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     --(select 'G','E',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','FPV',p_ente
     (select 'G','E',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N',decode(p.categoria,'03','FPVSC','04','FPVCC'),p_ente
        from previsione_entrata p
       where anno_creazione=p_anno_esercizio
	     and anno_esercizio=p_anno_esercizio
		 and p.titolo='0' and p.categoria in ('03','04')); 
     -- DAVIDE - 18.11.2016 - Fine

     -- 'AAM' -- Avanzo Amministrazione (ENTRATA)
     insert into migr_capitolo_eccezione
     (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
      numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
     (select 'G','E',p_anno_esercizio,p.nro_capitolo,p.nro_articolo,'1','N','AAM',p_ente
        from cap_entrata p
       where anno_esercizio=p_anno_esercizio
		 and p.titolo='0' and p.categoria = '01');

     commit;

    msgRes:='Inserimento migr_capitolo_entrata CAP-EG.';
    insert into migr_capitolo_entrata
      (capent_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
       descrizione,descrizione_articolo,titolo,tipologia,categoria,
       pdc_fin_quarto,pdc_fin_quinto,
       note,flag_rilevante_iva,tipo_finanziamento,tipo_vincolo,tipo_fondo,
       siope_livello_1,siope_livello_2,siope_livello_3,
       classificatore_1,classificatore_2,classificatore_3,classificatore_4,classificatore_5,
       classificatore_6,classificatore_7,classificatore_8,classificatore_9,classificatore_10,
       classificatore_11,classificatore_12,classificatore_13,classificatore_14,classificatore_15,
       centro_resp,cdc,
       classe_capitolo,flag_accertabile,
       stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
       stanziamento,stanziamento_res,stanziamento_cassa,
       stanziamento_iniziale_anno2,stanziamento_anno2,
       stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id)
      (select migr_capent_id_seq.nextval,
              'CAP-EG',cAnno.anno_esercizio,cAnno.nro_capitolo,cAnno.nro_articolo,1,
              cAnno.descri,null,
              tit118.titolo,tip118.titolo || '0' || tip118.tipologia || '00',
              cat118.categoria,
              decode(nvl(cap118.conto, ' '),' ', null,decode(pdcFin.Livello, 4, pdcFin.Conto, null)),
              decode(nvl(cap118.conto, ' '),' ', null,decode(pdcFin.Livello, 5, pdcFin.Conto, null)),
              cAnno.Note,cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ',null, tipoFin.Tipofin || '||' || tipoFin.Descri),
              decode(nvl(tipoVinc.Tipovinc, ' '),' ', null, tipoVinc.Tipovinc || '||' || tipoVinc.Descri),
              decode(nvl(tipoFondi.Tipofondi, ' '),' ',null,tipoFondi.Tipofondi || '||' || tipoFondi.Descri),
    -- DAVIDE - 12.11.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.cod_gest,
	-- DAVIDE - 12.11.015 - Fine
              decode(nvl(cAnno.upb, ' '),' ',null,'E' || '/' || upb.upb || '||' || upb.descri),
              decode(nvl(cAnno.tipocontr, ' '),' ', null,tipoContr.Tipocontr || '||' || tipoContr.Descri),
              null,null,null, null,null,null,null,null,
              'E' || '/' || cAnno.titolo || '||' || tit.descri,
              'E' || '/' || cat.titolo || '.' || cat.categoria || '||' ||cat.descri,
              decode(nvl(vusc.voce_eco, ' '),' ',null,'E' || '/' || vusc.titolo || '.' || vusc.categoria || '.' ||
                     vusc.voce_eco || '||' || vusc.descri),
              null,null,
              dir.direzione,
--              dir.direzione || '.' || dir.settore,
              dir.direzione ||  dir.settore, -- 26.10.2015 Sofia
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
              cAnno.st_attu,cAnno.st_attu_res,cAnno.st_attu_cassa,
              cAnno.st_attu,cAnno.st_attu_res,cAnno.st_attu_cassa,
              cAnno2.st_attu,cAnno2.st_attu,
              cAnno3.st_attu,cAnno3.st_attu,p_ente
         from cap_entrata                  cAnno,
              cap_entrata                  cAnno2,
              cap_entrata                  cAnno3,
              d118_cap_ent                 cap118,
              d118_titent                  tit118,
              d118_tipologie               tip118,
              d118_categorie               cat118,
              d118_piano_conti_ent         pdcFin,
              bil_st_tipofin_out           tipoFin,
              bil_st_tipovinc_out          tipoVinc,
              bil_st_tipofondi_out         tipoFondi,
              unita_previsionali_base_entr upb,
              bil_st_tipocontr_out         tipoContr,
              dirsetuff_capitolo           dir,
              titent                       tit,
              categorie                    cat,
              vocecoent                    vusc,
              migr_capitolo_eccezione      capEcc,
              ( select  nro_capitolo,nro_articolo, count(*) dir_count
                from dirsetuff_capitolo
                where anno_creazione=p_anno_esercizio and anno_esercizio=p_anno_esercizio and eu='E'
                group by nro_capitolo,nro_articolo
              ) CAP_DIR_COUNT
        where cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno.nro_capitolo >= 0
          and cAnno.nro_articolo = 0
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.anno_esercizio = cAnno.anno_esercizio
          and cap118.nro_capitolo = cAnno.nro_capitolo
          and cap118.nro_articolo = cAnno.nro_articolo
          and tit118.anno_esercizio = cap118.anno_esercizio
          and tit118.titolo = cap118.titolo
          and tip118.anno_esercizio = cap118.anno_esercizio
          and tip118.titolo = cap118.titolo
          and tip118.tipologia = cap118.tipologia
          and cat118.anno_esercizio = cap118.anno_esercizio
          and cat118.titolo = cap118.titolo
          and cat118.tipologia = cap118.tipologia
          and cat118.categoria = cap118.categoria
          and pdcFin.Anno_Esercizio(+) = cap118.anno_esercizio
          and pdcFin.Conto(+) = cap118.conto
          and tipoFin.tipofin(+) = cAnno.Tipofin
          and tipoVinc.Tipovinc(+) = cAnno.Tipovinc
          and tipoFondi.Tipofondi(+) = cAnno.Tipofondi
          and upb.anno_creazione(+) = cAnno.anno_esercizio
          and upb.upb(+) = cAnno.Upb
          and tipoContr.Tipocontr(+) = cAnno.Tipocontr
          and tit.anno_esercizio = cAnno.anno_esercizio
          and tit.titolo = cAnno.titolo
          and cat.anno_esercizio = cAnno.anno_esercizio
          and cat.titolo = cAnno.titolo
          and cat.categoria = cAnno.categoria
          and vusc.anno_esercizio(+) = cAnno.anno_esercizio
          and vusc.titolo(+) = cAnno.titolo
          and vusc.categoria(+) = cAnno.Categoria
          and vusc.voce_eco(+) = cAnno.Voce_Eco
          and CAP_DIR_COUNT.nro_capitolo = cAnno.nro_capitolo
          and CAP_DIR_COUNT.nro_articolo = cAnno.nro_articolo
          and dir.anno_creazione = cAnno.anno_esercizio
          and dir.anno_esercizio = cAnno.Anno_Esercizio
          and dir.eu = 'E'
          and dir.nro_capitolo = cAnno.nro_capitolo
          and dir.nro_articolo = cAnno.nro_articolo
          and ((CAP_DIR_COUNT.dir_count = 1 and dir.gerarchia = 1) or
               (CAP_DIR_COUNT.dir_count >1 and dir.gerarchia = 2))
          and capEcc.Tipo_Capitolo (+)='G'
          and capEcc.Eu (+)  ='E'
          and capEcc.Anno_Esercizio (+) = cAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cAnno.Nro_Articolo
          and capEcc.numero_ueb (+)= 1
          and capEcc.ente_proprietario_id (+)=p_ente );-- 07.01.2016 Sofia aggiunto

   pCodRes:=codRes;
   pMsgRes:='Migrazione capitolo entrata gestione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_cge;

procedure migrazione_attilegge_up(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin
    msgRes:='Pulizia tabella migr_attilegge_uscita atti_legge_uscita previsione.';
    delete migr_attilegge_uscita
     where tipo_capitolo = 'CAP-UP'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    msgRes:='Inserimento atti_legge_uscita previsione.';
    insert into migr_attilegge_uscita
      (attilegge_uscita_id,
       tipo_capitolo,
       anno_esercizio,
       numero_capitolo,
       numero_articolo,
       anno_legge,
       tipo_legge,
       nro_legge,
       articolo,
       comma,
       punto,
       gerarchia,
       inizio_finanz,
       fine_finanz,
       descrizione,
       ente_proprietario_id)
      (select migr_attilegge_spesa_id_seq.nextval,
              c.tipo_capitolo,
              a.anno_esercizio,
              a.nro_capitolo,
              a.nro_articolo,
              a.anno_legge,
              a.tipo_legge,
              a.nro_legge,
              a.articolo,
              a.comma,
              a.punto,
              a.gerarchia,
              to_char(a.iniz_finanz, 'YYYY-MM-DD'),
              to_char(a.fine_finanz, 'YYYY-MM-DD'),
              a.descri,
              p_ente
         from atti_legge a, migr_capitolo_uscita c
        where c.anno_esercizio = p_anno_esercizio
          and a.anno_esercizio = c.anno_esercizio
          and c.tipo_capitolo = 'CAP-UP'
          and a.nro_capitolo = c.numero_capitolo
          and a.nro_articolo = c.numero_articolo
          and a.eu = 'U'
          and c.fl_migrato = 'N'
      -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
        and c.ente_proprietario_id=p_ente);

   pCodRes:=codRes;
   pMsgRes:='Migrazione atti_legge_uscita previsione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_attilegge_up;

procedure migrazione_attilegge_ug(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin

    msgRes:='Pulizia tabella migr_attilegge_uscita atti_legge_uscita gestione.';

    delete migr_attilegge_uscita
     where tipo_capitolo = 'CAP-UG'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    msgRes:='Inserimento atti_legge_uscita gestione.';
    insert into migr_attilegge_uscita
      (attilegge_uscita_id,
       tipo_capitolo,
       anno_esercizio,
       numero_capitolo,
       numero_articolo,
       anno_legge,
       tipo_legge,
       nro_legge,
       articolo,
       comma,
       punto,
       gerarchia,
       inizio_finanz,
       fine_finanz,
       descrizione,
       ente_proprietario_id)
      (select migr_attilegge_spesa_id_seq.nextval,
              c.tipo_capitolo,
              a.anno_esercizio,
              a.nro_capitolo,
              a.nro_articolo,
              a.anno_legge,
              a.tipo_legge,
              a.nro_legge,
              a.articolo,
              a.comma,
              a.punto,
              a.gerarchia,
              to_char(a.iniz_finanz, 'YYYY-MM-DD'),
              to_char(a.fine_finanz, 'YYYY-MM-DD'),
              a.descri,
              p_ente
         from atti_legge a, migr_capitolo_uscita c
        where c.anno_esercizio = p_anno_esercizio
          and a.anno_esercizio = c.anno_esercizio
          and c.tipo_capitolo = 'CAP-UG'
          and a.nro_capitolo = c.numero_capitolo
          and a.nro_articolo = c.numero_articolo
          and a.eu = 'U'
          and c.fl_migrato = 'N'
      -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
        and c.ente_proprietario_id=p_ente);

   pCodRes:=codRes;
   pMsgRes:='Migrazione atti_legge_uscita gestione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_attilegge_ug;

procedure migrazione_attilegge_ep(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin

    msgRes:='Pulizia tabella migr_attilegge_entrata atti_legge_entrata previsione.';
    delete migr_attilegge_entrata
     where tipo_capitolo = 'CAP-EP'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    msgRes:='Inserimento atti_legge_entrata previsione.';
    insert into migr_attilegge_entrata
      (attilegge_entrata_id,
       tipo_capitolo,
       anno_esercizio,
       numero_capitolo,
       numero_articolo,
       anno_legge,
       tipo_legge,
       nro_legge,
       articolo,
       comma,
       punto,
       gerarchia,
       inizio_finanz,
       fine_finanz,
       descrizione,
       ente_proprietario_id)
      (select migr_attilegge_entrata_id_seq.nextval,
              c.tipo_capitolo,
              a.anno_esercizio,
              a.nro_capitolo,
              a.nro_articolo,
              a.anno_legge,
              a.tipo_legge,
              a.nro_legge,
              a.articolo,
              a.comma,
              a.punto,
              a.gerarchia,
              to_char(a.iniz_finanz, 'YYYY-MM-DD'),
              to_char(a.fine_finanz, 'YYYY-MM-DD'),
              a.descri,
              p_ente
         from atti_legge a, migr_capitolo_entrata c
        where c.anno_esercizio = p_anno_esercizio
          and a.anno_esercizio = c.anno_esercizio
          and c.tipo_capitolo = 'CAP-EP'
          and a.nro_capitolo = c.numero_capitolo
          and a.nro_articolo = c.numero_articolo
          and a.eu = 'E'
          and c.fl_migrato = 'N'
      -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
        and c.ente_proprietario_id=p_ente);

   pCodRes:=codRes;
   pMsgRes:='Migrazione atti_legge_entrata previsione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_attilegge_ep;

procedure migrazione_attilegge_eg(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin

    msgRes:='Pulizia tabella migr_attilegge_entrata atti_legge_entrata gestione.';
    delete migr_attilegge_entrata
     where tipo_capitolo = 'CAP-EG'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    msgRes:='Inserimento atti_legge_entrata gestione.';
    insert into migr_attilegge_entrata
      (attilegge_entrata_id,
       tipo_capitolo,
       anno_esercizio,
       numero_capitolo,
       numero_articolo,
       anno_legge,
       tipo_legge,
       nro_legge,
       articolo,
       comma,
       punto,
       gerarchia,
       inizio_finanz,
       fine_finanz,
       descrizione,
       ente_proprietario_id)
      (select migr_attilegge_entrata_id_seq.nextval,
              c.tipo_capitolo,
              a.anno_esercizio,
              a.nro_capitolo,
              a.nro_articolo,
              a.anno_legge,
              a.tipo_legge,
              a.nro_legge,
              a.articolo,
              a.comma,
              a.punto,
              a.gerarchia,
              to_char(a.iniz_finanz, 'YYYY-MM-DD'),
              to_char(a.fine_finanz, 'YYYY-MM-DD'),
              a.descri,
              p_ente
         from atti_legge a, migr_capitolo_entrata c
        where c.anno_esercizio = p_anno_esercizio
          and a.anno_esercizio = c.anno_esercizio
          and c.tipo_capitolo = 'CAP-EG'
          and a.nro_capitolo = c.numero_capitolo
          and a.nro_articolo = c.numero_articolo
          and a.eu = 'E'
          and c.fl_migrato = 'N'
      -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
        and c.ente_proprietario_id=p_ente);

   pCodRes:=codRes;
   pMsgRes:='Migrazione atti_legge_entrata gestione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_attilegge_eg;

procedure migrazione_vincoli_cp(p_anno_esercizio varchar2, p_ente number,pCodRes out number,pMsgRes out varchar2) is

    codRes number:=0;
    msgRes varchar2(1500):=null;
    vincoloId    integer := 0;
    tipoVincoloS varchar2(500) := null;
    tipoVincoloA varchar2(500) := null;
    nroCapitolo  integer := 0;
    nroArticolo  integer := 0;

begin

    msgRes:='Pulizia tabella migr_vincolo_capitolo vincolo_capitolo previsione.';
    delete migr_vincolo_capitolo
     where anno_esercizio = p_anno_esercizio
       and fl_migrato = 'N'
       and tipo_vincolo_bil = 'P'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    nroCapitolo := -1;
    nroArticolo := -1;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo previsione tipo_vincolo=A.';
    -- tipo_vincolo='A'
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UP'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'A'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from vincoli v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente
                     order by mcap.numero_capitolo, mcap.numero_articolo) loop

      if tipoVincoloA is null then
        tipoVincoloA := migrCap.tipo_vincolo;
      end if;

      if nroCapitolo || nroArticolo !=
         migrCap.numero_capitolo || migrCap.numero_articolo then
        nroCapitolo := migrCap.numero_capitolo;
        nroArticolo := migrCap.numero_articolo;

        select migr_vincolo_id_seq.nextval into vincoloId from dual;

      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'P',
                migrCap.Tipo_Vincolo,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from vincoli v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EP'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));

    end loop;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo previsione tipo_vincolo=V.';

    -- tipo_vincolo='V'
    nroCapitolo := -1;
    nroArticolo := -1;
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UP'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'V'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from vincoli v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente
                     order by mcap.numero_capitolo, mcap.numero_articolo) loop

      if nroCapitolo || nroArticolo !=
         migrCap.numero_capitolo || migrCap.numero_articolo then
        nroCapitolo := migrCap.numero_capitolo;
        nroArticolo := migrCap.numero_articolo;

        select migr_vincolo_id_seq.nextval into vincoloId from dual;

      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'P',
                migrCap.Tipo_Vincolo,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from vincoli v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EP'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));

    end loop;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo previsione tipo_vincolo=S.';
    select migr_vincolo_id_seq.nextval into vincoloId from dual;
    -- tipo_vincolo='S'
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UP'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'S'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from correlazioni v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente) loop

      if tipoVincoloS is null then
        tipoVincoloS := migrCap.tipo_vincolo;
      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'P',
                migrCap.Tipo_Vincolo,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from correlazioni v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EP'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));

    end loop;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo previsione tipo_vincolo=Y da correlazioni.';

    nroCapitolo := -1;
    nroArticolo := -1;
    -- tipo_vincolo ='Y' -- correlazioni
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UP'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'Y'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from correlazioni v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente
                     order by mcap.numero_capitolo, mcap.numero_articolo) loop
      if nroCapitolo || nroArticolo !=
         migrCap.numero_capitolo || migrCap.numero_articolo then
        nroCapitolo := migrCap.numero_capitolo;
        nroArticolo := migrCap.numero_articolo;

        begin
          select distinct vincolo_id
            into vincoloId
            from migr_vincolo_capitolo m
           where m.anno_esercizio = migrCap.Anno_Esercizio
             and m.numero_capitolo_u = migrCap.Numero_Capitolo
             and m.numero_articolo_u = migrCap.Numero_articolo
             and substr(m.tipo_vincolo, 1, 1) = 'S'
             and tipo_vincolo_bil = 'P'
			 -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
             and m.ente_proprietario_id=p_ente;

        exception
          when no_data_found then
            select migr_vincolo_id_seq.nextval into vincoloId from dual;
          when others then
            vincoloId := null;

        end;

      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'P',
                tipoVincoloS,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from correlazioni v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EP'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));
    end loop;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo previsione tipo_vincolo=Y da vincoli.';

    nroCapitolo := -1;
    nroArticolo := -1;
    -- tipo_vincolo ='Y' -- vincoli
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UP'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'Y'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from vincoli v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente
                     order by mcap.numero_capitolo, mcap.numero_articolo) loop
      if nroCapitolo || nroArticolo !=
         migrCap.numero_capitolo || migrCap.numero_articolo then
        nroCapitolo := migrCap.numero_capitolo;
        nroArticolo := migrCap.numero_articolo;

        begin
          select distinct vincolo_id
            into vincoloId
            from migr_vincolo_capitolo m
           where m.anno_esercizio = migrCap.Anno_Esercizio
             and m.numero_capitolo_u = migrCap.Numero_Capitolo
             and m.numero_articolo_u = migrCap.Numero_articolo
             and substr(m.tipo_vincolo, 1, 1) = 'A'
             and tipo_vincolo_bil = 'P'
			 -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
             and m.ente_proprietario_id=p_ente;


        exception
          when no_data_found then
            select migr_vincolo_id_seq.nextval into vincoloId from dual;
          when others then
            vincoloId := null;

        end;

      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'P',
                tipoVincoloA,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from correlazioni v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EP'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));
    end loop;

   pCodRes:=codRes;
   pMsgRes:='Migrazione vincolo_capitolo previsione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_vincoli_cp;

procedure migrazione_vincoli_cg(p_anno_esercizio varchar2, p_ente number,pCodRes out number,pMsgRes out varchar2) is
    codRes number:=0;
    msgRes varchar2(1500):=null;
    vincoloId    integer := 0;
    tipoVincoloS varchar2(500) := null;
    tipoVincoloA varchar2(500) := null;
    nroCapitolo  integer := 0;
    nroArticolo  integer := 0;
  begin

    msgRes:='Pulizia tabella migr_vincolo_capitolo vincolo_capitolo gestione.';
    delete migr_vincolo_capitolo
     where anno_esercizio = p_anno_esercizio
       and fl_migrato = 'N'
       and tipo_vincolo_bil = 'G'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    nroCapitolo := -1;
    nroArticolo := -1;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo gestione tipo_vincolo=A.';
    -- tipo_vincolo='A'
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UG'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'A'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from vincoli v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente
                     order by mcap.numero_capitolo, mcap.numero_articolo) loop

      if tipoVincoloA is null then
        tipoVincoloA := migrCap.tipo_vincolo;
      end if;

      if nroCapitolo || nroArticolo !=
         migrCap.numero_capitolo || migrCap.numero_articolo then
        nroCapitolo := migrCap.numero_capitolo;
        nroArticolo := migrCap.numero_articolo;

        select migr_vincolo_id_seq.nextval into vincoloId from dual;

      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'G',
                migrCap.Tipo_Vincolo,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from vincoli v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EG'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));

    end loop;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo gestione tipo_vincolo=V.';
    -- tipo_vincolo='V'
    nroCapitolo := -1;
    nroArticolo := -1;
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UG'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'V'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from vincoli v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente
                     order by mcap.numero_capitolo, mcap.numero_articolo) loop

      if nroCapitolo || nroArticolo !=
         migrCap.numero_capitolo || migrCap.numero_articolo then
        nroCapitolo := migrCap.numero_capitolo;
        nroArticolo := migrCap.numero_articolo;

        select migr_vincolo_id_seq.nextval into vincoloId from dual;

      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'G',
                migrCap.Tipo_Vincolo,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from vincoli v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EG'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));

    end loop;

    select migr_vincolo_id_seq.nextval into vincoloId from dual;
    -- tipo_vincolo='S'
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UG'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'S'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from correlazioni v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente) loop

      if tipoVincoloS is null then
        tipoVincoloS := migrCap.tipo_vincolo;
      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'G',
                migrCap.Tipo_Vincolo,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from correlazioni v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EG'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));

    end loop;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo gestione tipo_vincolo=Y da correlazioni.';
    nroCapitolo := -1;
    nroArticolo := -1;
    -- tipo_vincolo ='Y' -- correlazioni
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UG'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'Y'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from correlazioni v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente
                     order by mcap.numero_capitolo, mcap.numero_articolo) loop
      if nroCapitolo || nroArticolo !=
         migrCap.numero_capitolo || migrCap.numero_articolo then
        nroCapitolo := migrCap.numero_capitolo;
        nroArticolo := migrCap.numero_articolo;

        begin
          select distinct vincolo_id
            into vincoloId
            from migr_vincolo_capitolo m
           where m.anno_esercizio = migrCap.Anno_Esercizio
             and m.numero_capitolo_u = migrCap.Numero_Capitolo
             and m.numero_articolo_u = migrCap.Numero_articolo
             and substr(m.tipo_vincolo, 1, 1) = 'S'
             and tipo_vincolo_bil = 'G'
         -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
           and m.ente_proprietario_id=p_ente;

        exception
          when no_data_found then
            select migr_vincolo_id_seq.nextval into vincoloId from dual;
          when others then
            vincoloId := null;

        end;

      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'G',
                tipoVincoloS,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from correlazioni v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EG'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));
    end loop;

    msgRes:='Inserimento migr_vincolo_capitolo   vincolo_capitolo gestione tipo_vincolo=Y da vincoli.';

    nroCapitolo := -1;
    nroArticolo := -1;
    -- tipo_vincolo ='Y' -- vincoli
    for migrCap in (select mcap.anno_esercizio,
                           mcap.numero_capitolo,
                           mcap.numero_articolo,
                           mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UG'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 1) = 'Y'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from vincoli v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_capitolo_u = mcap.numero_capitolo
                               and v.nro_articolo_u = mcap.numero_articolo)
                   -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                     and mcap.ente_proprietario_id=p_ente
                     order by mcap.numero_capitolo, mcap.numero_articolo) loop
      if nroCapitolo || nroArticolo !=
         migrCap.numero_capitolo || migrCap.numero_articolo then
        nroCapitolo := migrCap.numero_capitolo;
        nroArticolo := migrCap.numero_articolo;

        begin
          select distinct vincolo_id
            into vincoloId
            from migr_vincolo_capitolo m
           where m.anno_esercizio = migrCap.Anno_Esercizio
             and m.numero_capitolo_u = migrCap.Numero_Capitolo
             and m.numero_articolo_u = migrCap.Numero_articolo
             and substr(m.tipo_vincolo, 1, 1) = 'A'
             and tipo_vincolo_bil = 'G'
         -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
           and m.ente_proprietario_id=p_ente;

        exception
          when no_data_found then
            select migr_vincolo_id_seq.nextval into vincoloId from dual;
          when others then
            vincoloId := null;

        end;

      end if;

      insert into migr_vincolo_capitolo
        (vincolo_id,
         vincolo_cap_id,
         tipo_vincolo_bil,
         tipo_vincolo,
         anno_esercizio,
         numero_capitolo_u,
         numero_articolo_u,
         numero_capitolo_e,
         numero_articolo_e,
         ente_proprietario_id)
        (select vincoloId,
                migr_vincolo_cap_id_seq.nextval,
                'G',
                tipoVincoloA,
                migrCap.anno_esercizio,
                migrCap.Numero_Capitolo,
                migrCap.Numero_Articolo,
                v.nro_capitolo_e,
                v.nro_articolo_e,
                p_ente
           from correlazioni v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_capitolo_u = migrCap.Numero_Capitolo
            and v.nro_articolo_u = migrCap.Numero_Articolo
            and v.nro_capitolo_e || v.nro_articolo_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EG'
                -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                  and mCapE.ente_proprietario_id=p_ente));
    end loop;

   pCodRes:=codRes;
   pMsgRes:='Migrazione vincolo_capitolo gestione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_vincoli_cg;

procedure migrazione_classif_cap_prev(p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin

    msgRes:='Pulizia migr_classif_capitolo previsione.';
    delete migr_classif_capitolo
     where fl_migrato = 'N'
       and tipo_capitolo in ('CAP-UP', 'CAP-EP')
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    msgRes:='Inserimento migr_classif_capitolo previsione.';
    -- CAP-UP
    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_1',
       'UPB di Spesa',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_2',
       'Tipo Contributo',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_3',
       'Area',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_4',
       'Programma',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_5',
       'Progetto',
       p_ente);
    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_6',
       'Tipo Mutuo',
       p_ente);
       
   -- 16.02.2017 Sofia       
   insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_7',
       'ExCapitolo',
       p_ente);
   -- 16.02.2017 Sofia
   insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_8',
       'Cod.Elenchi',
       p_ente);
       
    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_31',
       'Tipo Capitolo',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_32',
       'Ex Titolo',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_33',
       'Ex Categoria',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UP',
       'CLASSIFICATORE_34',
       'Ex Voce Economica di Spesa',
       p_ente);

    -- CAP-EP
    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EP',
       'CLASSIFICATORE_36',
       'UPB di Entrata',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EP',
       'CLASSIFICATORE_37',
       'Tipo Contributo',
       p_ente);
       
   -- 16.02.2017 Sofia       
   insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EP',
       'CLASSIFICATORE_38',
       'ExCapitolo',
       p_ente);
       
    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EP',
       'CLASSIFICATORE_46',
       'Ex Titolo',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EP',
       'CLASSIFICATORE_47',
       'Ex Categoria',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EP',
       'CLASSIFICATORE_48',
       'Ex Voce Economica di Entrata',
       p_ente);

   pCodRes:=codRes;
   pMsgRes:='Migrazione descrizioni classificatori capitolo previsione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_classif_cap_prev;

procedure migrazione_classif_cap_gest(p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;

begin

    msgRes:='Pulizia migr_classif_capitolo gestione.';
    delete migr_classif_capitolo
     where fl_migrato = 'N'
       and tipo_capitolo in ('CAP-UG', 'CAP-EG')
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    msgRes:='Inserimento migr_classif_capitolo gestione.';
    -- CAP-UG
    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_1',
       'UPB di Spesa',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_2',
       'Tipo Contributo',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_3',
       'Area',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_4',
       'Programma',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_5',
       'Progetto',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_6',
       'Tipo Mutuo',
       p_ente);

   -- 16.02.2017 Sofia       
   insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_7',
       'ExCapitolo',
       p_ente);
   -- 16.02.2017 Sofia
   insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_8',
       'Cod.Elenchi',
       p_ente);


    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_31',
       'Tipo Capitolo',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_32',
       'Ex Titolo',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_33',
       'Ex Categoria',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-UG',
       'CLASSIFICATORE_34',
       'Ex Voce Economica di Spesa',
       p_ente);

    -- CAP-EG
    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EG',
       'CLASSIFICATORE_36',
       'UPB di Entrata',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EG',
       'CLASSIFICATORE_37',
       'Tipo Contributo',
       p_ente);

   -- 16.02.2017 Sofia       
   insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EG',
       'CLASSIFICATORE_38',
       'ExCapitolo',
       p_ente);
       
    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EG',
       'CLASSIFICATORE_46',
       'Ex Titolo',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EG',
       'CLASSIFICATORE_47',
       'Ex Categoria',
       p_ente);

    insert into migr_classif_capitolo
      (classif_tipo_id,
       tipo_capitolo,
       codice,
       descrizione,
       ente_proprietario_id)
    values
      (migr_classif_capitolo_id_seq.nextval,
       'CAP-EG',
       'CLASSIFICATORE_48',
       'Ex Voce Economica di Entrata',
       p_ente);

   pCodRes:=codRes;
   pMsgRes:='Migrazione descrizioni classificatori capitolo gestione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_classif_cap_gest;


procedure migrazione_capitolo(pTipoCapitolo varchar2, pAnnoEsercizio varchar2,pEnte number,
                              pCodRes out number, pMsgRes out varchar2) is

  codRes number:=0;
  msgRes varchar2(1500);
  msgResIn varchar2(1500);
begin

  if pTipoCapitolo=TIPO_CAP_PREV then
     msgResIn:='Migrazione capitoli previsione uscita.';
     migrazione_cpu(pAnnoEsercizio,pEnte,codRes,msgRes);
     if (codRes=0 ) then
       msgResIn:='Migrazione capitoli previsione entrata.';
       migrazione_cpe(pAnnoEsercizio,pEnte,codRes,msgRes);
     end if;
     if (codRes=0) then
      msgResIn:='Migrazione atti legge previsione uscita.';
      migrazione_attilegge_up(pAnnoEsercizio,pEnte,codRes,msgRes);
     end if; 
     if (codRes=0 ) then
       msgResIn:='Migrazione atti legge previsione entrata.';
       migrazione_attilegge_ep(pAnnoEsercizio,pEnte,codRes,msgRes);
     end if;
     if ( codRes=0 ) then
       msgResIn:='Migrazione vincoli capitolo previsione.';
       migrazione_vincoli_cp(pAnnoEsercizio,pEnte,codRes,msgRes);
     end if;
     if ( codRes=0 ) then
       msgResIn:='Migrazione capitoli previsione descrizione classificatori.';
       migrazione_classif_cap_prev(pEnte,codRes,msgRes);
     end if;
  else
     msgResIn:='Migrazione capitoli gestione uscita.';
     migrazione_cgu(pAnnoEsercizio,pEnte,codRes,msgRes);
  --   dbms_output.put_line('doopo codREs='||codRes);
   --  dbms_output.put_line('dopo msgRes='||msgRes);
     if (codRes=0 ) then
       msgResIn:='Migrazione capitoli gestione entrata.';
       migrazione_cge(pAnnoEsercizio,pEnte,codRes,msgRes);
     end if;
     if (codRes=0) then
      msgResIn:='Migrazione atti legge gestione uscita.';
      migrazione_attilegge_ug(pAnnoEsercizio,pEnte,codRes,msgRes);
     end if; 
     if (codRes=0 ) then
       msgResIn:='Migrazione atti legge gestione entrata.';
       migrazione_attilegge_eg(pAnnoEsercizio,pEnte,codRes,msgRes);
     end if;
     if ( codRes=0 ) then
       msgResIn:='Migrazione vincoli capitolo gestione.';
       migrazione_vincoli_cg(pAnnoEsercizio,pEnte,codRes,msgRes);
     end if;
     if (codRes=0 ) then
       msgResIn:='Migrazione capitoli gestione descrizione classificatori.';
       migrazione_classif_cap_gest(pEnte,codRes,msgRes);
     end if;
  end if;

  pCodRes:=codRes;
  if (codRes=0) then
    pMsgRes:='Migrazione capitoli '||pTipoCapitolo||' OK.';
  else
    pMsgRes:=msgResIn||msgRes;
  end if;

exception
    when others then
      pMsgRes := msgResIn || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_capitolo;

procedure reset_seq(p_seq_name in varchar2) is
    l_val number;
  begin
    execute immediate 'select ' || p_seq_name || '.nextval from dual'
      INTO l_val;

    execute immediate 'alter sequence ' || p_seq_name || ' increment by -' ||
                      l_val || ' minvalue 0';

    execute immediate 'select ' || p_seq_name || '.nextval from dual'
      INTO l_val;

    execute immediate 'alter sequence ' || p_seq_name ||
                      ' increment by 1 minvalue 0';
end reset_seq;

procedure leggi_provvedimento(p_anno_provvedimento varchar2,p_numero_provvedimento varchar2,
                              p_tipo_provvedimento varchar2,p_direzione_provvedimento varchar2,
                              p_ente_proprietario_id number,
                              p_codRes out number,p_msgRes  out varchar2,
                              p_oggetto_provvedimento out varchar2,p_stato_provvedimento out varchar2,
                              p_note_provvedimento out varchar2
--                              p_numero_provvedimento_calcolato out varchar2
                             ) is

h_numero_provvedimento number:=0;
--h_numero_provvedimento_calcolato number:=0;
h_stato_provvedimento varchar2(5):=null;
h_nro_prov     number:=0;
h_nro_def      number:=0;
h_oggetto      varchar2(500):=null;
h_esito_giunta varchar2(10):=null;
h_note         varchar2(500):=null;
h_nelenco      number:=0;

h_anno_avvio_ente_str varchar2(4):=null;

h_ente varchar2(10):=null;
h_tipo_atto_id number:=0;

codRes  number:=0; -- 0 OK, -1 Errore non gestito, -2 Errore gestito: provvedimento non trovato
msgRes  varchar2(1500):=null;

begin

  h_numero_provvedimento:= to_number(p_numero_provvedimento);

  p_oggetto_provvedimento:=null;
  p_stato_provvedimento:=null;
  p_note_provvedimento:=null;

  p_codRes:=0;
  p_msgRes:='Lettura dati provvedimento '||p_anno_provvedimento||'/'||p_numero_provvedimento||
            ' tipo '||p_tipo_provvedimento||' sac '||p_direzione_provvedimento||'.';

  --if p_ente_proprietario_id= ENTE_REGP_GIUNTA then
    if p_tipo_provvedimento = PROVV_DETERMINA_REGP then
      begin
          msgRes:='Ricerca dati determina.';
          select d.oggetto into h_oggetto
          from determine d, direzioni dd
          where d.anno=p_anno_provvedimento and
                d.num_determ=h_numero_provvedimento and
                dd.direzione=p_direzione_provvedimento and
                d.cod_dir=dd.cod_dir;

      exception
          when no_data_found then
              --codRes:=-1;
              codRes:=-2;
              msgRes:='Determina non trovata';
          when others then
              codRes:=-1;
              msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';

      end;
    elsif p_tipo_provvedimento=PROVV_DELIBERA_REGP then
          begin
--              if p_anno_provvedimento > 2012 then 26.01.2017 Sofia mail di Ivano del 26.01.2017 le delibere 2013, 2014 sono state storicizzate
              if p_anno_provvedimento > 2014 then                
                  msgRes:='Ricerca dati delibera su tab. delibere';
                  select d.nro_provv,d.nro_def,d.oggetto,d.esito_giunta
                    into h_nro_prov,h_nro_def,h_oggetto,h_esito_giunta
                    from delibere d
                   where ( h_numero_provvedimento>=50000 and d.nro_provv=h_numero_provvedimento) or
                         ( h_numero_provvedimento<50000 and  d.nro_def=h_numero_provvedimento and d.anno=p_anno_provvedimento);
              else
                  msgRes:='Ricerca dati delibera su tab. delibere_storico';
                  select d.nro_provv,d.nro_def,d.oggetto,d.esito_giunta
                    into h_nro_prov,h_nro_def,h_oggetto,h_esito_giunta
                    from delibere_storico d
                   where ( h_numero_provvedimento>=50000 and d.nro_provv=h_numero_provvedimento) or
                         ( h_numero_provvedimento<50000 and  d.nro_def=h_numero_provvedimento and d.anno=p_anno_provvedimento);
              end if;

              if h_numero_provvedimento>=50000 and  h_nro_prov=h_nro_def then
                  h_stato_provvedimento:='P';
              end if;

              if (h_numero_provvedimento>=50000 and  h_nro_prov!=h_nro_def) or h_numero_provvedimento<50000 then
                  if h_esito_giunta='AP' then
                      h_stato_provvedimento:='D';
                  else
                      --h_stato_provvedimento:='A';
                      codRes:=-1;
                      msgRes:='Delibera ANNULLATA, esito giunta '||h_esito_giunta||'.';
                  end if;
              end if;

           exception
              when no_data_found then
                  --codRes:=-1;
                  codRes:=-2;
                  msgRes:='Delibera non trovata.';
              when others then
                  codRes:=-1;
                  msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
           end;

      -- 12.05.2015, daniela gestione tipo AL
    elsif p_tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE then
      begin
          select al.causale_pagam, al.note, al.nelenco
            into h_oggetto, h_note, h_nelenco
            from atti_liquid al
           where al.annoprov=p_anno_provvedimento
             and al.nprov=p_numero_provvedimento
             and al.direzione=p_direzione_provvedimento;

--          if h_nelenco > 0 then
--            h_numero_provvedimento_calcolato=100000+h_nelenco;
--          end if;
      exception
          when no_data_found then
--              codRes:=-1;
              codRes:=-2;
              msgRes:='Atto di liquidazione non trovato.';
          when others then
              codRes:=-1;
              msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
      end;
    end if;
  --end if;

  if codRes=0 and
     --( p_ente_proprietario_id!= ENTE_REGP_GIUNTA or
       (p_tipo_provvedimento not in ( PROVV_DETERMINA_REGP,PROVV_DELIBERA_REGP,PROVV_ATTO_LIQUIDAZIONE)  )
     --)
	 then
	 begin
             msgRes:='Ricerca descri provvedimento non integrato.';
             select t.descri into h_oggetto
             from tabprovved t
             where t.codprov=p_tipo_provvedimento;


             exception
              when no_data_found then
                  codRes:=-1;
                  msgRes:='Descri Provvedimento non trovato.';
              when others then
                  codRes:=-1;
                  msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
        end;
    end if;

  -- da vedere ancora numero repertorio per consiglio !

  -- per gli enti diversi da RegPGiunta verifico attivazione integrazione rispetto procedura Atti
  /*if codRes=0 and p_ente_proprietario_id!= ENTE_REGP_GIUNTA then
    begin
     msgRes:='Verifica integrazioneper tipo provvedimento '||p_tipo_provvedimento||' per ente strumentale.';
     select anno_avvio, ente, t_tipologia_atto_id
            into h_anno_avvio_ente_str, h_ente,h_tipo_atto_id
     from tabprovved_enti
     where codprov=p_tipo_provvedimento;

     if to_number(p_anno_provvedimento)>=to_number(h_anno_avvio_ente_str) then
       begin
        select substr(oggetto,1,500) into h_oggetto
        from  atti_enti
        where ente = h_ente and
              t_tipologia_atto_id=h_tipo_atto_id and
              numero_definitivo=p_numero_provvedimento and
              to_char(data_atto,'yyyy')=p_anno_provvedimento;

         exception
              when no_data_found then
                  codRes:=-1;
                  msgRes:='Provvedimento ente strumentale non trovato.';
              when others then
                  codRes:=-1;
                  msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
       end;
     end if;

     exception
        when no_data_found then
             null;
        when others then
             codRes:=-1;
             msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';

    end;
  end if;*/


  if codRes=0 then
   if h_oggetto is not null then
    p_oggetto_provvedimento:= h_oggetto;
   else p_oggetto_provvedimento:='         ';
   end if;
   if h_stato_provvedimento is not null then
     p_stato_provvedimento:=h_stato_provvedimento;
   end if;
   if h_note is not null then
     p_note_provvedimento := h_note;
   end if;
   /*if h_numero_provvedimento_calcolato > 0 then
     p_numero_provvedimento_calcolato := h_numero_provvedimento_calcolato
   else
     p_numero_provvedimento_calcolato := p_numero_provvedimento;
   end if;*/
  end if;

  p_codRes:=codRes;
  if codRes=0 then
    p_msgRes:=p_msgRes||'Lettura OK.';
  else
    p_msgRes:=p_msgRes||msgRes;
  end if;
exception
  when others then
    p_msgRes:=p_msgRes||msgRes||'Errore ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
    p_codRes:=-1;
end leggi_provvedimento;


procedure leggi_provvedimento_liq(p_anno_provvedimento varchar2,p_numero_provvedimento varchar2,
                              p_tipo_provvedimento varchar2,p_direzione_provvedimento varchar2,
                              p_ente_proprietario_id number,
                              p_codRes out number,p_msgRes  out varchar2,
                              p_oggetto_provvedimento out varchar2,p_stato_provvedimento out varchar2,
                              p_note_provvedimento out varchar2,
                              p_nprov_calcolato out varchar2
                             ) is

h_numero_provvedimento number:=0;
h_nprov_calcolato number:=0;
h_stato_provvedimento varchar2(5):=null;
h_nro_prov     number:=0;
h_nro_def      number:=0;
h_oggetto      varchar2(500):=null;
h_esito_giunta varchar2(10):=null;
h_note         varchar2(500):=null;
h_nelenco      number:=0;

h_anno_avvio_ente_str varchar2(4):=null;

h_ente varchar2(10):=null;
h_tipo_atto_id number:=0;

codRes  number:=0;
msgRes  varchar2(1500):=null;

begin

  h_numero_provvedimento:= to_number(p_numero_provvedimento);

  p_oggetto_provvedimento:=null;
  p_stato_provvedimento:=null;
  p_note_provvedimento:=null;

  p_codRes:=0;
  p_msgRes:='Lettura dati provvedimento '||p_anno_provvedimento||'/'||p_numero_provvedimento||
            ' tipo '||p_tipo_provvedimento||' sac '||p_direzione_provvedimento||'.';

    if p_tipo_provvedimento = PROVV_DETERMINA_REGP then
      begin
          msgRes:='Ricerca dati determina.';
          select d.oggetto into h_oggetto
          from determine d, direzioni dd
          where d.anno=p_anno_provvedimento and
                d.num_determ=h_numero_provvedimento and
                dd.direzione=p_direzione_provvedimento and
                d.cod_dir=dd.cod_dir;

      exception
          when no_data_found then
              codRes:=-1;
              msgRes:='Determina non trovata';
          when others then
              codRes:=-1;
              msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';

      end;
    elsif p_tipo_provvedimento=PROVV_DELIBERA_REGP then
          begin
--              if p_anno_provvedimento > 2012 then 26.01.2017 Sofia mail di Ivano del 26.01.2017 le delibere 2013, 2014 sono state storicizzate
              if p_anno_provvedimento > 2014 then                
                  msgRes:='Ricerca dati delibera su tab. delibere';
                  select d.nro_provv,d.nro_def,d.oggetto,d.esito_giunta
                    into h_nro_prov,h_nro_def,h_oggetto,h_esito_giunta
                    from delibere d
                   where ( h_numero_provvedimento>=50000 and d.nro_provv=h_numero_provvedimento) or
                         ( h_numero_provvedimento<50000 and  d.nro_def=h_numero_provvedimento and d.anno=p_anno_provvedimento);
              else
                  msgRes:='Ricerca dati delibera su tab. delibere_storico';
                  select d.nro_provv,d.nro_def,d.oggetto,d.esito_giunta
                    into h_nro_prov,h_nro_def,h_oggetto,h_esito_giunta
                    from delibere_storico d
                   where ( h_numero_provvedimento>=50000 and d.nro_provv=h_numero_provvedimento) or
                         ( h_numero_provvedimento<50000 and  d.nro_def=h_numero_provvedimento and d.anno=p_anno_provvedimento);
              end if;

              if h_numero_provvedimento>=50000 and  h_nro_prov=h_nro_def then
                  h_stato_provvedimento:='P';
              end if;

              if (h_numero_provvedimento>=50000 and  h_nro_prov!=h_nro_def) or h_numero_provvedimento<50000 then
                  if h_esito_giunta='AP' then
                      h_stato_provvedimento:='D';
                  else
                      --h_stato_provvedimento:='A';
                      codRes:=-1;
                      msgRes:='Delibera ANNULLATA, esito giunta '||h_esito_giunta||'.';
                  end if;
              end if;

           exception
              when no_data_found then
                  codRes:=-1;
                  msgRes:='Delibera non trovata.';
              when others then
                  codRes:=-1;
                  msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
           end;

      -- 12.05.2015, daniela gestione tipo AL
    elsif p_tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE then
      begin
          select al.causale_pagam, al.note, al.nelenco
            into h_oggetto, h_note, h_nelenco
            from atti_liquid al
           where al.annoprov=p_anno_provvedimento
             and al.nprov=p_numero_provvedimento
             and al.direzione=p_direzione_provvedimento;

          if h_nelenco > 0 then
            h_nprov_calcolato:=100000+h_nelenco;
          end if;
      exception
          when no_data_found then
              codRes:=-1;
              msgRes:='Atto di liquidazione non trovato.';
          when others then
              codRes:=-1;
              msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
      end;
    end if;

  if codRes=0 and
       (p_tipo_provvedimento not in ( PROVV_DETERMINA_REGP,PROVV_DELIBERA_REGP,PROVV_ATTO_LIQUIDAZIONE)  )
	 then
	 begin
             msgRes:='Ricerca descri provvedimento non integrato.';
             select t.descri into h_oggetto
             from tabprovved t
             where t.codprov=p_tipo_provvedimento;


             exception
              when no_data_found then
                  codRes:=-1;
                  msgRes:='Descri Provvedimento non trovato.';
              when others then
                  codRes:=-1;
                  msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
        end;
    end if;

  -- da vedere ancora numero repertorio per consiglio !

  -- per gli enti diversi da RegPGiunta verifico attivazione integrazione rispetto procedura Atti
  /*if codRes=0 and p_ente_proprietario_id!= ENTE_REGP_GIUNTA then
    begin
     msgRes:='Verifica integrazioneper tipo provvedimento '||p_tipo_provvedimento||' per ente strumentale.';
     select anno_avvio, ente, t_tipologia_atto_id
            into h_anno_avvio_ente_str, h_ente,h_tipo_atto_id
     from tabprovved_enti
     where codprov=p_tipo_provvedimento;

     if to_number(p_anno_provvedimento)>=to_number(h_anno_avvio_ente_str) then
       begin
        select substr(oggetto,1,500) into h_oggetto
        from  atti_enti
        where ente = h_ente and
              t_tipologia_atto_id=h_tipo_atto_id and
              numero_definitivo=p_numero_provvedimento and
              to_char(data_atto,'yyyy')=p_anno_provvedimento;

         exception
              when no_data_found then
                  codRes:=-1;
                  msgRes:='Provvedimento ente strumentale non trovato.';
              when others then
                  codRes:=-1;
                  msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
       end;
     end if;

     exception
        when no_data_found then
             null;
        when others then
             codRes:=-1;
             msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';

    end;
  end if;*/


  if codRes=0 then
   if h_oggetto is not null then
    p_oggetto_provvedimento:= h_oggetto;
   else p_oggetto_provvedimento:='         ';
   end if;
   if h_stato_provvedimento is not null then
     p_stato_provvedimento:=h_stato_provvedimento;
   end if;
   if h_note is not null then
     p_note_provvedimento := h_note;
   end if;
   if h_nprov_calcolato > 0 then
     p_nprov_calcolato := h_nprov_calcolato;
   else
     p_nprov_calcolato := p_numero_provvedimento;
   end if;
  end if;

  p_codRes:=codRes;
  if codRes=0 then
    p_msgRes:=p_msgRes||'Lettura OK.';
  else
    p_msgRes:=p_msgRes||msgRes;
  end if;
exception
  when others then
    p_msgRes:=p_msgRes||msgRes||'Errore ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
    p_codRes:=-1;
end leggi_provvedimento_liq;


function fnc_migr_impegno(p_ente_proprietario_id number,
                             p_anno_esercizioIniziale varchar2,
                             p_anno_esercizio varchar2,
                             p_cod_res out number,
                             p_imp_inseriti out number,
                             p_imp_scartati out number)
return varchar2 is

       msgRes varchar2(1500):=null;
       codRes number:=0;

       h_soggetto_determinato varchar2(1):=null;
       h_classe_soggetto varchar2(250):=null;
       h_indet  number:=0;
       h_sogg_migrato    number:=0;
       h_stato_impegno varchar2(1):=null;
       
       -- 21.03.2016 Sofia
       h_anno_plur number:=0;
       
       h_numero_ueb    number:=1;
       h_numero_ueb_orig    number:=1;
       h_pdc_finanziario MIGR_CAPITOLO_USCITA.PDC_FIN_QUINTO%type := null;
       h_per_sanitario varchar2(1):=null;
       h_impegno varchar2(50):=null;
       migrClasse tab_tipi_forn%rowtype;
       h_num number:=0;

       h_anno_provvedimento   varchar2(4):=null;
       h_numero_provvedimento varchar2(10):=null;
       h_tipo_provvedimento   varchar2(20):=null;
       h_direzione_provvedimento varchar2(20):=null;

       h_stato_provvedimento   varchar2(5):=null;
       h_oggetto_provvedimento varchar2(500):=null;
       h_note_provvedimento    varchar2(500):=null;

       h_nota varchar2(250) :=null;

       h_classificatore_1      varchar2(250):=null;
       h_classificatore_2      varchar2(250):=null;
       h_classificatore_3      varchar2(250):=null;
       h_classificatore_4      varchar2(250):=null;
       h_classificatore_5      varchar2(250):=null;
       h_parere_finanziario    number(1) := 0;

       msgMotivoScarto varchar2(1500):=null;
       msgResOut varchar2(1500):=null;

       cImpInseriti number:=0;
       cImpScartati number:=0;
       numImpegno number:=0;
       h_annoimp_riacc varchar2(10):=null; -- DAVIDE - 26.10.2016 - Popolamento campi riaccertato
       h_nimp_riacc number(10):=null;      -- DAVIDE - 26.10.2016 

       segnalare boolean := False; -- True: il record � inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record � inserito nella sola tabella migr_*
       h_oggetto_provvLR varchar2(500) :=null;
begin

       p_imp_scartati:=0;
       p_imp_inseriti:=0;
       p_cod_res:=0;

       msgResOut:='Migrazione impegni.';

       -- 21.03.2016 Sofia
       h_anno_plur :=p_anno_esercizio - p_anno_esercizioIniziale;

       -- 20.01.2017 Sofia aggiunto un Art.
       msgRes:='Lettura oggetto provvedimento LR.';
       select 'Art. '||PAR_CHAR into h_oggetto_provvLR
       from tab_parametri where cod_par = 'PLINP';


       msgRes:='Lettura Impegni.';
       -- Sofia 20.11.014 - forziamo articolo a zero poiche non passano e quindi gli impegni vengono reimputati a capitolo/articolo=0
       for  migrImpegno in
       ( select i.anno_esercizio,i.annoimp anno_impegno,i.nimp numero_impegno,0 numero_subimpegno,null pluriennale,
                'N' capo_riacc,
                i.nro_capitolo numero_capitolo,
                0 numero_articolo,
                --i.nro_articolo numero_articolo,
                to_char(i.dataemis,'YYYY-MM-DD') data_emissione,
                null data_scadenza,i.staoper stato_impegno,
                i.impoini importo_iniziale,i.impoatt importo_attuale,i.descri descrizione,
                i.annoimp anno_capitolo_orig,i.cap_origine numero_capitolo_orig,i.art_origine numero_articolo_orig,
                decode(nvl(i.nprov,'X'),'X',null,i.annoprov) anno_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,to_number(i.nprov)) numero_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                i.codben codice_soggetto, i.tipoforn classe_soggetto,i.nota , i.cup,i.cig,TIPO_IMPEGNO_SVI tipo_impegno,
                null anno_impegno_plur, null numero_impegno_plur,
                null anno_impegno_riacc,null numero_impegno_riacc, null opera, i.cod_interv_class ,
	-- DAVIDE - 26.02.016 - valorizzazione campi relativi alla tavola impegni_classif
                --null pdc_finanziario , null missione,null programma,null cofog,
                --null transazione_ue_spesa, null siope_spesa,null spesa_ricorrente,
                --null politiche_regionali_unitarie, null pdc_economico_patr ,
                --i.codtitgiu ,i.trasf_tipo,i.trasf_voce , i.nord direzione_delegata, i.centro_resp centro_resp
                --, i.corr_entr
         --from impegni i
		 --where i.anno_esercizio=p_anno_esercizio and
         --      i.staoper in ('P','D')
                NVL(c.conto, null) pdc_finanziario , null missione,null programma,c.cofog cofog,
                c.transaz_un_eur transazione_ue_spesa, null siope_spesa,c.ricorrente spesa_ricorrente,
                c.polit_reg_unit politiche_regionali_unitarie, null pdc_economico_patr ,
                i.codtitgiu ,i.trasf_tipo,i.trasf_voce , i.nord direzione_delegata, i.centro_resp centro_resp
                , i.corr_entr, c.perim_sanit perimetro_sanitario_spesa
         from impegni i, impegni_classif c, cap_uscita cap
         where i.anno_esercizio=p_anno_esercizio and
               i.annoimp=decode(h_anno_plur,0,i.annoimp,i.anno_esercizio) and -- 21.03.2016 Sofia
               i.staoper in ('P','D') and
               cap.anno_esercizio=p_anno_esercizioIniziale and  -- 21.03.2016 aggiunto join su cap_uscita  altrimenti tira su anche gli impegni pluriennali del nuovo bilancio
               cap.nro_capitolo=i.nro_capitolo and
               cap.nro_articolo=0 and
               c.annoimp (+) =i.annoimp and
               c.nimp (+) =i.nimp 
               and 0 !=(select count(*)
                        from d118_impegni_rsr r
                        where i.anno_esercizio = r.anno_esercizio and
                              i.annoimp = r.annoimp and
                              i.nimp = r.nimp and
                              r.anno_esercizio_orig = '2017'
                        )
/*               i.annoimp=c.annoimp and
               i.nimp=c.nimp*/
    -- DAVIDE - 26.02.016 - Fine
         order by 1,2,3
       )
       loop
               -- inizializza variabili
               h_classe_soggetto:=null;
               h_indet:=0;
               h_soggetto_determinato:='S';
               h_sogg_migrato:=0;
               h_stato_impegno := migrImpegno.stato_impegno;
               h_anno_provvedimento:=null;
               h_numero_provvedimento:=null;
               h_tipo_provvedimento:=null;
               h_direzione_provvedimento:=null;
               h_stato_provvedimento:=null;
               h_oggetto_provvedimento:=null;
               h_note_provvedimento:=null;
               h_per_sanitario:=null;
               h_classificatore_1:=null;
               h_classificatore_2:=null;
               h_classificatore_3:=null;
               h_nota:=null;
               codRes:=0;
               msgMotivoScarto:=null;
               msgRes:=null;
               h_num:=0;
               h_pdc_finanziario:=null;
               h_parere_finanziario:=0;
               segnalare := false;
               h_annoimp_riacc:=null; -- DAVIDE - 26.10.2016 - Popolamento campi riaccertato
               h_nimp_riacc:=null;    -- DAVIDE - 26.10.2016 

               h_impegno:='Impegno '||migrImpegno.anno_impegno||'/'||migrImpegno.numero_impegno||'.';
               -- verifica capitolo migrato
	-- DAVIDE - 26.02.016 - se pdc_finanziario non trovato sulla tavola impegni_classif, leggilo dal CAPITOLO QUINTO
	           if migrImpegno.pdc_finanziario is null then
                   begin
                       msgRes:='Lettura capitolo migrato.';
                       select PDC_FIN_QUINTO  into h_pdc_finanziario
                         from  migr_capitolo_uscita m
                        where
                             --m.anno_esercizio=p_anno_esercizio and
                               m.anno_esercizio=p_anno_esercizioIniziale and
                               m.numero_capitolo=migrImpegno.numero_capitolo and
                               m.tipo_capitolo='CAP-UG'
                        -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                               and m.ente_proprietario_id=p_ente_proprietario_id;
                   exception
                       when no_data_found then
                           codRes:=-1;
                           msgRes:='Capitolo non migrato.';
                   end;
			   else
			       h_pdc_finanziario := migrImpegno.pdc_finanziario;
               end if;
	-- DAVIDE - 26.02.016 - Fine
	
               -- DAVIDE - 26.10.2016 - Popolamento campi riaccertato
               if codRes=0 then
                   begin
                       msgRes:='Lettura impegno origine riaccertamento.';
                       select r.annoimp_orig, r.nimp_orig into h_annoimp_riacc,h_nimp_riacc
                         from d118_impegni_rsr r
                        where r.anno_esercizio = p_anno_esercizio 
                        and   r.annoimp = migrImpegno.anno_impegno
                        and   r.nimp =  migrImpegno.numero_impegno
                        and   r.anno_esercizio_orig = p_anno_esercizioIniziale;
                   exception 
                       when others then
					       h_annoimp_riacc := null;
						   h_nimp_riacc    := null;
                   end;           
               end if;
               -- DAVIDE - 26.10.2016 - Fine

               if codRes=0 then
                -- soggetto_determinato
                if migrImpegno.codice_soggetto!=0 then
                  msgRes:='Lettura soggetto determinato S-N.';
                  begin
                   select nvl(count(*),0) into h_indet
                   from benef_tipi b , tab_tipi_forn t
                   where b.codben=migrImpegno.codice_soggetto and
                        t.tipoforn=b.tipoforn and
                        t.fl_tipo_dati!=0;

                   if h_indet!=0 then
                      h_soggetto_determinato:='N';
                   end if;

                   exception
                         when no_data_found then
                            null;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                  end;
                else
                  msgRes:='Lettura soggetto determinato S-N.';
                  h_soggetto_determinato:='N';
                end if;
              end if;

               -- classe_soggetto
               if  migrImpegno.classe_soggetto is not null and codRes=0 then
                 msgRes:='Lettura classe soggetto.';
                 begin

                   select * into migrClasse
                   from tab_tipi_forn
                   where tipoforn=migrImpegno.classe_soggetto;

                   h_classe_soggetto:=migrClasse.tipoforn||'||'||migrClasse.descri;

                   exception
                        when no_data_found then
                            codRes:=-1;
                            msgRes:='Classe Soggetto non trovata.';
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                 end;
               end if;

--               dbms_output.put_line('QUI QUQI UQIUQ UQIU '||h_impegno);
               -- codice
               if h_soggetto_determinato='S' and codRes=0 then

                 msgRes:='Verifica soggetto migrato.';
                 begin
                  select nvl(count(*),0) into h_sogg_migrato
                  from migr_soggetto
                  where codice_soggetto=migrImpegno.codice_soggetto and
                        ente_proprietario_id=p_ente_proprietario_id;

                  if h_sogg_migrato=0 then
                    msgRes:='Soggetto determinato non migrato.';
--                    msgMotivoScarto:=msgRes;
                  end if;

                  exception
                         when no_data_found then
                            h_sogg_migrato:=0;
                            msgRes:='Soggetto determinato non migrato.';
--                            msgMotivoScarto:=msgRes;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                end;

                if codRes=0 and h_sogg_migrato=0 then
                   begin
                      codRes:=-1; --codice scarto per soggetto definito non migrato
                      select nvl(count(*),0) into h_num
                      from fornitori
                      where codben=migrImpegno.codice_soggetto and
                            blocco_pag='N';

                      if h_num=0 then
--                        codRes:=-1;
                        msgRes:=msgRes||'Soggetto non valido.';
--                        msgMotivoScarto:=msgRes;
                      end if;
                  exception
                         when no_data_found then
                            h_sogg_migrato:=0;
                            h_num:=0;
--                            codRes:=-1;
                            msgRes:=msgRes||'Soggetto non valido.';
--                            msgMotivoScarto:=msgRes;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                   end;
                end if;
               end if;

              -- 29.05.2015
              if codRes=0 then
                 msgRes:='Lettura dati Provvedimento.';
                 if
                   (migrImpegno.numero_provvedimento is null or migrImpegno.numero_provvedimento ='0') then
                     if migrImpegno.stato_impegno!=STATO_P then
                       if migrImpegno.corr_entr = 'S' then
                          h_stato_provvedimento:='D';
                          h_numero_provvedimento:=NUMPROVV_LR;
                          h_anno_provvedimento:=ANNOPROVV_LR;
                          h_tipo_provvedimento:=PROVV_LR||'||';
                          h_oggetto_provvedimento:=h_oggetto_provvLR;
                          -- 23.02.2016 Dani Segnalare il caso
                          segnalare := true;
                          msgMotivoScarto := 'Provvedimento non presente per impegno in stato '||migrImpegno.stato_impegno||'. Provvedimento associato '||PROVV_LR||'.';

                       else
                          h_stato_provvedimento:='D';
                          h_anno_provvedimento:=p_anno_esercizio;
                          h_tipo_provvedimento:=PROVV_SPR||'||';

                          -- 29.07.2015 Dani Segnalare il caso
                          segnalare := true;
                          msgMotivoScarto := 'Provvedimento non presente per impegno in stato '||migrImpegno.stato_impegno||'.Provvedimento associato '||PROVV_SPR||'.';
                       end if;
                     end if;
                 else
                    h_anno_provvedimento:=migrImpegno.anno_provvedimento;
                    h_numero_provvedimento:=migrImpegno.numero_provvedimento;
                    h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
                    h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

                    leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,
                                        h_tipo_provvedimento,h_direzione_provvedimento,p_ente_proprietario_id,
                                        codRes,msgRes,h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);
                    if codRes=0 then
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                       if migrImpegno.tipo_provvedimento = PROVV_DETERMINA_REGP then
                          h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                       else
                          if h_direzione_provvedimento is not null then
                             h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                          end if;
                       end if;
                    end if;
                    if codRes=0 and h_stato_provvedimento is null then
                         h_stato_provvedimento:='D';
                    end if;
                    if codRes=-2 then
                      -- Provvedimento non trovato.
                      h_stato_provvedimento:='D';
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';
                      h_numero_provvedimento:=null;

                      segnalare := true;
                      msgMotivoScarto := msgRes;
                      codRes := 0; -- Il record continua ad essere elaborato normalmente.
                    end if;
                 end if;
              end if;
              --  stato_impegno da calcolare
              if codRes=0 then
                 msgRes:='Definizione stato impegno.';
                 if h_stato_provvedimento = 'D' then
                   if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                        h_stato_impegno:=STATO_D;
                   else
                        h_stato_impegno:=STATO_N;
                   end if;
                 elsif h_stato_provvedimento = 'P' then
                   if migrImpegno.stato_impegno = 'P' then
                      h_stato_impegno := 'P';
                   else
                     -- 27.07.2015 Non scartare ma segnalare
--                     codRes:=-1;
--                     msgRes:=msgRes||'Stato impegno '||migrImpegno.stato_impegno||' per provvedimento in stato P.';
                     segnalare := true;
                     if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                          h_stato_impegno:=STATO_D;
                     else
                          h_stato_impegno:=STATO_N;
                     end if;
                     msgMotivoScarto := 'Provvedimento in P per impegno in stato '||migrImpegno.stato_impegno;
                   end if;
                 end if;
              end if;
              --  Definizione flag parere_finanziario
              if codRes=0 then
                 msgRes:='Definizione flag parere finanziario.';
                 if h_stato_impegno ='P' then
                      h_parere_finanziario:=0; -- false
                 else
                      h_parere_finanziario:=1; -- true
                 end if;
              end if;

/* 18.05.2015 Cambiata la logica a favore di quanto scritto sopra.
               --  stato_impegno da calcolare
               if codRes=0 then
                msgRes:='Calcolo stato impegno.';
                if migrImpegno.stato_impegno ='P' then
                  h_stato_impegno:=STATO_P;
                else
                  if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                      h_stato_impegno:=STATO_D;
                  else
                      h_stato_impegno:=STATO_N;
                  end if;
                end if;
              end if;
              -- provvedimento
              if codRes=0 then
                 msgRes:='Lettura dati Provvedimento.';
                 if migrImpegno.numero_provvedimento is null or migrImpegno.numero_provvedimento ='0' then
                   if  h_stato_impegno!=STATO_P then
                    h_anno_provvedimento:=p_anno_esercizio;
                    h_tipo_provvedimento:=PROVV_SPR||'||';
                   end if;
                 else
                    h_anno_provvedimento:=migrImpegno.anno_provvedimento;
                    h_numero_provvedimento:=migrImpegno.numero_provvedimento;
                    h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
                    h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

                    leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,
                                        h_tipo_provvedimento,h_direzione_provvedimento,p_ente_proprietario_id,
                                        codRes,msgRes,h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);
                    if codRes=0 then
                     if p_ente_proprietario_id!= ENTE_COTO  then
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                     else
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||';
                     end if;

                     if p_ente_proprietario_id= ENTE_REGP_GIUNTA  then
                       if migrImpegno.tipo_provvedimento = PROVV_DETERMINA_REGP then
                              h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                       else
                              if h_direzione_provvedimento is not null then
                               h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                              end if;

                       end if;
                     end if;
                   end if;

                   if codRes=0 and h_stato_provvedimento is null then
                      h_stato_provvedimento:=h_stato_impegno;
                      if h_stato_provvedimento='N' then
                         h_stato_provvedimento:='D';
                      end if;
                   end if;
                 end if;
              end if;
*/
              --  perimetro_sanitario_spesa
              --if codRes=0 and p_ente_proprietario_id=ENTE_REGP_GIUNTA then
		-- DAVIDE - 26.02.016 - tolta lettura del perimetro sanitario entrata - ora lo prendiamo da impegni_classif
              /*if codRes=0 then
                msgRes:='Lettura perimetro sanitario spesa.';
                begin
                  select decode(i.fl_coge,'S',SPE_GEST_SANITA,SPE_GEST_REG) into h_per_sanitario
                  from impegno_coge i
                  where i.anno_esercizio=migrImpegno.anno_esercizio and
                        i.annoimp=migrImpegno.anno_impegno and
                        i.nimp=migrImpegno.numero_impegno;

                   exception
                         when no_data_found then
                              h_per_sanitario:=SPE_GEST_REG;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                end;
              end if;*/

			  h_per_sanitario:=migrImpegno.perimetro_sanitario_spesa;

		-- DAVIDE - 26.02.016 -  Fine

              -- classificatore_1 --> classificatore_11
              --if p_ente_proprietario_id=ENTE_REGP_GIUNTA and codRes=0 and migrImpegno.codtitgiu is not null then
              if codRes=0 and migrImpegno.codtitgiu is not null then
                 msgRes:='Lettura dati classificatore_11.';
                 begin
                   select migrImpegno.codtitgiu||'||'||t.descri
                          into h_classificatore_1
                   from tabtitgiu  t
                   where t.codtitgiu=migrImpegno.codtitgiu;

                   exception
                         when no_data_found then
                            codRes:=-1;
                            msgRes:=msgRes||'Non presente.';
                            h_classificatore_1:=null;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                 end;
              end if;
              -- classificatore_2 --> classificatore_12
              -- classificatore_3 --> classificatore_13
              --if p_ente_proprietario_id=ENTE_REGP_GIUNTA and codRes=0 and
              if codRes=0 and
                 migrImpegno.trasf_tipo  is not null and migrImpegno.trasf_voce  is not null then

                 msgRes:='Lettura dati classificatore_12 e classificatore_13.';
                -- dbms_output.put_line('h_impegno '||h_impegno);
                --  dbms_output.put_line('TRASF_TIPO '||migrImpegno.trasf_tipo);
                -- dbms_output.put_line('TRASF_VOCE '||migrImpegno.trasf_voce);

                 begin
                   select migrImpegno.trasf_tipo||'||'||t.descrizione||'-'||t.denomin_voce
                          into h_classificatore_2
                   from trasf_tipi  t
                   where t.trasf_tipo=migrImpegno.trasf_tipo and
                         t.fl_valido='S';

                   begin
                      select migrImpegno.trasf_voce||'||'||t.descrizione
                          into h_classificatore_3
                      from trasf_voci  t
                      where  t.trasf_tipo=migrImpegno.trasf_tipo and
                             t.trasf_voce=migrImpegno.trasf_voce and
                             t.fl_valido='S';

                      exception
                         when no_data_found then
                            codRes:=-1;
                            msgRes:=msgRes||'Classificatore_13 non presente.';
                            h_classificatore_3:=null;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||'Errore per classificatore_13 '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                   end;

                   exception
                         when no_data_found then
                            codRes:=-1;
                            h_classificatore_2:=null;
                            h_classificatore_3:=null;
                            msgRes:=msgRes||'Classificatore_12 non presente.';
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||'Errore per classificatore_12 '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                 end;
              end if;

			  -- DAVIDE - 27.11.2015 - SOLO PER REGP --
			  --          Aggiunta popolamento classificatore_4 --> classificatore_14
              if codRes=0  then

                 msgRes:='Lettura dati classificatore_14.';

                 begin

                     select classif.code_bandi||'||'||classif.desc_bandi
                       into h_classificatore_4
                       from impegni_classif imp ,
                            (select  id_ambito id_bandi_4,0 id_bandi_5, programma||'.'||asse||'.'||b.linea_finanziam||'.'||ambito code_bandi, desc_linea desc_bandi
                               from  bandi_linea  b
                             where   livello=4
                             union
                             select  id_ambito id_bandi_4, b.progr_bando_linea id_bandi_5, programma||'.'||asse||'.'||b.linea_finanziam||'.'||ambito||'.'||b.id_bando code_bandi, desc_linea desc_bandi
                               from  bandi_linea  b
                              where  livello=5
                             order by 1,2) classif
                      where imp.id_ambito !=0
                      and   imp.id_ambito=classif.id_bandi_4
                      and   imp.progr_bando_linea (+) = classif.id_bandi_5
                      and   imp.annoimp=migrImpegno.anno_impegno
                      and   imp.nimp=migrImpegno.numero_impegno;

                 exception
                     when no_data_found then
                         h_classificatore_4:=null;
                     when others then
                         codRes:=-1;
                         msgRes:=msgRes||'Errore per classificatore_14 '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                 end;
              end if;
			  -- DAVIDE - 27.11.2015 - SOLO PER REGP -- Fine

              --- note
              h_nota:=migrImpegno.nota;
              --if p_ente_proprietario_id= ENTE_REGP_GIUNTA then
                 if migrImpegno.direzione_delegata is not null then
                    h_nota:=h_nota||' DIR_DEL='||migrImpegno.direzione_delegata;
                 end if;
              /*else
                 if  p_ente_proprietario_id= ENTE_AIPO then
                   if migrImpegno.centro_resp is not null then
                    h_nota:=h_nota||' CDR='||migrImpegno.centro_resp;
                   end if;
                 end if;
              end if;*/


              if codRes=0
                --and (h_soggetto_determinato='N'  or (h_soggetto_determinato='S' and  h_sogg_migrato<>0))
              then
               msgRes:='Inserimento in migr_impegno.';
               insert into migr_impegno
               ( impegno_id,tipo_movimento,anno_esercizio,anno_impegno,numero_impegno,numero_subimpegno,pluriennale,
                 capo_riacc,numero_capitolo,numero_articolo,numero_ueb,data_emissione,data_scadenza,stato_operativo,
                 importo_iniziale,importo_attuale,descrizione,anno_capitolo_orig,numero_capitolo_orig,numero_articolo_orig,
                 numero_ueb_orig,anno_provvedimento,numero_provvedimento,tipo_provvedimento,sac_provvedimento,
                 oggetto_provvedimento,note_provvedimento,stato_provvedimento,soggetto_determinato,
                 codice_soggetto,classe_soggetto,nota,cup,cig,tipo_impegno,anno_impegno_plur,numero_impegno_plur,
                 anno_impegno_riacc,numero_impegno_riacc,opera ,cod_interv_class,pdc_finanziario,missione,programma,
                 cofog,transazione_ue_spesa,siope_spesa,spesa_ricorrente,perimetro_sanitario_spesa,politiche_regionali_unitarie,
                 pdc_economico_patr,CLASSIFICATORE_1,CLASSIFICATORE_2,CLASSIFICATORE_3,CLASSIFICATORE_4,CLASSIFICATORE_5,
                 ente_proprietario_id, parere_finanziario)
                values
                (migr_impegno_id_seq.nextval, TIPO_IMPEGNO_I,migrImpegno.anno_esercizio,migrImpegno.anno_impegno,migrImpegno.numero_impegno,
                 migrImpegno.numero_subimpegno,migrImpegno.pluriennale,migrImpegno.capo_riacc,
                 migrImpegno.numero_capitolo,migrImpegno.numero_articolo,h_numero_ueb,migrImpegno.data_emissione,migrImpegno.data_scadenza,
                 h_stato_impegno,migrImpegno.importo_iniziale,migrImpegno.importo_attuale,migrImpegno.descrizione,
                 migrImpegno.anno_capitolo_orig,migrImpegno.numero_capitolo_orig,migrImpegno.numero_articolo_orig,h_numero_ueb_orig,
                 h_anno_provvedimento,to_number(h_numero_provvedimento),h_tipo_provvedimento,h_direzione_provvedimento,
                 h_oggetto_provvedimento,h_note_provvedimento,h_stato_provvedimento,h_soggetto_determinato,
                 migrImpegno.codice_soggetto,h_classe_soggetto,h_nota,migrImpegno.cup,migrImpegno.cig,
                 migrImpegno.tipo_impegno,migrImpegno.anno_impegno_plur,migrImpegno.numero_impegno_plur,
                 --migrImpegno.anno_impegno_riacc,migrImpegno.numero_impegno_riacc,migrImpegno.opera,migrImpegno.cod_interv_class, -- DAVIDE - 26.10.2016
                 h_annoimp_riacc,h_nimp_riacc,migrImpegno.opera,migrImpegno.cod_interv_class,                                      -- DAVIDE - 26.10.2016
                 h_pdc_finanziario,migrImpegno.missione,migrImpegno.programma,
                 migrImpegno.cofog,migrImpegno.transazione_ue_spesa,migrImpegno.siope_spesa,migrImpegno.spesa_ricorrente,
                 h_per_sanitario,migrImpegno.politiche_regionali_unitarie,migrImpegno.pdc_economico_patr,
                 h_classificatore_1,h_classificatore_2,h_classificatore_3,h_classificatore_4,h_classificatore_5,
                 p_ente_proprietario_id, h_parere_finanziario);

                 cImpInseriti:=cImpInseriti+1;
               end if;

               if codRes!=0 or
                 --( h_soggetto_determinato='S' and  h_sogg_migrato=0) or
                 segnalare = true  then
                 if codRes!=0 then
                     msgMotivoScarto:=msgRes;
                 end if;

                 msgRes:='Inserimento in migr_impegno_scarto.';
                 insert into migr_impegno_scarto
                 (impegno_scarto_id,anno_esercizio,anno_impegno,numero_impegno,numero_subimpegno,
                  motivo_scarto,ente_proprietario_id)
                  values
                 (migr_impegno_scarto_id_seq.nextval,migrImpegno.anno_esercizio,migrImpegno.anno_impegno,migrImpegno.numero_impegno,migrImpegno.numero_subimpegno,
                  msgMotivoScarto,p_ente_proprietario_id);
                  cImpScartati:=cImpScartati+1;
               end if;


               if numImpegno>=200  then
                  commit;
                  numImpegno:=0;
               else numImpegno:=numImpegno+1;
               end if;
       end loop;


       msgRes:='Inserimento migr_impegno_accertamento.';
       insert into migr_impegno_accertamento
       (vincolo_impacc_id,anno_impegno,numero_impegno,anno_accertamento,numero_accertamento,importo,
        ente_proprietario_id)
        select migr_vincolo_impacc_id_seq.nextval,i.annoimp,i.nimp,i.annoacc,i.nacc,i.importo,
               p_ente_proprietario_id
        from impegno_accertamenti i
        where i.annoimp||i.nimp in
              (select anno_impegno||numero_impegno
               from migr_impegno where anno_esercizio=p_anno_esercizio and numero_subimpegno=0) and
       i.fl_valido!='A' and
       i.annoimp||i.nimp||i.annoacc||i.nacc||i.importo not in
      (select anno_impegno||numero_impegno||anno_accertamento||numero_accertamento||importo
       from migr_impegno_accertamento where ente_proprietario_id=p_ente_proprietario_id);

       msgResOut:=msgResOut||'Elaborazione OK.Impegni inseriti='||cImpInseriti||' scartati='||cImpScartati||'.';

       p_imp_scartati:=cImpScartati;
       p_imp_inseriti:=cImpInseriti;

       commit;

       return msgResOut;

exception
  when others then
    dbms_output.put_line('Impegno '||h_impegno||' msgRes '||msgRes||' Errore '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100));
    msgResOut:=msgResOut||h_impegno||msgRes||'Errore ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
    p_imp_scartati:=cImpScartati;
    p_imp_inseriti:=cImpInseriti;
    p_cod_res:=-1;
    return msgResOut;
end fnc_migr_impegno;

function fnc_migr_subimpegno(p_ente_proprietario_id number,
                             p_anno_esercizio varchar2,
                             p_cod_res out number,
                             p_imp_inseriti out number,
                             p_imp_scartati out number)
return varchar2 is

       msgRes varchar2(1500):=null;
       codRes number:=0;

       h_sogg_migrato    number:=0;
       h_stato_impegno varchar2(1):=null;
       h_soggetto_determinato varchar2(1):=null;
       h_num number:=0;

       h_per_sanitario varchar2(1):=null;
       h_impegno varchar2(50):=null;



       h_anno_provvedimento   varchar2(4):=null;
       h_numero_provvedimento varchar2(10):=null;
       h_tipo_provvedimento   varchar2(20):=null;
       h_direzione_provvedimento varchar2(20):=null;

       h_stato_provvedimento   varchar2(5):=null;
       h_oggetto_provvedimento varchar2(500):=null;
       h_note_provvedimento    varchar2(500):=null;

	-- DAVIDE - 26.02.016 - aggiunta degli altri campi da valorizzare dalla impegni_classif, ereditati dalla migr_impegno
	   h_cofog	               varchar2(50):=null;
	   h_transazione_ue_spesa  varchar2(50):=null;
	   h_spesa_ricorrente      varchar2(50):=null;
	   h_pol_reg_unitarie      varchar2(50):=null;
	-- DAVIDE - 26.02.016 - Fine

       msgMotivoScarto varchar2(1500):=null;
       msgResOut varchar2(1500):=null;

       cImpInseriti number:=0;
       cImpScartati number:=0;
       numImpegno number:=0;
       h_pdc_finanziario MIGR_IMPEGNO.PDC_FINANZIARIO%TYPE;
       segnalare boolean := False; -- True: il record � inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record � inserito nella sola tabella migr_*

begin

       p_imp_scartati:=0;
       p_imp_inseriti:=0;
       p_cod_res:=0;

       msgResOut:='Migrazione SubImpegni.';
       msgRes:='Lettura SubImpegni.';


       for  migrImpegno in
       ( select i.anno_esercizio,i.annoimp anno_impegno,i.nimp numero_impegno,i.nsubimp numero_subimpegno,
                to_char(i.dataemis,'YYYY-MM-DD') data_emissione, null data_scadenza,i.staoper stato_impegno,
                i.impoini importo_iniziale,i.impoatt importo_attuale,i.descri descrizione,
                decode(nvl(i.nprov,'X'),'X',null,i.annoprov) anno_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,to_number(i.nprov)) numero_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                i.codben codice_soggetto, i.cup,i.cig,i.cod_interv_class ,
                null pdc_finanziario , null missione,null programma,null cofog,
                null transazione_ue_spesa, null siope_spesa,null spesa_ricorrente,
                null politiche_regionali_unitarie, null pdc_economico_patr
         from subimp i
         where i.anno_esercizio=p_anno_esercizio and
               i.staoper in ('P','D') and
               i.anno_esercizio||i.annoimp||i.nimp in
               (select imp.anno_esercizio||imp.anno_impegno||imp.numero_impegno from migr_impegno imp where imp.ente_proprietario_id=p_ente_proprietario_id and imp.tipo_movimento = TIPO_IMPEGNO_I)
         order by 1,2,3,4
       )
       loop
               -- inizializza variabili
               h_sogg_migrato:=0;
               h_soggetto_determinato:='S';
               h_stato_impegno :=null;
               h_anno_provvedimento:=null;
               h_numero_provvedimento:=null;
               h_tipo_provvedimento:=null;
               h_direzione_provvedimento:=null;
               h_stato_provvedimento:=null;
               h_oggetto_provvedimento:=null;
               h_note_provvedimento:=null;
               h_per_sanitario:=null;
               codRes:=0;
               msgMotivoScarto:=null;
               msgRes:=null;
               h_num:=0;
               h_pdc_finanziario := null;

	-- DAVIDE - 26.02.016 - aggiunta degli altri campi da valorizzare dalla impegni_classif, ereditati dalla migr_impegno
	           h_cofog	               :=null;
	           h_transazione_ue_spesa  :=null;
	           h_spesa_ricorrente      :=null;
	           h_pol_reg_unitarie      :=null;
	-- DAVIDE - 26.02.016 - Fine

               segnalare := false;
               h_impegno:='SubImpegno '||migrImpegno.anno_impegno||'/'||migrImpegno.numero_impegno||'/'||migrImpegno.numero_subimpegno||'.';

                -- soggetto_determinato
               if migrImpegno.codice_soggetto=0 then
                  msgRes:='Lettura soggetto indeterminato.';
                  h_soggetto_determinato:='N';
                  codRes:=-1;
               end if;

               -- codice
               if h_soggetto_determinato='S' and codRes=0 then

                 msgRes:='Verifica soggetto migrato.';
                 begin
                  select nvl(count(*),0) into h_sogg_migrato
                  from migr_soggetto
                  where codice_soggetto=migrImpegno.codice_soggetto and
                        ente_proprietario_id=p_ente_proprietario_id;

                  if h_sogg_migrato=0 then
                    msgRes:='Soggetto determinato non migrato.';
--                    msgMotivoScarto:=msgRes;
                  end if;

                  exception
                         when no_data_found then
                            h_sogg_migrato:=0;
                            msgRes:='Soggetto determinato non migrato.';
--                            msgMotivoScarto:=msgRes;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                end;

                if codRes=0 and h_sogg_migrato=0 then
                   begin
                      codRes:=-1;
                      select nvl(count(*),0) into h_num
                      from fornitori
                      where codben=migrImpegno.codice_soggetto and
                            blocco_pag='N';

                      if h_num=0 then
--                        codRes:=-1;
                        msgRes:=msgRes||'Soggetto non valido.';
--                        msgMotivoScarto:=msgRes;
                      end if;
                  exception
                         when no_data_found then
                            h_sogg_migrato:=0;
                            h_num:=0;
  --                          codRes:=-1;
                            msgRes:=msgRes||'Soggetto non valido.';
  --                          msgMotivoScarto:=msgRes;

                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                   end;
                end if;
               end if;

          --  pdc_finanziario ereditato da impegno migrato
	-- DAVIDE - 26.02.016 - aggiunta degli altri campi da valorizzare dalla impegni_classif, ereditati dalla migr_impegno
            if codRes=0 then
             begin
                  select pdc_finanziario, cofog, transazione_ue_spesa, spesa_ricorrente, politiche_regionali_unitarie, perimetro_sanitario_spesa
				  into h_pdc_finanziario, h_cofog, h_transazione_ue_spesa, h_spesa_ricorrente, h_pol_reg_unitarie, h_per_sanitario
                  from migr_impegno
                  where tipo_movimento = TIPO_IMPEGNO_I
                  and anno_esercizio = migrImpegno.anno_esercizio
                  and anno_impegno = migrImpegno.anno_impegno
                  and numero_impegno = migrImpegno.numero_impegno
                  and ente_proprietario_id = p_ente_proprietario_id;
             exception
                when no_data_found then
                  codRes := -1;
                  msgRes          := msgRes || 'Impegno padre non trovato in migr_impegno.';
                  msgMotivoScarto := msgRes;
                when too_many_rows then
                  codRes := -1;
                  msgRes          := msgRes || 'Ricerca Impegno padre.Too many rows';
                  msgMotivoScarto := msgRes;
                when others then
                  codRes := -1;
                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
              end;
             end if;
	-- DAVIDE - 26.02.016 - Fine

         	  -- stato_impegno
               h_stato_impegno:=migrImpegno.stato_impegno;

              -- provvedimento
              if codRes=0 then
                 msgRes:='Lettura dati Provvedimento.';
                 if migrImpegno.numero_provvedimento is null or migrImpegno.numero_provvedimento ='0' then
                    if h_stato_impegno!=STATO_P then
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';

                      --29.7.2015 Dani, gestiamo la segnalazione
                      h_stato_provvedimento:='D';
                      segnalare := true;
                      msgMotivoScarto := 'Provvedimento non presente per subimpegno in stato '||h_stato_impegno||'.';
                    end if;
                 else
                    h_anno_provvedimento:=migrImpegno.anno_provvedimento;
                    h_numero_provvedimento:=migrImpegno.numero_provvedimento;
                    h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
                    h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

                    leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,
                                        h_tipo_provvedimento,h_direzione_provvedimento,p_ente_proprietario_id,
                                        codRes,msgRes,h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);
                    if codRes=0 then
                     --if p_ente_proprietario_id!= ENTE_COTO  then
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                     /*else
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||';
                     end if;*/

                     --if p_ente_proprietario_id= ENTE_REGP_GIUNTA  then
                       if migrImpegno.tipo_provvedimento = PROVV_DETERMINA_REGP then
                           h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                       else
                           if h_direzione_provvedimento is not null then
                               h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                           end if;

                       end if;
                    -- end if;
                    end if;

                    if codRes=0 and h_stato_provvedimento is null then
                      h_stato_provvedimento:=h_stato_impegno;
                    end if;

                   -- 29.07.2015
                   -- Da segnalare
                    if h_stato_provvedimento = STATO_P and h_stato_impegno = STATO_D then
                     segnalare := true;
                     msgMotivoScarto := 'Provvedimento in P per subimpegno in stato D';
                    end if;
                    if codRes=-2 then
                      -- Provvedimento non trovato.
                      h_stato_provvedimento:='D';
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';
                      h_numero_provvedimento:=null;

                      segnalare := true;
                      msgMotivoScarto := msgRes;
                      codRes := 0; -- Il record continua ad essere elaborato normalmente.
                    end if;
                 end if;
              end if;

              --  perimetro_sanitario_spesa
              --if codRes=0 and p_ente_proprietario_id=ENTE_REGP_GIUNTA then
	    -- DAVIDE - 26.02.016 - perimetro_sanitario_spesa ereditato dalla migr_impegno
              /*if codRes=0 then
                msgRes:='Lettura perimetro sanitario spesa.';
                begin
                  select decode(i.fl_coge,'S',SPE_GEST_SANITA,SPE_GEST_REG) into h_per_sanitario
                  from impegno_coge i
                  where i.anno_esercizio=migrImpegno.anno_esercizio and
                        i.annoimp=migrImpegno.anno_impegno and
                        i.nimp=migrImpegno.numero_impegno;

                   exception
                         when no_data_found then
                              h_per_sanitario:=SPE_GEST_REG;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                end;
              end if;*/
	    -- DAVIDE - 26.02.016 - Fine

              if codRes=0
                --and h_sogg_migrato <> 0
              -- and (h_soggetto_determinato='N' or (h_soggetto_determinato='S and  h_sogg_migrato<>0))
              then
               msgRes:='Inserimento in migr_impegno.';
               insert into migr_impegno
               ( impegno_id,tipo_movimento,anno_esercizio,anno_impegno,numero_impegno,numero_subimpegno,
                 data_emissione,data_scadenza,stato_operativo,
                 importo_iniziale,importo_attuale,descrizione,
                 anno_provvedimento,numero_provvedimento,tipo_provvedimento,sac_provvedimento,
                 oggetto_provvedimento,note_provvedimento,stato_provvedimento,soggetto_determinato,
                 codice_soggetto,cup,cig,cod_interv_class,pdc_finanziario,missione,programma,
                 cofog,transazione_ue_spesa,siope_spesa,spesa_ricorrente,perimetro_sanitario_spesa,politiche_regionali_unitarie,
                 pdc_economico_patr, ente_proprietario_id )
                values
                (migr_impegno_id_seq.nextval, TIPO_IMPEGNO_S,migrImpegno.anno_esercizio,migrImpegno.anno_impegno,migrImpegno.numero_impegno,
                 migrImpegno.numero_subimpegno,migrImpegno.data_emissione,migrImpegno.data_scadenza,
                 h_stato_impegno,migrImpegno.importo_iniziale,migrImpegno.importo_attuale,migrImpegno.descrizione,
                 h_anno_provvedimento,to_number(h_numero_provvedimento),h_tipo_provvedimento,h_direzione_provvedimento,
                 h_oggetto_provvedimento,h_note_provvedimento,h_stato_provvedimento,h_soggetto_determinato,
                 migrImpegno.codice_soggetto,migrImpegno.cup,migrImpegno.cig,migrImpegno.cod_interv_class,
                 h_pdc_finanziario,migrImpegno.missione,migrImpegno.programma,

	    -- DAVIDE - 26.02.016 - aggiunta degli altri campi da valorizzare dalla impegni_classif, ereditati dalla migr_impegno
                 --migrImpegno.cofog,migrImpegno.transazione_ue_spesa,migrImpegno.siope_spesa,migrImpegno.spesa_ricorrente,
                 --h_per_sanitario,migrImpegno.politiche_regionali_unitarie,migrImpegno.pdc_economico_patr,
				 h_cofog, h_transazione_ue_spesa,migrImpegno.siope_spesa, h_spesa_ricorrente,
				 h_per_sanitario, h_pol_reg_unitarie, migrImpegno.pdc_economico_patr,
		-- DAVIDE - 26.02.016 - Fine

                 p_ente_proprietario_id);

                 cImpInseriti:=cImpInseriti+1;
               end if;

               if codRes!=0 --or ( h_soggetto_determinato='S' and  h_sogg_migrato=0)
                 or segnalare = true
                 then
                 if codRes!=0 then
                     msgMotivoScarto:=msgRes;
                 end if;

                 msgRes:='Inserimento in migr_impegno_scarto.';
                 insert into migr_impegno_scarto
                 (impegno_scarto_id,anno_esercizio,anno_impegno,numero_impegno,numero_subimpegno,
                  motivo_scarto,ente_proprietario_id)
                  values
                 (migr_impegno_scarto_id_seq.nextval,migrImpegno.anno_esercizio,migrImpegno.anno_impegno,migrImpegno.numero_impegno,migrImpegno.numero_subimpegno,
                  msgMotivoScarto,p_ente_proprietario_id);
                  cImpScartati:=cImpScartati+1;
               end if;


               if numImpegno>=200  then
                  commit;
                  numImpegno:=0;
               else numImpegno:=numImpegno+1;
               end if;
       end loop;

       msgResOut:=msgResOut||'Elaborazione OK.Impegni inseriti='||cImpInseriti||' scartati='||cImpScartati||'.';

       p_imp_scartati:=cImpScartati;
       p_imp_inseriti:=cImpInseriti;
       commit;

       return msgResOut;

exception
  when others then
    dbms_output.put_line('SubImpegno '||h_impegno||' msgRes '||msgRes||' Errore '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100));
    msgResOut:=msgResOut||h_impegno||msgRes||'Errore ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
    p_imp_scartati:=cImpScartati;
    p_imp_inseriti:=cImpInseriti;
    p_cod_res:=-1;
    return msgResOut;
end fnc_migr_subimpegno;


function fnc_migr_accertamento(p_ente_proprietario_id number,
                              p_anno_esercizioIniziale varchar2,
                              p_anno_esercizio varchar2,
                              p_cod_res out number,
                              p_imp_inseriti out number,
                              p_imp_scartati out number) return varchar2
 is
       msgRes varchar2(1500):=null;
       codRes number:=0;

       h_soggetto_determinato varchar2(1):=null;
       h_classe_soggetto varchar2(250):=null;
       h_indet  number:=0;
       h_sogg_migrato    number:=0;
       h_stato_impegno varchar2(1):=null;

       h_numero_ueb    number:=1;
       h_numero_ueb_orig    number:=1;

       h_per_sanitario varchar2(1):=null;
       h_impegno varchar2(50):=null;
       h_num number:=0;

       h_anno_provvedimento   varchar2(4):=null;
       h_numero_provvedimento varchar2(10):=null;
       h_tipo_provvedimento   varchar2(20):=null;
       h_direzione_provvedimento varchar2(20):=null;

       h_stato_provvedimento   varchar2(5):=null;
       h_oggetto_provvedimento varchar2(500):=null;
       h_note_provvedimento    varchar2(500):=null;

       h_nota varchar2(250) :=null;
       h_automatico varchar2(1):='N';
       h_parere_finanziario integer := 1; -- non cambia rimane impostato a TRUE
       
       h_anno_plur number:=0; -- 21.03.2016 Sofia
       
       h_classificatore_1      varchar2(250):=null;
       h_classificatore_2      varchar2(250):=null;
       h_classificatore_3      varchar2(250):=null;
       h_classificatore_4      varchar2(250):=null;
       h_classificatore_5      varchar2(250):=null;

       msgMotivoScarto varchar2(1500):=null;
       msgResOut varchar2(1500):=null;

       cImpInseriti number:=0;
       cImpScartati number:=0;
       numImpegno number:=0;
       h_pdc_finanziario migr_capitolo_entrata.PDC_FIN_QUINTO%TYPE;
       segnalare boolean := False; -- True: il record � inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record � inserito nella sola tabella migr_*
       h_annoimp_riacc varchar2(10):=null; -- DAVIDE - 26.10.2016 - Popolamento campi riaccertato
       h_nimp_riacc number(10):=null;      -- DAVIDE - 26.10.2016 

begin

       p_imp_scartati:=0;
       p_imp_inseriti:=0;
       p_cod_res:=0;

       -- 21.03.2016 Sofia
       h_anno_plur :=p_anno_esercizio - p_anno_esercizioIniziale;
       
       msgResOut:='Migrazione accertamenti.';
       msgRes:='Lettura Accertamenti.';

       for  migrImpegno in
       ( select i.anno_esercizio,i.annoacc anno_accertamento,i.nacc numero_accertamento,0 numero_subaccertamento,null pluriennale,
                'N' capo_riacc,
                i.nro_capitolo numero_capitolo,i.nro_articolo numero_articolo,to_char(i.dataemis,'YYYY-MM-DD') data_emissione,
                null data_scadenza,i.staoper stato_accertamento,
                i.impoini importo_iniziale,i.impoatt importo_attuale,i.descri descrizione,
                i.annoacc anno_capitolo_orig,i.cap_origine numero_capitolo_orig,i.art_origine numero_articolo_orig,
                decode(nvl(i.nprov,'X'),'X',null,i.annoprov) anno_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,to_number(i.nprov)) numero_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                i.codben codice_soggetto, null nota ,
                null anno_accertamento_plur, null numero_accertamento_plur,
                null anno_accertamento_riacc,null numero_accertamento_riacc, null opera,
	-- DAVIDE - 26.02.016 - valorizzazione campi relativi alla tavola impegni_classif
                --null pdc_finanziario , null transazione_ue_entrata, null siope_entrata,null entrata_ricorrente,
                --null pdc_economico_patr ,i.codtitgiu
         --from accertamenti i
		 --where i.anno_esercizio=p_anno_esercizio and
         --      i.staoper in ('P','D')
                NVL(c.conto, null) pdc_finanziario , c.transaz_un_eur transazione_ue_entrata, null siope_entrata, c.ricorrente entrata_ricorrente,
                null pdc_economico_patr ,i.codtitgiu, c.perim_sanit perimetro_sanitario_entrata
         from accertamenti i, accertamenti_classif c, cap_entrata cap
         where i.anno_esercizio=p_anno_esercizio and
               i.annoacc=decode(h_anno_plur,0,i.annoacc,i.anno_esercizio) and -- 21.03.2016 Sofia
               i.staoper in ('P','D') and
               cap.anno_esercizio=p_anno_esercizioIniziale and -- 21.03.2016 Sofia - aggiunto join su cap_entrata altrimenti tira su cap del nuovo bilancio
               cap.nro_capitolo=i.nro_capitolo and
               cap.nro_articolo=0 and 
               c.annoacc (+) =i.annoacc and
               c.nacc (+) =i.nacc
               and 0!=(select count(*)
                       from d118_accertamenti_rsr r
                       where i.anno_esercizio = r.anno_esercizio and
                             i.annoacc = r.annoacc and
                             i.nacc = r.nacc and
                             r.anno_esercizio_orig = '2017'
                       )
/* 21.03.2016 Sofia - aggiunto outer join altrimenti esclude movimenti non classificati
               i.annoacc=c.annoacc and
               i.nacc=c.nacc*/
	-- DAVIDE - 26.02.016 - Fine
         order by 1,2,3
       )
       loop
               -- inizializza variabili
               h_classe_soggetto:=null;
               h_indet:=0;
               h_soggetto_determinato:='S';
               h_sogg_migrato:=0;
               h_stato_impegno := migrImpegno.stato_accertamento;
               h_anno_provvedimento:=null;
               h_numero_provvedimento:=null;
               h_tipo_provvedimento:=null;
               h_direzione_provvedimento:=null;
               h_stato_provvedimento:=null;
               h_oggetto_provvedimento:=null;
               h_note_provvedimento:=null;
               h_per_sanitario:=null;
               h_classificatore_1:=null;
               h_classificatore_2:=null;
               h_classificatore_3:=null;
               h_nota:=null;
               h_automatico:='N';
               codRes:=0;
               msgMotivoScarto:=null;
               msgRes:=null;
               h_num:=0;
               h_pdc_finanziario:=null;
               segnalare := false;
               h_impegno:='Accertamento '||migrImpegno.anno_accertamento||'/'||migrImpegno.numero_accertamento||'.';

               h_annoimp_riacc:=null; -- DAVIDE - 26.10.2016 - Popolamento campi riaccertato
               h_nimp_riacc:=null;    -- DAVIDE - 26.10.2016 

               -- verifica capitolo migrato
	-- DAVIDE - 26.02.016 - se pdc_finanziario non trovato sulla tavola accertamenti_classif, leggilo dal CAPITOLO QUINTO
	           if migrImpegno.pdc_finanziario is null then
                   begin
                       msgRes:='Lettura capitolo migrato.';
                       select PDC_FIN_QUINTO  into h_pdc_finanziario
                        from  migr_capitolo_entrata m
                        where m.anno_esercizio=p_anno_esercizioIniziale and  --p_anno_esercizio and
                              m.numero_capitolo=migrImpegno.numero_capitolo and
                              tipo_capitolo='CAP-EG'
                       -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                          and m.ente_proprietario_id=p_ente_proprietario_id;
                   exception
                       when no_data_found then
                           codRes:=-1;
                           msgRes:='Capitolo non migrato.';
                   end;
			   else
			       h_pdc_finanziario := migrImpegno.pdc_finanziario;
			   end if;
	-- DAVIDE - 26.02.016 - Fine
	
               -- DAVIDE - 26.10.2016 - Popolamento campi riaccertato
               if codRes=0 then
                   begin
                       msgRes:='Lettura accertamento origine riaccertamento.';
                       select r.annoacc_orig, r.nacc_orig into h_annoimp_riacc,h_nimp_riacc
                         from d118_accertamenti_rsr r
                        where r.anno_esercizio = p_anno_esercizio 
                        and   r.annoacc = migrImpegno.anno_accertamento
                        and   r.nacc =  migrImpegno.numero_accertamento
                        and   r.anno_esercizio_orig = p_anno_esercizioIniziale;
                   exception 
                       when others then
					       h_annoimp_riacc := null;
						   h_nimp_riacc    := null;
                   end;           
               end if;
               -- DAVIDE - 26.10.2016 - Fine

                -- soggetto_determinato
               if codRes=0 and migrImpegno.codice_soggetto!=0 then
                 msgRes:='Lettura soggetto determinato S-N.';
                 begin
                  select nvl(count(*),0) into h_indet
                  from benef_tipi b , tab_tipi_forn t
                  where b.codben=migrImpegno.codice_soggetto and
                        t.tipoforn=b.tipoforn and
                        t.fl_tipo_dati!=0;

                  if h_indet!=0 then
                      h_soggetto_determinato:='N';
                      h_classe_soggetto:=CLASSE_MIGRAZIONE;
                  end if;

                  exception
                         when no_data_found then
                            null;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                 end;
               else
                  msgRes:='Lettura soggetto determinato S-N.';
                  h_soggetto_determinato:='N';
                  h_classe_soggetto:=CLASSE_MIGRAZIONE;
               end if;


               -- codice
               if h_soggetto_determinato='S' and codRes=0 then

                 msgRes:='Verifica soggetto migrato.';
                 begin
                  select nvl(count(*),0) into h_sogg_migrato
                  from migr_soggetto
                  where codice_soggetto=migrImpegno.codice_soggetto and
                        ente_proprietario_id=p_ente_proprietario_id;

                  if h_sogg_migrato=0 then
                    msgRes:='Soggetto determinato non migrato.';
--                    msgMotivoScarto:=msgRes;
                  end if;

                  exception
                         when no_data_found then
                            h_sogg_migrato:=0;
                            msgRes:='Soggetto determinato non migrato.';
--                            msgMotivoScarto:=msgRes;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                end;

                if codRes=0 and h_sogg_migrato=0 then
                   begin
                      codRes:=-1;
                      select nvl(count(*),0) into h_num
                      from fornitori
                      where codben=migrImpegno.codice_soggetto and
                            blocco_pag='N';

                      if h_num=0 then
--                        codRes:=-1;
                        msgRes:=msgRes||'Soggetto non valido.';
--                        msgMotivoScarto:=msgRes;
                      end if;
                  exception
                         when no_data_found then
                            h_sogg_migrato:=0;
                            h_num:=0;
  --                          codRes:=-1;
                            msgRes:=msgRes||'Soggetto non valido.';
--                            msgMotivoScarto:=msgRes;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                   end;
                end if;
               end if;

               /*
               --  stato_impegno da calcolare
               if codRes=0 then
                msgRes:='Calcolo stato accertamento.';
                if migrImpegno.stato_accertamento ='P' then
                  h_stato_impegno:=STATO_P;
                else
                  if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                      h_stato_impegno:=STATO_D;
                  else
                      h_stato_impegno:=STATO_N;
                  end if;
                end if;
              end if;  */
              -- provvedimento
              if codRes=0 then
                 msgRes:='Lettura dati Provvedimento.';
                 if (migrImpegno.numero_provvedimento is null or migrImpegno.numero_provvedimento ='0') then
                   if migrImpegno.stato_accertamento!=STATO_P then
                      h_stato_provvedimento:=STATO_D;
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';

                      -- 29.07.2015 Da segnalare
                      segnalare := true;
                      msgMotivoScarto := 'Provvedimento non presente per accertamento in stato '||migrImpegno.stato_accertamento||'.';
                   end if;
                 else
                    h_anno_provvedimento:=migrImpegno.anno_provvedimento;
                    h_numero_provvedimento:=migrImpegno.numero_provvedimento;
                    h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
                    h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

                    leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,
                                        h_tipo_provvedimento,h_direzione_provvedimento,p_ente_proprietario_id,
                                        codRes,msgRes,h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);
                    if codRes=0 then
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                      -- if p_ente_proprietario_id= ENTE_REGP_GIUNTA  then
                       if migrImpegno.tipo_provvedimento = PROVV_DETERMINA_REGP then
                           h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                       else
                           if h_direzione_provvedimento is not null then
                               h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                           end if;

                       end if;
                       --end if;
                    end if;

                    if codRes=0 and h_stato_provvedimento is null then
                      h_stato_provvedimento:='D';
                    end if;
                    if codRes=-2 then
                      -- Provvedimento non trovato.
                      h_stato_provvedimento:='D';
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';
                      h_numero_provvedimento:=null;

                      segnalare := true;
                      msgMotivoScarto := msgRes;
                      codRes := 0; -- Il record continua ad essere elaborato normalmente.
                    end if;
                 end if;
              end if;
              --  stato_impegno da calcolare
              if codRes=0 then
                 msgRes:='Definizione stato accertamento.';
                 if h_stato_provvedimento = 'D' then
                   if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                        h_stato_impegno:=STATO_D;
                   else
                        h_stato_impegno:=STATO_N;
                   end if;
                 elsif h_stato_provvedimento = 'P' then
                   if migrImpegno.stato_accertamento = 'P' then
                      h_stato_impegno := 'P';
                   else
                     -- 29.7.2015, Dani. non viene scartato ma segnalato.
--                     codRes:=-1;
--                     msgRes:=msgRes||'Stato accertamento '||migrImpegno.stato_accertamento||' per provvedimento in stato P.';
                       segnalare := true;
                       msgMotivoScarto := 'Provvedimento in P per accertamento in stato'||migrImpegno.stato_accertamento;
                       if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                            h_stato_impegno:=STATO_D;
                       else
                            h_stato_impegno:=STATO_N;
                       end if;

                   end if;
                 end if;
              end if;
              --  Definizione flag parere_finanziario
              -- sempre impostato a true (vedi dichiaarazione variabile)

              -- perimetro_sanitario_entrata
              --if codRes=0 and p_ente_proprietario_id=ENTE_REGP_GIUNTA then
		-- DAVIDE - 26.02.016 - tolta lettura del perimetro sanitario entrata - ora lo prendiamo da accertamenti_classif
              /*if codRes=0 then
                msgRes:='Lettura perimetro sanitario entrata.';
                begin
                  select decode(i.fl_coge,'S',ENT_GEST_SANITA,ENT_GEST_REG) into h_per_sanitario
                  from accertamento_coge i
                  where i.anno_esercizio=migrImpegno.anno_esercizio and
                        i.annoacc=migrImpegno.anno_accertamento and
                        i.nacc=migrImpegno.numero_accertamento;
                   exception
                         when no_data_found then
                              h_per_sanitario:=ENT_GEST_REG;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                end;
              end if;*/
			  h_per_sanitario:=migrImpegno.perimetro_sanitario_entrata;
		-- DAVIDE - 26.02.016 - Fine

              -- codtitgiu
              if codRes=0 and migrImpegno.codtitgiu is not null then
                --if p_ente_proprietario_id=ENTE_REGP_GIUNTA then
                  -- classificatore_1 --> classificatore_11
                 msgRes:='Lettura dati classificatore_11.';
                 begin
                   select migrImpegno.codtitgiu||'||'||t.descri
                          into h_classificatore_1
                   from tabtitgiu  t
                   where t.codtitgiu=migrImpegno.codtitgiu;

                   exception
                         when no_data_found then
                            codRes:=-1;
                            msgRes:=msgRes||'Non presente.';
                            h_classificatore_1:=null;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                 end;
                /*elsif p_ente_proprietario_id=ENTE_COTO then
                      if  migrImpegno.codtitgiu=ACC_AUTOMATICO then
                          h_automatico:='S';
                      end if;
                end if;*/
              end if;

              --- note
              h_nota:=migrImpegno.nota;

              if codRes=0
                --and (h_soggetto_determinato ='N' or (h_soggetto_determinato='S' and  h_sogg_migrato<>0))
              then
               msgRes:='Inserimento in migr_accertamento.';
               insert into migr_accertamento
               ( accertamento_id ,tipo_movimento,anno_esercizio,anno_accertamento,numero_accertamento,numero_subaccertamento,
                 pluriennale,capo_riacc,numero_capitolo,numero_articolo,numero_ueb,data_emissione,data_scadenza,stato_operativo,
                 importo_iniziale,importo_attuale,descrizione,
                 anno_capitolo_orig,numero_capitolo_orig,numero_articolo_orig,numero_ueb_orig,
                 anno_provvedimento,numero_provvedimento,tipo_provvedimento,sac_provvedimento,oggetto_provvedimento,
                 note_provvedimento,stato_provvedimento,soggetto_determinato,codice_soggetto,classe_soggetto,
                 nota,automatico,anno_accertamento_plur,numero_accertamento_plur,anno_accertamento_riacc,numero_accertamento_riacc,
                 opera,pdc_finanziario,transazione_ue_entrata,siope_entrata,entrata_ricorrente,perimetro_sanitario_entrata,pdc_economico_patr,
                 CLASSIFICATORE_1,CLASSIFICATORE_2,CLASSIFICATORE_3,CLASSIFICATORE_4,CLASSIFICATORE_5,
                 ente_proprietario_id,parere_finanziario)  -- DAVIDE - 26.10.2016 - Popolamento campi riaccertato
                values
                (migr_accertamento_id_seq.nextval, TIPO_IMPEGNO_A,migrImpegno.anno_esercizio,migrImpegno.anno_accertamento,migrImpegno.numero_accertamento,
                 migrImpegno.numero_subaccertamento,migrImpegno.pluriennale,migrImpegno.capo_riacc,
                 migrImpegno.numero_capitolo,migrImpegno.numero_articolo,h_numero_ueb,migrImpegno.data_emissione,migrImpegno.data_scadenza,
                 h_stato_impegno,migrImpegno.importo_iniziale,migrImpegno.importo_attuale,migrImpegno.descrizione,
                 migrImpegno.anno_capitolo_orig,migrImpegno.numero_capitolo_orig,migrImpegno.numero_articolo_orig,h_numero_ueb_orig,
                 h_anno_provvedimento,to_number(h_numero_provvedimento),h_tipo_provvedimento,h_direzione_provvedimento,
                 h_oggetto_provvedimento,h_note_provvedimento,h_stato_provvedimento,h_soggetto_determinato,
                 migrImpegno.codice_soggetto,h_classe_soggetto,h_nota,h_automatico,
                 migrImpegno.anno_accertamento_plur,migrImpegno.numero_accertamento_plur,
                 --migrImpegno.anno_accertamento_riacc,migrImpegno.numero_accertamento_riacc,migrImpegno.opera, -- DAVIDE - 26.10.2016
                 h_annoimp_riacc,h_nimp_riacc,migrImpegno.opera,                                                -- DAVIDE - 26.10.2016
                 h_pdc_finanziario,migrImpegno.transazione_ue_entrata,migrImpegno.siope_entrata,migrImpegno.entrata_ricorrente,
                 h_per_sanitario,migrImpegno.pdc_economico_patr,
                 h_classificatore_1,h_classificatore_2,h_classificatore_3,h_classificatore_4,h_classificatore_5,
                 p_ente_proprietario_id,h_parere_finanziario);

                 cImpInseriti:=cImpInseriti+1;
               end if;

               if codRes!=0 or
                 --( h_soggetto_determinato='S' and  h_sogg_migrato=0) or
                 segnalare = true
                 then
                 if codRes!=0 then
                     msgMotivoScarto:=msgRes;
                 end if;

                 msgRes:='Inserimento in migr_accertamento_scarto.';
                 insert into migr_accertamento_scarto
                 (accertamento_scarto_id,anno_esercizio,anno_accertamento,numero_accertamento,numero_subaccertamento,
                  motivo_scarto,ente_proprietario_id)
                  values
                 (migr_accert_scarto_id_seq.nextval,migrImpegno.anno_esercizio,migrImpegno.anno_accertamento,migrImpegno.numero_accertamento,migrImpegno.numero_subaccertamento,
                  msgMotivoScarto,p_ente_proprietario_id);
                  cImpScartati:=cImpScartati+1;
               end if;


               if numImpegno>=200  then
                  commit;
                  numImpegno:=0;
               else numImpegno:=numImpegno+1;
               end if;
       end loop;

       msgResOut:=msgResOut||'Elaborazione OK.Accertamenti inseriti='||cImpInseriti||' scartati='||cImpScartati||'.';

       p_imp_scartati:=cImpScartati;
       p_imp_inseriti:=cImpInseriti;
       commit;

       return msgResOut;

exception
  when others then
    dbms_output.put_line('Accertamento '||h_impegno||' msgRes '||msgRes||' Errore '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100));
    msgResOut:=msgResOut||h_impegno||msgRes||'Errore ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
    p_imp_scartati:=cImpScartati;
    p_imp_inseriti:=cImpInseriti;
    p_cod_res:=-1;
    return msgResOut;
end fnc_migr_accertamento;

-- da adeguare solo copiato da accertamento
function fnc_migr_subaccertamento(p_ente_proprietario_id number,
                                  p_anno_esercizio varchar2,
                                  p_cod_res out number,
                                  p_imp_inseriti out number,
                                  p_imp_scartati out number)
return varchar2 is

       msgRes varchar2(1500):=null;
       codRes number:=0;

       h_sogg_migrato    number:=0;
       h_stato_impegno varchar2(1):=null;
       h_soggetto_determinato varchar2(1):=null;
       h_num number:=0;

       h_per_sanitario varchar2(1):=null;
       h_impegno varchar2(50):=null;


       h_anno_provvedimento   varchar2(4):=null;
       h_numero_provvedimento varchar2(10):=null;
       h_tipo_provvedimento   varchar2(20):=null;
       h_direzione_provvedimento varchar2(20):=null;

       h_stato_provvedimento   varchar2(5):=null;
       h_oggetto_provvedimento varchar2(500):=null;
       h_note_provvedimento    varchar2(500):=null;

       h_data_emissione varchar2(15):=null;

	-- DAVIDE - 26.02.016 - aggiunta degli altri campi da valorizzare dalla accertamenti_classif, ereditati dalla migr_accertamento
	   h_transazione_ue_entrata  varchar2(50):=null;
	   h_entrata_ricorrente      varchar2(50):=null;
	-- DAVIDE - 26.02.016 - Fine

       msgMotivoScarto varchar2(1500):=null;
       msgResOut varchar2(1500):=null;

       cImpInseriti number:=0;
       cImpScartati number:=0;
       numImpegno number:=0;
       h_pdc_finanziario MIGR_ACCERTAMENTO.pdc_finanziario%type := null;
       segnalare boolean := False; -- True: il record � inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record � inserito nella sola tabella migr_*

begin

       p_imp_scartati:=0;
       p_imp_inseriti:=0;
       p_cod_res:=0;

       msgResOut:='Migrazione SubAccertamenti.';
       msgRes:='Lettura SubAccertamenti.';


       for  migrImpegno in
       ( select i.anno_esercizio,i.annoacc anno_accertamento,i.nacc numero_accertamento,i.nsubacc numero_subaccertamento,
                null data_emissione, null data_scadenza,i.staoper stato_impegno,
                i.impoini importo_iniziale,i.impoatt importo_attuale,i.descri descrizione,
                decode(nvl(i.nprov,'X'),'X',null,i.annoprov) anno_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,to_number(i.nprov)) numero_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                i.codben codice_soggetto,
                null pdc_finanziario ,
                null transazione_ue_entrata, null siope_entrata,null entrata_ricorrente,null pdc_economico_patr
         from subacc i
         where i.anno_esercizio=p_anno_esercizio and
               i.staoper in ('P','D') and
               i.anno_esercizio||i.annoacc||i.nacc in
               (select a.anno_esercizio||a.anno_accertamento||a.numero_accertamento from migr_accertamento a where a.ente_proprietario_id=p_ente_proprietario_id and a.tipo_movimento = TIPO_IMPEGNO_A)
         order by 1,2,3,4
       )
       loop
               -- inizializza variabili
               h_sogg_migrato:=0;
               h_soggetto_determinato:='S';
               h_stato_impegno :=null;
               h_anno_provvedimento:=null;
               h_numero_provvedimento:=null;
               h_tipo_provvedimento:=null;
               h_direzione_provvedimento:=null;
               h_stato_provvedimento:=null;
               h_oggetto_provvedimento:=null;
               h_note_provvedimento:=null;
               h_per_sanitario:=null;
               codRes:=0;
               msgMotivoScarto:=null;
               msgRes:=null;
               h_num:=0;
               h_data_emissione:=null;
               h_pdc_finanziario := null;

	        -- DAVIDE - 26.02.016 - aggiunta degli altri campi da valorizzare dalla accertamenti_classif, ereditati dalla migr_accertamento
	           h_transazione_ue_entrata  :=null;
	           h_entrata_ricorrente      :=null;
	        -- DAVIDE - 26.02.016 - Fine

               segnalare := false;
               h_impegno:='SubAccertamento '||migrImpegno.anno_accertamento||migrImpegno.numero_accertamento||'/'||migrImpegno.numero_subaccertamento||'.';

               -- dataemis letto da Accertamento
                 msgRes:='Lettura data di emissione Accertamento padre.';
                 begin
                  select to_char(dataemis,'YYYY-MM-DD')
                         into h_data_emissione
                  from accertamenti
                  where anno_esercizio=p_anno_esercizio and
                        annoacc=migrImpegno.anno_accertamento and
                        nacc=migrImpegno.numero_accertamento;

                  exception
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                 end;

               -- soggetto_determinato
               if migrImpegno.codice_soggetto=0 then
                  msgRes:='Lettura soggetto indeterminato.';
                  h_soggetto_determinato:='N';
                  codRes:=-1;
               end if;

               -- codice
               if h_soggetto_determinato='S' and codRes=0 then

                 msgRes:='Verifica soggetto migrato.';
                 begin
                  select nvl(count(*),0) into h_sogg_migrato
                  from migr_soggetto
                  where codice_soggetto=migrImpegno.codice_soggetto and
                        ente_proprietario_id=p_ente_proprietario_id;

                  if h_sogg_migrato=0 then
                    msgRes:='Soggetto determinato non migrato.';
--                    msgMotivoScarto:=msgRes;
                  end if;

                  exception
                         when no_data_found then
                            h_sogg_migrato:=0;
                            msgRes:='Soggetto determinato non migrato.';
--                            msgMotivoScarto:=msgRes;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                end;

                if codRes=0 and h_sogg_migrato=0 then
                   begin
                      codRes:=-1;
                      select nvl(count(*),0) into h_num
                      from fornitori
                      where codben=migrImpegno.codice_soggetto and
                            blocco_pag='N';

                      if h_num=0 then
--                        codRes:=-1;
                        msgRes:=msgRes||'Soggetto non valido.';
--                        msgMotivoScarto:=msgRes;
                      end if;
                  exception
                         when no_data_found then
                            h_sogg_migrato:=0;
                            h_num:=0;
--                            codRes:=-1;
                            msgRes:=msgRes||'Soggetto non valido.';
--                            msgMotivoScarto:=msgRes;

                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                   end;
                end if;
               end if;
    --  pdc_finanziario ereditato da accertamento migrato
	-- DAVIDE - 26.02.016 - aggiunta degli altri campi da valorizzare dalla accertamenti_classif, ereditati dalla migr_accertamento
        if codRes=0 then
            begin
                  select pdc_finanziario, transazione_ue_entrata, entrata_ricorrente, perimetro_sanitario_entrata
				  into h_pdc_finanziario, h_transazione_ue_entrata, h_entrata_ricorrente, h_per_sanitario
                  from migr_accertamento
                  where tipo_movimento = TIPO_IMPEGNO_A
                  and anno_esercizio = migrImpegno.anno_esercizio
                  and anno_accertamento = migrImpegno.anno_accertamento
                  and numero_accertamento = migrImpegno.numero_accertamento
                  and ente_proprietario_id = p_ente_proprietario_id;
             exception
                when no_data_found then
                  codRes := -1;
                  msgRes          := msgRes || 'Accertamento padre non trovato in migr_accertamento.';
                  msgMotivoScarto := msgRes;
                when too_many_rows then
                  codRes := -1;
                  msgRes          := msgRes || 'Ricerca accertamento padre.Too many rows';
                  msgMotivoScarto := msgRes;
                when others then
                  codRes := -1;
                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
              end;
        end if;
	-- DAVIDE - 26.02.016 - Fine

               -- stato_impegno
               h_stato_impegno:=migrImpegno.stato_impegno;


              -- provvedimento
              if codRes=0 then
                 msgRes:='Lettura dati Provvedimento.';
                 if migrImpegno.numero_provvedimento is null or migrImpegno.numero_provvedimento ='0' then
                    if h_stato_impegno!=STATO_P then
                     h_anno_provvedimento:=p_anno_esercizio;
                     h_tipo_provvedimento:=PROVV_SPR||'||';

                     -- 29.07.2015 Segnalare
                     h_stato_provvedimento := 'D';
                     segnalare := true;
                     msgMotivoScarto := 'Provvedimento non presente per accertamento in stato '||h_stato_impegno||'.';

                    end if;
                 else
                    h_anno_provvedimento:=migrImpegno.anno_provvedimento;
                    h_numero_provvedimento:=migrImpegno.numero_provvedimento;
                    h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
                    h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

                    leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,
                                        h_tipo_provvedimento,h_direzione_provvedimento,p_ente_proprietario_id,
                                        codRes,msgRes,h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);
                    if codRes=0 then
                     --if p_ente_proprietario_id!= ENTE_COTO  then
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                     /*else
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||';
                     end if;*/

                     --if p_ente_proprietario_id= ENTE_REGP_GIUNTA  then
                       if migrImpegno.tipo_provvedimento = PROVV_DETERMINA_REGP then
                           h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                       else
                           if h_direzione_provvedimento is not null then
                               h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                           end if;

                       end if;
                      --end if;
                     end if;
                     if codRes=0 and h_stato_provvedimento is null then
                        h_stato_provvedimento:=h_stato_impegno;
                     end if;

                     if h_stato_provvedimento = STATO_P and h_stato_impegno = STATO_D then
                       segnalare := true;
                       msgMotivoScarto := 'Provvedimento in P per subaccertamento in stato D';
                     end if;
                    if codRes=-2 then
                      -- Provvedimento non trovato.
                      h_stato_provvedimento:='D';
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';
                      h_numero_provvedimento:=null;

                      segnalare := true;
                      msgMotivoScarto := msgRes;
                      codRes := 0; -- Il record continua ad essere elaborato normalmente.
                    end if;
                 end if;
              end if;

              --  perimetro_sanitario_spesa
              --if codRes=0 and p_ente_proprietario_id=ENTE_REGP_GIUNTA then
	    -- DAVIDE - 26.02.016 - perimetro_sanitario_spesa ereditato dalla migr_accertamento
              /*if codRes=0 then
                msgRes:='Lettura perimetro sanitario entrata.';
                begin
                  select decode(i.fl_coge,'S',ENT_GEST_SANITA,ENT_GEST_REG) into h_per_sanitario
                  from accertamento_coge i
                  where i.anno_esercizio=migrImpegno.anno_esercizio and
                        i.annoacc=migrImpegno.anno_accertamento and
                        i.nacc=migrImpegno.numero_accertamento;

                   exception
                         when no_data_found then
                              h_per_sanitario:=ENT_GEST_REG;
                         when others then
                            codRes:=-1;
                            msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                end;
              end if;*/


              if codRes=0
                --and  h_sogg_migrato <> 0
                --and (h_soggetto_determinato ='N' or (h_soggetto_determinato='S' and  h_sogg_migrato<>0))
              then
               msgRes:='Inserimento in migr_accertamento.';
               insert into migr_accertamento
               ( accertamento_id,tipo_movimento,anno_esercizio,anno_accertamento,numero_accertamento,numero_subaccertamento,
                 data_emissione,data_scadenza,stato_operativo,
                 importo_iniziale,importo_attuale,descrizione,
                 anno_provvedimento,numero_provvedimento,tipo_provvedimento,sac_provvedimento,
                 oggetto_provvedimento,note_provvedimento,stato_provvedimento,soggetto_determinato,
                 codice_soggetto,pdc_finanziario,transazione_ue_entrata,siope_entrata,entrata_ricorrente,perimetro_sanitario_entrata,
                 pdc_economico_patr, ente_proprietario_id )
                values
                (migr_accertamento_id_seq.nextval, TIPO_IMPEGNO_S,migrImpegno.anno_esercizio,migrImpegno.anno_accertamento,migrImpegno.numero_accertamento,
                 migrImpegno.numero_subaccertamento,h_data_emissione,migrImpegno.data_scadenza,
                 h_stato_impegno,migrImpegno.importo_iniziale,migrImpegno.importo_attuale,migrImpegno.descrizione,
                 h_anno_provvedimento,to_number(h_numero_provvedimento),h_tipo_provvedimento,h_direzione_provvedimento,
                 h_oggetto_provvedimento,h_note_provvedimento,h_stato_provvedimento,h_soggetto_determinato,
                 migrImpegno.codice_soggetto,h_pdc_finanziario,

	    -- DAVIDE - 26.02.016 - aggiunta degli altri campi da valorizzare dalla accertamenti_classif, ereditati dalla migr_accertamento
                 --migrImpegno.transazione_ue_entrata,migrImpegno.siope_entrata,migrImpegno.entrata_ricorrente,
                 --h_per_sanitario,migrImpegno.pdc_economico_patr,
                 h_transazione_ue_entrata,migrImpegno.siope_entrata,h_entrata_ricorrente,
                 h_per_sanitario,migrImpegno.pdc_economico_patr,
	    -- DAVIDE - 26.02.016 - Fine

                 p_ente_proprietario_id);

                 cImpInseriti:=cImpInseriti+1;
               end if;

               if codRes!=0 --or ( h_soggetto_determinato='S' and  h_sogg_migrato=0)
                 or segnalare = true then
                 if codRes!=0 then
                     msgMotivoScarto:=msgRes;
                 end if;

                 msgRes:='Inserimento in migr_accertamento_scarto.';
                 insert into migr_accertamento_scarto
                 (accertamento_scarto_id,anno_esercizio,anno_accertamento,numero_accertamento,numero_subaccertamento,
                  motivo_scarto,ente_proprietario_id)
                  values
                 (migr_accert_scarto_id_seq.nextval,migrImpegno.anno_esercizio,migrImpegno.anno_accertamento,migrImpegno.numero_accertamento,migrImpegno.numero_subaccertamento,
                  msgMotivoScarto,p_ente_proprietario_id);
                  cImpScartati:=cImpScartati+1;
               end if;


               if numImpegno>=200  then
                  commit;
                  numImpegno:=0;
               else numImpegno:=numImpegno+1;
               end if;
       end loop;

       msgResOut:=msgResOut||'Elaborazione OK.SubAccertamenti inseriti='||cImpInseriti||' scartati='||cImpScartati||'.';

       p_imp_scartati:=cImpScartati;
       p_imp_inseriti:=cImpInseriti;
       commit;

       return msgResOut;

exception
  when others then
    dbms_output.put_line('SubAccertamenti '||h_impegno||' msgRes '||msgRes||' Errore '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100));
    msgResOut:=msgResOut||h_impegno||msgRes||'Errore ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
    p_imp_scartati:=cImpScartati;
    p_imp_inseriti:=cImpInseriti;
    p_cod_res:=-1;
    return msgResOut;
end fnc_migr_subaccertamento;

   procedure migrazione_impacc (p_ente_proprietario_id number,
                                       p_anno_esercizio varchar2,
                                       p_cod_res out number,
                                       msgResOut out varchar2)
    is
        v_imp_inseriti number := 0;
        v_imp_scartati number:= 0;
        v_codRes number := null;
        v_msgRes varchar2(1500) := '';    -- usato come variabile in cui concatenare tutti i mess di output delle procedure chiamate
        p_msgRes varchar2(1500) := null; -- passato come parametro alle procedure locali
        v_anno_esercizio number(4);
        v2_anno_esercizio number(4);
    begin
        msgResOut := 'Oracle.Migrazione Impegni/Accertamenti.';
        v_codRes := 0;

        -- controllo sulla presenza dei parametri in input
        if (p_ente_proprietario_id is null or p_anno_esercizio is null) then
            v_codRes := -1;
            v_msgRes := 'Uno o pi� parametri in input non sono stati valorizzati correttamente';
        end if;

        -- pulizia delle tabelle migr_
        begin
            v_msgRes := 'Pulizia tabelle di migrazione.';

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc',v_msgRes||'Begin.',p_ente_proprietario_id);
            commit;

     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
            DELETE FROM MIGR_IMPEGNO_SCARTO
            where ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_ACCERTAMENTO_SCARTO
            where ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_IMPEGNO WHERE FL_MIGRATO = 'N'
            and ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_ACCERTAMENTO WHERE FL_MIGRATO = 'N'
            and ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM migr_classif_impacc
            where ente_proprietario_id=p_ente_proprietario_id;
			
     -- DAVIDE - 14.07.2016 - gestione tabella migrazione vincoli su Impegni / Accertamenti
			DELETE FROM MIGR_IMPEGNO_ACCERTAMENTO
            where ente_proprietario_id=p_ente_proprietario_id;

  -- DAVIDE - 09.03.016 - aggiunta gestione modifiche Impegni / Accertamenti
            DELETE FROM MIGR_IMPEGNO_MODIFICA WHERE FL_MIGRATO = 'N'
            and ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_ACCERTAMENTO_MOD WHERE FL_MIGRATO = 'N'
            and ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_IMPEGNO_MODSCARTO
            where ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_ACCERTAMENTO_MODSC
            where ente_proprietario_id=p_ente_proprietario_id;
  -- DAVIDE - 09.03.016 - Fine

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc',v_msgRes||'End.',p_ente_proprietario_id);
            commit;

        exception when others then
                rollback;
                v_codRes := -1;
                v_msgRes := v_msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        end;

        v_anno_esercizio := to_number(p_anno_esercizio);

        for v_anno in v_anno_esercizio..v_anno_esercizio+2  loop

            if v_codRes = 0 then
                -- 1) Impegni
--                p_msgRes:=fnc_migr_impegno(p_ente_proprietario_id,v_anno,v_codRes,v_imp_inseriti,v_imp_scartati);


            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_impegno, anno '||v_anno||'.Begin.',p_ente_proprietario_id);
            commit;


                p_msgRes:=fnc_migr_impegno(p_ente_proprietario_id,p_anno_esercizio,v_anno,v_codRes,v_imp_inseriti,v_imp_scartati);
                v_msgRes := v_msgRes || p_msgRes ;

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_impegno, anno '||v_anno||'.End.',p_ente_proprietario_id);
            commit;

            end if;
            /*if v_codRes = 0 then -- 23.03.2017 Sofia ROR REGP
                -- 1) SubImpegni

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_subimpegno, anno '||v_anno||'.Begin.',p_ente_proprietario_id);
            commit;

                p_msgRes:=fnc_migr_subimpegno(p_ente_proprietario_id,v_anno,v_codRes,v_imp_inseriti,v_imp_scartati);
                v_msgRes := v_msgRes || p_msgRes ;


            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_subimpegno, anno '||v_anno||'.End.',p_ente_proprietario_id);
            commit;

            end if;*/
            if v_codRes = 0 then

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_accertamento, anno '||v_anno||'.Begin.',p_ente_proprietario_id);
            commit;


                -- 1) Accertamenti
--                p_msgRes:=fnc_migr_accertamento(p_ente_proprietario_id, v_anno, v_codRes, v_imp_inseriti, v_imp_scartati);
                p_msgRes:=fnc_migr_accertamento(p_ente_proprietario_id,p_anno_esercizio, v_anno, v_codRes, v_imp_inseriti, v_imp_scartati);
                v_msgRes := v_msgRes || p_msgRes ;

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_accertamento, anno '||v_anno||'.End.',p_ente_proprietario_id);
            commit;

            end if;
            /*if v_codRes = 0 then -- 23.03.2017 Sofia ROR REGP
            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_subaccertamento, anno '||v_anno||'.Begin.',p_ente_proprietario_id);
            commit;

                -- 1) SubAccertamenti
                p_msgRes:=fnc_migr_subaccertamento(p_ente_proprietario_id, v_anno, v_codRes, v_imp_inseriti, v_imp_scartati);
                v_msgRes := v_msgRes || p_msgRes ;

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_subaccertamento, anno '||v_anno||'.End.',p_ente_proprietario_id);
            commit;

            end if;*/

  -- DAVIDE - 09.03.016 - aggiunta gestione modifiche Impegni / Accertamenti
          /*  if v_codRes = 0 then -- 23.03.2017 Sofia ROR REGP
                -- Modifiche Impegni / SubImpegni 

                insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_impegno_modifica, anno '||v_anno||'.Begin.',p_ente_proprietario_id);
            commit;


                p_msgRes:=fnc_migr_impegno_modifica(p_ente_proprietario_id,v_anno,v_codRes,v_imp_inseriti,v_imp_scartati);
                v_msgRes := v_msgRes || p_msgRes ;

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_impegno_modifica, anno '||v_anno||'.End.',p_ente_proprietario_id);
            commit;

            end if;

            if v_codRes = 0 then

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_accertamento_modifica, anno '||v_anno||'.Begin.',p_ente_proprietario_id);
            commit;


                -- Modifiche Accertamenti / SubAccertamenti
                p_msgRes:=fnc_migr_accertamento_modifica(p_ente_proprietario_id, v_anno, v_codRes, v_imp_inseriti, v_imp_scartati);
                v_msgRes := v_msgRes || p_msgRes ;

            insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
            values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','fnc_migr_accertamento_modifica, anno '||v_anno||'.End.',p_ente_proprietario_id);
            commit;

            end if;
  -- DAVIDE - 09.03.016 - Fine
*/
             if v_codRes <> 0 then
                exit;
             end if;

        end loop;


        insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','Inserimento classificatori.Begin.',p_ente_proprietario_id);
        commit;

         insert into migr_classif_impacc
                (classif_tipo_id,tipo,codice,descrizione,ente_proprietario_id)
                values
                (migr_classif_impacc_id_seq.nextval,'I','CLASSIFICATORE_11','Titolo Giuridico',p_ente_proprietario_id);

                insert into migr_classif_impacc
                (classif_tipo_id,tipo,codice,descrizione,ente_proprietario_id)
                values
                (migr_classif_impacc_id_seq.nextval,'I','CLASSIFICATORE_12','Tipo Tracciabilita',p_ente_proprietario_id);


                insert into migr_classif_impacc
                (classif_tipo_id,tipo,codice,descrizione,ente_proprietario_id)
                values
                (migr_classif_impacc_id_seq.nextval,'I','CLASSIFICATORE_13','Voce Tracciabilita',p_ente_proprietario_id);


                insert into migr_classif_impacc
                (classif_tipo_id,tipo,codice,descrizione,ente_proprietario_id)
                values
                (migr_classif_impacc_id_seq.nextval,'A','CLASSIFICATORE_16','Titolo Giuridico',p_ente_proprietario_id);


        insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'migrazione_impacc','Inserimento classificatori.End.',p_ente_proprietario_id);
        commit;

        p_cod_res := v_codRes;
        msgResOut := msgResOut|| v_msgRes;

        if p_cod_res = 0 then
            msgResOut := msgResOut||'Migrazione completata.';
        else
            msgResOut := msgResOut||p_cod_res;
        end if;
     exception when others then
        msgResOut := msgResOut || v_msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        p_cod_res := -1;
    end migrazione_impacc;

  procedure migrazione_liquidazione(pEnte number,
                                    pAnnoEsercizio       varchar2,
                                    pCodRes              out number,
                                    pLiqInseriti         out number,
                                    pLiqScartati         out number,
                                    pMsgRes              out varchar2)
  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cLiqseriti number := 0;
        cLiqScartati number := 0;
        numInsert number := 0; --serve per contare i record e committare al 200esimo

        h_rec varchar2(50) := null;
        h_anno_provvedimento    varchar2(4) := null;
        h_numero_provvedimento  varchar2(10) := null;
        h_nprov_calcolato  varchar2(10) := null;
        h_tipo_provvedimento    varchar2(20) := null;
        h_direzione_provvedimento varchar2(20):=null;
        h_stato_provvedimento   varchar2(5) := null;
        h_oggetto_provvedimento varchar2(500) := null;
        h_note_provvedimento    varchar2(500) := null;
        h_anno_esercizio_orig   varchar2(4)  := null;
        h_nliq_orig             number(10)   := null;
        h_data_ins_orig         varchar2(10) := null;
        h_nelenco number(3) := 0;

      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_liquidazione.Uno o pi� parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin

            msgRes := 'Pulizia tabelle di migrazione liquidazione.';

            DELETE FROM MIGR_LIQUIDAZIONE WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_LIQUIDAZIONE_SCARTO where ente_proprietario_id = pEnte;

        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
               for migrCursor in (
                        select
                               l.nliq
                               , l.anno_esercizio
                               , l.descri descrizione
                               , '01/01/'||pAnnoEsercizio as data_emissione
                               , l.nliq_prec
                               , imp.importo
                               , l.codben
                               , l.progben -- modalita di pagamento
                               , decode (l.staoper,'D',STATO_LIQUIDAZIONE_V,l.staoper) staoper
                               , l.annoprov
                               , l.nprov
                               , l.codprov -- indica se � un atto AL o meno
                               , l.direzione
                               , imp.nimp
                               , imp.annoimp
                               , imp.nsubimp
                               , mi.pdc_finanziario -- ereditato da impegno associato
                               , mi.cofog           -- ereditato da impegno associato
                           -- 20.11.2015 aggiunto campo siope_spesa
                               , l.cod_gest as siope_spesa
                        from liquidazioni l
                             , imp_liq imp
                             , migr_soggetto ms, migr_impegno mi, migr_modpag mdp
                             , W_LIQUID_PAGAM w
                        where l.anno_esercizio = pAnnoEsercizio and l.staoper in ('P','D')
                        and imp.anno_esercizio = l.anno_esercizio
                        and imp.nliq = l.nliq
                        and ms.codice_soggetto = l.codben -- join per soggetto migrato
                        and mdp.soggetto_id=ms.soggetto_id-- join per modalita di pagamento migarta (legata al soggetto)
                        and mdp.codice_modpag=l.progben
                        and mi.numero_impegno= imp.nimp   -- join per impegno migrato
                        and mi.numero_subimpegno=imp.nsubimp
                        and mi.anno_impegno=imp.annoimp
                        and mi.anno_esercizio=imp.Anno_Esercizio
                        -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                        and ms.ente_proprietario_id=mi.ente_proprietario_id
                        and mi.ente_proprietario_id=mdp.ente_proprietario_id
                        and mi.ente_proprietario_id=pEnte
                        -- filtri su liquidazioni non pagate interamente
                        and w.anno_esercizio=l.anno_esercizio
                        and w.nliq=l.nliq
                        and w.importo>w.imporid )
                 loop
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            msgRes := null;
                            h_anno_provvedimento      := null;
                            h_nelenco := 0;
                            h_numero_provvedimento    := null;
                            h_nprov_calcolato         := null;
                            h_tipo_provvedimento      := null;
                            h_direzione_provvedimento := null;
                            h_stato_provvedimento     := null;
                            h_oggetto_provvedimento   := null;
                            h_note_provvedimento      := null;
                            h_anno_esercizio_orig := null;
                            h_nliq_orig := null;
                            h_data_ins_orig := null;

                            h_rec := 'Liquidazione ' || migrCursor.nliq || '/'||migrCursor.anno_esercizio||'.';

                            -- lettura dati provvedimento
                              msgRes := 'Lettura dati Provvedimento.';

                            if migrCursor.nprov is null or migrCursor.nprov = '0' then
                                h_anno_provvedimento:=pAnnoEsercizio;
                                h_tipo_provvedimento:=PROVV_SPR||'||';
                                h_stato_provvedimento:=STATO_D;
                            else
                                h_anno_provvedimento   := migrCursor.annoprov;
                                h_numero_provvedimento := migrCursor.nprov;
                                h_tipo_provvedimento := migrCursor.codprov;
                                h_direzione_provvedimento := migrCursor.direzione;
                                leggi_provvedimento_liq(h_anno_provvedimento,h_numero_provvedimento,h_tipo_provvedimento,h_direzione_provvedimento,
                                                  pEnte,codRes,msgRes,
                                                  h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento
                                                  ,h_nprov_calcolato);

                                if codRes=0 then
                                   --12.05.2015 daniela
                                   if h_tipo_provvedimento = PROVV_ATTO_LIQUIDAZIONE then
                                     h_tipo_provvedimento := PROVV_ATTO_LIQUIDAZIONE_SIAC;

/*                                     -- 18.09.2015
                                     Select nelenco into h_nelenco from atti_liquid al where
                                            al.annoprov=migrCursor.annoprov
                                            and al.nprov=migrCursor.nprov
                                            and al.direzione=migrCursor.direzione;
                                     if h_nelenco >0 then
                                        h_nprov_calcolato:=100000+h_nelenco;
                                     else
                                        h_nprov_calcolato:=h_numero_provvedimento;
                                     end if;*/
                                   end if;
                                   h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                                   if migrCursor.codprov = PROVV_DETERMINA_REGP or migrCursor.Codprov = PROVV_ATTO_LIQUIDAZIONE then
                                      if h_direzione_provvedimento is not null then
                                         h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                                      end if;
                                   else
                                      if h_direzione_provvedimento is not null then
                                         h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                                      end if;
                                   end if;
                                end if;
                                if codRes=0 and h_stato_provvedimento is null then
                                   h_stato_provvedimento:=STATO_D;
                                end if;
                          end if;

                          -- identificazione della liquidazione di partenza, salveremo anno esercizio,numero,data emissione.
                          -- prima scrematura tra le liquidazioni legate a liq precedenti e no
                          h_nliq_orig := migrCursor.nliq_prec;
                          h_anno_esercizio_orig := migrCursor.anno_esercizio;
                          h_data_ins_orig := migrCursor.data_emissione;
                          if h_nliq_orig is null or h_nliq_orig = 0 then
                            h_nliq_orig := migrCursor.nliq;
                          end if;

                          if codRes = 0 then
                              msgRes := 'Inserimento in migr_liquidazione.';
                              insert into migr_liquidazione
                              (liquidazione_id
                              ,numero_liquidazione
                              ,anno_esercizio
                              ,descrizione
                              ,data_emissione
                              ,importo
                              ,codice_soggetto
                              ,codice_progben -- regione l'ha definito a livello di liquidazione
                              ,stato_operativo
                              ,anno_provvedimento
                              ,numero_provvedimento_calcolato
                              ,numero_provvedimento
                              ,tipo_provvedimento
                              ,sac_provvedimento
                              ,oggetto_provvedimento
                              ,note_provvedimento
                              ,stato_provvedimento
                              ,numero_impegno
                              ,numero_subimpegno
                              ,anno_impegno
                              ,numero_mutuo
                              ,pdc_finanziario
                              ,cofog
                              ,ente_proprietario_id
                              ,numero_liquidazione_orig
                              ,anno_esercizio_orig
                              ,data_emissione_orig
                          -- 20.11.2015 aggiunto campo siope_spesa
                              ,siope_spesa)
                              values
                                (migr_liquidazione_id_seq.nextval,
                                 migrCursor.nliq,
                                 migrCursor.anno_esercizio,
                                 migrCursor.descrizione,
                                 migrCursor.data_emissione,
                                 migrCursor.importo,
                                 migrCursor.codben,
                                 migrCursor.progben,
                                 migrCursor.staoper,
                                 h_anno_provvedimento,
                                 h_nprov_calcolato,
                                 h_numero_provvedimento,
                                 h_tipo_provvedimento,
                                 h_direzione_provvedimento,
                                 h_oggetto_provvedimento,
                                 h_note_provvedimento,
                                 h_stato_provvedimento,
                                 migrCursor.nimp,
                                 migrCursor.nsubimp,
                                 migrCursor.annoimp,
                                 NULL, -- nro mutuo non valorizzato per regione
                                 migrCursor.pdc_finanziario,
                                 migrCursor.cofog,
                                 pEnte,
                                 h_nliq_orig,
                                 h_anno_esercizio_orig,
                                 h_data_ins_orig
                             -- 20.11.2015 aggiunto campo siope_spesa
                                 ,migrCursor.siope_spesa);
                              cLiqseriti := cLiqseriti + 1;
                            end if;

                            if codRes != 0 then
                              insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
                              values
                                (migr_liquid_scarto_id_seq.nextval,
                                 migrCursor.nliq,
                                 migrCursor.anno_esercizio,
                                 msgMotivoScarto,
                                 pEnte);
                              cLiqScartati := cLiqScartati + 1;
                            end if;

                            if numInsert >= 200 then
                              commit;
                              numInsert := 0;
                            else
                              numInsert := numInsert + 1;
                            end if;
                      end loop;
    -- aggiorno dati liquidazione.
    msgRes := 'Update dati liquidazione di partenza.';
    update migr_liquidazione m set
    (numero_liquidazione_orig,anno_esercizio_orig,data_emissione_orig)=
    ( select l1.nliq,l1.anno_esercizio,'01/01/'||l1.anno_esercizio
     from liquidazioni l1
     where l1.nliq_prec=0
     start with anno_esercizio=m.anno_esercizio and nliq= m.numero_liquidazione
     connect by nliq = prior nliq_prec and anno_esercizio = prior anno_esercizio-1)
    where m.numero_liquidazione!=m.numero_liquidazione_orig
  -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=pEnte;

    -- gestione degli scarti
    -- 1) scarti per soggetto non migrato.
    msgRes := 'Inserimento scarti per soggetto non migrato.';
     insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
      select migr_liquid_scarto_id_seq.nextval, l.nliq, l.anno_esercizio, 'Soggetto non migrato',pEnte
      from liquidazioni l
      where l.anno_esercizio = pAnnoEsercizio and l.staoper in ('D','P')
      and not exists (select 1 from migr_soggetto ms where ms.codice_soggetto=l.codben
                    -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                      and ms.ente_proprietario_id=pEnte
    );

    --2) mdp non migrata
    msgRes := 'Inserimento scarti per mdp non migrata.';
      insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
      select migr_liquid_scarto_id_seq.nextval, l.nliq, l.anno_esercizio, 'Mdp non migrata',pEnte
      from liquidazioni l
      where l.anno_esercizio = pAnnoEsercizio and l.staoper in ('D','P')
      and not exists (select 1 from migr_soggetto ms, migr_modpag mdp
                      where ms.codice_soggetto=l.codben
                      and mdp.soggetto_id = ms.soggetto_id
                      and mdp.codice_modpag=l.progben
                      -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
            and ms.ente_proprietario_id=mdp.ente_proprietario_id
            and ms.ente_proprietario_id=pEnte)
       -- e che non sia gi� stato inserito come scarto per altro motivo
       and not exists (select 1 from migr_liquidazione_scarto s where s.numero_liquidazione=l.nliq and s.anno_esercizio=l.anno_esercizio
                     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                       and s.ente_proprietario_id=pEnte);

    -- 3) scarti per movimento non migrato.
    msgRes := 'Inserimento scarti per movimento non migrato.';
      insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
      select migr_liquid_scarto_id_seq.nextval, l.nliq, l.anno_esercizio, 'Impegno non migrato',pEnte
      from liquidazioni l, imp_liq imp
      where l.anno_esercizio = pAnnoEsercizio and l.staoper in ('D','P')
      and imp.anno_esercizio = l.anno_esercizio
      and imp.nliq = l.nliq
      and not exists (select 1 from migr_impegno mi where
              mi.numero_impegno= imp.nimp
              and mi.numero_subimpegno=imp.nsubimp
              and mi.anno_impegno=imp.annoimp
              and mi.anno_esercizio=imp.anno_esercizio
              -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
        and mi.ente_proprietario_id=pEnte
             )
       -- e che non sia gi� stato inserito come scarto per altro motivo
       and not exists (select 1 from migr_liquidazione_scarto s where s.numero_liquidazione=l.nliq and s.anno_esercizio=l.anno_esercizio);
      
      -- 20.12.2016 Sofia&Davide ripreso da CmTo
      -- 4) segnalazioni per liq collegata a diverse quote fat
      msgRes := 'Inserimento segnalazione per collegamento diverse quote fat.'; 
      insert into migr_liquidazione_scarto
      (liquidazione_scarto_id,
       numero_liquidazione,
       anno_esercizio,
       motivo_scarto,
       ente_proprietario_id)
      ( select migr_liquid_scarto_id_seq.nextval, 
             migr.numero_liquidazione, migr.anno_esercizio,'Movimento segnalato per legame a diverse quote documento',pEnte
        from migr_liquidazione migr
        where  migr.ente_proprietario_id=pEnte
        and    migr.anno_esercizio=pAnnoEsercizio
        and    migr.numero_liquidazione in 
            ( select distinct migr.numero_liquidazione
              from migr_liquidazione migr , fatquo q
              where migr.ente_proprietario_id=pEnte
              and   migr.anno_esercizio=pAnnoEsercizio
              and   q.nliq=migr.numero_liquidazione
              and   q.anno_esercizio=pAnnoEsercizio
              and   q.eu='U'
              and   q.pagato='N'
              and   1  <    ( select count(*) from fatquo q
                              where  q.nliq=migr.numero_liquidazione
                               and    q.anno_esercizio=pAnnoEsercizio
                               and    q.eu='U')
             )                  
      );
          
    -- contiamo gli scarti ...
    select count (*) into cLiqScartati from migr_liquidazione_scarto where ente_proprietario_id = pEnte;

    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Liquidazioni inserite=' ||
                 cLiqseriti || ' scartate=' || cLiqScartati || '.';

    pLiqScartati := cLiqScartati;
    pLiqInseriti := cLiqseriti;
    commit;

  exception
    when others then
      rollback;
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pLiqScartati := cLiqScartati;
      pLiqInseriti := cLiqseriti;
      pCodRes      := -1;

  END migrazione_liquidazione;
  /* non usata, puo essere cancellata
  procedure get_liquidazioneOriginale (p_annoEsercizio in varchar2,p_nliq in number,o_annoEsercizio out varchar2,o_nliq out number,o_dataIns out varchar2)
  IS
        num_annoEsercizio integer := 0;
        v_nLiq number := 0;
        v_nLiqPrec number := 0;
  BEGIN

        num_annoEsercizio := to_number(p_annoEsercizio);
        v_nLiq := p_nliq;

        select nliq_prec into v_nLiqPrec
        from liquidazioni where nliq = v_nLiq and anno_esercizio = p_annoEsercizio;

        WHILE v_nLiqPrec != 0
          loop
            v_nLiq := v_nLiqPrec;
            num_annoEsercizio := num_annoEsercizio-1;
            select nliq_prec into v_nLiqPrec
            from liquidazioni where nliq = v_nLiq and anno_esercizio = num_annoEsercizio;
          end loop;

        o_annoEsercizio:= to_char(num_annoEsercizio);
        o_nliq := v_nLiq;
        o_dataIns := '01/01/'||o_annoEsercizio;

  END;
  */

    procedure migrazione_provvedimento(pEnte number,
                                    pAnnoEsercizio       varchar2,
                                    pCodRes              out number,
                                    pProvInseriti         out number,
                                    pProvScartati         out number,
                                    pMsgRes              out varchar2)
    is
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cProvInseriti number := 0;
        cProvScartati number := 0;
        --numInsert number := 0; --serve per contare i record e committare al 200esimo

        h_rec varchar2(50) := null;

      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_provvedimento.Uno o pi� parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin
            msgRes := 'Pulizia tabelle di migrazione provvedimento.';
            DELETE FROM MIGR_PROVVEDIMENTO WHERE ente_proprietario_id = pEnte;
            DELETE FROM MIGR_PROVVEDIMENTO_SCARTO where ente_proprietario_id = pEnte;
        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
        -- determine
        insert into migr_provvedimento
        ( provvedimento_id, anno_provvedimento, numero_provvedimento, tipo_provvedimento, sac_provvedimento, oggetto_provvedimento,
          stato_provvedimento, ente_proprietario_id)
        (Select migr_provvedimento_id_seq.nextval,
                d.anno_provvedimento, d.numero_provvedimento,d.tipo_provvedimento,d.sac_provvedimento,d.oggetto_provvedimento
                , d.stato_provvedimento, pEnte from
          (((select
                    TO_CHAR(d.anno) anno_provvedimento, d.num_determ numero_provvedimento
                    , dd.direzione||'||K' sac_provvedimento, 'AD||K' tipo_provvedimento, d.oggetto oggetto_provvedimento
                    , STATO_D stato_provvedimento
                  from determine d, direzioni dd
                  where d.anno = pAnnoEsercizio
                  and d.cod_dir=dd.cod_dir
                  minus
                  -- migrate con impegni
                  SELECT DISTINCT
                  elem.anno_provvedimento,elem.numero_provvedimento
                  ,elem.sac_provvedimento
                  ,elem.tipo_provvedimento,
                  ELEM.OGGETTO_PROVVEDIMENTO
                  ,elem.stato_provvedimento
                  from migr_impegno elem where elem.ente_proprietario_id=pEnte
                  and anno_provvedimento = pAnnoEsercizio
                  and elem.tipo_provvedimento='AD||K')
                  MINUS
                  -- migrate con accertamenti
                  SELECT DISTINCT
                  elem.anno_provvedimento,elem.numero_provvedimento
                  ,elem.sac_provvedimento
                  ,elem.tipo_provvedimento
                  ,ELEM.OGGETTO_PROVVEDIMENTO
                  ,elem.stato_provvedimento
                  from migr_accertamento elem where elem.ente_proprietario_id=pEnte
                  and anno_provvedimento = pAnnoEsercizio
                  and elem.tipo_provvedimento='AD||K')
                  MINUS
                  -- migrate con liquidazioni
                  SELECT DISTINCT
                    elem.anno_provvedimento,elem.numero_provvedimento
                    ,elem.sac_provvedimento
                    ,elem.tipo_provvedimento,
                    ELEM.OGGETTO_PROVVEDIMENTO
                    ,elem.stato_provvedimento
                    from migr_liquidazione elem where elem.ente_proprietario_id=pEnte
                    and anno_provvedimento = pAnnoEsercizio
                    and elem.tipo_provvedimento='AD||K')d
          );
        -- atti di liquidazione
        insert into migr_provvedimento
        ( provvedimento_id, anno_provvedimento, numero_provvedimento, tipo_provvedimento, sac_provvedimento, oggetto_provvedimento,
          note_provvedimento, stato_provvedimento, ente_proprietario_id)
        (Select migr_provvedimento_id_seq.nextval,
                d.anno_provvedimento, d.numero_provvedimento,d.tipo_provvedimento,d.sac_provvedimento,d.oggetto_provvedimento,
                d.note_provvedimento, d.stato_provvedimento, pEnte from
                (((select
                  al.annoprov anno_provvedimento
                  , to_number(al.nprov) numero_provvedimento
                  , al.direzione||'||' sac_provvedimento
                  , PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K' tipo_provvedimento
                  , al.causale_pagam oggetto_provvedimento
                  , al.note note_provvedimento
                  , STATO_D stato_provvedimento
                from atti_liquid al
                     where al.annoprov=pAnnoEsercizio
                MINUS
                -- migrati con impegni
                SELECT DISTINCT
                  elem.anno_provvedimento
                  ,elem.numero_provvedimento
                  ,elem.sac_provvedimento
                  ,elem.tipo_provvedimento
                  ,ELEM.OGGETTO_PROVVEDIMENTO
                  ,elem.note_provvedimento
                  ,elem.stato_provvedimento
                  from migr_impegno elem where elem.ente_proprietario_id=pEnte
                  and anno_provvedimento = pAnnoEsercizio
                  and elem.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K')
                MINUS
                -- migrati con accertamenti
                SELECT DISTINCT
                elem.anno_provvedimento
                ,elem.numero_provvedimento
                ,elem.sac_provvedimento
                ,elem.tipo_provvedimento
                ,ELEM.OGGETTO_PROVVEDIMENTO
                ,elem.note_provvedimento
                ,elem.stato_provvedimento
                from migr_accertamento elem where elem.ente_proprietario_id=pEnte
                and anno_provvedimento = pAnnoEsercizio
                and elem.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K')
                MINUS
                -- migrati con liquidazioni (15629)
                SELECT DISTINCT
                  elem.anno_provvedimento
                  ,elem.numero_provvedimento
                  ,elem.sac_provvedimento
                  ,elem.tipo_provvedimento
                  ,ELEM.OGGETTO_PROVVEDIMENTO
                  ,elem.note_provvedimento
                  ,elem.stato_provvedimento
                  from migr_liquidazione elem where elem.ente_proprietario_id=pEnte
                  and anno_provvedimento = pAnnoEsercizio
                  and elem.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K')d
          );

          -- Inserimento delle delibere. Lo stato del provvedimento deve essere un campo ragionato.

    -- contiamo gli scarti ...
    select count (*) into cProvScartati from migr_provvedimento_scarto;
    select count (*) into cProvInseriti from migr_provvedimento;

    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Provvedimenti inseriti=' ||
                 cProvInseriti || ' scartate=' || cProvScartati || '.';

    pProvScartati := cProvScartati;
    pProvInseriti := cProvInseriti;
    commit;

  exception
    when others then
      rollback;
      dbms_output.put_line(h_rec ||  ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pProvScartati := cProvScartati;
      pProvInseriti := cProvInseriti;
      pCodRes      := -1;
   end;

   procedure migrazione_doc_temp (pEu varchar2,
                                  pEnte number,
                                  pCodRes out number,
                                  pMsgRes out varchar2)
   is
      msgRes  varchar2(1500) := null;
   begin
      msgRes := 'Pulizia tabella temporanea '|| pEu||'.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_temp',msgRes||'begin.',pEnte);
commit;
      DELETE FROM migr_doc_temp WHERE ENTE_PROPRIETARIO_ID = pEnte and eu=pEu;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_temp',msgRes||'end.',pEnte);
commit;

      msgRes := 'Inserimento fatture uscita con almeno una quota non pagata.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_temp',msgRes||'begin.',pEnte);
commit;

      -- inserimento fatture uscita con quote non pagate
      insert into migr_doc_temp
      (eu,tipo,anno,numero,codice_soggetto,ente_proprietario_id)
      (select
                 f.eu
                 , f.tipofatt
                 , f.annofatt
                 , f.nfatt
                 , f.codben
                 , pEnte
      from fatture f
                where
                f.tipofatt in ('A', 'F')
                and f.eu = pEu
      and exists (select 1 from fatquo q where
                            f.eu=q.eu
                            and f.codben=q.codben
                            and f.annofatt=q.annofatt
                            and f.nfatt=q.nfatt
                            and f.tipofatt=q.tipofatt
                            and q.pagato='N'));

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_temp',msgRes||'end.',pEnte);
commit;

      msgRes := 'Inserimento fatture legate a note di credito con almeno una quota non pagata.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_temp',msgRes||'begin.',pEnte);
commit;
      -- inserimento fatture legate a note di credito non pagate completamente
      insert into migr_doc_temp
      (eu,tipo,anno,numero,codice_soggetto,ente_proprietario_id)
      (select
                distinct
                f.eu
                 , f.tipofatv
                 , f.annofatv
                 , f.nfatv
                 , f.codben
                 , pEnte
                from fatture f
                where
                f.tipofatt in ('A')
                and f.eu = pEu
                and f.nfatv is not null -- note di credito legate a fatture
                and exists (select 1 from fatquo q where
                            f.eu=q.eu
                            and f.codben=q.codben
                            and f.annofatt=q.annofatt
                            and f.nfatt=q.nfatt
                            and f.tipofatt=q.tipofatt
                            and q.pagato='N')
                and not exists (select 1 from migr_doc_temp tmp
                               where tmp.eu=f.eu and tmp.tipo=f.tipofatv and tmp.anno=f.annofatv and tmp.numero=f.nfatv and tmp.codice_soggetto=f.codben
                               and tmp.ente_proprietario_id=pEnte));


insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_temp',msgRes||'end.',pEnte);
--commit;

          pMsgRes := 'Popolata Tabella Temporanea.';
          pCodRes := 0;
          commit;

     exception when others then
       dbms_output.put_line(' msgRes ' ||msgRes || ' Errore ' || SQLCODE || '-' ||
                                 SUBSTR(SQLERRM, 1, 100));
       pMsgRes      := pMsgRes || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
       pCodRes      := -1;
       rollback;
   end migrazione_doc_temp;

procedure migrazione_doc_spesa (pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pRecInseriti out number,
                                   pRecScartati out number,
                                   pMsgRes out varchar2)
   is
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        numInsert number := 0;
        h_sogg_migrato number := 0;
        h_num number := 0;
        h_stato varchar2(3):=null;
        h_rec varchar2(750) := null;
        tipoScarto varchar2(3):=null;
        h_codPcc varchar2(10) := null;

     -- DAVIDE - Conversione dell'importo in Euro
    h_importo  NUMBER(15,2) := 0.0;
     -- DAVIDE - Fine

        ERROR_DOCUMENTO EXCEPTION;
   begin
        msgRes := 'Pulizia tabelle di migrazione.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_spesa',msgRes||'begin.',pEnte);
commit;
        DELETE FROM MIGR_DOC_SPESA WHERE ENTE_PROPRIETARIO_ID = pEnte and FL_MIGRATO = 'N';
        DELETE FROM MIGR_DOC_SPESA_SCARTO WHERE ENTE_PROPRIETARIO_ID = pEnte;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_spesa',msgRes||'end.',pEnte);
commit;


        msgRes := 'Inizio migrazione documenti di spesa.';

        select par_char into h_codPcc from tab_parametri where cod_par = 'CUIPA';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_spesa',msgRes||'begin.',pEnte);
commit;
        for migrCursor in
        (select
           f.tipofatt
           , decode ( f.tipofatt , 'F', 'FAT','A', decode(nvl(f.nfatv,'0'),'0','NTE','NCD')) as tipo
           , to_number(f.annofatt) annofatt
           , f.nfatt
           , f.codben
           , nvl(f.descri, 'DOCUMENTO N. '||f.nfatt||' DEL '|| to_char(f.dataemis,'DD/MM/YYYY')) descrizione
           , to_char(f.dataemis,'YYYY-MM-DD') data_emissione
           , to_char(f.datascad,'YYYY-MM-DD') data_scadenza
           , nvl(p.num_gg ,0)termine_pagamento
   -- DAVIDE - CONVERSIONE LIRA / EURO - aggiunto campo divisa_esercizio
           , f.divisa_esercizio
   -- DAVIDE - Fine
           , f.importo
           , to_char(fe.data_ricezione,'dd/MM/yyyy hh:mm:ss') data_ricezione
           , to_char(f.dataprot,'dd/MM/yyyy hh:mm:ss') data_repertorio
           --, to_char(trunc(fe.data_ricezione),'dd/MM/yyyy') data_ricezione
           --, to_char(trunc(f.dataprot),'dd/MM/yyyy') data_repertorio
           , f.nprot numero_repertorio
           , f.annoprot anno_repertorio
           , f.causale_sosp
           , to_char(f.datasosp_pag,'dd/MM/yyyy hh:mm:ss') data_sospensione
           , to_char(f.datariatt_pag,'dd/MM/yyyy hh:mm:ss') data_riattivazione
           --, to_char(trunc(f.datasosp_pag),'dd/MM/yyyy') data_sospensione
           --, to_char(trunc(f.datariatt_pag),'dd/MM/yyyy') data_riattivazione
           -- 14.10 dani, dati registro unico letti da tab fatture
--           , to_char(ruf.data_ruf,'YYYY-MM-DD') data_registro_fatt
--           , nvl(ruf.n_ruf, 0) numero_registro_fatt
           , to_char(f.data_ruf,'YYYY-MM-DD') data_registro_fatt
           , nvl(f.n_ruf, 0) numero_registro_fatt
           , f.anno_ruf anno_registro_fatt
           , nvl(f.ute_unix_ins,pLoginOperazione) utente_creazione
           , nvl(f.ute_unix_agg,pLoginOperazione) utente_modifica
           , f.annofatv -- rif. doc collegato
           , f.nfatv -- rif. doc collegato
           , f.tipofatv -- rif. doc collegato
           , fe2.codice_destinatario as codice_ufficio
           , decode (f.competenza, 'E', 'S', 'N') as collegato_cec
           from fatture f
           , migr_doc_temp tmp
           , termini_pagam p
           , sirfel_t_portale_fatture fe
           , sirfel_t_fattura_contabile fc
--           , fatture_numera_ruf ruf
           , sirfel_t_fattura fe2
          where
          tmp.ente_proprietario_id=pEnte
          and f.eu=tmp.eu and tmp.eu='U'
          and f.tipofatt=tmp.tipo
          and f.annofatt=tmp.anno
          and f.nfatt=tmp.numero
          and f.codben=tmp.codice_soggetto
          and f.termine_pagam=p.termine_pagam(+)
          and f.eu=fc.eu(+)
          and f.codben=fc.codben(+)
          and f.nfatt=fc.nfatt(+)
          and f.annofatt=fc.annofat(+)
          and f.tipofatt=fc.tipofatt(+)
          and fc.id_fattura=fe.id_fattura(+)
/*          and f.eu=ruf.eu(+)
          and f.codben=ruf.codben(+)
          and f.nfatt=ruf.nfatt(+)
          and f.annofatt=ruf.annofatt(+)
          and f.tipofatt=ruf.tipofatt(+)*/
          and fe2.id_fattura(+)=fc.id_fattura
          order by f.annofatt, f.tipofatt, f.codben, f.nfatt)

          loop
            -- inizializza variabili
            codRes := 0;
            msgMotivoScarto  := null;
            msgRes := null;
            h_sogg_migrato := 0;
            h_num := 0;
            h_stato := null;
            tipoScarto:=null;

            h_rec := 'Documento  '||migrCursor.annofatt || '/'||migrCursor.nfatt||' tipo '||migrCursor.tipofatt||
                     ' Soggetto '||migrCursor.codben||'.';

            -- se importo negativo e tipo = F scarto il documento
            msgRes := 'Verifica importo fattura.';
            if migrCursor.Tipofatt='F' and migrCursor.importo <0 then
                msgRes          := msgRes|| 'Importo negativo per tipo fattura.';
                msgMotivoScarto := msgRes;
                codRes := -2; -- codice -2 il record viene inserito come scarto, l'elaborazione continua.
                tipoScarto:='FN';-- fattura negativa
            end if;

            if codres = 0 then
              msgRes := 'Verifica soggetto migrato.';
              begin
                select nvl(count(*), 0)
                  into h_sogg_migrato
                  from migr_soggetto
                 where codice_soggetto = migrCursor.codben
                 and   ente_proprietario_id=pEnte;

                if h_sogg_migrato = 0 then
                  codRes := -2;
                  msgRes := msgRes||'Soggetto non migrato.';
                  msgMotivoScarto := msgRes;
                  tipoScarto:='SNM';
                end if;
              exception
                when no_data_found then
                  codRes := -2;
                  h_sogg_migrato  := 0;
                  msgRes          := msgRes|| 'Soggetto non migrato.';
                  msgMotivoScarto := msgRes;
                  tipoScarto:='SNM';-- SOGGETTO NON MIGRATO
                when others then
                  codRes := -1; --codice -1 errore non previsto, l'elaborazione termina.
                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                  raise ERROR_DOCUMENTO;
              end;
              msgRes := 'Verifica soggetto valido.';
              -- verifica della validit� del soggetto. Ulteriore dettaglio per lo scarto.
              if h_sogg_migrato = 0 and codRes!=-1 then
                begin
                  select nvl(count(*),0) into h_num
                  from fornitori
                  where codben=migrCursor.codben and blocco_pag='N';

                  if h_num = 0 then
                    codRes := -2;
                    msgRes  := msgRes || 'Soggetto non valido.';
                    msgMotivoScarto := msgRes;
                    tipoScarto:='SNV'; -- SOGGETTO NON VALIDO
                  end if;
                exception
                  when no_data_found then
                    codRes := -2;
                    h_sogg_migrato  := 0;
                    h_num           := 0;
                    msgRes          := msgRes || 'Soggetto non valido.';
                    msgMotivoScarto := msgRes;
                    tipoScarto:='SNV'; -- SOGGETTO NON VALIDO
                  when others then
                    codRes := -1;
                    msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                    raise ERROR_DOCUMENTO;
                end;
              end if;
            end if;

            if codRes = 0 then
              msgRes := 'Definizione stato documento.';
              get_stato_documento ('U', migrCursor.codben, migrCursor.annofatt, migrCursor.nfatt, migrCursor.tipofatt,pEnte,pAnnoEsercizio,
                                   h_stato, codRes, msgRes);

              if codRes = -1 then raise ERROR_DOCUMENTO; end if;
              if codRes = -2 then
                    msgMotivoScarto := msgRes;
                    tipoScarto:='FSS'; -- FATTURA SENZA STATO
              end if;
            end if;

            if codRes = 0 then

               -- DAVIDE - Conversione dell'importo in Euro
         if migrCursor.divisa_esercizio = 'L' then
           h_Importo := migrCursor.importo / RAPPORTO_EURO_LIRA;
         else
           h_Importo := migrCursor.importo;
         end if;
              -- DAVIDE - Fine

        msgRes := 'Inserimento in migr_doc_spesa.';
              insert into migr_doc_spesa
              (docspesa_id,
               tipo,
               tipo_fonte,
               anno,
               numero,
               codice_soggetto,
               codice_soggetto_pag,
               stato,
               descrizione,
               date_emissione,
               data_scadenza,
               termine_pagamento,
               importo,
               arrotondamento,
               codice_pcc,
               codice_ufficio,
               data_ricezione,
               data_repertorio,
               numero_repertorio,
               anno_repertorio,
               causale_sospensione,
               data_sospensione,
               data_riattivazione,
               data_registro_fatt,
               numero_registro_fatt,
               anno_registro_fatt,
               utente_creazione,
               utente_modifica,
               ente_proprietario_id,
               annoRif,
               numeroRif,
               tipoRif,
               collegato_cec)
              values
              (migr_doc_spesa_id_seq.nextval,
               migrCursor.tipo,
               migrCursor.tipofatt,
               migrCursor.annofatt,
               migrCursor.nfatt,
               migrCursor.codben,
               0,-- codben_pagamento
               h_stato,
               migrCursor.descrizione,
               migrCursor.data_emissione,
               migrCursor.data_scadenza,
               migrCursor.termine_pagamento,

               -- DAVIDE - Conversione dell'importo in Euro
               --migrCursor.importo,
               h_Importo,
         -- DAVIDE - Fine

               0,-- arrotondamento
               h_codPcc,--valore parametro CUIPA
               migrCursor.codice_ufficio,
               migrCursor.Data_Ricezione,
               migrCursor.Data_Repertorio,
               migrCursor.numero_repertorio,
               migrCursor.anno_repertorio,
               migrCursor.causale_sosp,
               migrCursor.Data_Sospensione,
               migrCursor.Data_Riattivazione,
               migrCursor.data_registro_fatt,
               migrCursor.numero_registro_fatt,
               migrCursor.anno_registro_fatt,
               migrCursor.utente_creazione,
               migrCursor.utente_modifica,
               pEnte,
               migrCursor.Annofatv,
               migrCursor.Nfatv,
               migrCursor.Tipofatv,
               migrCursor.collegato_cec);
              cDocInseriti := cDocInseriti + 1;
           else
              msgRes := 'Inserimento in migr_doc_spesa_scarto.';
              insert into migr_doc_spesa_scarto
              (doc_spesa_scarto_id,
               tipo,
               anno,
               numero,
               codice_soggetto,
               motivo_scarto,
               tipo_scarto,
               ente_proprietario_id)
              values
              (migr_doc_spesa_scarto_id_seq.nextval,
               migrCursor.tipofatt,
               migrCursor.annofatt,
               migrCursor.nfatt,
               migrCursor.Codben,
               msgMotivoScarto,
               tipoScarto,
               pEnte);

              cDocScartati := cDocScartati + 1;
            end if;

--            if codRes=-1 then
--               raise ERROR_DOCUMENTO;
--            end if;

            if numInsert >= N_BLOCCHI_DOC then
              commit;
              numInsert := 0;
            else
              numInsert := numInsert + 1;
            end if;

          end loop;

msgRes := 'Migrazione documenti di spesa.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_spesa',msgRes||'end.',pEnte);
commit;

          pMsgRes := pMsgRes || 'Documenti migrati '|| cDocInseriti || ', scartati '|| cDocScartati;
          pCodRes := 0;

    exception
          when ERROR_DOCUMENTO then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                 msgRes );
            pMsgRes      := pMsgRes || h_rec || msgRes ;
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
          when others then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                 msgRes || ' Errore ' || SQLCODE || '-' ||
                                 SUBSTR(SQLERRM, 1, 100));
            pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                              SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
   end migrazione_doc_spesa;

   procedure migrazione_docquo_spesa (pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pRecInseriti out number,
                                   pRecScartati out number,
                                   pMsgRes out varchar2)
   is
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(4000) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        cDocSegnalati number := 0;
        numInsert number := 0;
        h_rec varchar2(750) := null;
        tipoScarto varchar2(3):= null;
        h_note varchar2(500) := null;
        h_sede_secondaria varchar2(1) := null;

        h_nimac number := 0;
        h_nsubimac number := 0;
        h_annoimac varchar2(4) := NULL;
        h_nliq number := 0;
        h_progben number := 0;
        h_nordin number := 0;

        h_anno_provvedimento    varchar2(4) := null;
        h_numero_provvedimento  varchar2(10) := null;
        h_tipo_provvedimento    varchar2(20) := null;
        h_direzione_provvedimento varchar2(20):=null;
        h_stato_provvedimento   varchar2(5) := null;
        h_oggetto_provvedimento varchar2(500) := null;
        h_note_provvedimento    varchar2(500) := null;

        recSegnalato number := 0;
--        recMigrato number := 0;
--        recPresente number := 0; -- >0 -> il record cercato � �resente alla fonte per anno esercizio <> anno esercizio di migrazione
                                 -- =0 -> il record cercato non � presente alla fonte per anno esercizio <> anno esercizio di migrazione
        segnalare boolean := false; -- se True il rec viene inserito anche nella tabella di scarto

		-- DAVIDE - Conversione Importi quote
        h_Importo_quote number(15,2) :=0.0;
        h_Importo_quote_da_dedurre number(15,2) :=0.0;
		divisa_esercizio varchar2(1) := null;
		-- DAVIDE - Fine

        h_sede_id number:=null; -- DAVIDE - 14.07.2016 - Valorizzata con il campo migr_sede_secodiaria.sede_id se il soggetto legato al doc � una sede secondaria

        ERROR_DOCUMENTO EXCEPTION;
   begin
        msgRes := 'Pulizia tabelle di migrazione.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;
        DELETE FROM MIGR_DOCQUO_SPESA WHERE ENTE_PROPRIETARIO_ID = pEnte and FL_MIGRATO = 'N';
        DELETE FROM MIGR_DOCQUO_SPESA_SCARTO WHERE ENTE_PROPRIETARIO_ID = pEnte;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;
-- VERI scarti. La quota NON pagata � legata ad un impegno/subimpegno che dovrebbe essere stato migrato
-- dal momento che esiste alla fonte per anno esercizio oggetto della migrazione
        msgRes := 'Scarto quote non pagate per impegno non migrato.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;
        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (Select
             migr_docquo_spe_scarto_id_seq.nextval,q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
             ,'Impegno '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' a.e. '||pAnnoEsercizio||' non migrato.','IMP',pEnte
              from
              fatquo q
              , migr_doc_spesa f
              , impegni i
              where q.eu='U' and q.pagato='N'
              and f.tipo_fonte=q.tipofatt
              and f.anno=q.annofatt
              and f.numero=q.nfatt
              and f.codice_soggetto=q.codben
              and f.ente_proprietario_id=pEnte
              and q.nimac != 0
              and q.nsubimac = 0
              and i.nimp=q.nimac
              and i.annoimp=q.annoimac
              and i.anno_esercizio=pAnnoEsercizio
              and not exists (select 1 from migr_impegno imp where
                  imp.ente_proprietario_id=f.ente_proprietario_id
                  and imp.tipo_movimento='I'
                  and imp.numero_impegno=q.nimac
                  and imp.numero_subimpegno=q.nsubimac
                  and imp.anno_impegno=q.annoimac
                  and imp.anno_esercizio=pAnnoEsercizio));

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;
        msgRes := 'Scarto quote non pagate per subimpegno non migrato.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;
        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (Select
           migr_docquo_spe_scarto_id_seq.nextval,q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
           ,'Subimpegno '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' a.e. '||pAnnoEsercizio||' non migrato.','SIM',pEnte
            from
            fatquo q
            , migr_doc_spesa f
            , subimp i
            where q.eu='U' and q.pagato='N'
            and f.tipo_fonte=q.tipofatt
            and f.anno=q.annofatt
            and f.numero=q.nfatt
            and f.codice_soggetto=q.codben
            and f.ente_proprietario_id=pEnte
            and q.nimac != 0
            and q.nsubimac != 0
            and i.nimp=q.nimac
            and i.NSUBIMP=q.nsubimac
            and i.annoimp=q.annoimac
            and i.anno_esercizio=pAnnoEsercizio
            and not exists (select 1 from migr_impegno imp where
                imp.ente_proprietario_id=f.ente_proprietario_id
                and imp.tipo_movimento='S'
                and imp.numero_impegno=q.nimac
                and imp.numero_subimpegno=q.nsubimac
                and imp.anno_impegno=q.annoimac
                and imp.anno_esercizio=pAnnoEsercizio));

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;
-- VERI scarti. La quota NON pagata � legata ad una liquidazione che dovrebbe essere stata migrata
-- dal momento che esiste alla fonte per anno esercizio oggetto della migrazione.
        msgRes := 'Scarto quote non pagate per liquidazione non migrata.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;

        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
         (Select
           migr_docquo_spe_scarto_id_seq.nextval,q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
           ,'Liquidazione '||q.nliq||' anno_esercizio '||pAnnoEsercizio|| ' non migrata.','LIQ',pEnte
           from
            fatquo q
            , migr_doc_spesa f
            , liquidazioni l
            where q.eu='U' and q.pagato='N'
            and f.tipo_fonte=q.tipofatt
            and f.anno=q.annofatt
            and f.numero=q.nfatt
            and f.codice_soggetto=q.codben
            and f.ente_proprietario_id=pEnte
            and q.nliq != 0
            and q.nliq=l.nliq
            and l.anno_esercizio = pAnnoEsercizio
            and not exists (select 1 from migr_liquidazione liq where
                liq.ente_proprietario_id=f.ente_proprietario_id
                and liq.numero_liquidazione=q.nliq
                and liq.anno_esercizio=pAnnoEsercizio));

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;

       --18.12.2015
        -- Scarto quote fattura collegate ad impegni / liquidazioni non andata a residuo e se anno fattura <2014.
        msgRes := 'Scarto quote collegate a impegno non andato a residuo e annafatt<2014.';
        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (select migr_docquo_spe_scarto_id_seq.nextval
         , seg.tipofatt, seg.annofatt, seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto, seg.tipo_scarto,pEnte
        from
        (Select distinct -- il distinct � necessario perch� � possibile avere diversi impegni 'uguali' su diversi annni tutti <> pAnnoEsercizio
            q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
             ,'Impegno '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' non migrato, presente alla fonte per anno <> '||pAnnoEsercizio as motivo_scarto
             ,'IMP' tipo_scarto
              from
              fatquo q
              , migr_doc_spesa f
              , impegni i
              where q.eu='U' and q.pagato='N'
              and f.tipo_fonte=q.tipofatt
              and f.anno=q.annofatt
              and f.numero=q.nfatt
              and f.codice_soggetto=q.codben
              and f.ente_proprietario_id=pEnte
              and f.anno<2014
              and q.nimac != 0
              and q.nsubimac = 0
              and i.nimp=q.nimac
              and i.annoimp=q.annoimac
              and i.anno_esercizio<>pAnnoEsercizio
              and not exists (select 1 from migr_impegno imp where
                  imp.ente_proprietario_id=f.ente_proprietario_id
                  and imp.tipo_movimento='I'
                  and imp.numero_impegno=q.nimac
                  and imp.numero_subimpegno=q.nsubimac
                  and imp.anno_impegno=q.annoimac
                  and imp.anno_esercizio=pAnnoEsercizio)
              and not exists (select 1 from migr_docquo_spesa_scarto s
                where s.ente_proprietario_id = f.ente_proprietario_id
                and s.tipo=q.tipofatt
                and s.numero=q.nfatt
                and s.anno=q.annofatt
                and s.codice_soggetto=q.codben
                and s.frazione=q.frazione
                and s.tipo_scarto='IMP'))seg -- la quota segnalata non deve essere stata scartata per impegno 2015(anno esercizio di migrazione) non migrato.
            );

        msgRes := 'Scarto quote collegate a subimpegno non andato a residuo e annafatt<2014.';
        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (select migr_docquo_spe_scarto_id_seq.nextval
         , seg.tipofatt, seg.annofatt, seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto, seg.tipo_scarto,pEnte
        from
        (Select distinct -- il distinct � necessario perch� � possibile avere diversi subimpegni 'uguali' su diversi annni tutti <> pAnnoEsercizio
           q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
           ,'Subimpegno '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' non migrato, presente alla fonte per anno <> '||pAnnoEsercizio as motivo_scarto
           ,'SIM' tipo_scarto
            from
            fatquo q
            , migr_doc_spesa f
            , subimp i
            where q.eu='U' and q.pagato='N'
            and f.tipo_fonte=q.tipofatt
            and f.anno=q.annofatt
            and f.numero=q.nfatt
            and f.codice_soggetto=q.codben
            and f.ente_proprietario_id=pEnte
            and f.anno<2014
            and q.nimac != 0
            and q.nsubimac != 0
            and i.nimp=q.nimac
            and i.NSUBIMP=q.nsubimac
            and i.annoimp=q.annoimac
            and i.anno_esercizio<>pAnnoEsercizio
            and not exists (select 1 from migr_impegno imp where
                imp.ente_proprietario_id=f.ente_proprietario_id
                and imp.tipo_movimento='S'
                and imp.numero_impegno=q.nimac
                and imp.numero_subimpegno=q.nsubimac
                and imp.anno_impegno=q.annoimac
                and imp.anno_esercizio=pAnnoEsercizio)
            and not exists (select 1 from migr_docquo_spesa_scarto s
                where s.ente_proprietario_id = f.ente_proprietario_id
                and s.tipo=q.tipofatt
                and s.numero=q.nfatt
                and s.anno=q.annofatt
                and s.codice_soggetto=q.codben
                and s.frazione=q.frazione
                and s.tipo_scarto='SIM'))seg -- la quota segnalata non deve essere stata scartata per subimpegno 2015(anno esercizio di migrazione) non migrato.
      );

        msgRes := 'Scarto quote collegate a liquidazione non andata a residuo e annafatt<2014.';

        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (select migr_docquo_spe_scarto_id_seq.nextval
         , seg.tipofatt, seg.annofatt, seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto, seg.tipo_scarto,pEnte
        from
         (Select distinct -- il distinct � necessario perch� � possibile avere diverse liquidazioni 'uguali'(stesso nr) su diversi annni tutti <> pAnnoEsercizio
           q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
           ,'Liquidazione '||q.nliq||' non migrata, presente alla fonte per anno <> '||pAnnoEsercizio as motivo_scarto
           ,'LIQ' tipo_scarto
           from
            fatquo q
            , migr_doc_spesa f
            , liquidazioni l
            where q.eu='U' and q.pagato='N'
            and f.tipo_fonte=q.tipofatt
            and f.anno=q.annofatt
            and f.numero=q.nfatt
            and f.codice_soggetto=q.codben
            and f.ente_proprietario_id=pEnte
            and f.anno<2014
            and q.nliq != 0
            and q.nliq=l.nliq
            and l.anno_esercizio <> pAnnoEsercizio
            and not exists (select 1 from migr_liquidazione liq where
                liq.ente_proprietario_id=f.ente_proprietario_id
                and liq.numero_liquidazione=q.nliq
                and liq.anno_esercizio=pAnnoEsercizio)
            and not exists (select 1 from migr_docquo_spesa_scarto s
                where s.ente_proprietario_id = f.ente_proprietario_id
                and s.tipo=q.tipofatt
                and s.numero=q.nfatt
                and s.anno=q.annofatt
                and s.codice_soggetto=q.codben
                and s.frazione=q.frazione
                and s.tipo_scarto='LIQ'))seg-- la quota segnalata non deve essere stata scartata per liquidazione 2015(anno esercizio di migrazione) non migrato.
        );
       -- fine 18.12.2015

        --Scarto doc con quote VERAMENTE scartate
        msgRes := 'Scarto doc con quote scartate.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;

        Update migr_doc_spesa m
        set m.fl_scarto='S'
        where ente_proprietario_id = pEnte
        and m.fl_migrato = 'N'
        and exists (select 1 from migr_docquo_spesa_scarto s
                    where s.tipo=m.tipo_fonte
                    and s.anno=m.anno
                    and s.numero=m.numero
                    and s.codice_soggetto=m.codice_soggetto
                    and s.ente_proprietario_id=m.ente_proprietario_id);

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;

        -- SEGNALAZIONI PER Quote non pagate conannofat>=2014 su movimenti/liquidazioni non andate a residuo (quindi non migrate per anno = anno di migrazione)
        msgRes := 'Segnalazione quote non pagate per impegno non migrato, impegno presente alla fonte per anno <> anno di migrazione.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;

        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (select migr_docquo_spe_scarto_id_seq.nextval
         , seg.tipofatt, seg.annofatt, seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto, seg.tipo_scarto,pEnte
        from
        (Select distinct -- il distinct � necessario perch� � possibile avere diversi impegni 'uguali' su diversi annni tutti <> pAnnoEsercizio
            q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
             ,'Impegno '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' non migrato, presente alla fonte per anno <> '||pAnnoEsercizio as motivo_scarto
             ,'IM2' tipo_scarto
              from
              fatquo q
              , migr_doc_spesa f
              , impegni i
              where q.eu='U' and q.pagato='N'
              and f.tipo_fonte=q.tipofatt
              and f.anno=q.annofatt
              and f.numero=q.nfatt
              and f.codice_soggetto=q.codben
              and f.ente_proprietario_id=pEnte
              and f.anno >= 2014
              and q.nimac != 0
              and q.nsubimac = 0
              and i.nimp=q.nimac
              and i.annoimp=q.annoimac
              and i.anno_esercizio<>pAnnoEsercizio
              and not exists (select 1 from migr_impegno imp where
                  imp.ente_proprietario_id=f.ente_proprietario_id
                  and imp.tipo_movimento='I'
                  and imp.numero_impegno=q.nimac
                  and imp.numero_subimpegno=q.nsubimac
                  and imp.anno_impegno=q.annoimac
                  and imp.anno_esercizio=pAnnoEsercizio)
              and not exists (select 1 from migr_docquo_spesa_scarto s
                where s.ente_proprietario_id = f.ente_proprietario_id
                and s.tipo=q.tipofatt
                and s.numero=q.nfatt
                and s.anno=q.annofatt
                and s.codice_soggetto=q.codben
                and s.frazione=q.frazione
                and s.tipo_scarto='IMP'))seg -- la quota segnalata non deve essere stata scartata per impegno 2015(anno esercizio di migrazione) non migrato.
            );


insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;



        msgRes := 'Segnalazione quote non pagate per subimpegno presente alla fonte per anno <> anno di migrazione.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;


        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (select migr_docquo_spe_scarto_id_seq.nextval
         , seg.tipofatt, seg.annofatt, seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto, seg.tipo_scarto,pEnte
        from
        (Select distinct -- il distinct � necessario perch� � possibile avere diversi subimpegni 'uguali' su diversi annni tutti <> pAnnoEsercizio
           q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
           ,'Subimpegno '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' non migrato, presente alla fonte per anno <> '||pAnnoEsercizio as motivo_scarto
           ,'SI2' tipo_scarto
            from
            fatquo q
            , migr_doc_spesa f
            , subimp i
            where q.eu='U' and q.pagato='N'
            and f.tipo_fonte=q.tipofatt
            and f.anno=q.annofatt
            and f.numero=q.nfatt
            and f.codice_soggetto=q.codben
            and f.ente_proprietario_id=pEnte
            and f.anno >= 2014
            and q.nimac != 0
            and q.nsubimac != 0
            and i.nimp=q.nimac
            and i.NSUBIMP=q.nsubimac
            and i.annoimp=q.annoimac
            and i.anno_esercizio<>pAnnoEsercizio
            and not exists (select 1 from migr_impegno imp where
                imp.ente_proprietario_id=f.ente_proprietario_id
                and imp.tipo_movimento='S'
                and imp.numero_impegno=q.nimac
                and imp.numero_subimpegno=q.nsubimac
                and imp.anno_impegno=q.annoimac
                and imp.anno_esercizio=pAnnoEsercizio)
            and not exists (select 1 from migr_docquo_spesa_scarto s
                where s.ente_proprietario_id = f.ente_proprietario_id
                and s.tipo=q.tipofatt
                and s.numero=q.nfatt
                and s.anno=q.annofatt
                and s.codice_soggetto=q.codben
                and s.frazione=q.frazione
                and s.tipo_scarto='SIM'))seg -- la quota segnalata non deve essere stata scartata per subimpegno 2015(anno esercizio di migrazione) non migrato.
      );

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;



-- Segnalazioni per quota NON pagata legata ad una liquidazione non migrata perch� anno esercizio <> anno esercizio migrato
        msgRes := 'Segnalazione quote non pagate per liquidazione non migrata presente alla fonte per anno <> anno di migrazione.';


insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;

        insert into migr_docquo_spesa_scarto
               (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (select migr_docquo_spe_scarto_id_seq.nextval
         , seg.tipofatt, seg.annofatt, seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto, seg.tipo_scarto,pEnte
        from
         (Select distinct -- il distinct � necessario perch� � possibile avere diverse liquidazioni 'uguali'(stesso nr) su diversi annni tutti <> pAnnoEsercizio
           q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
           ,'Liquidazione '||q.nliq||' non migrata, presente alla fonte per anno <> '||pAnnoEsercizio as motivo_scarto
           ,'LI2' tipo_scarto
           from
            fatquo q
            , migr_doc_spesa f
            , liquidazioni l
            where q.eu='U' and q.pagato='N'
            and f.tipo_fonte=q.tipofatt
            and f.anno=q.annofatt
            and f.numero=q.nfatt
            and f.codice_soggetto=q.codben
            and f.ente_proprietario_id=pEnte
            and f.anno >= 2014
            and q.nliq != 0
            and q.nliq=l.nliq
            and l.anno_esercizio <> pAnnoEsercizio
            and not exists (select 1 from migr_liquidazione liq where
                liq.ente_proprietario_id=f.ente_proprietario_id
                and liq.numero_liquidazione=q.nliq
                and liq.anno_esercizio=pAnnoEsercizio)
            and not exists (select 1 from migr_docquo_spesa_scarto s
                where s.ente_proprietario_id = f.ente_proprietario_id
                and s.tipo=q.tipofatt
                and s.numero=q.nfatt
                and s.anno=q.annofatt
                and s.codice_soggetto=q.codben
                and s.frazione=q.frazione
                and s.tipo_scarto='LIQ'))seg-- la quota segnalata non deve essere stata scartata per liquidazione 2015(anno esercizio di migrazione) non migrato.
        );

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;


msgRes := 'Migrazione quote spesa.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;


        for migrCursor in
          (Select
             f.docspesa_id
             , q.tipofatt
             , f.tipo
             , q.annofatt
             , q.nfatt
             , q.codben
             , q.frazione
             , q.impquota
             , q.annoimac
             , q.nimac
             , q.nsubimac
             , q.pagato
             , q.nliq
             , l.annoprov -- dato del provvedimento legato alla liquidazione
             , l.nprov    -- dato del provvedimento legato alla liquidazione
             , l.codprov  -- dato del provvedimento legato alla liquidazione
             , l.direzione
             , l.codben codben_liq
             , l.progben  -- modalit� di pagamento legata alla liquidazione
             , nvl(q.rilev_iva, 'N')rilev_iva
             , f.data_scadenza
             , f.causale_sospensione
             , f.data_sospensione
             , f.data_riattivazione
             , q.cup
             , q.cig
             , 'N' flag_ord_singolo
             , 'N' flag_avviso
             , 'N' flag_esproprio
--             , 'N' flag_manuale
             , NULL as flag_manuale -- 28.12.2015 salvato su campo siac_t_subdoc.subdoc_convalida_manuale
             , q.note
             , q.nordin
             , q.causale_pagam
             , to_char(q.data_pagam,'YYYY-MM-DD') data_pagamento
             , f.descrizione
             , 'N' flag_certif_crediti
             , nvl(q.ute_unix_ins,pLoginOperazione) utente_creazione
             , nvl(q.ute_unix_agg,pLoginOperazione) utente_modifica
             , q.anno_esercizio
             , decode (f.collegato_cec, 'S', to_char(m.dataemis,'YYYY-MM-DD'),null) data_pagamento_cec
             , TIPO_COMMISSIONI_ES commissioni
             from
            fatquo q
            , migr_doc_spesa f
            , liquidazioni l
            , mandati m
            where q.eu='U'
            and f.tipo_fonte=q.tipofatt
            and f.anno=q.annofatt
            and f.numero=q.nfatt
            and f.codice_soggetto=q.codben
            and f.ente_proprietario_id=pEnte
            and f.fl_scarto='N'
            and l.nliq(+)=q.nliq
            and l.anno_esercizio(+)=pAnnoEsercizio
            and m.anno_esercizio(+)=q.anno_esercizio
            and m.nmand(+)=q.nordin)
            loop
                codRes := 0;
                msgMotivoScarto := null;
                msgRes := null;
                tipoScarto := null;
--                recMigrato := 0;
--                recPresente := 0;
                recSegnalato := 0;
                segnalare := false;

                h_nimac := 0;
                h_nsubimac := 0;
                h_annoimac := NULL;
                h_nliq := 0;
                h_progben := 0;
                h_nordin := migrCursor.Nordin;

                h_note := null;
                h_sede_secondaria := 'N'; -- obbligatorio, default N
                h_anno_provvedimento := null;
                h_numero_provvedimento :=null;
                h_tipo_provvedimento :=null;
                h_direzione_provvedimento :=null;
                h_oggetto_provvedimento :=null;
                h_stato_provvedimento :=null;
                h_note_provvedimento :=null;
                h_sede_id :=null; -- DAVIDE - 14.07.2016

                h_rec := 'Quota  ' || migrCursor.annofatt || '/'||migrCursor.nfatt||' tipo '||migrCursor.tipofatt||
                         ' Soggetto '||migrCursor.Codben||': frazione '||migrCursor.frazione||'.';
				
                msgRes := 'Verifica importo quota fattura.';
                if migrCursor.Tipofatt='F' and migrCursor.impquota <0 then
                    msgRes          := msgRes|| 'Importo negativo.';
                    msgMotivoScarto := msgRes;
                    tipoScarto:='FN';-- fattura negativa
                    codRes := -1;
                end if;

                if codRes = 0 then

                -- quota NON PAGATA
                  if migrCursor.pagato = 'N' then
                    -- cerco l'impegno/sub sulla tabella di migrazione se non c'� cerco l'impegno nella tabella fonte per anno <> anno esercizio di migrazione
                    -- (ci fosse per anno_esercizio=anno esercizio di migrazione non sarebbe presente nel cursore perch� caricato precedentemente come scarto.

                    if migrCursor.Nimac!=0 then

                      msgRes := 'Verifica impegno/subimpegno in tabella scarto.';

                      select count(*) into recSegnalato -- recMigrato
                      from migr_docquo_spesa_scarto m
                      where m.ente_proprietario_id=pEnte
                      and m.tipo=migrCursor.Tipofatt
                      and m.anno=migrCursor.Annofatt
                      and m.numero=migrCursor.Nfatt
                      and m.codice_soggetto=migrCursor.Codben
                      and m.frazione=migrCursor.Frazione
                      and m.tipo_scarto in ('IM2','SI2'); -- segnalazione per impegno e sub presente alla fonte per anno esercizio <> anno esercizio migrato

                      /*
                      msgRes := 'Verifica impegno/subimpegno migrato';

                      select count(*) into recMigrato
                      from migr_impegno m
                      where m.ente_proprietario_id=pEnte
                      and m.anno_esercizio=pAnnoEsercizio
                      and m.numero_impegno=migrCursor.Nimac
                      and m.numero_subimpegno=migrCursor.Nsubimac
                      and m.anno_impegno=migrCursor.Annoimac;
                      if recMigrato != 0 then
                      */
                      if recSegnalato = 0 then

                        h_nimac := migrCursor.Nimac;
                        h_nsubimac := migrCursor.Nsubimac;
                        h_annoimac := migrCursor.Annoimac;

                        -- Il record segnalato per mancanza di impegno/sub viene migrato con i dati a 0 anche per liquidazione e modalit� di pagamento
                        h_nliq := migrCursor.nliq;
                        h_progben := migrCursor.progben;

                      /*else  -- l'impegno/sub non � tra quelli migrati su contabilia.

                        if migrCursor.Nsubimac=0 then
                          msgRes := 'Ricerca impegno per anno esercizio <> '||pAnnoEsercizio;

                          tipoScarto:='IMP';
                          select count(*) into recPresente
                          from impegni i
                          where i.anno_esercizio<>pAnnoesercizio
                          and i.nimp=migrCursor.Nimac
                          and i.annoimp=migrCursor.Annoimac;

                        else
                          msgRes := 'Ricerca subimpegno per anno esercizio <> '||pAnnoEsercizio;

                          tipoScarto:='SIM';
                          select count(*) into recPresente
                          from subimp i
                          where i.anno_esercizio<>pAnnoesercizio
                          and i.nimp=migrCursor.Nimac
                          and i.annoimp=migrCursor.Annoimac
                          and i.nsubimp=migrCursor.Nsubimac;

                        end if;
                        if recPresente > 0 then
                          --  la quota � migrata senza i dati dell'impegno/subimpegno
                          segnalare := true;
                          msgMotivoScarto :=
                             'Impegno '||migrCursor.annoimac||'/'||migrCursor.nimac||'/'||migrCursor.nsubimac||' non migrato, presente alla fonte per anno <> '||pAnnoEsercizio;
                        else
                          codRes := -2;
                          msgMotivoScarto :=
                             'Impegno '||migrCursor.annoimac||'/'||migrCursor.nimac||'/'||migrCursor.nsubimac||' non migrato, non presente alla fonte.';
                        end if;*/
                      end if;
                    end if;
  --                  if migrCursor.nliq != 0 then
                    if h_nliq  != 0 then
                      -- QUOTA LIQUIDATA
                      msgRes := 'Quota liquidata, verifica liquidazione migrata.';

                      select count(*) into recSegnalato--recMigrato
                      from migr_docquo_spesa_scarto m
                      where m.ente_proprietario_id=pEnte
                      and m.tipo=migrCursor.Tipofatt
                      and m.anno=migrCursor.Annofatt
                      and m.numero=migrCursor.Nfatt
                      and m.codice_soggetto=migrCursor.Codben
                      and m.frazione=migrCursor.Frazione
                      and m.tipo_scarto = ('LI2');
                      /*
                      select count(*) into recMigrato
                      from migr_liquidazione m
                      where m.ente_proprietario_id=pEnte
                      and m.anno_esercizio=pAnnoEsercizio
                      and m.numero_liquidazione=migrCursor.Nliq;
                      if recMigrato != 0 then
                      */
                      if recSegnalato = 0 then
                        h_nliq := migrCursor.nliq;
                        h_progben := migrCursor.progben;
                      else
                        h_nliq := 0;
                        h_progben := 0;

                      /*else
                          msgRes := 'Ricerca liquidazione per anno esercizio <> '||pAnnoEsercizio;

                          select count(*) into recPresente
                          from liquidazioni i
                          where i.anno_esercizio<>pAnnoesercizio
                          and i.nliq=migrCursor.nliq;

                          if recPresente != 0 then
                            segnalare := true;
                            msgMotivoScarto :=
                             'Liquidazione '||migrCursor.nliq||' non migrato, presente alla fonte per anno <> '||pAnnoEsercizio;
                            tipoScarto := 'LIQ';
                          else
                            codRes := -2;
                            msgMotivoScarto :=
                               'Liquidazione '||migrCursor.nliq||' non migrato, non presente alla fonte per nessun anno.';
                          end if;*/
                      end if;

                      if h_nliq != 0 then     
                        -- quota liquidata e liquidazione migrata.

                      -- impostare la MDP solo se la quota � liquidata ma non pagata (pagato='N'), con la MDP della liquidazione stessa
                      -- se la MDP collegata ( derivata dalla liquidazione ) riferisce ad una sede secondaria, collegarla anche alla quota, sempre la quota non � pagata (pagato='N')
                      -- recuperare  il provvedimento legato alla liquidazione. Se non esiste il provvedimento leggerlo dall'impegno
                        msgRes := 'Verifica MDP migrata.';
                        begin
                          -- SEDE SECONDARIA?
                         -- select mdp.sede_secondaria into h_sede_secondaria          -- DAVIDE - 14.07.2016 - aggiunta sede_id
                          select mdp.sede_secondaria, mdp.sede_id into h_sede_secondaria, h_sede_id
                          from migr_soggetto sogg,  migr_modpag  mdp
                          where sogg.ente_proprietario_id=pEnte
                          and mdp.ente_proprietario_id=pEnte
                          and sogg.codice_soggetto=migrCursor.codben_liq
                          and sogg.soggetto_id=mdp.soggetto_id
                          and mdp.codice_modpag=migrCursor.progben;
                        exception
                           when no_data_found then
                             codRes:=-2;
                             msgRes := msgRes || 'MDP non migrata.';
                             msgMotivoScarto := msgRes;
    --                         tipoScarto:='MDE';
                             tipoScarto:='MDP';
                           when others then
                             codRes:=-1;
                             msgRes := msgRes || h_rec || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                             RAISE ERROR_DOCUMENTO;
                        end;
                        if codRes = 0 then
                          if migrCursor.Nprov is not null and migrCursor.Nprov <> '0' then

                              msgRes := 'Lettura dati Provvedimento della liquidazione.';

                              h_anno_provvedimento   := migrCursor.annoprov;
                              h_numero_provvedimento := migrCursor.nprov;
                              h_tipo_provvedimento := migrCursor.codprov;
                              h_direzione_provvedimento := migrCursor.direzione;

                              msgRes := 'leggi_provvedimento per '||h_anno_provvedimento||'/'||h_numero_provvedimento||'/'||h_tipo_provvedimento||'/'||h_direzione_provvedimento;
                              leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,h_tipo_provvedimento,h_direzione_provvedimento,
                                                  pEnte,codRes,msgRes,
                                                  h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);

                              if codRes=0 then
                                 if h_tipo_provvedimento = PROVV_ATTO_LIQUIDAZIONE then
                                   h_tipo_provvedimento := PROVV_ATTO_LIQUIDAZIONE_SIAC;
                                 end if;
                                 h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
  --                               if migrCursor.codprov = PROVV_DETERMINA_REGP or migrCursor.Codprov = PROVV_ATTO_LIQUIDAZIONE then
                                 if migrCursor.codprov = PROVV_DETERMINA_REGP or migrCursor.Codprov = PROVV_ATTO_LIQUIDAZIONE then
                                    h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                                 else
                                    if h_direzione_provvedimento is not null then
                                       h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                                    end if;
                                 end if;
                              end if;
                              if codRes=0 and h_stato_provvedimento is null then
                                 h_stato_provvedimento:=STATO_D;
                              end if;
                          end if;
                        end if;
                      end if;
                    end if;
                 elsif migrCursor.pagato = 'S' then
  --se la quota � pagata impostare prima
  --gli estremi di pagamento
  -- se nordin!=0 impostare tutta la catena di movimenti da impegno e mandato
  -- se nordin=0 impostare fatquo.causale_pagam e fatquo.data_pagam
  -- se nordin=0 e non c'� causale_pagam impostare una causale fittizia ""QUOTA PAGATA ESTRREMI DI PAGAMENTO MANCANTI"""
                    if h_nordin != 0 then
                       if migrCursor.nsubimac = 0 then
                         h_note:=' PAGAMENTO N.MAND '||h_nordin||' N.LIQ '||migrCursor.nliq||' IMPEGNO '||
                                  migrCursor.annoimac||'/'||migrCursor.nimac||'  ANNO '||migrCursor.anno_esercizio||'.';
                       else
                         h_note:='PAGAMENTO N.MAND '||h_nordin||' N.LIQ '||migrCursor.nliq||' SUBIMPEGNO '||
                                 migrCursor.annoimac||'/'||migrCursor.nimac||'/'||migrCursor.nsubimac
                                 ||'  ANNO '||migrCursor.anno_esercizio||'.';
                       end if;
                    else
                      h_nordin := 999;
                      if migrCursor.causale_pagam is not null then
                        h_note:='CAUSALE PAGAM: '||migrCursor.causale_pagam||'.DATA PAGAM '|| migrCursor.data_pagamento||'.';
                      else
                        h_note:='QUOTA PAGATA ESTRREMI DI PAGAMENTO MANCANTI.';
                      end if;
                    end if;
                    h_note:=h_note||migrCursor.Note;

                  end if;
               end if;

                if codRes = 0 then

                 -- DAVIDE - Conversione dell'importo in Euro
				 -- ricavo la divisa relativa alla quota e converto l'importo
				 -- se necessario
                 begin
                   divisa_esercizio := null;
                   h_Importo_quote := migrCursor.impquota;

                   select f.divisa_esercizio
                   into divisa_esercizio
                   from fatture f
                   where migrCursor.annofatt=f.annofatt
                   and migrCursor.codben=f.codben
                   and migrCursor.nfatt=f.nfatt
                   and migrCursor.tipofatt=f.tipofatt;

                   if divisa_esercizio = 'L' then
                     h_Importo_quote := migrCursor.impquota / RAPPORTO_EURO_LIRA;
                   end if;
                 exception
                     when others then
                      h_Importo_quote := migrCursor.impquota;
                 end;

                 -- DAVIDE - Fine
                 msgRes := 'Inserimento in migr_docquo_spesa.';

                 insert into migr_docquo_spesa
                 (docquospesa_id,
                  docspesa_id,
                  tipo,
                  tipo_fonte,
                  anno,
                  numero,
                  codice_soggetto,
                  frazione,
                  elenco_doc_id,-- da gestire, impostato valore di default 0
                  codice_soggetto_pag, -- valore di default 0
                  codice_modpag,
                  codice_modpag_del, -- valore di default 0
                  codice_indirizzo,-- valore di default 0
                  sede_secondaria,
                  importo,
                  importo_da_dedurre,--valore di default 0
                  anno_esercizio,
                  anno_impegno,
                  numero_impegno,
                  numero_subimpegno,
                  anno_provvedimento,
                  numero_provvedimento,
                  tipo_provvedimento,
                  sac_provvedimento,
                  oggetto_provvedimento,
                  note_provvedimento,
                  stato_provvedimento,
                  descrizione,
                  --numero_iva, da verificare come trattare
                  flag_rilevante_iva,
                  data_scadenza,
                  --data_scadenza_new, --NULL non gestito
                  cup,
                  cig,
                  commissioni,
                  causale_sospensione,
                  data_sospensione,
                  data_riattivazione,
                  flag_ord_singolo, -- valore di default N
                  flag_avviso, -- valore di default N
                  --tipo_avviso, NULL non gestito
                  flag_esproprio, -- valore di default N
                  flag_manuale, -- valore di default NULL
                  note,
                  causale_ordinativo,
                  numero_mutuo, -- valore di default 0
                  --annotazione_certif_crediti,
                  --data_certif_crediti, NULL non gestito
                  --note_certif_crediti, NULL non gestito
                  --numero_certif_crediti, NULL non gestito
                  flag_certif_crediti, --valore di default 0
                  numero_liquidazione,
                  numero_mandato,
                  data_pagamento_cec,
                  utente_creazione,
                  utente_modifica,
                  ente_proprietario_id,
				  sede_id)               -- DAVIDE - 14.07.2016 - aggiunta sede_id
                 values
                 (migr_docquo_spesa_id_seq.nextval,
                  migrCursor.Docspesa_Id,
                  migrCursor.tipo,
                  migrCursor.tipofatt,
                  migrCursor.annofatt,
                  migrCursor.nfatt,
                  migrCursor.Codben,
                  migrCursor.Frazione,
                  0,--elenco_doc_id
                  0,--codice_soggetto_pag
                  h_progben,
                  0,--codice_modpag_del
                  0,--codice_indirizzo
                  h_sede_secondaria,
               -- DAVIDE - Conversione dell'importo in Euro
                  --migrCursor.impquota,
				          h_Importo_quote,
		       -- DAVIDE - Fine
                  0,--importo_da_dedurre
                  pAnnoEsercizio,
                  h_annoimac,
                  h_nimac,
                  h_nsubimac,
                  h_anno_provvedimento,
                  h_numero_provvedimento,
                  h_tipo_provvedimento,
                  h_direzione_provvedimento,
                  h_oggetto_provvedimento,
                  h_note_provvedimento,
                  h_stato_provvedimento,
                  migrCursor.descrizione,
                  migrCursor.rilev_iva,
                  migrCursor.data_scadenza,
                  --migrCursor.data_scadenza_new,
                  migrCursor.cup,
                  migrCursor.cig,
                  migrCursor.Commissioni,
                  migrCursor.causale_sospensione,
                  migrCursor.data_sospensione,
                  migrCursor.data_riattivazione,
                  migrCursor.flag_ord_singolo,-- valore di default N
                  migrCursor.flag_avviso,-- valore di default N
--                  migrCursor.Tipo_Avviso,
                  migrCursor.flag_esproprio,-- valore di default N
                  migrCursor.flag_manuale,-- valore di default NULL
                  h_note,
                  migrCursor.descrizione, -- descrizione della fattura
                  0,--non gestito, valore di default
--                  h_annotazioni_dl35,
--                  h_data_dl35,
--                  h_note_dl35,
--                  h_numero_dl35,
                  migrCursor.flag_certif_crediti,
                  h_nliq,
                  h_nordin,
                  migrCursor.data_pagamento_cec,
                  migrCursor.utente_creazione,
                  migrCursor.utente_modifica,
                  pEnte,
				  h_sede_id);                         -- DAVIDE - 14.07.2016 - aggiunta sede_id
                 cDocInseriti := cDocInseriti + 1;
                end if;
                if codRes != 0 or segnalare=true then
                 msgRes := 'Inserimento in migr_docquo_spesa_scarto.';
                 insert into migr_docquo_spesa_scarto
                 (docquo_spesa_scarto_id,
                  tipo,
                  anno,
                  numero,
                  codice_soggetto,
                  frazione,
                  motivo_scarto,
                  tipo_scarto,
                  ente_proprietario_id)
                 values
                 (migr_docquo_spe_scarto_id_seq.nextval,
                  migrCursor.tipofatt,
                  migrCursor.Annofatt,
                  migrCursor.Nfatt,
                  migrCursor.Codben,
                  migrCursor.Frazione,
                  msgMotivoScarto,
                  tipoScarto,
                  pEnte);
--                  cDocScartati := cDocScartati + 1;
                 end if;

                 if numInsert >= N_BLOCCHI_DOC then
                  commit;
                  numInsert := 0;
                 else
                  numInsert := numInsert + 1;
                 end if;

          end loop;

msgRes := 'Migrazione quote spesa.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;

          msgRes:='Gestione scarti quote documenti spesa-aggiornamento migr_docquo_spesa dopo ciclo.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;

          update migr_docquo_spesa m set m.fl_scarto='S'
          where 0!=(select count(*) from  migr_docquo_spesa_scarto mq
                    where mq.anno=m.anno
                      and mq.numero=m.numero
                      and mq.tipo=m.tipo_fonte
                      and mq.codice_soggetto=m.codice_soggetto
                      and mq.ente_proprietario_id=pEnte
                      and mq.tipo_scarto not in ('IM2','SI2','LI2')) -- quote segnalata ma cmq. da migrare
          and   m.ente_proprietario_id=pEnte;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;

          msgRes:='Gestione scarti quote documenti spesa-aggiornamento migr_doc_spesa dopo ciclo.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'begin.',pEnte);
commit;
          update migr_doc_spesa m set m.fl_scarto='S'
          where 0!=(select count(*) from  migr_docquo_spesa_scarto mq
                    where mq.anno=m.anno
                      and mq.numero=m.numero
                      and mq.tipo=m.tipo_fonte
                      and mq.codice_soggetto=m.codice_soggetto
                      and mq.ente_proprietario_id=pEnte
                      and mq.tipo_scarto not in ('IM2','SI2','LI2')) -- quote segnalate, migrate per cui anche le fatt sono da migrare.
          and m.fl_scarto='N'
          and m.ente_proprietario_id=pEnte;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_spesa',msgRes||'end.',pEnte);
commit;
          select count(*) into cDocScartati from migr_docquo_spesa_scarto where ente_proprietario_id = pEnte and tipo_scarto not in ('IM2','SI2','LI2');
          select count(*) into cDocSegnalati from migr_docquo_spesa_scarto where ente_proprietario_id = pEnte and tipo_scarto in ('IM2','SI2','LI2');

          pMsgRes := pMsgRes || 'Quote migrate '|| cDocInseriti || ' di cui segnalate '||cDocSegnalati||', scartate '|| cDocScartati;
          pCodRes := 0;
          pRecScartati := cDocScartati;
          pRecInseriti := cDocInseriti;

    exception
          when ERROR_DOCUMENTO then
--            dbms_output.put_line(h_rec || ' msgRes ' ||
--                                 msgRes );
            pMsgRes      := pMsgRes || h_rec || msgRes ;
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
          when others then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                msgRes || ' Errore ' || SQLCODE || '-' ||
                                 SUBSTR(SQLERRM, 1, 1000));
            pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                              SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
   end migrazione_docquo_spesa;

   procedure migrazione_doc_entrata (pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pRecInseriti out number,
                                   pRecScartati out number,
                                   pMsgRes out varchar2
)
   is
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        numInsert number := 0;
        h_sogg_migrato number := 0;
        h_num number := 0;
        h_stato varchar2(3):=null;
        h_rec varchar2(750) := null;
        tipoScarto varchar2(3):=null;

     -- DAVIDE - Conversione dell'importo in Euro
		h_importo  NUMBER(15,2) := 0.0;
     -- DAVIDE - Fine

        ERROR_DOCUMENTO EXCEPTION;
   begin
        msgRes := 'Pulizia tabelle di migrazione.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_entrata',msgRes||'begin.',pEnte);
commit;

        DELETE FROM MIGR_DOC_ENTRATA WHERE ENTE_PROPRIETARIO_ID = pEnte and FL_MIGRATO = 'N';
        DELETE FROM MIGR_DOC_ENTRATA_SCARTO WHERE ENTE_PROPRIETARIO_ID = pEnte;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_entrata',msgRes||'end.',pEnte);
commit;

        msgRes := 'Inizio migrazione documenti di entrata.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_entrata',msgRes||'begin.',pEnte);
commit;

        for migrCursor in
        (select
           f.tipofatt
           , decode ( f.tipofatt , 'F', 'FTV','A', 'NCV') as tipo
           , to_number(f.annofatt) annofatt
           , f.nfatt
           , f.codben
           , nvl(f.descri, 'DOCUMENTO N. '||f.nfatt||' DEL '|| to_char(f.dataemis,'DD/MM/YYYY')) descrizione
           , to_char(f.dataemis,'YYYY-MM-DD') data_emissione
           , to_char(f.datascad,'YYYY-MM-DD') data_scadenza
   -- DAVIDE - CONVERSIONE LIRA / EURO - aggiunto campo divisa_esercizio
           , f.divisa_esercizio
   -- DAVIDE - Fine
           , f.importo
           , to_char(f.dataprot,'dd/MM/yyyy hh:mm:ss') data_repertorio
           --, to_char(trunc(f.dataprot),'dd/MM/yyyy') data_repertorio
           , f.nprot numero_repertorio
           , f.annoprot anno_repertorio
           -- 14.10 dani, dati registro unico letti da tab fatture
--           , to_char(ruf.data_ruf,'YYYY-MM-DD') data_registro_fatt
--           , nvl(ruf.n_ruf, 0) numero_registro_fatt
           , to_char(f.data_ruf,'YYYY-MM-DD') data_registro_fatt
           , nvl(f.n_ruf, 0) numero_registro_fatt
           , f.anno_ruf anno_registro_fatt
           , nvl(f.ute_unix_ins,pLoginOperazione) utente_creazione
           , nvl(f.ute_unix_agg,pLoginOperazione) utente_modifica
           , f.annofatv -- rif. doc collegato
           , f.nfatv -- rif. doc collegato
           , f.tipofatv -- rif. doc collegato
           from fatture f
           , migr_doc_temp tmp
--           , fatture_numera_ruf ruf
          where
            tmp.ente_proprietario_id = pEnte
            and f.eu=tmp.eu and tmp.eu = 'E'
            and f.tipofatt=tmp.tipo
            and f.annofatt=tmp.anno
            and f.nfatt=tmp.numero
            and f.codben=tmp.codice_soggetto
/*            and f.eu=ruf.eu(+)
            and f.codben=ruf.codben(+)
            and f.nfatt=ruf.nfatt(+)
            and f.annofatt=ruf.annofatt(+)
            and f.tipofatt=ruf.tipofatt(+)*/
            order by f.annofatt, f.tipofatt, f.codben, f.nfatt)

          loop
            -- inizializza variabili
            codRes := 0;
            msgMotivoScarto  := null;
            msgRes := null;
            h_sogg_migrato := 0;
            h_num := 0;
            h_stato := null;
            tipoScarto:=null;

            h_rec := 'Documento  '||migrCursor.annofatt || '/'||migrCursor.nfatt||' tipo '||migrCursor.tipofatt||
                     ' Soggetto '||migrCursor.codben||'.';

            -- se importo negativo e tipo = F scarto il documento
            msgRes := 'Verifica importo fattura.';
            if migrCursor.Tipofatt='F' and migrCursor.importo <0 then
                msgRes          := msgRes|| 'Importo negativo per tipo fattura.';
                msgMotivoScarto := msgRes;
                codRes := -2; -- Il record sar� inserito come scarto, l'elaborazione continua.
                tipoScarto:='FN';-- fattura negativa
            end if;

            if codres = 0 then

              msgRes := 'Verifica soggetto migrato.';
              begin
                select nvl(count(*), 0)
                  into h_sogg_migrato
                  from migr_soggetto
                 where codice_soggetto = migrCursor.codben
                 and   ente_proprietario_id=pEnte;

                if h_sogg_migrato = 0 then
                  codRes := -2;
                  msgRes := msgRes||'Soggetto non migrato.';
                  msgMotivoScarto := msgRes;
                  tipoScarto:='SNM';
                end if;
              exception
                when no_data_found then
                  codRes := -2;
                  h_sogg_migrato  := 0;
                  msgRes          := msgRes|| 'Soggetto non migrato.';
                  msgMotivoScarto := msgRes;
                  tipoScarto:='SNM';-- SOGGETTO NON MIGRATO
                when others then
                  codRes := -1;
                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                  raise ERROR_DOCUMENTO;
              end;
              msgRes := 'Verifica soggetto valido.';
              -- verifica della validit� del soggetto. Ulteriore dettaglio per lo scarto.
              if h_sogg_migrato = 0 and codRes!=-1 then
                begin
                  select nvl(count(*),0) into h_num
                  from fornitori
                  where codben=migrCursor.codben and blocco_pag='N';

                  if h_num = 0 then
                    codRes := -2;
                    msgRes  := msgRes || 'Soggetto non valido.';
                    msgMotivoScarto := msgRes;
                    tipoScarto:='SNV'; -- SOGGETTO NON VALIDO
                  end if;
                exception
                  when no_data_found then
                    codRes := -2;
                    h_sogg_migrato  := 0;
                    h_num           := 0;
                    msgRes          := msgRes || 'Soggetto non valido.';
                    msgMotivoScarto := msgRes;
                    tipoScarto:='SNV'; -- SOGGETTO NON VALIDO
                  when others then
                    codRes := -1;
                    msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                    raise ERROR_DOCUMENTO;
                end;
              end if;
            end if;

            if codRes = 0 then
              msgRes := 'Definizione stato documento.';
              get_stato_documento ('E', migrCursor.codben, migrCursor.annofatt, migrCursor.nfatt, migrCursor.tipofatt,pEnte,pAnnoEsercizio,
                                   h_stato, codRes, msgRes);

              if codRes = -1 then raise ERROR_DOCUMENTO; end if;
              if codRes = -2 then
                    msgMotivoScarto := msgRes;
                    tipoScarto:='FSS'; -- FATTURA SENZA STATO
              end if;
            end if;

            if codRes = 0 then

               -- DAVIDE - Conversione dell'importo in Euro
			   if migrCursor.divisa_esercizio = 'L' then
				   h_Importo := migrCursor.importo / RAPPORTO_EURO_LIRA;
			   else
				   h_Importo := migrCursor.importo;
			   end if;
              -- DAVIDE - Fine

 			   msgRes := 'Inserimento in migr_doc_entrata.';
               insert into migr_doc_entrata
               (docentrata_id,
                tipo,
                tipo_fonte,
                anno,
                numero,
                codice_soggetto,
                codice_soggetto_inc,
                stato,
                descrizione,
                data_emissione,
                data_scadenza,
                importo,
                arrotondamento,
                bollo,
                data_repertorio,
                numero_repertorio,
                anno_repertorio,
                note,
                numero_registro_fatt,
                anno_registro_fatt,
                data_registro_fatt,
                utente_creazione,
                utente_modifica,
                ente_proprietario_id,
                annoRif,
                numeroRif,
                tipoRif
                )
              values
              (migr_doc_entrata_id_seq.nextval,
               migrCursor.tipo,
               migrCursor.Tipofatt,
               migrCursor.annofatt,
               migrCursor.nfatt,
               migrCursor.codben,
               0,-- codice_soggetto_inc
               h_stato,
               migrCursor.descrizione,
               migrCursor.data_emissione,
               migrCursor.data_scadenza,
          -- DAVIDE - Conversione dell'importo in Euro
               --migrCursor.importo,
               h_Importo,
		  -- DAVIDE - Fine
               0,-- arrotondamento
               NULL, -- bollo
               migrCursor.Data_Repertorio,
               migrCursor.numero_repertorio,
               migrCursor.anno_repertorio,
               NULL, --note
               migrCursor.numero_registro_fatt,
               migrCursor.anno_registro_fatt,
               migrCursor.data_registro_fatt,
               migrCursor.utente_creazione,
               migrCursor.utente_modifica,
               pEnte,
               migrCursor.Annofatv,
               migrCursor.Nfatv,
               migrCursor.Tipofatv);
              cDocInseriti := cDocInseriti + 1;
           else
              msgRes := 'Inserimento in migr_doc_entrata_scarto.';
              insert into migr_doc_entrata_scarto
              (doc_entrata_scarto_id,
               tipo,
               anno,
               numero,
               codice_soggetto,
               motivo_scarto,
               tipo_scarto,
               ente_proprietario_id)
              values
              (migr_doc_entrata_scarto_id_seq.nextval,
               migrCursor.tipofatt,
               migrCursor.annofatt,
               migrCursor.nfatt,
               migrCursor.Codben,
               msgMotivoScarto,
               tipoScarto,
               pEnte);

              cDocScartati := cDocScartati + 1;
            end if;

--            if codRes=-1 then
--               raise ERROR_DOCUMENTO;
--            end if;

            if numInsert >= N_BLOCCHI_DOC then
              commit;
              numInsert := 0;
            else
              numInsert := numInsert + 1;
            end if;

          end loop;

msgRes := 'Migrazione documenti di entrata.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_doc_entrata',msgRes||'end.',pEnte);
commit;

          pMsgRes := pMsgRes || 'Documenti migrati '|| cDocInseriti || ', scartati '|| cDocScartati;
          pCodRes := 0;
    exception
          when ERROR_DOCUMENTO then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                 msgRes );
            pMsgRes      := pMsgRes || h_rec || msgRes ;
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
          when others then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                 msgRes || ' Errore ' || SQLCODE || '-' ||
                                 SUBSTR(SQLERRM, 1, 100));
            pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                              SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
   end migrazione_doc_entrata;

   procedure migrazione_docquo_entrata (pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pRecInseriti out number,
                                   pRecScartati out number,
                                   pMsgRes out varchar2)
   is
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        cDocSegnalati number := 0;
        numInsert number := 0;
        h_rec varchar2(750) := null;
        tipoScarto varchar2(3):= null;
        recSegnalato number := 0;

        h_note varchar2(500) := null;

        h_nimac number := 0;
        h_nsubimac number := 0;
        h_annoimac varchar2(4) := NULL;
        h_nordin number := 0;
        /* Dati del provvedimento per ora non trattati
        h_anno_provvedimento    varchar2(4) := null;
        h_numero_provvedimento  varchar2(10) := null;
        h_tipo_provvedimento    varchar2(20) := null;
        h_direzione_provvedimento varchar2(20):=null;
        h_stato_provvedimento   varchar2(5) := null;
        h_oggetto_provvedimento varchar2(500) := null;
        h_note_provvedimento    varchar2(500) := null;*/

		-- DAVIDE - Conversione Importi quote
        h_Importo_quote number(15,2) :=0.0;
        h_Importo_quote_da_dedurre number(15,2) :=0.0;
		divisa_esercizio varchar2(1) := null;
		-- DAVIDE - Fine

        ERROR_DOCUMENTO EXCEPTION;
   begin
        msgRes := 'Pulizia tabelle di migrazione.';



insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;

        DELETE FROM MIGR_DOCQUO_ENTRATA WHERE ENTE_PROPRIETARIO_ID = pEnte and FL_MIGRATO = 'N';
        DELETE FROM MIGR_DOCQUO_ENTRATA_SCARTO WHERE ENTE_PROPRIETARIO_ID = pEnte;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;

        --Scarto quote non pagate per accertamento 2015 (anno esercizio migrato) non migrato

        msgRes := 'Scarto quote non pagate per accertamento '||pAnnoEsercizio||' non migrato.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;

        insert into migr_docquo_entrata_scarto
               (docquo_entrata_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (Select
         migr_docquo_ent_scarto_id_seq.nextval,q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
         ,'Accertamento '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' a.e. '||pAnnoEsercizio||' non migrato.','ACC',pEnte
          from
          fatquo q
          , migr_doc_entrata f
          , accertamenti a
          where q.eu='E' and q.pagato='N'
          and f.tipo_fonte=q.tipofatt
          and f.anno=q.annofatt
          and f.numero=q.nfatt
          and f.codice_soggetto=q.codben
          and f.ente_proprietario_id=pEnte
          and q.nimac != 0
          and q.nsubimac = 0
          and a.annoacc = q.annoimac
          and a.nacc = q.nimac
          and a.anno_esercizio=pAnnoEsercizio
          and not exists (select 1 from migr_accertamento imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo_movimento = 'A'
              and imp.numero_accertamento=q.nimac
              and imp.numero_subaccertamento=q.nsubimac
              and imp.anno_accertamento=q.annoimac
              and imp.anno_esercizio=pAnnoEsercizio));

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;


        msgRes := 'Scarto quote non pagate per subaccertamento '||pAnnoEsercizio||' non migrato.';


insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;

        insert into migr_docquo_entrata_scarto
               (docquo_entrata_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (Select
         migr_docquo_ent_scarto_id_seq.nextval,q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
         ,'Accertamento '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' a.e. '||pAnnoEsercizio||' non migrato.','SAC',pEnte
          from
          fatquo q
          , migr_doc_entrata f
          , subacc a
          where q.eu='E' and q.pagato='N'
          and f.tipo_fonte=q.tipofatt
          and f.anno=q.annofatt
          and f.numero=q.nfatt
          and f.codice_soggetto=q.codben
          and f.ente_proprietario_id=pEnte
          and q.nimac != 0
          and q.nsubimac != 0
          and a.annoacc = q.annoimac
          and a.nacc = q.nimac
          and a.nsubacc = q.nsubimac
          and a.anno_esercizio=pAnnoEsercizio
          and not exists (select 1 from migr_accertamento imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo_movimento = 'S'
              and imp.numero_accertamento=q.nimac
              and imp.numero_subaccertamento=q.nsubimac
              and imp.anno_accertamento=q.annoimac
              and imp.anno_esercizio=pAnnoEsercizio));


insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;

        --18.12.2015
        -- Scarto quote non pagate con anno fattura <2014 e collegate a movimenti non andati a residuo .
        msgRes := 'Scarto quote collegate a accertamento non andato a residuo e annafatt<2014.';

        insert into migr_docquo_entrata_scarto
               (docquo_entrata_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (Select migr_docquo_ent_scarto_id_seq.nextval, seg.tipofatt,seg.annofatt,seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto,seg.tipo_scarto,pEnte
        from
        (Select DISTINCT
         q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
         ,'Accertamento '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' non migrato.Presente alla fonte per anno esercizio <> '||pAnnoEsercizio as motivo_scarto
         ,'ACC' tipo_scarto
          from
          fatquo q
          , migr_doc_entrata f
          , accertamenti a
          where q.eu='E' and q.pagato='N'
          and f.tipo_fonte=q.tipofatt
          and f.anno=q.annofatt
          and f.numero=q.nfatt
          and f.codice_soggetto=q.codben
          and f.ente_proprietario_id=pEnte
          and f.anno <2014
          and q.nimac != 0
          and q.nsubimac = 0
          and a.annoacc = q.annoimac
          and a.nacc = q.nimac
          and a.anno_esercizio<>pAnnoEsercizio
          and not exists (select 1 from migr_accertamento imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo_movimento ='A'
              and imp.numero_accertamento=q.nimac
              and imp.numero_subaccertamento=q.nsubimac
              and imp.anno_accertamento=q.annoimac
              and imp.anno_esercizio=pAnnoEsercizio)
          and not exists (select 1 from migr_docquo_entrata_scarto imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo=q.tipofatt
              and imp.anno=q.annofatt
              and imp.numero=q.nfatt
              and imp.codice_soggetto=q.codben
              and imp.frazione=q.frazione
              and imp.tipo_scarto='ACC'))seg
        );
        msgRes := 'Scarto quote collegate a subaccertamento non andato a residuo e annafatt<2014.';

        insert into migr_docquo_entrata_scarto
               (docquo_entrata_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (Select migr_docquo_ent_scarto_id_seq.nextval, seg.tipofatt,seg.annofatt,seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto,seg.tipo_scarto,pEnte
        from
        (Select DISTINCT
         q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
         ,'Subaccertamento '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' non migrato.Presente alla fonte per anno esercizio <> '||pAnnoEsercizio as motivo_scarto
         ,'SAC' tipo_scarto
          from
          fatquo q
          , migr_doc_entrata f
          , SUBACC a
          where q.eu='E' and q.pagato='N'
          and f.tipo_fonte=q.tipofatt
          and f.anno=q.annofatt
          and f.numero=q.nfatt
          and f.codice_soggetto=q.codben
          and f.ente_proprietario_id=pEnte
          and f.anno < 2014
          and q.nimac != 0
          and q.nsubimac != 0
          and a.annoacc = q.annoimac
          and a.nacc = q.nimac
          and a.nsubacc = q.nsubimac
          and a.anno_esercizio<>pAnnoEsercizio
          and not exists (select 1 from migr_accertamento imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo_movimento ='S'
              and imp.numero_accertamento=q.nimac
              and imp.numero_subaccertamento=q.nsubimac
              and imp.anno_accertamento=q.annoimac
              and imp.anno_esercizio=pAnnoEsercizio)
          and not exists (select 1 from migr_docquo_entrata_scarto imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo=q.tipofatt
              and imp.anno=q.annofatt
              and imp.numero=q.nfatt
              and imp.codice_soggetto=q.codben
              and imp.frazione=q.frazione
              and imp.tipo_scarto='SAC'))seg
        );
        -- fine 18.12.2015

        --Scarto doc con quote scartate
        msgRes := 'Scarto doc con quote scartate.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;

        Update migr_doc_entrata m
        set m.fl_scarto='S'
        where ente_proprietario_id = pEnte
        and m.fl_migrato = 'N'
        and exists (select 1 from migr_docquo_entrata_scarto s
                    where s.tipo=m.tipo_fonte
                    and s.anno=m.anno
                    and s.numero=m.numero
                    and s.codice_soggetto=m.codice_soggetto
                    and s.ente_proprietario_id=m.ente_proprietario_id);


insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;

        -- SEGNALAZIONI QUOTE NON PAGATE CON ACCERTAMENTO NON MIGRATO E PRESENTE ALLA FONTE PER ANNO <> ANNO ESERCIZIO MIGRATO
        -- L'ACCERTAMENTO NON DEVE ESISTERE PER L'ANNO DI ESERCIZIO MIGRATO (CONTROLLO PRESENZA REC SU TAB. SCARTO PER TIPO_SCARTO='ACC'
        -- 18.12.2015 l'anno della fattura deve essere >= 2014
        msgRes := 'Scarto quote non pagate per accertamento <> '||pAnnoEsercizio||' non migrato.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;


        insert into migr_docquo_entrata_scarto
               (docquo_entrata_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (Select migr_docquo_ent_scarto_id_seq.nextval, seg.tipofatt,seg.annofatt,seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto,seg.tipo_scarto,pEnte
        from
        (Select DISTINCT
         q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
         ,'Accertamento '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' non migrato.Presente alla fonte per anno esercizio <> '||pAnnoEsercizio as motivo_scarto
         ,'AC2' tipo_scarto
          from
          fatquo q
          , migr_doc_entrata f
          , accertamenti a
          where q.eu='E' and q.pagato='N'
          and f.tipo_fonte=q.tipofatt
          and f.anno=q.annofatt
          and f.numero=q.nfatt
          and f.codice_soggetto=q.codben
          and f.ente_proprietario_id=pEnte
          and f.anno >= 2014
          and q.nimac != 0
          and q.nsubimac = 0
          and a.annoacc = q.annoimac
          and a.nacc = q.nimac
          and a.anno_esercizio<>pAnnoEsercizio
          and not exists (select 1 from migr_accertamento imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo_movimento ='A'
              and imp.numero_accertamento=q.nimac
              and imp.numero_subaccertamento=q.nsubimac
              and imp.anno_accertamento=q.annoimac
              and imp.anno_esercizio=pAnnoEsercizio)
          and not exists (select 1 from migr_docquo_entrata_scarto imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo=q.tipofatt
              and imp.anno=q.annofatt
              and imp.numero=q.nfatt
              and imp.codice_soggetto=q.codben
              and imp.frazione=q.frazione
              and imp.tipo_scarto='ACC'))seg
        );


insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;


        -- SEGNALAZIONI QUOTE NON PAGATE CON SUBACCERTAMENTO NON MIGRATO E PRESENTE ALLA FONTE PER ANNO <> ANNO ESERCIZIO MIGRATO
        -- L'ACCERTAMENTO NON DEVE ESISTERE PER L'ANNO DI ESERCIZIO MIGRATO (CONTROLLO PRESENZA REC SU TAB. SCARTO PER TIPO_SCARTO='ACC'
        -- 18.12.2015 l'anno della fattura deve essere >= 2014
        msgRes := 'Scarto quote non pagate per subaccertamento <> '||pAnnoEsercizio||' non migrato.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;

        insert into migr_docquo_entrata_scarto
               (docquo_entrata_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
        (Select migr_docquo_ent_scarto_id_seq.nextval, seg.tipofatt,seg.annofatt,seg.nfatt,seg.codben,seg.frazione,seg.motivo_scarto,seg.tipo_scarto,pEnte
        from
        (Select DISTINCT
         q.tipofatt,q.annofatt, q.nfatt, q.codben, q.frazione
         ,'Subaccertamento '||q.annoimac||'/'||q.nimac||'/'||q.nsubimac||' non migrato.Presente alla fonte per anno esercizio <> '||pAnnoEsercizio as motivo_scarto
         ,'SA2' tipo_scarto
          from
          fatquo q
          , migr_doc_entrata f
          , SUBACC a
          where q.eu='E' and q.pagato='N'
          and f.tipo_fonte=q.tipofatt
          and f.anno=q.annofatt
          and f.numero=q.nfatt
          and f.codice_soggetto=q.codben
          and f.ente_proprietario_id=pEnte
          and f.anno >= 2014
          and q.nimac != 0
          and q.nsubimac != 0
          and a.annoacc = q.annoimac
          and a.nacc = q.nimac
          and a.nsubacc = q.nsubimac
          and a.anno_esercizio<>pAnnoEsercizio
          and not exists (select 1 from migr_accertamento imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo_movimento ='S'
              and imp.numero_accertamento=q.nimac
              and imp.numero_subaccertamento=q.nsubimac
              and imp.anno_accertamento=q.annoimac
              and imp.anno_esercizio=pAnnoEsercizio)
          and not exists (select 1 from migr_docquo_entrata_scarto imp where
              imp.ente_proprietario_id=f.ente_proprietario_id
              and imp.tipo=q.tipofatt
              and imp.anno=q.annofatt
              and imp.numero=q.nfatt
              and imp.codice_soggetto=q.codben
              and imp.frazione=q.frazione
              and imp.tipo_scarto='SAC'))seg
        );

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;


msgRes := 'Migrazione quote entrata.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;

        for migrCursor in
          (Select
             f.docentrata_id
             , q.tipofatt
             , f.tipo
             , q.annofatt
             , q.nfatt
             , q.codben
             , q.frazione
             , 0 as elenco_doc_id
             , 0 codice_soggetto_inc
             , q.impquota
             , q.annoimac
             , q.nimac
             , q.nsubimac
             , 0 as numero_provvedimento
             , q.pagato
             , f.descrizione
             , nvl(q.rilev_iva,'N') rilev_iva
             , f.data_scadenza
             , 'N' flag_ord_singolo
             , 'N' flag_avviso
             , 'N' flag_esproprio
--             , 'N' flag_manuale
             , NULL as flag_manuale -- 28.12.2015 salvato su campo siac_t_subdoc.subdoc_convalida_manuale
             , q.note
             , q.nordin
             , nvl(q.ute_unix_ins,pLoginOperazione) utente_creazione
             , nvl(q.ute_unix_agg,pLoginOperazione) utente_modifica
             , q.anno_esercizio
             from
            fatquo q
            , migr_doc_entrata f
            where q.eu='E'
            and f.tipo_fonte=q.tipofatt
            and f.anno=q.annofatt
            and f.numero=q.nfatt
            and f.codice_soggetto=q.codben
            and f.ente_proprietario_id=pEnte
            and f.fl_scarto='N')
            loop
                codRes := 0;
                msgMotivoScarto := null;
                msgRes := null;
                tipoScarto := null;
                recSegnalato:=0;

                h_note := null;
                h_nimac := 0;
                h_nsubimac := 0;
                h_annoimac := NULL;
                h_nordin := migrCursor.Nordin;

                h_rec := 'Quota  ' || migrCursor.annofatt || '/'||migrCursor.nfatt||' tipo '||migrCursor.tipofatt||
                         ' Soggetto '||migrCursor.Codben||': frazione '||migrCursor.frazione||'.';

                msgRes := 'Verifica importo quota fattura.';
                if migrCursor.Tipofatt='F' and migrCursor.impquota <0 then
                    msgRes          := msgRes|| 'Importo negativo.';
                    msgMotivoScarto := msgRes;
                    codRes := -1;
                    tipoScarto:='FN';-- fattura negativa
                end if;

                /* Dati del provvedimento per ora non trattati
                h_anno_provvedimento := null;
                h_numero_provvedimento :=null;
                h_tipo_provvedimento :=null;
                h_direzione_provvedimento :=null;
                h_oggetto_provvedimento :=null;
                h_stato_provvedimento :=null;
                h_note_provvedimento :=null;
                if codRes = 0 then
                  begin
                    if migrCursor.nimac != 0 and migrCursor.nsubimac = 0 then
                       msgRes := 'Lettura dati Provvedimento dell''ACCERTAMENTO. ';
                       select
                         i.annoprov, i.nprov, i.codprov, i.direzione
                         into h_anno_provvedimento,h_numero_provvedimento,h_tipo_provvedimento,h_direzione_provvedimento
                       from accertamenti i
                         where i.anno_esercizio=pAnnoEsercizio
                         and i.nimp=migrCursor.nimac
                         and i.annoimp=migrCursor.annoimac;
                    elsif migrCursor.nimac != 0 and migrCursor.nsubimac != 0 then
                       msgRes := 'Lettura dati Provvedimento del SUBIMPEGNO. ';
                       select
                         i.annoprov, i.nprov, i.codprov, i.direzione
                         into h_anno_provvedimento,h_numero_provvedimento,h_tipo_provvedimento,h_direzione_provvedimento
                       from subimp i
                         where i.anno_esercizio=pAnnoEsercizio
                         and i.nimp=migrCursor.nimac
                         and i.nsubimp=migrCursor.nsubimac
                         and i.annoimp=migrCursor.annoimac;
                    end if;
                 exception
                    when no_data_found then
                     codRes:=-2;
                     msgRes := msgRes || 'PROVVEDIMENTO non trovato per '||migrCursor.annoimac||'/'||migrCursor.nimac||'/'||migrCursor.nsubimac||' a.e. '||pAnnoEsercizio;
                     msgMotivoScarto := msgRes;
                     tipoScarto:='PRO';
                   when others then
                     codRes:=-1;
                     msgRes := msgRes || h_rec || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                     RAISE ERROR_DOCUMENTO;
                 end;

                     if codRes = 0 and h_numero_provvedimento is not null then
                        msgRes := 'leggi_provvedimento per '||h_anno_provvedimento||'/'||h_numero_provvedimento||'/'||h_tipo_provvedimento||'/'||h_direzione_provvedimento;
                        leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,h_tipo_provvedimento,h_direzione_provvedimento,
                                            pEnte,codRes,msgRes,
                                            h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);

                        if codRes=0 then
                           if h_tipo_provvedimento = PROVV_ATTO_LIQUIDAZIONE then
                             h_tipo_provvedimento := PROVV_ATTO_LIQUIDAZIONE_SIAC;
                           end if;
                           h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                           if migrCursor.codprov = PROVV_DETERMINA_REGP then
                              h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                           else
                              if h_direzione_provvedimento is not null then
                                 h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                              end if;
                           end if;
                        end if;
                        if codRes=0 and h_stato_provvedimento is null then
                           h_stato_provvedimento:=STATO_D;
                        end if;
                     end if;
                end if;*/

                if codRes = 0 then

                  if migrCursor.Pagato='N' then
                     msgRes := 'Verifica presenza quota segnalata.';

                      select count(*) into recSegnalato -- recMigrato
                      from migr_docquo_entrata_scarto m
                      where m.ente_proprietario_id=pEnte
                      and m.tipo=migrCursor.Tipofatt
                      and m.anno=migrCursor.Annofatt
                      and m.numero=migrCursor.Nfatt
                      and m.codice_soggetto=migrCursor.Codben
                      and m.frazione=migrCursor.Frazione
                      and m.tipo_scarto in ('AC2','SA2'); -- segnalazione per impegno e sub presente alla fonte per anno esercizio <> anno esercizio migrato

                      if recSegnalato = 0 then
                        h_nimac := migrCursor.Nimac;
                        h_nsubimac := migrCursor.Nsubimac;
                        h_annoimac := migrCursor.Annoimac;
                      end if;

                  else
                    --fatquo.note
                    --se la quota � pagata impostare prima gli estremi di pagamento
                    -- se nordin!=0 impostare tutta la catena di movimenti da accertamento  a riscossione(nordin)
                    -- se nordin = 0 concatenare dicitura: "QUOTA INCASSATA ESTREMI DI INCASSO MANCANTI"

                    if h_nordin!=0 then
                      if migrCursor.Nsubimac=0 then
                         h_note:='INCASSO N.RISCOS. '||h_nordin||' ACCERTAMENTO '||
                             migrCursor.annoimac||'/'||migrCursor.nimac||'  ANNO '||migrCursor.anno_esercizio||'.';
                      else
                         h_note:='INCASSO N.RISCOS. '||h_nordin||' SUBACCERTAMENTO '||
                             migrCursor.annoimac||'/'||migrCursor.nimac||'/'||migrCursor.Nsubimac||'  ANNO '||migrCursor.anno_esercizio||'.';
                      end if;
                    else
                      h_nordin := 999;
                      h_note := 'QUOTA INCASSATA ESTREMI DI INCASSO MANCANTI.';
                    end if;
                    h_note := h_note || migrCursor.Note;
                  end if;
                end if;

                if codRes = 0 then

                 -- DAVIDE - Conversione dell'importo in Euro
				 -- ricavo la divisa relativa alla quota e converto l'importo
				 -- se necessario
                 begin
                   divisa_esercizio := null;
                   h_Importo_quote := migrCursor.Impquota;

                   select f.divisa_esercizio
                   into divisa_esercizio
                   from fatture f
                   where migrCursor.annofatt=f.annofatt
                   and migrCursor.codben=f.codben
                   and migrCursor.nfatt=f.nfatt
                   and migrCursor.tipofatt=f.tipofatt;

                   if divisa_esercizio = 'L' then
                     h_Importo_quote := migrCursor.Impquota / RAPPORTO_EURO_LIRA;
                   end if;

                 exception
                     when others then
                      h_Importo_quote := migrCursor.Impquota;
                 end;

                 -- DAVIDE - Fine
                 msgRes := 'Inserimento in migr_docquo_entrata.';
                 insert into migr_docquo_entrata
                 (docquoentrata_id,
                  docentrata_id,
                  tipo,
                  tipo_fonte,
                  anno,
                  numero,
                  codice_soggetto,
                  frazione,
                  elenco_doc_id,
                  codice_soggetto_inc,
                  importo,
                  anno_esercizio,
                  anno_accertamento,
                  numero_accertamento,
                  numero_subaccertamento,
 /*                 anno_provvedimento,
                  numero_provvedimento,
                  tipo_provvedimento,
                  sac_provvedimento,
                  oggetto_provvedimento,
                  note_provvedimento,
                  stato_provvedimento,*/
                  descrizione,
                  data_scadenza,
--                  numero_iva,da capire come gestire
                  flag_rilevante_iva,
                  flag_ord_singolo,
                  flag_avviso,
--                  tipo_avviso,non gestito
                  flag_esproprio,
                  flag_manuale,
                  note,
                  numero_riscossione,
                  utente_creazione,
                  utente_modifica,
                  ente_proprietario_id)
                 values
                 (migr_docquo_entrata_id_seq.nextval,
                  migrCursor.Docentrata_Id,
                  migrCursor.Tipo,
                  migrCursor.Tipofatt,
                  migrCursor.Annofatt,
                  migrCursor.Nfatt,
                  migrCursor.Codben,
                  migrCursor.Frazione,
                  migrCursor.Elenco_Doc_Id, -- impostato default 0
                  migrCursor.Codice_Soggetto_Inc, -- impostato default 0
               -- DAVIDE - Conversione dell'importo in Euro
                  --migrCursor.Impquota,
				          h_Importo_quote,
		       	      -- DAVIDE - Fine
                  pAnnoEsercizio,
                  h_annoimac,
                  h_nimac,
                  h_nsubimac,
                  /*h_anno_provvedimento,
                  h_numero_provvedimento,
                  h_tipo_provvedimento,
                  h_direzione_provvedimento,
                  h_oggetto_provvedimento,
                  h_note_provvedimento,
                  h_stato_provvedimento,*/
                  migrCursor.descrizione,
                  migrCursor.data_scadenza,
--                  migrCursor.Niva,da capire come gestire
                  migrCursor.Rilev_Iva,
                  migrCursor.Flag_Ord_Singolo, -- impostato default N
                  migrCursor.Flag_Avviso,-- impostato default N
--                  migrCursor.Tipo_Avviso,non gestito
                  migrCursor.Flag_Esproprio,-- impostato default N
                  migrCursor.Flag_Manuale,-- impostato default NULL
                  h_note,
                  h_nordin,
                  migrCursor.Utente_Creazione,
                  migrCursor.Utente_Modifica,
                  pEnte);
                 cDocInseriti := cDocInseriti + 1;
                else
                 msgRes := 'Inserimento in migr_docquo_entrata_scarto.';
                 insert into migr_docquo_entrata_scarto
                 (docquo_entrata_scarto_id,
                  tipo,
                  anno,
                  numero,
                  codice_soggetto,
                  frazione,
                  motivo_scarto,
                  tipo_scarto,
                  ente_proprietario_id)
                 values
                 (migr_docquo_ent_scarto_id_seq.nextval,
                  migrCursor.tipofatt,
                  migrCursor.Annofatt,
                  migrCursor.Nfatt,
                  migrCursor.Codben,
                  migrCursor.Frazione,
                  msgMotivoScarto,
                  tipoScarto,
                  pEnte);
                end if;

                if numInsert >= N_BLOCCHI_DOC then
                  commit;
                  numInsert := 0;
                else
                  numInsert := numInsert + 1;
                end if;
          end loop;

msgRes := 'Migrazione quote entrata.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;


          msgRes:='Gestione scarti quote documenti entrata-aggiornamento migr_docquo_entrata dopo ciclo.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;

          update migr_docquo_entrata m set m.fl_scarto='S'
          where 0!=(select count(*) from  migr_docquo_entrata_scarto mq
                    where mq.anno=m.anno
                      and mq.numero=m.numero
                      and mq.tipo=m.tipo_fonte
                      and mq.codice_soggetto=m.codice_soggetto
                      and mq.ente_proprietario_id=pEnte
                      and mq.tipo_scarto not in ('AC2','SA2'))-- tipi di segnalazione, il rec. anche se presente deve essere migrato!
          and   m.ente_proprietario_id=pEnte;
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;



          msgRes:='Gestione scarti quote documenti spesa-aggiornamento migr_doc_entrata dopo ciclo.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'begin.',pEnte);
commit;

          update migr_doc_entrata m set m.fl_scarto='S'
          where 0!=(select count(*) from  migr_docquo_entrata_scarto mq
                    where mq.anno=m.anno
                      and mq.numero=m.numero
                      and mq.tipo=m.tipo_fonte
                      and mq.codice_soggetto=m.codice_soggetto
                      and mq.ente_proprietario_id=pEnte
                      and mq.tipo_scarto not in ('AC2','SA2'))-- tipi di segnalazione, il doc deve essere migrato anche con quote segnalate!
          and m.fl_scarto='N'
          and m.ente_proprietario_id=pEnte;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'migrazione_docquo_entrata',msgRes||'end.',pEnte);
commit;

          select count(*) into cDocScartati from migr_docquo_entrata_scarto
                 where ente_proprietario_id = pEnte
                 and tipo_scarto not in ('AC2','SA2');
          select count(*) into cDocSegnalati from migr_docquo_entrata_scarto
                 where ente_proprietario_id = pEnte
                 and tipo_scarto in ('AC2','SA2');
          pMsgRes := pMsgRes || 'Quote migrate '|| cDocInseriti || ' di cui segnalate '||cDocSegnalati||', scartate '|| cDocScartati;
          pCodRes := 0;
          pRecScartati := cDocScartati;
          pRecInseriti := cDocInseriti;

    exception
          when ERROR_DOCUMENTO then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                 msgRes );
            pMsgRes      := pMsgRes || h_rec || msgRes ;
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
          when others then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                msgRes || ' Errore ' || SQLCODE || '-' ||
                                 SUBSTR(SQLERRM, 1, 100));
            pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                              SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
   end migrazione_docquo_entrata;


   procedure get_stato_documento
             (
             doc_eu varchar2,
             doc_codben number,
             doc_annofatt varchar2,
             doc_nfatt varchar2,
             doc_tipofatt varchar2,
             pEnte number,
             pAnnoEsercizio varchar2,
             doc_stato out varchar2,
             pCodRes out number,
             pMsgRes out varchar2)
   is

    nr_quote number  := 0;
    quote_nimp number := 0; -- quote senza movimento
    quote_nimpmigr number := 0; -- quote con movimento non migrato
    quote_nliq number:= 0; -- quote senza liquidazione
    quote_nliqmigr number:= 0; -- quote con liquidazione non migrata
    quote_liq number := 0;
    quote_npag number := 0;
    quote_pag number := 0;

   begin
     pMsgRes := 'Called get_stato_documento.';
     pCodRes := 0;
      -- definizione dello stato del documento
      -- quote per fattura
      select count(*) into nr_quote from fatquo q where
      q.eu=doc_eu
      and q.annofatt=doc_annofatt
      and q.nfatt=doc_nfatt
      and q.codben=doc_codben
      and q.tipofatt=doc_tipofatt;
      -- quote senza dati finanziari
      -- Non avere dati finanziari puo significare: o avere nimac = 0 o avere un impegno/subimpegno non migrato
      select count(*) into quote_nimp from fatquo q where
      q.eu=doc_eu
      and q.annofatt=doc_annofatt
      and q.nfatt=doc_nfatt
      and q.codben=doc_codben
      and q.tipofatt=doc_tipofatt
      and (nimac = 0);

      if doc_eu = 'U' then
        select count(*) into quote_nimpmigr
        from fatquo q
        where
        q.eu=doc_eu
        and q.annofatt=doc_annofatt
        and q.nfatt=doc_nfatt
        and q.codben=doc_codben
        and q.tipofatt=doc_tipofatt
        and q.nimac != 0 -- con movimento
        and q.pagato='N' -- non pagata
        and not exists (select 1 from migr_impegno imp where
                    imp.ente_proprietario_id=pEnte
                    and imp.numero_impegno=q.nimac
                    and imp.numero_subimpegno=q.nsubimac
                    and imp.anno_impegno=q.annoimac
                    --and imp.anno_esercizio=q.annoimac
                    and imp.anno_esercizio=pAnnoEsercizio
                    );

      elsif doc_eu='E' then
        select count(*) into quote_nimpmigr
        from fatquo q
        where
        q.eu=doc_eu
        and q.annofatt=doc_annofatt
        and q.nfatt=doc_nfatt
        and q.codben=doc_codben
        and q.tipofatt=doc_tipofatt
        and q.nimac != 0 -- con movimento
        and q.pagato='N' -- non pagata
        and not exists (select 1 from migr_accertamento imp where
                    imp.ente_proprietario_id=pEnte
                    and imp.numero_accertamento=q.nimac
                    and imp.numero_subaccertamento=q.nsubimac
                    and imp.anno_accertamento=q.annoimac
                    --and imp.anno_esercizio=q.annoimac
                    and imp.anno_esercizio=pAnnoEsercizio
                    );
      end if;
      -- quote NON liquidate
      -- Non avere dati della liquidazione puo significare: o avere nliq = 0 o avere una liquidazione non migrata
      select count(*) into quote_nliq from fatquo q where
      q.eu=doc_eu
      and q.annofatt=doc_annofatt
      and q.nfatt=doc_nfatt
      and q.codben=doc_codben
      and q.tipofatt=doc_tipofatt
      and (nliq = 0);

      select count(*) into quote_nliqmigr from fatquo q where
      q.eu=doc_eu
      and q.annofatt=doc_annofatt
      and q.nfatt=doc_nfatt
      and q.codben=doc_codben
      and q.tipofatt=doc_tipofatt
      and q.nliq != 0
      and q.pagato='N'
      and not exists (select 1 from migr_liquidazione migr
                      where migr.ente_proprietario_id=pEnte
                      and migr.numero_liquidazione=q.nliq
                      and migr.anno_esercizio=q.anno_esercizio);

      -- quote liquidate
      select count(*) into quote_liq from fatquo q where
      q.eu=doc_eu
      and q.annofatt=doc_annofatt
      and q.nfatt=doc_nfatt
      and q.codben=doc_codben
      and q.tipofatt=doc_tipofatt
      and (nliq != 0);
      -- quote NON pagate
      select count(*) into quote_npag from fatquo q where
      q.eu=doc_eu
      and q.annofatt=doc_annofatt
      and q.nfatt=doc_nfatt
      and q.codben=doc_codben
      and q.tipofatt=doc_tipofatt
      and q.pagato='N';
      -- quote pagate
      select count(*) into quote_pag from fatquo q where
      q.eu=doc_eu
      and q.annofatt=doc_annofatt
      and q.nfatt=doc_nfatt
      and q.codben=doc_codben
      and q.tipofatt=doc_tipofatt
      and q.pagato='S';

      if (quote_nimp+quote_nimpmigr) > 0 and quote_liq = 0 then doc_stato := 'I'; end if; -- Almeno una quota senza dati finanziari e nessuna con MDP (ossia liquidazione), Incompleto.
      if (quote_nimp+quote_nimpmigr) = 0 and quote_liq = 0 then doc_stato := 'V'; end if; -- Tutte le quote hanno impegno/accertamento, e nessuna ha liquidazione VALIDO.
      if quote_liq = nr_quote and quote_npag=nr_quote then -- Tutte le quote liquidate e tutte da pagare, Liquidato.
        doc_stato := 'L';
      end if;
      if quote_liq > 0 and (quote_nliq+quote_nliqmigr) > 0 then -- Almeno una quota liquidata, ma esiste almeno una quota con nliq=0, Parzialmente liquidato.
        doc_stato := 'PL';
      end if;
      if quote_pag > 0 and quote_npag > 0 then -- Almeno una quota pagata e almeno una quota con pagato='N', Parzialmente emesso.
        doc_stato := 'PE';
      end if;
      if quote_pag=nr_quote then doc_stato := 'EM'; end if;--Tutte le quote sono pagate, stato EMESSO (serve per poter migrare le relazioni tra documenti)

      if doc_stato is null then
        pMsgRes := pMsgRes || 'Stato non definito.';
        pCodRes := -2; -- Non sono riuscito a definire lo stato appropriato.
      end if;

   exception when others then
      pMsgRes      := pMsgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;
   end get_stato_documento;


    -- Sofia / Davide - 03.11.2016 - calcolo Stato documento a partire dalle quote
    procedure get_stato_documento_migr
             (
             doc_eu varchar2,
             doc_codben number,
             doc_annofatt varchar2,
             doc_nfatt varchar2,
             doc_tipofatt varchar2,
             pEnte number,
             pAnnoEsercizio varchar2,
             doc_stato out varchar2,
             pCodRes out number,
             pMsgRes out varchar2)
   is

    nr_quote number  := 0;
    quote_nimp number := 0; -- quote senza movimento
    quote_nimpmigr number := 0; -- quote con movimento non migrato
    quote_nliq number:= 0; -- quote senza liquidazione
    quote_nliqmigr number:= 0; -- quote con liquidazione non migrata
    quote_liq number := 0;
    quote_npag number := 0;
    quote_pag number := 0;

   begin
     pMsgRes := 'Called get_stato_documento_migr.';
     pCodRes := 0;
      -- definizione dello stato del documento
      if doc_eu = 'U' then
        -- quote per fattura
        select count(*) into nr_quote from migr_docquo_spesa q 
        where q.ente_proprietario_id=pEnte
        and   q.anno=doc_annofatt
        and   q.numero=doc_nfatt
        and   q.codice_soggetto=doc_codben
        and   q.tipo_fonte=doc_tipofatt
        and   q.fl_scarto='N';
      
        -- quote senza dati finanziari
        -- Non avere dati finanziari puo significare: o avere nimac = 0 o avere un impegno/subimpegno non migrato
        select count(*) into quote_nimp from migr_docquo_spesa q 
        where q.ente_proprietario_id=pEnte
        and   q.anno=doc_annofatt
        and   q.numero=doc_nfatt
        and   q.codice_soggetto=doc_codben
        and   q.tipo_fonte=doc_tipofatt
        and   q.numero_impegno = 0
        and   q.fl_scarto='N';

      
        select count(*) into quote_nimpmigr
        from migr_docquo_spesa q
        where q.ente_proprietario_id=pEnte
        and   q.anno=doc_annofatt
        and   q.numero=doc_nfatt
        and   q.codice_soggetto=doc_codben
        and   q.tipo_fonte=doc_tipofatt
        and   q.numero_impegno != 0 -- con movimento
        and   q.numero_mandato=0 -- non pagata
        and   q.fl_scarto='N'
        and not exists (select 1 from migr_impegno imp 
                        where imp.ente_proprietario_id=pEnte
                        and   imp.numero_impegno=q.numero_impegno
                        and   imp.numero_subimpegno=q.numero_subimpegno
                        and   imp.anno_impegno=q.anno_impegno
                        and   imp.anno_esercizio=pAnnoEsercizio
                       );
                       
                       
      -- quote NON liquidate
      -- Non avere dati della liquidazione puo significare: o avere nliq = 0 o avere una liquidazione non migrata
      select count(*) into quote_nliq from migr_docquo_spesa q 
      where q.ente_proprietario_id=pEnte
      and   q.anno=doc_annofatt
      and   q.numero=doc_nfatt
      and   q.codice_soggetto=doc_codben
      and   q.tipo_fonte=doc_tipofatt
      and   q.numero_liquidazione= 0
      and   q.fl_scarto='N';

      select count(*) into quote_nliqmigr from migr_docquo_spesa q 
      where q.ente_proprietario_id=pEnte
      and   q.anno=doc_annofatt
      and   q.numero=doc_nfatt
      and   q.codice_soggetto=doc_codben
      and   q.tipo_fonte=doc_tipofatt
      and   q.numero_liquidazione != 0
      and   q.numero_mandato=0
      and not exists (select 1 from migr_liquidazione migr
                      where migr.ente_proprietario_id=pEnte
                      and   migr.numero_liquidazione=q.numero_liquidazione
                      and   migr.anno_esercizio=q.anno_esercizio);

      -- quote liquidate
      select count(*) into quote_liq from migr_docquo_spesa q 
      where q.ente_proprietario_id=pEnte
      and   q.anno=doc_annofatt
      and   q.numero=doc_nfatt
      and   q.codice_soggetto=doc_codben
      and   q.tipo_fonte=doc_tipofatt
      and   q.numero_liquidazione!=0
      and   q.fl_scarto='N';                       


      -- quote NON pagate
      select count(*) into quote_npag from migr_docquo_spesa q 
      where q.ente_proprietario_id=pEnte
      and   q.anno=doc_annofatt
      and   q.numero=doc_nfatt
      and   q.codice_soggetto=doc_codben
      and   q.tipo_fonte=doc_tipofatt
      and   q.numero_mandato=0
      and   q.fl_scarto='N';
      
      -- quote pagate
      select count(*) into quote_pag from migr_docquo_spesa q 
      where q.ente_proprietario_id=pEnte
      and   q.anno=doc_annofatt
      and   q.numero=doc_nfatt
      and   q.codice_soggetto=doc_codben
      and   q.tipo_fonte=doc_tipofatt
      and   q.numero_mandato!=0
      and   q.fl_scarto='N';

      elsif doc_eu='E' then
        -- quote per fattura
        select count(*) into nr_quote from migr_docquo_entrata q 
        where q.ente_proprietario_id=pEnte
        and   q.anno=doc_annofatt
        and   q.numero=doc_nfatt
        and   q.codice_soggetto=doc_codben
        and   q.tipo_fonte=doc_tipofatt
        and   q.fl_scarto='N';
      
        -- quote senza dati finanziari
        -- Non avere dati finanziari puo significare: o avere nimac = 0 o avere un impegno/subimpegno non migrato
        select count(*) into quote_nimp from migr_docquo_entrata q 
        where q.ente_proprietario_id=pEnte
        and   q.anno=doc_annofatt
        and   q.numero=doc_nfatt
        and   q.codice_soggetto=doc_codben
        and   q.tipo_fonte=doc_tipofatt
        and   q.numero_accertamento = 0
        and   q.fl_scarto='N';
        
        select count(*) into quote_nimpmigr
        from migr_docquo_entrata q
        where q.ente_proprietario_id=pEnte
        and   q.anno=doc_annofatt
        and   q.numero=doc_nfatt
        and   q.codice_soggetto=doc_codben
        and   q.tipo_fonte=doc_tipofatt
        and   q.numero_accertamento != 0 -- con movimento
        and   q.numero_riscossione=0 -- non pagata
        and   not exists (select 1 from migr_accertamento imp 
                          where imp.ente_proprietario_id=pEnte
                          and   imp.numero_accertamento=q.numero_accertamento
                          and   imp.numero_subaccertamento=q.numero_subaccertamento
                          and   imp.anno_accertamento=q.anno_accertamento
                          and   imp.anno_esercizio=pAnnoEsercizio
                         );
                         
        -- quote NON pagate
        select count(*) into quote_npag from migr_docquo_entrata q 
        where q.ente_proprietario_id=pEnte
        and   q.anno=doc_annofatt
        and   q.numero=doc_nfatt
        and   q.codice_soggetto=doc_codben
        and   q.tipo_fonte=doc_tipofatt
        and   q.numero_riscossione=0
        and   q.fl_scarto='N';
      
        -- quote pagate
        select count(*) into quote_pag from migr_docquo_entrata q 
        where q.ente_proprietario_id=pEnte
        and   q.anno=doc_annofatt
        and   q.numero=doc_nfatt
        and   q.codice_soggetto=doc_codben
        and   q.tipo_fonte=doc_tipofatt
        and   q.numero_riscossione!=0
        and   q.fl_scarto='N';
                         
      end if;
      

      if (quote_nimp+quote_nimpmigr) > 0 and quote_liq = 0 then doc_stato := 'I'; end if; -- Almeno una quota senza dati finanziari e nessuna con MDP (ossia liquidazione), Incompleto.
      if (quote_nimp+quote_nimpmigr) = 0 and quote_liq = 0 then doc_stato := 'V'; end if; -- Tutte le quote hanno impegno/accertamento, e nessuna ha liquidazione VALIDO.
      if quote_liq = nr_quote and quote_npag=nr_quote then -- Tutte le quote liquidate e tutte da pagare, Liquidato.
        doc_stato := 'L';
      end if;
      if quote_liq > 0 and (quote_nliq+quote_nliqmigr) > 0 then -- Almeno una quota liquidata, ma esiste almeno una quota con nliq=0, Parzialmente liquidato.
        doc_stato := 'PL';
      end if;
      if quote_pag > 0 and quote_npag > 0 then -- Almeno una quota pagata e almeno una quota con pagato='N', Parzialmente emesso.
        doc_stato := 'PE';
      end if;
      if quote_pag=nr_quote then doc_stato := 'EM'; end if;--Tutte le quote sono pagate, stato EMESSO (serve per poter migrare le relazioni tra documenti)

      if doc_stato is null then
        pMsgRes := pMsgRes || 'Stato non definito.';
        pCodRes := -2; -- Non sono riuscito a definire lo stato appropriato.
      end if;

   exception when others then
      pMsgRes      := pMsgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;
   end get_stato_documento_migr;
   
procedure aggiorna_stati_documenti(doc_eu         varchar2,
                                   pEnte          number,                                   
                                   pAnnoEsercizio varchar2,
                                   pCodRes        out number,
                                   pMsgRes        out varchar2)  IS
 codRes number := 0;
 msgRes  varchar2(1500) := null;
 h_stato varchar2(15):=null;

 
begin
    if doc_eu = 'U' then
        msgRes:='Aggiornamento stati doc. spesa.';
        for migrRec in
            (select *  
		       from migr_doc_spesa doc
              where doc.ente_proprietario_id=pEnte
   		        and doc.fl_scarto='N'
              order by doc.docspesa_id) loop   

            get_stato_documento_migr (doc_eu, migrRec.codice_soggetto, migrRec.anno, migrRec.numero, 
			                          migrRec.tipo_fonte, pEnte, pAnnoEsercizio, h_stato, codRes, msgRes);

            if h_stato!= migrRec.stato then
                update migr_doc_spesa migr 
		           set stato=h_stato
                 where migr.docspesa_id=migrRec.docspesa_id;
                 
            commit; -- sofia     
            end if;
        end loop;

	elsif doc_eu = 'E' then
        msgRes:='Aggiornamento stati doc. entrata.';
        for migrRec in
            (select *  
		       from migr_doc_entrata doc
              where doc.ente_proprietario_id=pEnte
   		        and doc.fl_scarto='N'
              order by doc.docentrata_id) loop   

            get_stato_documento_migr (doc_eu, migrRec.codice_soggetto, migrRec.anno, migrRec.numero, 
			                          migrRec.tipo_fonte, pEnte, pAnnoEsercizio, h_stato, codRes, msgRes);

            if h_stato!= migrRec.stato then
                update migr_doc_entrata migr 
		           set stato=h_stato
                 where migr.docentrata_id=migrRec.docentrata_id;
               commit; -- sofia     
            end if;
        end loop;
	end if;


  pMsgRes:=msgRes||'Operazione conclusa.';
  
exception when others then
      pMsgRes      := pMsgRes || 'Errore in aggiorna_stati_documenti' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;
end aggiorna_stati_documenti;

      -- Sofia / Davide - 03.11.2016 - Fine

procedure migrazione_relaz_documenti(pEnte number,
                                     pCodRes out number,
                                     pMsgRes out varchar2)  IS
        codRes number := 0;
        msgRes  varchar2(1500) := null;

      begin

        msgRes := 'Inizio migrazione relazioni documenti.';
        begin
            msgRes := 'Pulizia tabelle di migrazione relazione documenti.';
            DELETE FROM migr_relaz_documenti WHERE FL_MIGRATO = 'N'  and ente_proprietario_id=pEnte;
            commit;

            exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               return;
        end;

        msgRes := 'Inizio migrazione relazioni documenti tipo='||RELAZ_TIPO_NCD||'.';
        insert into migr_relaz_documenti
        (relazdoc_id,
         relaz_tipo,
         doc_id_da,
         tipo_da,
         anno_da,
         numero_da,
         codice_soggetto_da,
         doc_id_a,
         tipo_a,
         anno_a,
         numero_a,
         codice_soggetto_a,
         ente_proprietario_id)
        (select migr_relazdoc_id_seq.nextval,
                RELAZ_TIPO_NCD,
                fat.docspesa_id,
                fat.tipo,
                fat.anno,
                fat.numero,
                fat.codice_soggetto,
                ncd.docspesa_id,
                ncd.tipo,
                ncd.anno,
                ncd.numero,
                ncd.codice_soggetto,
                pEnte
          from migr_doc_spesa ncd, migr_doc_spesa fat
          where ncd.tiporif is not null and ncd.ente_proprietario_id=pEnte
          and fat.tipo_fonte=ncd.tiporif
          and fat.anno=ncd.annorif
          and fat.numero=ncd.numerorif
          and fat.codice_soggetto=ncd.codice_soggetto
          and fat.ente_proprietario_id=ncd.ente_proprietario_id
          and fat.fl_scarto='N' and ncd.fl_scarto='N');

        commit;

        pCodRes := 0;
        pMsgRes := 'Elaborazione OK.Relazioni documenti migrate.';
  exception
    when others then
      pMsgRes      :=  msgRes || 'Errore ' ||
                       SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;
      rollback;
 END migrazione_relaz_documenti;

 procedure migrazione_atto_allegato(pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pMsgRes out varchar2)  IS
    codRes number := 0;
    msgRes  varchar2(1500) := null;

    h_docSpesa_id number(10) :=0;
    h_frazione number(5) :=0;

    begin

        msgRes := 'Inizio migrazione atto_allegato semplice.';

        begin
           msgRes := 'Pulizia tabelle di migrazione atto_allegato.';
          insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,msgRes||'begin.',pEnte);
          commit;

          -- 15.09.2015 codice della procedura migrazione_elenco_atto_allegato
           UPDATE migr_docquo_spesa quo set quo.elenco_doc_id = 0 WHERE elenco_doc_id <> 0 and ente_proprietario_id = pEnte and FL_MIGRATO = 'N'
           and elenco_doc_id in (select el.elenco_doc_id from migr_elenco_doc_allegati el, migr_atto_allegato aa
                                where el.ente_proprietario_id=pEnte and el.ente_proprietario_id=aa.ente_proprietario_id
                                and el.atto_allegato_id=aa.atto_allegato_id
                                and el.fl_migrato='N' and aa.fl_daelenco='N');

           -- cancellare anche i doc fittizi e relative quote create.
           DELETE FROM migr_docquo_spesa quo WHERE fl_migrato='N' and ente_proprietario_id  = pEnte
           and quo.docspesa_id in (select doc.docspesa_id from migr_doc_spesa doc, migr_atto_allegato aa
                                   where doc.fl_migrato='N' and doc.ente_proprietario_id  = pEnte and doc.fl_fittizio='S'
                                   and doc.atto_allegato_id=aa.atto_allegato_id
                                   and aa.fl_daelenco='N' and aa.ente_proprietario_id=pEnte);

           DELETE FROM migr_doc_spesa doc WHERE doc.fl_migrato='N' and doc.ente_proprietario_id  = pEnte and doc.fl_fittizio='S'
           and doc.atto_allegato_id in (select atto_allegato_id from migr_atto_allegato aa
                                   where aa.fl_migrato='N' and fl_daelenco = 'N' and ente_proprietario_id = pEnte);

           DELETE FROM migr_elenco_doc_allegati WHERE FL_MIGRATO = 'N' and ente_proprietario_id=pEnte
           and atto_allegato_id in (select atto_allegato_id from migr_atto_allegato aa where aa.ente_proprietario_id = pEnte and aa.fl_daelenco='N');

          -- 15.09.2015  fine

           DELETE FROM migr_atto_allegato_sog WHERE FL_MIGRATO = 'N' and ente_proprietario_id=pEnte
             and atto_allegato_id in (select atto_allegato_id from migr_atto_allegato WHERE FL_MIGRATO = 'N' and fl_daelenco = 'N' and ente_proprietario_id=pEnte);

           DELETE FROM migr_atto_allegato WHERE FL_MIGRATO = 'N' and fl_daelenco = 'N' and ente_proprietario_id=pEnte;

-- non so ancora se farlo o no...
--           update migr_elenco_doc_allegati set atto_allegato_id=0
--           where  fl_migrato='N' and atto_allegato_id!=0 and ente_proprietario_id=pEnte;

          insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,msgRes||'end.',pEnte);
          commit;

           exception
             when others then
                  rollback;
                  pCodRes := -1;
                  pMsgRes := msgRes || 'Errore ' ||
                          SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
             return;
        end;

        msgRes := 'Inserimento tabella migrazione atto_allegato.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'begin.',pEnte);
        commit;

        insert into migr_atto_allegato
          ( atto_allegato_id,
            tipo_provvedimento,
            anno_provvedimento,
            numero_provvedimento_calcolato,
            numero_provvedimento,
            sac_provvedimento,
            settore,
            causale,
--            annotazioni varchar2(500) null, non usato
            note,
            pratica,
            numero_titolario,
            anno_titolario,
            responsabile_amm,
            responsabile_cont,
            altri_allegati,
            dati_sensibili,
            data_scadenza,
            causale_sospensione,
            data_sospensione,
            data_riattivazione,
            versione,
            codice_soggetto, -- informazione utilizzata pre creare la relazione soggetto/allegato atto
            stato, -- default COMPLETATO
            data_completamento,
            utente_creazione,
            ente_proprietario_id,
            fl_daelenco,
			attoal_flag_ritenute)           -- DAVIDE - 04.01.2017 - aggiunta decodifica flag_ritenute - mail Ivano Giachino 27 dicembre 2016
        (select
         migr_atto_allegato_id_seq.nextval
--         ,PROVV_ATTO_LIQUIDAZIONE_SIAC tipo_provvedimento
         ,PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K' tipo_provvedimento
         ,aa.anno_provvedimento
         ,aa.numero_provvedimento --numero_provvedimento_calcolato
         ,aa.numero_provvedimento
--         ,aa.sac_provvedimento
         ,aa.sac_provvedimento||'||K'
         ,aa.settore
         ,aa.causale
         ,aa.note
         ,aa.pratica
         ,aa.numero_titolario
         ,aa.anno_titolario
         ,aa.responsabile_amm
         ,aa.responsabile_cont
         ,aa.altri_allegati
         ,aa.dati_sensibili
         ,aa.data_scadenza
         ,aa.causale_sospensione
         ,aa.data_sospensione
         ,aa.data_riattivazione
         ,aa.versione
         ,aa.codice_soggetto
         ,aa.stato
         ,aa.data_completamento
         ,pLoginOperazione
         ,pEnte
         ,'N'
		 ,aa.attoal_flag_ritenute      -- DAVIDE - 04.01.2017 - aggiunta decodifica flag_ritenute - mail Ivano Giachino 27 dicembre 2016
         from
         (select distinct
               PROVV_ATTO_LIQUIDAZIONE_SIAC tipo_provvedimento
               , att.annoprov anno_provvedimento
               , att.nprov numero_provvedimento
               , att.direzione sac_provvedimento
               , att.settore
               ,nvl(att.causale_pagam,PROVV_ATTO_LIQUIDAZIONE_SIAC||'\'||att.annoprov||'\'||att.nprov||'\'||att.direzione) causale
               ,att.direzione||'_'||att.settore||'_'||att.annoprov||'_'||att.nprov||'_AL'||'.'||nvl(att.note,'') as note
               ,att.num_pratica pratica
               ,att.cod_titolario numero_titolario
               ,att.anno_titolario anno_titolario
               ,att.dirett_dirig_resp responsabile_amm
               ,att.funz_liq responsabile_cont
			   -- DAVIDE - 04.01.2017
               , decode (att.fl_fatture,'S','Altri Allegati: '
                        , decode(att.fl_dichiaraz,'S','Altri Allegati: '
                           , decode(att.fl_doc_giustif,'S','Altri Allegati: '
                           , decode(att.fl_estr_copia_prov,'S','Altri Allegati: '
                           , decode(att.fl_altro,'S','Altri Allegati: ','')))))
                  ||decode (att.fl_fatture,'S','Fatture. ','')
                  ||decode (att.fl_dichiaraz,'S','Dichiarazione. ','')
                  ||decode (att.fl_doc_giustif,'S','Estratto copia. ','')
                  ||decode (att.fl_altro,'S','Altro. ','') as altri_allegati
			   -- DAVIDE - 04.01.2017
               ,nvl(att.fl_dati_sens,'N') dati_sensibili
               ,to_char(att.datascad,'yyyy-MM-dd') as data_scadenza
               ,att.causale_sosp causale_sospensione
               ,to_char(att.datasosp_pag,'yyyy-MM-dd')data_sospensione
               ,to_char(att.datariat_pag,'yyyy-MM-dd')data_riattivazione
               ,att.versione
               ,migr.codice_soggetto --!!!! Prestare attenzione ai controlli fatti su questo campo.
               ,STATO_AA_C stato
               ,to_char(att.data_complet,'yyyy-MM-dd') as data_completamento
               ,decode(attliq.tipo_soggetto, null, 'N', decode(attliqalt.importo_iva,0,'N','S')) as attoal_flag_ritenute -- DAVIDE - 04.01.2017 - aggiunta decodifica flag_ritenute - mail Ivano Giachino 27 dicembre 2016            
			from migr_liquidazione migr,w_liquid_atti_migr att,			
            atti_liquid attliq,                           -- DAVIDE - 04.01.2017
            atti_liquid_altri_dati attliqalt              -- DAVIDE - 04.01.2017
            where
            att.nelenco=0
            and att.anno_esercizio=migr.anno_esercizio
            and att.nliq=migr.numero_liquidazione			
            and att.annoprov=attliq.annoprov(+)           -- DAVIDE - 04.01.2017
            and att.nprov=attliq.nprov(+)                 -- DAVIDE - 04.01.2017
            and att.direzione=attliq.direzione(+)         -- DAVIDE - 04.01.2017
            and att.annoprov=attliqalt.annoprov(+)        -- DAVIDE - 04.01.2017
            and att.nprov=attliqalt.nprov(+)              -- DAVIDE - 04.01.2017
            and att.direzione=attliqalt.direzione(+)      -- DAVIDE - 04.01.2017
            and migr.tipo_provvedimento like PROVV_ATTO_LIQUIDAZIONE_SIAC||'%'
            and migr.ente_proprietario_id = pEnte)aa
        );
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
        commit;


        msgRes := 'Verifica ed eventualmente scarto di atti allegati doppi per codice soggetto differenti.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;

        for aaDoppi in
            (select aa2.tipo_provvedimento, aa2.anno_provvedimento, aa2.numero_provvedimento, aa2.sac_provvedimento
             from migr_atto_allegato aa2
             where ente_proprietario_id = pEnte and aa2.fl_migrato ='N' and aa2.fl_daelenco = 'N'
             group by aa2.tipo_provvedimento, aa2.anno_provvedimento, aa2.numero_provvedimento, aa2.sac_provvedimento
             having count(*)>1)
        loop
            update migr_atto_allegato a
            set fl_scarto = 'S'
            where a.anno_provvedimento=aaDoppi.anno_provvedimento
            and a.numero_provvedimento=aaDoppi.numero_provvedimento
            and a.tipo_provvedimento=aaDoppi.Tipo_Provvedimento
            and a.sac_provvedimento=aaDoppi.sac_provvedimento
            and a.ente_proprietario_id=pEnte
            and a.fl_migrato='N' and a.fl_daelenco='N';
        end loop;

        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
        commit;

        -- Inserimento Relazione Soggetto / Allegato Atto
        -- Le Liquidazioni che riferiscono ad un atto di liquidazione hanno il medesimo soggetto. Verificare che questo si verifichi anche sui dati
        -- delle liquidazioni migrate. L'atto di liquidazione semplice (non in elenco) � legato ad un SOLO soggetto (distinct anche sul codice_soggetto)

        msgRes := 'Inserimento tabella migrazione relazione atto_allegato / soggetto.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;

        insert into migr_atto_allegato_sog
         (atto_allegato_sog_id ,
          atto_allegato_id     ,
          codice_soggetto      ,
          causale_sospensione  ,
          data_sospensione     ,
          data_riattivazione   ,
          ente_proprietario_id)
        (select
          migr_atto_allegato_sog_id_seq.nextval
          ,aa.atto_allegato_id
          ,aa.codice_soggetto
          ,aa.causale_sospensione
          ,aa.data_sospensione
          ,aa.data_riattivazione
          ,pEnte
          from migr_atto_allegato aa
          where aa.codice_soggetto is not null --creo relazioni solo per atti allegati semplici)
          and aa.ente_proprietario_id = pEnte
          and aa.fl_scarto = 'N' and aa.fl_daelenco='N');

      msgRes := 'Inserimento tabella migrazione relazione atto_allegato / soggetto.';
      insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
      values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
      commit;

      -- 15.09.2015 codice procedura migrazione_elenco_doc_allegati
        msgRes := 'Creazione elenco doc allegati per liquidazioni legate a fattura.';
           insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'begin.',pEnte);
           commit;

            insert into migr_elenco_doc_allegati
            ( elenco_doc_id,
              atto_allegato_id,
              anno_elenco,
              numero_elenco,
              stato,
--              data_trasmissione    VARCHAR2(10),
              tipo_provvedimento,
              anno_provvedimento,
              numero_provvedimento,
              sac_provvedimento,
              migr_tipo_elenco,
              ente_proprietario_id)
          (select
              migr_elenco_doc_id_seq.nextval
              ,el1.Atto_Allegato_Id
              ,el1.anno_elenco
              ,el1.numero_elenco
              ,el1.stato
              ,el1.Tipo_Provvedimento
              ,el1.Anno_Provvedimento
              ,el1.Numero_Provvedimento
              ,el1.Sac_Provvedimento
              ,el1.migr_tipo_elenco
              ,pEnte
          from
          (select distinct migrAA.Atto_Allegato_Id , pAnnoEsercizio anno_elenco,0 numero_elenco,STATO_ELENCO_DOC_C stato,
                 migrAA.Tipo_Provvedimento,migrAA.Anno_Provvedimento,migrAA.Numero_Provvedimento,migrAA.Sac_Provvedimento,1 migr_tipo_elenco
           from migr_atto_allegato migrAA, migr_liquidazione migrLiq, migr_docquo_spesa migrDocQuo
           where  migrAA.Ente_Proprietario_Id=pEnte
                 and migrAA.Fl_Migrato='N'
                 and migrAA.Fl_Scarto='N'
                 and migrAA.fl_daelenco = 'N'
                 and migrLiq.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K'
                 and migrLiq.anno_provvedimento=migrAA.Anno_Provvedimento
                 and migrLiq.numero_provvedimento=migrAA.Numero_Provvedimento
--                 and migrLiq.sac_provvedimento=migrAA.Sac_Provvedimento||'||'
                 and migrLiq.sac_provvedimento=migrAA.Sac_Provvedimento
                 and migrLiq.ente_proprietario_id = migrAA.Ente_Proprietario_Id
                 and migrDocQuo.anno_esercizio=migrLiq.anno_esercizio
                 and migrDocQuo.numero_liquidazione=migrLiq.numero_liquidazione
                 and migrDocQuo.Ente_Proprietario_Id=migrLiq.Ente_Proprietario_Id
                 and migrLiq.anno_esercizio !='0000'-- condizione che forza l'uso dell'indice XIFMIGR_DOCQUO_SPESA_LIQ sulla tabella migr_docquo_spesa
                 ) el1);

           insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,msgRes||'end.',pEnte);

        commit;

        dbms_output.put_line ('FINE.'||msgRes|| sysdate);


        msgRes := 'Creazione elenco doc allegati per liquidazioni non legate a fattura.';
           insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'begin.',pEnte);
commit;
            insert into migr_elenco_doc_allegati
            ( elenco_doc_id,
              atto_allegato_id,
              anno_elenco,
              numero_elenco,
              stato,
--              data_trasmissione    VARCHAR2(10),
              tipo_provvedimento,
              anno_provvedimento,
              numero_provvedimento,
              sac_provvedimento,
              migr_tipo_elenco,
              ente_proprietario_id)
          (select
              migr_elenco_doc_id_seq.nextval
              ,el2.Atto_Allegato_Id
              ,el2.anno_elenco
              ,el2.numero_elenco
              ,el2.stato
              ,el2.Tipo_Provvedimento
              ,el2.Anno_Provvedimento
              ,el2.Numero_Provvedimento
              ,el2.Sac_Provvedimento
              ,el2.migr_tipo_elenco
              ,pEnte
          from
          (select distinct migrAA.Atto_Allegato_Id , pAnnoEsercizio anno_elenco, 0 numero_elenco,STATO_ELENCO_DOC_C stato,
                 migrAA.Tipo_Provvedimento,migrAA.Anno_Provvedimento,migrAA.Numero_Provvedimento,migrAA.Sac_Provvedimento,2 migr_tipo_elenco
           from migr_atto_allegato migrAA, migr_liquidazione migrLiq, migr_docquo_spesa migrDocQuo
            where  migrAA.Ente_Proprietario_Id=pEnte
             and migrAA.Fl_Migrato='N'
             and migrAA.Fl_Scarto='N'
             and migrAA.fl_daelenco = 'N'
             and migrLiq.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K'
             and migrLiq.anno_provvedimento=migrAA.Anno_Provvedimento
             and migrLiq.numero_provvedimento=migrAA.Numero_Provvedimento
--             and migrLiq.sac_provvedimento=migrAA.Sac_Provvedimento||'||'
             and migrLiq.sac_provvedimento=migrAA.Sac_Provvedimento
             and migrLiq.ente_proprietario_id = migrAA.Ente_Proprietario_Id
             and migrDocQuo.anno_esercizio(+)=migrLiq.anno_esercizio
             and migrDocQuo.numero_liquidazione(+)=migrLiq.numero_liquidazione
             and migrDocQuo.Ente_Proprietario_Id(+)=migrLiq.Ente_Proprietario_Id
             and migrDocQuo.Docquospesa_Id is null)el2);

           insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'end.',pEnte);

           commit;

           -- Aggiornare lo stato degli allegati atto che non hanno elenchi di tipo 2 ma solo di tipo 1
           -- Dipende dallo stato degli elenchi associati all'allegato.
           -- D � Da completare, se esistono elenchi di documenti collegati in stato  B (elenco che raggruppa liquidazioni senza fattura, tipo_elenco = 2)
           -- C � Completato, se tutti gli elenchi di documenti collegati sono in stato C (elenco che raggruppa liquidazioni associati a fattura, tipo 1)
           -- Lo stato di partenza � D
           /* 18.09.2015 update non necessario, l'atto e gli elenchi sono creati in stato C - completato
           msgRes := 'Aggiornamento stato COMPLETATO per Allegato atto.';
           insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'begin.',pEnte);commit;

           update migr_atto_allegato aa
                  set aa.stato = STATO_AA_C
           where aa.ente_proprietario_id=pEnte
           and aa.fl_daelenco='N'
           and aa.fl_migrato='N'
           and not exists (select 1 from migr_elenco_doc_allegati el
                           where el.atto_allegato_id = aa.atto_allegato_id
                           and el.migr_tipo_elenco = 2
                           and el.ente_proprietario_id=pEnte );


           insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'end.',pEnte);

           commit;*/

           msgRes := 'Valorizzazione elenco_doc_id per quote con liquidazione.';

           insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'begin.',pEnte);commit;


            update migr_docquo_spesa quo
            set quo.elenco_doc_id =
                      (select el.elenco_doc_id from
                        migr_elenco_doc_allegati el,
                        migr_atto_allegato aa,
                        migr_liquidazione liq
                        where el.ente_proprietario_id=pEnte
                        and el.atto_allegato_id = aa.atto_allegato_id
                        and aa.fl_daelenco='N'
                        and el.anno_provvedimento=liq.anno_provvedimento
                        and el.numero_provvedimento=liq.numero_provvedimento
                        and el.migr_tipo_elenco=1   -- DAVIDE - 20.10/2016 - elenco id legato a fattura
--                        and el.tipo_provvedimento||'||K'=liq.tipo_provvedimento
--                        and el.sac_provvedimento||'||'=liq.sac_provvedimento
                        and el.tipo_provvedimento=liq.tipo_provvedimento
                        and el.sac_provvedimento=liq.sac_provvedimento
                        and el.ente_proprietario_id=liq.ente_proprietario_id
                        and quo.anno_esercizio = liq.anno_esercizio
                        and quo.numero_liquidazione=liq.numero_liquidazione
                        and quo.ente_proprietario_id=liq.ente_proprietario_id
                        and liq.anno_esercizio !='0000'-- condizione che forza l'uso dell'indice XIFMIGR_DOCQUO_SPESA_LIQ sulla tabella migr_docquo_spesa
                        )
            where quo.ente_proprietario_id=pEnte
            and exists (select 1 from migr_elenco_doc_allegati el,migr_atto_allegato aa,
                        migr_liquidazione liq
                        where
                        el.ente_proprietario_id=pEnte
                        and el.atto_allegato_id=aa.atto_allegato_id
                        and aa.fl_daelenco='N'
                        and el.anno_provvedimento=liq.anno_provvedimento
                        and el.numero_provvedimento=liq.numero_provvedimento
                        and el.migr_tipo_elenco=1 -- DAVIDE - 20.10/2016 - elenco id legato a fattura
--                        and el.tipo_provvedimento||'||K'=liq.tipo_provvedimento
--                        and el.sac_provvedimento||'||'=liq.sac_provvedimento
                        and el.tipo_provvedimento=liq.tipo_provvedimento
                        and el.sac_provvedimento=liq.sac_provvedimento
                        and el.ente_proprietario_id=liq.ente_proprietario_id
                        and quo.anno_esercizio = liq.anno_esercizio
                        and quo.numero_liquidazione=liq.numero_liquidazione
                        and quo.ente_proprietario_id=liq.ente_proprietario_id
                        and liq.anno_esercizio !='0000'-- condizione che forza l'uso dell'indice XIFMIGR_DOCQUO_SPESA_LIQ sulla tabella migr_docquo_spesa
                        );
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'end.',pEnte);
commit;


             msgRes := 'Creazione doc fittizio per elenco atto non legato a liquidazioni.';
           insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'begin.',pEnte);commit;

              insert into migr_doc_spesa
              (docspesa_id,-- sequence
               tipo, -- costante
               tipo_fonte,-- costante
               anno,-- anno di bilancio, di migrazione
               numero,-- composto con dati di atto allegato e elenco doc allegati
               codice_soggetto, -- quello dell'atto allegato
               codice_soggetto_pag, --> 0
               stato,    --> costante, L
               descrizione, -- causale atto allegato
               date_emissione, -- sysdate troncata alla data
               termine_pagamento, -- 0
               importo, -- totale delle quote, quindi liquid, inizialmente 0 modificare dopo
               arrotondamento, -- 0
--               codice_pcc, --  per ora NON GESTITO
               codice_ufficio, -- NULL
               data_ricezione, --NULL
               data_repertorio,--NULL
               numero_repertorio, -- 0, valore di default
               causale_sospensione, --NULL
               data_sospensione, -- NULL
               data_riattivazione, -- NULL
               data_registro_fatt, -- NULL
               numero_registro_fatt, -- 0, valore di deafult
               anno_registro_fatt, -- NULL
               utente_creazione, -- utente di migrazione
               utente_modifica, -- utente di migrazione
               ente_proprietario_id,
               fl_fittizio,
               atto_allegato_id, -- atto allegato dell'elenco
               elenco_doc_id -- nr elenco
               )
               (SELECT
                 migr_doc_spesa_id_seq.nextval
                 ,PROVV_ATTO_LIQUIDAZIONE_SIAC
                 ,PROVV_ATTO_LIQUIDAZIONE_SIAC
                 ,pAnnoEsercizio
--                 ,aa.Anno_Provvedimento||'\'||aa.Numero_Provvedimento||'\'||aa.Tipo_Provvedimento||'\'||aa.Sac_Provvedimento||'\'||el.Numero_Elenco||'\1'
                 ,aa.Anno_Provvedimento||'\'||aa.Numero_Provvedimento||'\'||PROVV_ATTO_LIQUIDAZIONE_SIAC||'\'||replace(aa.Sac_Provvedimento,'||K','')||'\'||aa.codice_soggetto||'\M' numero
                 ,aa.codice_soggetto -- codice_soggetto
                 ,0 as codice_soggetto_pag
                 ,STATO_DOC_L
                 ,aa.causale -- descrizione
                 ,to_char(sysdate,'YYYY-MM-DD') -- data_emissione
                 ,0 as termine_pagamento
                 ,0 as importo --fare update successivamente
                 ,0 as arrotondamento
              -- ,codice_pcc per ora non gestito
                 ,NULL codice_ufficio
                 ,NULL as data_ricezione
                 ,NULL as data_repertorio
                 ,0 as numero_repertorio
                 ,NULL as causale_sospensione
                 ,NULL as data_sospensione
                 ,NULL as data_riattivazione
                 ,NULL as data_registro_fatt
                 ,0 as numero_registro_fatt
                 ,NULL as anno_registro_fatt
                 ,pLoginOperazione as utente_creazione
                 ,pLoginOperazione as utente_modifica
                 ,pEnte as ente_proprietario_id
                 ,'S' -- fl_fittizio
                 ,aa.atto_allegato_id
                 ,el.elenco_doc_id
                 from migr_elenco_doc_allegati el, migr_atto_allegato aa
                 where el.migr_tipo_elenco = 2 -- elenco creato per atti liquidazione con liquidazioni senza fattura
                 and el.ente_proprietario_id = pEnte
                 and el.atto_allegato_id = aa.atto_allegato_id
                 and aa.fl_migrato = 'N'
                 and aa.fl_daelenco = 'N');

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'end.',pEnte);
commit;

             msgRes := 'Creazione quote spesa per doc fittizi.';

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'begin.',pEnte);
commit;

           -- inserimento delle quote di spesa per i doc fittizzi (con atto_allegato_id valorizzato e che trova corrispondenza sulla migr_atto_allegato)
                 insert into migr_docquo_spesa
                 (docquospesa_id,
                  docspesa_id,
                  tipo,
                  tipo_fonte,
                  anno,
                  numero,
                  codice_soggetto,
                  frazione,
                  elenco_doc_id,
                  codice_soggetto_pag, -- valore di default 0
                  codice_modpag,
                  codice_modpag_del, -- valore di default 0
                  codice_indirizzo,-- valore di default 0
                  sede_secondaria,
                  importo,
                  importo_da_dedurre,--valore di default 0
                  anno_esercizio,
                  anno_impegno,
                  numero_impegno,
                  numero_subimpegno,
                  anno_provvedimento,
                  numero_provvedimento,
                  tipo_provvedimento,
                  sac_provvedimento,
                  oggetto_provvedimento,
                  note_provvedimento,
                  stato_provvedimento,
                  descrizione,
                  --numero_iva, da verificare come trattare
                  flag_rilevante_iva,
                  data_scadenza,
                  --data_scadenza_new, --NULL non gestito
                  cup,
                  cig,
                  commissioni,-- ES valore di default
                  causale_sospensione,
                  data_sospensione,
                  data_riattivazione,
                  flag_ord_singolo, -- valore di default N
                  flag_avviso, -- valore di default N
                  --tipo_avviso, NULL non gestito
                  flag_esproprio, -- valore di default N
                  flag_manuale, -- valore di default NULL
                  note,
                  causale_ordinativo,
                  numero_mutuo, -- valore di default 0
                  --annotazione_certif_crediti,
                  --data_certif_crediti, NULL non gestito
                  --note_certif_crediti, NULL non gestito
                  --numero_certif_crediti, NULL non gestito
                  flag_certif_crediti, --valore di default 0
                  numero_liquidazione,
                  numero_mandato,
                  anno_elenco,
                  numero_elenco,
                  utente_creazione,
                  utente_modifica,
                  ente_proprietario_id,
				  sede_id)    -- DAVIDE - 14.07.2016 - aggiunta sede_id
          (select
             migr_docquo_spesa_id_seq.nextval
             , doc.docspesa_id
             , PROVV_ATTO_LIQUIDAZIONE_SIAC -- fattura fornitore
             , PROVV_ATTO_LIQUIDAZIONE_SIAC -- fattura fornitore coincide, creato in migrazione
             , doc.anno
             , doc.numero
             , doc.codice_soggetto
             , 0 -- frazione: contatore all'interno del doc
             , doc.elenco_doc_id
             , 0 -- codice_soggetto_pag non gestito
             , liq.codice_progben
             , 0 --codice_modpag_del
             , 0 --codice_indirizzo
             , mdp.sede_secondaria
             , liq.importo
             , 0 -- importo da dedurre, valore di default
             , liq.anno_esercizio
             , liq.anno_impegno
             , liq.numero_impegno
             , liq.numero_subimpegno
             , liq.anno_provvedimento
             , liq.numero_provvedimento
             , liq.tipo_provvedimento -- gi� concatenato con ||K
             , liq.sac_provvedimento -- gia concatenato con ||
             , liq.oggetto_provvedimento
             , liq.note_provvedimento
             , liq.stato_provvedimento
             , doc.descrizione
             , 'N' as fla_rilevante_iva
             , doc.data_scadenza as data_scadenza
             , NULL AS CUP
             , NULL as cig
             , TIPO_COMMISSIONI_ES
             , NULL as causale_sospensione
             , NULL as data_sospensione
             , NULL as data_riattivazione
             , 'N' as flag_ord_singolo
             , 'N' as flag_avviso
             , 'N' as flag_esproprio
--             , 'N' as flag_manuale
             , NULL as flag_manuale -- 28.12.2015 salvato su campo siac_t_subdoc.subdoc_convalida_manuale
             , NULL as note
             , aa.causale as causale_ordinativo
             , 0 as numero_mutuo
             , 'N' as flag_certif_crediti
             , liq.numero_liquidazione
             , 0 as numero_mandato
             , el.anno_elenco as anno_elenco
             , 0 as numero_elenco -- il numero elenco � rimasto a 0
             , pLoginOperazione as utente_creazione
             , pLoginOperazione as utente_modifica
             , pEnte
			 , mdp.sede_id                      -- DAVIDE - 14.07.2016 - aggiunta sede_id
          from
/*          migr_doc_spesa doc,
          migr_atto_allegato aa,
          migr_elenco_doc_allegati el,
          migr_liquidazione liq*/
          migr_atto_allegato aa,
          migr_doc_spesa doc,
          migr_elenco_doc_allegati el,
          migr_liquidazione liq
          ,migr_soggetto sogg,  migr_modpag  mdp -- per recuperare info sede secondaria
          where
          aa.fl_migrato='N' and aa.fl_scarto='N' and aa.fl_daelenco = 'N'
          and doc.atto_allegato_id=aa.atto_allegato_id
          and doc.elenco_doc_id=el.elenco_doc_id
          and doc.ente_proprietario_id=pEnte
--          and liq.tipo_provvedimento=aa.tipo_provvedimento||'||K'
          and liq.tipo_provvedimento=aa.tipo_provvedimento
          and liq.anno_provvedimento=aa.anno_provvedimento
          and liq.numero_provvedimento=aa.numero_provvedimento
--          and liq.sac_provvedimento=aa.sac_provvedimento||'||'
          and liq.sac_provvedimento=aa.sac_provvedimento
          and liq.ente_proprietario_id=pEnte
          -- inserisco le quote solo per le liq che non hanno fattura
          and not exists (select 1 from migr_docquo_spesa quo where quo.ente_proprietario_id=pEnte
                  and quo.anno_esercizio=liq.anno_esercizio
                  and quo.numero_liquidazione=liq.numero_liquidazione)
          and sogg.ente_proprietario_id=pEnte
          and sogg.codice_soggetto=liq.codice_soggetto
          and mdp.ente_proprietario_id=pEnte
          and mdp.soggetto_id=sogg.soggetto_id
          and mdp.codice_modpag=liq.codice_progben);

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'end.',pEnte);
commit;
          -- Aggiornare l'importo del doc con la somma delle quote.
          msgRes := 'Update importo del doc fittizio.';
insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'begin.',pEnte);
commit;
          UPDATE migr_doc_spesa doc
                 set importo = (select sum(quo.importo) from migr_docquo_spesa quo
                     where quo.ente_proprietario_id=pEnte
                     and quo.docspesa_id=doc.docspesa_id)
          where ente_proprietario_id = pEnte and fl_fittizio = 'S'
          and doc.atto_allegato_id in (select atto_allegato_id from migr_atto_allegato aa where aa.ente_proprietario_id=pEnte and aa.fl_daelenco='N');

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'end.',pEnte);
commit;


          -- attribuire la versione alla quota come contatore all'interno del doc.
          msgRes := 'Update frazione della quota di spesa.';

/*
         execute immediate 'update migr_docquo_spesa q
                             set frazione = (Select countNum.rn from
                                               (select quo.docspesa_id,quo.docquospesa_id,
                                               row_number() over (partition by quo.docspesa_id order by quo.docspesa_id ) as rn
                                               from migr_docquo_spesa quo, migr_doc_spesa doc
                                               where quo.ente_proprietario_id = '||pEnte||
                                               'and quo.docspesa_id=doc.docspesa_id
                                               and doc.fl_fittizio=''S'') countNum
                                               where countNum.docquospesa_id=q.docquospesa_id)
                              where q.ente_proprietario_id='||pEnte||
                              'and q.frazione = 0
                              and q.docspesa_id in (select docspesa_id from migr_doc_spesa d where d.ente_proprietario_id='||pEnte||' and d.fl_fittizio = ''S'')';
*/

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'begin.',pEnte);
commit;

      for migrQuote in (select q.docquospesa_id, q.docspesa_id
                    from migr_docquo_spesa q, migr_doc_spesa d, migr_atto_allegato a
                    where d.ente_proprietario_id = pEnte
                    and d.fl_fittizio = 'S'
                    and d.atto_allegato_id = a.atto_allegato_id
                    and a.fl_daelenco = 'N'
                    and q.docspesa_id = d.docspesa_id
                    and q.frazione = 0
                    order by  q.docspesa_id, q.docquospesa_id)
      loop
        if h_docSpesa_id <> migrQuote.docspesa_id then
          h_frazione := 1;
        else
          h_frazione:=h_frazione+1;
        end if;
          update migr_docquo_spesa set frazione = h_frazione where docquospesa_id = migrQuote.docquospesa_id;
          commit;
        h_docSpesa_id := migrQuote.docspesa_id;
      end loop;

insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
values (migr_migr_elab_id_seq.nextval,'ALLEGATO ATTO',msgRes||'end.',pEnte);
commit;
      -- 15.09.2015 fine codice procedura migrazione_elenco_doc_allegati
      pCodRes := 0;
      pMsgRes :=  'Ok.';

    exception
      when others then
        pMsgRes      :=  msgRes || 'Errore ' ||
                         SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        pCodRes      := -1;
        rollback;
   end migrazione_atto_allegato;

 procedure migrazione_aa_daelenco (pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pMsgRes out varchar2)  IS
    codRes number := 0;
    msgRes  varchar2(1500) := null;

    countRec number(3) :=0 ;

    h_rec varchar2(500) := null;
    h_docSpesa_id number(10) :=0;
    h_frazione number(5) :=0;

    begin

        msgRes := 'Inizio migrazione atto_allegato da elenco.';

        begin

           msgRes := 'Pulizia tabelle di migrazione atto_allegato.';
           insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
           commit;

           DELETE FROM migr_attodaelenco_temp;-- where ente_proprietario_id = pEnte;

           DELETE FROM migr_atti_liquid_temp;-- where ente_proprietario_id = pEnte; aggiungere alla chiave l'ente se vogliamo cancellare per ente

           DELETE FROM migr_aa_liquidazioni_temp;-- where ente_proprietario_id = pEnte;

           UPDATE migr_docquo_spesa quo set quo.elenco_doc_id = 0 WHERE elenco_doc_id <> 0 and ente_proprietario_id = pEnte and FL_MIGRATO = 'N'
           and elenco_doc_id in (select el.elenco_doc_id from migr_elenco_doc_allegati el, migr_atto_allegato aa
                                where el.ente_proprietario_id=pEnte and el.ente_proprietario_id=aa.ente_proprietario_id
                                and el.atto_allegato_id=aa.atto_allegato_id
                                and el.fl_migrato='N' and aa.fl_daelenco='S');

           -- cancellare anche i doc fittizi e relative quote create.
           DELETE FROM migr_docquo_spesa quo WHERE fl_migrato='N' and ente_proprietario_id  = pEnte
           and quo.docspesa_id in (select doc.docspesa_id from migr_doc_spesa doc, migr_atto_allegato aa
                                   where doc.fl_migrato='N' and doc.ente_proprietario_id  = pEnte and doc.fl_fittizio='S'
                                   and doc.atto_allegato_id=aa.atto_allegato_id
                                   and aa.fl_daelenco='S' and aa.ente_proprietario_id=pEnte);

           DELETE from migr_doc_spesa where FL_MIGRATO = 'N' and ente_proprietario_id = pEnte
                  and atto_allegato_id in (select atto_allegato_id from migr_atto_allegato where fl_daelenco = 'S' and ente_proprietario_id=pEnte);

           DELETE FROM migr_atto_allegato_sog WHERE FL_MIGRATO = 'N' and ente_proprietario_id=pEnte
                  and atto_allegato_id in (select atto_allegato_id FROM migr_atto_allegato WHERE FL_MIGRATO = 'N' and fl_daelenco = 'S' and ente_proprietario_id=pEnte);

           DELETE from migr_elenco_doc_allegati where FL_MIGRATO = 'N' and ente_proprietario_id = pEnte
                  and atto_allegato_id in (select atto_allegato_id from migr_atto_allegato where fl_daelenco = 'S' and ente_proprietario_id=pEnte);

           DELETE FROM migr_atto_allegato WHERE FL_MIGRATO = 'N' and fl_daelenco = 'S' and ente_proprietario_id=pEnte;

           insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
           values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
           commit;

           exception
             when others then
                  rollback;
                  pCodRes := -1;
                  pMsgRes := msgRes || 'Errore ' ||
                          SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
             return;
        end;

        msgRes := 'Popola tabella temp con elenchi da migrare.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;

        INSERT INTO MIGR_ATTODAELENCO_TEMP (ANNO_PROVVEDIMENTO, SAC_PROVVEDIMENTO, NUMERO_ELENCO,ENTE_PROPRIETARIO_ID)
        (select distinct att.annoprov, att.direzione, att.nelenco, pEnte
            from migr_liquidazione migr,w_liquid_atti_migr att
            where
            att.nelenco>0
            and att.anno_esercizio=migr.anno_esercizio
            and att.nliq=migr.numero_liquidazione
            and migr.tipo_provvedimento like PROVV_ATTO_LIQUIDAZIONE_SIAC||'%'
            and migr.ente_proprietario_id = pEnte);
        /*select distinct annoprov, direzione, nelenco, pEnte
          from atti_liquid att
          where exists (select 1 from migr_liquidazione liq
                where liq.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K'
                and att.annoprov = liq.anno_provvedimento
                and att.nprov = liq.numero_provvedimento
                -- in fase di migrazione alla direzione viene concatenato || e il tipo AL � tradotto in AA||K
                and att.direzione||'||'=liq.sac_provvedimento
                and liq.ente_proprietario_id = pEnte)
          and nelenco > 0);*/

        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
        commit;

        msgRes := 'Popola tabella temp con atti liquid coinvolti nella migrazione.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;

        insert into migr_atti_liquid_temp
        (annoprov, nprov, direzione,settore,note,nelenco,datascad,causale_pagam,dirett_dirig_resp,cod_titolario,anno_titolario,
         num_pratica,fl_estr_copia_prov,fl_fatture,fl_altro,fl_doc_giustif,fl_dichiaraz,versione,fl_dati_sens,datasosp_pag,
         causale_sosp,datariat_pag,data_complet,ente_proprietario_id)
        (select distinct
          al.annoprov,al.nprov,al.direzione,al.settore,al.note,al.nelenco,al.datascad,al.causale_pagam
          ,al.dirett_dirig_resp,al.cod_titolario,al.anno_titolario,al.num_pratica
          , al.fl_estr_copia_prov, al.fl_fatture,al.fl_altro, al.fl_doc_giustif,al.fl_dichiaraz,al.versione, al.fl_dati_sens,al.datasosp_pag
          , al.causale_sosp,al.datariat_pag, al.data_complet
          ,pEnte
          from atti_liquid al, MIGR_ATTODAELENCO_TEMP eltemp, migr_liquidazione l
           where al.annoprov=eltemp.anno_provvedimento
           and al.direzione=elTemp.Sac_Provvedimento
           and al.nelenco=eltemp.numero_elenco
           and al.annoprov = l.anno_provvedimento
           and al.direzione||'||K' = l.sac_provvedimento
           and al.nprov=l.numero_provvedimento
           and l.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K'
           and al.datareg is not null
           and al.data_rifiuto is null);

        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
        commit;

        msgRes := 'Inserimento testata atto allegato da elenco.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;

        for attoDaElenco_temp in (select anno_provvedimento, sac_provvedimento, numero_elenco from migr_attodaelenco_temp where ente_proprietario_id = pEnte)
          loop
            h_rec := 'Elenco '|| attoDaElenco_temp.Anno_Provvedimento || '/'||attoDaElenco_temp.Sac_Provvedimento||'/'||attoDaElenco_temp.Numero_Elenco||'.';

            insert into migr_atto_allegato
              ( atto_allegato_id,
                tipo_provvedimento,
                anno_provvedimento,
                numero_provvedimento_calcolato,
                numero_provvedimento,
                sac_provvedimento,
                settore,
                causale,
                note,
                pratica,
                numero_titolario,
                anno_titolario,
                responsabile_amm,
                responsabile_cont,
                altri_allegati,
                dati_sensibili,
                data_scadenza,
                causale_sospensione,
                data_sospensione,
                data_riattivazione,
                versione,
                codice_soggetto, -- Default 0
                stato, -- default C
                data_completamento,
                utente_creazione,
                fl_daelenco,
                numero_elenco,
                ente_proprietario_id)
                (Select
                 migr_atto_allegato_id_seq.nextval
                ,PROVV_ATTO_LIQUIDAZIONE_SIAC tipo_provvedimento
                ,ord.anno_provvedimento
                ,ord.numero_provvedimento_calcolato
                ,ord.numero_provvedimento
                ,ord.sac_provvedimento
                ,ord.settore
                ,ord.causale
                ,ord.note
                ,ord.pratica
                ,ord.numero_titolario
                ,ord.anno_titolario
                ,ord.responsabile_amm
                ,ord.responsabile_cont
                ,ord.altri_allegati
                ,ord.dati_sensibili
                ,ord.data_scadenza
                ,ord.causale_sospensione
                ,ord.data_sospensione
                ,ord.data_riattivazione
                ,ord.versione
                ,ord.codice_soggetto
                ,ord.stato -- impostato a Da completare , Da aggiornare una volta creati gli elenchi.
                ,ord.data_completamento
                ,pLoginOperazione
                ,'S'
                ,ord.nelenco
                ,pEnte
                from
                  (select
                  att.annoprov anno_provvedimento
                  ,(100000+nelenco) numero_provvedimento_calcolato
                  ,att.nprov numero_provvedimento
                  ,att.direzione sac_provvedimento
                  ,att.settore
                  ,nvl(att.causale_pagam,PROVV_ATTO_LIQUIDAZIONE_SIAC||'\'||att.annoprov||'\'||att.nprov||'\'||att.direzione) causale
                  ,att.direzione||'_'||att.settore||'_'||att.annoprov||'_'||att.nelenco||'_EL'||'.'||nvl(att.note,'') as note
                  ,att.num_pratica pratica
                  ,att.cod_titolario numero_titolario
                  ,att.anno_titolario anno_titolario
                  ,att.dirett_dirig_resp responsabile_amm
                  ,att.funz_liq responsabile_cont
                  , decode (fl_fatture,'S','Altri Allegati: '
                          , decode(fl_dichiaraz,'S','Altri Allegati: '
                             , decode(fl_doc_giustif,'S','Altri Allegati: '
                             , decode(fl_estr_copia_prov,'S','Altri Allegati: '
                             , decode(fl_altro,'S','Altri Allegati: ','')))))
                    ||decode (fl_fatture,'S','Fatture. ','')
                    ||decode (fl_dichiaraz,'S','Dichiarazione. ','')
                    ||decode (fl_doc_giustif,'S','Estratto copia. ','')
                    ||decode (fl_altro,'S','Altro. ','') as altri_allegati
                 ,nvl(att.fl_dati_sens,'N') dati_sensibili
                 ,to_char(att.datascad,'yyyy-MM-dd') as data_scadenza
                 ,att.causale_sosp causale_sospensione
                 ,to_char(att.datasosp_pag,'yyyy-MM-dd')data_sospensione
                 ,to_char(att.datariat_pag,'yyyy-MM-dd')data_riattivazione
                 ,att.versione
                 ,0 codice_soggetto --valore di default
                 ,STATO_AA_C stato
                 ,to_char(att.data_complet,'yyyy-MM-dd')data_completamento
                 ,nelenco
                 from migr_atti_liquid_temp att
                 where att.ente_proprietario_id = pEnte
                 and exists (select 1 from migr_liquidazione liq
                               where liq.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K'
                               and att.annoprov = liq.anno_provvedimento
                               and att.nprov = liq.numero_provvedimento
                               -- in fase di migrazione alla direzione viene concatenato ||K e il tipo AL � tradotto in AA||K
                               and att.direzione||'||K'=liq.sac_provvedimento
                               and liq.ente_proprietario_id = pente)
                  and att.annoprov = attoDaElenco_temp.anno_provvedimento
                  and att.direzione= attoDaElenco_temp.sac_provvedimento
                  and att.nelenco = attoDaElenco_temp.numero_elenco
                  order by numero_provvedimento ) ord
                where rownum=1);

                if countRec = N_BLOCCHI_DOC then
                  commit;
                  countRec := 0;
                else
                    countRec := countRec+1;
                end if;

            end loop;
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
        commit;


        msgRes := 'Popola tabella temp con liquidazioni coinvolte nella migrazione.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;

        insert into migr_aa_liquidazioni_temp
        ( atto_allegato_id,
          tipo_provvedimento_aa,
          anno_provvedimento_aa,
          numero_provvedimento_aa,
          sac_provvedimento_aa,
          causale,
          Anno_Esercizio,
          Numero_Liquidazione,
          importo,
          Codice_Soggetto,
          Codice_Progben,
          anno_impegno,
          numero_impegno,
          numero_subimpegno,
          anno_provvedimento_liq,
          numero_provvedimento_liq,
          tipo_provvedimento_liq,
          sac_provvedimento_liq,
--          oggetto_provvedimento_liq,
--          note_provvedimento_liq,
--          stato_provvedimento_liq,
          soggetto_id,
          sede_secondaria,
          ente_proprietario_id)
          (select
           migrAA.atto_allegato_id
           , migrAA.Tipo_Provvedimento
           , migrAA.Anno_Provvedimento
           , migrAA.Numero_Provvedimento_calcolato
           , migrAA.Sac_Provvedimento
--           , migrAA.causale � la causale del primo atto di liquidazione che � stato usato per caricare l'atto alleggato
           , al.causale_pagam -- � la causale del singolo atto di liquidazione che compone l'elenco
           , migrLiq.Anno_Esercizio
           , migrLiq.Numero_Liquidazione
           , migrLiq.Importo
           , migrLiq.Codice_Soggetto
           , migrLiq.Codice_Progben
           , migrLiq.anno_impegno
           , migrLiq.numero_impegno
           , migrLiq.numero_subimpegno
           , migrLiq.anno_provvedimento
           , migrLiq.numero_provvedimento
           , migrLiq.tipo_provvedimento -- gi� concatenato con ||K
           , migrLiq.sac_provvedimento -- gia concatenato con ||
--           , migrLiq.oggetto_provvedimento
--           , migrLiq.note_provvedimento
--           , migrLiq.stato_provvedimento
           , so.soggetto_id
           , mdp.sede_secondaria
           , pEnte
          from
          migr_atti_liquid_temp al, migr_atto_allegato migrAA, migr_liquidazione migrLiq, migr_soggetto so, migr_modpag mdp
                  where  migrAA.Ente_Proprietario_Id=pEnte and migrAA.Fl_Migrato='N' and migrAA.Fl_Scarto='N' and migrAA.fl_daelenco = 'S'
          -- condizioni per trovare gli atti liq dell'elenco
                  and al.ente_proprietario_id=pEnte
                  and migrAA.Anno_Provvedimento=al.annoprov
                  and migrAA.Sac_Provvedimento=al.direzione
                  and migrAA.Numero_Elenco=al.nelenco
          -- condizioni per trovare le liq migrate legate agli atti liq
--                  and migrLiq.anno_esercizio !='0000'
                  and migrLiq.tipo_provvedimento=PROVV_ATTO_LIQUIDAZIONE_SIAC||'||K'
                  and migrLiq.anno_provvedimento=al.annoprov
                  and migrLiq.numero_provvedimento=al.nprov
                  and migrLiq.sac_provvedimento=al.direzione||'||K'
                  and migrLiq.ente_proprietario_id = al.ente_proprietario_id
          -- condizioni per soggetto
                  and so.codice_soggetto=migrLiq.Codice_Soggetto
                  and so.ente_proprietario_id=pEnte
          -- condizioni per mdp
                  and mdp.soggetto_id=so.soggetto_id
                  and mdp.codice_modpag=migrLiq.Codice_Progben);

      insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
      values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
      commit;

      msgRes := 'Inserimento relazione atto allegato / soggetto.';
      insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
      values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
      commit;
          insert into migr_atto_allegato_sog
           (atto_allegato_sog_id ,
            atto_allegato_id     ,
            codice_soggetto      ,
            causale_sospensione  ,
            data_sospensione     ,
            data_riattivazione   ,
            ente_proprietario_id)
          (select
            migr_atto_allegato_sog_id_seq.nextval
            , rel.atto_allegato_id
            , rel.codice_soggetto
            , rel.causale_sospensione
            , rel.data_sospensione
            , rel.data_riattivazione
            ,pEnte from
         (select distinct
            migrAA.atto_allegato_id
            ,aaL.codice_soggetto
            ,migrAA.causale_sospensione
            ,migrAA.data_sospensione
            ,migrAA.data_riattivazione
          from
            migr_atto_allegato migrAA
            , migr_aa_liquidazioni_temp aaL
          where
            aaL.ente_proprietario_id = pEnte
            and aaL.atto_allegato_id = migrAA.Atto_Allegato_Id)rel);
      insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
      values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
      commit;


        msgRes := 'Creazione elenco per atti con liquidazioni fatturate.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;

      insert into migr_elenco_doc_allegati
      ( elenco_doc_id,
        atto_allegato_id,
        anno_elenco,
        numero_elenco,
        stato,
        tipo_provvedimento,
        anno_provvedimento,
        numero_provvedimento,
        sac_provvedimento,
        migr_tipo_elenco,
        ente_proprietario_id)
       (select
        migr_elenco_doc_id_seq.nextval
        ,sub.atto_allegato_id
        ,sub.anno_elenco
        ,sub.numero_elenco
        ,sub.stato
        ,sub.Tipo_Provvedimento_aa
        ,sub.Anno_Provvedimento_aa
        ,sub.numero_provvedimento_aa
        ,sub.Sac_Provvedimento_aa
        ,1 -- tipo elenco
        ,pEnte
        from
        (select distinct t.atto_allegato_id
                      ,pAnnoEsercizio anno_elenco
                      ,0 numero_elenco
                      ,STATO_ELENCO_DOC_C stato
                      ,t.tipo_provvedimento_aa
                      ,t.Anno_Provvedimento_aa
                      ,t.Numero_Provvedimento_aa
                      ,t.Sac_Provvedimento_aa
          from migr_aa_liquidazioni_temp t
          where t.ente_proprietario_id=pEnte
          and exists (select 1 from migr_docquo_spesa d
                 where d.ente_proprietario_id=pEnte
                 and d.anno_esercizio=t.anno_esercizio
                 and d.numero_liquidazione=t.numero_liquidazione))sub);

        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
        commit;


        msgRes := 'Valorizzazione elenco_doc_id per quote con liquidazione.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;
        for rec in (select quo.docquospesa_id, t.atto_allegato_id
                     from migr_docquo_spesa quo, migr_aa_liquidazioni_temp t
                     where quo.ente_proprietario_id = pEnte
                     and quo.anno_esercizio =t.anno_esercizio
                     and quo.numero_liquidazione=t.numero_liquidazione
                     and t.ente_proprietario_id=pEnte)
        loop
          update migr_docquo_spesa
                 set elenco_doc_id = (select elenco_doc_id from migr_elenco_doc_allegati where atto_allegato_id = rec.atto_allegato_id and migr_tipo_elenco = 1)
          where docquospesa_id = rec.docquospesa_id;
       end loop;
       insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
       values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
       commit;

        msgRes := 'Creazione elenco per atti con liquidazioni non fatturate.';
        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
        commit;

      -- ELENCHI TIPO 2
      insert into migr_elenco_doc_allegati
      ( elenco_doc_id,
        atto_allegato_id,
        anno_elenco,
        numero_elenco,
        stato,
        tipo_provvedimento,
        anno_provvedimento,
        numero_provvedimento,
        sac_provvedimento,
        migr_tipo_elenco,
        ente_proprietario_id)
       (select
        migr_elenco_doc_id_seq.nextval
        ,sub.atto_allegato_id
        ,sub.anno_elenco
        ,sub.numero_elenco
        ,sub.stato
        ,sub.Tipo_Provvedimento_aa
        ,sub.Anno_Provvedimento_aa
        ,sub.numero_provvedimento_aa
        ,sub.Sac_Provvedimento_aa
        ,2 -- tipo elenco
        ,pEnte
        from
        (select distinct t.atto_allegato_id
                      ,pAnnoEsercizio anno_elenco
                      ,0 numero_elenco
                      ,STATO_ELENCO_DOC_C stato
                      ,t.Tipo_Provvedimento_aa
                      ,t.Anno_Provvedimento_aa
                      ,t.Numero_Provvedimento_aa
                      ,t.Sac_Provvedimento_aa
          from migr_aa_liquidazioni_temp t
          where t.ente_proprietario_id=pEnte
          and not exists (select 1 from migr_docquo_spesa d
                 where d.ente_proprietario_id=pEnte
                 and d.anno_esercizio=t.anno_esercizio
                 and d.numero_liquidazione=t.numero_liquidazione))sub);

        insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
        commit;

       /* 18.09.2015 aggiornamento non necessario, gli atti allegati e gli elenchi sono creati in stato C
       msgRes := 'Aggiornamento stato COMPLETATO per Allegato atto.';
       insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
       values (migr_migr_elab_id_seq.nextval,msgRes||'begin.',pEnte);commit;
       commit;

       update migr_atto_allegato aa
              set aa.stato = STATO_AA_C
       where aa.ente_proprietario_id=pEnte
       and aa.fl_daelenco='S'
       and aa.fl_migrato='N'
       and not exists (select 1 from migr_elenco_doc_allegati el
                       where el.atto_allegato_id = aa.atto_allegato_id
                       and el.migr_tipo_elenco = 2
                       and el.ente_proprietario_id=pEnte );

       insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
       values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
       commit;*/

      msgRes := 'Creazione doc fittizio per elenco atto non legato a liquidazioni.';
      insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
      values (migr_migr_elab_id_seq.nextval,msgRes||'begin.',pEnte);
      commit;

  insert into migr_doc_spesa
      (docspesa_id,-- sequence
       tipo, -- costante
       tipo_fonte,-- costante
       anno,-- anno di bilancio, di migrazione
       numero,-- composto con dati di atto allegato e elenco doc allegati
       codice_soggetto, -- quello della liquidazione non legata a fatture
       codice_soggetto_pag, --> 0
       stato,    --> costante, L
       descrizione, -- causale atto allegato
       date_emissione, -- sysdate troncata alla data
       termine_pagamento, -- 0
       importo, -- totale delle quote, quindi liquid, inizialmente 0 modificare dopo
       arrotondamento, -- 0
       codice_ufficio, -- NULL
       data_ricezione, --NULL
       data_repertorio,--NULL
       numero_repertorio, -- 0, valore di default
       causale_sospensione, --NULL
       data_sospensione, -- NULL
       data_riattivazione, -- NULL
       data_registro_fatt, -- NULL
       numero_registro_fatt, -- 0, valore di deafult
       anno_registro_fatt, -- NULL
       utente_creazione, -- utente di migrazione
       utente_modifica, -- utente di migrazione
       ente_proprietario_id,
       fl_fittizio,
       atto_allegato_id, -- atto allegato dell'elenco
       elenco_doc_id -- nr elenco
       )
       (SELECT
       migr_doc_spesa_id_seq.nextval
       ,PROVV_ATTO_LIQUIDAZIONE_SIAC
       ,PROVV_ATTO_LIQUIDAZIONE_SIAC
       ,pAnnoEsercizio
       ,aa.numero
       ,aa.codice_soggetto
       ,aa.codice_soggetto_pag
       ,aa.stato
       ,aa.descrizione
       ,aa.data_emissione
      ,aa.termine_pagamento
      ,aa.importo --fare update successivamente
      ,aa.arrotondamento
      ,aa.codice_ufficio
      ,aa.data_ricezione
      ,aa.data_repertorio
      ,aa.numero_repertorio
      ,aa.causale_sospensione
      ,aa.data_sospensione
      ,aa.data_riattivazione
      ,aa.data_registro_fatt
      ,aa.numero_registro_fatt
      ,aa.anno_registro_fatt
      ,aa.utente_creazione
      ,aa.utente_modifica
      ,pEnte
      ,'S' -- fl_fittizio
      ,aa.atto_allegato_id
      ,aa.elenco_doc_id
      from
      (SELECT distinct
--      aaL.Anno_Provvedimento_aa||'\'||aaL.Numero_Provvedimento_aa||'\'||aaL.Tipo_Provvedimento_aa||'\'||aaL.Sac_Provvedimento_aa||'\'||el.Numero_Elenco||'\1' numero
      aaL.Anno_Provvedimento_aa||'\'||aaL.Numero_Provvedimento_aa||'\'||aaL.Tipo_Provvedimento_aa||'\'||aaL.Sac_Provvedimento_aa||'\'||aaL.codice_soggetto||'\M' numero
       ,aaL.codice_soggetto
       ,0 as codice_soggetto_pag
       ,STATO_DOC_L stato
       ,aaL.causale descrizione
       ,to_char(sysdate,'YYYY-MM-DD') as data_emissione -- data_emissione
      ,0 as termine_pagamento
      ,0 as importo --fare update successivamente
      ,0 as arrotondamento
      ,NULL codice_ufficio
      ,NULL as data_ricezione
      ,NULL as data_repertorio
      ,0 as numero_repertorio
      ,NULL as causale_sospensione
      ,NULL as data_sospensione
      ,NULL as data_riattivazione
      ,NULL as data_registro_fatt
      ,0 as numero_registro_fatt
      ,NULL as anno_registro_fatt
      ,pLoginOperazione as utente_creazione
      ,pLoginOperazione as utente_modifica
      ,aaL.atto_allegato_id
      ,el.elenco_doc_id
      from migr_elenco_doc_allegati el, migr_aa_liquidazioni_temp aaL
      where el.migr_tipo_elenco = 2 -- elenco creato per atti liquidazione con liquidazioni senza fattura
      and el.ente_proprietario_id = pEnte
      and el.atto_allegato_id = aaL.atto_allegato_id
      and not exists (select 1 from migr_docquo_spesa quo
                     where quo.ente_proprietario_id=pEnte
                     and quo.anno_esercizio=aaL.anno_esercizio
                     and quo.numero_liquidazione=aaL.numero_liquidazione))aa);

      insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
      values (migr_migr_elab_id_seq.nextval,msgRes||'begin.',pEnte);
      commit;

      msgRes := 'Creazione quote per doc fittizi.';
      insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
      values (migr_migr_elab_id_seq.nextval,msgRes||'Begin.',pEnte);
      commit;

     insert into migr_docquo_spesa
       (docquospesa_id,
        docspesa_id,
        tipo,
        tipo_fonte,
        anno,
        numero,
        codice_soggetto,
        frazione, -- impostata a 0 cambiata dopo
        elenco_doc_id,
        codice_soggetto_pag, -- valore di default 0
        codice_modpag,
        codice_modpag_del, -- valore di default 0
        codice_indirizzo,-- valore di default 0
        sede_secondaria,
        importo,
        importo_da_dedurre,--valore di default 0
        anno_esercizio,
        anno_impegno,
        numero_impegno,
        numero_subimpegno,
        anno_provvedimento,
        numero_provvedimento,
        tipo_provvedimento,
        sac_provvedimento,
        oggetto_provvedimento,
        note_provvedimento,
        stato_provvedimento,
        descrizione,
        --numero_iva, da verificare come trattare
        flag_rilevante_iva,
        data_scadenza,
        --data_scadenza_new, --NULL non gestito
        cup,
        cig,
        commissioni,--ES valore di default
        causale_sospensione,
        data_sospensione,
        data_riattivazione,
        flag_ord_singolo, -- valore di default N
        flag_avviso, -- valore di default N
        --tipo_avviso, NULL non gestito
        flag_esproprio, -- valore di default N
        flag_manuale, -- valore di default NULL
        note,
        causale_ordinativo,
        numero_mutuo, -- valore di default 0
        --annotazione_certif_crediti,
        --data_certif_crediti, NULL non gestito
        --note_certif_crediti, NULL non gestito
        --numero_certif_crediti, NULL non gestito
        flag_certif_crediti, --valore di default 0
        numero_liquidazione,
        numero_mandato,
        anno_elenco,
        numero_elenco,
        utente_creazione,
        utente_modifica,
        ente_proprietario_id,
		sede_id)               -- DAVIDE - 14.07.2016 - aggiunta sede_id
          (select
             migr_docquo_spesa_id_seq.nextval,
             doc.docspesa_id
             , PROVV_ATTO_LIQUIDAZIONE_SIAC -- Tipo ALG
             , PROVV_ATTO_LIQUIDAZIONE_SIAC -- fattura fornitore coincide, creato in migrazione
             , doc.anno
             , doc.numero
             , aaL.codice_soggetto
             , 0
             , doc.elenco_doc_id
             , 0 -- codice_soggetto_pag non gestito
             , aaL.codice_progben
             , 0 --codice_modpag_del
             , 0 --codice_indirizzo
             , aaL.sede_secondaria
             , aaL.importo
             , 0 -- importo da dedurre, valore di default
             , aaL.anno_esercizio
             , aaL.anno_impegno
             , aaL.numero_impegno
             , aaL.numero_subimpegno
             , aa.anno_provvedimento
             , aa.numero_provvedimento_calcolato
             , aa.tipo_provvedimento
             , aa.sac_provvedimento
             , NULL as oggetto_provvedimento
             , NULL as note_provvedimento
             , NULL as stato_provvedimento
             , doc.descrizione
             , 'N' as fla_rilevante_iva
             , doc.data_scadenza as data_scadenza
             , NULL AS CUP
             , NULL as cig
             , TIPO_COMMISSIONI_ES
             , NULL as causale_sospensione
             , NULL as data_sospensione
             , NULL as data_riattivazione
             , 'N' as flag_ord_singolo
             , 'N' as flag_avviso
             , 'N' as flag_esproprio
--             , 'N' as flag_manuale
             , NULL as flag_manuale -- 28.12.2015 salvato su campo siac_t_subdoc.subdoc_convalida_manuale
             , NULL as note
             , aaL.causale as causale_ordinativo
             , 0 as numero_mutuo
             , 'N' as flag_certif_crediti
             , aaL.numero_liquidazione
             , 0 as numero_mandato
             , 0 as anno_elenco -- poi vediamo
             , 0 as numero_elenco -- il numero elenco � rimasto a 0
             , pLoginOperazione as utente_creazione
             , pLoginOperazione as utente_modifica
             , pEnte
			 , mdp.sede_id                                -- DAVIDE - 14.07.2016 - aggiunta sede_id
      from migr_doc_spesa doc, migr_atto_allegato aa
      , migr_aa_liquidazioni_temp aaL, migr_modpag mdp
      where doc.ente_proprietario_id = pEnte and doc.fl_fittizio = 'S'
      and aa.atto_allegato_id=doc.atto_allegato_id and aa.fl_daelenco='S'
      and aaL.Atto_Allegato_Id=aa.atto_allegato_id
      and doc.codice_soggetto=aal.codice_soggetto
      and mdp.soggetto_id=aal.soggetto_id and mdp.codice_modpag=aal.codice_progben  -- DAVIDE - 14.07.2016 - aggiunta sede_id
      and aal.ente_proprietario_id = pEnte
      and mdp.ente_proprietario_id = aal.ente_proprietario_id                       -- DAVIDE - 14.07.2016 - aggiunta sede_id
      and not exists (select 1 from migr_docquo_spesa quo where
                            quo.ente_proprietario_id=pEnte
                            and quo.anno_esercizio=aaL.anno_esercizio
                            and quo.numero_liquidazione=aaL.numero_liquidazione));

      insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
      values (migr_migr_elab_id_seq.nextval,msgRes||'End.',pEnte);
      commit;

         -- Aggiornare l'importo del doc con la somma delle quote.
          msgRes := 'Update importo del doc fittizio.';
          insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,msgRes||'begin.',pEnte);
          commit;
          UPDATE migr_doc_spesa doc
                 set importo = (select sum(quo.importo) from migr_docquo_spesa quo
                     where quo.ente_proprietario_id=pEnte
                     and quo.docspesa_id=doc.docspesa_id)
          where ente_proprietario_id = pEnte and fl_fittizio = 'S'
          and doc.atto_allegato_id in (select atto_allegato_id from migr_atto_allegato aa where aa.ente_proprietario_id=pEnte and aa.fl_daelenco='S');

          insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,msgRes||'end.',pEnte);
          commit;

          -- attribuire la versione alla quota come contatore all'interno del doc.
          msgRes := 'Update frazione della quota di spesa.';

          insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,msgRes||'begin.',pEnte);
          commit;

          for migrQuote in (select q.docquospesa_id, q.docspesa_id
                        from migr_docquo_spesa q, migr_doc_spesa d, migr_atto_allegato a
                        where d.ente_proprietario_id = pEnte
                        and d.fl_fittizio = 'S'
                        and d.atto_allegato_id = a.atto_allegato_id
                        and a.fl_daelenco = 'S'
                        and q.docspesa_id = d.docspesa_id
                        and q.frazione = 0
                        order by  q.docspesa_id, q.docquospesa_id)
          loop
            if h_docSpesa_id <> migrQuote.docspesa_id then
              h_frazione := 1;
            else
              h_frazione:=h_frazione+1;
            end if;
              update migr_docquo_spesa set frazione = h_frazione where docquospesa_id = migrQuote.docquospesa_id;
              commit;
            h_docSpesa_id := migrQuote.docspesa_id;
          end loop;

          insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,msgRes||'end.',pEnte);
          commit;


          msgRes := 'Update tipo provvedimento, sac provvedimento per atto allegato, elenco e quote.';
          insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,msgRes||'begin.',pEnte);
          commit;

          -- atto allegato
          update migr_atto_allegato a
                 set a.tipo_provvedimento=a.tipo_provvedimento||'||K'
                 , a.sac_provvedimento=a.sac_provvedimento||'||K' -- la direzione per tipo ALG � in chiave
          where ente_proprietario_id = pEnte
          and fl_migrato='N'
          and fl_daelenco = 'S';

          -- elenchi
          update migr_elenco_doc_allegati el
           set el.tipo_provvedimento=el.tipo_provvedimento||'||K'
             , el.sac_provvedimento=el.sac_provvedimento||'||K' -- la direzione per tipo ALG � in chiave
          where el.ente_proprietario_id=pEnte
          and el.atto_allegato_id in (select a.atto_allegato_id from  migr_atto_allegato a where a.fl_daelenco='S')
          and el.fl_migrato='N';

          -- quote
          update migr_docquo_spesa q
           set q.tipo_provvedimento=q.tipo_provvedimento||'||K'
             , q.sac_provvedimento=q.sac_provvedimento||'||K' -- la direzione per tipo ALG � in chiave
          where ente_proprietario_id = pEnte
          and docspesa_id in
              (select docspesa_id from migr_doc_spesa where fl_fittizio = 'S')
          and elenco_doc_id in
              (select elenco_doc_id from migr_elenco_doc_allegati el , migr_atto_allegato aa where aa.atto_allegato_id=el.atto_allegato_id
               and aa.fl_daelenco = 'S')
          and q.fl_migrato='N';

          insert into migr_elaborazione (migr_elab_id,messaggio_esito,ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,msgRes||'end.',pEnte);
          commit;

      pCodRes := 0;
      pMsgRes :=  'Ok.';
    exception
      when others then
        pMsgRes      :=  msgRes || h_rec || 'Errore ' ||
                         SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        pCodRes      := -1;
        rollback;
   end migrazione_aa_daelenco;

   procedure migrazione_documenti(pEnte number,
                                  pAnnoEsercizio varchar2,
                                  pLoginOperazione varchar2,
                                  pCodRes out number,
                                  pMsgRes out varchar2) is

    codRes number:=0;
    msgRes varchar2(4000):=null;
    ERROR_DOCUMENTO EXCEPTION;
    cDocInseriti number:=0;
    cDocScartati number:=0;

   begin

    -- popolamento tabella temporanea Uscita
    migrazione_doc_temp ('U', pEnte, codRes, msgRes);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    end if;

    -- Documenti di spesa

    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_doc_spesa', 'Begin',pEnte);
    commit;

    migrazione_doc_spesa(pEnte,pLoginOperazione,pAnnoEsercizio,
                         codRes,cDocInseriti,cDocScartati,msgRes);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
          insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_doc_spesa',msgRes,pEnte);
          commit;
          msgRes:='';
    end if;

    -- Quote documenti di spesa
    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_docquo_spesa', 'Begin',pEnte);
    commit;

    migrazione_docquo_spesa(pEnte,pLoginOperazione,pAnnoEsercizio,
                         codRes,cDocInseriti,cDocScartati,msgRes);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
          insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_docquo_spesa',msgRes,pEnte);
          commit;
          msgRes:='';
    end if;

    -- DAVIDE - 03.11.2016 - calcolo Stato documento a partire dalle quote  
    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','aggiorna_stati_docSpesa', 'Begin',pEnte);
    commit;

    aggiorna_stati_documenti('U', pEnte, pAnnoEsercizio,
                             codRes, msgRes);
							 
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
          insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','aggiorna_stati_docSpesa',msgRes,pEnte);
          commit;
          msgRes:='';
    end if;
	-- DAVIDE - 03.11.2016 - Fine

    -- popolamento tabella temporanea ENTRATA
    migrazione_doc_temp ('E', pEnte, codRes, msgRes);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    end if;

    -- Documenti di entrata
    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_doc_entrata', 'Begin',pEnte);
    commit;
    migrazione_doc_entrata(pEnte,pLoginOperazione,pAnnoEsercizio,
                           codRes,cDocInseriti,cDocScartati,msgRes);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
          insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_doc_entrata',msgRes,pEnte);
          commit;
          msgRes:='';
    end if;

    -- Quote Documenti di entrata
    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_docquo_entrata', 'Begin',pEnte);
    commit;
    migrazione_docquo_entrata(pEnte,pLoginOperazione,pAnnoEsercizio,
                              codRes,cDocInseriti,cDocScartati,msgRes);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
          insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_docquo_entrata',msgRes,pEnte);
          commit;
          msgRes:='';
    end if;

    -- Sofia / Davide  - 03.11.2016 - calcolo Stato documento a partire dalle quote  
    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','aggiorna_stati_docEntrata', 'Begin',pEnte);
    commit;

    aggiorna_stati_documenti('E', pEnte, pAnnoEsercizio,
                             codRes,msgRes);

    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
          insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','aggiorna_stati_docEntrata',msgRes,pEnte);
          commit;
          msgRes:='';
    end if;
	-- Sofia / Davide  - 03.11.2016 - Fine

    -- Relazioni Documenti

    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_relaz_documenti', 'Begin',pEnte);
    commit;
    migrazione_relaz_documenti(pEnte,codRes,msgRes);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
        insert into migr_elaborazione
             (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_relaz_documenti',msgRes,pEnte);
        commit;
        msgRes:='';
    end if;

    -- Atto di liquidazione
    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_atto_allegato', 'Begin',pEnte);
    commit;

    migrazione_atto_allegato(pEnte,pLoginOperazione,pAnnoEsercizio,codRes,msgres);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
        insert into migr_elaborazione
             (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_atto_allegato',msgres,pEnte);
        commit;
        msgres:='';
    end if;

    -- Atto da elenco
    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_aa_daelenco', 'Begin',pEnte);
    commit;
    migrazione_aa_daelenco(pEnte,pLoginOperazione,pAnnoEsercizio,codRes,msgres);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
        insert into migr_elaborazione
             (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_aa_daelenco', msgres,pEnte);
        commit;
        msgres:='';
    end if;

    pCodRes:=0;
    pMsgRes:='Elaborazione OK.Documenti Migrati.';

    exception
       when ERROR_DOCUMENTO then
        pMsgRes    := msgRes;
        pCodRes    := -1;
        rollback;
        insert into migr_elaborazione
               (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'DOC',NULL, pMsgRes,pEnte);
        commit;
      when others then
        pMsgRes      :=  msgRes || 'Errore ' ||
                         SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        pCodRes      := -1;
        rollback;
        insert into migr_elaborazione
               (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'DOC',NULL, pMsgRes,pEnte);
        commit;
   end  migrazione_documenti;

   procedure migrazione_iva(pEnte number,pAnnoEsercizio varchar2,pLoginOperazione varchar2,pCodRes out number,pMsgRes out varchar2)
     is
     begin
       pCodRes :=0;
       pMsgRes :='Procedura non implementata.';
     end;


  --- 09.03.2016 Sofia --- ordinativi ------------------------------------------------------

   procedure migrazione_ordinativo(pAnnoEsercizio varchar2,
                                   pEnte number,
                                   pCodRes out number,
                                   pMsgRes out varchar2) is
    codRes number := 0;
    msgRes  varchar2(1500) := null;
    cOrdInseriti number := 0;
    cOrdScartati number := 0;
    cOrdSegnalati number := 0;
   begin
       pCodRes :=0;
       pMsgRes :='Migrazione Ordinativi.';

       msgRes:='Migrazione Ordinativi di Spesa.';
       insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
       values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_SPE',msgRes||' Begin.',pEnte);
       commit;
       migrazione_ordinativo_spesa(pEnte,pAnnoEsercizio,
                                   codRes,
                                   cOrdInseriti,cOrdScartati,cOrdSegnalati,
                                   msgRes);
       insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
       values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_SPE',
               msgRes||' Fine. Inseriti='||cOrdInseriti||' Scartati='||cOrdScartati||'.',pEnte);
       commit;

        cOrdInseriti:=0;
        cOrdScartati:=0;

       if codRes=0 then
         msgRes:='Migrazione Ordinativi di Spesa-Quote.';
         insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
         values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_SPE_TS',msgRes||' Begin.',pEnte);
         commit;
         migrazione_ordinativo_spesa_ts(pEnte,
                                        pAnnoEsercizio,
                                        codRes,
                                        cOrdInseriti,cOrdScartati,
                                        msgRes);
        insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_SPE_TS',
               msgRes||' Fine. Inseriti='||cOrdInseriti||' Scartati='||cOrdScartati||'.',pEnte);
        commit;
       end if;

       if codRes=0 then
        msgRes:='Migrazione Ordinativi di Entrata.';
        insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_ENT',msgRes||' Begin.',pEnte);
        commit;
        
        cOrdInseriti:=0;
        cOrdScartati:=0;
        cOrdSegnalati:=0;
        
        migrazione_ordinativo_entrata(pEnte,pAnnoEsercizio,
                                      codRes,
                                      cOrdInseriti,cOrdScartati,cOrdSegnalati,
                                      msgRes);
        insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_ENT',
                msgRes||' Fine. Inseriti='||cOrdInseriti||' Scartati='||cOrdScartati||' Segnalati='||cOrdSegnalati||'.',pEnte);
        commit;

       end if;

       cOrdInseriti:=0;
       cOrdScartati:=0;

       if codRes=0 then
         msgRes:='Migrazione Ordinativi di Entrata-Quote.';
         insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
         values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_ENT_TS',msgRes||' Begin.',pEnte);
         commit;
         migrazione_ordinativo_entr_ts(pEnte,
                                        pAnnoEsercizio,
                                        codRes,
                                        cOrdInseriti,cOrdScartati,
                                        msgRes);
        insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_ENT_TS',
               msgRes||' Fine. Inseriti='||cOrdInseriti||' Scartati='||cOrdScartati||'.',pEnte);
        commit;
       end if;

       cOrdInseriti:=0;
       cOrdScartati:=0;

       if codRes=0 then
         msgRes:='Migrazione Ordinativi. Provvisori di cassa.';
         insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
         values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','PROV_C',msgRes||' Begin.',pEnte);
         commit;
         migrazione_provissori_cassa(pEnte,pAnnoEsercizio,
                                     codRes,
                                     cOrdInseriti,
                                     cOrdScartati,
                                     msgRes);
         insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
         values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','PROV_C',
                 msgRes||' Fine. Inseriti='||cOrdInseriti||' Scartati='||cOrdScartati||'.',pEnte);
         commit;                            
                                     
       end if;
	   
	   -- DAVIDE - 23.03.016 - inserita migrazione collegamenti ordinativi provvisori cassa
       cOrdInseriti:=0;
       cOrdScartati:=0;

       if codRes=0 then
         msgRes:='Migrazione Ordinativi. Collegamenti Ordinativi Provvisori di cassa.';
         insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
         values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_PROV_C',msgRes||' Begin.',pEnte);
         commit;
         migr_ord_provv_cassa(pEnte,pAnnoEsercizio,
                              codRes,
                              cOrdInseriti,
                              cOrdScartati,
                              msgRes);
         insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
         values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','ORD_PROV_C',
                 msgRes||' Fine. Inseriti='||cOrdInseriti||' Scartati='||cOrdScartati||'.',pEnte);
         commit;                            
                                     
       end if;

       if codRes=0 then
          pMsgRes :='Migrazione Ordinativi.Elaborazione terminata';
          commit;
       else
          pCodRes:=codRes;
          pMsgRes:=pMsgRes||' '||msgRes;
          rollback;
       end if;
       insert into migr_elaborazione (migr_elab_id,migr_tipo,migr_tipo_elab,messaggio_esito,ente_proprietario_id)
       values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','END_OK',pMsgRes||' Fine.',pEnte);
       commit;

    exception
      when others then
        pMsgRes      :=  msgRes || 'Errore ' ||
                         SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        pCodRes      := -1;
        rollback;
        insert into migr_elaborazione
        (migr_elab_id,migr_tipo,  migr_tipo_elab,messaggio_esito, ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'migr_ordinativo','END_KO', pMsgRes||' Fine.',pEnte);
        commit;

   end migrazione_ordinativo;
  
  procedure migrazione_provissori_cassa(pEnte number,
                                    pAnnoEsercizio       varchar2,
                                    pCodRes              out number,
                                    pProvvInseriti         out number,
                                    pProvvScartati         out number,
                                    pMsgRes              out varchar2)
  IS
        msgRes  varchar2(1500) := null;
        cProvvUscInserti number := 0;
        cProvvEntInserti number := 0;
        
        cProvvUscScartati number := 0;
        cProvvEntScartati number := 0;                         

      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_provissori_cassa.Uno o pi� parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin

            msgRes := 'Pulizia tabelle di migrazione provvisori di cassa';

            DELETE FROM MIGR_PROVV_CASSA WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_PROVV_CASSA_SCARTO where ente_proprietario_id = pEnte;

        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
               
          msgRes := 'Inserimento in migr_provv_cassa spesa. Scarti per provvisorio regolarizzati e ordinativo non migrato.';
          
          insert into    MIGR_PROVV_CASSA_SCARTO
          ( provvisorio_scarto_id,
            tipo_eu,
            numero_provvisorio,
            anno_esercizio,
            motivo_scarto,
            ente_proprietario_id )
          (select 
            migr_provv_cassa_scarto_id_seq.nextval,
            'S',
            p.nprov,
            p.anno_esercizio,
            'Provvisorio regolarizzato con ordinativo non migrato',
            pEnte
           from  provvisori_man_mif p  
           where p.anno_esercizio=pAnnoEsercizio
           and exists (select 1 from rel_mandati_provvisori rel, mandati m
                       where rel.nprov=p.nprov
                       and   rel.anno_prov=p.anno_esercizio
                       and   m.nmand=rel.nmand
                       and   m.anno_esercizio=rel.anno_esercizio
                       and   m.staoper!='A'
                       and   not exists (select 1 from migr_ordinativo_spesa migr
                                         where migr.numero_ordinativo=rel.nmand
                                         and   migr.anno_esercizio=rel.anno_esercizio
                                         and   migr.fl_scarto='N')));
          
          msgRes := 'Inserimento in migr_provv_cassa entrata. Scarti per provvisorio regolarizzati e ordinativo non migrato.';
          
          insert into    MIGR_PROVV_CASSA_SCARTO
          ( provvisorio_scarto_id,
            tipo_eu,
            numero_provvisorio,
            anno_esercizio,
            motivo_scarto,
            ente_proprietario_id )
          (select 
            migr_provv_cassa_scarto_id_seq.nextval,
            'E',
            p.nprov,
            p.anno_esercizio,
            'Provvisorio regolarizzato con ordinativo non migrato',
            pEnte
           from  provvisori_rev_mif p  
           where p.anno_esercizio=pAnnoEsercizio
           and exists (select 1 from rel_riscossioni_provvisori rel, riscossioni r
                       where rel.nprov=p.nprov
                       and   rel.anno_prov=p.anno_esercizio
                       and   r.nriscos=rel.nriscos
                       and   r.anno_esercizio=rel.anno_esercizio
                       and   r.staoper!='A'
                       and   not exists (select 1 from migr_ordinativo_entrata migr
                                         where migr.numero_ordinativo=rel.nriscos
                                         and   migr.anno_esercizio=rel.anno_esercizio
                                         and   migr.fl_scarto='N')));
          
          msgRes := 'Inserimento in migr_provv_cassa spesa.';
           /* Inserimento provvisori di SPESA  */
          insert into migr_provv_cassa 
          (provvisorio_id,
           tipo_eu,
           anno_provvisorio,
           numero_provvisorio,
           causale,
           sub_causale,
           data_emissione,
           importo,
           denominazione_soggetto,
           data_annullamento,
           data_regolarizzazione,
           ente_proprietario_id)
            (select 
             migr_provv_cassa_id_seq.nextval,
--             'U',
             'S', -- 22.03.2016 Sofia             
              anno_esercizio,
              nprov,
              causale,
              '',
              to_char(dataemis ,'dd/mm/yyyy'),
              importo,
              ragsoc,
              '',
              '',
              pEnte
             from provvisori_man_mif p
             where p.anno_esercizio = pAnnoEsercizio
             and   not exists (select 1 from MIGR_PROVV_CASSA_SCARTO s
                               where s.tipo_eu='S'
                               and   s.numero_provvisorio=p.nprov
                               and   s.anno_esercizio=p.anno_esercizio
                               and   s.ente_proprietario_id=pEnte));                    


            /* aggiornamento data di regolarizzazione di spesa*/
      update migr_provv_cassa mpc set mpc.data_regolarizzazione = (select to_char(max(m.dataemis) ,'dd/mm/yyyy') from rel_mandati_provvisori rel,  mandati m
                                                                   where rel.anno_esercizio = mpc.anno_provvisorio
                                                                     and rel.nprov = mpc.numero_provvisorio
                                                                     and rel.anno_esercizio = m.anno_esercizio
                                                                     and rel.nmand = m.nmand
                                                                     and m.staoper != 'A')
--       where mpc.tipo_eu = 'U' 22.03.2016 Sofia
       where mpc.tipo_eu = 'S'       
       and mpc.importo = (select sum(m.imporid) from rel_mandati_provvisori rel,  mandati m
                                                                   where rel.anno_esercizio = mpc.anno_provvisorio
                                                                     and rel.nprov = mpc.numero_provvisorio
                                                                     and rel.anno_esercizio = m.anno_esercizio
                                                                     and rel.nmand = m.nmand
                                                                     and m.staoper != 'A');


          
           msgRes := 'Inserimento in migr_provv_cassa entrata.';
           /* Inserimento provvisori di ENTRATA */
          insert into migr_provv_cassa 
          (provvisorio_id,
           tipo_eu,
           anno_provvisorio,
           numero_provvisorio,
           causale,
           sub_causale,
           data_emissione,
           importo,
           denominazione_soggetto,
           data_annullamento,
           data_regolarizzazione,
           ente_proprietario_id)
            (select 
             migr_provv_cassa_id_seq.nextval,
             'E',
              anno_esercizio,
              nprov,
              causale,
              '',
              to_char(dataemis ,'dd/mm/yyyy'),
              importo,
              ragsoc,
              '',
              '',
              pEnte
             from provvisori_rev_mif p
             where p.anno_esercizio = pAnnoEsercizio
             and   not exists (select 1 from MIGR_PROVV_CASSA_SCARTO s
                               where s.tipo_eu='E'
                               and   s.numero_provvisorio=p.nprov
                               and   s.anno_esercizio=p.anno_esercizio
                               and   s.ente_proprietario_id=pEnte));                     

     /* aggiornamento data di regolarizzazione di entrata */
    update migr_provv_cassa mpc set mpc.data_regolarizzazione = (select to_char(max(r.dataemis) ,'dd/mm/yyyy') from rel_riscossioni_provvisori rel,  riscossioni r
                                                               where rel.anno_esercizio = mpc.anno_provvisorio
                                                                 and rel.nprov = mpc.numero_provvisorio
                                                                 and rel.anno_esercizio = r.anno_esercizio
                                                                 and rel.nriscos = r.nriscos
                                                                 and r.staoper != 'A')
   where mpc.tipo_eu = 'E'
   and mpc.importo = (select sum(r.imporisc) from rel_riscossioni_provvisori rel,  riscossioni r
                                                               where rel.anno_esercizio = mpc.anno_provvisorio
                                                                 and rel.nprov = mpc.numero_provvisorio
                                                                 and rel.anno_esercizio = r.anno_esercizio
                                                                 and rel.nriscos = r.nriscos
                                                                 and r.staoper != 'A');



   select count(*) into cProvvUscInserti
   from migr_provv_cassa
   where anno_provvisorio = pAnnoEsercizio
     and tipo_eu = 'S';                   
                      
   select count(*) into cProvvUscScartati
   from migr_provv_cassa_scarto
   where anno_esercizio = pAnnoEsercizio
     and tipo_eu = 'S';    

   select count(*) into cProvvEntInserti
   from migr_provv_cassa
   where anno_provvisorio = pAnnoEsercizio
     and tipo_eu = 'E';                   
     
   select count(*) into cProvvEntScartati
   from migr_provv_cassa_scarto
   where anno_esercizio = pAnnoEsercizio
     and tipo_eu = 'E';                   


    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Provvisori inseriti di spesa=' ||
                 cProvvUscInserti || ' di entrata=' || cProvvEntInserti ||'.'||
                 'Provvisori scartati di spesa='|| 
                 cProvvUscScartati || ' di entrata=' || cProvvEntScartati ||'.';


    pProvvScartati := cProvvUscScartati+cProvvEntScartati;
    pProvvInseriti := cProvvUscInserti + cProvvEntInserti;
    commit;

   exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
  END migrazione_provissori_cassa;  
    
  --  DAVIDE - 23.03.016 - inserita migrazione collegamenti ordinativi provvisori cassa
  procedure migr_ord_provv_cassa(pEnte number,
                                 pAnnoEsercizio       varchar2,
                                 pCodRes              out number,
                                 pProvvInseriti         out number,
                                 pProvvScartati         out number,
                                 pMsgRes              out varchar2)
  IS
        msgRes  varchar2(1500) := null;
        cProvvUscInserti number := 0;
        cProvvEntInserti number := 0;
        
        cProvvUscScartati number := 0;
        cProvvEntScartati number := 0;                         

      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_ordinativi_provvisori_cassa.Uno o pi� parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin

            msgRes := 'Pulizia tabelle di migrazione ordinativi provvisori di cassa';

            DELETE FROM MIGR_PROVV_CASSA_ORDINATIVO WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_PROVV_CASSA_ORD_SCARTO where ente_proprietario_id = pEnte;

        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
               
          msgRes := 'Inserimento in migr_ordinativi_provv_cassa scarto. Scarti per ordinativo spesa non migrato.';
          
          insert into    MIGR_PROVV_CASSA_ORD_SCARTO
          ( provvisorio_scarto_id,
		  	anno_esercizio,
            ordinativo_id,
            provvisorio_id,
			tipo_eu,
            motivo_scarto,
			fl_migrato,
            ente_proprietario_id )
          (select 
            migr_provv_cas_ord_sca_id_seq.nextval,
			pAnnoEsercizio,
			os.ordinativo_scarto_id,
            0,
			'S',
            'Collegamento ordinativo provvisorio con ordinativo spesa non migrato',
			'N',
            pEnte
           from  rel_mandati_provvisori rel, migr_ordinativo_spesa_scarto os  
           where rel.anno_esercizio=pAnnoEsercizio
		     and rel.anno_esercizio=os.anno_esercizio
			 and rel.nmand=os.numero_ordinativo
			 and os.ente_proprietario_id=pEnte
			 and not exists (select 1 from migr_ordinativo_spesa migr
                                         where migr.numero_ordinativo=rel.nmand
                                         and   migr.anno_esercizio=rel.anno_esercizio
										 and   migr.ente_proprietario_id=pEnte));
               
          msgRes := 'Inserimento in migr_ordinativi_provv_cassa scarto. Scarti per ordinativo entrata non migrato.';
          
          insert into    MIGR_PROVV_CASSA_ORD_SCARTO
          ( provvisorio_scarto_id,
		  	anno_esercizio,
            ordinativo_id,
            provvisorio_id,
			tipo_eu,
            motivo_scarto,
			fl_migrato,
            ente_proprietario_id  )
          (select 
            migr_provv_cas_ord_sca_id_seq.nextval,
			pAnnoEsercizio,
			os.ordinativo_scarto_id,
            0,
			'E',
            'Collegamento ordinativo provvisorio con ordinativo entrata non migrato',
			'N',
            pEnte
		   from  rel_riscossioni_provvisori rel, migr_ordinativo_entrata_scarto os   
           where rel.anno_esercizio=pAnnoEsercizio
		     and rel.anno_esercizio=os.anno_esercizio
			 and rel.nriscos=os.numero_ordinativo
			 and os.ente_proprietario_id=pEnte
			 and not exists (select 1 from migr_ordinativo_entrata migr
                                         where migr.numero_ordinativo=rel.nriscos
                                         and   migr.anno_esercizio=rel.anno_esercizio
										 and   migr.ente_proprietario_id=pEnte));
               
          msgRes := 'Inserimento in migr_ordinativi_provv_cassa scarto. Scarti per provvisorio cassa spesa non migrato.';
          
          insert into    MIGR_PROVV_CASSA_ORD_SCARTO
          ( provvisorio_scarto_id,
		  	anno_esercizio,
            ordinativo_id,
            provvisorio_id,
			tipo_eu,
            motivo_scarto,
			fl_migrato,
            ente_proprietario_id )
          (select 
            migr_provv_cas_ord_sca_id_seq.nextval,
			pAnnoEsercizio,
			0,
			pcs.provvisorio_scarto_id,
			pcs.tipo_eu,
            'Collegamento ordinativo provvisorio con provvisorio cassa spesa non migrato',
			'N',
            pEnte
		   from  rel_mandati_provvisori rel, migr_provv_cassa_scarto pcs   
           where rel.anno_esercizio=pAnnoEsercizio
		     and rel.anno_esercizio=pcs.anno_esercizio
			 and rel.nprov=pcs.numero_provvisorio
			 and pcs.tipo_eu = 'S'
			 and pcs.ente_proprietario_id=pEnte
			 and not exists (select 1 from migr_provv_cassa migr
                                         where migr.anno_provvisorio=rel.anno_prov
										 and   migr.numero_provvisorio=rel.nprov
										 and   migr.tipo_eu = 'S'
										 and   migr.ente_proprietario_id=pEnte));
               
          msgRes := 'Inserimento in migr_ordinativi_provv_cassa scarto. Scarti per provvisorio cassa entrata non migrato.';
          
          insert into    MIGR_PROVV_CASSA_ORD_SCARTO
          ( provvisorio_scarto_id,
		  	anno_esercizio,
            ordinativo_id,
            provvisorio_id,
			tipo_eu,
            motivo_scarto,
			fl_migrato,
            ente_proprietario_id )
          (select 
            migr_provv_cas_ord_sca_id_seq.nextval,
			pAnnoEsercizio,
			0,
			pcs.provvisorio_scarto_id,
			pcs.tipo_eu,
            'Collegamento ordinativo provvisorio con provvisorio cassa entrata non migrato',
			'N',
            pEnte
		   from  rel_riscossioni_provvisori rel, migr_provv_cassa_scarto pcs  
           where rel.anno_esercizio=pAnnoEsercizio
		     and rel.anno_esercizio=pcs.anno_esercizio
			 and rel.nprov=pcs.numero_provvisorio
			 and pcs.tipo_eu = 'E'
			 and pcs.ente_proprietario_id=pEnte
			 and not exists (select 1 from migr_provv_cassa migr
                                         where migr.anno_provvisorio=rel.anno_prov
										 and   migr.numero_provvisorio=rel.nprov
										 and   migr.tipo_eu = 'E'
										 and   migr.ente_proprietario_id=pEnte));
          
          msgRes := 'Inserimento in migr_provv_cassa_ordinativo spesa.';
           /* Inserimento collegamenti ordinativi di SPESA con provvisori cassa di SPESA */
          insert into migr_provv_cassa_ordinativo 
          (provvisorio_id,
           tipo_eu,
           ordinativo_id,
           ord_numero,
           anno_esercizio,
           anno_provvisorio,
           numero_provvisorio,
           importo,
           ente_proprietario_id)
          (select 
                  migr_provv_cassa_ord_id_seq.nextval,
			      --pcs.provvisorio_id,
                  'S',
			      os.ordinativo_id,
			      rel.nmand,
                  rel.anno_esercizio,
			      rel.anno_prov,
                  rel.nprov,
                  rel.importo,
                  pEnte
             from rel_mandati_provvisori rel, migr_ordinativo_spesa os, migr_provv_cassa pcs
            where rel.anno_esercizio = pAnnoEsercizio
			  and rel.anno_esercizio = os.anno_esercizio
			  and rel.nmand = os.numero_ordinativo
			  and rel.anno_prov = pcs.anno_provvisorio
			  and rel.nprov = pcs.numero_provvisorio
			  and pcs.tipo_eu = 'S'
			  and os.ente_proprietario_id = pcs.ente_proprietario_id
			  and os.ente_proprietario_id = pEnte); 
          
           msgRes := 'Inserimento in migr_provv_cassa_ordinativo entrata.';
           /* Inserimento collegamenti ordinativi di ENTRATA con provvisori cassa di ENTRATA */
          insert into migr_provv_cassa_ordinativo 
          (provvisorio_id,
           tipo_eu,
           ordinativo_id,
           ord_numero,
           anno_esercizio,
           anno_provvisorio,
           numero_provvisorio,
           importo,
           ente_proprietario_id)
          (select 
                  migr_provv_cassa_ord_id_seq.nextval,
			      --pce.provvisorio_id,
                  'E',
			      oe.ordinativo_id,
			      rel.nriscos,
                  rel.anno_esercizio,
			      rel.anno_prov,
                  rel.nprov,
                  rel.importo,
                  pEnte
             from rel_riscossioni_provvisori rel, migr_ordinativo_entrata oe, migr_provv_cassa pce
            where rel.anno_esercizio = pAnnoEsercizio
			  and rel.anno_esercizio = oe.anno_esercizio
			  and rel.nriscos = oe.numero_ordinativo
			  and rel.anno_prov = pce.anno_provvisorio
			  and rel.nprov = pce.numero_provvisorio
			  and pce.tipo_eu = 'E'
			  and oe.ente_proprietario_id = pce.ente_proprietario_id
			  and oe.ente_proprietario_id = pEnte); 

   select count(*) into cProvvUscInserti
   from migr_provv_cassa_ordinativo
   where anno_provvisorio = pAnnoEsercizio
     and tipo_eu = 'S';                   
                      
   select count(*) into cProvvUscScartati
   from migr_provv_cassa_ord_scarto
   where anno_esercizio = pAnnoEsercizio
     and tipo_eu = 'S';    

   select count(*) into cProvvEntInserti
   from migr_provv_cassa_ordinativo
   where anno_provvisorio = pAnnoEsercizio
     and tipo_eu = 'E';                   
     
   select count(*) into cProvvEntScartati
   from migr_provv_cassa_ord_scarto
   where anno_esercizio = pAnnoEsercizio
     and tipo_eu = 'E';                   


    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Provvisori Cassa Ordinativi inseriti di spesa=' ||
                 cProvvUscInserti || ' di entrata=' || cProvvEntInserti ||'.'||
                 'Provvisori Cassa Ordinativi scartati di spesa='|| 
                 cProvvUscScartati || ' di entrata=' || cProvvEntScartati ||'.';


    pProvvScartati := cProvvUscScartati+cProvvEntScartati;
    pProvvInseriti := cProvvUscInserti + cProvvEntInserti;
    commit;

   exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
  END migr_ord_provv_cassa;
  
  procedure migrazione_ordinativo_spesa(pEnte number,
                                        pAnnoEsercizio       varchar2,
                                        pCodRes              out number,
                                        pOrdInseriti         out number,
                                        pOrdScartati         out number,
                                        pOrdSegnalati        out number,
                                        pMsgRes              out varchar2)
  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        tipoScarto varchar2(50):=null;
        msgRes  varchar2(1500) := null;
        cOrdInseriti number := 0;
        cOrdScartati number := 0;
        cOrdSegnalati number := 0;
        numInsert number := 0; --serve per contare i record e committare al 200esimo

        h_rec varchar2(50) := null;

        h_classificatore_1 varchar2(500):=null;
        h_classificatore_2 varchar2(500):=null;
        h_classificatore_3 varchar2(500):=null;
        h_classificatore_4 varchar2(500):=null;
        h_pdc_finanziario  varchar2(100):=null;
        h_transazione_ue_spesa varchar2(50):=null;
        h_spesa_ricorrente varchar2(50):=null;
        h_perimetro_sanitario_spesa varchar2(50):=null;
        h_politiche_regionali_unitarie varchar2(50):=null;
        h_pdc_economico_patr varchar2(50):=null;
        h_cofog varchar2(50):=null;
        h_siope_spesa varchar2(50):=null;
        h_stato_operativo varchar2(1):=null;

        ERROR_ORDINATIVO EXCEPTION;

      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_ordinativo_spesa.Uno o pi� parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin

            msgRes := 'Pulizia tabelle di migrazione ordinativo spesa.';

            DELETE FROM MIGR_ORDINATIVO_SPESA WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_ORDINATIVO_SPESA_SCARTO where ente_proprietario_id = pEnte;

        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
               for migrCursor in (
                        select
                              m.anno_esercizio anno_esercizio,
                              m.nmand numero_ordinativo,
                              m.nro_capitolo  numero_capitolo,
                              m.nro_articolo  numero_articolo,
                              '1'             numero_ueb,
                              m.descri        descrizione,
                              to_char(m.dataemis ,'dd/mm/yyyy') data_emissione,
                              to_char(m.dataannu,'dd/mm/yyyy') data_annullamento,
                              to_char(m.datarid,'dd/mm/yyyy') data_riduzione,
                              to_char(m.datascad,'dd/mm/yyyy') data_scadenza,
                              to_char(mif.dataspost,'dd/mm/yyyy') data_spostamento,
                              to_char(mif.datastam_mif,'dd/mm/yyyy') data_trasmissione,
                              m.staoper stato_operativo,
                              m.distinta codice_distinta,
                              m.codbol   codice_bollo,
                              TIPO_COMMISSIONI_ES codice_commissione,
                              decode(substr(m.distinta,1,1),'1',CONTO_CC_SANITA,'6',CONTO_CC_SANITA,CONTO_CC_ALTRO) codice_conto_corrente,
                              m.codben codice_soggetto,
                              m.progben codice_modpag,
                              nvl(mif.fl_alleg_cart,'N') flag_allegato_cart,
                              null note_tesoriere,
                              mif.comunic_tes comunicazioni_tes,
                              m.cup cup,
                              m.cig cig,
                              to_char(m.datatrasm,'dd/mm/yyyy') firma_ord_data,
                              mif.firma_nome firma_ord,
                              decode(m.nquiet,0,null,m.nquiet) quietanza_numero,
                              decode(m.nquiet,0,null,to_char(m.datapaga,'dd/mm/yyyy')) quietanza_data,
                              decode(m.nquiet,0,null,m.impopag) quietanza_importo,
                              decode(m.nquiet,0,null,m.cro) quietanza_codice_cro,
                              decode(m.nstorno,0,null, m.nstorno) storno_quiet_numero,
                              decode(m.nstorno,0,null, to_char(m.datastorno,'dd/mm/yyyy')) storno_quiet_data,
                              decode(m.nstorno,0,null, m.impostorno) storno_quiet_importo,
                              0 cast_competenza, 0 cast_cassa, 0 cast_emessi,
                              m.utente utente_creazione, m.utente utente_modifica,
                              m.cod_nota cod_nota,
                              m.annoimp anno_impegno,
                              m.nimp numero_impegno,
                              m.nsubimp numero_subimpegno,
                              m.nliq numero_liquidazione
                        from mandati m,mandati_mif mif,
                             migr_soggetto s, migr_modpag mdp, migr_impegno mi, migr_liquidazione liq
                        where m.anno_esercizio = pAnnoEsercizio
                        and   mif.nmand=m.nmand
                        and   mif.anno_esercizio=m.anno_esercizio
                        and   s.codice_soggetto=m.codben
                        and   s.ente_proprietario_id=pEnte
                        and   mdp.soggetto_id=s.soggetto_id
                        and   mdp.codice_modpag=m.progben
                        and   mdp.ente_proprietario_id=pEnte
                        and   mi.anno_esercizio=pAnnoEsercizio
                        and   mi.anno_impegno=m.annoimp
                        and   mi.numero_impegno=m.nimp
                        and   mi.numero_subimpegno=m.nsubimp
                        and   mi.ente_proprietario_id=pEnte
                        and   liq.anno_esercizio=pAnnoEsercizio
                        and   liq.numero_liquidazione=m.nliq
                        and   liq.ente_proprietario_id=pEnte
                        order by m.nmand)
                 loop
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            tipoScarto :=null;
                            msgRes := null;

                            h_classificatore_1:=null;
                            h_classificatore_2:=null;
                            h_classificatore_3:=null;
                            h_classificatore_4:=null;
                            h_pdc_finanziario:=null;
                            h_transazione_ue_spesa:=null;
                            h_spesa_ricorrente:=null;
                            h_perimetro_sanitario_spesa:=null;
                            h_politiche_regionali_unitarie:=null;
                            h_pdc_economico_patr:=null;
                            h_cofog:=null;
                            h_siope_spesa:=null;
                            h_stato_operativo:=null;

                            h_rec := 'Ordinativo di spesa ' || migrCursor.numero_ordinativo || '/'||migrCursor.anno_esercizio||'.';

                            -- calcolo dello stato_operativo
                            -- h_stato_operativo
                            msgRes:='Calcolo stato operativo.';
                            if migrCursor.stato_operativo=ORD_ANNULLATO then -- capire con Antonino
                               -- annullato
                               h_stato_operativo:=migrCursor.stato_operativo;
                            end if;

                            if codRes=0 and h_stato_operativo is null then
                               -- quietanzato
                               if migrCursor.quietanza_numero is not null then
                                 if migrCursor.data_trasmissione is not null then
                                    h_stato_operativo:=ORD_QUIETANZATO;
                                 else
                                    -- scarto
                                    codRes:=-1;
                                    msgMotivoScarto:='Dati quietanza senza dati trasmissione.';
                                 end if;
                               end if;
                             end if;

                             -- firmato
                             if codRes=0 and h_stato_operativo is null then
                                if migrCursor.firma_ord_data is not null then
                                 if migrCursor.data_trasmissione is not null then
                                    h_stato_operativo:=ORD_FIRMATO;
                                 else
                                    -- scarto
                                    codRes:=-1;
                                    msgMotivoScarto:='Dati firma senza dati trasmissione.';
                                 end if;
                                end if;
                             end if;

                             -- trasmesso-inserito
                             if codRes=0 and h_stato_operativo is null then
                                if migrCursor.data_trasmissione is not null then
                                      h_stato_operativo:=ORD_TRASMESSO;
                                else h_stato_operativo:=ORD_INSERITO;
                                end if;
                             end if;

                             if codRes=0 and   h_stato_operativo is null then
                                codRes:=-1;
                                msgMotivoScarto:='Stato operativo non determinato';
                             end if;

                            -- ricavo nota migrCursor.cod_nota
                            -- h_classificatore_1
                            if codRes=0 and migrCursor.cod_nota is not null then
                              begin
                              msgRes:='Lettura NOTE per classificatore_1.';
                              select n.cod_nota||'||'||n.descri into h_classificatore_1
                              from note n
                              where n.cod_nota=migrCursor.cod_nota;

                              exception
                                when no_data_found then
                                     codRes:=-1;
                                     msgRes:='Codice Nota '||migrCursor.cod_nota||' non presente in archivio [note].';
                                     msgMotivoScarto:=msgRes;
                                     tipoScarto:='ORD_CL1';
                                when others then
                                     codRes:=-1;
                                     msgRes:='Codice Nota '||migrCursor.cod_nota||' errore in reperimento dati [note].';
                                     raise ERROR_ORDINATIVO;
                              end;

                            end if;


                            -- transazione elementare -- verificare se ricavare  livelli superiori ( capitolo )
                            if codRes=0 then
                              begin
                              msgRes:='Lettura dati transazione elementare [impegni_classif].';
                              select i.conto , i.cofog, i.transaz_un_eur, i.ricorrente, i.perim_sanit, i.polit_reg_unit
                               into h_pdc_finanziario,h_cofog,h_transazione_ue_spesa, h_spesa_ricorrente,h_perimetro_sanitario_spesa,
                                    h_politiche_regionali_unitarie
                              from impegni_classif i
                              where i.annoimp=migrCursor.anno_impegno
                              and   i.nimp=migrCursor.numero_impegno;

                              exception
                                when no_data_found then
                                     codRes:=-1;
                                     msgRes:='Transazione elementare non reperita [impegni_classif].';
                                     msgMotivoScarto:=msgRes;
                                     tipoScarto:='ORD_TRB';
                                when others then
                                     codRes:=-1;
                                     msgRes:='Transazione elementare errore in reperimento [impegni_classif].';
                                     raise ERROR_ORDINATIVO;
                              end;
                            end if;

                            --- h_siope_spesa
                            if codRes=0 then
                              begin
                               msgRes:='Lettura Siope [mandati_cod_gest].';
                               select c.cod_gest into h_siope_spesa
                               from mandati_cod_gest c
                               where c.anno_esercizio=migrCursor.anno_esercizio
                               and   c.nmand=migrCursor.numero_ordinativo;

                               exception
                                when no_data_found then
                                     codRes:=-1;
                                     msgRes:='Codice Siope [mandati_cod_gest] non reperito.';
                                     msgMotivoScarto:=msgRes;
                                     tipoScarto:='ORD_SIO';
                                when others then
                                     codRes:=-1;
                                     msgRes:='Codice Siope errore in reperimento [mandati_cod_gest].';
                                     raise ERROR_ORDINATIVO;

                              end;
                            end if;
                            
                            if codRes != 0 then
                              insert into migr_ordinativo_spesa_scarto
                                (ordinativo_scarto_id,
                                 numero_ordinativo,
                                 anno_esercizio,
                                 tipo_scarto,
                                 motivo_scarto,
                                 ente_proprietario_id)
                              values
                                (migr_ord_spesa_scarto_id_seq.nextval,
                                 migrCursor.numero_ordinativo,
                                 migrCursor.anno_esercizio,
                                 tipoScarto,
                                 msgMotivoScarto,
                                 pEnte);
                                 
                              if tipoScarto is not null and tipoScarto in ('ORD_TRB','ORD_SIO','ORD_CL1') then
                                 codRes:=0;
                                 cOrdSegnalati := cOrdSegnalati + 1;
                              else   
                                 cOrdScartati := cOrdScartati + 1;
                              end if;                              
                              
                            end if;
                            
                            if codRes = 0 then
                              msgRes := 'Inserimento in migr_ordinativo_spesa.';
                              insert into migr_ordinativo_spesa
                              (ordinativo_id,
                               anno_esercizio,
                               numero_ordinativo,
                               numero_capitolo,
                               numero_articolo,
                               numero_ueb,
                               descrizione,
                               data_emissione,
                               data_annullamento,
                               data_riduzione,
                               data_scadenza,
                               data_spostamento,
                               data_trasmissione,
                               stato_operativo,
                               codice_distinta,
                               codice_bollo,
                               codice_commissione,
                               codice_conto_corrente,
                               codice_soggetto,
                               codice_modpag,
                               flag_allegato_cart,
                               note_tesoriere,  -- non gestito
                               comunicazioni_tes,
                               cup,
                               cig,
                               firma_ord_data,
                               firma_ord,
                               quietanza_numero,
                               quietanza_data,
                               quietanza_importo,
                               quietanza_codice_cro,
                               storno_quiet_numero,
                               storno_quiet_data,
                               storno_quiet_importo,
                               cast_competenza,
                               cast_cassa,
                               cast_emessi,
                               utente_creazione,
                               utente_modifica,
                               classificatore_1,
                               classificatore_2,
                               classificatore_3,
                               pdc_finanziario,
                               transazione_ue_spesa,
                               spesa_ricorrente,
                               perimetro_sanitario_spesa,
                               politiche_regionali_unitarie,
                               pdc_economico_patr, -- non gestito
                               cofog,
                               siope_spesa,
                               ente_proprietario_id)
                              values
                                (migr_ord_spesa_id_seq.nextval,
                                 migrCursor.anno_esercizio,
                                 migrCursor.numero_ordinativo,
                                 migrCursor.numero_capitolo,
                                 migrCursor.numero_articolo,
                                 migrCursor.numero_ueb,
                                 migrCursor.descrizione,
                                 migrCursor.data_emissione,
                                 migrCursor.data_annullamento,
                                 migrCursor.data_riduzione,
                                 migrCursor.data_scadenza,
                                 migrCursor.data_spostamento,
                                 migrCursor.data_trasmissione,
                                 h_stato_operativo,
                                 migrCursor.codice_distinta,
                                 migrCursor.codice_bollo,
                                 migrCursor.codice_commissione,
                                 migrCursor.codice_conto_corrente,
                                 migrCursor.codice_soggetto,
                                 migrCursor.codice_modpag,
                                 migrCursor.flag_allegato_cart,
                                 migrCursor.note_tesoriere,
                                 migrCursor.comunicazioni_tes,
                                 migrCursor.cup,
                                 migrCursor.cig,
                                 migrCursor.firma_ord_data,
                                 migrCursor.firma_ord,
                                 migrCursor.quietanza_numero,
                                 migrCursor.quietanza_data,
                                 migrCursor.quietanza_importo,
                                 migrCursor.quietanza_codice_cro,
                                 migrCursor.storno_quiet_numero,
                                 migrCursor.storno_quiet_data,
                                 migrCursor.storno_quiet_importo,
                                 migrCursor.cast_competenza,
                                 migrCursor.cast_cassa,
                                 migrCursor.cast_emessi,
                                 migrCursor.utente_creazione,
                                 migrCursor.utente_modifica,
                                 h_classificatore_1,
                                 h_classificatore_2,
                                 h_classificatore_3,
                                 h_pdc_finanziario,
                                 h_transazione_ue_spesa,
                                 h_spesa_ricorrente,
                                 h_perimetro_sanitario_spesa,
                                 h_politiche_regionali_unitarie,
                                 h_pdc_economico_patr,
                                 h_cofog,
                                 h_siope_spesa,
                                 pEnte);
                              cOrdInseriti := cOrdInseriti + 1;
                            end if;

                        

                            if numInsert >= 200 then
                              commit;
                              numInsert := 0;
                            else
                              numInsert := numInsert + 1;
                            end if;
                      end loop;




    -- gestione degli scarti
    -- 1) scarti per soggetto non migrato.
    msgRes := 'Inserimento scarti per soggetto non migrato.';
    insert into migr_ordinativo_spesa_scarto
    (ordinativo_scarto_id,
     numero_ordinativo,
     anno_esercizio,
     motivo_scarto,
     ente_proprietario_id)
     select migr_ord_spesa_scarto_id_seq.nextval, m.nmand, m.anno_esercizio, 'Soggetto non migrato',pEnte
     from mandati m
     where m.anno_esercizio = pAnnoEsercizio
     and not exists (select 1 from migr_soggetto ms where ms.codice_soggetto=m.codben
                     and ms.ente_proprietario_id=pEnte
	  );

    --2) mdp non migrata
    msgRes := 'Inserimento scarti per mdp non migrata.';
    insert into migr_ordinativo_spesa_scarto
    (ordinativo_scarto_id,
     numero_ordinativo,
     anno_esercizio,
     motivo_scarto,
     ente_proprietario_id)
     select migr_ord_spesa_scarto_id_seq.nextval, m.nmand, m.anno_esercizio, 'Mdp non migrata',pEnte
     from mandati m
     where m.anno_esercizio = pAnnoEsercizio
     and not exists (select 1 from migr_soggetto ms, migr_modpag mdp
                      where ms.codice_soggetto=m.codben
                      and mdp.soggetto_id = ms.soggetto_id
                      and mdp.codice_modpag=m.progben
					            and ms.ente_proprietario_id=mdp.ente_proprietario_id
            				  and ms.ente_proprietario_id=pEnte)
      and not exists (select 1 from migr_ordinativo_spesa_scarto s where s.numero_ordinativo=m.nmand and s.anno_esercizio=m.anno_esercizio
                       and s.ente_proprietario_id=pEnte);

    -- 3) scarti per movimento non migrato.
    msgRes := 'Inserimento scarti per movimento non migrato.';
    insert into migr_ordinativo_spesa_scarto
    (ordinativo_scarto_id,
     numero_ordinativo,
     anno_esercizio,
     motivo_scarto,
     ente_proprietario_id)
    select migr_ord_spesa_scarto_id_seq.nextval, m.nmand, m.anno_esercizio, 'Impegno non migrato',pEnte
    from mandati m
    where m.anno_esercizio = pAnnoEsercizio
    and not exists (select 1 from migr_impegno mi
                    where mi.numero_impegno= m.nimp
                    and mi.numero_subimpegno=m.nsubimp
                    and mi.anno_impegno=m.annoimp
                    and mi.anno_esercizio=m.anno_esercizio
   			            and mi.ente_proprietario_id=pEnte
                   )
     and not exists (select 1 from migr_ordinativo_spesa_scarto s where s.numero_ordinativo=m.nmand and s.anno_esercizio=m.anno_esercizio
                     and s.ente_proprietario_id=pEnte);

    -- 4) scarti per liquidazione non migrato.
    msgRes := 'Inserimento scarti per liquidazione non migrato.';
    insert into migr_ordinativo_spesa_scarto
    (ordinativo_scarto_id,
     numero_ordinativo,
     anno_esercizio,
     motivo_scarto,
     ente_proprietario_id)
     select migr_ord_spesa_scarto_id_seq.nextval, m.nmand, m.anno_esercizio, 'Liquidazione non migrata',pEnte
     from mandati m
     where m.anno_esercizio = pAnnoEsercizio
     and not exists (select 1 from migr_liquidazione mi
                     where mi.numero_liquidazione=m.nliq
                     and mi.anno_esercizio=m.anno_esercizio
                     and mi.ente_proprietario_id=pEnte
                     )
     and not exists (select 1 from migr_ordinativo_spesa_scarto s where s.numero_ordinativo=m.nmand and s.anno_esercizio=m.anno_esercizio
                     and s.ente_proprietario_id=pEnte);


    -- contiamo gli scarti ...
    select count (*) into cOrdScartati
    from migr_ordinativo_spesa_scarto 
    where ente_proprietario_id = pEnte
    and   (tipo_scarto is null or (tipo_scarto not in ('ORD_TRB','ORD_SIO','ORD_CL1')));
    
    select count (*) into cOrdSegnalati 
    from migr_ordinativo_spesa_scarto 
    where ente_proprietario_id = pEnte
    and   tipo_scarto is not null
    and   tipo_scarto in ('ORD_TRB','ORD_SIO','ORD_CL1');

    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Ordinativi di spesa inseriti=' ||
                 cOrdInseriti || ' scartati=' || cOrdScartati || ' segnalati=' || cOrdSegnalati|| '.';

    pOrdScartati := cOrdScartati;
    pOrdInseriti := cOrdInseriti;
    pOrdSegnalati := cOrdSegnalati;
    commit;

  exception
    when ERROR_ORDINATIVO then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                 msgRes );
            pMsgRes      := pMsgRes || h_rec || msgRes ;
            pOrdScartati := cOrdScartati;
            pOrdInseriti := cOrdInseriti;
            pOrdSegnalati := cOrdSegnalati;
            pCodRes      := -1;
            rollback;

    when others then
      rollback;
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pOrdScartati := cOrdScartati;
      pOrdInseriti := cOrdInseriti;
      pOrdSegnalati := cOrdSegnalati;
      pCodRes      := -1;

  END migrazione_ordinativo_spesa;




  procedure migrazione_ordinativo_spesa_ts(pEnte number,
                                           pAnnoEsercizio       varchar2,
                                           pCodRes              out number,
                                           pOrdInseriti         out number,
                                           pOrdScartati         out number,
                                           pMsgRes              out varchar2)
  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cOrdInseriti number := 0;
        cOrdScartati number := 0;
        numInsert number := 0; --serve per contare i record e committare al 200esimo
        numNCDNonAgganciate number:=0;
        h_note_agganciate number:=0;
        h_rec varchar2(50) := null;



       procedure associa_nota_credito    (pEnte number,
                                          pAnnoEsercizio       varchar2,
                                          pNumeroOrdinativo    number,
                                          pOrdinativoId        number,
                                          pCodRes              out number,
                                          pMsgRes              out varchar2,
										                      pNoteCredNonAgganciate    out number)
       is

          codRes number := 0;
          msgRes  varchar2(1500) := null;
		      h_importo_dedotto number:=0;
          h_importo_dedotto_att number:=0;
          h_importo_attuale number:=0;
       begin

       	 pNoteCredNonAgganciate:=0;
       	 pCodRes:=0;
         pMsgRes:='';

         msgRes:='Lettura quote note di credito.';
         for ordCursor in
         (select q.annofatt anno_nota_cred, q.nfatt numero_nota_cred, q.codben cod_sogg_nota_cred,q.frazione frazione_nota_cred,
                 decode(f.divisa_esercizio,'L',round(abs(q.impquota)/RAPPORTO_EURO_LIRA,2),
                                               abs(q.impquota))  importo_nota_cred, f.annofatv annofatt_rif, f.nfatv nfatt_rif
          from fatquo q, fatture f
          where q.nordin=pNumeroOrdinativo
          and   q.anno_esercizio=pAnnoEsercizio
          and   q.pagato='S'
          and   q.tipofatt='A'
          and   q.eu='U'
          and   f.eu=q.eu
          and   f.annofatt=q.annofatt
          and   f.nfatt=q.nfatt
          and   f.tipofatt=q.tipofatt
          and   f.codben=q.codben
          )
         loop

           h_importo_dedotto:=0;
		       msgRes:='Lettura dedotto per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                     ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred||'.';
		       select nvl(sum(ts.importo_nota_cred),0) into h_importo_dedotto
           from migr_ordinativo_spesa_ts ts
           where ts.ordinativo_id=pOrdinativoId
           and   ts.ente_proprietario_id=pEnte
           and   ts.importo_nota_cred is not null
           and   ts.importo_nota_cred!=0
           and   ts.numero_nota_cred    =ordCursor.numero_nota_cred
           and   ts.anno_nota_cred      =ordCursor.Anno_Nota_Cred
           and   ts.frazione_nota_cred  =ordCursor.frazione_nota_cred;

           if ordCursor.importo_nota_cred= h_importo_dedotto then
               --- ritorno al loop di lettura delle NCD
               goto continue_read_ncd;
           end if;

           -- provo ad aggiornare direttamente su una eventuale quota di pari importo
           if ordCursor.annofatt_rif is not null then
            msgRes:='Aggiornamento migr_ordinativo_spesa_ts  per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                                              ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred
																	                                                ||' DocRif Anno/Numero '
                                                                                  ||ordCursor.annofatt_Rif||'/'
																			                                            ||ordCursor.nfatt_Rif||'.Aggiornamento per importo.';

            update migr_ordinativo_spesa_ts ts
            set  ts.importo_iniziale=0,
                 ts.importo_attuale=0,
                 ts.anno_nota_cred=OrdCursor.anno_nota_cred,
                 ts.numero_nota_cred=OrdCursor.numero_nota_cred,
                 ts.cod_sogg_nota_cred=OrdCursor.cod_sogg_nota_cred,
                 ts.frazione_nota_cred=OrdCursor.frazione_nota_cred,
                 ts.importo_nota_cred=ts.importo_attuale
             where ts.ordinativo_id=pOrdinativoId
             and   ts.ente_proprietario_id=pEnte
             and   ts.numero_nota_cred is null
             and   ts.anno_documento  =ordCursor.annofatt_Rif
             and   ts.numero_documento=ordCursor.nfatt_Rif
             and   ts.tipo_documento='F'
             and   ts.importo_attuale =OrdCursor.importo_nota_cred
             and   ts.ordinativo_ts_id in
                   (select ts1.ordinativo_ts_id from migr_ordinativo_spesa_ts ts1
                    where  ts1.ordinativo_id=ts.ordinativo_id
                    and    ts1.ente_proprietario_id=ts.ente_proprietario_id
                    and    ts1.numero_nota_cred is null
                    and    ts1.anno_documento  =ts.anno_documento
                    and    ts1.numero_documento=ts.numero_documento
                    and    ts1.tipo_documento='F'
                    and    ts1.importo_attuale=OrdCursor.importo_nota_cred
                    and    rownum=1);

          else
            msgRes:='Aggiornamento migr_ordinativo_spesa_ts  per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                                              ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred
																	                                                ||'.Aggiornamento per importo.';
            update migr_ordinativo_spesa_ts ts
            set  ts.importo_iniziale=0,
                 ts.importo_attuale=0,
                 ts.anno_nota_cred=OrdCursor.anno_nota_cred,
                 ts.numero_nota_cred=OrdCursor.numero_nota_cred,
                 ts.cod_sogg_nota_cred=OrdCursor.cod_sogg_nota_cred,
                 ts.frazione_nota_cred=OrdCursor.frazione_nota_cred,
                 ts.importo_nota_cred=ts.importo_attuale
             where ts.ordinativo_id=pOrdinativoId
             and   ts.ente_proprietario_id=pEnte
             and   ts.numero_nota_cred is null
             and   ts.importo_attuale=OrdCursor.importo_nota_cred
             and   ts.ordinativo_ts_id in
                   (select ts1.ordinativo_ts_id from migr_ordinativo_spesa_ts ts1
                    where  ts1.ordinativo_id=ts.ordinativo_id
                    and    ts1.ente_proprietario_id=ts.ente_proprietario_id
                    and    ts1.numero_nota_cred is null
                    and    ts1.importo_attuale=OrdCursor.importo_nota_cred
                    and    rownum=1);

          end if;

          h_importo_dedotto:=0;
		      msgRes:='Lettura dedotto per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                     ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred||' dopo aggiornamento per importo.';
		      select nvl(sum(ts.importo_nota_cred),0) into h_importo_dedotto
          from migr_ordinativo_spesa_ts ts
          where ts.ordinativo_id=pOrdinativoId
          and   ts.ente_proprietario_id=pEnte
          and   ts.importo_nota_cred is not null
          and   ts.importo_nota_cred!=0
          and   ts.numero_nota_cred    =ordCursor.numero_nota_cred
          and   ts.anno_nota_cred      =ordCursor.Anno_Nota_Cred
          and   ts.frazione_nota_cred  =ordCursor.frazione_nota_cred;

          if ordCursor.importo_nota_cred= h_importo_dedotto then
               --- ritorno al loop di lettura delle NCD
               goto continue_read_ncd;
          end if;

     		  if ordCursor.annofatt_rif is not null then
		          msgRes:='Lettura migr_ordinativo_spesa_ts  per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                                          ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred
                                                                       				||' DocRif Anno/Numero '
                                                                              ||ordCursor.annofatt_Rif||'/'
                                         																			||ordCursor.nfatt_Rif||'.';
            for migrCursorTs in
            (select ts.ordinativo_id, ts.ordinativo_ts_id,
                    ts.anno_documento, ts.numero_documento,ts.frazione_documento,ts.tipo_documento,ts.cod_soggetto_documento
     		     from migr_ordinativo_spesa_ts ts
             where ts.ordinativo_id=pOrdinativoId
             and   ts.ente_proprietario_id=pEnte
             and   ts.numero_nota_cred is null
             and   ts.anno_documento  =ordCursor.annofatt_Rif
             and   ts.numero_documento=ordCursor.nfatt_Rif
             and   ts.tipo_documento='F'
             and   ts.importo_attuale>0
             order by ts.frazione_documento
            )
            loop
             h_importo_dedotto:=0;
             msgRes:='Lettura migr_ordinativo_spesa_ts  per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                                         ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred
                                                                             ||' DocRif Anno/Numero '
                                                                             ||ordCursor.annofatt_Rif||'/'
                                                                             ||ordCursor.nfatt_Rif||'. Calcolo importo dedotto.';
             select nvl(sum(ts.importo_nota_cred),0) into h_importo_dedotto
             from migr_ordinativo_spesa_ts ts
             where ts.ordinativo_id=pOrdinativoId
             and   ts.ente_proprietario_id=pEnte
             and   ts.importo_nota_cred is not null
             and   ts.importo_nota_cred!=0
             and   ts.numero_nota_cred    =ordCursor.numero_nota_cred
             and   ts.anno_nota_cred      =ordCursor.Anno_Nota_Cred
             and   ts.frazione_nota_cred  =ordCursor.frazione_nota_cred;



             if ordCursor.importo_nota_cred!= h_importo_dedotto then
            			msgRes:='Aggiornamento migr_ordinativo_spesa_ts  per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                                              ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred
																	                                                ||' DocRif Anno/Numero '
                                                                                  ||ordCursor.annofatt_Rif||'/'
																			                                            ||ordCursor.nfatt_Rif||'.Aggiornamento td_id='
                                                                                  ||migrCursorTs.ordinativo_ts_id||'.';
                  update migr_ordinativo_spesa_ts ts
                  set  ts.importo_iniziale=decode(sign(ts.importo_iniziale-(OrdCursor.importo_nota_cred-h_importo_dedotto)),-1,
                                                      0,
                                                      ts.importo_iniziale-((OrdCursor.importo_nota_cred-h_importo_dedotto))),
                       ts.importo_attuale=decode(sign(ts.importo_attuale-(OrdCursor.importo_nota_cred-h_importo_dedotto)),-1,
                                                      0,
                                                      ts.importo_attuale-((OrdCursor.importo_nota_cred-h_importo_dedotto))),
                       ts.anno_nota_cred=OrdCursor.anno_nota_cred,
                       ts.numero_nota_cred=OrdCursor.numero_nota_cred,
                       ts.cod_sogg_nota_cred=OrdCursor.cod_sogg_nota_cred,
                       ts.frazione_nota_cred=OrdCursor.frazione_nota_cred,
                       ts.importo_nota_cred=decode(sign(ts.importo_attuale-(OrdCursor.importo_nota_cred-h_importo_dedotto)),-1,
				                                                ts.importo_attuale,
                                                        OrdCursor.importo_nota_cred-h_importo_dedotto)
                   where ts.ordinativo_ts_id=migrCursorTs.ordinativo_ts_id
                   --and   ts.ordinativo_id=pOrdinativoId
                   and   ts.ente_proprietario_id=pEnte;
             end if;

             h_importo_dedotto:=0;
             msgRes:='Lettura migr_ordinativo_spesa_ts  per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                                          ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred
                                                                              ||' DocRif Anno/Numero '
                                                                              ||ordCursor.annofatt_Rif||'/'
                                                                              ||ordCursor.nfatt_Rif||'. Calcolo importo dedotto.';
             select nvl(sum(ts.importo_nota_cred),0) into h_importo_dedotto
             from migr_ordinativo_spesa_ts ts
             where ts.ordinativo_id=pOrdinativoId
             and   ts.ente_proprietario_id=pEnte
             and   ts.importo_nota_cred is not null
             and   ts.importo_nota_cred!=0
             and   ts.numero_nota_cred  =ordCursor.numero_nota_cred
             and   ts.anno_nota_cred    =ordCursor.Anno_Nota_Cred
             and   ts.cod_sogg_nota_cred=OrdCursor.cod_sogg_nota_cred
             and   ts.frazione_nota_cred=OrdCursor.frazione_nota_cred;


             exit when ordCursor.importo_nota_cred=h_importo_dedotto;
            end loop;
          end if;

          if  ordCursor.importo_nota_cred=h_importo_dedotto then
               --- ritorno al loop di lettura delle NCD
               goto continue_read_ncd;
          end if;

          msgRes:='Lettura migr_ordinativo_spesa_ts  per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                                      ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred
                                                                          ||' ts_id non collegati a NCD.';
     		  --h_importo_dedotto:=0;
          for migrCursorTs1 in
          (select ts.ordinativo_id, ts.ordinativo_ts_id,
                  ts.anno_documento, ts.numero_documento,ts.tipo_documento,ts.cod_soggetto_documento,ts.importo_attuale
           from migr_ordinativo_spesa_ts ts
           where ts.ordinativo_id=pOrdinativoId
           and   ts.ente_proprietario_id=pEnte
           and   ts.numero_nota_cred is null
           order by ts.importo_attuale desc)
           loop

              h_importo_dedotto_att:=0;
              h_importo_attuale:=0;

              if migrCursorTs1.importo_attuale>=OrdCursor.importo_nota_cred-h_importo_dedotto then
              			     h_importo_attuale:=migrCursorTs1.importo_attuale-(OrdCursor.importo_nota_cred-h_importo_dedotto);
                         h_importo_dedotto_att:=OrdCursor.importo_nota_cred-h_importo_dedotto;
                         h_importo_dedotto:=h_importo_dedotto+ h_importo_dedotto_att;

              else
                 h_importo_dedotto:= h_importo_dedotto+migrCursorTs1.importo_attuale;
                 h_importo_dedotto_att:=migrCursorTs1.importo_attuale;
              end if;

              msgRes:='Aggiornamento migr_ordinativo_spesa_ts  per NCD Anno/Numero '||ordCursor.Anno_Nota_Cred||'/'
		                                                                          ||ordCursor.numero_nota_cred||' quota='||ordCursor.frazione_nota_cred
                                                                              ||' ts_id non collegati a NCD. Aggiornamento ts_id='||migrCursorTs1.ordinativo_ts_id||'.';
              update migr_ordinativo_spesa_ts ts
              set  ts.importo_iniziale=h_importo_attuale,
                   ts.importo_attuale=h_importo_attuale,
                   ts.anno_nota_cred=OrdCursor.anno_nota_cred,
                   ts.numero_nota_cred=OrdCursor.numero_nota_cred,
                   ts.cod_sogg_nota_cred=OrdCursor.cod_sogg_nota_cred,
                   ts.frazione_nota_cred=OrdCursor.frazione_nota_cred,
                   ts.importo_nota_cred=h_importo_dedotto_att
               where ts.ordinativo_ts_id=migrCursorTs1.ordinativo_ts_id
               and   ts.ente_proprietario_id=pEnte;

               exit when h_importo_dedotto=OrdCursor.importo_nota_cred;

            end loop;

            <<continue_read_ncd>>
            null;
         end loop;

         -- controllo che tutte le note di credito associate all'ordinativo siano state agganciate ad una quota, diversamente scartare
         msgRes:='Lettura quote note di credito non collegate a migr_ordinativo_spesa_ts.';
         select nvl(count(*),0) into pNoteCredNonAgganciate
         from fatquo q
         where q.nordin=pNumeroOrdinativo
         and   q.anno_esercizio=pAnnoEsercizio
         and   q.pagato='S'
         and   q.tipofatt='A'
         and   q.eu='U'
         and   not exists (select 1 from migr_ordinativo_spesa_ts ts
		                       where ts.ordinativo_id=pOrdinativoId
                           and   ts.ente_proprietario_id=pente
                           and   ts.anno_nota_cred=q.annofatt
                           and   ts.numero_nota_cred=q.nfatt
                           and   ts.frazione_nota_cred=q.frazione
                           and   ts.importo_nota_cred is not null
                           and   ts.importo_nota_cred!=0);

         msgRes:='Lettura quote note di credito.Quote non collegate='||pNoteCredNonAgganciate||'.';
         pMsgRes:=MsgRes;

       exception
       when others then
        dbms_output.put_line(' msgRes ' ||msgRes || ' Errore ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100));
        pMsgRes      := pMsgRes || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        pCodRes      := -1;
       end;


      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_ordinativo_spesa_ts.Uno o pi� parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin

            msgRes := 'Pulizia tabelle di migrazione quote ordinativo spesa.';

            DELETE FROM MIGR_ORDINATIVO_SPESA_TS WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_ORDINATIVO_SPE_TS_SCARTO where ente_proprietario_id = pEnte;

        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
               for migrCursor in (
                        select
                              migr.ordinativo_id,
                              migr.anno_esercizio,
                              migr.numero_ordinativo,
                              migr.descrizione,
                              migr.data_scadenza,
                              m.annoimp anno_impegno,
                              m.nimp    numero_impegno,
                              m.nsubimp numero_subimpegno,
                              m.nliq numero_liquidazione,
                              m.imporid importo_attuale
                        from mandati m, migr_ordinativo_spesa migr    -- 10.03.2016 Sofia se l'ordinativo e'' in migr impegno e liquidazione sono stati migrati
                        where m.anno_esercizio=pAnnoEsercizio
                        and   migr.numero_ordinativo=m.nmand
                        and   migr.anno_esercizio=m.anno_esercizio
                        and   migr.ente_proprietario_id=pEnte
                        and   migr.fl_scarto='N'
                        order by m.nmand)
                 loop
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            msgRes := null;
                            numNCDNonAgganciate:=0;
                            h_note_agganciate:=0;

                            h_rec := 'Ordinativo di spesa quota' || migrCursor.numero_ordinativo || '/'||migrCursor.anno_esercizio||'.';


                            msgRes:='Inserimento quote legate a quote fattura.';
                            insert into migr_ordinativo_spesa_ts
                            ( ordinativo_ts_id,
                              ordinativo_id,
                              anno_esercizio,
                              numero_ordinativo,
                              quota_ordinativo,
                              anno_impegno,
                              numero_impegno,
                              numero_subimpegno,
                              numero_liquidazione,
                              data_scadenza,
                              descrizione,
                              importo_iniziale,
                              importo_attuale,
                              anno_documento,
                              numero_documento,
                              tipo_documento,
                              cod_soggetto_documento,
                              frazione_documento,
                              ente_proprietario_id
                             )
                            (
                             select migr_ord_spesa_ts_id_seq.nextval,
                                    migrCursor.ordinativo_id,
                                    migrCursor.anno_esercizio,
                                    migrCursor.numero_ordinativo,
                                    rownum,
                                    migrCursor.anno_impegno,
                                    migrCursor.numero_impegno,
                                    migrCursor.numero_subimpegno,
                                    migrCursor.numero_liquidazione,
                                    migrCursor.data_scadenza,
                                    migrCursor.descrizione,
                                    decode(fa.divisa_esercizio, 'L' , round(f.impquota/RAPPORTO_EURO_LIRA,2),
                                                                      f.impquota),
                                    decode(fa.divisa_esercizio, 'L' , round(f.impquota/RAPPORTO_EURO_LIRA,2),
                                                                      f.impquota),
                                    f.annofatt,
                                    f.nfatt,
                                    f.tipofatt,
                                    f.codben,
                                    f.frazione,
                                    pEnte
                             from fatquo f, fatture fa
                             where f.anno_esercizio = migrCursor.anno_esercizio
                             and   f.nordin         = migrCursor.numero_ordinativo
                             and   f.pagato         ='S'
                             and   f.eu='U'
                             and   f.tipofatt!='A' -- escludo
                             and   fa.annofatt=f.annofatt
                             and   fa.nfatt=f.nfatt
                             and   fa.tipofatt=f.tipofatt
                             and   fa.eu=f.eu
                             and   fa.codben=f.codben
                            );

                            -- procedure di sistemazione delle quote per le note di credito da implementare
                            -- riduzione degli importi delle quote su cui associare anche la nota credito
                            -- in postgres non fare creare le quote di ordinativo a 0 dire ad Antonino
                            -- per ora creazione delle quote ordinativo a 0 sulla migr
                            -- tracciando  i dati sia della F che della A e dei relativi importi
                            -- quindi modificare poi la migrazione dei doc per
                            -- associare l'importo da dedurre sulla F importo uguale alla A tracciato sulla migr_ordinativo_spesa_ts
                            -- non associare alle quote doc (F,A) le quote ordinativo

                            -- se esistono note credito associate -- richiamare la successiva e gestire eventuali scarti

                            msgRes:='Calcolo quote Note Credito legate a ordinativo.';
                            select nvl(count(*),0 ) into  h_note_agganciate
                            from fatquo q
                            where q.anno_esercizio=migrCursor.anno_esercizio
                            and   q.nordin=migrCursor.numero_ordinativo
                            and   q.eu='U'
                            and   q.tipofatt='A'
                            and   q.pagato='S';

                            if h_note_agganciate!=0 then
                             associa_nota_credito    (pEnte,
                                                      migrCursor.anno_esercizio,
                                                      migrCursor.numero_ordinativo,
                                                      migrCursor.ordinativo_id,
                                                      codRes,
                                                      msgRes,
                                                      numNCDNonAgganciate);

                             -- se non ha agganciato tutte le quote NCD
                             -- inserisco in migr_ordinativo_spesa_ts_scarto tutte le ts
                             -- cancello i records ts inseriti
                             -- a termine procedure manda in scarto tutto ordinativo
                             if codRes=0 and numNCDNonAgganciate!=0 then
                               msgRes:='Inserimento migr_ordinativo_spesa_scarto per numNCDNonAgganciate='||numNCDNonAgganciate||'.';
                               -- inserimento in migr_ordinativo_spe_ts_scarto per tutte le quote_ts inserite
                               insert into migr_ordinativo_spe_ts_scarto
                               (ordinativo_ts_scarto_id,
                                quota_ordinativo,
                                numero_ordinativo,
                                anno_esercizio,
                                motivo_scarto,
                                ente_proprietario_id)
                                ( select migr_ord_spe_ts_scarto_id_seq.nextval,
                                         ts.quota_ordinativo,
                                         migrCursor.numero_ordinativo,
                                         migrCursor.anno_esercizio,
                                         'Quote NDC non collegate='||numNCDNonAgganciate||'.',
                                         ts.ente_proprietario_id
                                 from migr_ordinativo_spesa_ts  ts
                                 where ordinativo_id=migrCursor.ordinativo_id
                                 and   ente_proprietario_id=pEnte);

                                msgRes:='Cancellazione migr_ordinativo_spesa_ts per numNCDNonAgganciate='||numNCDNonAgganciate||'.';
                                delete migr_ordinativo_spesa_ts
                                where ordinativo_id=migrCursor.ordinativo_id
                                and   ente_proprietario_id=pEnte;
								                -- simulo il continue
                                goto continue_loop;
                             end if;
                            end if;

                            msgRes:='Inserimento quota non legata a fattura.';
                            insert into migr_ordinativo_spesa_ts
                            ( ordinativo_ts_id,
                              ordinativo_id,
                              anno_esercizio,
                              numero_ordinativo,
                              quota_ordinativo,
                              anno_impegno,
                              numero_impegno,
                              numero_subimpegno,
                              numero_liquidazione,
                              data_scadenza,
                              descrizione,
                              importo_iniziale,
                              importo_attuale,
                              ente_proprietario_id
                             )
                            (select migr_ord_spesa_ts_id_seq.nextval,
                                    migrCursor.ordinativo_id,
                                    migrCursor.anno_esercizio,
                                    migrCursor.numero_ordinativo,
                                    TS.ult_quota+1,
                                    migrCursor.anno_impegno,
                                    migrCursor.numero_impegno,
                                    migrCursor.numero_subimpegno,
                                    migrCursor.numero_liquidazione,
                                    migrCursor.data_scadenza,
                                    migrCursor.descrizione,
                                    migrCursor.importo_attuale-TS.importo_totale,
                                    migrCursor.importo_attuale-TS.importo_totale,
                                    pEnte
                             from  (select nvl(max(quota_ordinativo),0) ult_quota,
                                           nvl(sum(importo_attuale),0) importo_totale
                                    from migr_ordinativo_spesa_ts ts
                                    where ts.numero_ordinativo=migrCursor.numero_ordinativo
                                    and   ts.anno_esercizio   =migrCursor.anno_esercizio
                                    and   ts.ente_proprietario_id=pEnte) TS
                             where migrCursor.importo_attuale!=TS.importo_totale
                            );


                            cOrdInseriti := cOrdInseriti + 1;

                            if codRes != 0 then
                              -- gestione scarti al momento non previsti
                              null;
                            end if;

                            if numInsert >= 200 then
                              commit;
                              numInsert := 0;
                            else
                              numInsert := numInsert + 1;
                            end if;

                            <<continue_loop>>
                            null;
                      end loop;


    -- gestione degli scarti sulle quote AL MOMENTO non PREVISTI



    -- contiamo gli scarti ...
     msgRes:='Calcolo quote ordinativo scartate.';
    select nvl(count (*),0) into cOrdScartati from migr_ordinativo_spe_ts_scarto where ente_proprietario_id = pEnte;

    -- aggiornamento migr_ordinativo_spesa per fl_scarto='S' se non si inserisce neanche una quota
    msgRes:='Aggiornamento migr_ordinativo_spesa fl_scarto per ordinativi senza quote migrate.';
    update migr_ordinativo_spesa m
    set fl_scarto='S'
    where m.anno_esercizio=pAnnoEsercizio
    and   m.ente_proprietario_id=pEnte
    and   m.fl_scarto!='S'
    and   not exists (select 1
                      from migr_ordinativo_spesa_ts s
                      where s.ordinativo_id=m.ordinativo_id
                      and   s.ente_proprietario_id=m.ente_proprietario_id
                      and   s.fl_scarto!='S');

    msgRes:='Aggiornamento migr_ordinativo_spesa fl_scarto per ordinativi senza quote migrate con importo valorizzato.';
    update migr_ordinativo_spesa m
    set fl_scarto='S'
    where m.anno_esercizio=pAnnoEsercizio
    and   m.ente_proprietario_id=pEnte
    and   m.fl_scarto!='S'
    and   not exists (select 1
                      from migr_ordinativo_spesa_ts s
                      where s.ordinativo_id=m.ordinativo_id
                      and   s.ente_proprietario_id=m.ente_proprietario_id
                      and   s.fl_scarto!='S'
                      and   s.importo_attuale!=0);

    --  aggiornamento migr_ordinativo_spesa per fl_scarto='S' se ci sono quote in scarto
    msgRes:='Aggiornamento migr_ordinativo_spesa fl_scarto per ordinativi con quote scartate.';
    update migr_ordinativo_spesa m
    set fl_scarto='S'
    where m.anno_esercizio=pAnnoEsercizio
    and   m.ente_proprietario_id=pEnte
    and   m.fl_scarto!='S'
    and exists (select 1 from migr_ordinativo_spe_ts_scarto ts
                where ts.numero_ordinativo=m.numero_ordinativo
                and   ts.anno_esercizio=m.anno_esercizio
                and   ts.ente_proprietario_id=m.ente_proprietario_id);

    --  aggiornamento migr_ordinativo_spesa_ts per fl_scarto='S' se ci sono altre quote in scarto
    msgRes:='Aggiornamento migr_ordinativo_spesa_ts fl_scarto per quote ordinativi con altre scartate.';
    update migr_ordinativo_spesa_ts m
    set fl_scarto='S'
    where m.anno_esercizio=pAnnoEsercizio
    and   m.ente_proprietario_id=pEnte
    and exists (select 1 from migr_ordinativo_spe_ts_scarto ts
                where ts.numero_ordinativo=m.numero_ordinativo
                and   ts.anno_esercizio=m.anno_esercizio
                and   ts.ente_proprietario_id=m.ente_proprietario_id);


    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Ordinativi di spesa quote inseriti=' ||
                 cOrdInseriti || ' scartati=' || cOrdScartati || '.';

    pOrdScartati := cOrdScartati;
    pOrdInseriti := cOrdInseriti;
    commit;

  exception
    when others then
      rollback;
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pOrdScartati := cOrdScartati;
      pOrdInseriti := cOrdInseriti;
      pCodRes      := -1;

  END migrazione_ordinativo_spesa_ts;

procedure migrazione_ordinativo_entrata(pEnte number,
                                        pAnnoEsercizio       varchar2,
                                        pCodRes              out number,
                                        pOrdInseriti         out number,
                                        pOrdScartati         out number,
                                        pOrdSegnalati        out number,
                                        pMsgRes              out varchar2)
  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        tipoScarto varchar2(50):=null;
        msgRes  varchar2(1500) := null;
        cOrdInseriti number := 0;
        cOrdScartati number := 0;
        cOrdSegnalati number := 0;
        numInsert number := 0; --serve per contare i record e committare al 200esimo

        h_rec varchar2(50) := null;

        h_classificatore_1 varchar2(500):=null;
        h_classificatore_2 varchar2(500):=null;
        h_classificatore_3 varchar2(500):=null;
        h_classificatore_4 varchar2(500):=null;
        h_pdc_finanziario  varchar2(100):=null;
        h_transazione_ue_entrata varchar2(50):=null;
        h_entrata_ricorrente varchar2(50):=null;
        h_perimetro_sanitario_entrata varchar2(50):=null;
        h_pdc_economico_patr varchar2(50):=null;
        h_siope_entrata varchar2(50):=null;
        h_stato_operativo varchar2(1):=null;

        ERROR_ORDINATIVO EXCEPTION;

      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_ordinativo_entrata.Uno o pi� parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin

            msgRes := 'Pulizia tabelle di migrazione ordinativo entrata.';

            DELETE FROM MIGR_ORDINATIVO_ENTRATA WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_ORDINATIVO_ENTRATA_SCARTO where ente_proprietario_id = pEnte;

        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
               for migrCursor in (
                        select
                              m.anno_esercizio anno_esercizio,
                              m.nriscos numero_ordinativo,
                              risc.nro_capitolo  numero_capitolo,
                              risc.nro_articolo  numero_articolo,
                              '1'             numero_ueb,
                              m.descri        descrizione,
                              to_char(m.dataemis ,'dd/mm/yyyy') data_emissione,
                              to_char(m.dataannu,'dd/mm/yyyy') data_annullamento,
                              to_char(m.datarid,'dd/mm/yyyy') data_riduzione,
                              to_char(m.datascad,'dd/mm/yyyy') data_scadenza,
                              to_char(mif.dataspost,'dd/mm/yyyy') data_spostamento,
                              to_char(mif.datastam_mif,'dd/mm/yyyy') data_trasmissione,
                              m.staoper stato_operativo,
                              m.distinta codice_distinta,
                              BOLLO_ESENTE   codice_bollo,
                              decode(substr(m.distinta,1,1),'1',CONTO_CC_SANITA,'6',CONTO_CC_SANITA,CONTO_CC_ALTRO) codice_conto_corrente,
                              m.codben codice_soggetto,
                              nvl(mif.fl_alleg_cart,'N') flag_allegato_cart,
                              null note_tesoriere,
                              mif.comunic_tes comunicazioni_tes,
                              to_char(mif.data_firma,'dd/mm/yyyy') firma_ord_data,
                              mif.firma_nome firma_ord,
                              decode(m.nquiet,0,null,m.nquiet) quietanza_numero,
                              decode(m.nquiet,0,null,to_char(m.datarisc,'dd/mm/yyyy')) quietanza_data,
                              decode(m.nquiet,0,null,m.imporisc) quietanza_importo,
                              null storno_quiet_numero,
                              null storno_quiet_data,
                              null storno_quiet_importo,
                              0 cast_competenza, 0 cast_cassa, 0 cast_emessi,
                              m.utente utente_creazione, m.utente utente_modifica,
                              risc.annoacc anno_accertamento,
                              risc.nacc numero_accertamento,
                              risc.nsubacc numero_subaccertamento
                        from riscossioni m,acc_risc risc, riscossioni_mif mif,
                             migr_soggetto s, migr_accertamento mi
                        where m.anno_esercizio = pAnnoEsercizio
                        and   risc.nriscos=m.nriscos
                        and   risc.anno_esercizio=m.anno_esercizio
                        and   mif.nriscos=m.nriscos
                        and   mif.anno_esercizio=m.anno_esercizio
                        and   s.codice_soggetto=m.codben
                        and   s.ente_proprietario_id=pEnte
                        and   mi.anno_esercizio=pAnnoEsercizio
                        and   mi.anno_accertamento=risc.annoacc
                        and   mi.numero_accertamento=risc.nacc
                        and   mi.numero_subaccertamento=risc.nsubacc
                        and   mi.ente_proprietario_id=pEnte
                        order by m.nriscos)
                 loop
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            tipoScarto :=null;
                            msgRes := null;

                            h_classificatore_1:=null;
                            h_classificatore_2:=null;
                            h_classificatore_3:=null;
                            h_classificatore_4:=null;
                            h_pdc_finanziario:=null;
                            h_transazione_ue_entrata:=null;
                            h_entrata_ricorrente:=null;
                            h_perimetro_sanitario_entrata:=null;
                            h_pdc_economico_patr:=null;
                            h_siope_entrata:=null;
                            h_stato_operativo:=null;
                                   
                            h_rec := 'Ordinativo di entrata ' || migrCursor.numero_ordinativo || '/'||migrCursor.anno_esercizio||'.';

                            -- calcolo dello stato_operativo
                            -- h_stato_operativo
                            msgRes:='Calcolo stato operativo.';
                            if migrCursor.stato_operativo=ORD_ANNULLATO then -- capire con Antonino
                               -- annullato
                               h_stato_operativo:=migrCursor.stato_operativo;
                            end if;

                            if codRes=0 and h_stato_operativo is null then
                               -- quietanzato
                               if migrCursor.quietanza_numero is not null then
                                 if migrCursor.data_trasmissione is not null then
                                    h_stato_operativo:=ORD_QUIETANZATO;
                                 else
                                    -- scarto
                                    codRes:=-1;
                                    msgMotivoScarto:='Dati quietanza senza dati trasmissione.';
                                 end if;
                               end if;
                             end if;

                             -- firmato
                             if codRes=0 and h_stato_operativo is null then
                                if migrCursor.firma_ord_data is not null then
                                 if migrCursor.data_trasmissione is not null then
                                    h_stato_operativo:=ORD_FIRMATO;
                                 else
                                    -- scarto
                                    codRes:=-1;
                                    msgMotivoScarto:='Dati firma senza dati trasmissione.';
                                 end if;
                                end if;
                             end if;

                             -- trasmesso-inserito
                             if codRes=0 and h_stato_operativo is null then
                                if migrCursor.data_trasmissione is not null then
                                      h_stato_operativo:=ORD_TRASMESSO;
                                else h_stato_operativo:=ORD_INSERITO;
                                end if;
                             end if;

                             if codRes=0 and   h_stato_operativo is null then
                                codRes:=-1;
                                msgMotivoScarto:='Stato operativo non determinato';
                             end if;


                            -- transazione elementare -- verificare se ricavare  livelli superiori ( capitolo )
                            if codRes=0 then
                              begin
                              msgRes:='Lettura dati transazione elementare [accertamenti_classif].';
                              select i.conto , i.transaz_un_eur, i.ricorrente, i.perim_sanit
                               into h_pdc_finanziario,h_transazione_ue_entrata, h_entrata_ricorrente,h_perimetro_sanitario_entrata
                              from accertamenti_classif i
                              where i.annoacc=migrCursor.anno_accertamento
                              and   i.nacc=migrCursor.numero_accertamento;

                              exception
                                when no_data_found then
                                     codRes:=-1;
                                     msgRes:='Transazione elementare non reperita [accertamenti_classif].';
                                     msgMotivoScarto:=msgRes;
                                     tipoScarto:='ORD_TRB';
                                when others then
                                     codRes:=-1;
                                     msgRes:='Transazione elementare errore in reperimento [accertamenti_classif].';
                                     raise ERROR_ORDINATIVO;
                              end;
                            end if;

                            --- h_siope_entrata
                            if codRes=0 then
                              begin
                               msgRes:='Lettura Siope [riscossioni_cod_gest].';
                               select c.cod_gest into h_siope_entrata
                               from riscossioni_cod_gest c
                               where c.anno_esercizio=migrCursor.anno_esercizio
                               and   c.nriscos=migrCursor.numero_ordinativo;

                               exception
                                when no_data_found then
                                     codRes:=-1;
                                     msgRes:='Codice Siope [riscossioni_cod_gest] non reperito.';
                                     msgMotivoScarto:=msgRes;
                                     tipoScarto:='ORD_SIO';
                                when others then
                                     codRes:=-1;
                                     msgRes:='Codice Siope errore in reperimento [riscossioni_cod_gest].';
                                     raise ERROR_ORDINATIVO;

                              end;
                            end if;

                            if codRes != 0 then
                              insert into migr_ordinativo_entrata_scarto
                                (ordinativo_scarto_id,
                                 numero_ordinativo,
                                 anno_esercizio,
                                 tipo_scarto,
                                 motivo_scarto,
                                 ente_proprietario_id)
                              values
                                (migr_ord_spesa_scarto_id_seq.nextval,
                                 migrCursor.numero_ordinativo,
                                 migrCursor.anno_esercizio,
                                 tipoScarto,
                                 msgMotivoScarto,
                                 pEnte);
                                 
                              if tipoScarto  in ('ORD_TRB','ORD_SIO') then
                                codRes:=0;
                                cOrdSegnalati := cOrdSegnalati + 1;
                              else
                                cOrdScartati := cOrdScartati + 1;
                              end  if;   
                              
                            end if;

                            if codRes = 0 then
                              msgRes := 'Inserimento in migr_ordinativo_entrata.';
                              insert into migr_ordinativo_entrata
                              (ordinativo_id,
                               anno_esercizio,
                               numero_ordinativo,
                               numero_capitolo,
                               numero_articolo,
                               numero_ueb,
                               descrizione,
                               data_emissione,
                               data_annullamento,
                               data_riduzione,
                               data_scadenza,
                               data_spostamento,
                               data_trasmissione,
                               stato_operativo,
                               codice_distinta,
                               codice_bollo,
                               codice_conto_corrente,
                               codice_soggetto,
                               flag_allegato_cart,
                               note_tesoriere,  -- non gestito
                               comunicazioni_tes,
                               firma_ord_data,
                               firma_ord,
                               quietanza_numero,
                               quietanza_data,
                               quietanza_importo,
                               storno_quiet_numero,
                               storno_quiet_data,
                               storno_quiet_importo,
                               cast_competenza,
                               cast_cassa,
                               cast_emessi,
                               utente_creazione,
                               utente_modifica,
                               classificatore_1,
                               classificatore_2,
                               classificatore_3,
                               pdc_finanziario,
                               transazione_ue_entrata,
                               entrata_ricorrente,
                               perimetro_sanitario_entrata,
                               pdc_economico_patr, -- non gestito
                               siope_entrata,
                               ente_proprietario_id)
                              values
                                (migr_ord_spesa_id_seq.nextval,
                                 migrCursor.anno_esercizio,
                                 migrCursor.numero_ordinativo,
                                 migrCursor.numero_capitolo,
                                 migrCursor.numero_articolo,
                                 migrCursor.numero_ueb,
                                 migrCursor.descrizione,
                                 migrCursor.data_emissione,
                                 migrCursor.data_annullamento,
                                 migrCursor.data_riduzione,
                                 migrCursor.data_scadenza,
                                 migrCursor.data_spostamento,
                                 migrCursor.data_trasmissione,
                                 h_stato_operativo,
                                 migrCursor.codice_distinta,
                                 migrCursor.codice_bollo,
                                 migrCursor.codice_conto_corrente,
                                 migrCursor.codice_soggetto,
                                 migrCursor.flag_allegato_cart,
                                 migrCursor.note_tesoriere,
                                 migrCursor.comunicazioni_tes,
                                 migrCursor.firma_ord_data,
                                 migrCursor.firma_ord,
                                 migrCursor.quietanza_numero,
                                 migrCursor.quietanza_data,
                                 migrCursor.quietanza_importo,
                                 migrCursor.storno_quiet_numero,
                                 migrCursor.storno_quiet_data,
                                 migrCursor.storno_quiet_importo,
                                 migrCursor.cast_competenza,
                                 migrCursor.cast_cassa,
                                 migrCursor.cast_emessi,
                                 migrCursor.utente_creazione,
                                 migrCursor.utente_modifica,
                                 h_classificatore_1,
                                 h_classificatore_2,
                                 h_classificatore_3,
                                 h_pdc_finanziario,
                                 h_transazione_ue_entrata,
                                 h_entrata_ricorrente,
                                 h_perimetro_sanitario_entrata,
                                 h_pdc_economico_patr,
                                 h_siope_entrata,
                                 pEnte);
                              cOrdInseriti := cOrdInseriti + 1;
                            end if;


                            if numInsert >= 200 then
                              commit;
                              numInsert := 0;
                            else
                              numInsert := numInsert + 1;
                            end if;
                      end loop;




     -- gestione degli scarti
     -- 1) scarti per soggetto non migrato.
     msgRes := 'Inserimento scarti per soggetto non migrato.';
     insert into migr_ordinativo_entrata_scarto
     (ordinativo_scarto_id,
      numero_ordinativo,
      anno_esercizio,
      motivo_scarto,
      ente_proprietario_id)
      select migr_ord_entrata_scarto_id_seq.nextval, m.nriscos, m.anno_esercizio, 'Soggetto non migrato',pEnte
      from riscossioni m
      where m.anno_esercizio = pAnnoEsercizio
      and not exists (select 1 from migr_soggetto ms where ms.codice_soggetto=m.codben
                      and ms.ente_proprietario_id=pEnte
	    );


      -- 3) scarti per movimento non migrato.
      msgRes := 'Inserimento scarti per movimento non migrato.';
      insert into migr_ordinativo_entrata_scarto
      (ordinativo_scarto_id,
       numero_ordinativo,
       anno_esercizio,
       motivo_scarto,
       ente_proprietario_id)
       select migr_ord_entrata_scarto_id_seq.nextval, m.nriscos, m.anno_esercizio, 'Accertamento non migrato',pEnte
       from riscossioni m,acc_risc risc
       where m.anno_esercizio = pAnnoEsercizio
       and   risc.nriscos=m.nriscos
       and   risc.anno_esercizio=m.anno_esercizio
       and not exists (select 1 from migr_accertamento mi
                       where mi.numero_accertamento= risc.nacc
                       and mi.numero_subaccertamento=risc.nsubacc
                       and mi.anno_accertamento=risc.annoacc
                       and mi.anno_esercizio=risc.anno_esercizio
           			       and mi.ente_proprietario_id=pEnte
                      )
       and not exists (select 1 from migr_ordinativo_entrata_scarto s where s.numero_ordinativo=m.nriscos and s.anno_esercizio=m.anno_esercizio
                       and s.ente_proprietario_id=pEnte);


    -- contiamo gli scarti ...
    select count (*) into cOrdScartati from migr_ordinativo_entrata_scarto 
    where ente_proprietario_id = pEnte 
    and   (tipo_scarto is null or  tipo_scarto not in ('ORD_SIO','ORD_TRB')) ;

    -- contiamo le segnalazioni ...
    select count (*) into cOrdSegnalati from migr_ordinativo_entrata_scarto 
    where ente_proprietario_id = pEnte 
    and   tipo_scarto is not null 
    and   tipo_scarto in ('ORD_SIO','ORD_TRB') ;


    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Ordinativi di entrata inseriti=' ||
                 cOrdInseriti || ' scartati=' || cOrdScartati || ' segnalati= '||cOrdSegnalati||  '.';

    pOrdScartati := cOrdScartati;
    pOrdInseriti := cOrdInseriti;
    pOrdSegnalati := cOrdSegnalati;
    commit;

  exception
    when ERROR_ORDINATIVO then
            dbms_output.put_line(h_rec || ' msgRes ' ||
                                 msgRes );
            pMsgRes      := pMsgRes || h_rec || msgRes ;
            pOrdScartati := cOrdScartati;
            pOrdInseriti := cOrdInseriti;
             pOrdSegnalati := cOrdSegnalati;
            pCodRes      := -1;
            rollback;

    when others then
      rollback;
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pOrdScartati := cOrdScartati;
      pOrdInseriti := cOrdInseriti;
      pOrdSegnalati := cOrdSegnalati;
      pCodRes      := -1;

  END migrazione_ordinativo_entrata;

  procedure migrazione_ordinativo_entr_ts(pEnte number,
                                             pAnnoEsercizio       varchar2,
                                             pCodRes              out number,
                                             pOrdInseriti         out number,
                                             pOrdScartati         out number,
                                             pMsgRes              out varchar2)
  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cOrdInseriti number := 0;
        cOrdScartati number := 0;
        numInsert number := 0; --serve per contare i record e committare al 200esimo
        h_rec varchar2(50) := null;


  begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_ordinativo_entrata_ts.Uno o pi� parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin

            msgRes := 'Pulizia tabelle di migrazione quote ordinativo entrata.';

            DELETE FROM MIGR_ORDINATIVO_ENTRATA_TS WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_ORDINATIVO_ENT_TS_SCARTO where ente_proprietario_id = pEnte;

        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
               for migrCursor in (
                        select
                              migr.ordinativo_id,
                              migr.anno_esercizio,
                              migr.numero_ordinativo,
                              migr.descrizione,
                              migr.data_scadenza,
                              risc.annoacc anno_accertamento,
                              risc.nacc    numero_accertamento,
                              risc.nsubacc numero_subaccertamento,
                              risc.imporid importo_attuale
                        from riscossioni m,acc_risc risc, migr_ordinativo_entrata migr -- 18.03.2016 Sofia se l'ordinativo e'' in migr accertamemto � stati migrati
                        where m.anno_esercizio=pAnnoEsercizio
                        and   risc.nriscos=m.nriscos
                        and   risc.anno_esercizio=m.anno_esercizio
                        and   migr.numero_ordinativo=m.nriscos
                        and   migr.anno_esercizio=m.anno_esercizio
                        and   migr.ente_proprietario_id=pEnte
                        and   migr.fl_scarto='N'
                        order by m.nriscos)
                 loop
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            msgRes := null;

                            h_rec := 'Ordinativo di entrata quota' || migrCursor.numero_ordinativo || '/'||migrCursor.anno_esercizio||'.';


                            msgRes:='Inserimento quote legate a quote fattura.';
                            insert into migr_ordinativo_entrata_ts
                            ( ordinativo_ts_id,
                              ordinativo_id,
                              anno_esercizio,
                              numero_ordinativo,
                              quota_ordinativo,
                              anno_accertamento,
                              numero_accertamento,
                              numero_subaccertamento,
                              data_scadenza,
                              descrizione,
                              importo_iniziale,
                              importo_attuale,
                              anno_documento,
                              numero_documento,
                              tipo_documento,
                              cod_soggetto_documento,
                              frazione_documento,
                              ente_proprietario_id
                             )
                            (
                             select migr_ord_entrata_ts_id_seq.nextval,
                                    migrCursor.ordinativo_id,
                                    migrCursor.anno_esercizio,
                                    migrCursor.numero_ordinativo,
                                    rownum,
                                    migrCursor.anno_accertamento,
                                    migrCursor.numero_accertamento,
                                    migrCursor.numero_subaccertamento,
                                    migrCursor.data_scadenza,
                                    migrCursor.descrizione,
                                    decode(fa.divisa_esercizio, 'L' , round(f.impquota/RAPPORTO_EURO_LIRA,2),
                                                                      f.impquota),
                                    decode(fa.divisa_esercizio, 'L' , round(f.impquota/RAPPORTO_EURO_LIRA,2),
                                                                      f.impquota),
                                    f.annofatt,
                                    f.nfatt,
                                    f.tipofatt,
                                    f.codben,
                                    f.frazione,
                                    pEnte
                             from fatquo f, fatture fa
                             where f.anno_esercizio = migrCursor.anno_esercizio
                             and   f.nordin         = migrCursor.numero_ordinativo
                             and   f.pagato         ='S'
                             and   f.eu='E'
                             and   fa.annofatt=f.annofatt
                             and   fa.nfatt=f.nfatt
                             and   fa.tipofatt=f.tipofatt
                             and   fa.eu=f.eu
                             and   fa.codben=f.codben
                            );


                            msgRes:='Inserimento quota non legata a fattura.';
                            insert into migr_ordinativo_entrata_ts
                            ( ordinativo_ts_id,
                              ordinativo_id,
                              anno_esercizio,
                              numero_ordinativo,
                              quota_ordinativo,
                              anno_accertamento,
                              numero_accertamento,
                              numero_subaccertamento,
                              data_scadenza,
                              descrizione,
                              importo_iniziale,
                              importo_attuale,
                              ente_proprietario_id
                             )
                            (select migr_ord_entrata_ts_id_seq.nextval,
                                    migrCursor.ordinativo_id,
                                    migrCursor.anno_esercizio,
                                    migrCursor.numero_ordinativo,
                                    TS.ult_quota+1,
                                    migrCursor.anno_accertamento,
                                    migrCursor.numero_accertamento,
                                    migrCursor.numero_subaccertamento,
                                    migrCursor.data_scadenza,
                                    migrCursor.descrizione,
                                    migrCursor.importo_attuale-TS.importo_totale,
                                    migrCursor.importo_attuale-TS.importo_totale,
                                    pEnte
                             from  (select nvl(max(quota_ordinativo),0) ult_quota,
                                           nvl(sum(importo_attuale),0) importo_totale
                                    from migr_ordinativo_entrata_ts ts
                                    where ts.numero_ordinativo=migrCursor.numero_ordinativo
                                    and   ts.anno_esercizio   =migrCursor.anno_esercizio
                                    and   ts.ente_proprietario_id=pEnte) TS
                             where migrCursor.importo_attuale!=TS.importo_totale
                            );


                            cOrdInseriti := cOrdInseriti + 1;

                            if codRes != 0 then
                              -- gestione scarti al momento non previsti
                              null;
                            end if;

                            if numInsert >= 200 then
                              commit;
                              numInsert := 0;
                            else
                              numInsert := numInsert + 1;
                            end if;

                            <<continue_loop>>
                            null;
                      end loop;


    -- gestione degli scarti sulle quote AL MOMENTO non PREVISTI



    -- contiamo gli scarti ...
     msgRes:='Calcolo quote ordinativo scartate.';
    select nvl(count (*),0) into cOrdScartati from migr_ordinativo_ent_ts_scarto where ente_proprietario_id = pEnte;

    -- aggiornamento migr_ordinativo_entrata per fl_scarto='S' se non si inserisce neanche una quota
    msgRes:='Aggiornamento migr_ordinativo_entrata fl_scarto per ordinativi senza quote migrate.';
    update migr_ordinativo_entrata m
    set fl_scarto='S'
    where m.anno_esercizio=pAnnoEsercizio
    and   m.ente_proprietario_id=pEnte
    and   m.fl_scarto!='S'
    and   not exists (select 1
                      from migr_ordinativo_entrata_ts s
                      where s.ordinativo_id=m.ordinativo_id
                      and   s.ente_proprietario_id=m.ente_proprietario_id
                      and   s.fl_scarto!='S');

    msgRes:='Aggiornamento migr_ordinativo_entrata fl_scarto per ordinativi senza quote migrate con importo valorizzato.';
    update migr_ordinativo_entrata m
    set fl_scarto='S'
    where m.anno_esercizio=pAnnoEsercizio
    and   m.ente_proprietario_id=pEnte
    and   m.fl_scarto!='S'
    and   not exists (select 1
                      from migr_ordinativo_entrata_ts s
                      where s.ordinativo_id=m.ordinativo_id
                      and   s.ente_proprietario_id=m.ente_proprietario_id
                      and   s.fl_scarto!='S'
                      and   s.importo_attuale!=0);

    --  aggiornamento migr_ordinativo_entrata per fl_scarto='S' se ci sono quote in scarto
    msgRes:='Aggiornamento migr_ordinativo_entrata fl_scarto per ordinativi con quote scartate.';
    update migr_ordinativo_entrata m
    set fl_scarto='S'
    where m.anno_esercizio=pAnnoEsercizio
    and   m.ente_proprietario_id=pEnte
    and   m.fl_scarto!='S'
    and exists (select 1 from migr_ordinativo_ent_ts_scarto ts
                where ts.numero_ordinativo=m.numero_ordinativo
                and   ts.anno_esercizio=m.anno_esercizio
                and   ts.ente_proprietario_id=m.ente_proprietario_id);

    --  aggiornamento migr_ordinativo_entrata_ts per fl_scarto='S' se ci sono altre quote in scarto
    msgRes:='Aggiornamento migr_ordinativo_entrata_ts fl_scarto per quote ordinativi con altre scartate.';
    update migr_ordinativo_entrata_ts m
    set fl_scarto='S'
    where m.anno_esercizio=pAnnoEsercizio
    and   m.ente_proprietario_id=pEnte
    and exists (select 1 from migr_ordinativo_ent_ts_scarto ts
                where ts.numero_ordinativo=m.numero_ordinativo
                and   ts.anno_esercizio=m.anno_esercizio
                and   ts.ente_proprietario_id=m.ente_proprietario_id);


    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Ordinativi di entrata quote inseriti=' ||
                 cOrdInseriti || ' scartati=' || cOrdScartati || '.';

    pOrdScartati := cOrdScartati;
    pOrdInseriti := cOrdInseriti;
    commit;

  exception
    when others then
      rollback;
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pOrdScartati := cOrdScartati;
      pOrdInseriti := cOrdInseriti;
      pCodRes      := -1;

  END migrazione_ordinativo_entr_ts;


function fnc_migr_impegno_modifica(p_ente_proprietario_id number,
                                   p_anno_esercizio varchar2,
                                   p_cod_res out number,
                                   p_imp_inseriti out number,
                                   p_imp_scartati out number)
return varchar2 is

       msgRes varchar2(1500):=null;
       codRes number:=0;

       h_impegno varchar2(50):=null;

       h_impegno_migrato    number:=0;
       h_stato_impegno varchar2(1):=null;
       h_tipo_movimento varchar2(1):=null;
       h_tipo_modifica  varchar2(10):=null;

       h_anno_provvedimento   varchar2(4):=null;
       h_numero_provvedimento varchar2(10):=null;
       h_tipo_provvedimento   varchar2(20):=null;
       h_direzione_provvedimento varchar2(20):=null;
       h_stato_provvedimento   varchar2(5):=null;
       h_oggetto_provvedimento varchar2(500):=null;
       h_note_provvedimento    varchar2(500):=null;

       msgMotivoScarto varchar2(1500):=null;
       msgResOut varchar2(1500):=null;

       cImpInseriti number:=0;
       cImpScartati number:=0;
       numImpegno number:=0;

       segnalare boolean := False; -- True: il record � inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record � inserito nella sola tabella migr_*
       h_oggetto_provvLR varchar2(500) :=null;
begin

       p_imp_scartati:=0;
       p_imp_inseriti:=0;
       p_cod_res:=0;

       msgResOut:='Migrazione modifiche impegni.';


       msgRes:='Lettura oggetto provvedimento LR.';
       select PAR_CHAR into h_oggetto_provvLR
       from tab_parametri where cod_par = 'PLINP';

       msgRes:='Lettura Modifiche Impegni.';
       for  migrImpegnoMod in
       ( select i.anno_esercizio,i.annomov anno_impegno,i.nmov numero_impegno,i.nsubmov numero_subimpegno,i.tipomov tipo_movimento,
                i.nmodif numero_modifica,i.nro_capitolo numero_capitolo,i.nro_articolo numero_articolo,
                decode(nvl(i.nprov,'X'),'X',null,i.annoprov) anno_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,to_number(i.nprov)) numero_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                i.staoper stato_operativo, i.importo, i.descri descrizione, i.motivo motivo_modifica, to_char(i.dataagg,'YYYY-MM-DD') data_modifica,
                ii.corr_entr, ii.staoper stato_impegno
         from modifiche i, impegni ii
         where i.anno_esercizio=p_anno_esercizio and
               i.staoper in ('V','A') and
               i.tipomov in ('MIM', 'MSI') and
               ii.anno_esercizio=i.anno_esercizio and
               ii.annoimp=i.annomov and
               ii.nimp=i.nmov
         order by 1,2,3,4
       )
       loop
               -- inizializza variabili
               h_impegno_migrato:=0;
               h_stato_impegno := migrImpegnoMod.stato_impegno;
               h_tipo_movimento:=null;
               h_tipo_modifica:=null;
               h_anno_provvedimento:=null;
               h_numero_provvedimento:=null;
               h_tipo_provvedimento:=null;
               h_direzione_provvedimento:=null;
               h_stato_provvedimento:=null;
               h_oggetto_provvedimento:=null;
               h_note_provvedimento:=null;

               codRes:=0;
               msgMotivoScarto:=null;
               msgRes:=null;
               segnalare := false;

               h_impegno:='Modifiche Impegno '||migrImpegnoMod.anno_impegno||'/'||migrImpegnoMod.numero_impegno||'.';

               -- verifica importo modifica
               if migrImpegnoMod.importo = 0 then
                   msgRes:='Modifica Impegno scartata per importo = 0';
                   codRes:=-1;
               else
                   -- Determina il tipo_modifica
                   if migrImpegnoMod.importo < 0 then
                       h_tipo_modifica:='ECON';
                   else
                       h_tipo_modifica:='ALT';
                   end if;
               end if;

               -- Determina il tipo_movimento
               if migrImpegnoMod.tipo_movimento = 'MIM' then
                   h_tipo_movimento:=TIPO_IMPEGNO_I;
               else
                   h_tipo_movimento:=TIPO_IMPEGNO_S;
               end if;

               -- verifica movimento migrato
               if codRes=0 then
                   msgRes:='Verifica impegno migrato.';
                   begin
                       select nvl(count(*),0) into h_impegno_migrato
                         from migr_impegno
                        where anno_esercizio=migrImpegnoMod.anno_esercizio and
                              anno_impegno=migrImpegnoMod.anno_impegno and
                              numero_impegno=migrImpegnoMod.numero_impegno and
                              numero_subimpegno=migrImpegnoMod.numero_subimpegno and
                              tipo_movimento=h_tipo_movimento and
                              ente_proprietario_id=p_ente_proprietario_id;

                       if h_impegno_migrato=0 then
                           codRes:=-1;
                           msgRes:='Impegno / SubImpegno legato alla modifica non migrato.';
                       end if;

                   exception
                       when no_data_found then
                           h_impegno_migrato:=0;
                           codRes:=-1;
                           msgRes:='Impegno / SubImpegno legato alla modifica non migrato.';
                       when others then
                           codRes:=-1;
                           msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                   end;
               end if;

               if codRes=0 then
                 msgRes:='Lettura dati Provvedimento.';
                 if
                   (migrImpegnoMod.numero_provvedimento is null or migrImpegnoMod.numero_provvedimento ='0') then
                     if h_stato_impegno!=STATO_P then
                       if migrImpegnoMod.corr_entr = 'S' and h_tipo_movimento = TIPO_IMPEGNO_I then
                          h_stato_provvedimento:='D';
                          h_numero_provvedimento:=NUMPROVV_LR;
                          h_anno_provvedimento:=ANNOPROVV_LR;
                          h_tipo_provvedimento:=PROVV_LR||'||';
                          h_oggetto_provvedimento:=h_oggetto_provvLR;
                          segnalare := true;
                          msgMotivoScarto := 'Provvedimento non presente per modifica impegno in stato '||h_stato_impegno||'. Provvedimento associato '||PROVV_LR||'.';

                       else
                          h_stato_provvedimento:='D';
                          h_anno_provvedimento:=p_anno_esercizio;
                          h_tipo_provvedimento:=PROVV_SPR||'||';

                          segnalare := true;
                          msgMotivoScarto := 'Provvedimento non presente per modifica impegno in stato '||h_stato_impegno||'.Provvedimento associato '||PROVV_SPR||'.';
                       end if;
                     end if;
                 else

                    h_anno_provvedimento:=migrImpegnoMod.anno_provvedimento;
                    h_numero_provvedimento:=migrImpegnoMod.numero_provvedimento;
                    h_tipo_provvedimento:=migrImpegnoMod.tipo_provvedimento;
                    h_direzione_provvedimento:=migrImpegnoMod.direzione_provvedimento;

                    leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,
                                        h_tipo_provvedimento,h_direzione_provvedimento,p_ente_proprietario_id,
                                        codRes,msgRes,h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);
                    if codRes=0 then
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                       if migrImpegnoMod.tipo_provvedimento = PROVV_DETERMINA_REGP then
                          h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                       else
                          if h_direzione_provvedimento is not null then
                             h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                          end if;
                       end if;
                    end if;
                    if codRes=0 and h_stato_provvedimento is null then
                         h_stato_provvedimento:='D';
                    end if;
                    if codRes=-2 then
                      -- Provvedimento non trovato.
                      h_stato_provvedimento:='D';
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';
                      h_numero_provvedimento:=null;

                      segnalare := true;
                      codRes := 0; -- Il record continua ad essere elaborato normalmente.
                    end if;
                 end if;
              end if;

              if codRes=0
              then
               msgRes:='Inserimento in migr_impegno_modifica.';
               insert into migr_impegno_modifica
               ( impegno_mod_id,tipo_movimento,anno_esercizio,anno_impegno,numero_impegno,numero_subimpegno,numero_modifica,
                 tipo_modifica,descrizione,anno_provvedimento,numero_provvedimento,tipo_provvedimento,sac_provvedimento,
                 oggetto_provvedimento,note_provvedimento,stato_provvedimento,importo,stato_operativo,data_modifica,
                 ente_proprietario_id )
                values
                (migr_impegno_modifica_id_seq.nextval, h_tipo_movimento, migrImpegnoMod.anno_esercizio,
                 migrImpegnoMod.anno_impegno, migrImpegnoMod.numero_impegno, migrImpegnoMod.numero_subimpegno,
                 migrImpegnoMod.numero_modifica,h_tipo_modifica,migrImpegnoMod.descrizione,h_anno_provvedimento,
                 to_number(h_numero_provvedimento),h_tipo_provvedimento,h_direzione_provvedimento,h_oggetto_provvedimento,
                 h_note_provvedimento,h_stato_provvedimento,migrImpegnoMod.importo,migrImpegnoMod.stato_operativo,
                 migrImpegnoMod.data_modifica,p_ente_proprietario_id);

                 cImpInseriti:=cImpInseriti+1;
               end if;

               if codRes!=0 or segnalare = true  then
                 if codRes!=0 then
                     msgMotivoScarto:=msgRes;
                 end if;

                 msgRes:='Inserimento in migr_impegno_scarto.';
                 insert into migr_impegno_modscarto
                 (impegno_modscarto_id,anno_esercizio,anno_modifica,numero_modifica,motivo_scarto,ente_proprietario_id)
                  values
                 (migr_impegno_modscarto_id_seq.nextval,migrImpegnoMod.anno_esercizio,migrImpegnoMod.anno_impegno,migrImpegnoMod.numero_modifica,
                  msgMotivoScarto,p_ente_proprietario_id);

                  if segnalare = false then
                      cImpScartati:=cImpScartati+1;
                  end if;
               end if;


               if numImpegno>=200  then
                  commit;
                  numImpegno:=0;
               else numImpegno:=numImpegno+1;
               end if;
       end loop;

       msgResOut:=msgResOut||'Elaborazione OK.Modifiche Impegni inserite='||cImpInseriti||' scartate='||cImpScartati||'.';

       p_imp_scartati:=cImpScartati;
       p_imp_inseriti:=cImpInseriti;

       commit;

       return msgResOut;

exception
  when others then
    dbms_output.put_line('Impegno '||h_impegno||' msgRes '||msgRes||' Errore '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100));
    msgResOut:=msgResOut||h_impegno||msgRes||'Errore ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
    p_imp_scartati:=cImpScartati;
    p_imp_inseriti:=cImpInseriti;
    p_cod_res:=-1;
    return msgResOut;
end fnc_migr_impegno_modifica;

function fnc_migr_accertamento_modifica(p_ente_proprietario_id number,
                                        p_anno_esercizio varchar2,
                                        p_cod_res out number,
                                        p_imp_inseriti out number,
                                        p_imp_scartati out number) return varchar2
 is

       msgRes varchar2(1500):=null;
       codRes number:=0;

       h_accertamento varchar2(50):=null;

       h_accertamento_migrato    number:=0;
       h_stato_accertamento varchar2(1):=null;
       h_tipo_movimento varchar2(1):=null;
       h_tipo_modifica  varchar2(10):=null;

       h_anno_provvedimento   varchar2(4):=null;
       h_numero_provvedimento varchar2(10):=null;
       h_tipo_provvedimento   varchar2(20):=null;
       h_direzione_provvedimento varchar2(20):=null;
       h_stato_provvedimento   varchar2(5):=null;
       h_oggetto_provvedimento varchar2(500):=null;
       h_note_provvedimento    varchar2(500):=null;

       msgMotivoScarto varchar2(1500):=null;
       msgResOut varchar2(1500):=null;

       cImpInseriti number:=0;
       cImpScartati number:=0;
       numImpegno number:=0;

       segnalare boolean := False; -- True: il record � inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record � inserito nella sola tabella migr_*

begin

       p_imp_scartati:=0;
       p_imp_inseriti:=0;
       p_cod_res:=0;

       msgResOut:='Migrazione modifiche accertamenti.';

       msgRes:='Lettura Modifiche Accertamenti.';
       for  migrAccertamentoMod in
       ( select i.anno_esercizio,i.annomov anno_accertamento,i.nmov numero_accertamento,i.nsubmov numero_subaccertamento,i.tipomov tipo_movimento,
                i.nmodif numero_modifica,i.nro_capitolo numero_capitolo,i.nro_articolo numero_articolo,
                decode(nvl(i.nprov,'X'),'X',null,i.annoprov) anno_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,to_number(i.nprov)) numero_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                i.staoper stato_operativo, i.importo, i.descri descrizione, i.motivo motivo_modifica, to_char(i.dataagg,'YYYY-MM-DD') data_modifica,
                ii.staoper stato_accertamento
         from modifiche i, accertamenti ii
         where i.anno_esercizio=p_anno_esercizio and
               i.staoper in ('V','A') and
               i.tipomov in ('MAC', 'MSA') and
               ii.anno_esercizio=i.anno_esercizio and
               ii.annoacc=i.annomov and
               ii.nacc=i.nmov
         order by 1,2,3,4
       )
       loop
               -- inizializza variabili
               h_accertamento_migrato:=0;
               h_stato_accertamento := migrAccertamentoMod.stato_accertamento;
               h_tipo_movimento:=null;
               h_tipo_modifica:=null;
               h_anno_provvedimento:=null;
               h_numero_provvedimento:=null;
               h_tipo_provvedimento:=null;
               h_direzione_provvedimento:=null;
               h_stato_provvedimento:=null;
               h_oggetto_provvedimento:=null;
               h_note_provvedimento:=null;

               codRes:=0;
               msgMotivoScarto:=null;
               msgRes:=null;
               segnalare := false;

               h_accertamento:='Modifiche Accertamento '||migrAccertamentoMod.anno_accertamento||'/'||migrAccertamentoMod.numero_accertamento||'.';

               -- verifica importo modifica
               if migrAccertamentoMod.importo = 0 then
                   msgRes:='Modifica Accertamento scartata per importo = 0';
                   codRes:=-1;
               else
                   -- Determina il tipo_modifica
                   if migrAccertamentoMod.importo < 0 then
                       h_tipo_modifica:='ECON';
                   else
                       h_tipo_modifica:='ALT';
                   end if;
               end if;

               -- Determina il tipo_movimento
               if migrAccertamentoMod.tipo_movimento = 'MAC' then
                   h_tipo_movimento:=TIPO_IMPEGNO_A;
               else
                   h_tipo_movimento:=TIPO_IMPEGNO_S;
               end if;

               -- verifica movimento migrato
               if codRes=0 then
                   msgRes:='Verifica accertamento migrato.';
                   begin
                       select nvl(count(*),0) into h_accertamento_migrato
                         from migr_accertamento
                        where anno_esercizio=migrAccertamentoMod.anno_esercizio and
                              anno_accertamento=migrAccertamentoMod.anno_accertamento and
                              numero_accertamento=migrAccertamentoMod.numero_accertamento and
                              numero_subaccertamento=migrAccertamentoMod.numero_subaccertamento and
                              tipo_movimento=h_tipo_movimento and
                              ente_proprietario_id=p_ente_proprietario_id;

                       if h_accertamento_migrato=0 then
                           codRes:=-1;
                           msgRes:='Accertamento / SubAccertamento legato alla modifica non migrato.';
                       end if;

                   exception
                       when no_data_found then
                           h_accertamento_migrato:=0;
                           codRes:=-1;
                           msgRes:='Accertamento / SubAccertamento legato alla modifica non migrato.';
                       when others then
                           codRes:=-1;
                           msgRes:=msgRes||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
                   end;
               end if;

               if codRes=0 then
                 msgRes:='Lettura dati Provvedimento.';
                 if (migrAccertamentoMod.numero_provvedimento is null or migrAccertamentoMod.numero_provvedimento ='0') then
                   if h_stato_accertamento!=STATO_P then
                      h_stato_provvedimento:=STATO_D;
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';

                      segnalare := true;
                      msgMotivoScarto := 'Provvedimento non presente per modifica accertamento in stato '||h_stato_accertamento||'.';
                   end if;
                 else
                    h_anno_provvedimento:=migrAccertamentoMod.anno_provvedimento;
                    h_numero_provvedimento:=migrAccertamentoMod.numero_provvedimento;
                    h_tipo_provvedimento:=migrAccertamentoMod.tipo_provvedimento;
                    h_direzione_provvedimento:=migrAccertamentoMod.direzione_provvedimento;

                    leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,
                                        h_tipo_provvedimento,h_direzione_provvedimento,p_ente_proprietario_id,
                                        codRes,msgRes,h_oggetto_provvedimento,h_stato_provvedimento,h_note_provvedimento);
                    if codRes=0 then
                       h_tipo_provvedimento:=h_tipo_provvedimento||'||K';
                      -- if p_ente_proprietario_id= ENTE_REGP_GIUNTA  then
                       if migrAccertamentoMod.tipo_provvedimento = PROVV_DETERMINA_REGP then
                           h_direzione_provvedimento:=h_direzione_provvedimento||'||K';
                       else
                           if h_direzione_provvedimento is not null then
                               h_direzione_provvedimento:=h_direzione_provvedimento||'||';
                           end if;

                       end if;
                       --end if;
                    end if;

                    if codRes=0 and h_stato_provvedimento is null then
                      h_stato_provvedimento:='D';
                    end if;
                    if codRes=-2 then
                      -- Provvedimento non trovato.
                      h_stato_provvedimento:='D';
                      h_anno_provvedimento:=p_anno_esercizio;
                      h_tipo_provvedimento:=PROVV_SPR||'||';
                      h_numero_provvedimento:=null;

                      segnalare := true;
                      msgMotivoScarto := msgRes;
                      codRes := 0; -- Il record continua ad essere elaborato normalmente.
                    end if;
                 end if;
              end if;

              if codRes=0
              then
               msgRes:='Inserimento in migr_accertamento_mod.';
               insert into migr_accertamento_mod
               ( accertamento_mod_id,tipo_movimento,anno_esercizio,anno_accertamento,numero_accertamento,numero_subaccertamento,
                 numero_modifica,tipo_modifica,descrizione,anno_provvedimento,numero_provvedimento,tipo_provvedimento,sac_provvedimento,
                 oggetto_provvedimento,note_provvedimento,stato_provvedimento,importo,stato_operativo,data_modifica,
                 ente_proprietario_id )
                values
                (migr_accertamento_mod_id_seq.nextval, h_tipo_movimento, migrAccertamentoMod.anno_esercizio,
                 migrAccertamentoMod.anno_accertamento, migrAccertamentoMod.numero_accertamento, migrAccertamentoMod.numero_subaccertamento,
                 migrAccertamentoMod.numero_modifica,h_tipo_modifica,migrAccertamentoMod.descrizione,h_anno_provvedimento,
                 to_number(h_numero_provvedimento),h_tipo_provvedimento,h_direzione_provvedimento,h_oggetto_provvedimento,
                 h_note_provvedimento,h_stato_provvedimento,migrAccertamentoMod.importo,migrAccertamentoMod.stato_operativo,
                 migrAccertamentoMod.data_modifica,p_ente_proprietario_id);

                 cImpInseriti:=cImpInseriti+1;
               end if;

               if codRes!=0 or segnalare = true  then
                 if codRes!=0 then
                     msgMotivoScarto:=msgRes;
                 end if;

                 msgRes:='Inserimento in migr_accertamento_modsc.';
                 insert into migr_accertamento_modsc
                 (accertamento_modscarto_id,anno_esercizio,anno_modifica,numero_modifica,motivo_scarto,ente_proprietario_id)
                  values
                 (migr_accertamento_modsc_id_seq.nextval,migrAccertamentoMod.anno_esercizio,migrAccertamentoMod.anno_accertamento,
                  migrAccertamentoMod.numero_modifica,msgMotivoScarto,p_ente_proprietario_id);

                  if segnalare = false then
                      cImpScartati:=cImpScartati+1;
                  end if;
               end if;


               if numImpegno>=200  then
                  commit;
                  numImpegno:=0;
               else numImpegno:=numImpegno+1;
               end if;
       end loop;

       msgResOut:=msgResOut||'Elaborazione OK.Modifiche Accertamenti inserite='||cImpInseriti||' scartate='||cImpScartati||'.';

       p_imp_scartati:=cImpScartati;
       p_imp_inseriti:=cImpInseriti;

       commit;

       return msgResOut;

exception
  when others then
    dbms_output.put_line('Modifica Accertamento '||h_accertamento||' msgRes '||msgRes||' Errore '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100));
    msgResOut:=msgResOut||h_accertamento||msgRes||'Errore ' ||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 100)||'.';
    p_imp_scartati:=cImpScartati;
    p_imp_inseriti:=cImpInseriti;
    p_cod_res:=-1;
    return msgResOut;
end fnc_migr_accertamento_modifica;

end PCK_MIGRAZIONE_SIAC;
