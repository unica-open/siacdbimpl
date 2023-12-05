/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 24.11.2017 Sofia SIOPE PLUS
-- DDL creazione e adeguamento struttura dati
-- rilasciato in all.sql


alter table mif_t_ordinativo_entrata
 alter column  mif_ord_rif_doc_esterno TYPE varchar(150);

