/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿select mif.*
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


select r.accredito_tipo_oil_rel_id,
       oil.accredito_tipo_oil_code, oil.accredito_tipo_oil_desc,
       oil.accredito_tipo_oil_area,
       gruppo.accredito_gruppo_code,
       tipo.accredito_tipo_code, tipo.accredito_tipo_desc
from siac_d_accredito_tipo_oil oil, siac_r_accredito_tipo_oil r, siac_d_accredito_tipo tipo,
     siac_d_accredito_gruppo gruppo
where oil.ente_proprietario_id=2
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   tipo.accredito_tipo_id=r.accredito_tipo_id
and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
and   r.data_cancellazione is  null
--and   oil.accredito_tipo_oil_code in ('02','03','04')
order by oil.accredito_tipo_oil_code::integer

select ord.ord_numero::integer,
       ord.ord_id,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_Code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine

select ord.ord_numero::integer,
       ord.ord_id,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
	   accre.accredito_tipo_code, accre.accredito_tipo_desc,
       gruppo.accredito_gruppo_code,
       accre.accredito_tipo_id,
       mdp.*
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_modpag rmdp, siac_t_modpag mdp , siac_d_accredito_tipo accre,siac_d_accredito_gruppo gruppo,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rmdp.ord_id=ord.ord_id
and   mdp.modpag_id=rmdp.modpag_id
and   accre.accredito_tipo_id=mdp.accredito_tipo_id
and   gruppo.accredito_gruppo_id=accre.accredito_gruppo_id
and   accre.accredito_tipo_code='FI'
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_Code!='A'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine

select ord.ord_numero::integer,
       ord.ord_id,
       stato.ord_stato_code,
       rs.validita_inizio, rs.validita_fine,
	   accre.accredito_tipo_code, accre.accredito_tipo_desc,
       gruppo.accredito_gruppo_code,
       accre.accredito_tipo_id,
       mdp.*
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_modpag rmdp, siac_t_modpag mdp , siac_d_accredito_tipo accre,siac_d_accredito_gruppo gruppo,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer=76
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rmdp.ord_id=ord.ord_id
and   mdp.modpag_id=rmdp.modpag_id
and   accre.accredito_tipo_id=mdp.accredito_tipo_id
and   gruppo.accredito_gruppo_id=accre.accredito_gruppo_id
and   accre.accredito_tipo_code='FI'
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_Code!='A'
and   rs.data_cancellazione is null
--and   rs.validita_fine is null
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine

select ord.ord_numero::integer,
       ord.ord_id,
       stato.ord_stato_code,
       ord.ord_trasm_oil_data,
       rs.validita_inizio, rs.validita_fine
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer=13662
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_Code!='A'
--and   rs.data_cancellazione is null
--and   rs.validita_fine is null
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine

update siac_t_ordinativo ord
set     ord_trasm_oil_data=null
where ord.ord_id=20530
update siac_r_ordinativo_stato r
set    validita_fine=null
where r.ord_id=20530

-- modpag_id=149673




insert into siac_r_ordinativo_stato
(
	ord_id,
    ord_stato_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
)
select 20801,
       stato.ord_stato_id,
       now(),
       '',
       stato.ente_proprietario_id
from siac_d_ordinativo_stato stato
where stato.ente_proprietario_id=2
and   stato.ord_stato_code='F'


select mif.mif_ord_anno, mif.mif_ord_numero, doc.mif_ord_doc_natura_spesa
from mif_t_ordinativo_spesa mif, mif_t_ordinativo_spesa_documenti doc,
     mif_d_flusso_elaborato_tipo tipo, mif_t_flusso_elaborato miff
where doc.mif_ord_id=mif.mif_ord_id
and   mif.mif_ord_flusso_elab_mif_id=miff.flusso_elab_mif_id
and   tipo.flusso_elab_mif_tipo_id=miff.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
order by mif.mif_ord_anno,mif.mif_ord_numero::integer




