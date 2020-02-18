/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 20.12.2017 Sofia JIRA-5665- SIOPE+
-- function compilate fnc_mif_ordinativo_spesa_splus
-- fnc_mif_ordinativo_esiste_documenti_splus
-- fnc_mif_ordinativo_entrata_splus
-- fnc_mif_ordinativo_documenti_splus inserire drop
select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(select 1
from mif_d_flusso_elaborato_tipo tipo
where  mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and     tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' )
--and     tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS' )
order by mif.flusso_elab_mif_ordine

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(select 1
from mif_d_flusso_elaborato_tipo tipo
where  mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and     tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' )
--and   mif.flusso_elab_mif_code='delegato'
--and   mif.flusso_elab_mif_code='creditore_effettivo'
--and   mif.flusso_elab_mif_code='sepa_credit_transfer'
and   mif.flusso_elab_mif_code='numero_conto_banca_italia_ente_ricevente'
order by mif.flusso_elab_mif_ordine

--CO|REGOLARIZZAZIONE
begin;
rollback;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CO|REGOLARIZZAZIONE|COMPENSAZIONE'
from   mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='delegato';

-- CSI|CO|REGOLARIZZAZIONE
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CSI|CO|REGOLARIZZAZIONE|COMPENSAZIONE'
from   mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='creditore_effettivo';

-- CBI|REGOLARIZZAZIONE
begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CBI|REGOLARIZZAZIONE|COMPENSAZIONE'
from   mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='numero_conto_banca_italia_ente_ricevente';

-- COMMERCIALE|FPR|FAT|NCD
begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='COMMERCIALE|FPR|FAT|NCD'
from   mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='tipo_debito_siope_c';




--- ord_incasso 6340 6342 6343 consip
--18.12.2017
--A) [IMPORTANTE] Revesali per la quota di split.
--Per le reversali dello split, sono riportati i dati della fattura di spesa
--che ha dato origine alla reversale. Tra i ta della fattura c'è importo_siope che ad oggi
-- valorizziamo con l'importo della fattura. A detta di quelli di Banca d'Italia
--(mail di Pietro Palermo 18.12.2017) in questo campo dobbiamo mettere l'importo dello split.


select ord.*
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='I'
and   ord.ord_tipo_id=tipo.ord_tipo_id
--and   ord.ord_numero::integer=6340
and   ord.ord_numero::integer=6342
--ord_id=20307
--ord_id=20312

select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='I'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer in (6342,6340)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
order by 1
--ord_id=20307

select ord.ord_id , ord.ord_numero
			     from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			         siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato, siac_d_relaz_tipo tiporel
--				 where rord.ord_id_a=20307
                 where rord.ord_id_a=20312
				 and   ord.ord_id=rord.ord_id_da
				 and   tipo.ord_tipo_id=ord.ord_tipo_id
				 and   tipo.ord_tipo_code='P'
			     and   rstato.ord_id=ord.ord_id
	             and   stato.ord_stato_id=rstato.ord_stato_id
	             and   stato.ord_stato_code!='A'
				 and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
                 and   tiporel.relaz_tipo_code='SPR'
				 and   rord.data_cancellazione is null
				 and   rord.validita_fine is null
				 and   ord.data_cancellazione is null
			     and   ord.validita_fine is null
			     and   rstato.data_cancellazione is null
	             and   rstato.validita_fine is null
                 limit 1;
-- ord_id=20308
-- ord_id=20315

select subdoc.*
from siac_r_subdoc_ordinativo_ts rs, siac_t_ordinativo_ts ts,
     siac_t_subdoc subdoc
--where ts.ord_id=20308
where ts.ord_id in (20315,20308)
and   rs.ord_ts_id=ts.ord_ts_id
and   subdoc.subdoc_id=rs.subdoc_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null

-- 34,81
-- 2,94

select *
from
fnc_mif_ordinativo_documenti_splus( 20315,
 									35,
                                    'FPR|FAT,NCD',
                                    'ANALOGICO',
                                    'dataScadenzaDopoSospensione',
                                    '1',
                                    'REGP',
                                    2,
                                    now()::timestamp,
                                    now()::timestamp);


select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   date_trunc('DAY', ord.ord_emissione_data)=date_trunc('DAY','2017-12-13'::timestamp)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
order by 1
--ord_numero =13767,13768
-- ord_id=20397,20398

select *
from siac_r_ordinativo_modpag r
where r.ord_id in (20397,20398)

select rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,
       coalesce(sum(detda.ord_ts_det_importo),0),
       count(*),
       ord.ord_id, det.ord_ts_det_importo
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel,
       siac_t_ordinativo_ts tsda, siac_t_ordinativo_ts_det detda,siac_t_ordinativo ordda
  where rord.ente_proprietario_id=2
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tsda.ord_id=rord.ord_id_da
  and   detda.ord_ts_id=tsda.ord_ts_id
  and   ordda.ord_id=tsda.ord_id
  and   detda.ord_ts_det_tipo_id=tipod.ord_ts_det_tipo_id
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
  group by rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data, ord.ord_id, det.ord_ts_det_importo
  having coalesce(sum(det.ord_ts_det_importo),0)=coalesce(sum(detda.ord_ts_det_importo),0)-- and count(*)>2
order by 1

select rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,
       rmdp.modpag_id, rmdp.soggetto_relaz_id
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel,
       siac_t_ordinativo_ts tsda, siac_t_ordinativo_ts_det detda,siac_t_ordinativo ordda,
       siac_r_ordinativo_modpag rmdp
  where rord.ente_proprietario_id=2
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tsda.ord_id=rord.ord_id_da
  and   detda.ord_ts_id=tsda.ord_ts_id
  and   ordda.ord_id=tsda.ord_id
  and   rmdp.ord_id=tsda.ord_id
  and   detda.ord_ts_det_tipo_id=tipod.ord_ts_det_tipo_id
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
  and   rmdp.data_cancellazione is null
  and   rmdp.validita_fine is null
  group by rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,rmdp.modpag_id, rmdp.soggetto_relaz_id
  having coalesce(sum(det.ord_ts_det_importo),0)=coalesce(sum(detda.ord_ts_det_importo),0)
order by 1




select rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,
       rmdp.modpag_id, rmdp.soggetto_relaz_id,
       mdp.iban
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel,
       siac_t_ordinativo_ts tsda, siac_t_ordinativo_ts_det detda,siac_t_ordinativo ordda,
       siac_r_ordinativo_modpag rmdp,siac_t_modpag mdp
  where rord.ente_proprietario_id=2
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tsda.ord_id=rord.ord_id_da
  and   detda.ord_ts_id=tsda.ord_ts_id
  and   ordda.ord_id=tsda.ord_id
  and   rmdp.ord_id=tsda.ord_id
  and    mdp.modpag_id=rmdp.modpag_id
  and   detda.ord_ts_det_tipo_id=tipod.ord_ts_det_tipo_id
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
  and   rmdp.data_cancellazione is null
  and   rmdp.validita_fine is null
  group by rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,rmdp.modpag_id, rmdp.soggetto_relaz_id,mdp.iban
  having coalesce(sum(det.ord_ts_det_importo),0)=coalesce(sum(detda.ord_ts_det_importo),0)
order by 1


select rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,
       rmdp.modpag_id, rmdp.soggetto_relaz_id,
       accre.accredito_tipo_code,mdp.contocorrente
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel,
       siac_t_ordinativo_ts tsda, siac_t_ordinativo_ts_det detda,siac_t_ordinativo ordda,
       siac_r_ordinativo_modpag rmdp,siac_t_modpag mdp,siac_d_accredito_tipo accre
  where rord.ente_proprietario_id=2
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tsda.ord_id=rord.ord_id_da
  and   detda.ord_ts_id=tsda.ord_ts_id
  and   ordda.ord_id=tsda.ord_id
  and   rmdp.ord_id=tsda.ord_id
  and    mdp.modpag_id=rmdp.modpag_id
  and   accre.accredito_tipo_id=mdp.accredito_tipo_id
--  and   accre.accredito_tipo_code='GF'
  and   detda.ord_ts_det_tipo_id=tipod.ord_ts_det_tipo_id
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
  and   rmdp.data_cancellazione is null
  and   rmdp.validita_fine is null
  group by rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,rmdp.modpag_id, rmdp.soggetto_relaz_id,
           accre.accredito_tipo_code,mdp.contocorrente
  having coalesce(sum(det.ord_ts_det_importo),0)=coalesce(sum(detda.ord_ts_det_importo),0)
order by 1

--20299
-- 20298,20317

select mdp.*
from siac_r_ordinativo_modpag r,siac_t_modpag mdp
--where r.ord_id in (20207)
where r.ord_id in (15130)
and   mdp.modpag_id=r.modpag_id
-- modpag_id=184511
-- modpag_id=147725
begin;
update siac_t_modpag mdp
set   accredito_tipo_id=accre.accredito_tipo_id,
      contocorrente='01234567'
from siac_d_accredito_tipo accre
where mdp.modpag_id=184511
and   accre.ente_proprietario_id=mdp.ente_proprietario_id
and   accre.accredito_tipo_code='GF'

rollback;
begin;
update siac_t_modpag mdp
set   accredito_tipo_id=accre.accredito_tipo_id,
      iban=null,
      quietanziante='paperino.pluto',
      quietanziante_codice_fiscale='9999999999999999'
from siac_d_accredito_tipo accre
where mdp.modpag_id=147725
and   accre.ente_proprietario_id=mdp.ente_proprietario_id
and   accre.accredito_tipo_code='CT'

select mif.*
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select  mif.mif_ord_bci_conto, mif.*
from mif_t_ordinativo_spesa mif
--where mif.mif_ord_flusso_elab_mif_id=1258
where  mif.mif_ord_bci_conto is not null



-- sono quietanzati, sbloccati
-- 13685, 13698 IBAN
-- 10786, 10817 DELEGATO
-- 13631 -- GF
-- 10103 - CT
-- 13778 -- forzato importo ordinativo ritenuta per compensazione
select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer in (13685, 13698,10786, 10817,13631,10103,13778)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
--and   rs.validita_fine is null
order by 1,rs.validita_inizio, rs.validita_fine

select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer in (13778)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
--and   stato.ord_stato_code!='A'
--and   rs.data_cancellazione is null
--and   rs.validita_fine is null
order by 1,rs.validita_inizio, rs.validita_fine

rollback;
begin;
update siac_r_ordinativo_stato rs
set    validita_fine=null
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_d_ordinativo_stato stato
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer=10103--13631-- in (13685, 13698,10786, 10817)
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code='T'
and   rs.data_cancellazione is null

begin;
update siac_r_ordinativo_stato rs
set    ord_stato_id=stato.ord_stato_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer=13778----1377810103--13631-- in (13685, 13698,10786, 10817)
and   rs.ord_id=ord.ord_id
and   stato.ente_proprietario_id=2
and   stato.ord_stato_code='I'
and   rs.data_cancellazione is null
and   rs.validita_fine is null


select ord.ord_id
from siac_r_ordinativo_stato rs, siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer=10103--13631-- in (13685, 13698,10786, 10817)
and   rs.ord_id=ord.ord_id
and   stato.ente_proprietario_id=2
and   stato.ord_stato_code='I'
and   rs.data_cancellazione is null
and   rs.validita_fine is null

select rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,
       coalesce(sum(detda.ord_ts_det_importo),0)/count(*),
       coalesce(sum(det.ord_ts_det_importo),0),
       count(*)
--       detda.ord_ts_det_importo,
--       ord.ord_id, det.ord_ts_det_importo
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel,
       siac_t_ordinativo_ts tsda, siac_t_ordinativo_ts_det detda,siac_t_ordinativo ordda
  where rord.ente_proprietario_id=2
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tsda.ord_id=rord.ord_id_da
  and   detda.ord_ts_id=tsda.ord_ts_id
  and   ordda.ord_id=tsda.ord_id
--  and   ordda.ord_numero::integer=13778
  and   detda.ord_ts_det_tipo_id=tipod.ord_ts_det_tipo_id
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
  group by rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data--,--detda.ord_ts_det_importo,
  --ord.ord_id, det.ord_ts_det_importo
  having coalesce(sum(det.ord_ts_det_importo),0)=coalesce(sum(detda.ord_ts_det_importo),0)/count(*)
order by 1 desc

-- 13778
select rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,
       coalesce(sum(detda.ord_ts_det_importo),0),
       detda.ord_ts_det_importo,
       ord.ord_id, det.ord_ts_det_importo
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel,
       siac_t_ordinativo_ts tsda, siac_t_ordinativo_ts_det detda,siac_t_ordinativo ordda
  where rord.ente_proprietario_id=2
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tsda.ord_id=rord.ord_id_da
  and   detda.ord_ts_id=tsda.ord_ts_id
  and   ordda.ord_id=tsda.ord_id
  and   ordda.ord_numero::integer=13778
  and   detda.ord_ts_det_tipo_id=tipod.ord_ts_det_tipo_id
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
  group by rord.ord_id_da,ordda.ord_numero,ordda.ord_emissione_data,detda.ord_ts_det_importo,
  ord.ord_id, det.ord_ts_det_importo
  --having coalesce(sum(det.ord_ts_det_importo),0)=coalesce(sum(detda.ord_ts_det_importo),0)
order by 1 desc
-- 216,45

select *
from siac_t_ordinativo_ts_det det,siac_t_ordinativo_ts ts,siac_d_ordinativo_ts_det_tipo tipo
where ts.ord_id=20416
and   det.ord_ts_id=ts.ord_ts_id
and   tipo.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
and   tipo.ord_ts_det_tipo_code='A'
--ord_td_det_id=41530

select *
from siac_t_ordinativo_ts_det det
where det.ord_ts_det_id=41530


select ord.ord_numero::integer,
       fnc_mif_ordinativo_esiste_documenti_splus( ord.ord_id,
                                                  'FRP|FAT|NCD',
                                                  ord.ente_proprietario_id
                                                 ) esisteDoc,
       deb.siope_tipo_debito_desc_bnkit
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_d_siope_tipo_debito deb
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   deb.siope_tipo_debito_id=ord.siope_tipo_debito_id
order by 1



-- 13772 FALSE COMMERCIALE

with
esisteDoc as
(
select ord.ord_id,
       fnc_mif_ordinativo_esiste_documenti_splus( ord.ord_id,
                                                  'FRP|FAT|NCD',
                                                  ord.ente_proprietario_id
                                                 ) esisteDoc
from siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
),
ordinativi as
(
select ord.ord_numero::integer,ord.ord_id,ord.ord_trasm_oil_data, ord.ord_emissione_data,stato.ord_stato_code,
       ord.siope_tipo_debito_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
)
select  ordinativi.ord_numero,
        ordinativi.ord_id,ordinativi.ord_trasm_oil_data, ordinativi.ord_emissione_data,ordinativi.ord_stato_code
from  esisteDoc,
      ordinativi
         left  join siac_d_siope_tipo_debito deb on (ordinativi.siope_tipo_debito_id=deb.siope_tipo_debito_id)
where ordinativi.ord_id=esisteDoc.ord_id
--and   esisteDoc.esisteDoc=false
and   esisteDoc.esisteDoc=true
--and   deb.siope_tipo_debito_desc_bnkit='COMMERCIALE'
and   deb.siope_tipo_debito_desc_bnkit='NON_COMMERCIALE'
--and   ordinativi.siope_tipo_debito_id is null
order by 1


-- 13773 -- NON_COMMERCIALE - doc=false, COMMERCIALE
-- 13779 -- NON_COMMERCIALE - doc=false, NON_COMMERCIALE
--       -- NON_COMMERCIALE - doc=false, null --non ne trovo
-- 13613 -- COMMERCIALE     - doc=true,  null
-- 13758 -- COMMERCIALE     - doc=true,  COMMERCIALE
-- 13774 -- COMMERCIALE     - doc=true,  NON_COMMERCIALE

