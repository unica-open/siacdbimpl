/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE VIEW siac.siac_v_dwh_tipo_documento (
    cod_tipo_documento,
    desc_tipo_documento,
    codice_gruppo,
    descrizione_gruppo,
    codice_famiglia,
    descrizione_famiglia,
    ente_proprietario_id,
    validita_inizio,
    validita_fine, rilevante_coge)
AS
with doc as (
SELECT a.doc_tipo_code,a.doc_tipo_desc,b.doc_gruppo_tipo_code,
    b.doc_gruppo_tipo_desc,c.doc_fam_tipo_code,
    c.doc_fam_tipo_desc, a.ente_proprietario_id,
    a.validita_inizio, a.validita_fine, a.doc_tipo_id
FROM siac_d_doc_tipo a
   JOIN siac_d_doc_fam_tipo c ON c.doc_fam_tipo_id = a.doc_fam_tipo_id AND
       a.ente_proprietario_id = c.ente_proprietario_id AND c.data_cancellazione IS NULL
   LEFT JOIN siac_d_doc_gruppo b ON a.doc_gruppo_tipo_id = b.doc_gruppo_tipo_id
       AND a.ente_proprietario_id = b.ente_proprietario_id AND b.data_cancellazione IS NULL
WHERE a.data_cancellazione IS NULL)
, 
coge as 
(select 
b2.doc_tipo_id
 from siac_r_doc_tipo_attr b2, siac_t_attr c2
where c2.attr_id=b2.attr_id and c2.attr_code='flagAttivaGEN')
select 
doc.doc_tipo_code AS cod_tipo_documento,
    doc.doc_tipo_desc AS desc_tipo_documento,
    doc.doc_gruppo_tipo_code AS codice_gruppo,
    doc.doc_gruppo_tipo_desc AS descrizione_gruppo,
    doc.doc_fam_tipo_code AS codice_famiglia,
    doc.doc_fam_tipo_desc AS descrizione_famiglia, doc.ente_proprietario_id,
    doc.validita_inizio, doc.validita_fine,
    case when coge.doc_tipo_id is not null then 'S' else 'N' end rilevante_coge
 from doc left join coge
on 
doc.doc_tipo_id=coge.doc_tipo_id;

GRANT SELECT ON siac.siac_v_dwh_tipo_documento TO siac_dwh;
