/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
lter table mif_t_ordinativo_spesa add  mif_ord_sepa_iban_tr varchar(50) null;
alter table mif_t_ordinativo_spesa add mif_ord_sepa_bic_tr  varchar(50) null;
alter table mif_t_ordinativo_spesa add mif_ord_sepa_id_end_tr varchar(100) null;