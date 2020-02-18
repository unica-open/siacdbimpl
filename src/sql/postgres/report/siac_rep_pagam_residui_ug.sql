/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_pagam_residui_ug (
  elem_id INTEGER,
  pagamenti_residui NUMERIC,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);