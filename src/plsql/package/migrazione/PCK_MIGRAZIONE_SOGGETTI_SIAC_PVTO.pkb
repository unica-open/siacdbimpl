/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE PACKAGE BODY PCK_MIGRAZIONE_SOGGETTI_SIAC AS
function fnc_migrazione_mod_accredito(pEnte number,pMsgRes out varchar2)
    return number is
    msgRes            varchar2(1500) := null;
    codRes            integer := 0;
    --tipoAccreditoSiac varchar2(10) := '';
    decodificaOIL     varchar2(150) := '';
  begin
        msgRes:='Migrazione modalita di accredito.Pulizia migr_mod_accredito.';
        delete migr_mod_accredito where fl_migrato='N'
        --12.10.2015 dani
        and ente_proprietario_id = pEnte;
        commit;  
        
        msgRes:='Migrazione modalita di accredito.Inserimento.';
          insert into migr_mod_accredito
          (ACCREDITO_ID ,  CODICE ,  DESCRI ,  TIPO_ACCREDITO ,  PRIORITA,  DECODIFICAOIL,  ENTE_PROPRIETARIO_ID  ,  FL_MIGRATO,  DATA_INS )  
          (select migr_accredito_id_seq.nextval, 
            modAccredito.mod_pagam, modAccredito.descrizione, modAccredito.TIPO_ACCREDITO, modAccredito.ordine, modAccredito.decodificaOIL,pEnte,'N',sysdate
          from
          (
              select distinct
                t.mod_pagam, t.descrizione
                , decode (t.mod_pagam,
                                1,'CB',
                                2,'CCP',
                                3, 'CO',
                                4, 'GE',
                                5, 'CO',
                                6, 'CO',
                                7,'CB',
                                8, 'CO',
                                9,'CB',
                               10,'CB',
                               99,'GE',
                               11, 'CBI',
                               12, 'GE',
                               14,'GE',
                               98,'GE',
                               13, 'GE',
                              'ND') as TIPO_ACCREDITO,
                t.ordine, t2.codaccre_tes||'||'||t2.descri as decodificaOIL
                from anag_mod_pagamento t, tabaccre_modpag_tes t2, migr_modpag mmdp
                where t.mod_pagam = t2.codaccre
                and   t.mod_pagam = mmdp.codice_accredito  and mmdp.ente_proprietario_id = pEnte and mmdp.fl_migrato = 'N'
                )modAccredito);

    /*
    msgRes := 'Migrazione modalita di accredito.';

    for modAccredito in (select distinct t.modpagam, t.descrizione,t.
                           from anag_mod_pagamento t
                           where exists (select 1 from migr_modpag m
                                                where m.codice_accredito = t.codaccre
                                                and m.ente_proprietario_id = pEnte
                                                and m.fl_migrato = 'N')
                                                order by 1) loop
      decodificaOIL := '';
    
      if modAccredito.codaccre in (CODACCRE_CB, CODACCRE_LR) then
         tipoAccreditoSiac := SIAC_TIPOACCRE_CB;
         decodificaOIL := '53||CONTO CORRENTE BANCARIO';
      elsif modAccredito.codaccre in (CODACCRE_F3,
                                      CODACCRE_F4,
                                      CODACCRE_PA,
                                      CODACCRE_DM,
                                      CODACCRE_MO
				-- DAVIDE - 10.02.016 - spostate modalit� accredito da CO a GE					  
							, CODACCRE_AB, CODACCRE_AC, CODACCRE_AP) then
									  ) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_GE;
        decodificaOIL := '1||CONTANTI';
      elsif modAccredito.codaccre in (CODACCRE_CT,
                                      CODACCRE_CR) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CO;                              
        decodificaOIL := '1||CONTANTI';
      elsif modAccredito.codaccre in (CODACCRE_PE) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CO;
        decodificaOIL := '1||CONTANTI';
      elsif modAccredito.codaccre=CODACCRE_MD  then
        tipoAccreditoSiac := SIAC_TIPOACCRE_GE;
        decodificaOIL := '0||DISTINTA ALLEGATA';    
      elsif modAccredito.codaccre in (CODACCRE_AT) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CO;
        decodificaOIL := '57||ASSEGNO TRAENZA';
      elsif modAccredito.codaccre=CODACCRE_TC then
        tipoAccreditoSiac := SIAC_TIPOACCRE_GE;
        decodificaOIL := '71||TESORIERE CIVICO';
      elsif modAccredito.codaccre in (CODACCRE_CP,CODACCRE_BP ) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CCP;
      elsif  modAccredito.codaccre=CODACCRE_VA then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CCP;
        decodificaOIL := '1||CONTANTI'; 
      elsif modAccredito.codaccre =CODACCRE_CX then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CSI;
       -- decodificaOIL := '53||CONTO CORRENTE BANCARIO';
      elsif modAccredito.codaccre in (CODACCRE_CC,
                                      CODACCRE_FA,        
                                      CODACCRE_PR,
                                      CODACCRE_PS) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CSI;
      elsif modAccredito.codaccre=CODACCRE_AG then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CSI;
        decodificaOIL := '1||CONTANTI';
      elsif modAccredito.codaccre in (CODACCRE_GC,CODACCRE_CS) then
        tipoAccreditoSiac := SIAC_TIPOACCRE_CBI;
        decodificaOIL := '61||GIRO CONTO BANCA ITALIA';
      else
        tipoAccreditoSiac := SIAC_TIPOACCRE_ND;
      end if;
    
    
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
         modAccredito.priorita,
         decodificaOIL,
         pEnte);
    
    end loop;
    */
    
    commit;  
    pMsgRes := 'Migrazione modalita di accredito OK';
    return codRes;
  
  exception
    when others then
      rollback;
      pMsgRes := msgRes || ' ' || SQLCODE || '-' ||
                   SUBSTR(SQLERRM, 1, 100) || '.';
      codRes    := -1;
      return codRes;
  end fnc_migrazione_mod_accredito;
  
  
