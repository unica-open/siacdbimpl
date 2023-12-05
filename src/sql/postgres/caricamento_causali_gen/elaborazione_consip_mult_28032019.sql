/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
begin;
select
fnc_siac_bko_caricamento_pdce_conto
( 2019,
  ente.ente_proprietario_id,
  'AMBITO_FIN',
  'SIAC-6661',
  now()::timestamp
)
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (4,5,10,13,14,16,29)


NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 75646244
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 482719
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.


NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 96518694
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 521842
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 96518695
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 521843
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 96518696
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 521844
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 96518697
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 521845
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 96518698
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 521846
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 96518699
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 521847
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_t_class]. 96518700
NOTICE:  strMessaggio=Inserimento codice di bilancio B.13.a [siac_r_class_fam_tree]. 521848
NOTICE:  Conti livello V inseriti=8
NOTICE:  Conti livello VI inseriti=31
NOTICE:  Conti livello VII inseriti=11
NOTICE:  Attributi pdce_conto_foglia inseriti=38
NOTICE:  Attributi pdce_conto_di_legge inseriti=50
NOTICE:  Attributi pdce_ammortamento inseriti=0
NOTICE:  Attributi pdce_conto_attivo inseriti=50
NOTICE:  Attributi pdce_conto_segno_negativo inseriti=0
NOTICE:  Codifiche di bilancio  pdce_conto inserite=44
NOTICE:  Codifiche di bilancio  pdce_conto inserite=25
NOTICE:  Inserimento conti PDC_ECON di generale ambitoCode=AMBITO_FIN. Elaborazione terminata.

7 rows returned (execution time: 22,218 sec; total time: 22,375 sec)

select ente_proprietario_id, count(*)
from siac_bko_t_caricamento_pdce_conto bko
group by ente_proprietario_id;


select conto.ente_proprietario_id,count(*)
from siac_t_pdce_conto conto
where conto.ente_proprietario_id in (4,5,10,13,14,16,29)
and   conto.login_operazione like '%SIAC-6661%' -- 73
--and   conto.login_operazione like 'admin-carica-pdce-SIAC-6661@%' -- 50
group by conto.ente_proprietario_id


select ente_proprietario_id,count(*)
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='I'
group by ente_proprietario_id

-- 50
select ente_proprietario_id,count(*)
from siac_bko_t_caricamento_pdce_conto bko
where bko.tipo_operazione='A'
group by ente_proprietario_id

-- 23




select  ente_proprietario_id,count(*)
from siac_r_pdce_conto_class r
where r.ente_proprietario_id in (4,5,10,13,14,16,29)
and   r.login_operazione like '%SIAC-6661%'
and  r.data_cancellazione is null
group by ente_proprietario_id
-- 69




rollback;
begin;
select
fnc_siac_bko_caricamento_causali
(
  2019,
  ente.ente_proprietario_id,
  'AMBITO_FIN',
   'SIAC-6661',
  now()::timestamp
)
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id in (4,5,10,13,14,16,29)

NOTICE:  numeroCausali=240 (260)
NOTICE:  numeroStatoCausali=240
NOTICE:  numeroPdcFinCausali=240
NOTICE:  numeroContiCausali=474 (517)
NOTICE:  numeroContiSEGNOCausali=480
NOTICE:  numeroContiTIPOIMPORTOCausali=474
NOTICE:  numeroContiUTILIZZOCONTOCausali=474
NOTICE:  numeroContiUTILIZZOIMPORTOCausali=474
NOTICE:  numeroCausaliEvento=606 -- ok
NOTICE:  Inserimento causale di generale ambitoCode=AMBITO_FIN. Inserite 240 causali.