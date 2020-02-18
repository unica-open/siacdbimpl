CREATE OR REPLACE PACKAGE PCK_MIGRAZIONE_SIAC AS

    TIPO_CAP_PREV  CONSTANT VARCHAR2(1) := 'P'; 
    TIPO_IMPEGNO_SVI  CONSTANT VARCHAR2(3):='SVI';
    STATO_P  CONSTANT VARCHAR2(1):='P'; 
    STATO_D  CONSTANT VARCHAR2(1):='D';
    STATO_N  CONSTANT VARCHAR2(1):='N';
	
    STATO_LIQUIDAZIONE_V  CONSTANT VARCHAR2(1):='V';

    TIPO_IMPEGNO_I  CONSTANT VARCHAR2(1):='I'; -- impegno
    TIPO_IMPEGNO_A  CONSTANT VARCHAR2(1):='A'; -- accertamento
    TIPO_IMPEGNO_S  CONSTANT VARCHAR2(1):='S'; -- subimp/acc

    PROVV_SPR  CONSTANT VARCHAR2(3):='SPR'; -- impegno/acc senza provvedimento
    PROVV_AD CONSTANT VARCHAR2(3):='AD';  -- i provvedimento di questo tipo hano in chiave la direzione (quindi ricerca su postgres anche per direzione oltre che per numero e anno)
    PROVV_DP CONSTANT VARCHAR2(3):='DP';  -- i provvedimento di questo tipo hano in chiave la direzione (quindi ricerca su postgres anche per direzione oltre che per numero e anno)
    PROVV_DD CONSTANT VARCHAR2(3):='DD';  -- i provvedimento di questo tipo hano in chiave la direzione (quindi ricerca su postgres anche per direzione oltre che per numero e anno)
    PROVV_DG  CONSTANT varchar2(2):='DG';
    PROVV_ATTO_LIQUIDAZIONE  CONSTANT varchar2(2):='AL';
    PROVV_ATTO_LIQUIDAZIONE_SIAC  CONSTANT varchar2(3):='ALG';

     N_BLOCCHI_DOC CONSTANT  NUMBER :=200;

    CLASSE_MIGRAZIONE CONSTANT VARCHAR2(250):='MIGRAZIONE||MIGRAZIONE';

     RELAZ_TIPO_NCD CONSTANT VARCHAR2(3):='NCD';
     RELAZ_TIPO_NCDI CONSTANT VARCHAR2(4):='NCDI';

     STATO_ELENCO_DOC_B  CONSTANT  VARCHAR2(1) :='B'; -- BOZZA
     STATO_ELENCO_DOC_C  CONSTANT  VARCHAR2(1) :='C'; -- COMPLETO
     STATO_DOC_L  CONSTANT  VARCHAR2(1) :='L'; -- LIQUIDATO

     STATO_AA_D CONSTANT  VARCHAR2(1) :='D'; -- DA COMPLETARE
     STATO_AA_C CONSTANT  VARCHAR2(1) :='C'; -- COMPLETATO

     -- DAVIDE - rapporto di conversione Lira / Euro
     RAPPORTO_EURO_LIRA NUMBER (15,2) := 1936.27;
     -- DAVIDE - Fine
     TIPO_COMMISSIONI_ES CONSTANT VARCHAR2(2):='ES';

  procedure migrazione_cpu(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cpe(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cgu(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cge(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_classif_cap_prev(p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_classif_cap_gest(p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_capitolo(pTipoCapitolo varchar2, pAnnoEsercizio varchar2,pEnte number,
                                pCodRes out number, pMsgRes out varchar2);
  procedure reset_seq(p_seq_name in varchar2);

  procedure migrazione_impacc (p_ente_proprietario_id number, p_anno_esercizio varchar2,p_cod_res out number, msgResOut out varchar2);
  procedure migrazione_impegni(p_ente_proprietario_id number,p_anno_bilancio varchar2, p_anno_esercizio varchar2,p_cod_res out number,p_imp_inseriti out number,p_imp_scartati out number,pMsgRes out varchar2);
  procedure migrazione_subimpegni(p_ente_proprietario_id number,p_anno_esercizio varchar2,p_cod_res out number, p_imp_inseriti out number,p_imp_scartati out number,pMsgRes out varchar2);
  procedure migrazione_accertamenti(p_ente_proprietario_id number,p_anno_bilancio varchar2, p_anno_esercizio varchar2,p_cod_res out number, p_imp_inseriti out number, p_imp_scartati out number,pMsgRes out varchar2);
  procedure migrazione_subaccertamenti(p_ente_proprietario_id number,p_anno_esercizio varchar2,p_cod_res out number, p_imp_inseriti out number, p_imp_scartati out number,pMsgRes out varchar2);

  procedure migrazione_liquidazione(pEnte number,
                                      pAnnoEsercizio       varchar2,
                                      pCodRes              out number,
                                      pLiqInseriti         out number,
                                      pLiqScartati         out number,
                                      pMsgRes              out varchar2);
									  
  procedure migrazione_doc_spesa (pEnte number, pLoginOperazione varchar2,pAnnoEsercizio varchar2,pCodRes out number, pRecInseriti out number,pRecScartati out number,pMsgRes out varchar2);
  procedure migrazione_docquo_spesa (pEnte number,pLoginOperazione varchar2,pAnnoEsercizio varchar2,pCodRes out number,pRecInseriti out number,pRecScartati out number,pMsgRes out varchar2);
  procedure migrazione_doc_entrata (pEnte number,pLoginOperazione varchar2,pAnnoEsercizio varchar2,pCodRes out number,pRecInseriti out number,pRecScartati out number,pMsgRes out varchar2);
  procedure migrazione_docquo_entrata (pEnte number, pLoginOperazione varchar2, pAnnoEsercizio varchar2, pCodRes out number,pRecInseriti out number, pRecScartati out number, pMsgRes out varchar2);
  procedure get_stato_documento (doc_eu varchar2,doc_codben number,doc_annofatt varchar2,doc_nfatt varchar2,doc_tipofatt varchar2,pEnte number, pAnnoEsercizio varchar2, doc_stato out varchar2,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_relaz_documenti(pEnte number, pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_atto_allegato(pEnte number, pLoginOperazione varchar2, pAnnoEsercizio varchar2, pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_aa_daelenco(pEnte number, pLoginOperazione varchar2, pAnnoEsercizio varchar2, pCodRes out number, pMsgRes out varchar2);                          
  procedure migrazione_documenti(pEnte number,pAnnoEsercizio varchar2,pLoginOperazione varchar2,pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_doc_iva(pEnte number,pAnnoEsercizio varchar2,pLoginOperazione varchar2,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_aliquota_iva (pEnte number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_relaz_documenti_iva(pEnte number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_iva(pEnte number,pAnnoEsercizio varchar2,pLoginOperazione varchar2,pCodRes out number,pMsgRes out varchar2);

    END;
/
