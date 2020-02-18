/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- SELECT PER I CONTI GEN ETC
select tipo.pdce_ct_tipo_code, pdce.*
from siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f, siac_r_pdce_conto_attr r , siac_t_attr a
where f.ente_proprietario_id=4
and   f.pdce_fam_code='EP'
and   ft.pdce_fam_id=f.pdce_fam_id
and   pdce.pdce_fam_tree_id=ft.pdce_fam_tree_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and   r.pdce_conto_id=  pdce.pdce_conto_id
and   a.attr_id=r.attr_id
and   a.attr_code='pdce_conto_foglia'
and   r.boolean='S'

select * from
siac_t_mov_ep_det md,
siac_t_pdce_conto pdce,
siac_t_pdce_fam_tree ft,
siac_d_pdce_fam f,
siac_t_mov_ep m,
siac_t_prima_nota pn,
siac_r_prima_nota_stato pns,
siac_d_prima_nota_stato pnst
where md.pdce_conto_id = pdce.pdce_conto_id
and ft.pdce_fam_tree_id = pdce.pdce_fam_tree_id
and f.pdce_fam_id = 196
and f.ente_proprietario_id=4
AND md.movep_id = m.movep_id
and m.regep_id = pn.pnota_id
and pn.pnota_id = pns.pnota_id
and pns.pnota_stato_id = pnst.pnota_stato_id
and m.movep_id = 143

select ft.*
from siac_d_pdce_fam fam, siac_t_pdce_fam_tree ft
where fam.ente_proprietario_id=4
and   ft.pdce_fam_id=fam.pdce_fam_id


select * from siac_d_ambito
where ente_proprietario_id=4

select c.*
from siac_t_causale_ep c
where c.ente_proprietario_id=4
and   exists (select 1 from siac_d_causale_ep_tipo tipo
              where tipo.ente_proprietario_id=4
			  and   tipo.causale_ep_tipo_code='LIB'
       	      and   c.causale_ep_tipo_id=tipo.causale_ep_tipo_id
             )
and   c.data_cancellazione is null
and   c.validita_fine is null

insert into siac_t_causale_ep
(
 causale_ep_code,
 causale_ep_desc,
 causale_ep_tipo_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 login_creazione,
 ambito_id
 )
 select 'CHI ATT',
        'Chiusura Patrimoniale Attivo',
        tipo.causale_ep_tipo_id,
        now(),
        tipo.ente_proprietario_id,
        'admin',
        'admin',
        a.ambito_id
 from siac_d_ambito a, siac_d_causale_ep_tipo tipo
 where tipo.ente_proprietario_id=4
 and   tipo.causale_ep_tipo_code='LIB'
 and   a.ente_proprietario_id=tipo.ente_proprietario_id
 and   a.ambito_code='AMBITO_FIN'

insert into siac_t_causale_ep
(
 causale_ep_code,
 causale_ep_desc,
 causale_ep_tipo_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 login_creazione,
 ambito_id
 )
 select 'CHI PASS',
        'Chiusura Patrimoniale Passivo',
        tipo.causale_ep_tipo_id,
        now(),
        tipo.ente_proprietario_id,
        'admin',
        'admin',
        a.ambito_id
 from siac_d_ambito a, siac_d_causale_ep_tipo tipo
 where tipo.ente_proprietario_id=4
 and   tipo.causale_ep_tipo_code='LIB'
 and   a.ente_proprietario_id=tipo.ente_proprietario_id
 and   a.ambito_code='AMBITO_FIN'

insert into siac_t_causale_ep
(
 causale_ep_code,
 causale_ep_desc,
 causale_ep_tipo_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 login_creazione,
 ambito_id
 )
 select 'CHI CE',
        'Chiusura Costi',
        tipo.causale_ep_tipo_id,
        now(),
        tipo.ente_proprietario_id,
        'admin',
        'admin',
        a.ambito_id
 from siac_d_ambito a, siac_d_causale_ep_tipo tipo
 where tipo.ente_proprietario_id=4
 and   tipo.causale_ep_tipo_code='LIB'
 and   a.ente_proprietario_id=tipo.ente_proprietario_id
 and   a.ambito_code='AMBITO_FIN'

insert into siac_t_causale_ep
(
 causale_ep_code,
 causale_ep_desc,
 causale_ep_tipo_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 login_creazione,
 ambito_id
 )
 select 'CHI RE',
        'Chiusura Ricavi',
        tipo.causale_ep_tipo_id,
        now(),
        tipo.ente_proprietario_id,
        'admin',
        'admin',
        a.ambito_id
 from siac_d_ambito a, siac_d_causale_ep_tipo tipo
 where tipo.ente_proprietario_id=4
 and   tipo.causale_ep_tipo_code='LIB'
 and   a.ente_proprietario_id=tipo.ente_proprietario_id
 and   a.ambito_code='AMBITO_FIN'

insert into siac_t_causale_ep
(
 causale_ep_code,
 causale_ep_desc,
 causale_ep_tipo_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 login_creazione,
 ambito_id
 )
 select 'REE',
        'Risultato economico esercizio',
        tipo.causale_ep_tipo_id,
        now(),
        tipo.ente_proprietario_id,
        'admin',
        'admin',
        a.ambito_id
 from siac_d_ambito a, siac_d_causale_ep_tipo tipo
 where tipo.ente_proprietario_id=4
 and   tipo.causale_ep_tipo_code='LIB'
 and   a.ente_proprietario_id=tipo.ente_proprietario_id
 and   a.ambito_code='AMBITO_FIN'

-- tutti i conti foglia COSTI
select pdce.pdce_conto_id,  pdce.pdce_conto_code, tipo.pdce_ct_tipo_code, f.pdce_fam_segno
from siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f,
     siac_r_pdce_conto_attr r, siac_t_attr a
where  f.ente_proprietario_id=4
and    f.pdce_fam_code='CE'
and    ft.pdce_fam_id=f.pdce_fam_id
and    pdce.pdce_fam_tree_id=ft.pdce_fam_tree_id
and    tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and    r.pdce_conto_id=pdce.pdce_conto_id
and    a.attr_id=r.attr_id
and    a.attr_code='pdce_conto_foglia'
and    r.boolean='S'
and    pdce.data_cancellazione is null
and    pdce.validita_fine is null
and    r.data_cancellazione is null
and    r.validita_fine is null

begin;
insert into siac_t_causale_ep
(
 causale_ep_code,
 causale_ep_desc,
 causale_ep_tipo_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 login_creazione,
 ambito_id
 )
 select 'SRI',
        'Storno Risconti',
        tipo.causale_ep_tipo_id,
        now(),
        tipo.ente_proprietario_id,
        'admin',
        'admin',
        a.ambito_id
 from siac_d_ambito a, siac_d_causale_ep_tipo tipo
 where tipo.ente_proprietario_id=4
 and   tipo.causale_ep_tipo_code='LIB'
 and   a.ente_proprietario_id=tipo.ente_proprietario_id
 and   a.ambito_code='AMBITO_FIN'

-- movimenti su prime note definitive
-- per bilancio 2016
-- su conti classe foglia CE
select pdce.pdce_conto_code, pdce.pdce_conto_desc, tipo.pdce_ct_tipo_code,
       f.pdce_fam_segno,
       sum( case when upper(movdet.movep_det_segno)=f.pdce_fam_segno then movdet.movep_det_importo else 0 END),
       sum( case when upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo else 0 END),
       sum( case when upper(movdet.movep_det_segno)=f.pdce_fam_segno then movdet.movep_det_importo else 0 END)-
       sum( case when upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo else 0 END)
from siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f,
     siac_r_pdce_conto_attr r, siac_t_attr a,
     siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnotastato,
     siac_t_mov_ep movep, siac_t_mov_ep_det movdet,
     siac_t_bil bil , siac_t_periodo per
where  f.ente_proprietario_id=4
and    f.pdce_fam_code='CE'
and    ft.pdce_fam_id=f.pdce_fam_id
and    pdce.pdce_fam_tree_id=ft.pdce_fam_tree_id
and    tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and    r.pdce_conto_id=pdce.pdce_conto_id
and    a.attr_id=r.attr_id
and    a.attr_code='pdce_conto_foglia'
and    r.boolean='S'
and    movdet.pdce_conto_id=pdce.pdce_conto_id
and    movep.movep_id=movdet.movep_id
and    pnota.pnota_id=movep.regep_id
and    rpnota.pnota_id=pnota.pnota_id
and    pnotastato.pnota_stato_id=rpnota.pnota_stato_id
and    pnotastato.pnota_stato_code='D'
and    bil.bil_id=pnota.bil_id
and    per.periodo_id=bil.periodo_id
and    per.anno::integer=2016
and    pdce.data_cancellazione is null
and    pdce.validita_fine is null
and    r.data_cancellazione is null
and    r.validita_fine is null
and    movdet.data_cancellazione is null
and    movdet.validita_fine is null
and    movep.data_cancellazione is null
and    movep.validita_fine is null
and    pnota.data_cancellazione is null
and    pnota.validita_fine is null
and    rpnota.data_cancellazione is null
and    rpnota.validita_fine is null
group by pdce.pdce_conto_code, pdce.pdce_conto_desc, tipo.pdce_ct_tipo_code,
         f.pdce_fam_segno,movdet.movep_det_segno
having sum( case when upper(movdet.movep_det_segno)=f.pdce_fam_segno then movdet.movep_det_importo else 0 END)-
       sum( case when upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo else 0 END)!=0
order by pdce.pdce_conto_code

-- inserimento elaborazione in fase_gen_t_elaborazione_fineanno in stato IN-1
-- inserimento dettaglio in  fase_gen_t_elaborazione_fineanno_det con ordine=1 per calcolo saldi in stato IN-1
-- inserimento in  fase_gen_t_elaborazione_fineanno_saldi per fase_gen_t_elaborazione_fineanno_det.fase_gen_det_id
   -- per tutti tipi di conti contemplati
-- se controlli sui saldi di tutti i conti inseriti sopra Ok
-- se controlli sui conti epilogativi ok
-- allora chiusura di    fase_gen_t_elaborazione_fineanno_det con ordine=1 con stato OK
-- inserimento dettaglio in  fase_gen_t_elaborazione_fineanno_det con ordine=2  in stato IN-1 per inserimento pnnota CE
-- se ok chiusura fase_gen_t_elaborazione_fineanno_det con ordine=2 con stato OK
....

select *
from fase_gen_t_elaborazione_fineanno
where ente_proprietario_id=4
select *
from fase_gen_t_elaborazione_fineanno_det
where ente_proprietario_id=4
select *
from fase_gen_t_elaborazione_fineanno_saldi

delete from fase_gen_t_elaborazione_fineanno_saldi

insert into fase_gen_t_elaborazione_fineanno
(
  fase_gen_elab_esito,
  fase_gen_elab_esito_msg,
  bil_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
 )
 (select 'IN-1',
	     'ELABORAZIONE SCRITTURE GEN DI CHIUSURA/APERTURA FINE ANNO - INIZIO',
         bil.bil_id,
         now(),
         'td_gen_chiape',
         bil.ente_proprietario_id
  from siac_t_bil bil, siac_t_periodo per
  where bil.ente_proprietario_id=4
  and   per.periodo_id=bil.periodo_id
  and   per.anno::integer=2016
 );

