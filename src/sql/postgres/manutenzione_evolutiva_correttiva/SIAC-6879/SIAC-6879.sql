/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
SELECT * from fnc_dba_add_column_params ('siac_t_prov_cassa', 'provc_data_invio_servizio', 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * from fnc_dba_add_column_params ('siac_t_prov_cassa', 'provc_data_rifiuto_errata_attribuzione', 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * from fnc_dba_add_column_params ('siac_t_prov_cassa', 'provc_data_presa_in_carico_servizio', 'TIMESTAMP WITHOUT TIME ZONE');
