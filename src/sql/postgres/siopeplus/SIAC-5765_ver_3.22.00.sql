/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 15.01.2018 Sofia JIRA-5765
--  fnc_mif_ordinativo_spesa_splus
    -- inserimento codice_operatore in mif_d_flusso_elaborato e compilazione fnc
    -- aggiornamento conf piazzatura per CCP
--  fnc_mif_ordinativo_entrata_splus -- inserimento codice_operatore in mif_d_flusso_elaborato e compilazione fnc
--  fnc_mif_ordinativo_documenti_splus -- compilazione , cambio paramentri
---

INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (158,'codice_operatore',NULL,true,'flusso_ordinativi.ordinativi.mandato.dati_a_disposizione_ente_mandato','mif_t_ordinativo_spesa','mif_ord_codice_atto_contabile',NULL,true,null,'2017-01-01',2,'admin',135,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));


INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (96,'codice_operatore',NULL,true,'flusso_ordinativi.ordinativi.reversale.dati_a_disposizione_ente_reversale','mif_t_ordinativo_entrata','mif_ord_codice_atto_contabile',NULL,true,null,'2017-01-01',2,'admin',73,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));

/*rollback;
begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CB|IT|CCP'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code in
(
'abi_beneficiario',
'cab_beneficiario',
'caratteri_controllo',
'codice_cin',
'codice_paese'
);

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='00000'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code in
(
'abi_beneficiario',
'cab_beneficiario'
);

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='00'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code in
(
'caratteri_controllo'
);

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='X'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code in
(
'codice_cin'
);

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='IT'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code in
(
'codice_paese'
);*/


begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='DISPOSIZIONE DOCUMENTO ESTERNO|BONIFICO ESTERO EURO|STI|CCP'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='riferimento_documento_esterno';

update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CB|IT'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='numero_conto_corrente_beneficiario';


begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='SENZA PROVVEDIMENTO'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code in
(
'estremi_provvedimento_autorizzativo'
);



begin;
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='ANALOGICO|9999999999999999'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code in ('REVMIF_SPLUS','MANDMIF_SPLUS')
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code in
(
'codice_fiscale_emittente_siope'
);


