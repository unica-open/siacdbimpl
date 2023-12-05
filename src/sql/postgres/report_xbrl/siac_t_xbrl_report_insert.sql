/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--128

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR128',
       'REND',
       'SDB',
       'bdap-sdb-rend-enti_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='EELL'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR128')
       ;
       

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR128',
       'REND',
       'SDB',
       'bdap-sdb-rend-regioni_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='REG'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR128');       


--129

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR129',
       'REND',
       'SDB',
       'bdap-sdb-rend-enti_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='EELL'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR129')
       ;
       

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR129',
       'REND',
       'SDB',
       'bdap-sdb-rend-regioni_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='REG'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR129');  

--125      

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR125',
       'REND',
       'SDB',
       'bdap-sdb-rend-enti_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='EELL'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR125')
       ;
       

INSERT INTO siac_t_xbrl_report(xbrl_rep_codice, xbrl_rep_fase_code,
  xbrl_rep_tipologia_code, xbrl_rep_xsd_tassonomia, validita_inizio,
  ente_proprietario_id, login_operazione)
select 'BILR125',
       'REND',
       'SDB',
       'bdap-sdb-rend-regioni_2016-10-18.xsd',
       '2016-01-01'::timestamp,
       a.ente_proprietario_id,
       'gt1307'
       from siac_t_ente_proprietario a, siac_r_ente_proprietario_tipo b ,siac_d_ente_proprietario_tipo c
       where a.ente_proprietario_id=b.ente_proprietario_id
       and c.eptipo_id=b.eptipo_id
       and c.eptipo_code='REG'
        and not exists (select 1 from siac_t_xbrl_report z where z.xbrl_rep_codice='BILR125');   