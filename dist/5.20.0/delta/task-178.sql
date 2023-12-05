/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--task-178 - Alessandra - INIZIO
DROP INDEX IF EXISTS idx_siac_t_subdoc_iva_1;

CREATE UNIQUE INDEX idx_siac_t_subdoc_iva_1 ON siac.siac_t_subdoc_iva
USING btree (subdociva_anno, subdociva_numero, subdociva_data_emissione, ente_proprietario_id) WHERE (data_cancellazione IS NULL); 
--task-178 - Alessandra - FINE