procedure migrazione_soggetto(pEnte   number,pCodRes out number,pMsgRes out varchar2)
  is 
    msgRes  varchar2(1500) := null;
    codRes   integer := 0;
    tipoIndirizzo_RESIDENZA varchar2(10) := 'RESIDENZA';
    tipoIndirizzo_SEDEAMM varchar2(10) := 'SEDEAMM';
    tipoVia_DEFAULT varchar2(10) := 'MIGRAZIONE';
    
      procedure  migrazione_soggetto_agg_via ( 
                                            pEnte   number,
                                            pCodRes out number,
                                            pMsgRes out varchar2) is
        msgRes            varchar2(1500) := null;
        codRes             integer := 0;
      begin


       msgRes:='Migrazione Soggetto.Aggiornamento campo VIA.';  
       -- VIA
      update migr_soggetto m set 
      m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='VIA'
      where m.via like 'VIA%' and m.fl_migrato='N'
      --12.10.2015 dani
     and m.ente_proprietario_id = pEnte;

      update migr_soggetto m set 
      m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='VIA'
      where m.via like 'V.%' and m.fl_migrato='N'
      --12.10.2015 dani
     and m.ente_proprietario_id = pEnte;


      update migr_soggetto m set 
      m.via=substr(m.via,3,length(m.via)-2),m.tipo_via='VIA'
      where m.via like 'V %' and m.fl_migrato='N'
      --12.10.2015 dani
     and m.ente_proprietario_id = pEnte;


      -- CORSO
      update migr_soggetto m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CORSO'
      where m.via like 'CORSO%' and m.fl_migrato='N'
      --12.10.2015 dani
     and m.ente_proprietario_id = pEnte;


      update migr_soggetto m set 
      m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='CORSO'
      where m.via like 'CSO %' and m.fl_migrato='N'      
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      update migr_soggetto m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='CORSO'
      where m.via like 'C.SO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      update migr_soggetto m set 
      m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='CORSO'
      where m.via like 'C. %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      --- VIALE
      update migr_soggetto m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='VIALE'
      where m.via like 'VIALE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      update migr_soggetto m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='VIALE'
      where m.via like 'V.LE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      -- VICOLO
      update migr_soggetto m set 
      m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='VICOLO'
      where m.via like 'VICOLO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      -- LARGO
      update migr_soggetto m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='LARGO'
      where m.via like 'LARGO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      update migr_soggetto m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LARGO'
      where m.via like 'L.GO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      
      -- STRADA
      update migr_soggetto m set 
      m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='STRADA'
      where m.via like 'STRADA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      

      update migr_soggetto m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='STRADA'
      where m.via like 'STR.%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      update migr_soggetto m set 
      m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='STRADA'
      where m.via like 'STR %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


      -- CALLE
      update migr_soggetto m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CALLE'
     where m.via like 'CALLE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     -- PIAZZA
     update migr_soggetto m set 
     m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='PIAZZA'
     where m.via like 'PIAZZA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     update migr_soggetto m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='PIAZZA'
     where m.via like 'P.ZZA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     update migr_soggetto m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='PIAZZA'
     where m.via like 'P.ZA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     update migr_soggetto m set 
      m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='PIAZZA'
     where m.via like 'P. %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     
     -- BIVIO
     update migr_soggetto m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='BIVIO'
     where m.via like 'BIVIO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     -- BORGATA
     update migr_soggetto m set 
      m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='BORGATA'
     where m.via like 'BORGATA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     -- FRAZIONE
     update migr_soggetto m set 
      m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='FRAZIONE'
     where m.via like 'FRAZIONE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     
     update migr_soggetto m set 
      m.via=substr(m.via,7,length(m.via)-5),m.tipo_via='FRAZIONE'
     where m.via like 'FRAZ.%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     
     update migr_soggetto m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='FRAZIONE'
     where m.via like 'FRAZ %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     -- REGIONE

     update migr_soggetto m set 
      m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='REGIONE'
     where m.via like 'REGIONE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     
     -- LOCALITA
     update migr_soggetto m set 
      m.via=substr(m.via,11,length(m.via)-10),m.tipo_via='LOCALITA'
     where m.via like 'LOCALITA''%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     update migr_soggetto m set 
      m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='LOCALITA'
     where m.via like 'LOCALITA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     update migr_soggetto m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LOCALITA'
     where m.via like 'LOC.%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;
     

     update migr_soggetto m set 
      m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='LOCALITA'
     where m.via like 'LOC %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;


     commit;

      pMsgRes:= msgRes||' ' ||'Migrazione OK.';
      pCodRes:=codRes;
                  
     exception
        when others then
          pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
          pCodRes    := -1;
          rollback;  
     end migrazione_soggetto_agg_via;
 
  begin
        msgRes:='Migrazione soggetto.Pulizia migr_soggetto.';
        delete migr_soggetto 
        --12.10.2015 dani
        where ente_proprietario_id = pEnte;

        commit;
      msgRes := 'Migrazione Soggetti <> SEDI SEC. ';
          insert into migr_soggetto
        (soggetto_id, codice_soggetto,tipo_soggetto,forma_giuridica, ragione_sociale,codice_fiscale,partita_iva,codice_fiscale_estero,cognome, nome, sesso, data_nascita, 
         comune_nascita,indirizzo_principale,tipo_indirizzo,tipo_via, via,cap,comune, prov,nazione,avviso,email,stato_soggetto, note, generico
         ,ente_proprietario_id)
        (select migr_soggetto_id_seq.nextval 
        , f.codice as codice_soggetto
-- DAVIDE - 29.11.2016 - soggetti ATI migrati come PGI-con partita iva
-- DAVIDE - 29.11.2016 - nature giuridiche 2 e 3 migrate tenendo conto della presenza della p.iva o no - mail Sofia del 29.11.2016
        -- , decode (F.NAT_GIURIDICA,NULL,NULL, 0, 'PF',1,'PFI',2,'PG',3,'PGI',F.NAT_GIURIDICA) -- 4 se deve essere inserito in sede secondaria, codice_rif come legame col soggetto 'principale'
                                                                                                                                                             --select count(*) from fornitore where NAT_GIURIDICA is null and stato = 'S'-- 25052
                                                                                                                                                             --select count(*) from fornitore where NAT_GIURIDICA = 5 and stato = 'S' --31
                                                                                                                                                               -- DEVE ESSERE RICNDOTTO A PF/PFI/PG/PGI
        , decode (F.NAT_GIURIDICA,NULL,NULL, 0, 'PF',1,'PFI',
                   2,decode(f.partita_iva,NULL,'PG','PGI'),
                   3,decode(f.partita_iva,NULL,'PG','PGI'),
                   5,'PGI',F.NAT_GIURIDICA) 
        , NULL --as  forma_giuridica --� uguale al campo  tipo_soggetto ?
                                          -- nota valenzano: che cosa si intende? (srl-spa�.)
                                           -- ELENCATI I DATI SU EXCEL
        , nvl(trim(f.nome1||' '||f.nome2),'RAGIONE SOCIALE MANCANTE') --as ragione_sociale
-- DAVIDE - 29.11.2016 - natura giuridica 2 con presenza della p.iva, passa la p.iva altrimenti passa cf - mail Sofia del 29.11.2016
        -- , f.codice_fiscale 
      , decode (F.NAT_GIURIDICA, 2, decode(f.codice_fiscale,NULL,decode(f.partita_iva,NULL,NULL,f.partita_iva),f.codice_fiscale), 
                               --  3, decode(f.codice_fiscale,NULL,decode(f.partita_iva,NULL,NULL,f.partita_iva),f.codice_fiscale),
                                 5, decode(f.codice_fiscale,NULL,decode(f.partita_iva,NULL,NULL,f.partita_iva),f.codice_fiscale),
                                 f.codice_fiscale)
        , f.partita_iva
        , decode (ditta_estera, 'S', nvl(codice_fiscale,'9999999999999999'),NULL) --as codice_fiscale_estero
        , F.NOME1 --as cognome -- attenzione non abbiamo i campi separati
                                           -- GUARDARE COSA FATTO PER COTO: gestiti i campi separati
                                           -- REGP dedotti da ragione sociale
        , NULL as nome
        , f.sesso
        , to_char(f.dta_nascita,'YYYY-MM-DD') data_nascita
        , decode(F.LUOGO_NASCITA,NULL,NULL,upper(F.LUOGO_NASCITA)||'||||') --as comune_nascita
        --, NULL as provincia_nascita
        --, NULL as nazione_nascita
        , 'S'-- as indirizzo_principale
        , decode (F.NAT_GIURIDICA,0,tipoIndirizzo_RESIDENZA,tipoIndirizzo_SEDEAMM) --as tipo_indirizzo
        ,  tipoVia_DEFAULT  --as tipo_via --migrazione_soggetto_agg_via COME PER REGP importante che non rimanga NULL per postgres
        , F.INDIRIZZO --as via
        --, NULL as numero_civico
        --, NULL as interno
        --, NULL as frazione
        , f.cap
        , decode (trim(f.comune),NULL,NULL,  upper(f.comune)||'||||') --as comune
        , decode (f.ditta_estera, 'S','EE||',
            decode (removeBadChar(upper(f.provincia)),NULL,NULL,  
            removeBadChar(upper(f.provincia))||'||')) --as prov 
        , decode (f.ditta_estera,'N', 'ITALIA||001',NULL) --as nazione
        , 'N' --as avviso
        --, NULL as tel1           
        --, NULL as tel2
        --, NULL as fax
        --, NULL as sito_www
        , decode (f.mail, NULL, NULL, 'email||'||f.mail||'||N') --as email
        --, NULL as contatto_generico
-- DAVIDE - 29.11.2016 - soggetti ATI migrati in stato SOSPESO
        --, 'VALIDO'--as stato_soggetto
		, decode (F.NAT_GIURIDICA,5,'SOSPESO','VALIDO')  
        , f.note-- as note
        , 'N' --as generico
        , pEnte
        from fornitore f
        where f.stato = 'S'
--        and F.NAT_GIURIDICA not in ( 4, 5) -- ESCLUDIAMO LE SEDI SECONDARIE CHE SARANNO CARICATE SUCCESSIVAMENTE (4)
                                             -- PER ORA ESCLUDIAMO LE ATI CHE NON SAPPIAMO COME GESTIRE (5)
        and F.NAT_GIURIDICA not in ( 4) -- DAVIDE - 29.11.2016 - le ATI possiamo gestirle ora
--        and F.INDIRIZZO IS NOT NULL -- CONDIZIONE DA ELIMINARE, IL CAMPO DEVE ESSERE SEMPRE VALORIZZATO
                                      -- 09.10.2015 condizione cancellata, il dato ancora non � stato bonificato, il soggetto senza
                                      -- il soggetto senza inidirizzo viene comunque migrato.
        );
        
        msgRes:='Migrazione Soggetto. Aggiorna campo VIA.';
        migrazione_soggetto_agg_via (pEnte,codRes,msgRes);
        if codRes=0 then
              pMsgRes:='Migrazione Soggetto OK.';
        else   pMsgRes:=msgRes;
        end if;

        pCodRes:=codRes;
        commit;
  exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;  
  end migrazione_soggetto;


    procedure migrazione_indirizzo_second(pEnte           number,
                                      pCodRes out number,
                                      pMsgRes out varchar2) is
                                      
  msgRes            varchar2(1500) := null;
  msgResFin         varchar2(1500) := null;
  codRes            integer := 0;
  indirizzoPrincipale varchar2(1)       :='N';
  tipoVia            varchar2(50)      :='MIGRAZIONE';
  tipoIndirizzo      varchar2(50)      :='DOMICILIO';
  flagAvviso         varchar2(1)       :='N';

  ERROR_SOGGETTO     EXCEPTION;


  procedure migrazione_agg_via_indir_sec ( pEnte number,
                                           pCodRes out number,
                                           pMsgRes out varchar2) is
  
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
  
  begin
  
  msgRes:='Migrazione Soggetto Indirizzi Secondari.Aggiornamento via su indirizzo.';
  -- VIA
  update migr_indirizzo_secondario m set 
  m.via=nvl(substr(m.via,5,length(m.via)-4),'   '),m.tipo_via='VIA'
  where m.via like 'VIA%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;
      
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='VIA'
  where m.via like 'V.%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,3,length(m.via)-2),m.tipo_via='VIA'
  where m.via like 'V %'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- CORSO
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CORSO'
  where m.via like 'CORSO%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='CORSO'
  where m.via like 'CSO %'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='CORSO'
  where m.via like 'C.SO%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='CORSO'
  where m.via like 'C. %'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  --- VIALE
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='VIALE'
  where m.via like 'VIALE%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='VIALE'
  where m.via like 'V.LE%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- VICOLO
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='VICOLO'
  where m.via like 'VICOLO%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- LARGO
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='LARGO'
  where m.via like 'LARGO%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LARGO'
  where m.via like 'L.GO%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- STRADA
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='STRADA'
  where m.via like 'STRADA%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='STRADA'
  where m.via like 'STR.%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='STRADA'
  where m.via like 'STR %' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- CALLE
  
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CALLE'
  where m.via like 'CALLE%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- PIAZZA

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='PIAZZA'
  where m.via like 'PIAZZA%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='PIAZZA'
  where m.via like 'P.ZZA%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='PIAZZA'
  where m.via like 'P.ZA%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='PIAZZA'
  where m.via like 'P. %' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- BIVIO

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='BIVIO'
  where m.via like 'BIVIO%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- BORGATA

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='BORGATA'
  where m.via like 'BORGATA%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;
  

  -- FRAZIONE
  
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='FRAZIONE'
  where m.via like 'FRAZIONE%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;

  
 update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-5),m.tipo_via='FRAZIONE'
 where m.via like 'FRAZ.%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;
 
     
 update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='FRAZIONE'
 where m.via like 'FRAZ %' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  -- REGIONE

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='REGIONE'
  where m.via like 'REGIONE%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;
  

  -- LOCALITA

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,11,length(m.via)-10),m.tipo_via='LOCALITA'
  where m.via like 'LOCALITA''%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='LOCALITA'
  where m.via like 'LOCALITA%' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LOCALITA'
  where m.via like 'LOC.%'
    and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;


  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='LOCALITA'
  where m.via like 'LOC %' and m.fl_migrato='N'
  --12.10.2015 dani
  and m.ente_proprietario_id = pEnte;

  commit;

  pMsgRes:= msgRes||' ' ||'Aggiornamento OK.';
  pCodRes:=codRes;
              
  exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;  
  end migrazione_agg_via_indir_sec;

  begin

    msgResFin:='Migrazione indirizzo secondario.Popolamento migr_indirizzo_secondario.';
    msgRes:='Pulizia migr_indirizzo_secondario.';
    delete migr_indirizzo_secondario where fl_migrato='N'
    --12.10.2015 dani
    and ente_proprietario_id = pEnte;
    
    commit;

    msgRes:='Lettura migr_soggetto e indir_alternativi.';

    insert into  migr_indirizzo_secondario
    (indirizzo_id, soggetto_id, indirizzo_principale,
     tipo_indirizzo, tipo_via, via,
     cap, comune, prov, nazione, avviso,ente_proprietario_id)
    (select migr_indirizzo_id_seq.nextval,
        ms.soggetto_id
        , indirizzoPrincipale -- flag indirizzo principale
        , tipoIndirizzo -- inserire il valore in variabile e verificare se sia questo il tipo per il domicilio fiscale
        , tipoVia --tipo via aggiornata in seguito
        , INDIRIZZO_FISC -- via
        , CAP_FISC
        , decode (trim(COMUNE_FISC),NULL, NULL, COMUNE_FISC||'||||')
        , decode (f.ditta_estera, 'S','EE||',
                decode (PCK_MIGRAZIONE_SOGGETTI_SIAC.removeBadChar(upper(f.provincia)),NULL,NULL,  
                PCK_MIGRAZIONE_SOGGETTI_SIAC.removeBadChar(upper(f.provincia))||'||')) --as prov 
        , decode (f.ditta_estera,'N', 'ITALIA||001',NULL) --as nazione
        , flagAvviso
        , pEnte
    from migr_soggetto ms, fornitore f
    where ms.ente_proprietario_id = pEnte
    and MS.CODICE_SOGGETTO =   F.CODICE
    and (F.INDIRIZZO_FISC is not null and F.COMUNE_FISC is not null ));

    if (codRes=0) then
       migrazione_agg_via_indir_sec ( pEnte,codRes,msgRes);
    end if;

    pCodRes:=codRes;
    if codRes=0 then
          pMsgRes:='Migrazione Soggetti-Indirizzi Secondari OK.';
          commit;
    else
          pMsgRes    := msgResFin||' ' ||msgRes;
    end if;

