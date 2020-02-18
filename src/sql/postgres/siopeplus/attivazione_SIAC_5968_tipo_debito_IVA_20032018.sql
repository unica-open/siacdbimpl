/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code in ('numero_conto_corrente_beneficiario','piazzatura','riferimento_documento_esterno')
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

begin;
-- ATTIVAZIONE
-- MANDMIF_SPLUS
-- attivazione piazzatura-numero_conto_corrente_beneficiario per CCP
-- CB|IT
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CB|IT|CCP'
where  mif.flusso_elab_mif_code='numero_conto_corrente_beneficiario'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);

-- DISPOSIZIONE DOCUMENTO ESTERNO|BONIFICO ESTERO EURO|STI|CCP
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='DISPOSIZIONE DOCUMENTO ESTERNO|BONIFICO ESTERO EURO|STI'
where mif.flusso_elab_mif_code='riferimento_documento_esterno'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code like 'tipo_debito_siope_%'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

begin;
-- Attivazione tipo_debito_nc=IVA - da eseguire per attivare gestine tipo_debito_nc=IVA
-- TIPO_DEBITO COMMERCIALE, NON_COMMERCIALE, IVA
-- NON_COMMERCIALE
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='PDC_V|U.7.01.01.02.001',
       flusso_elab_mif_default='NON_COMMERCIALE|IVA'
where mif.flusso_elab_mif_code='tipo_debito_siope_nc'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);


-- REVMIF_SPLUS
-- COMMERCIALE
-- Attivazione tipo_debito_nc=IVA - da eseguire per attivare gestine tipo_debito_nc=IVA

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='SPR|REI_ORD|FPR|FAT|NCD'
where mif.flusso_elab_mif_code like 'tipo_debito_siope_c'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);


-- NON_COMMERCIALE
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='PDC_V|U.7.01.01.02.001',
       flusso_elab_mif_default='NON_COMMERCIALE|IVA'
where mif.flusso_elab_mif_code like 'tipo_debito_siope_nc'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);









----------- DISATTIVAZIONE

-- disattivazione
begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CB|IT'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='numero_conto_corrente_beneficiario'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='DISPOSIZIONE DOCUMENTO ESTERNO|BONIFICO ESTERO EURO|STI|CCP'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='riferimento_documento_esterno'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);


begin;
-- disattivo - deve essere cosi
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param=null,
       flusso_elab_mif_default='NON_COMMERCIALE'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='tipo_debito_siope_nc'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);


begin;
-- disattivazione tipo_debit_nc=IVA
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='SPR'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code like 'tipo_debito_siope_c'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param=null,
       flusso_elab_mif_default='NON_COMMERCIALE'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code like 'tipo_debito_siope_nc'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);

