/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE siac_t_doc  ADD doc_data_operazione timestamp without time zone;
ALTER TABLE siac_t_doc  ADD cod_avviso_pago_pa varchar(100);
ALTER TABLE siac_t_doc  ADD iuv varchar(100); --- IdentificativoUnivocoVersamento


