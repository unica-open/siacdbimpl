/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 07.11.2018 Sofia siac-6351

alter table siac_t_prov_cassa
   add provc_conto_evidenza varchar(200),
   add provc_conto_evidenza_desc varchar(500);

alter table mif_t_oil_ricevuta
   add oil_ricevuta_conto_evidenza varchar(200),
   add   oil_ricevuta_conto_evidenza_desc varchar(500);

alter table siac_t_oil_ricevuta
   add oil_ricevuta_conto_evidenza varchar(200),
   add oil_ricevuta_conto_evidenza_desc varchar(500);


begin;
SELECT fnc_dba_add_column_params('siac_t_prov_cassa', 'provc_conto_evidenza', 'varchar(200)');
SELECT fnc_dba_add_column_params('siac_t_prov_cassa', 'provc_conto_evidenza_desc', 'varchar(500)');

SELECT fnc_dba_add_column_params('mif_t_oil_ricevuta', 'oil_ricevuta_conto_evidenza', 'varchar(200)');
SELECT fnc_dba_add_column_params('mif_t_oil_ricevuta', 'oil_ricevuta_conto_evidenza_desc', 'varchar(500)');


SELECT fnc_dba_add_column_params('siac_t_oil_ricevuta', 'oil_ricevuta_conto_evidenza', 'varchar(200)');
SELECT fnc_dba_add_column_params('siac_t_oil_ricevuta', 'oil_ricevuta_conto_evidenza_desc', 'varchar(500)');
