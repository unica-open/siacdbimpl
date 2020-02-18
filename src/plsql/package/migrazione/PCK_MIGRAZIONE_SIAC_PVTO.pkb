CREATE OR REPLACE PACKAGE BODY PCK_MIGRAZIONE_SIAC IS

procedure migrazione_cpu(p_anno_esercizio varchar2,p_ente number,pCodRes out number, pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;

  -- 03.12.2015 Sofia diCuiImpegnato
  excCaricadicui  EXCEPTION;
begin
    msgRes:='Pulizia migr_capitolo_uscita CAP-UP.';
    -- pulizia tabella migrazione per capitoli di previsione d'uscita
    delete migr_capitolo_uscita
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-UP'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

     -- pulizia tabella migr_capitolo_eccezione Anna V. 04/07/2016
      delete migr_capitolo_eccezione
       where anno_esercizio = p_anno_esercizio
       and eu = 'U' and tipo_capitolo='P'
       and ente_proprietario_id=p_ente;

      --insert nella tabella migr_capitolo_eccezione Anna V. 04/07/2016
      insert into migr_capitolo_eccezione
       (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
        numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
      select distinct 'P','U',p_anno_esercizio,cAnno.Nro_Capitolo_77,0,'1','N','FPV',p_ente
       from prev_peg cAnno
       where cAnno.anno_ese=p_anno_esercizio-1
       and   cAnno.Tipo_Int_77='U'
       and   cAnno.Tipo_Cap_Gemello='FPV'
      union
      select distinct 'P','U',p_anno_esercizio,cAnno.Nro_Capitolo_77,0,'1','N','FSC',p_ente
       from prev_peg cAnno
       where cAnno.anno_ese=p_anno_esercizio-1
       and   cAnno.Tipo_Int_77='U'
       and   cAnno.nro_capitolo_77 in (15315,16327);

     commit;

     -- 03.12.2015 Sofia diCuiImpegnato
     msgRes:='Gestione d118_prev_usc_impegnato.';
     d118_di_cui_gia_impegnato(p_anno_esercizio, codRes, msgRes);
     if codRes!=0 then
       RAISE excCaricadicui;
     end if;


  msgRes:='Inserimento migr_capitolo_uscita CAP-UP da prev_peg.';
  insert into migr_capitolo_uscita
  ( capusc_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
    descrizione,descrizione_articolo, titolo,macroaggregato,missione,programma,
    pdc_fin_quarto, pdc_fin_quinto,note,
    trasferimenti_comunitari,funzioni_delegate,
    flag_per_memoria,flag_rilevante_iva,
    tipo_finanziamento, tipo_vincolo, tipo_fondo,
    siope_livello_1,siope_livello_2,siope_livello_3,
    classificatore_1,classificatore_2,classificatore_3,classificatore_4,
    classificatore_5,classificatore_6,classificatore_7,classificatore_8,
    classificatore_9,classificatore_10,classificatore_11,classificatore_12,
    classificatore_13,classificatore_14,classificatore_15,
    centro_resp,cdc,
    classe_capitolo,flag_impegnabile,
    stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
    stanziamento,stanziamento_res,stanziamento_cassa,
    stanziamento_iniziale_anno2,stanziamento_anno2,
    stanziamento_iniziale_anno3,stanziamento_anno3,
    dicuiimpegnato_anno1, dicuiimpegnato_anno2, dicuiimpegnato_anno3, -- 03.12.2015 Sofia diCuiImpegnato
    ente_proprietario_id,
  cofog,                -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Uscita
  spesa_ricorrente)     -- DAVIDE - 22.08.2016
    (select  migr_capusc_id_seq.nextval,'CAP-UP',cAnno.Anno_Capitolo_77,cAnno.nro_capitolo_77,0,1,
             cAnno.ogg1||' '||cAnno.ogg2||' '||cAnno.ogg3||' '||cAnno.ogg4||' '||cAnno.ogg5,null,
             decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
             decode(nvl(macr118.macroaggreg,' '),' ',null, macr118.titolo||macr118.macroaggreg||'0000'),
             decode(nvl(miss118.missione, ' ' ),' ' , null,miss118.missione),
             decode(nvl(prog118.programma, ' ' ),' ' , null,prog118.missione||prog118.programma),
             decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
             decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
             null,
             decode(nvl(to_char(trans_118.codice),' '),' ',null,to_char(trans_118.codice)),'N',--30/06/2016 aggiunta valorizzazione trasferimenti EU e funzioni delegate Anna V
             'N', 'N',
             decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
             null,
             decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
    -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.codice_gest,
  -- DAVIDE - 16.12.015 - Fine
             decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
             decode(nvl(cAnno.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
             decode(nvl(cAnno.Partita_Giro, ' ' ),' ' , null,'N',null,'S','1||Partita di giro'), --classif3
			 
  -- DAVIDE - 12.01.2017 - Imposta valori classificatori 4, 5 e 6 come da mail Valenzano del 09.01.2017
             --null,null,null,null,
			 decode(nvl(cAnno.tipo_cap_gemello, ' ' ),' ' , null,'R','1||Riaccertato','FPV','2||Fondo pluriennale vincolato'), --classif4
			 decode(cAnno.cap_origine,0 , null,cAnno.cap_origine||'||'||cAnno.cap_origine), --classif5
			 decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ),  --classif6
			 '2||No', --classif7 
  -- DAVIDE - 12.01.2017 - Fine	
			 
			 null,null,null,
             decode(nvl(exBilancio.Nro_Intervento_77,0),0,null,
                    exBilancio.Tipo_Int_77||'/'||exBilancio.Cod_Bilancio||'||'||
                    exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5), --classif11
             decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
             decode(nvl(cAnno.Cod_Stat4,0 ), 0 ,null,
                    cAnno.Cod_Stat4||'||'||cAnno.Cod_Stat4 ), --classif13
             decode(nvl(obiettivo.codice,0 ), 0 ,null,
                    obiettivo.codice||'||'||obiettivo.descr ), --classif14
             decode(nvl(programma.codice,0 ), 0 ,null,
                    programma.codice||'||'||programma.descr ), --classif15
             Cdr.codice,Cdc.codice,
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
             nvl(cAnno.Importo,0), 0,nvl(cAnno.importo_cassa,0), -- 23.06.2016 Sofia aggiunti NVL
             nvl(cAnno.importo,0), 0,nvl(cAnno.importo_cassa,0), -- 23.06.2016 Sofia aggiunti NVL
             nvl(cAnno2.importo,0),nvl(cAnno2.importo,0),nvl(cAnno3.importo,0),nvl(cAnno3.importo,0),
             nvl(cdicuiimpe.gia_impegnato_anno1,0), nvl(cdicuiimpe.gia_impegnato_anno2,0), nvl(cdicuiimpe.gia_impegnato_anno3,0), -- 03.12.2015 Sofia diCuiImpegnato

             p_ente,
       trim(cap118.cofog),                   -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Uscita
       ltrim(to_char(cap118.eu_ricor, '99')) -- DAVIDE - 22.08.2016
     from prev_peg cAnno, prev_peg cAnno2,prev_peg cAnno3, d118_prev_usc cap118,
          d118_titusc tit118, d118_macroaggreg macr118,
          d118_missioni miss118,d118_programmi prog118,
          d118_piano_conti_usc pdcFin,tipologia_capitolo tipoFin ,
          d118_transazione_ue trans_118,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,prev_interventi77 exBilancio,
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc,  migr_capitolo_eccezione capEcc,
          d118_prev_usc_impegnato cdicuiimpe -- 03.12.2015 Sofia diCuiImpegnato
     where cAnno.anno_ese=p_anno_esercizio-1 and
           cAnno.Anno_Capitolo_77=p_anno_esercizio and
           cAnno.Tipo_Int_77='U' and
           cAnno2.anno_ese (+) =cAnno.anno_ese and
           cAnno2.Anno_Capitolo_77 (+) =to_number(cAnno.Anno_Capitolo_77)+1 and
           cAnno2.Tipo_Int_77 (+) =cAnno.Tipo_Int_77 and
           cAnno2.nro_capitolo_77 (+) = cAnno.nro_capitolo_77 and
           cAnno3.anno_ese (+) =cAnno.anno_ese and
           cAnno3.Anno_Capitolo_77 (+)=to_number(cAnno.Anno_Capitolo_77)+2 and
           cAnno3.Tipo_Int_77 (+) =cAnno.Tipo_Int_77 and
           cAnno3.nro_capitolo_77 (+) = cAnno.nro_capitolo_77 and
           cap118.anno_esercizio=cAnno.anno_capitolo_77 and
           cap118.anno_capitolo=cAnno.anno_capitolo_77 and
           cap118.nro_capitolo=cAnno.nro_capitolo_77 and
           cap118.nro_articolo=0 and
           tit118.anno_esercizio   (+) =cap118.anno_esercizio and
           tit118.titolo           (+) =cap118.titolo and
           macr118.anno_esercizio  (+) =cap118.Anno_Esercizio and
           macr118.titolo          (+) =cap118.titolo and
           macr118.macroaggreg     (+) =cap118.macroaggreg and
           miss118.anno_esercizio  (+) =cap118.anno_esercizio and
           miss118.missione        (+) = cap118.missione and
           prog118.anno_esercizio  (+) = cap118.anno_esercizio and
           prog118.missione        (+) = cap118.missione and
           prog118.programma       (+) = cap118.programma and
           pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
           pdcFin.Conto            (+) =cap118.conto and
           trans_118.codice        (+) =cap118.trans_eu and --transazione europea
           tipoFin.Anno_Esercizio  (+) = cAnno.anno_capitolo_77 and -- tipo_finanziamento
           tipoFin.Tipologia       (+) = 'TF' and
           tipoFin.Procedura       (+) = 5 and
           tipoFin.Codice          (+) = cAnno.Tipo_Fin and
           tipoFondi.Anno_Esercizio (+) = cAnno.anno_capitolo_77 and -- tipo_fondo
           tipoFondi.Tipologia      (+) = 'TS' and
           tipoFondi.Procedura      (+) = 5 and
           tipoFondi.Codice         (+) = cAnno.Tipo_Spesa and
           classif1.anno_esercizio  (+) = cAnno.Anno_Capitolo_77 and -- classif1
           classif1.tipologia       (+) = 'TC' and
           classif1.procedura       (+) = 5 and
           classif1.codice          (+) = cAnno.tipologia_cap_77 and
           exBilancio.Anno_Intervento_77 (+) = cAnno.Anno_Intervento_77 and -- classif11
           exBilancio.Nro_Intervento_77  (+) = cAnno.Nro_Intervento_77 and
           exBilancio.Tipo_Int_77        (+) = cAnno.Tipo_Int_77 and
           codStat1.Anno_Peg             (+) = cAnno.Anno_Ese and   -- classif12
           codStat1.Codice               (+) = cAnno.Cod_Stat1 and
           obiettivo.tipo_tabella        (+) = '51' and             -- classif14
           obiettivo.codice              (+) = cAnno.Obbiettivo and
           programma.tipo_tabella        (+) = '52' and             -- classif15
           programma.codice              (+) = cAnno.Programma and
           Cdr.codice = substr(cAnno.Up,1,2) and
           Cdc.codice = cAnno.Up and
           capEcc.Tipo_Capitolo (+)='P' and
           capEcc.Eu (+)  ='U' and
           capEcc.Anno_Esercizio  (+) = cAnno.Anno_Capitolo_77 and
           capEcc.numero_capitolo (+) = cAnno.nro_capitolo_77 and
           capEcc.numero_articolo (+) = 0 and
           capEcc.numero_ueb      (+) = 1 and
           capEcc.ente_proprietario_id (+)=p_ente and -- 07.01.2016 Sofia aggiunto and
           cdicuiimpe.Anno_creazione (+) = cAnno.Anno_Capitolo_77 and -- 03.12.2015 Sofia diCuiImpegnato
           cdicuiimpe.Anno_Esercizio (+) = cAnno.Anno_Capitolo_77 and
           cdicuiimpe.nro_capitolo (+) = cAnno.nro_capitolo_77 and
           cdicuiimpe.nro_articolo (+) = 0);
  commit;
  
  -- DAVIDE - 12.01.2017 - popola il classificatore 7 con l'update come da mail Valenzano del 09.01.2017
  update migr_capitolo_uscita migrp
     set classificatore_7='1||Si'  
   where exists (select 1 from as_movimenti_llpp llpp
                 where llpp.anno_capitolo=migrp.anno_esercizio
                 and   llpp.nro_capitolo=migrp.numero_capitolo
   				       and   llpp.tipo_eu='U')
	 and migrp.ente_proprietario_id=p_ente
	 and migrp.tipo_capitolo='CAP-UP';
	 
    commit;
  -- DAVIDE - 12.01.2017 - Fine
  
  /* 26.11.2015 Sofia commentata perche non esiste più la tabella
  msgRes:='Inserimento migr_capitolo_uscita CAP-UP da prev_peg_residui_noriac.';

  insert into migr_capitolo_uscita
  ( capusc_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
    descrizione,descrizione_articolo, titolo,macroaggregato,missione,programma,
    pdc_fin_quarto, pdc_fin_quinto,note,
    flag_per_memoria,flag_rilevante_iva,
    tipo_finanziamento, tipo_vincolo, tipo_fondo,
    siope_livello_1,siope_livello_2,siope_livello_3,
    classificatore_1,classificatore_2,classificatore_3,classificatore_4,
    classificatore_5,classificatore_6,classificatore_7,classificatore_8,
    classificatore_9,classificatore_10,classificatore_11,classificatore_12,
    classificatore_13,classificatore_14,classificatore_15,
    centro_resp,cdc,
    classe_capitolo,flag_impegnabile,
    stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
    stanziamento,stanziamento_res,stanziamento_cassa,
    stanziamento_iniziale_anno2,stanziamento_anno2,
    stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id)
    (select  migr_capusc_id_seq.nextval,'CAP-UP',cAnno.Anno_Capitolo_77,cAnno.nro_capitolo_77,0,1,
             cAnno.ogg1||' '||cAnno.ogg2||' '||cAnno.ogg3||' '||cAnno.ogg4||' '||cAnno.ogg5,null,
             decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
             decode(nvl(macr118.macroaggreg,' '),' ',null, macr118.titolo||macr118.macroaggreg||'0000'),
             decode(nvl(miss118.missione, ' ' ),' ' , null,miss118.missione),
             decode(nvl(prog118.programma, ' ' ),' ' , null,prog118.missione||prog118.programma),
             decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
             decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
             null,'N', 'N',
             decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
             null,
             decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
             null,null,null,
             decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
             decode(nvl(cAnno.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
             decode(nvl(cAnno.Partita_Giro, ' ' ),' ' , null,'N',null,'S','1||Partita di giro'), --classif3
             null,null,null,null,null,null,null,
             decode(nvl(exBilancio.Nro_Intervento_77,0),0,null,
                    exBilancio.Tipo_Int_77||'/'||exBilancio.Cod_Bilancio||'||'||
                    exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5), --classif11
             decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
             decode(nvl(cAnno.Cod_Stat4,0 ), 0 ,null,
                    cAnno.Cod_Stat4||'||'||cAnno.Cod_Stat4 ), --classif13
             decode(nvl(obiettivo.codice,0 ), 0 ,null,
                    obiettivo.codice||'||'||obiettivo.descr ), --classif14
             decode(nvl(programma.codice,0 ), 0 ,null,
                    programma.codice||'||'||programma.descr ), --classif15
             Cdr.codice,Cdc.codice,
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
             cAnno.Importo, 0,cAnno.importo,
             cAnno.importo, 0,cAnno.importo,
             0,0,0,0,p_ente
     from prev_peg_residui_noriac cAnno, d118_prev_usc cap118,
          d118_titusc tit118, d118_macroaggreg macr118,
          d118_missioni miss118,d118_programmi prog118,
          d118_piano_conti_usc pdcFin,tipologia_capitolo tipoFin ,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,prev_interventi77 exBilancio,
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc,  migr_capitolo_eccezione capEcc
     where cAnno.anno_ese=p_anno_esercizio-1 and
           cAnno.Anno_Capitolo_77=p_anno_esercizio and
           cAnno.Tipo_Int_77='U' and
           cap118.anno_esercizio (+) =cAnno.anno_capitolo_77 and
           cap118.anno_capitolo  =cAnno.anno_capitolo_77 and
           cap118.nro_capitolo   =cAnno.nro_capitolo_77 and
           cap118.nro_articolo   =0 and
           tit118.anno_esercizio   (+) =cap118.anno_esercizio and
           tit118.titolo           (+) =cap118.titolo and
           macr118.anno_esercizio  (+) =cap118.Anno_Esercizio and
           macr118.titolo          (+) =cap118.titolo and
           macr118.macroaggreg     (+) =cap118.macroaggreg and
           miss118.anno_esercizio  (+) =cap118.anno_esercizio and
           miss118.missione        (+) = cap118.missione and
           prog118.anno_esercizio  (+) = cap118.anno_esercizio and
           prog118.missione        (+) = cap118.missione and
           prog118.programma       (+) = cap118.programma and
           pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
           pdcFin.Conto            (+) =cap118.conto and
           tipoFin.Anno_Esercizio  (+) = cAnno.anno_capitolo_77 and -- tipo_finanziamento
           tipoFin.Tipologia       (+) = 'TF' and
           tipoFin.Procedura       (+) = 5 and
           tipoFin.Codice          (+) = cAnno.Tipo_Fin and
           tipoFondi.Anno_Esercizio (+) = cAnno.anno_capitolo_77 and -- tipo_fondo
           tipoFondi.Tipologia      (+) = 'TS' and
           tipoFondi.Procedura      (+) = 5 and
           tipoFondi.Codice         (+) = cAnno.Tipo_Spesa and
           classif1.anno_esercizio  (+) = cAnno.Anno_Capitolo_77 and -- classif1
           classif1.tipologia       (+) = 'TC' and
           classif1.procedura       (+) = 5 and
           classif1.codice          (+) = cAnno.tipologia_cap_77 and
           exBilancio.Anno_Intervento_77 (+) = cAnno.Anno_Intervento_77 and -- classif11
           exBilancio.Nro_Intervento_77  (+) = cAnno.Nro_Intervento_77 and
           exBilancio.Tipo_Int_77        (+) = cAnno.Tipo_Int_77 and
           codStat1.Anno_Peg             (+) = cAnno.Anno_Ese and   -- classif12
           codStat1.Codice               (+) = cAnno.Cod_Stat1 and
           obiettivo.tipo_tabella        (+) = '51' and             -- classif14
           obiettivo.codice              (+) = cAnno.Obbiettivo and
           programma.tipo_tabella        (+) = '52' and             -- classif15
           programma.codice              (+) = cAnno.Programma and
           Cdr.codice = substr(cAnno.Up,1,2) and
           Cdc.codice = cAnno.Up and
           capEcc.Tipo_Capitolo (+)='P' and
           capEcc.Eu (+)  ='U' and
           capEcc.Anno_Esercizio  (+) = cAnno.Anno_Capitolo_77 and
           capEcc.numero_capitolo (+) = cAnno.nro_capitolo_77 and
           capEcc.numero_articolo (+) = 0 and
           capEcc.numero_ueb      (+) = 1 and
           not exists (select 1 from migr_capitolo_uscita m
                       where m.anno_esercizio=p_anno_esercizio
                       and   m.numero_capitolo=cAnno.nro_capitolo_77
                       and   m.numero_articolo=0
                       and   m.tipo_capitolo='CAP-UP'
                    -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
             and   m.ente_proprietario_id=p_ente));
     commit;
     */
     msgRes:='Aggiornamento migr_capitolo_uscita per stanz. residui CAP-UP da as_capitoli.';
     -- update per stanziamenti res e cassa
     /*ANNA VALENZANO*/
     /*update migr_capitolo_uscita m
     set (m.stanziamento_iniziale_res)=
     (select nvl(sum(res.residui_da_riportare ),0)
      from  as_capitoli res
      where res.anno_peg=m.anno_esercizio-1 and
            res.nro_capitolo=m.numero_capitolo and
            res.anno_capitolo<=res.anno_peg and
            res.tipo_eu='U')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP' and
           0!=(select count(*)
               from as_capitoli res
               where res.anno_peg=m.anno_esercizio-1 and
                     res.anno_capitolo<=res.anno_peg and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='U')
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente;*/
     
/*ANNA VALENZANO 19/05/2016 sostituito nella prima where res.anno_peg=m.anno_esercizio-1
con res.anno_peg=m.anno_esercizio*/
/*     update migr_capitolo_uscita m
     set (m.stanziamento_iniziale_res)=
     (select nvl(sum(res.stanz_definitivo ),0)
      from  as_capitoli res
--      where res.anno_peg=m.anno_esercizio and 27.01.2017
      where res.anno_peg=m.anno_esercizio-1 and
            res.nro_capitolo=m.numero_capitolo and
            res.anno_capitolo<res.anno_peg and
            res.tipo_eu='U')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP' and
           0!=(select count(*)
               from as_capitoli res
--               where res.anno_peg=m.anno_esercizio and 27.01.2017 Sofia
               where res.anno_peg=m.anno_esercizio-1 and               
                     res.anno_capitolo<res.anno_peg and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='U')
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente;  31.01.2017 Sofia sostituita con la successiva dopo mail di Valenzano */
     
     -- 31.01.2017 Sofia - nuovo calcolo sui residui presunti in fase di migrazione anche per previsione
     update migr_capitolo_uscita m
     set (m.stanziamento_iniziale_res)=
     (select nvl(sum(res.residui_da_riportare),0)
      from  as_capitoli res
      where res.anno_peg=m.anno_esercizio-1 and
            res.nro_capitolo=m.numero_capitolo and
            res.anno_capitolo<=res.anno_peg and
            res.tipo_eu='U')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP' and
           0!=(select count(*)
               from as_capitoli res
               where res.anno_peg=m.anno_esercizio-1 and
                     res.anno_capitolo<=res.anno_peg and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='U')
     and m.ente_proprietario_id=p_ente;     
     commit;
      /*ANNA VALENZANO*/
     /*msgRes:='Aggiornamento migr_capitolo_uscita per stanz. residui CAP-UP da residui_80000.';
     update migr_capitolo_uscita m
     set (m.stanziamento_iniziale_res)=
     (select nvl(sum(res.residuo ),0)
      from  residui_80000 res
      where res.anno_capitolo=m.anno_esercizio and
            res.nro_capitolo=m.numero_capitolo and
            res.tipo_eu='U')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP' and
           0!=(select count(*)
               from residui_80000 res
               where res.anno_capitolo=m.anno_esercizio and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='U')
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente;

     commit;                */

  
     msgRes:='Aggiornamento migr_capitolo_uscita per stanz. cassa CAP-UP.';
     update migr_capitolo_uscita  m
         --ANNA V 30/06/2016 commentato perchè in fase di caricamento lo stanziamento_iniziale_cassa é uguale allo stanziamento_cassa
     set --m.stanziamento_iniziale_cassa=m.stanziamento_iniziale_cassa+m.stanziamento_iniziale_res,
         m.stanziamento_res=m.stanziamento_iniziale_res
         -- ANNA V. commentato perchè è stato inserito l'importo cassa in preventivo
         --m.stanziamento_cassa=m.stanziamento_cassa+m.stanziamento_iniziale_res
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP' and m.stanziamento_iniziale_res!=0
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente;

     
     msgRes:='Aggiornamento migr_capitolo_uscita per funzioni delegate CAP-UP.'; --ANNA V 30/06/2016

     update migr_capitolo_uscita  m
     set m.funzioni_delegate='S'
     where exists (select 1 from prev_peg a where
                                             a.tipo_spesa='DE' and a.tipo_fin='FR'
                                             and a.tipo_int_77='U' and a.anno_capitolo_77=m.anno_esercizio
                                             and m.anno_esercizio=p_anno_esercizio
                                             and a.nro_capitolo_77=m.numero_capitolo)
     and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP'
     and m.ente_proprietario_id=p_ente;

     /*Anna Valenzano--19/07/2016 richiesto di avere gli stanziamenti a zero per
                      il 2017 e 2018 e anche il di_cui_gia_impegnato su questi anni*/
    /* update migr_capitolo_uscita m set m.stanziamento_iniziale_anno2=0, m.stanziamento_anno2=0,
     m.stanziamento_iniziale_anno3=0, m.stanziamento_anno3=0,m.dicuiimpegnato_anno2=0,m.dicuiimpegnato_anno3=0
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP'
     and m.ente_proprietario_id=p_ente;  31.01.2017 Sofia commentato in seguito a mail di Valenzano */

     update migr_capitolo_uscita m set m.trasferimenti_comunitari=8
     where m.trasferimenti_comunitari!=3 and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UP'
     and m.ente_proprietario_id=p_ente;


   pCodRes:=codRes;
   pMsgRes:='Migrazione capitolo uscita previsione OK.';
   commit;

exception
   -- 03.12.2015 Sofia diCuiImpegnato
   when excCaricadicui then
      pMsgRes := msgRes;
      pCodRes := -1;
      rollback;
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_cpu;


procedure migrazione_cgu(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
--aggiungere la valorizzazione degli stanziamenti di cassa Anna V --
--la transazione europea Anna V --Fatto
--le funzioni delegate Anna V --Fatto
--aggiungere la parte di cancellazione e insert su migr_capitolo_eccezione --FATTO
begin
    msgRes:='Pulizia migr_capitolo_uscita CAP-UG.';
    -- pulizia tabella migrazione per capitoli di gestione d'uscita
    delete migr_capitolo_uscita
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-UG'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

     delete migr_capitolo_eccezione
       where anno_esercizio = p_anno_esercizio
       and eu = 'U' and tipo_capitolo='G'
       and ente_proprietario_id=p_ente;


     insert into migr_capitolo_eccezione
       (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
        numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
      select distinct 'G','U',cAnno.anno_esercizio,cAnno.Nro_intervento,0,'1','N','FPV',p_ente
       from gest_intervento cAnno
       where cAnno.anno_esercizio=p_anno_esercizio
       and   cAnno.Tipo_cap='U'
       and   cAnno.Tipo_Cap_Gemello='FPV'
      union
      select distinct 'G','U',cAnno.anno_esercizio,cAnno.Nro_intervento,0,'1','N','FSC',p_ente
       from gest_intervento cAnno
       where cAnno.anno_esercizio=p_anno_esercizio
       and   cAnno.Tipo_cap='U'
       and   cAnno.nro_intervento in (15315,16327);


    commit;

    msgRes:='Inserimento migr_capitolo_uscita CAP-UG.';
    -- migr_capitolo_uscita
    insert into migr_capitolo_uscita
    ( capusc_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
      descrizione,descrizione_articolo, titolo,macroaggregato,missione,programma,
      pdc_fin_quarto, pdc_fin_quinto,note,
      trasferimenti_comunitari,funzioni_delegate,
      flag_per_memoria,flag_rilevante_iva,
      tipo_finanziamento, tipo_vincolo, tipo_fondo,
      siope_livello_1,siope_livello_2,siope_livello_3,
      classificatore_1,classificatore_2,classificatore_3,classificatore_4,
      classificatore_5,classificatore_6,classificatore_7,classificatore_8,
      classificatore_9,classificatore_10,classificatore_11,classificatore_12,
      classificatore_13,classificatore_14,classificatore_15,
      centro_resp,cdc,
      classe_capitolo, flag_impegnabile,
      stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
      stanziamento,stanziamento_res,stanziamento_cassa,
      stanziamento_iniziale_anno2,stanziamento_anno2,
      stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
      cofog,                -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Uscita
      spesa_ricorrente)     -- DAVIDE - 22.08.2016
    (select  migr_capusc_id_seq.nextval,'CAP-UG',cAnno.Anno_Intervento,cAnno.Nro_Intervento,0,1,
             cAnno.ogg1||' '||cAnno.ogg2||' '||cAnno.ogg3||' '||cAnno.ogg4||' '||cAnno.ogg5,null,
             decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
             decode(nvl(macr118.macroaggreg,' '),' ',null, macr118.titolo||macr118.macroaggreg||'0000'),
             decode(nvl(miss118.missione, ' ' ),' ' , null,miss118.missione),
             decode(nvl(prog118.programma, ' ' ),' ' , null,prog118.missione||prog118.programma),
             decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
             decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
             null,
             decode(nvl(to_char(trans_118.codice),' '),' ',null,to_char(trans_118.codice)),'N',
             'N', 'N',
             decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
             null,
             decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
  -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.codice_gest,
  -- DAVIDE - 16.12.015 - Fine
             decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
             decode(nvl(cAnno.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
             decode(nvl(cAnno.Partita_Giro, ' ' ),' ' , null,'N',null,'S','1||Partita di giro'), --classif3
			 
  -- DAVIDE - 12.01.2017 - Imposta valori classificatori 4, 6 e 7 come da mail Valenzano del 09.01.2017
             --null,null,null,null,
			 decode(nvl(cAnno.tipo_cap_gemello, ' ' ),' ' , null,'R','1||Riaccertato','FPV','2||Fondo pluriennale vincolato'), --classif4
			 decode(cAnno.cap_origine,0 , null,cAnno.cap_origine||'||'||cAnno.cap_origine), --classif5
			 decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ),  --classif6
			 '2||No', --classif7
  -- DAVIDE - 12.01.2017 - Fine	
  
			 null,null,null,
             decode(nvl(exBilancio.Nro_capitolo,0),0,null,
                    exBilancio.Tipo_Cap||'/'||exBilancio.Cod_Bilancio||'||'||
                    exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5), --classif11
             decode(nvl(codStat1.Codice,0 ), 0 ,null,codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
             decode(nvl(cAnno.Cod_Stat4,0 ), 0 ,null,cAnno.Cod_Stat4||'||'||cAnno.Cod_Stat4 ), --classif13
             decode(nvl(obiettivo.codice,0 ), 0 ,null,obiettivo.codice||'||'||obiettivo.descr ), --classif14
             decode(nvl(programma.codice,0 ), 0 ,null,programma.codice||'||'||programma.descr ), --classif15
             Cdr.codice,Cdc.codice,
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
             cAnno.Importo, 0,nvl(cAnno.Stanz_Cassa_Iniz,0),
             cAnno.importo, 0,nvl(cAnno.Stanz_Cassa_Def,0),
             nvl(cAnno2.importo,0),nvl(cAnno2.importo,0),nvl(cAnno3.importo,0),nvl(cAnno3.importo,0),p_ente,
       trim(cap118.cofog),                   -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Uscita
       ltrim(to_char(cap118.eu_ricor, '99')) -- DAVIDE - 22.08.2016
     from gest_intervento cAnno, gest_intervento cAnno2,gest_intervento cAnno3, d118_cap_usc cap118,
          d118_titusc tit118, d118_macroaggreg macr118,
          d118_missioni miss118,d118_programmi prog118,
          d118_piano_conti_usc pdcFin,tipologia_capitolo tipoFin ,
          d118_transazione_ue trans_118,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,cc_gest_capitolo exBilancio,--gest_capitolo exBilancio, 27.01.2017 Sofia
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc,  migr_capitolo_eccezione capEcc
     where cAnno.Anno_Intervento =p_anno_esercizio and
           cAnno.Anno_esercizio=p_anno_esercizio and
           cAnno.tipo_cap='U' and
           cAnno2.anno_esercizio (+) =cAnno.anno_esercizio and
           cAnno2.Anno_intervento (+) =to_number(cAnno.Anno_intervento)+1 and
           cAnno2.tipo_cap (+) =cAnno.tipo_cap and
           cAnno2.Nro_Intervento (+) = cAnno.Nro_Intervento and
           cAnno3.anno_esercizio (+) =cAnno.anno_esercizio and
           cAnno3.Anno_intervento (+) =to_number(cAnno.Anno_intervento)+2 and
           cAnno3.tipo_cap (+) =cAnno.tipo_cap and
           cAnno3.Nro_Intervento (+) = cAnno.Nro_Intervento and
           cap118.anno_esercizio=cAnno.anno_esercizio and
           cap118.anno_capitolo=cAnno.anno_esercizio and
           cap118.nro_capitolo=cAnno.Nro_Intervento and
           cap118.nro_articolo=0 and
           tit118.anno_esercizio   (+) =cap118.anno_esercizio and
           tit118.titolo           (+) =cap118.titolo and
           macr118.anno_esercizio  (+) =cap118.Anno_Esercizio and
           macr118.titolo          (+) =cap118.titolo and
           macr118.macroaggreg     (+) =cap118.macroaggreg and
           miss118.anno_esercizio  (+) =cap118.anno_esercizio and
           miss118.missione        (+) = cap118.missione and
           prog118.anno_esercizio  (+) = cap118.anno_esercizio and
           prog118.missione        (+) = cap118.missione and
           prog118.programma       (+) = cap118.programma and
           pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
           pdcFin.Conto            (+) =cap118.conto and
           trans_118.codice        (+) =cap118.trans_eu and --transazione europea
           tipoFin.Anno_Esercizio  (+) = cAnno.Anno_Esercizio and -- tipo_finanziamento
           tipoFin.Tipologia       (+) = 'TF' and
           tipoFin.Procedura       (+) = 1 and
           tipoFin.Codice          (+) = cAnno.Tipo_Finanz and
           tipoFondi.Anno_Esercizio (+) = cAnno.Anno_Esercizio and -- tipo_fondo
           tipoFondi.Tipologia      (+) = 'TS' and
           tipoFondi.Procedura      (+) = 1 and
           tipoFondi.Codice         (+) = cAnno.Tipo_Spesa and
           classif1.anno_esercizio  (+) = cAnno.Anno_Esercizio and -- classif1
           classif1.tipologia       (+) = 'TC' and
           classif1.procedura       (+) = 1 and
           classif1.codice          (+) = cAnno.tipo_intervento and
           exBilancio.Anno_Esercizio(+) = cAnno.Anno_Esercizio and -- classif11
           exBilancio.Anno_Cap      (+) = cAnno.Anno_Cap and
           exBilancio.Nro_Capitolo  (+) = cAnno.Nro_Cap and
           exBilancio.tipo_cap      (+) = cAnno.Tipo_Cap and
           exBilancio.tipo_cap      (+) = 'U' and
           codStat1.Anno_Peg             (+) = cAnno.Anno_Esercizio and   -- classif12
           codStat1.Codice               (+) = cAnno.Cod_Stat1 and
           obiettivo.tipo_tabella        (+) = '51' and             -- classif14
           obiettivo.codice              (+) = cAnno.Programma and
           programma.tipo_tabella        (+) = '52' and             -- classif15
           programma.codice              (+) = cAnno.Centro_Di_Costo and
           Cdr.codice = substr(cAnno.Up,1,2) and
           Cdc.codice = cAnno.Up and
           capEcc.Tipo_Capitolo (+)='G' and
           capEcc.Eu (+)  ='U' and
           capEcc.Anno_Esercizio  (+) = cAnno.Anno_Intervento and
           capEcc.numero_capitolo (+) = cAnno.Nro_Intervento and
           capEcc.numero_articolo (+) = 0 and
           capEcc.numero_ueb      (+) = 1 and
           capEcc.ente_proprietario_id (+)=p_ente );-- 07.01.2016 Sofia aggiunto
    commit;

    msgRes:='Inserimento migr_capitolo_uscita CAP-UG anno+1.';
     -- x capitolo che esistono da anno+1 e non in anno
    insert into migr_capitolo_uscita
    ( capusc_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
      descrizione,descrizione_articolo, titolo,macroaggregato,missione,programma,
      pdc_fin_quarto, pdc_fin_quinto,note,
      trasferimenti_comunitari,funzioni_delegate,
      flag_per_memoria,flag_rilevante_iva,
      tipo_finanziamento, tipo_vincolo, tipo_fondo,
      siope_livello_1,siope_livello_2,siope_livello_3,
      classificatore_1,classificatore_2,classificatore_3,classificatore_4,
      classificatore_5,classificatore_6,classificatore_7,classificatore_8,
      classificatore_9,classificatore_10,classificatore_11,classificatore_12,
      classificatore_13,classificatore_14,classificatore_15,
      centro_resp,cdc,
      classe_capitolo,flag_impegnabile,
      stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
      stanziamento,stanziamento_res,stanziamento_cassa,
      stanziamento_iniziale_anno2,stanziamento_anno2,
      stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
    cofog,                -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Uscita
    spesa_ricorrente)     -- DAVIDE - 22.08.2016
    (select  migr_capusc_id_seq.nextval,'CAP-UG',cAnno2.Anno_esercizio,cAnno2.Nro_Intervento,0,1,
             cAnno2.ogg1||' '||cAnno2.ogg2||' '||cAnno2.ogg3||' '||cAnno2.ogg4||' '||cAnno2.ogg5,null,
             decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
             decode(nvl(macr118.macroaggreg,' '),' ',null, macr118.titolo||macr118.macroaggreg||'0000'),
             decode(nvl(miss118.missione, ' ' ),' ' , null,miss118.missione),
             decode(nvl(prog118.programma, ' ' ),' ' , null,prog118.missione||prog118.programma),
             decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
             decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
             null,
             decode(nvl(to_char(trans_118.codice),' '),' ',null,to_char(trans_118.codice)),'N',
             'N', 'N',
             decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
             null,
             decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
  -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.codice_gest,
  -- DAVIDE - 16.12.015 - Fine
             decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
             decode(nvl(cAnno2.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
             decode(nvl(cAnno2.Partita_Giro, ' ' ),' ' , null,'N',null,'S','1||Partita di giro'), --classif3
			 
  -- DAVIDE - 12.01.2017 - Imposta valori classificatori 4, 6 e 7 come da mail Valenzano del 09.01.2017
             --null,null,null,null,
			 decode(nvl(cAnno2.tipo_cap_gemello, ' ' ),' ' , null,'R','1||Riaccertato','FPV','2||Fondo pluriennale vincolato'), --classif4
			 decode(cAnno2.cap_origine, 0 , null,cAnno2.cap_origine||'||'||cAnno2.cap_origine), --classif5
			 decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ),  --classif6
			 '2||No', --classif7 
  -- DAVIDE - 12.01.2017 - Fine	
  
             null,null,null,
             decode(nvl(exBilancio.Nro_capitolo,0),0,null,
                        exBilancio.Tipo_Cap||'/'||exBilancio.Cod_Bilancio||'||'||
                        exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5), --classif11
             decode(nvl(codStat1.Codice,0 ), 0 ,null,codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
             decode(nvl(cAnno2.Cod_Stat4,0 ), 0 ,null,cAnno2.Cod_Stat4||'||'||cAnno2.Cod_Stat4 ), --classif13
             decode(nvl(obiettivo.codice,0 ), 0 ,null,obiettivo.codice||'||'||obiettivo.descr ), --classif14
             decode(nvl(programma.codice,0 ), 0 ,null,
                    programma.codice||'||'||programma.descr ), --classif15
             Cdr.codice,Cdc.codice,
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
             nvl(cAnno.Importo,0), 0,nvl(cAnno.Stanz_Cassa_Iniz,0),
             nvl(cAnno.Importo,0), 0,nvl(cAnno.Stanz_Cassa_Def,0),
             nvl(cAnno2.importo,0),nvl(cAnno2.importo,0),nvl(cAnno3.importo,0),nvl(cAnno3.importo,0),p_ente,
       trim(cap118.cofog),                   -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Uscita
       ltrim(to_char(cap118.eu_ricor, '99')) -- DAVIDE - 22.08.2016
     from gest_intervento cAnno, gest_intervento cAnno2,gest_intervento cAnno3, d118_cap_usc cap118,
          d118_titusc tit118, d118_macroaggreg macr118,
          d118_missioni miss118,d118_programmi prog118,
          d118_piano_conti_usc pdcFin,tipologia_capitolo tipoFin ,
          d118_transazione_ue trans_118,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,cc_gest_capitolo exBilancio,--gest_capitolo exBilancio, 27.01.2017
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc, migr_capitolo_eccezione capEcc
      where cAnno2.Anno_Intervento =p_anno_esercizio+1 and
            cAnno2.Anno_esercizio=p_anno_esercizio and
            cAnno2.tipo_cap='U' and
            cAnno.anno_esercizio (+) =cAnno2.anno_esercizio and
            cAnno.Anno_intervento (+) =to_number(cAnno2.Anno_intervento)-1 and
            cAnno.tipo_cap (+) =cAnno2.tipo_cap and
            cAnno.Nro_Intervento (+) = cAnno2.Nro_Intervento and
            cAnno3.anno_esercizio (+) =cAnno2.anno_esercizio and
            cAnno3.Anno_intervento (+) =to_number(cAnno2.Anno_intervento)+1 and
            cAnno3.tipo_cap (+) =cAnno2.tipo_cap and
            cAnno3.Nro_Intervento (+) = cAnno2.Nro_Intervento and
            cap118.anno_esercizio=cAnno2.anno_esercizio and
            cap118.anno_capitolo=cAnno2.anno_esercizio and
            cap118.nro_capitolo=cAnno2.Nro_Intervento and
            cap118.nro_articolo=0 and
            tit118.anno_esercizio   (+) =cap118.anno_esercizio and
            tit118.titolo           (+) =cap118.titolo and
            macr118.anno_esercizio  (+) =cap118.Anno_Esercizio and
            macr118.titolo          (+) =cap118.titolo and
            macr118.macroaggreg     (+) =cap118.macroaggreg and
            miss118.anno_esercizio  (+) =cap118.anno_esercizio and
            miss118.missione        (+) = cap118.missione and
            prog118.anno_esercizio  (+) = cap118.anno_esercizio and
            prog118.missione        (+) = cap118.missione and
            prog118.programma       (+) = cap118.programma and
            pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
            pdcFin.Conto            (+) =cap118.conto and
            trans_118.codice        (+) =cap118.trans_eu and --transazione europea
            tipoFin.Anno_Esercizio  (+) = cAnno2.Anno_Esercizio and -- tipo_finanziamento
            tipoFin.Tipologia       (+) = 'TF' and
            tipoFin.Procedura       (+) = 1 and
            tipoFin.Codice          (+) = cAnno2.Tipo_Finanz and
            tipoFondi.Anno_Esercizio (+) = cAnno2.Anno_Esercizio and -- tipo_fondo
            tipoFondi.Tipologia      (+) = 'TS' and
            tipoFondi.Procedura      (+) = 1 and
            tipoFondi.Codice         (+) = cAnno2.Tipo_Spesa and
            classif1.anno_esercizio  (+) = cAnno2.Anno_Esercizio and -- classif1
            classif1.tipologia       (+) = 'TC' and
            classif1.procedura       (+) = 1 and
            classif1.codice          (+) = cAnno2.tipo_intervento and
            exBilancio.Anno_Esercizio(+) = cAnno2.Anno_Esercizio and -- classif11
            exBilancio.Anno_Cap      (+) = cAnno2.Anno_Cap and
            exBilancio.Nro_Capitolo  (+) = cAnno2.Nro_Cap and
            exBilancio.tipo_cap      (+) = cAnno2.Tipo_Cap and
            exBilancio.tipo_cap      (+) = 'U' and
            codStat1.Anno_Peg             (+) = cAnno2.Anno_Esercizio and   -- classif12
            codStat1.Codice               (+) = cAnno2.Cod_Stat1 and
            obiettivo.tipo_tabella        (+) = '51' and             -- classif14
            obiettivo.codice              (+) = cAnno2.Programma and
            programma.tipo_tabella        (+) = '52' and             -- classif15
            programma.codice              (+) = cAnno2.Centro_Di_Costo and
            Cdr.codice = substr(cAnno2.Up,1,2) and
            Cdc.codice = cAnno2.Up and
            capEcc.Tipo_Capitolo (+)='G' and
            capEcc.Eu (+)  ='U' and
            capEcc.Anno_Esercizio  (+) = cAnno2.Anno_esercizio and
            capEcc.numero_capitolo (+) = cAnno2.Nro_Intervento and
            capEcc.numero_articolo (+) = 0 and
            capEcc.numero_ueb      (+) = 1 and
            capEcc.ente_proprietario_id (+)=p_ente and -- 07.01.2016 Sofia aggiunto
            0=(select count(*) from migr_capitolo_uscita m
                where m.anno_esercizio=p_anno_esercizio and
                      m.numero_Capitolo=cAnno2.Nro_Intervento and
                      m.numero_articolo=0  and
                      m.tipo_capitolo='CAP-UG'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente));
    commit;

    msgRes:='Inserimento migr_capitolo_uscita CAP-UG anno+2.';
    -- x capitolo che esistono da anno+2 e non in anni indietro
    insert into migr_capitolo_uscita
    ( capusc_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
      descrizione,descrizione_articolo, titolo,macroaggregato,missione,programma,
      pdc_fin_quarto, pdc_fin_quinto,note,
      trasferimenti_comunitari,funzioni_delegate,
      flag_per_memoria,flag_rilevante_iva,
      tipo_finanziamento, tipo_vincolo, tipo_fondo,
      siope_livello_1,siope_livello_2,siope_livello_3,
      classificatore_1,classificatore_2,classificatore_3,classificatore_4,
      classificatore_5,classificatore_6,classificatore_7,classificatore_8,
      classificatore_9,classificatore_10,classificatore_11,classificatore_12,
      classificatore_13,classificatore_14,classificatore_15,
      centro_resp,cdc,
      classe_capitolo,flag_impegnabile,
      stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
      stanziamento,stanziamento_res,stanziamento_cassa,
      stanziamento_iniziale_anno2,stanziamento_anno2,
      stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
    cofog,                -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Uscita
    spesa_ricorrente)     -- DAVIDE - 22.08.2016
    (select  migr_capusc_id_seq.nextval,'CAP-UG',cAnno3.Anno_esercizio,cAnno3.Nro_Intervento,0,1,
             cAnno3.ogg1||' '||cAnno3.ogg2||' '||cAnno3.ogg3||' '||cAnno3.ogg4||' '||cAnno3.ogg5,null,
             decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
             decode(nvl(macr118.macroaggreg,' '),' ',null, macr118.titolo||macr118.macroaggreg||'0000'),
             decode(nvl(miss118.missione, ' ' ),' ' , null,miss118.missione),
             decode(nvl(prog118.programma, ' ' ),' ' , null,prog118.missione||prog118.programma),
             decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
             decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
             null,
             decode(nvl(to_char(trans_118.codice),' '),' ',null,to_char(trans_118.codice)),'N',
             'N', 'N',
             decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
             null,
             decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
  -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.codice_gest,
  -- DAVIDE - 16.12.015 - Fine
             decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
             decode(nvl(cAnno3.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
             decode(nvl(cAnno3.Partita_Giro, ' ' ),' ' , null, 'N',null,'S','1||Partita di giro'), --classif3
			 
  -- DAVIDE - 12.01.2017 - Imposta valori classificatori 4, 6 e 7 come da mail Valenzano del 09.01.2017
             --null,null,null,null,
			 decode(nvl(cAnno3.tipo_cap_gemello, ' ' ),' ' , null,'R','1||Riaccertato','FPV','2||Fondo pluriennale vincolato'), --classif4
			 decode(cAnno3.cap_origine,0 , null,cAnno3.cap_origine||'||'||cAnno3.cap_origine), --classif5
			 decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ),  --classif6
			 '2||No', --classif7 
  -- DAVIDE - 12.01.2017 - Fine				 
			 
			 null,null,null,
             decode(nvl(exBilancio.Nro_capitolo,0),0,null,
                    exBilancio.Tipo_Cap||'/'||exBilancio.Cod_Bilancio||'||'||
                    exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5), --classif11
             decode(nvl(codStat1.Codice,0 ), 0 ,null,codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
         decode(nvl(cAnno3.Cod_Stat4,0 ), 0 ,null,cAnno3.Cod_Stat4||'||'||cAnno3.Cod_Stat4 ), --classif13
         decode(nvl(obiettivo.codice,0 ), 0 ,null,obiettivo.codice||'||'||obiettivo.descr ), --classif14
         decode(nvl(programma.codice,0 ), 0 ,null, programma.codice||'||'||programma.descr ), --classif15
         Cdr.codice,Cdc.codice,
         decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
         decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
         nvl(cAnno.Importo,0),0,nvl(cAnno.Stanz_Cassa_Iniz,0),
         nvl(cAnno.Importo,0), 0,nvl(cAnno.Stanz_Cassa_Def,0),
         nvl(cAnno2.importo,0),nvl(cAnno2.importo,0),nvl(cAnno3.importo,0),nvl(cAnno3.importo,0),p_ente,
     trim(cap118.cofog),                   -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Uscita
     ltrim(to_char(cap118.eu_ricor, '99')) -- DAVIDE - 22.08.2016
     from gest_intervento cAnno, gest_intervento cAnno2,gest_intervento cAnno3, d118_cap_usc cap118,
          d118_titusc tit118, d118_macroaggreg macr118,
          d118_missioni miss118,d118_programmi prog118,
          d118_piano_conti_usc pdcFin,tipologia_capitolo tipoFin ,
          d118_transazione_ue trans_118,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,cc_gest_capitolo exBilancio,--gest_capitolo exBilancio, 27.01.2017 Sofia
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc, migr_capitolo_eccezione capEcc
     where cAnno3.Anno_Intervento =p_anno_esercizio+2 and
           cAnno3.Anno_esercizio=p_anno_esercizio and
           cAnno3.tipo_cap='U' and
           cAnno.anno_esercizio (+) =cAnno3.anno_esercizio and
           cAnno.Anno_intervento (+) =to_number(cAnno3.Anno_intervento)-2 and
           cAnno.tipo_cap (+) =cAnno3.tipo_cap and
           cAnno.Nro_Intervento (+) = cAnno3.Nro_Intervento and
           cAnno2.anno_esercizio (+) =cAnno3.anno_esercizio and
           cAnno2.Anno_intervento (+) =to_number(cAnno3.Anno_intervento)-1 and
           cAnno2.tipo_cap (+) =cAnno3.tipo_cap and
           cAnno2.Nro_Intervento (+) = cAnno3.Nro_Intervento and
           cap118.anno_esercizio=cAnno3.anno_esercizio and
           cap118.anno_capitolo=cAnno3.anno_esercizio and
           cap118.nro_capitolo=cAnno3.Nro_Intervento and
           cap118.nro_articolo=0 and
           tit118.anno_esercizio   (+) =cap118.anno_esercizio and
           tit118.titolo           (+) =cap118.titolo and
           macr118.anno_esercizio  (+) =cap118.Anno_Esercizio and
           macr118.titolo          (+) =cap118.titolo and
           macr118.macroaggreg     (+) =cap118.macroaggreg and
           miss118.anno_esercizio  (+) =cap118.anno_esercizio and
           miss118.missione        (+) = cap118.missione and
           prog118.anno_esercizio  (+) = cap118.anno_esercizio and
           prog118.missione        (+) = cap118.missione and
           prog118.programma       (+) = cap118.programma and
           pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
           pdcFin.Conto            (+) =cap118.conto and
           trans_118.codice        (+) =cap118.trans_eu and --transazione europea
           tipoFin.Anno_Esercizio  (+) = cAnno3.Anno_Esercizio and -- tipo_finanziamento
           tipoFin.Tipologia       (+) = 'TF' and
           tipoFin.Procedura       (+) = 1 and
           tipoFin.Codice          (+) = cAnno3.Tipo_Finanz and
           tipoFondi.Anno_Esercizio (+) = cAnno3.Anno_Esercizio and -- tipo_fondo
           tipoFondi.Tipologia      (+) = 'TS' and
           tipoFondi.Procedura      (+) = 1 and
           tipoFondi.Codice         (+) = cAnno3.Tipo_Spesa and
           classif1.anno_esercizio  (+) = cAnno3.Anno_Esercizio and -- classif1
           classif1.tipologia       (+) = 'TC' and
           classif1.procedura       (+) = 1 and
           classif1.codice          (+) = cAnno3.tipo_intervento and
           exBilancio.Anno_Esercizio(+) = cAnno3.Anno_Esercizio and -- classif11
           exBilancio.Anno_Cap      (+) = cAnno3.Anno_Cap and
           exBilancio.Nro_Capitolo  (+) = cAnno3.Nro_Cap and
           exBilancio.tipo_cap      (+) = cAnno3.Tipo_Cap and
           exBilancio.tipo_cap      (+) = 'U' and
           codStat1.Anno_Peg             (+) = cAnno3.Anno_Esercizio and   -- classif12
           codStat1.Codice               (+) = cAnno3.Cod_Stat1 and
           obiettivo.tipo_tabella        (+) = '51' and             -- classif14
           obiettivo.codice              (+) = cAnno3.Programma and
           programma.tipo_tabella        (+) = '52' and             -- classif15
           programma.codice              (+) = cAnno3.Centro_Di_Costo and
           Cdr.codice = substr(cAnno3.Up,1,2) and
           Cdc.codice = cAnno3.Up and
           capEcc.Tipo_Capitolo (+)='G' and
           capEcc.Eu (+)  ='U' and
           capEcc.Anno_Esercizio  (+) = cAnno3.Anno_esercizio and
           capEcc.numero_capitolo (+) = cAnno3.Nro_Intervento and
           capEcc.numero_articolo (+) = 0 and
           capEcc.numero_ueb      (+) = 1 and
           capEcc.ente_proprietario_id (+)=p_ente and -- 07.01.2016 Sofia aggiunto
           0=(select count(*) from migr_capitolo_uscita m
              where m.anno_esercizio=p_anno_esercizio and
                    m.numero_Capitolo=cAnno3.Nro_Intervento and
                    m.numero_articolo=0  and
                    m.tipo_capitolo='CAP-UG'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente));
    commit;
  
     -- DAVIDE - 12.01.2017 - popola il classificatore 7 con l'update come da mail Valenzano del 09.01.2017
     update migr_capitolo_uscita migrp
        set classificatore_7='1||Si'  
      where exists (select 1 from as_movimenti_llpp llpp
                    where llpp.anno_capitolo=migrp.anno_esercizio
				            and   llpp.nro_capitolo=migrp.numero_capitolo
				            and   llpp.tipo_eu='U')
	    and migrp.ente_proprietario_id=p_ente
	    and migrp.tipo_capitolo='CAP-UG';

	 commit;
   -- DAVIDE - 12.01.2017 - Fine


    -- update per stanziamenti res e cassa
    msgRes:='Aggiornamento migr_capitolo_uscita CAP-UG per stanz. residui.';
    
    update migr_capitolo_uscita m
    set (m.stanziamento_iniziale_res)=
    /*12.10.2015
        (select nvl(sum(res.residui_da_riportare ),0)
         from  as_capitoli res
         where res.anno_peg=m.anno_esercizio and
               res.nro_capitolo=m.numero_capitolo and
               res.anno_capitolo<=res.anno_peg and -- 05.10.2015 Sofia mancava =
               res.tipo_eu='U')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UG' and
     0!=(select count(*)
         from as_capitoli res
         where res.anno_peg=m.anno_esercizio and
               res.nro_capitolo=m.numero_capitolo and
               res.anno_capitolo<=res.anno_peg and -- 05.10.2015 Sofia mancava =
               res.tipo_eu='U')
      aggiornamento reisdui dopo riaccertamento, su indicazione di Valenzano */
      /*   (select nvl(sum(res.stanz_definitivo ),0)
          from  as_capitoli res
          where res.anno_peg=m.anno_esercizio and
                res.nro_capitolo=m.numero_capitolo and
                res.anno_capitolo<res.anno_peg and
                res.tipo_eu='U')
     where m.anno_esercizio=p_anno_esercizio  and m.tipo_capitolo='CAP-UG' and
           0!=(select count(*)
               from as_capitoli res
               where res.anno_peg=m.anno_esercizio and
                     res.anno_capitolo<res.anno_peg and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='U') */
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
    -- 27.01.2017 Sofia nuovo update x migrazione
    (select nvl(importo_res,0)
     from  gest_intervento res 
     where res.nro_intervento=m.numero_capitolo and
           res.anno_intervento=p_anno_esercizio and
           res.tipo_cap='U')
    where m.anno_esercizio=p_anno_esercizio  
    and   m.tipo_capitolo='CAP-UG'            
    and   m.ente_proprietario_id=p_ente 
    and   0!=(select count(*)
              from  gest_intervento res 
              where res.nro_intervento=m.numero_capitolo and
              res.anno_intervento=p_anno_esercizio and
              res.tipo_cap='U')
     and m.ente_proprietario_id=p_ente;
     commit;

     -- 05.10.2015 Sofia - mancava calcolo residui a partire da residui_80000
     msgRes:='Aggiornamento migr_capitolo_uscita per stanz. residui CAP-UG da residui_80000.';
     /*update migr_capitolo_uscita m
     set (m.stanziamento_iniziale_res)=
    /*12.10.2015
     (select nvl(sum(res.residuo ),0)
      from  residui_80000 res
      where res.anno_capitolo=m.anno_esercizio and
            res.nro_capitolo=m.numero_capitolo and
            res.tipo_eu='U')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UG' and
           0!=(select count(*)
               from residui_80000 res
               where res.anno_capitolo=m.anno_esercizio and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='U')
     aggiornamento reisdui dopo riaccertamento, su indicazione di Valenzano
           (select nvl(sum(res.residuo ),0)
                from  residui_80000_new res
                where res.anno_capitolo=m.anno_esercizio and
                      res.nro_capitolo=m.numero_capitolo and
                      res.tipo_eu='U')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UG' and
           0!=(select count(*)
               from residui_80000_new res
               where res.anno_capitolo=m.anno_esercizio and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='U')
     and m.ente_proprietario_id=p_ente;
    commit;
    */
    msgRes:='Aggiornamento migr_capitolo_uscita CAP-UG per stanz. cassa.';
    update migr_capitolo_uscita  m
    set --m.stanziamento_iniziale_cassa=m.stanziamento_iniziale_cassa+m.stanziamento_iniziale_res,
        m.stanziamento_res=m.stanziamento_iniziale_res
        --m.stanziamento_cassa=m.stanziamento_cassa+m.stanziamento_iniziale_res
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UG' and m.stanziamento_iniziale_res!=0
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente;

     msgRes:='Aggiornamento migr_capitolo_uscita CAP-UG per la funzioni delegate';
     update migr_capitolo_uscita  m
     set m.funzioni_delegate='S'
     where exists (select 1 from prev_peg a where
                                             a.tipo_spesa='DE' and a.tipo_fin='FR'
                                             and a.tipo_int_77='U' and a.anno_capitolo_77=m.anno_esercizio
                                             and m.anno_esercizio=p_anno_esercizio
                                             and a.nro_capitolo_77=m.numero_capitolo)
     and m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-UG'
     and m.ente_proprietario_id=p_ente;

   pCodRes:=codRes;
   pMsgRes:='Migrazione capitolo uscita gestione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end   migrazione_cgu;

procedure migrazione_cpe(p_anno_esercizio varchar2,p_ente number,pCodRes out number, pMsgRes out varchar2) is
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

     -- pulizia tabella migr_capitolo_eccezione Anna V. 04/07/2016
      delete migr_capitolo_eccezione
       where anno_esercizio = p_anno_esercizio
       and eu = 'E' and tipo_capitolo='P'
       and ente_proprietario_id=p_ente;

      --insert nella tabella migr_capitolo_eccezione Anna V. 04/07/2016
      insert into migr_capitolo_eccezione
       (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
        numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
      select distinct 'P','E',p_anno_esercizio,cAnno.Nro_Capitolo_77,0,'1','N',
-- DAVIDE - 17.11.2016 - distinzione tra fondi spese correnti e conto capitale - segnalazione Valenzano
--      decode(b.cod_bilancio,'0009001','AAM','0009002','AAM','0009003','AAM','0009004','AAM',
--      '0009005','FPV','0009006','FPV'),3
      decode(b.cod_bilancio,'0009001','AAM','0009002','AAM','0009003','AAM','0009004','AAM',
      '0009005','FPVSC','0009006','FPVCC'),p_ente
-- DAVIDE - 17.11.2016 - Fine
      from prev_peg cAnno,prev_interventi77 b
      where cAnno.anno_ese=p_anno_esercizio-1
      and   cAnno.Tipo_Int_77='E'
      and b.cod_bilancio in  ('0009001','0009002','0009003','0009004','0009005','0009006')
      and cAnno.Nro_Intervento_77=b.nro_intervento_77
      and cAnno.Anno_Intervento_77=b.anno_intervento_77;

      commit;

    msgRes:='Inserimento migr_capitolo_entrata CAP-EP da prev_peg.';
    insert into migr_capitolo_entrata
    ( capent_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
      descrizione,descrizione_articolo, titolo,tipologia,categoria,
      pdc_fin_quarto, pdc_fin_quinto,note,
      trasferimenti_comunitari,
      flag_per_memoria,flag_rilevante_iva,
      tipo_finanziamento, tipo_vincolo, tipo_fondo,
      siope_livello_1,siope_livello_2,siope_livello_3,
      classificatore_1,classificatore_2,classificatore_3,classificatore_4,
      classificatore_5,classificatore_6,classificatore_7,classificatore_8,
      classificatore_9,classificatore_10,classificatore_11,classificatore_12,
      classificatore_13,classificatore_14,classificatore_15,
      centro_resp,cdc,
      classe_capitolo, flag_accertabile,
      stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
      stanziamento,stanziamento_res,stanziamento_cassa,
      stanziamento_iniziale_anno2,stanziamento_anno2,
      stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
    entrata_ricorrente)     -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Entrata
      (select  migr_capent_id_seq.nextval,'CAP-EP',cAnno.Anno_Capitolo_77,cAnno.nro_capitolo_77,0,1,
               cAnno.ogg1||' '||cAnno.ogg2||' '||cAnno.ogg3||' '||cAnno.ogg4||' '||cAnno.ogg5,null,
               decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
               decode(nvl(tip118.tipologia,' '),' ',null, tip118.titolo||'0'||tip118.tipologia||'00'),
               decode(nvl(categ118.categoria, ' ' ),' ' , null,categ118.categoria),
               decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
               decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
               null,
               decode(nvl(to_char(trans_118.codice),' '),' ',null,to_char(trans_118.codice)),--30/06/2016 aggiunta valorizzazione trasferimenti EU Anna V
               'N', 'N',
               decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
               null,
               decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
  -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.codice_gest,
  -- DAVIDE - 16.12.015 - Fine
               decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
               decode(nvl(cAnno.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
               decode(nvl(cAnno.Partita_Giro, ' ' ),' ' , null,'N',null,'S','1||Partita di giro'), --classif3			   
			 
  -- DAVIDE - 12.01.2017 - Imposta valori classificatori 4, 6 e 7 come da mail Valenzano del 09.01.2017
              --null,null,null,null,
			  decode(nvl(cAnno.tipo_cap_gemello, ' ' ),' ' , null,'R','1||Riaccertato','FPV','2||Fondo pluriennale vincolato'), --classif4
			  decode(cAnno.cap_origine,0 , null,cAnno.cap_origine||'||'||cAnno.cap_origine), --classif5
			  decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ),  --classif6
			  '2||No', --classif7 
  -- DAVIDE - 12.01.2017 - Fine	
			   
			   null,null,null,
               substr(decode(nvl(exBilancio.Nro_Intervento_77,0),0,null,
                             exBilancio.Tipo_Int_77||'/'||exBilancio.Cod_Bilancio||'||'||
                             exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5),
                             1,250), --classif11
                decode(nvl(codStat1.Codice,0 ), 0 ,null,
                       codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
                decode(nvl(cAnno.Cod_Stat4,0 ), 0 ,null,
                       cAnno.Cod_Stat4||'||'||cAnno.Cod_Stat4 ), --classif13
                decode(nvl(obiettivo.codice,0 ), 0 ,null,
                       obiettivo.codice||'||'||obiettivo.descr ), --classif14
                decode(nvl(programma.codice,0 ), 0 ,null,
                       programma.codice||'||'||programma.descr ), --classif15
                Cdr.codice,Cdc.codice,
                decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
                decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
                nvl(cAnno.Importo,0), 0,nvl(cAnno.importo_cassa,0), -- 23.06.2016 Sofia aggiunti NVL
                nvl(cAnno.importo,0), 0,nvl(cAnno.importo_cassa,0),-- 23.06.2016 Sofia aggiunti NVL
                nvl(cAnno2.importo,0),nvl(cAnno2.importo,0),nvl(cAnno3.importo,0),nvl(cAnno3.importo,0),p_ente,
        ltrim(to_char(cap118.eu_ricor, '99'))        -- DAVIDE - 22.08.2016 - aggiunto campo per Capitoli Entrata
     from prev_peg cAnno, prev_peg cAnno2,prev_peg cAnno3, d118_prev_ent cap118,
          d118_titent tit118, d118_tipologie tip118, d118_categorie categ118,
          d118_piano_conti_ent pdcFin,tipologia_capitolo tipoFin ,
          d118_transazione_ue trans_118,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,prev_interventi77 exBilancio,
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc, migr_capitolo_eccezione capEcc
     where cAnno.anno_ese=p_anno_esercizio-1 and
           cAnno.Anno_Capitolo_77=p_anno_esercizio and
           cAnno.Tipo_Int_77='E' and
           cAnno2.anno_ese (+) =cAnno.anno_ese and
           cAnno2.Anno_Capitolo_77 (+) =to_number(cAnno.Anno_Capitolo_77)+1 and
           cAnno2.Tipo_Int_77 (+) =cAnno.Tipo_Int_77 and
           cAnno2.nro_capitolo_77 (+) = cAnno.nro_capitolo_77 and
           cAnno3.anno_ese (+) =cAnno.anno_ese and
           cAnno3.Anno_Capitolo_77 (+)=to_number(cAnno.Anno_Capitolo_77)+2 and
           cAnno3.Tipo_Int_77 (+)=cAnno.Tipo_Int_77 and
           cAnno3.nro_capitolo_77(+) = cAnno.nro_capitolo_77 and
           cap118.anno_esercizio=cAnno.anno_capitolo_77 and
           cap118.anno_capitolo=cAnno.anno_capitolo_77 and
           cap118.nro_capitolo=cAnno.nro_capitolo_77 and
           cap118.nro_articolo=0 and
           tit118.anno_esercizio   (+) =cap118.anno_esercizio and
           tit118.titolo           (+) =cap118.titolo and
           tip118.anno_esercizio   (+) =cap118.Anno_Esercizio and
           tip118.titolo           (+) =cap118.titolo and
           tip118.tipologia        (+) =cap118.tipologia and
           categ118.anno_esercizio (+) =cap118.anno_esercizio and
           categ118.titolo         (+) = cap118.titolo and
           categ118.tipologia      (+) = cap118.tipologia and
           categ118.categoria      (+) = cap118.categoria and
           pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
           pdcFin.Conto            (+) =cap118.conto and
           tipoFin.Anno_Esercizio  (+) = cAnno.anno_capitolo_77 and -- tipo_finanziamento
           trans_118.codice        (+) =cap118.trans_eu and
           tipoFin.Tipologia       (+) = 'TF' and
           tipoFin.Procedura       (+) = 5 and
           tipoFin.Codice          (+) = cAnno.Tipo_Fin and
           tipoFondi.Anno_Esercizio (+) = cAnno.anno_capitolo_77 and -- tipo_fondo
           tipoFondi.Tipologia      (+) = 'TS' and
           tipoFondi.Procedura      (+) = 5 and
           tipoFondi.Codice         (+) = cAnno.Tipo_Spesa and
           classif1.anno_esercizio  (+) = cAnno.Anno_Capitolo_77 and -- classif1
           classif1.tipologia       (+) = 'TC' and
           classif1.procedura       (+) = 5 and
           classif1.codice          (+) = cAnno.tipologia_cap_77 and
           exBilancio.Anno_Intervento_77 (+) = cAnno.Anno_Intervento_77 and -- classif11
           exBilancio.Nro_Intervento_77  (+) = cAnno.Nro_Intervento_77 and
           exBilancio.Tipo_Int_77        (+) = cAnno.Tipo_Int_77 and
           codStat1.Anno_Peg             (+) = cAnno.Anno_Ese and   -- classif12
           codStat1.Codice               (+) = cAnno.Cod_Stat1 and
           obiettivo.tipo_tabella        (+) = '51' and             -- classif14
           obiettivo.codice              (+) = cAnno.Obbiettivo and
           programma.tipo_tabella        (+) = '52' and             -- classif15
           programma.codice              (+) = cAnno.Programma and
           Cdr.codice = substr(cAnno.Up,1,2) and
           Cdc.codice = cAnno.Up and
           capEcc.Tipo_Capitolo (+)='P' and
           capEcc.Eu (+)  ='E' and
           capEcc.Anno_Esercizio  (+) = cAnno.Anno_Capitolo_77 and
           capEcc.numero_capitolo (+) = cAnno.nro_capitolo_77 and
           capEcc.numero_articolo (+) = 0 and
           capEcc.numero_ueb      (+) = 1 and
           capEcc.ente_proprietario_id (+)=p_ente );-- 07.01.2016 Sofia aggiunto
    commit;
  
     -- DAVIDE - 12.01.2017 - popola il classificatore 7 con l'update come da mail Valenzano del 09.01.2017
     update migr_capitolo_entrata migrp
        set classificatore_7='1||Si'  
      where exists (select 1 from as_movimenti_llpp  llpp
                    where llpp.anno_capitolo=migrp.anno_esercizio
				            and   llpp.nro_capitolo=migrp.numero_capitolo
                    and   llpp.tipo_eu='E')
	    and migrp.ente_proprietario_id=p_ente
	    and migrp.tipo_capitolo='CAP-EP';

	 commit;
     -- DAVIDE - 12.01.2017 - Fine

/*  26.11.2015 Sofia commentata perchè non esiste più la tabella
    msgRes:='Inserimento migr_capitolo_entrata CAP-EP da prev_peg_residui_noriac.';
    insert into migr_capitolo_entrata
    ( capent_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
      descrizione,descrizione_articolo, titolo,tipologia,categoria,
      pdc_fin_quarto, pdc_fin_quinto,note,
      flag_per_memoria,flag_rilevante_iva,
      tipo_finanziamento, tipo_vincolo, tipo_fondo,
      siope_livello_1,siope_livello_2,siope_livello_3,
      classificatore_1,classificatore_2,classificatore_3,classificatore_4,
      classificatore_5,classificatore_6,classificatore_7,classificatore_8,
      classificatore_9,classificatore_10,classificatore_11,classificatore_12,
      classificatore_13,classificatore_14,classificatore_15,
      centro_resp,cdc,
      classe_capitolo, flag_accertabile,
      stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
      stanziamento,stanziamento_res,stanziamento_cassa,
      stanziamento_iniziale_anno2,stanziamento_anno2,
      stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id)
      (select  migr_capent_id_seq.nextval,'CAP-EP',cAnno.Anno_Capitolo_77,cAnno.nro_capitolo_77,0,1,
               cAnno.ogg1||' '||cAnno.ogg2||' '||cAnno.ogg3||' '||cAnno.ogg4||' '||cAnno.ogg5,null,
               decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
               decode(nvl(tip118.tipologia,' '),' ',null, tip118.titolo||'0'||tip118.tipologia||'00'),
               decode(nvl(categ118.categoria, ' ' ),' ' , null,categ118.categoria),
               decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
               decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
               null,'N', 'N',
               decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
               null,
               decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
               null,null,null,
               decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
               decode(nvl(cAnno.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
               decode(nvl(cAnno.Partita_Giro, ' ' ),' ' , null,'N',null,'S','1||Partita di giro'), --classif3			   
               null,null,null,null,null,null,null,
               substr(decode(nvl(exBilancio.Nro_Intervento_77,0),0,null,
                             exBilancio.Tipo_Int_77||'/'||exBilancio.Cod_Bilancio||'||'||
                             exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5),
                             1,250), --classif11
                decode(nvl(codStat1.Codice,0 ), 0 ,null,
                       codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
                decode(nvl(cAnno.Cod_Stat4,0 ), 0 ,null,
                       cAnno.Cod_Stat4||'||'||cAnno.Cod_Stat4 ), --classif13
                decode(nvl(obiettivo.codice,0 ), 0 ,null,
                       obiettivo.codice||'||'||obiettivo.descr ), --classif14
                decode(nvl(programma.codice,0 ), 0 ,null,
                       programma.codice||'||'||programma.descr ), --classif15
                Cdr.codice,Cdc.codice,
                decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
                decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
                cAnno.Importo, 0,cAnno.importo,
                cAnno.importo, 0,cAnno.importo,
                0,0,0,0,p_ente
     from prev_peg_residui_noriac cAnno, d118_prev_ent cap118,
          d118_titent tit118, d118_tipologie tip118, d118_categorie categ118,
          d118_piano_conti_ent pdcFin,tipologia_capitolo tipoFin ,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,prev_interventi77 exBilancio,
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc, migr_capitolo_eccezione capEcc
     where cAnno.anno_ese=p_anno_esercizio-1 and
           cAnno.Anno_Capitolo_77=p_anno_esercizio and
           cAnno.Tipo_Int_77='E' and
           cap118.anno_esercizio =cAnno.anno_capitolo_77 and
           cap118.anno_capitolo  =cAnno.anno_capitolo_77 and
           cap118.nro_capitolo   =cAnno.nro_capitolo_77 and
           cap118.nro_articolo   =0 and
           tit118.anno_esercizio   (+) =cap118.anno_esercizio and
           tit118.titolo           (+) =cap118.titolo and
           tip118.anno_esercizio   (+) =cap118.Anno_Esercizio and
           tip118.titolo           (+) =cap118.titolo and
           tip118.tipologia        (+) =cap118.tipologia and
           categ118.anno_esercizio (+) =cap118.anno_esercizio and
           categ118.titolo         (+) = cap118.titolo and
           categ118.tipologia      (+) = cap118.tipologia and
           categ118.categoria      (+) = cap118.categoria and
           pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
           pdcFin.Conto            (+) =cap118.conto and
           tipoFin.Anno_Esercizio  (+) = cAnno.anno_capitolo_77 and -- tipo_finanziamento
           tipoFin.Tipologia       (+) = 'TF' and
           tipoFin.Procedura       (+) = 5 and
           tipoFin.Codice          (+) = cAnno.Tipo_Fin and
           tipoFondi.Anno_Esercizio (+) = cAnno.anno_capitolo_77 and -- tipo_fondo
           tipoFondi.Tipologia      (+) = 'TS' and
           tipoFondi.Procedura      (+) = 5 and
           tipoFondi.Codice         (+) = cAnno.Tipo_Spesa and
           classif1.anno_esercizio  (+) = cAnno.Anno_Capitolo_77 and -- classif1
           classif1.tipologia       (+) = 'TC' and
           classif1.procedura       (+) = 5 and
           classif1.codice          (+) = cAnno.tipologia_cap_77 and
           exBilancio.Anno_Intervento_77 (+) = cAnno.Anno_Intervento_77 and -- classif11
           exBilancio.Nro_Intervento_77  (+) = cAnno.Nro_Intervento_77 and
           exBilancio.Tipo_Int_77        (+) = cAnno.Tipo_Int_77 and
           codStat1.Anno_Peg             (+) = cAnno.Anno_Ese and   -- classif12
           codStat1.Codice               (+) = cAnno.Cod_Stat1 and
           obiettivo.tipo_tabella        (+) = '51' and             -- classif14
           obiettivo.codice              (+) = cAnno.Obbiettivo and
           programma.tipo_tabella        (+) = '52' and             -- classif15
           programma.codice              (+) = cAnno.Programma and
           Cdr.codice = substr(cAnno.Up,1,2) and
           Cdc.codice = cAnno.Up and
           capEcc.Tipo_Capitolo (+)='P' and
           capEcc.Eu (+)  ='E' and
           capEcc.Anno_Esercizio  (+) = cAnno.Anno_Capitolo_77 and
           capEcc.numero_capitolo (+) = cAnno.nro_capitolo_77 and
           capEcc.numero_articolo (+) = 0 and
           capEcc.numero_ueb      (+) = 1 and
           not exists (select 1 from migr_capitolo_entrata m
                       where m.anno_esercizio=p_anno_esercizio
                       and   m.numero_capitolo=cAnno.nro_capitolo_77
                       and   m.numero_articolo=0
                       and   m.tipo_capitolo='CAP-EP'
                       -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
                       and m.ente_proprietario_id=p_ente));
     commit;      */
     msgRes:='Aggiornamento migr_capitolo_entrata CAP-EP per stanz. redisuo.';
     -- update per stanziamenti res e cassa
     /*ANNA VALENZANO*/
     /*update migr_capitolo_entrata m
     set (m.stanziamento_iniziale_res)=
     (select nvl(sum(res.residui_da_riportare ),0)
      from  as_capitoli res
      where res.anno_peg=m.anno_esercizio-1 and
            res.nro_capitolo=m.numero_capitolo and
            res.anno_capitolo<=res.anno_peg and
            res.tipo_eu='E')
      where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EP' and
      0!=(select count(*)
          from as_capitoli res
          where res.anno_peg=m.anno_esercizio-1 and
                res.anno_capitolo<=res.anno_peg and
                res.nro_capitolo=m.numero_capitolo and
                res.tipo_eu='E')
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente; */

/*ANNA VALENZANO 19/05/2016 sostituito nella prima where res.anno_peg=m.anno_esercizio-1
con res.anno_peg=m.anno_esercizio*/

   /*  update migr_capitolo_entrata m
     set (m.stanziamento_iniziale_res)=
     (select nvl(sum(res.stanz_definitivo ),0)
      from  as_capitoli res
--      where res.anno_peg=m.anno_esercizio and 27.01.2017
      where res.anno_peg=m.anno_esercizio-1 and      
            res.nro_capitolo=m.numero_capitolo and
            res.anno_capitolo<res.anno_peg and
            res.tipo_eu='E')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EP' and
           0!=(select count(*)
               from as_capitoli res
--               where res.anno_peg=m.anno_esercizio and
               where res.anno_peg=m.anno_esercizio-1 and               
                     res.anno_capitolo<res.anno_peg and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='E')
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente; 31.01.2017 Sofia sostituita con la successiva dopo mail di Valenzano */
     
     -- 31.01.2017 Sofia - nuovo calcolo sui residui presunti in fase di migrazione anche per previsione
     update migr_capitolo_entrata m
     set (m.stanziamento_iniziale_res)=
     (select nvl(sum(res.residui_da_riportare),0)
      from  as_capitoli res
      where res.anno_peg=m.anno_esercizio-1 and
            res.nro_capitolo=m.numero_capitolo and
            res.anno_capitolo<=res.anno_peg and
            res.tipo_eu='E')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EP' and
           0!=(select count(*)
               from as_capitoli res
               where res.anno_peg=m.anno_esercizio-1 and
                     res.anno_capitolo<=res.anno_peg and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='E')
     and m.ente_proprietario_id=p_ente; 
     commit;
     /*ANNA VALENZANO*/
     /*msgRes:='Aggiornamento migr_capitolo_entrata per stanz. residui CAP-EP da residui_80000.';
     update migr_capitolo_entrata m
     set (m.stanziamento_iniziale_res)=
     (select nvl(sum(res.residuo ),0)
      from  residui_80000 res
      where res.anno_capitolo=m.anno_esercizio and
            res.nro_capitolo=m.numero_capitolo and
            res.tipo_eu='E')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EP' and
           0!=(select count(*)
               from residui_80000 res
               where res.anno_capitolo=m.anno_esercizio and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='E')
           -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
           and m.ente_proprietario_id=p_ente;
      commit;               */

      msgRes:='Aggiornamento migr_capitolo_entrata CAP-EP per stanz. cassa.';
      update migr_capitolo_entrata  m
      set -- ANNA V. commentato perchè è in fase di caricamento preventivo stanziamento_iniziale_cassa=stanziamento_cassa
      --m.stanziamento_iniziale_cassa=m.stanziamento_iniziale_cassa+m.stanziamento_iniziale_res,
          m.stanziamento_res=m.stanziamento_iniziale_res
          -- ANNA V. commentato perchè è stato inserito l'importo cassa in preventivo
          --m.stanziamento_cassa=m.stanziamento_cassa+m.stanziamento_iniziale_res
      where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EP' and m.stanziamento_iniziale_res!=0
            -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
            and m.ente_proprietario_id=p_ente;

   /*Anna Valenzano--19/07/2016 richiesto di avere gli stanziamenti a zero per
                      il 2017 e 2018 */
  /*     update migr_capitolo_entrata m set m.stanziamento_iniziale_anno2=0, m.stanziamento_anno2=0,
       m.stanziamento_iniziale_anno3=0, m.stanziamento_anno3=0
       where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EP'
       and m.ente_proprietario_id=p_ente;  31.01.2017 Sofia commentato dopo mail di Valenzano */

   pCodRes:=codRes;
   pMsgRes:='Migrazione capitolo entrata previsione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_cpe;

procedure migrazione_cge(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2) is
  codRes number:=0;
  msgRes varchar2(1500):=null;
begin
--aggiungere la cassa Anna V
--transazione europea Anna V
--aggiungere la parte di cancellazione e insert su migr_capitolo_eccezione
    msgRes:='Pulizia migr_capitolo_entrata CAP-EG.';
    -- pulizia tabella migrazione per capitoli di gestione di entrata
    delete migr_capitolo_entrata
     where anno_esercizio = p_anno_esercizio
       and tipo_capitolo = 'CAP-EG'
       and fl_migrato = 'N'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and ente_proprietario_id=p_ente;

    delete migr_capitolo_eccezione
       where anno_esercizio = p_anno_esercizio
       and eu = 'E' and tipo_capitolo='G'
       and ente_proprietario_id=p_ente;


     insert into migr_capitolo_eccezione
       (tipo_capitolo, eu, anno_esercizio, numero_capitolo, numero_articolo,
        numero_ueb, flag_impegnabile, classe_capitolo, ente_proprietario_id)
      select distinct 'G','E',cAnno.anno_esercizio,cAnno.nro_intervento,0,'1','N',
-- DAVIDE - 17.11.2016 - distinzione tra fondi spese correnti e conto capitale - segnalazione Valenzano
--      decode(b.cod_bilancio,'0009001','AAM','0009002','AAM','0009003','AAM','0009004','AAM',
--      '0009005','FPV','0009006','FPV'),3
      decode(b.cod_bilancio,'0009001','AAM','0009002','AAM','0009003','AAM','0009004','AAM',
      '0009005','FPVSC','0009006','FPVCC'),p_ente
-- DAVIDE - 17.11.2016 - Fine
      from gest_intervento cAnno,cc_gest_capitolo b--gest_capitolo b 27.01.2017
      where cAnno.anno_esercizio=p_anno_esercizio
      and   cAnno.Tipo_cap='E'
      and b.cod_bilancio in  ('0009001','0009002','0009003','0009004','0009005','0009006')
      and cAnno.Nro_Cap=b.nro_capitolo
      and cAnno.Anno_Cap=b.anno_cap;


    msgRes:='Inserimento migr_capitolo_entrata CAP-EG.';
    --- migr_capitolo_entrata
    insert into migr_capitolo_entrata
    ( capent_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
      descrizione,descrizione_articolo, titolo,tipologia,categoria,
      pdc_fin_quarto, pdc_fin_quinto,note,
      trasferimenti_comunitari,
      flag_per_memoria,flag_rilevante_iva,
      tipo_finanziamento, tipo_vincolo, tipo_fondo,
      siope_livello_1,siope_livello_2,siope_livello_3,
      classificatore_1,classificatore_2,classificatore_3,classificatore_4,
      classificatore_5,classificatore_6,classificatore_7,classificatore_8,
      classificatore_9,classificatore_10,classificatore_11,classificatore_12,
      classificatore_13,classificatore_14,classificatore_15,
      centro_resp,cdc,
      classe_capitolo,flag_accertabile,
      stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
      stanziamento,stanziamento_res,stanziamento_cassa,
      stanziamento_iniziale_anno2,stanziamento_anno2,
      stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
    entrata_ricorrente)     -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Entrata
    (select  migr_capent_id_seq.nextval,'CAP-EG',cAnno.Anno_intervento,cAnno.nro_intervento,0,1,
             cAnno.ogg1||' '||cAnno.ogg2||' '||cAnno.ogg3||' '||cAnno.ogg4||' '||cAnno.ogg5,null,
             decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
             decode(nvl(tip118.tipologia,' '),' ',null, tip118.titolo||'0'||tip118.tipologia||'00'),
             decode(nvl(categ118.categoria, ' ' ),' ' , null,categ118.categoria),
             decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
             decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
             null,
             decode(nvl(to_char(trans_118.codice),' '),' ',null,to_char(trans_118.codice)),
             'N', 'N',
             decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
             null,
             decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
  -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.codice_gest,
  -- DAVIDE - 16.12.015 - Fine
             decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
             decode(nvl(cAnno.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
             decode(nvl(cAnno.Partita_Giro, ' ' ),' ' , null,'N',null,'S','1||Partita di giro'), --classif3
			 
  -- DAVIDE - 12.01.2017 - Imposta valori classificatori 4, 6 e 7 come da mail Valenzano del 09.01.2017
             --null,null,null,null,
			 decode(nvl(cAnno.tipo_cap_gemello, ' ' ),' ' , null,'R','1||Riaccertato','FPV','2||Fondo pluriennale vincolato'), --classif4
			 decode(cAnno.cap_origine,0 , null,cAnno.cap_origine||'||'||cAnno.cap_origine), --classif5
			 decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ),  --classif6
			 '2||No', --classif7 
  -- DAVIDE - 12.01.2017 - Fine	

             null,null,null,
             substr(decode(nvl(exBilancio.nro_capitolo,0),0,null,
                    exBilancio.tipo_cap||'/'||exBilancio.Cod_Bilancio||'||'||
                    exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5),
                    1,250), --classif11
             decode(nvl(codStat1.Codice,0 ), 0 ,null,codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
             decode(nvl(cAnno.Cod_Stat4,0 ), 0 ,null,cAnno.Cod_Stat4||'||'||cAnno.Cod_Stat4 ), --classif13
             decode(nvl(obiettivo.codice,0 ), 0 ,null,obiettivo.codice||'||'||obiettivo.descr ), --classif14
             decode(nvl(programma.codice,0 ), 0 ,null,programma.codice||'||'||programma.descr ), --classif15
             Cdr.codice,Cdc.codice,
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
             cAnno.Importo,  0,nvl(cAnno.Stanz_Cassa_Iniz,0),
             cAnno.importo,  0,nvl(cAnno.Stanz_Cassa_Def,0),
             nvl(cAnno2.importo,0), nvl(cAnno2.importo,0),nvl(cAnno3.importo,0),nvl(cAnno3.importo,0),p_ente,
         ltrim(to_char(cap118.eu_ricor, '99'))        -- DAVIDE - 22.08.2016 - aggiunto campo per Capitoli Entrata
     from gest_intervento cAnno, gest_intervento cAnno2,gest_intervento cAnno3, d118_cap_ent cap118,
          d118_titent tit118, d118_tipologie tip118, d118_categorie categ118,
          d118_piano_conti_ent pdcFin,tipologia_capitolo tipoFin ,
          d118_transazione_ue trans_118,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,cc_gest_capitolo exBilancio,--gest_capitolo exBilancio, 27.01.2017
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc, migr_capitolo_eccezione capEcc
     where cAnno.Anno_Intervento=p_anno_esercizio and
           cAnno.Anno_esercizio=p_anno_esercizio and
           cAnno.tipo_cap='E' and
           cAnno2.anno_esercizio(+)=cAnno.anno_esercizio and
           cAnno2.Anno_intervento(+)=to_number(cAnno.Anno_intervento)+1 and
           cAnno2.tipo_cap(+)=cAnno.tipo_cap and
           cAnno2.Nro_Intervento (+)= cAnno.Nro_Intervento and
           cAnno3.anno_esercizio(+)=cAnno.anno_esercizio and
           cAnno3.Anno_intervento(+)=to_number(cAnno.Anno_intervento)+2 and
           cAnno3.tipo_cap(+)=cAnno.tipo_cap and
           cAnno3.Nro_Intervento(+) = cAnno.Nro_Intervento and
           cap118.anno_esercizio=cAnno.anno_esercizio and
           cap118.anno_capitolo=cAnno.anno_esercizio and
           cap118.nro_capitolo=cAnno.Nro_Intervento and
           cap118.nro_articolo=0 and
           tit118.anno_esercizio   (+) =cap118.anno_esercizio and
           tit118.titolo           (+) =cap118.titolo and
           tip118.anno_esercizio   (+) =cap118.Anno_Esercizio and
           tip118.titolo           (+) =cap118.titolo and
           tip118.tipologia        (+) =cap118.tipologia and
           categ118.anno_esercizio (+) =cap118.anno_esercizio and
           categ118.titolo         (+) = cap118.titolo and
           categ118.tipologia      (+) = cap118.tipologia and
           categ118.categoria      (+) = cap118.categoria and
           pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
           pdcFin.Conto            (+) =cap118.conto and
           trans_118.codice        (+) =cap118.trans_eu and
           tipoFin.Anno_Esercizio  (+) = cAnno.anno_intervento and -- tipo_finanziamento
           tipoFin.Tipologia       (+) = 'TF' and
           tipoFin.Procedura       (+) = 1 and
           tipoFin.Codice          (+) = cAnno.Tipo_Finanz and
           tipoFondi.Anno_Esercizio (+) = cAnno.anno_intervento and -- tipo_fondo
           tipoFondi.Tipologia      (+) = 'TS' and
           tipoFondi.Procedura      (+) = 1 and
           tipoFondi.Codice         (+) = cAnno.Tipo_Spesa and
           classif1.anno_esercizio  (+) = cAnno.anno_intervento and -- classif1
           classif1.tipologia       (+) = 'TC' and
           classif1.procedura       (+) = 1 and
           classif1.codice          (+) = cAnno.tipo_intervento and
           exBilancio.Anno_Esercizio(+) = cAnno.Anno_Esercizio and -- classif11
           exBilancio.Anno_Cap      (+) = cAnno.Anno_Cap and
           exBilancio.Nro_Capitolo  (+) = cAnno.Nro_Cap and
           exBilancio.tipo_cap      (+) = cAnno.Tipo_Cap and
           exBilancio.tipo_cap      (+) = 'E' and
           codStat1.Anno_Peg             (+) = cAnno.Anno_Esercizio and   -- classif12
           codStat1.Codice               (+) = cAnno.Cod_Stat1 and
           obiettivo.tipo_tabella        (+) = '51' and             -- classif14
           obiettivo.codice              (+) = cAnno.Programma and
           programma.tipo_tabella        (+) = '52' and             -- classif15
           programma.codice              (+) = cAnno.Centro_Di_Costo and
           Cdr.codice = substr(cAnno.Up,1,2) and
           Cdc.codice = cAnno.Up and
           capEcc.Tipo_Capitolo (+)='G' and
           capEcc.Eu (+)  ='E' and
           capEcc.Anno_Esercizio  (+) = cAnno.Anno_esercizio and
           capEcc.numero_capitolo (+) = cAnno.Nro_Intervento and
           capEcc.numero_articolo (+) = 0 and
           capEcc.numero_ueb      (+) = 1 and
           capEcc.ente_proprietario_id (+)=p_ente );-- 07.01.2016 Sofia aggiunto

    commit;

    msgRes:='Inserimento migr_capitolo_entrata CAP-EG anno+1.';
    -- x capitolo che esistono da anno+1 e non in anno
    insert into migr_capitolo_entrata
    (capent_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
     descrizione,descrizione_articolo, titolo,tipologia,categoria,
     pdc_fin_quarto, pdc_fin_quinto,note,
     trasferimenti_comunitari,
     flag_per_memoria,flag_rilevante_iva,
     tipo_finanziamento, tipo_vincolo, tipo_fondo,
     siope_livello_1,siope_livello_2,siope_livello_3,
     classificatore_1,classificatore_2,classificatore_3,classificatore_4,
     classificatore_5,classificatore_6,classificatore_7,classificatore_8,
     classificatore_9,classificatore_10,classificatore_11,classificatore_12,
     classificatore_13,classificatore_14,classificatore_15,
     centro_resp,cdc,
     classe_capitolo,flag_accertabile,
     stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
     stanziamento,stanziamento_res,stanziamento_cassa,
     stanziamento_iniziale_anno2,stanziamento_anno2,
     stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
   entrata_ricorrente)     -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Entrata
     (select  migr_capent_id_seq.nextval,'CAP-EG',cAnno2.Anno_esercizio,cAnno2.nro_intervento,0,1,
              cAnno2.ogg1||' '||cAnno2.ogg2||' '||cAnno2.ogg3||' '||cAnno2.ogg4||' '||cAnno2.ogg5,null,
              decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
              decode(nvl(tip118.tipologia,' '),' ',null, tip118.titolo||'0'||tip118.tipologia||'00'),
              decode(nvl(categ118.categoria, ' ' ),' ' , null,categ118.categoria),
              decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
              decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
              null,
              decode(nvl(to_char(trans_118.codice),' '),' ',null,to_char(trans_118.codice)),
              'N', 'N',
              decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
              null,
              decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
  -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.codice_gest,
  -- DAVIDE - 16.12.015 - Fine
              decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
              decode(nvl(cAnno2.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
              decode(nvl(cAnno2.Partita_Giro, ' ' ),' ' , null,'N',null,'S','1||Partita di giro'), --classif3
			 
  -- DAVIDE - 12.01.2017 - Imposta valori classificatori 4, 6 e 7 come da mail Valenzano del 09.01.2017
              --null,null,null,null,
			  decode(nvl(cAnno2.tipo_cap_gemello, ' ' ),' ' , null,'R','1||Riaccertato','FPV','2||Fondo pluriennale vincolato'), --classif4
			  decode(cAnno2.cap_origine, 0 , null,cAnno2.cap_origine||'||'||cAnno2.cap_origine), --classif5
			  decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ),  --classif6
			  '2||No', --classif7 
  -- DAVIDE - 12.01.2017 - Fine	

              null,null,null,
              substr(decode(nvl(exBilancio.nro_capitolo,0),0,null,
                     exBilancio.tipo_cap||'/'||exBilancio.Cod_Bilancio||'||'||
                     exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5),
                     1,250), --classif11
              decode(nvl(codStat1.Codice,0 ), 0 ,null,codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
              decode(nvl(cAnno2.Cod_Stat4,0 ), 0 ,null,cAnno2.Cod_Stat4||'||'||cAnno2.Cod_Stat4 ), --classif13
              decode(nvl(obiettivo.codice,0 ), 0 ,null,obiettivo.codice||'||'||obiettivo.descr ), --classif14
              decode(nvl(programma.codice,0 ), 0 ,null,programma.codice||'||'||programma.descr ), --classif15
              Cdr.codice,Cdc.codice,
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
              decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
              nvl(cAnno.Importo,0),  0,nvl(cAnno.Stanz_Cassa_Iniz,0),
              nvl(cAnno.Importo,0),  0,nvl(cAnno.Stanz_Cassa_Def,0),
              nvl(cAnno2.importo,0), nvl(cAnno2.importo,0),nvl(cAnno3.importo,0),nvl(cAnno3.importo,0),p_ente,
          ltrim(to_char(cap118.eu_ricor, '99'))        -- DAVIDE - 22.08.2016 - aggiunto campo per Capitoli Entrata
      from gest_intervento cAnno, gest_intervento cAnno2,gest_intervento cAnno3, d118_cap_ent cap118,
           d118_titent tit118, d118_tipologie tip118, d118_categorie categ118,
           d118_piano_conti_ent pdcFin,tipologia_capitolo tipoFin ,
           d118_transazione_ue trans_118,
           tipologia_capitolo tipoFondi, tipologia_capitolo classif1,cc_gest_capitolo exBilancio,--gest_capitolo exBilancio, Sofia 27.01.2017
           tabella_supporto obiettivo, tabella_supporto programma,
           anag_delega_assessore codStat1,
           struttura Cdr , struttura Cdc, migr_capitolo_eccezione capEcc
      where cAnno2.Anno_Intervento=p_anno_esercizio+1 and
            cAnno2.Anno_esercizio=p_anno_esercizio and
            cAnno2.tipo_cap='E' and
            cAnno.anno_esercizio(+)=cAnno2.anno_esercizio and
            cAnno.Anno_intervento(+)=to_number(cAnno2.Anno_intervento)-1 and
            cAnno.tipo_cap(+)=cAnno2.tipo_cap and
            cAnno.Nro_Intervento (+)= cAnno2.Nro_Intervento and
            cAnno3.anno_esercizio(+)=cAnno2.anno_esercizio and
            cAnno3.Anno_intervento(+)=to_number(cAnno2.Anno_intervento)+1 and
            cAnno3.tipo_cap(+)=cAnno2.tipo_cap and
            cAnno3.Nro_Intervento(+) = cAnno2.Nro_Intervento and
            cap118.anno_esercizio=cAnno2.anno_esercizio and
            cap118.anno_capitolo=cAnno2.anno_esercizio and
            cap118.nro_capitolo=cAnno2.Nro_Intervento and
            cap118.nro_articolo=0 and
            tit118.anno_esercizio   (+) =cap118.anno_esercizio and
            tit118.titolo           (+) =cap118.titolo and
            tip118.anno_esercizio   (+) =cap118.Anno_Esercizio and
            tip118.titolo           (+) =cap118.titolo and
            tip118.tipologia        (+) =cap118.tipologia and
            categ118.anno_esercizio (+) =cap118.anno_esercizio and
            categ118.titolo         (+) = cap118.titolo and
            categ118.tipologia      (+) = cap118.tipologia and
            categ118.categoria      (+) = cap118.categoria and
            pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
            pdcFin.Conto            (+) =cap118.conto and
            trans_118.codice        (+) =cap118.trans_eu and
            tipoFin.Anno_Esercizio  (+) = cAnno2.anno_intervento and -- tipo_finanziamento
            tipoFin.Tipologia       (+) = 'TF' and
            tipoFin.Procedura       (+) = 1 and
            tipoFin.Codice          (+) = cAnno2.Tipo_Finanz and
            tipoFondi.Anno_Esercizio (+) = cAnno2.anno_intervento and -- tipo_fondo
            tipoFondi.Tipologia      (+) = 'TS' and
            tipoFondi.Procedura      (+) = 1 and
            tipoFondi.Codice         (+) = cAnno2.Tipo_Spesa and
            classif1.anno_esercizio  (+) = cAnno2.anno_intervento and -- classif1
            classif1.tipologia       (+) = 'TC' and
            classif1.procedura       (+) = 1 and
            classif1.codice          (+) = cAnno2.tipo_intervento and
            exBilancio.Anno_Esercizio(+) = cAnno2.Anno_Esercizio and -- classif11
            exBilancio.Anno_Cap      (+) = cAnno2.Anno_Cap and
            exBilancio.Nro_Capitolo  (+) = cAnno2.Nro_Cap and
            exBilancio.tipo_cap      (+) = cAnno2.Tipo_Cap and
            exBilancio.tipo_cap      (+) = 'E' and
            codStat1.Anno_Peg             (+) = cAnno2.Anno_Esercizio and   -- classif12
            codStat1.Codice               (+) = cAnno2.Cod_Stat1 and
            obiettivo.tipo_tabella        (+) = '51' and             -- classif14
            obiettivo.codice              (+) = cAnno2.Programma and
            programma.tipo_tabella        (+) = '52' and             -- classif15
            programma.codice              (+) = cAnno2.Centro_Di_Costo and
            Cdr.codice = substr(cAnno2.Up,1,2) and
            Cdc.codice = cAnno2.Up and
            capEcc.Tipo_Capitolo (+)='G' and
            capEcc.Eu (+)  ='E' and
            capEcc.Anno_Esercizio  (+) = cAnno2.Anno_esercizio and
            capEcc.numero_capitolo (+) = cAnno2.Nro_Intervento and
            capEcc.numero_articolo (+) = 0 and
            capEcc.numero_ueb      (+) = 1 and
            capEcc.ente_proprietario_id (+)=p_ente and -- 07.01.2016 Sofia aggiunto
            0=(select count(*) from migr_capitolo_entrata m
               where m.anno_esercizio=p_anno_esercizio and
                     m.numero_Capitolo=cAnno2.Nro_Intervento and
                     m.numero_articolo=0  and
                     m.tipo_capitolo='CAP-EG'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente));

    commit;

    msgRes:='Inserimento migr_capitolo_entrata CAP-EG anno+2.';
    -- x capitolo che esistono da anno+2 e non in anno
    insert into migr_capitolo_entrata
    ( capent_id,tipo_capitolo,anno_esercizio,numero_capitolo,numero_articolo,numero_ueb,
      descrizione,descrizione_articolo, titolo,tipologia,categoria,
      pdc_fin_quarto, pdc_fin_quinto,note,
      trasferimenti_comunitari,
      flag_per_memoria,flag_rilevante_iva,
      tipo_finanziamento, tipo_vincolo, tipo_fondo,
      siope_livello_1,siope_livello_2,siope_livello_3,
      classificatore_1,classificatore_2,classificatore_3,classificatore_4,
      classificatore_5,classificatore_6,classificatore_7,classificatore_8,
      classificatore_9,classificatore_10,classificatore_11,classificatore_12,
      classificatore_13,classificatore_14,classificatore_15,
      centro_resp,cdc,
      classe_capitolo,flag_accertabile,
      stanziamento_iniziale,stanziamento_iniziale_res,stanziamento_iniziale_cassa,
      stanziamento,stanziamento_res,stanziamento_cassa,
      stanziamento_iniziale_anno2,stanziamento_anno2,
      stanziamento_iniziale_anno3,stanziamento_anno3,ente_proprietario_id,
    entrata_ricorrente)     -- DAVIDE - 22.08.2016 - aggiunti campi per Capitoli Entrata
    (select  migr_capent_id_seq.nextval,'CAP-EG',cAnno3.Anno_intervento,cAnno3.nro_intervento,0,1,
             cAnno3.ogg1||' '||cAnno3.ogg2||' '||cAnno3.ogg3||' '||cAnno3.ogg4||' '||cAnno3.ogg5,null,
             decode(nvl(tit118.titolo,' '),' ',null,tit118.titolo),
             decode(nvl(tip118.tipologia,' '),' ',null, tip118.titolo||'0'||tip118.tipologia||'00'),
             decode(nvl(categ118.categoria, ' ' ),' ' , null,categ118.categoria),
             decode(nvl(cap118.conto,' '),' ', null,decode(pdcFin.Livello,4,pdcFin.Conto,null)),
             decode(nvl(cap118.conto,' '), ' ',null, decode(pdcFin.Livello,5,pdcFin.Conto,null)),
             null,
             decode(nvl(to_char(trans_118.codice),' '),' ',null,to_char(trans_118.codice)),
             'N', 'N',
             decode(nvl(tipoFin.Codice,' '),' ',null, tipoFin.Codice||'||'||tipoFin.Descrizione ),
             null,
             decode(nvl(tipoFondi.Codice,' ' ),' ',null,tipoFondi.codice||'||'||tipoFondi.Descrizione),
  -- DAVIDE - 16.12.015 - Popolamento campo siope_livello_3 - richiesta Vitelli
              --null,null, null,
              null,null, cAnno.codice_gest,
  -- DAVIDE - 16.12.015 - Fine
             decode(nvl(classif1.codice,' ' ),' ' ,null,classif1.codice||'||'||classif1.descrizione), -- classif1
             decode(nvl(cAnno3.Ritenuta_Fisc, ' ' ),' ' , null,'N',null,'S','1||Ritenuta Fiscale'),    --classif2
             decode(nvl(cAnno3.Partita_Giro, ' ' ),' ' , null,
               'N',null,'S','1||Partita di giro'), --classif3			   
			 
  -- DAVIDE - 12.01.2017 - Imposta valori classificatori 4, 6 e 7 come da mail Valenzano del 09.01.2017
             --null,null,null,null,
			 decode(nvl(cAnno3.tipo_cap_gemello, ' ' ),' ' , null,'R','1||Riaccertato','FPV','2||Fondo pluriennale vincolato'), --classif4
			 decode(cAnno3.cap_origine, 0 , null,cAnno3.cap_origine||'||'||cAnno3.cap_origine), --classif5
			 decode(nvl(codStat1.Codice,0 ), 0 ,null,
                    codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ),  --classif6
			 '2||No', --classif7 
  -- DAVIDE - 12.01.2017 - Fine	
			 
			 null,null,null,
			 
             substr(decode(nvl(exBilancio.nro_capitolo,0),0,null,
                    exBilancio.tipo_cap||'/'||exBilancio.Cod_Bilancio||'||'||
                    exBilancio.Ogg1||' '||exBilancio.Ogg2||' '||exBilancio.Ogg3||' ' ||exBilancio.Ogg4||' '||exBilancio.Ogg5),
                    1,250), --classif11
             decode(nvl(codStat1.Codice,0 ), 0 ,null,codStat1.Codice||'||'||codStat1.Descrizione||' ASS- '||codStat1.Assessore ), --classif12
             decode(nvl(cAnno3.Cod_Stat4,0 ), 0 ,null,cAnno3.Cod_Stat4||'||'||cAnno3.Cod_Stat4 ), --classif13
             decode(nvl(obiettivo.codice,0 ), 0 ,null,obiettivo.codice||'||'||obiettivo.descr ), --classif14
             decode(nvl(programma.codice,0 ), 0 ,null,programma.codice||'||'||programma.descr ), --classif15
             Cdr.codice,Cdc.codice,
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'STD',capEcc.Classe_Capitolo),
             decode(nvl(capEcc.Numero_Capitolo,0), 0 ,'S',capEcc.flag_impegnabile),
             nvl(cAnno.Importo,0),  0,nvl(cAnno.Stanz_Cassa_Iniz,0),
             nvl(cAnno.Importo,0),  0,nvl(cAnno.Stanz_Cassa_Def,0),
             nvl(cAnno2.importo,0), nvl(cAnno2.importo,0),nvl(cAnno3.importo,0),nvl(cAnno3.importo,0),p_ente,
         ltrim(to_char(cap118.eu_ricor, '99'))        -- DAVIDE - 22.08.2016 - aggiunto campo per Capitoli Entrata
     from gest_intervento cAnno, gest_intervento cAnno2,gest_intervento cAnno3, d118_cap_ent cap118,
          d118_titent tit118, d118_tipologie tip118, d118_categorie categ118,
          d118_piano_conti_ent pdcFin,tipologia_capitolo tipoFin ,
          d118_transazione_ue trans_118,
          tipologia_capitolo tipoFondi, tipologia_capitolo classif1,cc_gest_capitolo exBilancio,--gest_capitolo exBilancio, 27.01.2017 Sofia 
          tabella_supporto obiettivo, tabella_supporto programma,
          anag_delega_assessore codStat1,
          struttura Cdr , struttura Cdc, migr_capitolo_eccezione capEcc
     where cAnno3.Anno_Intervento=p_anno_esercizio+2 and
           cAnno3.Anno_esercizio=p_anno_esercizio and
           cAnno3.tipo_cap='E' and
           cAnno.anno_esercizio(+)=cAnno3.anno_esercizio and
           cAnno.Anno_intervento(+)=to_number(cAnno3.Anno_intervento)-2 and
           cAnno.tipo_cap(+)=cAnno3.tipo_cap and
           cAnno.Nro_Intervento (+)= cAnno3.Nro_Intervento and
           cAnno2.anno_esercizio(+)=cAnno3.anno_esercizio and
           cAnno2.Anno_intervento(+)=to_number(cAnno3.Anno_intervento)-1 and
           cAnno2.tipo_cap(+)=cAnno3.tipo_cap and
           cAnno2.Nro_Intervento(+) = cAnno3.Nro_Intervento and
           cap118.anno_esercizio=cAnno3.anno_esercizio and
           cap118.anno_capitolo=cAnno3.anno_esercizio and
           cap118.nro_capitolo=cAnno3.Nro_Intervento and
           cap118.nro_articolo=0 and
           tit118.anno_esercizio   (+) =cap118.anno_esercizio and
           tit118.titolo           (+) =cap118.titolo and
           tip118.anno_esercizio   (+) =cap118.Anno_Esercizio and
           tip118.titolo           (+) =cap118.titolo and
           tip118.tipologia        (+) =cap118.tipologia and
           categ118.anno_esercizio (+) =cap118.anno_esercizio and
           categ118.titolo         (+) = cap118.titolo and
           categ118.tipologia      (+) = cap118.tipologia and
           categ118.categoria      (+) = cap118.categoria and
           pdcFin.Anno_Esercizio   (+) =cap118.anno_esercizio and
           pdcFin.Conto            (+) =cap118.conto and
           trans_118.codice        (+) =cap118.trans_eu and
           tipoFin.Anno_Esercizio  (+) = cAnno3.anno_intervento and -- tipo_finanziamento
           tipoFin.Tipologia       (+) = 'TF' and
           tipoFin.Procedura       (+) = 1 and
           tipoFin.Codice          (+) = cAnno3.Tipo_Finanz and
           tipoFondi.Anno_Esercizio (+) = cAnno3.anno_intervento and -- tipo_fondo
           tipoFondi.Tipologia      (+) = 'TS' and
           tipoFondi.Procedura      (+) = 1 and
           tipoFondi.Codice         (+) = cAnno3.Tipo_Spesa and
           classif1.anno_esercizio  (+) = cAnno3.anno_intervento and -- classif1
           classif1.tipologia       (+) = 'TC' and
           classif1.procedura       (+) = 1 and
           classif1.codice          (+) = cAnno3.tipo_intervento and
           exBilancio.Anno_Esercizio(+) = cAnno3.Anno_Esercizio and -- classif11
           exBilancio.Anno_Cap      (+) = cAnno3.Anno_Cap and
           exBilancio.Nro_Capitolo  (+) = cAnno3.Nro_Cap and
           exBilancio.tipo_cap      (+) = cAnno3.Tipo_Cap and
           exBilancio.tipo_cap      (+) = 'E' and
           codStat1.Anno_Peg             (+) = cAnno3.Anno_Esercizio and   -- classif12
           codStat1.Codice               (+) = cAnno3.Cod_Stat1 and
           obiettivo.tipo_tabella        (+) = '51' and             -- classif14
           obiettivo.codice              (+) = cAnno3.Programma and
           programma.tipo_tabella        (+) = '52' and             -- classif15
           programma.codice              (+) = cAnno3.Centro_Di_Costo and
           Cdr.codice = substr(cAnno3.Up,1,2) and
           Cdc.codice = cAnno3.Up and
           capEcc.Tipo_Capitolo (+)='G' and
           capEcc.Eu (+)  ='E' and
           capEcc.Anno_Esercizio  (+) = cAnno3.Anno_esercizio and
           capEcc.numero_capitolo (+) = cAnno3.Nro_Intervento and
           capEcc.numero_articolo (+) = 0 and
           capEcc.numero_ueb      (+) = 1 and
           capEcc.ente_proprietario_id (+)=p_ente and -- 07.01.2016 Sofia aggiunto
           0=(select count(*) from migr_capitolo_entrata m
              where m.anno_esercizio=p_anno_esercizio and
                    m.numero_Capitolo=cAnno3.Nro_Intervento and
                    m.numero_articolo=0  and
                    m.tipo_capitolo='CAP-EG'
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente));

     commit;
  
     -- DAVIDE - 12.01.2017 - popola il classificatore 7 con l'update come da mail Valenzano del 09.01.2017
     update migr_capitolo_entrata migrp
        set classificatore_7='1||Si'  
      where exists (select 1 from as_movimenti_llpp llpp
                    where llpp.anno_capitolo=migrp.anno_esercizio
 				            and   llpp.nro_capitolo=migrp.numero_capitolo
 				            and   llpp.tipo_eu='E')
	    and migrp.ente_proprietario_id=p_ente
	    and migrp.tipo_capitolo='CAP-EG';

	 commit;
     -- DAVIDE - 12.01.2017 - Fine

     msgRes:='Aggiornamento migr_capitolo_entrata CAP-EG per stanz. residuo.';
     -- update per stanziamenti res e cassa
     update migr_capitolo_entrata m
     set (m.stanziamento_iniziale_res)=
     /*12.10.2015
     (select nvl(sum(res.residui_da_riportare ),0)
      from  as_capitoli res
      where res.anno_peg=m.anno_esercizio and
            res.nro_capitolo=m.numero_capitolo and
            res.anno_capitolo<=res.anno_peg and -- 05.10.2015 Sofia mancava =
            res.tipo_eu='E')
      where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EG' and
            0!=(select count(*)
                from as_capitoli res
                where res.anno_peg=m.anno_esercizio and
                      res.nro_capitolo=m.numero_capitolo and
                      res.anno_capitolo<=res.anno_peg and -- 05.10.2015 Sofia mancava =
                      res.tipo_eu='E')
     aggiornamento dopo riaccertamento su indicazione di Valenzano */
 /*    (select nvl(sum(res.stanz_definitivo ),0)
      from  as_capitoli res
      where res.anno_peg=m.anno_esercizio and
            res.nro_capitolo=m.numero_capitolo and
            res.anno_capitolo<res.anno_peg and
            res.tipo_eu='E')
     where m.anno_esercizio=p_anno_esercizio  and m.tipo_capitolo='CAP-EG' and
           0!=(select count(*)
               from as_capitoli res
               where res.anno_peg=m.anno_esercizio and
                     res.anno_capitolo<res.anno_peg and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='E')*/
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     -- 27.01.2017 Sofia x migrazione
     (select nvl(importo_res,0)
      from  gest_intervento res 
      where res.nro_intervento=m.numero_capitolo and
            res.anno_intervento=p_anno_esercizio and
            res.tipo_cap='E')
     where m.anno_esercizio=p_anno_esercizio  
     and   m.tipo_capitolo='CAP-EG'            
     and   m.ente_proprietario_id=p_ente 
     and   0!=(select count(*)
               from  gest_intervento res 
               where res.nro_intervento=m.numero_capitolo and
               res.anno_intervento=p_anno_esercizio and
              res.tipo_cap='E')
      and m.ente_proprietario_id=p_ente;
     commit;

     --05.10.2015 Sofia mancava calcolo residui da residui_80000
     msgRes:='Aggiornamento migr_capitolo_entrata per stanz. residui CAP-EG da residui_80000.';
     /* commento perchè non serve più Anna V.
     update migr_capitolo_entrata m
     set (m.stanziamento_iniziale_res)=
          /*12.10.2015
     (select nvl(sum(res.residuo ),0)
      from  residui_80000 res
      where res.anno_capitolo=m.anno_esercizio and
            res.nro_capitolo=m.numero_capitolo and
            res.tipo_eu='E')
     where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EG' and
           0!=(select count(*)
               from residui_80000 res
               where res.anno_capitolo=m.anno_esercizio and
                     res.nro_capitolo=m.numero_capitolo and
                     res.tipo_eu='E')
      aggiornamento dopo riaccertamento su indicazione di Valenzano *
       (select nvl(sum(res.residuo ),0)
            from  residui_80000_new res
            where res.anno_capitolo=m.anno_esercizio and
                  res.nro_capitolo=m.numero_capitolo and
                  res.tipo_eu='E')
       where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EG' and
             0!=(select count(*)
                 from residui_80000_new res
                 where res.anno_capitolo=m.anno_esercizio and
                       res.nro_capitolo=m.numero_capitolo and
                       res.tipo_eu='E')
      and m.ente_proprietario_id=p_ente;
      commit;*/

     msgRes:='Aggiornamento migr_capitolo_entrata CAP-EG per stanz. cassa.';
     update migr_capitolo_entrata  m
      set --m.stanziamento_iniziale_cassa=m.stanziamento_iniziale_cassa+m.stanziamento_iniziale_res,
          m.stanziamento_res=m.stanziamento_iniziale_res
          --m.stanziamento_cassa=m.stanziamento_cassa+m.stanziamento_iniziale_res
      where m.anno_esercizio=p_anno_esercizio and m.tipo_capitolo='CAP-EG' and m.stanziamento_iniziale_res!=0
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
     and m.ente_proprietario_id=p_ente;


   pCodRes:=codRes;
   pMsgRes:='Migrazione capitolo entrata gestione OK.';
   commit;

exception
   when others then
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
 end migrazione_cge;

 -- procedure migrazione_vincoli_cp(p_anno_esercizio varchar2,p_ente number) is

--    vincoloId   integer := 0;
--    nroCapitolo integer := 0;
--    nroArticolo integer := 0;

--  begin
    --delete migr_vincolo_capitolo
    -- where anno_esercizio = p_anno_esercizio
    --   and fl_migrato = 'N'
    --   and tipo_vincolo_bil = 'P'
    --   and ente_proprietario_id=p_ente;

    -- ancora da implementare  per pvto !

  --  null;
--  end migrazione_vincoli_cp;

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

       --  migr_classif_capitolo
       -- CAP-UP
       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_1','Tipologia Capitolo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_2','Ritenuta Fiscale',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_3','Partita di Giro',p_ente);
	   
    -- DAVIDE - 12.01.2017 - aggiunta nuovi classificatori, mail Valenzano del 09.01.2017

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_4','Tipo Capitolo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_5','Numero Capitolo Origine',p_ente); 
	   
       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_6','Codice Delega',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_7','Capitolo LLPP',p_ente);
	   
    -- DAVIDE - 12.01.2017 - Fine

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_31','Ex Codifica Bilancio',p_ente);


       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_32','Assessorato',p_ente);

        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_33','Gruppo',p_ente);

        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_34','Ex Obiettivo',p_ente);

        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-UP','CLASSIFICATORE_35','Ex Programma',p_ente);


        -- CAP-EP
        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_36','Tipologia Capitolo',p_ente);


        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_37','Ritenuta Fiscale',p_ente);

        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_38','Partita di Giro',p_ente);
	   
    -- DAVIDE - 12.01.2017 - aggiunta nuovi classificatori, mail Valenzano del 09.01.2017

        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_39','Tipo Capitolo',p_ente);

        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_40','Numero Capitolo Origine',p_ente); 
	   
        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_41','Codice Delega',p_ente);

        insert into migr_classif_capitolo
        (classif_tipo_id, tipo_capitolo, codice, descrizione,
         ente_proprietario_id)
        values
        (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_42','Capitolo LLPP',p_ente);
	   
    -- DAVIDE - 12.01.2017 - Fine

         insert into migr_classif_capitolo
         (classif_tipo_id, tipo_capitolo, codice, descrizione,
          ente_proprietario_id)
         values
         (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_46','Ex Codifica Bilancio',p_ente);

         insert into migr_classif_capitolo
         (classif_tipo_id, tipo_capitolo, codice, descrizione,
          ente_proprietario_id)
         values
         (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_47','Assessorato',p_ente);

         insert into migr_classif_capitolo
         (classif_tipo_id, tipo_capitolo, codice, descrizione,
          ente_proprietario_id)
          values
          (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_48','Gruppo',p_ente);

          insert into migr_classif_capitolo
          (classif_tipo_id, tipo_capitolo, codice, descrizione,
           ente_proprietario_id)
          values
          (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_49','Ex Obiettivo',p_ente);

          insert into migr_classif_capitolo
          (classif_tipo_id, tipo_capitolo, codice, descrizione,
           ente_proprietario_id)
          values
          (migr_classif_capitolo_id_seq.nextval,'CAP-EP','CLASSIFICATORE_50','Ex Programma',p_ente);

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

       --  migr_classif_capitolo
       -- CAP-UG
       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_1','Tipologia Capitolo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
        values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_2','Ritenuta Fiscale',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_3','Partita di Giro',p_ente);
	   
    -- DAVIDE - 12.01.2017 - aggiunta nuovi classificatori, mail Valenzano del 09.01.2017

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_4','Tipo Capitolo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_5','Numero Capitolo Origine',p_ente);
	   
       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_6','Codice Delega',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_7','Capitolo LLPP',p_ente);
	   
    -- DAVIDE - 12.01.2017 - Fine

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_31','Ex Codifica Bilancio',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_32','Assessorato',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_33','Gruppo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_34','Ex Obiettivo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-UG','CLASSIFICATORE_35','Ex Programma',p_ente);

       -- CAP-EG
       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_36','Tipologia Capitolo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_37','Ritenuta Fiscale',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_38','Partita di Giro',p_ente);
	   
    -- DAVIDE - 12.01.2017 - aggiunta nuovi classificatori, mail Valenzano del 09.01.2017

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_39','Tipo Capitolo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_40','Numero Capitolo Origine',p_ente);
	   
       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_41','Codice Delega',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_42','Capitolo LLPP',p_ente);
	   
    -- DAVIDE - 12.01.2017 - Fine

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_46','Ex Codifica Bilancio',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_47','Assessorato',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_48','Gruppo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_49','Ex Obiettivo',p_ente);

       insert into migr_classif_capitolo
       (classif_tipo_id, tipo_capitolo, codice, descrizione,
        ente_proprietario_id)
       values
       (migr_classif_capitolo_id_seq.nextval,'CAP-EG','CLASSIFICATORE_50','Ex Programma',p_ente);

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

  procedure migrazione_impegno(p_ente_proprietario_id number,
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
                        from movimento_contab mc, as_movimenti_mandati asm, atto a, fornitore f
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

      if p_tipo_cap = TIPO_CAP_USCITA then
         h_impegno := 'Impegno ' || migrImpegno.anno_impegno || '/' ||
                   migrImpegno.numero_impegno || '/' ||
                   migrImpegno.numero_ueb || '.';
      elsif p_tipo_cap = TIPO_CAP_ENTRATA THEN
         h_impegno := 'Accertamento ' || migrImpegno.anno_impegno || '/' ||
                   migrImpegno.numero_impegno || '/' ||
                   migrImpegno.numero_ueb || '.';
      end if;

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

              if p_tipo_cap = TIPO_CAP_USCITA then
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
              elsif  p_tipo_cap = TIPO_CAP_ENTRATA then
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
      IF migrImpegno.codice_soggetto = '0' AND h_stato_impegno = STATO_IMPEGNO_D THEN
        migrImpegno.codice_soggetto := null;
        h_stato_impegno := STATO_IMPEGNO_N;
    ELSIF migrImpegno.codice_soggetto = '0' THEN
        migrImpegno.codice_soggetto := null;
        END IF;

        IF migrImpegno.codice_soggetto = '999' THEN

            IF h_stato_impegno = STATO_IMPEGNO_P THEN
                migrImpegno.codice_soggetto := null;
            ELSIF h_stato_impegno = STATO_IMPEGNO_N THEN
                NULL;
            ELSIF h_stato_impegno = STATO_IMPEGNO_D THEN
                h_stato_impegno := STATO_IMPEGNO_N;
            END IF;

            -- Aggiungi la classe soggetto SOGGETTI DIVERSI
            IF h_stato_impegno = STATO_IMPEGNO_N THEN
                h_classe_soggetto:='SOGGETTI DIVERSI||SOGGETTI DIVERSI||';
            END IF;
        END IF;

        if h_stato_impegno in (STATO_IMPEGNO_P, STATO_IMPEGNO_N) then
            -- controlla se ci sono liquidazioni legate a questi impegni
            begin
                select count(*)
                  into numLiquidazioni
                  from movimento_contab liq,
                  as_movimenti_mandati asm, atto a
                where liq.tipo_mov=3 -- Liquidazione
                and liq.tipo_cap=TIPO_CAP_USCITA -- discrimina la liquidazione sull'impegno
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

        end if;

    -- DAVIDE - 01.12.2016 - Fine

      end if;

      -- provvedimento
      -- 22.09.015 Sofia
      if codRes=0 and segnalare = false then
       msgRes := 'Dati Provvedimento.';
       if migrImpegno.numero_provvedimento is null or
          migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
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
        if p_tipo_cap = TIPO_CAP_USCITA then
		
          IF migrImpegno.codice_soggetto = '999' AND       -- DAVIDE - 14.12.2016 - Impegni legati a soggetti 999 devono avere stato definito
		     h_stato_impegno = STATO_IMPEGNO_N       THEN
             h_stato_impegno := STATO_IMPEGNO_D;
          END IF;
		  
          msgRes := 'Inserimento in migr_impegno.';
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
             TIPO_IMPEGNO_I,
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
        elsif p_tipo_cap = TIPO_CAP_ENTRATA then
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
             TIPO_IMPEGNO_A,
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
        if p_tipo_cap = TIPO_CAP_USCITA then
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
        elsif p_tipo_cap = TIPO_CAP_ENTRATA then
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
  end migrazione_impegno;

  procedure migrazione_subimpegno(p_ente_proprietario_id number,
                               p_anno_esercizio       varchar2,
                               p_tipo_cap             varchar2,
                               p_cod_res              out number,
                               p_imp_inseriti         out number,
                               p_imp_scartati         out number,
                               msgResOut              out varchar2) is

    msgRes varchar2(1500) := null;
    codRes number := 0;
    h_impegno varchar2(50) := null;
    h_tipoMov varchar2(50) := null;
    h_pdc_finanziario MIGR_IMPEGNO.PDC_FINANZIARIO%type := null; -- dato ereditato dall'impegno
    h_sogg_migrato number := 0;
    h_codsogg_migrato varchar2(50) := null; -- codice soggetto migrato, corrisponde a fornitore.codice se soggetto di natura 0,1,2,3 ; fornitore.codice_rif se  soggetto di natura 4 (sempre che ci sia correispondenza su migr_soggetto)
    h_mov_migrato number := 0; --movimento padre migrato
    h_num number := 0;
    h_stato_impegno varchar2(1) := null;
     h_parere_finanziario integer := 1; -- non cambia rimane impostato a TRUE

    msgMotivoScarto varchar2(1500) := null;
    cImpInseriti number := 0;
    cImpScartati number := 0;
    numImpegno   number := 0;

     segnalare boolean:=false;

    h_anno_provvedimento   varchar2(4) := null;
    h_numero_provvedimento varchar2(10) := null;
    h_tipo_provvedimento   varchar2(20) := null;
    h_stato_provvedimento   varchar2(5) := null;
    h_direzione_provvedimento varchar2(10):=null;

  begin
    p_imp_scartati := 0;
    p_imp_inseriti := 0;
    p_cod_res      := 0;

    msgResOut := 'Migrazione sub ['||p_tipo_cap||'].';


    for migrImpegno in (select -- mc.anno_esercizio
                              --  asm.anno_peg anno_esercizio
                              p_anno_esercizio anno_esercizio-- 30.01.2017 Sofia
                              , mc.anno_intervento anno_impegno
                              , mc.nro_mov_riferim numero_impegno
                              , mc.nro_movimento numero_subimpegno
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
                              , replace(mc.note,'''','''''') as nota
                              , mc.codice_cup as cup
                              , mc.codice_cig as cig
                              , 'SVI' as tipo_impegno
                              --, NULL as pdc_finanziario     -- DAVIDE - 24.10.2016
                              , asm.conto_118 pdc_finanziario -- DAVIDE - 24.10.2016
                              , mc.codice_gest as siope       -- DAVIDE - 16.12.015 - Popolamento campo siope (E/U)
    -- DAVIDE - 16.12.015 - Fine
    -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
                              , asm.cofog
                              , asm.trans_eu
                              , asm.eu_ricor
                              , asm.nro_mov_267
    -- DAVIDE - 24.10.2016 - Fine
                        from movimento_contab mc, as_movimenti_mandati asm, atto a, fornitore f
                        where asm.tipo_mov=2 -- SUBIMPEGNI / SUBACCERTAMENTO
                        and   asm.tipo_eu=p_tipo_cap
--                        and   asm.anno_peg=p_anno_esercizio
                        and   asm.anno_peg=p_anno_esercizio-1 -- 30.01.2017 Sofia per migrazione effettiva                        
--                        and   asm.disponibilita>0
                        --and   nvl(asm.residuo_da_riportare,0)>0  -- 22.09.015 Sofia - modifica dopo mail Valenzano
                        and  ( ( mc.anno_intervento<=p_anno_esercizio-1 and nvl(asm.residuo_da_riportare,0)>0 ) or -- Sofia 19.12.2016 x migrPluriennali
                                 mc.anno_intervento>p_anno_esercizio-1 -- 30.01.2017 Sofia
                             )
                        and   mc.tipo_mov=asm.tipo_mov
                        and   mc.tipo_cap=asm.tipo_eu
                        and   mc.nro_movimento = asm.nro_movimento
                        and   a.anno_prot=mc.anno_delibera
                        and   a.nro_prot=mc.nro_delibera -- 22.09.015 Sofia - modifica dopo incontro con Valenzano
                        and   f.codice(+) = mc.cod_fornitore
                        order by 2,3,4) loop
/*                        where mc.tipo_cap=p_tipo_cap 22.09.015 Sofia - modifica dopo incontro con Valenzano
                        and mc.tipo_mov = 2 -- SUBIMPEGNI / SUBACCERTAMENTO
                        and mc.anno_esercizio = p_anno_esercizio
                        and nvl(mc.importo,0)-nvl(mc.pag_anno_prec,0) > 0
                        and mc.nro_movimento = asm.nro_movimento
                        and mc.anno_esercizio = asm.anno_peg
                        and mc.anno_delibera = a.anno_prot
                        and mc.nro_delibera = a.nro_prot
                        and mc.cod_fornitore IS NOT NULL and mc.cod_fornitore <> COD_SOGGETTO_NULL -- condizione da eliminare perchè tutti i sub devono avere il soggetto determinato, necessaria bonifica dei dati
                        order by 2,3,4) loop*/

      msgRes := 'Lettura SubMovimenti.';


      h_impegno := migrImpegno.anno_impegno || '/' ||
                   migrImpegno.numero_impegno || '/' ||
                   migrImpegno.numero_subimpegno || '.';
      codRes := 0;
      h_pdc_finanziario :='-1';
      h_sogg_migrato := 0;
      h_mov_migrato := 0; -- movimento padre migrato
      h_num          := 0;
      h_stato_impegno:= null;
      msgMotivoScarto:= null;
      msgRes := null;

      h_anno_provvedimento   := null;
      h_numero_provvedimento := null;
      h_tipo_provvedimento   := null;
      h_stato_provvedimento   := null;
      h_direzione_provvedimento:=null;
      segnalare:=false; -- 22.09.015 Sofia

      -- verifica che il ovimento padre sia stato migrato, in caso contrario salto al record successivo
      if p_tipo_cap = TIPO_CAP_USCITA then
        select count(*) into h_mov_migrato from migr_impegno mi where mi.numero_impegno = migrImpegno.numero_impegno and mi.tipo_movimento = TIPO_IMPEGNO_I;
      elsif p_tipo_cap = TIPO_CAP_ENTRATA then
        select count(*) into h_mov_migrato from migr_accertamento mi where mi.numero_accertamento = migrImpegno.numero_impegno and mi.tipo_movimento = TIPO_IMPEGNO_A;
      end if;

      if h_mov_migrato = 0 then
        codRes := -1; -- il record non deve essere elaborato, dobbiamo saltare a quello successivo
        msgRes := 'Movimento padre non migrato';
      end if;

      -- verifica che il soggetto sia determinato e che sia stato migrato
      -- soggetto_determinato
      if (codRes = 0 and migrImpegno.codice_soggetto is null or migrImpegno.codice_soggetto = '' or migrImpegno.codice_soggetto = COD_SOGGETTO_NULL) then
        msgRes := 'Soggetto non determinato per sub';
        codRes := -1; -- il record viene scartato, inserito nella migr_impegno_scarto
      end if;
      --09.10.2015 se soggetto ATI sub scartato (ati non migrato come soggetto) - DAVIDE - tolto questo controllo - i soggetti ATI vengono migrati per CMTO
      --if migrImpegno.nat_giuridica = 5 then
      --  msgRes := 'Soggetto ATI per sub';
      --  codRes := -1; -- il record viene scartato, inserito nella migr_impegno_scarto
      --end if;

      -- soggetto migrato
      if migrImpegno.Soggetto_Determinato = 'S' and codRes = 0 then
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

        /*
        select nvl(count(*), 0)
            into h_sogg_migrato
            from migr_soggetto
           where codice_soggetto = migrImpegno.codice_soggetto
             and ente_proprietario_id = p_ente_proprietario_id;
        if h_sogg_migrato = 0 then
          codRes := -1;
          msgRes := 'Soggetto determinato non migrato.';
        end if;*/

      end if;

      -- DAVIDE - 24.10.2016 - se dal ciclo precedente non si ricava il pdc_v,
      --                       tento di ricavarlo dall'impegno / accertamento padre
      if codRes = 0 then
          if migrImpegno.pdc_finanziario is null then
              if p_tipo_cap = TIPO_CAP_USCITA then
                  msgRes := 'Lettura pdc_finanziario impegno';
                  select pdc_finanziario into h_pdc_finanziario
                    from migr_impegno
                   where tipo_movimento = TIPO_IMPEGNO_I
                     and numero_impegno = migrImpegno.numero_impegno
                     and ente_proprietario_id = p_ente_proprietario_id;
              elsif p_tipo_cap = TIPO_CAP_ENTRATA then
                  msgRes := 'Lettura pdc_finanziario accertamento';
                  select pdc_finanziario into h_pdc_finanziario
                    from migr_accertamento
                   where tipo_movimento = TIPO_IMPEGNO_A
                     and numero_accertamento = migrImpegno.numero_impegno
                     and ente_proprietario_id = p_ente_proprietario_id;
              end if;
          else
              h_pdc_finanziario := migrImpegno.pdc_finanziario;
          end if;
      end if;
      -- DAVIDE - 24.10.2016 - Fine

      -- stato_impegno
      h_stato_impegno := migrImpegno.stato_operativo;

      -- provvedimento

      -- 22.09.015 Sofia
      if codRes=0 then
       msgRes := 'Dati Provvedimento.';
       if migrImpegno.numero_provvedimento is null or
         migrImpegno.numero_provvedimento = '0' then
          if h_stato_impegno != STATO_IMPEGNO_P then
            h_anno_provvedimento := p_anno_esercizio;
            h_tipo_provvedimento := PROVV_SPR || '||';
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
          h_stato_provvedimento  :=h_stato_impegno;
       end if;
     end if;

      if codRes = 0
      then
        if p_tipo_cap = TIPO_CAP_USCITA then
           msgRes := 'Inserimento in migr_impegno.';
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
    -- DAVIDE - 24.10.2016 - Fine
           )
          values
            (migr_impegno_id_seq.nextval,
             TIPO_IMPEGNO_S,
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
             h_direzione_provvedimento,
             migrImpegno.oggetto_provvedimento,
             migrImpegno.note_provvedimento,
             h_stato_provvedimento,
             migrImpegno.Soggetto_Determinato,
             h_codsogg_migrato,
             migrImpegno.Nota,
             migrImpegno.Tipo_Impegno,
             --migrImpegno.opera,
             h_pdc_finanziario,
             p_ente_proprietario_id,
             h_parere_finanziario
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
             , migrImpegno.siope
    -- DAVIDE - 16.12.015 - Fine
    -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
             , migrImpegno.cup
             , migrImpegno.cig
             , migrImpegno.cofog
             , migrImpegno.trans_eu
             , migrImpegno.eu_ricor
    -- DAVIDE - 24.10.2016 - Fine
           );
        elsif p_tipo_cap  = TIPO_CAP_ENTRATA then
           msgRes := 'Inserimento in migr_accertamento.';
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
    -- DAVIDE - 24.10.2016 - Fine
           )
          values
            (migr_impegno_id_seq.nextval,
             TIPO_IMPEGNO_S,
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
             h_direzione_provvedimento,
             migrImpegno.oggetto_provvedimento,
             migrImpegno.note_provvedimento,
             h_stato_provvedimento,
             migrImpegno.Soggetto_Determinato,
             h_codsogg_migrato,
             migrImpegno.Nota,
             --migrImpegno.opera,
             h_pdc_finanziario,
             p_ente_proprietario_id,
             h_parere_finanziario
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
             , migrImpegno.siope
    -- DAVIDE - 16.12.015 - Fine
    -- DAVIDE - 24.10.2016 - Popolamento campi mancanti - segnalazione Valenzano
             , migrImpegno.trans_eu
             , migrImpegno.eu_ricor
    -- DAVIDE - 24.10.2016 - Fine
       );
        end if;
        cImpInseriti := cImpInseriti + 1;
      end if;

      if codRes != 0 or
         segnalare=true then
        if msgMotivoScarto is null then
                msgMotivoScarto := msgRes;
        end if;

        if p_tipo_cap = TIPO_CAP_USCITA then
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
        elsif p_tipo_cap = TIPO_CAP_ENTRATA then
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
      msgResOut := msgResOut||h_impegno|| msgRes || 'Record non trovato.';
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
  end migrazione_subimpegno;

  procedure migrazione_impacc (p_ente_proprietario_id number,
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
     -- DAVIDE : gestione ente proprietario nelle tabelle di migrazione
            DELETE FROM MIGR_IMPEGNO_SCARTO
            where ente_proprietario_id=p_ente_proprietario_id;
            DELETE FROM MIGR_ACCERTAMENTO_SCARTO
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
            migrazione_impegno(p_ente_proprietario_id, p_anno_esercizio,TIPO_CAP_USCITA, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;

        if v_codRes = 0 then
            -- 1) SubImpegni
            v_msgRes:='Migrazione subimpegni.';
            migrazione_subimpegno(p_ente_proprietario_id, p_anno_esercizio,TIPO_CAP_USCITA, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;
        if v_codRes = 0 then
            -- 1) Accertamenti
--            migrazione_accertamento(p_ente_proprietario_id, p_anno_esercizio, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes:='Migrazione accertamenti.';
            migrazione_impegno(p_ente_proprietario_id, p_anno_esercizio,TIPO_CAP_ENTRATA, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;
        if v_codRes = 0 then
            -- 1) SubAccertamenti
            --migrazione_subaccertamento(p_ente_proprietario_id, p_anno_esercizio, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes:='Migrazione subaccertamenti.';
            migrazione_subimpegno(p_ente_proprietario_id, p_anno_esercizio,TIPO_CAP_ENTRATA, v_codRes, v_imp_inseriti, v_imp_scartati,p_msgRes);
            v_msgRes := v_msgRes || p_msgRes ;
        end if;

        -- 31.01.2017 Sofia update su migr per gestione pluriennali        
        if v_codRes=0 then
          v_msgRes:='Update anno_esercizio su migr_impegno.';
          update migr_impegno migr
          set    anno_esercizio=anno_impegno
          where  migr.ente_proprietario_id=p_ente_proprietario_id
          and    migr.anno_esercizio=p_anno_esercizio
          and    migr.anno_impegno>p_anno_esercizio;
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
          and    migr.anno_accertamento>p_anno_esercizio;
          v_msgRes:='Update anno_esercizio su migr_accertamento_scarto.';
          update migr_accertamento_scarto migr
          set    anno_esercizio=anno_accertamento
          where  migr.ente_proprietario_id=p_ente_proprietario_id
          and    migr.anno_esercizio=p_anno_esercizio
          and    migr.anno_accertamento>p_anno_esercizio;
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
        h_sogg_migrato number := 0;
        h_codice_soggetto number:=null;
        h_sede_id number:=null;
        h_stato_provvedimento   varchar2(5) := null;
        h_tipo_provvedimento    varchar2(20) := null;
        h_direzione_provvedimento varchar2(20):=null;

        v_count number :=0;

      begin
        -- controllo sulla presenza dei parametri in input
        if (pEnte is null or pAnnoEsercizio is null) then
            pCodRes := -1;
            pMsgRes := 'proc migrazione_liquidazione.Uno o più parametri in input non sono stati valorizzati correttamente. Ente: '||pEnte||', annoEsercizio: '||pAnnoEsercizio;
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
                select -- liquidazioni legate ad impegni
                liq.nro_movimento numero_liquidazione, 
                --asm.anno_peg anno_esercizio,
                pAnnoEsercizio anno_esercizio, -- 30.01.2017 Sofia
                liq.nro_movimento numero_liquidazione_orig, liq.anno_esercizio anno_liquidazione_orig
                ,liq.ogg1||liq.ogg2||liq.ogg3||liq.ogg4||liq.ogg5 descrizione
                ,to_char (nvl(liq.data_inserimento, liq.data_ins_mov),'dd/mm/yyyy') data_emissione
                ,nvl(liq.importo,0) importo
                ,nvl(liq.cod_fornitore,0) codice_soggetto
                ,decode (liq.stato, 'P', 'P', 'D', 'P', ' ', 'V', NULL) stato_operativo
                ,liq.anno_delibera as anno_provvedimento
                ,liq.nro_delibera as numero_provvedimento
                , a.tipo_doc as tipo_provvedimento
                , a.cod_uffprop as direzione_provvedimento
                , replace(a.ogg1||a.ogg2||a.ogg3||a.ogg4||a.ogg5,'''','''''') as oggetto_provvedimento
                , replace(a.note,'''','''''') as note_provvedimento
                ,imp.anno_intervento anno_impegno
                ,imp.nro_movimento as numero_impegno
                , 0 as numero_subimpegno
                , migrM.Pdc_Finanziario -- ereditato da impegno associato
                , migrM.Cofog -- ereditato da movimento associato
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
                , liq.codice_gest as siope_spesa
  -- DAVIDE - 16.12.015 - Fine
                from movimento_contab liq
                , movimento_contab imp
                , as_movimenti_mandati asm
                , atto a
                , migr_impegno migrM
                where liq.tipo_mov=3 -- Liquidazione
                and liq.tipo_cap='U' -- discrimina la liquidazione sull'impegno/subimpegno
                and liq.importo>0
                and imp.nro_movimento = liq.nro_mov_riferim
                and imp.tipo_mov = 1 -- liq legata ad impegno
                and liq.tipo_mov=asm.tipo_mov
                and liq.tipo_cap=asm.tipo_eu
                and liq.nro_movimento = asm.nro_movimento
--                and asm.anno_peg=pAnnoEsercizio -- parametro input
                and asm.anno_peg=pAnnoEsercizio-1 -- parametro input 30.01.2017 Sofia                
                and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
                and a.anno_prot=liq.anno_delibera
                and a.nro_prot=liq.nro_delibera
                and migrM.anno_impegno = imp.anno_intervento
                and migrM.numero_impegno = imp.nro_movimento
                and migrM.numero_subimpegno = 0
                and migrM.stato_operativo = STATO_IMPEGNO_D -- esecutivi
                and migrM.ente_proprietario_id = pEnte
                union
                select -- liquidazioni legate a subimpegni
                liq.nro_movimento numero_liquidazione, 
--                asm.anno_peg anno_esercizio,
                pAnnoEsercizio anno_esercizio,
                liq.nro_movimento numero_liquidazione_orig, liq.anno_esercizio anno_liquidazione_orig
                ,liq.ogg1||liq.ogg2||liq.ogg3||liq.ogg4||liq.ogg5 descrizione
                ,to_char (nvl(liq.data_inserimento, liq.data_ins_mov),'dd/mm/yyyy') data_emissione
                ,nvl(liq.importo,0) importo
                ,nvl(liq.cod_fornitore,0) codice_soggetto
                ,decode (liq.stato, 'P', 'P', 'D', 'P', ' ', 'V', NULL) stato_operativo
                ,liq.anno_delibera as anno_provvedimento
                ,liq.nro_delibera as numero_provvedimento
                , a.tipo_doc as tipo_provvedimento
                , a.cod_uffprop as direzione_provvedimento
                , replace(a.ogg1||a.ogg2||a.ogg3||a.ogg4||a.ogg5,'''','''''') as oggetto_provvedimento
                , replace(a.note,'''','''''') as note_provvedimento
                ,sub.anno_intervento anno_impegno
                ,sub.nro_mov_riferim as numero_impegno
                ,sub.nro_movimento as numero_subimpegno
                , migrM.Pdc_Finanziario -- ereditato da impegno associato
                , migrM.Cofog -- ereditato da movimento associato
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
                , liq.codice_gest as siope_spesa
  -- DAVIDE - 16.12.015 - Fine
                from movimento_contab liq
                , movimento_contab sub
                , as_movimenti_mandati asm
                , atto a
                , migr_impegno migrM
                where liq.tipo_mov=3 -- liquidazione
                and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
                and liq.importo>0
                and sub.nro_movimento = liq.nro_mov_riferim
                and sub.tipo_mov = 2
                and liq.tipo_cap=asm.tipo_eu
                and liq.nro_movimento = asm.nro_movimento
--                and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
                and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione 30.01.2017
                and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
                and a.anno_prot=liq.anno_delibera
                and a.nro_prot=liq.nro_delibera
                and migrM.anno_impegno = sub.anno_intervento
                and migrM.numero_impegno = sub.nro_mov_riferim
                and migrM.numero_subimpegno = sub.nro_movimento
                and migrM.stato_operativo = STATO_IMPEGNO_D -- esecutivi
                and migrM.Ente_Proprietario_Id=pEnte
                union
                select -- liquidazioni legate a movimenti di budget legati a loro volta ad impegni
                liq.nro_movimento numero_liquidazione, 
--                asm.anno_peg anno_esercizio,
                pAnnoEsercizio anno_esercizio, -- 30.01.2017
                liq.nro_movimento numero_liquidazione_orig, liq.anno_esercizio anno_liquidazione_orig
                ,liq.ogg1||liq.ogg2||liq.ogg3||liq.ogg4||liq.ogg5 descrizione
                ,to_char (nvl(liq.data_inserimento, liq.data_ins_mov),'dd/mm/yyyy') data_emissione
                ,nvl(liq.importo,0) importo
                ,nvl(liq.cod_fornitore,0) codice_soggetto
                ,decode (liq.stato, 'P', 'P', 'D', 'P', ' ', 'V', NULL) stato_operativo
                ,liq.anno_delibera as anno_provvedimento
                ,liq.nro_delibera as numero_provvedimento
                , a.tipo_doc as tipo_provvedimento
                , a.cod_uffprop as direzione_provvedimento
                , replace(a.ogg1||a.ogg2||a.ogg3||a.ogg4||a.ogg5,'''','''''') as oggetto_provvedimento
                , replace(a.note,'''','''''') as note_provvedimento
                ,imp.anno_intervento anno_impegno
                ,imp.nro_movimento numero_impegno
                ,0 as numero_subimpegno
                , migrM.Pdc_Finanziario -- ereditato da impegno associato
                , migrM.Cofog -- ereditato da movimento associato
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
                , liq.codice_gest as siope_spesa
  -- DAVIDE - 16.12.015 - Fine
                from movimento_contab liq
                , movimento_contab movBudg
                , movimento_contab imp
                , as_movimenti_mandati asm
                , atto a
                , migr_impegno migrM
                where liq.tipo_mov=3-- liquidazione
                and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
                and liq.importo>0
                and movBudg.nro_movimento = liq.nro_mov_riferim
                and movBudg.tipo_mov = 6
                and imp.Nro_Movimento=movBudg.nro_mov_riferim
                and imp.tipo_mov=1
                and liq.tipo_cap=asm.tipo_eu
                and liq.nro_movimento = asm.nro_movimento
--                and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
                and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione  30.01.2017              
                and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
                and a.anno_prot=liq.anno_delibera
                and a.nro_prot=liq.nro_delibera
                and migrM.anno_impegno = imp.anno_intervento
                and migrM.numero_impegno = imp.nro_mov_riferim
                and migrM.numero_subimpegno = 0
                and migrM.stato_operativo = STATO_IMPEGNO_D -- esecutivi
                and migrM.Ente_Proprietario_Id=pEnte
                union
                select -- liquidazioni legate a movimenti di budget legati a loro volta a subimpegni
                liq.nro_movimento numero_liquidazione, 
--                asm.anno_peg anno_esercizio,
                pAnnoEsercizio anno_esercizio, -- 30.01.2017
                liq.nro_movimento numero_liquidazione_orig, liq.anno_esercizio anno_liquidazione_orig
                ,liq.ogg1||liq.ogg2||liq.ogg3||liq.ogg4||liq.ogg5 descrizione
                ,to_char (nvl(liq.data_inserimento, liq.data_ins_mov),'dd/mm/yyyy') data_emissione
                ,nvl(liq.importo,0) importo
                ,nvl(liq.cod_fornitore,0) codice_soggetto
                ,decode (liq.stato, 'P', 'P', 'D', 'P', ' ', 'V', NULL) stato_operativo
                ,liq.anno_delibera as anno_provvedimento
                ,liq.nro_delibera as numero_provvedimento
                , a.tipo_doc as tipo_provvedimento
                , a.cod_uffprop as direzione_provvedimento
                , replace(a.ogg1||a.ogg2||a.ogg3||a.ogg4||a.ogg5,'''','''''') as oggetto_provvedimento
                , replace(a.note,'''','''''') as note_provvedimento
                ,sub.anno_intervento anno_impegno, sub.nro_mov_riferim numero_impegno, sub.nro_movimento as numero_subimpegno
                , migrM.Pdc_Finanziario -- ereditato da movimento associato
                , migrM.Cofog -- ereditato da movimento associato
    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
                , liq.codice_gest as siope_spesa
  -- DAVIDE - 16.12.015 - Fine
                from movimento_contab liq
                , movimento_contab movBudg
                , movimento_contab sub
                , as_movimenti_mandati asm
                , atto a
                , migr_impegno migrM
                where liq.tipo_mov=3
                and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
                and liq.importo>0
                and movBudg.nro_movimento = liq.nro_mov_riferim
                and movBudg.tipo_mov = 6
                and sub.Nro_Movimento=movBudg.nro_mov_riferim
                and sub.tipo_mov=2
                and liq.tipo_cap=asm.tipo_eu
                and liq.nro_movimento = asm.nro_movimento
--                and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
                and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione      30.01.2017 Sofia           
                and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
                and a.anno_prot=liq.anno_delibera
                and a.nro_prot=liq.nro_delibera
                and migrM.anno_impegno = sub.anno_intervento
                and migrM.numero_impegno = sub.nro_mov_riferim
                and migrM.numero_subimpegno = sub.nro_movimento
                and migrM.stato_operativo = STATO_IMPEGNO_D -- esecutivi
                and migrM.Ente_Proprietario_Id=pEnte)
              loop
                          -- inizializza variabili
                          codRes := 0;
                          msgMotivoScarto  := null;
                          msgRes := null;
                          h_sogg_migrato := 0;
                          h_codice_soggetto :=null;
                          h_sede_id :=null;
                          h_stato_provvedimento     := null;
                          h_tipo_provvedimento      := null;
                          h_direzione_provvedimento := null;
                          v_count := 0;

                          h_rec := 'Liquidazione ' || migrCursor.numero_liquidazione || '/'||migrCursor.anno_esercizio||'.';


                          -- verifica soggetto liquidazione igrato
                          if migrCursor.codice_soggetto is not null and migrCursor.codice_soggetto <> 0 then
                              msgRes := 'Verifica soggetto migrato.';
                              begin
                                select ms.codice_soggetto, nvl(count(*), 0), nvl(mss.sede_id,0)
                                into h_codice_soggetto, h_sogg_migrato, h_sede_id
                                from fornitore f ,migr_soggetto ms, migr_sede_secondaria mss
                                where f.codice = migrCursor.codice_soggetto
                                and
                                (--(f.nat_giuridica in (0,1,2,3) and ms.codice_soggetto=f.codice)
                                 (f.nat_giuridica in (0,1,2,3,5) and ms.codice_soggetto=f.codice) -- 19.12.2016 Sofia ATI come soggetto normale
                                 or
                                 (f.nat_giuridica = 4 and ms.codice_soggetto=f.codice_rif)
                               --   19.12.2016 Sofia le ATI , 5 vanno trattate come soggetto normal , solo le 4 come sedi 
                               --  (f.nat_giuridica in (4,5) and ms.codice_soggetto=f.codice_rif)  -- DAVIDE - 02.12.2016 - soggetti con nat_giuridica=5 sono migrati
                                )
                                and ms.ente_proprietario_id = pEnte
                                and mss.codice_sede (+) = f.codice
                                and mss.ente_proprietario_id(+) = pEnte
                                group by ms.codice_soggetto, mss.sede_id;

                              exception
                                when no_data_found then
                                     codRes := -1;
--                                     msgRes := 'Soggetto determinato non migrato.';
                                     msgMotivoScarto := 'Soggetto determinato non migrato.';
                                     select count(*) into v_count from fornitore where codice = migrCursor.codice_soggetto and nat_giuridica = 5 ;
                                     if v_count > 0 then msgMotivoScarto := msgMotivoScarto||'Soggetto ATI.';end if;
                                when others then
                                  dbms_output.put_line(h_rec || ' msgRes ' ||
                                                       msgRes || ' Errore ' || SQLCODE || '-' ||
                                                       SUBSTR(SQLERRM, 1, 100));
                                  pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                                                    SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                                  pLiqScartati := cLiqScartati;
                                  pLiqInseriti := cLiqseriti;
                                  pCodRes      := -1;
                                  return;
                              end;
                          else
                             codRes := -1;
                             msgMotivoScarto := 'Soggetto non determinato.';
                          end if;
                          /*
                          if codRes = 0 and h_sogg_migrato = 0 then
                             codRes := -1;
                             msgMotivoScarto := 'Soggetto determinato non migrato.';
                          end if;*/

                          -- provvedimento
                          if codRes = 0 then
                            msgRes := 'Dati Provvedimento.';

                            h_stato_provvedimento:=migrCursor.stato_operativo;
                            if migrCursor.tipo_provvedimento is not null then
                               h_tipo_provvedimento   :=migrCursor.tipo_provvedimento||'||';
                            end if;
                            if migrCursor.direzione_provvedimento is not null then
                               h_direzione_provvedimento :=migrCursor.direzione_provvedimento||'||';
                            end if;
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
                              ,sede_id
                              ,codice_progben -- non definito a livello di liquidazione
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
                    -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
                              , siope_spesa
                  -- DAVIDE - 16.12.015 - Fine
                )
                              values
                                (migr_liquidazione_id_seq.nextval,
                                 migrCursor.numero_liquidazione,
                                 migrCursor.anno_esercizio,
                                 migrCursor.descrizione,
                                 migrCursor.data_emissione,
                                 migrCursor.importo,
                                 h_codice_soggetto, -- codice soggetto di riferimento
                                 h_sede_id, -- sedi id migr se soggetto sede secondaria
                                 NULL, --codice progben non presente a questo livello
                                 migrCursor.stato_operativo,
                                 migrCursor.anno_provvedimento,
                                 migrCursor.numero_provvedimento,
                                 migrCursor.numero_provvedimento,
                                 h_tipo_provvedimento,
                                 h_direzione_provvedimento,
                                 migrCursor.oggetto_provvedimento,
                                 migrCursor.note_provvedimento,
                                 h_stato_provvedimento,
                                 migrCursor.numero_impegno,
                                 migrCursor.numero_subimpegno,
                                 migrCursor.anno_impegno,
                                 NULL, -- nro mutuo non valorizzato per provincia
                                 migrCursor.pdc_finanziario,
                                 migrCursor.cofog,
                                 pEnte,
                                 migrCursor.numero_liquidazione_orig,
                                 migrCursor.anno_liquidazione_orig,
                                 migrCursor.data_emissione
                        -- DAVIDE - 16.12.015 - Popolamento campo siope_spesa
                                 , migrCursor.siope_spesa
                      -- DAVIDE - 16.12.015 - Fine
                 );
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
                                 migrCursor.numero_liquidazione,
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

    -- gestione degli scarti
    -- 1) scarti per soggetto non migrato.
    /* la verifica del soggetto migrato è fatto nel loop
    msgRes := 'Inserimento scarti per soggetto non migrato.';
     insert into migr_liquidazione_scarto
                                (liquidazione_scarto_id,
                                 numero_liquidazione,
                                 anno_esercizio,
                                 motivo_scarto,
                                 ente_proprietario_id)
      select migr_liquid_scarto_id_seq.nextval, liq.nro_movimento,asm.anno_peg, 'Soggetto non migrato',pEnte
      from movimento_contab liq
      , as_movimenti_mandati asm
      where liq.tipo_mov=3 -- liquidazione
      and liq.tipo_cap='U' -- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and liq.tipo_mov=asm.tipo_mov
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
      and asm.anno_peg=pAnnoEsercizio
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      and not exists (select 1 from migr_soggetto migrS
            where migrS.Codice_Soggetto=liq.cod_fornitore
            and migrS.Ente_Proprietario_Id = pEnte);*/


    -- 2) Liquidazioni scarti per movimento non stato D
    -- 05.10.2016 Sofia - gestione scarti per liquidazioni legate a impegni/sub migrati  ma non in stato D ( esecutivi )
    msgRes := 'Inserimento scarti per movimento non stato D.';
    insert into migr_liquidazione_scarto
    (liquidazione_scarto_id,
     numero_liquidazione,
     anno_esercizio,
     motivo_scarto,
     ente_proprietario_id)
    -- liquidazioni legate ad impegni
    select migr_liquid_scarto_id_seq.nextval, sc.nro_movimento,  
--           sc.anno_peg,
           pAnnoEsercizio, -- 30.01.2017
           'Movimento migrato in stato non DEFINITIVO ( esecutivo )',pEnte
    from
    (
      select  liq.nro_movimento, asm.anno_peg
      from movimento_contab liq
      , movimento_contab imp
      , as_movimenti_mandati asm
      where liq.tipo_mov=3
      and liq.tipo_cap='U' -- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and imp.nro_movimento = liq.nro_mov_riferim
      and imp.tipo_mov = 1 -- liq legata ad impegno
      and liq.tipo_mov=asm.tipo_mov
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
--      and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
      and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione       30.01.2017
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      --and liq.nro_movimento = 1453106
      and     exists ( select 1
                       from migr_impegno migrM
                       where migrM.anno_impegno      = imp.anno_intervento
                         and migrM.numero_impegno    = imp.nro_movimento
                         and migrM.numero_subimpegno = 0
                         and migrM.stato_operativo   != STATO_IMPEGNO_D -- esecutivi
                         and migrM.ente_proprietario_id = pEnte )
      and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte)
      union
      -- liquidazioni legate a subimpegni
      select  liq.nro_movimento, asm.anno_peg
      from movimento_contab liq
      , movimento_contab sub
      , as_movimenti_mandati asm
      where liq.tipo_mov=3
      and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and sub.nro_movimento = liq.nro_mov_riferim
      and sub.tipo_mov = 2
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
--      and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
      and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione      30.01.2017 Sofia
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      and     exists ( select 1
                       from migr_impegno migrM
                       where migrM.anno_impegno      = sub.anno_intervento
                         and migrM.numero_impegno    = sub.nro_mov_riferim
                         and migrM.numero_subimpegno = sub.nro_movimento
                         and migrM.stato_operativo   != STATO_IMPEGNO_D -- esecutivi
                         and migrM.ente_proprietario_id = pEnte )
      and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte)
      union
      --liquidazioni legate a movimenti di budget legati a loro volta ad impegni
      select liq.nro_movimento, asm.anno_peg
      from movimento_contab liq
      , movimento_contab movBudg
      , movimento_contab imp
      , as_movimenti_mandati asm
      , migr_impegno migrM
      where liq.tipo_mov=3
      and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and movBudg.nro_movimento = liq.nro_mov_riferim
      and movBudg.tipo_mov = 6
      and imp.Nro_Movimento=movBudg.nro_mov_riferim
      and imp.tipo_mov=1
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
--      and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
      and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione -- 30.01.2017      
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      and     exists ( select 1
                       from migr_impegno migrM
                       where migrM.anno_impegno      = imp.anno_intervento
                         and migrM.numero_impegno    = imp.nro_movimento
                         and migrM.numero_subimpegno = 0
                         and migrM.stato_operativo   != STATO_IMPEGNO_D -- esecutivi
                         and migrM.ente_proprietario_id = pEnte )
      and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte)
      union
      --liquidazioni legate a movimenti di budget legati a loro volta a subimpegni
      select  liq.nro_movimento, asm.anno_peg
      from movimento_contab liq
      , movimento_contab movBudg
      , movimento_contab sub
      , as_movimenti_mandati asm
      , migr_impegno migrM
      , migr_soggetto migrS
      where liq.tipo_mov=3
      and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and movBudg.nro_movimento = liq.nro_mov_riferim
      and movBudg.tipo_mov = 6
      and sub.Nro_Movimento=movBudg.nro_mov_riferim
      and sub.tipo_mov=2
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
--      and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
      and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione       30.01.2017
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      and     exists ( select 1
                       from migr_impegno migrM
                       where migrM.anno_impegno      = sub.anno_intervento
                         and migrM.numero_impegno    = sub.nro_mov_riferim
                         and migrM.numero_subimpegno = sub.nro_movimento
                         and migrM.stato_operativo   != STATO_IMPEGNO_D -- esecutivi
                         and migrM.ente_proprietario_id = pEnte )
      and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte))sc;


    -- 3) scarti per movimento non migrato.
    msgRes := 'Inserimento scarti per movimento non migrato.';
    insert into migr_liquidazione_scarto
    (liquidazione_scarto_id,
     numero_liquidazione,
     anno_esercizio,
     motivo_scarto,
     ente_proprietario_id)
    -- liquidazioni legate ad impegni
    select migr_liquid_scarto_id_seq.nextval, sc.nro_movimento, 
           --sc.anno_peg,
           pAnnoEsercizio,-- 30.01.2017 Sofia
           'Movimento non migrato',pEnte
    from (
      select  liq.nro_movimento, asm.anno_peg
      from movimento_contab liq
      , movimento_contab imp
      , as_movimenti_mandati asm
      , migr_impegno migrM
      where liq.tipo_mov=3
      and liq.tipo_cap='U' -- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and imp.nro_movimento = liq.nro_mov_riferim
      and imp.tipo_mov = 1 -- liq legata ad impegno
      and liq.tipo_mov=asm.tipo_mov
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
--      and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
      and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione      30.01.2017 Sofia
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      --and liq.nro_movimento = 1453106
      and migrM.anno_impegno(+) = imp.anno_intervento
      and migrM.numero_impegno(+) = imp.nro_movimento
      and migrM.numero_subimpegno(+) = 0
      and migrM.stato_operativo(+) = STATO_IMPEGNO_D -- esecutivi
      and migrM.ente_proprietario_id(+) = pEnte
      and migrM.Impegno_Id is null
      and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte)
      union
      -- liquidazioni legate a subimpegni
      select  liq.nro_movimento, asm.anno_peg
      from movimento_contab liq
      , movimento_contab sub
      , as_movimenti_mandati asm
      , migr_impegno migrM
      where liq.tipo_mov=3
      and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and sub.nro_movimento = liq.nro_mov_riferim
      and sub.tipo_mov = 2
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
--      and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
      and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione      30.01.2017 Sofia
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      and migrM.anno_impegno(+) = sub.anno_intervento
      and migrM.numero_impegno(+) = sub.nro_mov_riferim
      and migrM.numero_subimpegno(+) = sub.nro_movimento
      and migrM.stato_operativo(+) = STATO_IMPEGNO_D -- esecutivi
      and migrM.Ente_Proprietario_Id(+)=pEnte
      and migrM.Impegno_Id is null
      and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte)
      union
      --liquidazioni legate a movimenti di budget legati a loro volta ad impegni
      select liq.nro_movimento, asm.anno_peg
      from movimento_contab liq
      , movimento_contab movBudg
      , movimento_contab imp
      , as_movimenti_mandati asm
      , migr_impegno migrM
      where liq.tipo_mov=3
      and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and movBudg.nro_movimento = liq.nro_mov_riferim
      and movBudg.tipo_mov = 6
      and imp.Nro_Movimento=movBudg.nro_mov_riferim
      and imp.tipo_mov=1
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
--      and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
      and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione      30.01.2017 Sofia
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      and migrM.anno_impegno(+) = imp.anno_intervento
      and migrM.numero_impegno(+) = imp.nro_mov_riferim
      and migrM.numero_subimpegno(+) = 0
      and migrM.stato_operativo(+) = STATO_IMPEGNO_D -- esecutivi
      and migrM.Ente_Proprietario_Id(+)=pEnte
      and migrM.Impegno_Id is null
      and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte)
      union
      --liquidazioni legate a movimenti di budget legati a loro volta a subimpegni
      select  liq.nro_movimento, asm.anno_peg
      from movimento_contab liq
      , movimento_contab movBudg
      , movimento_contab sub
      , as_movimenti_mandati asm
      , migr_impegno migrM
      , migr_soggetto migrS
      where liq.tipo_mov=3
      and liq.tipo_cap='U'-- discrimina la liquidazione sull'impegno/subimpegno
      and liq.importo>0
      and movBudg.nro_movimento = liq.nro_mov_riferim
      and movBudg.tipo_mov = 6
      and sub.Nro_Movimento=movBudg.nro_mov_riferim
      and sub.tipo_mov=2
      and liq.tipo_cap=asm.tipo_eu
      and liq.nro_movimento = asm.nro_movimento
--      and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
      and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione       30.01.2017 Sofia
      and nvl(asm.residuo_da_riportare,0)>0 -- disponibilità della liquidazione
      and migrM.anno_impegno(+) = sub.anno_intervento
      and migrM.numero_impegno(+) = sub.nro_mov_riferim
      and migrM.numero_subimpegno(+) = sub.nro_movimento
      and migrM.stato_operativo(+) = STATO_IMPEGNO_D -- esecutivi
      and migrM.Ente_Proprietario_Id(+)=pEnte
      and migrM.Impegno_Id is null
      and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte))sc;

    -- 05.10.2016 Sofia
    -- 4) liquidazione legata a diverse quote documento.
    msgRes := 'Inserimento segnalazioni per liquidazione legata a diverse quote documento.';
    insert into migr_liquidazione_scarto
    (liquidazione_scarto_id,
     numero_liquidazione,
     anno_esercizio,
     motivo_scarto,
     ente_proprietario_id)
    select migr_liquid_scarto_id_seq.nextval, sc.nro_movimento, 
           --sc.anno_peg,
           pAnnoEsercizio, -- 30.01.2017 Sofia
           'Movimento segnalato per legame a diverse quote documento',pEnte
    from ( select liq.nro_movimento, asm.anno_peg
           from movimento_contab liq,
                movimento_contab imp,
                as_movimenti_mandati asm
           where liq.tipo_mov=3
             and liq.tipo_cap='U' -- discrimina la liquidazione sull'impegno/subimpegno
             and liq.importo>0
             and imp.nro_movimento = liq.nro_mov_riferim
             and imp.tipo_mov = 1 -- liq legata ad impegno
             and liq.tipo_mov=asm.tipo_mov
             and liq.tipo_cap=asm.tipo_eu
             and liq.nro_movimento = asm.nro_movimento
--             and asm.anno_peg=pAnnoEsercizio -- parametro input funzione
             and asm.anno_peg=pAnnoEsercizio-1 -- parametro input funzione 30.01.2017 Sofia
             and nvl(asm.residuo_da_riportare,0)>0 --- disponibilità della liquidazione
             and liq.nro_movimento not in (select s.numero_liquidazione from migr_liquidazione_scarto s where s.ente_proprietario_id=pEnte)
             and 1 < (select count(*) from dwh.fattura_migrazione_quota q where q.nro_liquidazione=liq.nro_movimento ))sc;

    -- DAVIDE - 15.12.2016 - update valenzano su MDP
	/*update migr_liquidazione j 
	   set j.codice_progben=(select min(k.progr_benefic)  
                               from mand_revers k 
	                          where j.numero_liquidazione=k.num_liquidaz 
	                            and k.stato=77 
	                            and k.anno_esercizio=pAnnoEsercizio 
                                and j.codice_soggetto=k.codice_benefic
                              group by k.num_liquidaz)
     where j.codice_soggetto!='999'
       and j.anno_esercizio=pAnnoEsercizio and j.ente_proprietario_id=pEnte
       and exists (select 1  
                     from mand_revers k 
					where j.numero_liquidazione=k.num_liquidaz 
					  and k.stato=77 
					  and k.anno_esercizio=pAnnoEsercizio 
                      and j.codice_soggetto=k.codice_benefic);*/
					  
	-- DAVIDE - 16.15.2016 - update nuovo di Valenzano
    /*update migr_liquidazione j 
	   set j.codice_progben=(select min(k.progr_benefic)  
                               from mand_revers k 
							  where j.numero_liquidazione=k.num_liquidaz 
							    and k.stato=77 
								and k.anno_esercizio=pAnnoEsercizio 
                                and j.codice_soggetto=k.codice_benefic
                              group by k.num_liquidaz)
     where j.codice_soggetto!='999'
       and j.anno_esercizio=pAnnoEsercizio and j.ente_proprietario_id=pEnte
       and exists (select 1  
                     from mand_revers k 
					where j.numero_liquidazione=k.num_liquidaz 
					  and k.stato=77 
					  and k.anno_esercizio=pAnnoEsercizio 
                      and j.codice_soggetto=k.codice_benefic)
       and not exists (select 1 
	                     from modalita_pagamento w 
						where j.numero_liquidazione=w.nro_liquidazione);  	*/
					  
	-- DAVIDE - 13.01.2017 - update nuovo di Valenzano - ULTIMA VERSIONE - mail del 12.01.2017
    update migr_liquidazione j 
	   set j.codice_progben=(select min(k.progr_benefic)  
                               from cc_mand_revers k 
							  where j.numero_liquidazione=k.num_liquidaz 
--							    and k.anno_esercizio=pAnnoEsercizio 
							    and k.anno_esercizio=pAnnoEsercizio-1 -- 30.01.2017                 
                                and j.codice_soggetto=k.codice_benefic
                              group by k.num_liquidaz)
     where j.codice_soggetto!='999'
       and j.anno_esercizio=pAnnoEsercizio 
       and j.ente_proprietario_id=pEnte
       and exists (select 1  
                     from cc_mand_revers k 
					where j.numero_liquidazione=k.num_liquidaz 
-- 				    and k.anno_esercizio=pAnnoEsercizio 
					  and k.anno_esercizio=pAnnoEsercizio-1 -- 30.01.2017            
                      and j.codice_soggetto=k.codice_benefic)
       and not exists (select 1 
	                     from modalita_pagamento w 
						where j.numero_liquidazione=w.nro_liquidazione);  						
					  
	-- DAVIDE - 13.01.2017 - Fine
					  
    -- update nostro su MDP
	update migr_liquidazione j 
	   set j.codice_progben=(select min(k.beneficiario_pag)  
                               from dwh.fattura_migrazione_quota k 
	                          where j.numero_liquidazione=k.nro_liquidazione 
--	                            and k.anno_mandato=pAnnoEsercizio 
	                            and k.anno_mandato=pAnnoEsercizio-1 -- 30.01.2017 Sofia                              
                              and j.codice_soggetto=k.fornitore_fat
                              group by k.nro_liquidazione)
     where j.anno_esercizio=pAnnoEsercizio 
	   and j.ente_proprietario_id=pEnte
       and exists (select 1  
                     from dwh.fattura_migrazione_quota k 
	                where j.numero_liquidazione=k.nro_liquidazione 
--	                  and k.anno_mandato=pAnnoEsercizio 
	                  and k.anno_mandato=pAnnoEsercizio-1 -- 30.01.2017 Sofia                    
                    and j.codice_soggetto=k.fornitore_fat);	   
	-- DAVIDE - 15.12.2016 - Fine

    -- 01.02.2017 Sofia aggiornamenti puntuali di MDP su liquidazioni passate da Valenzano - INIZIO 
    update migr_liquidazione set codice_progben=2 where numero_liquidazione=1555781 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=1 where numero_liquidazione=1224759 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=7 where numero_liquidazione=1134472 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=2 where numero_liquidazione=1223749 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=2 where numero_liquidazione=1197739 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=2 where numero_liquidazione=1186681 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=4 where numero_liquidazione=1158788 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=7 where numero_liquidazione=1158887 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=1 where numero_liquidazione=1115784 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=4 where numero_liquidazione=1350730 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=5 where numero_liquidazione=1310244 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=3 where numero_liquidazione=1288823 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=6 where numero_liquidazione=1302000 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione set codice_progben=1 where numero_liquidazione=1378707 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    
/*    update migr_liquidazione j  set j.codice_soggetto=9,      j.codice_progben=2 where j.numero_liquidazione=1543940 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione j  set j.codice_soggetto=11,     j.codice_progben=5 where j.numero_liquidazione=1560447 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione j  set j.codice_soggetto=131420, j.codice_progben=1 where j.numero_liquidazione=1560556 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte; */
/*update migr_liquidazione j  set j.codice_soggetto=5368,   j.codice_progben=1 where j.numero_liquidazione=1543940 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte; 
Anna Valenzano modificato dopo la prova in collaudo*/
    update migr_liquidazione j  set j.codice_soggetto=5368,   j.codice_progben=2 where j.numero_liquidazione=1543940 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione j  set j.codice_soggetto=16,     j.codice_progben=1 where j.numero_liquidazione=1560447 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;

    update migr_liquidazione j  set j.codice_soggetto=130526, j.codice_progben=1 where j.numero_liquidazione=1560556 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione j  set j.codice_soggetto=97095,  j.codice_progben=1 where j.numero_liquidazione=1317517 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;
    update migr_liquidazione j  set j.codice_soggetto=121534, j.codice_progben=1 where j.numero_liquidazione=1552141 and anno_esercizio=pAnnoEsercizio and ente_proprietario_id=pEnte;

    -- 01.02.2017 Sofia aggiornamenti puntuali di MDP su liquidazioni passate da Valenzano - FINE

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

  procedure migrazione_doc_spesa (pEnte number,pLoginOperazione varchar2,pAnnoEsercizio varchar2,pCodRes out number,pRecInseriti out number,pRecScartati out number,pMsgRes out varchar2)
   is
        codRes number := 0;
        msgMotivoScarto varchar2(1500) := null;
        msgRes  varchar2(1500) := null;
        cDocInseriti number := 0;
        cDocScartati number := 0;
        numInsert number := 0;

        h_sogg_migrato number := 0;
        h_sogg_valido number := 0;
        h_codice_soggetto number:=null; -- coincide con il codice soggetto del doc se questo non è una sede secondaria, altrimenti è il codice soggetto di riferimento della sede secondaria

        h_sede_id number:=null; --Valorizzata con il campo migr_sede_secodiaria.sede_id se il soggetto legato al doc è una sede secondaria

        h_num number := 0;
        h_stato varchar2(3):=null;
        h_rec varchar2(750) := null;
        tipoScarto varchar2(3):=null;

        v_count number :=0;

        ERROR_DOCUMENTO EXCEPTION;
   begin
        msgRes := 'Pulizia tabelle di migrazione.';

        --insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
        --values (migr_migr_elab_id_seq.nextval,'migrazione_doc_spesa',msgRes||'begin.',pEnte);
        --commit;

        DELETE FROM MIGR_DOC_SPESA WHERE ENTE_PROPRIETARIO_ID = pEnte and FL_MIGRATO = 'N';
        DELETE FROM MIGR_DOC_SPESA_SCARTO WHERE ENTE_PROPRIETARIO_ID = pEnte;

        --insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
        --values (migr_migr_elab_id_seq.nextval,'migrazione_doc_spesa',msgRes||'end.',pEnte);
        commit;

        msgRes := 'Inizio migrazione documenti di spesa.';

        --insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
        --values (migr_migr_elab_id_seq.nextval,'migrazione_doc_spesa',msgRes||'begin.',pEnte);
        --commit;
        for migrCursor in
        (select
          decode(fat.tipo_documento,NULL,-1,fat.tipo_documento) tipo_fonte
          , decode(fat.tipo_documento, 1,'FAT',4,'NCD',5,'NTE',6,'FPR',7,'FAT',8,'NCD',NULL) tipo
          , fat.anno_fattura anno
          , fat.nro_fattura numero
          , fat.cod_fornitore codice_soggetto
          , fat.stato
          , replace(fat.oggetto,'''','''''') descrizione
          , to_char(fat.data_fattura,'yyyy-mm-dd') data_emissione
          , to_char(fat.data_scadenza,'yyyy-mm-dd')data_scadenza
      --, data_scadenza_new,  -- per il momento non valorizzata
          , nvl(fat.importo_fattura, 0) as importo
          , nvl(fat.importo_liquidato, 0)as importo_liquidato
          , nvl(fat.importo_dapagare, 0)as importo_dapagare
          , nvl(fat.importo_pagato, 0)as importo_pagato
          , nvl(fat.arrotondamento,0)+nvl(fat.abbuono,0)+nvl(fat.nota_credito,0) as arrotondamento -- DAVIDE - 05.12.2016 - aggiunta nota_credito nel calcolo arrotondamento
  -- DAVIDE - 10.02.016 - Attributi con date : formato da usare dd/mm/yyyy hh:mm:ss
          --, to_char(fat.data_arrivo,'yyyy-mm-dd')data_ricezione
          --, to_char(fat.data_prot,'yyyy-mm-dd')data_repertorio
          , to_char(fat.data_arrivo,'dd/MM/yyyy hh:mm:ss')data_ricezione
          , to_char(fat.data_prot,'dd/MM/yyyy hh:mm:ss')data_repertorio
          , nvl(fat.nro_prot,0) numero_repertorio
  -- DAVIDE - 10.02.016 - Gestire nuovo campo anno_repertorio
          , SUBSTR( to_char(fat.data_prot,'dd/MM/yyyy'), 7 , 4 ) anno_repertorio
      --, data_sospensione,    -- per il momento non valorizzata
          --, data_riattivazione,  -- per il momento non valorizzata
          , fat.note
          , to_char(fat.data_registrazione,'yyyy-mm-dd')data_registro_fatt
          , nvl(fat.nro_registro,0) numero_registro_fatt
          , nvl(fat.utente, pLoginOperazione) as utente_creazione
          , pLoginOperazione as utente_modifica
      , fat.codice_pcc                                              -- DAVIDE - 05.12.2016 - campo aggiunto al doc spesa
          , fat.codice_ufficio                                          -- DAVIDE - 05.12.2016 - campo aggiunto al doc spesa
          from dwh.fattura_migrazione fat
          order by fat.anno_fattura, tipo, fat.cod_fornitore, fat.nro_fattura)

          loop
            -- inizializza variabili
            codRes := 0;
            msgMotivoScarto  := null;
            msgRes := null;
            h_sogg_migrato := 0;
            h_sogg_valido := 0;
            h_codice_soggetto := null; -- verificare se serve
            h_sede_id :=null; -- verificare se serve
            h_num := 0;
            h_stato := null;
            tipoScarto:=null;
            v_count := 0;

            h_rec := 'Documento  '||migrCursor.anno || '/'||migrCursor.numero||' tipo '||migrCursor.tipo||
                     ' Soggetto '||migrCursor.codice_soggetto||'.';

          -- DAVIDE - 10.02.016 - aggiunto scarto per fattura negativa
            -- se importo negativo e tipo = FAT scarto il documento
            msgRes := 'Verifica importo fattura.';
            if migrCursor.tipo='FAT' and migrCursor.importo <0 then
          codRes := -1;
                msgMotivoScarto := 'Importo negativo per tipo fattura.';
                tipoScarto:='FN'; -- fattura negativa
            end if;

            if codRes = 0 then
                -- scartiamo i doc per cui non è stato possibile definirne il tipo, il dato deve essere bonificato.
                if migrCursor.Tipo is null then
                    codRes := -1;
                    msgMotivoScarto := 'Tipo documento non determinato.';
                end if;
            end if;

            if codRes = 0 then
              if migrCursor.codice_soggetto is not null and migrCursor.codice_soggetto <> 0 then
                  msgRes := 'Verifica soggetto migrato.';
                  -- verifico che il soggetto di riferimento sia stato migrato
                  begin
                    select ms.codice_soggetto, nvl(count(*), 0), nvl(mss.sede_id,0)
                    into h_codice_soggetto, h_sogg_migrato, h_sede_id
                    from fornitore f ,migr_soggetto ms, migr_sede_secondaria mss
                    where f.codice = migrCursor.codice_soggetto
                    and
                    (--(f.nat_giuridica in (0,1,2,3) and ms.codice_soggetto=f.codice)
                     (f.nat_giuridica in (0,1,2,3,5) and ms.codice_soggetto=f.codice)  -- 19.12.2016 Sofia le ATI , 5 come soggetti normali
                     or
                     (f.nat_giuridica = 4 and ms.codice_soggetto=f.codice_rif)
                     -- 19.12.2016 Sofia le ATI vanno trattate come soggetto normale, sole le 4 come sedi
                     --(f.nat_giuridica in (4,5) and ms.codice_soggetto=f.codice_rif) -- DAVIDE - 02.12.2016 - soggetti nat_giuridica 5 sono migrati
                    )
                    and ms.ente_proprietario_id = pEnte
                    and mss.codice_sede (+) = f.codice
                    and mss.ente_proprietario_id(+) = pEnte
                    group by ms.codice_soggetto, mss.sede_id;

                  exception
                    when no_data_found then
                         codRes := -1;
                         msgMotivoScarto := 'Soggetto determinato non migrato.';
                         select count(*) into v_count from fornitore where codice = migrCursor.codice_soggetto and nat_giuridica = 5 ;
                         if v_count > 0 then msgMotivoScarto := msgMotivoScarto||'Soggetto ATI.';end if;
                    when others then
                      dbms_output.put_line(h_rec || ' msgRes ' ||
                                           msgRes || ' Errore ' || SQLCODE || '-' ||
                                           SUBSTR(SQLERRM, 1, 100));
                      pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore ' ||
                                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
                      pRecScartati := cDocScartati;
                      pRecInseriti := cDocInseriti;
                      pCodRes      := -1;
                      return;
                  end;

                  if h_sogg_migrato = 0 then
                    select nvl(count(*),0) into h_sogg_valido
                    from fornitore f
                    where f.codice = migrCursor.codice_soggetto
                    and f.stato='S';
                    if h_sogg_valido = 0 then
                      msgMotivoScarto :=  msgMotivoScarto||'Soggetto non valido.';
                    end if;
                  end if;
              else
                 codRes := -1;
                 msgMotivoScarto := 'Soggetto non determinato.';
              end if;

            end if;

            -- DAVIDE - 27.10.2016 - aggiunta algoritmo stato documento uguale per tutti.
            /*if codRes = 0 then
              msgRes := 'Definizione stato documento.';
  /* mettere nel ciclo
  I-->se stato=1
  PL --> importo_liquidato<importo_dapagare
  L -->  importo_dapagare=importo_liquidato and importo_pagato is null
  PE-->  importo_liquidato>importo_pagato*/
              /*if migrCursor.stato=1 then h_stato := 'I'; end if;
              if abs(migrCursor.Importo_Liquidato)<abs(migrCursor.Importo_Dapagare) then h_stato := 'PL'; end if;
              if abs(migrCursor.importo_dapagare)=abs(migrCursor.importo_liquidato) and migrCursor.importo_pagato=null then h_stato := 'L'; end if;
              if abs(migrCursor.importo_liquidato)>abs(migrCursor.importo_pagato) then h_stato := 'PE'; end if;

              if h_stato = null then
                codRes := -1;
                msgMotivoScarto := 'Stato non determinato.';
                tipoScarto:='FSS'; -- FATTURA SENZA STATO
              end if;
            end if;*/

            if codRes = 0 then
              msgRes := 'Definizione stato documento.';
              get_stato_documento ('U', migrCursor.codice_soggetto, migrCursor.anno, migrCursor.numero, migrCursor.tipo_fonte,pEnte,pAnnoEsercizio,
                                   h_stato, codRes, msgRes);

              if codRes = -1 then raise ERROR_DOCUMENTO; end if;
              if codRes = -2 then
                    codRes := -1;
                    msgMotivoScarto := msgRes;
                    tipoScarto:='FSS'; -- FATTURA SENZA STATO
              end if;
            end if;
            -- DAVIDE - 27.10.2016 - Fine

            if codRes = 0 then
              msgRes := 'Inserimento in migr_doc_spesa.';
              insert into migr_doc_spesa
              (docspesa_id,
               tipo,
               tipo_fonte,
               anno,
               numero,
               codice_soggetto_fonte, -- è il dato letto dalla vista
               codice_soggetto, -- coincide con il dato letto dalla vista se il soggetto non è sede secondaria, in alternativa è il codice del soggetto di riferimento della sede
               sede_id, -- è l'id della tabella migr_sede_secondaria
               codice_soggetto_pag, -- valore di default
               stato,
               descrizione,
               date_emissione,
               data_scadenza,
               -- data_scadenza_new non gestito per pvto
               termine_pagamento, --non gestito
               importo,
               arrotondamento,
               --bollo --non gestito
               codice_pcc,                                             -- DAVIDE - 05.12.2016 - campo aggiunto al doc spesa
               codice_ufficio,                                         -- DAVIDE - 05.12.2016 - campo aggiunto al doc spesa
               data_ricezione,
               data_repertorio,
               numero_repertorio,
    -- DAVIDE - 10.02.016 - Gestire nuovo campo anno_repertorio
         anno_repertorio,
               note,
               -- causale_sospensione, -non gestito
               -- data_sospensione, -non gestito
               -- data_riattivazione, -non gestito
               -- codice_fiscale_pign, -non gestito
               -- tipo_impresa, -non gestito
               data_registro_fatt,
               numero_registro_fatt,
--               anno_registro_fatt, non è letto dalla vista
               collegato_cec, -- non gestito
               utente_creazione,
               utente_modifica,
               ente_proprietario_id
               )
              values
              (migr_doc_spesa_id_seq.nextval,
               migrCursor.tipo,
               migrCursor.tipo_fonte,
               migrCursor.anno,
               migrCursor.numero,
               migrCursor.codice_soggetto,
               h_codice_soggetto,
               h_sede_id, --è valorizzato se il soggetto del doc è una sede secondaria
               0,-- codben_pagamento
               h_stato,
               migrCursor.descrizione,
               migrCursor.data_emissione,
               migrCursor.data_scadenza,
               0,-- termine di pagamento, valore di default
               migrCursor.importo,
               migrCursor.arrotondamento,-- arrotondamento
         migrCursor.codice_pcc,                                             -- DAVIDE - 05.12.2016 - campo aggiunto al doc spesa
               migrCursor.codice_ufficio,                                         -- DAVIDE - 05.12.2016 - campo aggiunto al doc spesa
               migrCursor.Data_Ricezione,
               migrCursor.Data_Repertorio,
               migrCursor.numero_repertorio,
    -- DAVIDE - 10.02.016 - Gestire nuovo campo anno_repertorio
         migrCursor.anno_repertorio,
         migrCursor.note,
               migrCursor.data_registro_fatt,
               migrCursor.numero_registro_fatt,
--             migrCursor.anno_registro_fatt, scommentare nel caso venisse letto dalla vista
               'N', -- collegato cec valore di default
               migrCursor.utente_creazione,
               migrCursor.utente_modifica,
               pEnte);
              cDocInseriti := cDocInseriti + 1;
           else
              msgRes := 'Inserimento in migr_doc_spesa_scarto.';
              msgRes := msgRes||'Tipo '|| migrCursor.tipo_fonte;
              msgRes := msgRes||'.Anno '|| migrCursor.anno||'.Nr '||migrCursor.numero||'.CodForn '||migrCursor.codice_soggetto;
              msgRes := msgRes||'.Msg '|| msgMotivoScarto||'.Tipo '||tipoScarto;
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
               migrCursor.tipo_fonte,
               migrCursor.anno,
               migrCursor.numero,
               migrCursor.codice_soggetto,
               msgMotivoScarto,
               tipoScarto,
               pEnte);

              cDocScartati := cDocScartati + 1;
            end if;

            if numInsert >= N_BLOCCHI_DOC then
              commit;
              numInsert := 0;
            else
              numInsert := numInsert + 1;
            end if;

          end loop;

--          msgRes := 'Migrazione documenti di spesa.';
--          insert into migr_elaborazione (migr_elab_id,migr_tipo,messaggio_esito,ente_proprietario_id)
--          values (migr_migr_elab_id_seq.nextval,'migrazione_doc_spesa',msgRes||'end.',pEnte);
--          commit;

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
        tipoScarto varchar2(3):=null;
        msgRes  varchar2(4000) := null;

        cDocInseriti number := 0;
        cDocScartati number := 0;

        numInsert number := 0;
        h_rec varchar2(750) := null;

    -- DAVIDE - Conversione Importi quote
--        h_Importo_quote number(15,2) :=0.0;
--        h_Importo_quote_da_dedurre number(15,2) :=0.0;
--    divisa_esercizio varchar2(1) := null;
    -- DAVIDE - Fine

        h_note varchar2(500) := null;
        h_movimentoMigrato number := 0;
        h_liquidazioneMigrata number := 0;
        h_mdpMigrata number := 0;
        h_tipoMov number := 0;
        h_tipoMovrif number := 0;
        h_nro_movimentorif number :=0;
        h_anno_movimentorif number :=0;
        h_nimac number := 0;
        h_nsubimac number := 0;
        h_annoimac varchar2(4) := NULL;
        h_progben varchar2(10):= NULL; -- codice mod pag valorizzata se quota non pagata
        h_liq number := 0;
        h_flag_manuale varchar2(1) := NULL;  -- DAVIDE - 14.12.2016 - aggiunta gestione flag convalida_manuale
        h_motivoScarto varchar2(500):= NULL; -- contiene eventuale motivo scarto di impegno o liquidazione.

        ERROR_DOCUMENTO EXCEPTION;
   begin
        msgRes := 'Pulizia tabelle di migrazione.';

        DELETE FROM MIGR_DOCQUO_SPESA WHERE ENTE_PROPRIETARIO_ID = pEnte and FL_MIGRATO = 'N';
        DELETE FROM MIGR_DOCQUO_SPESA_SCARTO WHERE ENTE_PROPRIETARIO_ID = pEnte;

        commit;

        msgRes := 'Inizio migrazione quote di spesa.';

        for migrCursor in
          (select
              d.docspesa_id
              ,q.tipo_documento as tipo_fonte
              ,decode (q.tipo_documento,1,'FAT',4,'NCD',5,'NTE',6,'FPR',7,'FAT',8,'NCD',NULL) tipo
              ,q.anno_fattura anno
              ,q.nro_fattura numero
              ,q.fornitore_fat codice_soggetto_fonte
              ,q.progressivo frazione
              ,d.codice_soggetto -- codice soggetto del documento (di riferimento se doc legato a sede secondaria)
              ,d.sede_id
              ,0 elenco_doc_id -- non gestito, valore di default
              ,0 codice_soggetto_pag -- non gestito, valore di default
              ,decode(q.tipo_cessione,'NC',q.beneficiario_pag,NULL) codice_modpag
              ,0 codice_modpag_del -- non gestito, valore di default
              ,0 codice_indirizzo -- non gestito, valore di default
              ,'N' sede_secondaria -- non gestito, valore di default
              ,nvl(q.importo_quota,0) as importo
              ,pAnnoEsercizio as anno_esercizio -- anno di migrazione
              ,q.anno_capitolo as anno_impegno
              ,nvl(q.nro_impegno,0) as numero_impegno
              ,nvl(q.nro_subimpegno,0) as numero_subimpegno
              ,q.anno_atto as anno_provvedimento
              ,nvl(q.nro_atto,0) as numero_provvedimento
    -- DAVIDE - 10.02.016 - Descrizione /datascadenza della quota doc , se non presente valorizzare con dati doc
              ,d.descrizione                                       -- per PVTO, prendo dalla tavola migr_doc_spesa
        ,d.data_scadenza                                     -- per PVTO, prendo dalla tavola migr_doc_spesa
              ,q.tipo_atto as tipo_provvedimento
              ,NULL as sac_provvedimento
              ,'N' as flag_rilevante_iva -- non gestito, valore di default
              ,q.cup
              ,q.cig
    -- DAVIDE - 10.02.016 - inserito il valore di default in commissioni
              --,NULL as commissioni
              ,TIPO_COMMISSIONI_ES as commissioni  -- DAVIDE - 15.12.2016
              ,'N' as flag_ord_singolo --non gestito, valore di default
              ,'N' as flag_avviso --non gestito, valore di default
              ,'N' as flag_esproprio --non gestito, valore di default
              --,'S' as flag_manuale
              ,NULL as flag_manuale -- DAVIDE - 11.02.016
              , decode (q.tipo_cessione,'NC',NULL,q.fornitore_pag||'/'||q.beneficiario_pag) note
              , 0 as numero_mutuo --non gestito, valore di default
              ,'N' as flag_certif_crediti --non gestito, valore di default
              ,nvl(q.nro_liquidazione,0)nro_liquidazione
              ,nvl(q.nro_mandato,0) as numero_mandato
              ,0 as anno_elenco -- non gestitp
              ,0 as numero_elenco --non gestito
              ,nvl(q.login_quota,pLoginOperazione) as utente_creazione
              ,pLoginOperazione as utente_modifica
        ,q.importo_splitreverse                   -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
              ,q.tipo_iva_splitreverse                  -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
        ,d.codice_pcc                             -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
        ,d.codice_ufficio                         -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
            from dwh.fattura_migrazione_quota q
                 , migr_doc_spesa d
            where d.ente_proprietario_id=pEnte
            and d.anno=q.anno_fattura
            and d.numero=q.nro_fattura
            and d.codice_soggetto_fonte=q.fornitore_fat
            and d.tipo_fonte=q.tipo_documento)
        loop
          codRes := 0;
          h_movimentoMigrato := 0;
          h_liquidazioneMigrata := 0;
          h_mdpMigrata := 0;
          h_tipoMov  := 0;
          h_tipoMovrif := 0;
          h_nro_movimentorif :=0;
          h_anno_movimentorif := 0;
          h_progben := NULL; -- modalità di pagamento valorizzata solo se quota non pagata
          h_nimac := 0; --dato valorizzato solo se quota non pagata
          h_nsubimac := 0; --dato valorizzato solo se quota non pagata
          h_annoimac := NULL; --dato valorizzato solo se quota non pagata
          h_liq := 0; --dato valorizzato solo se quota non pagata
          h_note := NULL;
          h_motivoScarto := NULL;
          h_flag_manuale := migrCursor.flag_manuale;   -- DAVIDE - 14.12.2016 - aggiunta gestione flag convalida_manuale

          h_rec := 'Quota  ' || migrCursor.anno || '/'||migrCursor.numero||' tipo '||migrCursor.tipo_fonte||
                     ' Soggetto '||migrCursor.codice_soggetto||': frazione '||migrCursor.frazione||'.';

          -- DAVIDE - 10.02.016 - aggiunto scarto per fattura negativa
          -- se importo negativo e tipo = FAT scarto il documento
          msgRes := 'Verifica importo fattura.';
          if migrCursor.tipo='FAT' and migrCursor.importo <0 then
          codRes := -1;
              msgMotivoScarto := 'Importo negativo per tipo fattura.';
              tipoScarto:='FN'; -- fattura negativa
          end if;

          if codRes = 0 then

              if migrCursor.numero_mandato = 0 -- quota non pagata
              then
--1 quota non pagata
              -- 1 Verifica Modalità di pagamento se valorizzata
              if migrCursor.codice_modpag is not null then
                msgRes := 'Verifica mdp migrata '||migrCursor.codice_modpag||' per soggetto code '||migrCursor.codice_soggetto||', sede id '|| migrCursor.sede_id||'.';
                h_progben := migrCursor.codice_modpag;
                begin
                  if migrCursor.sede_id is null or migrCursor.sede_id = 0 then
--                    msgRes := msgRes|| 'Ricerca senza sede.';
                    Select nvl(count(*),0) into h_mdpMigrata
                    from migr_modpag mdp, migr_soggetto sogg
                    where sogg.ente_proprietario_id = pEnte
                    and sogg.codice_soggetto = migrCursor.codice_soggetto -- codice_soggetto di riferimento del doc
                    and mdp.soggetto_id = sogg.soggetto_id
                    and mdp.codice_modpag = migrCursor.codice_modpag
                    and mdp.sede_id is null;
                  else
--                    msgRes := msgRes|| 'Ricerca con sede '||migrCursor.sede_id||'.';
                    Select nvl(count(*),0) into h_mdpMigrata
                    from migr_modpag mdp, migr_soggetto sogg
                    where sogg.ente_proprietario_id = pEnte
                    and sogg.codice_soggetto = migrCursor.codice_soggetto  -- codice_soggetto di riferimento del doc
                    and mdp.soggetto_id = sogg.soggetto_id
                    and mdp.codice_modpag = migrCursor.codice_modpag
                    and mdp.sede_id = migrCursor.sede_id;
                  end if;
                exception
                when no_data_found then
                     codRes := -1;
                     msgMotivoScarto := 'Mdp non migrata.';
                     tipoScarto := 'MDP';
                  when
                    others then
                    msgRes := msgRes || ' Errore ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 100);
                    RAISE ERROR_DOCUMENTO;
                end;
              end if;
            -- 1 Verifica Modalità di pagamento se valorizzata
          -- 2 Verifica movimento migrato , se quota non pagata
          if codRes = 0 and migrCursor.numero_impegno !=0 then -- 02.11.2016 Sofia verifiche da fare solo se impegno associato a quota
            msgRes := 'Verifica movimento migrato '||migrCursor.anno_impegno||'\'||migrCursor.numero_impegno||'\'||migrCursor.numero_subimpegno||'.';

            if migrCursor.numero_subimpegno !=0 then
              msgRes := msgRes||'Verifica tipo movimento.';
              -- capisco che tipo di movimento abbiamo legato alla quota, se movimento di budget (tipo 6), dobbiamo impostare correttamente il nr impegno ed il sub
              select mc.tipo_mov ,mc_rif.tipo_mov,mc.nro_mov_riferim, mc_rif.anno_intervento
              into h_tipoMov, h_tipoMovrif, h_nro_movimentorif, h_anno_movimentorif
              from movimento_contab mc, movimento_contab mc_rif
              where mc.nro_movimento = migrCursor.numero_subimpegno
              and mc_rif.nro_movimento = mc.nro_mov_riferim;

              msgRes := msgRes || 'Tipo movimento letto '||h_tipoMov||', tipo mov rif letto '||h_tipoMovrif;
              if h_tipoMov = 6 then -- movimento di budget
                if h_tipoMovrif = 1 then -- movimento di budget legato ad impengo
                  h_nimac := h_nro_movimentorif; -- dovrebbe coincidere con il campo dwh.fattura_migrazione_quota.nro_impegno letto
                  h_nsubimac := 0;
                  h_annoimac := to_char(h_anno_movimentorif); -- dovrebbe coincidere con il campo dwh.fattura_migrazione_quota.anno_capitolo letto
                elsif h_tipoMovrif = 2 then -- movimento di budget legato a subimpengo

                  h_nsubimac := h_nro_movimentorif;

                  select mc_rif.nro_movimento, mc_rif.anno_intervento, mc_rif.tipo_mov
                  into h_nro_movimentorif, h_anno_movimentorif, h_tipoMovrif
                  from movimento_contab mc, movimento_contab mc_rif
                  where mc.nro_movimento = h_nro_movimentorif --nr subimpegno
                  and mc_rif.nro_movimento = mc.nro_mov_riferim;

                  if h_tipoMovrif = 1 then
                    h_nimac := h_nro_movimentorif;
                    h_annoimac := to_char(h_anno_movimentorif);
                  end if;

                end if;
              elsif h_tipoMov = 2 then -- movimento subimpegno
                h_nimac := migrCursor.numero_impegno;
                h_nsubimac := migrCursor.numero_subimpegno;
                h_annoimac := migrCursor.anno_impegno;
              elsif   h_tipoMov = 1 then -- il nro_subimpegno in realta e un movimento impegno  -- 09.11.2016 Sofia&DAvide
                h_nimac := migrCursor.numero_subimpegno;
                h_nsubimac := 0;
                h_annoimac := migrCursor.anno_impegno;
              end if;


              -- 02.11.2016 Sofia spostato da sotto
              if h_nimac = 0 then -- non sono riuscita a recuperare l'impegno associato, caso non considerato, scartiamo il record
               codRes := -1;
               msgMotivoScarto := 'Movimento non trovato nella movimento_contab.';
               tipoScarto := 'MOV';
              end if;
            else
              h_nimac := migrCursor.numero_impegno;
              h_nsubimac := migrCursor.numero_subimpegno;
              h_annoimac := migrCursor.anno_impegno;
            end if;

            /** 02.11.2016 Sofia spostato da sopra solo per numero_subimpegno , ricerca degli estremi del movimento padrre
            if h_nimac = 0 then -- non sono riuscita a recuperare l'impegno associato, caso non considerato, scartiamo il record
               codRes := -1;
               msgMotivoScarto := 'Movimento non trovato nella movimento_contab.';
               tipoScarto := 'MOV';
            end if; **/

            if codRes = 0 then
              Select nvl(count(*),0) into h_movimentoMigrato from migr_impegno m
              where ente_proprietario_id = pEnte
              and m.anno_esercizio = migrCursor.anno_esercizio
              and m.anno_impegno = h_annoimac
              and m.numero_impegno = h_nimac
              and m.numero_subimpegno = h_nsubimac;

              if h_movimentoMigrato = 0 then
                 codRes := -1;
                 msgMotivoScarto := 'Impegno '||migrCursor.anno_impegno||'/'||migrCursor.numero_impegno||'/'||migrCursor.numero_subimpegno||' a.e. '||migrCursor.anno_esercizio||' non migrato.';
                 tipoScarto := 'MOV';

                 begin
                   -- verifica movimento scartato
                   msgRes := 'Verifica movimento scartato.';
                   select ms.motivo_scarto into h_motivoScarto
                   from migr_impegno_scarto ms
                    where ms.ente_proprietario_id = pEnte
                    and ms.anno_esercizio = migrCursor.anno_esercizio
                    and ms.anno_impegno = h_annoimac
                    and ms.numero_impegno = h_nimac
                    and ms.numero_subimpegno = h_nsubimac;
                 exception
                  when no_data_found then
                    h_motivoScarto:=NULL;
                  when too_many_rows then
                    h_motivoScarto:='Movimento scartato per più di un motivo.'; -- migliorare concatenando i motivi di scarto del movimento.
                  when others then
                      msgRes := msgRes || ' Errore ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 100);
                      RAISE ERROR_DOCUMENTO;
                 end;
                 if h_motivoScarto is not null then
                   msgMotivoScarto := msgMotivoScarto||h_motivoScarto;
                 end if;

              end if;-- movimento non migrato
             end if;-- if codRes=0
        end if; -- if codRes=0 -- 02.11.2016 Sofia aggiunto if su numero_impegno valorizzato
        -- 2 Verifica movimento migrato , se quota non pagata

        if codRes = 0 and migrCursor.nro_liquidazione!=0 then -- 02.11.2016 Sofia aggiunto test su nro_liquidazione
        -- 3 Verifica liquidazione migrata, se quota non pagata
          msgRes := 'Verifica liquidazione migrata numero '||migrCursor.nro_liquidazione||'.';
          h_liq := migrCursor.nro_liquidazione;

--          begin
            Select nvl (count(*),0) into h_liquidazioneMigrata
            from migr_liquidazione
            where ente_proprietario_id = pEnte
            and anno_esercizio = migrCursor.anno_esercizio
            and numero_liquidazione = migrCursor.nro_liquidazione;

            if h_liquidazioneMigrata = 0 then
                 codRes := -1;
                 msgMotivoScarto := 'Liquidazione '||migrCursor.nro_liquidazione||' a.e. '||migrCursor.anno_esercizio||' non migrata.';
                 tipoScarto := 'LIQ';

                 -- verifica liquidazione scartata
                 begin
                   msgRes := 'Verifica Liquidazione scartata.';
                   select ms.motivo_scarto into h_motivoScarto
                   from migr_liquidazione_scarto ms
                    where ms.ente_proprietario_id = pEnte
                    and ms.anno_esercizio = migrCursor.anno_esercizio
                    and ms.numero_liquidazione = migrCursor.nro_liquidazione;
                  exception
                    when no_data_found then
                      h_motivoScarto:=NULL;
                    when too_many_rows then
                      h_motivoScarto:='Liquidazione scartata per più di un motivo.'; -- migliorare concatenando i motivi di scarto della liquidazione.
                    when others then
                        msgRes := msgRes || ' Errore ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 100);
                        RAISE ERROR_DOCUMENTO;
                  end;
                  if h_motivoScarto is not null then
                    msgMotivoScarto := msgMotivoScarto||h_motivoScarto;
                  end if;
            else  -- DAVIDE - 14.12.2016 - aggiunta gestione flag convalida_manuale
                h_flag_manuale := 'M';
            end if;
--          exception
--            when no_data_found then
--                 codRes := -1;
--                 msgMotivoScarto := 'Liquidazione '||migrCursor.nro_liquidazione||' a.e. '||migrCursor.anno_esercizio||' non migrata.';
--                 tipoScarto := 'LIQ';
--            when others then
--                 msgRes := msgRes || ' Errore ' || SQLCODE || '-' ||SUBSTR(SQLERRM, 1, 100);
--                 RAISE ERROR_DOCUMENTO;
--            end;-- chiude blocco begin
            end if; -- codRes = 0
            -- 3 Verifica liquidazione migrata, se quota non pagata

            else
            msgRes := 'Quota Pagata.';
            -- la quota è pagata, integriamo le note
            if migrCursor.numero_subimpegno = 0 then
              h_note:='PAGAMENTO N.MAND '||migrCursor.numero_mandato||' N.LIQ '||migrCursor.nro_liquidazione||' IMPEGNO '||
                    migrCursor.anno_impegno||'/'||migrCursor.numero_impegno||'  ANNO '||migrCursor.anno_esercizio||'.';
            else
              h_note:='PAGAMENTO N.MAND '||migrCursor.numero_mandato||' N.LIQ '||migrCursor.nro_liquidazione||' SUBIMPEGNO '||
                   migrCursor.anno_impegno||'/'||migrCursor.numero_impegno||'/'||migrCursor.numero_subimpegno
                   ||'  ANNO '||migrCursor.anno_esercizio||'.';
            end if;
           end if; -- if quota non pagata
           --1 quota non pagata

        end if; -- DAVIDE 10.02.016 - codRes = 0

        if codRes = 0 then

          h_note := h_note||migrCursor.note;

          insert into migr_docquo_spesa
                     (docquospesa_id,
                      docspesa_id,
                      tipo,
                      tipo_fonte,
                      anno,
                      numero,
                      codice_soggetto,
                      codice_soggetto_fonte,
                      frazione,
                      sede_id, -- id della tabella migr_sede_secondaria se soggetto sede secondaria
                      elenco_doc_id,-- impostato valore di default 0
                      codice_soggetto_pag, -- valore di default 0
                      codice_modpag,
                      codice_modpag_del, -- valore di default 0
                      codice_indirizzo,-- valore di default 0
                      sede_secondaria,--valore di default N
                      importo,
                      importo_da_dedurre,--valore di default 0
                      anno_esercizio,
                      anno_impegno,
                      numero_impegno,
                      numero_subimpegno,
                      anno_provvedimento,
                      numero_provvedimento,
                      tipo_provvedimento,
                      sac_provvedimento, --NULL
    --                  oggetto_provvedimento,
    --                  note_provvedimento,
    --                  stato_provvedimento,
    -- DAVIDE - 10.02.016 - Descrizione /datascadenza della quota doc , se non presente valorizzare con dati doc
                      descrizione,
    --          numero_iva, da verificare come trattare
                      flag_rilevante_iva, -- valore di default N
                      data_scadenza,
    --          data_scadenza_new, --NULL non gestito
                      cup,
                      cig,
      -- DAVIDE - 10.02.016 - inserito il campo commissioni con il valore default
                      commissioni,
                      --causale_sospensione,non gestito
                      --data_sospensione,non gestito
                      --data_riattivazione,non gestito
                      flag_ord_singolo, -- valore di default N
                      flag_avviso, -- valore di default N
                      --tipo_avviso, NULL non gestito
                      flag_esproprio, -- valore di default N
                      flag_manuale, -- valore impostato a S
                      note,
                      causale_ordinativo, -- DAVIDE - 15.12.2016 - gestito da adesso
                      numero_mutuo, -- valore di default 0
                      --annotazione_certif_crediti,
                      --data_certif_crediti, NULL non gestito
                      --note_certif_crediti, NULL non gestito
                      --numero_certif_crediti, NULL non gestito
                      flag_certif_crediti, --valore di default N
                      numero_liquidazione,
                      numero_mandato,
                      anno_elenco , -- valore di default 0
                      numero_elenco , -- valore di default 0
                      --data_pagamento_cec,non gestito
                      importo_splitreverse,                  -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
                      tipo_iva_splitreverse,                 -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
            codice_pcc,                            -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
            codice_ufficio,                        -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
                      utente_creazione,
                      utente_modifica,
                      ente_proprietario_id)
                     values
                     (migr_docquo_spesa_id_seq.nextval,
                      migrCursor.Docspesa_Id,
                      migrCursor.tipo,
                      migrCursor.tipo_fonte, -- fa parte della chiave del doc
                      migrCursor.anno,
                      migrCursor.numero,
                      migrCursor.codice_soggetto,
                      migrCursor.codice_soggetto_fonte, -- fa parte della chiave del doc
                      migrCursor.Frazione,
                      migrCursor.Sede_id,
                      migrCursor.elenco_doc_id,
                      migrCursor.codice_soggetto_pag,--codice_soggetto_pag
                      h_progben,
                      migrCursor.codice_modpag_del,--codice_modpag_del
                      migrCursor.codice_indirizzo,--codice_indirizzo
                      migrCursor.sede_secondaria,
                      migrCursor.importo,
                      0,--importo_da_dedurre
                      migrCursor.anno_esercizio,
                      h_annoimac,
                      h_nimac,
                      h_nsubimac,
                      migrCursor.anno_provvedimento,
                      migrCursor.numero_provvedimento,
                      migrCursor.tipo_provvedimento,
                      migrCursor.sac_provvedimento,
      -- DAVIDE - 05.02.016 - Descrizione /datascadenza della quota doc , se non presente valorizzare con dati doc
                      migrCursor.descrizione,
                      migrCursor.flag_rilevante_iva,
                      migrCursor.data_scadenza,
                      migrCursor.cup,
                      migrCursor.cig,
      -- DAVIDE - 10.02.016 - inserito il campo commissioni con il valore default
                      migrCursor.commissioni,
                      migrCursor.flag_ord_singolo,-- valore di default N
                      migrCursor.flag_avviso,-- valore di default N
                      migrCursor.flag_esproprio,-- valore di default N
                      --migrCursor.flag_manuale,-- valore di default N
					  h_flag_manuale,           -- DAVIDE - 14.12.2016 - aggiunta gestione flag convalida_manuale
                      h_note,
					  migrCursor.descrizione, -- descrizione della fattura come causale_ordinativo - DAVIDE - 15.12.2016
                      migrCursor.numero_mutuo,
                      migrCursor.flag_certif_crediti,
                      h_liq,
                      migrCursor.numero_mandato,
                      migrCursor.anno_elenco,
                      migrCursor.numero_elenco,
                      migrCursor.importo_splitreverse,      -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
                      migrCursor.tipo_iva_splitreverse,     -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
            migrCursor.codice_pcc,                -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
            migrCursor.codice_ufficio,            -- DAVIDE - 05.12.2016 - campo aggiunto alla quota
                      migrCursor.utente_creazione,
                      migrCursor.utente_modifica,
                      pEnte);
                      cDocInseriti := cDocInseriti+1;

              end if;
              if codRes = -1 then
                insert into migr_docquo_spesa_scarto
                (docquo_spesa_scarto_id,tipo,anno,numero,codice_soggetto,frazione,motivo_scarto,tipo_scarto,ente_proprietario_id)
                values
                (migr_docquo_spe_scarto_id_seq.nextval,migrCursor.tipo_fonte,migrCursor.anno,migrCursor.numero,migrCursor.codice_soggetto_fonte
                ,migrCursor.frazione,msgMotivoScarto,tipoScarto,pEnte);
                cDocScartati := cDocScartati+1;
              end if;

               if numInsert >= N_BLOCCHI_DOC then
                commit;
                numInsert := 0;
               else
                numInsert := numInsert + 1;
               end if;
            end loop;

            msgRes := 'set fl_scarto per doc con quote scartate';
            update migr_doc_spesa m set m.fl_scarto='S'
            where 0!=(select count(*) from  migr_docquo_spesa_scarto mq
                where mq.anno=m.anno
                  and mq.numero=m.numero
                  and mq.tipo=m.tipo_fonte
                  and mq.codice_soggetto=m.codice_soggetto_fonte
                  and mq.ente_proprietario_id=pEnte) -- quote scartate
            and   m.ente_proprietario_id=pEnte;

            pCodRes := 0; -- Elaborazione terminata senza errori, con possibili scarti
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;

    exception
          when ERROR_DOCUMENTO then
            pMsgRes      := pMsgRes || h_rec || msgRes ;
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
          when others then
            pMsgRes      := pMsgRes || h_rec || msgRes || 'Errore AAA' ||SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
            pRecScartati := cDocScartati;
            pRecInseriti := cDocInseriti;
            pCodRes      := -1;
            rollback;
   end migrazione_docquo_spesa;

   -- DAVIDE - 27.10.2016 - aggiunta algoritmo stato documento uguale per tutti.
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
      select count(*) into nr_quote from dwh.fattura_migrazione_quota q where
      --q.eu=doc_eu
      --and
      q.anno_fattura=doc_annofatt
      and q.nro_fattura=doc_nfatt
      and q.fornitore_fat=doc_codben
      and q.tipo_documento=doc_tipofatt;

   if   nr_quote>0 then   --- documenti con quote Sofia 02.11.2016
      -- quote senza dati finanziari
      -- Non avere dati finanziari puo significare: o avere nro_impegno = 0 o avere un impegno/subimpegno non migrato
      select count(*) into quote_nimp from dwh.fattura_migrazione_quota q where
      --q.eu=doc_eu
      --and
      q.anno_fattura=doc_annofatt
      and q.nro_fattura=doc_nfatt
      and q.fornitore_fat=doc_codben
      and q.tipo_documento=doc_tipofatt
      and (nro_impegno = 0);


      if doc_eu = 'U' then
        select count(*) into quote_nimpmigr
        from dwh.fattura_migrazione_quota q
        where
        --q.eu=doc_eu
        --and
        q.anno_fattura=doc_annofatt
        and q.nro_fattura=doc_nfatt
        and q.fornitore_fat=doc_codben
        and q.tipo_documento=doc_tipofatt
        and q.nro_impegno != 0 -- con movimento
--        and q.stato_liq <> 'P' -- non pagata
        and q.nro_mandato=0 -- non pagata 15.12.2016 Sofia
        and not exists (select 1 from migr_impegno imp where
                    imp.ente_proprietario_id=pEnte
                    and imp.numero_impegno=q.nro_impegno
                    and imp.numero_subimpegno=q.nro_subimpegno
                    and imp.anno_impegno=q.anno_capitolo
                    --and imp.anno_esercizio=q.anno_capitolo
                    and imp.anno_esercizio=pAnnoEsercizio
                    );

      elsif doc_eu='E' then
        select count(*) into quote_nimpmigr
        from dwh.fattura_migrazione_quota q
        where
        --q.eu=doc_eu
        --and
        q.anno_fattura=doc_annofatt
        and q.nro_fattura=doc_nfatt
        and q.fornitore_fat=doc_codben
        and q.tipo_documento=doc_tipofatt
        and q.nro_impegno != 0 -- con movimento
        --and q.stato_liq <> 'P' -- non pagata
        and q.nro_mandato=0 -- non pagata 15.12.2016 Sofia        
        and not exists (select 1 from migr_accertamento imp where
                    imp.ente_proprietario_id=pEnte
                    and imp.numero_accertamento=q.nro_impegno
                    and imp.numero_subaccertamento=q.nro_subimpegno
                    and imp.anno_accertamento=q.anno_capitolo
                    --and imp.anno_esercizio=q.anno_capitolo
                    and imp.anno_esercizio=pAnnoEsercizio
                    );
      end if;
      -- quote NON liquidate
      -- Non avere dati della liquidazione puo significare: o avere nro_liquidazione = 0 o avere una liquidazione non migrata
      select count(*) into quote_nliq from dwh.fattura_migrazione_quota q where
     -- q.eu=doc_eu
     -- and
      q.anno_fattura=doc_annofatt
      and q.nro_fattura=doc_nfatt
      and q.fornitore_fat=doc_codben
      and q.tipo_documento=doc_tipofatt
      and (nro_liquidazione = 0);

      select count(*) into quote_nliqmigr from dwh.fattura_migrazione_quota q where
      --q.eu=doc_eu
      --and
      q.anno_fattura=doc_annofatt
      and q.nro_fattura=doc_nfatt
      and q.fornitore_fat=doc_codben
      and q.tipo_documento=doc_tipofatt
      and q.nro_liquidazione != 0
--      and q.stato_liq <> 'P'
      and q.nro_mandato=0 -- non pagata 15.12.2016 Sofia
      and not exists (select 1 from migr_liquidazione migr
                      where migr.ente_proprietario_id=pEnte
                      and migr.numero_liquidazione=q.nro_liquidazione
                      and migr.anno_esercizio=q.anno_prot);

      -- quote liquidate
      select count(*) into quote_liq from dwh.fattura_migrazione_quota q where
      --q.eu=doc_eu
      --and
      q.anno_fattura=doc_annofatt
      and q.nro_fattura=doc_nfatt
      and q.fornitore_fat=doc_codben
      and q.tipo_documento=doc_tipofatt
      and (nro_liquidazione != 0);
      -- quote NON pagate
      select count(*) into quote_npag from dwh.fattura_migrazione_quota q where
      --q.eu=doc_eu
      --and
      q.anno_fattura=doc_annofatt
      and q.nro_fattura=doc_nfatt
      and q.fornitore_fat=doc_codben
      and q.tipo_documento=doc_tipofatt
      --and q.stato_liq <> 'P'
      and q.nro_mandato=0 -- non pagata 15.12.2016 Sofia
      ;
      -- quote pagate
      select count(*) into quote_pag from dwh.fattura_migrazione_quota q where
      --q.eu=doc_eu
      --and
      q.anno_fattura=doc_annofatt
      and q.nro_fattura=doc_nfatt
      and q.fornitore_fat=doc_codben
      and q.tipo_documento=doc_tipofatt
      --and q.stato_liq = 'P'
      and q.nro_mandato != 0 -- non pagata 15.12.2016 Sofia
      ;
   end if; -- documenti con quote 02.11.2016 Sofia

   if nr_quote>0 then -- 02.11.2016 Sofia
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
   else   doc_stato:='I'; -- 02.11.2016 Sofia
   end if;


      if doc_stato is null then
        pMsgRes := pMsgRes || 'Stato non definito.';
        pCodRes := -2; -- Non sono riuscito a definire lo stato appropriato.
      end if;

   exception when others then
      pMsgRes      := pMsgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
      pCodRes      := -1;
   end get_stato_documento;
   -- DAVIDE - 27.10.2016 - Fine

-- Davide - 07.12.2016 - calcolo stato documenti a
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

      if nr_quote>0 then -- 13.12.2016 DAVIDE

          if (quote_nimp+quote_nimpmigr) > 0 and quote_liq = 0 then doc_stato := 'I'; end if; -- Almeno una quota senza dati finanziari e nessuna con MDP (ossia liquidazione), Incompleto.

          if (quote_nimp+quote_nimpmigr) = 0 and quote_liq = 0 then doc_stato := 'V'; end if; -- Tutte le quote hanno impegno/accertamento, e nessuna ha liquidazione VALIDO.

          if quote_liq > 0 and quote_npag > 0
             and (quote_liq = nr_quote and quote_npag=nr_quote) then -- Tutte le quote liquidate e tutte da pagare, Liquidato.
              doc_stato := 'L';
          end if;

          if quote_liq > 0 and (quote_nliq+quote_nliqmigr) > 0 then -- Almeno una quota liquidata, ma esiste almeno una quota con nliq=0, Parzialmente liquidato.
              doc_stato := 'PL';
          end if;

          if quote_pag > 0 and quote_npag > 0 then -- Almeno una quota pagata e almeno una quota con pagato='N', Parzialmente emesso.
              doc_stato := 'PE';
          end if;

          if quote_pag > 0 and (quote_pag=nr_quote) then doc_stato := 'EM'; --Tutte le quote sono pagate, stato EMESSO (serve per poter migrare le relazioni tra documenti)
          end if;

    else                        doc_stato:='I'; -- 13.12.2016 DAVIDE
    end if;

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
-- Davide - 07.12.2016 - Fine

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

    -- Documenti di spesa

/*    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_doc_spesa', 'Begin',pEnte);
    commit;*/

 -- DAVIDE - 27.10.2016 - aggiunta algoritmo stato documento uguale per tutti.
    --migrazione_doc_spesa(pEnte,pLoginOperazione,codRes,cDocInseriti,cDocScartati,msgRes);
    migrazione_doc_spesa(pEnte,pLoginOperazione,pAnnoEsercizio,codRes,cDocInseriti,cDocScartati,msgRes);

    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
    /*      insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_doc_spesa',msgRes,pEnte);
          commit;
          msgRes:='';*/
      commit;
    end if;

    -- Quote documenti di spesa
/*    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_docquo_spesa', 'Begin',pEnte);
    commit;*/

    migrazione_docquo_spesa(pEnte,pLoginOperazione,pAnnoEsercizio,
                         codRes,cDocInseriti,cDocScartati,msgRes);
    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
/*          insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','migrazione_docquo_spesa',msgRes,pEnte);
          commit;
          msgRes:='';*/
        commit;
    end if;

    -- DAVIDE - 07.12.2016 - calcolo Stato documento a partire dalle quote
/*    insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
    values (migr_migr_elab_id_seq.nextval,'DOC','aggiorna_stati_docSpesa', 'Begin',pEnte);
    commit;*/

    aggiorna_stati_documenti('U', pEnte, pAnnoEsercizio,
                             codRes, msgRes);

    if codRes!=0 then
        raise ERROR_DOCUMENTO;
    else
/*          insert into migr_elaborazione
           (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
          values (migr_migr_elab_id_seq.nextval,'DOC','aggiorna_stati_docSpesa',msgRes,pEnte);
          commit;
          msgRes:='';*/
      commit;
    end if;
  -- DAVIDE - 07.12.2016 - Fine

    pCodRes:=0;
    pMsgRes:='Elaborazione OK.Documenti Migrati.';

    exception
       when ERROR_DOCUMENTO then
        pMsgRes    := msgRes;
        pCodRes    := -1;
        rollback;
/*        insert into migr_elaborazione
               (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'DOC',NULL, pMsgRes,pEnte);
        commit;*/
      when others then
        pMsgRes      :=  msgRes || 'Errore ' ||
                         SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
        pCodRes      := -1;
        rollback;
/*        insert into migr_elaborazione
               (migr_elab_id,migr_tipo, migr_tipo_elab, messaggio_esito, ente_proprietario_id)
        values (migr_migr_elab_id_seq.nextval,'DOC',NULL, pMsgRes,pEnte);
        commit;*/
   end  migrazione_documenti;

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
