/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Mandati - Sostituzione
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

with
ordinativi as
(
select ord.ord_id, ord.ord_numero, ord_stato_code,ord.ord_trasm_oil_data,rs.validita_inizio
from siac_t_ordinativo ord , siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
),
ordSos as
(
select rord.ord_id_da, rord.ord_id_a
from siac_r_ordinativo rord, siac_d_relaz_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.relaz_tipo_code='SOS_ORD'
and   rord.relaz_tipo_id=tipo.relaz_tipo_id
and   rord.data_cancellazione is null
and   rord.validita_fine is null
)
select ordinativi.*,
       ordSos.*
from ordSos, ordinativi
where
ordinativi.ord_id=ordSos.ord_id_da
or
ordinativi.ord_id=ordSos.ord_id_a
order by ordinativi.ord_numero::integer

rollback;
begin;
update siac_r_ordinativo_stato rs
set    validita_fine=now()
where rs.ord_id=20961
and   rs.validita_fine is null
and   rs.data_cancellazione is null
insert into siac_r_ordinativo_stato
(
	ord_id,
    ord_stato_id,
    login_operazione,
    validita_inizio,
    ente_proprietario_id
)
select 20961,
       stato.ord_stato_id,
       'siac-5969',
       now(),
       stato.ente_proprietario_id
from siac_d_ordinativo_stato stato
where stato.ente_proprietario_id=2
and   stato.ord_stato_code='A'

select mif.*
from mif_d_flusso_elaborato mif, mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
order by mif.flusso_elab_mif_ordine


select ord.ord_id, ord.ord_numero, ord_stato_code,ord.ord_trasm_oil_data,rs.validita_inizio
from siac_t_ordinativo ord , siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rs.ord_id=ord.ord_id
and   ord.ord_numero in (150,151)
and   stato.ord_stato_id=rs.ord_stato_id
--and   rs.data_cancellazione is null
--and   rs.validita_fine is null

begin;
update siac_t_ordinativo ord
set    ord_trasm_oil_data=null
where ord.ord_id in (20962,20963)

update siac_r_ordinativo_stato ord
set    validita_fine=null
where ord.ord_id in (20962,20963)