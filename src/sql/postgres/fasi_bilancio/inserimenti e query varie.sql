/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-------------------------------------------------------------- INSERIMENTO DATI -----------------------------

select * from fase_gen_d_elaborazione_fineanno_tipo
where ente_proprietario_id=4
order by ordine

select * from fase_gen_d_elaborazione_fineanno_tipo_det
where ente_proprietario_id=4

select fasetipo.fase_gen_elab_tipo_code, fasetipo.fase_gen_elab_tipo_desc,
       c.causale_ep_code, c.causale_ep_desc,
       pdc.pdce_conto_code,
       pdc.pdce_conto_desc,
       f.pdce_fam_code
from siac_t_causale_ep c, siac_d_causale_ep_tipo tipo,fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_pdce_conto pdc,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f,
     siac_r_pdce_conto_attr r, siac_t_attr a
where tipo.ente_proprietario_id=4
and   tipo.causale_ep_tipo_code='LIB'
and   c.causale_ep_tipo_id=tipo.causale_ep_tipo_id
and   fasetipo.causale_ep_id=c.causale_ep_id
and   pdc.pdce_conto_id=fasetipo.pdce_conto_ep_id
and   r.pdce_conto_id=pdc.pdce_conto_id
and   a.attr_id=r.attr_id
and   a.attr_code ='pdce_conto_foglia'
and   r.boolean='S'
and   ft.pdce_fam_tree_id=pdc.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   c.data_cancellazione is null
and   pdc.data_cancellazione is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   f.data_cancellazione is null
and   ft.data_cancellazione is null


select c.*
from siac_t_causale_ep c, siac_d_causale_ep_tipo tipo
where tipo.ente_proprietario_id=4
and   tipo.causale_ep_tipo_code='LIB'
and   c.causale_ep_tipo_id=tipo.causale_ep_tipo_id
and   c.data_cancellazione is null
and   c.validita_fine is null


select pdc.pdce_conto_id,
       pdc.pdce_conto_code,
       pdc.pdce_conto_desc,
       f.pdce_fam_code
from siac_t_pdce_conto pdc,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f,
     siac_r_pdce_conto_attr r, siac_t_attr a
where pdc.ente_proprietario_id=4
and   pdc.pdce_conto_desc like 'Risultato%'
and   r.pdce_conto_id=pdc.pdce_conto_id
and   a.attr_id=r.attr_id
and   a.attr_code ='pdce_conto_foglia'
and   r.boolean='S'
and   ft.pdce_fam_tree_id=pdc.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
--and   f.pdce_fam_code='PP'
and   pdc.data_cancellazione is null
and   r.data_cancellazione is null
and   r.validita_fine is null
and   f.data_cancellazione is null
and   ft.data_cancellazione is null



select pdc.pdce_conto_code,
       pdc.pdce_conto_desc
from siac_t_pdce_conto pdc
where pdc.ente_proprietario_id=4
and   pdc.pdce_conto_code='2.1.4.01.01.01.001'


insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('DETSALDI',
  'DETERMINAZIONE SALDI CONTI ECONOMICO PATRIMONIALI',
  null,
  1,
  '2016-01-01',
  'admin',
  4
 );

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('CHIPP',
  'CHIUSURA PASSIVITA'' PATRIMONIALI E CONTI ORDINE PASSIVI',
  null, -- CHI 943379
  null, -- 2331711
  2,
  '2016-01-01',
  'admin',
  4
 );

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('CHIAP',
  'CHIUSURA ATTIVITA'' PATRIMONIALI E CONTI ORDINE ATTIVI',
  null, -- CHI 943378
  null, --2331711
  3,
  '2016-01-01',
  'admin',
  4
 );




insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('EPCE',
  'EPILOGO COSTI',
  null, -- EPC 943380
  null, -- 2331714
  4,
  '2016-01-01',
  'admin',
  4
 );

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('EPRE',
  'EPILOGO RICAVI',
  null, -- EPR 943381
  null, -- 2331714
  5,
  '2016-01-01',
  'admin',
  4
 );

 insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('DETREE',
  'DETERMINAZIONE RISULTATO ECONOMICO D''ESERCIZIO',
  null, -- REE 943382
  null, --2331714
  6,
  '2016-01-01',
  'admin',
  4
 );

insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('APEPP',
  'APERTURA PASSIVITA'' PATRIMONIALI E CONTI ORDINE PASSIVI',
  null, -- APE 578452
  null, -- 2331708
  7,
  '2016-01-01',
  'admin',
  4
 );


insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('APEAP',
  'APERTURA ATTIVITA'' PATRIMONIALI E CONTI ORDINE ATTIVI',
  null, -- APE 578453
  null, -- 2331708
  8,
  '2016-01-01',
  'admin',
  4
 );


insert into fase_gen_d_elaborazione_fineanno_tipo
 (
  fase_gen_elab_tipo_code,
  fase_gen_elab_tipo_desc,
  causale_ep_id,
  pdce_conto_ep_id,
  ordine,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 values
 ('STRISC',
  'STORNO RISCONTI',
  null, -- SRI 945761
  null,
  9,
  '2016-01-01',
  'admin',
  4
 );

-- 73983 Risultato economico di esercizio
insert into fase_gen_d_elaborazione_fineanno_tipo_det
(
  fase_gen_elab_tipo_id,
  pdce_conto_id,
  pdce_conto_segno,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select  tipo.fase_gen_elab_tipo_id,
        73983,
        'DARE',
        '2016-01-01',
        'admin',
        4
from fase_gen_d_elaborazione_fineanno_tipo tipo
where tipo.ente_proprietario_id=4
and   tipo.ordine=6

insert into fase_gen_d_elaborazione_fineanno_tipo_det
(
  fase_gen_elab_tipo_id,
  pdce_conto_id,
  pdce_conto_segno,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select  tipo.fase_gen_elab_tipo_id,
        73983,
        'AVERE',
        '2016-01-01',
        'admin',
        4
from fase_gen_d_elaborazione_fineanno_tipo tipo
where tipo.ente_proprietario_id=4
and   tipo.ordine=6