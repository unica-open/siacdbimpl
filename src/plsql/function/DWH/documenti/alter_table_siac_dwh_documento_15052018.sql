/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 15.05.2018 Sofia JIRA SIAC-6124

alter table siac_dwh_documento_spesa
  add data_ins_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  add data_completa_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  add data_convalida_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  add data_sosp_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  add causale_sosp_atto_allegato varchar(250),
  add data_riattiva_atto_allegato TIMESTAMP WITHOUT TIME ZONE;

alter table siac_dwh_documento_entrata
  add data_ins_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  add data_completa_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  add data_convalida_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  add data_sosp_atto_allegato TIMESTAMP WITHOUT TIME ZONE,
  add causale_sosp_atto_allegato varchar(250),
  add data_riattiva_atto_allegato TIMESTAMP WITHOUT TIME ZONE;