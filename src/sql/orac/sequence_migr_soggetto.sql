/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- pulizia sequence STAGE ORACLE

drop sequence migr_soggetto_id_seq;
drop sequence migr_soggetto_classe_id_seq;
drop sequence migr_indirizzo_id_seq;
drop sequence migr_recapito_id_seq;
drop sequence migr_sede_id_seq;
drop sequence migr_modpag_id_seq;
drop sequence migr_relaz_id_seq;
drop sequence migr_accredito_id_seq;
drop sequence migr_classe_id_seq;
drop sequence migr_delegato_id_seq;

drop sequence migr_soggetto_scarto_id_seq;

create sequence migr_soggetto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_soggetto_classe_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_indirizzo_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_recapito_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_sede_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_modpag_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_relaz_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;


create sequence migr_accredito_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_classe_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence MIGR_DELEGATO_ID_SEQ
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_soggetto_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;
