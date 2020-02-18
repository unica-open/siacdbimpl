/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop sequence migr_elenco_doc_id_seq;
drop sequence migr_atto_allegato_id_seq;
drop sequence migr_atto_allegato_sog_id_seq;
drop sequence migr_doc_spesa_id_seq;
drop sequence migr_docquo_spesa_id_seq;
drop sequence migr_doc_entrata_id_seq;
drop sequence migr_docquo_entrata_id_seq;
drop sequence migr_relazdoc_id_seq;
drop sequence MIGR_DOC_SPESA_SCARTO_ID_SEQ;
drop sequence MIGR_DOC_SPE_SCARTO_ID_SEQ;

drop sequence MIGR_DOC_ENTRATA_SCARTO_ID_SEQ;
drop sequence MIGR_DOC_ENT_SCARTO_ID_SEQ;

-- dati documenti iva
drop sequence migr_doc_spesa_iva_id_seq;
drop sequence migr_docquo_spesa_iva_id_seq;
drop sequence migr_docquospesaivaaliq_id_seq;
drop sequence migr_relazdocspesaiva_id_seq;
drop sequence migr_docquoiva_scarto_id_seq;


create sequence migr_elenco_doc_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_atto_allegato_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_atto_allegato_sog_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;


create sequence migr_doc_spesa_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;


create sequence migr_docquo_spesa_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_doc_entrata_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_docquo_entrata_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;


create sequence migr_relazdoc_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence MIGR_DOC_SPESA_SCARTO_ID_SEQ
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence MIGR_DOCQUO_SPE_SCARTO_ID_SEQ
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence MIGR_DOC_ENTRATA_SCARTO_ID_SEQ
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence MIGR_DOCQUO_ENT_SCARTO_ID_SEQ
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

-- dati documenti iva
create sequence migr_doc_spesa_iva_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_docquo_spesa_iva_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_docquospesaivaaliq_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_relazdocspesaiva_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_docquoiva_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_quoivaaliqscarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;
