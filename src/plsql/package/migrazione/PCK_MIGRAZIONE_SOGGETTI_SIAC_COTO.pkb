/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- PACKAGE MIGRAZIONE SOGGETTI COTO
CREATE OR REPLACE PACKAGE BODY PCK_MIGRAZIONE_SOGGETTI_SIAC IS
 function fnc_migrazione_mod_accredito(pEnte number,
                                       pMsgRes out varchar2)
    return number is
  
    msgRes            varchar2(1500) := null;
    codRes            integer := 0;
    tipoAccreditoSiac varchar2(10) := '';
    decodificaOIL     varchar2(150) := '';
  begin
  
    msgRes:='Migrazione modalita di accredito.Pulizia migr_mod_accredito.';
    delete migr_mod_accredito where fl_migrato='N' and ente_proprietario_id = pEnte;
    commit;
    
    msgRes := 'Migrazione modalita di accredito.';
  
    for modAccredito in (select distinct t.codaccre, t.descri,t.priorita
                           from tabaccre t
                          where 0 != (select count(*)
                                      from migr_modpag m
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
				-- DAVIDE - 05.02.016 - spostate modalit� accredito da CO a GE					  
							, CODACCRE_AB, CODACCRE_AC, CODACCRE_AP) then
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

  procedure migrazione_delegati ( pEnte number,
                                pCodRes out number,
                                pMsgRes out varchar2) is
  
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
  
  begin
  
  msgRes:='Migrazione delegati soggetto.Pulizia migr_delegati.';
  delete migr_delegati where fl_migrato='N' and ente_proprietario_id = pEnte;
  commit;
  
  msgRes:='Migrazione delegati soggetto.Inserimento tipologie CO.';
  -- delegati con MDP del tipo CO ( cassa )
  insert into migr_delegati
  (delegato_id,codben,progdel,progben,tipo,fl_quiet,fl_intest,ente_proprietario_id)
  (select migr_delegato_id_seq.nextval,d.codben,d.progdel,b.progben,'MDP','S','N',pEnte
   from delegati d, beneficiari b
   where d.data_cessa is null
     and b.codben=d.codben
     and b.progben=d.progben
     and b.data_cessa is null
     and b.codaccre in ('CT','CR','AP')
     and exists (select 1 from migr_soggetto_temp ms where ms.codice_soggetto=d.codben and ms.ente_proprietario_id = pEnte));
  commit;
  
  msgRes:='Migrazione delegati soggetto.Inserimento tipologie CO [non CT,CR,AP].';
  insert into migr_delegati
  (delegato_id,codben,progdel,progben,tipo,fl_quiet,fl_intest,ente_proprietario_id)
  (select migr_delegato_id_seq.nextval,d.codben,d.progdel,b.progben,'MDP','S','N',pEnte
   from delegati d, beneficiari b
   where d.data_cessa is null
     and b.codben=d.codben
     and b.progben=d.progben
     and b.data_cessa is null
     and b.codaccre in ('AC', 'AB', 'AT')
     and exists (select 1 from migr_soggetto_temp ms where ms.codice_soggetto=d.codben and ms.ente_proprietario_id = pEnte));
  commit;   
  
  msgRes:='Migrazione delegati soggetto.Inserimento tipologie GE.';
  insert into migr_delegati
  (delegato_id,codben,progdel,progben,tipo,fl_quiet,fl_intest,ente_proprietario_id)
  (select migr_delegato_id_seq.nextval,d.codben,d.progdel,b.progben,'MDP','N','N',pEnte
   from delegati d, beneficiari b
   where d.data_cessa is null
     and b.codben=d.codben
     and b.progben=d.progben
     and b.data_cessa is null
     and b.codaccre in ('TC', 'F3', 'F4', 'PE', 'PA', 'DM', 'MO', 'MD')
     and exists (select 1 from migr_soggetto_temp ms where ms.codice_soggetto=d.codben and ms.ente_proprietario_id = pEnte));
  commit;   
      
  msgRes:='Migrazione delegati soggetto.Inserimento tipologie CB [CB,LR].';
  insert into migr_delegati
  (delegato_id,codben,progdel,progben,tipo,fl_quiet,fl_intest,ente_proprietario_id)
  (select migr_delegato_id_seq.nextval,d.codben,d.progdel,b.progben,'MDP','N','S',pEnte
   from delegati d, beneficiari b
   where d.data_cessa is null
     and b.codben=d.codben
     and b.progben=d.progben
     and b.data_cessa is null
     and b.codaccre in ('CB','LR')
     and exists (select 1 from migr_soggetto_temp ms where ms.codice_soggetto=d.codben and ms.ente_proprietario_id = pEnte));
  commit;
  
  msgRes:='Migrazione delegati soggetto.Inserimento tipologie CBI.';
  insert into migr_delegati
  (delegato_id,codben,progdel,progben,tipo,fl_quiet,fl_intest,ente_proprietario_id)
  (select migr_delegato_id_seq.nextval,d.codben,d.progdel,b.progben,'MDP','N','S',pEnte
   from delegati d, beneficiari b
   where d.data_cessa is null
     and b.codben=d.codben
     and b.progben=d.progben
     and b.data_cessa is null
     and b.codaccre in ('GC', 'CS')
     and exists (select 1 from migr_soggetto_temp ms where ms.codice_soggetto=d.codben and ms.ente_proprietario_id = pEnte));
  commit;
  
  msgRes:='Migrazione delegati soggetto.Inserimento tipologie CCP.';
  insert into migr_delegati
  (delegato_id,codben,progdel,progben,tipo,fl_quiet,fl_intest,ente_proprietario_id)
  (select migr_delegato_id_seq.nextval,d.codben,d.progdel,b.progben,'MDP','N','S',pEnte
   from delegati d, beneficiari b
   where d.data_cessa is null
     and b.codben=d.codben
     and b.progben=d.progben
     and b.data_cessa is null
     and b.codaccre in ('CP', 'VA', 'BP')
     and exists (select 1 from migr_soggetto_temp ms where ms.codice_soggetto=d.codben and ms.ente_proprietario_id = pEnte));
  commit;   
      
  msgRes:='Migrazione delegati soggetto.Inserimento tipologie CSI [CC,CX].';
  insert into migr_delegati
  (delegato_id,codben,progdel,progben,tipo,tipo_relazione,fl_intest,fl_quiet,ente_proprietario_id)
  (select migr_delegato_id_seq.nextval,d.codben,d.progdel,b.progben,'SO','CSI','N','N',pEnte
   from delegati d, beneficiari b
   where d.data_cessa is null
     and b.codben=d.codben
     and b.progben=d.progben
     and b.data_cessa is null
     and b.codaccre in ('CC', 'CX')
     and exists (select 1 from migr_soggetto_temp ms where ms.codice_soggetto=d.codben and ms.ente_proprietario_id = pEnte));
  commit;
  
  msgRes:='Migrazione delegati soggetto.Inserimento tipologie CSI [altro da  .. CC,CX].'; 
  insert into migr_delegati
  (delegato_id,codben,progdel,progben,tipo,tipo_relazione,fl_intest,fl_quiet,ente_proprietario_id)
  (select migr_delegato_id_seq.nextval,d.codben,d.progdel,b.progben,'SO','CSI','N','N',pEnte
   from delegati d, beneficiari b
   where d.data_cessa is null
     and b.codben=d.codben
     and b.progben=d.progben
     and b.data_cessa is null
     and b.codaccre in ('FA', 'PR', 'PS', 'AG')
     and exists (select 1 from migr_soggetto_temp ms where ms.codice_soggetto=d.codben and ms.ente_proprietario_id = pEnte));   
  commit;
  
  pMsgRes:= 'Migrazione Soggetto delegati OK.';
  pCodRes:=codRes;
  
 
  exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;    
  end migrazione_delegati;


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
    delete migr_soggetto_temp 
    --where ente_proprietario_id = p_ente
    ;
    commit;
  
  
    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti con pagamenti recenti.';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'ORD', p_ente
        from fornitori f
       where f.staoper in ('V','S') and
             f.codben!=0 and
             f.anno_ult_mand is not null and
             f.anno_ult_mand>=h_anno_inizio_migr;

			 
    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti senza pagamenti recenti con impegni nell''anno.';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'IMP', p_ente
        from fornitori f
       where f.staoper in ('V','S') and
             f.codben!=0 and
             ( f.anno_ult_mand is null or f.anno_ult_mand<h_anno_inizio_migr) and
             0!=(select count(*) from impegni i
	-- DAVIDE - 05.02.016 - soggetti relativi a Impegni futuri		 
                -- where i.anno_esercizio=p_anno_esercizio and
                where i.anno_esercizio >= p_anno_esercizio and
                       i.codben=f.codben and i.staoper!='A') and
             0=(select count(*) from migr_soggetto_temp t
                where t.codice_soggetto=f.codben
                and t.ente_proprietario_id=p_ente);

    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti senza pagamenti recenti con subimpegni nell''anno.';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'SIM', p_ente
        from fornitori f
       where f.staoper in ('V','S') and
             f.codben!=0 and
             ( f.anno_ult_mand is null or f.anno_ult_mand<h_anno_inizio_migr) and
             0!=(select count(*) from subimp i
	-- DAVIDE - 05.02.016 - soggetti relativi a SubImpegni futuri		 
                -- where i.anno_esercizio=p_anno_esercizio and
                 where i.anno_esercizio >= p_anno_esercizio and
                       i.codben=f.codben and i.staoper!='A') and
             0=(select count(*) from migr_soggetto_temp t
                where t.codice_soggetto=f.codben
                and t.ente_proprietario_id=p_ente);


    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti senza pagamenti recenti con accertamenti nell''anno.';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'ACC', p_ente
        from fornitori f
       where f.staoper in ('V','S') and
             f.codben!=0 and
             ( f.anno_ult_mand is null or f.anno_ult_mand<h_anno_inizio_migr) and
             0!=(select count(*) from accertamenti i
	-- DAVIDE - 05.02.016 - soggetti relativi a Accertamenti futuri		 
               -- where i.anno_esercizio=p_anno_esercizio and
                where i.anno_esercizio >= p_anno_esercizio and
                       i.codben=f.codben and i.staoper!='A') and
             0=(select count(*) from migr_soggetto_temp t
                where t.codice_soggetto=f.codben
                and t.ente_proprietario_id=p_ente);
                       

    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti senza pagamenti recenti con subacc nell''anno.';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'SAC', p_ente
        from fornitori f
       where f.staoper in ('V','S') and
             f.codben!=0 and
             ( f.anno_ult_mand is null or f.anno_ult_mand<h_anno_inizio_migr) and
             0!=(select count(*) from subacc i
	-- DAVIDE - 05.02.016 - soggetti relativi a SubAccertamenti futuri		 
             --    where i.anno_esercizio=p_anno_esercizio and
                 where i.anno_esercizio >= p_anno_esercizio and
                       i.codben=f.codben and i.staoper!='A') and
             0=(select count(*) from migr_soggetto_temp t
                where t.codice_soggetto=f.codben
                and t.ente_proprietario_id=p_ente);

                       
    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti senza pagamenti recenti con liquidazioni nell''anno.';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'LIQ', p_ente
        from fornitori f
       where f.staoper in ('V','S') and
             f.codben!=0 and
             ( f.anno_ult_mand is null or f.anno_ult_mand<h_anno_inizio_migr) and
             0!=(select count(*) from liquidazione i
                 where i.anno_esercizio=p_anno_esercizio and
                       i.codben=f.codben and i.staoper!='A') and
             0=(select count(*) from migr_soggetto_temp t
                where t.codice_soggetto=f.codben
                and t.ente_proprietario_id=p_ente);
      
     -- 26.02.015 Sofia -verificare se va bene o se bisogna escludere le relazioni tra lo stesso soggetto                  
     /* 02.03.015 Sofia - da mail di Silvia non migriamo soggetti non movimentati solo perche presenti in una catena
     msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti relazionati in forn_storico_ragsoc i soggetti migrati.';
     insert into migr_soggetto_temp
     (codice_soggetto, motivo, ente_proprietario_id)
      select distinct f.codben, 'CAT', p_ente
      from fornitori f
      where exists (select 1 
                    from forn_storico_ragsoc cat , migr_soggetto new
                    where cat.vecchio_codben=f.codben 
                    and   cat.nuovo_codben=new.codice_soggetto
                    and   new.fl_genera_codice='N' ) 
      and  not exists (select 1 from migr_soggetto_temp t
                       where t.codice_soggetto=f.codben);         */
                         
                                       
    -- da aggiungere la parte dei documenti, probilmente controllando che gli stessi soggetti non siano gia presenti da insert
    -- dovuto a movimenti gestione
    
    -- 17.04.2015 - Soggetti legati a mutui che saranno migrati
    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti legati a mutui.';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
    select distinct f.codben, 'MUT', p_ente from fornitori f 
      where f.staoper in ('V','S') and exists
        (select 1 from mutui m, eventi_mutuo ev
                where (m.stato = 'P' or
                               (m.stato <> 'P' and exists (select 1 from imp_mutui v where v.nro_mutuo=m.nro_mutuo and v.anno_esercizio>=p_anno_esercizio))
                       )and not exists (select 1 from eventi_mutuo e where e.nro_mutuo=m.nro_mutuo and e.tipo_evento = 'EST')
                        and ev.nro_mutuo(+) = m.nro_mutuo
                        and (ev.prog_evento is null or ev.prog_evento = (select max(prog_evento) from eventi_mutuo ev2 where ev2.nro_mutuo=m.nro_mutuo))
                and f.codben=m.ist_mutuante
         )
      and not exists (select 1 from migr_soggetto_temp t where t.codice_soggetto=f.codben and t.ente_proprietario_id=p_ente);
      
    commit;
    
    -- 24.04.2015 - Soggetti legati a documenti di spesa che saranno migrati
    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti legati a documenti di spesa [codben].';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
    select distinct f.codben, 'DSO', p_ente from fornitori f 
      where f.staoper in ('V','S') 
      and f.codben!=0
      and exists
            (select 1 from documenti m
             where  m.codben=f.codben
             and    m.statodoc not in  ('EM', 'AN', 'ST','RT') and m.cod_errore is null
            )
      and not exists (select 1 from migr_soggetto_temp t where t.codice_soggetto=f.codben and t.ente_proprietario_id=p_ente);
      
    commit;
    
    -- 18.05.2015 - Soggetti legati a documenti di spesa che saranno migrati come codben_pagamento
    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti legati a documenti di spesa [codben_pagamento].';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
    select distinct f.codben, 'DSP', p_ente from fornitori f 
      where f.staoper in ('V','S') 
      and f.codben!=0
      and exists
            (select 1 from documenti m
             where  m.codben_pagamento=f.codben
             and    m.codben_pagamento!=m.codben
             and    m.statodoc not in  ('EM', 'AN', 'ST','RT') and m.cod_errore is null
            )
      and not exists (select 1 from migr_soggetto_temp t where t.codice_soggetto=f.codben and t.ente_proprietario_id=p_ente);
      
    commit;
    
    -- 24.04.2015 - Soggetti legati a documenti di entrata che saranno migrati
    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti legati a documenti di entrata [codben].';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
    select distinct f.codben, 'DES', p_ente from fornitori f 
      where f.staoper in ('V','S') 
      and f.codben!=0
      and exists
            (select 1 from documenti_ent m
             where m.codben=f.codben
             and   m.statodoc not in  ('EM', 'AN', 'ST','RT') and m.cod_errore is null
            )
      and not exists (select 1 from migr_soggetto_temp t where t.codice_soggetto=f.codben and t.ente_proprietario_id=p_ente);
      
    commit;

    -- 18.05.2015 - Soggetti legati a documenti di entrata che saranno migrati [codben_incasso]
    msgRes:='Migrazione soggetto.Popolamento soggetto_temp.Soggetti legati a documenti di entrata [codben_incasso].';
    insert into migr_soggetto_temp
    (codice_soggetto, motivo, ente_proprietario_id)
    select distinct f.codben, 'DEI', p_ente from fornitori f 
      where f.staoper in ('V','S') 
      and f.codben!=0
      and exists
            (select 1 from documenti_ent m
             where m.codben_incasso=f.codben
             and   m.codben!=m.codben_incasso
             and   m.statodoc not in  ('EM', 'AN', 'ST','RT') and m.cod_errore is null
            )
      and not exists (select 1 from migr_soggetto_temp t where t.codice_soggetto=f.codben and t.ente_proprietario_id=p_ente);
      
    commit;

    
    migrazione_delegati(p_ente,codRes,msgRes);
    
    if ( codRes=0) then
        pMsgRes:='Migrazione Soggetto_temp e delegati OK.';
    else pMsgRes:=msgRes;    
    end if;     
    
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
  msgResFin         varchar2(1500) := null;  
  codRes            integer := 0;
  
  countSoggetto     number(6):=0; 
  tipoSoggetto   varchar2(5)       := null;
  codiceSoggetto number(6)         :=null;
  formaGiuridica varchar2(300)     :=null;
  ragioneSociale varchar2(200)     :=null;
  codiceFiscale  varchar2(16)      :=null;
  partitaIva     varchar2(11)      :=null;
  flGeneraCodice varchar2(1)       :=null;
  codiceFiscaleEstero varchar2(16) :=null;
  codiceFiscaleTemp  varchar2(16)      :=null;
  partitaIvaTemp     varchar2(11)      :=null;
  nomeSoggetto    varchar2(150)    :=null;
  cognomeSoggetto varchar2(150)    :=null;
  dtNascitaSoggetto varchar2(15)   :=null;
  comNascitaSoggetto varchar2(150) :=null;
  provNascitaSoggetto varchar2(150)  :=null;
  statoNascitaSoggetto varchar2(150) :=null;
  sessoSoggetto varchar2(1)          :=null;  
  indirizzoPrinciale varchar2(1)     :='S';
  tipoVia            varchar2(50)    :=null;
  tipoIndirizzo varchar2(50)         :=null;
  viaIndirPrincipale varchar2(250)   :=null;
  capIndirPrincipale varchar2(5)   :=null;
  sedimeIndirPrincipale varchar2(50) :=null;
  comIndirPrincipale    varchar2(150) :=null;
  provIndirPrincipale   varchar2(150) :=null;
  statoIndirPrincipale varchar2(150)  :=null;
  flagAvvisoSoggetto   varchar2(1)   :='N';
  tel1Soggetto         varchar2(50)  :=null;
  tel2Soggetto         varchar2(50)  :=null;
  faxSoggetto          varchar2(50)  :=null;
  sitoWebSoggetto      varchar2(250) :=null;
  emailSoggetto     varchar2(250) :=null;
  noteSoggetto         varchar2(1000) :=null;
  noteSoggettoInTab    varchar2(500)  :=null;  
  statoSoggetto varchar2(50) :=null;
  matricolaHrSpi varchar2(50):=null;
  flagGenerico varchar2(1):='N';
  numCivIndirPrincipale varchar2(7):=null;
  delegatoId number(10):=null;
  progBen number(5):=null;
  progBenDel number(5):=null;
  tipoRelazioneDel varchar2(20):=null;
  
  ERROR_SOGGETTO EXCEPTION;

  
  begin
    
    
    msgResFin:='Migrazione soggetto.Popolamento migr_soggetto.Pulizia migr_soggetto.';
    delete migr_soggetto where fl_migrato='N' and ente_proprietario_id = pEnte;
    delete migr_soggetto_scarto where ente_proprietario_id = pEnte;
    commit;
    
    msgResFin:='Migrazione soggetto.Lettura migr_soggetto_temp e fornitori.';
    msgRes:='Inizio ciclo.';
    for migrSoggettoTemp in
    (select f.codben, f.codfisc,f.partiva,f.codfisc_estero,
            f.ragsoc, f.cognome,f.nome,f.codnatgiu, f.dtns, f.cmns, f.prns, f.stns, f.ssso,
            f.sedime,f.via,f.n_civico,f.cap,f.comune,f.prov, f.cod_stato,
            f.fl_avviso,f.pref1,f.tel1,f.pref2,f.tel2,f.fax,f.sito_www, f.ind_email, f.contatto,
            f.staoper,f.note,f.generico,f.Matricola_Hr_Spi,
            to_char(f.data_fallimento,'dd/mm/yyyy') data_fallimento,f.nro_fallimento,f.note_fallimento, 
            0 delegato_id, 0 progben, 0 progdel
     from migr_soggetto_temp t, fornitori f
     where t.ente_proprietario_id = pEnte 
           and f.codben=t.codice_soggetto
     union 
     select dd.codben, dd.codfisc_partiva codfisc, null partiva, null codifisc_estero,
            dd.ragsoc, dd.cognome, dd.nome,dd.codnatgiu,dd.dtns,dd.documento cmns, dd.prns, dd.stns,dd.ssso,
             null sedime, dd.via,null n_civico, dd.cap, dd.comune, dd.prov, dd.cod_stato, 
            null fl_avviso,dd.pref1, dd.tel1,dd.pref2,dd.tel2, dd.fax,null sito_www, null ind_email, null contatto,
            'V' staoper, null note, 'N' generico,null Matricola_Hr_Spi,
            null data_fallimento, null nro_fallimento,null note_fallimento,
            d.delegato_id ,dd.progben,dd.progdel
     from migr_delegati d, delegati dd
     where 
           dd.codben=d.codben and
           dd.progdel=d.progdel and
           d.tipo='SO' and
           d.ente_proprietario_id=pEnte
     order by 1) 
    loop
     
       delegatoId:=null;
       progBen:=null;
       progBenDel:=null;
       codiceFiscaleTemp:=null;
       partitaIvaTemp:=null;
       flGeneraCodice:='N';
       
       tipoSoggetto:=null;
       codiceSoggetto:=null;
       formaGiuridica:=null;
       ragioneSociale:=null;
       codiceFiscale:=null;
       partitaIva:=null;
       codiceFiscaleEstero:=null;
       nomeSoggetto:=null;
       cognomeSoggetto:=null;
       dtNascitaSoggetto:=null;
       comNascitaSoggetto:=null;
       provNascitaSoggetto:=null;
       statoNascitaSoggetto:=null;
       sessoSoggetto:=null;
       tipoVia:=null;
       tipoIndirizzo:=null;
       viaIndirPrincipale:=null;
       sedimeIndirPrincipale:=null;
       numCivIndirPrincipale:=null;
       comIndirPrincipale:=null;
       provIndirPrincipale:=null;
       statoIndirPrincipale:=null;
       flagAvvisoSoggetto:='N';
       tel1Soggetto:=null;
       tel2Soggetto:=null;
       faxSoggetto:=null;
       sitoWebSoggetto:=null;
       emailSoggetto:=null;
       noteSoggetto:=null;
       noteSoggettoInTab:=null;
       statoSoggetto:=null;
       matricolaHrSpi:=null;
       flagGenerico:='N';
       
       codRes:=0;
       msgRes:=null;
       msgResFin:='Migrazione soggetto.Soggetto codice '||migrSoggettoTemp.codben||'.';
       
       delegatoId:=migrSoggettoTemp.delegato_id;
       progBen:=migrSoggettoTemp.progben;
       progBenDel:=migrSoggettoTemp.progdel;
      
       if (delegatoId is not null and delegatoId!=0 ) then
          flGeneraCodice:='S';
       end if;
       
       msgRes:='Calcolo tipoSoggetto,codiceFiscaleTemp,partitaIvaTemp.';
       if (delegatoId is not null and delegatoid!=0) then
         codiceFiscaleTemp:=migrSoggettoTemp.codfisc; 
         if (length(migrSoggettoTemp.codfisc)=11 and 
           TRIM(TRANSLATE(migrSoggettoTemp.codfisc, '0123456789', ' ' )) is null and
           substr(migrSoggettoTemp.codfisc,1,1) not in ('8','9')) then
                partitaIvaTemp:=migrSoggettoTemp.codfisc;
        end if;   
       else 
         codiceFiscaleTemp:=migrSoggettoTemp.codfisc;
         partitaIvaTemp:=migrSoggettoTemp.partiva;
       end if;
       
       msgRes:='Calcolo tipoSoggetto,codiceFiscale,partitaIva.';
       -- codice_fiscale
       -- partita_iva
       -- PF = PF 
       -- PFI = DI
       -- PG = DP, AS, PS, EP
       -- PGI = PG, CO, RE, PR, CN, CT, US, IM, TC, BA
       --  tipo_soggetto --> PFI 
       if ( codiceFiscaleTemp is not null and   -- codfisc=16  con partita iva per qualsiasi natura giuridica
            length(codiceFiscaleTemp)=16 and
            TRIM(TRANSLATE(codiceFiscaleTemp, '0123456789', ' ' )) is not null and
            partitaIvaTemp is not null ) then
            tipoSoggetto:=PFI_NATGIU;
            codiceFiscale:=codiceFiscaleTemp;
            partitaIva:=partitaIvaTemp;
       end if;     
       
       --- tipo_soggetto --> PG,PGI per esteri con codice_fiscale=9999999999999999 per qualsiasi natura giuridica
       if ( codiceFiscaleTemp is not null and   
            length(codiceFiscaleTemp)=16 and
            TRIM(TRANSLATE(codiceFiscaleTemp, '9', ' ' )) is null ) then
            if ( partitaIvaTemp is not null ) then
               tipoSoggetto:=PGI_NATGIU;
               codiceFiscale:=codiceFiscaleTemp;
               partitaIva:=partitaIvaTemp;
            else
               tipoSoggetto:=PG_NATGIU;
               codiceFiscale:=codiceFiscaleTemp;
            end if;   
       end if;     

      
       --  tipo_soggetto --> PF            
       if ( codiceFiscaleTemp is not null and    --  codfisc=16 senza partiva iva per qualsiasi natura giuridica
            length(codiceFiscaleTemp)=16 and
            TRIM(TRANSLATE(codiceFiscaleTemp, '0123456789', ' ' )) is not null and
            partitaIvaTemp is null ) then
            tipoSoggetto:=PF_NATGIU;
            codiceFiscale:=codiceFiscaleTemp;
       end if;     
      
       --  tipo_soggetto --> PGI 
       if ( partitaIvaTemp is not null ) then -- con partita iva
          if ( codiceFiscaleTemp is not null and -- con codice fiscale !=8,9
               (length(codiceFiscaleTemp)=11 or length(codiceFiscaleTemp) not in (11,16)) and
                substr(codiceFiscaleTemp,1,1) not in ('8','9')) then
                  tipoSoggetto:=PGI_NATGIU;
                  codiceFiscale:=codiceFiscaleTemp;
                  partitaIva:=partitaIvaTemp;
          else 
                  if (codiceFiscaleTemp is null and  -- senza codice fiscale e partita iva !=8,9
                      substr(partitaIvaTemp,1,1) not in ('8','9') ) then
                    tipoSoggetto:=PGI_NATGIU;
                    partitaIva:=partitaIvaTemp;
                  end if;  
          end if; 
      else                                                   -- senza partita iva
              if ( codiceFiscaleTemp  is not null and -- con codice fiscale !=8,9
                   (length(codiceFiscaleTemp)=11 or  length(codiceFiscaleTemp) not in (11,16)) and 
                   substr(codiceFiscaleTemp,1,1) not in ('8','9')) then -- quelli senza natura giuridica potrebbero essere PG
                   if (length(codiceFiscaleTemp)<=11 and 
                       TRIM(TRANSLATE(codiceFiscaleTemp, '0123456789', ' ' )) is null ) then
                         partitaIva:=codiceFiscaleTemp;
                   else  codiceFiscale:=codiceFiscaleTemp;                                
                   end if;                   
                   if (partitaIva is not null and migrSoggettoTemp.Codnatgiu is not null) then
                        tipoSoggetto:=PGI_NATGIU;
                   else tipoSoggetto:=PG_NATGIU;
                   end if;                     
              end if;       
      end if; 

      --  tipo_soggetto --> PG
      if (partitaIvaTemp is not null ) then      -- con partita iva
        if ( codiceFiscaleTemp is not null and      -- con codice fiscale =8,9
             ( length(codiceFiscaleTemp)=11  or length(codiceFiscaleTemp) not in (11,16)) and
             substr(codiceFiscaleTemp,1,1) in ('8','9'))  then
             tipoSoggetto:=PG_NATGIU;
             codiceFiscale:=codiceFiscaleTemp;
             partitaIva:=partitaIvaTemp;
        else   
                  if (codiceFiscaleTemp is null and  -- senza codice fiscale e partita iva =8,9
                      substr(partitaIvaTemp,1,1) in ('8','9') ) then
                    tipoSoggetto:=PG_NATGIU;
                    codiceFiscale:=partitaIvaTemp;
                  end if;  
        end if;
      else                                             -- senza partita iva  
        if ( codiceFiscaleTemp  is not null and -- con codice fiscale =8,9
                   (length(codiceFiscaleTemp)=11 or  length(codiceFiscaleTemp) not in (11,16)) and 
                   substr(codiceFiscaleTemp,1,1) in ('8','9')) then
                   tipoSoggetto:=PG_NATGIU;
                   codiceFiscale:=codiceFiscaleTemp;
        else 
             if  ( codiceFiscaleTemp is null )  then -- senza codice fiscale
               tipoSoggetto:=PG_NATGIU;
             end if;
        end if;  
      end if;    
      
      if (tipoSoggetto is null) then
        msgRes:='Tipo Soggetto non determinato.';
        codRes:=-2; -- 24.04.015 Sofia gestione scarti
        insert into migr_soggetto_scarto
        (soggetto_scarto_id ,  codice_soggetto, motivo_scarto,ente_proprietario_id)
        values
        (migr_soggetto_scarto_id_seq.nextval,migrSoggettoTemp.codben,msgRes,pEnte);
      end if;
      
      if (codRes=0) then
       msgRes:='Codice soggetto, ragioneSociale ...';
       -- codice_soggetto
       codiceSoggetto:=migrSoggettoTemp.codben;
       -- ragione_sociale
       ragioneSociale:=migrSoggettoTemp.ragsoc;

       -- codice_fiscale_estero
       if (migrSoggettoTemp.cod_stato!='001' and migrSoggettoTemp.prov='EE') then
          if ( migrSoggettoTemp.Codfisc_Estero is not null ) then
               codiceFiscaleEstero:=migrSoggettoTemp.Codfisc_Estero; 
          else codiceFiscaleEstero:=CF_ESTERO_99;
          end if;
       end if;
       
       -- cognome, nome e dati di nascita solo per PF,PFI con data di nascita
       -- sesso
       -- data_nascita
       -- comune_nascita
       -- provincia_nascita
       -- nazione_nascita
       if (tipoSoggetto in (PF_NATGIU,PFI_NATGIU) and migrSoggettoTemp.dtns is not null) then
           msgRes:='Cognome,nome , dati di nascita ...'; 
           cognomeSoggetto:= migrSoggettoTemp.cognome;
           nomeSoggetto:=migrSoggettoTemp.nome;
           dtNascitaSoggetto:=to_char(migrSoggettoTemp.Dtns,'YYYY-MM-DD');
           sessoSoggetto:=migrSoggettoTemp.Ssso;
           
           if (migrSoggettoTemp.Cmns is not null) then
            begin  
             --select distinct c.des_comune||'||'||c.cod_istat into comNascitaSoggetto
             select distinct c.des_comune||'||'||c.cod_istat||'||'||c.COD_BELFIORE  into comNascitaSoggetto
             from comuni c
             where c.des_comune=migrSoggettoTemp.Cmns and
                   (migrSoggettoTemp.prns is null or c.prov=migrSoggettoTemp.prns) and
                   c.flag_val=1;
             
             exception 
              when no_data_found then
                 --comNascitaSoggetto:=migrSoggettoTemp.Cmns||'||';
                 comNascitaSoggetto:=migrSoggettoTemp.Cmns||'||||';
              when others then
                  codRes:=-1;
                  msgRes:='Errore in lettura comune di nascita '||migrSoggettoTemp.Cmns||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.'; 
            end;      
           end if;
           
           if (codRes=0 and migrSoggettoTemp.Prns is not null) then
              provNascitaSoggetto:=migrSoggettoTemp.Prns||'||';
           end if;
           
           if (codRes=0 and  migrSoggettoTemp.stns is not null) then
             begin
              select t.des_stato||'||'||t.cod_stato into statoNascitaSoggetto
              from tabstati t
              where t.cod_stato=migrSoggettoTemp.Stns;
              
               exception 
                when no_data_found then
                  statoNascitaSoggetto:=null;
                when others then
                  codRes:=-1;
                  msgRes:='Errore in lettura nazione di nascita '||migrSoggettoTemp.stns||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.';
             end;
           end if;
       end if;       
       
      end if; 

      -- forma_giuridica
      if codRes=0 and migrSoggettoTemp.Codnatgiu is not null and
          migrSoggettoTemp.Codnatgiu!=PF_NATGIU then
          msgRes:='Lettura natura giuridica.';
          begin
           select t.codnatgiu||'||'||t.descri into formaGiuridica
           from  tabnatgiu t
           where t.codnatgiu=migrSoggettoTemp.Codnatgiu;
           
           exception 
              when no_data_found then
                  codRes:=-1;
                  msgRes:='Forma giuridica '||migrSoggettoTemp.Codnatgiu||' non presente in archivio.';
              when others then
                  codRes:=-1;
                  msgRes:='Errore in lettura forma giuridica '||migrSoggettoTemp.Codnatgiu||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.'; 
          end; 
      end if;
              
      if (codRes=0 ) then
        msgRes:='Dati indirizzo principale.';
        -- indirizzo_principale --> 'S'
        -- tipo_indirizzo
        if (tipoSoggetto=PF_NATGIU) then
              tipoIndirizzo:='RESIDENZA';
        else   tipoIndirizzo:='SEDE_AMM';
        end if;
       msgRes:='Dati indirizzo principale.Tipo Via';
        -- tipo_via
        if (migrSoggettoTemp.Sedime is not null) then
         if ( migrSoggettoTemp.Sedime in ('VIA','V.','V')) then
            tipoVia:='VIA';
         end if;
         if ( migrSoggettoTemp.Sedime in ('CORSO','CSO','C.SO','C.')) then
            tipoVia:='CORSO';
         end if;   
         if ( migrSoggettoTemp.Sedime in ('VIALE','V.LE')) then
            tipoVia:='VIALE';
         end if;
         if ( migrSoggettoTemp.Sedime in ('LARGO','L.GO')) then
            tipoVia:='LARGO';
         end if;
         if ( migrSoggettoTemp.Sedime in ('STRADA','STR','STR.')) then
            tipoVia:='STRADA';
         end if;
         if ( migrSoggettoTemp.Sedime in ('PIAZZA','P.ZZA','P.ZA','P.')) then
            tipoVia:='PIAZZA';
         end if;
         if ( migrSoggettoTemp.Sedime in ('LOCALITA''','LOCALITA','LOC','LOC.')) then
            tipoVia:='PIAZZA';
         end if;
         if ( migrSoggettoTemp.Sedime in ('VICOLO','BIOVO','BORGATA','FRAZIONE','REGIONE','CALLE')) then
            tipoVia:=migrSoggettoTemp.Sedime;
         end if;
        end if;
        if (tipoVia is null ) then
          tipoVia:='MIGRAZIONE';
        end if;
        msgRes:='Dati indirizzo principale.Via';
        -- via
        viaIndirPrincipale:=migrSoggettoTemp.via;
        -- civico
         msgRes:='Dati indirizzo principale.Via';
        if (length(migrSoggettoTemp.n_Civico)<=7) then
          numCivIndirPrincipale:=migrSoggettoTemp.n_Civico;
        else 
          if (viaIndirPrincipale is not null) then
             viaIndirPrincipale:=viaIndirPrincipale||' '||migrSoggettoTemp.n_Civico;
          end if;  
        end if;  
         msgRes:='Dati indirizzo principale.Cap';
        -- cap
        capIndirPrincipale:=migrSoggettoTemp.cap;
       msgRes:='Dati indirizzo principale.Comune';
        -- comune
        if (migrSoggettoTemp.comune is not null) then
            begin  
             --select distinct c.des_comune||'||'||c.cod_istat into comIndirPrincipale
             select distinct c.des_comune||'||'||c.cod_istat||'||'||c.cod_belfiore into comIndirPrincipale
             from comuni c
             where c.des_comune=migrSoggettoTemp.comune and
                   ( migrSoggettoTemp.prov is null or c.prov=migrSoggettoTemp.prov ) and
                   c.flag_val=1;
             
             exception 
              when no_data_found then
                  --comIndirPrincipale:=migrSoggettoTemp.comune||'||';
                  comIndirPrincipale:=migrSoggettoTemp.comune||'||||';
              when others then
                  codRes:=-1;
                  msgRes:='Errore in lettura comune indirizzo principale '||migrSoggettoTemp.comune||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.'; 
            end;      
        end if;
         msgRes:='Dati indirizzo principale.Prov';
        -- prov
        if (codRes=0 and migrSoggettoTemp.prov is not null) then
              provIndirPrincipale:=migrSoggettoTemp.prov||'||';
        end if;
        
        -- nazione
        if (codRes=0 and migrSoggettoTemp.Cod_Stato is not null) then
         begin
          select t.des_stato||'||'||t.cod_stato into statoIndirPrincipale
          from tabstati t
          where t.cod_stato=migrSoggettoTemp.cod_stato;
              
          exception 
           when no_data_found then
            statoIndirPrincipale:=null;
           when others then
            codRes:=-1;
            msgRes:='Errore in lettura nazione indirizzo principale '||migrSoggettoTemp.cod_stato||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.';
         end;
        end if;
        
      end if;  
      
      if (codRes=0) then     
       msgRes:='Avviso, contatti, stato .....';
       -- avviso
       if (migrSoggettoTemp.fl_avviso is not null and migrSoggettoTemp.fl_avviso in ('S','P')) then
           flagAvvisoSoggetto:='S';
       else flagAvvisoSoggetto:='N';
       end if;
       -- tel1
       tel1Soggetto:=migrSoggettoTemp.pref1||migrSoggettoTemp.tel1;
       -- tel2
       tel2Soggetto:=migrSoggettoTemp.pref2||migrSoggettoTemp.tel2;
       -- fax
       faxSoggetto:=migrSoggettoTemp.fax;
       -- sito_www
       if (migrSoggettoTemp.Sito_Www is not null) then
          sitoWebSoggetto:='sito'||'||'||migrSoggettoTemp.Sito_Www;  
       end if;
       -- email 
       if (migrSoggettoTemp.Ind_Email is not null) then
         emailSoggetto:='email'||'||'||migrSoggettoTemp.Ind_Email||'||'||flagAvvisoSoggetto;
       end if;
       
       
       -- stato_soggetto
       if (migrSoggettoTemp.Staoper='V') then
            statoSoggetto:='VALIDO';
       else statoSoggetto:='SOSPESO';
       end if;
       
       -- matricola_hr_spi
       -- generico       
       flagGenerico:=migrSoggettoTemp.Generico;
       matricolaHrSpi:=migrSoggettoTemp.Matricola_Hr_Spi;
       
       -- note
       if (migrSoggettoTemp.note is not null) then
          noteSoggetto:=migrSoggettoTemp.note;
       end if;
       begin
          select noteForn.Note into noteSoggettoInTab
          from tab_note_forn noteForn
          where noteForn.Codben=  migrSoggettoTemp.codben;
          
          if (noteSoggetto is not null) then
                noteSoggetto:=noteSoggetto||' '||noteSoggettoInTab;
          else  noteSoggetto:=noteSoggettoInTab;
          end if;
          
          exception 
              when no_data_found then
                null;
              when others then
                  codRes:=-1;
                  msgRes:='Errore in lettura note'||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.';
       end;
       
       if (codRes=0 and migrSoggettoTemp.contatto is not null and length(noteSoggetto)<500 ) then
          if (noteSoggetto is not null) then
                 noteSoggetto:=noteSoggetto||' CONTATTO: '||migrSoggettoTemp.contatto;
          else    noteSoggetto:=' CONTATTO: '||migrSoggettoTemp.contatto;
          end if;
       end if;
       
       if ( codRes=0 and migrSoggettoTemp.data_fallimento is not null and length(noteSoggetto)<500) then
          if (noteSoggetto is not null) then
                noteSoggetto:=noteSoggetto||
                              ' DATI FALLIMENTO: '||migrSoggettoTemp.data_fallimento;
          else  noteSoggetto:=' DATI FALLIMENTO: '||migrSoggettoTemp.data_fallimento;
          end if; 
          if (length(noteSoggetto)<500 and migrSoggettoTemp.Nro_Fallimento is not null) then
            noteSoggetto:=noteSoggetto||' '|| migrSoggettoTemp.Nro_Fallimento;
          end if;
          if (length(noteSoggetto)<500 and migrSoggettoTemp.Note_Fallimento is not null) then
            noteSoggetto:=noteSoggetto||' '|| migrSoggettoTemp.Note_Fallimento;
          end if;
       end if;
      end if;   
       
      if (codRes=0 and length(noteSoggetto)>500) then
            noteSoggetto:=substr(noteSoggetto,1,500);
      end if;


     if (codRes=0) then
        msgRes:='Inserimento in migr_soggetto.';
        --- insert 
        insert into  migr_soggetto
        (soggetto_id,codice_soggetto,tipo_soggetto,forma_giuridica,ragione_sociale,codice_fiscale,
         partita_iva,codice_fiscale_estero,cognome,nome,sesso,
         data_nascita,comune_nascita,provincia_nascita,nazione_nascita,
         indirizzo_principale,tipo_indirizzo,tipo_via,via,numero_civico,cap,comune,prov,nazione,
         avviso,tel1,tel2,fax,sito_www,email,
         stato_soggetto,note,generico,classif,matricola_hr_spi,fl_genera_codice,
         delegato_id,codice_progben_del,codice_progdel_del,ente_proprietario_id
        )
        values
        (migr_soggetto_id_seq.nextval,codiceSoggetto,tipoSoggetto,formaGiuridica,ragioneSociale,codiceFiscale,
         partitaIva,codiceFiscaleEstero,cognomeSoggetto,nomeSoggetto,sessoSoggetto,
         dtNascitaSoggetto,comNascitaSoggetto,provNascitaSoggetto,statoNascitaSoggetto,
         indirizzoPrinciale,tipoIndirizzo,tipoVia,viaIndirPrincipale,numCivIndirPrincipale,capIndirPrincipale,
         comIndirPrincipale,provIndirPrincipale,statoIndirPrincipale,
         flagAvvisoSoggetto,tel1Soggetto,tel2Soggetto,faxSoggetto,sitoWebSoggetto,emailSoggetto,
         statoSoggetto,noteSoggetto,flagGenerico,null,matricolaHrSpi,flGeneraCodice,
         delegatoId,progBen,progBenDel,pEnte
        );
        
     end if;
     
     
     if (codRes=0) then
       countSoggetto:=countSoggetto+1;
     else  
       if (codRes!=-2) then
          RAISE ERROR_SOGGETTO;
       end if;   
     end if;
          
     if  ( ( codRes=0  and countSoggetto>1000 ) or codRes=-2) then
       commit;
     end if; 
     if codRes=-2 then
       codRes:=0;
     end if;  
    end loop;

    
          
    pCodRes:=codRes;
    if codRes=0 then
      pMsgRes:='Migrazione Soggetti OK.[countSoggetti]='||countSoggetto;
      commit;
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
end migrazione_soggetto;                                   


procedure migrazione_recapito_soggetto ( pEnte number,
                                           pCodiceSoggetto  number,
                                           migrRecapito migr_recapito_soggetto%rowtype,
                                           pCodRes out number,
                                           pMsgRes out varchar2) is
  
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
  
  begin

  msgRes:='Inserimento recapito [soggetto_code,soggetto_id,indirizzo_id]='||
          pCodiceSoggetto||','||migrRecapito.soggetto_id||','||migrRecapito.indirizzo_id||'.';    
  
  insert into migr_recapito_soggetto
  (recapito_id,soggetto_id,indirizzo_id,
   tipo_recapito,recapito,avviso,ente_proprietario_id)
  values
  (migr_recapito_id_seq.nextval,migrRecapito.soggetto_id,migrRecapito.indirizzo_id,
   migrRecapito.tipo_recapito,migrRecapito.recapito,migrRecapito.avviso,pEnte);
  
  pMsgRes:= msgRes||' ' ||'Inserimento OK.';
  pCodRes:=codRes;
  
  exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;
end   migrazione_recapito_soggetto;
    
procedure migrazione_indirizzo_second(pEnte           number,
                                      pCodRes out number,
                                      pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  msgResFin         varchar2(1500) := null;  
  codRes            integer := 0;
  
  countIndirizzo     number(6):=0; 

  indirizzoPrincipale varchar2(1)       :='N';
  codiceIndirizzo    number(2)         :=null;
  tipoVia            varchar2(50)      :=null;
  tipoIndirizzo      varchar2(50)      :=null;
  viaIndirizzo       varchar2(250)     :=null;
  capIndirizzo       varchar2(5)       :=null;
  comIndirizzo       varchar2(150)     :=null;
  provIndirizzo      varchar2(150)     :=null;
  statoIndirizzo     varchar2(150)     :=null;
  flagAvviso         varchar2(1)       :=null;
  tel1Indirizzo      varchar2(50)      :=null;
  tel2Indirizzo      varchar2(50)      :=null;
  faxIndirizzo       varchar2(50)      :=null;
  numCivIndirizzo    varchar2(7)       :=null;
  soggettoId         number(7)         :=null;
  indirizzoId        number(7)         :=null;
  ERROR_SOGGETTO     EXCEPTION;
  
  migrRecapito       migr_recapito_soggetto%rowtype;

  procedure migrazione_agg_via_indir_sec ( pEnte   number,
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
    and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='VIA'
  where m.via like 'V.%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,3,length(m.via)-2),m.tipo_via='VIA'
  where m.via like 'V %'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- CORSO
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CORSO'
  where m.via like 'CORSO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='CORSO'
  where m.via like 'CSO %'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;  

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='CORSO'
  where m.via like 'C.SO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;  

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='CORSO'
  where m.via like 'C. %'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;  

  --- VIALE
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='VIALE'
  where m.via like 'VIALE%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;  

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='VIALE'
  where m.via like 'V.LE%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;  

  -- VICOLO
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='VICOLO'
  where m.via like 'VICOLO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- LARGO
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='LARGO'
  where m.via like 'LARGO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LARGO'
  where m.via like 'L.GO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte; 

  -- STRADA
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='STRADA'
  where m.via like 'STRADA%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='STRADA'
  where m.via like 'STR.%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='STRADA'
  where m.via like 'STR %' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  -- CALLE
  
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CALLE'
  where m.via like 'CALLE%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  -- PIAZZA

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='PIAZZA'
  where m.via like 'PIAZZA%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='PIAZZA'
  where m.via like 'P.ZZA%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='PIAZZA'
  where m.via like 'P.ZA%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='PIAZZA'
  where m.via like 'P. %' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  -- BIVIO

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='BIVIO'
  where m.via like 'BIVIO%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  -- BORGATA

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='BORGATA'
  where m.via like 'BORGATA%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  -- FRAZIONE
  
  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='FRAZIONE'
  where m.via like 'FRAZIONE%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  -- REGIONE

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='REGIONE'
  where m.via like 'REGIONE%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  -- LOCALITA

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,11,length(m.via)-10),m.tipo_via='LOCALITA'
  where m.via like 'LOCALITA''%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='LOCALITA'
  where m.via like 'LOCALITA%' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LOCALITA'
  where m.via like 'LOC.%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_indirizzo_secondario m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='LOCALITA'
  where m.via like 'LOC %' and m.fl_migrato='N'
  and m.ente_proprietario_id=pEnte;
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
    delete migr_indirizzo_secondario where fl_migrato='N' and ente_proprietario_id = pEnte;
    commit;
    
    msgRes:='Lettura migr_soggetto e indir_alternativi.';

    -- indirizzo_principale --> 'N'
    -- tipo_indirizzo
    -- tipo_via
    tipoIndirizzo:='MIGRAZIONE';
    tipoVia:='MIGRAZIONE';
    
    for migrIndirSecondario in
    (select t.soggetto_id,t.codice_soggetto codice_soggetto,i.cod_indir,'N' avviso, 
            i.via via,i.n_civico n_civico,i.cap cap,i.comune comune,i.prov prov, i.cod_stato cod_stato,
            i.pref1 pref1,i.tel1 tel1,i.pref2 pref2,i.tel2 tel2,i.fax fax
     from migr_soggetto t, indir_alternativi i
     where t.codice_soggetto=i.codben and
           (t.delegato_id is null or t.delegato_id=0) and
           t.ente_proprietario_id = pEnte and
           t.fl_migrato='N' and
           i.data_cessa is null and
           i.ragsoc is null and 
           i.descrizione is null and
           i.contatto is null
     union
     select t.soggetto_id,f.codben codice_soggetto,0 cod_indir,'S' avviso, 
            decode(nvl(f.sedime_av,'X'),'X',f.via_av,f.sedime_av||' '||f.via_av) via,f.n_civico_av n_civico,f.cap_av cap,f.comune_av comune,f.prov_av prov, null cod_stato,
            null pref1, null tel1, null pref2,null tel2, null fax
     from migr_soggetto t, fornitori f
     where t.codice_soggetto=f.codben and      
           (t.delegato_id is null or t.delegato_id=0) and
            t.ente_proprietario_id = pEnte and
            t.fl_migrato='N' and
           ( f.presso_av is null and 
             f.via_av is not null and
              (-- f.sedime_av is not null or 
                --f.via_av is not null or 
                f.n_civico_av is not null or 
                f.cap_av is not null or f.comune_av is not null or f.prov_av is not null 
              )
           )     
     order by 1,2
    ) 
    loop
       
      soggettoId:=null;
      indirizzoId:=null;
      codiceIndirizzo:=null;

      flagAvviso:=null;
      
      viaIndirizzo:=null;
      numCivIndirizzo:=null;
      comIndirizzo:=null;
      provIndirizzo:=null;
      statoIndirizzo:=null;
      
       
      codRes:=0;
      msgRes:='Soggetto codice '||migrIndirSecondario.codice_soggetto||
               'CodIndir '||migrIndirSecondario.Cod_Indir||'.';
        
        
      msgRes:=msgRes||'Dati indirizzo secondario.';
      -- soggetto_id     
      soggettoId:=  migrIndirSecondario.soggetto_id;
      -- codice_indirizzo
      codiceIndirizzo:= migrIndirSecondario.Cod_Indir;
      -- flag_avviso
      flagAvviso:=migrIndirSecondario.avviso;
        

      msgRes:='Dati indirizzo secondario.Via';
      -- via
      viaIndirizzo:=migrIndirSecondario.via;
      -- civico
      msgRes:='Dati indirizzo secondario.Civico';
      if (length(migrIndirSecondario.n_Civico)<=7) then
          numCivIndirizzo:=migrIndirSecondario.n_Civico;
      else 
          if (viaIndirizzo is not null) then
             viaIndirizzo:=viaIndirizzo||' '||migrIndirSecondario.n_Civico;
          end if;  
      end if;  
       
      msgRes:='Dati indirizzo secondario.Cap';
      -- cap
      capIndirizzo:=migrIndirSecondario.cap;
      msgRes:='Dati indirizzo secondario.Comune';
      -- comune
      if (migrIndirSecondario.comune is not null) then
            begin  
             select 
             --distinct c.des_comune||'||'||c.cod_istat into comIndirizzo
             distinct c.des_comune||'||'||c.cod_istat||'||'||c.cod_belfiore into comIndirizzo
             from comuni c
             where c.des_comune=migrIndirSecondario.comune and
                   ( migrIndirSecondario.prov is null or c.prov=migrIndirSecondario.prov ) and
                   c.flag_val=1;
             
             exception 
              when no_data_found then
                  --comIndirizzo:=migrIndirSecondario.comune||'||';
                  comIndirizzo:=migrIndirSecondario.comune||'||||';
              when others then
                  codRes:=-1;
                  msgRes:='Errore in lettura comune indirizzo secondario '||migrIndirSecondario.comune||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.'; 
            end;      
      end if;
      msgRes:='Dati indirizzo secondario.Prov';
       -- prov
      if (codRes=0 and migrIndirSecondario.prov is not null) then
              provIndirizzo:=migrIndirSecondario.prov||'||';
      end if;

      msgRes:='Dati indirizzo secondario.Nazione';
      -- nazione
      if (codRes=0 and migrIndirSecondario.Cod_Stato is not null) then
         begin
          select t.des_stato||'||'||t.cod_stato into statoIndirizzo
          from tabstati t
          where t.cod_stato=migrIndirSecondario.cod_stato;
              
          exception 
           when no_data_found then
            statoIndirizzo:=null;
           when others then
            codRes:=-1;
            msgRes:='Errore in lettura nazione indirizzo secondario '||migrIndirSecondario.cod_stato||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.';
         end;
      end if;

     if (codRes=0) then
        msgRes:='Inserimento in migr_indirizzo_secondario.';
        --- insert 
        insert into  migr_indirizzo_secondario
        (indirizzo_id, soggetto_id, codice_indirizzo, indirizzo_principale, 
         tipo_indirizzo, tipo_via, via, numero_civico, 
         cap, comune, prov, nazione, avviso,ente_proprietario_id
        )
        values
        (migr_indirizzo_id_seq.nextval,soggettoId,codiceIndirizzo,indirizzoPrincipale,
         tipoIndirizzo,tipoVia,viaIndirizzo,numCivIndirizzo,
         capIndirizzo,comIndirizzo,provIndirizzo,statoIndirizzo,flagAvviso,pEnte
        )
        returning indirizzo_id into indirizzoId;
     end if;
     
     if (codRes=0) then
       -- tel1
       if (migrIndirSecondario.tel1 is not null ) then
              msgRes:='Inserimento recapito tel1.';                      
              migrRecapito.soggetto_id:=soggettoId;
              migrRecapito.indirizzo_id:=indirizzoId;
              migrRecapito.tipo_recapito:='telefono';
              migrRecapito.recapito:=migrIndirSecondario.Pref1||migrIndirSecondario.Tel1;
              migrRecapito.avviso:='N';
              migrazione_recapito_soggetto (pEnte,migrIndirSecondario.codice_soggetto,migrRecapito,codRes,msgRes );
              if (codRes!=0) then
                 RAISE ERROR_SOGGETTO;
              end if;
       end if;
       
       -- tel2
       if (migrIndirSecondario.tel2 is not null ) then
              msgRes:='Inserimento recapito tel2.';
              migrRecapito.soggetto_id:=soggettoId;
              migrRecapito.indirizzo_id:=indirizzoId;
              migrRecapito.tipo_recapito:='telefono';
              migrRecapito.recapito:=migrIndirSecondario.Pref2||migrIndirSecondario.Tel2;
              migrRecapito.avviso:='N';
              migrazione_recapito_soggetto (pEnte,migrIndirSecondario.codice_soggetto,migrRecapito,codRes,msgRes );
              if (codRes!=0) then
                 RAISE ERROR_SOGGETTO;
              end if;
       end if;
       -- fax
       if (migrIndirSecondario.fax is not null) then
              msgRes:='Inserimento recapito fax.';                     
              migrRecapito.soggetto_id:=soggettoId;
              migrRecapito.indirizzo_id:=indirizzoId;
              migrRecapito.tipo_recapito:='fax';
              migrRecapito.recapito:=migrIndirSecondario.fax;
              migrRecapito.avviso:='N';
              migrazione_recapito_soggetto (pEnte,migrIndirSecondario.codice_soggetto,migrRecapito,codRes,msgRes );
              if (codRes!=0) then
                 RAISE ERROR_SOGGETTO;
              end if;
       end if;

     end if;
     
     if (codRes=0) then
       countIndirizzo:=countIndirizzo+1;
     else  RAISE ERROR_SOGGETTO;
     end if;
          
     if (codRes=0 and countIndirizzo>1000) then
       commit;
     end if; 
      
    end loop;

        
    if (codRes=0 and countIndirizzo>0 ) then
       migrazione_agg_via_indir_sec ( pEnte,codRes,msgRes);
    end if;
    
    pCodRes:=codRes;
    if codRes=0 then
          pMsgRes:='Migrazione Soggetti-Indirizzi Secondari OK.[countIndirizzo]='||countIndirizzo;
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

procedure migrazione_soggetto_sede_sec(pEnte           number,
                                       pCodRes out number,
                                       pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  msgResFin         varchar2(1500) := null;  
  codRes            integer := 0;
  
  countSede     number(6):=0; 

  indirizzoPrincipale varchar2(1)       :='N';
  codiceIndirizzo    number(2)         :=null;
  codiceModPag       number(6)         :=null;
  tipoVia            varchar2(50)      :=null;
  tipoIndirizzo      varchar2(50)      :=null;
  tipoRelazione      varchar2(50)      :=null;
  viaIndirizzo       varchar2(250)     :=null;
  capIndirizzo       varchar2(5)       :=null;
  comIndirizzo       varchar2(150)     :=null;
  provIndirizzo      varchar2(150)     :=null;
  statoIndirizzo     varchar2(150)     :=null;
  flagAvviso         varchar2(1)       :='N';
  tel1Indirizzo      varchar2(50)      :=null;
  tel2Indirizzo      varchar2(50)      :=null;
  faxIndirizzo       varchar2(50)      :=null;
  contattoIndirizzo  varchar2(250)      :=null;
  ragSocialeIndirizzo varchar2(250)      :=null;
  numCivIndirizzo    varchar2(7)       :=null;
  soggettoId         number(7)         :=null;
  indirizzoId        number(7)         :=null;
  sedeId             number(7)         :=null;
  esisteSedePerModPag  number(7)         :=null;
  ERROR_SOGGETTO     EXCEPTION;
  

  procedure migrazione_agg_via_sede_sec ( pEnte   number,
                                          pCodRes out number,
                                          pMsgRes out varchar2) is
  
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
  
  begin
  
  msgRes:='Migrazione Soggetto Sede Secondarie.Aggiornamento via su indirizzo sede.';
  -- VIA
  update migr_sede_secondaria m set 
  m.via=nvl(substr(m.via,5,length(m.via)-4),'   '),m.tipo_via='VIA'
  where m.via like 'VIA%' 
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='VIA'
  where m.via like 'V.%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;  

  update migr_sede_secondaria m set 
  m.via=substr(m.via,3,length(m.via)-2),m.tipo_via='VIA'
  where m.via like 'V %'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte; 

  -- CORSO
  update migr_sede_secondaria m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CORSO'
  where m.via like 'CORSO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte; 

  update migr_sede_secondaria m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='CORSO'
  where m.via like 'CSO %'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='CORSO'
  where m.via like 'C.SO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='CORSO'
  where m.via like 'C. %'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  --- VIALE
  update migr_sede_secondaria m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='VIALE'
  where m.via like 'VIALE%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='VIALE'
  where m.via like 'V.LE%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- VICOLO
  update migr_sede_secondaria m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='VICOLO'
  where m.via like 'VICOLO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- LARGO
  update migr_sede_secondaria m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='LARGO'
  where m.via like 'LARGO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LARGO'
  where m.via like 'L.GO%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- STRADA
  update migr_sede_secondaria m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='STRADA'
  where m.via like 'STRADA%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='STRADA'
  where m.via like 'STR.%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='STRADA'
  where m.via like 'STR %' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- CALLE
  
  update migr_sede_secondaria m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='CALLE'
  where m.via like 'CALLE%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- PIAZZA

  update migr_sede_secondaria m set 
  m.via=substr(m.via,8,length(m.via)-7),m.tipo_via='PIAZZA'
  where m.via like 'PIAZZA%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='PIAZZA'
  where m.via like 'P.ZZA%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='PIAZZA'
  where m.via like 'P.ZA%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,4,length(m.via)-3),m.tipo_via='PIAZZA'
  where m.via like 'P. %' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- BIVIO

  update migr_sede_secondaria m set 
  m.via=substr(m.via,7,length(m.via)-6),m.tipo_via='BIVIO'
  where m.via like 'BIVIO%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- BORGATA

  update migr_sede_secondaria m set 
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='BORGATA'
  where m.via like 'BORGATA%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- FRAZIONE
  
  update migr_sede_secondaria m set 
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='FRAZIONE'
  where m.via like 'FRAZIONE%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- REGIONE

  update migr_sede_secondaria m set 
  m.via=substr(m.via,9,length(m.via)-8),m.tipo_via='REGIONE'
  where m.via like 'REGIONE%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  -- LOCALITA

  update migr_sede_secondaria m set 
  m.via=substr(m.via,11,length(m.via)-10),m.tipo_via='LOCALITA'
  where m.via like 'LOCALITA''%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,10,length(m.via)-9),m.tipo_via='LOCALITA'
  where m.via like 'LOCALITA%' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,6,length(m.via)-5),m.tipo_via='LOCALITA'
  where m.via like 'LOC.%'
    and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;

  update migr_sede_secondaria m set 
  m.via=substr(m.via,5,length(m.via)-4),m.tipo_via='LOCALITA'
  where m.via like 'LOC %' and m.fl_migrato='N'
    and m.ente_proprietario_id=pEnte;
  commit;

  pMsgRes:= msgRes||' ' ||'Aggiornamento OK.';
  pCodRes:=codRes;
              
  exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;  
  end migrazione_agg_via_sede_sec;
  
  
    
  begin
    
    
    msgResFin:='Migrazione sede secondarie.Popolamento migr_sede_secondaria.';
    msgRes:='Pulizia migr_sede_secondaria.';
    delete migr_sede_secondaria where fl_migrato='N' and ente_proprietario_id=pEnte;
    commit;
    
    msgRes:='Lettura migr_soggetto  indir_alternativi e beneficiari.';

    -- indirizzo_principale --> 'N'
    -- tipo_indirizzo
    -- tipo_via
    tipoIndirizzo:='SEDE_LEGALE';
    tipoVia:='MIGRAZIONE';
    tipoRelazione:='SEDE_SECONDARIA';
    
    for migrSedeSecondaria in
    (select t.soggetto_id soggetto_id,t.codice_soggetto codice_soggetto,i.progben codice_modpag, i.cod_indir cod_indir,
            i.ragsoc ragione_sociale, i.descrizione descrizione,
            i.via via,i.n_civico n_civico,i.cap cap ,i.comune comune,i.prov prov, i.cod_stato cod_stato,
            i.pref1 pref1,i.tel1 tel1,i.pref2 pref2,i.tel2 tel2,i.fax fax,i.contatto contatto
     from migr_soggetto t, indir_alternativi i, beneficiari b
     where t.ente_proprietario_id=pEnte and
           t.codice_soggetto=i.codben and
           (t.delegato_id is null or t.delegato_id=0) and
           t.fl_migrato='N' and
           (i.ragsoc is not null or i.descrizione is not null) and
           i.data_cessa is null and
           b.codben  (+) = i.codben and
           b.progben (+) = i.progben and
           b.data_cessa (+) is null
     union
     select t.soggetto_id soggetto_id,t.codice_soggetto codice_soggetto,i.progben codice_modpag, i.cod_indir cod_indir,
            i.contatto ragione_sociale, null descrizione,
            i.via via,i.n_civico n_civico,i.cap cap,i.comune comune,i.prov prov, i.cod_stato cod_stato,
            i.pref1 pref1,i.tel1 tel1,i.pref2 pref2,i.tel2 tel2,i.fax fax, null contatto
     from migr_soggetto t, indir_alternativi i, beneficiari b
     where t.ente_proprietario_id=pEnte and
          t.codice_soggetto=i.codben and
           (t.delegato_id is null or t.delegato_id=0) and
           t.fl_migrato='N' and           
           i.data_cessa is null and
           i.ragsoc is null and 
           i.descrizione is null and
           i.contatto is not null and
           b.codben  (+) = i.codben and
           b.progben (+) = i.progben and
           b.data_cessa (+) is null
     union 
     select t.soggetto_id soggetto_id,f.codben codice_soggetto,0 codice_modpag,0 cod_indir, 
            f.presso_av ragione_sociale, null descrizione,
            decode(nvl(f.sedime_av,'X'),'X', f.via_av,f.sedime_av||' '||f.via_av) via,f.n_civico_av n_civico,f.cap_av cap,f.comune_av comune,f.prov_av prov, null cod_stato,
            null pref1, null tel1, null pref2,null tel2, null fax, null contatto
     from migr_soggetto t, fornitori f
     where t.ente_proprietario_id=pEnte and
          t.codice_soggetto=f.codben and      
           (t.delegato_id is null or t.delegato_id=0) and
           t.fl_migrato='N' and           
           ( f.presso_av is not null and 
             f.via_av is not null and
              (-- f.sedime_av is not null or 
                --f.via_av is not null or 
                f.n_civico_av is not null or 
                f.cap_av is not null or f.comune_av is not null or f.prov_av is not null 
              )
           )          
     order by 1,2,4,3
    ) 
    loop
       
      soggettoId:=null;
      indirizzoId:=null;
      codiceIndirizzo:=null;
      codiceModPag:=null;

      viaIndirizzo:=null;
      numCivIndirizzo:=null;
      comIndirizzo:=null;
      provIndirizzo:=null;
      statoIndirizzo:=null;
      tel1Indirizzo:=null;
      tel2Indirizzo:=null;      
      faxIndirizzo:=null;      
      contattoIndirizzo:=null;  
      ragSocialeIndirizzo:=null;    
      
       
      codRes:=0;
      msgRes:='Soggetto codice '||migrSedeSecondaria.codice_soggetto||
               'CodIndir '||migrSedeSecondaria.Cod_Indir||
               'CodiceModpag '||migrSedeSecondaria.codice_modpag||'.';
        
        
      msgRes:=msgRes||'Dati sede secondaria.';
      -- soggetto_id     
      soggettoId:=  migrSedeSecondaria.soggetto_id;
      -- codice_indirizzo
      codiceIndirizzo:= nvl(migrSedeSecondaria.Cod_Indir,0);
      codiceModPag:=nvl(migrSedeSecondaria.codice_modpag,0);
      
      esisteSedePerModPag:=0;
      if ( codiceIndirizzo!=0 and  codiceModPag!=0) then
       begin
           select nvl(count(*),0) into esisteSedePerModPag
           from migr_sede_secondaria 
           where ente_proprietario_id = pEnte 
           and soggetto_id=migrSedeSecondaria.soggetto_id
      --     and   codice_soggetto=migrSedeSecondaria.codice_soggetto
           and   codice_modpag=migrSedeSecondaria.codice_modpag
           and   codice_indirizzo is not null and codice_indirizzo!=0
           and   codice_indirizzo!=migrSedeSecondaria.cod_indir;
           
           if esisteSedePerModPag!=0 then
              codiceModPag:=0;
           end if;
           
           exception 
              when no_data_found then
                  null;
              when others then
                  codRes:=-1;
                  msgRes:='Errore in lettura verifica associazione MDP a diverse sedi '||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.';
       end;
      end if;
           
           
      if (migrSedeSecondaria.Ragione_Sociale is not null) then
       ragSocialeIndirizzo:=migrSedeSecondaria.Ragione_Sociale;
       if (migrSedeSecondaria.Descrizione is not null and 
           migrSedeSecondaria.Descrizione!=migrSedeSecondaria.Ragione_Sociale) then
           ragSocialeIndirizzo:=ragSocialeIndirizzo||' '||migrSedeSecondaria.Descrizione;
           if (length(ragSocialeIndirizzo)>150) then
              ragSocialeIndirizzo:=substr(ragSocialeIndirizzo,1,150);
           end if;
       end if;
      else ragSocialeIndirizzo:=migrSedeSecondaria.Descrizione;
      end if; 
        

      msgRes:='Dati sede secondaria.Via';
      -- via
      viaIndirizzo:=migrSedeSecondaria.via;
      -- civico
      msgRes:='Dati sede secondaria.Civico';
      if (length(migrSedeSecondaria.n_Civico)<=7) then
          numCivIndirizzo:=migrSedeSecondaria.n_Civico;
      else 
          if (viaIndirizzo is not null) then
             viaIndirizzo:=viaIndirizzo||' '||migrSedeSecondaria.n_Civico;
          end if;  
      end if;  
       
      msgRes:='Dati sede secondaria.Cap';
      -- cap
      capIndirizzo:=migrSedeSecondaria.cap;
      msgRes:='Dati indirizzo secondaria.Comune';
      -- comune
      if (migrSedeSecondaria.comune is not null) then
            begin  
             --select distinct c.des_comune||'||'||c.cod_istat into comIndirizzo
             select distinct c.des_comune||'||'||c.cod_istat||'||'||c.cod_belfiore into comIndirizzo
             from comuni c
             where c.des_comune=migrSedeSecondaria.comune and
                   ( migrSedeSecondaria.prov is null or c.prov=migrSedeSecondaria.prov ) and
                   c.flag_val=1;
             
             exception 
              when no_data_found then
                  --comIndirizzo:=migrSedeSecondaria.comune||'||';
                  comIndirizzo:=migrSedeSecondaria.comune||'||||';
              when others then
                  codRes:=-1;
                  msgRes:='Errore in lettura comune sede secondaria '||migrSedeSecondaria.comune||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.'; 
            end;      
      end if;
      msgRes:='Dati sede secondaria.Prov';
       -- prov
      if (codRes=0 and migrSedeSecondaria.prov is not null) then
              provIndirizzo:=migrSedeSecondaria.prov||'||';
      end if;
      msgRes:='Dati sede secondaria.Nazione';
      -- nazione
      if (codRes=0 and migrSedeSecondaria.Cod_Stato is not null) then
         begin
          select t.des_stato||'||'||t.cod_stato into statoIndirizzo
          from tabstati t
          where t.cod_stato=migrSedeSecondaria.cod_stato;
              
          exception 
           when no_data_found then
            statoIndirizzo:=null;
           when others then
            codRes:=-1;
            msgRes:='Errore in lettura nazione sede secondaria '||migrSedeSecondaria.cod_stato||' '||SQLCODE||'-'||SUBSTR(SQLERRM, 1, 500)||'.';
         end;
      end if;
     
     if (codRes=0 and migrSedeSecondaria.tel1 is not null ) then
        tel1Indirizzo:='SS||'||migrSedeSecondaria.pref1||migrSedeSecondaria.tel1||'||N';
     end if;

     if (codRes=0 and migrSedeSecondaria.tel2 is not null ) then
        tel2Indirizzo:='SS||'||migrSedeSecondaria.pref2||migrSedeSecondaria.tel2||'||N';
     end if;

     if (codRes=0 and migrSedeSecondaria.fax is not null ) then
        faxIndirizzo:='SS||'||migrSedeSecondaria.fax||'||N';
     end if;

     if (codRes=0 and migrSedeSecondaria.contatto is not null ) then
        contattoIndirizzo:='SS||'||'soggetto||'||migrSedeSecondaria.contatto||'||N';
     end if;

     if (codRes=0) then
        msgRes:='Inserimento in migr_sede_secondaria.';
        --- insert 
        insert into  migr_sede_secondaria
        (sede_id,soggetto_id,codice_indirizzo,codice_modpag,ragione_sociale,tipo_relazione,tipo_indirizzo,
         indirizzo_principale,tipo_via,via,numero_civico,cap,comune,prov,nazione,
         tel1,tel2,fax,contatto_generico,avviso,ente_proprietario_id
        )
        values
        (migr_sede_id_seq.nextval,soggettoId,codiceIndirizzo,codiceModPag,ragSocialeIndirizzo,
         tipoRelazione,tipoIndirizzo,
         indirizzoPrincipale,tipoVia,viaIndirizzo,numCivIndirizzo,
         capIndirizzo,comIndirizzo,provIndirizzo,statoIndirizzo,
         tel1Indirizzo,tel2Indirizzo,faxIndirizzo,contattoIndirizzo,
         flagAvviso,pEnte
        );
     end if;
     
     if (codRes=0) then
       countSede:=countSede+1;
     else  RAISE ERROR_SOGGETTO;
     end if;
          
     if (codRes=0 and countSede>1000) then
       commit;
     end if; 
      
    end loop;

        
    if (codRes=0 and countSede>0 ) then
       migrazione_agg_via_sede_sec ( pEnte,codRes,msgRes);
    end if;
    
    if (codRes=0 and countSede>0 ) then
       -- trattamento per aggiornamento sede_id su MDP 
       msgRes:='Migrazione Soggetto Sedi Secondarie.Aggiornamento sede_id su MDP.';
       update migr_modpag mdp
       set mdp.sede_id = (select ms.sede_id 
                          from migr_sede_secondaria ms 
                          where  ms.ente_proprietario_id = pEnte and
                                 ms.soggetto_id=mdp.soggetto_id and 
                                 ms.codice_modpag!=0 and ms.codice_modpag is not null and
                                 ms.codice_modpag=mdp.codice_modpag and ms.fl_migrato='N' and
                                 exists (select 1 from migr_soggetto mm 
                                         where mm.ente_proprietario_id = pEnte
                                           and mm.soggetto_id=ms.soggetto_id
                                           and ( mm.delegato_id is null or mm.delegato_id=0 ) 
                                           and mm.fl_genera_codice='N'
                                           and mm.fl_migrato='N'))  
        where mdp.sede_secondaria='S' and mdp.fl_migrato='N' and  mdp.ente_proprietario_id = pEnte ;
    end if;
    
    pCodRes:=codRes;
    if codRes=0 then
          pMsgRes:='Migrazione Soggetti-Sede Secondarie OK.[countSede]='||countSede;
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
end migrazione_soggetto_sede_sec;      


procedure migrazione_soggetto_mdp(pEnte   number,
                                  pCodRes out number,
                                  pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
begin

  msgRes:='Migrazione Soggetto MDP.Pulizia migr_modpag.';
  delete migr_modpag where fl_migrato='N' and ente_proprietario_id = pEnte;
  commit;
  
  -- MDP SENZA COLLEGAMENTO A DELEGATI
  --- MDP SENZA CESSIONE INCASSO/CREDITO SENZA SEDE SECONDARIA
  msgRes:='Migrazione Soggetto MDP.MDP senza cessione di credito/incasso senza sede secondaria.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,null,'N',
          b.codaccre,b.cod_iban,null,b.codbanca,b.codagen,
          decode(sign(length(b.codcc)-13),1, null,b.codcc),null,
          null,null,null,null,null,null,
          'VALIDO',
          ltrim(rtrim(decode(sign(length(b.codcc)-13),-1, ' ',0,' ',
                 'CC MIGRAZIONE='||b.codcc)||
          decode(b.codaccre, 'FA', 
                 ' DATI FALLIMENTO: '||
                 to_char(f.data_fallimento,'YYYY-MM-DD')||' '||f.nro_fallimento||' '||f.note_fallimento, ' '))),
          null,0,pEnte
   from migr_soggetto ms, beneficiari b, fornitori f
   where b.codben = ms.codice_soggetto and 
         b.data_cessa is null and
         ( ms.delegato_id is null or ms.delegato_id=0 ) and
         ms.ente_proprietario_id=pEnte and
         ms.fl_genera_codice='N' and
         f.codben = b.codben and
         ms.fl_migrato='N' and
         not exists (select 1 from indir_alternativi i
                     where i.codben=ms.codice_soggetto 
                     and i.codben=b.codben 
                     and i.progben=b.progben
                     and i.data_cessa is null 
                     and  ((i.ragsoc is not null or i.descrizione is not null) or 
                            (i.ragsoc is null and i.descrizione is null and i.contatto is not null)
                            )) and
         not exists (select 1 from migr_delegati d 
                     where d.codben=b.codben
                       and d.progben=b.progben
                       and d.ente_proprietario_id=pEnte)
  );
  commit;

  --- MDP SENZA CESSIONE INCASSO/CREDITO CON SEDE SECONDARIA
  msgRes:='Migrazione Soggetto MDP.MDP senza cessione di credito/incasso con sede secondaria.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,null,'S',
          b.codaccre,b.cod_iban,null,b.codbanca,b.codagen,
          decode(sign(length(b.codcc)-13),1, null,b.codcc),null,
          null,null,null,null,null,null,
          'VALIDO',
          ltrim(rtrim(decode(sign(length(b.codcc)-13),-1, ' ',0,' ',
                'CC MIGRAZIONE='||b.codcc)||
                decode(b.codaccre, 'FA', 
                      ' DATI FALLIMENTO: '||
                      to_char(f.data_fallimento,'YYYY-MM-DD')||' '||f.nro_fallimento||' '||f.note_fallimento, ' '))),
          null,0,pEnte
   from migr_soggetto ms, beneficiari b, fornitori f
   where b.codben = ms.codice_soggetto and 
         b.data_cessa is null and
         ( ms.delegato_id is null or ms.delegato_id=0 ) and
         ms.ente_proprietario_id = pEnte and
         ms.fl_genera_codice='N' and
         f.codben = b.codben and
         ms.fl_migrato='N' and
         exists (select 1 from indir_alternativi i
                 where i.codben=ms.codice_soggetto
                 and   i.codben=b.codben 
                 and i.progben=b.progben
                 and   i.data_cessa is null 
                 and  ((i.ragsoc is not null or i.descrizione is not null) or 
                            (i.ragsoc is null and i.descrizione is null and i.contatto is not null)
                       )) and
         not exists (select 1 from migr_delegati d 
                     where d.codben=b.codben
                       and d.progben=b.progben
                       and d.ente_proprietario_id = pEnte)                   
  );
  commit;

  -- aggiungere le MDP derivanti da delegati

  --- MDP SENZA CESSIONE INCASSO/CREDITO SENZA SEDE SECONDARIA
  msgRes:='Migrazione Soggetto MDP.MDP senza cessione di credito/incasso senza sede secondaria.Delegati MDP nuove.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,codice_modpag_del,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,fl_genera_codice,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,dd.progdel,null,'N',
          b.codaccre,
          decode(d.fl_intest,'S', b.cod_iban,null),null,
          decode(d.fl_intest,'S',b.codbanca,null),
          decode(d.fl_intest,'S',b.codagen,null),
          decode(d.fl_intest,'S',decode(sign(length(b.codcc)-13),1, null,b.codcc),null),
          decode(d.fl_intest,'S',dd.ragsoc,null),
          decode(d.fl_quiet,'S',dd.ragsoc,null),
          decode(d.fl_quiet,'S',dd.codfisc_partiva,null),
          decode(d.fl_intest,'S',dd.codfisc_partiva,null),
          --decode(d.fl_intest,'S',dd.dtns,
          --      decode(d.fl_quiet,'S',dd.dtns,null),null),
          to_char(decode(d.fl_intest,'S',dd.dtns,
                decode(d.fl_quiet,'S',dd.dtns,null),null),'yyyy-mm-dd'),
          decode(d.fl_intest,'S',dd.documento,
                decode(d.fl_quiet,'S',dd.documento,null),null),                      
          decode(d.fl_intest,'S',dd.stns,
                decode(d.fl_quiet,'S',dd.stns,null),null),                      
          'VALIDO',
          ltrim(rtrim(decode(sign(length(b.codcc)-13),-1, ' ',0,' ',
                 'CC MIGRAZIONE='||b.codcc)||
           decode(b.codaccre, 'FA', 
                 ' DATI FALLIMENTO: '||
                 to_char(f.data_fallimento,'YYYY-MM-DD')||' '||f.nro_fallimento||' '||f.note_fallimento, ' '))),
          null,d.delegato_id,'S', pEnte
   from migr_soggetto ms, beneficiari b, fornitori f, migr_delegati d, delegati dd
   where b.codben = ms.codice_soggetto and 
         b.data_cessa is null and
         f.codben = b.codben and
         d.codben=b.codben and
         d.progben=b.progben and
         d.tipo='MDP' and
         dd.codben=d.codben and
         dd.progben=d.progben and
         dd.progdel=d.progdel and
        ( ms.delegato_id is null or ms.delegato_id=0 ) and
         ms.fl_genera_codice='N' and
         ms.fl_migrato='N' and
         ms.ente_proprietario_id = pEnte and
         d.ente_proprietario_id = pEnte and
         not exists (select 1 from indir_alternativi i
                     where i.codben=ms.codice_soggetto 
                     and   i.codben=b.codben 
                     and i.progben=b.progben
                     and   i.data_cessa is null 
                     and  ((i.ragsoc is not null or i.descrizione is not null) or 
                            (i.ragsoc is null and i.descrizione is null and i.contatto is not null)
                            ))                   
  );
  commit;
  
  --- MDP SENZA CESSIONE INCASSO/CREDITO CON SEDE SECONDARIA
  msgRes:='Migrazione Soggetto MDP.MDP senza cessione di credito/incasso con sede secondaria.Delegati MDP nuove.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,codice_modpag_del,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,fl_genera_codice,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,dd.progdel,null,'S',
          b.codaccre,
          decode(d.fl_intest,'S', b.cod_iban,null),null,
          decode(d.fl_intest,'S',b.codbanca,null),
          decode(d.fl_intest,'S',b.codagen,null),
          decode(d.fl_intest,'S',decode(sign(length(b.codcc)-13),1, null,b.codcc),null),
          decode(d.fl_intest,'S',dd.ragsoc,null),
          decode(d.fl_quiet,'S',dd.ragsoc,null),
          decode(d.fl_quiet,'S',dd.codfisc_partiva,null),
          decode(d.fl_intest,'S',dd.codfisc_partiva,null),
          --decode(d.fl_intest,'S',dd.dtns,
            --    decode(d.fl_quiet,'S',dd.dtns,null),null),
          to_char(decode(d.fl_intest,'S',dd.dtns,
                decode(d.fl_quiet,'S',dd.dtns,null),null),'yyyy-mm-dd'),  
          decode(d.fl_intest,'S',dd.documento,
                decode(d.fl_quiet,'S',dd.documento,null),null),                      
          decode(d.fl_intest,'S',dd.stns,
                decode(d.fl_quiet,'S',dd.stns,null),null),                      
          'VALIDO',
           ltrim(rtrim(decode(sign(length(b.codcc)-13),-1, ' ',0,' ',
                 'CC MIGRAZIONE='||b.codcc)||
           decode(b.codaccre, 'FA', 
                 ' DATI FALLIMENTO: '||
                 to_char(f.data_fallimento,'YYYY-MM-DD')||' '||f.nro_fallimento||' '||f.note_fallimento, ' '))),
          null,d.delegato_id,'S', pEnte
   from migr_soggetto ms, beneficiari b, fornitori f, migr_delegati d, delegati dd
   where b.codben = ms.codice_soggetto and 
         b.data_cessa is null and
         f.codben = b.codben and
         d.codben=b.codben and
         d.progben=b.progben and
         d.tipo='MDP' and
         dd.codben=d.codben and
         dd.progben=d.progben and
         dd.progdel=d.progdel and
         ( ms.delegato_id is null or ms.delegato_id=0 ) and
         ms.fl_genera_codice='N' and
         ms.fl_migrato='N' and
         ms.ente_proprietario_id = pEnte and
         d.ente_proprietario_id = pEnte and
         exists (select 1 from indir_alternativi i
                 where i.codben=ms.codice_soggetto 
                 and   i.codben=b.codben 
                 and i.progben=b.progben
                 and i.data_cessa is null 
                 and ((i.ragsoc is not null or i.descrizione is not null) or 
                         (i.ragsoc is null and i.descrizione is null and i.contatto is not null)
                         ))                   
  );
  commit;
    
  --- MDP CESSIONE INCASSO/CREDITO SENZA SEDE SECONDARIA - MDP del soggetto di origine
  msgRes:='Migrazione Soggetto MDP.MDP con cessione di credito/incasso senza sede secondaria.Soggetti cedenti.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,codice_modpag_del,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,fl_genera_codice,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,d.progdel,d.tipo_relazione,'N',
          b.codaccre,
          null,null,null,null,null,null,
          null,null,null,null,null,null,                      
          'VALIDO',null,null,d.delegato_id,'N', pEnte
   from migr_soggetto ms, beneficiari b, fornitori f, migr_delegati d
   where b.codben = ms.codice_soggetto and 
         b.data_cessa is null and
         f.codben = b.codben and
         d.codben=b.codben and
         d.progben=b.progben and
         d.tipo='SO' and
        ( ms.delegato_id is null or ms.delegato_id=0 ) and
         ms.fl_genera_codice='N' and
         ms.fl_migrato='N' and
         ms.ente_proprietario_id = pEnte and
         d.ente_proprietario_id = pEnte and         
         not exists (select 1 from indir_alternativi i
                     where i.codben=ms.codice_soggetto 
                     and   i.codben=b.codben 
                     and i.progben=b.progben
                     and   i.data_cessa is null 
                     and  ((i.ragsoc is not null or i.descrizione is not null) or 
                            (i.ragsoc is null and i.descrizione is null and i.contatto is not null)
                            ))                   
  );
  commit;
  
  --- MDP CESSIONE INCASSO/CREDITO CON SEDE SECONDARIA - MDP del soggetto di origine
  msgRes:='Migrazione Soggetto MDP.MDP con cessione di credito/incasso con sede secondaria.Soggetti cedenti.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,codice_modpag_del,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,fl_genera_codice,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,d.progdel,d.tipo_relazione,'S',
          b.codaccre,
          null,null,null,null,null,null,
          null,null,null,null,null,null,                      
          'VALIDO',null,null,d.delegato_id,'N', pEnte
   from migr_soggetto ms, beneficiari b, fornitori f, migr_delegati d
   where b.codben = ms.codice_soggetto and 
         b.data_cessa is null and
         f.codben = b.codben and
         d.codben=b.codben and
         d.progben=b.progben and
         d.tipo='SO' and
         ( ms.delegato_id is null or ms.delegato_id=0 ) and
         ms.fl_genera_codice='N' and
         ms.fl_migrato='N' and
         ms.ente_proprietario_id = pEnte and
         d.ente_proprietario_id = pEnte and
         exists (select 1 from indir_alternativi i
                 where i.codben=ms.codice_soggetto 
                 and   i.codben=b.codben 
                 and   i.progben=b.progben
                 and   i.data_cessa is null 
                 and  ((i.ragsoc is not null or i.descrizione is not null) or 
                            (i.ragsoc is null and i.descrizione is null and i.contatto is not null)
                            ))                   
  );
  commit;
  
  --- MDP CESSIONE INCASSO/CREDITO [SENZA SEDE SECONDARIA . non serve controllare queste non avranno sede sec]
  --- MDP del soggetto ceduto , in questo caso il codaccre resta sulla MDP del soggetto cedente
  --- quindi sulle nuove MDP del ceduto � impostato CB in caso di presenza di cod_iban, diversamente un codaccre
  --- di cassa , non volenvo fissare CT, si imposta CR - CONTANTI IN CIRCOLARITA
  msgRes:='Migrazione Soggetto MDP.MDP con cessione di credito/incasso senza sede secondaria.Soggetti ceduti.';
  insert into migr_modpag
  (modpag_id,soggetto_id,sede_id,codice_modpag,codice_modpag_del,cessione,sede_secondaria,
   codice_accredito,iban,bic,abi,cab,conto_corrente,
   conto_corrente_intest, 
   quietanzante,codice_fiscale_quiet,
   codice_fiscale_del,
   data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
   stato_modpag,note,email,delegato_id,fl_genera_codice,ente_proprietario_id)
  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,d.progdel,null,'N',
          decode(nvl(b.cod_iban,'X'),'X','CR','CB'),
          decode(nvl(b.cod_iban,'X'),'X',null,b.cod_iban),null,
          decode(nvl(b.cod_iban,'X'),'X',null,b.codbanca),
          decode(nvl(b.cod_iban,'X'),'X',null,b.codagen),
          decode(nvl(b.cod_iban,'X'),'X',null,decode(sign(length(b.codcc)-13),1, null,b.codcc)),null,
          null,null,null,null,null,null,                  
          'VALIDO',
          decode(nvl(b.cod_iban,'X'),'X',null,
                 decode(sign(length(b.codcc)-13),-1, ' ',0,' ',
                 'CC MIGRAZIONE='||b.codcc)),
          null,d.delegato_id,'S', pEnte
   from migr_soggetto ms, beneficiari b, fornitori f, migr_delegati d
   where b.codben = ms.codice_soggetto and 
         b.data_cessa is null and
         f.codben = b.codben and
         d.codben=b.codben and
         d.progben=b.progben and
         d.tipo='SO' and
         ms.delegato_id is not null and
         ms.delegato_id!=0 and
         ms.fl_genera_codice='S' and
         ms.fl_migrato='N' and
         ms.delegato_id=d.delegato_id and
         ms.ente_proprietario_id = pEnte and
         d.ente_proprietario_id = pEnte