select *
from siac_d_class_fam f
where f.ente_proprietario_id=2
and   f.classif_fam_desc='Spesa - TitoliMacroaggregati'

select tree.*
from siac_t_class_fam_tree tree, siac_d_class_fam d
where d.ente_proprietario_id=2
and   d.classif_fam_desc='Spesa - TitoliMacroaggregati'
and   tree.classif_fam_id=d.classif_fam_id

select  c.classif_code, c1.classif_code,r.*
from siac_r_class_fam_tree r, siac_t_class_fam_tree tree, siac_d_class_fam d,
     siac_t_class c,siac_t_class c1
where d.ente_proprietario_id=2
and   d.classif_fam_desc='Spesa - TitoliMacroaggregati'
and   tree.classif_fam_id=d.classif_fam_id
and   r.classif_fam_tree_id=tree.classif_fam_tree_id
and   c.classif_id=r.classif_id_padre
and   c.classif_code='1'
and   c1.classif_id=r.classif_id


select ord.ord_numero::integer,
       ord.ord_id,
       stato.ord_stato_code,
       ord.ord_trasm_oil_data,
       ord.ord_spostamento_data,
       rs.validita_inizio, rs.validita_fine
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer in (13692)
and   anno.anno_bilancio=2017
and   anno.bil_id=ord.bil_id
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_Code!='A'
--and   rs.data_cancellazione is null
--and   rs.validita_fine is null
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine

select  mif.mif_ord_ord_id,mif.mif_ord_anno, mif.mif_ord_numero, doc.mif_ord_doc_natura_spesa,mif.mif_ord_flusso_elab_mif_id
from mif_t_ordinativo_entrata mif, mif_t_ordinativo_spesa_documenti doc,
     mif_d_flusso_elaborato_tipo tipo, mif_t_flusso_elaborato miff
where doc.mif_ord_id=mif.mif_ord_id
and   mif.mif_ord_flusso_elab_mif_id=miff.flusso_elab_mif_id
and   tipo.flusso_elab_mif_tipo_id=miff.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
and   mif.mif_ord_numero::integer in (6391,6350)
and doc.mif_ord_doc_natura_spesa is not null
order by mif.mif_ord_flusso_elab_mif_id desc,mif.mif_ord_anno,mif.mif_ord_numero::integer


		         select ord.ord_id
			     from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			         siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato, siac_d_relaz_tipo tiporel
				 where rord.ord_id_a=20492
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


select mif.*
from mif_d_flusso_elaborato mif
where mif.ente_proprietario_id=2
and   exists
(select 1
 from mif_d_flusso_elaborato_tipo tipo
 where tipo.ente_proprietario_id=mif.ente_proprietario_id
-- and   tipo.flusso_elab_mif_tipo_code='REVMIF_SPLUS'
  and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
 and   tipo.flusso_elab_mif_tipo_id=mif.flusso_elab_mif_tipo_id
)
order by mif.flusso_elab_mif_ordine


select c.*
from siac_t_class c, siac_d_class_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.classif_tipo_code='CLASSIFICATORE_23'
and   c.classif_tipo_id=tipo.classif_tipo_id



select ord.ord_numero::integer,
       ord.ord_id,
       stato.ord_stato_code,
       ord.ord_trasm_oil_data,
       fnc_mif_ordinativo_esiste_documenti_splus( ord.ord_id,
                                                  'FPR|FAT|NCD',
                                                  ord.ente_proprietario_id
                                                                        ),
       rs.validita_inizio, rs.validita_fine
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
--and   ord.ord_numero::integer in (6391,6350)
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_Code!='A'
and   rs.data_cancellazione is null
--and   rs.validita_fine is null
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine
-- 1 ord_id=20596
-- 24 ord_id=20751


158

