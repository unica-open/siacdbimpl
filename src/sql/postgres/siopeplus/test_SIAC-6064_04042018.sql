/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-6064

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


select op.ord_numero,
       op.ord_stato_code,
       rel.*
from siac_v_bko_ordinativo_op_stati op,siac_r_ordinativo_modpag rmdp,
     siac_r_soggrel_modpag rel, siac_t_modpag mdp,
     siac_r_soggetto_relaz rsog,siac_d_relaz_tipo tipo
where op.ente_proprietario_id=2
and   op.anno_bilancio=2018
and   op.ord_stato_code!='A'
and   rmdp.ord_id=op.ord_id
and   rmdp.modpag_id is null
and   rel.soggetto_relaz_id=rmdp.soggetto_relaz_id
and   mdp.modpag_id=rel.modpag_id
and   rsog.soggetto_relaz_id=rel.soggetto_relaz_id
and   tipo.relaz_tipo_id=rsog.relaz_tipo_id
and   tipo.relaz_tipo_code='CSI'
and   op.statoord_validita_fine is null
and   op.statoord_Data_cancellazione is null
and   rmdp.data_cancellazione is null
and   rmdp.validita_fine is null
and   rsog.data_cancellazione is null
and   rsog.validita_fine is  null
and   rel.data_cancellazione is null
and   rel.validita_fine is not null
order by op.ord_numero desc


-- 2659
select *
from siac_r_soggrel_modpag r
where r.soggrelmpag_id=2659

-- ord_numero=7940

select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select *
from mif_t_ordinativo_spesa mif
where mif.ente_proprietario_id=2
and mif.mif_ord_flusso_elab_mif_id=3483


      Select coalesce(rel.modpag_id,0),rel.validita_fine
      from siac_r_ordinativo_modpag s, siac_r_soggrel_modpag rel
      where s.ord_id=83705
      and s.soggetto_relaz_id is not null
      and rel.soggetto_relaz_id=s.soggetto_relaz_id
      and s.data_cancellazione is null
      and s.validita_fine is null
      and rel.data_cancellazione is null
      -- and rel.validita_fine is null
      -- 04.04.2018 Sofia SIAC-6064
      and date_trunc('day',now())<=date_trunc('day',coalesce(rel.validita_fine,now()))
      and exists  (select  1 from siac_r_soggrel_modpag rel1
                   where    rel.soggetto_relaz_id=s.soggetto_relaz_id
		           and      rel1.soggrelmpag_id=rel.soggrelmpag_id
         		   order by rel1.modpag_id
			       limit 1);

       Select coalesce(s.modpag_id,0)
      from siac_r_ordinativo_modpag s
      where s.ord_id=83705
   	  and s.modpag_id is not null
      and s.data_cancellazione is null
      and s.validita_fine is null;


begin;
update siac_r_gestione_ente r
set    gestione_livello_id=dnew.gestione_livello_id,
       data_modifica=now(),
       login_operazione=r.login_operazione||'-admin-siope+'
from siac_d_gestione_livello d,siac_d_gestione_livello dnew
where d.ente_proprietario_id=2
and   d.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_UNIIT'
and   r.gestione_livello_id=d.gestione_livello_id
and   dnew.ente_proprietario_id=d.ente_proprietario_id
and   dnew.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS'
and   r.data_cancellazione is null
and   r.validita_fine is null;


update siac_r_gestione_ente r
set    gestione_livello_id=dnew.gestione_livello_id,
       data_modifica=now(),
       login_operazione=r.login_operazione||'-admin-siope+'
from siac_d_gestione_livello d,siac_d_gestione_livello dnew
where d.ente_proprietario_id=2
and   d.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_SIOPE_PLUS'
and   r.gestione_livello_id=d.gestione_livello_id
and   dnew.ente_proprietario_id=d.ente_proprietario_id
and   dnew.gestione_livello_code='ORDINATIVI_MIF_TRASMETTI_UNIIT'
and   r.data_cancellazione is null
and   r.validita_fine is null;


update siac_t_ente_oil e
set    ente_oil_siope_plus=true
where e.ente_proprietario_id=2;

update siac_t_ente_oil e
set    ente_oil_siope_plus=false
where e.ente_proprietario_id=2;