--         not exists (select 1 from indir_alternativi i
--                     where i.codben=ms.codice_soggetto and i.codben=b.codben and i.data_cessa is null and
--                           ((i.ragsoc is not null or i.descrizione is not null) or 
--                            (i.ragsoc is null and i.descrizione is null and i.contatto is not null)
--                            ))                   
  );
  commit;

  --- MDP CESSIONE INCASSO/CREDITO CON SEDE SECONDARIA - MDP del soggetto ceduto
 -- msgRes:='Migrazione Soggetto MDP.MDP con cessione di credito/incasso con sede secondaria.Soggetti ceduti.';
 -- insert into migr_modpag
 -- (modpag_id,soggetto_id,sede_id,codice_modpag,cessione,sede_secondaria,
  -- codice_accredito,iban,bic,abi,cab,conto_corrente,
 --  conto_corrente_intest, 
 --  quietanzante,codice_fiscale_quiet,
  -- codice_fiscale_del,
 --  data_nascita_qdel,luogo_nascita_qdel,stato_nascita_qdel,
 --  stato_modpag,note,email,delegato_id,fl_genera_codice,ente_proprietario_id)
--  (select migr_modpag_id_seq.nextval,ms.soggetto_id,null,b.progben,null,'S',
--          decode(nvl(b.cod_iban,'X'),'X','CT','CB'),
 --         decode(nvl(b.cod_iban,'X'),'X',null,b.cod_iban),null,
 ----         decode(nvl(b.cod_iban,'X'),'X',null,b.abi),
 --         decode(nvl(b.cod_iban,'X'),'X',null,b.cab),
 --         decode(nvl(b.cod_iban,'X'),'X',null,b.codcc),null,
 --         null,null,null,null,null,null,null,                      
 --         'VALIDO',null,null,d.delegato_id,'S', pEnte
 --  from migr_soggetto ms, beneficiari b, fornitori f, migr_delegati d
 --  where b.codben = ms.codice_soggetto and 
 --        b.data_cessa is null and
 --        f.codben = b.codben and
  --       d.codben=b.codben and
 --        d.progben=b.progben and
 --        d.tipo='SO' and
--         ms.delegato_id is not null and
 --        ms.fl_genera_codice='S' and
 --        ms.fl_migrato='N' and
 --        exists (select 1 from indir_alternativi i
 --                where i.codben=ms.codice_soggetto and i.codben=b.codben and i.data_cessa is null and
 --                     ((i.ragsoc is not null or i.descrizione is not null) or 
  --                     (i.ragsoc is null and i.descrizione is null and i.contatto is not null)
  --                     ))                   
  --);
  --commit;

  
  pMsgRes:= 'Migrazione Soggetto MDP OK.';
  pCodRes:=codRes;
  
 
exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;  
end migrazione_soggetto_mdp;

procedure migrazione_soggetto_relaz   (pEnte   number,
                                       pCodRes out number,
                                       pMsgRes out varchar2) is
  msgRes            varchar2(1500) := null;
  codRes            integer := 0;
begin

  msgRes:='Migrazione Soggetto Relaz. Pulizia migr_relaz_soggetto.';
  delete migr_relaz_soggetto where fl_migrato='N' and ente_proprietario_id = pEnte;
  commit;
  
  msgRes:='Migrazione Soggetto Relaz Cessione Incasso.';
  insert into migr_relaz_soggetto
  (tipo_relazione,relaz_id,soggetto_id_da,modpag_id_da,soggetto_id_a,modpag_id_a,ente_proprietario_id)
  (select 'CSI',migr_relaz_id_seq.nextval ,md.soggetto_id,md.modpag_id,mo1.soggetto_id,md1.modpag_id,pEnte
   from migr_modpag md, migr_soggetto mo,  migr_soggetto mo1, migr_modpag md1
   where md.ente_proprietario_id = pEnte and
         md.cessione is not null and
         md.cessione='CSI' and 
         md.fl_migrato='N' and
         md.delegato_id is not null and
         md.delegato_id!=0 and
         md.fl_genera_codice='N' and
         mo.soggetto_id=md.soggetto_id and
         ( mo.delegato_id is null or mo.delegato_id=0) and
         mo.fl_genera_codice='N' and
         mo.fl_migrato='N' and
         mo.ente_proprietario_id = pEnte and
         mo1.codice_soggetto=mo.codice_soggetto and
         mo1.delegato_id is not null and mo1.delegato_id!=0 and
         mo1.fl_genera_codice='S' and
         mo1.ente_proprietario_id = pEnte and
         mo1.delegato_id=md.delegato_id and
         md1.soggetto_id=mo1.soggetto_id and
         md1.delegato_id is not null and md1.delegato_id!=0 and
         md1.delegato_id=mo1.delegato_id and
         md1.ente_proprietario_id = pEnte); 
  commit;
  
  --  msgRes:='Migrazione Soggetto Relaz Cessione Credito.';
  -- non dovrebbero essercene
  
  -- Sofia 26.02.015 CATENE verificare se passare anche le relazioni tra lo stesso soggetto
  -- Sofia 02.03.015 Mail di Silvia T. dice di non passare relazioni tra stesso soggetto
  msgRes:='Migrazione Soggetto Relaz Catena Storico.';
   
  insert into migr_relaz_soggetto
  (tipo_relazione,relaz_id,soggetto_id_da,modpag_id_da,soggetto_id_a,modpag_id_a,ente_proprietario_id)
  (select 'CATENA',migr_relaz_id_seq.nextval ,old.soggetto_id,0,new.soggetto_id,0,pEnte
   from  migr_soggetto new,  migr_soggetto old, forn_storico_ragsoc cat
   where  new.ente_proprietario_id = pEnte and
          old.ente_proprietario_id = pEnte and
          new.fl_genera_codice='N' and
          old.fl_genera_codice='N' and
          cat.nuovo_codben!=cat.vecchio_codben and
          cat.nuovo_codben=new.codice_soggetto and
          cat.vecchio_codben=old.codice_soggetto );
  commit;
    
    pMsgRes:= 'Migrazione Soggetto Relaz OK.';
    pCodRes:=codRes;
  

