/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿------------delete-----------------

delete from siac_r_liquidazione_atto_amm where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_r_liquidazione_attr where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_r_liquidazione_class where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_r_liquidazione_movgest where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_r_liquidazione_ord where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_r_liquidazione_soggetto where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_r_liquidazione_stato where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_r_mutuo_voce_liquidazione where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_r_subdoc_liquidazione where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);
delete from siac_t_liquidazione where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=&ente);

delete from siac_r_cartacont_det_subdoc where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_elenco_doc_subdoc where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_mutuo_voce_subdoc where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_predoc_subdoc where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_atto_amm where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_attr where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_class where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_liquidazione where ente_proprietario_id=&ente and  subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_modpag where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_movgest_ts where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_ordinativo_ts where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_prov_cassa where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_sog where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_splitreverse_iva_tipo where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_r_subdoc_subdoc_iva where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_t_registro_pcc where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));
delete from siac_t_subdoc where ente_proprietario_id=&ente and subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente));

delete from siac_r_doc_attr where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_doc_class where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_doc_iva where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_doc_onere_ordinativo_ts where ente_proprietario_id=&ente;
delete from siac_r_doc_onere where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_doc_ordine where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_doc_sirfel where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_doc_sog where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_doc_stato where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_richiesta_econ_doc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_t_registro_pcc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_t_registrounico_doc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_t_subdoc_num where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);
delete from siac_r_doc where ente_proprietario_id=&ente;
delete from siac_t_doc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=&ente);

-------a partire da -----------
select distinct
'delete from '||table_name||' where liq_id in (select liq_id from siac_t_liquidazione a where a.ente_proprietario_id=1);'
 from information_schema.columns where column_name='liq_id'
and table_name not like 'siac_v%' and table_name not like 'siac_rep%'
and table_name not like '%migr%'
and table_name not like '%elab%'
order by 1


select distinct
'delete from '||table_name||' where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=1));'
 from information_schema.columns where column_name='subdoc_id'
and table_name not like 'siac_v%' and table_name not like 'siac_rep%'
and table_name not like '%migr%'
and table_name not like '%elab%'
order by 1

select distinct
'delete from '||table_name||' where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=1);'
 from information_schema.columns where column_name='doc_id'
and table_name not like 'siac_v%' and table_name not like 'siac_rep%'
and table_name not like '%migr%'
and table_name not like '%elab%'
order by 1