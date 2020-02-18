/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
- adeguamenti per ABI36

ALTER TABLE mif_t_ordinativo_spesa
  ALTER COLUMN mif_ord_anno_res DROP NOT NULL;

ALTER TABLE mif_t_ordinativo_entrata
  ALTER COLUMN mif_ord_anno_res DROP NOT NULL;

alter table mif_t_ordinativo_spesa
add   mif_ord_commissioni_natura varchar(100) null;