--------------------
select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(select 1
from mif_d_flusso_elaborato_tipo tipo
where  mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and     tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' )
--and     tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS' )
--and   mif.flusso_elab_mif_campo='mif_ord_code_operatore'
/*and mif.flusso_elab_mif_code in
(
'estremi_provvedimento_autorizzativo',
'abi_beneficiario',
'cab_beneficiario',
'caratteri_controllo',
'codice_cin',
'codice_paese'
)*/
--and mif.flusso_elab_mif_code='codice_fiscale_emittente_siope'
order by mif.flusso_elab_mif_ordine

/*CB|IT|CCP
00000
00
X
IT*/



select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
--and   tipo.ord_tipo_code='I'

and   ord.ord_tipo_id=tipo.ord_tipo_id
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
order by 1, rs.validita_inizio, rs.validita_fine


select *
from siac_r_ordinativo_stato rs
where rs.ord_id=20498

select *
from siac_t_ordinativo ord
where ord.ord_id=20498

select  *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc


select mif.mif_ord_numero,
       mif.mif_ord_code_operatore
from mif_t_ordinativo_spesa mif
where mif.mif_ord_flusso_elab_mif_id=1327

select *
from siac_r_ordinativo_stato r
where r.ord_id=20494

select *
from siac_t_ordinativo ord
where ord.ord_id=20494

-- 6391

select mif.mif_ord_numero,
       mif.mif_ord_code_operatore
from mif_t_ordinativo_entrata mif
where mif.mif_ord_flusso_elab_mif_id=1334



select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       accre.accredito_tipo_code,
       mdp.contocorrente,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato,
     siac_r_ordinativo_modpag rmdp, siac_t_modpag mdp, siac_d_accredito_tipo accre, siac_d_accredito_gruppo gruppo
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rmdp.ord_id=ord.ord_id
and   mdp.modpag_id=rmdp.modpag_id
and   accre.accredito_tipo_id=mdp.accredito_tipo_id
and   gruppo.accredito_gruppo_id=accre.accredito_gruppo_id
and   gruppo.accredito_gruppo_code='CB'
--and   gruppo.accredito_gruppo_code='CCP'
and   mdp.iban not like '%IT%'
and   rs.data_cancellazione is null
and   rmdp.data_cancellazione is null
and   rmdp.validita_fine is null
order by 1, rs.validita_inizio, rs.validita_fine


select mif.*
from mif_t_ordinativo_spesa mif
where mif.mif_ord_flusso_elab_mif_id=1353

-- 13802  000001036407
select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
       atto.attoamm_anno, atto.attoamm_numero,
       tipoa.attoamm_tipo_code,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato,
     siac_r_ordinativo_atto_amm ratto, siac_t_atto_amm atto, siac_d_atto_amm_tipo tipoa
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   ratto.ord_id=ord.ord_id
and   atto.attoamm_id=ratto.attoamm_id
and   tipoa.attoamm_tipo_id=atto.attoamm_tipo_id
and   rs.data_cancellazione is null
and   ratto.data_cancellazione is null
and   ratto.validita_fine is null
order by 1, rs.validita_inizio, rs.validita_fine


select mif.mif_ord_numero, mif.mif_ord_class_tipo_debito
from mif_t_ordinativo_spesa mif
where mif.ente_proprietario_id=2
and   mif.mif_ord_class_tipo_debito is not null

-- 13474

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
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
and   ord.ord_numero::integer in (13813,13814)
order by 1, rs.validita_inizio, rs.validita_fine

-- 13813 13814

select *
from siac_r_ordinativo_stato r
where r.ord_id=20493

select *
from siac_t_ordinativo ord
where ord.ord_id=20493



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
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
and   ord.ord_numero::integer in (13813,13814)
order by 1, rs.validita_inizio, rs.validita_fine

-- ord_id=20489, 20493

select ts.ord_id, tipo.doc_tipo_code,
       sog.soggetto_id, sog.codice_fiscale, sog.partita_iva
from siac_t_ordinativo_ts ts, siac_r_subdoc_ordinativo_ts rdoc,siac_t_subdoc sub, siac_t_doc doc, siac_d_doc_tipo tipo,
     siac_r_doc_sog rsog, siac_t_soggetto sog
where ts.ord_id in (20489, 20493)
and   rdoc.ord_ts_id=ts.ord_ts_id
and   sub.subdoc_id=rdoc.subdoc_id
and   doc.doc_id=sub.doc_id
and   tipo.doc_tipo_id=doc.doc_tipo_id
and   rsog.doc_id=doc.doc_id
and   sog.soggetto_id=rsog.soggetto_id
and   rdoc.data_cancellazione is null
and   rdoc.validita_fine is null
and   rsog.data_cancellazione is null
and   rsog.validita_fine is null


rollback;
begin;
update siac_t_soggetto sog
set    codice_fiscale='01995120019'
where sog.soggetto_id=137140

select *
from siac_t_soggetto sog
where sog.soggetto_id=137140

select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='I'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rs.data_cancellazione is null
and   ord.ord_numero::integer in (6389,6390,6391)
order by 1, rs.validita_inizio, rs.validita_fine

-- ord_id=20490

select *
from siac_r_ordinativo_stato r
where r.ord_id=20490


select ord.ord_id ,rord.ord_id_a, tiporel.relaz_tipo_code
			     from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			         siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato, siac_d_relaz_tipo tiporel
				 where rord.ente_proprietario_id=2
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
order by 1,2

---20493 , 20492


select ord.ord_numero::integer,
	   ord.ord_emissione_data,
       ord.ord_trasm_oil_data,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
       ord.ord_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato,
     siac_r_ordinativo_modpag rmdp, siac_r_soggrel_modpag rel, siac_t_modpag mdp
 where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_code!='A'
and   rmdp.ord_id=ord.ord_id
and   rmdp.soggetto_relaz_id is not null
and   rel.soggetto_relaz_id=rmdp.soggetto_relaz_id
and   mdp.modpag_id=rel.modpag_id
and   mdp.iban is not null
and   mdp.iban  like 'IT%'
and   rs.data_cancellazione is null
order by 1, rs.validita_inizio, rs.validita_fine

--13848
-- 5476
select *
from siac_r_ordinativo_stato r
where r.ord_id=7741