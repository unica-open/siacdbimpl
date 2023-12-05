/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


select mif.*
from mif_d_flusso_elaborato mif,mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
order by mif.flusso_elab_mif_ordine

select *
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_desc in ('VAGLIA POSTALE','VAGLIA TESORO')


select tipo.*
from siac_d_accredito_tipo_oil oil,siac_r_accredito_tipo_oil r,siac_d_accredito_tipo tipo
where oil.ente_proprietario_id=2
and   oil.accredito_tipo_oil_desc in ('VAGLIA POSTALE','VAGLIA TESORO')
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null

select *
from siac_d_accredito_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.accredito_tipo_desc ='VAGLIA POSTALE'


-------- UPDATE ----
update siac_d_accredito_tipo tipo
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=tipo.login_operazione||'-SIAC-8119'
from siac_d_accredito_tipo_oil oil,siac_r_accredito_tipo_oil r
where oil.ente_proprietario_id  in (2,3,4,5,10,14,15)
and   oil.accredito_tipo_oil_desc in ('VAGLIA POSTALE','VAGLIA TESORO')
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   tipo.data_cancellazione is null
and   tipo.validita_fine is null
and   oil.data_cancellazione is null
and   oil.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null;



update siac_r_accredito_tipo_oil r
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=r.login_operazione||'-SIAC-8119'
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id  in (2,3,4,5,10,14,15)
and   oil.accredito_tipo_oil_desc in ('VAGLIA POSTALE','VAGLIA TESORO')
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   r.data_cancellazione is null
and   r.validita_fine is null
and   oil.data_cancellazione is null
and   oil.validita_fine is null;

update siac_d_accredito_tipo_oil oil
set    data_cancellazione=now(),
       validita_fine=now(),
       login_operazione=r.login_operazione||'-SIAC-8119'
where oil.ente_proprietario_id  in (2,3,4,5,10,14,15)
and   oil.accredito_tipo_oil_desc in ('VAGLIA POSTALE','VAGLIA TESORO')
and   oil.data_cancellazione is null
and   oil.validita_fine is null;