exception
   when ERROR_SOGGETTO then
     pMsgRes    := msgResFin||' ' ||msgRes;
     pCodRes    := -1;
     rollback;
    when others then
      pMsgRes    := msgResFin||' ' ||msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end migrazione_indirizzo_second;

procedure migrazione_soggetto_sede_sec(pEnte number,pCodRes out number,pMsgRes out varchar2)
  is 
    msgRes varchar2(1500) := '';
    codRes integer := 0;
    tipoIndirizzo varchar2(20):='MIGRAZIONE';
    tipoRelazione varchar2(20):='SEDE_SECONDARIA';
    tipoVia_default varchar2(20):= 'MIGRAZIONE';
     procedure  migrazione_agg_via_sede_sec (pEnte number,
                                             pCodRes out number,
                                             pMsgRes out varchar2) is
        msgRes            varchar2(1500) := null;
        codRes             integer := 0;
      begin


       msgRes:='Migrazione Soggetto Sede secondaria.Aggiornamento campo VIA.';  
       -- VIA
      update migr_sede_secondaria m set 
      m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='VIA'
      where m.via like 'VIA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='VIA'
      where m.via like 'V.%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,3,length(m.via)-2),m.tipo_via='VIA'
      where m.via like 'V %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      -- CORSO
      update migr_sede_secondaria m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CORSO'
      where m.via like 'CORSO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='CORSO'
      where m.via like 'CSO %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='CORSO'
      where m.via like 'C.SO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='CORSO'
      where m.via like 'C. %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      --- VIALE
      update migr_sede_secondaria m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='VIALE'
      where m.via like 'VIALE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='VIALE'
      where m.via like 'V.LE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      -- VICOLO
      update migr_sede_secondaria m set 
      m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='VICOLO'
      where m.via like 'VICOLO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      -- LARGO
      update migr_sede_secondaria m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='LARGO'
      where m.via like 'LARGO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LARGO'
      where m.via like 'L.GO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;
      
      -- STRADA
      update migr_sede_secondaria m set 
      m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='STRADA'
      where m.via like 'STRADA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='STRADA'
      where m.via like 'STR.%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      update migr_sede_secondaria m set 
      m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='STRADA'
      where m.via like 'STR %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

      -- CALLE
      update migr_sede_secondaria m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CALLE'
     where m.via like 'CALLE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     -- PIAZZA
     update migr_sede_secondaria m set 
     m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='PIAZZA'
     where m.via like 'PIAZZA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     update migr_sede_secondaria m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='PIAZZA'
     where m.via like 'P.ZZA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     update migr_sede_secondaria m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='PIAZZA'
     where m.via like 'P.ZA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     update migr_sede_secondaria m set 
      m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='PIAZZA'
     where m.via like 'P. %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;
     
     -- BIVIO
     update migr_sede_secondaria m set 
      m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='BIVIO'
     where m.via like 'BIVIO%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     -- BORGATA
     update migr_sede_secondaria m set 
      m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='BORGATA'
     where m.via like 'BORGATA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     -- FRAZIONE
     update migr_sede_secondaria m set 
      m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='FRAZIONE'
     where m.via like 'FRAZIONE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;
     
     update migr_sede_secondaria m set 
      m.via=substr(m.via,7,length(m.via)-5),m.tipo_via='FRAZIONE'
     where m.via like 'FRAZ.%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;
     
     update migr_sede_secondaria m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='FRAZIONE'
     where m.via like 'FRAZ %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     -- REGIONE

     update migr_sede_secondaria m set 
      m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='REGIONE'
     where m.via like 'REGIONE%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;
     
     -- LOCALITA
     update migr_sede_secondaria m set 
      m.via=substr(m.via,11,length(m.via)-10),m.tipo_via='LOCALITA'
     where m.via like 'LOCALITA''%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     update migr_sede_secondaria m set 
      m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='LOCALITA'
     where m.via like 'LOCALITA%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     update migr_sede_secondaria m set 
      m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LOCALITA'
     where m.via like 'LOC.%' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     update migr_sede_secondaria m set 
      m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='LOCALITA'
     where m.via like 'LOC %' and m.fl_migrato='N'
      --12.10.2015 dani
      and m.ente_proprietario_id = pEnte;

     commit;

      pMsgRes:= msgRes||' ' ||'Migrazione OK.';
      pCodRes:=codRes;
                  
     exception
        when others then
          pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
          pCodRes    := -1;
          rollback;  
     end migrazione_agg_via_sede_sec;
    
  begin
    -- verificare casi  il soggtto a cui si fa rimferimento � stato migrato?
    -- devo mantenere l'informazione del codice soggetto sede
    
    msgRes:='Migrazione soggetto SEDE.Pulizia migr_sede_secondaria.';
        delete migr_sede_secondaria
        --12.10.2015 dani
       where ente_proprietario_id = pEnte;
       
    commit;    
    msgRes:='Migrazione soggetto SEDE.Inserimento.';
    insert into  migr_sede_secondaria
        (sede_id,soggetto_id,codice_sede,ragione_sociale,email, note, tipo_indirizzo,indirizzo_principale,tipo_via,via,cap, comune, prov,nazione,avviso,tipo_relazione, ente_proprietario_id,
        codice_modpag)
        (select 
        migr_sede_id_seq.nextval
        ,ms.soggetto_id
        , F.CODICE
        ,f.nome1||' '||f.nome2
        ,decode (f.mail, NULL, NULL, 'SS||email||'||f.mail||'||N')  -- Con SS l'indirizzo email verr� associato al sogetto sede lato postgres
        , f.note 
        , tipoIndirizzo -- impostato a MIGRAZIONE
        ,'N'
        ,tipoVia_default --determinarlo dal campo VIA chiamando la procedura migrazione_agg_via_sec
        ,f.indirizzo
        ,f.cap
        , decode (trim(f.comune),NULL,NULL,  upper(f.comune)||'||||') --as comune
        , decode (f.ditta_estera, 'S','EE||',decode (f.provincia,NULL,NULL,  upper(f.provincia)||'||')) --as prov 
        , decode (f.ditta_estera,'N', 'ITALIA||001',NULL) --as nazione
        ,'N'
        , tipoRelazione -- impostato a SEDE_SECONDARIA
        , pEnte
        ,'0'-- valorizzare solo se la sede deriva da una modalit� di pagamento, non � questo il caso
         from migr_soggetto ms, fornitore f
            where ms.ente_proprietario_id = pEnte
            and F.CODICE_RIF = ms.codice_soggetto
            and F.NAT_GIURIDICA = 4 -- sede secondaria
            and f.stato='S'
--            and F.INDIRIZZO IS NOT NULL -- CONDIZIONE DA ELIMINARE, IL CAMPO DEVE ESSERE SEMPRE VALORIZZATO
                                      -- 09.10.2015 condizione cancellata, il dato ancora non � stato bonificato, il soggetto senza
                                      -- il soggetto senza inidirizzo viene comunque migrato.            
            );
     
    msgRes:='Migrazione Soggetto sede secondaria. Aggiorna campo VIA.';
    migrazione_agg_via_sede_sec (pEnte,codRes,msgRes);
    if codRes=0 then
       pMsgRes:='Migrazione Soggetto sede secondaria OK.';
    else   pMsgRes:=msgRes;
    end if;

    pCodRes := 0;
    commit;
  exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback; 
  end migrazione_soggetto_sede_sec;
  
