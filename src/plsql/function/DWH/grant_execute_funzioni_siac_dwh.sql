/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_accertamento(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_capitolo_entrata(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh; 
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_capitolo_spesa(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_documento_entrata(p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_documento_spesa(p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_impegno(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_liquidazione(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_ordinativo_incasso(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_ordinativo_pagamento(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_programma(p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh; 
  GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_soggetto(p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_vincolo(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh;
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_iva(p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh; 
GRANT EXECUTE
  ON FUNCTION siac.fnc_siac_dwh_contabilita_generale(p_anno_bilancio varchar, p_ente_proprietario_id integer, p_data timestamp) TO siac_dwh; 