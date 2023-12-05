/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
order by mif.flusso_elab_mif_ordine


-- tipo_debito_siope_nc

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='tipo_debito_siope_nc'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

-- NON_COMMERCIALE
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='NON_COMMERCIALE|IVA'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='tipo_debito_siope_nc'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='piazzatura'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

--numero_conto_corrente_beneficiario
select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='numero_conto_corrente_beneficiario'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CB|IT|CCP'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='numero_conto_corrente_beneficiario'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
--riferimento_documento_esterno
select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='riferimento_documento_esterno'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)

-- DISPOSIZIONE DOCUMENTO ESTERNO|BONIFICO ESTERO EURO|STI|CCP
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='DISPOSIZIONE DOCUMENTO ESTERNO|BONIFICO ESTERO EURO|STI'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code='riferimento_documento_esterno'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)



select *
from siac_d_siope_tipo_debito deb
where deb.ente_proprietario_id=2

insert into siac_d_siope_tipo_debito
(
  siope_tipo_debito_code,
  siope_tipo_debito_desc,
  siope_tipo_debito_desc_bnkit,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
values
(
  'IVA',
  'Iva',
  'IVA',
  now(),
  2,
  'admin'
);


----------------------------------------

select ord.ord_numero::integer,
       ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       rs.validita_inizio,
       rs.validita_fine,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
--and   rs.data_cancellazione is null
order by ord.ord_numero::integer desc, rs.validita_inizio,rs.validita_fine

select ord.ord_numero::integer,
       ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       rs.validita_inizio,
       rs.validita_fine,
       ord.ord_id,
       mdp.contocorrente
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato,
     siac_r_ordinativo_modpag rmdp, siac_t_modpag mdp, siac_d_accredito_tipo accre,siac_d_accredito_gruppo gruppo
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rmdp.ord_id=ord.ord_id
and   mdp.modpag_id=rmdp.modpag_id
and   accre.accredito_tipo_id=mdp.accredito_tipo_id
and   gruppo.accredito_gruppo_id=accre.accredito_gruppo_id
and   gruppo.accredito_gruppo_code='CCP'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   rmdp.data_cancellazione is null
and   rmdp.validita_fine is null
order by ord.ord_numero::integer desc, rs.validita_inizio,rs.validita_fine


select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc


select *
from mif_t_ordinativo_ritrasmesso rit
where rit.ente_proprietario_id=2
and   rit.mif_ord_ritrasm_elab_id=1556
rollback;
begin;
select * from
fnc_mif_ordinativo_spesa_splus_ritrasm
( 2,
  'REGP',
  '2017',
  '20474'::text,
  'batch',
  now()::timestamp
 );



-----------------


select ord.ord_numero::integer,
       ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       fnc_mif_ordinativo_esiste_documenti_splus( ord.ord_id,
                                                  'FPR|FAT|NCD',
                                                  ord.ente_proprietario_id
                                                ),
       ord.ord_id,
       ord.siope_tipo_debito_id,
       deb.siope_tipo_debito_desc_bnkit
from siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato,
     siac_t_ordinativo ord left join siac_d_siope_tipo_debito deb on (deb.siope_tipo_debito_id=ord.siope_tipo_debito_id)
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id

and   rs.data_cancellazione is null
and   rs.validita_fine is null
order by ord.ord_numero::integer desc



select ord.ord_numero::integer,
       ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       fnc_mif_ordinativo_esiste_documenti_splus( ord.ord_id,
                                                  'FPR|FAT|NCD',
                                                  ord.ente_proprietario_id
                                                ),
       c.classif_code,
       ord.ord_id,
       ord.siope_tipo_debito_id,
       deb.siope_tipo_debito_desc_bnkit
from siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato,
     siac_r_ordinativo_class rc, siac_t_class c,siac_d_class_tipo tipoc,
     siac_t_ordinativo ord left join siac_d_siope_tipo_debito deb on (deb.siope_tipo_debito_id=ord.siope_tipo_debito_id)
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   rc.ord_id=ord.ord_id
and   c.classif_id=rc.classif_id
and   tipoc.classif_tipo_id=c.classif_tipo_id
and   tipoc.classif_tipo_code='PDC_V'
and   c.classif_code='U.7.01.01.02.001'
--and   rs.data_cancellazione is null
--and   rs.validita_fine is null
and   rc.data_cancellazione is null
and   rc.validita_fine is null

order by ord.ord_numero::integer desc

-- 144
-- 20953

select c.classif_id
from siac_t_class c, siac_d_class_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.classif_tipo_code='PDC_V'
and   c.classif_tipo_id=tipo.classif_tipo_id
and   c.classif_code='U.7.01.01.02.001'
-- 1714729

rollback;
begin;
update siac_r_ordinativo_class rc
set    classif_id=1714729
from siac_t_class c ,siac_d_class_tipo tipo
where rc.ord_id=20953
and   tipo.ente_proprietario_id=2
and   tipo.classif_tipo_code='PDC_V'
and   c.classif_tipo_id=tipo.classif_tipo_id
and   rc.classif_id=c.classif_id

begin;
update siac_t_ordinativo ord
set    siope_tipo_debito_id=deb.siope_tipo_debito_id
from siac_d_siope_tipo_debito deb
where ord.ord_id=21014
and   deb.ente_proprietario_id=2
and   deb.siope_tipo_debito_desc_bnkit='NON_COMMERCIALE'



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
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='SPR|REI_ORD|FPR|FAT|NCD'
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
set    flusso_elab_mif_param='PDC_V|U.7.01.01.02.001',
       flusso_elab_mif_default='NON_COMMERCIALE|IVA'
where mif.ente_proprietario_id=2
and   mif.flusso_elab_mif_code like 'tipo_debito_siope_nc'
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
 and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
);