-- qui qui per cercare ordinati di spesa con note di credito
-- e poi ordinativi di entrata split collegate
with
ordinativi as
(
select ord.ord_numero::integer,
       ord.ord_id,
       stato.ord_stato_code,
       ord.ord_trasm_oil_data,
       rs.validita_inizio, rs.validita_fine,
       ord.ente_proprietario_id
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_Code!='A'
and   rs.data_cancellazione is null
and   exists
(
select 1
from siac_r_ordinativo r, siac_d_relaz_tipo tipor
where r.ord_id_da=ord.ord_id
and   tipor.relaz_tipo_id=r.relaz_tipo_id
and   tipor.relaz_tipo_code='SPR'
and   r.data_cancellazione is null
and   r.validita_fine is null
)
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine
),
documenti as
(
select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           docNcd.doc_anno annoDocNcd, docNcd.doc_numero numeroDocNcd, tipoNcd.doc_tipo_code tipoDocNcd,
           lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from docNcd.doc_data_emissione) dataDoc,
           sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
           docNcd.doc_id docId,
           docNcd.pccuff_id pccuffId,
           subNcd.subdoc_data_scadenza datascadDoc,
           docNcd.siope_documento_tipo_id siopeDocTipoId,
           docNcd.doc_sdi_lotto_siope  siopeSdiLotto,
           docNcd.siope_documento_tipo_analogico_id siopeDocAnTipoId,
           sum(subdoc.subdoc_importo) importoDoc,
           0 importoSplitDoc,
           sum(subdoc.subdoc_importo_da_dedurre) importoNcd,
           ordts.ord_id
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd,
         siac_r_doc_sog rsog, siac_t_soggetto sog
    where --ordts.ord_id=ordinativoId
          ordts.ente_proprietario_id=2
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,'FPR','FAT','NCD')=true
    and   tipo.doc_tipo_code!='ALG'
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code='NCD'
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,'FPR','FAT','NCD')=true
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   rsog.doc_id=docNcd.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rsog.data_cancellazione is null and rsog.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    and   sog.data_cancellazione is null
    group by  doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,doc.doc_id,
              docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
              lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              extract('year' from docNcd.doc_data_emissione),
              sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,subNcd.subdoc_data_scadenza,
              docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id,
              ordts.ord_id
)
select ordinativi.*,
       documenti.*,
       fnc_mif_ordinativo_esiste_documenti_splus( ordinativi.ord_id,
                                                  'FPR|FAT|NCD',
                                                  ordinativi.ente_proprietario_id
                                                                        ) esisteDoc
from ordinativi,documenti
where ordinativi.ord_id=documenti.ord_id


