/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- pulizia sequence STAGE ORACLE

drop sequence migr_impegno_id_seq;
drop sequence migr_accertamento_id_seq;
drop sequence migr_vincolo_impacc_id_seq;
drop sequence migr_classif_impacc_id_seq;
drop sequence migr_impegno_scarto_id_seq;
drop sequence migr_accert_scarto_id_seq;

-- DAVIDE - 09.03.016 - aggiunte per modifiche Impegni / Accertamenti
drop sequence migr_impegno_modifica_id_seq;
drop sequence migr_accertamento_modifica_id_seq;
drop sequence migr_impegno_modscarto_id_seq;
drop sequence migr_accertamento_modsc_id_seq;

create sequence migr_impegno_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_accert_scarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_impegno_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_accertamento_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence  migr_vincolo_impacc_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_classif_impacc_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

-- DAVIDE - 09.03.016 - aggiunte per modifiche Impegni / Accertamenti

create sequence migr_impegno_modifica_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_accertamento_mod_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_impegno_modscarto_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

create sequence migr_accertamento_modsc_id_seq
minvalue 1
maxvalue 999999999999999999999999999
start with 1
increment by 1
cache 20;

