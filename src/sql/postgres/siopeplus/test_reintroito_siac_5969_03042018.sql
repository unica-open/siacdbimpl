/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- Mandati - Sostituzione
-- i mandati sostituti li trasmette con
-- tipo_operazione=SOSTITUZIONE
   -- con questo tipo_operazione la piazzatura non è popolata
-- <sostituzione_mandato>
--  sezione valorizzata se esiste relazione SOS_ORD, anche se ord sostituito ANNULLATO, anche in seguito a
--  annullamento, spostamento o variazioen dell'ordinativo sostituto
    -- <numero_mandato_da_sostituire>
    -- <progressivo_beneficiario_da_sostuire>
    -- <esercizio_mandato_da_sostituire>
--ord_id_da = sostituito
--ord_id_a  = sostituto

-- provare trasmissione di un ordinativo con relazione SOS_ORD

-- modificato fnc_mif_ordinativo_spesa_splus per non trasmettere annullamenti di SOS_ORD
-- modificato fnc_mif_ordinativo_spesa_chiu_elab per chiusura dei SOSTITUITI e impostazione stato TRASMESSO
-- testare tutti i casi di trasmissione segnalati in excel di Anna per Reintroito, per chiudure la JIRA

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and  exists
(select 1 from mif_d_flusso_elaborato_tipo tipo
 where mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
--and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'

)
order by mif.flusso_elab_mif_ordine

select *
from siac_d_relaz_tipo rel
where rel.ente_proprietario_id=2

select ord_da.ord_numero, stato_da.ord_stato_code,
       ord_a.ord_numero, stato_a.ord_stato_code
from siac_t_ordinativo ord_da, siac_r_ordinativo_stato rs_da,siac_d_ordinativo_stato stato_da,
     siac_t_ordinativo ord_a, siac_r_ordinativo_stato rs_a,siac_d_ordinativo_stato stato_a,
     siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo rord,siac_d_relaz_tipo rel
where rel.ente_proprietario_id=2
and   rel.relaz_tipo_code='REI_ORD'
and   rord.relaz_tipo_id=rel.relaz_tipo_id
and   ord_da.ord_id=rord.ord_id_da
and   ord_a.ord_id=rord.ord_id_a
and   tipo.ente_proprietario_id=rel.ente_proprietario_id
and   tipo.ord_tipo_code='I'
and   ord_da.ord_tipo_id=tipo.ord_tipo_id
--and   ord_a.ord_tipo_id=tipo.ord_tipo_id
and   rs_da.ord_id=ord_da.ord_id
and   stato_da.ord_stato_id=rs_da.ord_stato_id
and   rs_a.ord_id=ord_a.ord_id
and   stato_a.ord_stato_id=rs_a.ord_stato_id
and   rord.data_cancellazione is null
and   rord.validita_fine is null
and   rs_da.data_cancellazione is null
and   rs_da.validita_fine is null
and   rs_a.data_cancellazione is null
and   rs_a.validita_fine is null


select ord_da.ord_numero, stato_da.ord_stato_code,
       ord_a.ord_numero, stato_a.ord_stato_code
from siac_t_ordinativo ord_da, siac_r_ordinativo_stato rs_da,siac_d_ordinativo_stato stato_da,
     siac_t_ordinativo ord_a, siac_r_ordinativo_stato rs_a,siac_d_ordinativo_stato stato_a,
     siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo rord,siac_d_relaz_tipo rel
