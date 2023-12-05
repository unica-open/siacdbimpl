/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop sequence migr_provvedimento_id_seq;
drop sequence migr_provv_scarto_id_seq;

create sequence migr_provvedimento_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_provv_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;
