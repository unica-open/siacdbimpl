/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--- 05.04.2019 Sofia HD-INC000003138402_Edisu
--- HD-INC000003138402_Edisu_sposta_acc_su_OrdInc_05042019.sql
/*From: giuseppe.pastore@edisu-piemonte.it
To: hd_contabilia@csi.it
Subject: Richiesta trattamento dati
---
Buongiorno,

    n on potendo annullare l'ordinativo 535 del 26/02/2019 in quanto già quietanzato,
con la presente si richiede un trattamento dati che:

agganci all'ordinativo d'incasso 535/2019 afferenti al provvisorio 1271
all'accertamento n.461/2018 anziché all'accertamento 77/2019 come erroneamente effettuato.

Rimanendo a vostra disposizione si porgono cordiali saluti.



Giuseppe PASTORE*/

/*I: Richiesta trattamento dati
Davide Garbero
<davide.garbero@edisu-piemonte.it>
14:52
491.4 KB
A  antonella.gentile@unicredit.eu   Copia  Giuseppe Pastore   e altri 2
Risposta rapida a tuttiRispondiRispondi a tuttiInoltraElimina
Buongiorno,



con la presente si richiedere di sregolarizzare la reversale n. 535, collegata al provvisorio di incasso n. 1271.



Rimanendo in attesa di un gentile riscontro, porgiamo cordiali saluti.



Davide Garbero

EDISU Piemonte - Ufficio Amministrazione, Finanza e Controllo

Via Madama Cristina 83, 10126 Torino
Telefono 011/6531101*/

select *
from siac_v_bko_ordinativo_oi_valido oi
where oi.ente_proprietario_id=13
and   oi.anno_bilancio=2019
and   oi.ord_numero=535


select oi.ord_numero,acc.movgest_anno,acc.movgest_numero, e.elem_code
from siac_v_bko_ordinativo_oi_valido oi,siac_t_ordinativo_ts ts,
     siac_r_ordinativo_ts_movgest_ts r, siac_v_bko_accertamento_valido acc,
     siac_r_ordinativo_bil_elem re,siac_t_bil_elem e
where oi.ente_proprietario_id=13
and   oi.anno_bilancio=2019
and   oi.ord_numero=535
and   ts.ord_id=oi.ord_id
and   r.ord_ts_id=ts.ord_ts_id
and   acc.movgest_ts_id=r.movgest_ts_id
and   re.ord_id=oi.ord_id
and   e.elem_id=re.elem_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   re.data_cancellazione is null
and   re.validita_fine is null
-- 2019/77 218

-- n.461/2018
select acc.movgest_anno, acc.movgest_numero,e.elem_code
from siac_v_bko_accertamento_valido acc,siac_r_movgest_bil_elem re,siac_t_bil_elem e
where acc.ente_proprietario_id=13
and   acc.anno_bilancio=2019
and   acc.movgest_anno=2018
and   acc.movgest_numero=461
and   re.movgest_id=acc.movgest_id
and   e.elem_id=re.elem_id
and   re.data_cancellazione is null
and   re.validita_fine is null


select * from siac_bko_sposta_ordinativo_inc bko
where bko.ente_proprietario_id=13

insert into siac_bko_sposta_ordinativo_inc
(
  ente_proprietario_id,
  anno_bilancio,
  ord_numero,
  ord_sub_numero,
  numero_capitolo_da,
  numero_capitolo_a,
  anno_accertamento_da,
  numero_accertamento_da,
  numero_subaccertamento_da,
  anno_accertamento_a,
  numero_accertamento_a,
  numero_subaccertamento_a
)
select oi.ente_proprietario_id,
       oi.anno_bilancio,
       oi.ord_numero,
       ts.ord_ts_code::integer,
       e.elem_code::integer,
       e.elem_code::integer,
       acc.movgest_anno,
       acc.movgest_numero,
       acc.movgest_subnumero,
       2018,
       461,
       0
from siac_v_bko_ordinativo_oi_valido oi,siac_t_ordinativo_ts ts,
     siac_r_ordinativo_ts_movgest_ts r, siac_v_bko_accertamento_valido acc,
     siac_r_ordinativo_bil_elem re,siac_t_bil_elem e
where oi.ente_proprietario_id=13
and   oi.anno_bilancio=2019
and   oi.ord_numero=535
and   ts.ord_id=oi.ord_id
and   r.ord_ts_id=ts.ord_ts_id
and   acc.movgest_ts_id=r.movgest_ts_id
and   re.ord_id=oi.ord_id
and   e.elem_id=re.elem_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   re.data_cancellazione is null
and   re.validita_fine is null

begin;
select
fnc_siac_bko_sposta_accertamento_su_ordinativo
(
2019,
13,
'INC000003138402',
true,
false,
true
)

-- 1271
select p.*
from siac_t_prov_cassa p,siac_d_prov_cassa_tipo tipo
where tipo.ente_proprietario_id=13
and   tipo.provc_tipo_code='E'
and   p.provc_tipo_id=tipo.provc_tipo_id
and   p.provc_anno::integer=2019
and   p.provc_numero::integer=1271


select r.ord_provc_importo, p.*
from siac_v_bko_ordinativo_oi_valido oi,siac_r_ordinativo_prov_cassa r,siac_t_prov_cassa p
where oi.ente_proprietario_id=13
and   oi.anno_bilancio=2019
and   oi.ord_numero=535
and   r.ord_id=oi.ord_id
and   p.provc_id=r.provc_id
and   r.data_cancellazione is null
and   r.validita_fine is null