exception
    when others then
      pMsgRes    := msgRes || ' ' || SQLCODE || '-' || SUBSTR(SQLERRM, 1, 500) || '.';
      pCodRes    := -1;
      rollback;  
end  migrazione_soggetto_relaz;


 procedure migrazione_soggetti(pEnte           number,
                               pAnnoEsercizio varchar2,
                               pAnni           number,
                               pCodRes out number,
                               pMsgRes out varchar2) is
 msgRes            varchar2(1500) := null;
 codRes            integer := 0;
 ERROR_SOGGETTO EXCEPTION;
 begin
   
 -- popolamento migr_soggetto_temp
 migrazione_soggetto_temp(pEnte,pAnnoEsercizio,pAnni,
                          codRes,msgRes);
 if (codRes!=0) then
   raise ERROR_SOGGETTO;
 end if;                     
 
 -- popolamento migr_soggetto    
 migrazione_soggetto(pEnte,codRes,msgRes);
 if (codRes!=0) then
   raise ERROR_SOGGETTO;
 end if;
 
 -- popolamento migr_indirizzo_secondario
 migrazione_indirizzo_second(pEnte,codRes,msgRes);
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

 
 -- popolamento migr_sede_secondaria
 migrazione_soggetto_sede_sec(pEnte,codRes,msgRes);
 if (codRes!=0) then
   raise ERROR_SOGGETTO;
 end if;
 
 -- popolamento migr_relaz_soggetto [da fare]                                       
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
