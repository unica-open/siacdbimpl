/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE TABLE siac.siac_rep_pagam_ug_completa (
  elem_id INTEGER,
  pagamenti_competenza NUMERIC,
  anno_competenza INTEGER,
  stato VARCHAR,
  ente_proprietario_id INTEGER,
  utente VARCHAR
) 
WITH (oids = false);