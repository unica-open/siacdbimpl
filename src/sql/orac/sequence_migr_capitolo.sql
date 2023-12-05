/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- pulizia sequence STAGE ORACLE

drop sequence migr_capusc_id_seq;
drop sequence migr_capent_id_seq;

drop sequence migr_attilegge_spesa_id_seq ;
drop sequence migr_attilegge_entrata_id_seq ;

drop sequence migr_vincolo_id_seq;
drop sequence migr_vincolo_cap_id_seq;
drop sequence migr_classif_capitolo_id_seq;

create sequence migr_capusc_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_capent_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_attilegge_spesa_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_attilegge_entrata_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_vincolo_cap_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_vincolo_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_classif_capitolo_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;


