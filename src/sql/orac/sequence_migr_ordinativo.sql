/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop sequence migr_ord_spesa_id_seq;
drop sequence migr_ord_spesa_scarto_id_seq;
drop sequence migr_ord_spesa_ts_id_seq:
drop sequence migr_ord_spe_ts_scarto_id_seq:
drop sequence migr_ord_entrata_id_seq;
drop sequence migr_ord_entrata_scarto_id_seq;
drop sequence migr_ord_entrata_ts_id_seq;
drop sequence migr_ord_entr_ts_scarto_id_seq;
drop sequence migr_provv_cassa_id_seq;
drop sequence migr_provv_cassa_scarto_id_seq;
drop sequence migr_provv_cassa_ord_id_seq;
drop sequence migr_provv_cas_ord_sca_id_seq;
drop sequence migr_ord_relaz_id_seq;

create sequence  migr_ord_spesa_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_ord_spesa_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_ord_spesa_ts_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_ord_spe_ts_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;


create sequence  migr_ord_entrata_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_ord_entrata_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_ord_entrata_ts_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_ord_entr_ts_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;


create sequence  migr_provv_cassa_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_provv_cassa_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_provv_cassa_ord_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_provv_cas_ord_sca_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_ord_relaz_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;
