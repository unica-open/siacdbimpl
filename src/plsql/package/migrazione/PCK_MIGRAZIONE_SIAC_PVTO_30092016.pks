/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE PACKAGE PCK_MIGRAZIONE_SIAC AS
  procedure migrazione_cpu(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cpe(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cgu(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_cge(p_anno_esercizio varchar2,p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_classif_cap_prev(p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_classif_cap_gest(p_ente number,pCodRes out number,pMsgRes out varchar2);
  procedure migrazione_capitolo(pTipoCapitolo varchar2, pAnnoEsercizio varchar2,pEnte number,pCodRes out number, pMsgRes out varchar2);
  procedure reset_seq(p_seq_name in varchar2);
  
  procedure migrazione_impegno(p_ente_proprietario_id number,p_anno_esercizio varchar2,p_tipo_cap varchar2,p_cod_res out number,p_imp_inseriti out number,
                               p_imp_scartati out number,msgResOut out varchar2);
  procedure migrazione_subimpegno(p_ente_proprietario_id number,p_anno_esercizio varchar2,p_tipo_cap varchar2, p_cod_res out number,p_imp_inseriti out number,
    p_imp_scartati out number,msgResOut out varchar2);
                               
  procedure migrazione_impacc (p_ente_proprietario_id number,p_anno_esercizio varchar2,p_cod_res out number,msgResOut out varchar2);
  procedure migrazione_liquidazione(pEnte number,pAnnoEsercizio varchar2,pCodRes out number,pLiqInseriti out number,pLiqScartati out number,pMsgRes out varchar2);
  procedure migrazione_documenti(pEnte number, pAnnoEsercizio varchar2,pLoginOperazione varchar2, pCodRes out number, pMsgRes out varchar2);
  procedure migrazione_doc_spesa(pEnte number,pLoginOperazione varchar2,pCodRes out number,pRecInseriti out number,pRecScartati out number,pMsgRes out varchar2);
  procedure migrazione_docquo_spesa (pEnte number, pLoginOperazione varchar2, pAnnoEsercizio varchar2, pCodRes out number,pRecInseriti out number,pRecScartati out number,pMsgRes out varchar2);

  procedure migrazione_iva(pEnte number,pAnnoEsercizio varchar2,pLoginOperazione varchar2,pCodRes out number,pMsgRes out varchar2);
  
  TIPO_CAP_PREV  CONSTANT VARCHAR2(1) := 'P';
  TIPO_IMPEGNO_I CONSTANT VARCHAR2(1) := 'I'; -- impegno
  TIPO_IMPEGNO_A CONSTANT VARCHAR2(1) := 'A'; -- accertamento
  TIPO_IMPEGNO_S CONSTANT VARCHAR2(1) := 'S'; -- subimp/acc
  TIPO_CAP_USCITA CONSTANT VARCHAR2(1) := 'U'; -- per impegni / subimpegni
  TIPO_CAP_ENTRATA CONSTANT VARCHAR2(1) := 'E'; -- per accertamenti / subaccertamenti
  STATO_IMPEGNO_P CONSTANT  VARCHAR2(1):='P'; -- 22.09.2015 Sofia
  STATO_IMPEGNO_D CONSTANT  VARCHAR2(1):='D'; -- 08.10.2015 Daniela  
  COD_SOGGETTO_NULL CONSTANT VARCHAR2(3) := '999'; -- per i mov. di gestione se il soggetto di riferimento non � valorizzato troviamo  il valore 999
  
  PROVV_SPR  CONSTANT VARCHAR2(3):='SPR'; -- impegno/acc senza provvedimento  
  N_BLOCCHI_DOC CONSTANT  NUMBER :=200;
END;
