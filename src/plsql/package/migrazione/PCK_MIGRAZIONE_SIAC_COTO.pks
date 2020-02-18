CREATE OR REPLACE PACKAGE BILANCIO.PCK_MIGRAZIONE_SIAC AS

  STATO_IMPEGNO_P CONSTANT VARCHAR2(1) := 'P';
  STATO_IMPEGNO_D CONSTANT VARCHAR2(1) := 'D';
  STATO_IMPEGNO_N CONSTANT VARCHAR2(1) := 'N';

  TIPO_IMPEGNO_I CONSTANT VARCHAR2(1) := 'I'; -- impegno
  TIPO_IMPEGNO_A CONSTANT VARCHAR2(1) := 'A'; -- accertamento
  TIPO_IMPEGNO_S CONSTANT VARCHAR2(1) := 'S'; -- subimp/acc

  PROVV_SPR      CONSTANT VARCHAR2(3) := 'SPR';
  -- DAVIDE 18.09.2015 - tipi Provvedimento per Liquidazioni
  PROVV_AA       CONSTANT VARCHAR2(3) := 'AA';
  PROVV_ALG      CONSTANT VARCHAR2(3) := 'ALG';
  -- DAVIDE 18.09.2015 - fine

  ACC_AUTOMATICO CONSTANT varchar2(2) := 'AU';
  TIPO_CAP_PREV  CONSTANT VARCHAR2(1) := 'P'; 

  STATO_LIQUIDAZIONE_V CONSTANT VARCHAR2(1) := 'V';
  
  N_BLOCCHI_DOC CONSTANT  NUMBER :=500;
  
  RELAZ_TIPO_NCD CONSTANT VARCHAR2(3):='NCD';
  RELAZ_TIPO_SUB CONSTANT VARCHAR2(3):='SUB';
  
  TIPO_IVASPLITREVERSE_SI CONSTANT VARCHAR2(2):='SI'; --Split istituzionale
  TIPO_IVASPLITREVERSE_SC CONSTANT VARCHAR2(2):='SC'; --Split commerciale
  TIPO_IVASPLITREVERSE_RC CONSTANT VARCHAR2(2):='RC'; --Reverse Charge
  TIPO_IVASPLITREVERSE_ES CONSTANT VARCHAR2(2):='ES'; --Esenzione
  
  -- DAVIDE - rapporto di conversione Lira / Euro
  RAPPORTO_EURO_LIRA NUMBER (15,2) := 1936.27;
  -- DAVIDE - Fine
  
  procedure migrazione_cpu(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_cgu(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_cpe(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_cge(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_vincoli_cp(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_vincoli_cg(p_anno_esercizio varchar2, p_ente number,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_classif_cap_prev(p_ente number,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_classif_cap_gest(p_ente number,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_impegni(p_ente_proprietario_id number,
                               p_anno_esercizioIniziale varchar2,
                               p_anno_esercizio       varchar2,
                               p_cod_res              out number,
                               p_imp_inseriti         out number,
                               p_imp_scartati         out number,
                               msgResOut              out varchar2);
  procedure migrazione_subimpegno(p_ente_proprietario_id number,
                                  p_anno_esercizio       varchar2,
                                  p_cod_res              out number,
                                  p_imp_inseriti         out number,
                                  p_imp_scartati         out number,
                                  msgResOut              out varchar2);
  procedure migrazione_accertamento(p_ente_proprietario_id number,
                                    p_anno_esercizioIniziale varchar2,
                                    p_anno_esercizio       varchar2,
                                    p_cod_res              out number,
                                    p_imp_inseriti         out number,
                                    p_imp_scartati         out number,
                                    msgResOut              out varchar2);
  procedure migrazione_subaccertamento(p_ente_proprietario_id number,
                                       p_anno_esercizio       varchar2,
                                       p_cod_res              out number,
                                       p_imp_inseriti         out number,
                                       p_imp_scartati         out number,
                                       msgResOut              out varchar2);
  procedure leggi_provvedimento(p_anno_provvedimento    varchar2,
                                p_numero_provvedimento  varchar2,
                                p_ente_proprietario_id  number,
                                p_codRes                out number,
                                p_msgRes                out varchar2,
                                p_tipo_provvedimento    out varchar2,
                                p_oggetto_provvedimento out varchar2,
                                p_stato_provvedimento   out varchar2,
                                p_note_provvedimento    out varchar2,
								p_sac_provvedimento     out varchar2);  -- DAVIDE - Gestione SAC provvedimento
  procedure reset_seq(p_seq_name in varchar2);
  procedure migrazione_impegniPlur(p_ente_proprietario_id number,
                               p_anno_esercizio       varchar2,
                               p_cod_res              out number,
                               p_imp_inseriti         out number,
                               p_imp_scartati         out number,
                               msgResOut              out varchar2);
                               
    procedure migrazione_subimpegnoPlur(p_ente_proprietario_id number,
                                      p_anno_esercizio       varchar2,
                                      p_cod_res              out number,
                                      p_imp_inseriti         out number,
                                      p_imp_scartati         out number,
                                      msgResOut              out varchar2);
  procedure migrazione_accertamentoPlur(p_ente_proprietario_id number,
                                    p_anno_esercizio       varchar2,
                                    p_cod_res              out number,
                                    p_imp_inseriti         out number,
                                    p_imp_scartati         out number,
                                    msgResOut              out varchar2);
  procedure migrazione_subaccertamentoPlur(p_ente_proprietario_id number,
                                       p_anno_esercizio       varchar2,
                                       p_cod_res              out number,
                                       p_imp_inseriti         out number,
                                       p_imp_scartati         out number,
                                       msgResOut              out varchar2);
    procedure migrazione_impacc (p_ente_proprietario_id number,
                                       p_anno_esercizio varchar2,
                                       p_cod_res out number,
                                       msgResOut out varchar2);
    procedure migrazione_capitolo(pTipoCapitolo varchar2, pAnnoEsercizio varchar2,pEnte number,
                                  pCodRes out number, pMsgRes out varchar2);
   procedure migrazione_mutuo (pAnnoEsercizio varchar2,pEnte number, pCodRes out number, pMsgRes out varchar2,pMutuiInseriti out number,pMutuiScartati out number);
   procedure migrazione_voce_mutuo (pAnnoEsercizio varchar2,pEnte number, pCodRes out number, pMsgRes out varchar2,pMutuiInseriti out number,pMutuiScartati out number);
   procedure migrazione_liquidazione(pEnte number,
                                    pAnnoEsercizio       varchar2,
                                    pCodRes              out number,
                                    pLiqInseriti         out number,
                                    pLiqScartati         out number,
                                    pMsgRes              out varchar2);   
                                    
                                    
   procedure migrazione_doc_spesa(pEnte number,
                                 pAnnoEsercizio varchar2,
                                 pCodRes              out number,
                                 pDocInseriti         out number,
                                 pDocScartati         out number,
                                 pMsgRes              out varchar2);
                                 
   procedure migrazione_docquo_spesa(pEnte number,
                                    pAnnoEsercizio varchar2,
                                    pCodRes              out number,
                                    pDocInseriti         out number,
                                    pDocScartati         out number,
                                    pMsgRes              out varchar2);
                                    
   procedure migrazione_doc_entrata(pEnte number,
                                    pAnnoEsercizio varchar2,
                                    pCodRes              out number,
                                    pDocInseriti         out number,
                                    pDocScartati         out number,
                                    pMsgRes              out varchar2);
                                    
  procedure migrazione_docquo_entrata(pEnte number,
                                      pAnnoEsercizio varchar2,
                                      pCodRes              out number,
                                      pDocInseriti         out number,
                                      pDocScartati         out number,
                                      pMsgRes              out varchar2);                                    
                                      
  procedure migrazione_relaz_documenti(pEnte number,
                                       pCodRes              out number,
                                       pMsgRes              out varchar2);   
                                       
  procedure migrazione_elenco_doc_allegati(pEnte number,
                                           pCodRes              out number,
                                           pMsgRes              out varchar2);    
                                           
  procedure migrazione_documenti(pEnte number,
                                 pAnnoEsercizio varchar2,
                                 pLoginOperazione varchar2, 								 
                                 pCodRes              out number,
                                 pMsgRes              out varchar2);                                                                                                                 
                                      
  procedure migrazione_atto_allegato(pEnte number,
                                   pCodRes              out number,
                                   pMsgRes              out varchar2);   
                                   
  procedure migrazione_provvedimento(pEnte number,
                                    pAnnoEsercizio       varchar2,
                                    pCodRes              out number,
                                    pProvInseriti         out number,
                                    pProvScartati         out number,
                                    pMsgRes              out varchar2);

  procedure migrazione_iva(pEnte number,pAnnoEsercizio varchar2,pLoginOperazione varchar2,pCodRes out number,pMsgRes out varchar2);

END;
/
