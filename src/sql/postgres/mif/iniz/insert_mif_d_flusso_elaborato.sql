/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- creare script insert lanciando la select successiva su pgdAdmin senza "quote"
-- lanciare le insert
-- fare update per flusso_elab_mif_tipo_id
-- select * From mif_d_flusso_elaborato where flusso_elab_mif_tipo_id=2
-- select * from mif_d_flusso_elaborato_tipo

--update mif_d_flusso_elaborato set flusso_elab_mif_tipo_id=2
-- where flusso_elab_mif_tipo_id is null

select 'INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out) values ('
            ||  flusso_elab_mif_ordine||','
            ||  quote_nullable(flusso_elab_mif_code)||','
            ||  quote_nullable(flusso_elab_mif_desc)||','
            ||  flusso_elab_mif_attivo||','
            ||  quote_nullable(flusso_elab_mif_code_padre)||','
            ||  quote_nullable(flusso_elab_mif_tabella)||','
            ||  quote_nullable(flusso_elab_mif_campo)||','
            ||  quote_nullable(flusso_elab_mif_default)||','
            ||  flusso_elab_mif_elab||','
            ||  quote_nullable(flusso_elab_mif_param)||','
            || quote_nullable('2015-01-01')||','
            || ente_proprietario_id||','
            ||  quote_nullable(login_operazione)||','
            ||  flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(flusso_elab_mif_query)||','
            ||  flusso_elab_mif_xml_out
            || ');'
from mif_d_flusso_elaborato
where ente_proprietario_id=15
and   flusso_elab_mif_tipo_id=2
order by flusso_elab_mif_id