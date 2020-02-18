CREATE OR REPLACE PACKAGE BODY PCK_MIGRAZIONE_SIAC IS
  procedure ditest(par_1 in varchar2, par_2 in varchar2, par_3 out varchar2)
  is
  begin
    par_3 := par_1 || par_2;
  end ditest;
  
  procedure migrazione_cpu(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
  
  excCaricadicui  EXCEPTION; -- 30.03.2016 Sofia
begin
    msgRes:='Pulizia migr_capitolo_uscita CAP-UP.';
    -- pulizia tabella migrazione per capitoli di previsione d'uscita
    delete migr_capitolo_uscita
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-UP'
       and fl_migrato = 'N'
       and ente_proprietario_id = p_ente;
    
    -- 30.03.2016 Sofia
    msgRes:='Gestione d118_prev_usc_impegnato.';
    d118_di_cui_gia_impegnato(p_anno_esercizio, p_ente,codRes, msgRes);

      if codRes!=0 then
         RAISE excCaricadicui;
    end if;
         
    msgRes:='Inserimento migr_capitolo_uscita CAP-UP.';
    --- inserimento solo con stanziamento_iniziale e stanziamento valorizzato
    insert into migr_capitolo_uscita
      (capusc_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
       descrizione,descrizione_articolo,titolo,macroaggregato,
       missione,programma,pdc_fin_quarto, pdc_fin_quinto,cofog,
       note,flag_per_memoria,flag_rilevante_iva,tipo_finanziamento, tipo_vincolo,tipo_fondo,
       siope_livello_1,siope_livello_2,siope_livello_3,
       classificatore_1,classificatore_2,classificatore_3,classificatore_4,classificatore_5,
       classificatore_6,classificatore_7,classificatore_8,classificatore_9,classificatore_10,
       classificatore_11,classificatore_12,classificatore_13,classificatore_14,classificatore_15,
       centro_resp,cdc,
       classe_capitolo,flag_impegnabile,
       stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
       stanziamento,stanziamento_res,stanziamento_cassa,
       stanziamento_iniziale_anno2,stanziamento_anno2,
       stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
       dicuiimpegnato_anno1, dicuiimpegnato_anno2, dicuiimpegnato_anno3, -- 30.03.2016 Sofia
       trasferimenti_comunitari, funzioni_delegate)                      -- 30.03.2016 Davide
      (
      select migr_capusc_id_seq.nextval,'CAP-UP',
              cAnno.Anno_Esercizio,cAnno.nro_capitolo,cAnno.nro_articolo,
-- 03.02.2015 Sofia adeguato a dimensione massima su applicativo
--            decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '00' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '000'),
              decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '0000'),
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
              --cAnno.descri,cAnno.descri,
              descri_capitolo.descri,cAnno.descri,
-- 09.09.2015 Davide fine              
              trim(tit118.titolo),
              decode(trim(macr118.macroag),null,null, macr118.titolo || macr118.macroag || '0000'),
              trim(miss118.missioni),
              decode(trim(progr118.programma),null,null,trim(progr118.missioni) || trim(progr118.PROGRAMMA)),
              decode(nvl(cap118.piano_fin_4l, ' '),' ',null, decode(ltrim(rtrim(pdcFin.Livello)),'IV',pdcFin.Conto,null)),
              decode(nvl(ueb118.piano_fin_5l, ' '),' ',null, decode(ltrim(rtrim(pdcFinUeb.Livello)),'V',pdcFinUeb.Conto,null)),
              trim(cap118.cofog),
              null,cAnno.Escl_Peg, cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ',null,tipoFin.Tipofin || '||' || tipoFin.Descri),
              decode(nvl(c_vincoli.num_vincoli, 0),0,null,'FV||FONDI VINCOLATI'),
              decode(nvl(tipoFondi.conto_vincolato, 0),0, null,tipoFondi.conto_vincolato || '||' || tipoFondi.Descri),
    -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli       
              --null,null, null,
              null,null, cAnno.codice_gestionale,
    -- DAVIDE - 16.12.015 - Fine
              decode(nvl(cUebAnno.All_Bil_Prev, ' '),' ',null,allPrev.Cod_Allegato || '||' || allPrev.Descri),
              decode(nvl(cUebAnno.All_Cons, ' '),' ', null,allCons.Cod_Allegato || '||' || allCons.Descri_Cons),
              decode(nvl(cAnno.Codclass_Patto, ' '),' ',null,classPatto.Codclass_Patto || '||' || classPatto.descri),
              decode(nvl(cAnno.codclass_cap, ' '),' ',null,
              'U' || '/' || classCap.Titolo || '.' ||classCap.Intervento || '.' || classCap.Codclass_Cap || '||' ||classCap.Descri),
              decode(nvl(cUebAnno.area, ' '),' ', null, cUebAnno.area || '||' || a.descri),
              decode(nvl(cUebAnno.assessorato, ' '),' ',null,ass.Assessorato || '||' || ass.descrizione || ' ' || ass.assessore),
              decode(nvl(cUebAnno.Coel, ' '),' ',null,coel.coel || '||' || coel.descri),
              null,null,null,
              'U' || '/' || cAnno.titolo || '||' || tit.descri,
              'U' || '/' || cAnno.Funzione || '||' || fun.descri,
              'U' || '/' || cAnno.Funzione || '.' || cAnno.Servizio || '||' ||ser.descri,
              'U' || '/' || cAnno.titolo || '.' || cAnno.intervento || '||' ||interv.descri,
              decode(nvl(cAnno.Voce_Eco, ' '),' ',null,
                     'U' || '/' || vusc.titolo || '.' || vusc.intervento || '.' ||vusc.voce_eco || '||' || vusc.descri),
              cdr.centro_resp,cdc.cdc,
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
--17.07.2015 Lusso: Per poter stampare correttamente la colonna 'Previsioni definitive anno precedente' dei report ufficiali, è necessario impostare lo stanziamento inziale
--dei capitoli di contabilia (Tipo stanziamento STI) con il valore dell'importo ST_ANNO_PREC di Tarantella
--              cUebAnno.St_Prev,0,0,
-- 21.04.2016 Sofia             cUebAnno.St_Anno_Prec,0,0,
-- 27.04.2016 Davide            cUebAnno.St_Anno_Prec,nvl(cUebAnno.st_residui,0),nvl(cUebAnno.st_cassa,0),              
              cUebAnno.St_Anno_Prec,nvl(cUebAnno.st_residui,0),nvl(cCassaEP.importo,0),              
-- 21.04.2016 Sofia             cUebAnno.St_Prev,0,0,
-- 27.04.2016 Davide              cUebAnno.St_Prev,nvl(cUebAnno.st_residui,0),nvl(cUebAnno.st_cassa,0),              
              cUebAnno.St_Prev,nvl(cUebAnno.st_residui,0),nvl(cCassaEP.importo,0),              
--              cUebAnno2.st_prev,cUebAnno2.st_prev,
-- 29.03.2016 Sofia
--              cUebAnno2.St_Anno_Prec,cUebAnno2.st_prev,
              cUebAnno2.st_prev,cUebAnno2.st_prev,              
--              cUebAnno3.st_prev,cUebAnno3.st_prev, p_ente
-- 29.03.2016 Sofia
--              cUebAnno3.St_Anno_Prec,cUebAnno3.st_prev, p_ente
              cUebAnno3.st_prev,cUebAnno3.st_prev, p_ente  ,
              cdicuiimpe.gia_impegnato_anno1, cdicuiimpe.gia_impegnato_anno2, cdicuiimpe.gia_impegnato_anno3, -- 30.03.2016 Sofia
              cAnno.trasf_comu, cAnno.funz_dele                                                               -- 30.03.2016 Davide
         from previsione_uscita cAnno, previsione_uscita cAnno2, previsione_uscita cAnno3,
              capcdc_prev_u cUebAnno, capcdc_prev_u cUebAnno2,capcdc_prev_u cUebAnno3,
              siac_capitoli cap118,siac_ueb ueb118,siac_titoli tit118,siac_macroag macr118,
              siac_missioni miss118,siac_programmi progr118,
              siac_piano_dei_conti pdcFin,siac_piano_dei_conti pdcFinUeb,
              tipo_fin tipoFin, conti_vincolati tipoFondi,
              aree a, assessorati ass,
              tab_allegati allPrev,tab_allegati allCons,
              tabclass_patto classPatto, tabclass_cap classCap,
              titusc tit,funzioni fun,servizi ser,interventi interv,vocecousc vusc,
              centri_resp cdr, tabcdc cdc,codici_elaborativi coel,
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
              (select distinct r.nro_capitolo, r.descri from previsione_uscita r
                where r.nro_articolo=0 and r.anno_esercizio=p_anno_esercizio and r.anno_creazione=p_anno_esercizio) descri_capitolo,
-- 09.09.2015 Davide fine
                (select vincoli.nro_cap_u nro_capitolo,
                      vincoli.nro_art_u nro_articolo,
                      nvl(count(*), 0) num_vincoli
               from coll_ent_usc vincoli
               where vincoli.anno_esercizio = p_anno_esercizio
              group by vincoli.nro_cap_u, vincoli.nro_art_u) c_vincoli, migr_capitolo_eccezione capEcc,
              d118_prev_usc_impegnato cdicuiimpe  -- 30.03.2016 Sofia
			  ,siac_cassa_ep cCassaEP             -- 27.04.2016  Davide
        where cAnno.anno_creazione = p_anno_esercizio
          and cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno2.anno_creazione = cAnno.anno_creazione
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_creazione = cAnno.anno_creazione
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.eu = 'U'
          and cap118.anno_esercizio = cAnno.anno_esercizio
          and cap118.anno_bilancio = cAnno.anno_esercizio
          and cap118.nro_capitolo = cAnno.nro_capitolo
          and cap118.nro_articolo = cAnno.nro_articolo
          and cUebAnno.Anno_Creazione = cAnno.anno_creazione
          and cUebAnno.Anno_esercizio = cAnno.Anno_esercizio
          and cUebAnno.Nro_Capitolo = cAnno.Nro_Capitolo
          and cUebAnno.Nro_articolo = cAnno.Nro_articolo
          and cUebAnno2.Anno_Creazione = cUebAnno.Anno_Creazione
          and cUebAnno2.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 1
          and cUebAnno2.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno2.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno2.cdc = cUebAnno.cdc
          and cUebAnno2.tipofin = cUebAnno.tipofin
          and cUebAnno2.coel = cUebAnno.coel
          and cUebAnno2.tipocdc = cUebAnno.tipocdc
          and cUebAnno3.Anno_Creazione = cUebAnno.Anno_Creazione
          and cUebAnno3.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 2
          and cUebAnno3.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno3.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno3.cdc = cUebAnno.cdc
          and cUebAnno3.tipofin = cUebAnno.tipofin
          and cUebAnno3.coel = cUebAnno.coel
          and cUebAnno3.tipocdc = cUebAnno.tipocdc
          and ueb118.anno_esercizio = cUebAnno.anno_esercizio
          and ueb118.anno_bilancio = cUebAnno.anno_esercizio
          and ueb118.eu = 'U'
          and ueb118.nro_capitolo = cUebAnno.nro_capitolo
          and ueb118.nro_articolo = cUebAnno.nro_articolo
          and ueb118.settore = cUebAnno.Cdc
          and ueb118.coel = cUebAnno.coel
          and ueb118.tipo_fin = cUebAnno.Tipofin
  -- Davide - 27.04.2016 - aggiunta lettura stanziamento iniziale cassa da tavola siac_cassa_ep
          and cCassaEP.anno_esercizio(+) = cUebAnno.anno_esercizio-1
          and cCassaEP.eu(+) = 'U'
          and cCassaEP.nro_capitolo(+) = cUebAnno.nro_capitolo
          and cCassaEP.nro_articolo(+) = cUebAnno.nro_articolo
          and cCassaEP.settore(+) = cUebAnno.Cdc
          and cCassaEP.coel(+) = cUebAnno.coel
          and cCassaEP.tipo_fin(+) = cUebAnno.Tipofin
    -- Davide - 27.04.2016 - fine
          and tit118.eu(+) = 'U'
          and tit118.titolo(+) = cap118.titolo
          and macr118.eu(+) = 'U'
          and macr118.titolo(+) = cap118.titolo
          and macr118.macroag(+) = cap118.macroag
          and miss118.eu(+) = 'U'
          and miss118.missioni(+) = cap118.missione
          and progr118.eu(+) = 'U'
          and progr118.missioni(+) = cap118.missione
          and progr118.programma(+) = cap118.programma
          and pdcFin.eu(+) = 'U'
          and pdcFin.Conto(+) = cap118.piano_fin_4l
          and pdcFinUeb.eu(+) = 'U'
          and pdcFinUeb.Conto(+) = ueb118.piano_fin_5l
          and tipoFin.Tipofin(+) = cUebAnno.Tipofin
          and tipoFondi.Anno_Creazione(+) = cAnno.Anno_Creazione
          and tipoFondi.Conto_Vincolato(+) = cAnno.Conto_Vincolato
          and a.anno_creazione(+) = cUebAnno.Anno_Creazione
          and a.area(+) = cUebAnno.area
          and ass.anno_creazione(+) = cUebAnno.Anno_Creazione
          and ass.assessorato(+) = cUebAnno.Assessorato
          and allPrev.Anno_Creazione(+) = cUebAnno.anno_creazione
          and allPrev.Cod_Allegato(+) = cUebAnno.All_Bil_Prev
          and allCons.Anno_Creazione(+) = cUebAnno.anno_creazione
          and allCons.Cod_Allegato(+) = cUebAnno.All_Cons
          and classPatto.Anno_Esercizio(+) = cAnno.Anno_Creazione
          and classPatto.Codclass_Patto(+) = cAnno.Codclass_Patto
          and classCap.titolo(+) = cAnno.Titolo
          and classCap.Intervento(+) = cAnno.Intervento
          and classCap.Codclass_Cap(+) = cAnno.Codclass_Cap
          and tit.titolo = cAnno.titolo
          and fun.funzione = cAnno.Funzione
          and ser.funzione = fun.funzione
          and ser.servizio = cAnno.Servizio
          and interv.titolo = tit.titolo
          and interv.intervento = cAnno.Intervento
          and vusc.titolo(+) = cAnno.titolo
          and vusc.intervento(+) = cAnno.intervento
          and vusc.voce_eco(+) = cAnno.Voce_Eco
          and cdc.anno_creazione = cUebAnno.Anno_Creazione
          and cdc.tipocdc = cUebAnno.Tipocdc
          and cdc.cdc = cUebAnno.Cdc
          and cdr.anno_creazione = cdc.Anno_Creazione
          and cdr.centro_resp = cdc.Centro_Resp
          and coel.anno_creazione(+) = cUebAnno.Anno_Creazione
          and coel.coel(+) = cUebAnno.Coel
          and c_vincoli.nro_capitolo(+) = cAnno.Nro_Capitolo
          and c_vincoli.nro_articolo(+) = cAnno.nro_articolo 
          and capEcc.Tipo_Capitolo (+)='P'
          and capEcc.Eu (+)  ='U'
          and capEcc.Anno_Esercizio  (+) = cUebAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cUebAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cUebAnno.Nro_Articolo
          and capEcc.numero_ueb      (+) = 
              decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '0000')
          and capEcc.ente_proprietario_id (+)=p_ente -- 07.01.2016 Sofia aggiunto    
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
          and descri_capitolo.nro_capitolo = cAnno.Nro_Capitolo
-- 09.09.2015 Davide fine
          and cdicuiimpe.Anno_Esercizio (+) = cUebAnno.anno_esercizio and -- 30.03.2016 Sofia
              cdicuiimpe.nro_capitolo (+)   = cUebAnno.Nro_Capitolo   and
              cdicuiimpe.nro_articolo (+)   = cUebAnno.Nro_Articolo   and
              cdicuiimpe.numero_ueb   (+)   = 
               decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '0000') and
              cdicuiimpe.ente_proprietario_id   (+)   =  p_ente
              );
    --- aggiornamento stanziamento_iniziale_res
    
    msgRes:='Aggiornamento migr_capitolo_uscita.stanziamento_iniziale_res CAP-UP.';
-- 17.07.2015 Daniela: la tabella letta è cambiata, il campo usato è impoatt_no_riacc
-- 23.02.2016 Sofia : riportato calcolo stanz. residuo su impegni
 /* 21.04.2016 Sofia - importato valori su campi da capcdc_prev_u  
    update migr_capitolo_uscita m
    set m.stanziamento_iniziale_res=  
    (
--     select nvl(sum(i.impoatt),0)
--       select nvl(sum(i.impoatt_no_riacc),0)
     select nvl(sum(i.impoini),0) -- 15.04.2016 Sofia
     from 
            impegni i
--            impegni_contabilia i
     where m.anno_esercizio=p_anno_esercizio and
           m.tipo_capitolo='CAP-UP' and
           i.anno_esercizio=m.anno_esercizio and
           i.anno_residuo<i.anno_esercizio and
           i.annoimp<i.anno_esercizio and -- 15.04.2016 Sofia
           i.nro_capitolo=m.numero_capitolo and
           i.nro_articolo=m.numero_articolo and
           i.tipofin=decode(substr(m.numero_ueb,1,1),'1','MB','MU') and
           i.cdc=substr(m.numero_ueb,3,3) and
           i.coel=substr(m.numero_ueb,6,4) 
           and i.staoper !='A'
           )
     where 
           m.ente_proprietario_id=p_ente and
           m.anno_esercizio=p_anno_esercizio and 
           m.tipo_capitolo='CAP-UP' and
           0!=(select count(*)
               from impegni i
--                   impegni_contabilia i
               where i.anno_esercizio=m.anno_esercizio and
                     i.anno_residuo<i.anno_esercizio and
                     i.annoimp<i.anno_esercizio and -- 15.04.2016 Sofia
                     i.nro_capitolo=m.numero_capitolo and
                     i.nro_articolo=m.numero_articolo and
                     i.tipofin=decode(substr(m.numero_ueb,1,1),'1','MB','MU') and
                     i.cdc=substr(m.numero_ueb,3,3) and
                     i.coel=substr(m.numero_ueb,6,4) 
                     and i.staoper !='A' 
                     );
      
     msgRes:='Aggiornamento migr_capitolo_uscita.stanziamento_iniziale_cassa CAP-UP.';
     -- aggiornamento stanziamento_inziale_cassa                
     update migr_capitolo_uscita m
     set m.stanziamento_iniziale_cassa=m.stanziamento_iniziale+m.stanziamento_iniziale_res
     where m.ente_proprietario_id=p_ente and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP';
     
     msgRes:='Aggiornamento migr_capitolo_uscita.stanziamento_res, migr_capitolo_uscita.stanziamento_cassa, CAP-UP.';
     -- aggiornamento stanziamento_res e stanziamento_cassa
     update migr_capitolo_uscita m
     set m.stanziamento_res=m.stanziamento_iniziale_res, m.stanziamento_cassa=m.stanziamento+m.stanziamento_iniziale_res
     where m.ente_proprietario_id=p_ente and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP'; */
     
       pCodRes:=codRes;           
       pMsgRes:='Migrazione capitolo uscita previsione OK.';
       commit;     
     
  exception
   -- 30.03.2016 Sofia 
   when excCaricadicui then
      pMsgRes := msgRes;
      pCodRes := -1;
      rollback;
    
    when others then
          pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
          pCodRes    := -1;
          rollback;
  end migrazione_cpu;

procedure migrazione_cgu(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin
    msgRes:='Pulizia migr_capitolo_uscita CAP-UG.';
    -- pulizia tabella migrazione per capitoli di gestione d'uscita
    delete migr_capitolo_uscita
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-UG'
       and fl_migrato = 'N'
       and ente_proprietario_id = p_ente;

    msgRes:='Inserimento migr_capitolo_uscita CAP-UG.';
    --- inserimento solo con stanziamento_inziale e stanziamento
    insert into migr_capitolo_uscita
      (capusc_id, tipo_capitolo, anno_esercizio, numero_capitolo, numero_articolo, numero_ueb,
       descrizione, descrizione_articolo, titolo,macroaggregato,missione,programma,pdc_fin_quarto,pdc_fin_quinto,cofog,
       note,flag_per_memoria,flag_rilevante_iva,tipo_finanziamento,tipo_vincolo,tipo_fondo,
       siope_livello_1,siope_livello_2,siope_livello_3,
       classificatore_1,classificatore_2,classificatore_3,classificatore_4,classificatore_5,
       classificatore_6,classificatore_7,classificatore_8,classificatore_9,classificatore_10,
       classificatore_11,classificatore_12,classificatore_13,classificatore_14,classificatore_15,
       centro_resp,cdc,
       classe_capitolo,flag_impegnabile,
       stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
       stanziamento,stanziamento_res,stanziamento_cassa,
       stanziamento_iniziale_anno2,stanziamento_anno2,
       stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
       trasferimenti_comunitari, funzioni_delegate)                              -- 05.04.2016 Davide
      (
      -- querey da eliminare a favore della commentata sotto, questa mette in outer join le tabelle di riclassificazione dei capitoli
select migr_capusc_id_seq.nextval,
              'CAP-UG',cAnno.Anno_Esercizio,cAnno.nro_capitolo,cAnno.nro_articolo,
 --             decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '00' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '000'),
              decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '0000'),              
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
              --cAnno.descri,cAnno.descri,
              descri_capitolo.descri,cAnno.descri,
-- 09.09.2015 Davide fine              
              trim(tit118.titolo),
              decode(trim(macr118.macroag),null, null,macr118.titolo || macr118.macroag || '0000'),
              trim(miss118.missioni),
              decode(trim(progr118.programma),null,null,trim(progr118.missioni) || trim(progr118.PROGRAMMA)),
              decode(nvl(cap118.piano_fin_4l, ' '), ' ',null,decode(ltrim(rtrim(pdcFin.Livello)),'IV', pdcFin.Conto,null)),
              decode(nvl(ueb118.piano_fin_5l, ' '),' ', null, decode(ltrim(rtrim(pdcFinUeb.Livello)),'V',pdcFinUeb.Conto,null)),
              trim(cap118.cofog),
              null,cAnno.Escl_Peg,cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ', null, tipoFin.Tipofin || '||' || tipoFin.Descri),
              decode(nvl(c_vincoli.num_vincoli, 0), 0,null,'FV||FONDI VINCOLATI'),
              decode(nvl(tipoFondi.conto_vincolato, 0),0,null, tipoFondi.conto_vincolato || '||' || tipoFondi.Descri),
    -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli       
              --null, null, null, decode(nvl(cUebAnno.All_Bil_Prev, ' '),' ',null,allPrev.Cod_Allegato || '||' || allPrev.Descri),
              null,null, cAnno.codice_gestionale, decode(nvl(cUebAnno.All_Bil_Prev, ' '),' ',null,allPrev.Cod_Allegato || '||' || allPrev.Descri),
    -- DAVIDE - 16.12.015 - Fine
              decode(nvl(cUebAnno.All_Cons, ' '),' ',null, allCons.Cod_Allegato || '||' || allCons.Descri_Cons),
              decode(nvl(cAnno.Codclass_Patto, ' '),' ',null, classPatto.Codclass_Patto || '||' || classPatto.descri),
              decode(nvl(cAnno.codclass_cap, ' '),' ', null,
                     'U' || '/' || classCap.Titolo || '.' ||classCap.Intervento || '.' || classCap.Codclass_Cap || '||' ||classCap.Descri),
              decode(nvl(cUebAnno.area, ' '),' ',null, cUebAnno.area || '||' || a.descri),
              decode(nvl(cUebAnno.assessorato, ' '),' ',null,ass.Assessorato || '||' || ass.descrizione || ' ' || ass.assessore),
              decode(nvl(cUebAnno.Coel, ' '),' ',null,coel.coel || '||' || coel.descri),
              null,null, null,
              'U' || '/' || cAnno.titolo || '||' || tit.descri,
              'U' || '/' || cAnno.Funzione || '||' || fun.descri,
              'U' || '/' || cAnno.Funzione || '.' || cAnno.Servizio || '||' ||ser.descri,
              'U' || '/' || cAnno.titolo || '.' || cAnno.intervento || '||' ||interv.descri,
              decode(nvl(cAnno.Voce_Eco, ' '),' ',null, 'U' || '/' || vusc.titolo || '.' || vusc.intervento || '.' ||vusc.voce_eco || '||' || vusc.descri),
              cdr.centro_resp, cdc.cdc,
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
              cUebAnno.St_attu,0, 0,
              cUebAnno.St_attu,0,0,
              cUebAnno2.St_attu, cUebAnno2.St_attu,
              cUebAnno3.St_attu,cUebAnno3.St_attu,p_ente,
			  cAnno.trasf_comu, cAnno.funz_dele                                                               -- 05.04.2016 Davide
         from cap_uscita cAnno,cap_uscita cAnno2,cap_uscita cAnno3,
              capcdc_uscita cUebAnno,capcdc_uscita cUebAnno2,capcdc_uscita cUebAnno3,
--              siac_capitoli_gest cap118,siac_ueb_gest ueb118,siac_titoli tit118, 17.12.2015 Sofia le tabelle _gest non vengono ALIMENTATE
              siac_capitoli cap118,siac_ueb ueb118,siac_titoli tit118,              
              siac_macroag macr118,siac_missioni miss118,siac_programmi progr118,
              siac_piano_dei_conti pdcFin,siac_piano_dei_conti pdcFinUeb,
              tipo_fin tipoFin,conti_vincolati tipoFondi,
              aree a,assessorati ass,tab_allegati allPrev,tab_allegati allCons,
              tabclass_patto classPatto,tabclass_cap classCap,
              titusc tit,funzioni fun,servizi ser,interventi interv,vocecousc vusc,
              centri_resp cdr, tabcdc cdc,codici_elaborativi coel,
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
              (select distinct r.nro_capitolo, r.descri from cap_uscita r
                where r.nro_articolo=0 and r.anno_esercizio=p_anno_esercizio and r.anno_creazione=p_anno_esercizio) descri_capitolo,
-- 09.09.2015 Davide fine
              (select vincoli.nro_cap_u nro_capitolo,
                      vincoli.nro_art_u nro_articolo,
                      nvl(count(*), 0) num_vincoli
               from coll_ent_usc vincoli
               where vincoli.anno_esercizio = p_anno_esercizio
              group by vincoli.nro_cap_u, vincoli.nro_art_u) c_vincoli, migr_capitolo_eccezione capEcc
        where    cAnno.Anno_Esercizio = p_anno_esercizio
             and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
             and cAnno2.nro_capitolo = cAnno.nro_capitolo
             and cAnno2.nro_articolo = cAnno.nro_articolo
             and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
             and cAnno3.nro_capitolo = cAnno.nro_capitolo
             and cAnno3.nro_articolo = cAnno.nro_articolo
             and cap118.eu = 'U'
             and cap118.anno_esercizio = cAnno.anno_esercizio
             and cap118.anno_bilancio = cAnno.anno_esercizio
             and cap118.nro_capitolo = cAnno.nro_capitolo
             and cap118.nro_articolo = cAnno.nro_articolo
             and cUebAnno.Anno_esercizio = cAnno.Anno_esercizio
             and cUebAnno.Nro_Capitolo = cAnno.Nro_Capitolo
             and cUebAnno.Nro_articolo = cAnno.Nro_articolo
             and cUebAnno2.anno_esercizio =  to_number(cUebAnno.anno_esercizio) + 1
             and cUebAnno2.Nro_Capitolo = cUebAnno.Nro_Capitolo
             and cUebAnno2.Nro_articolo = cUebAnno.Nro_articolo
             and cUebAnno2.cdc = cUebAnno.cdc
             and cUebAnno2.tipofin = cUebAnno.tipofin
             and cUebAnno2.coel = cUebAnno.coel
             and cUebAnno2.tipocdc = cUebAnno.tipocdc
             and cUebAnno3.anno_esercizio = to_number(cUebAnno.anno_esercizio) + 2
             and cUebAnno3.Nro_Capitolo = cUebAnno.Nro_Capitolo
             and cUebAnno3.Nro_articolo = cUebAnno.Nro_articolo
             and cUebAnno3.cdc = cUebAnno.cdc
             and cUebAnno3.tipofin = cUebAnno.tipofin
             and cUebAnno3.coel = cUebAnno.coel
             and cUebAnno3.tipocdc = cUebAnno.tipocdc
             and ueb118.anno_esercizio = cUebAnno.anno_esercizio
             and ueb118.anno_bilancio = cUebAnno.anno_esercizio--ueb118.anno_esercizio
             and ueb118.eu = 'U'
             and ueb118.nro_capitolo = cUebAnno.nro_capitolo
             and ueb118.nro_articolo = cUebAnno.nro_articolo
             and ueb118.settore = cUebAnno.Cdc
             and ueb118.coel = cUebAnno.coel
             and ueb118.tipo_fin = cUebAnno.Tipofin
             and tit118.eu(+) = 'U'
             and tit118.titolo(+) = cap118.titolo
             and macr118.eu(+) = 'U'
             and macr118.titolo(+) = cap118.titolo
             and macr118.macroag(+) = cap118.macroag
             and miss118.eu(+) = 'U'
             and miss118.missioni(+) = cap118.missione
             and progr118.eu(+) = 'U'
             and progr118.missioni(+) = cap118.missione
             and progr118.programma(+) = cap118.programma
             and pdcFin.eu(+) = 'U'
             and pdcFin.Conto(+) = cap118.piano_fin_4l
             and pdcFinUeb.eu(+) = 'U'
             and pdcFinUeb.Conto(+) = ueb118.piano_fin_5l
             and tipoFin.Tipofin(+) = cUebAnno.Tipofin
             and tipoFondi.Anno_Creazione(+) = cAnno.Anno_esercizio
             and tipoFondi.Conto_Vincolato(+) = cAnno.Conto_Vincolato
             and a.anno_creazione(+) = cUebAnno.Anno_esercizio
             and a.area(+) = cUebAnno.area
             and ass.anno_creazione(+) = cUebAnno.Anno_esercizio
             and ass.assessorato(+) = cUebAnno.Assessorato
             and allPrev.Anno_Creazione(+) = cUebAnno.anno_esercizio
             and allPrev.Cod_Allegato(+) = cUebAnno.All_Bil_Prev
             and allCons.Anno_Creazione(+) = cUebAnno.anno_esercizio
             and allCons.Cod_Allegato(+) = cUebAnno.All_Cons
             and classPatto.Anno_Esercizio(+) = cAnno.Anno_esercizio
             and classPatto.Codclass_Patto(+) = cAnno.Codclass_Patto
             and classCap.titolo(+) = cAnno.Titolo
             and classCap.Intervento(+) = cAnno.Intervento
             and classCap.Codclass_Cap(+) = cAnno.Codclass_Cap
             and tit.titolo = cAnno.titolo
             and fun.funzione = cAnno.Funzione
             and ser.funzione = fun.funzione
             and ser.servizio = cAnno.Servizio
             and interv.titolo = tit.titolo
             and interv.intervento = cAnno.Intervento
             and vusc.titolo(+) = cAnno.titolo
             and vusc.intervento(+) = cAnno.intervento
             and vusc.voce_eco(+) = cAnno.Voce_Eco
             and cdc.anno_creazione = cUebAnno.Anno_esercizio
             and cdc.tipocdc = cUebAnno.Tipocdc
             and cdc.cdc = cUebAnno.Cdc
             and cdr.anno_creazione = cdc.Anno_creazione
             and cdr.centro_resp = cdc.Centro_Resp
             and coel.anno_creazione(+) = cUebAnno.Anno_esercizio
             and coel.coel(+) = cUebAnno.Coel
             and c_vincoli.nro_capitolo(+) = cAnno.Nro_Capitolo
             and c_vincoli.nro_articolo(+) = cAnno.nro_articolo
             and capEcc.Tipo_Capitolo (+)='G'
             and capEcc.Eu (+)  ='U'
             and capEcc.Anno_Esercizio  (+) = cUebAnno.anno_esercizio
             and capEcc.numero_capitolo (+) = cUebAnno.Nro_Capitolo
             and capEcc.numero_articolo (+) = cUebAnno.Nro_Articolo
             and capEcc.numero_ueb      (+) = 
                 decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '0000')      
             and capEcc.ente_proprietario_id (+)=p_ente -- 07.01.2016 Sofia aggiunto    
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
             and descri_capitolo.nro_capitolo = cAnno.Nro_Capitolo
-- 09.09.2015 Davide fine
      /*select migr_capusc_id_seq.nextval,
              'CAP-UG',cAnno.Anno_Esercizio,cAnno.nro_capitolo,cAnno.nro_articolo,
              decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '00' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '000'),
              cAnno.descri, cAnno.descri,
              trim(tit118.titolo),
              decode(trim(macr118.macroag),null, null,macr118.titolo || macr118.macroag || '0000'),
              trim(miss118.missioni),
              decode(trim(progr118.programma),null,null,trim(progr118.missioni) || trim(progr118.PROGRAMMA)),
              decode(nvl(cap118.piano_fin_4l, ' '), ' ',null,decode(ltrim(rtrim(pdcFin.Livello)),'IV', pdcFin.Conto,null)),
              decode(nvl(ueb118.piano_fin_5l, ' '),' ', null, decode(ltrim(rtrim(pdcFinUeb.Livello)),'V',pdcFinUeb.Conto,null)),
              null,cAnno.Escl_Peg,cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ', null, tipoFin.Tipofin || '||' || tipoFin.Descri),
              decode(nvl(c_vincoli.num_vincoli, 0), 0,null,'FV||FONDI VINCOLATI'),
              decode(nvl(tipoFondi.conto_vincolato, 0),0,null, tipoFondi.conto_vincolato || '||' || tipoFondi.Descri),
              null, null, null, decode(nvl(cUebAnno.All_Bil_Prev, ' '),' ',null,allPrev.Cod_Allegato || '||' || allPrev.Descri),
              decode(nvl(cUebAnno.All_Cons, ' '),' ',null, allCons.Cod_Allegato || '||' || allCons.Descri),
              decode(nvl(cAnno.Codclass_Patto, ' '),' ',null, classPatto.Codclass_Patto || '||' || classPatto.descri),
              decode(nvl(cAnno.codclass_cap, ' '),' ', null,
                     'U' || '/' || classCap.Titolo || '.' ||classCap.Intervento || '.' || classCap.Codclass_Cap || '||' ||classCap.Descri),
              decode(nvl(cUebAnno.area, ' '),' ',null, cUebAnno.area || '||' || a.descri),
              decode(nvl(cUebAnno.assessorato, ' '),' ',null,ass.Assessorato || '||' || ass.descrizione || ' ' || ass.assessore),
              decode(nvl(cUebAnno.Coel, ' '),' ',null,coel.coel || '||' || coel.descri),
              null,null, null,
              'U' || '/' || cAnno.titolo || '||' || tit.descri,
              'U' || '/' || cAnno.Funzione || '||' || fun.descri,
              'U' || '/' || cAnno.Funzione || '.' || cAnno.Servizio || '||' ||ser.descri,
              'U' || '/' || cAnno.titolo || '.' || cAnno.intervento || '||' ||interv.descri,
              decode(nvl(cAnno.Voce_Eco, ' '),' ',null, 'U' || '/' || vusc.titolo || '.' || vusc.intervento || '.' ||vusc.voce_eco || '||' || vusc.descri),
              cdr.centro_resp, cdc.cdc,
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
              cUebAnno.St_attu,0, 0,
              cUebAnno.St_attu,0,0,
              cUebAnno2.St_attu, cUebAnno2.St_attu,
              cUebAnno3.St_attu,cUebAnno3.St_attu,p_ente
         from cap_uscita cAnno,cap_uscita cAnno2,cap_uscita cAnno3,
              capcdc_uscita cUebAnno,capcdc_uscita cUebAnno2,capcdc_uscita cUebAnno3,
              siac_capitoli_gest cap118,siac_ueb_gest ueb118,siac_titoli tit118,
              siac_macroag macr118,siac_missioni miss118,siac_programmi progr118,
              siac_piano_dei_conti pdcFin,siac_piano_dei_conti pdcFinUeb,
              tipo_fin tipoFin,conti_vincolati tipoFondi,
              aree a,assessorati ass,tab_allegati allPrev,tab_allegati allCons,
              tabclass_patto classPatto,tabclass_cap classCap,
              titusc tit,funzioni fun,servizi ser,interventi interv,vocecousc vusc,
              centri_resp cdr, tabcdc cdc,codici_elaborativi coel,
              (select vincoli.nro_cap_u nro_capitolo,
                      vincoli.nro_art_u nro_articolo,
                      nvl(count(*), 0) num_vincoli
               from coll_ent_usc vincoli
               where vincoli.anno_esercizio = p_anno_esercizio
              group by vincoli.nro_cap_u, vincoli.nro_art_u) c_vincoli, migr_capitolo_eccezione capEcc
        where    cAnno.Anno_Esercizio = p_anno_esercizio
             and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
             and cAnno2.nro_capitolo = cAnno.nro_capitolo
             and cAnno2.nro_articolo = cAnno.nro_articolo
             and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
             and cAnno3.nro_capitolo = cAnno.nro_capitolo
             and cAnno3.nro_articolo = cAnno.nro_articolo
             and cap118.eu = 'U'
             and cap118.anno_esercizio = cAnno.anno_esercizio
             and cap118.anno_bilancio = cAnno.anno_esercizio
             and cap118.nro_capitolo = cAnno.nro_capitolo
             and cap118.nro_articolo = cAnno.nro_articolo
             and cUebAnno.Anno_esercizio = cAnno.Anno_esercizio
             and cUebAnno.Nro_Capitolo = cAnno.Nro_Capitolo
             and cUebAnno.Nro_articolo = cAnno.Nro_articolo
             and cUebAnno2.anno_esercizio =  to_number(cUebAnno.anno_esercizio) + 1
             and cUebAnno2.Nro_Capitolo = cUebAnno.Nro_Capitolo
             and cUebAnno2.Nro_articolo = cUebAnno.Nro_articolo
             and cUebAnno2.cdc = cUebAnno.cdc
             and cUebAnno2.tipofin = cUebAnno.tipofin
             and cUebAnno2.coel = cUebAnno.coel
             and cUebAnno2.tipocdc = cUebAnno.tipocdc
             and cUebAnno3.anno_esercizio = to_number(cUebAnno.anno_esercizio) + 2
             and cUebAnno3.Nro_Capitolo = cUebAnno.Nro_Capitolo
             and cUebAnno3.Nro_articolo = cUebAnno.Nro_articolo
             and cUebAnno3.cdc = cUebAnno.cdc
             and cUebAnno3.tipofin = cUebAnno.tipofin
             and cUebAnno3.coel = cUebAnno.coel
             and cUebAnno3.tipocdc = cUebAnno.tipocdc
             and ueb118.anno_esercizio = cUebAnno.anno_esercizio
             and ueb118.anno_bilancio = ueb118.anno_esercizio
             and ueb118.eu = 'U'
             and ueb118.nro_capitolo = cUebAnno.nro_capitolo
             and ueb118.nro_articolo = cUebAnno.nro_articolo
             and ueb118.settore = cUebAnno.Cdc
             and ueb118.coel = cUebAnno.coel
             and ueb118.tipo_fin = cUebAnno.Tipofin
             and tit118.eu(+) = 'U'
             and tit118.titolo(+) = cap118.titolo
             and macr118.eu(+) = 'U'
             and macr118.titolo(+) = cap118.titolo
             and macr118.macroag(+) = cap118.macroag
             and miss118.eu(+) = 'U'
             and miss118.missioni(+) = cap118.missione
             and progr118.eu(+) = 'U'
             and progr118.missioni(+) = cap118.missione
             and progr118.programma(+) = cap118.programma
             and pdcFin.eu(+) = 'U'
             and pdcFin.Conto(+) = cap118.piano_fin_4l
             and pdcFinUeb.eu(+) = 'U'
             and pdcFinUeb.Conto(+) = ueb118.piano_fin_5l
             and tipoFin.Tipofin(+) = cUebAnno.Tipofin
             and tipoFondi.Anno_Creazione(+) = cAnno.Anno_esercizio
             and tipoFondi.Conto_Vincolato(+) = cAnno.Conto_Vincolato
             and a.anno_creazione(+) = cUebAnno.Anno_esercizio
             and a.area(+) = cUebAnno.area
             and ass.anno_creazione(+) = cUebAnno.Anno_esercizio
             and ass.assessorato(+) = cUebAnno.Assessorato
             and allPrev.Anno_Creazione(+) = cUebAnno.anno_esercizio
             and allPrev.Cod_Allegato(+) = cUebAnno.All_Bil_Prev
             and allCons.Anno_Creazione(+) = cUebAnno.anno_esercizio
             and allCons.Cod_Allegato(+) = cUebAnno.All_Cons
             and classPatto.Anno_Esercizio(+) = cAnno.Anno_esercizio
             and classPatto.Codclass_Patto(+) = cAnno.Codclass_Patto
             and classCap.titolo(+) = cAnno.Titolo
             and classCap.Intervento(+) = cAnno.Intervento
             and classCap.Codclass_Cap(+) = cAnno.Codclass_Cap
             and tit.titolo = cAnno.titolo
             and fun.funzione = cAnno.Funzione
             and ser.funzione = fun.funzione
             and ser.servizio = cAnno.Servizio
             and interv.titolo = tit.titolo
             and interv.intervento = cAnno.Intervento
             and vusc.titolo(+) = cAnno.titolo
             and vusc.intervento(+) = cAnno.intervento
             and vusc.voce_eco(+) = cAnno.Voce_Eco
             and cdc.anno_creazione = cUebAnno.Anno_esercizio
             and cdc.tipocdc = cUebAnno.Tipocdc
             and cdc.cdc = cUebAnno.Cdc
             and cdr.anno_creazione = cdc.Anno_creazione
             and cdr.centro_resp = cdc.Centro_Resp
             and coel.anno_creazione(+) = cUebAnno.Anno_esercizio
             and coel.coel(+) = cUebAnno.Coel
             and c_vincoli.nro_capitolo(+) = cAnno.Nro_Capitolo
             and c_vincoli.nro_articolo(+) = cAnno.nro_articolo
             and capEcc.Tipo_Capitolo (+)='G'
             and capEcc.Eu (+)  ='U'
             and capEcc.Anno_Esercizio  (+) = cUebAnno.anno_esercizio
             and capEcc.numero_capitolo (+) = cUebAnno.Nro_Capitolo
             and capEcc.numero_articolo (+) = cUebAnno.Nro_Articolo
             and capEcc.numero_ueb      (+) = 
                 decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '00' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '000')*/);

    
    msgRes:='Aggiornamento migr_capitolo_uscita.stanziamento_iniziale_res CAP-UG.';
    --- aggiornamento stanziamento_iniziale_res
    update migr_capitolo_uscita m
    set m.stanziamento_iniziale_res=  
    (select nvl(sum(i.impoatt),0)
     from impegni i
     where m.anno_esercizio=p_anno_esercizio and
           m.tipo_capitolo='CAP-UG' and
           i.anno_esercizio=m.anno_esercizio and
           i.anno_residuo<i.anno_esercizio and
           i.nro_capitolo=m.numero_capitolo and
           i.nro_articolo=m.numero_articolo and
           i.tipofin=decode(substr(m.numero_ueb,1,1),'1','MB','MU') and
           i.cdc=substr(m.numero_ueb,3,3) and
           i.coel=substr(m.numero_ueb,6,4) and
           i.staoper !='A' )
     where m.ente_proprietario_id=p_ente and
           m.anno_esercizio=p_anno_esercizio and 
           m.tipo_capitolo='CAP-UG' and
           0!=(select count(*)
               from impegni i
               where i.anno_esercizio=m.anno_esercizio and
                     i.anno_residuo<i.anno_esercizio and
                     i.nro_capitolo=m.numero_capitolo and
                     i.nro_articolo=m.numero_articolo and
                     i.tipofin=decode(substr(m.numero_ueb,1,1),'1','MB','MU') and
                     i.cdc=substr(m.numero_ueb,3,3) and
                     i.coel=substr(m.numero_ueb,6,4) and
                     i.staoper !='A');
                     
     
     msgRes:='Aggiornamento migr_capitolo_uscita.stanziamento_iniziale_cassa CAP-UG.';
     -- aggiornamento stanziamento_inziale_cassa                
     update migr_capitolo_uscita m
     set m.stanziamento_iniziale_cassa=m.stanziamento_iniziale+m.stanziamento_iniziale_res
     where m.ente_proprietario_id=p_ente and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UG';
     
     msgRes:='Aggiornamento migr_capitolo_uscita.stanziamento_res, migr_capitolo_uscita.stanziamento_cassa CAP-UG.';
     -- aggiornamento stanziamento_res e stanziamento_cassa
     update migr_capitolo_uscita m
     set m.stanziamento_res=m.stanziamento_iniziale_res, m.stanziamento_cassa=m.stanziamento+m.stanziamento_iniziale_res
     where m.ente_proprietario_id=p_ente and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UG';   
         
    pCodRes:=codRes;           
    pMsgRes:='Migrazione capitolo uscita gestione OK.';
    commit;
   
exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
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
       and ente_proprietario_id = p_ente;

    --- inserimento solo con stanziamento_iniziale e stanziamento valorizzati
    msgRes:='Inserimento migr_capitolo_entrata CAP-EP.';
    insert into migr_capitolo_entrata
      (capent_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
       descrizione, descrizione_articolo,
       titolo,tipologia,categoria,pdc_fin_quarto, pdc_fin_quinto,note,
       flag_per_memoria,flag_rilevante_iva,tipo_finanziamento,tipo_vincolo, tipo_fondo,
       siope_livello_1,siope_livello_2,siope_livello_3,
       classificatore_1,classificatore_2,classificatore_3,classificatore_4,classificatore_5,
       classificatore_6,classificatore_7,classificatore_8,classificatore_9,classificatore_10,
       classificatore_11,classificatore_12,classificatore_13,classificatore_14,classificatore_15,
       centro_resp,cdc,
       classe_capitolo,flag_accertabile,
       stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
       stanziamento,stanziamento_res,stanziamento_cassa,
       stanziamento_iniziale_anno2,stanziamento_anno2,
       stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
       trasferimenti_comunitari)                                                  -- 30.03.2016 Davide
      (
      -- querey da eliminare a favore della commentata sotto, questa mette in outer join le tabelle di riclassificazione dei capitoli
      select migr_capent_id_seq.nextval,'CAP-EP',
              cAnno.Anno_Esercizio, cAnno.nro_capitolo,cAnno.nro_articolo,
              decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||
              cUebAnno.Cdc || nvl(cUebAnno.coel, '0000'),
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
              --cAnno.descri,
              --cAnno.descri,
              descri_capitolo.descri,cAnno.descri,
-- 09.09.2015 Davide fine              
              trim(tit118.titolo),
              decode(trim(tip118.tipologia), null, null, trim(tip118.titolo) || '0' || trim(tip118.tipologia) || '00'),
              trim(cap118.codice_categoria),
              decode(nvl(cap118.piano_fin_4l, ' '),' ',null,decode(ltrim(rtrim(pdcFin.Livello)),'IV',pdcFin.Conto,null)),
              decode(nvl(ueb118.piano_fin_5l, ' '),' ',null,decode(ltrim(rtrim(pdcFinUeb.Livello)),'V',pdcFinUeb.Conto,null)),
              null,
              cAnno.Escl_Peg, cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ', null,tipoFin.Tipofin || '||' || tipoFin.Descri),
              null,
              decode(nvl(tipoFondi.conto_vincolato, 0),0,null,tipoFondi.conto_vincolato || '||' || tipoFondi.Descri),
    -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli       
              --null, null, null, 
              null,null, cAnno.codice_gestionale, 
    -- DAVIDE - 16.12.015 - Fine
              decode(nvl(cUebAnno.All_Bil_Prev, ' '),' ',null,allPrev.Cod_Allegato || '||' || allPrev.Descri),
              decode(nvl(cUebAnno.All_Cons, ' '),' ',null,allCons.Cod_Allegato || '||' || allCons.Descri_Cons),
              decode(nvl(cAnno.Codclass_Patto, ' '),' ',null,classPatto.Codclass_Patto || '||' || classPatto.descri),
              decode(nvl(cUebAnno.area, ' '),' ', null,cUebAnno.area || '||' || a.descri),
              decode(nvl(cUebAnno.assessorato, ' '),' ',null,ass.Assessorato || '||' || ass.descrizione || ' ' ||ass.assessore),
              decode(nvl(cUebAnno.Coel, ' '),' ',null,coel.coel || '||' || coel.descri),
              null,null,null,null,
              'E' || '/' || cAnno.titolo || '||' || tit.descri,
              'E' || '/' || cAnno.titolo || '.' || cAnno.Categoria || '||' ||cat.descri,
              'E' || '/' || cAnno.titolo || '.' || cAnno.categoria || '.' ||cAnno.Risorsa || '||' || ris.descri,
              decode(nvl(cAnno.Voce_Eco, ' '),' ',null,
                     'E' || '/' || vent.titolo || '.' || vent.categoria || '.' || vent.voce_eco || '||' || vent.descri),
              null,
              cdr.centro_resp,cdc.cdc,
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
--17.07.2015 Lusso: Per poter stampare correttamente la colonna 'Previsioni definitive anno precedente' dei report ufficiali, è necessario impostare lo stanziamento inziale
--dei capitoli di contabilia (Tipo stanziamento STI) con il valore dell'importo ST_ANNO_PREC di Tarantella
--              cUebAnno.St_Prev,0,0,
-- 21.04.2016 Sofia             cUebAnno.St_Anno_Prec,0,0,
-- 27.04.2016 Davide            cUebAnno.St_Anno_Prec,nvl(cUebAnno.st_residui,0),nvl(cUebAnno.st_cassa,0),              
              cUebAnno.St_Anno_Prec,nvl(cUebAnno.st_residui,0),nvl(cCassaEP.importo,0),              
-- 21.04.2016 Sofia              cUebAnno.St_Prev,0,0,
-- 27.04.2016 Davide              cUebAnno.St_Prev,nvl(cUebAnno.st_residui,0),nvl(cUebAnno.st_cassa,0),              
              cUebAnno.St_Prev,nvl(cUebAnno.st_residui,0),nvl(cCassaEP.importo,0),              
--              cUebAnno2.st_prev,cUebAnno2.st_prev,
-- 29.03.2016 Sofia
--              cUebAnno2.St_Anno_Prec,cUebAnno2.st_prev,
              cUebAnno2.st_prev,cUebAnno2.st_prev,
--              cUebAnno3.st_prev,cUebAnno3.st_prev, p_ente
-- 29.03.2016 Sofia
--              cUebAnno3.St_Anno_Prec,cUebAnno3.st_prev, p_ente
              cUebAnno3.st_prev,cUebAnno3.st_prev, p_ente,
              cAnno.trasf_comu                                                               -- 30.03.2016 Davide
         from previsione_entrata   cAnno, previsione_entrata   cAnno2,previsione_entrata   cAnno3,
              capcdc_prev_e cUebAnno, capcdc_prev_e cUebAnno2, capcdc_prev_e cUebAnno3,
              siac_capitoli cap118, siac_ueb ueb118,
              siac_titoli tit118, siac_tipologie tip118,siac_categorie categ118,
              siac_piano_dei_conti pdcFin,siac_piano_dei_conti pdcFinUeb,
              tipo_fin tipoFin, conti_vincolati tipoFondi,
              aree a, assessorati ass, tab_allegati allPrev, tab_allegati allCons,
              tabclass_patto classPatto,titent tit,categorie cat,
              risorse ris, vocecoent vent,
              centri_resp cdr, tabcdc cdc,
              codici_elaborativi   coel,
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
              (select distinct r.nro_capitolo, r.descri from previsione_entrata r
                where r.nro_articolo=0 and r.anno_esercizio=p_anno_esercizio and r.anno_creazione=p_anno_esercizio) descri_capitolo,
-- 09.09.2015 Davide fine
              migr_capitolo_eccezione capEcc
			  ,siac_cassa_ep cCassaEP             -- 27.04.2016  Davide
        where cAnno.anno_creazione = p_anno_esercizio
          and cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno2.anno_creazione = cAnno.anno_creazione
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_creazione = cAnno.anno_creazione
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.eu = 'E'
          and cap118.anno_esercizio  = cAnno.anno_esercizio
          and cap118.anno_bilancio  = cAnno.anno_esercizio
          and cap118.nro_capitolo  = cAnno.nro_capitolo
          and cap118.nro_articolo  = cAnno.nro_articolo
          and cUebAnno.Anno_Creazione = cAnno.anno_creazione
          and cUebAnno.Anno_esercizio = cAnno.Anno_esercizio
          and cUebAnno.Nro_Capitolo = cAnno.Nro_Capitolo
          and cUebAnno.Nro_articolo = cAnno.Nro_articolo
          and cUebAnno2.Anno_Creazione = cUebAnno.Anno_Creazione
          and cUebAnno2.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 1
          and cUebAnno2.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno2.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno2.cdc = cUebAnno.cdc
          and cUebAnno2.tipofin = cUebAnno.tipofin
          and cUebAnno2.coel = cUebAnno.coel
          and cUebAnno2.tipocdc = cUebAnno.tipocdc
          and cUebAnno3.Anno_Creazione = cUebAnno.Anno_Creazione
          and cUebAnno3.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 2
          and cUebAnno3.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno3.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno3.cdc = cUebAnno.cdc
          and cUebAnno3.tipofin = cUebAnno.tipofin
          and cUebAnno3.coel = cUebAnno.coel
          and cUebAnno3.tipocdc = cUebAnno.tipocdc
          and ueb118.anno_esercizio  = cUebAnno.anno_esercizio
          and ueb118.anno_bilancio  = cUebAnno.anno_esercizio--ueb118.anno_esercizio
          and ueb118.eu  = 'E'
          and ueb118.nro_capitolo  = cUebAnno.nro_capitolo
          and ueb118.nro_articolo  = cUebAnno.nro_articolo
          and ueb118.settore  = cUebAnno.Cdc
          and ueb118.coel  = cUebAnno.coel
          and ueb118.tipo_fin  = cUebAnno.Tipofin
  -- Davide - 27.04.2016 - aggiunta lettura stanziamento iniziale cassa da tavola siac_cassa_ep
          and cCassaEP.anno_esercizio(+) = cUebAnno.anno_esercizio-1
          and cCassaEP.eu(+) = 'E'
          and cCassaEP.nro_capitolo(+) = cUebAnno.nro_capitolo
          and cCassaEP.nro_articolo(+) = cUebAnno.nro_articolo
          and cCassaEP.settore(+) = cUebAnno.Cdc
          and cCassaEP.coel(+) = cUebAnno.coel
          and cCassaEP.tipo_fin(+) = cUebAnno.Tipofin
    -- Davide - 27.04.2016 - fine
          and tit118.eu(+) = 'E'
          and tit118.titolo(+) = cap118.titolo
          and tip118.eu(+) = 'E'
          and tip118.titolo(+) = cap118.titolo
          and tip118.tipologia(+) = cap118.tipologia
          and categ118.eu(+) = 'E'
          and categ118.titolo(+) = cap118.titolo
          and categ118.tipologia(+) = cap118.tipologia
          and categ118.categoria(+) = cap118.categoria
          and pdcFin.eu(+) = 'E'
          and pdcFin.Conto(+) = cap118.piano_fin_4l
          and pdcFinUeb.eu(+) = 'E'
          and pdcFinUeb.Conto(+) = ueb118.piano_fin_5l
          and tipoFin.Tipofin(+) = cUebAnno.Tipofin
          and tipoFondi.Anno_Creazione(+) = cAnno.Anno_Creazione
          and tipoFondi.Conto_Vincolato(+) = cAnno.Conto_Vincolato
          and a.anno_creazione(+) = cUebAnno.Anno_Creazione
          and a.area(+) = cUebAnno.area
          and ass.anno_creazione(+) = cUebAnno.Anno_Creazione
          and ass.assessorato(+) = cUebAnno.Assessorato
          and allPrev.Anno_Creazione(+) = cUebAnno.anno_creazione
          and allPrev.Cod_Allegato(+) = cUebAnno.All_Bil_Prev
          and allCons.Anno_Creazione(+) = cUebAnno.anno_creazione
          and allCons.Cod_Allegato(+) = cUebAnno.All_Cons
          and classPatto.Anno_Esercizio(+) = cAnno.Anno_Creazione
          and classPatto.Codclass_Patto(+) = cAnno.Codclass_Patto
          and tit.titolo = cAnno.titolo
          and cat.titolo = cAnno.titolo
          and cat.categoria = cAnno.Categoria
          and ris.anno_creazione = cAnno.Anno_Creazione
          and ris.titolo = cAnno.titolo
          and ris.categoria = cAnno.Categoria
          and ris.risorsa = cAnno.Risorsa
          and vent.titolo(+) = cAnno.titolo
          and vent.categoria(+) = cAnno.categoria
          and vent.voce_eco(+) = cAnno.Voce_Eco
          and cdc.anno_creazione = cUebAnno.Anno_Creazione
          and cdc.tipocdc = cUebAnno.Tipocdc
          and cdc.cdc = cUebAnno.Cdc
          and cdr.anno_creazione = cdc.Anno_Creazione
          and cdr.centro_resp = cdc.Centro_Resp
          and coel.anno_creazione(+) = cUebAnno.Anno_Creazione
          and coel.coel(+) = cUebAnno.Coel
          and capEcc.Tipo_Capitolo (+)='P'
          and capEcc.Eu (+)  ='E'
          and capEcc.Anno_Esercizio  (+) = cUebAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cUebAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cUebAnno.Nro_Articolo
          and capEcc.numero_ueb      (+) = 
                 decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '0000')
          and capEcc.ente_proprietario_id (+)=p_ente -- 07.01.2016 Sofia aggiunto       
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
          and descri_capitolo.nro_capitolo = cAnno.Nro_Capitolo
-- 09.09.2015 Davide fine
      /*select migr_capent_id_seq.nextval,'CAP-EP',
              cAnno.Anno_Esercizio, cAnno.nro_capitolo,cAnno.nro_articolo,
              decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '00' ||
              cUebAnno.Cdc || nvl(cUebAnno.coel, '000'),
              cAnno.descri,
              cAnno.descri,
              trim(tit118.titolo),
              decode(trim(tip118.tipologia), null, null, trim(tip118.titolo) || '0' || trim(tip118.tipologia) || '00'),
              trim(categ118.categoria),
              decode(nvl(cap118.piano_fin_4l, ' '),' ',null,decode(ltrim(rtrim(pdcFin.Livello)),'IV',pdcFin.Conto,null)),
              decode(nvl(ueb118.piano_fin_5l, ' '),' ',null,decode(ltrim(rtrim(pdcFinUeb.Livello)),'V',pdcFinUeb.Conto,null)),
              null,
              cAnno.Escl_Peg, cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ', null,tipoFin.Tipofin || '||' || tipoFin.Descri),
              null,
              decode(nvl(tipoFondi.conto_vincolato, 0),0,null,tipoFondi.conto_vincolato || '||' || tipoFondi.Descri),
              null, null,null,
              decode(nvl(cUebAnno.All_Bil_Prev, ' '),' ',null,allPrev.Cod_Allegato || '||' || allPrev.Descri),
              decode(nvl(cUebAnno.All_Cons, ' '),' ',null,allCons.Cod_Allegato || '||' || allCons.Descri),
              decode(nvl(cAnno.Codclass_Patto, ' '),' ',null,classPatto.Codclass_Patto || '||' || classPatto.descri),
              decode(nvl(cUebAnno.area, ' '),' ', null,cUebAnno.area || '||' || a.descri),
              decode(nvl(cUebAnno.assessorato, ' '),' ',null,ass.Assessorato || '||' || ass.descrizione || ' ' ||ass.assessore),
              decode(nvl(cUebAnno.Coel, ' '),' ',null,coel.coel || '||' || coel.descri),
              null,null,null,null,
              'E' || '/' || cAnno.titolo || '||' || tit.descri,
              'E' || '/' || cAnno.titolo || '.' || cAnno.Categoria || '||' ||cat.descri,
              'E' || '/' || cAnno.titolo || '.' || cAnno.categoria || '.' ||cAnno.Risorsa || '||' || ris.descri,
              decode(nvl(cAnno.Voce_Eco, ' '),' ',null,
                     'E' || '/' || vent.titolo || '.' || vent.categoria || '.' || vent.voce_eco || '||' || vent.descri),
              null,
              cdr.centro_resp,cdc.cdc,
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
              cUebAnno.St_Prev,0,0,
              cUebAnno.St_Prev,0,0,
              cUebAnno2.st_prev,cUebAnno2.st_prev,
              cUebAnno3.st_prev,cUebAnno3.st_prev, p_ente
         from previsione_entrata   cAnno, previsione_entrata   cAnno2,previsione_entrata   cAnno3,
              capcdc_prev_e cUebAnno, capcdc_prev_e cUebAnno2, capcdc_prev_e cUebAnno3,
              siac_capitoli cap118, siac_ueb ueb118,
              siac_titoli tit118, siac_tipologie tip118,siac_categorie categ118,
              siac_piano_dei_conti pdcFin,siac_piano_dei_conti pdcFinUeb,
              tipo_fin tipoFin, conti_vincolati tipoFondi,
              aree a, assessorati ass, tab_allegati allPrev, tab_allegati allCons,
              tabclass_patto classPatto,titent tit,categorie cat,
              risorse ris, vocecoent vent,
              centri_resp cdr, tabcdc cdc,
              codici_elaborativi   coel, migr_capitolo_eccezione capEcc
        where cAnno.anno_creazione = p_anno_esercizio
          and cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno2.anno_creazione = cAnno.anno_creazione
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_creazione = cAnno.anno_creazione
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.eu = 'E'
          and cap118.anno_esercizio = cAnno.anno_esercizio
          and cap118.anno_bilancio = cAnno.anno_esercizio
          and cap118.nro_capitolo = cAnno.nro_capitolo
          and cap118.nro_articolo = cAnno.nro_articolo
          and cUebAnno.Anno_Creazione = cAnno.anno_creazione
          and cUebAnno.Anno_esercizio = cAnno.Anno_esercizio
          and cUebAnno.Nro_Capitolo = cAnno.Nro_Capitolo
          and cUebAnno.Nro_articolo = cAnno.Nro_articolo
          and cUebAnno2.Anno_Creazione = cUebAnno.Anno_Creazione
          and cUebAnno2.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 1
          and cUebAnno2.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno2.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno2.cdc = cUebAnno.cdc
          and cUebAnno2.tipofin = cUebAnno.tipofin
          and cUebAnno2.coel = cUebAnno.coel
          and cUebAnno2.tipocdc = cUebAnno.tipocdc
          and cUebAnno3.Anno_Creazione = cUebAnno.Anno_Creazione
          and cUebAnno3.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 2
          and cUebAnno3.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno3.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno3.cdc = cUebAnno.cdc
          and cUebAnno3.tipofin = cUebAnno.tipofin
          and cUebAnno3.coel = cUebAnno.coel
          and cUebAnno3.tipocdc = cUebAnno.tipocdc
          and ueb118.anno_esercizio = cUebAnno.anno_esercizio
          and ueb118.anno_bilancio = ueb118.anno_esercizio
          and ueb118.eu = 'E'
          and ueb118.nro_capitolo = cUebAnno.nro_capitolo
          and ueb118.nro_articolo = cUebAnno.nro_articolo
          and ueb118.settore = cUebAnno.Cdc
          and ueb118.coel = cUebAnno.coel
          and ueb118.tipo_fin = cUebAnno.Tipofin
          and tit118.eu(+) = 'E'
          and tit118.titolo(+) = cap118.titolo
          and tip118.eu(+) = 'E'
          and tip118.titolo(+) = cap118.titolo
          and tip118.tipologia(+) = cap118.tipologia
          and categ118.eu(+) = 'E'
          and categ118.titolo(+) = cap118.titolo
          and categ118.tipologia(+) = cap118.tipologia
          and categ118.categoria(+) = cap118.categoria
          and pdcFin.eu(+) = 'E'
          and pdcFin.Conto(+) = cap118.piano_fin_4l
          and pdcFinUeb.eu(+) = 'E'
          and pdcFinUeb.Conto(+) = ueb118.piano_fin_5l
          and tipoFin.Tipofin(+) = cUebAnno.Tipofin
          and tipoFondi.Anno_Creazione(+) = cAnno.Anno_Creazione
          and tipoFondi.Conto_Vincolato(+) = cAnno.Conto_Vincolato
          and a.anno_creazione(+) = cUebAnno.Anno_Creazione
          and a.area(+) = cUebAnno.area
          and ass.anno_creazione(+) = cUebAnno.Anno_Creazione
          and ass.assessorato(+) = cUebAnno.Assessorato
          and allPrev.Anno_Creazione(+) = cUebAnno.anno_creazione
          and allPrev.Cod_Allegato(+) = cUebAnno.All_Bil_Prev
          and allCons.Anno_Creazione(+) = cUebAnno.anno_creazione
          and allCons.Cod_Allegato(+) = cUebAnno.All_Cons
          and classPatto.Anno_Esercizio(+) = cAnno.Anno_Creazione
          and classPatto.Codclass_Patto(+) = cAnno.Codclass_Patto
          and tit.titolo = cAnno.titolo
          and cat.titolo = cAnno.titolo
          and cat.categoria = cAnno.Categoria
          and ris.anno_creazione = cAnno.Anno_Creazione
          and ris.titolo = cAnno.titolo
          and ris.categoria = cAnno.Categoria
          and ris.risorsa = cAnno.Risorsa
          and vent.titolo(+) = cAnno.titolo
          and vent.categoria(+) = cAnno.categoria
          and vent.voce_eco(+) = cAnno.Voce_Eco
          and cdc.anno_creazione = cUebAnno.Anno_Creazione
          and cdc.tipocdc = cUebAnno.Tipocdc
          and cdc.cdc = cUebAnno.Cdc
          and cdr.anno_creazione = cdc.Anno_Creazione
          and cdr.centro_resp = cdc.Centro_Resp
          and coel.anno_creazione(+) = cUebAnno.Anno_Creazione
          and coel.coel(+) = cUebAnno.Coel
          and capEcc.Tipo_Capitolo (+)='P'
          and capEcc.Eu (+)  ='E'
          and capEcc.Anno_Esercizio  (+) = cUebAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cUebAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cUebAnno.Nro_Articolo
          and capEcc.numero_ueb      (+) = 
                 decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '00' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '000')*/
                 );
    
    --- aggiornamento stanziamento_iniziale_res
     msgRes:='Aggiornamento migr_capitolo_entrata.stanziamento_iniziale_res CAP-EP.';
-- 17.07.2015 Daniela: la tabella letta è cambiata, il campo usato è impoatt_no_riacc
-- 23.02.2016 Sofia  : riportato calcolo stanz. res su tabella accertamenti
/* 21.04.2016 Sofia - valorizzati con campi aggiunti in capcdc_prev_e
    update migr_capitolo_entrata m
    set m.stanziamento_iniziale_res=  
    (select 
--        nvl(sum(i.impoatt),0)
        nvl(sum(i.impoini),0)  -- 15.04.2016 Sofia
--        nvl(sum(i.impoatt_no_riacc),0)
     from accertamenti i
--          accertamenti_contabilia i
     where m.anno_esercizio=p_anno_esercizio and
           m.tipo_capitolo='CAP-EP' and
           i.anno_esercizio=m.anno_esercizio and
           i.anno_residuo<i.anno_esercizio and
           i.annoacc<i.anno_esercizio and  -- 15.04.2016 Sofia
           i.nro_capitolo=m.numero_capitolo and
           i.nro_articolo=m.numero_articolo and
           i.tipofin=decode(substr(m.numero_ueb,1,1),'1','MB','MU') and
           i.cdc=substr(m.numero_ueb,3,3) and
           i.coel=substr(m.numero_ueb,6,4) 
           and i.staoper !='A'
           )
     where m.ente_proprietario_id = p_ente and
           m.anno_esercizio=p_anno_esercizio and 
           m.tipo_capitolo='CAP-EP' and
           0!=(select count(*)
               from accertamenti i
                    --accertamenti_contabilia i
               where i.anno_esercizio=m.anno_esercizio and
                     i.anno_residuo<i.anno_esercizio and
                     i.annoacc<i.anno_esercizio and  -- 15.04.2016 Sofia
                     i.nro_capitolo=m.numero_capitolo and
                     i.nro_articolo=m.numero_articolo and
                     i.tipofin=decode(substr(m.numero_ueb,1,1),'1','MB','MU') and
                     i.cdc=substr(m.numero_ueb,3,3) and
                     i.coel=substr(m.numero_ueb,6,4) 
                     and i.staoper !='A'
                     );
                     
     -- aggiornamento stanziamento_inziale_cassa                
      msgRes:='Aggiornamento migr_capitolo_entrata.stanziamento_iniziale_cassa CAP-EP.';
     update migr_capitolo_entrata m
     set m.stanziamento_iniziale_cassa=m.stanziamento_iniziale+m.stanziamento_iniziale_res
     where m.ente_proprietario_id = p_ente and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EP';
     
     msgRes:='Aggiornamento migr_capitolo_entrata.stanziamento_res, migr_capitolo_entrata.stanziamento_cassa CAP-EP.';
     -- aggiornamento stanziamento_res e stanziamento_cassa
     update migr_capitolo_entrata m
     set m.stanziamento_res=m.stanziamento_iniziale_res, m.stanziamento_cassa=m.stanziamento+m.stanziamento_iniziale_res
     where m.ente_proprietario_id = p_ente and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EP'; */
     
       pCodRes:=codRes;           
       pMsgRes:='Migrazione capitolo entrata previsione OK.';
       commit;
   
exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
 end migrazione_cpe;

 procedure migrazione_cge(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
 begin
    -- pulizia tabella migrazione per capitoli di gestione di entrata
    msgRes:='Pulizia migr_capitolo_entrata CAP-EG.';
    delete migr_capitolo_entrata
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-EG'
       and fl_migrato = 'N'
       and ente_proprietario_id = p_ente;

    --- inserimento con stanziamento_iniziale e stanziamento valorizzati
    msgRes:='Inserimento migr_capitolo_entrata CAP-EG.';
    insert into migr_capitolo_entrata
      (capent_id,tipo_capitolo,anno_esercizio, numero_capitolo, numero_articolo, numero_ueb,
       descrizione, descrizione_articolo,
       titolo,tipologia,categoria,pdc_fin_quarto,pdc_fin_quinto,note,flag_per_memoria,flag_rilevante_iva,
       tipo_finanziamento,tipo_vincolo, tipo_fondo,
       siope_livello_1,siope_livello_2,siope_livello_3,
       classificatore_1,classificatore_2,classificatore_3,classificatore_4,classificatore_5,
       classificatore_6,classificatore_7,classificatore_8, classificatore_9,classificatore_10,
       classificatore_11,classificatore_12,classificatore_13,classificatore_14,classificatore_15,
       centro_resp,cdc,
       classe_capitolo,flag_accertabile,
       stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
       stanziamento,stanziamento_res,stanziamento_cassa,
       stanziamento_iniziale_anno2,stanziamento_anno2,
       stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
       trasferimenti_comunitari)                                                  -- 05.04.2016 Davide
      (
      -- querey da eliminare a favore della commentata sotto, questa mette in outer join le tabelle di riclassificazione dei capitoli
select migr_capent_id_seq.nextval,'CAP-EG',
              cAnno.Anno_Esercizio, cAnno.nro_capitolo,cAnno.nro_articolo,
              decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||
              cUebAnno.Cdc || nvl(cUebAnno.coel, '0000'),
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
              --cAnno.descri,
              --cAnno.descri,
              descri_capitolo.descri,cAnno.descri,
-- 09.09.2015 Davide fine              
              trim(tit118.titolo),
              decode(trim(tip118.tipologia), null, null, trim(tip118.titolo) || '0' || trim(tip118.tipologia) || '00'),
              trim(cap118.codice_categoria),
              decode(nvl(cap118.piano_fin_4l, ' '),' ',null,decode(ltrim(rtrim(pdcFin.Livello)),'IV',pdcFin.Conto,null)),
              decode(nvl(ueb118.piano_fin_5l, ' '),' ',null,decode(ltrim(rtrim(pdcFinUeb.Livello)),'V',pdcFinUeb.Conto,null)),
              null,
              cAnno.Escl_Peg, cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ', null,tipoFin.Tipofin || '||' || tipoFin.Descri),
              null,
              decode(nvl(tipoFondi.conto_vincolato, 0),0,null,tipoFondi.conto_vincolato || '||' || tipoFondi.Descri),
    -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli       
              --null, null, null, 
              null,null, cAnno.codice_gestionale, 
    -- DAVIDE - 16.12.015 - Fine
              decode(nvl(cUebAnno.All_Bil_Prev, ' '),' ',null,allPrev.Cod_Allegato || '||' || allPrev.Descri),
              decode(nvl(cUebAnno.All_Cons, ' '),' ',null,allCons.Cod_Allegato || '||' || allCons.Descri_Cons),
              decode(nvl(cAnno.Codclass_Patto, ' '),' ',null,classPatto.Codclass_Patto || '||' || classPatto.descri),
              decode(nvl(cUebAnno.area, ' '),' ', null,cUebAnno.area || '||' || a.descri),
              decode(nvl(cUebAnno.assessorato, ' '),' ',null,ass.Assessorato || '||' || ass.descrizione || ' ' ||ass.assessore),
              decode(nvl(cUebAnno.Coel, ' '),' ',null,coel.coel || '||' || coel.descri),
              null,null,null,null,
              'E' || '/' || cAnno.titolo || '||' || tit.descri,
              'E' || '/' || cAnno.titolo || '.' || cAnno.Categoria || '||' ||cat.descri,
              'E' || '/' || cAnno.titolo || '.' || cAnno.categoria || '.' ||cAnno.Risorsa || '||' || ris.descri,
              decode(nvl(cAnno.Voce_Eco, ' '),' ',null,
                     'E' || '/' || vent.titolo || '.' || vent.categoria || '.' || vent.voce_eco || '||' || vent.descri),
              null,
              cdr.centro_resp,cdc.cdc,
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
              cUebAnno.St_attu,0,0,
              cUebAnno.St_attu,0,0,
              cUebAnno2.St_attu,cUebAnno2.St_attu,
              cUebAnno3.St_attu,cUebAnno3.St_attu, p_ente,
			  cAnno.trasf_comu                                                               -- 05.04.2016 Davide
         from cap_entrata   cAnno, cap_entrata   cAnno2,cap_entrata   cAnno3,
              capcdc_entrata cUebAnno, capcdc_entrata cUebAnno2, capcdc_entrata cUebAnno3,
--              siac_capitoli_gest cap118, siac_ueb_gest ueb118, 17.12.2015 Sofia le tabelle _gest non vengono ALIMENTATE
              siac_capitoli cap118, siac_ueb ueb118,              
              siac_titoli tit118, siac_tipologie tip118,siac_categorie categ118,
              siac_piano_dei_conti pdcFin,siac_piano_dei_conti pdcFinUeb,
              tipo_fin tipoFin, conti_vincolati tipoFondi,
              aree a, assessorati ass, tab_allegati allPrev, tab_allegati allCons,
              tabclass_patto classPatto,titent tit,categorie cat,
              risorse ris, vocecoent vent,
              centri_resp cdr, tabcdc cdc,
              codici_elaborativi   coel,
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
              (select distinct r.nro_capitolo, r.descri from cap_entrata r
                where r.nro_articolo=0 and r.anno_esercizio=p_anno_esercizio and r.anno_creazione=p_anno_esercizio) descri_capitolo,
-- 09.09.2015 Davide fine
              migr_capitolo_eccezione capEcc
        where cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.eu = 'E'
          and cap118.anno_esercizio = cAnno.anno_esercizio
          and cap118.anno_bilancio = cAnno.anno_esercizio
          and cap118.nro_capitolo = cAnno.nro_capitolo
          and cap118.nro_articolo = cAnno.nro_articolo
          and cUebAnno.Anno_esercizio = cAnno.Anno_esercizio
          and cUebAnno.Nro_Capitolo = cAnno.Nro_Capitolo
          and cUebAnno.Nro_articolo = cAnno.Nro_articolo
          and cUebAnno2.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 1
          and cUebAnno2.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno2.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno2.cdc = cUebAnno.cdc
          and cUebAnno2.tipofin = cUebAnno.tipofin
          and cUebAnno2.coel = cUebAnno.coel
          and cUebAnno2.tipocdc = cUebAnno.tipocdc
          and cUebAnno3.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 2
          and cUebAnno3.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno3.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno3.cdc = cUebAnno.cdc
          and cUebAnno3.tipofin = cUebAnno.tipofin
          and cUebAnno3.coel = cUebAnno.coel
          and cUebAnno3.tipocdc = cUebAnno.tipocdc
          and ueb118.anno_esercizio = cUebAnno.anno_esercizio
          and ueb118.anno_bilancio =cUebAnno.anno_esercizio-- ueb118.anno_esercizio
          and ueb118.eu = 'E'
          and ueb118.nro_capitolo = cUebAnno.nro_capitolo
          and ueb118.nro_articolo = cUebAnno.nro_articolo
          and ueb118.settore = cUebAnno.Cdc
          and ueb118.coel = cUebAnno.coel
          and ueb118.tipo_fin = cUebAnno.Tipofin
          and tit118.eu(+) = 'E'
          and tit118.titolo(+) = cap118.titolo
          and tip118.eu(+) = 'E'
          and tip118.titolo(+) = cap118.titolo
          and tip118.tipologia(+) = cap118.tipologia
          and categ118.eu(+) = 'E'
          and categ118.titolo(+) = cap118.titolo
          and categ118.tipologia(+) = cap118.tipologia
          and categ118.categoria(+) = cap118.categoria
          and pdcFin.eu(+) = 'E'
          and pdcFin.Conto(+) = cap118.piano_fin_4l
          and pdcFinUeb.eu(+) = 'E'
          and pdcFinUeb.Conto(+) = ueb118.piano_fin_5l
          and tipoFin.Tipofin(+) = cUebAnno.Tipofin
          and tipoFondi.Anno_Creazione(+) = cAnno.Anno_esercizio
          and tipoFondi.Conto_Vincolato(+) = cAnno.Conto_Vincolato
          and a.anno_creazione(+) = cUebAnno.Anno_esercizio
          and a.area(+) = cUebAnno.area
          and ass.anno_creazione(+) = cUebAnno.Anno_esercizio
          and ass.assessorato(+) = cUebAnno.Assessorato
          and allPrev.Anno_Creazione(+) = cUebAnno.anno_esercizio
          and allPrev.Cod_Allegato(+) = cUebAnno.All_Bil_Prev
          and allCons.Anno_Creazione(+) = cUebAnno.anno_esercizio
          and allCons.Cod_Allegato(+) = cUebAnno.All_Cons
          and classPatto.Anno_Esercizio(+) = cAnno.Anno_esercizio
          and classPatto.Codclass_Patto(+) = cAnno.Codclass_Patto
          and tit.titolo = cAnno.titolo
          and cat.titolo = cAnno.titolo
          and cat.categoria = cAnno.Categoria
          and ris.anno_creazione = cAnno.Anno_esercizio
          and ris.titolo = cAnno.titolo
          and ris.categoria = cAnno.Categoria
          and ris.risorsa = cAnno.Risorsa
          and vent.titolo(+) = cAnno.titolo
          and vent.categoria(+) = cAnno.categoria
          and vent.voce_eco(+) = cAnno.Voce_Eco
          and cdc.anno_creazione = cUebAnno.Anno_esercizio
          and cdc.tipocdc = cUebAnno.Tipocdc
          and cdc.cdc = cUebAnno.Cdc
          and cdr.anno_creazione = cdc.Anno_Creazione
          and cdr.centro_resp = cdc.Centro_Resp
          and coel.anno_creazione(+) = cUebAnno.Anno_esercizio
          and coel.coel(+) = cUebAnno.Coel
          and capEcc.Tipo_Capitolo (+)='G'
          and capEcc.Eu (+)  ='E'
          and capEcc.Anno_Esercizio  (+) = cUebAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cUebAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cUebAnno.Nro_Articolo
          and capEcc.numero_ueb      (+) = 
                 decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '0' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '0000')      
          and capEcc.ente_proprietario_id (+)=p_ente -- 07.01.2016 Sofia aggiunto       
-- 09.09.2015 Davide correzione descrizione Capitolo - deve essere diversa da quella dell'Articolo
--            se num. Articolo <> 0
          and descri_capitolo.nro_capitolo = cAnno.Nro_Capitolo
-- 09.09.2015 Davide fine
      /*
      select migr_capent_id_seq.nextval,'CAP-EG',
              cAnno.Anno_Esercizio, cAnno.nro_capitolo,cAnno.nro_articolo,
              decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '00' ||
              cUebAnno.Cdc || nvl(cUebAnno.coel, '000'),
              cAnno.descri,
              cAnno.descri,
              trim(tit118.titolo),
              decode(trim(tip118.tipologia), null, null, trim(tip118.titolo) || '0' || trim(tip118.tipologia) || '00'),
              trim(categ118.categoria),
              decode(nvl(cap118.piano_fin_4l, ' '),' ',null,decode(ltrim(rtrim(pdcFin.Livello)),'IV',pdcFin.Conto,null)),
              decode(nvl(ueb118.piano_fin_5l, ' '),' ',null,decode(ltrim(rtrim(pdcFinUeb.Livello)),'V',pdcFinUeb.Conto,null)),
              null,
              cAnno.Escl_Peg, cAnno.Rilev_Iva,
              decode(nvl(tipoFin.Tipofin, ' '),' ', null,tipoFin.Tipofin || '||' || tipoFin.Descri),
              null,
              decode(nvl(tipoFondi.conto_vincolato, 0),0,null,tipoFondi.conto_vincolato || '||' || tipoFondi.Descri),
              null, null,null,
              decode(nvl(cUebAnno.All_Bil_Prev, ' '),' ',null,allPrev.Cod_Allegato || '||' || allPrev.Descri),
              decode(nvl(cUebAnno.All_Cons, ' '),' ',null,allCons.Cod_Allegato || '||' || allCons.Descri),
              decode(nvl(cAnno.Codclass_Patto, ' '),' ',null,classPatto.Codclass_Patto || '||' || classPatto.descri),
              decode(nvl(cUebAnno.area, ' '),' ', null,cUebAnno.area || '||' || a.descri),
              decode(nvl(cUebAnno.assessorato, ' '),' ',null,ass.Assessorato || '||' || ass.descrizione || ' ' ||ass.assessore),
              decode(nvl(cUebAnno.Coel, ' '),' ',null,coel.coel || '||' || coel.descri),
              null,null,null,null,
              'E' || '/' || cAnno.titolo || '||' || tit.descri,
              'E' || '/' || cAnno.titolo || '.' || cAnno.Categoria || '||' ||cat.descri,
              'E' || '/' || cAnno.titolo || '.' || cAnno.categoria || '.' ||cAnno.Risorsa || '||' || ris.descri,
              decode(nvl(cAnno.Voce_Eco, ' '),' ',null,
                     'E' || '/' || vent.titolo || '.' || vent.categoria || '.' || vent.voce_eco || '||' || vent.descri),
              null,
              cdr.centro_resp,cdc.cdc,
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
              cUebAnno.St_attu,0,0,
              cUebAnno.St_attu,0,0,
              cUebAnno2.St_attu,cUebAnno2.St_attu,
              cUebAnno3.St_attu,cUebAnno3.St_attu, p_ente
         from cap_entrata   cAnno, cap_entrata   cAnno2,cap_entrata   cAnno3,
              capcdc_entrata cUebAnno, capcdc_entrata cUebAnno2, capcdc_entrata cUebAnno3,
              siac_capitoli_gest cap118, siac_ueb_gest ueb118,
              siac_titoli tit118, siac_tipologie tip118,siac_categorie categ118,
              siac_piano_dei_conti pdcFin,siac_piano_dei_conti pdcFinUeb,
              tipo_fin tipoFin, conti_vincolati tipoFondi,
              aree a, assessorati ass, tab_allegati allPrev, tab_allegati allCons,
              tabclass_patto classPatto,titent tit,categorie cat,
              risorse ris, vocecoent vent,
              centri_resp cdr, tabcdc cdc,
              codici_elaborativi   coel, migr_capitolo_eccezione capEcc
        where cAnno.Anno_Esercizio = p_anno_esercizio
          and cAnno2.anno_esercizio = to_number(cAnno.anno_esercizio) + 1
          and cAnno2.nro_capitolo = cAnno.nro_capitolo
          and cAnno2.nro_articolo = cAnno.nro_articolo
          and cAnno3.anno_esercizio = to_number(cAnno.anno_esercizio) + 2
          and cAnno3.nro_capitolo = cAnno.nro_capitolo
          and cAnno3.nro_articolo = cAnno.nro_articolo
          and cap118.eu = 'E'
          and cap118.anno_esercizio = cAnno.anno_esercizio
          and cap118.anno_bilancio = cAnno.anno_esercizio
          and cap118.nro_capitolo = cAnno.nro_capitolo
          and cap118.nro_articolo = cAnno.nro_articolo
          and cUebAnno.Anno_esercizio = cAnno.Anno_esercizio
          and cUebAnno.Nro_Capitolo = cAnno.Nro_Capitolo
          and cUebAnno.Nro_articolo = cAnno.Nro_articolo
          and cUebAnno2.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 1
          and cUebAnno2.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno2.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno2.cdc = cUebAnno.cdc
          and cUebAnno2.tipofin = cUebAnno.tipofin
          and cUebAnno2.coel = cUebAnno.coel
          and cUebAnno2.tipocdc = cUebAnno.tipocdc
          and cUebAnno3.anno_esercizio =
              to_number(cUebAnno.anno_esercizio) + 2
          and cUebAnno3.Nro_Capitolo = cUebAnno.Nro_Capitolo
          and cUebAnno3.Nro_articolo = cUebAnno.Nro_articolo
          and cUebAnno3.cdc = cUebAnno.cdc
          and cUebAnno3.tipofin = cUebAnno.tipofin
          and cUebAnno3.coel = cUebAnno.coel
          and cUebAnno3.tipocdc = cUebAnno.tipocdc
          and ueb118.anno_esercizio = cUebAnno.anno_esercizio
          and ueb118.anno_bilancio = ueb118.anno_esercizio
          and ueb118.eu = 'E'
          and ueb118.nro_capitolo = cUebAnno.nro_capitolo
          and ueb118.nro_articolo = cUebAnno.nro_articolo
          and ueb118.settore = cUebAnno.Cdc
          and ueb118.coel = cUebAnno.coel
          and ueb118.tipo_fin = cUebAnno.Tipofin
          and tit118.eu(+) = 'E'
          and tit118.titolo(+) = cap118.titolo
          and tip118.eu(+) = 'E'
          and tip118.titolo(+) = cap118.titolo
          and tip118.tipologia(+) = cap118.tipologia
          and categ118.eu(+) = 'E'
          and categ118.titolo(+) = cap118.titolo
          and categ118.tipologia(+) = cap118.tipologia
          and categ118.categoria(+) = cap118.categoria
          and pdcFin.eu(+) = 'E'
          and pdcFin.Conto(+) = cap118.piano_fin_4l
          and pdcFinUeb.eu(+) = 'E'
          and pdcFinUeb.Conto(+) = ueb118.piano_fin_5l
          and tipoFin.Tipofin(+) = cUebAnno.Tipofin
          and tipoFondi.Anno_Creazione(+) = cAnno.Anno_esercizio
          and tipoFondi.Conto_Vincolato(+) = cAnno.Conto_Vincolato
          and a.anno_creazione(+) = cUebAnno.Anno_esercizio
          and a.area(+) = cUebAnno.area
          and ass.anno_creazione(+) = cUebAnno.Anno_esercizio
          and ass.assessorato(+) = cUebAnno.Assessorato
          and allPrev.Anno_Creazione(+) = cUebAnno.anno_esercizio
          and allPrev.Cod_Allegato(+) = cUebAnno.All_Bil_Prev
          and allCons.Anno_Creazione(+) = cUebAnno.anno_esercizio
          and allCons.Cod_Allegato(+) = cUebAnno.All_Cons
          and classPatto.Anno_Esercizio(+) = cAnno.Anno_esercizio
          and classPatto.Codclass_Patto(+) = cAnno.Codclass_Patto
          and tit.titolo = cAnno.titolo
          and cat.titolo = cAnno.titolo
          and cat.categoria = cAnno.Categoria
          and ris.anno_creazione = cAnno.Anno_esercizio
          and ris.titolo = cAnno.titolo
          and ris.categoria = cAnno.Categoria
          and ris.risorsa = cAnno.Risorsa
          and vent.titolo(+) = cAnno.titolo
          and vent.categoria(+) = cAnno.categoria
          and vent.voce_eco(+) = cAnno.Voce_Eco
          and cdc.anno_creazione = cUebAnno.Anno_esercizio
          and cdc.tipocdc = cUebAnno.Tipocdc
          and cdc.cdc = cUebAnno.Cdc
          and cdr.anno_creazione = cdc.Anno_Creazione
          and cdr.centro_resp = cdc.Centro_Resp
          and coel.anno_creazione(+) = cUebAnno.Anno_esercizio
          and coel.coel(+) = cUebAnno.Coel
          and capEcc.Tipo_Capitolo (+)='G'
          and capEcc.Eu (+)  ='E'
          and capEcc.Anno_Esercizio  (+) = cUebAnno.anno_esercizio
          and capEcc.numero_capitolo (+) = cUebAnno.Nro_Capitolo
          and capEcc.numero_articolo (+) = cUebAnno.Nro_Articolo
          and capEcc.numero_ueb      (+) = 
                 decode(cUebAnno.tipofin, 'MB', 1, 'MU', 2) || '00' ||cUebAnno.Cdc || nvl(cUebAnno.coel, '000')*/
                 );
    
    --- aggiornamento stanziamento_iniziale_res
    msgRes:='Aggiornamento migr_capitolo_entrata.stanziamento_iniziale_res CAP-EG.';
    update migr_capitolo_entrata m
    set m.stanziamento_iniziale_res=  
    (select nvl(sum(i.impoatt),0)
     from accertamenti i
     where m.anno_esercizio=p_anno_esercizio and
           m.tipo_capitolo='CAP-EG' and
           i.anno_esercizio=m.anno_esercizio and
           i.anno_residuo<i.anno_esercizio and
           i.nro_capitolo=m.numero_capitolo and
           i.nro_articolo=m.numero_articolo and
           i.tipofin=decode(substr(m.numero_ueb,1,1),'1','MB','MU') and
           i.cdc=substr(m.numero_ueb,3,3) and
           i.coel=substr(m.numero_ueb,6,4) and
           i.staoper !='A' )
     where m.ente_proprietario_id=p_ente and
           m.anno_esercizio=p_anno_esercizio and 
           m.tipo_capitolo='CAP-EG' and
           0!=(select count(*)
               from accertamenti i
               where i.anno_esercizio=m.anno_esercizio and
                     i.anno_residuo<i.anno_esercizio and
                     i.nro_capitolo=m.numero_capitolo and
                     i.nro_articolo=m.numero_articolo and
                     i.tipofin=decode(substr(m.numero_ueb,1,1),'1','MB','MU') and
                     i.cdc=substr(m.numero_ueb,3,3) and
                     i.coel=substr(m.numero_ueb,6,4) and
                     i.staoper !='A');
                     
     
     -- aggiornamento stanziamento_inziale_cassa                
     msgRes:='Aggiornamento migr_capitolo_entrata.stanziamento_iniziale_cassa CAP-EG.';
     update migr_capitolo_entrata m
     set m.stanziamento_iniziale_cassa=m.stanziamento_iniziale+m.stanziamento_iniziale_res
     where m.ente_proprietario_id=p_ente and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EG';
     
     -- aggiornamento stanziamento_res e stanziamento_cassa
     msgRes:='Aggiornamento migr_capitolo_entrata.stanziamento_res, migr_capitolo_entrata.stanziamento_cassa CAP-EG.';
     update migr_capitolo_entrata m
     set m.stanziamento_res=m.stanziamento_iniziale_res, m.stanziamento_cassa=m.stanziamento+m.stanziamento_iniziale_res
     where m.ente_proprietario_id=p_ente and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EG'; 
     
     pCodRes:=codRes;           
     pMsgRes:='Migrazione capitolo entrata gestione OK.';
     commit;
   
exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
  end migrazione_cge;

  procedure migrazione_vincoli_cp(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2) is
    codRes number:=0;
    msgRes varchar2(1500):=null;

    vincoloId   integer := 0;
    nroCapitolo integer := 0;
    nroArticolo integer := 0;

  begin
    msgRes:='Pulizia migr_vincolo_capitolo previsione.';  
    delete migr_vincolo_capitolo
     where anno_esercizio = p_anno_esercizio
       and fl_migrato = 'N'
       and tipo_vincolo_bil = 'P'
       and ente_proprietario_id = p_ente;

    msgRes:='Inserimento migr_vincolo_capitolo previsione.';   
    nroCapitolo := -1;
    nroArticolo := -1;
    -- tipo_vincolo='FV'
    for migrCap in (select distinct mcap.anno_esercizio,
                                    mcap.numero_capitolo,
                                    mcap.numero_articolo,
                                    mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.ente_proprietario_id = p_ente
                       and mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UP'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 2) = 'FV'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from coll_ent_usc v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_cap_u = mcap.numero_capitolo
                               and v.nro_art_u = mcap.numero_articolo)
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
                v.nro_cap_e,
                v.nro_art_e,
                p_ente
           from coll_ent_usc v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_cap_u = migrCap.Numero_Capitolo
            and v.nro_art_u = migrCap.Numero_Articolo
            and v.nro_cap_e || v.nro_art_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.ente_proprietario_id = p_ente
                    and mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EP'));

    end loop;
   pCodRes:=codRes;           
   pMsgRes:='Migrazione vincolo capitolo previsione OK.';
   commit;
   
exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
  end migrazione_vincoli_cp;

 procedure migrazione_vincoli_cg(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2) is
    codRes number:=0;
    msgRes varchar2(1500):=null;

    vincoloId   integer := 0;
    nroCapitolo integer := 0;
    nroArticolo integer := 0;

  begin
    msgRes:='Pulizia migr_vincolo_capitolo gestione.';  
    delete migr_vincolo_capitolo
     where anno_esercizio = p_anno_esercizio
       and fl_migrato = 'N'
       and tipo_vincolo_bil = 'G'
       and ente_proprietario_id = p_ente;

    msgRes:='Inserimento migr_vincolo_capitolo gestione.';
    nroCapitolo := -1;
    nroArticolo := -1;
    -- tipo_vincolo='FV'
    for migrCap in (select distinct mcap.anno_esercizio,
                                    mcap.numero_capitolo,
                                    mcap.numero_articolo,
                                    mcap.tipo_vincolo
                      from migr_capitolo_uscita mcap
                     where mcap.ente_proprietario_id = p_ente
                       and mcap.anno_esercizio = p_anno_esercizio
                       and mcap.tipo_capitolo = 'CAP-UG'
                       and mcap.fl_migrato = 'N'
                       and mcap.tipo_vincolo is not null
                       and substr(mcap.tipo_vincolo, 1, 2) = 'FV'
                       and 0 !=
                           (select nvl(count(*), 0)
                              from coll_ent_usc v
                             where v.anno_esercizio = mcap.anno_esercizio
                               and v.nro_cap_u = mcap.numero_capitolo
                               and v.nro_art_u = mcap.numero_articolo)
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
                v.nro_cap_e,
                v.nro_art_e,
                p_ente
           from coll_ent_usc v
          where v.anno_esercizio = migrCap.anno_esercizio
            and v.nro_cap_u = migrCap.Numero_Capitolo
            and v.nro_art_u = migrCap.Numero_Articolo
            and v.nro_cap_e || v.nro_art_e in
                (select mCapE.numero_capitolo || mCapE.numero_articolo
                   from migr_capitolo_entrata mCapE
                  where mCapE.ente_proprietario_id = p_ente
                    and mCapE.anno_esercizio = migrCap.anno_esercizio
                    and mCapE.fl_migrato = 'N'
                    and mCapE.tipo_capitolo = 'CAP-EG'));

    end loop;
    
  pCodRes:=codRes;           
  pMsgRes:='Migrazione vincolo capitolo gestione OK.';
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
     where ente_proprietario_id = p_ente
       and fl_migrato = 'N'
       and tipo_capitolo in ('CAP-UP', 'CAP-EP');

    msgRes:='Inserimento migr_classif_capitolo previsione.';
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
       'Allegati bilancio previsione',
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
       'Allegati consuntivo',
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
       'Classificatore Patto',
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
       'Classificatore Capitoli',
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
       'Aree',
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
       'Assessorati',
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
       'CLASSIFICATORE_7',
       'Coel',
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
       'Ex Titolo Spesa',
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
       'CLASSIFICATORE_36',
       'Allegati bilancio di previsione',
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
       'Allegati consuntivo',
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
       'CLASSIFICATORE_38',
       'Classificatore Capitoli',
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
       'CLASSIFICATORE_39',
       'Aree',
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
       'CLASSIFICATORE_40',
       'Assessorati',
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
       'CLASSIFICATORE_41',
       'Coel',
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
       'Ex Titolo Entrata',
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
       'Ex Risorsa',
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
       'CLASSIFICATORE_49',
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
     where ente_proprietario_id = p_ente
       and fl_migrato = 'N'
       and tipo_capitolo in ('CAP-UG', 'CAP-EG');

    msgRes:='Inserimento migr_classif_capitolo gestione.';
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
       'Allegati bilancio previsione',
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
       'Allegati consuntivo',
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
       'Classificatore Patto',
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
       'Classificatore Capitoli',
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
       'Aree',
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
       'Assessorati',
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
       'CLASSIFICATORE_7',
       'Coel',
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
       'Ex Titolo Spesa',
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
       'CLASSIFICATORE_36',
       'Allegati bilancio di previsione',
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
       'Allegati consuntivo',
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
       'CLASSIFICATORE_38',
       'Classificatore Capitoli',
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
       'CLASSIFICATORE_39',
       'Aree',
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
       'CLASSIFICATORE_40',
       'Assessorati',
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
       'CLASSIFICATORE_41',
       'Coel',
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
       'Ex Titolo Entrata',
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
       'Ex Risorsa',
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
       'CLASSIFICATORE_49',
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


  procedure migrazione_impegni(p_ente_proprietario_id number,
                               p_anno_esercizioIniziale varchar2,
                               p_anno_esercizio       varchar2,
                               p_cod_res              out number,
                               p_imp_inseriti         out number,
                               p_imp_scartati         out number,
                               msgResOut              out varchar2) is
    msgRes varchar2(1500) := null;
    codRes number := 0;

    h_soggetto_determinato varchar2(1) := null;
    h_classe_soggetto      varchar2(250) := null;
    h_indet                number := 0;
    h_sogg_migrato         number := 0;
    h_stato_impegno        varchar2(1) := null;
    h_tipo_impegno         varchar2(5) := null;

    h_numero_ueb      number := 1;
    h_numero_ueb_orig number := 1;
    --h_capitolo        number := 0;
    --h_per_sanitario varchar2(1):=null;
    h_impegno varchar2(50) := null;
    h_num     number := 0;

    h_anno_provvedimento   varchar2(4) := null;
    h_numero_provvedimento varchar2(10) := null;
    h_tipo_provvedimento   varchar2(20) := null;
    --h_direzione_provvedimento varchar2(20):=null;

    h_stato_provvedimento   varchar2(5) := null;
    h_oggetto_provvedimento varchar2(500) := null;
    h_note_provvedimento    varchar2(500) := null;
    
    h_sac_provvedimento     varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento

    h_nota varchar2(250) := null;

    h_classificatore_1 varchar2(250) := null;
    h_classificatore_2 varchar2(250) := null;
    h_classificatore_3 varchar2(250) := null;
    h_classificatore_4 varchar2(250) := null;
    h_classificatore_5 varchar2(250) := null;
    h_pdc_finanziario MIGR_CAPITOLO_USCITA.PDC_FIN_QUINTO%type := null;
    h_cofog varchar2(50);
    h_parere_finanziario integer := 1; -- non cambia sempre passato a TRUE
    
    msgMotivoScarto varchar2(1500) := null;

    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;
 -- DAVIDE - 23.02.016 - segnalazione impegni e gestione corretta leggi_provvedimento
    segnalare    boolean := False; -- True: il record è inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record è inserito nella sola tabella migr_*
    
  begin

    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    msgResOut := 'Migrazione impegni.';
    msgRes    := 'Lettura Impegni.';

    for migrImpegno in (select i.anno_esercizio,
                               i.annoimp anno_impegno,
                               i.nimp numero_impegno,
                               0 numero_subimpegno,
                               null pluriennale,
                               'N' capo_riacc,
                               i.nro_capitolo numero_capitolo,
                               i.nro_articolo numero_articolo,
                               decode(i.tipofin, 'MB', 1, 'MU', 2) || '0' ||
                               i.Cdc || nvl(i.coel, '0000') numero_ueb
                               ,to_char(i.data_ins,'YYYY-MM-DD') data_emissione,
                               null      data_scadenza,
                               i.staoper stato_impegno,
                               i.impoini importo_iniziale,
                               i.impoatt importo_attuale,
                               nvl(i.descri,'DESCRIZIONE NULL')  descrizione,
                                i.annoimp anno_capitolo_orig
                               ,i.ex_capitolo numero_capitolo_orig
                               ,i.ex_articolo numero_articolo_orig
                               , decode(i.ex_tipofin, 'MB', 1, 'MU', 2) || '0' ||
                               i.ex_Cdc || nvl(i.ex_coel, '0000') numero_ueb_orig
                               ,decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      i.annoprov) anno_provvedimento,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      to_number(i.nprov)) numero_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                               i.codben codice_soggetto
                               --, i.tipoforn classe_soggetto
                               --,i.nota
                               --, i.cup
                               --,i.cig
                              ,
                               TIPO_IMPEGNO tipo_impegno,
                               sdf,
                               null         anno_impegno_plur,
                               null         numero_impegno_plur,
                               i.annoimp_orig anno_impegno_riacc, -- 20.07.2015 prima lasciato a NULL
                               i.nimp_orig    numero_impegno_riacc, -- 20.07.2015 prima lasciato a NULL
                               null         opera
                               --, i.cod_interv_class
                              ,
                               null pdc_finanziario,
                               null missione,
                               null programma,
                               null cofog,
                               null transazione_ue_spesa,
                               null siope_spesa,
                               null spesa_ricorrente,
                               null politiche_regionali_unitarie,
                               null pdc_economico_patr,
                               I.IMP_FONDI -- se valorizzato con 'S' valorizzo il campo note con 'IMPEGNO FONDI'
                        --i.codtitgiu utilizzato solo per accertamenti
                        -- ,i.trasf_tipo
                        --,i.trasf_voce
                        -- , i.nord direzione_delegata
                        --, i.centro_resp centro_resp
                          from impegni i
                         where i.anno_esercizio = p_anno_esercizio
                           and i.staoper in ('P', 'D')
                           and I.SDF <> 'S' -- Gli impegni SDF (senza disponibilità di fondi) non vengoni migrati
                         order by 1, 2, 3) loop
      -- inizializza variabili
      --h_classe_soggetto:=null;
      h_indet                := 0;
      h_soggetto_determinato := 'S';
      h_sogg_migrato         := 0;
      h_stato_impegno        := null;
      h_anno_provvedimento   := null;
      h_numero_provvedimento := null;
      h_tipo_provvedimento   := null;
      --h_direzione_provvedimento:=null;
      h_stato_provvedimento   := null;
      h_oggetto_provvedimento := null;
      h_note_provvedimento    := null;
      
      h_sac_provvedimento     := null; -- DAVIDE - Gestione SAC Provvedimento
      
      --h_per_sanitario:=null;
      h_classificatore_1 := null;
      h_classificatore_2 := null;
      h_classificatore_3 := null;
      h_nota             := null;
      codRes             := 0;
      msgMotivoScarto    := null;
      msgRes             := null;
      h_num              := 0;
      --h_capitolo         := 0;
      h_pdc_finanziario :=null;
      h_cofog := null;
      
 -- DAVIDE - 23.02.016 - segnalazione impegni e gestione corretta leggi_provvedimento
      segnalare := false;

      h_impegno := 'Impegno ' || migrImpegno.anno_impegno || '/' ||
                   migrImpegno.numero_impegno || '/' ||
                   migrImpegno.numero_ueb || '.';
      -- verifica capitolo migrato
      -- se esite il campo valorizzato PDC_FIN_QUINTO passa al campo  migr_impegno.PDC_FINANZIARIO
      begin
        msgRes := 'Lettura capitolo migrato.';
        select 
         PDC_FIN_QUINTO, COFOG into h_pdc_finanziario, h_cofog
          from migr_capitolo_uscita m
         where m.ente_proprietario_id=p_ente_proprietario_id
           and m.anno_esercizio = p_anno_esercizioIniziale
           and m.numero_capitolo = migrImpegno.numero_capitolo
           and m.numero_articolo =migrImpegno.numero_articolo
           and m.numero_ueb = migrImpegno.numero_ueb
           and m.tipo_capitolo = 'CAP-UG';
      exception
        when no_data_found then
          codRes := -1;
          msgRes := 'Capitolo non migrato.';
        when others then
          codRes := -1;
          msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';

      end;

      if codRes = 0 then
        -- soggetto_determinato
        if migrImpegno.codice_soggetto != 0 then
          h_soggetto_determinato := 'S';
        else
          msgRes                 := 'Lettura soggetto determinato S-N.';
          h_soggetto_determinato := 'N';
        end if;
      end if;

      -- definizione tipo_impegno
       if (upper(migrImpegno.tipo_impegno) = 'C' 
            or upper(migrImpegno.tipo_impegno) = 'S'
            or upper(migrImpegno.tipo_impegno) = 'D') then 
            h_tipo_impegno:='SVI';
       elsif (upper(migrImpegno.tipo_impegno) = 'M'
            or upper(migrImpegno.tipo_impegno) = 'Y')then 
            h_tipo_impegno:='MUT';
       else
            h_tipo_impegno:=null;
        end if;

      -- codice
      if h_soggetto_determinato = 'S' and codRes = 0 then

        msgRes := 'Verifica soggetto migrato.';
        begin
          select nvl(count(*), 0)
            into h_sogg_migrato
            from migr_soggetto
           where codice_soggetto = migrImpegno.codice_soggetto
             and ente_proprietario_id = p_ente_proprietario_id;

          if h_sogg_migrato = 0 then
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          end if;

        exception
          when no_data_found then
            h_sogg_migrato  := 0;
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          when others then
            codRes := -1;
            msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        end;

        if codRes = 0 and h_sogg_migrato = 0 then
          begin
            /*2 ----- colonna blocco_pag non esiste */
               select nvl(count(*),0) into h_num
               from fornitori
               where codben=migrImpegno.codice_soggetto and
                staoper in ('V','S');
            
            if h_num = 0 then
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            end if;
          exception
            when no_data_found then
              h_sogg_migrato  := 0;
              h_num           := 0;
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            when others then
              codRes := -1;
              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
          end;
        end if;
      end if;

      --  stato_impegno da calcolare
      /*if codRes = 0 then
        msgRes := 'Calcolo stato impegno.';
        if migrImpegno.stato_impegno = 'P' then
          h_stato_impegno := STATO_IMPEGNO_P;
        else
          if h_soggetto_determinato = 'S' then
            --3 ----- classe soggetto non recuperato quindi verifica condizione non necessaria
            -- or h_classe_soggetto is not null then
            h_stato_impegno := STATO_IMPEGNO_D;
          else
            -- Impegni definitivi senza attribuzione di un soggetto sono migrati in stato N 'Definitivi non liquidabili'
            h_stato_impegno := STATO_IMPEGNO_N;
          end if;
        end if;
      end if;*/
      -- provvedimento
      if codRes = 0 then
        msgRes := 'Lettura dati Provvedimento.';
        if migrImpegno.numero_provvedimento is null or
           migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
            
          -- DAVIDE - 23.02.016 - segnalazione impegni e gestione corretta leggi_provvedimento
            segnalare := true;
            msgMotivoScarto := 'Provvedimento non presente per impegno in stato '||migrImpegno.stato_impegno||'.';

          end if;
        else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          --h_tipo_provvedimento:=migrImpegno.tipo_provvedimento; --5 ----- DATO NON RECUPERATO DA RECUPERARE
          --h_direzione_provvedimento:=migrImpegno.direzione_provvedimento; --6 ----- DATO NON PRESENTE E NECESSARIO PER COTO

          -- dbms_output.put_line('msgRes prima di leggi_provvedimento '||msgRes);
          -- da implementare
          leggi_provvedimento(h_anno_provvedimento,
                              h_numero_provvedimento,
                              p_ente_proprietario_id,
                              codRes,
                              msgRes,
                              h_tipo_provvedimento,
                              h_oggetto_provvedimento,
                              h_stato_provvedimento,
                              h_note_provvedimento,
                              h_sac_provvedimento); -- DAVIDE - Gestione SAC Provvedimento

          /*7 ----- discrimina per ente proprietario lavora su tipo e direzione provvedimento (dati non gestiti)
          nel caso di coto il tipo_provvedimento non e in chiave*/
          if codRes = 0 then
            h_tipo_provvedimento := h_tipo_provvedimento || '||';
          end if;

          if codRes = 0 and h_stato_provvedimento is null then
            h_stato_provvedimento := 'D';
            /*h_stato_provvedimento := h_stato_impegno;
            if h_stato_provvedimento = 'N' then
              h_stato_provvedimento := 'D';
            end if;*/
          end if;
          
          -- DAVIDE - 23.02.016 - segnalazione impegni e gestione corretta leggi_provvedimento
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
                h_stato_impegno:='D';
           else
                h_stato_impegno:='N';
           end if;
         elsif h_stato_provvedimento = 'P' then
           if migrImpegno.stato_impegno = 'P' then
              h_stato_impegno := 'P';
           else
    -- DAVIDE - 23.02.016 - segnalazione impegni e gestione corretta leggi_provvedimento
             --codRes:=-1;
             --msgRes:=msgRes||'Stato impegno '||migrImpegno.stato_impegno||' per provvedimento in stato P.';
             segnalare := true;
             if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                 h_stato_impegno:='D';
             else
                 h_stato_impegno:='N';
             end if;
             msgMotivoScarto := 'Provvedimento in stato P per impegno in stato '||migrImpegno.stato_impegno;
              
           end if;
         else -- 18.09.015 Sofia
           codRes:=-1;
           msgRes:=msgRes||'Stato provvedimento '||h_stato_provvedimento||' non previsto per impegno in stato '||migrImpegno.stato_impegno||'.';  
         end if;
      end if;
      --  Definizione flag parere_finanziario, sempre impostato a true (vedi dichiarazione).

      /*9 ----- Classificatori
      -- classificatore_1 --> classificatore_11
      if p_ente_proprietario_id=ENTE_REGP_GIUNTA and codRes=0 and migrImpegno.codtitgiu is not null then
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
      if p_ente_proprietario_id=ENTE_REGP_GIUNTA and codRes=0 and
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
      */

      --- note
      if codRes = 0 then
        if migrImpegno.IMP_FONDI = 'S' then
            h_nota:='IMPEGNO FONDI';
        end if;
      end if;

      if codRes = 0 and (h_soggetto_determinato = 'N' or (h_soggetto_determinato = 'S' and h_sogg_migrato <> 0 ))
      then
        msgRes := 'Inserimento in migr_impegno.';
        insert into migr_impegno
          (impegno_id,
           tipo_movimento,
           anno_esercizio,
           anno_impegno,
           numero_impegno,
           numero_subimpegno,
           pluriennale,
           capo_riacc,
           numero_capitolo,
           numero_articolo,
           numero_ueb,
           data_emissione,
           data_scadenza,
           stato_operativo,
           importo_iniziale,
           importo_attuale,
           descrizione,
           anno_capitolo_orig,
           numero_capitolo_orig,
           numero_articolo_orig,
           numero_ueb_orig,
           anno_provvedimento,
           numero_provvedimento,
           tipo_provvedimento,
           sac_provvedimento,     -- DAVIDE - Gestione SAC Provvedimento
           oggetto_provvedimento,
           note_provvedimento,
           stato_provvedimento,
           soggetto_determinato,
           codice_soggetto,
           nota,
           tipo_impegno,
           anno_impegno_plur,
           numero_impegno_plur,
           anno_impegno_riacc,
           numero_impegno_riacc,
           opera,
           pdc_finanziario,
           missione,
           programma,
           cofog,
           transazione_ue_spesa,
           siope_spesa,
           spesa_ricorrente,
           --perimetro_sanitario_spesa,
           politiche_regionali_unitarie,
           pdc_economico_patr
           --,CLASSIFICATORE_1,CLASSIFICATORE_2,CLASSIFICATORE_3,CLASSIFICATORE_4,CLASSIFICATORE_5
           ,ente_proprietario_id
           ,parere_finanziario)
        values
          (migr_impegno_id_seq.nextval,
           TIPO_IMPEGNO_I,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_impegno,
           migrImpegno.numero_impegno,
           migrImpegno.numero_subimpegno,
           migrImpegno.pluriennale,
           migrImpegno.capo_riacc,
           migrImpegno.numero_capitolo,
           migrImpegno.numero_articolo,
           migrImpegno.numero_ueb,
           migrImpegno.data_emissione,
           migrImpegno.data_scadenza,
           h_stato_impegno,
           migrImpegno.importo_iniziale,
           migrImpegno.importo_attuale,
           migrImpegno.descrizione,
           migrImpegno.anno_capitolo_orig,
           migrImpegno.numero_capitolo_orig,
           migrImpegno.numero_articolo_orig,
           migrImpegno.numero_ueb_orig,
           h_anno_provvedimento,
           to_number(h_numero_provvedimento),
           h_tipo_provvedimento,
           h_sac_provvedimento,              -- DAVIDE - Gestione SAC Provvedimento
           h_oggetto_provvedimento,
           h_note_provvedimento,
           h_stato_provvedimento,
           h_soggetto_determinato,
           migrImpegno.codice_soggetto,
           h_nota,
           h_tipo_impegno,
           migrImpegno.anno_impegno_plur,
           migrImpegno.numero_impegno_plur,
           migrImpegno.anno_impegno_riacc,
           migrImpegno.numero_impegno_riacc,
           migrImpegno.opera,
           h_pdc_finanziario,
           migrImpegno.missione,
           migrImpegno.programma,
           h_cofog,
           migrImpegno.transazione_ue_spesa,
           migrImpegno.siope_spesa,
           migrImpegno.spesa_ricorrente,
           --h_per_sanitario,
           migrImpegno.politiche_regionali_unitarie,
           migrImpegno.pdc_economico_patr,
           --h_classificatore_1,h_classificatore_2,h_classificatore_3,h_classificatore_4,h_classificatore_5,
           p_ente_proprietario_id
           ,h_parere_finanziario);

        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
    -- DAVIDE - 23.02.016 - segnalazione impegni e gestione corretta leggi_provvedimento
         --(h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
         segnalare = true  then

        if codRes != 0 then
          msgMotivoScarto := msgRes;
        end if;

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
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
    end loop;

    msgResOut      := msgResOut || 'Elaborazione OK.Impegni inseriti=' ||
                      cImpInseriti || ' scartati=' || cImpScartati || '.';
    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;

    commit;
  exception
    when others then
      dbms_output.put_line('Impegno ' || h_impegno || ' msgRes ' || msgRes ||
                           ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      p_cod_res      := -1;
  end migrazione_impegni;

  procedure migrazione_subimpegno(p_ente_proprietario_id number,
                                  p_anno_esercizio       varchar2,
                                  p_cod_res              out number,
                                  p_imp_inseriti         out number,
                                  p_imp_scartati         out number,
                                  msgResOut              out varchar2) is
    msgRes varchar2(1500) := null;
    codRes number := 0;

    h_sogg_migrato         number := 0;
    h_stato_impegno        varchar2(1) := null;
    h_soggetto_determinato varchar2(1) := null;
    h_num                  number := 0;

    --       h_per_sanitario varchar2(1):=null;
    h_impegno varchar2(50) := null;

    h_anno_provvedimento   varchar2(4) := null;
    h_numero_provvedimento varchar2(10) := null;
    h_tipo_provvedimento   varchar2(20) := null;
    --      h_direzione_provvedimento varchar2(20):=null;

    h_stato_provvedimento   varchar2(5) := null;
    h_oggetto_provvedimento varchar2(500) := null;
    h_note_provvedimento    varchar2(500) := null;
    
    h_sac_provvedimento     varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento

    msgMotivoScarto varchar2(1500) := null;

    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;
    
    h_pdc_finanziario MIGR_ACCERTAMENTO.PDC_FINANZIARIO%TYPE;
    h_cofog varchar2(50); -- ereditato da impegno

 -- DAVIDE - 23.02.016 - segnalazione subimpegni e gestione corretta leggi_provvedimento
    segnalare    boolean := False; -- True: il record è inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record è inserito nella sola tabella migr_*
  begin

    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    msgResOut := 'Migrazione SubImpegni.';
    msgRes    := 'Lettura SubImpegni.';

    for migrImpegno in (select i.anno_esercizio,
                               i.annoimp        anno_impegno,
                               i.nimp           numero_impegno,
                               i.nsubimp        numero_subimpegno,
                               to_char(i.data_ins,'YYYY-MM-DD') data_emissione,
                               null data_scadenza,
                               i.staoper stato_impegno,
                               i.impoini importo_iniziale,
                               i.impoatt importo_attuale,
                               i.descri descrizione,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      i.annoprov) anno_provvedimento,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      to_number(i.nprov)) numero_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento, [non esiste il campo]  tipologia provvedimento restituita dalla funzione leggi_provvedimento
                               --decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento, [non esiste il campo]
                               i.codben codice_soggetto,
                               i.cup,
                               i.cig
                               --i.cod_interv_class  [non esiste il campo]
                              ,
                               null pdc_finanziario,
                               null missione,
                               null programma,
                               null cofog,
                               null transazione_ue_spesa,
                               null siope_spesa,
                               null spesa_ricorrente,
                               null politiche_regionali_unitarie,
                               null pdc_economico_patr
                          from subimp i
                         where i.anno_esercizio = p_anno_esercizio
                           and i.staoper in ('P', 'D')
                           and i.anno_esercizio || i.annoimp || i.nimp in
                               (select imp.anno_esercizio || IMP.ANNO_IMPEGNO || IMP.NUMERO_IMPEGNO
                                  from migr_impegno imp
                                 where imp.ente_proprietario_id = p_ente_proprietario_id
                                 and imp.tipo_movimento = TIPO_IMPEGNO_I)
                         order by 1, 2, 3, 4) loop
      -- inizializza variabili
      h_sogg_migrato         := 0;
      h_soggetto_determinato := 'S';
      h_stato_impegno        := null;
      h_anno_provvedimento   := null;
      h_numero_provvedimento := null;
      h_tipo_provvedimento   := null;
      --               h_direzione_provvedimento:=null;
      h_stato_provvedimento   := null;
      h_oggetto_provvedimento := null;
      h_note_provvedimento    := null;
      --               h_per_sanitario:=null;
      
      h_sac_provvedimento     := null;        -- DAVIDE - Gestione SAC Provvedimento
      
      codRes          := 0;
      msgMotivoScarto := null;
      msgRes          := null;
      h_num           := 0;
      h_pdc_finanziario := null;
      h_cofog := null;

  -- DAVIDE - 23.02.016 - segnalazione subimpegni e gestione corretta leggi_provvedimento
      segnalare := false;

      h_impegno := 'SubImpegno ' || migrImpegno.anno_impegno || '/' ||
                   migrImpegno.numero_impegno || '/' ||
                   migrImpegno.numero_subimpegno || '.';

      -- soggetto_determinato
      if migrImpegno.codice_soggetto = 0 then
        msgRes                 := 'Lettura soggetto indeterminato.';
        h_soggetto_determinato := 'N';
        codRes                 := -1;
      end if;

      -- codice
      if h_soggetto_determinato = 'S' and codRes = 0 then

        msgRes := 'Verifica soggetto migrato.';
        begin
          select nvl(count(*), 0)
            into h_sogg_migrato
            from migr_soggetto
           where codice_soggetto = migrImpegno.codice_soggetto
             and ente_proprietario_id = p_ente_proprietario_id;

          if h_sogg_migrato = 0 then
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          end if;

        exception
          when no_data_found then
            h_sogg_migrato  := 0;
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          when others then
            codRes := -1;
            msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        end;

        if codRes = 0 and h_sogg_migrato = 0 then
          begin

            /*2 ----- colonna blocco_pag non esiste su tabella FORNITORI*/
            select nvl(count(*),0) into h_num
            from fornitori
            where codben=migrImpegno.codice_soggetto and
                staoper in ('V','S'); 

            if h_num = 0 then
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            end if;
          exception
            when no_data_found then
              h_sogg_migrato  := 0;
              h_num           := 0;
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;

            when others then
              codRes := -1;
              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
          end;
        end if;
      end if;

          --  pdc_finanziario e cofog ereditati da impegno migrato
        begin
              select pdc_finanziario, cofog into h_pdc_finanziario, h_cofog
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
      
      -- stato_impegno
      h_stato_impegno := migrImpegno.stato_impegno;

      -- provvedimento
      if codRes = 0 then
        msgRes := 'Lettura dati Provvedimento.';
        if migrImpegno.numero_provvedimento is null or
           migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
            
       -- DAVIDE - 23.02.016 - segnalazione subimpegni e gestione corretta leggi_provvedimento
            h_stato_provvedimento:='D';
            segnalare := true;
            msgMotivoScarto := 'Provvedimento non presente per subimpegno in stato '||h_stato_impegno||'.';

          end if;
        else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          --h_tipo_provvedimento:=migrImpegno.tipo_provvedimento; [dato non recuperato nel cursore]
          --h_direzione_provvedimento:=migrImpegno.direzione_provvedimento; [dato non recuperato nel cursore]

          leggi_provvedimento(h_anno_provvedimento,
                              h_numero_provvedimento,
                              p_ente_proprietario_id,
                              codRes,
                              msgRes,
                              h_tipo_provvedimento,
                              h_oggetto_provvedimento,
                              h_stato_provvedimento,
                              h_note_provvedimento,
                              h_sac_provvedimento);        -- DAVIDE - Gestione SAC Provvedimento

          if codRes = 0 then
            h_tipo_provvedimento := h_tipo_provvedimento || '||';
          end if;

          if codRes = 0 and h_stato_provvedimento is null then
            h_stato_provvedimento := h_stato_impegno;
            /* 3 ----- Necessario anche per il subimpegno???
            if h_stato_provvedimento='N' then
               h_stato_provvedimento:='D';
            end if;
            */
          end if;
          
       -- DAVIDE - 23.02.016 - segnalazione subimpegni e gestione corretta leggi_provvedimento
          if h_stato_provvedimento = 'P' and h_stato_impegno = 'D' then
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

          -- da implementare
          /*leggi_provvedimento(h_anno_provvedimento,h_numero_provvedimento,
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
          end if;
          */
        end if;
      end if;

      --  perimetro_sanitario_spesa
      /* NON GESTI TO PER CO.TO
      if codRes=0 and p_ente_proprietario_id=ENTE_REGP_GIUNTA then
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
      end if;
      */

      if codRes = 0 and h_sogg_migrato <> 0 then 
        msgRes := 'Inserimento in migr_impegno.';
        insert into migr_impegno
          (impegno_id,
           tipo_movimento,
           anno_esercizio,
           anno_impegno,
           numero_impegno,
           numero_subimpegno,
           data_emissione,
           data_scadenza,
           stato_operativo,
           importo_iniziale,
           importo_attuale,
           descrizione,
           anno_provvedimento,
           numero_provvedimento,
           tipo_provvedimento,
           sac_provvedimento,         -- DAVIDE - Gestione SAC Provvedimento
           oggetto_provvedimento,
           note_provvedimento,
           stato_provvedimento,
           soggetto_determinato,
           codice_soggetto,
           cup,
           cig,
           --cod_interv_class,
           pdc_finanziario,
           missione,
           programma,
           cofog,
           transazione_ue_spesa,
           siope_spesa,
           spesa_ricorrente,
           --perimetro_sanitario_spesa,
           politiche_regionali_unitarie,
           pdc_economico_patr,
           ente_proprietario_id)
        values
          (migr_impegno_id_seq.nextval,
           TIPO_IMPEGNO_S,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_impegno,
           migrImpegno.numero_impegno,
           migrImpegno.numero_subimpegno,
           migrImpegno.data_emissione,
           migrImpegno.data_scadenza,
           h_stato_impegno,
           migrImpegno.importo_iniziale,
           migrImpegno.importo_attuale,
           migrImpegno.descrizione,
           h_anno_provvedimento,
           to_number(h_numero_provvedimento),
           h_tipo_provvedimento,
           h_sac_provvedimento,               -- DAVIDE - Gestione SAC Provvedimento
           h_oggetto_provvedimento,
           h_note_provvedimento,
           h_stato_provvedimento,
           h_soggetto_determinato,
           migrImpegno.codice_soggetto,
           migrImpegno.cup,
           migrImpegno.cig,
           --migrImpegno.cod_interv_class,
           h_pdc_finanziario,
           migrImpegno.missione,
           migrImpegno.programma,
           h_cofog,
           migrImpegno.transazione_ue_spesa,
           migrImpegno.siope_spesa,
           migrImpegno.spesa_ricorrente,
           --h_per_sanitario,
           migrImpegno.politiche_regionali_unitarie,
           migrImpegno.pdc_economico_patr,
           p_ente_proprietario_id);

        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
       -- DAVIDE - 23.02.016 - segnalazione subimpegni e gestione corretta leggi_provvedimento
         --(h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
         segnalare = true then

        if codRes != 0 then
          msgMotivoScarto := msgRes;
        end if;

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
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
    end loop;

    msgResOut := msgResOut || 'Elaborazione OK.Subimpegni inseriti=' ||
                 cImpInseriti || ' scartati=' || cImpScartati || '.';

    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;
    commit;

  exception
    when others then
      dbms_output.put_line('SubImpegno ' || h_impegno || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      p_cod_res      := -1;
  end migrazione_subimpegno;

  procedure migrazione_accertamento(p_ente_proprietario_id number,
                                    p_anno_esercizioIniziale varchar2,
                                    p_anno_esercizio       varchar2,
                                    p_cod_res              out number,
                                    p_imp_inseriti         out number,
                                    p_imp_scartati         out number,
                                    msgResOut              out varchar2) is
    msgRes varchar2(1500) := null;
    codRes number := 0;

    h_soggetto_determinato varchar2(1) := null;
    h_classe_soggetto      varchar2(250) := null;
    h_indet                number := 0;
    h_sogg_migrato         number := 0;
    h_stato_impegno        varchar2(1) := null;

    h_numero_ueb      number := 1;
    h_numero_ueb_orig number := 1;

    h_per_sanitario varchar2(1) := null;
    h_impegno       varchar2(50) := null;
    h_num           number := 0;

    h_anno_provvedimento      varchar2(4) := null;
    h_numero_provvedimento    varchar2(10) := null;
    h_tipo_provvedimento      varchar2(20) := null;
    h_direzione_provvedimento varchar2(20) := null;

    h_stato_provvedimento   varchar2(5) := null;
    h_oggetto_provvedimento varchar2(500) := null;
    h_note_provvedimento    varchar2(500) := null;
    h_nota       varchar2(250) := null;
    h_automatico varchar2(1) := 'N';
    h_classificatore_1 varchar2(250) := null;
    h_classificatore_2 varchar2(250) := null;
    h_classificatore_3 varchar2(250) := null;
    h_classificatore_4 varchar2(250) := null;
    h_classificatore_5 varchar2(250) := null;

    h_parere_finanziario integer := 1; -- non cambia rimane impostato a TRUE
    
    h_sac_provvedimento  varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento

    msgMotivoScarto varchar2(1500) := null;

    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;
    --h_capitolo   number := 0;
    
    h_pdc_finanziario MIGR_CAPITOLO_ENTRATA.PDC_FIN_QUINTO%type := null;
    
-- DAVIDE - 23.02.016 - segnalazione accertamenti e gestione corretta leggi_provvedimento    
    segnalare    boolean := False; -- True: il record è inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record è inserito nella sola tabella migr_*

  begin
    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    msgResOut := 'Migrazione accertamenti.';
    msgRes    := 'Lettura Accertamenti.';

    for migrImpegno in (select i.anno_esercizio,
                               i.annoacc anno_accertamento,
                               i.nacc numero_accertamento,
                               0 numero_subaccertamento,
                               null pluriennale,
                               'N' capo_riacc,
                               i.nro_capitolo numero_capitolo,
                               i.nro_articolo numero_articolo,
                               decode(i.tipofin, 'MB', 1, 'MU', 2) || '0' ||
                               i.Cdc || nvl(i.coel, '0000') numero_ueb,
                               to_char(i.data_ins,'YYYY-MM-DD') data_emissione,
                               null      data_scadenza,
                               i.staoper stato_accertamento,
                               i.impoini importo_iniziale,
                               i.impoatt importo_attuale,
                               i.descri descrizione,
                               i.annoacc anno_capitolo_orig,
                               i.ex_capitolo numero_capitolo_orig,
                               i.ex_articolo numero_articolo_orig,
                               decode(i.ex_tipofin, 'MB', 1, 'MU', 2) || '0' ||i.ex_Cdc || nvl(i.ex_coel, '0000') numero_ueb_orig,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      i.annoprov) anno_provvedimento,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      to_number(i.nprov)) numero_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento, [CAMPO NON PRESENTE]
                               --decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,[CAMPO NON PRESENTE]
                               i.codben    codice_soggetto,
                               null        nota,
                               null        anno_accertamento_plur,
                               null        numero_accertamento_plur,
                               i.annoimp_orig anno_accertamento_riacc, -- 20.07.2015: prima lasciato a NULL
                               i.nimp_orig    numero_accertamento_riacc,-- 20.07.2015: prima lasciato a NULL
                               null        opera,
                               null        pdc_finanziario,
                               null        transazione_ue_entrata,
                               null        siope_entrata,
                               null        entrata_ricorrente,
                               null        pdc_economico_patr,
                               i.codtitgiu
                          from accertamenti i
                         where i.anno_esercizio = p_anno_esercizio
                           and i.staoper in ('P', 'D')
                         order by 1, 2, 3) loop
      -- inizializza variabili
      h_classe_soggetto         := null;
      h_indet                   := 0;
      h_soggetto_determinato    := 'S';
      h_sogg_migrato            := 0;
      h_stato_impegno           := null;
      h_anno_provvedimento      := null;
      h_numero_provvedimento    := null;
      h_tipo_provvedimento      := null;
      h_direzione_provvedimento := null;
      h_stato_provvedimento     := null;
      h_oggetto_provvedimento   := null;
      h_note_provvedimento      := null;
                
      h_sac_provvedimento       := null; -- DAVIDE - Gestione SAC Provvedimento

      h_per_sanitario           := null;
      h_classificatore_1        := null;
      h_classificatore_2        := null;
      h_classificatore_3        := null;
      h_nota                    := null;
      h_automatico              := 'N';
      codRes                    := 0;
      msgMotivoScarto           := null;
      msgRes                    := null;
      h_num                     := 0;
      --h_capitolo                := 0;
      h_pdc_finanziario         := null;
      
   -- DAVIDE - 23.02.016 - segnalazione accertamenti e gestione corretta leggi_provvedimento      
      segnalare                 := false;
      
      h_impegno := 'Accertamento ' || migrImpegno.anno_accertamento || '/' ||
                   migrImpegno.numero_accertamento || '.';
      -- verifica capitolo migrato
      begin
        msgRes := 'Lettura capitolo migrato.';
        select pdc_fin_quinto into h_pdc_finanziario
          from migr_capitolo_entrata m
         where m.ente_proprietario_id = p_ente_proprietario_id
           and m.anno_esercizio = p_anno_esercizioIniziale
           and m.numero_capitolo = migrImpegno.numero_capitolo
           and m.numero_articolo =migrImpegno.numero_articolo
           and m.numero_ueb = migrImpegno.numero_ueb
           and tipo_capitolo = 'CAP-EG';
      exception
        when no_data_found then
          codRes := -1;
          msgRes := 'Capitolo non migrato.';
        when others then
          codRes := -1;
          msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';

/* Gestita l'eccezione no_data_found
          if h_capitolo = 0 then
            codRes := -1;
            msgRes := 'Capitolo non migrato.';
          end if;*/
      end;
      -- soggetto_determinato
      if codRes = 0 then
        if migrImpegno.codice_soggetto != 0 then
          h_soggetto_determinato := 'S';
        else
          msgRes                 := 'Lettura soggetto determinato S-N.';
          h_soggetto_determinato := 'N';
        end if;
      end if;
      /*
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
             --h_classe_soggetto:=CLASSE_MIGRAZIONE;
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
      */

      -- codice
      if h_soggetto_determinato = 'S' and codRes = 0 then

        msgRes := 'Verifica soggetto migrato.';
        begin
          select nvl(count(*), 0)
            into h_sogg_migrato
            from migr_soggetto
           where codice_soggetto = migrImpegno.codice_soggetto
             and ente_proprietario_id = p_ente_proprietario_id;

          if h_sogg_migrato = 0 then
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          end if;

        exception
          when no_data_found then
            h_sogg_migrato  := 0;
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          when others then
            codRes := -1;
            msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        end;

        if codRes = 0 and h_sogg_migrato = 0 then
          begin
            select nvl(count(*),0) into h_num
            from fornitori
            where codben=migrImpegno.codice_soggetto and
                  staoper in ('V','S'); 
                
            if h_num = 0 then
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            end if;
          exception
            when no_data_found then
              h_sogg_migrato  := 0;
              h_num           := 0;
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            when others then
              codRes := -1;
              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
          end;
        end if;
      end if;

      --  stato_impegno da calcolare
      /*
      if codRes = 0 then
        msgRes := 'Calcolo stato accertamento.';
        if migrImpegno.stato_accertamento = 'P' then
          h_stato_impegno := STATO_IMPEGNO_P;
        else
          if h_soggetto_determinato = 'S' then
            --or h_classe_soggetto is not null then
            h_stato_impegno := STATO_IMPEGNO_D;
          else
            h_stato_impegno := STATO_IMPEGNO_N;
          end if;
        end if;
      end if;*/

      -- provvedimento
      if codRes = 0 then
        msgRes := 'Lettura dati Provvedimento.';
        if migrImpegno.numero_provvedimento is null or
           migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
            
        -- DAVIDE - 23.02.016 - segnalazione accertamenti e gestione corretta leggi_provvedimento    
            h_stato_provvedimento:='D';
            segnalare := true;
            msgMotivoScarto := 'Provvedimento non presente per accertamento in stato '||migrImpegno.stato_accertamento||'.';

          end if;
        else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          --h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
          --h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

          -- dbms_output.put_line('msgRes prima di leggi_provvedimento '||msgRes);
          -- da implementare
          leggi_provvedimento(h_anno_provvedimento,
                              h_numero_provvedimento,
                              p_ente_proprietario_id,
                              codRes,
                              msgRes,
                              h_tipo_provvedimento,
                              h_oggetto_provvedimento,
                              h_stato_provvedimento,
                              h_note_provvedimento,
                              h_sac_provvedimento);   -- DAVIDE - Gestione SAC Provvedimento

          if codRes = 0 then
            h_tipo_provvedimento := h_tipo_provvedimento || '||';
          end if;
          
       -- DAVIDE - 23.02.016 - segnalazione accertamenti e gestione corretta leggi_provvedimento          
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

        if codRes = 0 and h_stato_provvedimento is null then
          h_stato_provvedimento := 'D';
          /*h_stato_provvedimento := h_stato_impegno;
          if h_stato_provvedimento = 'N' then
            h_stato_provvedimento := 'D';
          end if;*/
        end if;
      end if;
      --  stato_impegno da calcolare
        if codRes=0 then
           msgRes:='Definizione stato accertamento.';
           if h_stato_provvedimento = 'D' then
             if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                  h_stato_impegno:='D';
             else
                  h_stato_impegno:='N';
             end if;
           elsif h_stato_provvedimento = 'P' then
             if migrImpegno.stato_accertamento = 'P' then
                h_stato_impegno := 'P';
             else

               --codRes:=-1;
               --msgRes:=msgRes||'Stato accertamento '||migrImpegno.stato_accertamento||' per provvedimento in stato P.';
               segnalare := true;
               msgMotivoScarto := 'Provvedimento in P per accertamento in stato'||migrImpegno.stato_accertamento;
               if h_soggetto_determinato='S' or h_classe_soggetto is not null then
                   h_stato_impegno:='D';
               else
                   h_stato_impegno:='N';
               end if;
             end if;
           else
             -- 23.06.2015 Modifica provvisoria, da gestire i casi
             -- Non riesco a determinare lo stato dell'accertamento 
             msgRes:=msgRes||'Stato accertamento '||migrImpegno.stato_accertamento||' per provvedimento in stato '||h_stato_provvedimento;
             codRes:=-1;
           end if;
        end if;
        --  Definizione flag parere_finanziario
        -- sempre impostato a true (vedi dichiarazione variabile)

      -- codtitgiu
      if codRes = 0 and migrImpegno.codtitgiu is not null then
        /*if p_ente_proprietario_id=ENTE_REGP_GIUNTA then
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
        elsif p_ente_proprietario_id=ENTE_COTO then*/
        if migrImpegno.codtitgiu = ACC_AUTOMATICO then
          h_automatico := 'S';
        end if;
        --end if;
      end if;

      --- note
      h_nota := migrImpegno.nota;

      if codRes = 0
        and (h_soggetto_determinato = 'N' or (h_soggetto_determinato = 'S' and h_sogg_migrato <> 0))
      then
        msgRes := 'Inserimento in migr_accertamento.';
        insert into migr_accertamento
          (accertamento_id,
           tipo_movimento,
           anno_esercizio,
           anno_accertamento,
           numero_accertamento,
           numero_subaccertamento,
           pluriennale,
           capo_riacc,
           numero_capitolo,
           numero_articolo,
           numero_ueb,
           data_emissione,
           data_scadenza,
           stato_operativo,
           importo_iniziale,
           importo_attuale,
           descrizione,
           anno_capitolo_orig,
           numero_capitolo_orig,
           numero_articolo_orig,
           numero_ueb_orig,
           anno_provvedimento,
           numero_provvedimento,
           tipo_provvedimento,
           sac_provvedimento,       -- DAVIDE - Gestione SAC Provvedimento
           oggetto_provvedimento,
           note_provvedimento,
           stato_provvedimento,
           soggetto_determinato,
           codice_soggetto,
           --classe_soggetto,
           nota,
           automatico,
           anno_accertamento_plur,
           numero_accertamento_plur,
           anno_accertamento_riacc,
           numero_accertamento_riacc,
           opera,
           pdc_finanziario,
           transazione_ue_entrata,
           siope_entrata,
           entrata_ricorrente,
           --perimetro_sanitario_entrata,
           pdc_economico_patr,
           --CLASSIFICATORE_1,CLASSIFICATORE_2,CLASSIFICATORE_3,CLASSIFICATORE_4,CLASSIFICATORE_5,
           ente_proprietario_id
           ,parere_finanziario)
        values
          (migr_accertamento_id_seq.nextval,
           TIPO_IMPEGNO_A,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_accertamento,
           migrImpegno.numero_accertamento,
           migrImpegno.numero_subaccertamento,
           migrImpegno.pluriennale,
           migrImpegno.capo_riacc,
           migrImpegno.numero_capitolo,
           migrImpegno.numero_articolo,
           migrImpegno.numero_ueb,
           migrImpegno.data_emissione,
           migrImpegno.data_scadenza,
           h_stato_impegno,
           migrImpegno.importo_iniziale,
           migrImpegno.importo_attuale,
           migrImpegno.descrizione,
           migrImpegno.anno_capitolo_orig,
           migrImpegno.numero_capitolo_orig,
           migrImpegno.numero_articolo_orig,
           migrImpegno.numero_ueb_orig,
           h_anno_provvedimento,
           to_number(h_numero_provvedimento),
           h_tipo_provvedimento,
           h_sac_provvedimento,        -- DAVIDE - Gestione SAC Provvedimento
           h_oggetto_provvedimento,
           h_note_provvedimento,
           h_stato_provvedimento,
           h_soggetto_determinato,
           migrImpegno.codice_soggetto,
           --h_classe_soggetto,
           h_nota,
           h_automatico,
           migrImpegno.anno_accertamento_plur,
           migrImpegno.numero_accertamento_plur,
           migrImpegno.anno_accertamento_riacc,
           migrImpegno.numero_accertamento_riacc,
           migrImpegno.opera,
           h_pdc_finanziario,
           migrImpegno.transazione_ue_entrata,
           migrImpegno.siope_entrata,
           migrImpegno.entrata_ricorrente,
           --h_per_sanitario,
           migrImpegno.pdc_economico_patr,
           --h_classificatore_1,h_classificatore_2,h_classificatore_3,h_classificatore_4,h_classificatore_5,
           p_ente_proprietario_id
           ,h_parere_finanziario);

        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
      
      -- DAVIDE - 23.02.016 - segnalazione accertamenti e gestione corretta leggi_provvedimento          
        -- (h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
        segnalare = true then
        if codRes != 0 then
          msgMotivoScarto := msgRes;
        end if;

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
           migrImpegno.anno_accertamento,
           migrImpegno.numero_accertamento,
           migrImpegno.numero_subaccertamento,
           msgMotivoScarto,
           p_ente_proprietario_id);
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
    end loop;

    msgResOut := msgResOut || 'Elaborazione OK.Accertamenti inseriti=' ||
                 cImpInseriti || ' scartati=' || cImpScartati || '.';

    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;
    commit;

  exception
    when others then
      dbms_output.put_line('Accertamento ' || h_impegno || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      p_cod_res      := -1;

  end migrazione_accertamento;

  procedure migrazione_subaccertamento(p_ente_proprietario_id number,
                                       p_anno_esercizio       varchar2,
                                       p_cod_res              out number,
                                       p_imp_inseriti         out number,
                                       p_imp_scartati         out number,
                                       msgResOut              out varchar2) is
    msgRes varchar2(1500) := null;
    codRes number := 0;

    h_sogg_migrato         number := 0;
    h_stato_impegno        varchar2(1) := null;
    h_soggetto_determinato varchar2(1) := null;
    h_num                  number := 0;

    h_impegno varchar2(50) := null;

    h_anno_provvedimento      varchar2(4) := null;
    h_numero_provvedimento    varchar2(10) := null;
    h_tipo_provvedimento      varchar2(20) := null;
    h_direzione_provvedimento varchar2(20) := null;

    h_stato_provvedimento   varchar2(5) := null;
    h_oggetto_provvedimento varchar2(500) := null;
    h_note_provvedimento    varchar2(500) := null;

    msgMotivoScarto varchar2(1500) := null;
    
    h_sac_provvedimento  varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento

    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;
    
    h_pdc_finanziario MIGR_ACCERTAMENTO.pdc_finanziario%type := null;
    
    -- DAVIDE - 23.02.016 - segnalazione subaccertamenti e gestione corretta leggi_provvedimento          
    segnalare    boolean := False; -- True: il record è inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record è inserito nella sola tabella migr_*

  begin

    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    msgResOut := 'Migrazione SubAccertamenti.';
    msgRes    := 'Lettura SubAccertamenti.';

    for migrImpegno in (select i.anno_esercizio,
                               i.annoacc anno_accertamento,
                               i.nacc numero_accertamento,
                               i.nsubacc numero_subaccertamento,
                               to_char(i.data_ins,'YYYY-MM-DD')  data_emissione,
                               null data_scadenza,
                               i.staoper stato_impegno,
                               i.impoini importo_iniziale,
                               i.impoatt importo_attuale,
                               i.descri descrizione,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      i.annoprov) anno_provvedimento,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      to_number(i.nprov)) numero_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                               i.codben codice_soggetto,
                               null     pdc_finanziario,
                               null     transazione_ue_entrata,
                               null     siope_entrata,
                               null     entrata_ricorrente,
                               null     pdc_economico_patr
                          from subacc i
                         where i.anno_esercizio = p_anno_esercizio
                           and i.staoper in ('P', 'D')
                           and i.anno_esercizio || i.annoacc || i.nacc in
                               (select a.anno_esercizio || a.anno_accertamento || A.NUMERO_ACCERTAMENTO
                                  from migr_accertamento a
                                 where a.ente_proprietario_id = p_ente_proprietario_id
                                 and A.TIPO_MOVIMENTO=TIPO_IMPEGNO_A )
                         order by 1, 2, 3, 4) loop
      -- inizializza variabili
      h_sogg_migrato            := 0;
      h_soggetto_determinato    := 'S';
      h_stato_impegno           := null;
      h_anno_provvedimento      := null;
      h_numero_provvedimento    := null;
      h_tipo_provvedimento      := null;
      h_direzione_provvedimento := null;
      h_stato_provvedimento     := null;
      h_oggetto_provvedimento   := null;
      h_note_provvedimento      := null;
          
      h_sac_provvedimento       := null; -- DAVIDE - Gestione SAC Provvedimento

      --h_per_sanitario:=null;
      codRes           := 0;
      msgMotivoScarto  := null;
      msgRes           := null;
      h_num            := 0;
      h_pdc_finanziario:= null;
      
    -- DAVIDE - 23.02.016 - segnalazione subaccertamenti e gestione corretta leggi_provvedimento    
      segnalare := false;

      h_impegno := 'SubAccertamento ' || migrImpegno.anno_accertamento || '/' ||
                   migrImpegno.numero_accertamento || '/' ||
                   migrImpegno.numero_subaccertamento || '.';

      -- dataemis letto da Accertamento
      /*1-----
      if p_ente_proprietario_id!=ENTE_COTO then
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
      end if;
      */

      -- soggetto_determinato
      if migrImpegno.codice_soggetto = 0 then
        msgRes                 := 'Lettura soggetto indeterminato.';
        h_soggetto_determinato := 'N';
        codRes                 := -1;
      end if;

      -- codice
      if h_soggetto_determinato = 'S' and codRes = 0 then

        msgRes := 'Verifica soggetto migrato.';
        begin
          select nvl(count(*), 0)
            into h_sogg_migrato
            from migr_soggetto
           where codice_soggetto = migrImpegno.codice_soggetto
             and ente_proprietario_id = p_ente_proprietario_id;

          if h_sogg_migrato = 0 then
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          end if;

        exception
          when no_data_found then
            h_sogg_migrato  := 0;
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          when others then
            codRes := -1;
            msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        end;

        if codRes = 0 and h_sogg_migrato = 0 then
          begin
            select nvl(count(*),0) into h_num
            from fornitori
            where codben=migrImpegno.codice_soggetto and
                staoper in ('V','S'); 
            
            if h_num = 0 then
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            end if;
          exception
            when no_data_found then
              h_sogg_migrato  := 0;
              h_num           := 0;
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;

            when others then
              codRes := -1;
              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
          end;
        end if;
      end if;

    --  pdc_finanziario ereditato da accertamento migrato
        begin
              select pdc_finanziario into h_pdc_finanziario
              from migr_accertamento
              where tipo_movimento = TIPO_IMPEGNO_A
              and anno_esercizio = migrImpegno.anno_esercizio
              and anno_accertamento = migrImpegno.anno_accertamento
              and numero_accertamento = migrImpegno.numero_accertamento
              and ente_proprietario_id = p_ente_proprietario_id;
             exception
                when no_data_found then
                  msgRes          := msgRes || 'Accertamento padre non trovato in migr_accertamento.';
                  msgMotivoScarto := msgRes;
                when too_many_rows then
                  msgRes          := msgRes || 'Ricerca accertamento padre.Too many rows';
                  msgMotivoScarto := msgRes;
                when others then
                  codRes := -1;
                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
              end;

      -- stato_impegno
      h_stato_impegno := migrImpegno.stato_impegno;

      -- provvedimento
      if codRes = 0 then
        msgRes := 'Lettura dati Provvedimento.';
        if migrImpegno.numero_provvedimento is null or
           migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
            
         -- DAVIDE - 23.02.016 - segnalazione subaccertamenti e gestione corretta leggi_provvedimento            
            h_stato_provvedimento := 'D';
            segnalare := true;
            msgMotivoScarto := 'Provvedimento non presente per accertamento in stato '||h_stato_impegno||'.';

          end if;
        else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          --h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
          --h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

          -- dbms_output.put_line('msgRes prima di leggi_provvedimento '||msgRes);
          -- da implementare
          leggi_provvedimento(h_anno_provvedimento,
                              h_numero_provvedimento,
                              p_ente_proprietario_id,
                              codRes,
                              msgRes,
                              h_tipo_provvedimento,
                              h_oggetto_provvedimento,
                              h_stato_provvedimento,
                              h_note_provvedimento,
                              h_sac_provvedimento);      -- DAVIDE - Gestione SAC Provvedimento
          if codRes = 0 then
            h_tipo_provvedimento := h_tipo_provvedimento || '||';
          end if;
          
    -- DAVIDE - 23.02.016 - segnalazione subaccertamenti e gestione corretta leggi_provvedimento
          if h_stato_provvedimento = 'P' and h_stato_impegno = 'D' then
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

        if codRes = 0 and h_stato_provvedimento is null then
          h_stato_provvedimento := h_stato_impegno;
        end if;
      end if;

      if codRes = 0 and h_sogg_migrato <> 0 then
        msgRes := 'Inserimento in migr_accertamento.';
        insert into migr_accertamento
          (accertamento_id,
           tipo_movimento,
           anno_esercizio,
           anno_accertamento,
           numero_accertamento,
           numero_subaccertamento,
           data_emissione,
           data_scadenza,
           stato_operativo,
           importo_iniziale,
           importo_attuale,
           descrizione,
           anno_provvedimento,
           numero_provvedimento,
           tipo_provvedimento,
           sac_provvedimento,      -- DAVIDE - Gestione SAC Provvedimento
           oggetto_provvedimento,
           note_provvedimento,
           stato_provvedimento,
           soggetto_determinato,
           codice_soggetto,
           pdc_finanziario,
           transazione_ue_entrata,
           siope_entrata,
           entrata_ricorrente,
           --perimetro_sanitario_entrata,
           pdc_economico_patr,
           ente_proprietario_id)
        values
          (migr_accertamento_id_seq.nextval,
           TIPO_IMPEGNO_S,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_accertamento,
           migrImpegno.numero_accertamento,
           migrImpegno.numero_subaccertamento,
           migrImpegno.data_emissione,
           migrImpegno.data_scadenza,
           h_stato_impegno,
           migrImpegno.importo_iniziale,
           migrImpegno.importo_attuale,
           migrImpegno.descrizione,
           h_anno_provvedimento,
           to_number(h_numero_provvedimento),
           h_tipo_provvedimento,
           h_sac_provvedimento,      -- DAVIDE - Gestione SAC Provvedimento
           h_oggetto_provvedimento,
           h_note_provvedimento,
           h_stato_provvedimento,
           h_soggetto_determinato,
           migrImpegno.codice_soggetto,
           h_pdc_finanziario,
           migrImpegno.transazione_ue_entrata,
           migrImpegno.siope_entrata,
           migrImpegno.entrata_ricorrente,
           --h_per_sanitario,
           migrImpegno.pdc_economico_patr,
           p_ente_proprietario_id);

        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
    -- DAVIDE - 23.02.016 - segnalazione subaccertamenti e gestione corretta leggi_provvedimento          
         --(h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
         segnalare = true then
         
        if codRes != 0 then
          msgMotivoScarto := msgRes;
        end if;

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
           migrImpegno.anno_accertamento,
           migrImpegno.numero_accertamento,
           migrImpegno.numero_subaccertamento,
           msgMotivoScarto,
           p_ente_proprietario_id);
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
    end loop;

    msgResOut := msgResOut || 'Elaborazione OK.SubAccertamenti inseriti=' ||
                 cImpInseriti || ' scartati=' || cImpScartati || '.';

    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;
    commit;

  exception
    when others then
      dbms_output.put_line('SubAccertamenti ' || h_impegno || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      p_cod_res      := -1;

  end migrazione_subaccertamento;

  -- DAVIDE - Gestione SAC provvedimento 
  procedure leggi_provvedimento(p_anno_provvedimento    varchar2,
                                p_numero_provvedimento  varchar2,
                                p_ente_proprietario_id  number,
                                p_codRes                out number,
                                p_msgRes                out varchar2,
                                p_tipo_provvedimento    out varchar2,
                                p_oggetto_provvedimento out varchar2,
                                p_stato_provvedimento   out varchar2,
                                p_note_provvedimento    out varchar2,
                                p_sac_provvedimento     out varchar2) is

    h_stato_provvedimento varchar2(5) := null;
    h_oggetto             varchar2(500) := null;
    h_tipo_provvedimento  varchar(4) := null;
    h_sac_provvedimento   varchar2(20) := null;
    
    codRes number := 0;
    msgRes varchar2(1500) := null;

  begin

    p_oggetto_provvedimento := null;
    p_stato_provvedimento   := null;
    p_note_provvedimento    := null;
    p_sac_provvedimento     := null;


    p_codRes := 0;
    p_msgRes := 'Lettura dati provvedimento ' || p_anno_provvedimento || '/' ||
                p_numero_provvedimento || '. ';
    begin
    
     if (to_number(p_numero_provvedimento)>50000 and to_number(p_numero_provvedimento)<55000 ) then
          select oggetto, staoper, 'MIN' codprov -- tipo_provvedimento da definire con GF
                into h_oggetto, h_stato_provvedimento, h_tipo_provvedimento
                from MOVIMENTI_INTERNI
               where nprov = p_numero_provvedimento
                 and annoprov = p_anno_provvedimento
                 and cod_azienda = 1;--p_ente_proprietario_id;
     else
        select oggetto, staoper, codprov, cdc
            into h_oggetto, h_stato_provvedimento, h_tipo_provvedimento, h_sac_provvedimento
        from bilancio.DELIBERE
       where nprov =  lpad(p_numero_provvedimento,5,'0')
         and annoprov = p_anno_provvedimento
         and cod_azienda = 1;--p_ente_proprietario_id;
     end if;
    exception
      when no_data_found then
-- DAVIDE - 22.02.016 - aggiunta gestione scarto per provvedimento non trovato - come REGP
         --codRes := -1;
        codRes := -2;
        msgRes := 'Provvedimento non trovato';
    when others then
        codRes := -1;
        msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
    end;

    /*1 -----
    if p_ente_proprietario_id= ENTE_REGP_GIUNTA then
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
            msgRes:='Ricerca dati delibera.';
            select d.nro_provv,d.nro_def,d.oggetto,d.esito_giunta
                   into h_nro_prov,h_nro_def,h_oggetto,h_esito_giunta
            from delibere d
            where d.anno=p_anno_provvedimento and
                  ( ( h_numero_provvedimento>=50000 and d.nro_provv=h_numero_provvedimento) or
                    ( h_numero_provvedimento<50000 and  d.nro_def=h_numero_provvedimento)
                   );

             if h_numero_provvedimento>=50000 and  h_nro_prov=h_nro_def then
                h_stato_provvedimento:='P';
             end if;

             if (h_numero_provvedimento>=50000 and  h_nro_prov!=h_nro_def) or h_numero_provvedimento<50000 then
                if h_esito_giunta='AP' then
                   h_stato_provvedimento:='D';
                else
                   h_stato_provvedimento:='A';
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
      end if;
    end if;
    */

    /*2 -----
    if codRes=0 and
       ( p_ente_proprietario_id!= ENTE_REGP_GIUNTA or
         (p_tipo_provvedimento not in ( PROVV_DETERMINA_REGP,PROVV_DELIBERA_REGP)  )
       )   then
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
      */
    -- da vedere ancora numero repertorio per consiglio !

    -- per gli enti diversi da RegPGiunta verifico attivazione integrazione rispetto procedura Atti

    /*3 -----
    if codRes=0 and p_ente_proprietario_id!= ENTE_REGP_GIUNTA then
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
    end if;
    */

    if codRes = 0 then
      if h_tipo_provvedimento is not null then
        p_tipo_provvedimento := h_tipo_provvedimento;
      else
        p_tipo_provvedimento := '         ';
      end if;
      if h_oggetto is not null then
        p_oggetto_provvedimento := h_oggetto;
      else
        p_oggetto_provvedimento := '         ';
      end if;
      if h_stato_provvedimento is not null then
        p_stato_provvedimento := h_stato_provvedimento;
      end if;
      if h_sac_provvedimento is not null then
        p_sac_provvedimento := h_sac_provvedimento;
      end if;
    end if;

    p_codRes := codRes;
    if codRes = 0 then
      p_msgRes := p_msgRes || 'Lettura OK.';
    else
      p_msgRes := p_msgRes || msgRes;
    end if;
  exception
    when others then
      p_msgRes := p_msgRes || msgRes || 'Errore ' || SQLCODE || '-' ||
                  SUBSTR(SQLERRM, 1, 100) || '.';
      p_codRes := -1;
  end leggi_provvedimento;
-- DAVIDE - Fine

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

  procedure migrazione_impegniPlur(p_ente_proprietario_id number,
                               p_anno_esercizio       varchar2,
                               p_cod_res              out number,
                               p_imp_inseriti         out number,
                               p_imp_scartati         out number,
                               msgResOut              out varchar2)
  is
    msgRes varchar2(1500) := null;
    msgMotivoScarto varchar2(1500) := null;
    codRes number := 0;
    cImpInseriti number := 0;
    cImpScartati number := 0;    
    numImpegno number := 0;    
    
    h_impegno varchar2(50) := null;
    h_soggetto_determinato varchar2(1) := null;
    h_sogg_migrato number := 0;
    h_stato_impegno varchar2(1) := null;
    h_pdc_finanziario MIGR_CAPITOLO_USCITA.PDC_FIN_QUINTO%type := null;
    h_cofog  varchar2(50) := null;
    h_num number := 0;
    h_tipo_impegno varchar2(5) := null;
    h_anno_provvedimento   varchar2(4) := null;
    h_numero_provvedimento varchar2(10) := null;
    h_tipo_provvedimento   varchar2(20) := null;
    h_stato_provvedimento   varchar2(5) := null;
    h_oggetto_provvedimento varchar2(500) := null;
    h_note_provvedimento    varchar2(500) := null;
    
    h_sac_provvedimento  varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento
 -- DAVIDE - 23.02.016 - segnalazione impegni pluriennali e gestione corretta leggi_provvedimento
    segnalare    boolean := False; -- True: il record è inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record è inserito nella sola tabella migr_*

  begin
  
    msgRes    := 'Lettura Impegni pluriennali.';
    msgResOut := 'Migrazione impegni pluriennali.';
    
  
    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    for migrImpegno in (select i.anno_esercizio,
                               i.annoimp anno_impegno,
                               i.nimp numero_impegno,
                               0 numero_subimpegno,
                               null pluriennale,
                               'N' capo_riacc,
                               i.nro_capitolo numero_capitolo,
                               i.nro_articolo numero_articolo,
                               decode(i.tipofin, 'MB', 1, 'MU', 2) || '0' ||
                               i.Cdc || nvl(i.coel, '0000') numero_ueb
                               ,to_char(i.data_ins,'YYYY-MM-DD') data_emissione,
                               null      data_scadenza,
                               i.staoper stato_impegno,
                               i.impoini importo_iniziale,
                               i.impoatt importo_attuale,
                               i.descri descrizione, 
                                i.annoimp anno_capitolo_orig
                               ,decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      i.annoprov) anno_provvedimento,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      to_number(i.nprov)) numero_provvedimento,
                               i.codben codice_soggetto,
                               TIPO_IMPEGNO tipo_impegno,
                               null         anno_impegno_plur,
                               null         numero_impegno_plur,
                               null         anno_impegno_riacc,
                               null         numero_impegno_riacc,
                               null         opera
                              ,
                               null pdc_finanziario,
                               null missione,
                               null programma,
                               null cofog,
                               null transazione_ue_spesa,
                               null siope_spesa,
                               null spesa_ricorrente,
                               null politiche_regionali_unitarie,
                               null pdc_economico_patr
                          from impegni_plur i
                         where i.anno_esercizio >= p_anno_esercizio+3
                           and i.staoper <> 'A'
                           and I.IMP_FONDI = 'N'
                         order by 1, 2, 3 ) loop
                        
        -- inizializzazione varibili
        msgRes := null;
        msgMotivoScarto    := null;
        codRes := 0;
        h_soggetto_determinato := 'S';
        h_sogg_migrato := 0;
        h_stato_impegno := null;
        h_pdc_finanziario :=null;
        h_cofog :=null;
        h_num := 0;
        h_tipo_impegno:=null;
        h_anno_provvedimento   := null;
        h_numero_provvedimento := null;
        h_tipo_provvedimento   := null;
        h_stato_provvedimento := null;
        h_oggetto_provvedimento := null;
        h_note_provvedimento := null;
    
        h_sac_provvedimento  := null; -- DAVIDE - Gestione SAC Provvedimento
        
     -- DAVIDE - 23.02.016 - segnalazione impegni pluriennali e gestione corretta leggi_provvedimento
        segnalare            := false;

        h_impegno := 'Impegno plur' || migrImpegno.anno_impegno || '/' || migrImpegno.numero_impegno || '/' || migrImpegno.numero_ueb || '.';
          
          -- verifica capitolo migrato
          -- se esite il campo valorizzato PDC_FIN_QUINTO passa al campo  migr_impegno.PDC_FINANZIARIO
        BEGIN
           msgRes := 'Lettura capitolo migrato.';

           SELECT PDC_FIN_QUINTO, COFOG
             INTO h_pdc_finanziario, h_cofog
             FROM migr_capitolo_uscita m
            WHERE m.ente_proprietario_id=p_ente_proprietario_id
                  and m.anno_esercizio = p_anno_esercizio
                  AND m.numero_capitolo = migrImpegno.numero_capitolo
                  and m.numero_articolo =migrImpegno.numero_articolo
                  AND m.numero_ueb = migrImpegno.numero_ueb
                  AND m.tipo_capitolo = 'CAP-UG';
        EXCEPTION
           WHEN NO_DATA_FOUND
           THEN
              codRes := -1;
              msgRes := 'Capitolo non migrato.';
           WHEN OTHERS
           THEN
              codRes := -1;
              msgRes := msgRes || SQLCODE || '-' || SUBSTR (SQLERRM, 1, 100) || '.';

        END;
        
          if codRes = 0 then
            -- soggetto_determinato
            if migrImpegno.codice_soggetto != 0 then
              h_soggetto_determinato := 'S';
            else
              msgRes := 'Lettura soggetto determinato S-N.';
              h_soggetto_determinato := 'N';
            end if;
          end if;
          if h_soggetto_determinato = 'S' and codRes = 0 then
            msgRes := 'Verifica soggetto migrato.';
            begin
              select nvl(count(*), 0)
                into h_sogg_migrato
                from migr_soggetto
               where codice_soggetto = migrImpegno.codice_soggetto
                 and ente_proprietario_id = p_ente_proprietario_id;

              if h_sogg_migrato = 0 then
                msgRes          := 'Soggetto determinato non migrato.';
                msgMotivoScarto := msgRes;
              end if;

            exception
              when no_data_found then
                h_sogg_migrato  := 0;
                msgRes          := 'Soggetto determinato non migrato.';
                msgMotivoScarto := msgRes;
              when others then
                codRes := -1;
                msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            end;

            if codRes = 0 and h_sogg_migrato = 0 then
              begin

                   select nvl(count(*),0) into h_num
                   from fornitori
                   where codben=migrImpegno.codice_soggetto and
                         staoper in ('V','S');
                         
                if h_num = 0 then
                  msgRes          := msgRes || 'Soggetto non valido.';
                  msgMotivoScarto := msgRes;
                end if;
              exception
                when no_data_found then
                  h_sogg_migrato  := 0;
                  h_num           := 0;
                  msgRes          := msgRes || 'Soggetto non valido.';
                  msgMotivoScarto := msgRes;
                when others then
                  codRes := -1;
                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
              end;
            end if;
          end if;
      
      -- definizione tipo_impegno
      -- verificare se serve , facendo una distinct sul tipo_impegno l'unico valore risultante è S
           if (upper(migrImpegno.tipo_impegno) = 'C' 
                or upper(migrImpegno.tipo_impegno) = 'S'
                or upper(migrImpegno.tipo_impegno) = 'D') then 
                h_tipo_impegno:='SVI';
           elsif (upper(migrImpegno.tipo_impegno) = 'M'
                or upper(migrImpegno.tipo_impegno) = 'Y')then 
                h_tipo_impegno:='MUT';
           else
                h_tipo_impegno:=null;
           end if;      

      --  stato_impegno da calcolare
          if codRes = 0 then
            msgRes := 'Calcolo stato impegno.';
            if migrImpegno.stato_impegno = 'P' then
              h_stato_impegno := STATO_IMPEGNO_P;
            else
              if h_soggetto_determinato = 'S' then
                h_stato_impegno := STATO_IMPEGNO_D;
              else
                -- Impegni definitivi senza attribuzione di un soggetto sono migrati in stato N 'Definitivi non liquidabili'
                h_stato_impegno := STATO_IMPEGNO_N;
              end if;
            end if;
          end if;
          
      -- provvedimento
      if codRes = 0 then
        msgRes := 'Lettura dati Provvedimento.';
        if migrImpegno.numero_provvedimento is null or
           migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
            
          -- DAVIDE - 23.02.016 - segnalazione impegni plurinennali e gestione corretta leggi_provvedimento
            segnalare := true;
            msgMotivoScarto := 'Provvedimento non presente per impegno pluriennale in stato '||migrImpegno.stato_impegno||'.';

          end if;
        else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          --h_tipo_provvedimento:=migrImpegno.tipo_provvedimento; --5 ----- DATO NON RECUPERATO DA RECUPERARE
          --h_direzione_provvedimento:=migrImpegno.direzione_provvedimento; --6 ----- DATO NON PRESENTE E NECESSARIO PER COTO

          -- da implementare
          leggi_provvedimento(h_anno_provvedimento,
                              h_numero_provvedimento,
                              p_ente_proprietario_id,
                              codRes,
                              msgRes,
                              h_tipo_provvedimento,
                              h_oggetto_provvedimento,
                              h_stato_provvedimento,
                              h_note_provvedimento,
                              h_sac_provvedimento);  -- DAVIDE - Gestione SAC Provvedimento

          /*7 ----- discrimina per ente proprietario lavora su tipo e direzione provvedimento (dati non gestiti)
          nel caso di coto il tipo_provvedimento non e in chiave*/
          if codRes = 0 then
            h_tipo_provvedimento := h_tipo_provvedimento || '||';
          end if;

          if codRes = 0 and h_stato_provvedimento is null then
            h_stato_provvedimento := h_stato_impegno;
            if h_stato_provvedimento = 'N' then
              h_stato_provvedimento := 'D';
            end if;
          end if;          
          
          -- DAVIDE - 23.02.016 - segnalazione impegni pluriennali e gestione corretta leggi_provvedimento
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
     --- note
      /*10 ----- Campo NOTA non recuperato da verificare
      h_nota:=null;
      verificare se da estrarre da un altra tabella tipo impegno_nota
      */

      if codRes = 0 and  (h_soggetto_determinato='N' or (h_soggetto_determinato = 'S' and h_sogg_migrato <> 0))
       then
        msgRes := 'Inserimento in migr_impegno.';
        insert into migr_impegno
          (impegno_id,
           tipo_movimento,
           anno_esercizio,
           anno_impegno,
           numero_impegno,
           numero_subimpegno,
           pluriennale,
           capo_riacc,
           numero_capitolo,
           numero_articolo,
           numero_ueb,
           data_emissione,
           data_scadenza,
           stato_operativo,
           importo_iniziale,
           importo_attuale,
           descrizione,
           --anno_capitolo_orig,
           --numero_capitolo_orig,
           --numero_articolo_orig,
           --numero_ueb_orig,
           anno_provvedimento,
           numero_provvedimento,
           tipo_provvedimento,
           sac_provvedimento,       -- DAVIDE - Gestione SAC Provvedimento
           oggetto_provvedimento,
           note_provvedimento,
           stato_provvedimento,
           soggetto_determinato,
           codice_soggetto,
           tipo_impegno,
           anno_impegno_plur,
           numero_impegno_plur,
           anno_impegno_riacc,
           numero_impegno_riacc,
           opera,
           pdc_finanziario,
           missione,
           programma,
           cofog,
           transazione_ue_spesa,
           siope_spesa,
           spesa_ricorrente,
           --perimetro_sanitario_spesa,
           politiche_regionali_unitarie,
           pdc_economico_patr
           --,CLASSIFICATORE_1,CLASSIFICATORE_2,CLASSIFICATORE_3,CLASSIFICATORE_4,CLASSIFICATORE_5
          ,
           ente_proprietario_id)
        values
          (migr_impegno_id_seq.nextval,
           TIPO_IMPEGNO_I,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_impegno,
           migrImpegno.numero_impegno,
           migrImpegno.numero_subimpegno,
           migrImpegno.pluriennale,
           migrImpegno.capo_riacc,
           migrImpegno.numero_capitolo,
           migrImpegno.numero_articolo,
           migrImpegno.numero_ueb,
           migrImpegno.data_emissione,
           migrImpegno.data_scadenza,
           h_stato_impegno,
           migrImpegno.importo_iniziale,
           migrImpegno.importo_attuale,
           migrImpegno.descrizione,
           --migrImpegno.anno_capitolo_orig,
           --migrImpegno.numero_capitolo_orig,
           --migrImpegno.numero_articolo_orig,
           --migrImpegno.numero_ueb_orig,
           h_anno_provvedimento,
           to_number(h_numero_provvedimento),
           h_tipo_provvedimento,
           h_sac_provvedimento,      -- DAVIDE - Gestione SAC Provvedimento
           h_oggetto_provvedimento,
           h_note_provvedimento,
           h_stato_provvedimento,
           h_soggetto_determinato,
           migrImpegno.codice_soggetto,
           h_tipo_impegno,
           migrImpegno.anno_impegno_plur,
           migrImpegno.numero_impegno_plur,
           migrImpegno.anno_impegno_riacc,
           migrImpegno.numero_impegno_riacc,
           migrImpegno.opera,
           h_pdc_finanziario,
           migrImpegno.missione,
           migrImpegno.programma,
           h_cofog,
           migrImpegno.transazione_ue_spesa,
           migrImpegno.siope_spesa,
           migrImpegno.spesa_ricorrente,
           --h_per_sanitario,
           migrImpegno.politiche_regionali_unitarie,
           migrImpegno.pdc_economico_patr,
           --h_classificatore_1,h_classificatore_2,h_classificatore_3,h_classificatore_4,h_classificatore_5,
           p_ente_proprietario_id);

        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
    -- DAVIDE - 23.02.016 - segnalazione impegni pluriennali e gestione corretta leggi_provvedimento
         --(h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
         segnalare = true  then
         
        if codRes != 0 then
          msgMotivoScarto := msgRes;
        end if;

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
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
      
    end loop;
           
    msgResOut      := msgResOut || 'Elaborazione OK.Impegni plur inseriti=' ||
                      cImpInseriti || ' scartati=' || cImpScartati || '.';
    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;

    commit;
    exception
        when others then
          dbms_output.put_line('Impegno pluriennale ' || h_impegno || ' msgRes ' || msgRes ||
                               ' Errore ' || SQLCODE || '-' ||
                               SUBSTR(SQLERRM, 1, 100));
          msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                            SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
          p_imp_scartati := cImpScartati;
          p_imp_inseriti := cImpInseriti;
          p_cod_res      := -1;           
end migrazione_impegniPlur;


    procedure migrazione_subimpegnoPlur(p_ente_proprietario_id number,
                                          p_anno_esercizio       varchar2,
                                          p_cod_res              out number,
                                          p_imp_inseriti         out number,
                                          p_imp_scartati         out number,
                                          msgResOut              out varchar2)
    is
    
    msgRes varchar2(1500) := null;
    codRes number := 0;
    msgMotivoScarto varchar2(1500) := null;
    h_impegno varchar2(50) := null;
    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;
         
    h_soggetto_determinato varchar2(1) := null;
    h_sogg_migrato number := 0;
    h_num number := 0;
    h_pdc_finanziario MIGR_ACCERTAMENTO.PDC_FINANZIARIO%TYPE;
    h_cofog varchar2(50) := null;
    h_stato_impegno        varchar2(1) := null;
    h_anno_provvedimento   varchar2(4) := null;
    h_numero_provvedimento varchar2(10) := null;
    h_tipo_provvedimento   varchar2(20) := null;
    h_stato_provvedimento   varchar2(5) := null;
    h_oggetto_provvedimento varchar2(500) := null;
    h_note_provvedimento    varchar2(500) := null;
    
    h_sac_provvedimento     varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento

 -- DAVIDE - 23.02.016 - segnalazione subimpegni pluriennali e gestione corretta leggi_provvedimento
  segnalare    boolean := False; -- True: il record è inserito in entrambe le tabelle migr_* e migr_*_scarto
                                   -- False: il record è inserito nella sola tabella migr_*
     
    begin
    
        p_imp_scartati := 0;
        p_imp_inseriti := 0;
        p_cod_res      := 0;

        msgResOut := 'Migrazione SubImpegni plur.';
        msgRes    := 'Lettura SubImpegni plur.';

        for migrImpegno in (select i.anno_esercizio,
                                   i.annoimp        anno_impegno,
                                   i.nimp           numero_impegno,
                                   i.nsubimp        numero_subimpegno,
                                   to_char(i.data_ins,'YYYY-MM-DD') data_emissione,
                                   null data_scadenza,
                                   i.staoper stato_impegno,
                                   i.impoini importo_iniziale,
                                   i.impoatt importo_attuale,
                                   i.descri descrizione,
                                   decode(nvl(i.nprov, 'X'),
                                          'X',
                                          null,
                                          i.annoprov) anno_provvedimento,
                                   decode(nvl(i.nprov, 'X'),
                                          'X',
                                          null,
                                          to_number(i.nprov)) numero_provvedimento,
                                   --decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento, [non esiste il campo]  tipologia provvedimento restituita dalla funzione leggi_provvedimento
                                   --decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento, [non esiste il campo]
                                   i.codben codice_soggetto,
                                   i.cup,
                                   i.cig,
                                   --i.cod_interv_class  [non esiste il campo]
                                   null pdc_finanziario,
                                   null missione,
                                   null programma,
                                   null cofog,
                                   null transazione_ue_spesa,
                                   null siope_spesa,
                                   null spesa_ricorrente,
                                   null politiche_regionali_unitarie,
                                   null pdc_economico_patr
                              from subimp_plur i
                             where i.anno_esercizio = p_anno_esercizio + 3
                               and i.staoper in ('P', 'D')
                               and i.anno_esercizio || i.annoimp || i.nimp in
                                   (select imp.anno_esercizio || imp.anno_impegno || imp.numero_impegno
                                      from migr_impegno imp
                                     where ente_proprietario_id = p_ente_proprietario_id
                                     and imp.tipo_movimento = TIPO_IMPEGNO_I)
                             order by 1, 2, 3, 4) loop
      -- inizializza variabili
        msgRes := null;
        codRes := 0;
        msgMotivoScarto := null;
        h_soggetto_determinato := 'S';
        h_sogg_migrato := 0;
        h_num := 0;
        h_pdc_finanziario := null;
        h_cofog := null;
        h_stato_impegno        := null;
        h_anno_provvedimento   := null;
        h_numero_provvedimento := null;
        h_tipo_provvedimento   := null;
        h_stato_provvedimento   := null;
        h_oggetto_provvedimento := null;
        h_note_provvedimento    := null;
        
  -- DAVIDE - 23.02.016 - segnalazione subimpegni pluriennali e gestione corretta leggi_provvedimento
        segnalare               := false;
      
        h_impegno := 'SubImpegno plur ' || migrImpegno.anno_impegno || '/' ||migrImpegno.numero_impegno || '/' ||migrImpegno.numero_subimpegno || '.';
    
        h_sac_provvedimento     := null; -- DAVIDE - Gestione SAC Provvedimento

      -- soggetto_determinato
        if migrImpegno.codice_soggetto = 0 then
            msgRes := 'Lettura soggetto indeterminato.';
            h_soggetto_determinato := 'N';
            codRes := -1;
        end if;

        if h_soggetto_determinato = 'S' and codRes = 0 then
            msgRes := 'Verifica soggetto migrato.';
            begin
              select nvl(count(*), 0)
                into h_sogg_migrato
                from migr_soggetto
               where codice_soggetto = migrImpegno.codice_soggetto
                 and ente_proprietario_id = p_ente_proprietario_id;

              if h_sogg_migrato = 0 then
                msgRes          := 'Soggetto determinato non migrato.';
                msgMotivoScarto := msgRes;
              end if;

            exception
              when no_data_found then
                h_sogg_migrato  := 0;
                msgRes          := 'Soggetto determinato non migrato.';
                msgMotivoScarto := msgRes;
              when others then
                codRes := -1;
                msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            end;

            if codRes = 0 and h_sogg_migrato = 0 then
                begin

            select nvl(count(*),0) into h_num
            from fornitori
            where codben=migrImpegno.codice_soggetto and
                  staoper in ('V','S'); 

                if h_num = 0 then
                  msgRes := msgRes || 'Soggetto non valido.';
                  msgMotivoScarto := msgRes;
                end if;
                  exception
                    when no_data_found then
                      h_sogg_migrato  := 0;
                      h_num           := 0;
                      msgRes          := msgRes || 'Soggetto non valido.';
                      msgMotivoScarto := msgRes;
                    when others then
                      codRes := -1;
                      msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               end;
            end if;
         end if;

          --  pdc_finanziario ereditato da impegno migrato
        begin
              select pdc_finanziario, cofog into h_pdc_finanziario,h_cofog
              from migr_impegno
              where tipo_movimento = TIPO_IMPEGNO_I
              and anno_esercizio = migrImpegno.anno_esercizio
              and anno_impegno = migrImpegno.anno_impegno
              and numero_impegno = migrImpegno.numero_impegno
              and ente_proprietario_id = p_ente_proprietario_id;
             exception
                when no_data_found then
                  msgRes          := msgRes || 'Impegno padre non trovato in migr_impegno.';
                  msgMotivoScarto := msgRes;
                when too_many_rows then
                  msgRes          := msgRes || 'Ricerca Impegno padre.Too many rows';
                  msgMotivoScarto := msgRes;
                when others then
                  codRes := -1;
                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
              end;
      
      -- stato_impegno
      h_stato_impegno := migrImpegno.stato_impegno;

      -- provvedimento
      if codRes = 0 then
        msgRes := 'Lettura dati Provvedimento.';
        if migrImpegno.numero_provvedimento is null or
           migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
                        
       -- DAVIDE - 23.02.016 - segnalazione subimpegni e gestione corretta leggi_provvedimento
            h_stato_provvedimento:='D';
            segnalare := true;
            msgMotivoScarto := 'Provvedimento non presente per subimpegno in stato '||h_stato_impegno||'.';

          end if;
        else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          --h_tipo_provvedimento:=migrImpegno.tipo_provvedimento; [dato non recuperato nel cursore]
          --h_direzione_provvedimento:=migrImpegno.direzione_provvedimento; [dato non recuperato nel cursore]

          leggi_provvedimento(h_anno_provvedimento,
                              h_numero_provvedimento,
                              p_ente_proprietario_id,
                              codRes,
                              msgRes,
                              h_tipo_provvedimento,
                              h_oggetto_provvedimento,
                              h_stato_provvedimento,
                              h_note_provvedimento,
                              h_sac_provvedimento);   -- DAVIDE - Gestione SAC Provvedimento

          if codRes = 0 then
            h_tipo_provvedimento := h_tipo_provvedimento || '||';
          end if;

          if codRes = 0 and h_stato_provvedimento is null then
            h_stato_provvedimento := h_stato_impegno;
          end if;
          
          
       -- DAVIDE - 23.02.016 - segnalazione subimpegni pluriennali e gestione corretta leggi_provvedimento
          if h_stato_provvedimento = 'P' and h_stato_impegno = 'D' then
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
      if codRes = 0 and h_sogg_migrato <> 0 then
        msgRes := 'Inserimento in migr_impegno.';
        insert into migr_impegno
          (impegno_id,
           tipo_movimento,
           anno_esercizio,
           anno_impegno,
           numero_impegno,
           numero_subimpegno,
           data_emissione,
           data_scadenza,
           stato_operativo,
           importo_iniziale,
           importo_attuale,
           descrizione,
           anno_provvedimento,
           numero_provvedimento,
           tipo_provvedimento,
           sac_provvedimento,      -- DAVIDE - Gestione SAC Provvedimento
           oggetto_provvedimento,
           note_provvedimento,
           stato_provvedimento,
           soggetto_determinato,
           codice_soggetto,
           cup,
           cig,
           --cod_interv_class,
           pdc_finanziario,
           missione,
           programma,
           cofog,
           transazione_ue_spesa,
           siope_spesa,
           spesa_ricorrente,
           --perimetro_sanitario_spesa,
           politiche_regionali_unitarie,
           pdc_economico_patr,
           ente_proprietario_id)
        values
          (migr_impegno_id_seq.nextval,
           TIPO_IMPEGNO_S,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_impegno,
           migrImpegno.numero_impegno,
           migrImpegno.numero_subimpegno,
           migrImpegno.data_emissione,
           migrImpegno.data_scadenza,
           h_stato_impegno,
           migrImpegno.importo_iniziale,
           migrImpegno.importo_attuale,
           migrImpegno.descrizione,
           h_anno_provvedimento,
           to_number(h_numero_provvedimento),
           h_tipo_provvedimento,
           h_sac_provvedimento,                -- DAVIDE - Gestione SAC Provvedimento
           h_oggetto_provvedimento,
           h_note_provvedimento,
           h_stato_provvedimento,
           h_soggetto_determinato,
           migrImpegno.codice_soggetto,
           migrImpegno.cup,
           migrImpegno.cig,
           --migrImpegno.cod_interv_class,
           h_pdc_finanziario,
           migrImpegno.missione,
           migrImpegno.programma,
           h_cofog,
           migrImpegno.transazione_ue_spesa,
           migrImpegno.siope_spesa,
           migrImpegno.spesa_ricorrente,
           --h_per_sanitario,
           migrImpegno.politiche_regionali_unitarie,
           migrImpegno.pdc_economico_patr,
           p_ente_proprietario_id);

        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
   -- DAVIDE - 23.02.016 - segnalazione subimpegni pluriennali e gestione corretta leggi_provvedimento
        -- (h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
        segnalare = true then    
        
        if codRes != 0 then
          msgMotivoScarto := msgRes;
        end if;

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
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
    end loop;

    msgResOut := msgResOut || 'Elaborazione OK.Subimpegni plur inseriti=' ||
                 cImpInseriti || ' scartati=' || cImpScartati || '.';

    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;
    commit;

  exception
    when others then
      dbms_output.put_line('SubImpegno ' || h_impegno || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      p_cod_res      := -1;
    end migrazione_subimpegnoPlur;
    
    procedure migrazione_accertamentoPlur(p_ente_proprietario_id number,
                                    p_anno_esercizio       varchar2,
                                    p_cod_res              out number,
                                    p_imp_inseriti         out number,
                                    p_imp_scartati         out number,
                                    msgResOut              out varchar2)
    is   
    msgRes varchar2(1500) := null;
    msgMotivoScarto varchar2(1500) := null;
    codRes number := 0;
    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;
    
    h_impegno varchar2(50) := null;
    h_soggetto_determinato varchar2(1) := null;
    h_sogg_migrato number := 0;
    h_pdc_finanziario MIGR_CAPITOLO_ENTRATA.PDC_FIN_QUINTO%type := null;
    h_num number := 0;
    h_stato_impegno varchar2(1) := null;
    h_anno_provvedimento      varchar2(4) := null;
    h_numero_provvedimento    varchar2(10) := null;
    h_tipo_provvedimento      varchar2(20) := null;
    h_stato_provvedimento   varchar2(5) := null;
    h_oggetto_provvedimento varchar2(500) := null;
    h_note_provvedimento    varchar2(500) := null;
    h_nota       varchar2(250) := null;
    h_automatico varchar2(1) := 'N';
    
    h_sac_provvedimento     varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento

-- DAVIDE - 23.02.016 - segnalazione accertamenti pluriennali e gestione corretta leggi_provvedimento
    segnalare               boolean      := False; -- True: il record è inserito in entrambe le tabelle migr_* e migr_*_scarto
                                                   -- False: il record è inserito nella sola tabella migr_*

  begin
    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    msgResOut := 'Migrazione accertamenti plur.';
    msgRes    := 'Lettura Accertamenti plur.';

    for migrImpegno in (select i.anno_esercizio,
                               i.annoacc anno_accertamento,
                               i.nacc numero_accertamento,
                               0 numero_subaccertamento,
                               null pluriennale,
                               'N' capo_riacc,
                               i.nro_capitolo numero_capitolo,
                               i.nro_articolo numero_articolo,
                               decode(i.tipofin, 'MB', 1, 'MU', 2) || '0' ||
                               i.Cdc || nvl(i.coel, '0000') numero_ueb,
                               to_char(i.data_ins,'YYYY-MM-DD') data_emissione,
                               null      data_scadenza,
                               i.staoper stato_accertamento,
                               i.impoini importo_iniziale,
                               i.impoatt importo_attuale,
                               i.descri descrizione,
                               --i.annoacc anno_capitolo_orig,
                               --i.ex_capitolo numero_capitolo_orig,
                               --i.ex_articolo numero_articolo_orig,
                               --decode(i.ex_tipofin, 'MB', 1, 'MU', 2) || '00' ||i.ex_Cdc || nvl(i.ex_coel, '000') numero_ueb_orig,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      i.annoprov) anno_provvedimento,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      to_number(i.nprov)) numero_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento, [CAMPO NON PRESENTE]
                               --decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,[CAMPO NON PRESENTE]
                               i.codben    codice_soggetto,
                               null        nota,
                               null        anno_accertamento_plur,
                               null        numero_accertamento_plur,
                               null        anno_accertamento_riacc,
                               null        numero_accertamento_riacc,
                               null        opera,
                               null        pdc_finanziario,
                               null        transazione_ue_entrata,
                               null        siope_entrata,
                               null        entrata_ricorrente,
                               null        pdc_economico_patr,
                               i.codtitgiu
                          from accertamenti i
                         where i.anno_esercizio = p_anno_esercizio +3
                           and i.staoper in ('P', 'D')
                         order by 1, 2, 3) loop
      -- inizializza variabili
      codRes := 0;
      msgMotivoScarto := null;
      msgRes := null;
      
      h_sogg_migrato := 0;
      h_soggetto_determinato := 'S';
      h_pdc_finanziario := null;
      h_num := 0;
      h_stato_impegno := null;
      h_anno_provvedimento := null;
      h_numero_provvedimento := null;
      h_tipo_provvedimento := null;
      h_stato_provvedimento     := null;
      h_oggetto_provvedimento   := null;
      h_note_provvedimento      := null;
      h_automatico := 'N';
      h_nota := null;
    
      h_sac_provvedimento       := null; -- DAVIDE - Gestione SAC Provvedimento

   -- DAVIDE - 23.02.016 - segnalazione accertamenti pluriennali e gestione corretta leggi_provvedimento
      segnalare                 := false;

      h_impegno := 'Accertamento plur ' || migrImpegno.anno_accertamento || '/' ||
                   migrImpegno.numero_accertamento || '.';
      -- verifica capitolo migrato
      begin
        msgRes := 'Lettura capitolo migrato.';
        select pdc_fin_quinto into h_pdc_finanziario
          from migr_capitolo_entrata m
         where m.ente_proprietario_id=p_ente_proprietario_id
           and m.anno_esercizio = p_anno_esercizio
           and m.numero_capitolo = migrImpegno.numero_capitolo
           and m.numero_articolo =migrImpegno.numero_articolo
           and m.numero_ueb = migrImpegno.numero_ueb
           and tipo_capitolo = 'CAP-EG';
      exception
        when no_data_found then
          codRes := -1;
          msgRes := 'Capitolo non migrato.';
        when others then
          codRes := -1;
          msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      end;
      -- soggetto_determinato
      if codRes = 0 then
        if migrImpegno.codice_soggetto != 0 then
          h_soggetto_determinato := 'S';
        else
          msgRes := 'Lettura soggetto determinato S-N.';
          h_soggetto_determinato := 'N';
        end if;
      end if;

      if h_soggetto_determinato = 'S' and codRes = 0 then
        msgRes := 'Verifica soggetto migrato.';
        begin
          select nvl(count(*), 0)
            into h_sogg_migrato
            from migr_soggetto
           where codice_soggetto = migrImpegno.codice_soggetto
             and ente_proprietario_id = p_ente_proprietario_id;

          if h_sogg_migrato = 0 then
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          end if;

        exception
          when no_data_found then
            h_sogg_migrato  := 0;
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          when others then
            codRes := -1;
            msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        end;

        if codRes = 0 and h_sogg_migrato = 0 then
          begin
            select nvl(count(*),0) into h_num
            from fornitori
            where codben=migrImpegno.codice_soggetto and
                staoper in ('V','S'); 

            if h_num = 0 then
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            end if;
          exception
            when no_data_found then
              h_sogg_migrato  := 0;
              h_num           := 0;
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            when others then
              codRes := -1;
              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
          end;
        end if;
      end if;

      --  stato_impegno da calcolare
      if codRes = 0 then
        msgRes := 'Calcolo stato accertamento.';
        if migrImpegno.stato_accertamento = 'P' then
          h_stato_impegno := STATO_IMPEGNO_P;
        else
          if h_soggetto_determinato = 'S' then
            --or h_classe_soggetto is not null then
            h_stato_impegno := STATO_IMPEGNO_D;
          else
            h_stato_impegno := STATO_IMPEGNO_N;
          end if;
        end if;
      end if;

      -- provvedimento
      if codRes = 0 then
        msgRes := 'Lettura dati Provvedimento.';
        if migrImpegno.numero_provvedimento is null or
           migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
                    
        -- DAVIDE - 23.02.016 - segnalazione accertamenti e gestione corretta leggi_provvedimento
            h_stato_provvedimento:='D';
            segnalare := true;
            msgMotivoScarto := 'Provvedimento non presente per accertamento in stato '||migrImpegno.stato_accertamento||'.';

          end if;
        else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          --h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
          --h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

          -- dbms_output.put_line('msgRes prima di leggi_provvedimento '||msgRes);
          -- da implementare
          leggi_provvedimento(h_anno_provvedimento,
                              h_numero_provvedimento,
                              p_ente_proprietario_id,
                              codRes,
                              msgRes,
                              h_tipo_provvedimento,
                              h_oggetto_provvedimento,
                              h_stato_provvedimento,
                              h_note_provvedimento,
                              h_sac_provvedimento);    -- DAVIDE - Gestione SAC Provvedimento

          if codRes = 0 then
            h_tipo_provvedimento := h_tipo_provvedimento || '||';
          end if;

       -- DAVIDE - 23.02.016 - segnalazione accertamenti pluriennali e gestione corretta leggi_provvedimento
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

        if codRes = 0 and h_stato_provvedimento is null then
          h_stato_provvedimento := h_stato_impegno;
          if h_stato_provvedimento = 'N' then
            h_stato_provvedimento := 'D';
          end if;
        end if;
      end if;

      -- codtitgiu
      if codRes = 0 and migrImpegno.codtitgiu is not null then
        if migrImpegno.codtitgiu = ACC_AUTOMATICO then
          h_automatico := 'S';
        end if;
      end if;

      --- note
      h_nota := migrImpegno.nota;

      if codRes = 0 and (h_soggetto_determinato = 'N' or  (h_soggetto_determinato = 'S' and h_sogg_migrato = 0))
      then
        msgRes := 'Inserimento in migr_accertamento.';
        insert into migr_accertamento
          (accertamento_id,
           tipo_movimento,
           anno_esercizio,
           anno_accertamento,
           numero_accertamento,
           numero_subaccertamento,
           pluriennale,
           capo_riacc,
           numero_capitolo,
           numero_articolo,
           numero_ueb,
           data_emissione,
           data_scadenza,
           stato_operativo,
           importo_iniziale,
           importo_attuale,
           descrizione,
           --anno_capitolo_orig,
           --numero_capitolo_orig,
           --numero_articolo_orig,
           --numero_ueb_orig,
           anno_provvedimento,
           numero_provvedimento,
           tipo_provvedimento,
           sac_provvedimento,       -- DAVIDE - Gestione SAC Provvedimento
           oggetto_provvedimento,
           note_provvedimento,
           stato_provvedimento,
           soggetto_determinato,
           codice_soggetto,
           --classe_soggetto,
           nota,
           automatico,
           anno_accertamento_plur,
           numero_accertamento_plur,
           anno_accertamento_riacc,
           numero_accertamento_riacc,
           opera,
           pdc_finanziario,
           transazione_ue_entrata,
           siope_entrata,
           entrata_ricorrente,
           --perimetro_sanitario_entrata,
           pdc_economico_patr,
           --CLASSIFICATORE_1,CLASSIFICATORE_2,CLASSIFICATORE_3,CLASSIFICATORE_4,CLASSIFICATORE_5,
           ente_proprietario_id)
        values
          (migr_accertamento_id_seq.nextval,
           TIPO_IMPEGNO_A,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_accertamento,
           migrImpegno.numero_accertamento,
           migrImpegno.numero_subaccertamento,
           migrImpegno.pluriennale,
           migrImpegno.capo_riacc,
           migrImpegno.numero_capitolo,
           migrImpegno.numero_articolo,
           migrImpegno.numero_ueb,
           migrImpegno.data_emissione,
           migrImpegno.data_scadenza,
           h_stato_impegno,
           migrImpegno.importo_iniziale,
           migrImpegno.importo_attuale,
           migrImpegno.descrizione,
           --migrImpegno.anno_capitolo_orig,
           --migrImpegno.numero_capitolo_orig,
           --migrImpegno.numero_articolo_orig,
           --migrImpegno.numero_ueb_orig,
           h_anno_provvedimento,
           to_number(h_numero_provvedimento),
           h_tipo_provvedimento,
           h_sac_provvedimento,               -- DAVIDE - Gestione SAC Provvedimento
           h_oggetto_provvedimento,
           h_note_provvedimento,
           h_stato_provvedimento,
           h_soggetto_determinato,
           migrImpegno.codice_soggetto,
           --h_classe_soggetto,
           h_nota,
           h_automatico,
           migrImpegno.anno_accertamento_plur,
           migrImpegno.numero_accertamento_plur,
           migrImpegno.anno_accertamento_riacc,
           migrImpegno.numero_accertamento_riacc,
           migrImpegno.opera,
           h_pdc_finanziario,
           migrImpegno.transazione_ue_entrata,
           migrImpegno.siope_entrata,
           migrImpegno.entrata_ricorrente,
           --h_per_sanitario,
           migrImpegno.pdc_economico_patr,
           --h_classificatore_1,h_classificatore_2,h_classificatore_3,h_classificatore_4,h_classificatore_5,
           p_ente_proprietario_id);

        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
     -- DAVIDE - 23.02.016 - segnalazione accertamenti e gestione corretta leggi_provvedimento
         -- (h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
         segnalare = true then

         --(h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
        if codRes != 0 then
          msgMotivoScarto := msgRes;
        end if;

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
           migrImpegno.anno_accertamento,
           migrImpegno.numero_accertamento,
           migrImpegno.numero_subaccertamento,
           msgMotivoScarto,
           p_ente_proprietario_id);
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
    end loop;

    msgResOut := msgResOut || 'Elaborazione OK.Accertamenti plur inseriti=' ||
                 cImpInseriti || ' scartati=' || cImpScartati || '.';

    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;
    commit;

  exception
    when others then
      dbms_output.put_line('Accertamento plur' || h_impegno || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      p_cod_res      := -1;
      
end migrazione_accertamentoPlur;

  procedure migrazione_subaccertamentoPlur(p_ente_proprietario_id number,
                                       p_anno_esercizio       varchar2,
                                       p_cod_res              out number,
                                       p_imp_inseriti         out number,
                                       p_imp_scartati         out number,
                                       msgResOut              out varchar2) is
    msgRes varchar2(1500) := null;
    codRes number := 0;
    msgMotivoScarto varchar2(1500) := null;
    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;

    h_impegno varchar2(50) := null;
    h_sogg_migrato number := 0;
    h_soggetto_determinato varchar2(1) := null;
    h_num number := 0;
    h_pdc_finanziario MIGR_ACCERTAMENTO.pdc_finanziario%type := null;
    h_stato_impegno        varchar2(1) := null;
    h_anno_provvedimento      varchar2(4) := null;
    h_numero_provvedimento    varchar2(10) := null;
    h_tipo_provvedimento      varchar2(20) := null;
    h_stato_provvedimento   varchar2(5) := null;
    h_oggetto_provvedimento varchar2(500) := null;
    h_note_provvedimento    varchar2(500) := null;
        
    h_sac_provvedimento     varchar2(20)  := null; -- DAVIDE - Gestione SAC Provvedimento

  -- DAVIDE - 23.02.016 - segnalazione subaccertamenti pluriennali e gestione corretta leggi_provvedimento
    segnalare               boolean       := False; -- True: il record è inserito in entrambe le tabelle migr_* e migr_*_scarto
                                                    -- False: il record è inserito nella sola tabella migr_*

  begin
    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    msgResOut := 'Migrazione SubAccertamenti plur.';
    msgRes    := 'Lettura SubAccertamenti plur.';

    for migrImpegno in (select i.anno_esercizio,
                               i.annoacc anno_accertamento,
                               i.nacc numero_accertamento,
                               i.nsubacc numero_subaccertamento,
                               to_char(i.data_ins,'YYYY-MM-DD')  data_emissione,
                               null data_scadenza,
                               i.staoper stato_impegno,
                               i.impoini importo_iniziale,
                               i.impoatt importo_attuale,
                               i.descri descrizione,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      i.annoprov) anno_provvedimento,
                               decode(nvl(i.nprov, 'X'),
                                      'X',
                                      null,
                                      to_number(i.nprov)) numero_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,i.codprov) tipo_provvedimento,
                               --decode(nvl(i.nprov,'X'),'X',null,decode(nvl(i.direzione,'X'),'X',null,i.direzione)) direzione_provvedimento,
                               i.codben codice_soggetto,
                               null     pdc_finanziario,
                               null     transazione_ue_entrata,
                               null     siope_entrata,
                               null     entrata_ricorrente,
                               null     pdc_economico_patr
                          from subacc_plur i
                         where i.anno_esercizio = p_anno_esercizio+3
                           and i.staoper in ('P', 'D')
                           and i.anno_esercizio || i.annoacc || i.nacc in
                               (select a.anno_esercizio || a.anno_accertamento || a.numero_accertamento
                                  from migr_accertamento a
                                 where ente_proprietario_id = p_ente_proprietario_id
                                 and a.tipo_movimento=TIPO_IMPEGNO_A)
                         order by 1, 2, 3, 4) loop
      -- inizializza variabili
      codRes := 0;
      msgMotivoScarto  := null;
      msgRes := null;
      h_sogg_migrato := 0;
      h_soggetto_determinato := 'S';
      h_num := 0;
      h_pdc_finanziario := null;
      h_stato_impegno           := null;
      
      h_anno_provvedimento      := null;
      h_numero_provvedimento    := null;
      h_tipo_provvedimento      := null;
      h_stato_provvedimento     := null;
      h_oggetto_provvedimento   := null;
      h_note_provvedimento      := null;
        
      h_sac_provvedimento       := null; -- DAVIDE - Gestione SAC Provvedimento
      
  -- DAVIDE - 23.02.016 - segnalazione subaccertamenti pluriennali e gestione corretta leggi_provvedimento
      segnalare                 := false;

      h_impegno := 'SubAccertamento plur' || migrImpegno.anno_accertamento ||
                   migrImpegno.numero_accertamento || '/' ||
                   migrImpegno.numero_subaccertamento || '.';
      
      -- soggetto_determinato
      if migrImpegno.codice_soggetto = 0 then
        msgRes  := 'Lettura soggetto indeterminato.';
        h_soggetto_determinato := 'N';
        codRes  := -1;
      end if;

      if h_soggetto_determinato = 'S' and codRes = 0 then

        msgRes := 'Verifica soggetto migrato.';
        begin
          select nvl(count(*), 0)
            into h_sogg_migrato
            from migr_soggetto
           where codice_soggetto = migrImpegno.codice_soggetto
             and ente_proprietario_id = p_ente_proprietario_id;

          if h_sogg_migrato = 0 then
            msgRes := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          end if;

        exception
          when no_data_found then
            h_sogg_migrato  := 0;
            msgRes          := 'Soggetto determinato non migrato.';
            msgMotivoScarto := msgRes;
          when others then
            codRes := -1;
            msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        end;

        if codRes = 0 and h_sogg_migrato = 0 then
          begin
            select nvl(count(*),0) into h_num
            from fornitori
            where codben=migrImpegno.codice_soggetto and
                staoper in ('V','S'); 

            if h_num = 0 then
              msgRes  := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;
            end if;
          exception
            when no_data_found then
              h_sogg_migrato  := 0;
              h_num           := 0;
              msgRes          := msgRes || 'Soggetto non valido.';
              msgMotivoScarto := msgRes;

            when others then
              codRes := -1;
              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
          end;
        end if;
      end if;

    --  pdc_finanziario ereditato da accertamento migrato
        begin
              select pdc_finanziario into h_pdc_finanziario
              from migr_accertamento
              where tipo_movimento = TIPO_IMPEGNO_A
              and anno_esercizio = migrImpegno.anno_esercizio
              and anno_accertamento = migrImpegno.anno_accertamento
              and numero_accertamento = migrImpegno.numero_accertamento
              and ente_proprietario_id = p_ente_proprietario_id;
             exception
                when no_data_found then
                  msgRes          := msgRes || 'Accertamento padre non trovato in migr_accertamento.';
                  msgMotivoScarto := msgRes;
                when too_many_rows then
                  msgRes          := msgRes || 'Ricerca accertamento padre.Too many rows';
                  msgMotivoScarto := msgRes;
                when others then
                  codRes := -1;
                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
              end;

      -- stato_impegno
      h_stato_impegno := migrImpegno.stato_impegno;

      -- provvedimento
      if codRes = 0 then
        msgRes := 'Lettura dati Provvedimento.';
        if migrImpegno.numero_provvedimento is null or
           migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
                        
       -- DAVIDE - 23.02.016 - segnalazione subaccertamenti pluriennali e gestione corretta leggi_provvedimento
            h_stato_provvedimento := 'D';
            segnalare := true;
            msgMotivoScarto := 'Provvedimento non presente per subaccertamento pluriennale in stato '||h_stato_impegno||'.';

          end if;
        else
          h_anno_provvedimento   := migrImpegno.anno_provvedimento;
          h_numero_provvedimento := migrImpegno.numero_provvedimento;
          --h_tipo_provvedimento:=migrImpegno.tipo_provvedimento;
          --h_direzione_provvedimento:=migrImpegno.direzione_provvedimento;

          -- dbms_output.put_line('msgRes prima di leggi_provvedimento '||msgRes);
          -- da implementare
          leggi_provvedimento(h_anno_provvedimento,
                              h_numero_provvedimento,
                              p_ente_proprietario_id,
                              codRes,
                              msgRes,
                              h_tipo_provvedimento,
                              h_oggetto_provvedimento,
                              h_stato_provvedimento,
                              h_note_provvedimento,
                              h_sac_provvedimento);   -- DAVIDE - Gestione SAC Provvedimento
          if codRes = 0 then
            h_tipo_provvedimento := h_tipo_provvedimento || '||';
          end if;
          
     -- DAVIDE - 23.02.016 - segnalazione subaccertamenti pluriennali e gestione corretta leggi_provvedimento
          if h_stato_provvedimento = 'P' and h_stato_impegno = 'D' then
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

        if codRes = 0 and h_stato_provvedimento is null then
          h_stato_provvedimento := h_stato_impegno;
        end if;
      end if;

      if codRes = 0 and h_sogg_migrato <> 0 then
        msgRes := 'Inserimento in migr_accertamento.';
        insert into migr_accertamento
          (accertamento_id,
           tipo_movimento,
           anno_esercizio,
           anno_accertamento,
           numero_accertamento,
           numero_subaccertamento,
           data_emissione,
           data_scadenza,
           stato_operativo,
           importo_iniziale,
           importo_attuale,
           descrizione,
           anno_provvedimento,
           numero_provvedimento,
           tipo_provvedimento,
           sac_provvedimento,        -- DAVIDE - Gestione SAC Provvedimento
           oggetto_provvedimento,
           note_provvedimento,
           stato_provvedimento,
           soggetto_determinato,
           codice_soggetto,
           pdc_finanziario,
           transazione_ue_entrata,
           siope_entrata,
           entrata_ricorrente,
           --perimetro_sanitario_entrata,
           pdc_economico_patr,
           ente_proprietario_id)
        values
          (migr_accertamento_id_seq.nextval,
           TIPO_IMPEGNO_S,
           migrImpegno.anno_esercizio,
           migrImpegno.anno_accertamento,
           migrImpegno.numero_accertamento,
           migrImpegno.numero_subaccertamento,
           migrImpegno.data_emissione,
           migrImpegno.data_scadenza,
           h_stato_impegno,
           migrImpegno.importo_iniziale,
           migrImpegno.importo_attuale,
           migrImpegno.descrizione,
           h_anno_provvedimento,
           to_number(h_numero_provvedimento),
           h_tipo_provvedimento,
           h_sac_provvedimento,               -- DAVIDE - Gestione SAC Provvedimento
           h_oggetto_provvedimento,
           h_note_provvedimento,
           h_stato_provvedimento,
           h_soggetto_determinato,
           migrImpegno.codice_soggetto,
           h_pdc_finanziario,
           migrImpegno.transazione_ue_entrata,
           migrImpegno.siope_entrata,
           migrImpegno.entrata_ricorrente,
           --h_per_sanitario,
           migrImpegno.pdc_economico_patr,
           p_ente_proprietario_id);

        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
    -- DAVIDE - 23.02.016 - segnalazione subaccertamenti pluriennali e gestione corretta leggi_provvedimento
        -- (h_soggetto_determinato = 'S' and h_sogg_migrato = 0) then
        segnalare = true then
        
        if codRes != 0 then
          msgMotivoScarto := msgRes;
        end if;

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
           migrImpegno.anno_accertamento,
           migrImpegno.numero_accertamento,
           migrImpegno.numero_subaccertamento,
           msgMotivoScarto,
           p_ente_proprietario_id);
        cImpScartati := cImpScartati + 1;
      end if;

      if numImpegno >= 200 then
        commit;
        numImpegno := 0;
      else
        numImpegno := numImpegno + 1;
      end if;
    end loop;

    msgResOut := msgResOut || 'Elaborazione OK.SubAccertamenti plur inseriti=' ||
                 cImpInseriti || ' scartati=' || cImpScartati || '.';

    p_imp_scartati := cImpScartati;
    p_imp_inseriti := cImpInseriti;
    commit;

  exception
    when others then
      dbms_output.put_line('SubAccertamenti plur ' || h_impegno || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      msgResOut      := msgResOut || h_impegno || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      p_imp_scartati := cImpScartati;
      p_imp_inseriti := cImpInseriti;
      p_cod_res      := -1;

  end migrazione_subaccertamentoPlur;
  
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
    begin
        msgResOut := 'Oracle.Migrazione Impegni/Accertamenti.';
        v_codRes := 0;
        
        -- controllo sulla presenza dei parametri in input
        if (p_ente_proprietario_id is null or p_anno_esercizio is null) then
            v_codRes := -1;
            v_msgRes := 'Uno o più parametri in input non sono stati valorizzati correttamente';
        end if;
        
        -- pulizia delle tabelle migr_
        begin
            v_msgRes := 'Pulizia tabelle di migrazione.';
            DELETE FROM MIGR_IMPEGNO_SCARTO where ente_proprietario_id = p_ente_proprietario_id;
            DELETE FROM MIGR_ACCERTAMENTO_SCARTO where ente_proprietario_id = p_ente_proprietario_id;
            DELETE FROM MIGR_IMPEGNO WHERE FL_MIGRATO = 'N' and ente_proprietario_id = p_ente_proprietario_id;
            DELETE FROM MIGR_ACCERTAMENTO WHERE FL_MIGRATO = 'N' and ente_proprietario_id = p_ente_proprietario_id;
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
              migrazione_impegni(p_ente_proprietario_id, p_anno_esercizio,v_anno, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
              v_msgRes := v_msgRes || p_msgRes ;
          end if;
          if v_codRes = 0 then
              -- 1) SubImpegni
              migrazione_subimpegno(p_ente_proprietario_id,v_anno, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
              v_msgRes := v_msgRes || p_msgRes ;
          end if;
          if v_codRes = 0 then
              -- 1) Accertamenti
              migrazione_accertamento(p_ente_proprietario_id, p_anno_esercizio,v_anno, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
              v_msgRes := v_msgRes || p_msgRes ;
          end if;
          if v_codRes = 0 then
              -- 1) SubAccertamenti
              migrazione_subaccertamento(p_ente_proprietario_id,v_anno, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
              v_msgRes := v_msgRes || p_msgRes ;
          end if;
        end loop;
        if v_codRes = 0 then
            -- 1) ImpegniPlur
            migrazione_impegniplur(p_ente_proprietario_id, p_anno_esercizio, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;
        if v_codRes = 0 then
            -- 1) subImpegniPlur
            migrazione_subimpegnoplur(p_ente_proprietario_id, p_anno_esercizio, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;      
        if v_codRes = 0 then
            -- 1) Accertamenti plur
            migrazione_accertamentoplur(p_ente_proprietario_id, p_anno_esercizio, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;    
        if v_codRes = 0 then
            -- 1) sub accertamenti Plur
            migrazione_subaccertamentoplur(p_ente_proprietario_id, p_anno_esercizio, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;    
        
        if v_codRes = 0 then
          migrazione_mutuo ( p_anno_esercizio, p_ente_proprietario_id,v_codRes,p_msgRes,v_imp_inseriti,v_imp_scartati);
          v_msgRes := v_msgRes || p_msgRes ;
        end if;
        
        if v_codRes = 0 then
          migrazione_voce_mutuo ( p_anno_esercizio, p_ente_proprietario_id,v_codRes,p_msgRes,v_imp_inseriti,v_imp_scartati);
          v_msgRes := v_msgRes || p_msgRes ;
        end if;
                                
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
         if ( codRes=0) then
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
         if (codRes=0 ) then
           msgResIn:='Migrazione capitoli gestione entrata.';
           migrazione_cge(pAnnoEsercizio,pEnte,codRes,msgRes);
         end if;
         if ( codRes=0) then
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


   procedure migrazione_mutuo (pAnnoEsercizio varchar2,pEnte number, pCodRes out number, pMsgRes out varchar2,pMutuiInseriti out number,pMutuiScartati out number)
      is
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cMutuiInseriti number := 0;
        cMutuiScartati number := 0;
        numMutuo number := 0; --serve per contare i mutui e committare al 200esimo
        
        h_sogg_migrato number := 0;
        h_num number := 0;
        h_note varchar2(250):=null;
        h_mutuo varchar2(50) := null;
        h_stato_impegno         varchar2(1) := null;
        h_anno_provvedimento    varchar2(4) := null;
        h_numero_provvedimento  varchar2(10) := null;
        h_tipo_provvedimento    varchar2(20) := null;
        h_stato_provvedimento   varchar2(5) := null;
        h_oggetto_provvedimento varchar2(500) := null;
        h_note_provvedimento    varchar2(500) := null;
          
        h_sac_provvedimento     varchar2(20)  := null; -- DAVIDE - Gestione SAC Provvedimento
      
  procedure migrazione_agg_tipoMutuo ( pEnte number,
                                       pCodRes out number,
                                       pMsgRes out varchar2) is

  msgRes            varchar2(1500) := null;
  codRes            integer := 0;

  begin
    -- codice tipo mutuo presente su SIAC
    /*RIS - Riscossione Completa
    AVL - Avanzamento Lavori
    BOC - B.O.C.
    FID - Fideiussione
    GAR - Garanzie
    PRE -Prestito Flessibile
    */
  msgRes:='Migrazione mutuo.Aggiornamento tipo.';
  update migr_mutuo m set
  m.tipo_mutuo='RIS'
  where m.tipo_mutuo = 'R'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;
    
  update migr_mutuo m set
  m.tipo_mutuo='AVL'
  where m.tipo_mutuo = 'A'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;
    
  update migr_mutuo m set
  m.tipo_mutuo='BOC'
  where m.tipo_mutuo = 'B'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_mutuo m set
  m.tipo_mutuo='FID'
  where m.tipo_mutuo = 'F'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;
    
  update migr_mutuo m set
  m.tipo_mutuo='GAR'
  where m.tipo_mutuo = 'G'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;
    
  update migr_mutuo m set
  m.tipo_mutuo='PRE'
  where m.tipo_mutuo = 'P'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;
    
  commit;

  pMsgRes:= msgRes||' ' ||'Aggiornamento OK.';
  pCodRes:=codRes;

  exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
  end migrazione_agg_tipoMutuo;
        
      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_mutuo.Uno o più parametri in input non sono stati valorizzati correttamente';
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin
            msgRes := 'Pulizia tabelle di migrazione mutuo.';
            DELETE FROM MIGR_MUTUO WHERE FL_MIGRATO = 'N' AND ente_proprietario_id = pEnte;
            DELETE FROM MIGR_MUTUO_SCARTO WHERE ente_proprietario_id = pEnte;
        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
               for migrMutuo in (select 
                                 m.nro_mutuo
                                 , m.descri
                                 , m.tipo tipo_mutuo
                                 -- DAVIDE 02.10.015 - importi dei mutui da migrare devono essere in Euro
                                 --, m.importo_orig as importo_iniziale
                                 --, m.importo as importo_attuale --aspetto indicazione su come calcolare l'info
                                 , m.euro_importo_orig as importo_iniziale
                                 , m.euro_importo as importo_attuale --aspetto indicazione su come calcolare l'info
                                 -- DAVIDE 02.10.015 - Fine
                                 , m.durata
                                 , m.posizione
                                 , to_char(m.data_ini,'YYYY-MM-DD') as data_inizio
                                 , to_char(m.data_fine,'YYYY-MM-DD') as data_fine
                                 , m.stato
                                 , m.ist_mutuante
                                 , m.annoprov, m.nprov, m.tipoprov, m.cdc_prov
                                 , NULL as oggetto_prov 
                                 , NULL as note_prov
                                 , NULL as stato_prov
                                 --, NULL as note 
                                 , ev.prog_evento||', '||ev.descri||', '||to_char(ev.data_ini,'DD/MM/YYYY') as note -- da valorizzare con codice||descrizione||dataini dell'ultimo evento registrato per il mutuo.
                                from mutui m
                                , eventi_mutuo ev
                                where 
                                     (m.stato = 'P' or
                                     (m.stato <> 'P' and exists (select 1 from imp_mutui v where v.nro_mutuo=m.nro_mutuo and v.anno_esercizio>=pAnnoEsercizio))
                                     )and 
                                not exists (select 1 from eventi_mutuo e where e.nro_mutuo=m.nro_mutuo and e.tipo_evento = 'EST')
                                and ev.nro_mutuo(+) = m.nro_mutuo
                                and 
                                    (ev.prog_evento = (select max(prog_evento) from eventi_mutuo ev2 where ev2.nro_mutuo=m.nro_mutuo)
                                    or ev.prog_evento is null))
                                    loop
                                      
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            msgRes := null;
                            h_sogg_migrato := 0;
                            h_num := 0;
                            h_note := null;
                            h_anno_provvedimento      := null;
                            h_numero_provvedimento    := null;
                            h_tipo_provvedimento      := null;
                            h_stato_provvedimento     := null;
                            h_oggetto_provvedimento   := null;
                            h_note_provvedimento      := null;
                            h_mutuo := 'Mutuo ' || migrMutuo.nro_mutuo || '.';
              
                            h_sac_provvedimento       := null; -- DAVIDE - Gestione SAC Provvedimento

                            msgRes := 'Verifica soggetto migrato.';
                            begin
                              select nvl(count(*), 0)
                                into h_sogg_migrato
                                from migr_soggetto
                               where codice_soggetto = migrMutuo.ist_mutuante
                                 and ente_proprietario_id = pEnte;

                              if h_sogg_migrato = 0 then
                                codRes := -1;
                                msgRes := 'Soggetto non migrato.';
                                msgMotivoScarto := msgRes;
                              end if;

                            exception
                              when no_data_found then
                                codRes := -1;
                                h_sogg_migrato  := 0;
                                msgRes          := 'Soggetto non migrato.';
                                msgMotivoScarto := msgRes;
                              when others then
                                codRes := -1;
                                msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                            end;

                            if h_sogg_migrato = 0 then
                              begin
                                select nvl(count(*),0) into h_num
                                from fornitori
                                where codben=migrMutuo.ist_mutuante and
                                    staoper in ('V','S'); 

                                if h_num = 0 then
                                  msgRes  := msgRes || 'Soggetto non valido.';
                                  msgMotivoScarto := msgRes;
                                end if;
                              exception
                                when no_data_found then
                                  --codRes := -1; già impostato prima
                                  h_sogg_migrato  := 0;
                                  h_num           := 0;
                                  msgRes          := msgRes || 'Soggetto non valido.';
                                  msgMotivoScarto := msgRes;
                                when others then
                                  --codRes := -1; già impostato prima
                                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                              end;
                            end if;

                            -- provvedimento
                            if codRes = 0 then
                              msgRes := 'Lettura dati Provvedimento.';
                              -- il provvedimento DEVE essere presente per il mutupo (la colonna nprov non accetta valori NULL)
                              h_anno_provvedimento   := migrMutuo.annoprov;
                              h_numero_provvedimento := migrMutuo.nprov;
                              leggi_provvedimento(h_anno_provvedimento,
                                                  h_numero_provvedimento,
                                                  pEnte,
                                                  codRes,
                                                  msgRes,
                                                  h_tipo_provvedimento,
                                                  h_oggetto_provvedimento,
                                                  h_stato_provvedimento,
                                                  h_note_provvedimento,
                                                  h_sac_provvedimento);     -- DAVIDE - Gestione SAC Provvedimento
                              if codRes = 0 then
                                h_tipo_provvedimento := h_tipo_provvedimento || '||';
                              end if;
                              if codRes = 0 and h_stato_provvedimento is null then
                                -- ci sono 3 casi in produzione per cui lo stato non è definito, quindi è corretto nel caso non lo sia,
                                -- usare lo stato del mutuo?
                                -- il valore NULL è possibile solo su tabelle DELIBERE e non su MOVIMENTI INTERNI
                                h_stato_provvedimento := migrMutuo.stato; -- è così?
                              end if;
                            end if;
                            
                            if codRes = 0 then
                               -- da fare meglio.
                              if migrMutuo.note <> ', , ' then
                                 h_note := migrMutuo.note;
                              end if;
                            end if;
                            

                            if codRes = 0 then
                              msgRes := 'Inserimento in migr_mutuo.';
                              insert into migr_mutuo 
                              (mutuo_id
                              , codice_mutuo
                              , descrizione
                              , tipo_mutuo
                              ,importo_iniziale
                              ,importo_attuale 
                              ,durata
                              ,numero_registrazione
                              ,data_inizio
                              ,data_fine
                              ,stato_operativo
                              ,codice_soggetto
                              ,anno_provvedimento
                              ,numero_provvedimento
                              ,tipo_provvedimento
                              ,sac_provvedimento        -- DAVIDE - Gestione SAC Provvedimento
                              ,oggetto_provvedimento
                              ,note_provvedimento
                              ,stato_provvedimento
                              ,note
                              ,ente_proprietario_id)
                              values
                                (migr_mutuo_id_seq.nextval,
                                -- DAVIDE - 02.10.015 - Codice Mutuo senza zeri davanti
                                 --migrMutuo.nro_mutuo,
                                 LTRIM(migrMutuo.nro_mutuo, '0'),
                                 -- DAVIDE - 02.10.015 - Fine
                                 migrMutuo.descri,
                                 migrMutuo.tipo_mutuo,
                                 migrMutuo.importo_iniziale,
                                 migrMutuo.importo_attuale,
                                 migrMutuo.durata,
                                 migrMutuo.posizione,
                                 migrMutuo.data_inizio,
                                 migrMutuo.data_fine,
                                 migrMutuo.stato,
                                 migrMutuo.ist_mutuante,
                                 h_anno_provvedimento,
                                 h_numero_provvedimento,
                                 h_tipo_provvedimento,
                                 h_sac_provvedimento,       -- DAVIDE - Gestione SAC Provvedimento
                                 h_oggetto_provvedimento,
                                 h_note_provvedimento,
                                 h_stato_provvedimento,
                                 h_note,
                                 pEnte);
                              cMutuiInseriti := cMutuiInseriti + 1;
                            end if;

                            if codRes != 0 then
                              msgRes := 'Inserimento in migr_mutuo_scarto.';
                              insert into migr_mutuo_scarto
                                (mutuo_scarto_id,
                                 codice_mutuo,
                                 motivo_scarto,
                                 ente_proprietario_id)
                              values
                                (migr_mutuo_scarto_id_seq.nextval,
                                -- DAVIDE - 02.10.015 - Codice Mutuo senza zeri davanti
                                 --migrMutuo.nro_mutuo,
                                 LTRIM(migrMutuo.nro_mutuo, '0'),
                                 -- DAVIDE - 02.10.015 - Fine
                                 msgMotivoScarto,
                                 pEnte);
                              cMutuiScartati := cMutuiScartati + 1;
                            end if;

                            if numMutuo >= 200 then
                              commit;
                              numMutuo := 0;
                            else
                              numMutuo := numMutuo + 1;
                            end if;
                      end loop;
                      
    if (codRes=0 and cMutuiInseriti>0 ) then
       migrazione_agg_tipoMutuo (pEnte,codRes,msgRes);
    end if;

    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Mutui inseriti=' ||
                 cMutuiInseriti || ' scartati=' || cMutuiScartati || '.';

    pMutuiScartati := cMutuiScartati;
    pMutuiInseriti := cMutuiInseriti;
    commit;

  exception
    when others then
      dbms_output.put_line(h_mutuo || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_mutuo || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pMutuiScartati := cMutuiScartati;
      pMutuiInseriti := cMutuiInseriti;
      pCodRes      := -1;
      
  end migrazione_mutuo;
  procedure migrazione_voce_mutuo (pAnnoEsercizio varchar2,pEnte number, pCodRes out number, pMsgRes out varchar2,pMutuiInseriti out number,pMutuiScartati out number)
      is
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cMutuiInseriti number := 0;
        cMutuiScartati number := 0;
        numMutuo number := 0; --serve per contare i mutui e committare al 200esimo
        
        h_imp_migrato number := 0;
        h_mutuo varchar2(50) := null;
        h_tipo varchar2(10) := '01'; -- di default il tipo voce mutuo è ORIGINALE, 
                                      -- diversamente se imp_iniziale = 0 tipo = 002 (Storno), se anno_impegno<anno_esercizio tipo = 003 (Da residuo)

      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_voce_mutuo.Uno o più parametri in input non sono stati valorizzati correttamente';
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin
            msgRes := 'Pulizia tabelle di migrazione voce mutuo.';
            DELETE FROM MIGR_VOCE_MUTUO WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_VOCE_MUTUO_SCARTO WHERE ente_proprietario_id = pEnte;
        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
        
        -- SCARTI PER MANCANZA DI IMPEGNO MIGRATO
        insert into migr_voce_mutuo_scarto
               (voce_mutuo_scarto_id,
               nro_mutuo,
               numero_impegno,
               anno_impegno,
               anno_esercizio,
               motivo_scarto,
               ente_proprietario_id)
         (select migr_voce_mutuo_scarto_id_seq.nextval,
            -- DAVIDE - 02.10.015 - pulizia codice_voce_mutuo e settaggio automatico
                 LTRIM(v.nro_mutuo,'0'),v.nimp, v.annoimp, v.anno_esercizio, 'Impegno non migrato.',pEnte
            -- DAVIDE - 02.10.015 - Fine
                  from imp_mutui v
                  where v.anno_esercizio>=pAnnoEsercizio
                  and LTRIM(v.nro_mutuo,'0') in (select codice_mutuo from migr_mutuo m where m.ente_proprietario_id = pEnte)
                  and not exists (select 1 from migr_impegno imp where imp.ente_proprietario_id = pEnte and imp.numero_impegno= v.nimp and imp.anno_impegno=v.annoimp and imp.anno_esercizio=v.anno_esercizio));
                  
        -- VOCI DI MUTUO CHE SONO DA MIGRARE
         insert into migr_voce_mutuo 
            (voce_mutuo_id
            ,codice_voce_mutuo
            ,nro_mutuo
            ,descrizione
            ,importo_iniziale
            ,importo_attuale
            ,tipo_voce_mutuo
            ,anno_impegno
            ,numero_impegno
            ,anno_esercizio
            ,ente_proprietario_id)
            -- DAVIDE - 02.10.015 - pulizia codice_voce_mutuo e settaggio automatico
            -- tipo_voce_mutuo - tolta l'update sull'importo sotto e inseriti i settaggi nella query 
         (select migr_voce_mutuo_id_seq.nextval,
          --NULL, v.nro_mutuo
          NULL, LTRIM(v.nro_mutuo,'0')
          ,'Finanziamento impegno '||v.annoimp||'/'||v.nimp
          --,v.impoini,v.impoatt,h_tipo, v.annoimp,
          ,v.impoini,v.impoatt,
          DECODE(v.impoini, 0,    '02',
                            null, '02',
                            '01'), 
          v.annoimp,
          v.nimp, v.anno_esercizio,pEnte
          from imp_mutui v
          where v.anno_esercizio>=pAnnoEsercizio
          and LTRIM(v.nro_mutuo,'0') in (select codice_mutuo from migr_mutuo m where m.ente_proprietario_id = pEnte)
          and exists (select 1 from migr_impegno imp where imp.ente_proprietario_id = pEnte and imp.numero_impegno= v.nimp and imp.anno_impegno=v.annoimp and imp.anno_esercizio=v.anno_esercizio));

       -- AGGIORNO TIPO_VOCE_MUTUO
       /*UPDATE migr_voce_mutuo 
              SET tipo_voce_mutuo = '02'
       WHERE (importo_iniziale IS NULL OR importo_iniziale = 0) 
       and ente_proprietario_id = pEnte;*/
       -- DAVIDE - 02.10.015 - Fine

       UPDATE migr_voce_mutuo 
              SET tipo_voce_mutuo = '03'
       WHERE TO_NUMBER(anno_impegno) < TO_NUMBER(anno_esercizio)
       and ente_proprietario_id = pEnte;
       
       commit;
       
       SELECT COUNT (*) INTO pMutuiInseriti 
       FROM MIGR_VOCE_MUTUO 
       WHERE FL_MIGRATO = 'N'
       and ente_proprietario_id = pEnte; 
       
       SELECT COUNT (*) INTO pMutuiScartati 
       FROM MIGR_VOCE_MUTUO_SCARTO
       where ente_proprietario_id = pEnte;

       pCodRes:=0;
       pMsgRes:= pMsgRes || 'Elaborazione OK.Voci di Mutuo inserite=' ||
                 cMutuiInseriti || ' scartate=' || cMutuiScartati || '.';

/*        
               for migrMutuo in (select v.nro_mutuo,v.nimp, v.annoimp, v.anno_esercizio, v.cod_azienda
                                 ,v.impoini as importo_iniziale
                                 ,v.impoatt as importo_attuale
                                 from imp_mutui v
                                 where v.anno_esercizio>=pAnnoEsercizio
                                 -- prendere solo quelli legati a mutui migrati (presenti nella migr_mutuo)
                                 and v.nro_mutuo in (select codice_mutuo from migr_mutuo m)
                                 )
                                    loop
                                      
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            msgRes := null;
                            h_imp_migrato := 0;
                            h_mutuo := 'Voce Mutuo nr mutuo ' || migrMutuo.nro_mutuo || '/'||migrMutuo.nimp|| '/'||migrMutuo.annoimp
                                    ||'/'||migrMutuo.anno_esercizio||'/'||migrMutuo.cod_azienda;
      
                            msgRes := 'Verifica impegno migrato.';
                            begin
                              select nvl(count(*), 0)
                                into h_imp_migrato
                                from migr_impegno
                               where anno_esercizio = migrMutuo.anno_esercizio
                                 and anno_impegno = migrMutuo.annoimp
                                 and numero_impegno = migrMutuo.nimp
                                 and ente_proprietario_id = pEnte;

                              if h_imp_migrato = 0 then
                                codRes := -1;
                                msgRes := 'Impegno non migrato.';
                                msgMotivoScarto := msgRes;
                              end if;

                            exception
                              when no_data_found then
                                codRes := -1;
                                h_imp_migrato  := 0;
                                msgRes          := 'Impegno non migrato.';
                                msgMotivoScarto := msgRes;
                              when others then
                                codRes := -1;
                                msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                            end;
                           

                            -- definizione tipo voce mutuo:
                            if migrMutuo.Importo_Iniziale=0 then 
                               h_tipo := '002';
                            elsif  migrMutuo.Annoimp<migrMutuo.Anno_Esercizio then
                               h_tipo := '003';
                            end if;

                            if codRes = 0 then
                              msgRes := 'Inserimento in migr_voce_mutuo.';
                              insert into migr_voce_mutuo 
                                (voce_mutuo_id
                                ,codice_voce_mutuo
                                ,nro_mutuo
                                ,importo_iniziale
                                ,importo_attuale
                                ,tipo_voce_mutuo
                                ,anno_impegno
                                ,numero_impegno
                                ,anno_esercizio
                                ,ente_proprietario_id)
                              values
                                (migr_voce_mutuo_id_seq.nextval,
                                 NULL,
                                 migrMutuo.Nro_Mutuo,
                                 migrMutuo.Importo_Iniziale,
                                 migrMutuo.Importo_Attuale,
                                 h_tipo,
                                 migrMutuo.Annoimp,
                                 migrMutuo.Nimp,
                                 migrMutuo.Anno_Esercizio,
                                 pEnte);
                              cMutuiInseriti := cMutuiInseriti + 1;
                            end if;
                            if codRes != 0 then
                              msgRes := 'Inserimento in migr_voce_mutuo_scarto.';
                              insert into migr_voce_mutuo_scarto
                                (voce_mutuo_scarto_id,
                                 nro_mutuo,
                                 numero_impegno,
                                 anno_impegno,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
                              values
                                (migr_voce_mutuo_scarto_id_seq.nextval,
                                 migrMutuo.nro_mutuo,
                                 migrMutuo.Nimp,
                                 migrMutuo.Annoimp,
                                 migrMutuo.Anno_Esercizio,
                                 msgMotivoScarto,
                                 pEnte);
                              cMutuiScartati := cMutuiScartati + 1;
                            end if;
                            if numMutuo >= 200 then
                              commit;
                              numMutuo := 0;
                            else
                              numMutuo := numMutuo + 1;
                            end if;
                      end loop;

    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Voci di Mutuo inserite=' ||
                 cMutuiInseriti || ' scartate=' || cMutuiScartati || '.';

    pMutuiScartati := cMutuiScartati;
    pMutuiInseriti := cMutuiInseriti;
    commit;
*/
  exception
    when others then
      dbms_output.put_line(h_mutuo || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_mutuo || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pMutuiScartati := cMutuiScartati;
      pMutuiInseriti := cMutuiInseriti;
      pCodRes      := -1;
      
  end migrazione_voce_mutuo;
  
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
        numInsert number := 0; --serve per contare i mutui e committare al 200esimo
        
        h_num number := 0;
        h_rec varchar2(50) := null;
        h_anno_provvedimento    varchar2(4)  := null;
        h_numero_provvedimento  varchar2(10) := null;
        h_tipo_provvedimento    varchar2(20) := null;
        h_stato_provvedimento   varchar2(5)  := null;
        h_oggetto_provvedimento varchar2(500):= null;
        h_note_provvedimento    varchar2(500):= null;
        h_descrizione           varchar2(500):= null;
        h_anno_esercizio_orig   varchar2(4)  := null;
        h_nliq_orig             number(10)   := null;
        h_data_ins_orig         varchar2(10) := null;
        h_codice_soggetto       number(6) := null; -- contiene il codice soggetto salvato sulla migr_liquidazione
        h_progben               number(3) := null; -- docquote.progben
        h_progdel               number(3) := null; -- docquote.progdel
        h_codben_pagamento      number(6) := null; -- documenti.codben_pagamento  se <> da codben liquidazione il record viene migrato ma 
                                                   -- inserito cmq. nella tabella di scarto.
        da_segnalare            number := 0;  -- true: il record è inserito in tab. scarto oltre che in  tab. migrazione 
                                              -- false: il record è inserito in tab.migrazione
        h_sogg_migrato          number := 0;
    
        h_sac_provvedimento     varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento
        
      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_liquidazione.Uno o più parametri in input non sono stati valorizzati correttamente';
            return;
        end if;

        -- pulizia delle tabelle migr_
        begin
            msgRes := 'Pulizia tabelle di migrazione liquidazione.';
            DELETE FROM MIGR_LIQUIDAZIONE WHERE FL_MIGRATO = 'N' and ente_proprietario_id = pEnte;
            DELETE FROM MIGR_LIQUIDAZIONE_SCARTO WHERE ente_proprietario_id = pEnte;
        exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        return;
        end;
           -- 06.05.2015
           -- non cosiderate le liquidazioni che non hanno impegno/subimpegno o, se definito, voce di mutuo/impegno non migrati.
           -- la verifica del soggetto migrato viene fatta dopo nel ciclo.
           for migrCursor in ( select distinct
                               l.nliq
                               , l.anno_esercizio
                               , l.descri descrizione
--                               , to_char(l.data_ins,'dd/MM/yyyy') data_emissione
                               , to_char(l.data_ins,'yyyy-MM-dd') data_emissione
                               , l.importo
                               , l.ex_liquidazione
                               , l.codben
                               , decode (l.staoper,'D','V',l.staoper) staoper
                               , l.annoprov
                               , l.nprov
                               , l.nimp
                               , l.nsubimp
                               , l.annoimp
                               , l.nro_mutuo
                               , mi.pdc_finanziario
                               , mi.cofog
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa       
                               , null as siope_spesa
    -- DAVIDE - 16.12.015 - Fine
                            from liquidazione l
                            --, migr_soggetto ms
                            , migr_impegno mi
                            where l.anno_esercizio = pAnnoEsercizio and l.staoper in ('D','P')
                            --and ms.ente_proprietario_id=pEnte
                            --and ms.codice_soggetto=l.codben -- verifica soggetto migrato
                            and mi.ente_proprietario_id=pEnte
                            and mi.numero_impegno= l.nimp -- verifica impegno/subimpegno migrato
                            and mi.numero_subimpegno=l.nsubimp
                            and mi.anno_impegno=l.annoimp
                            and mi.anno_esercizio=l.Anno_Esercizio 
                            and (
                              nro_mutuo is null 
                              or
                              exists (select 1 from migr_voce_mutuo vm
                                      where vm.ente_proprietario_id=pEnte
                                      and vm.nro_mutuo=l.nro_mutuo
                                      and vm.numero_impegno= l.nimp
                                      and vm.anno_impegno=l.annoimp
                                      and vm.anno_esercizio=l.anno_esercizio)
                               ))
                 loop
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            msgRes := null;
                            h_anno_provvedimento      := null;
                            h_numero_provvedimento    := null;
                            h_tipo_provvedimento      := null;
                            h_stato_provvedimento     := null;
                            h_oggetto_provvedimento   := null;
                            h_sogg_migrato            := 0;
                            h_note_provvedimento      := null;
                            h_codice_soggetto         := null;
                            h_progben                 := null; -- docquote.progben
                            h_progdel                 := null; -- docquote.progdel
                            h_codben_pagamento        := null; -- documenti.codben_pagamento
                            da_segnalare              := 0;
                                
                            h_sac_provvedimento       := null; -- DAVIDE - Gestione SAC Provvedimento

                            h_rec := 'Liquidazione ' || migrCursor.nliq || '/'||migrCursor.anno_esercizio||'.';
      
                            -- recupero progben e codben da quote e documenti
                            begin
                              select d.CODBEN_PAGAMENTO, q.PROGBEN, q.PROGDEL
                               into h_codben_pagamento,h_progben,h_progdel
                              from
                              docquote q
                              ,documenti d 
                              where q.nliq=migrCursor.nliq and q.anno_esercizio=migrCursor.anno_esercizio
                              and q.cod_azienda=1
                              and q.tipodoc=d.tipodoc
                              and q.annodoc=d.annodoc
                              and q.ndoc=d.ndoc
                              and q.codben=d.codben;
                              
                              -- se soggetto pagamento del doc <> soggetto della liq segnalare nello scarto, e migrare cmq.
                              if h_codben_pagamento <> migrCursor.codben then
                                da_segnalare := 1;
                                msgMotivoScarto := 'Codben documento <> codben liq.';
                              end if;
                            exception when no_data_found then
                                da_segnalare := 1;
                                msgMotivoScarto := 'Liquidazione non legata al doc.';
                              when too_many_rows then
                                da_segnalare := 1;
                                msgMotivoScarto := 'Impossibile determinare il doc associato.';
                              when others then
                                da_segnalare := 1;
                                msgMotivoScarto := 'Impossibile determinare il doc associato.';
                            end;
                            
                            -- verifica del soggetto migrato
                            msgRes := 'Verifica soggetto migrato.';
                            if h_codben_pagamento is null or h_codben_pagamento ='' then h_codice_soggetto := migrCursor.codben;
                            else h_codice_soggetto := h_codben_pagamento; end if;

                            begin
                              select nvl(count(*), 0)
                                into h_sogg_migrato
                                from migr_soggetto
                               where codice_soggetto = h_codice_soggetto
                               and   ente_proprietario_id=pEnte;
                              if h_sogg_migrato = 0 then
                                codRes := -1;
                                msgRes := msgRes||'Soggetto non migrato.';
                                msgMotivoScarto := msgRes;
                              end if;
                            exception
                              when no_data_found then
                                codRes := -1;
                                h_sogg_migrato  := 0;
                                msgRes          := msgRes|| 'Soggetto non migrato.';
                                msgMotivoScarto := msgRes;
                            end;
                            -- il soggetto non è stato migrato per lo stato?
                            if h_sogg_migrato = 0 then
                              begin
                                select nvl(count(*),0) into h_sogg_migrato
                                from fornitori
                                where codben=h_codice_soggetto and
                                      staoper in ('V','S');

                                if h_sogg_migrato = 0 then
                                  codRes := -1;
                                  msgRes  := msgRes || 'Soggetto non valido.';
                                  msgMotivoScarto := msgRes;
                                end if;
                              exception
                                when no_data_found then
                                  codRes := -1;
                                  h_sogg_migrato  := 0;
                                  msgRes          := msgRes || 'Soggetto non valido.';
                                  msgMotivoScarto := msgRes;
                                when others then
                                  codRes := -1;
                                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                              end;
                            end if;
                                                      
                            -- lettura dati provvedimento
                            if codRes = 0 then
                              msgRes := 'Lettura dati Provvedimento.';
                              -- il provvedimento DEVE essere presente per la liquidazione (la colonna nprov non accetta valori NULL)
                              h_anno_provvedimento   := migrCursor.annoprov;
                              h_numero_provvedimento := migrCursor.nprov;
                              leggi_provvedimento(h_anno_provvedimento,
                                                  h_numero_provvedimento,
                                                  pEnte,
                                                  codRes,
                                                  msgRes,
                                                  h_tipo_provvedimento,
                                                  h_oggetto_provvedimento,
                                                  h_stato_provvedimento,
                                                  h_note_provvedimento,
                                                  h_sac_provvedimento);    -- DAVIDE - Gestione SAC Provvedimento
                              if codRes = 0 then
                              -- DAVIDE 18.09.2015 - se tipo provvedimento = PROVV_AA diventa PROVV_ALG
                              if h_tipo_provvedimento = PROVV_AA then
                                 h_tipo_provvedimento := PROVV_ALG;
                              end if;
                              -- DAVIDE 18.09.2015 - fine
                                h_tipo_provvedimento := h_tipo_provvedimento || '||';
                              end if;
                            end if;

                            if codRes = 0 then
                              -- descrizione: se non valorizzata impostata a oggetto del provvedimento.
                              h_descrizione := migrCursor.descrizione;
                              if h_descrizione is null then
                                h_descrizione := h_oggetto_provvedimento;
                              end if;
    
                              -- identificazione della liquidazione di partenza, salveremo anno esercizio,numero,data emissione.
                              -- prima scrematura tra le liquidazioni legate a liq precedenti e no
                              h_nliq_orig := migrCursor.ex_liquidazione;
                              if h_nliq_orig is null or h_nliq_orig = 0 then
                                h_anno_esercizio_orig := migrCursor.anno_esercizio;
                                h_nliq_orig := migrCursor.nliq;
                                h_data_ins_orig := migrCursor.data_emissione;
                              end if;
  
                              msgRes := 'Inserimento in migr_liquidazione.';
                              insert into migr_liquidazione 
                              (liquidazione_id
                              ,numero_liquidazione
                              ,anno_esercizio
                              ,numero_liquidazione_orig
                              ,anno_esercizio_orig
                              ,descrizione
                              ,data_emissione
                              ,data_emissione_orig
                              ,importo 
                              ,codice_soggetto
                              ,codice_progben
                              ,codice_modpag_del
                              ,stato_operativo
                              ,anno_provvedimento
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
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa       
                              ,siope_spesa
    -- DAVIDE - 16.12.015 - Fine
                              )
                              values
                                (migr_liquidazione_id_seq.nextval,
                                 migrCursor.nliq,
                                 migrCursor.anno_esercizio,
                                 h_nliq_orig,
                                 h_anno_esercizio_orig,
                                 h_descrizione,
                                 migrCursor.data_emissione,
                                 h_data_ins_orig,
                                 migrCursor.importo,
                                 h_codice_soggetto,
                                 h_progben,
                                 h_progdel,
                                 migrCursor.staoper,
                                 h_anno_provvedimento,
                                 h_numero_provvedimento,
                                 h_tipo_provvedimento,
                                 h_sac_provvedimento,
                                 h_oggetto_provvedimento,
                                 h_note_provvedimento,
                                 h_stato_provvedimento,
                                 migrCursor.nimp,
                                 migrCursor.nsubimp,
                                 migrCursor.annoimp,
                                 migrCursor.Nro_Mutuo,
                                 migrCursor.pdc_finanziario,
                                 migrCursor.cofog,
                                 pEnte
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa       
                                 ,migrCursor.siope_spesa
    -- DAVIDE - 16.12.015 - Fine
                                 );
                              cLiqseriti := cLiqseriti + 1;
                            end if;

                            if (codRes != 0 or da_segnalare != 0) then
                              insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 fl_migrato,
                                 ente_proprietario_id)
                              values
                                (migr_liquid_scarto_id_seq.nextval,
                                 migrCursor.nliq,
                                 migrCursor.anno_esercizio,
                                 msgMotivoScarto,
                                 decode(da_segnalare,1,'S','N'), -- il record con fl_migrato = S è stato inserito anche nella migr_liquidazione.
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
    ( select l1.nliq,l1.anno_esercizio,to_char(l1.data_ins,'dd/MM/yyyy')
     from liquidazione l1 
     where l1.ex_liquidazione=0
     start with anno_esercizio=m.anno_esercizio and nliq= m.numero_liquidazione
     connect by nliq = prior ex_liquidazione and anno_esercizio = prior anno_esercizio-1)
    where m.numero_liquidazione!=m.numero_liquidazione_orig
    and m.ente_proprietario_id=pEnte;

    -- 06.05.2015 Gestione Scarti
    -- 1) scarti per soggetto non migrato.
    -- 26.06.2015 Migrazione soggetto verificata nel ciclo.
     /*insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
      select migr_liquid_scarto_id_seq.nextval, l.nliq, l.anno_esercizio, 'Soggetto non migrato',pEnte
      from liquidazione l
      where l.anno_esercizio = pAnnoEsercizio and l.staoper in ('D','P')
      and not exists (select 1 from migr_soggetto ms where ms.codice_soggetto=l.codben and ms.ente_proprietario_id=pEnte);*/
      
    -- 2) scarti per movimento non migrato.
      insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
      select migr_liquid_scarto_id_seq.nextval, l.nliq, l.anno_esercizio, 'Impegno non migrato',pEnte
      from liquidazione l
      where l.anno_esercizio = pAnnoEsercizio and l.staoper in ('D','P')
      and not exists (select 1 from migr_impegno mi where 
              mi.ente_proprietario_id=pEnte
              and mi.numero_impegno= nimp -- verifica impegno/subimpegno migrato
              and mi.numero_subimpegno=nsubimp
              and mi.anno_impegno=annoimp
              and mi.anno_esercizio=l.Anno_Esercizio)
       and not exists (select 1 from migr_liquidazione_scarto s where s.numero_liquidazione=l.nliq and s.anno_esercizio=l.anno_esercizio and s.ente_proprietario_id=pEnte);
    -- 3) scarti per mutuo non migrato.
      insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
      select migr_liquid_scarto_id_seq.nextval, l.nliq, l.anno_esercizio, 'Voce di mutuo non migrata.',pEnte
      from liquidazione l
      where l.anno_esercizio = pAnnoEsercizio and l.staoper in ('D','P')
      and nro_mutuo is not null 
      and not exists (select 1 from migr_voce_mutuo vm
                where vm.ente_proprietario_id=pEnte
                and vm.nro_mutuo=l.nro_mutuo
                and vm.numero_impegno= l.nimp
                and vm.anno_impegno=l.annoimp
                and vm.anno_esercizio=l.anno_esercizio)
      and not exists (select 1 from migr_liquidazione_scarto s where s.numero_liquidazione=l.nliq and s.anno_esercizio=l.anno_esercizio and s.ente_proprietario_id=pEnte);
    
    
    -- contiamo gli scarti ... 
    select count (*) into cLiqScartati from migr_liquidazione_scarto where ente_proprietario_id=pEnte;
    
    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Liquidazioni inserite=' ||
                 cLiqseriti || ' scartate=' || cLiqScartati || '.';

    pLiqScartati := cLiqScartati;
    pLiqInseriti := cLiqseriti;
    commit;

  exception
    when others then
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pLiqScartati := cLiqScartati;
      pLiqInseriti := cLiqseriti;
      pCodRes      := -1;
      
  END migrazione_liquidazione;
  
  
  procedure migrazione_doc_spesa(pEnte number,
                                 pAnnoEsercizio varchar2,
                                 pCodRes              out number,
                                 pDocInseriti         out number,
                                 pDocScartati         out number,
                                 pMsgRes              out varchar2)  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        numInsert number := 0;
        
        h_sogg_migrato number := 0;
        h_num number := 0;
        
        h_rec varchar2(750) := null;
        
        h_descri varchar2(500) := null;
        
        h_numero_registro_fatt number:=0;
        h_data_registro_fatt varchar2(10):=null;
        h_codfisc_pign varchar2(20):=null;
        h_codfisc_pign_ins varchar2(20):=null;
        h_partiva_pign varchar2(20):=null;
        h_codben_pign number:=0;
        h_codice_ufficio varchar2(20):=null;
        tipoScarto varchar2(3):=null;

        -- DAVIDE - Conversione Importi documenti
        h_Importo_Lordo number(15,2) :=0.0;
        -- DAVIDE - Fine

        ERROR_DOCUMENTO EXCEPTION;
        
      begin
        
        
        msgRes := 'Inizio migrazione documenti di spesa.';
        begin
            msgRes := 'Pulizia tabelle di migrazione documenti di spesa.';
            DELETE FROM migr_doc_spesa WHERE FL_MIGRATO = 'N' and ente_proprietario_id=pEnte;
            DELETE FROM migr_doc_spesa_scarto where  ente_proprietario_id=pEnte;
            
            exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               return;
        end;
        
        msgRes := 'Inizio ciclo di migrazione documenti di spesa.';
        for migrCursor in 
        (select            d.annodoc, d.ndoc,d.tipodoc,d.codben,nvl(d.codben_pagamento,0) codben_pagamento,
                           decode(d.statodoc,'IN','I',
                                             'LI','L',
                                             'PE','PE',
                                             'PL','PL',
                                             'VA','V',
                                             null) stato_documento,
                                   d.descri,d.oggetto_fornitura,
                                   to_char(d.datadoc,'YYYY-MM-DD') data_emissione,
                                   to_char(d.scadenza,'YYYY-MM-DD') data_scadenza,nvl(d.giorni,0) giorni,
                    -- DAVIDE - 10.02.016 - Attributi con date : formato da usare dd/mm/yyyy hh:mm:ss
                               --    to_char(d.data_scad_new,'YYYY-MM-DD') data_scadenza_new,
                                   to_char(d.data_scad_new,'dd/MM/yyyy hh:mm:ss') data_scadenza_new,
        -- DAVIDE - Conversione Importi documenti
                                   d.cod_valuta,
        -- DAVIDE - Fine
                                   d.importo_lordo,d.arrotondamento, 
                                   decode(d.cod_registro_iva,'00','00',
                                                             '77','77',
                                                             '99','99',
                                                             null) bollo, 
                    -- DAVIDE - 05.02.016 - Attributi con date : formato da usare dd/mm/yyyy hh:mm:ss
                                   --d.cod_ufficio, to_char(d.data_ins,'YYYY-MM-DD') data_ricezione,
                                   --to_char(d.dataprotoc,'YYYY-MM-DD') data_repertorio,d.nprotoc,
                                   --to_char(d.data_iniz_sosp,'YYYY-MM-DD') data_sospensione,
                                   --to_char(d.data_riatt_sosp,'YYYY-MM-DD') data_riattivazione,
                                   d.cod_ufficio, to_char(d.data_ins,'dd/MM/yyyy hh:mm:ss') data_ricezione,
                                   to_char(d.dataprotoc,'dd/MM/yyyy hh:mm:ss') data_repertorio,d.nprotoc,
                    -- DAVIDE - 05.02.016 - Gestire nuovo campo anno_repertorio               
                                   SUBSTR( to_char(d.dataprotoc,'dd/MM/yyyy'), 7 , 4 ) anno_repertorio,
                                   to_char(d.data_iniz_sosp,'dd/MM/yyyy hh:mm:ss') data_sospensione,
                                   to_char(d.data_riatt_sosp,'dd/MM/yyyy hh:mm:ss') data_riattivazione,
                                   decode(d.fl_ati ,'S','ATI','R','RTI',null) tipo_impresa,
                                   d.utente_ins, d.utente_agg
          from documenti d
          where d.statodoc not in ('EM', 'AN', 'ST','RT')
            and d.cod_errore is null
            and d.annodoc>'1900'
          order by d.annodoc,d.tipodoc,d.codben,d.ndoc)
          loop
                                      
                            -- inizializza variabili
                            codRes := 0;
                            msgMotivoScarto  := null;
                            msgRes := null;
                            h_sogg_migrato := 0;
                            h_num := 0;
                            h_numero_registro_fatt:=0;
                            h_data_registro_fatt:=null;
                            h_codfisc_pign:=null;
                            h_codfisc_pign_ins:=null;
                            h_partiva_pign:=null;
                            h_codben_pign:=0;
                            h_codice_ufficio:=null;
                            h_descri:=null;
                            tipoScarto:=null;
                            
                            h_rec := 'Documento  ' || migrCursor.annodoc || '/'||migrCursor.ndoc||' tipo '||migrCursor.tipodoc||
                                     ' Soggetto '||migrCursor.Codben||'.';
      
                            -- DAVIDE - 05.02.016 - aggiunto scarto per fattura negativa
                            -- se importo negativo e tipo = F scarto il documento
                            msgRes := 'Verifica importo fattura.';
                            if migrCursor.tipodoc='F' and migrCursor.importo_lordo <0 then
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
                                      tipoScarto:='SNM';
                                    when others then
                                      codRes := -1;
                                      msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                                end;

                                if h_sogg_migrato = 0 and codRes!=-1 then
                                    begin
                                        select nvl(count(*),0) into h_num
                                          from fornitori
                                         where codben=migrCursor.codben and
                                               staoper in ('V','S'); 

                                        if h_num = 0 then
                                            codRes := -2;
                                            msgRes  := msgRes || 'Soggetto non valido.';
                                            msgMotivoScarto := msgRes;
                                            tipoScarto:='SNV';
                                        end if;
                                    exception
                                        when no_data_found then
                                          codRes := -2; 
                                          h_sogg_migrato  := 0;
                                          h_num           := 0;
                                          msgRes          := msgRes || 'Soggetto non valido.';
                                          msgMotivoScarto := msgRes;
                                          tipoScarto:='SNV';
                                        when others then
                                          codRes := -1;
                                          msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                                    end;
                                end if;
                            
                                h_sogg_migrato := 0;
                                h_num := 0;
                                if migrCursor.codben_pagamento!=0 and migrCursor.codben_pagamento!=migrCursor.codben and 
                                    codRes=0 then 
                                    msgRes := 'Verifica soggetto pagamento migrato.';
                                    begin
                                        select nvl(count(*), 0)
                                          into h_sogg_migrato
                                          from migr_soggetto
                                         where codice_soggetto = migrCursor.codben_pagamento
                                         and   ente_proprietario_id=pEnte;

                                        if h_sogg_migrato = 0 then
                                            codRes := -2;
                                            msgRes := msgRes||'Soggetto pagamento non migrato.';
                                            msgMotivoScarto := msgRes;
                                            tipoScarto:='SPN';
                                        end if;

                                    exception
                                        when no_data_found then
                                          codRes := -2;
                                          h_sogg_migrato  := 0;
                                          msgRes          := msgRes||'Soggetto pagamento non migrato.';
                                          msgMotivoScarto := msgRes;
                                          tipoScarto:='SPN';
                                        when others then
                                          codRes := -1;
                                          msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                                    end;

                                    if h_sogg_migrato = 0 and codRes!=-1 then
                                        begin
                                            select nvl(count(*),0) into h_num
                                              from fornitori
                                             where codben=migrCursor.codben_pagamento and
                                                   staoper in ('V','S'); 

                                            if h_num = 0 then
                                                codRes:=-2;
                                                msgRes  := msgRes || 'Soggetto pagamento non valido.';
                                                msgMotivoScarto := msgRes;
                                                tipoScarto:='SPV';
                                            end if;
                                        exception
                                            when no_data_found then
                                              codRes:=-2;
                                              h_sogg_migrato  := 0;
                                              h_num           := 0;
                                              msgRes          := msgRes || 'Soggetto pagamento non valido.';
                                              msgMotivoScarto := msgRes;
                                              tipoScarto:='SPV';
                                            when others then
                                              codRes:=-1;
                                              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                                        end;
                                    end if;   
                            
                                    if codRes=0 then
                                        codRes:=-2;
                                        msgRes := msgRes || 'Soggetto pagamento indicato.';
                                        msgMotivoScarto := msgRes;
                                        tipoScarto:='SPI';
                                    end if; 
                                end if; 
                            end if;      

                           -- registro_iva 
                           if codRes=0 then
                           
                            msgRes:='Lettura registro unico fatture.';
                            begin
                             select r.numero_registro ,  to_char(r.data_registro,'YYYY-MM-DD')
                                   into h_numero_registro_fatt,h_data_registro_fatt
                             from registro_fatture r
                             where r.annodoc=migrCursor.annodoc
                             and   r.ndoc=migrCursor.ndoc
                             and   r.tipodoc=migrCursor.Tipodoc
                             and   r.codben=migrCursor.codben;
                             exception
                                when no_data_found then
                                  null;
                                when others then
                                  codRes:=-1;
                                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                            end;
                          end if;
                          
                          -- pignoramento  
                          if codRes=0 then
                            msgRes:='Lettura soggetto pignorato.';
                            begin
                             select r.codfisc , nvl(r.partiva,'XX')
                             into h_codfisc_pign,h_partiva_pign
                             from pignoramento r
                             where r.annodoc=migrCursor.annodoc
                             and   r.ndoc=migrCursor.ndoc
                             and   r.tipodoc=migrCursor.Tipodoc
                             and   r.codben=migrCursor.codben;
                             
                             h_codfisc_pign_ins:=h_codfisc_pign;
                             
                             if h_codfisc_pign is null then
                               h_codfisc_pign:='XX';
                             end if;
                               
                             msgRes:='Lettura anagrafica soggetto pignorato.';
                             begin
                               select f.codben into h_codben_pign
                               from fornitori f
                               where f.staoper in ('V','S') 
                               and  ( f.codfisc=h_codfisc_pign or f.partiva=h_partiva_pign);
                               
                               msgRes:='Verifica soggetto pignorato migrato.';
                               h_sogg_migrato:=0;
                               begin
                                select nvl(count(*), 0)
                                into h_sogg_migrato
                                from migr_soggetto
                                where codice_soggetto = h_codben_pign
                                and   fl_genera_codice='N';
 
                                if h_sogg_migrato = 0 then
                                 codRes := -2;
                                 msgRes := 'Soggetto pignorato non migrato.';
                                 msgMotivoScarto := msgRes;
                                 tipoScarto:='SPG';
                                end if;

                                exception
                                 when no_data_found then
                                  codRes := -2;
                                  h_sogg_migrato  := 0;
                                  msgRes          := msgRes||'Soggetto pignorato non migrato.';
                                  msgMotivoScarto := msgRes;
                                  tipoScarto:='SPG';
                                 when others then
                                  codRes := -1;
                                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                                end;
                               
                               exception
                                when no_data_found then
                                  codRes:=-2;
                                  msgRes  := msgRes || 'Soggetto pignorato non valido o non esistente.';
                                  msgMotivoScarto := msgRes;
                                  tipoScarto:='SPG';
                                when TOO_MANY_ROWS then
                                  codRes:=-2;
                                  msgRes  := msgRes || 'Soggetto pignorato non univoco per codFisc='||
                                             h_codfisc_pign||' o partitaIva='||h_partiva_pign||'.';
                                  msgMotivoScarto := msgRes;  
                                  tipoScarto:='SPG';
                                when others then
                                  codRes:=-1;
                                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                                  
                             end;
                             
                             exception
                                when no_data_found then
                                  null;
                                when others then
                                  codRes:=-1;
                                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                            end;
                            
                          end if;  
                          
                          -- tab_cod_uffici
                          msgRes:='Lettura codicePcc codice ufficio.';
                          if codRes=0 and migrCursor.cod_ufficio is not null then
                            begin
                             select distinct t.codice_ipa into h_codice_ufficio
                             from tab_cod_uffici t
                             where t.anno_esercizio=pAnnoEsercizio
                             and   t.cod_ufficio=migrCursor.Cod_Ufficio
                             and t.codice_ipa is not null;
                             
                             exception
                                when no_data_found then
                                  codRes:=-2;
                                  msgRes  := msgRes || 'Codice Ufficio non presente in tab_cod_uffici.';
                                  msgMotivoScarto := msgRes;
                                  tipoScarto:='UFF';
                                when others then
                                  codRes:=-1;
                                  msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                           end;       
                          end if;
                             
                          if codRes=0 then
                             if migrCursor.Oggetto_Fornitura is not null then
                                  h_descri:=migrCursor.Oggetto_Fornitura;
                             else h_descri:=migrCursor.Descri;
                             end if;
                          end if;
                                                      
    
                           if codRes = 0 then
                              -- DAVIDE - Conversione dell'importo in Euro 
                              if migrCursor.Importo_Lordo > 0 and migrCursor.cod_valuta <> '01' then
                                  h_Importo_Lordo := migrCursor.Importo_Lordo / RAPPORTO_EURO_LIRA;
                              else 
                                  h_Importo_Lordo := migrCursor.Importo_Lordo;
                              end if;
                              -- DAVIDE - Fine

                              msgRes := 'Inserimento in migr_doc_spesa.';
                              insert into migr_doc_spesa 
                              (docspesa_id,
                               tipo,
                               anno,
                               numero,
                               codice_soggetto,
                               codice_soggetto_pag,
                               stato,
                               descrizione,
                               date_emissione,
                               data_scadenza,
                               data_scandenza_new,
                               termine_pagamento,
                               importo,
                               arrotondamento,
                               bollo,
                               codice_pcc,
                               codice_ufficio,
                               data_ricezione,
                               data_repertorio,
                               numero_repertorio,
                -- DAVIDE - 05.02.016 - Gestire nuovo campo anno_repertorio               
                               anno_repertorio,
                               note,
                               causale_sospensione,
                               data_sospensione,
                               data_riattivazione,
                               codice_fiscale_pign,
                               tipo_impresa,
                               data_registro_fatt,
                               numero_registro_fatt,
                               utente_creazione,
                               utente_modifica,
                               ente_proprietario_id,
                               collegato_cec)
                              values
                              (migr_doc_spesa_id_seq.nextval,
                               migrCursor.tipodoc,
                               migrCursor.annodoc,
                               migrCursor.ndoc,
                               migrCursor.codben,
                               migrCursor.codben_pagamento,
                               migrCursor.stato_documento,
                               h_descri,
                               migrCursor.data_emissione,
                               migrCursor.data_scadenza,
                               migrCursor.Data_Scadenza_New,
                               migrCursor.Giorni,
                        -- DAVIDE - Conversione dell'importo in Euro 
                               --migrCursor.Importo_Lordo,
                               h_Importo_Lordo,
                        -- DAVIDE - Fine 
                               migrCursor.Arrotondamento,
                               migrCursor.bollo,
                               migrCursor.Cod_Ufficio,
                               h_codice_ufficio,
                               migrCursor.Data_Ricezione,
                               migrCursor.Data_Repertorio,
                               migrCursor.Nprotoc,
                           -- DAVIDE - 05.02.016 - Gestire nuovo campo anno_repertorio               
                               migrCursor.anno_repertorio,
                               '','',
                               migrCursor.Data_Sospensione,
                               migrCursor.Data_Riattivazione,
                               h_codfisc_pign_ins,
                               migrCursor.Tipo_Impresa,
                               h_data_registro_fatt,
                               h_numero_registro_fatt,
                               migrCursor.Utente_Ins,
                               migrCursor.Utente_Agg,
                               pEnte,
                               'N');
                              cDocInseriti := cDocInseriti + 1;
                            end if;

                            if codRes = -2 then
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
                               migrCursor.Tipodoc,
                               migrCursor.Annodoc,
                               migrCursor.Ndoc,
                               migrCursor.Codben,
                               msgMotivoScarto,
                               tipoScarto,
                               pEnte);
                               
                              cDocScartati := cDocScartati + 1;
                            end if;
                              
                            if codRes=-1 then
                               raise ERROR_DOCUMENTO;  
                            end if;

                            if numInsert >= N_BLOCCHI_DOC then
                              commit;
                              numInsert := 0;
                            else
                              numInsert := numInsert + 1;
                            end if;
   end loop;

    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Documenti di spesa inseriti=' ||
                 cDocInseriti || ' scartati=' || cDocScartati || '.';

    pDocScartati := cDocScartati;
    pDocInseriti := cDocInseriti;
    commit;

  exception
    when ERROR_DOCUMENTO then
     dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes );
      pMsgRes      := pMsgRes || h_rec || msgRes ;
      pDocScartati := cDocScartati;
      pDocInseriti := cDocInseriti;
      pCodRes      := -1; 
    when others then
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pDocScartati := cDocScartati;
      pDocInseriti := cDocInseriti;
      pCodRes      := -1;
      
  END migrazione_doc_spesa;


  procedure migrazione_docquo_spesa(pEnte number,
                                    pAnnoEsercizio varchar2,
                                    pCodRes              out number,
                                    pDocInseriti         out number,
                                    pDocScartati         out number,
                                    pMsgRes              out varchar2)  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        numInsert number := 0;
        
        h_sogg_migrato number := 0;
        h_num number := 0;
        
        h_rec varchar2(750) := null;
        
        h_note varchar2(500) := null;
        
        h_anno_provvedimento    varchar2(4) := null;
        h_numero_provvedimento  varchar2(10) := null;
        h_tipo_provvedimento    varchar2(20) := null;
        h_stato_provvedimento   varchar2(5) := null;
        h_oggetto_provvedimento varchar2(500) := null;
        h_note_provvedimento    varchar2(500) := null;
        
        h_annotazioni_dl35 varchar2(500) := null;
        -- DAVIDE - 10.02.016 - Attributi con date : formato da usare dd/mm/yyyy hh:mm:ss
        --h_data_dl35 varchar2(10) := null;
        h_data_dl35 varchar2(19) := null;
        h_note_dl35 varchar2(500) := null;
        h_numero_dl35 varchar2(50) := null;
        h_flag_dl35    varchar2(1) :=null;
        h_importo number:=0;
        h_importo_da_dedurre number:=0;
        h_modpag number:=0;
        h_modpag_del number:=0;        
        
        h_sede_secondaria varchar2(1):='N';
        h_codice_indirizzo number:=0;
        h_fl_genera_codice varchar2(1):='N';
        h_codice_soggetto number:=0;
        h_count_sede number:=0;
        h_soggetto_id number:=0;

        tipoScarto varchar2(3):=null;

        -- DAVIDE - Conversione Importi quote
        h_Importo_quote number(15,2) :=0.0;
        h_Importo_quote_da_dedurre number(15,2) :=0.0;
        -- DAVIDE - Fine
    
        h_sac_provvedimento     varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento

        ERROR_DOCUMENTO EXCEPTION;
        
        h_tipoIva varchar2(2) := null;
      begin

        msgRes := 'Inizio migrazione quote documenti di spesa.';
        begin
            msgRes := 'Pulizia tabelle di migrazione quote documenti di spesa.';
            DELETE FROM migr_docquo_spesa WHERE FL_MIGRATO = 'N' and   ente_proprietario_id=pEnte;
            DELETE FROM migr_docquo_spesa_scarto where ente_proprietario_id=pEnte;
            UPDATE migr_doc_spesa set fl_scarto='N'
            where fl_migrato='N'
            and   fl_scarto='S'
            and   ente_proprietario_id=pEnte;
            
            commit;
            
            exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               return;
        end;
        
    begin    
     msgRes:='Gestione scarti quote documenti spesa per impegno non migrato.'; 
         insert into migr_docquo_spesa_scarto
         (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,
      ente_proprietario_id)
          (select migr_docquo_spe_scarto_id_seq.nextval,q.tipodoc,q.annodoc,q.ndoc,q.codben,q.frazione,
            'Impegno '||q.annoimp||'/'||q.nimp||' anno_esercizio '||q.anno_esercizio||' non migrato.','IMP',pEnte
      from docquote q, migr_doc_spesa m
      where q.cod_azienda=1
        and q.tipodoc=m.tipo
        and q.annodoc=m.anno
        and q.ndoc=m.numero
        and q.codben=m.codice_soggetto
        and m.ente_proprietario_id=pEnte
        and nvl(q.nimp,0)!=0
        and nvl(q.nsubimp,0)=0
        and nvl(q.nmand,0)=0
        and 0=(select count(*) from migr_impegno mi
                 where mi.numero_impegno=q.nimp
                   and mi.anno_impegno=q.annoimp
                   and mi.anno_esercizio=pAnnoEsercizio
                   and mi.tipo_movimento='I'
                   and mi.ente_proprietario_id=pEnte)
     );
     commit;
       
     msgRes:='Gestione scarti quote documenti spesa per subimpegno non migrato.';  
     insert into migr_docquo_spesa_scarto
         (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,
      ente_proprietario_id)
          (select migr_docquo_spe_scarto_id_seq.nextval,q.tipodoc,q.annodoc,q.ndoc,q.codben,q.frazione,
            'SubImpegno '||q.annoimp||'/'||q.nimp||'/'||q.nsubimp||' anno_esercizio '||q.anno_esercizio||' non migrato.','SIM',pEnte
      from docquote q, migr_doc_spesa m
      where q.cod_azienda=1
        and q.tipodoc=m.tipo
        and q.annodoc=m.anno
        and q.ndoc=m.numero
        and q.codben=m.codice_soggetto
        and m.ente_proprietario_id=pEnte
        and nvl(q.nimp,0)!=0        
        and nvl(q.nsubimp,0)!=0
        and nvl(q.nmand,0)=0
        and 0=(select count(*) from migr_impegno mi
                 where mi.numero_impegno=q.nimp
                   and mi.numero_subimpegno=q.nsubimp
                   and mi.anno_impegno=q.annoimp
                   and mi.anno_esercizio=pAnnoEsercizio
                   and mi.tipo_movimento='S'
                   and mi.ente_proprietario_id=pEnte)
       );
      commit;
      
     msgRes:='Gestione scarti quote documenti spesa per liquidazione non migrata.';  
     insert into migr_docquo_spesa_scarto
         (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,
      ente_proprietario_id)
          (select migr_docquo_spe_scarto_id_seq.nextval,q.tipodoc,q.annodoc,q.ndoc,q.codben,q.frazione,
            'Liquidazione '||q.nliq||' anno_esercizio '||q.anno_esercizio||' non migrata.','LIQ',pEnte
      from docquote q, migr_doc_spesa m
      where q.cod_azienda=1
        and q.tipodoc=m.tipo
        and q.annodoc=m.anno
        and q.ndoc=m.numero
        and q.codben=m.codice_soggetto
        and m.ente_proprietario_id=pEnte
        and nvl(q.nliq,0)!=0
        and nvl(q.nmand,0)=0
        and 0=(select count(*) from migr_liquidazione mi
                 where mi.numero_liquidazione=q.nliq
                   and mi.anno_esercizio=pAnnoEsercizio
                   and mi.ente_proprietario_id=pEnte)
       );
      commit;
      
      msgRes:='Gestione scarti quote documenti spesa-aggiornamento migr_doc_spesa prima ciclo.';
      update migr_doc_spesa m set m.fl_scarto='S'
      where 0!=(select count(*) from  migr_docquo_spesa_scarto mq
                where mq.anno=m.anno
                  and mq.numero=m.numero
                  and mq.tipo=m.tipo 
                  and mq.codice_soggetto=m.codice_soggetto
                  and mq.ente_proprietario_id=pEnte)
      and   m.ente_proprietario_id=pEnte;
      commit;
                   
     exception 
       when others then
            rollback;
            pCodRes := -1;
            pMsgRes := msgRes || 'Errore ' ||
            SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            return;  
    end;   
                  
        msgRes := 'Inizio ciclo di migrazione quote documenti di spesa.';
        for migrCursor in 
        (select m.docspesa_id,q.annodoc, q.ndoc, q.tipodoc,q.codben, nvl(d.codben_pagamento,0) codben_pagamento,
                q.frazione, nvl(q.progben,0) modpag_quota, nvl(q.progdel,0) modpag_del_quota, 
                nvl(d.cod_indir,0) codice_indirizzo,
                nvl(d.progben,0) modpag_doc, nvl(d.progdel,0) modpag_del_doc,
        -- DAVIDE - Conversione Lira / Euro
                d.cod_valuta,
        -- DAVIDE - Fine
                nvl(q.impquota,0) importo,nvl(q.importo_debito_orig,0) importo_debito_orig,
                q.anno_esercizio,q.annoimp,nvl(q.nimp,0) nimp,nvl(q.nsubimp,0) nsubimp,
                nvl(q.nliq,0) nliq,nvl(q.nmand,0) nmand,
                q.annoprov,nvl(q.nprov,0) nprov,
        -- DAVIDE - 05.02.016 - Descrizione /datascadenza della quota doc , se non presente valorizzare con dati doc
                --q.descri,
                nvl(q.descri,d.descri) as descri,
                         nvl(q.niva,0) niva, decode(nvl(q.niva,0),0,'N','S') flag_rilevante_iva,
                --to_char(q.scadenza,'YYYY-MM-DD') data_scadenza,
                to_char(nvl(q.scadenza,d.scadenza),'YYYY-MM-DD') data_scadenza,
        -- DAVIDE - 10.02.016 - Attributi con date : formato da usare dd/mm/yyyy hh:mm:ss
                --to_char(q.data_scad_new,'YYYY-MM-DD') data_scadenza_new,
                to_char(nvl(q.data_scad_new,d.data_scad_new),'dd/MM/yyyy hh:mm:ss') data_scadenza_new,
                q.cup,q.cig,
                decode(d.fl_commissioni,'B','BN',
                                        'C','CE',
                                        'E','ES',null) commissioni,
        -- DAVIDE - 10.02.016 - Attributi con date : formato da usare dd/mm/yyyy hh:mm:ss
               --to_char(q.data_iniz_sosp,'YYYY-MM-DD') data_sospensione,
               --to_char(q.data_riatt_sosp,'YYYY-MM-DD') data_riattivazione,
               to_char(q.data_iniz_sosp,'dd/MM/yyyy hh:mm:ss') data_sospensione,
               to_char(q.data_riatt_sosp,'dd/MM/yyyy hh:mm:ss') data_riattivazione,
               nvl(q.flag_mand_singolo,'N') flag_mand_singolo ,
               decode(q.fl_avviso,'S','S','P','S','N') flag_avviso,
               decode(q.fl_avviso,'S','TESORIERE','P','TESORIERE','N',null) tipo_avviso,
               nvl(q.fl_esproprio,'N') fl_esproprio, 
               --decode(nvl(q.nliq,0),0,'N',decode(nvl(q.nmand,0),0,'S','N')) fl_manuale,
        -- DAVIDE - 26.02.016 - flag_manuale impostato come in REGP - salvato su campo siac_t_subdoc.subdoc_convalida_manuale
               --nvl(q.fl_manuale,'N') fl_manuale,
               NULL as fl_manuale,
               d.note_tesoriere,
               d.descri causale_ordinativo,
               nvl(q.nro_mutuo,0) nro_mutuo,
               q.utente_ins, q.utente_agg,
               q.reverse_charge, -- IMPORTO SPLIT REVERSE
               q.NO_SPLIT, -- R - REVERSE CHARGE / S: NO SPLIT -> ESENZIONE / N: SPLIT DEDURRE DA RILEV_IVA
               cap.RILEV_IVA -- N/NULL IVA ISTITUZIONALE , S IVA COMMERCIALE
          from docquote q, documenti d, migr_doc_spesa m
               , impegni imp, cap_uscita cap          
          where d.statodoc not in ('EM', 'AN', 'ST','RT')
            and d.cod_errore is null
            and d.annodoc>'1900'
            and q.cod_azienda=1
            and q.tipodoc=d.tipodoc
            and q.annodoc=d.annodoc
            and q.ndoc=d.ndoc
            and q.codben=d.codben
            and m.anno=d.annodoc
            and m.numero=d.ndoc
            and m.tipo=d.tipodoc
            and m.codice_soggetto=d.codben
            and m.fl_scarto='N'
            and m.ente_proprietario_id=pEnte
            and q.anno_esercizio=imp.anno_esercizio(+)
            and q.annoimp=imp.annoimp(+)
            and q.nimp = imp.nimp(+)
            and imp.anno_esercizio=cap.anno_esercizio(+)
            and imp.nro_capitolo=cap.nro_capitolo(+)
            and imp.nro_articolo=cap.nro_articolo(+)
          order by q.annodoc,q.tipodoc,q.codben,q.ndoc,q.frazione)
          loop
                                      
                -- inizializza variabili
                codRes := 0;
                msgMotivoScarto  := null;
                msgRes := null;
                h_sogg_migrato := 0;
                h_num := 0;
                h_anno_provvedimento:=null;
                h_numero_provvedimento:=null;
                h_tipo_provvedimento:=null;
                h_stato_provvedimento:=null;
                h_oggetto_provvedimento:=null;
                h_note_provvedimento:=null;
                h_annotazioni_dl35:=null;
                h_data_dl35:=null;
                h_note_dl35:=null;
                h_numero_dl35:=null;
                h_flag_dl35:=null;
                h_importo:=0;
                h_importo_da_dedurre:=0;
                h_modpag:=0;
                h_modpag_del:=0;
                h_sede_secondaria:='N';
                h_codice_indirizzo:=0;
                h_fl_genera_codice:='N';
                h_note:=null;
                h_codice_soggetto :=0;            
                h_count_sede :=0;
                h_soggetto_id :=0;
                h_tipoIva := null;
    
                h_sac_provvedimento  := null; -- DAVIDE - Gestione SAC Provvedimento
                
                tipoScarto:=null;
                
                h_rec := 'Documento  ' || migrCursor.annodoc || '/'||migrCursor.ndoc||' tipo '||migrCursor.tipodoc||
                         ' Soggetto '||migrCursor.Codben||': frazione '||migrCursor.frazione||'.';

            -- DAVIDE - 05.02.016 - aggiunto scarto per fattura negativa
                -- se importo negativo e tipo = F scarto il documento
                msgRes := 'Verifica importo quota fattura.';
                if migrCursor.tipodoc='F' and migrCursor.importo <0 then
                    msgRes          := msgRes|| 'Importo negativo.';
                    msgMotivoScarto := msgRes;
                    tipoScarto:='FN';-- fattura negativa
                    codRes := -1;
                end if;
                
               -- soggetto e soggetto pagamento
               -- non si ripetono qui i controlli sui soggetti perche gia fatti sul documento
 
                           -- provvedimento
                           
                if codRes=0 and migrCursor.nprov!=0 then

                    h_anno_provvedimento   := migrCursor.annoprov;
                    h_numero_provvedimento := migrCursor.nprov;
                  
                    leggi_provvedimento(h_anno_provvedimento,
                                        h_numero_provvedimento,
                                        pEnte,
                                        codRes,
                                        msgRes,
                                        h_tipo_provvedimento,
                                        h_oggetto_provvedimento,
                                        h_stato_provvedimento,
                                        h_note_provvedimento,
                                        h_sac_provvedimento);    -- DAVIDE - Gestione SAC Provvedimento

                    if codRes = 0 then
                        h_tipo_provvedimento := h_tipo_provvedimento || '||';
                         -- capire se e come gestire lo stato del provvedimento
                    end if;
            -- DAVIDE - 22.02.016 - aggiunta gestione scarto per provvedimento non trovato 
                    if codRes = -2 then
                        msgMotivoScarto := msgRes;
                        tipoScarto:='PNT';
                    end if;
                end if;
                
                -- docquote_dl35
                if codRes=0 then
                    msgRes:='Dati certificazioni crediti.';
                    begin
        -- DAVIDE - 10.02.016 - Attributi con date : formato da usare dd/mm/yyyy hh:mm:ss
                      --  select r.annotazioni ,  to_char(r.data_cert,'YYYY-MM-DD'),
                        select r.annotazioni ,  to_char(r.data_cert,'dd/MM/yyyy hh:mm:ss'),
                               r.note_dl35,r.numero_cert , r.fl_certificabile
                          into h_annotazioni_dl35,h_data_dl35,h_note_dl35,h_numero_dl35, h_flag_dl35
                          from docquote_dl35 r
                         where r.annodoc=migrCursor.annodoc
                         and   r.ndoc=migrCursor.ndoc
                         and   r.tipodoc=migrCursor.Tipodoc
                         and   r.codben=migrCursor.codben
                         and   r.frazione=migrCursor.frazione;
                     
                    exception
                        when no_data_found then
                          null;
                        when others then
                          codRes:=-1;
                          msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                    end;
                end if;
                
                -- verifica MDP
                if codRes=0 then
                    -- se quota pagata non migriamo il collegamento con la MDP
                    -- se la quota è incompleta ( non vi sono le imputazioni contabili ) non migriamo il collegamento con la MDP
                    if migrCursor.Nmand=0 and migrCursor.nimp!=0 then
                        if migrCursor.Modpag_Quota!=0 then
                            h_modpag:=migrCursor.Modpag_Quota;
                            h_modpag_del:=migrCursor.Modpag_del_Quota;
                        else
                            h_modpag:=migrCursor.Modpag_doc;
                            h_modpag_del:=migrCursor.Modpag_Del_Doc;
                        end if;
                    end if;   
                  
                    if migrCursor.Codben_Pagamento!=migrCursor.codben then
                        h_codice_soggetto:=migrCursor.Codben_Pagamento;
                    else
                        h_codice_soggetto:=migrCursor.Codben;
                    end if;
                  
                    -- h_codice_indirizzo lo valorizzo solo se sede_secondaria='S'
                    --if   migrCursor.Codice_Indirizzo!=0 then
                    -- h_codice_indirizzo:=migrCursor.Codice_Indirizzo;
                    -- end if;
                  
                    if h_modpag_del=0  and h_modpag!=0 then -- DELEGATO NO !
                        begin    
                            msgRes:='Verifica migrazione MDP codice_soggetto='||h_codice_soggetto||' modpag='||h_modpag||'.';
                            select  m.sede_secondaria, mo.soggetto_id into h_sede_secondaria, h_soggetto_id
                              from migr_modpag m, migr_soggetto mo
                             where  mo.codice_soggetto=h_codice_soggetto  
                             and   (mo.delegato_id <1 or mo.delegato_id is null)
                             and   mo.fl_genera_codice='N'
                             and   mo.ente_proprietario_id=pEnte
                             and   m.soggetto_id=mo.soggetto_id
                             and   m.codice_modpag=h_modpag
                             and   m.fl_genera_codice='N'
                             and   (m.delegato_id <1 or m.delegato_id is null)
                             and   m.ente_proprietario_id=pEnte;
                      
                            --- verifica coerenza con indirizzo se presente
                            if h_sede_secondaria='S' then
                                begin
                                    msgRes:='Verifica migrazione SEDE SEC. per  MDP codice_soggetto='||h_codice_soggetto||' modpag='||h_modpag||'.';  
                                    select nvl(count(*),0) into h_count_sede
                                      from migr_sede_secondaria s
                                     where  s.soggetto_id=h_soggetto_id
                                       and  s.codice_modpag=h_modpag
                                       and  s.codice_indirizzo=migrCursor.Codice_Indirizzo
                                       and  s.ente_proprietario_id=pEnte;
                          
                                    if h_count_sede=0 then
                                        h_codice_indirizzo:=0;
                                        --h_sede_secondaria:='N';
                                    else         
                                        h_codice_indirizzo:= migrCursor.Codice_Indirizzo;  
                                    end if;   
                                exception
                                        when no_data_found then
                                          --codRes:=-2;
                                          --msgRes := msgRes || 'SEDE non migrata.';
                                          --msgMotivoScarto := msgRes;
                                          h_codice_indirizzo:=0;
                                          h_sede_secondaria:='N';
                                        when others then
                                          codRes:=-1;
                                         msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';  
                            
                                end;
                            else h_codice_indirizzo:=0;
                            end if;
                      
                        exception
                            when no_data_found then
                              codRes:=-2;
                              msgRes := msgRes || 'MDP non migrata.';
                              msgMotivoScarto := msgRes;
                              tipoScarto:='MND';
                            when others then
                              codRes:=-1;
                              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        end;
                     
                    end if;  

                    if codRes=0 and h_modpag_del!=0 and h_modpag!=0 then -- DELEGATO SI MA NO CESSIONE
                        begin    
                            msgRes:='Verifica migrazione MDP codice_soggetto='||h_codice_soggetto
                                    ||' modpag='||h_modpag||' modpag_del='||h_modpag_del||'.';
                            -- select  m.sede_secondaria, mo.fl_genera_codice ,mo.soggetto_id
                            select  m.sede_secondaria, mo.soggetto_id
                           -- into h_sede_secondaria, h_fl_genera_codice,h_soggetto_id
                              into h_sede_secondaria, h_soggetto_id
                              from migr_modpag m, migr_soggetto mo
                             where mo.codice_soggetto=h_codice_soggetto
                             --and   mo.fl_genera_codice='N' 
                               and   mo.ente_proprietario_id=pEnte
                               and   m.soggetto_id=mo.soggetto_id
                               and   m.codice_modpag=h_modpag
                               and   m.codice_modpag_del=h_modpag_del
                               and   m.fl_genera_codice='S'
                               and   m.ente_proprietario_id=pEnte;
                      
                            -- verifica coerenza con indirizzo se presente
                            --if h_sede_secondaria='S' and h_fl_genera_codice='N' then
                            if h_sede_secondaria='S'  then
                                begin
                                    msgRes:='Verifica migrazione SEDE SEC. per  MDP codice_soggetto='||h_codice_soggetto
                                            ||' modpag='||h_modpag||' modpag_del='||h_modpag_del||'.';  
                                    select nvl(count(*),0) into h_count_sede
                                      from migr_sede_secondaria s
                                     where  s.soggetto_id=h_soggetto_id
                                       and  s.codice_modpag=h_modpag
                                       and  s.codice_indirizzo=migrCursor.Codice_Indirizzo
                                       and  s.ente_proprietario_id=pEnte;
                         
                                    if h_count_sede=0 then
                                        h_codice_indirizzo:=0;
                                        --  h_sede_secondaria:='N';
                                    else    
                                        h_codice_indirizzo:= migrCursor.Codice_Indirizzo;  
                                    end if;    
                          
                                exception
                                    when no_data_found then
                                      --codRes:=-2;
                                      --msgRes := msgRes || 'SEDE non migrata.';
                                      --msgMotivoScarto := msgRes;
                                      h_codice_indirizzo:=0;
                                      h_sede_secondaria:='N';
                                    when others then
                                      codRes:=-1;
                                      msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';  
                            
                                end;
                            else h_codice_indirizzo:=0;                        
                            end if;
                      
                        exception
                            when no_data_found then
                              codRes:=-2;
                              msgRes := msgRes || 'MDP non migrata.';
                              msgMotivoScarto := msgRes;
                              tipoScarto:='MDE';
                            when others then
                              codRes:=-1;
                              msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                        end;
                     
                    end if;  
                   
                end if;
                           
                -- calcolo importi            
                if codRes=0 then
                  if migrCursor.importo_debito_orig!=0 and
                     abs(migrCursor.importo_debito_orig)>abs(migrCursor.importo) then
                     h_importo:=migrCursor.importo_debito_orig;
                     h_importo_da_dedurre:=h_importo-migrCursor.importo;
                  else h_importo:=migrCursor.importo;
                  end if;
                end if;
                          
                if codRes= 0 then
                  if migrCursor.nmand!=0 then
                     if migrCursor.Nsubimp=0 then
                       h_note:='PAGAMENTO N.MAND '||migrCursor.nmand||' N.LIQ '||migrCursor.nliq||' IMPEGNO '||
                                migrCursor.annoimp||'/'||migrCursor.nimp||'  ANNO '||migrCursor.anno_esercizio;
                     else
                       h_note:='PAGAMENTO N.MAND '||migrCursor.nmand||' N.LIQ '||migrCursor.nliq||' SUBIMPEGNO '||
                               migrCursor.annoimp||'/'||migrCursor.nimp||'/'||migrCursor.Nsubimp
                               ||'  ANNO '||migrCursor.anno_esercizio;
                     end if;   
                     h_note:=h_note||'.'||migrCursor.Note_Tesoriere;
                  else h_note:=migrCursor.Note_Tesoriere;  
                  end if;
                  
                  if migrCursor.no_split = 'R' then
                     h_tipoIva := TIPO_IVASPLITREVERSE_RC;
                  elsif migrCursor.no_split = 'S' then
                     h_tipoIva := TIPO_IVASPLITREVERSE_ES;    
                  elsif migrCursor.no_split = 'N' and (migrCursor.RILEV_IVA is null or migrCursor.RILEV_IVA='N') then
                     h_tipoIva := TIPO_IVASPLITREVERSE_SI;
                  elsif migrCursor.no_split = 'N' and migrCursor.RILEV_IVA ='S' then
                     h_tipoIva := TIPO_IVASPLITREVERSE_SC;
                  else
                    h_tipoIva := null;
                  end if;
                  
                end if;
                       
                if codRes = 0 then

                 -- DAVIDE - Conversione dell'importo in Euro 
                  if h_importo > 0 and migrCursor.cod_valuta <> '01' then
                     h_Importo_quote := h_importo / RAPPORTO_EURO_LIRA;
                 else 
                     h_Importo_quote := h_importo;
                 end if;
                  if h_importo_da_dedurre > 0 and migrCursor.cod_valuta <> '01' then
                     h_Importo_quote_da_dedurre := h_importo_da_dedurre / RAPPORTO_EURO_LIRA;
                 else 
                     h_Importo_quote_da_dedurre := h_importo_da_dedurre;
                 end if;
                              
                 -- DAVIDE - Fine    
                 msgRes := 'Inserimento in migr_docquo_spesa.';
                 insert into migr_docquo_spesa 
                 (docquospesa_id,
                  docspesa_id,
                  tipo,
                  anno,
                  numero,
                  codice_soggetto,
                  frazione,
                  elenco_doc_id,
                  codice_soggetto_pag,
                  codice_modpag,
                  codice_modpag_del,
                  codice_indirizzo,
                  sede_secondaria,
                  importo,
                  importo_da_dedurre,
                  anno_esercizio,
                  anno_impegno,
                  numero_impegno,
                  numero_subimpegno,
                  anno_provvedimento,
                  numero_provvedimento,
                  tipo_provvedimento,
                  sac_provvedimento,       -- DAVIDE - Gestione SAC Provvedimento
                  oggetto_provvedimento,
                  note_provvedimento,
                  stato_provvedimento,
                  descrizione,
                  numero_iva,
                  flag_rilevante_iva,
                  data_scadenza,
                  data_scadenza_new,
                  cup,
                  cig,
                  commissioni,
                  causale_sospensione,
                  data_sospensione,
                  data_riattivazione,
                  flag_ord_singolo,
                  flag_avviso,
                  tipo_avviso,
                  flag_esproprio,
                  flag_manuale,
                  note,
                  causale_ordinativo,
                  numero_mutuo,
                  annotazione_certif_crediti,
                  data_certif_crediti,
                  note_certif_crediti,
                  numero_certif_crediti,
                  flag_certif_crediti,
                  numero_liquidazione,
                  numero_mandato,
                  utente_creazione,
                  utente_modifica,
                  ente_proprietario_id,
                  importo_splitreverse,
                  tipo_iva_splitreverse)
                 values
                 (migr_docquo_spesa_id_seq.nextval,
                  migrCursor.Docspesa_Id,
                  migrCursor.Tipodoc,
                  migrCursor.Annodoc,
                  migrCursor.Ndoc,
                  migrCursor.Codben,
                  migrCursor.Frazione,
                  0,
                  migrCursor.Codben_Pagamento,
                  --migrCursor.Modpag_Quota,
                 -- migrCursor.Modpag_Del_Quota,
                 -- migrCursor.Codice_Indirizzo,
                  h_modpag,
                  h_modpag_del,
                  h_codice_indirizzo,
                  h_sede_secondaria,
    -- DAVIDE - Conversione Lira / Euro              
                  --h_importo,
                  --h_importo_da_dedurre,
                  h_importo_quote,
                  h_importo_quote_da_dedurre,
    -- DAVIDE - Fine
                  decode(migrCursor.nmand,0,pAnnoEsercizio,migrCursor.anno_esercizio),
                  decode(migrCursor.Nimp,0,null,migrCursor.Annoimp),
                  migrCursor.Nimp,
                  migrCursor.Nsubimp,
                  h_anno_provvedimento,
                  h_numero_provvedimento,
                  h_tipo_provvedimento,
                  h_sac_provvedimento,        -- DAVIDE - Gestione SAC Provvedimento
                  h_oggetto_provvedimento,
                  h_note_provvedimento,
                  h_stato_provvedimento,
                  migrCursor.descri,
                  migrCursor.Niva,
                  migrCursor.Flag_Rilevante_Iva,
                  migrCursor.data_scadenza,
                  migrCursor.data_scadenza_new,
                  migrCursor.cup,
                  migrCursor.cig,
                  migrCursor.Commissioni,
                  '',
                  migrCursor.data_sospensione,
                  migrCursor.data_riattivazione,
                  migrCursor.Flag_Mand_Singolo,
                  migrCursor.flag_avviso,
                  migrCursor.Tipo_Avviso,
                  migrCursor.fl_esproprio,
                  migrCursor.Fl_Manuale,
                  h_note,
                  migrCursor.Causale_Ordinativo,
                  migrCursor.Nro_Mutuo,
                  h_annotazioni_dl35,
                  h_data_dl35,
                  h_note_dl35,
                  h_numero_dl35,
                  h_flag_dl35,
                  migrCursor.Nliq,
                  migrCursor.Nmand,
                  migrCursor.Utente_Ins,
                  migrCursor.Utente_Agg,
                  pEnte,
                  migrCursor.reverse_charge,
                  h_tipoIva);
                 cDocInseriti := cDocInseriti + 1;
                end if;

                if codRes = -2 then
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
                  migrCursor.Tipodoc,
                  migrCursor.Annodoc,
                  migrCursor.Ndoc,
                  migrCursor.Codben,
                  migrCursor.Frazione,
                  msgMotivoScarto,
                  tipoScarto,
                  pEnte);
                               
                  cDocScartati := cDocScartati + 1;
                 end if;
                              
                 if codRes=-1 then
                  raise ERROR_DOCUMENTO;  
                 end if;

                 if numInsert >= N_BLOCCHI_DOC then
                  commit;
                  numInsert := 0;
                 else
                  numInsert := numInsert + 1;
                 end if;
    end loop;
    
    if cDocScartati>0 then
      msgRes:='Gestione scarti quote documenti spesa-aggiornamento migr_docquo_spesa dopo ciclo.';
      update migr_docquo_spesa m set m.fl_scarto='S'
      where 0!=(select count(*) from  migr_docquo_spesa_scarto mq
                where mq.anno=m.anno
                  and mq.numero=m.numero
                  and mq.tipo=m.tipo 
                  and mq.codice_soggetto=m.codice_soggetto
                  and mq.ente_proprietario_id=pEnte)
      and   m.ente_proprietario_id=pEnte;
      commit;
                  
      msgRes:='Gestione scarti quote documenti spesa-aggiornamento migr_doc_spesa dopo ciclo.';
      update migr_doc_spesa m set m.fl_scarto='S'
      where 0!=(select count(*) from  migr_docquo_spesa_scarto mq
                where mq.anno=m.anno
                  and mq.numero=m.numero
                  and mq.tipo=m.tipo 
                  and mq.codice_soggetto=m.codice_soggetto
                  and mq.ente_proprietario_id=pEnte)
       and m.fl_scarto='N'
       and m.ente_proprietario_id=pEnte;
       
       commit;
    end if;
    
    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Quote documenti di spesa inseriti=' ||
                 cDocInseriti || ' scartati=' || cDocScartati || '.';

    pDocScartati := cDocScartati;
    pDocInseriti := cDocInseriti;
    commit;

  exception
    when ERROR_DOCUMENTO then
     dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes );
      pMsgRes      := pMsgRes || h_rec || msgRes ;
      pDocScartati := cDocScartati;
      pDocInseriti := cDocInseriti;
      pCodRes      := -1; 
    when others then
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pDocScartati := cDocScartati;
      pDocInseriti := cDocInseriti;
      pCodRes      := -1;
      
 END migrazione_docquo_spesa;
 /*
 procedure get_liquidazioneOriginale (p_annoEsercizio in varchar2,p_nliq in number, o_annoEsercizio out varchar2,o_nliq out number, o_dataIns out varchar2)
  IS
        num_annoEsercizio integer := 0; 
        v_nLiq number := 0;
        v_nLiqPrec number := 0;
        v_dataInsPrec varchar2(10) := NULL;
        
  BEGIN
        num_annoEsercizio := to_number(p_annoEsercizio);
        v_nLiq := p_nliq;
        
        select ex_liquidazione, to_char(data_ins,'dd/MM/yyyy') into v_nLiqPrec, v_dataInsPrec
        from liquidazione where nliq = v_nLiq and anno_esercizio = p_annoEsercizio;
        
        WHILE v_nLiqPrec != 0
          loop
            v_nLiq := v_nLiqPrec;
            num_annoEsercizio := num_annoEsercizio-1; 
            select ex_liquidazione, to_char(data_ins,'dd/MM/yyyy') into v_nLiqPrec, v_dataInsPrec
            from liquidazione where nliq = v_nLiq and anno_esercizio = num_annoEsercizio;
          end loop;
          
        o_annoEsercizio:= to_char(num_annoEsercizio);
        o_nliq := v_nLiq;
        o_dataIns := v_dataInsPrec;
        
  END;
  */
  procedure migrazione_doc_entrata(pEnte number,
                                 pAnnoEsercizio varchar2,
                                 pCodRes              out number,
                                 pDocInseriti         out number,
                                 pDocScartati         out number,
                                 pMsgRes              out varchar2)  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        numInsert number := 0;
        
        h_sogg_migrato number := 0;
        h_num number := 0;
        
        h_rec varchar2(750) := null;
        

        h_numero_registro_fatt number:=0;
        h_data_registro_fatt varchar2(10):=null;
        
        tipoScarto varchar2(3):=null;
   
        -- DAVIDE - Conversione Importi documenti
        h_Importo_Lordo number(15,2) :=0.0;
        -- DAVIDE - Fine
        
        ERROR_DOCUMENTO EXCEPTION;
        
      begin

        msgRes := 'Inizio migrazione documenti di entrata.';
        begin
            msgRes := 'Pulizia tabelle di migrazione documenti di entrata.';
            DELETE FROM migr_doc_entrata WHERE FL_MIGRATO = 'N' and   ente_proprietario_id=pEnte;
            DELETE FROM migr_doc_entrata_scarto where   ente_proprietario_id=pEnte;
            
            exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               return;
        end;
        
        msgRes := 'Inizio ciclo di migrazione documenti di entrata.';
        for migrCursor in 
        (select d.annodoc, d.ndoc,d.tipodoc,d.codben,nvl(d.codben_incasso,0) codben_incasso,
                decode(d.statodoc,'IN','I',
                                  'LI','L',
                                  'PE','PE',
                                  'PL','PL',
                                  'VA','V',
                                  null) stato_documento,
                d.descri,
                to_char(d.datadoc,'YYYY-MM-DD') data_emissione,
                to_char(d.scadenza,'YYYY-MM-DD') data_scadenza,
        -- DAVIDE - Conversione Importi documenti
                d.cod_valuta,
        -- DAVIDE - Fine
                d.importo_lordo,--d.arrotondamento, 
                decode(d.cod_registro_iva,'00','00',
                                          '77','77',
                                          '99','99',
                                                null) bollo, 
                -- DAVIDE - 05.02.016 - Attributi con date : formato da usare dd/mm/yyyy hh:mm:ss
                --to_char(d.dataprotoc,'YYYY-MM-DD') data_repertorio,d.nprotoc,
                to_char(d.dataprotoc,'dd/MM/yyyy hh:mm:ss') data_repertorio,d.nprotoc,
                -- DAVIDE - 05.02.016 - Gestire nuovo campo anno_repertorio               
                SUBSTR( to_char(d.dataprotoc,'dd/MM/yyyy'), 7 , 4 ) anno_repertorio,
                d.utente_ins, d.utente_agg
          from documenti_ent d
          where d.statodoc not in ('EM', 'AN', 'ST','RT')
            and d.cod_errore is null
            and d.annodoc>'1900'
          order by d.annodoc,d.tipodoc,d.codben,d.ndoc)
          loop
                                      
           -- inizializza variabili
           codRes := 0;
           msgMotivoScarto  := null;
           msgRes := null;
           h_sogg_migrato := 0;
           h_num := 0;
           h_numero_registro_fatt:=0;
           h_data_registro_fatt:=null;
           tipoScarto:=null;

                            
           h_rec := 'Documento  ' || migrCursor.annodoc || '/'||migrCursor.ndoc||' tipo '||migrCursor.tipodoc||
                    ' Soggetto '||migrCursor.Codben||'.';
      
         -- DAVIDE - 05.02.016 - aggiunto scarto per fattura negativa
           -- se importo negativo e tipo = F scarto il documento
           msgRes := 'Verifica importo fattura.';
           if migrCursor.tipodoc='F' and migrCursor.importo_lordo <0 then
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
                     tipoScarto:='SNM';
                   when others then
                     codRes := -1;
                     msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               end;

               if h_sogg_migrato = 0 and codRes!=-1 then
                   begin
                       select nvl(count(*),0) into h_num
                         from fornitori
                        where codben=migrCursor.codben and
                              staoper in ('V','S'); 

                       if h_num = 0 then
                           codRes := -2;
                           msgRes  := msgRes || 'Soggetto non valido.';
                           msgMotivoScarto := msgRes;
                           tipoScarto:='SNV';
                       end if;
             
                   exception
                       when no_data_found then
                         codRes := -2; 
                         h_sogg_migrato  := 0;
                         h_num           := 0;
                         msgRes          := msgRes || 'Soggetto non valido.';
                         msgMotivoScarto := msgRes;
                         tipoScarto:='SNV';
                       when others then
                         codRes := -1;
                         msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                   end;
               end if;
                            
               h_sogg_migrato := 0;
               h_num := 0;
               if migrCursor.codben_incasso!=0 and migrCursor.codben_incasso!=migrCursor.codben and 
                   codRes=0 then 
                   msgRes := 'Verifica soggetto incasso migrato.';
                   begin
                       select nvl(count(*), 0)
                         into h_sogg_migrato
                         from migr_soggetto
                        where codice_soggetto = migrCursor.codben_incasso
                        and   ente_proprietario_id=pEnte;

                       if h_sogg_migrato = 0 then
                           codRes := -2;
                           msgRes := msgRes||'Soggetto incasso non migrato.';
                           msgMotivoScarto := msgRes;
                           tipoScarto:='SIN';
                       end if;

                   exception
                       when no_data_found then
                         codRes := -2;
                         h_sogg_migrato  := 0;
                         msgRes          := msgRes||'Soggetto incasso non migrato.';
                         msgMotivoScarto := msgRes;
                         tipoScarto:='SIN';
                       when others then
                         codRes := -1;
                         msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                   end;
              
                   if h_sogg_migrato = 0 and codRes!=-1 then
                       begin
                           select nvl(count(*),0) into h_num
                             from fornitori
                            where codben=migrCursor.codben_incasso and
                                  staoper in ('V','S'); 

                           if h_num = 0 then
                               codRes:=-2;
                               msgRes  := msgRes || 'Soggetto incasso non valido.';
                               msgMotivoScarto := msgRes;
                               tipoScarto:='SIV';
                           end if;
                
                       exception
                           when no_data_found then
                             codRes:=-2;
                             h_sogg_migrato  := 0;
                             h_num           := 0;
                             msgRes          := msgRes || 'Soggetto incasso non valido.';
                             msgMotivoScarto := msgRes;
                             tipoScarto:='SIV';
                           when others then
                             codRes:=-1;
                             msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                       end;
                   end if;   
                            
                   if codRes=0 then
                       codRes:=-2;
                       msgRes := msgRes || 'Soggetto incasso indicato.';
                       msgMotivoScarto := msgRes;
                       tipoScarto:='SII';
                   end if; 
               end if; 
           end if; 
                           
              -- registro_iva 
              if codRes=0 then
                           
              msgRes:='Lettura registro unico fatture.';
              begin
               select r.numero_registro ,  to_char(r.data_registro,'YYYY-MM-DD')
               into h_numero_registro_fatt,h_data_registro_fatt
               from registro_fatture r
               where r.annodoc=migrCursor.annodoc
               and   r.ndoc=migrCursor.ndoc
               and   r.tipodoc=migrCursor.Tipodoc
               and   r.codben=migrCursor.codben;
  
               exception
                when no_data_found then
                 null;
                when others then
                 codRes:=-1;
                 msgRes := msgRes || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               end;
              end if;
                               
    
              if codRes = 0 then
               -- DAVIDE - Conversione dell'importo in Euro 
                if migrCursor.Importo_Lordo > 0 and migrCursor.cod_valuta <> '01' then
                   h_Importo_Lordo := migrCursor.Importo_Lordo / RAPPORTO_EURO_LIRA;
               else 
                   h_Importo_Lordo := migrCursor.Importo_Lordo;
               end if;
               -- DAVIDE - Fine

               msgRes := 'Inserimento in migr_doc_entrata.';
               insert into migr_doc_entrata 
               (docentrata_id,
                tipo,
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
                -- DAVIDE - 05.02.016 - Gestire nuovo campo anno_repertorio               
                anno_repertorio,
                note,
                numero_registro_fatt,
                data_registro_fatt,
                utente_creazione,
                utente_modifica,
                ente_proprietario_id)
               values
               (migr_doc_entrata_id_seq.nextval,
                migrCursor.tipodoc,
                migrCursor.annodoc,
                migrCursor.ndoc,
                migrCursor.codben,
                migrCursor.codben_incasso,
                migrCursor.stato_documento,
                migrCursor.descri,
                migrCursor.data_emissione,
                migrCursor.data_scadenza,
        -- DAVIDE - Conversione dell'importo in Euro 
                --migrCursor.Importo_Lordo,
                h_Importo_Lordo,
        -- DAVIDE - Fine 
                0,
                migrCursor.bollo,
                migrCursor.Data_Repertorio,
                migrCursor.Nprotoc,
                -- DAVIDE - 05.02.016 - Gestire nuovo campo anno_repertorio               
                migrCursor.anno_repertorio,
                '',
                h_numero_registro_fatt,h_data_registro_fatt,
                migrCursor.Utente_Ins,
                migrCursor.Utente_Agg,
                pEnte);
               cDocInseriti := cDocInseriti + 1;
              end if;

              if codRes = -2 then
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
                migrCursor.Tipodoc,
                migrCursor.Annodoc,
                migrCursor.Ndoc,
                migrCursor.Codben,
                msgMotivoScarto,
                tipoScarto,
                pEnte);
                               
               cDocScartati := cDocScartati + 1;
              end if;
                              
              if codRes=-1 then
               raise ERROR_DOCUMENTO;  
              end if;

              if numInsert >= N_BLOCCHI_DOC then
               commit;
               numInsert := 0;
              else
               numInsert := numInsert + 1;
              end if;
    end loop;

    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Documenti di entrata inseriti=' ||
                 cDocInseriti || ' scartati=' || cDocScartati || '.';

    pDocScartati := cDocScartati;
    pDocInseriti := cDocInseriti;
    commit;

  exception
    when ERROR_DOCUMENTO then
     dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes );
      pMsgRes      := pMsgRes || h_rec || msgRes ;
      pDocScartati := cDocScartati;
      pDocInseriti := cDocInseriti;
      pCodRes      := -1; 
    when others then
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pDocScartati := cDocScartati;
      pDocInseriti := cDocInseriti;
      pCodRes      := -1;
      
  END migrazione_doc_entrata;


  procedure migrazione_docquo_entrata(pEnte number,
                                      pAnnoEsercizio varchar2,
                                      pCodRes              out number,
                                      pDocInseriti         out number,
                                      pDocScartati         out number,
                                      pMsgRes              out varchar2)  IS
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        numInsert number := 0;
        
        h_sogg_migrato number := 0;
        h_num number := 0;
        
        h_rec varchar2(750) := null;
        
        h_note varchar2(500) := null;
        
        h_anno_provvedimento    varchar2(4) := null;
        h_numero_provvedimento  varchar2(10) := null;
        h_tipo_provvedimento    varchar2(20) := null;
        h_stato_provvedimento   varchar2(5) := null;
        h_oggetto_provvedimento varchar2(500) := null;
        h_note_provvedimento    varchar2(500) := null;
    
        h_sac_provvedimento     varchar2(20) := null; -- DAVIDE - Gestione SAC Provvedimento
      
        tipoScarto varchar2(3):=null;

        -- DAVIDE - Conversione Importi quote
        h_Importo number(15,2) :=0.0;
        -- DAVIDE - Fine
        
        ERROR_DOCUMENTO EXCEPTION;
        
      begin

        msgRes := 'Inizio migrazione quote documenti di entrata.';
        begin
            msgRes := 'Pulizia tabelle di migrazione quote documenti di entrata.';
            DELETE FROM migr_docquo_entrata WHERE FL_MIGRATO = 'N' and   ente_proprietario_id=pEnte;
            DELETE FROM migr_docquo_entrata_scarto where ente_proprietario_id=pEnte;
            UPDATE migr_doc_entrata set fl_scarto='N'
            where fl_migrato='N'
            and   fl_scarto='S'
            and   ente_proprietario_id=pEnte;
            
            commit;
            
            exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               return;
        end;
        
    begin    
     msgRes:='Gestione scarti quote documenti entrata per accertamento non migrato.'; 
         insert into migr_docquo_entrata_scarto
         (docquo_entrata_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,
      ente_proprietario_id)
          (select migr_docquo_ent_scarto_id_seq.nextval,q.tipodoc,q.annodoc,q.ndoc,q.codben,q.frazione,
            'Accertamento '||q.annoacc||'/'||q.nacc||' anno_esercizio '||q.anno_esercizio||' non migrato.','ACC',pEnte
      from docquote_ent q, migr_doc_entrata m
      where q.cod_azienda=1
        and q.tipodoc=m.tipo
        and q.annodoc=m.anno
        and q.ndoc=m.numero
        and q.codben=m.codice_soggetto
        and m.ente_proprietario_id=pEnte
        and nvl(q.nacc,0)!=0
        and nvl(q.nsubacc,0)=0
        and nvl(q.nriscos,0)=0
        and 0=(select count(*) from migr_accertamento mi
                 where mi.numero_accertamento=q.nacc
                   and mi.anno_accertamento=q.annoacc
                   and mi.anno_esercizio=pAnnoEsercizio
                   and mi.tipo_movimento='A'
                   and mi.ente_proprietario_id=pEnte)
     );
     commit;
       
     msgRes:='Gestione scarti quote documenti accertamento per subaccertamento non migrato.';  
     insert into migr_docquo_entrata_scarto
         (docquo_entrata_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,
      ente_proprietario_id)
          (select migr_docquo_ent_scarto_id_seq.nextval,q.tipodoc,q.annodoc,q.ndoc,q.codben,q.frazione,
            'SubAccertamento '||q.annoacc||'/'||q.nacc||'/'||q.nsubacc||' anno_esercizio '||q.anno_esercizio||' non migrato.','SAC',pEnte
      from docquote_ent q, migr_doc_entrata m
      where q.cod_azienda=1
        and q.tipodoc=m.tipo
        and q.annodoc=m.anno
        and q.ndoc=m.numero
        and q.codben=m.codice_soggetto
        and m.ente_proprietario_id=pEnte
        and nvl(q.nacc,0)!=0        
        and nvl(q.nsubacc,0)!=0
        and nvl(q.nriscos,0)=0
        and 0=(select count(*) from migr_accertamento mi
                 where mi.numero_accertamento=q.nacc
                   and mi.numero_subaccertamento=q.nsubacc
                   and mi.anno_accertamento=q.annoacc
                   and mi.anno_esercizio=pAnnoEsercizio
                   and mi.tipo_movimento='S'
                   and mi.ente_proprietario_id=pEnte)
       );
      commit;
      
      
      msgRes:='Gestione scarti quote documenti entrata-aggiornamento migr_doc_entrata prima ciclo.';
      update migr_doc_entrata m set m.fl_scarto='S'
      where 0!=(select count(*) from  migr_docquo_entrata_scarto mq
                where mq.anno=m.anno
                  and mq.numero=m.numero
                  and mq.tipo=m.tipo 
                  and mq.codice_soggetto=m.codice_soggetto
                  and mq.ente_proprietario_id=pEnte)
      and m.ente_proprietario_id=pEnte;
      commit;
                   
     exception 
       when others then
            rollback;
            pCodRes := -1;
            pMsgRes := msgRes || 'Errore ' ||
            SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            return;  
    end;   
                  
        msgRes := 'Inizio ciclo di migrazione quote documenti di entrata.';
        for migrCursor in 
        (select m.docentrata_id,q.annodoc, q.ndoc, q.tipodoc,q.codben, nvl(d.codben_incasso,0) codben_incasso,
                q.frazione,  
        -- DAVIDE - Conversione Lira / Euro
                d.cod_valuta,
        -- DAVIDE - Fine
                nvl(q.impquota,0) importo,
                q.anno_esercizio,q.annoacc,nvl(q.nacc,0) nacc,nvl(q.nsubacc,0) nsubacc,
                nvl(q.nriscos,0) nriscos,
                q.annoprov,nvl(q.nprov,0) nprov,
        -- DAVIDE - 05.02.016 - Descrizione /datascadenza della quota doc , se non presente valorizzare con dati doc
                --q.descri,
                nvl(q.descri,d.descri) as descri,
                         nvl(q.niva,0) niva, decode(nvl(q.niva,0),0,'N','S') flag_rilevante_iva,
        -- DAVIDE - 05.02.016 - Descrizione /datascadenza della quota doc , se non presente valorizzare con dati doc
                --to_char(q.scadenza,'YYYY-MM-DD') data_scadenza,
                to_char(nvl(q.scadenza,d.scadenza),'YYYY-MM-DD') data_scadenza,
                nvl(q.flag_rev_singola,'N') flag_rev_singola ,
                decode(q.fl_avviso,'S','S','P','S','N') flag_avviso,
                decode(q.fl_avviso,'S','TESORIERE','P','TESORIERE','N',null) tipo_avviso,
                nvl(q.fl_esproprio,'N') fl_esproprio, 
--                decode(nvl(q.nriscos,0),0,'N','S') fl_manuale,
        -- DAVIDE - 26.02.016 - flag_manuale impostato come in REGP - salvato su campo siac_t_subdoc.subdoc_convalida_manuale
            --  nvl(q.fl_manuale,'N') fl_manuale,
                NULL as fl_manuale,
                d.note_tesoriere,
                q.utente_ins, q.utente_agg
          from docquote_ent q, documenti_ent d, migr_doc_entrata m
          where d.statodoc not in ('EM', 'AN', 'ST','RT')
            and d.cod_errore is null
            and d.annodoc>'1900'
            and q.cod_azienda=1
            and q.tipodoc=d.tipodoc
            and q.annodoc=d.annodoc
            and q.ndoc=d.ndoc
            and q.codben=d.codben
            and m.anno=d.annodoc
            and m.numero=d.ndoc
            and m.tipo=d.tipodoc
            and m.codice_soggetto=d.codben
            and m.fl_scarto='N'
            and m.ente_proprietario_id=pEnte                                  
          order by q.annodoc,q.tipodoc,q.codben,q.ndoc,q.frazione)
          loop
                                      
                -- inizializza variabili
                codRes := 0;
                msgMotivoScarto  := null;
                msgRes := null;
                h_sogg_migrato := 0;
                h_num := 0;
                h_anno_provvedimento:=null;
                h_numero_provvedimento:=null;
                h_tipo_provvedimento:=null;
                h_stato_provvedimento:=null;
                h_oggetto_provvedimento:=null;
                h_note_provvedimento:=null;

                h_note:=null;
                tipoScarto:=null;
       
                h_sac_provvedimento  := null; -- DAVIDE - Gestione SAC Provvedimento
             
                h_rec := 'Documento  ' || migrCursor.annodoc || '/'||migrCursor.ndoc||' tipo '||migrCursor.tipodoc||
                         ' Soggetto '||migrCursor.Codben||': frazione '||migrCursor.frazione||'.';

            -- DAVIDE - 05.02.016 - aggiunto scarto per fattura negativa
                -- se importo negativo e tipo = F scarto il documento
                msgRes := 'Verifica importo quota fattura.';
                if migrCursor.tipodoc='F' and migrCursor.importo <0 then
                    msgRes          := msgRes|| 'Importo negativo.';
                    msgMotivoScarto := msgRes;
                    tipoScarto:='FN';-- fattura negativa
                    codRes := -1;
                end if;
               
                -- soggetto e soggetto incasso
                -- non si ripetono qui i controlli sui soggetti perche gia fatti sul documento
 
                           -- provvedimento
                           
                if codRes=0 and migrCursor.nprov!=0 then
                
                    h_anno_provvedimento   := migrCursor.annoprov;
                    h_numero_provvedimento := migrCursor.nprov;
                  
                    leggi_provvedimento(h_anno_provvedimento,
                                        h_numero_provvedimento,
                                        pEnte,
                                        codRes,
                                        msgRes,
                                        h_tipo_provvedimento,
                                        h_oggetto_provvedimento,
                                        h_stato_provvedimento,
                                        h_note_provvedimento,
                                        h_sac_provvedimento);     -- DAVIDE - Gestione SAC Provvedimento

                    if codRes = 0 then
                        h_tipo_provvedimento := h_tipo_provvedimento || '||';
                        -- h_stato_provvedimento capire se e come gestire 
                    end if;

            -- DAVIDE - 22.02.016 - aggiunta gestione scarto per provvedimento non trovato 
                    if codRes = -2 then
                        msgMotivoScarto := msgRes;
                        tipoScarto:='PNT';
                    end if;
                  end if;
                          
                if codRes= 0 then
                    if migrCursor.nriscos!=0 then
                        if migrCursor.Nsubacc=0 then
                            h_note:='INCASSO N.RISCOS. '||migrCursor.nriscos||' ACCERTAMENTO '
                                    ||migrCursor.Annoacc||'/'||migrCursor.nacc||' ANNO '||migrCursor.anno_esercizio;             
                        else
                            h_note:='INCASSO N.RISCOS. '||migrCursor.nriscos||' SUBACCERTAMENTO '
                                    ||migrCursor.Annoacc||'/'||migrCursor.nacc||'/'||migrCursor.Nsubacc||' ANNO '||migrCursor.anno_esercizio;
                        end if;            
                        h_note:=h_note||'.'||migrCursor.Note_Tesoriere;
                    else h_note:=migrCursor.Note_Tesoriere;  
                    end if;
                end if;  
                       
                if codRes = 0 then

                    -- DAVIDE - Conversione dell'importo in Euro 
                     if migrCursor.importo > 0 and migrCursor.cod_valuta <> '01' then
                        h_Importo := migrCursor.importo / RAPPORTO_EURO_LIRA;
                    else 
                        h_Importo := migrCursor.importo;
                    end if;
                    -- DAVIDE - Fine

                    msgRes := 'Inserimento in migr_docquo_entrata.';
                    insert into migr_docquo_entrata
                 (docquoentrata_id,
                  docentrata_id,
                  tipo,
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
                  anno_provvedimento,
                  numero_provvedimento,
                  tipo_provvedimento,
                  sac_provvedimento,      -- DAVIDE - Gestione SAC Provvedimento
                  oggetto_provvedimento,
                  note_provvedimento,
                  stato_provvedimento,
                  descrizione,
                  numero_iva,
                  flag_rilevante_iva,
                  data_scadenza,
                  flag_ord_singolo,
                  flag_avviso,
                  tipo_avviso,
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
                  migrCursor.Tipodoc,
                  migrCursor.Annodoc,
                  migrCursor.Ndoc,
                  migrCursor.Codben,
                  migrCursor.Frazione,
                  0,
                  migrCursor.Codben_incasso,
            -- DAVIDE - Conversione Lira / Euro
                  --migrCursor.importo,
                  h_Importo,
            -- DAVIDE - Fine
                  decode(migrCursor.nriscos,0,pAnnoEsercizio,migrCursor.anno_esercizio),
                  decode(migrCursor.Nacc,0,null,migrCursor.Annoacc),
                  migrCursor.Nacc,
                  migrCursor.Nsubacc,
                  h_anno_provvedimento,
                  h_numero_provvedimento,
                  h_tipo_provvedimento,
                  h_sac_provvedimento,       -- DAVIDE - Gestione SAC Provvedimento
                  h_oggetto_provvedimento,
                  h_note_provvedimento,
                  h_stato_provvedimento,
                  migrCursor.descri,
                  migrCursor.Niva,
                  migrCursor.Flag_Rilevante_Iva,
                  migrCursor.data_scadenza,
                  migrCursor.flag_rev_singola,
                  migrCursor.flag_avviso,
                  migrCursor.Tipo_Avviso,
                  migrCursor.fl_esproprio,
                  migrCursor.Fl_Manuale,
                  h_note,
                  migrCursor.Nriscos,
                  migrCursor.Utente_Ins,
                  migrCursor.Utente_Agg,
                  pEnte);
                 cDocInseriti := cDocInseriti + 1;
                end if;

                if codRes = -2 then
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
                  migrCursor.Tipodoc,
                  migrCursor.Annodoc,
                  migrCursor.Ndoc,
                  migrCursor.Codben,
                  migrCursor.Frazione,
                  msgMotivoScarto,
                  tipoScarto,
                  pEnte);
                               
                  cDocScartati := cDocScartati + 1;
                 end if;
                              
                 if codRes=-1 then
                  raise ERROR_DOCUMENTO;  
                 end if;

                 if numInsert >= N_BLOCCHI_DOC then
                  commit;
                  numInsert := 0;
                 else
                  numInsert := numInsert + 1;
                 end if;
    end loop;
    
    if cDocScartati>0 then
      msgRes:='Gestione scarti quote documenti entrata-aggiornamento migr_docquo_entrata dopo ciclo.';
      update migr_docquo_entrata m set m.fl_scarto='S'
      where 0!=(select count(*) from  migr_docquo_entrata_scarto mq
                where mq.anno=m.anno
                  and mq.numero=m.numero
                  and mq.tipo=m.tipo 
                  and mq.codice_soggetto=m.codice_soggetto
                  and mq.ente_proprietario_id=pEnte)
      and m.ente_proprietario_id=pEnte;
      commit;
                  
      msgRes:='Gestione scarti quote documenti entrata-aggiornamento migr_doc_entrata dopo ciclo.';
      update migr_doc_entrata m set m.fl_scarto='S'
      where 0!=(select count(*) from  migr_docquo_entrata_scarto mq
                where mq.anno=m.anno
                  and mq.numero=m.numero
                  and mq.tipo=m.tipo 
                  and mq.codice_soggetto=m.codice_soggetto
                  and mq.ente_proprietario_id=pEnte)
       and m.fl_scarto='N'
       and m.ente_proprietario_id=pEnte;
       
       commit;
    end if;
    
    pCodRes := 0;
    pMsgRes := pMsgRes || 'Elaborazione OK.Quote documenti di entrata inseriti=' ||
                 cDocInseriti || ' scartati=' || cDocScartati || '.';

    pDocScartati := cDocScartati;
    pDocInseriti := cDocInseriti;
    commit;

  exception
    when ERROR_DOCUMENTO then
     dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes );
      pMsgRes      := pMsgRes || h_rec || msgRes ;
      pDocScartati := cDocScartati;
      pDocInseriti := cDocInseriti;
      pCodRes      := -1; 
    when others then
      dbms_output.put_line(h_rec || ' msgRes ' ||
                           msgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pDocScartati := cDocScartati;
      pDocInseriti := cDocInseriti;
      pCodRes      := -1;
      
 END migrazione_docquo_entrata;    
 

procedure migrazione_relaz_documenti(pEnte number,
                                       pCodRes              out number,
                                       pMsgRes              out varchar2)  IS
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
                doc.docspesa_id,
                doc.tipo,
                doc.anno,
                doc.numero,
                doc.codice_soggetto,
                ncd.docspesa_id,
                ncd.tipo,
                ncd.anno,
                ncd.numero,
                ncd.codice_soggetto,
                pEnte
         from docnotacred cred,migr_doc_spesa doc, migr_doc_spesa ncd 
         where doc.anno=cred.annodoc1
         and   doc.numero=cred.ndoc1
         and   doc.codice_soggetto=cred.codben1
         and   doc.tipo=cred.tipodoc1
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc
         and   ncd.numero=cred.ndoc
         and   ncd.codice_soggetto=cred.codben
         and   ncd.tipo=cred.tipodoc
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);         
/*         where doc.anno=cred.annodoc
         and   doc.numero=cred.ndoc
         and   doc.codice_soggetto=cred.codben
         and   doc.tipo=cred.tipodoc
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc1
         and   ncd.numero=cred.ndoc1
         and   ncd.codice_soggetto=cred.codben1
         and   ncd.tipo=cred.tipodoc1
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);*/
        
        commit;
        
        msgRes := 'Inizio migrazione relazioni documenti AGGIO [spesa] tipo='||RELAZ_TIPO_SUB||'.';
        insert into migr_relaz_documenti
        (relazdoc_id,relaz_tipo,
         anno_da,numero_da,tipo_da,codice_soggetto_da,doc_id_da,
         anno_a,numero_a,tipo_a,codice_soggetto_a,doc_id_a,ente_proprietario_id)
        (select migr_relazdoc_id_seq.nextval,RELAZ_TIPO_SUB,
         ncd.anno,ncd.numero,ncd.tipo,ncd.codice_soggetto,ncd.docentrata_id,
         doc.anno,doc.numero,doc.tipo,doc.codice_soggetto,doc.docspesa_id,pEnte
         from doc_colleg_ent cred,migr_doc_spesa doc, migr_doc_entrata ncd 
         where doc.anno=cred.annodoc
         and   doc.numero=cred.ndoc
         and   doc.codice_soggetto=cred.codben
         and   doc.tipo=cred.tipodoc
         and   doc.tipo='AGG' -- AGGIO
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc_ent
         and   ncd.numero=cred.ndoc_ent
         and   ncd.codice_soggetto=cred.codben_ent
         and   ncd.tipo=cred.tipodoc_ent
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);
        
        commit;

        msgRes := 'Inizio migrazione relazioni documenti PENALE [entrata] tipo='||RELAZ_TIPO_SUB||'.';
        insert into migr_relaz_documenti
        (relazdoc_id,relaz_tipo,
         anno_da,numero_da,tipo_da,codice_soggetto_da,doc_id_da,
         anno_a,numero_a,tipo_a,codice_soggetto_a,doc_id_a,ente_proprietario_id)
        (select migr_relazdoc_id_seq.nextval,RELAZ_TIPO_SUB,
         doc.anno,doc.numero,doc.tipo,doc.codice_soggetto,doc.docspesa_id,
         ncd.anno,ncd.numero,ncd.tipo,ncd.codice_soggetto,ncd.docentrata_id,pEnte
         from doc_colleg_ent cred,migr_doc_spesa doc, migr_doc_entrata ncd 
         where doc.anno=cred.annodoc
         and   doc.numero=cred.ndoc
         and   doc.codice_soggetto=cred.codben
         and   doc.tipo=cred.tipodoc
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc_ent
         and   ncd.numero=cred.ndoc_ent
         and   ncd.codice_soggetto=cred.codben_ent
         and   ncd.tipo=cred.tipodoc_ent
         and   cred.tipodoc_ent='PNL' -- PENALE
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);
        
        commit;

        msgRes := 'Inizio migrazione relazioni documenti REG [spesa] tipo='||RELAZ_TIPO_SUB||'.';
        insert into migr_relaz_documenti
        (relazdoc_id,relaz_tipo,
         anno_da,numero_da,tipo_da,codice_soggetto_da,doc_id_da,
         anno_a,numero_a,tipo_a,codice_soggetto_a,doc_id_a,ente_proprietario_id)
        (select migr_relazdoc_id_seq.nextval,RELAZ_TIPO_SUB,
         ncd.anno,ncd.numero,ncd.tipo,ncd.codice_soggetto,ncd.docentrata_id,
         doc.anno,doc.numero,doc.tipo,doc.codice_soggetto,doc.docspesa_id,pEnte
         from doc_colleg_ent cred,migr_doc_spesa doc, migr_doc_entrata ncd 
         where doc.anno=cred.annodoc
         and   doc.numero=cred.ndoc
         and   doc.codice_soggetto=cred.codben
         and   doc.tipo=cred.tipodoc
         and   doc.tipo='REG' -- REG
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc_ent
         and   ncd.numero=cred.ndoc_ent
         and   ncd.codice_soggetto=cred.codben_ent
         and   ncd.tipo=cred.tipodoc_ent
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);
        
        commit;

        msgRes := 'Inizio migrazione relazioni documenti SUB [spesa] tipo='||RELAZ_TIPO_SUB||'.';
        insert into migr_relaz_documenti
        (relazdoc_id,relaz_tipo,
         anno_da,numero_da,tipo_da,codice_soggetto_da,doc_id_da,
         anno_a,numero_a,tipo_a,codice_soggetto_a,doc_id_a,ente_proprietario_id)
        (select migr_relazdoc_id_seq.nextval,RELAZ_TIPO_SUB,
         ncd.anno,ncd.numero,ncd.tipo,ncd.codice_soggetto,ncd.docentrata_id,
         doc.anno,doc.numero,doc.tipo,doc.codice_soggetto,doc.docspesa_id,pEnte
         from doc_colleg_ent cred,migr_doc_spesa doc, migr_doc_entrata ncd 
         where doc.anno=cred.annodoc
         and   doc.numero=cred.ndoc
         and   doc.codice_soggetto=cred.codben
         and   doc.tipo=cred.tipodoc
         and   doc.tipo='SUB' -- SUB SPESA
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc_ent
         and   ncd.numero=cred.ndoc_ent
         and   ncd.codice_soggetto=cred.codben_ent
         and   ncd.tipo=cred.tipodoc_ent
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);
        
        commit;

        msgRes := 'Inizio migrazione relazioni documenti SUB [entrata] tipo='||RELAZ_TIPO_SUB||'.';
        insert into migr_relaz_documenti
        (relazdoc_id,relaz_tipo,
         anno_da,numero_da,tipo_da,codice_soggetto_da,doc_id_da,
         anno_a,numero_a,tipo_a,codice_soggetto_a,doc_id_a,ente_proprietario_id)
        (select migr_relazdoc_id_seq.nextval,RELAZ_TIPO_SUB,
         doc.anno,doc.numero,doc.tipo,doc.codice_soggetto,doc.docspesa_id,
         ncd.anno,ncd.numero,ncd.tipo,ncd.codice_soggetto,ncd.docentrata_id,pEnte
         from doc_colleg_ent cred,migr_doc_spesa doc, migr_doc_entrata ncd 
         where doc.anno=cred.annodoc
         and   doc.numero=cred.ndoc
         and   doc.codice_soggetto=cred.codben
         and   doc.tipo=cred.tipodoc
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc_ent
         and   ncd.numero=cred.ndoc_ent
         and   ncd.codice_soggetto=cred.codben_ent
         and   ncd.tipo=cred.tipodoc_ent
         and   cred.tipodoc_ent='SUB' -- SUB ENTRATA
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);
        
        commit;

        
/**        msgRes := 'Inizio migrazione relazioni documenti no AGGIO tipo='||RELAZ_TIPO_SUB||'.';
        insert into migr_relaz_documenti
        (relazdoc_id,relaz_tipo,
         anno_da,numero_da,tipo_da,codice_soggetto_da,doc_id_da,
         anno_a,numero_a,tipo_a,codice_soggetto_a,doc_id_a,ente_proprietario_id)
        (select migr_relazdoc_id_seq.nextval,RELAZ_TIPO_SUB,
         doc.anno,doc.numero,doc.tipo,doc.codice_soggetto,doc.docspesa_id,
         ncd.anno,ncd.numero,ncd.tipo,ncd.codice_soggetto,ncd.docentrata_id,pEnte
         from doc_colleg_ent cred,migr_doc_spesa doc, migr_doc_entrata ncd 
         where doc.anno=cred.annodoc
         and   doc.numero=cred.ndoc
         and   doc.codice_soggetto=cred.codben
         and   doc.tipo=cred.tipodoc
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc_ent
         and   ncd.numero=cred.ndoc_ent
         and   ncd.codice_soggetto=cred.codben_ent
         and   ncd.tipo=cred.tipodoc_ent
         and   cred.tipodoc_ent!='AGG'
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);
        
        commit;

        msgRes := 'Inizio migrazione relazioni documenti  AGGIO tipo='||RELAZ_TIPO_SUB||'.';

        insert into migr_relaz_documenti
        (relazdoc_id,relaz_tipo,
         anno_da,numero_da,tipo_da,codice_soggetto_da,doc_id_da,
         anno_a,numero_a,tipo_a,codice_soggetto_a,doc_id_a,ente_proprietario_id)
        (select migr_relazdoc_id_seq.nextval,RELAZ_TIPO_SUB,
         ncd.anno,ncd.numero,ncd.tipo,ncd.codice_soggetto,ncd.docentrata_id,
         doc.anno,doc.numero,doc.tipo,doc.codice_soggetto,doc.docspesa_id,pEnte
         from doc_colleg_ent cred,migr_doc_spesa doc, migr_doc_entrata ncd 
         where doc.anno=cred.annodoc
         and   doc.numero=cred.ndoc
         and   doc.codice_soggetto=cred.codben
         and   doc.tipo=cred.tipodoc
         and   doc.fl_scarto='N'
         and   doc.ente_proprietario_id=pEnte
         and   ncd.anno=cred.annodoc_ent
         and   ncd.numero=cred.ndoc_ent
         and   ncd.codice_soggetto=cred.codben_ent
         and   ncd.tipo=cred.tipodoc_ent
         and   cred.tipodoc_ent='AGG'
         and   ncd.fl_scarto='N'
         and   ncd.ente_proprietario_id=pEnte);**/


        pCodRes := 0;
        pMsgRes := 'Elaborazione OK.Relazioni documenti migrate.';        
  exception
    when others then
      pMsgRes      :=  msgRes || 'Errore ' ||
                       SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;
 END migrazione_relaz_documenti; 

  procedure migrazione_elenco_doc_allegati(pEnte number,
                                           pCodRes              out number,
                                           pMsgRes              out varchar2)  IS
        codRes number := 0;
        msgRes  varchar2(1500) := null;
        
      begin

        msgRes := 'Inizio migrazione elenco_doc_allegati.';
        begin
            msgRes := 'Pulizia tabelle di migrazione elenco_doc_allegati.';
            DELETE FROM migr_elenco_doc_allegati WHERE FL_MIGRATO = 'N' and   ente_proprietario_id=pEnte;
            UPDATE MIGR_DOCQUO_SPESA set anno_elenco=null,numero_elenco=0,elenco_doc_id=0
            where  fl_migrato='N' and elenco_doc_id!=0 and   ente_proprietario_id=pEnte;
            UPDATE MIGR_DOCQUO_ENTRATA set anno_elenco=null,numero_elenco=0,elenco_doc_id=0
            where  fl_migrato='N' and elenco_doc_id!=0 and   ente_proprietario_id=pEnte;
            commit;
            
            exception when others then
                rollback;
                pCodRes := -1;
                pMsgRes := msgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
               return;
        end;
        
        msgRes := 'Migrazione elenco_doc_allegati per quote documenti spesa.';
        insert into migr_elenco_doc_allegati
        (elenco_doc_id,anno_elenco,numero_elenco,stato,data_trasmissione,anno_provvedimento,numero_provvedimento,
         atto_allegato_id, ente_proprietario_id)
        (select migr_elenco_doc_id_seq.nextval,r.anno_elenco,r.n_elenco, 'B',to_char(r.data_trasmissione_economato,'YYYY-MM-DD'),
                r.annoprov,r.nprov, 0,pEnte
         from registro_elenchi r
         where r.stato='P' 
         and   exists (select 1 from migr_docquo_spesa m
                       where m.fl_scarto='N'
                       and   m.anno_provvedimento=r.annoprov
                       and   m.numero_provvedimento=r.nprov 
                       and   m.numero_mandato=0
                       and   m.ente_proprietario_id=pEnte));                       
         
         commit;
         
         msgRes := 'Migrazione elenco_doc_allegati per quote documenti entrata.';
         insert into migr_elenco_doc_allegati
         (elenco_doc_id,anno_elenco,numero_elenco,stato,data_trasmissione,anno_provvedimento,numero_provvedimento,
          atto_allegato_id,ente_proprietario_id)
         (select migr_elenco_doc_id_seq.nextval,r.anno_elenco,r.n_elenco,'B',to_char(r.data_trasmissione_economato,'YYYY-MM-DD'),
                 r.annoprov,r.nprov,0, pEnte
          from registro_elenchi r
          where r.stato='P' 
          and   exists (select 1 from migr_docquo_entrata m
                        where m.fl_scarto='N'
                        and   m.anno_provvedimento=r.annoprov
                        and   m.numero_provvedimento=r.nprov 
                        and   m.numero_riscossione=0
                        and   m.ente_proprietario_id=pEnte)
          and not exists (select 1 from    migr_elenco_doc_allegati r1
                          where r1.anno_provvedimento=r.annoprov
                          and   r1.numero_provvedimento=r.nprov
                          and   r1.anno_elenco=r.anno_elenco
                          and   r1.numero_elenco=r.n_elenco
                          and   r1.ente_proprietario_id=pEnte));   
                          
          commit;
          
          msgRes := 'Migrazione elenco_doc_allegati.Aggiornamento  stato completato.';
          update migr_elenco_doc_allegati r
          set r.stato='C'                 
          where  ( exists (select 1 from migr_docquo_spesa m
                           where m.fl_scarto='N'
                           and   m.anno_provvedimento=r.anno_provvedimento
                           and   m.numero_provvedimento=r.numero_provvedimento 
                           and   m.numero_liquidazione!=0
                           and   m.numero_mandato=0
                           and   m.ente_proprietario_id=pEnte) or 
                   exists (select 1 from migr_docquo_entrata m
                           where m.fl_scarto='N'
                           and   m.anno_provvedimento=r.anno_provvedimento
                           and   m.numero_provvedimento=r.numero_provvedimento 
                           and   m.numero_accertamento!=0
                           and   m.numero_riscossione=0
                           and   m.ente_proprietario_id=pEnte) );
                           
                           
          commit;
          
          msgRes := 'Migrazione elenco_doc_allegati.Aggiornamento  estremi elenco su quote spesa.';
          update migr_docquo_spesa m
          set (elenco_doc_id,anno_elenco,numero_elenco) = 
              (select r.elenco_doc_id,r.anno_elenco,r.numero_elenco
               from migr_elenco_doc_allegati r
               where r.anno_provvedimento=m.anno_provvedimento
               and   r.numero_provvedimento=m.numero_provvedimento
               and   r.ente_proprietario_id=pEnte)
          where m.fl_scarto='N'
          and m.numero_provvedimento!=0
          and m.numero_mandato=0
          and m.ente_proprietario_id=pEnte      
          and exists (select 1 from migr_elenco_doc_allegati r
                      where r.anno_provvedimento=m.anno_provvedimento
                      and   r.numero_provvedimento=m.numero_provvedimento
                      and   r.ente_proprietario_id=pEnte);
                      
          commit;
          
          msgRes := 'Migrazione elenco_doc_allegati.Aggiornamento  estremi elenco su quote entrata.';                 
          update migr_docquo_entrata m
          set (elenco_doc_id,anno_elenco,numero_elenco) = 
              (select r.elenco_doc_id,r.anno_elenco,r.numero_elenco
               from migr_elenco_doc_allegati r
               where r.anno_provvedimento=m.anno_provvedimento
               and   r.numero_provvedimento=m.numero_provvedimento
               and   r.ente_proprietario_id=pEnte)
          where m.fl_scarto='N'
          and m.numero_provvedimento!=0 
          and m.numero_riscossione=0 
          and m.ente_proprietario_id=pEnte    
          and exists (select 1 from migr_elenco_doc_allegati r
                      where r.anno_provvedimento=m.anno_provvedimento
                      and   r.numero_provvedimento=m.numero_provvedimento
                      and   r.ente_proprietario_id=pEnte);                   
          commit;            


          msgRes := 'Migrazione elenco_doc_allegati.Aggiornamento  tipo_provvedimento da migr_docquo_spesa.';
          update migr_elenco_doc_allegati r
          set r.tipo_provvedimento=(select distinct tipo_provvedimento from migr_docquo_spesa q 
                                    where q.fl_scarto='N' 
                                    and   q.elenco_doc_id=r.elenco_doc_id
                                    and   q.ente_proprietario_id=pEnte)                 
          where  r.tipo_provvedimento is null 
          and    r.ente_proprietario_id=pEnte
          and exists (select 1 from migr_docquo_spesa m
                      where m.fl_scarto='N'
                        and   m.anno_provvedimento=r.anno_provvedimento
                        and   m.numero_provvedimento=r.numero_provvedimento
                        and   m.elenco_doc_id=r.elenco_doc_id
                        and   m.ente_proprietario_id=pEnte);
          
           commit;  
             
          msgRes := 'Migrazione elenco_doc_allegati.Aggiornamento  tipo_provvedimento da migr_docquo_entrata.';
          update migr_elenco_doc_allegati r
          set r.tipo_provvedimento=(select distinct tipo_provvedimento from migr_docquo_entrata q 
                                    where q.fl_scarto='N' 
                                    and   q.elenco_doc_id=r.elenco_doc_id
                                    and   q.ente_proprietario_id=pEnte)                 
          where  r.tipo_provvedimento is null
            and  r.ente_proprietario_id=pEnte
            and  exists (select 1 from migr_docquo_entrata m
                         where m.fl_scarto='N'
                           and   m.anno_provvedimento=r.anno_provvedimento
                           and   m.numero_provvedimento=r.numero_provvedimento
                           and   m.elenco_doc_id=r.elenco_doc_id
                           and   m.ente_proprietario_id=pEnte);               
          
           commit;  
                            
         pCodRes := 0;
         pMsgRes := 'Elaborazione OK.Elenco documenti allegati migrati.';        
                                      
        
  exception
    when others then
      pMsgRes      :=  msgRes || 'Errore ' ||
                       SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;
 END migrazione_elenco_doc_allegati;   
 
 
procedure migrazione_atto_allegato(pEnte number,
                                   pCodRes              out number,
                                   pMsgRes              out varchar2)  IS
 codRes number := 0;
 msgRes  varchar2(1500) := null;
        
begin
  
  msgRes := 'Inizio migrazione atto_allegato.';
  begin
         msgRes := 'Pulizia tabelle di migrazione atto_allegato.';
         DELETE FROM migr_atto_allegato WHERE FL_MIGRATO = 'N' and ente_proprietario_id=pEnte;
         DELETE FROM migr_atto_allegato_sog WHERE FL_MIGRATO = 'N' and ente_proprietario_id=pEnte;
                 
         update migr_elenco_doc_allegati set atto_allegato_id=0
         where  fl_migrato='N' and atto_allegato_id!=0 and ente_proprietario_id=pEnte;
         
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
  insert into migr_atto_allegato      
  (atto_allegato_id,
   tipo_provvedimento,
   anno_provvedimento,
   numero_provvedimento,
   numero_provvedimento_calcolato,
   sac_provvedimento,
   settore, -- DAVIDE 10.02.016 - aggiunta gestione a NULL di questo campo
   causale,
   annotazioni,
   note,
   pratica,
   responsabile_amm,
   responsabile_cont,
   altri_allegati,
   dati_sensibili,
   data_scadenza,
   causale_sospensione,
   data_sospensione,
   data_riattivazione,
   codice_soggetto,
   stato, -- default COMPLETATO - DAVIDE 11.02.016
   utente_creazione,
   ente_proprietario_id,
   numero_titolario,anno_titolario,versione)
  (select  migr_atto_allegato_id_seq.nextval,
           m.tipo_provvedimento,m.anno_provvedimento,m.numero_provvedimento,m.numero_provvedimento,m.sac_provvedimento,
      -- DAVIDE 10.02.016 - aggiunta gestione a NULL del campo settore       
      --     'ATTO ALLEGATO ELENCHI DOCUMENTI',null,null,null,null,null,null,'N',
           null,'ATTO ALLEGATO ELENCHI DOCUMENTI',null,null,null,null,null,null,'N',
           null,null,null,null,0,'C','migr_documenti',pEnte, null,null,null
    from 
    (select distinct m.tipo_provvedimento,m.anno_provvedimento,m.numero_provvedimento,m.sac_provvedimento               
     from migr_elenco_doc_allegati  m
     where m.fl_migrato='N' 
     and   m.ente_proprietario_id=pEnte) m
  ); 
  commit;
  
  msgRes := 'Aggiornamento tabella migrazione elenco_doc_allegati per atto_alleggato_id.';
  update migr_elenco_doc_allegati e
  set e.atto_allegato_id=(select a.atto_allegato_id from migr_atto_allegato a
                          where a.anno_provvedimento=e.anno_provvedimento
                          and   a.numero_provvedimento=e.numero_provvedimento
                          and   a.tipo_provvedimento=e.tipo_provvedimento
                          and   nvl(a.sac_provvedimento,'X')=nvl(e.sac_provvedimento  ,'X')
                          and   a.fl_migrato='N'
                          and   a.ente_proprietario_id=pEnte)
  where e.fl_migrato='N' 
  and   e.ente_proprietario_id=pEnte
  and exists (select 1 from migr_atto_allegato a
          where a.anno_provvedimento=e.anno_provvedimento
          and   a.numero_provvedimento=e.numero_provvedimento
          and   a.tipo_provvedimento=e.tipo_provvedimento
          and   nvl(a.sac_provvedimento,'X')=nvl(e.sac_provvedimento  ,'X')  
          and   a.fl_migrato='N'
          and   a.ente_proprietario_id=pEnte);
  commit;
  
  msgRes := 'Aggiornamento tabella migrazione atto_allegato per stato=D.';
  update migr_atto_allegato a
  set a.stato='D'
  where a.fl_migrato='N'
  and   a.ente_proprietario_id=pEnte
  and   exists (select 1 from migr_elenco_doc_allegati e
                where e.fl_migrato='N'
                and   e.atto_allegato_id=a.atto_allegato_id
                and   e.stato='B'
                and   e.ente_proprietario_id=pEnte);
  commit;
                
  pCodRes := 0;
  pMsgRes := 'Elaborazione OK.Elenco documenti allegati migrati.';   
 
 
exception
    when others then
      pMsgRes      :=  msgRes || 'Errore ' ||
                       SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;  
end migrazione_atto_allegato;
        
      
      
 procedure migrazione_documenti(pEnte number,
                                pAnnoEsercizio varchar2, 
                                pLoginOperazione varchar2, 
                                pCodRes              out number,
                                pMsgRes              out varchar2) is
                                
  codRes number:=0;
  msgRes varchar2(1500):=null;
  ERROR_DOCUMENTO EXCEPTION;
  cDocInseriti number:=0;
  cDocScartati number:=0;
  
 begin
   
  -- insert migr_doc_spesa
  migrazione_doc_spesa(pEnte,pAnnoEsercizio,
                       codRes,cDocInseriti,cDocScartati,msgRes);                                                                
  if codRes!=0 then
      raise ERROR_DOCUMENTO;
  end if;
  
  -- insert migr_docquo_spesa
  migrazione_docquo_spesa(pEnte,pAnnoEsercizio,
                       codRes,cDocInseriti,cDocScartati,msgRes);                                                                
  if codRes!=0 then
      raise ERROR_DOCUMENTO;
  end if;
  
  -- insert migr_doc_entrata
  migrazione_doc_entrata(pEnte,pAnnoEsercizio,
                         codRes,cDocInseriti,cDocScartati,msgRes);                                                                
  if codRes!=0 then
      raise ERROR_DOCUMENTO;
  end if;
  
  -- insert migr_docquo_entrata
  migrazione_docquo_entrata(pEnte,pAnnoEsercizio,
                            codRes,cDocInseriti,cDocScartati,msgRes);                                                                
  if codRes!=0 then
      raise ERROR_DOCUMENTO;
  end if;
  
  -- insert migr_relaz_documenti
  migrazione_relaz_documenti(pEnte,codRes,msgRes);                                                                
  if codRes!=0 then
      raise ERROR_DOCUMENTO;
  end if;
  
  -- insert migr_elenco_doc_allegati
  migrazione_elenco_doc_allegati(pEnte,codRes,msgRes);                                                                
  if codRes!=0 then
      raise ERROR_DOCUMENTO;
  end if;
  
  -- insert migr_atto_allegato
  migrazione_atto_allegato(pEnte,codRes,msgRes);                                                                
  if codRes!=0 then
      raise ERROR_DOCUMENTO;
  end if;
  
  pCodRes:=0;
  pMsgRes:='Elaborazione OK.Documenti Migrati.';
                       
  exception
     when ERROR_DOCUMENTO then
      pMsgRes    := msgRes;
      pCodRes    := -1;
      rollback;
    when others then
      pMsgRes      :=  msgRes || 'Errore ' ||
                       SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;
      rollback;                          
 end  migrazione_documenti;
 
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
            pMsgRes := 'proc migrazione_provvedimento.Uno o più parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
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
        
        -- DELIBERE
        insert into migr_provvedimento
        ( provvedimento_id, anno_provvedimento, numero_provvedimento, tipo_provvedimento, oggetto_provvedimento,stato_provvedimento, ente_proprietario_id)
        (Select migr_provvedimento_id_seq.nextval,
                d.anno_provvedimento, d.numero_provvedimento,d.tipo_provvedimento,d.oggetto_provvedimento, d.stato_provvedimento, pEnte from
                  ((((((select 
                    --count(*) 
                    --distinct staoper
                    d.annoprov anno_provvedimento,to_number(d.nprov) numero_provvedimento,codprov||'||' tipo_provvedimento, d.oggetto oggetto_provvedimento, d.staoper stato_provvedimento
                    from 
                    bilancio.DELIBERE d
                    where d.annoprov=pAnnoEsercizio
                    and staoper in ('P','D')
                  minus
                    -- definiti in impegni
                    -- 7678
                    -- per 2015 873
                    select distinct elem.anno_provvedimento,elem.numero_provvedimento, elem.tipo_provvedimento, elem.oggetto_provvedimento, elem.stato_provvedimento
                    from migr_impegno elem
                    where elem.ente_proprietario_id=pEnte
                    and elem.anno_provvedimento=pAnnoEsercizio)
                  MINUS
                    -- migrati con accertamenti
                    -- 1357
                    SELECT DISTINCT
                    elem.anno_provvedimento
                    ,elem.numero_provvedimento
                    ,elem.tipo_provvedimento
                    ,ELEM.OGGETTO_PROVVEDIMENTO
                    ,elem.stato_provvedimento
                    from migr_accertamento elem where elem.ente_proprietario_id=pEnte
                    and anno_provvedimento = pAnnoEsercizio)
                  MINUS
                    -- migrati con mutui
                    -- 0 per anno 2015
                    SELECT DISTINCT
                    elem.anno_provvedimento
                    ,elem.numero_provvedimento
                    ,elem.tipo_provvedimento
                    ,ELEM.OGGETTO_PROVVEDIMENTO
                    ,elem.stato_provvedimento
                    from migr_mutuo elem where elem.ente_proprietario_id=pEnte
                    and anno_provvedimento = pAnnoEsercizio)
                  MINUS
                    -- migrati con liquidazioni (7363)
                    SELECT DISTINCT
                      elem.anno_provvedimento
                      ,elem.numero_provvedimento
                      ,elem.tipo_provvedimento
                      ,ELEM.OGGETTO_PROVVEDIMENTO
                      ,elem.stato_provvedimento
                      from migr_liquidazione elem where elem.ente_proprietario_id=pEnte
                      and anno_provvedimento = pAnnoEsercizio)
                  MINUS
                     -- migrati con docquo spesa (1405)
                    SELECT DISTINCT
                      elem.anno_provvedimento
                      ,elem.numero_provvedimento
                      ,elem.tipo_provvedimento
                      ,ELEM.OGGETTO_PROVVEDIMENTO
                      ,elem.stato_provvedimento
                      from migr_docquo_spesa elem where elem.ente_proprietario_id=pEnte
                      and anno_provvedimento = pAnnoEsercizio)
                  MINUS
                     -- migrati con docquo spesa (73)
                    SELECT DISTINCT
                      elem.anno_provvedimento
                      ,elem.numero_provvedimento
                      ,elem.tipo_provvedimento
                      ,ELEM.OGGETTO_PROVVEDIMENTO
                      ,elem.stato_provvedimento
                      from migr_docquo_entrata elem where elem.ente_proprietario_id=pEnte
                      and anno_provvedimento = pAnnoEsercizio)d
          );
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

   procedure migrazione_iva(pEnte number,pAnnoEsercizio varchar2,pLoginOperazione varchar2,pCodRes out number,pMsgRes out varchar2)
     is
     begin
       pCodRes :=0;
       pMsgRes :='Procedura non implementata.';
     end;



        procedure migrazione_ordinativo(
   pAnnoEsercizio varchar2,
   pEnte number,
   pLoginOperazione varchar2,
   pCodRes out number,
   pMsgRes out varchar2) is
   begin
       pCodRes :=0;
       pMsgRes :='Procedura non implementata.';
   end;
   
end PCK_MIGRAZIONE_SIAC;
/
