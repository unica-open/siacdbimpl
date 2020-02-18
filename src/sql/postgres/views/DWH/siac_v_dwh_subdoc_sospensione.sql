/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_dwh_subdoc_sospensione (
	doc_id,
    anno_doc ,
    num_doc,
    cod_tipo_doc,
    data_emissione_doc,
    cod_sogg_doc,
	num_subdoc,
    causale_sospensione,
    data_sospensione,
    data_riattivazione,
 	ente_proprietario_id)
AS
with doc as
	(select
    doc.doc_id
    , doc.doc_anno
    , doc.doc_numero
    , tipoDoc.doc_tipo_code
    , doc.doc_data_emissione
    , doc.ente_proprietario_id
    from siac_t_doc doc,
    siac_d_doc_tipo tipoDoc
    where
    doc.doc_tipo_id = tipoDoc.doc_tipo_id)
    , subDoc as
    (select
      sub.doc_id
    , sub.subdoc_numero
    , sosp.subdoc_sosp_causale
    , sosp.subdoc_sosp_data
    , sosp.subdoc_sosp_data_riattivazione
    , sub.ente_proprietario_id
    from siac_t_subdoc sub,
    	 siac_t_subdoc_sospensione sosp
        where sosp.subdoc_id = sub.subdoc_id
        and   sosp.data_cancellazione is null
        and   sosp.validita_fine is null
    )
    , sogg as
    (select
      r.doc_id
    , s.soggetto_code
    , r.ente_proprietario_id
    from
    siac_t_soggetto s,
    siac_r_doc_sog r
    where r.data_cancellazione is null
    and   r.validita_fine is null
    and   r.soggetto_id = s.soggetto_id)
select
    doc.doc_id
    , doc.doc_anno as anno_doc
    , doc.doc_numero as num_doc
    , doc.doc_tipo_code as cod_tipo_doc
    , doc.doc_data_emissione as data_emissione_doc
    , sogg.soggetto_code as cod_sogg_doc
    , subdoc.subdoc_numero as num_subdoc
    , subdoc.subdoc_sosp_causale as causale_sospensione
    , to_char(subdoc.subdoc_sosp_data,'dd/mm/yyyy') as data_sospensione
    , to_char(subdoc.subdoc_sosp_data_riattivazione,'dd/mm/yyyy') as data_riattivazione
    , doc.ente_proprietario_id
from doc, subdoc, sogg
where doc.doc_id = subdoc.doc_id
and   doc.doc_id = sogg.doc_id;
