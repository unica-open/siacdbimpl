CREATE OR REPLACE PACKAGE PCK_MIGRAZIONE_SOGGETTI_SIAC AS
  -- costanti
  -- modalità di accredito note RegP
  CODACCRE_CB CONSTANT VARCHAR2(2) := 'CB'; --  'bonifico bancario CB'
  CODACCRE_BP CONSTANT VARCHAR2(2) := 'BP'; --  'bonifico postale CB'

  -- 08.08.014 Aipo -- CSC
  CODACCRE_BD CONSTANT VARCHAR2(2) := 'BD'; --  'BONIFICO POSTALE DEDICATO' 'CSC' 'BONIFICO'
  CODACCRE_CD CONSTANT VARCHAR2(2) := 'CD'; --  'CC BANCARIO DEDICATO' 'CSC' 'BONIFICO'

  -- 08.08.014 Aipo

  CODACCRE_AB CONSTANT VARCHAR2(2) := 'AB'; -- 'assegno traenza CO'   -- Come da indicazioni di MC passate come CO
  CODACCRE_AC CONSTANT VARCHAR2(2) := 'AC'; -- 'assegno circolare CO' -- Come da indicazioni di MC passate come CO
  CODACCRE_AS CONSTANT VARCHAR2(2) := 'AS'; -- 'assegno circolare CO' -- Come da indicazioni di MC passate come CO

  CODACCRE_CT CONSTANT VARCHAR2(2) := 'CT'; -- 'contanti CO'

  CODACCRE_F2 CONSTANT VARCHAR2(2) := 'F2'; -- 'contanti CO'
  CODACCRE_F3 CONSTANT VARCHAR2(2) := 'F3'; -- 'contanti CO'
  CODACCRE_FI CONSTANT VARCHAR2(2) := 'FI'; -- 'contanti CO'
  CODACCRE_RI CONSTANT VARCHAR2(2) := 'RI'; -- 'contanti CO'

  -- 08.08.014 Aipo
  CODACCRE_AI CONSTANT VARCHAR2(2) := 'AI'; -- 'ACCANTONAMENTO (IRPEF - INPDAP)' -- 'CO'
  CODACCRE_AP CONSTANT VARCHAR2(2) := 'AP'; -- 'ALLEGATO PROSPETTO' -- 'CO'
  CODACCRE_AV CONSTANT VARCHAR2(2) := 'AV'; -- 'ACCANTONAMENTI VARI' -- 'CO'
  CODACCRE_CE CONSTANT VARCHAR2(2) := 'CE'; -- 'CONTABILITA DI ENTRATA' -- 'CO'
  CODACCRE_CI CONSTANT VARCHAR2(2) := 'CI'; -- 'CASSA INTERNA' -- ' CO'
  CODACCRE_DP CONSTANT VARCHAR2(2) := 'DP'; -- 'MOD. CASSA DEPOSITI E PRESTITI' -- 'CO'
  CODACCRE_MF CONSTANT VARCHAR2(2) := 'MF'; -- 'TRAMITE MOD. F23' -- 'CO'
  CODACCRE_PC CONSTANT VARCHAR2(2) := 'PC'; -- 'PER CASSA' -- 'CO'
  CODACCRE_TE CONSTANT VARCHAR2(2) := 'TE'; -- 'F24 TELEMATICO TRAMITE ENTRATEL' -- 'CO'
  CODACCRE_TT CONSTANT VARCHAR2(2) := 'TT'; -- 'TRAMITE TESORIERE' --'CO'
  CODACCRE_QT CONSTANT VARCHAR2(2) := 'QT'; -- 'NON UTILIZZARE - CONTO DI TESORERIA' ---'CO'
  CODACCRE_TC CONSTANT VARCHAR2(2) := 'TC'; -- 'IN ESSERE PRESSO TESORERIA CENTRALE' ---'CO'

  CODACCRE_CP CONSTANT VARCHAR2(2) := 'CP'; -- 'conto corrente postale CCP'
  -- 28.08.014 Aipo
  CODACCRE_PP CONSTANT VARCHAR2(2) := 'PP'; -- 'BOLLETTINI POSTALI PRESTAMPATI DALL ENTE E DA ALTRI ENTI' ---'CCP'

  CODACCRE_CC CONSTANT VARCHAR2(2) := 'CC'; -- 'cessione incasso CSI'
  CODACCRE_PE CONSTANT VARCHAR2(2) := 'PE'; -- 'cessione incasso CSI'

  CODACCRE_GF CONSTANT VARCHAR2(2) := 'GF'; -- 'banca italia CBI'

  -- DAVIDE aggiunti accrediti per Crp
  CODACCRE_AD CONSTANT VARCHAR2(2) := 'AD'; -- 'ASSEGNO CIRCOLARE-DA INVIARE A DOMICILIO' -- 'CO'
  CODACCRE_BE CONSTANT VARCHAR2(2) := 'BE'; -- 'PAGAMENTO ESTERO (VEDI FOGLIO ALLEGATO)' -- 'GE'
  CODACCRE_FT CONSTANT VARCHAR2(2) := 'FT'; -- 'F24-TELEMATICO' -- 'GE'
  CODACCRE_GC CONSTANT VARCHAR2(2) := 'GC'; -- 'GIROCONTO' -- 'GE'
  CODACCRE_QD CONSTANT VARCHAR2(2) := 'QD'; -- 'NON USARE QUIETANZA DIRETTA' -- 'GE'
  CODACCRE_SP CONSTANT VARCHAR2(2) := 'SP'; -- 'SPORTELLO' -- 'GE'
  -- DAVIDE FINE

  -- DAVIDE aggiunti accrediti per Edisu
  CODACCRE_LA CONSTANT VARCHAR2(2) := 'LA'; -- 'MANDATO CON LISTA ALLEGATA' -- 'GE'
  CODACCRE_MV CONSTANT VARCHAR2(2) := 'MV'; -- 'MAV' -- 'GE'
  CODACCRE_TB CONSTANT VARCHAR2(2) := 'TB'; -- 'TESORERIA - BOLLETTINO POSTALE ALLEGATO' -- 'GE'
  -- DAVIDE FINE

  -- DAVIDE aggiunti accrediti per Arpea
  CODACCRE_ST CONSTANT VARCHAR2(2) := 'ST'; -- 'STIPENDI - A COPERTURA' -- 'GE'
  -- DAVIDE FINE

  -- DAVIDE aggiunti accrediti per Parchi 
  CODACCRE_AE CONSTANT VARCHAR2(2) := 'AE'; -- 'F24EP A COPERTURA' -- 'GE'
  CODACCRE_BA CONSTANT VARCHAR2(2) := 'BA'; -- 'BOLLETTINO ALLEGATO' -- 'GE'
  CODACCRE_DA CONSTANT VARCHAR2(2) := 'DA'; -- 'DISTINTA ALLEGATA' -- 'GE'
  CODACCRE_EA CONSTANT VARCHAR2(2) := 'EA'; -- 'EMISSIONE ASSEGNO CIRCOLARE DA CONSEGNARSI ALLA DIPENDENTE BENZO ANNARITA' -- 'GE'
  CODACCRE_PO CONSTANT VARCHAR2(2) := 'PO'; -- 'PAGAMENTO ONLINE - F24' -- 'GE'
  CODACCRE_RB CONSTANT VARCHAR2(2) := 'RB'; -- 'RI.BA. RICEVUTA BANCARIA' -- 'GE'
  CODACCRE_RD CONSTANT VARCHAR2(2) := 'RD'; -- 'PAGAMENTO MEDIANTE R.I.D.' -- 'GE'
  CODACCRE_SE CONSTANT VARCHAR2(2) := 'SE'; -- 'SEPA DIRECT DEBIT' -- 'GE'
  CODACCRE_TS CONSTANT VARCHAR2(2) := 'TS'; -- 'CONTABILITA' SPECIALE - TESORERIA STATALE' -- 'GE'
  CODACCRE_F4 CONSTANT VARCHAR2(2) := 'F4'; -- 'F23' -- 'GE'
  CODACCRE_FV CONSTANT VARCHAR2(2) := 'FV'; -- 'F24 EP - SCADENZA ___/___/___' -- 'GE'
  CODACCRE_GI CONSTANT VARCHAR2(2) := 'GI'; -- 'GIROCONTO BANCA ITALIA - TABELLA A-INFRUTTIFERO' -- 'GE'
  CODACCRE_IE CONSTANT VARCHAR2(2) := 'IE'; -- 'F24 CARTACEO' -- 'GE'
  CODACCRE_CA CONSTANT VARCHAR2(2) := 'CA'; -- 'PRONTA CASSA' -- 'GE'
  CODACCRE_GG CONSTANT VARCHAR2(2) := 'GG'; -- 'GIROFONDI AT0300234' -- 'GE'
  CODACCRE_GR CONSTANT VARCHAR2(2) := 'GR'; -- 'GIROFONDI 60982' -- 'GE'
  CODACCRE_RE CONSTANT VARCHAR2(2) := 'RE'; -- 'REGOLARIZZO ALLE PARTITE PENDENTI' -- 'GE'
  CODACCRE_RA CONSTANT VARCHAR2(2) := 'RA'; -- 'RAV' -- 'GE'
  CODACCRE_BB CONSTANT VARCHAR2(2) := 'BB'; -- 'BONIFICO' -- 'GE'
  CODACCRE_GB CONSTANT VARCHAR2(2) := 'GB'; -- 'GIROCONTO CONTABILITA'SPECIALE' -- 'GE'
  CODACCRE_SS CONSTANT VARCHAR2(2) := 'SS'; -- 'SPORTELLO' -- 'GE'
  CODACCRE_AT CONSTANT VARCHAR2(2) := 'AT'; -- 'ASSEGNO DI TRAENZA' -- 'GE'
  CODACCRE_CS CONSTANT VARCHAR2(2) := 'CS'; -- 'CONTABILITA' SPECIALE DI GIROFONDI' -- 'GE'
  CODACCRE_EP CONSTANT VARCHAR2(2) := 'EP'; -- 'F24 EP' -- 'GE'
  CODACCRE_MP CONSTANT VARCHAR2(2) := 'MP'; -- 'MANDATO DI PAGAMENTO' -- 'GE'
  CODACCRE_ID CONSTANT VARCHAR2(2) := 'ID'; -- 'DOMICILIAZIONE BANCARIA' -- 'GE'
  CODACCRE_BL CONSTANT VARCHAR2(2) := 'BL'; -- 'BOLLETTINO POSTALE' -- 'GE'
  CODACCRE_DC CONSTANT VARCHAR2(2) := 'DC'; -- 'DOMICILIAZIONE BANCARIA' -- 'GE'
  CODACCRE_DM CONSTANT VARCHAR2(2) := 'DM'; -- 'DISTINTA MENSILE' -- 'GE'
  CODACCRE_EU CONSTANT VARCHAR2(2) := 'EU'; -- 'CONTANTI' -- 'GE'
  CODACCRE_MA CONSTANT VARCHAR2(2) := 'MA'; -- 'M.AV. ELETTRONICO BANCARIO' -- 'GE'
  CODACCRE_VT CONSTANT VARCHAR2(2) := 'VT'; -- 'VERSAMENTO PRESSO TESORERIA STATO' -- 'GE'
  -- DAVIDE FINE

  -- DAVIDE aggiunti accrediti per Apl, Arai
  CODACCRE_DB CONSTANT VARCHAR2(2) := 'DB'; -- 'DISPOSIZIONE BANCARIA - STIPENDI -' -- 'GE'
  CODACCRE_D3 CONSTANT VARCHAR2(2) := 'D3'; -- 'MODELLO 124 T' -- 'GE'
  CODACCRE_MD CONSTANT VARCHAR2(2) := 'MD'; -- 'MODELLO F24/ACCISE TELEMATICO TRAMITE ENTRATEL' -- 'GE'
  CODACCRE_MS CONSTANT VARCHAR2(2) := 'MS'; -- 'PER CASSA CON F24 SEMPLIFICATO' -- 'GE'
  CODACCRE_RC CONSTANT VARCHAR2(2) := 'RC'; -- 'REGOLARIZZAZIONE PAGAMENTO CARTA CONTABILE' -- 'GE'
  CODACCRE_RP CONSTANT VARCHAR2(2) := 'RP'; -- 'REGOLARIZZAZIONE PROVVISORIO' -- 'GE'
  CODACCRE_CO CONSTANT VARCHAR2(2) := 'CO'; -- 'A COMPENSAZIONE' -- 'GE'
  CODACCRE_CR CONSTANT VARCHAR2(2) := 'CR'; -- 'A COPERTURA C/CREDITO' -- 'GE'
  CODACCRE_PR CONSTANT VARCHAR2(2) := 'PR'; -- 'PROVVISORIO PER  F24 ON-LINE' -- 'GE'
  CODACCRE_QP CONSTANT VARCHAR2(2) := 'QP'; -- 'QUIETANZA DIRETTA PER CARTA PREPAGATA A MANI DI MICCINESI O MARCHISIO' -- 'CO'
  CODACCRE_VA CONSTANT VARCHAR2(2) := 'VA'; -- 'VEDI DISTINTA ALLEGATA' -- 'GE'
  CODACCRE_WU CONSTANT VARCHAR2(2) := 'WU'; -- 'QUIETANZA DIRETTA A MANI MICCINESI/MARCHISIO' -- 'GE'
  -- DAVIDE FINE

  -- nature giuridiche RegP
  -- PF_NATGIU CONSTANT VARCHAR2(2) := 'PF';   -- 'persona fisica'
  DG_NATGIU CONSTANT VARCHAR2(2) := 'DG'; -- 'ditta generica'
  EN_NATGIU CONSTANT VARCHAR2(2) := 'EN'; -- 'ente generico'
  PN_NATGIU CONSTANT VARCHAR2(2) := 'PN'; -- 'persona non fisica'
  SP_NATGIU CONSTANT VARCHAR2(2) := 'SP'; -- 'studio professionale'
  -- nature giuridiche Aipo
  SC_NATGIU CONSTANT VARCHAR2(2) := 'SC'; -- '--'
  SN_NATGIU CONSTANT VARCHAR2(2) := 'SN'; -- '--'
  -- DAVIDE aggiunte nature giuridiche per Parchi
  AS_NATGIU CONSTANT VARCHAR2(2) := 'AS'; -- 'Associazione'
  EP_NATGIU CONSTANT VARCHAR2(2) := 'EP'; -- 'Ente Previdenziale'
  SI_NATGIU CONSTANT VARCHAR2(2) := 'SI'; -- 'Sindacati'
  -- DAVIDE FINE

  -- tipo_soggetto Siac
  PFI_NATGIU CONSTANT VARCHAR2(3) := 'PFI'; -- 'persona fisica con Iva'
  PF_NATGIU  CONSTANT VARCHAR2(2) := 'PF'; -- 'persona fisica senza Iva'
  PGI_NATGIU CONSTANT VARCHAR2(3) := 'PGI'; -- 'persona giuridica con Iva'
  PG_NATGIU  CONSTANT VARCHAR2(2) := 'PG'; -- 'persona giuridica senza Iva'

  -- tipologie di mod.accredito Siac
  SIAC_TIPOACCRE_CB  CONSTANT VARCHAR2(2) := 'CB'; -- 'bonifico bancario CB'
  SIAC_TIPOACCRE_CO  CONSTANT VARCHAR2(2) := 'CO'; -- 'contanti CO'
  SIAC_TIPOACCRE_CBI CONSTANT VARCHAR2(3) := 'CBI'; -- 'banca italia CBI'
  SIAC_TIPOACCRE_CCP CONSTANT VARCHAR2(3) := 'CCP'; -- 'conto corrente postale CCP'
  SIAC_TIPOACCRE_CSC CONSTANT VARCHAR2(3) := 'CSC'; -- 'cessione credito CSC'
  SIAC_TIPOACCRE_CSI CONSTANT VARCHAR2(3) := 'CSI'; -- 'cessione incasso CSI'
  SIAC_TIPOACCRE_ND  CONSTANT VARCHAR2(2) := 'ND'; -- 'non definito'

  -- DAVIDE : AGGIUNTA GRUPPO ACCREDITO SIAC GE
  SIAC_TIPOACCRE_GE  CONSTANT VARCHAR2(2) := 'GE'; -- 'generica'


  --- procedure - funciont
  function fnc_migrazione_mod_accredito(p_ente_proprietario_id number,
                                        p_msg_res              out varchar2)
    return number;

  procedure migrazione_soggetto_temp(p_ente           number,
                                     p_anno_esercizio varchar2,
                                     p_anni           number,
                                     pCodRes          out number,
                                     pMsgRes          out varchar2);
  procedure migrazione_soggetto(pEnte   number,
                                pCodRes out number,
                                pMsgRes out varchar2);

  procedure migrazione_soggetto_classe(pEnte   number,
                                       pCodRes out number,
                                       pMsgRes out varchar2);

  procedure migrazione_soggetto_mdp(pEnte   number,
                                    pAnnoEsercizio varchar2,
                                    pCodRes out number,
                                    pMsgRes out varchar2);

  procedure migrazione_soggetto_sede_sec(pEnte   number,
                                         pCodRes out number,
                                         pMsgRes out varchar2);

  procedure migrazione_soggetto_relaz   (pEnte   number,
                                         pCodRes out number,
                                         pMsgRes out varchar2);
-- procedura cappello per la migrazione dei soggetti
  procedure migrazione_soggetti(pEnte  number, pAnnoEsercizio varchar2, pAnni  number, pCodRes out number, pMsgRes out varchar2);

END;
/