select tipo_da.ord_tipo_code, ord_da.ord_id,
	   tipo_a.ord_tipo_code, ord_a.ord_id
from siac_r_ordinativo r, siac_d_relaz_tipo tiporel,
     siac_t_ordinativo ord_da, siac_d_ordinativo_tipo tipo_da,
     siac_t_ordinativo ord_a, siac_d_ordinativo_tipo tipo_a
where tiporel.ente_proprietario_id=2
and   tiporel.relaz_tipo_code='REI_ORD'
and   r.relaz_tipo_id=tiporel.relaz_tipo_id
and   ord_da.ord_id=r.ord_id_da
and   tipo_da.ord_tipo_id=ord_da.ord_tipo_id
and   ord_a.ord_id=r.ord_id_a
and   tipo_a.ord_tipo_id=ord_a.ord_tipo_id
and   r.data_cancellazione is null
and   r.validita_fine is null



with
relSplit as
(
select ord_a.ord_id ,
       ord_da.ord_numero::integer ordSplitNumero,
       ord_da.ord_id ordSplitId
from siac_r_ordinativo r, siac_d_relaz_tipo tiporel,
     siac_t_ordinativo ord_da, siac_d_ordinativo_tipo tipo_da,
     siac_t_ordinativo ord_a, siac_d_ordinativo_tipo tipo_a,
     siac_r_ordinativo_stato rs,siac_d_ordinativo_stato stato
where tiporel.ente_proprietario_id=2
and   tiporel.relaz_tipo_code='SPR'
and   r.relaz_tipo_id=tiporel.relaz_tipo_id
and   ord_da.ord_id=r.ord_id_da
and   tipo_da.ord_tipo_id=ord_da.ord_tipo_id
and   tipo_da.ord_tipo_code='P'
and   ord_a.ord_id=r.ord_id_a
and   tipo_a.ord_tipo_id=ord_a.ord_tipo_id
and   rs.ord_id=ord_da.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rs.data_cancellazione is null
and   rs.validita_fine is null
),
relREI as
(
select ord_da.ord_id ,
       ord_a.ord_id ordReiId,
       ord_a.ord_numero::integer ordReiNumero,
       fnc_mif_ordinativo_esiste_documenti_splus( ord_a.ord_id,
                                                  'FPR|FAT|NCD',
                                                  ord_a.ente_proprietario_id
                                                ) asReiDoc,
       c.classif_code pdcFinRei
from siac_r_ordinativo r, siac_d_relaz_tipo tiporel,
     siac_t_ordinativo ord_da, siac_d_ordinativo_tipo tipo_da,
     siac_t_ordinativo ord_a, siac_d_ordinativo_tipo tipo_a,
     siac_r_ordinativo_class rc, siac_t_class c, siac_d_class_tipo tipoc
where tiporel.ente_proprietario_id=2
and   tiporel.relaz_tipo_code='REI_ORD'
and   r.relaz_tipo_id=tiporel.relaz_tipo_id
and   ord_da.ord_id=r.ord_id_da
and   tipo_da.ord_tipo_id=ord_da.ord_tipo_id
and   tipo_da.ord_tipo_code='I'
and   ord_a.ord_id=r.ord_id_a
and   tipo_a.ord_tipo_id=ord_a.ord_tipo_id
and   rc.ord_id=ord_a.ord_id
and   c.classif_id=rc.classif_id
and   tipoc.classif_tipo_id=c.classif_tipo_id
and   tipoc.classif_tipo_code='PDC_V'
and   rC.data_cancellazione is null
and   rC.validita_fine is null
and   r.data_cancellazione is null
and   r.validita_fine is null
),
ordinativi as
(
select ord.ord_numero::integer,
       ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       ord.ord_id
from siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato,
     siac_t_ordinativo ord
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='I'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
)
select ordinativi.ord_numero,
       ordinativi.ord_emissione_data,
       ordinativi.ord_trasm_oil_data,
       ordinativi.ord_stato_code,
       relREI.ordReiNumero,
       relREI.ordReiId,
       relREI.asReiDoc,
       relREI.pdcFinRei,
       relSplit.ordSplitNumero,
       relSplit.ordSplitId
from ordinativi
     left join relREI on (ordinativi.ord_id=relREI.ord_id)
     left join relSplit on (ordinativi.ord_id=relSplit.ord_id)
order by 1 desc

-- 94 split commerciale OK
-- 82 non commerciale  non reintroito KO