procedure migrazione_soggetto_mdp(pEnte   number, pCodRes out number, pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
begin

  msgRes:='Migrazione Soggetto MDP.Pulizia migr_modpag.';
  delete migr_modpag where fl_migrato='N'
        --12.10.2015 dani
  and ente_proprietario_id = pEnte;
  commit;
  
  msgRes:='Migrazione Soggetto MDP - SEDE SECONDARIA N';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,ente_proprietario_id)
   (select migr_modpag_id_seq.nextval,
    ms.soggetto_id,NULL
    , MDP.PROGRESSIVO
    , NULL -- cessione Valenzano deve fare un'estrazione per avere l'info
    , 'N' -- sede secondaria
    , MDP.MOD_PAGAM -- codice di accredito
    ,mdp.iban, MDP.BIC
    , decode(MDP.COD_BANCA,NULL,NULL,MDP.COD_BANCA||'||'||B.DESCRI) abi
    , decode(MDP.CAB,NULL,NULL,MDP.CAB||'||'||A.descri) cab
    , decode(MDP.MOD_PAGAM, 2,MDP.CC_POSTALE,MDP.CC_BANCA) -- DAVIDE - 12.12.2016 - MDP.CC_BANCA o MDP.CC_POSTALE per campo conto_corrente 
    , NULL -- per conto_corrente_intest
    , MDP.DELEGATO -- per quietanzante
    , MDP.CODFISC_DELEGATO -- per codice_fiscale_quiet
    , null --codice_fiscale_del
    , null -- per data_nascita_qdel
    , null -- per luogo_nascita_qdel
    , null -- per stato_nascita_qdel,
    , 'VALIDO' -- per stato_modpag
    , MDP.NOTE -- note
    , null --email
    , 0 -- delegato_id
    , pEnte
    from migr_soggetto ms, beneficiario mdp,tabbanche_valide b, tabagenzie_valide a  
    where ms.ente_proprietario_id = pEnte
    and mdp.codice=ms.CODICE_SOGGETTO 
    and MDP.COD_BANCA = B.CODBANCA(+)
    and MDP.CAB = A.CODAGEN(+)
    and MDP.COD_BANCA = A.CODBANCA(+)
    and MDP.STATO = 'S'
    and MDP.MOD_PAGAM is not null -- CONDIZIONE DA ELIMINARE TUTTI I RECORD DEVONO AVERE LA MODALITA DI ACCREDITO DEFINITA
    and ritenuta is null -- 10.03.2015 Non sono migrate le mdp con ritenuta valorizzata
    --order by ms.soggetto_id,mdp.progressivo
    );
    
  msgRes:='Migrazione Soggetto MDP - SEDE SECONDARIA S';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,ente_proprietario_id)
   (select migr_modpag_id_seq.nextval
    , MSS.soggetto_id
    , MSS.SEDE_ID
    , MDP.PROGRESSIVO
    , NULL -- cessione Valenzano deve fare un'estrazione per avere l'info
    , 'S' -- sede secondaria
    , MDP.MOD_PAGAM -- codice di accredito
    , mdp.iban, MDP.BIC
    , decode(MDP.COD_BANCA,NULL,NULL,MDP.COD_BANCA||'||'||B.DESCRI) abi
    , decode(MDP.CAB,NULL,NULL,MDP.CAB||'||'||A.descri) cab
    , decode(MDP.MOD_PAGAM, 2,MDP.CC_POSTALE,MDP.CC_BANCA) -- DAVIDE - 12.12.2016 - MDP.CC_BANCA o MDP.CC_POSTALE per campo conto_corrente
    , NULL -- per conto_corrente_intest
    , MDP.DELEGATO -- per quietanzante
    , MDP.CODFISC_DELEGATO -- per codice_fiscale_quiet
    , null --codice_fiscale_del
    , null -- per data_nascita_qdel
    , null -- per luogo_nascita_qdel
    , null -- per stato_nascita_qdel,
    , 'VALIDO' -- per stato_modpag
    , MDP.NOTE -- note
    , null --email
    , 0 -- delegato_id
    , pEnte
    from migr_sede_secondaria mss, beneficiario mdp,tabbanche_valide b, tabagenzie_valide a
    where mss.ente_proprietario_id = pEnte
    and mdp.codice=mss.CODICE_SEDE
    and MDP.COD_BANCA = B.CODBANCA(+)
    and MDP.CAB = A.CODAGEN(+)
    and MDP.COD_BANCA = A.CODBANCA(+)
    and MDP.STATO = 'S'
    --order by ms.soggetto_id,mdp.progressivo
    and MDP.MOD_PAGAM is not null -- CONDIZIONE DA ELIMINARE TUTTI I RECORD DEVONO AVERE LA MODALITA DI ACCREDITO DEFINITA
    and ritenuta is null -- 10.03.2015 Non sono migrate le mdp con ritenuta valorizzata
    );
 
  -- DAVIDE - 11.01.2017 - aggiorna il campo contocorrente_intest prendendo il valore dalla tavola beneficiario_11, mail Valenzano del 09.01.2017
  update migr_modpag mdp
	  set conto_corrente_intest = (select mdp11.nome_tesoreria
                                     from beneficiario_11 mdp11, migr_soggetto sog
                                    where sog.ente_proprietario_id=mdp.ente_proprietario_id
                                      and sog.soggetto_id=mdp.soggetto_id
                                      and mdp11.codice=sog.codice_soggetto
                                      and mdp11.progressivo=mdp.codice_modpag)
   where mdp.ente_proprietario_id = pEnte
     and mdp.codice_accredito=11;	   
  -- DAVIDE - 11.01.2017 - Fine
  
  pMsgRes:= 'Migrazione Soggetto MDP OK.';
  pCodRes:=codRes;
  
  commit;
 
exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;  
end migrazione_soggetto_mdp;

procedure migrazione_soggetti(pEnte  number,pAnnoEsercizio varchar2,pAnni  number, pCodRes out number,pMsgRes out varchar2) is
    msgRes            varchar2(1500) := null;
    codRes            integer := 0;
    ERROR_SOGGETTO EXCEPTION;
    begin          

         -- popolamento migr_soggetto    
         migrazione_soggetto(pEnte,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;
         
            -- popolamento migr_indirizzo_secondario
            -- to do
         migrazione_indirizzo_second(pEnte,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;
     
         -- popolamento migr_sede_secondaria
         migrazione_soggetto_sede_sec(pEnte,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;
         
     -- popolamento migr_modpag
         migrazione_soggetto_mdp(pEnte,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;
     
         -- popolamento migr_modaccre
         codRes:=fnc_migrazione_mod_accredito(pEnte,msgRes);
         if (codRes!=0) then
            raise ERROR_SOGGETTO;
         end if;

     -- popolamento migr_relaz_soggetto [da fare]              
     -- NON SERVE PER PROVINCIA                         
         /*migrazione_soggetto_relaz(pEnte,codRes,msgRes);
         if (codRes!=0) then
           raise ERROR_SOGGETTO;
         end if;*/ 
                              
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
 

    
    --create table migr_badChar ( str varchar2(255) primary key ) 
    procedure insertBadChar is
     l_str varchar2(255);
     begin
      delete migr_badChar;
      for i in 0 .. 31
        loop
             l_str := l_str || chr(i);
        end loop;
       for i in 127..255
         loop
                  l_str := l_str || chr(i);
        end loop;
        insert into migr_badChar values ( l_str );
        commit;
      end;
  
    function removeBadChar( str in varchar2) return varchar2 is
        undesirable varchar2(25) ;
     begin
        select str into undesirable from migr_badChar;
        return replace(
                    translate(str, undesirable, '@@' ),
                    '@@' , '' 
                    );
        exception when others then
            return null;
      end;

END;
/
