CREATE OR REPLACE PACKAGE PCK_MIGRAZIONE_SIAC AS
       TIPO_CAP_PREV  CONSTANT VARCHAR2(1) := 'P';

       TIPO_IMPEGNO_I  CONSTANT VARCHAR2(1):='I'; -- impegno
       TIPO_IMPEGNO_A  CONSTANT VARCHAR2(1):='A'; -- accertamento
       TIPO_IMPEGNO_S  CONSTANT VARCHAR2(1):='S'; -- subimp/acc

       TIPO_IMPEGNO_SVI  CONSTANT VARCHAR2(3):='SVI';
       PROVV_SPR  CONSTANT VARCHAR2(3):='SPR'; -- impegno/acc senza provvedimento

       STATO_P  CONSTANT VARCHAR2(1):='P';
       STATO_D  CONSTANT VARCHAR2(1):='D';
       STATO_N  CONSTANT VARCHAR2(1):='N';

       PROVV_DETERMINA_REGP CONSTANT varchar2(2):='AD';
       PROVV_DELIBERA_REGP  CONSTANT varchar2(2):='DG';
       PROVV_ATTO_LIQUIDAZIONE  CONSTANT varchar2(2):='AL';
       PROVV_ATTO_LIQUIDAZIONE_SIAC  CONSTANT varchar2(3):='ALG';

       ACC_AUTOMATICO  CONSTANT varchar2(2):='AU';

       ENTE_COTO             CONSTANT number:=1;
       ENTE_REGP_GIUNTA      CONSTANT number:=2;
       ENTE_AIPO             CONSTANT number:=4;

       SPE_GEST_SANITA       CONSTANT number:=4;
       SPE_GEST_REG          CONSTANT number:=3;
       ENT_GEST_SANITA       CONSTANT number:=2;
       ENT_GEST_REG          CONSTANT number:=1;

       CLASSE_MIGRAZIONE     CONSTANT VARCHAR2(250):='MIGRAZIONE||MIGRAZIONE';

       STATO_LIQUIDAZIONE_V  CONSTANT VARCHAR2(1):='V';
       
       N_BLOCCHI_DOC CONSTANT  NUMBER :=200;
       
       RELAZ_TIPO_NCD CONSTANT VARCHAR2(3):='NCD';
       
       STATO_ELENCO_DOC_B  CONSTANT  VARCHAR2(1) :='B'; -- BOZZA
       STATO_ELENCO_DOC_C  CONSTANT  VARCHAR2(1) :='C'; -- COMPLETO
       STATO_DOC_L  CONSTANT  VARCHAR2(1) :='L'; -- LIQUIDATO
       
       STATO_AA_D CONSTANT  VARCHAR2(1) :='D'; -- DA COMPLETARE
       STATO_AA_C CONSTANT  VARCHAR2(1) :='C'; -- COMPLETATO
  
       -- DAVIDE - rapporto di conversione Lira / Euro
       RAPPORTO_EURO_LIRA NUMBER (15,2) := 1936.27;
       -- DAVIDE - Fine
       
       TIPO_COMMISSIONI_ES CONSTANT VARCHAR2(2):='ES';
       
       PROVV_LR CONSTANT VARCHAR2(2):='LR'; -- impegno con provvedimento non trovato
       ANNOPROVV_LR CONSTANT VARCHAR2(4):='2001';
       NUMPROVV_LR CONSTANT INTEGER:=7;
       
       -- ordinativi
       -- conto_corrente
       CONTO_CC_SANITA CONSTANT VARCHAR2(10):='0000101';
       CONTO_CC_ALTRO  CONSTANT VARCHAR2(10):='0000100';
       
       -- stato_operativo
       ORD_ANNULLATO   CONSTANT VARCHAR2(1):='A';
       ORD_QUIETANZATO CONSTANT VARCHAR2(1):='Q';
       ORD_FIRMATO     CONSTANT VARCHAR2(1):='F';
       ORD_TRASMESSO   CONSTANT VARCHAR2(1):='T';
       ORD_INSERITO    CONSTANT VARCHAR2(1):='I';
       
       -- bollo esente
       BOLLO_ESENTE     CONSTANT VARCHAR2(2):='ES';
       
  --- capitoli
  procedure migrazione_cpu(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cpe(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cgu(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cge(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_attilegge_up(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_attilegge_ep(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_attilegge_ug(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_attilegge_eg(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_vincoli_cp(p_anno_esercizio varchar2, p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_vincoli_cg(p_anno_esercizio varchar2, p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_classif_cap_prev(p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_classif_cap_gest(p_ente number,pCodRes out number,pMsgRes out varchar2);

  procedure migrazione_capitolo(pTipoCapitolo varchar2, pAnnoEsercizio varchar2,pEnte number,
                                pCodRes out number, pMsgRes out varchar2);
  procedure reset_seq(p_seq_name in varchar2);

       -- function-procedure per popolamento tabelle stage migrazione impegni/accertamenti
       -- migr_impegno, migr_impegno_accertamento

       function fnc_migr_impegno(p_ente_proprietario_id number,
                                 p_anno_esercizioIniziale varchar2,
                                 p_anno_esercizio varchar2,
                                 p_cod_res out number,
                                 p_imp_inseriti out number,
                                 p_imp_scartati out number) return varchar2;

       function fnc_migr_subimpegno(p_ente_proprietario_id number,
                                    p_anno_esercizio varchar2,
                                    p_cod_res out number,
                                    p_imp_inseriti out number,
                                    p_imp_scartati out number) return varchar2;
       -- migr_accertamento
       function fnc_migr_accertamento(p_ente_proprietario_id number,
                                      p_anno_esercizioIniziale varchar2,
                                      p_anno_esercizio varchar2,
                                      p_cod_res out number,
                                      p_imp_inseriti out number,
                                      p_imp_scartati out number) return varchar2;

       function fnc_migr_subaccertamento(p_ente_proprietario_id number,
                                      p_anno_esercizio varchar2,
                                      p_cod_res out number,
                                      p_imp_inseriti out number,
                                      p_imp_scartati out number) return varchar2;

    procedure migrazione_impacc (p_ente_proprietario_id number,
                                       p_anno_esercizio varchar2,
                                       p_cod_res out number,
                                       msgResOut out varchar2);
    procedure migrazione_liquidazione(pEnte number,
                                      pAnnoEsercizio       varchar2,
                                      pCodRes              out number,
                                      pLiqInseriti         out number,
                                      pLiqScartati         out number,
                                      pMsgRes              out varchar2);

    procedure migrazione_provvedimento(pEnte number,
                                      pAnnoEsercizio       varchar2,
                                      pCodRes              out number,
                                      pProvInseriti         out number,
                                      pProvScartati         out number,
                                      pMsgRes              out varchar2);

--  procedure get_liquidazioneOriginale (p_annoEsercizio in varchar2,p_nliq in number, o_annoEsercizio out varchar2,o_nliq out number, o_dataIns out varchar2);

   procedure migrazione_doc_temp (pEu varchar2,
                                  pEnte number,
                                  pCodRes out number,
                                  pMsgRes out varchar2);
                                  
 	 procedure migrazione_doc_spesa (pEnte number, pLoginOperazione varchar2,pAnnoEsercizio varchar2,pCodRes out number, pRecInseriti out number,pRecScartati out number,pMsgRes out varchar2);
   procedure migrazione_docquo_spesa (pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pRecInseriti out number,
                                   pRecScartati out number,
                                   pMsgRes out varchar2);
 	 procedure migrazione_doc_entrata (pEnte number,pLoginOperazione varchar2,pAnnoEsercizio varchar2,pCodRes out number,pRecInseriti out number,pRecScartati out number,pMsgRes out varchar2);
   procedure migrazione_docquo_entrata (pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pRecInseriti out number,
                                   pRecScartati out number,
                                   pMsgRes out varchar2);

   procedure get_stato_documento (doc_eu varchar2,doc_codben number,doc_annofatt varchar2,doc_nfatt varchar2,doc_tipofatt varchar2,pEnte number, pAnnoEsercizio varchar2, doc_stato out varchar2,pCodRes out number,pMsgRes out varchar2);

   -- Sofia / Davide - 03.11.2016 - calcolo Stato documento a partire dalle quote
   procedure get_stato_documento_migr (doc_eu varchar2,doc_codben number,doc_annofatt varchar2,doc_nfatt varchar2,doc_tipofatt varchar2,pEnte number, pAnnoEsercizio varchar2, doc_stato out varchar2,pCodRes out number,pMsgRes out varchar2);
    
   procedure aggiorna_stati_documenti(doc_eu varchar2, pEnte number, pAnnoEsercizio varchar2, pCodRes out number, pMsgRes out varchar2);              
   -- Sofia / Davide - 03.11.2016 - Fine

   procedure migrazione_relaz_documenti(pEnte number,
                                       pCodRes out number,
                                       pMsgRes out varchar2);
                                       
 procedure migrazione_atto_allegato(pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pMsgRes out varchar2);
/* procedure migrazione_elenco_doc_allegati(pEnte number,
                                   pLoginOperazione varchar,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pMsgRes out varchar2);*/
                                   
 procedure migrazione_aa_daelenco
                                   (pEnte number,
                                   pLoginOperazione varchar2,
                                   pAnnoEsercizio varchar2,
                                   pCodRes out number,
                                   pMsgRes out varchar2);
 
   procedure migrazione_documenti(pEnte number,
                                  pAnnoEsercizio varchar2,
                                  pLoginOperazione varchar2,                                 
                                  pCodRes out number,
                                  pMsgRes out varchar2);
                  
/*   procedure migrazione_atti_allegati
                                 (pEnte number,
                                  pAnnoEsercizio varchar2,
                                  pLoginOperazione varchar2,                                 
                                  pCodRes out number,
                                  pMsgRes out varchar2);  */          
                                  
   procedure migrazione_iva(pEnte number,pAnnoEsercizio varchar2,pLoginOperazione varchar2,pCodRes out number,pMsgRes out varchar2);
   
   -- ordinativi  
   procedure migrazione_ordinativo(pAnnoEsercizio varchar2,
                                   pEnte number,
                                   pCodRes out number,
                                   pMsgRes out varchar2);
                                   
   procedure migrazione_ordinativo_spesa(pEnte number,
                                         pAnnoEsercizio       varchar2,
                                         pCodRes              out number,
                                         pOrdInseriti         out number,
                                         pOrdScartati         out number,
                                         pOrdSegnalati        out number,
                                         pMsgRes              out varchar2);

   
   
   procedure migrazione_ordinativo_spesa_ts(pEnte number,
                                           pAnnoEsercizio       varchar2,
                                           pCodRes              out number,
                                           pOrdInseriti         out number,
                                           pOrdScartati         out number,
                                           pMsgRes              out varchar2);

   procedure migrazione_ordinativo_entrata(pEnte number,
                                           pAnnoEsercizio       varchar2,
                                           pCodRes              out number,
                                           pOrdInseriti         out number,
                                           pOrdScartati         out number,
                                           pOrdSegnalati        out number,
                                           pMsgRes              out varchar2);

   
   
   procedure migrazione_ordinativo_entr_ts(pEnte number,
                                           pAnnoEsercizio       varchar2,
                                           pCodRes              out number,
                                           pOrdInseriti         out number,
                                           pOrdScartati         out number,
                                           pMsgRes              out varchar2);
    
   procedure migrazione_provissori_cassa(pEnte number,
                                         pAnnoEsercizio       varchar2,
                                         pCodRes              out number,
                                         pProvvInseriti         out number,
                                         pProvvScartati         out number,
                                         pMsgRes              out varchar2);   

  -- DAVIDE - 09.03.016 - aggiunta gestione modifiche Impegni / Accertamenti
  function fnc_migr_impegno_modifica(p_ente_proprietario_id number,
                                     p_anno_esercizio varchar2,
                                     p_cod_res out number,
                                     p_imp_inseriti out number,
                                     p_imp_scartati out number) return varchar2;

  function fnc_migr_accertamento_modifica(p_ente_proprietario_id number,
                                          p_anno_esercizio varchar2,
                                          p_cod_res out number,
                                          p_imp_inseriti out number,
                                          p_imp_scartati out number) return varchar2;

  --  DAVIDE - 23.03.016 - inserita migrazione collegamenti ordinativi provvisori cassa
   procedure migr_ord_provv_cassa(pEnte number,
                                  pAnnoEsercizio       varchar2,
                                  pCodRes              out number,
                                  pProvvInseriti         out number,
                                  pProvvScartati         out number,
                                  pMsgRes              out varchar2); 
END;
/
