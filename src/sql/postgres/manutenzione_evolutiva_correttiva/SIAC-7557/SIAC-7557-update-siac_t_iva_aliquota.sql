/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

update siac_t_iva_aliquota   ia
set codice =  (select codice from sirfel_d_natura where codice =  'N2.2' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc = 'ART. 74 C.1 LETT. C DPR 633/72 (LIBRI)';

update siac_t_iva_aliquota  ia
set codice =  (select codice from sirfel_d_natura where codice =   'N3.2' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc ='ART. 72 C.3 N.3 D.P.R. 633/72 TRATTATI INTERNAZ.';

update siac_t_iva_aliquota  ia
set codice =  (select codice from sirfel_d_natura where codice =   'N4' and ia.ente_proprietario_id =ente_proprietario_id)
where ivaaliquota_desc in ('4% - Esente', '10% - Esente', '22% - Esente');

update siac_t_iva_aliquota  ia
set codice = (select codice from sirfel_d_natura where codice =  'N6.9' and ia.ente_proprietario_id =ente_proprietario_id) 
where ivaaliquota_desc in ('4% - ART.17-TER SCISSIONE PAGAMENTI','10% - ART.17-TER SCISSIONE PAGAMENTI',
'22% - ART.17-TER SCISSIONE PAGAMENTI');