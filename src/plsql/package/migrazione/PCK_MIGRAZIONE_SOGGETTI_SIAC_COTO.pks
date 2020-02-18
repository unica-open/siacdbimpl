CREATE OR REPLACE PACKAGE PCK_MIGRAZIONE_SOGGETTI_SIAC AS

  -- costanti
  -- CB - conto corrente bancario
  CODACCRE_CB CONSTANT VARCHAR2(2) := 'CB'; -- conto corrente bancario
  CODACCRE_LR CONSTANT VARCHAR2(2) := 'LR'; -- libretto di risparmio

  
  -- CO - contanti
  CODACCRE_CT CONSTANT VARCHAR2(2) := 'CT'; -- contanti [quietanza]
  CODACCRE_CR CONSTANT VARCHAR2(2) := 'CR'; -- circolarita'' contanti
  CODACCRE_AP CONSTANT VARCHAR2(2) := 'AP'; -- assegno postale localizzato
  
  CODACCRE_AC CONSTANT VARCHAR2(2) := 'AC'; -- assegno circolare
  CODACCRE_AB CONSTANT VARCHAR2(2) := 'AB'; -- assegno bancario
  CODACCRE_AT CONSTANT VARCHAR2(2) := 'AT'; -- assegno traenza
  CODACCRE_TC CONSTANT VARCHAR2(2) := 'TC'; -- tesoriere civico
  CODACCRE_F3 CONSTANT VARCHAR2(2) := 'F3'; -- modello F23
  CODACCRE_F4 CONSTANT VARCHAR2(2) := 'F4'; -- modello F24
  CODACCRE_PE CONSTANT VARCHAR2(2) := 'PE'; -- diritto di pegno
  CODACCRE_PA CONSTANT VARCHAR2(2) := 'PA'; -- pagamenti esteri
  CODACCRE_DM CONSTANT VARCHAR2(2) := 'DM'; -- MODELLO DM10
  CODACCRE_MO CONSTANT VARCHAR2(2) := 'MO'; -- MODELLO 124 T
  CODACCRE_MD CONSTANT VARCHAR2(2) := 'MD'; -- mandato lista allegato
 

  -- CBI - banca italia
  CODACCRE_GC CONSTANT VARCHAR2(2) := 'GC';
  CODACCRE_CS CONSTANT VARCHAR2(2) := 'CS';
  
  -- CCP - conto corrente postale
  CODACCRE_CP CONSTANT VARCHAR2(2) := 'CP';
  CODACCRE_VA CONSTANT VARCHAR2(2) := 'VA';
  CODACCRE_BP CONSTANT VARCHAR2(2) := 'BP';
  
  
  
  -- CSI  - CESSIONE INCASSO
  -- cessione credito
  CODACCRE_CC CONSTANT VARCHAR2(2) := 'CC'; -- CESSIONE CREDITO PRO SOLVENDO
  CODACCRE_CX CONSTANT VARCHAR2(2) := 'CX'; -- CESSIONE DI CREDITO PRO SOLUTO
  -- cessione incasso
  CODACCRE_FA CONSTANT VARCHAR2(2) := 'FA'; -- FALLIMENTO
  CODACCRE_PR CONSTANT VARCHAR2(2) := 'PR'; -- PROCURA
  CODACCRE_PS CONSTANT VARCHAR2(2) := 'PS'; -- PROCURA SPECIALE
  CODACCRE_AG CONSTANT VARCHAR2(2) := 'AG'; -- AGENTE RAPPRESENTANTE



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
  SIAC_TIPOACCRE_GE CONSTANT VARCHAR2(3) := 'GE'; -- 'generica'
  SIAC_TIPOACCRE_ND  CONSTANT VARCHAR2(2) := 'ND'; -- 'non definito'

  CF_ESTERO_99       CONSTANT VARCHAR2(16) := '9999999999999999';


  procedure migrazione_soggetto_temp(p_ente           number,
                                     p_anno_esercizio varchar2,
                                     p_anni           number,
                                     pCodRes          out number,
                                     pMsgRes          out varchar2);
  procedure migrazione_soggetto(pEnte   number,
                                pCodRes out number,
                                pMsgRes out varchar2);
                                
  procedure migrazione_indirizzo_second(pEnte number,
                                        pCodRes out number,
                                        pMsgRes out varchar2);
                                        
  procedure migrazione_soggetto_sede_sec(pEnte           number,
                                         pCodRes out number,
                                         pMsgRes out varchar2);                                        
                                         
  procedure migrazione_soggetto_mdp(pEnte   number,
                                    pCodRes out number,
                                    pMsgRes out varchar2);    
                                    
  procedure migrazione_soggetti(pEnte           number,
                                pAnnoEsercizio varchar2,
                                pAnni           number,
                                pCodRes out number,
                                pMsgRes out varchar2);  
                                
  function fnc_migrazione_mod_accredito(pEnte number,
                                        pMsgRes out varchar2)
  return number;    
  procedure migrazione_soggetto_relaz   (pEnte   number,
                                         pCodRes out number,
                                         pMsgRes out varchar2);                                                                                                   
END;
/
