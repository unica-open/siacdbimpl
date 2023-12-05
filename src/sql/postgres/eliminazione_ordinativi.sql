/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿delete from siac_r_doc_onere_ordinativo_ts where ente_proprietario_id=&ente;
delete from siac_r_liquidazione_ord where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_ts_movgest_ts where ente_proprietario_id=&ente;
delete from siac_r_subdoc_ordinativo_ts where ente_proprietario_id=&ente;
delete from siac_t_ordinativo_ts_det where ente_proprietario_id=&ente;


delete from siac_r_ordinativo where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_atto_amm where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_attr where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_bil_elem where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_class where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_firma where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_modpag where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_prov_cassa where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_quietanza where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_soggetto where ente_proprietario_id=&ente;
delete from siac_r_ordinativo_stato where ente_proprietario_id=&ente;
delete from siac_t_ordinativo_ts where ente_proprietario_id=&ente;
delete from siac_t_ordinativo  where ente_proprietario_id=&ente;