--- ord_id=20308
--- ord_numero=13692
--  ord_id_a=20307
select  ord_numero, ord.contotes_id, d.contotes_code
from siac_t_ordinativo ord,siac_d_contotesoreria d
where ord.ord_id=20308--20307
and   d.contotes_id=ord.contotes_id
-- 6340
select  * --ord_numero, ord.contotes_id, d.contotes_code
from siac_t_ordinativo ord
where ord.ord_id=20308--20307

         select ord.ord_id,rord.ord_id_a
			     from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
			         siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato, siac_d_relaz_tipo tiporel
				 where rord.ord_id_da=20308
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



          select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
        'P'::varchar tipoColl,doc.doc_id docPrincId,
        null annoDocNcd, null numeroDocNcd, null tipoDocNcd,
        lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
        lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
        extract('year' from doc.doc_data_emissione) dataDoc,
        sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
        doc.doc_id docId,
        doc.pccuff_id pccuffId,
        subdoc.subdoc_data_scadenza datascadDoc,
        doc.siope_documento_tipo_id siopeDocTipoId,
        doc.doc_sdi_lotto_siope  siopeSdiLotto,
        doc.siope_documento_tipo_analogico_id siopeDocAnTipoId,
        sum(subdoc.subdoc_importo) importoDoc,
        coalesce(sum(subdoc.subdoc_splitreverse_importo),0) importoSplitDoc,
        null importoNcd,null numeroNcd,
        null importoRipartNcd
  from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
       siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
       siac_r_doc_sog rsog, siac_t_soggetto sog
  where ordts.ord_id=20308
  and   subdocts.ord_ts_id=ordts.ord_ts_id
  and   subdoc.subdoc_id=subdocts.subdoc_id
  and   doc.doc_id=subdoc.doc_id
  and   tipo.doc_tipo_id=doc.doc_tipo_id
  and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,'FPR','FAT','NCD')=true
  and   tipo.doc_tipo_code!='ALG'
  and   rsog.doc_id=doc.doc_id
  and   sog.soggetto_id=rsog.soggetto_id
  and   ordts.data_cancellazione is null and ordts.validita_fine is null
  and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
  and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
  and   doc.data_cancellazione is null and doc.validita_fine is null
  and   tipo.data_cancellazione is null
  and   rsog.data_cancellazione is null and rsog.validita_fine is null
  and   sog.data_cancellazione is null
  and   date_trunc('day',now()::timestamp)>=date_trunc('day',tipo.validita_inizio)
  and   date_trunc('day',now()::timestamp)<=date_trunc('day',coalesce(tipo.validita_fine,now()::timestamp))
  group by doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,
           lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from doc.doc_data_emissione),
           sog.codice_fiscale, sog.partita_iva, doc.doc_id,doc.pccuff_id,subdoc.subdoc_data_scadenza,
           doc.siope_documento_tipo_id, doc.doc_sdi_lotto_siope,doc.siope_documento_tipo_analogico_id
  union
  (
   with
   docS as
   (
    select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           docNcd.doc_anno annoDocNcd, docNcd.doc_numero numeroDocNcd, tipoNcd.doc_tipo_code tipoDocNcd,
           lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
           extract('year' from docNcd.doc_data_emissione) dataDoc,
           sog.codice_fiscale codfiscDoc, sog.partita_iva partivaDoc,
           docNcd.doc_id docId,
           docNcd.pccuff_id pccuffId,
           subNcd.subdoc_data_scadenza datascadDoc,
           docNcd.siope_documento_tipo_id siopeDocTipoId,
           docNcd.doc_sdi_lotto_siope  siopeSdiLotto,
           docNcd.siope_documento_tipo_analogico_id siopeDocAnTipoId,
           sum(subdoc.subdoc_importo) importoDoc,
           0 importoSplitDoc,
           sum(subdoc.subdoc_importo_da_dedurre) importoNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd,
         siac_r_doc_sog rsog, siac_t_soggetto sog
    where ordts.ord_id=20308
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,'FPR','FAT','NCD')=true
    and   tipo.doc_tipo_code!='ALG'
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code='NCD'
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,'FPR','FAT','NCD')=true
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   rsog.doc_id=docNcd.doc_id
    and   sog.soggetto_id=rsog.soggetto_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rsog.data_cancellazione is null and rsog.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    and   sog.data_cancellazione is null
    group by  doc.doc_anno , doc.doc_numero , tipo.doc_tipo_code,doc.doc_id,
              docNcd.doc_anno , docNcd.doc_numero , tipoNcd.doc_tipo_code,
              lpad(extract('day' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              lpad(extract('month' from docNcd.doc_data_emissione)::varchar,2,'0')||'/'||
              extract('year' from docNcd.doc_data_emissione),
              sog.codice_fiscale, sog.partita_iva, docNcd.doc_id,docNcd.pccuff_id,subNcd.subdoc_data_scadenza,
              docNcd.siope_documento_tipo_id, docNcd.doc_sdi_lotto_siope,docNcd.siope_documento_tipo_analogico_id
   ),
   docCountNcd as
   (
    select doc.doc_anno annoDoc, doc.doc_numero numeroDoc, tipo.doc_tipo_code tipoDoc,
           'S'::varchar tipoColl,doc.doc_id docPrincId,
           count(*) numeroNcd
    from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs,
         siac_t_ordinativo_ts ordts, siac_d_doc_tipo tipo,
         siac_r_doc rdoc, siac_d_relaz_tipo tipoRel,
         siac_t_doc docNcd, siac_t_subdoc subNcd, siac_d_doc_tipo tipoNcd
    where ordts.ord_id=20308
    and   subdocts.ord_ts_id=ordts.ord_ts_id
    and   subdoc.subdoc_id=subdocts.subdoc_id
    and   doc.doc_id=subdoc.doc_id
    and   tipo.doc_tipo_id=doc.doc_tipo_id
    and   fnc_mif_isDocumentoCommerciale_splus(doc.doc_id,'FPR','FAT','NCD')=true
    and   tipo.doc_tipo_code!='ALG'
    and   rdoc.doc_id_da=doc.doc_id
    and   docncd.doc_id=rdoc.doc_id_a
    and   tipoRel.relaz_tipo_id=rdoc.relaz_tipo_id
    and   tipoRel.relaz_tipo_code='NCD'
    and   fnc_mif_isDocumentoCommerciale_splus(docNcd.doc_id,'FPR','FAT','NCD')=true
    and   subNcd.doc_id=docNcd.doc_id
    and   tipoNcd.doc_tipo_id=docNcd.doc_tipo_id
    and   ordts.data_cancellazione is null and ordts.validita_fine is null
    and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
    and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
    and   doc.data_cancellazione is null and doc.validita_fine is null
    and   subNcd.data_cancellazione is null and subNcd.validita_fine is null
    and   docNcd.data_cancellazione is null and docNcd.validita_fine is null
    and   rdoc.data_cancellazione is null and rdoc.validita_fine is null
    group by doc.doc_anno , doc.doc_numero, tipo.doc_tipo_code ,doc.doc_id
   )
   select docS.*,
          docCountNcd.numeroNcd, round(docS.importoNcd/docCountNcd.numeroNcd,2) importoRipartNcd
   from docS, docCountNcd
   where docS.docPrincId=docCountNcd.docPrincId
   and   'N'='N'
  )
  order by 1,2,3,4,6,7,8



  select *
  from mif_r_conto_tesoreria_vincolato r
  where r.ente_proprietario_id=2

  insert into mif_r_conto_tesoreria_vincolato
  (
   contotes_id,
   vincolato,
   validita_inizio,
   login_operazione,
   ente_proprietario_id
  )
  values
  (5,'LIBERA',now(),'test',2);


