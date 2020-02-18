/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿creare script insert lanciando la select successiva su pgdAdmin senza "quote"
-- lanciare le insert

/*update mif_d_flusso_elaborato m
set flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=&ente
and   tipo.flusso_elab_mif_tipo_code=&tipoFlusso
and   m.ente_proprietario_id=tipo.ente_proprietario_id
and   m.flusso_elab_mif_tipo_id is null ;*/

select 'INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values ('
            ||  d.flusso_elab_mif_ordine||','
            ||  quote_nullable(d.flusso_elab_mif_code)||','
            ||  quote_nullable(d.flusso_elab_mif_desc)||','
            ||  d.flusso_elab_mif_attivo||','
            ||  quote_nullable(d.flusso_elab_mif_code_padre)||','
            ||  quote_nullable(d.flusso_elab_mif_tabella)||','
            ||  quote_nullable(d.flusso_elab_mif_campo)||','
            ||  quote_nullable(d.flusso_elab_mif_default)||','
            ||  d.flusso_elab_mif_elab||','
            ||  quote_nullable(d.flusso_elab_mif_param)||','
            ||  quote_nullable('2016-01-01')||','
            ||  17||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  tipo_a.flusso_elab_mif_tipo_id
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo, mif_d_flusso_elaborato_tipo tipo_a
where d.ente_proprietario_id=24
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
and   tipo_a.ente_proprietario_id=17
and   tipo_a.flusso_elab_mif_tipo_code='MANDMIF';

select * from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=27


-- da collaudo per ente e tipo
select 'INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values ('
            ||  d.flusso_elab_mif_ordine||','
            ||  quote_nullable(d.flusso_elab_mif_code)||','
            ||  quote_nullable(d.flusso_elab_mif_desc)||','
            ||  d.flusso_elab_mif_attivo||','
            ||  quote_nullable(d.flusso_elab_mif_code_padre)||','
            ||  quote_nullable(d.flusso_elab_mif_tabella)||','
            ||  quote_nullable(d.flusso_elab_mif_campo)||','
            ||  quote_nullable(d.flusso_elab_mif_default)||','
            ||  d.flusso_elab_mif_elab||','
            ||  quote_nullable(d.flusso_elab_mif_param)||','
            ||  quote_nullable('2016-01-01')||','
            ||  32||','
            ||  quote_nullable(d.login_operazione)||','
            ||  d.flusso_elab_mif_ordine_elab||','
            ||  quote_nullable(d.flusso_elab_mif_query)||','
            ||  d.flusso_elab_mif_xml_out||','
            ||  66
            || ');'
from mif_d_flusso_elaborato d,
     mif_d_flusso_elaborato_tipo tipo
where d.ente_proprietario_id=32
and   d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   tipo.flusso_elab_mif_tipo_code='MANDMIF'
--and   tipo.flusso_elab_mif_tipo_code='REVMIF'
order by d.flusso_elab_mif_ordine;

begin;
delete from mif_d_flusso_elaborato where ente_proprietario_id=1