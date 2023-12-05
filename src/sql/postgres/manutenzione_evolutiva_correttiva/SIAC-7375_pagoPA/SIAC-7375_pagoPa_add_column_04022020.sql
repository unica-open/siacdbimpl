/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--pagopa_t_riconciliazione_det.pagopa_det_data_pagamento

--siac_t_doc.doc_data_operazione


SELECT * from fnc_dba_add_column_params ('pagopa_t_riconciliazione_doc', 'pagopa_ric_doc_data_operazione', 'TIMESTAMP WITHOUT TIME ZONE');