insert into fase_gen_t_elaborazione_fineanno_det
(
  fase_gen_elab_id,
  fase_gen_elab_tipo_id,
  fase_gen_det_elab_esito,
  fase_gen_det_elab_esito_msg,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select  fase.fase_gen_elab_id,
        fasetipo.fase_gen_elab_tipo_id,
        'IN-1',
        'ELABORAZIONE SCRITTURE GEN DI CHIUSURA/APERTURA FINE ANNO - CALCOLO SALDI - INIZIO',
        now(),
        'td_gen_chiape',
        fase.ente_proprietario_id
from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_bil bil, siac_t_periodo per
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
--and   fasetipo.fase_gen_elab_tipo_code='DETSALDI'
and   fase.data_cancellazione is null
and   fase.validita_fine is null

-- costi
insert into fase_gen_t_elaborazione_fineanno_saldi
(
  fase_gen_elab_det_id,
  pdce_conto_id,
  pdce_conto_segno,
  pdce_conto_dare,
  pdce_conto_avere,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select fasedet.fase_gen_elab_det_id,
       pdce.pdce_conto_id,
       f.pdce_fam_segno,
       sum( ( case when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end )),
       sum( ( case when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='DARE'  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end )),
       now(),
       'td_gen_chiape',
       bil.ente_proprietario_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f,
     siac_r_pdce_conto_attr r, siac_t_attr a,
     siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnotastato,
     siac_t_mov_ep movep, siac_t_mov_ep_det movdet
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   pnota.bil_id=bil.bil_id
and   rpnota.pnota_id=pnota.pnota_id
and   pnotastato.pnota_stato_id=rpnota.pnota_stato_id
and   pnotastato.pnota_stato_code='D'
and   movep.regep_id=pnota.pnota_id
and   movdet.movep_id=movep.movep_id
and   pdce.pdce_conto_id=movdet.pdce_conto_id
and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   f.pdce_fam_code='CE'
and   f.ente_proprietario_id=bil.ente_proprietario_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and   r.pdce_conto_id=pdce.pdce_conto_id
and   a.attr_id=r.attr_id
and   a.attr_code='pdce_conto_foglia'
and   r.boolean='S'
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   pnota.data_cancellazione is null
and   pnota.validita_fine is null
and   rpnota.data_cancellazione is null
and   rpnota.validita_fine is null
and   movdet.data_cancellazione is null
and   movdet.validita_fine is null
and   movep.data_cancellazione is null
and   movep.validita_fine is null
and   pdce.data_cancellazione is null
and   pdce.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
group by fasedet.fase_gen_elab_det_id,
         pdce.pdce_conto_id,
         f.pdce_fam_segno,
         bil.bil_id
having sum( ( case when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end ))-
       sum( ( case when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='DARE'  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end ))!=0

-- ricavi
insert into fase_gen_t_elaborazione_fineanno_saldi
(
  fase_gen_elab_det_id,
  pdce_conto_id,
  pdce_conto_segno,
  pdce_conto_dare,
  pdce_conto_avere,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select fasedet.fase_gen_elab_det_id,
       pdce.pdce_conto_id,
       f.pdce_fam_segno,
       sum( ( case when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end )),
       sum( ( case when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='DARE'  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end )),
       now(),
       'td_gen_chiape',
       bil.ente_proprietario_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f,
     siac_r_pdce_conto_attr r, siac_t_attr a,
     siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnotastato,
     siac_t_mov_ep movep, siac_t_mov_ep_det movdet
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   pnota.bil_id=bil.bil_id
and   rpnota.pnota_id=pnota.pnota_id
and   pnotastato.pnota_stato_id=rpnota.pnota_stato_id
and   pnotastato.pnota_stato_code='D'
and   movep.regep_id=pnota.pnota_id
and   movdet.movep_id=movep.movep_id
and   pdce.pdce_conto_id=movdet.pdce_conto_id
and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   f.pdce_fam_code='RE'
and   f.ente_proprietario_id=bil.ente_proprietario_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and   r.pdce_conto_id=pdce.pdce_conto_id
and   a.attr_id=r.attr_id
and   a.attr_code='pdce_conto_foglia'
and   r.boolean='S'
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   pnota.data_cancellazione is null
and   pnota.validita_fine is null
and   rpnota.data_cancellazione is null
and   rpnota.validita_fine is null
and   movdet.data_cancellazione is null
and   movdet.validita_fine is null
and   movep.data_cancellazione is null
and   movep.validita_fine is null
and   pdce.data_cancellazione is null
and   pdce.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
group by fasedet.fase_gen_elab_det_id,
         pdce.pdce_conto_id,
         f.pdce_fam_segno,
         bil.bil_id
having sum( ( case when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end ))-
       sum( ( case when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='DARE'  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end ))!=0


-- debiti, conti ordine passivi
insert into fase_gen_t_elaborazione_fineanno_saldi
(
  fase_gen_elab_det_id,
  pdce_conto_id,
  pdce_conto_segno,
  pdce_conto_dare,
  pdce_conto_avere,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select fasedet.fase_gen_elab_det_id,
       pdce.pdce_conto_id,
       f.pdce_fam_segno,
       sum( ( case when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end )),
       sum( ( case when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='DARE'  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end )),
       now(),
       'td_gen_chiape',
       bil.ente_proprietario_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f,
     siac_r_pdce_conto_attr r, siac_t_attr a,
     siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnotastato,
     siac_t_mov_ep movep, siac_t_mov_ep_det movdet
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   pnota.bil_id=bil.bil_id
and   rpnota.pnota_id=pnota.pnota_id
and   pnotastato.pnota_stato_id=rpnota.pnota_stato_id
and   pnotastato.pnota_stato_code='D'
and   movep.regep_id=pnota.pnota_id
and   movdet.movep_id=movep.movep_id
and   pdce.pdce_conto_id=movdet.pdce_conto_id
and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   f.pdce_fam_code in ('PP','OP')
and   f.ente_proprietario_id=bil.ente_proprietario_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and   r.pdce_conto_id=pdce.pdce_conto_id
and   a.attr_id=r.attr_id
and   a.attr_code='pdce_conto_foglia'
and   r.boolean='S'
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   pnota.data_cancellazione is null
and   pnota.validita_fine is null
and   rpnota.data_cancellazione is null
and   rpnota.validita_fine is null
and   movdet.data_cancellazione is null
and   movdet.validita_fine is null
and   movep.data_cancellazione is null
and   movep.validita_fine is null
and   pdce.data_cancellazione is null
and   pdce.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
group by fasedet.fase_gen_elab_det_id,
         pdce.pdce_conto_id,
         f.pdce_fam_segno,
         bil.bil_id
having sum( ( case when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end ))-
       sum( ( case when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='DARE'  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end ))!=0

-- crediti, conti ordine attivi
insert into fase_gen_t_elaborazione_fineanno_saldi
(
  fase_gen_elab_det_id,
  pdce_conto_id,
  pdce_conto_segno,
  pdce_conto_dare,
  pdce_conto_avere,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select fasedet.fase_gen_elab_det_id,
       pdce.pdce_conto_id,
       f.pdce_fam_segno,
       sum( ( case when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end )),
       sum( ( case when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='DARE'  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end )),
       now(),
       'td_gen_chiape',
       bil.ente_proprietario_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f,
     siac_r_pdce_conto_attr r, siac_t_attr a,
     siac_t_prima_nota pnota, siac_r_prima_nota_stato rpnota, siac_d_prima_nota_stato pnotastato,
     siac_t_mov_ep movep, siac_t_mov_ep_det movdet
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   pnota.bil_id=bil.bil_id
and   rpnota.pnota_id=pnota.pnota_id
and   pnotastato.pnota_stato_id=rpnota.pnota_stato_id
and   pnotastato.pnota_stato_code='D'
and   movep.regep_id=pnota.pnota_id
and   movdet.movep_id=movep.movep_id
and   pdce.pdce_conto_id=movdet.pdce_conto_id
and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   f.pdce_fam_code in ('AP','OA')
and   f.ente_proprietario_id=bil.ente_proprietario_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and   r.pdce_conto_id=pdce.pdce_conto_id
and   a.attr_id=r.attr_id
and   a.attr_code='pdce_conto_foglia'
and   r.boolean='S'
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   pnota.data_cancellazione is null
and   pnota.validita_fine is null
and   rpnota.data_cancellazione is null
and   rpnota.validita_fine is null
and   movdet.data_cancellazione is null
and   movdet.validita_fine is null
and   movep.data_cancellazione is null
and   movep.validita_fine is null
and   pdce.data_cancellazione is null
and   pdce.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
group by fasedet.fase_gen_elab_det_id,
         pdce.pdce_conto_id,
         f.pdce_fam_segno,
         bil.bil_id
having sum( ( case when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='DARE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end ))-
       sum( ( case when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)=f.pdce_fam_segno  then movdet.movep_det_importo
                   when f.pdce_fam_segno='AVERE' and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then 0
                   when f.pdce_fam_segno='DARE'  and upper(movdet.movep_det_segno)!=f.pdce_fam_segno then movdet.movep_det_importo
				   else 0 end ))!=0

-- update per segno_errato su singoli conti
update      fase_gen_t_elaborazione_fineanno_saldi fase
set   pdce_conto_saldo_errato=
       (case when fase.pdce_conto_segno='DARE' and  fase.pdce_conto_dare-fase.pdce_conto_avere<0 then true
             when fase.pdce_conto_segno='AVERE' and fase.pdce_conto_dare-fase.pdce_conto_avere>0 then true
             else false
        end)

select (case when f.pdce_fam_code='CE' then 1
            when f.pdce_fam_code='RE' then 2
            when f.pdce_fam_code in ('PP','OP') then 3
            when f.pdce_fam_code in ('AP','OA') then 4
            else 0 end ) ordine,
       pdce.pdce_conto_code, pdce.pdce_conto_desc,
       f.pdce_fam_code, f.pdce_fam_desc, f.pdce_fam_segno,
       fasesaldi.pdce_conto_saldo_errato,
       fasesaldi.pdce_conto_segno,
       fasesaldi.pdce_conto_dare,
       fasesaldi.pdce_conto_avere,
       fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere saldo
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     fase_gen_t_elaborazione_fineanno_saldi fasesaldi,
     siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   fasesaldi.fase_gen_elab_det_id=fasedet.fase_gen_elab_det_id
and   pdce.pdce_conto_id=fasesaldi.pdce_conto_id
and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   f.ente_proprietario_id=bil.ente_proprietario_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   fasesaldi.data_cancellazione is null
and   fasesaldi.validita_fine is null
and   pdce.data_cancellazione is null
and   pdce.validita_fine is null
order by 1 ,pdce.pdce_conto_code


-- saldo_epcc (epilogativo conto economico ) e saldo_epcp (epilogativo conto bilancio patr.)
-- devono essere uguali e di segno opposto
select sum( case when f.pdce_fam_code='CE' then  fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere else 0 end ) saldo_costi,
       sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) saldo_epcc_dare,
	   sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) saldo_epcc_avere,
       sum( case when f.pdce_fam_code='RE' then  fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere else 0 end ) saldo_ricavi,
       sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) saldo_epcr_dare,
       sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) saldo_epcr_avere,
       (sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
	   (sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) saldo_epcc,
       sum( case when f.pdce_fam_code in ('PP','OP') then  fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere else 0 end ) saldo_passivo,
       sum( case when f.pdce_fam_code in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) saldo_epcp_dare,
	   sum( case when f.pdce_fam_code  in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) saldo_epcp_avere,
       sum( case when f.pdce_fam_code in ('AP','OA') then  fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere else 0 end ) saldo_attivo,
      sum( case when f.pdce_fam_code in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) saldo_epca_dare,
	   sum( case when f.pdce_fam_code  in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) saldo_epca_avere ,
      (sum( case when f.pdce_fam_code in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
       (sum( case when f.pdce_fam_code  in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code  in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) saldo_epcp,
     ( case when
       sign(( sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
	   (sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) )=
       sign((sum( case when f.pdce_fam_code in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
       (sum( case when f.pdce_fam_code  in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code  in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) ) then false
       else true  end)   segno_saldo_diverso  ,
     ( case when
       abs(( sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
	   (sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) )=
       abs((sum( case when f.pdce_fam_code in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
       (sum( case when f.pdce_fam_code  in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code  in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) ) then true
       else false end ) saldo_uguale
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     fase_gen_t_elaborazione_fineanno_saldi fasesaldi,
     siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   fasesaldi.fase_gen_elab_det_id=fasedet.fase_gen_elab_det_id
and   pdce.pdce_conto_id=fasesaldi.pdce_conto_id
and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   f.ente_proprietario_id=bil.ente_proprietario_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   fasesaldi.data_cancellazione is null
and   fasesaldi.validita_fine is null
and   pdce.data_cancellazione is null
and   pdce.validita_fine is null


select
     ( case when
       sign(( sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
	   (sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) )=
       sign((sum( case when f.pdce_fam_code in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
       (sum( case when f.pdce_fam_code  in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code  in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) ) then false
       else true  end)   segno_saldo_diverso  ,
     ( case when
       abs(( sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
	   (sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) )=
       abs((sum( case when f.pdce_fam_code in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
       (sum( case when f.pdce_fam_code  in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code  in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) ) then true
       else false end ) saldo_uguale
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     fase_gen_t_elaborazione_fineanno_saldi fasesaldi,
     siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   fasesaldi.fase_gen_elab_det_id=fasedet.fase_gen_elab_det_id
and   pdce.pdce_conto_id=fasesaldi.pdce_conto_id
and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   f.ente_proprietario_id=bil.ente_proprietario_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   fasesaldi.data_cancellazione is null
and   fasesaldi.validita_fine is null
and   pdce.data_cancellazione is null
and   pdce.validita_fine is null

/*
saldo_costi  20397011,53  dare    EPC dare 20397011,53
saldo_ricavi -42115982,87 avere   EPC avere  42115982,87
saldo_epc 20397011,53-42115982,87=-21718971,34 AVERE (se positivo dare, se negativo avere)-21718971,34
select 20397011.53-42115982.87
saldo passivo 23426600,59 avere   EPP dare 23426600,59
salvo attivo  -1794874,5  dare    EPP avere 1794874,5
saldo_epp  23426600,59-1794874,5=25221475,09 DARE ( se positivo dare, se negativo avere ) 21631726,09 */
--select 23426600.59-1794874.5

--select 24534540.82+63448996.63=87983537,45
--select 1107940.23+65243871.13=66351811,36

--select 87983537.45-66351811.36=21631726,09
-- 21631726,09
-- in questo caso sbagliato

-- se fosse giusto si potrebbe procedere

-- chiusura fase_gen_t_elaborazione_fineanno_det con ordine=1

-- errore per saldi errati

select * from fase_gen_t_elaborazione_fineanno_det
begin;
update  fase_gen_t_elaborazione_fineanno_det fasedet
set  fase_gen_det_elab_esito='KO',
     fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - SALDI ERRATI - TERMINE',
     data_modifica=now(),
     validita_fine=now(),
     login_operazione=fasedet.login_operazione||'_TERMINE'
from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_bil bil, siac_t_periodo per
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_elab_tipo_id=fasetipo.fase_gen_elab_tipo_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   exists ( select 1 from fase_gen_t_elaborazione_fineanno_saldi fasesaldi
			   where  fasesaldi.fase_gen_elab_det_id=fasedet.fase_gen_elab_det_id
               and    fasesaldi.pdce_conto_saldo_errato=true
               and    fasesaldi.data_cancellazione is null
               and    fasesaldi.validita_fine is null
             )
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   fase.data_cancellazione is null
and   fase.validita_fine is null

-- errore per saldi conti epilogativi errati
rollback;
begin;
update fase_gen_t_elaborazione_fineanno_det fasedet
set  fase_gen_det_elab_esito='KO',
     fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - SALDI EPILOGO ECON. PATR. NON COERENTI - TERMINE',
     data_modifica=now(),
     validita_fine=now(),
     login_operazione=fasedet.login_operazione||'_TERMINE'
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   false= (
     select
     ( case when
       sign(( sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
	   (sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) )=
       sign((sum( case when f.pdce_fam_code in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
       (sum( case when f.pdce_fam_code  in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code  in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) ) then false
       else true  end)   and
     ( case when
       abs(( sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
	   (sum( case when f.pdce_fam_code='CE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code='RE' and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) )=
       abs((sum( case when f.pdce_fam_code in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere>0
            then  abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) -
       (sum( case when f.pdce_fam_code  in ('PP','OP') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) +
        sum( case when f.pdce_fam_code  in ('AP','OA') and fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere<0
            then abs(fasesaldi.pdce_conto_dare-fasesaldi.pdce_conto_avere) else 0 end ) ) ) then true
       else false end )
     from   fase_gen_t_elaborazione_fineanno_saldi fasesaldi,
            siac_t_pdce_conto pdce,siac_d_pdce_conto_tipo tipo,
            siac_t_pdce_fam_tree ft,
            siac_d_pdce_fam f
     where   fasesaldi.fase_gen_elab_det_id=fasedet.fase_gen_elab_det_id
     and   pdce.pdce_conto_id=fasesaldi.pdce_conto_id
     and   ft.pdce_fam_tree_id=pdce.pdce_fam_tree_id
     and   f.pdce_fam_id=ft.pdce_fam_id
     and   f.ente_proprietario_id=bil.ente_proprietario_id
     and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id
     and   fasesaldi.data_cancellazione is null
     and   fasesaldi.validita_fine is null
     and   pdce.data_cancellazione is null
     and   pdce.validita_fine is null
    )
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null

-- chiusura OK
begin;
update  fase_gen_t_elaborazione_fineanno_det fasedet
set  fase_gen_det_elab_esito='OK',
     fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - TERMINE',
     data_modifica=now(),
     validita_fine=now(),
     login_operazione=fasedet.login_operazione||'_TERMINE'
from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_bil bil, siac_t_periodo per
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=1
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_elab_tipo_id=fasetipo.fase_gen_elab_tipo_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null

select * from fase_gen_t_elaborazione_fineanno_det

-- inserimento fase_gen_t_elaborazione_fineanno_det con ordine=2
begin;
rollback;
insert into fase_gen_t_elaborazione_fineanno_det
(
  fase_gen_elab_id,
  fase_gen_elab_tipo_id,
  fase_gen_det_elab_esito,
  fase_gen_det_elab_esito_msg,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select  fase.fase_gen_elab_id,
        fasetipo.fase_gen_elab_tipo_id,
        'IN-1',
        'ELABORAZIONE SCRITTURE GEN DI CHIUSURA/APERTURA FINE ANNO - INSERIMENTO CHI. PASS.PATR. - INIZIO ',
        now(),
        'td_gen_chiape',
        fase.ente_proprietario_id
from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_bil bil, siac_t_periodo per
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=2
and   exists ( select 1 from fase_gen_t_elaborazione_fineanno_det detprec, fase_gen_d_elaborazione_fineanno_tipo fasetipoprec
               where detprec.fase_gen_elab_id=fase.fase_gen_elab_id
               and   detprec.fase_gen_det_elab_esito='OK'
               and   fasetipoprec.fase_gen_elab_tipo_id=detprec.fase_gen_elab_tipo_id
               and   fasetipoprec.ordine=fasetipo.ordine-1
               and   detprec.data_cancellazione is null
              )
and   fase.data_cancellazione is null
and   fase.validita_fine is null


select substring('td_gen_chiape$9999'
       from strpos ('td_gen_chiape$9999','$')+1
         for (length ('td_gen_chiape$9999')-strpos ('td_gen_chiape$9999','$'))::integer)

select * from fase_gen_d_elaborazione_fineanno_tipo

-- inserimento prima nota per scrittura di chiusura passivita patrimoniali

select *
from siac_t_prima_nota
where ente_proprietario_id=4
and   login_operazione like 'td_gen_chiape$%'

select * from siac_r_prima_nota_stato
where ente_proprietario_id=4
and   login_operazione like 'td_gen_chiape%'


rollback;
begin;
insert into siac_t_prima_nota
(pnota_numero,
 pnota_desc,
 pnota_data,
 bil_id,
 causale_ep_tipo_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 login_creazione,
 ambito_id)
select max(num.pnota_numero)+1,
       fasetipo.fase_gen_elab_tipo_desc,
       now(),
       bil.bil_id,
       c.causale_ep_tipo_id,
       now(),
       bil.ente_proprietario_id,
       'td_gen_chiape$'||fasedet.fase_gen_elab_det_id::varchar,
       'td_gen_chiape',
       a.ambito_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_prima_nota_num num, siac_d_ambito a, siac_t_causale_ep c
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=2
and   a.ente_proprietario_id=bil.ente_proprietario_id
and   a.ambito_code='AMBITO_FIN'
and   num.ente_proprietario_id=bil.ente_proprietario_id
and   num.pnota_anno::integer=per.anno::integer
and   c.causale_ep_id=fasetipo.causale_ep_id
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   c.data_cancellazione is null
and   c.validita_fine is null
group by fasetipo.fase_gen_elab_tipo_desc,
         bil.bil_id,
         c.causale_ep_tipo_id,bil.ente_proprietario_id,fasedet.fase_gen_elab_det_id, a.ambito_id

insert into siac_r_prima_nota_stato
( pnota_id,
  pnota_stato_id,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select pnota.pnota_id,
       stato.pnota_stato_id,
       now(),
       'td_gen_chiape',
       bil.ente_proprietario_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_prima_nota pnota, siac_d_prima_nota_stato stato
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=2
and   pnota.login_operazione like 'td_gen_chiape$%'
and   fasedet.fase_gen_elab_det_id=
      substring(pnota.login_operazione
      from strpos (pnota.login_operazione,'$')+1 for (length (pnota.login_operazione)-strpos (pnota.login_operazione,'$')))::integer
and   pnota.bil_id=bil.bil_id
and   stato.ente_proprietario_id=bil.ente_proprietario_id
and   stato.pnota_stato_code='P'
and   pnota.data_cancellazione is null
and   pnota.validita_fine is null
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null

update siac_t_prima_nota_num num
set pnota_numero=num.pnota_numero+1
where num.ente_proprietario_id=4
and   num.pnota_anno::integer=2016;
-- 15267
select * from siac_t_prima_nota_num num
where num.ente_proprietario_id=4
and   num.pnota_anno::integer=2016

-- inserimento movimento ep  per chiusura passivita patrimoniali

rollback;
begin;
insert into siac_t_mov_ep
( movep_code,
  movep_desc,
  causale_ep_id,
  regep_id,
  regmovfin_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione,
  ambito_id
)
select max(num.movep_code)+1,
       fasetipo.fase_gen_elab_tipo_desc,
       fasetipo.causale_ep_id,
       pnota.pnota_id,
       null,
       now(),
       bil.ente_proprietario_id,
       'td_gen_chiape$'||fasedet.fase_gen_elab_det_id::varchar,
       a.ambito_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_mov_ep_num num, siac_d_ambito a, siac_t_prima_nota pnota
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=2
and   a.ente_proprietario_id=bil.ente_proprietario_id
and   a.ambito_code='AMBITO_FIN'
and   num.ente_proprietario_id=bil.ente_proprietario_id
and   num.movep_anno::integer=per.anno::integer
and   pnota.bil_id=bil.bil_id
and   pnota.login_operazione like 'td_gen_chiape$%'
and   substring(pnota.login_operazione
      from strpos (pnota.login_operazione,'$')+1
      for (length (pnota.login_operazione)-strpos (pnota.login_operazione,'$')))::integer=fasedet.fase_gen_elab_det_id
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   pnota.data_cancellazione is null
and   pnota.validita_fine is null
group by fasetipo.fase_gen_elab_tipo_desc,fasetipo.causale_ep_id,pnota.pnota_id,
         bil.ente_proprietario_id,fasedet.fase_gen_elab_det_id, a.ambito_id
-- 15718


update siac_t_mov_ep_num num
set movep_code=num.movep_code+1
where num.ente_proprietario_id=4
and   num.movep_anno::integer=2016

select *
from siac_t_mov_ep_num num
where num.ente_proprietario_id=4
and   num.movep_anno::integer=2016


select  e.ente_denominazione, row_number() over (order by e.ente_proprietario_id)
from siac_t_ente_proprietario e
select * From fase_gen_t_elaborazione_fineanno_saldi
where pdce_conto_id=74649

insert into siac_t_mov_ep_det
(movep_det_code,
 movep_det_desc,
 movep_det_importo,
 movep_det_segno,
 movep_id,
 pdce_conto_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 ambito_id
)
select row_number() over (order by saldi.fase_gen_elab_saldi_id),
	   null,
       abs(saldi.pdce_conto_dare-saldi.pdce_conto_avere),
       (case when saldi.pdce_conto_segno='DARE' then 'Avere' else 'Dare' end),
       ep.movep_id,
       pdce.pdce_conto_id,
       now(),
       bil.ente_proprietario_id,
       'td_gen_chiape$'||fasedet.fase_gen_elab_det_id::varchar,
       ep.ambito_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_mov_ep ep,
     fase_gen_t_elaborazione_fineanno_saldi saldi,
     fase_gen_t_elaborazione_fineanno_det   fasedetS,
     fase_gen_d_elaborazione_fineanno_tipo  fasetipoS,
     siac_t_pdce_conto pdce,
     siac_t_pdce_fam_tree ft,
     siac_d_pdce_fam f
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=2
and   ep.login_operazione like 'td_gen_chiape$%'
and   substring(ep.login_operazione
      from strpos (ep.login_operazione,'$')+1
      for (length (ep.login_operazione)-strpos (ep.login_operazione,'$')))::integer=fasedet.fase_gen_elab_det_id
and   saldi.fase_gen_elab_det_id=fasedetS.fase_gen_elab_det_id
and   saldi.pdce_conto_saldo_errato=false
and   fasedetS.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasetipoS.fase_gen_elab_tipo_id=fasedetS.fase_gen_elab_tipo_id
and   fasetipoS.ordine=1
and   fasedetS.fase_gen_det_elab_esito='OK'
and   pdce.pdce_conto_id=saldi.pdce_conto_id
and   pdce.pdce_fam_tree_id=ft.pdce_fam_tree_id
and   f.pdce_fam_id=ft.pdce_fam_id
and   f.pdce_fam_code in ('PP','OP')
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   ep.data_cancellazione is null
and   ep.validita_fine is null
and   fasedetS.data_cancellazione is null
and   pdce.data_cancellazione is null
and   pdce.validita_fine is null
and   saldi.data_cancellazione is null
and   saldi.validita_fine is null
order by saldi.fase_gen_elab_saldi_id

insert into siac_t_mov_ep_det
(movep_det_code,
 movep_det_segno,
 movep_det_importo,
 movep_id,
 pdce_conto_id,
 validita_inizio,
 ente_proprietario_id,
 login_operazione,
 ambito_id
)
(with
movEpTot as
(
select   max(detep.movep_det_code) max_movep_det_code,
         sum(detep.movep_det_importo) movep_det_importo_tot,
         detep.movep_det_segno movep_det_segno,
         ep.movep_id movep_id,
         fasetipo.pdce_conto_ep_id pdce_conto_ep_id,
         bil.ente_proprietario_id ente_proprietario_id,
         'td_gen_chiape$'||fasedet.fase_gen_elab_det_id::varchar login_operazione,
         ep.ambito_id ambito_id
from siac_t_bil bil, siac_t_periodo per,
     fase_gen_t_elaborazione_fineanno fase,
     fase_gen_t_elaborazione_fineanno_det fasedet,
     fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_mov_ep ep,siac_t_mov_ep_det detep
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=2
and   ep.login_operazione like 'td_gen_chiape$%'
and   substring(ep.login_operazione
      from strpos (ep.login_operazione,'$')+1
      for (length (ep.login_operazione)-strpos (ep.login_operazione,'$')))::integer=fasedet.fase_gen_elab_det_id
and   detep.movep_id=ep.movep_id
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null
and   fasedet.validita_fine is null
and   ep.data_cancellazione is null
and   ep.validita_fine is null
and   detep.data_cancellazione is null
and   detep.validita_fine is null
group by detep.movep_det_segno ,
         ep.movep_id ,
         fasetipo.pdce_conto_ep_id ,
         bil.ente_proprietario_id ,
		 fasedet.fase_gen_elab_det_id,
         ep.ambito_id
)
select  movEpTot.max_movep_det_code+1,
        (case when movEpTot.movep_det_segno='DARE' then 'Avere' else 'Dare' end),
		movEpTot.movep_det_importo_tot,
        movEpTot.movep_id,
        movEpTot.pdce_conto_ep_id,
        now(),
        movEpTot.ente_proprietario_id,
        movEpTot.login_operazione,
        movEpTot.ambito_id
from  movEpTot
);

select det.movep_det_code, det.pdce_conto_id,
       case when det.movep_det_segno='DARE' then det.movep_det_importo else 0 end,
       case when det.movep_det_segno='AVERE' then det.movep_det_importo else 0 end
from siac_t_mov_ep_det det
where det.ente_proprietario_id=4
and   det.login_operazione like 'td_gen_chiape%'
order by 1

select * from fase_gen_t_elaborazione_fineanno_det fasedet
-- chiusura OK
begin;
update  fase_gen_t_elaborazione_fineanno_det fasedet
set  movep_id=ep.movep_id,
     pnota_id=ep.regep_id,
     fase_gen_det_elab_esito='OK',
     fase_gen_det_elab_esito_msg=fasedet.fase_gen_det_elab_esito_msg||' - TERMINE',
     data_modifica=now(),
     validita_fine=now(),
     login_operazione=fasedet.login_operazione||'_TERMINE'
from fase_gen_t_elaborazione_fineanno fase, fase_gen_d_elaborazione_fineanno_tipo fasetipo,
     siac_t_bil bil, siac_t_periodo per, siac_t_mov_ep ep
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   fase.bil_id=bil.bil_id
and   fase.fase_gen_elab_esito='IN-1'
and   fasetipo.ente_proprietario_id=bil.ente_proprietario_id
and   fasetipo.ordine=2
and   fasedet.fase_gen_elab_id=fase.fase_gen_elab_id
and   fasedet.fase_gen_elab_tipo_id=fasetipo.fase_gen_elab_tipo_id
and   fasedet.fase_gen_det_elab_esito='IN-1'
and   ep.ente_proprietario_id=bil.ente_proprietario_id
and   ep.login_operazione like 'td_gen_chiape$%'
and   substring(ep.login_operazione
      from strpos (ep.login_operazione,'$')+1
      for (length (ep.login_operazione)-strpos (ep.login_operazione,'$')))::integer=fasedet.fase_gen_elab_det_id
and   fase.data_cancellazione is null
and   fase.validita_fine is null
and   fasedet.data_cancellazione is null

select *
from siac_t_prima_nota pnota
where pnota.login_operazione like 'td_gen_chiape$%'

select *
from siac_r_prima_nota_stato pnota
where pnota.login_operazione like 'td_gen_chiape%'

select *
from siac_t_mov_ep pnota
where pnota.login_operazione like 'td_gen_chiape$%'

select *
from siac_t_mov_ep_det pnota
where pnota.login_operazione like 'td_gen_chiape%'

select max(pnota.movep_det_code) ,pnota.movep_det_segno
from siac_t_mov_ep_det pnota
where pnota.login_operazione like 'td_gen_chiape%'
group by pnota.movep_det_segno

select distinct  pnota.movep_det_segno
from siac_t_mov_ep_det pnota

update siac_t_mov_ep_det
set movep_det_segno='Dare'
where login_operazione like 'td_gen_chiape%'
and movep_det_segno='DARE'

update siac_t_mov_ep_det
set movep_det_segno='Avere'
where login_operazione like 'td_gen_chiape%'
and movep_det_segno='AVERE'



select *
from siac_t_pdce_conto pdce
where pdce.pdce_conto_id=2331711--2331714

select  pdce.pdce_conto_id,pdce.pdce_conto_code,
        pdce.pdce_conto_desc,
        a.attr_code, r.boolean
from siac_t_pdce_conto pdce, siac_r_pdce_conto_attr r, siac_t_attr a
where pdce.pdce_conto_id  in (2331714,2331711)
and   r.pdce_conto_id=pdce.pdce_conto_id
and   a.attr_id=r.attr_id
and   a.attr_code like '%foglia%'

select *
from siac_t_pdce_conto pdce
where pdce.ente_proprietario_id=4
and   pdce.pdce_conto_code='8.2.01.01.01'

select * from fase_gen_d_elaborazione_fineanno_tipo tipo
where tipo.ente_proprietario_id=4

select *
from fase_gen_t_elaborazione_fineanno fase
where fase.ente_proprietario_id=4
order by fase.fase_gen_elab_id desc

select *
from fase_gen_t_elaborazione_fineanno_det fase
where fase.ente_proprietario_id=4
and   fase.fase_gen_elab_id=31
order by fase.fase_gen_elab_id desc,fase.fase_gen_elab_det_id desc

select *
from fase_gen_t_elaborazione_fineanno_saldi fase
where fase.ente_proprietario_id=4
and   date_trunc('DAY', data_creazione)=date_trunc('DAY', now()::timestamp)
order by fase.fase_gen_elab_det_id desc

select *
from fase_gen_t_elaborazione_fineanno_log log
where log.fase_gen_elab_id=23
order by log.fase_gen_elab_log_id

begin;
select *
from fnc_fase_gen_elaborazione_fineanno
 (
  4,
  2016,
  'td_gen_chiape',
  now()::timestamp
 )
rollback;


select *
from siac_r_prima_nota r
where r.pnota_id_da=161

 -- per EPC ,EPR bisogna usare epilogativo economico e non lo stesso dei patrimoniali
 -- per REE si va poi a vedere il suo segna , se AVERE --> UTILE si chiude lui in dare e si apre utile in avere
 --                                         , se DATE  --> PERDITA si chiude lui in avere e si apre perdita in dare

 -- EPC 70 Avere 20397011.53
 -- EPR 18 Dare 42115982.87

 -- movEpcImporto=20397011.53
 -- pdceContoEpReeId=2331714
 -- movEprImporto=42115982.87
 -- saldoREE=-21718971.34

 select *
 from siac_t_mov_ep_det det
 where det.movep_id in (168873,168874,168875)
 and   det.movep_det_code::integer=1


   select *--det.pdce_conto_id into pdceContoReeId
    from  fase_gen_d_elaborazione_fineanno_tipo tipo, fase_gen_d_elaborazione_fineanno_tipo_det det
    where tipo.ente_proprietario_id=4
    and   tipo.ordine=6
    and   det.fase_gen_elab_tipo_id=tipo.fase_gen_elab_tipo_id
--    and   det.pdce_conto_segno=segnoREE;

-- REE 21718971,34
 select det.movep_det_code, det.movep_det_desc,
        det.movep_det_segno,
        det.movep_det_importo , pdce.pdce_conto_code, pdce.pdce_conto_desc
 from siac_t_mov_ep_det det, siac_t_pdce_conto pdce
 where det.movep_id=168901
 and   pdce.pdce_conto_id=det.pdce_conto_id

 -- ricavi EP  avere 42115982,87
 select det.movep_det_code, det.movep_det_desc,
        det.movep_det_segno,
        det.movep_det_importo , pdce.pdce_conto_code, pdce.pdce_conto_desc
 from siac_t_mov_ep_det det, siac_t_pdce_conto pdce
 where det.movep_id=168900
 and   pdce.pdce_conto_id=det.pdce_conto_id
 order by det.movep_det_code::integer

  -- costi ?? EP  dare (avere ?? ) 20397011,53
 select det.movep_det_code, det.movep_det_desc,
        det.movep_det_segno,
        det.movep_det_importo , pdce.pdce_conto_code, pdce.pdce_conto_desc
 from siac_t_mov_ep_det det, siac_t_pdce_conto pdce
 where det.movep_id=168897
 and   pdce.pdce_conto_id=det.pdce_conto_id
 order by det.movep_det_code::integer

 40794023,06
     select max(det.movep_det_code),'$$'||det.movep_det_segno||'$$',sum(det.movep_det_importo)
     from siac_t_mov_ep_det det
     where det.movep_id=168873
     and   det.movep_det_code::INTEGER>1
     group by det.movep_det_segno
     limit  1;


 -- 168924 168929

select *
from siac_t_mov_ep m
where m.movep_id>=168932
order by movep_id

select *
from siac_t_mov_ep_det det
where det.movep_id=168936--168924
order by det.movep_det_code::integer

select *
from siac_t_prima_nota p
where p.pnota_id>=164020
order by pnota_id

select * from siac_t_prima_nota_num n
where n.ente_proprietario_id=4

--------------- ratei risconti
select *
from siac_d_pdce_conto_tipo tipo
where tipo.ente_proprietario_id=4


select det.*
from siac_t_mov_ep_det det, siac_t_pdce_conto pdce, siac_d_pdce_conto_tipo tipo
where tipo.ente_proprietario_id=4
and tipo.pdce_ct_tipo_code in ('RAT','RIS')
and   pdce.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id
and   det.pdce_conto_id=pdce.pdce_conto_id

select tipo.pdce_ct_tipo_code, det.*
from siac_t_mov_ep_det det, siac_t_pdce_conto pdce, siac_d_pdce_conto_tipo tipo
where det.ente_proprietario_id=4
and   date_trunc('DAY',det.data_creazione)=date_trunc('DAY',now()::timestamp)
and   pdce.pdce_conto_id=det.pdce_conto_id
and   tipo.pdce_ct_tipo_id=pdce.pdce_ct_tipo_id

-- 168985
select  *
from siac_t_mov_ep_det ep
where ep.movep_id in (168985,168986,161)

select  *
from siac_t_mov_ep ep
where ep.movep_id in (168985,168986)

select  *
from siac_t_mov_ep ep
where ep.regep_id in (164061,164062,161)

-- 164061
select *
from siac_t_prima_nota_ratei_risconti pnota
where pnota.ente_proprietario_id=4

siac_r_prima_nota

select * from siac_r_prima_nota
where ente_proprietariO_id=4
and   date_trunc('DAY',data_creazione)=date_trunc('DAY',now()::timestamp)


select * from siac_r_prima_nota r
where r.ente_proprietariO_id=4
and   r.pnota_id_da=150614


select * from siac_t_prima_nota p
where p.pnota_id in (150614,164064,164065)

select * from siac_t_prima_nota p
where p.pnota_id in (164061,164062,161)
--where p.pnota_id=161
-- 161
select * from siac_t_prima_nota p
where p.pnota_id in (150619,164068)

select  pn.bil_id,ep.movep_id, pdc.pdce_conto_code, pdc.pdce_conto_desc,
        ep.movep_det_code, ep.movep_det_segno,ep.movep_det_importo
from siac_t_mov_ep_det ep, siac_t_pdce_conto pdc,siac_t_mov_ep m,siac_t_prima_nota pn
where m.regep_id in (164061,164062,161)
and   m.movep_id=ep.movep_id
and   pdc.pdce_conto_id=ep.pdce_conto_id
and   pn.pnota_id=m.regep_id
order by pn.bil_id,m.regep_id, ep.movep_id, ep.movep_det_code::integer

select  ep.movep_id, pdc.pdce_conto_code, pdc.pdce_conto_desc,
        ep.movep_det_code, ep.movep_det_segno,ep.movep_det_importo
from siac_t_mov_ep_det ep, siac_t_pdce_conto pdc
where ep.movep_id in (150619,164068)
and   pdc.pdce_conto_id=ep.pdce_conto_id
order by ep.movep_id, ep.movep_det_code::integer

select  pn.bil_id, bil.bil_code,pn.pnota_id,pn.pnota_numero,
        ep.movep_id, pdc.pdce_conto_code, pdc.pdce_conto_desc,
        ep.movep_det_code, ep.movep_det_segno,ep.movep_det_importo
from siac_t_mov_ep_det ep, siac_t_pdce_conto pdc, siac_t_prima_nota pn, siac_t_mov_ep m, siac_t_bil bil
     --, siac_t_prima_nota_ratei_risconti rr
where pn.pnota_id in (150614,164064,164065)
and   pdc.pdce_conto_id=ep.pdce_conto_id
and   m.movep_id=ep.movep_id
and   m.regep_id=pn.pnota_id
and   bil.bil_id=pn.bil_id
--and   rr.pnota_id=pn.pnota_id
order by pn.bil_id,ep.movep_id, ep.movep_det_code::integer

select
     		 num.pnota_numero+1,
     	     fasetipo.fase_gen_elab_tipo_desc,
	         c.causale_ep_tipo_id
 	 from fase_gen_t_elaborazione_fineanno_det fasedet,
	      fase_gen_d_elaborazione_fineanno_tipo fasetipo,
	      siac_t_prima_nota_num num, siac_t_causale_ep c
	 where fasedet.fase_gen_elab_det_id=faseBilElabDetId
	 and   fasetipo.fase_gen_elab_tipo_id=fasedet.fase_gen_elab_tipo_id
	 and   num.ente_proprietario_id=enteProprietarioId
	 and   num.pnota_anno::integer=annoBilancio
	 and   c.causale_ep_id=fasetipo.causale_ep_id
	 and   c.data_cancellazione is null
	 and   c.validita_fine is null


select
from siac_t_pdce_conto pdce, siac_d_pdce_conto_tipo tipo,
     siac_r_pdce_conto_attr rattr, siac_t_attr attr,
     siac_t_mov_ep_det det,siac_t_mov_ep ep,
	 siac_t_prima_nota pnota,
     siac_r_prima_nota_stato rstato, siac_d_prima_nota_stato stato
where tipo.ente_proprietario_id=4
and   tipo.pdce_ct_tipo_code in ('RAT','RIS')
and   pdce.pdce_conto_id=tipo.pdce_ct_tipo_id
and   rattr.pdce_conto_id=pdce.pdce_conto_id
and   attr.attr_id=rattr.attr_id
and   attr.attr_code='pdce_conto_foglia'
and   rattr.boolean='S'
and   det.pdce_conto_id=pdce.pdce_conto_id
and   ep.movep_id=det.movep_id
and   pnota.pnota_id=ep.regep_id
and   rstato.pnota_id=pnota.pnota_id
and   stato.pnota_stato_id=rstato.

------------------- 31.03.2017

select *
from siac_t_prima_nota_ratei_risconti pnota
where pnota.ente_proprietario_id=4
select *
from siac_r_prima_nota pnota
where pnota.ente_proprietario_id=4
and   pnota.pnota_id_da=161

select *
from siac_t_prima_nota pn
where pn.pnota_id in (161,164061,164062)

select *
from siac_t_mov_ep ep
where ep.regep_id in (161,164061,164062)

--168985
select * From siac_t_mov_ep_det det
where det.movep_id=168986

select * from siac_t_bil
where ente_proprietario_id=4


select  bil.bil_id,
        per.anno,
        pnota.anno,
        pnota_da.pnota_id, pnota_da.bil_id, pnota_da.pnota_data,
        pnota_a.pnota_id, pnota_a.bil_id, pnota_a.pnota_data,
        stato_a.pnota_stato_code
       -- ep.movep_id,
       -- det.movep_det_code,
       -- det.pdce_conto_id,
       -- det.movep_det_segno, det.movep_det_importo
from siac_t_prima_nota_ratei_risconti pnota,siac_d_prima_nota_rel_tipo tipo,
     siac_t_bil bil, siac_t_periodo per,
     siac_r_prima_nota rel,
     siac_t_prima_nota pnota_da, siac_r_prima_nota_stato rstato_da,siac_d_prima_nota_stato stato_da,
     siac_t_prima_nota pnota_a, siac_r_prima_nota_stato rstato_a,siac_d_prima_nota_stato stato_a--,
  --   siac_t_mov_ep ep, siac_t_mov_ep_det det
where bil.ente_proprietario_id=4
and   per.periodo_id=bil.periodo_id
and   per.anno::integer=2016
and   pnota.ente_proprietario_id=bil.ente_proprietario_id
and   pnota.anno::integer=(per.anno::integer)+1
and   tipo.pnota_rel_tipo_id=pnota.pnota_rel_tipo_id
and   tipo.pnota_rel_tipo_code='RISCONTO'
and   rel.pnota_id_da=pnota.pnota_id
and   rel.pnota_rel_tipo_id=tipo.pnota_rel_tipo_id
--and   pnota_da.bil_id=bil.bil_id
and   pnota_da.pnota_id=rel.pnota_id_da
and   rstato_da.pnota_id=pnota.pnota_id
and   stato_da.pnota_stato_id=rstato_da.pnota_stato_id
and   stato_da.pnota_stato_code!='A'
--and   pnota_a.bil_id=bil.bil_id
and   pnota_a.pnota_id=rel.pnota_id_a
and   rstato_a.pnota_id=pnota_a.pnota_id
and   stato_a.pnota_stato_id=rstato_a.pnota_stato_id
--and   stato_a.pnota_stato_code!='A'
--and   ep.regep_id=pnota_a.pnota_id
--and   det.movep_id=ep.movep_id
and   pnota.data_cancellazione is null
and   pnota.validita_fine is null
and   rel.data_cancellazione is null
and   rel.validita_fine is null
and   pnota_da.data_cancellazione is null
and   pnota_da.validita_fine is null
and   rstato_da.data_cancellazione is null
and   rstato_da.validita_fine is null
and   pnota_a.data_cancellazione is null
and   pnota_a.validita_fine is null
and   rstato_a.data_cancellazione is null
and   rstato_a.validita_fine is null
/*and   ep.data_cancellazione is null
and   ep.validita_fine is null
and   det.data_cancellazione is null
and   det.validita_fine is null*/
order by det.movep_det_code::integer


select pn.pnota_id,pn.login_operazione,
       substring(pn.login_operazione from strpos (pn.login_operazione,'@')+1
                     for (strpos (pn.login_operazione,'*')-strpos (pn.login_operazione,'@')-1)
                 )::integer,
       substring(pn.login_operazione from strpos (pn.login_operazione,'*') +1 )::integer
from siac_t_prima_nota pn
where pn.ente_proprietario_id=4
and  pn.login_operazione like '%_gen_chiape_sri%'
order by pn.pnota_id desc


select * from siac_t_mov_ep ep
where ep.regep_id=164391

select * from siac_t_mov_ep_det
where movep_id=169364

and  substring(pn.login_operazione from strpos (pn.login_operazione,'@')+1
                     for (strpos (pn.login_operazione,'*')-strpos (pn.login_operazione,'@')-1)
                 )::integer=342


select *
from siac_r_prima_nota r
where r.pnota_id_da=161