select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select ord.ord_numero::integer, d.contotes_code, mif.mif_ord_bci_conto_tes,
       mif.mif_ord_progr_dest
from mif_t_ordinativo_spesa  mif,siac_t_ordinativo ord, siac_d_contotesoreria d
where mif.mif_ord_flusso_elab_mif_id=1529
and   ord.ord_id=mif.mif_ord_ord_id
and   d.contotes_id=ord.contotes_id
order by 1

-- classificatore_23
select ord.ord_numero::integer,
       ord.ord_id,
       stato.ord_stato_code,
       ord.ord_trasm_oil_data,
       fnc_mif_ordinativo_esiste_documenti_splus( ord.ord_id,
                                                  'FPR|FAT|NCD',
                                                  ord.ente_proprietario_id
                                                                        ),
       rs.validita_inizio, rs.validita_fine
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo, siac_v_bko_anno_bilancio anno,
     siac_r_ordinativo_stato rs, siac_d_ordinativo_stato stato
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='P'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   ord.ord_numero::integer in (158,6350)
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2018
and   rs.ord_id=ord.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   stato.ord_stato_Code!='A'
and   rs.data_cancellazione is null
--and   rs.validita_fine is null
order by ord.ord_numero::integer,rs.validita_inizio, rs.validita_fine
-- 1 ord_id=20596
-- 24 ord_id=20751