where rel.ente_proprietario_id=2
and   rel.relaz_tipo_code='SOS_ORD'
and   rord.relaz_tipo_id=rel.relaz_tipo_id
and   ord_da.ord_id=rord.ord_id_da
and   ord_a.ord_id=rord.ord_id_a
and   tipo.ente_proprietario_id=rel.ente_proprietario_id
and   tipo.ord_tipo_code='P'
and   ord_da.ord_tipo_id=tipo.ord_tipo_id
and   ord_a.ord_tipo_id=tipo.ord_tipo_id
and   rs_da.ord_id=ord_da.ord_id
and   stato_da.ord_stato_id=rs_da.ord_stato_id
and   rs_a.ord_id=ord_a.ord_id
and   stato_a.ord_stato_id=rs_a.ord_stato_id
and   rord.data_cancellazione is null
and   rord.validita_fine is null
and   rs_da.data_cancellazione is null
and   rs_da.validita_fine is null
and   rs_a.data_cancellazione is null
and   rs_a.validita_fine is null

--mandato 3 e 102 sono spostamenti
--mandato 44 è stato sostituito da 8197 9196 e ha la reversale 232 che è stata spostata
--mandato 77 sostitito da 8200 8199 8198 con reversali in partita di giro 389 390 spostati

select *
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
order by op.ord_numero desc , op.statoord_validita_inizio, op.statoord_validita_fine


-- spostamento  mandati
-- 2018/8157
select *
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
--and   op.ord_numero=8157
--and   op.ord_numero=8127
--and   op.ord_numero=3656
and   op.ord_numero in (3,102)
order by op.ord_numero desc , op.statoord_validita_inizio, op.statoord_validita_fine
-- 8157 non_commerciale
-- 8127 commerciale
-- 3656 IVA

-- spostamento  reversali
select *
from siac_v_bko_ordinativo_oi_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
--and   op.ord_numero=3831
and   op.ord_numero=3778
order by op.ord_numero desc , op.statoord_validita_inizio, op.statoord_validita_fine
-- 3831 non_commerciale
-- 3778 commerciale split

select op.*
from siac_v_bko_ordinativo_oi_stati op,siac_r_ordinativo ord,siac_d_relaz_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   ord.ord_id_a=op.ord_id
and   tipo.relaz_tipo_id=ord.relaz_tipo_id
and   tipo.relaz_tipo_code='SPR'
and   op.statoord_validita_fine is NULL
and   ord.data_cancellazione is null
and   ord.validita_fine is null
order by op.ord_numero desc , op.statoord_validita_inizio, op.statoord_validita_fine
-- 3778 split COMMERCIALE

select op.*
from siac_v_bko_ordinativo_op_stati op,siac_t_subdoc sub,siac_t_doc doc, siac_d_doc_tipo tipo,
     siac_r_subdoc_ordinativo_ts r,siac_t_ordinativo_ts ts
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   ts.ord_id=op.ord_id
and   r.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=r.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   tipo.doc_tipo_code='FAT'
and   op.statoord_validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
order by op.ord_numero desc , op.statoord_validita_inizio, op.statoord_validita_fine


select op.*
from siac_v_bko_ordinativo_op_stati op,siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   rc.ord_id=op.ord_id
and   c.classif_id=rc.classif_id
and   tipo.classif_tipo_id=c.classif_tipo_id
and   tipo.classif_tipo_code='PDC_V'
and   c.classif_code='U.7.01.01.02.001'
and   op.statoord_validita_fine is null
and   rc.data_cancellazione is null
and   rc.validita_fine is null
order by op.ord_numero desc
-- 3656


select *
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero=3656
order by op.ord_numero desc , op.statoord_validita_inizio, op.statoord_validita_fine

begin;
update siac_r_ordinativo_stato rs
set    data_cancellazione=now(),
       validita_fine=now()
from
(
select distinct op.ord_id
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero=3656
) QUERY,siac_d_ordinativo_stato stato
where rs.ord_id=QUERY.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code in ('Q','F')
and   rs.data_cancellazione is null
--and   rs.validita_fine is null


update siac_r_ordinativo_stato rs
set    data_cancellazione=null,
       validita_fine=null
from
(
select distinct op.ord_id
from siac_v_bko_ordinativo_op_stati op
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_numero=3656
) QUERY,siac_d_ordinativo_stato stato
where rs.ord_id=QUERY.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code ='T'
and   rs.data_cancellazione is null


